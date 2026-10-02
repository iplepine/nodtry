// Every Firestore read build ≥81 issues, exactly as the app sends it — same
// collection, where clauses, orderBy and limit, as a one-off get() or as a
// listener (snapshots()) where the app listens:
//   lib/repositories/real_record_repository.dart
//   lib/repositories/real_connect_repository.dart
//   lib/repositories/real_user_repository.dart
//   lib/screens/developer_screen.dart, lib/core/services/{app_version_gate,client_metadata_sync}.dart
// plus the read-then-write flows (인정, 했어, approve) that depend on them.
//
// Runs against firestore.rules (`npm test`) and firestore.rules.next
// (`npm run test:next`):
//   - a participant's read must succeed, with the expected results, under
//     BOTH — build 81 works before and after the flip;
//   - the same read sent by a stranger — a user of another couple, an
//     anonymous guest on a custom client, or nobody signed in — must fail
//     under the narrowed rules. Under today's firestore.rules only what those
//     rules already deny is checked (signed out everywhere; strangers on
//     relations and single actions).
// "Narrowed" is probed from the loaded rules, not inferred from the file
// name, so this suite stays valid after the flip copies rules.next over
// firestore.rules (SECURITY_RULES.md, 전환 절차 2).
//
// When the app gains or changes a read, add it here (and to the contract in
// docs/operations/SECURITY_RULES.md, "앱 쿼리 계약").
const {describe, it, before, beforeEach, after} = require("node:test");
const assert = require("node:assert/strict");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {
    arrayUnion, collection, deleteField, doc, getDoc, getDocs, limit, onSnapshot, or, orderBy, query,
    runTransaction, serverTimestamp, setDoc, updateDoc, where, writeBatch, Timestamp,
} = require("firebase/firestore");
const {createTestEnv, firestoreRulesFile} = require("../test/helpers");
const {seed, day} = require("./fixtures");

const RULES = firestoreRulesFile();

// alice ⇄ bob are the couple (fixtures.js): alice manages bob's bPlan, bob
// manages alice's aPlan; aSolo is alice's plan without a manager.
// Today's window for _todayDoneActionRef: the whole of fixture day 1 (UTC).
const DAY1_START = Timestamp.fromMillis(Date.UTC(2026, 9, 1, 0, 0, 0));
const DAY1_END = Timestamp.fromMillis(Date.UTC(2026, 9, 1, 23, 59, 59));

/**
 * The app's queries. `as` is the signed-in participant; strangers send the
 * very same query (alice's / bob's uids as literals). `modes`: how the app
 * issues it. `expect`: result ids (in order when `ordered`). `scopedToday`:
 * firestore.rules already denies a signed-in stranger this read.
 */
const QUERIES = [
    // ── plans ────────────────────────────────────────────────────────────
    {
        name: "plans where userId == me",
        app: "RealRecordRepository._readablePlansOf(me) (getPlansByUserId[Stream], getAllPlansByUserIdStream), " +
            "getHomeCardStates, deletePlansByUserId(me)",
        as: "alice",
        modes: ["get", "listen"],
        build: (db) => query(collection(db, "plans"), where("userId", "==", "alice")),
        expect: ["aPlan", "aSolo"],
    },
    {
        name: "plans where userId == partner && managerId == me",
        app: "RealRecordRepository._readablePlansOf(partner) (getPlansByUserId[Stream], getAllPlansByUserIdStream)",
        as: "alice",
        modes: ["get", "listen"],
        build: (db) => query(collection(db, "plans"),
            where("userId", "==", "bob"), where("managerId", "==", "alice")),
        expect: ["bPlan"],
    },
    {
        name: "plans where (userId == me OR managerId == me)",
        app: "RealRecordRepository.getHomeCardStatesStream (snapshots, includeMetadataChanges), completeOverduePlans",
        as: "alice",
        modes: ["get", "listen"],
        build: (db) => query(collection(db, "plans"),
            or(where("userId", "==", "alice"), where("managerId", "==", "alice"))),
        expect: ["aPlan", "aSolo", "bPlan"],
    },
    {
        name: "plans where userId == me && state in [active, pending_approval]",
        app: "RealRecordRepository.assignManagerToActivePlans",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "plans"),
            where("userId", "==", "alice"), where("state", "in", ["active", "pending_approval"])),
        expect: ["aPlan", "aSolo"],
    },
    {
        name: "plans where managerId == me limit 1",
        app: "developer_screen (push test buttons)",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "plans"), where("managerId", "==", "alice"), limit(1)),
        expect: ["bPlan"],
    },

    // ── actions ──────────────────────────────────────────────────────────
    {
        name: "actions where userId == me orderBy date desc",
        app: "RealRecordRepository.getHistoryItems, _readableActionsOf(me) (getHistoryItemsStream)",
        as: "alice",
        modes: ["get", "listen"],
        build: (db) => query(collection(db, "actions"), where("userId", "==", "alice"), orderBy("date", "desc")),
        expect: ["aLegacy", "a2", "a1"],
        ordered: true,
    },
    {
        name: "actions where userId == partner && managerId == me orderBy date desc",
        app: "RealRecordRepository._readableActionsOf(partner) (getHistoryItemsStream)",
        as: "alice",
        modes: ["listen"],
        build: (db) => query(collection(db, "actions"),
            where("userId", "==", "bob"), where("managerId", "==", "alice"), orderBy("date", "desc")),
        // bLegacy (unstamped, build ≤80) appears once the server / backfill stamps it.
        expect: ["b1"],
        ordered: true,
    },
    {
        name: "actions where planId == X && userId == me orderBy date desc (my plan's timeline)",
        app: "RealRecordRepository.getHistoryItemsByPlanIdStream(ownerId: me, or null)",
        as: "alice",
        modes: ["listen"],
        build: (db) => query(collection(db, "actions"),
            where("planId", "==", "aPlan"), where("userId", "==", "alice"), orderBy("date", "desc")),
        expect: ["aLegacy", "a1"],
        ordered: true,
    },
    {
        name: "actions where planId == X && managerId == me orderBy date desc (partner's plan timeline)",
        app: "RealRecordRepository.getHistoryItemsByPlanIdStream(ownerId: partner, or null)",
        as: "alice",
        modes: ["listen"],
        build: (db) => query(collection(db, "actions"),
            where("planId", "==", "bPlan"), where("managerId", "==", "alice"), orderBy("date", "desc")),
        expect: ["b1"],
        ordered: true,
    },
    {
        name: "actions where planId == my plan && managerId == me orderBy date desc (ownerId null: the empty branch)",
        app: "RealRecordRepository.getHistoryItemsByPlanIdStream(ownerId: null) on my own plan",
        as: "alice",
        modes: ["listen"],
        build: (db) => query(collection(db, "actions"),
            where("planId", "==", "aPlan"), where("managerId", "==", "alice"), orderBy("date", "desc")),
        expect: [],
        ordered: true,
    },
    {
        name: "actions where planId == X && managerId == me && date in today orderBy date desc",
        app: "RealRecordRepository._todayDoneActionRef fallback (cheerPartner / verifyPlan)",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "actions"),
            where("planId", "==", "bPlan"), where("managerId", "==", "alice"),
            where("date", ">=", DAY1_START), where("date", "<=", DAY1_END),
            orderBy("date", "desc")),
        expect: ["b1"],
        ordered: true,
    },

    // ── relations ────────────────────────────────────────────────────────
    {
        name: "relations where (executorId == me OR managerId == me)",
        app: "getHomeCardStatesStream, RealConnectRepository.watchConnectionStatus / disconnectByUser / " +
            "deleteAllRelationsByUserId(me)",
        as: "alice",
        modes: ["get", "listen"],
        build: (db) => query(collection(db, "relations"),
            or(where("executorId", "==", "alice"), where("managerId", "==", "alice"))),
        expect: ["rAB", "rBA"],
        scopedToday: true,
    },
    {
        name: "relations where (executorId == me OR managerId == me) limit 1",
        app: "RealConnectRepository.getConnectionStatus",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "relations"),
            or(where("executorId", "==", "alice"), where("managerId", "==", "alice")), limit(1)),
        expectSize: 1,
        scopedToday: true,
    },
    {
        name: "relations where executorId == me",
        app: "RealConnectRepository.getConnections",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "relations"), where("executorId", "==", "alice")),
        expect: ["rBA"],
        scopedToday: true,
    },
    {
        name: "relations where managerId == me",
        app: "RealConnectRepository.getConnections",
        as: "alice",
        modes: ["get"],
        build: (db) => query(collection(db, "relations"), where("managerId", "==", "alice")),
        expect: ["rAB"],
        scopedToday: true,
    },
];

/** Single-document reads: who must be able to read each one. */
const DOCS = [
    {
        path: "plans/aPlan",
        app: "plans/{id} get: reportCompletion, reportSkip, cheerPartner, verifyPlan, rescue/rest, approvePlan tx",
        readers: ["alice", "bob"],
    },
    {path: "plans/bPlan", app: "the partner's plan, read by its manager", readers: ["bob", "alice"]},
    {
        path: "actions/a1",
        app: "actions/{id} get (stamped): getHistoryItem (push / proof cache), _todayDoneActionRef(lastActionId)",
        readers: ["alice", "bob"],
        scopedToday: true,
    },
    {
        path: "actions/aLegacy",
        app: "actions/{id} get (no stamp, build ≤80): the plan's manager still opens it",
        readers: ["alice", "bob"],
        scopedToday: true,
    },
    {path: "actions/bLegacy", app: "same, the other way round", readers: ["bob", "alice"], scopedToday: true},
    {
        path: "users/alice",
        app: "users/{me} get / snapshots: initializeUser, getMyProfile, watchMyProfile, getMyInviteCode",
        readers: ["alice"],
        modes: ["get", "listen"],
        // Any signed-in user may get a profile by uid (partner profiles), by design.
        signedInMayRead: true,
    },
    {
        path: "users/bob",
        app: "users/{partner} get: RealUserRepository.getUsersByIds",
        readers: ["alice"],
        signedInMayRead: true,
    },
];

const ids = (snap) => snap.docs.map((d) => d.id);

/** Resolves with the first snapshot that came from the server (a listener, like the app's streams). */
function firstServerSnapshot(target) {
    return new Promise((resolve, reject) => {
        let unsubscribe = () => {};
        const timer = setTimeout(() => {
            unsubscribe();
            reject(new Error("listener timed out"));
        }, 10000);
        unsubscribe = onSnapshot(target, {includeMetadataChanges: true}, (snap) => {
            if (snap.metadata.fromCache) return;
            clearTimeout(timer);
            unsubscribe();
            resolve(snap);
        }, (error) => {
            clearTimeout(timer);
            reject(error);
        });
    });
}

function read(target, mode) {
    if (mode === "listen") return firstServerSnapshot(target);
    return target.type === "document" ? getDoc(target) : getDocs(target);
}

describe(`client reads of build ≥81 (${RULES})`, () => {
    let testEnv;
    /** True when the loaded rules scope plans/actions/users reads to participants. */
    let narrowed;

    const strangers = () => [
        ["mallory (another couple)", testEnv.authenticatedContext("mallory").firestore()],
        ["an anonymous guest", testEnv.authenticatedContext("guest", {
            firebase: {sign_in_provider: "anonymous"},
        }).firestore()],
        ["nobody signed in", testEnv.unauthenticatedContext().firestore()],
    ];
    const signedOut = () => testEnv.unauthenticatedContext().firestore();
    const dbOf = (uid) => testEnv.authenticatedContext(uid).firestore();

    before(async () => {
        testEnv = await createTestEnv();
        await seed(testEnv);
        try {
            await getDocs(query(collection(dbOf("mallory"), "plans"), where("userId", "==", "alice")));
            narrowed = false;
        } catch (e) {
            if (e.code !== "permission-denied") throw e;
            narrowed = true;
        }
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await seed(testEnv);
    });

    it("the staged rules are the narrowed ones", () => {
        if (RULES === "firestore.rules.next") assert.equal(narrowed, true);
    });

    describe("queries", () => {
        for (const shape of QUERIES) {
            for (const mode of shape.modes) {
                it(`${shape.name} [${mode}] — ${shape.app}`, async () => {
                    const snap = await assertSucceeds(read(shape.build(dbOf(shape.as)), mode));
                    if (shape.expectSize !== undefined) {
                        assert.equal(snap.size, shape.expectSize);
                    } else if (shape.ordered) {
                        assert.deepEqual(ids(snap), shape.expect);
                    } else {
                        assert.deepEqual(ids(snap).sort(), [...shape.expect].sort());
                    }

                    if (narrowed || shape.scopedToday) {
                        for (const [who, db] of strangers()) {
                            await assertFails(read(shape.build(db), mode)).catch((e) => {
                                throw new Error(`${who}: ${e.message}`);
                            });
                        }
                    } else {
                        await assertFails(read(shape.build(signedOut()), mode));
                    }
                });
            }
        }

        it("users where inviteCode == X limit 1 — the pre-callable fallback " +
            "(RealUserRepository._userByInviteCodeDirectly, RealConnectRepository._connectWithCodeDirectly)",
        async () => {
            const lookup = (db) => getDocs(query(collection(db, "users"),
                where("inviteCode", "==", "BOBB2345"), limit(1)));
            if (narrowed) {
                // Only reached while resolveInviteCode / redeemInviteCode are not
                // deployed; the flip requires them, so the denial is expected.
                await assertFails(lookup(dbOf("alice")));
                for (const [, db] of strangers()) await assertFails(lookup(db));
            } else {
                assert.deepEqual(ids(await assertSucceeds(lookup(dbOf("alice")))), ["bob"]);
                await assertFails(lookup(signedOut()));
            }
        });
    });

    describe("single documents", () => {
        for (const d of DOCS) {
            for (const mode of d.modes || ["get"]) {
                it(`${d.path} [${mode}] — ${d.app}`, async () => {
                    for (const uid of d.readers) {
                        const snap = await assertSucceeds(read(doc(dbOf(uid), d.path), mode));
                        assert.equal(snap.exists(), true);
                    }
                    for (const [who, db] of strangers()) {
                        const signedIn = who !== "nobody signed in";
                        const mayRead = signedIn && (d.signedInMayRead || (!narrowed && !d.scopedToday));
                        if (mayRead) {
                            if (d.signedInMayRead) await assertSucceeds(read(doc(db, d.path), mode));
                            continue;
                        }
                        await assertFails(read(doc(db, d.path), mode)).catch((e) => {
                            throw new Error(`${who}: ${e.message}`);
                        });
                    }
                });
            }
        }

        it("config/app before sign-in — AppVersionGate", async () => {
            await assertSucceeds(getDoc(doc(signedOut(), "config/app")));
        });

        it("a deleted action can't be read, so _todayDoneActionRef falls back to its query", async () => {
            await assertFails(getDoc(doc(dbOf("alice"), "actions/gone")));
            await assertFails(getDoc(doc(dbOf("bob"), "actions/gone")));
        });

        it("the partner's plan stops being readable once I no longer manage it", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await updateDoc(doc(ctx.firestore(), "plans/bPlan"), {managerId: deleteField()});
            });
            const plans = await assertSucceeds(getDocs(query(collection(dbOf("alice"), "plans"),
                where("userId", "==", "bob"), where("managerId", "==", "alice"))));
            assert.equal(plans.size, 0);
            if (narrowed) await assertFails(getDoc(doc(dbOf("alice"), "plans/bPlan")));
        });
    });

    describe("read-then-write flows", () => {
        // cheerPartner / verifyPlan: plan get → today's done action (lastActionId
        // get, else the managerId query) → one batch (cheer + plan + action).
        async function cheer(db, me, planId, actionRef) {
            const batch = writeBatch(db);
            batch.set(doc(collection(db, "cheers")), {
                fromUserId: me, toUserId: "bob", planId, reactionType: "👏", createdAt: serverTimestamp(),
            });
            batch.update(doc(db, `plans/${planId}`), {
                lastCheerMessage: deleteField(),
                lastComment: deleteField(),
                lastCheerType: "👏",
                lastCheerAt: Timestamp.now(),
                lastUpdatedBy: me,
                verifiedDates: arrayUnion(Timestamp.now()),
            });
            if (actionRef) {
                batch.update(actionRef, {verifiedBy: me, verifiedAt: serverTimestamp(), reaction: "👏"});
            }
            return batch.commit();
        }

        it("인정 on the Now tab through lastActionId (stamped, then a build ≤80 unstamped record)", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                const db = ctx.firestore();
                await setDoc(doc(db, "actions/bToday"),
                    {userId: "bob", planId: "bPlan", type: "done", date: day(1)});
                await updateDoc(doc(db, "plans/bPlan"), {lastActionId: "b1"});
            });
            const db = dbOf("alice");
            const plan = await assertSucceeds(getDoc(doc(db, "plans/bPlan")));
            const ref = doc(db, `actions/${plan.data().lastActionId}`);
            await assertSucceeds(getDoc(ref));
            await assertSucceeds(cheer(db, "alice", "bPlan", ref));

            // An unstamped record of the plan opens through the plan's manager.
            const legacy = doc(db, "actions/bToday");
            await assertSucceeds(getDoc(legacy));
            await assertSucceeds(cheer(db, "alice", "bPlan", legacy));

            const mallory = dbOf("mallory");
            await assertFails(getDoc(doc(mallory, "actions/b1")));
            await assertFails(cheer(mallory, "mallory", "bPlan", doc(mallory, "actions/b1")));
        });

        it("인정 on the Now tab through the fallback query", async () => {
            const db = dbOf("alice");
            await assertSucceeds(getDoc(doc(db, "plans/bPlan")));
            const today = await assertSucceeds(getDocs(query(collection(db, "actions"),
                where("planId", "==", "bPlan"), where("managerId", "==", "alice"),
                where("date", ">=", DAY1_START), where("date", "<=", DAY1_END),
                orderBy("date", "desc"))));
            assert.deepEqual(ids(today), ["b1"]);
            await assertSucceeds(cheer(db, "alice", "bPlan", today.docs[0].ref));
        });

        it("인정 on the 기록 tab — verifyHistoryItem's transaction", async () => {
            const verify = (db, me, actionId) => runTransaction(db, async (tx) => {
                const ref = doc(db, `actions/${actionId}`);
                const snap = await tx.get(ref);
                assert.equal(snap.exists(), true);
                tx.update(ref, {verifiedBy: me, verifiedAt: serverTimestamp(), comment: "굿", reaction: "🔥"});
                const data = snap.data();
                tx.set(doc(collection(db, "cheers")), {
                    fromUserId: me, toUserId: data.userId, planId: data.planId, reactionType: "🔥",
                    createdAt: serverTimestamp(), message: "굿",
                });
                tx.update(doc(db, `plans/${data.planId}`), {
                    verifiedDates: arrayUnion(data.date), lastUpdatedBy: me,
                    lastCheerType: "🔥", lastCheerAt: Timestamp.now(), lastCheerMessage: "굿", lastComment: "굿",
                });
            });
            await assertSucceeds(verify(dbOf("bob"), "bob", "a1")); // stamped
            await assertSucceeds(verify(dbOf("bob"), "bob", "aLegacy")); // unstamped, via the plan
            await assertFails(verify(dbOf("mallory"), "mallory", "a1"));
        });

        it("approvePlan's transaction (the manager reads and updates the partner's plan)", async () => {
            const approve = (db, me) => runTransaction(db, async (tx) => {
                const ref = doc(db, "plans/bPlan");
                const snap = await tx.get(ref);
                assert.equal(snap.exists(), true);
                tx.update(ref, {state: "active", lastUpdatedBy: me});
            });
            await assertSucceeds(approve(dbOf("alice"), "alice"));
            await assertFails(approve(dbOf("mallory"), "mallory"));
        });

        it("했어 (reportCompletion) is listed for the partner at once — the action carries the stamp", async () => {
            const db = dbOf("alice");
            const plan = await assertSucceeds(getDoc(doc(db, "plans/aPlan")));
            const actionRef = doc(collection(db, "actions"));
            const batch = writeBatch(db);
            batch.update(doc(db, "plans/aPlan"), {
                completedDates: arrayUnion(day(5)), lastActionNote: "굿", lastActionId: actionRef.id,
            });
            batch.set(actionRef, {
                userId: "alice", planId: "aPlan", date: day(5), type: "done", title: "스쿼트", note: "굿",
                createdAt: serverTimestamp(), managerId: plan.data().managerId,
            });
            await assertSucceeds(batch.commit());

            const bob = dbOf("bob");
            const history = await assertSucceeds(firstServerSnapshot(query(collection(bob, "actions"),
                where("userId", "==", "alice"), where("managerId", "==", "bob"), orderBy("date", "desc"))));
            assert.deepEqual(ids(history), [actionRef.id, "a1"]);
            const timeline = await assertSucceeds(firstServerSnapshot(query(collection(bob, "actions"),
                where("planId", "==", "aPlan"), where("managerId", "==", "bob"), orderBy("date", "desc"))));
            assert.deepEqual(ids(timeline), [actionRef.id, "a1"]);
            await assertSucceeds(getDoc(doc(bob, `actions/${actionRef.id}`)));
        });

        it("a reportSkip-style add with a stale stamp is refused; the unstamped retry lands", async () => {
            // The plan's manager changed after the app read it (e.g. unlinked offline).
            const db = dbOf("alice");
            const data = {
                userId: "alice", planId: "aPlan", date: day(6), type: "skipped", title: "스쿼트",
                createdAt: serverTimestamp(),
            };
            await assertFails(setDoc(doc(collection(db, "actions")), {...data, managerId: "carol"}));
            await assertSucceeds(setDoc(doc(collection(db, "actions")), data));
        });
    });
});
