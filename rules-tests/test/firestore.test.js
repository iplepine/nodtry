// firestore.rules — config, invite-code links (relations), server-owned
// fields, and the pivot's new optional fields. Every case here must also hold
// under firestore.rules.next (`npm run test:next` runs this file against it):
// the staged rules narrow reads, never writes.
const {describe, it, before, beforeEach, after} = require("node:test");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {
    doc, getDoc, setDoc, updateDoc, deleteDoc, addDoc, collection, serverTimestamp, writeBatch, deleteField,
    Timestamp,
} = require("firebase/firestore");
const {createTestEnv} = require("./helpers");

describe("firestore.rules", () => {
    let testEnv;

    before(async () => {
        testEnv = await createTestEnv();
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await testEnv.clearFirestore();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            const db = ctx.firestore();
            await setDoc(doc(db, "config/app"), {minBuild: 1, latestBuild: 81});
            await setDoc(doc(db, "users/alice"), {displayName: "Alice", inviteCode: "ABCD2345"});
            await setDoc(doc(db, "users/bob"), {displayName: "Bob", inviteCode: "BOBB2345"});
            await setDoc(doc(db, "users/nocode"), {displayName: "No code"});
            await setDoc(doc(db, "plans/planA"), {userId: "alice", managerId: "bob", state: "active"});
            await setDoc(doc(db, "actions/act1"), {userId: "alice", planId: "planA", type: "done"});
            await setDoc(doc(db, "serverLocks/poke_planA_2026-10-02"), {at: 1});
        });
    });

    const dbOf = (uid) => (uid ? testEnv.authenticatedContext(uid) : testEnv.unauthenticatedContext()).firestore();

    describe("config/{doc}", () => {
        it("is readable by anyone, signed in or not", async () => {
            await assertSucceeds(getDoc(doc(dbOf(null), "config/app")));
            await assertSucceeds(getDoc(doc(dbOf("alice"), "config/app")));
        });

        it("is not writable by clients", async () => {
            await assertFails(setDoc(doc(dbOf("alice"), "config/app"), {minBuild: 999}));
            await assertFails(updateDoc(doc(dbOf("alice"), "config/app"), {minBuild: 999}));
            await assertFails(deleteDoc(doc(dbOf("alice"), "config/app")));
            await assertFails(setDoc(doc(dbOf("alice"), "config/other"), {x: 1}));
            await assertFails(setDoc(doc(dbOf(null), "config/app"), {minBuild: 999}));
        });
    });

    describe("server-only collections", () => {
        it("serverLocks is closed to clients", async () => {
            await assertFails(getDoc(doc(dbOf("alice"), "serverLocks/poke_planA_2026-10-02")));
            await assertFails(setDoc(doc(dbOf("alice"), "serverLocks/x"), {at: 1}));
        });
    });

    describe("actions", () => {
        it("the owner can create an action carrying a proof photo path", async () => {
            await assertSucceeds(setDoc(doc(dbOf("alice"), "actions/act2"), {
                userId: "alice",
                planId: "planA",
                type: "done",
                proofPhotoPath: "proofs/alice/planA/act2.jpg",
                proofSource: "camera",
                proofTakenAt: serverTimestamp(),
            }));
        });

        it("the plan's manager can 인정 with a reaction", async () => {
            await assertSucceeds(updateDoc(doc(dbOf("bob"), "actions/act1"), {
                verifiedBy: "bob",
                verifiedAt: serverTimestamp(),
                reaction: "🔥",
                partnerMessage: "멋져",
            }));
        });

        it("someone who is not the manager cannot react", async () => {
            await assertFails(updateDoc(doc(dbOf("mallory"), "actions/act1"), {reaction: "🔥"}));
        });
    });

    describe("plans", () => {
        it("owner can store workoutType and the last-proof pointers", async () => {
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "plans/planA"), {
                workoutType: "running",
                lastActionId: "act1",
                lastProofPhotoPath: "proofs/alice/planA/act1.jpg",
                lastProofAt: serverTimestamp(),
                lastUpdatedBy: "alice",
            }));
        });
    });

    describe("cheers", () => {
        it("a poke reply can be created by its sender only", async () => {
            const reply = {
                fromUserId: "alice", toUserId: "bob", planId: "planA",
                reactionType: "reply", message: "지금 간다 🏃", createdAt: serverTimestamp(),
            };
            await assertSucceeds(addDoc(collection(dbOf("alice"), "cheers"), reply));
            await assertFails(addDoc(collection(dbOf("mallory"), "cheers"), reply));
        });
    });

    describe("users", () => {
        it("a user can write the new profile fields on her own doc only", async () => {
            const fields = {clientBuild: 81, timezone: "Asia/Seoul", locale: "ko", partnerNickname: "자기"};
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "users/alice"), fields));
            await assertFails(updateDoc(doc(dbOf("bob"), "users/alice"), fields));
        });
    });
    describe("users: invite codes and private data", () => {
        it("the invite code can't be changed or dropped once issued", async () => {
            await assertFails(updateDoc(doc(dbOf("alice"), "users/alice"), {inviteCode: "BOBB2345"}));
            await assertFails(updateDoc(doc(dbOf("alice"), "users/alice"), {inviteCode: deleteField()}));
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "users/alice"), {inviteCode: "ABCD2345", locale: "ko"}));
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "users/alice"), {fcmToken: "t", displayName: "A"}));
        });

        it("a missing code can be backfilled once", async () => {
            await assertSucceeds(updateDoc(doc(dbOf("nocode"), "users/nocode"), {inviteCode: "NEWC2345"}));
            await assertFails(updateDoc(doc(dbOf("nocode"), "users/nocode"), {inviteCode: "NEWD2345"}));
        });

        it("users/{uid}/private is owner-only", async () => {
            const ref = (uid) => doc(dbOf(uid), "users/alice/private/messaging");
            await assertSucceeds(setDoc(ref("alice"), {fcmToken: "t"}));
            await assertSucceeds(getDoc(ref("alice")));
            await assertFails(getDoc(ref("bob")));
            await assertFails(setDoc(ref("bob"), {fcmToken: "x"}));
            await assertFails(getDoc(ref(null)));
        });
    });

    describe("relations (짝꿍 links)", () => {
        const pair = (writerDb, inviter, enterer, extra = {}) => {
            const batch = writeBatch(writerDb);
            const base = {status: "active", createdAt: serverTimestamp(), connectedAt: serverTimestamp(), ...extra};
            batch.set(doc(collection(writerDb, "relations")), {managerId: inviter, executorId: enterer, ...base});
            batch.set(doc(collection(writerDb, "relations")), {managerId: enterer, executorId: inviter, ...base});
            return batch.commit();
        };
        const stamp = (code) => ({inviterId: "alice", inviteCode: code});

        it("the person who entered the owner's current code can link", async () => {
            await assertSucceeds(pair(dbOf("bob"), "alice", "bob", stamp("ABCD2345")));
        });

        it("a stale or wrong code is refused", async () => {
            await assertFails(pair(dbOf("bob"), "alice", "bob", stamp("ZZZZ2345")));
            await assertFails(pair(dbOf("bob"), "alice", "bob", stamp("abcd2345")));
        });

        it("the code owner can't link someone else in (writer must be the code enterer)", async () => {
            // mallory stamps herself as inviter with her own code.
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "users/mallory"), {inviteCode: "MALL2345"});
            });
            await assertFails(pair(dbOf("mallory"), "mallory", "alice", {inviterId: "mallory", inviteCode: "MALL2345"}));
        });

        it("the stamp must name the other participant", async () => {
            await assertFails(pair(dbOf("bob"), "alice", "bob", {inviterId: "carol", inviteCode: "ABCD2345"}));
            await assertFails(pair(dbOf("bob"), "alice", "bob", {inviterId: "alice"}));
            await assertFails(pair(dbOf("bob"), "alice", "bob", {inviteCode: "ABCD2345"}));
        });

        it("unstamped (pre-둘운완) links are refused unless the legacy window is open", async () => {
            await assertFails(pair(dbOf("bob"), "alice", "bob"));
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await updateDoc(doc(ctx.firestore(), "config/app"), {
                    legacyLinkUntil: Timestamp.fromMillis(Date.now() - 60000),
                });
            });
            await assertFails(pair(dbOf("bob"), "alice", "bob"));
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await updateDoc(doc(ctx.firestore(), "config/app"), {
                    legacyLinkUntil: Timestamp.fromMillis(Date.now() + 3600000),
                });
            });
            await assertSucceeds(pair(dbOf("bob"), "alice", "bob"));
        });

        it("outsiders, self-links, forged createdBy and client timestamps are refused", async () => {
            await assertFails(pair(dbOf("mallory"), "alice", "bob", stamp("ABCD2345")));
            await assertFails(pair(dbOf(null), "alice", "bob", stamp("ABCD2345")));
            await assertFails(setDoc(doc(dbOf("alice"), "relations/self"), {
                managerId: "alice", executorId: "alice", ...stamp("ABCD2345"), createdAt: serverTimestamp(),
            }));
            await assertFails(pair(dbOf("bob"), "alice", "bob", {...stamp("ABCD2345"), createdBy: "alice"}));
            await assertSucceeds(pair(dbOf("bob"), "alice", "bob", {...stamp("ABCD2345"), createdBy: "bob"}));
            await assertFails(setDoc(doc(dbOf("bob"), "relations/backdated"), {
                managerId: "alice", executorId: "bob", ...stamp("ABCD2345"), createdAt: Timestamp.fromMillis(1),
            }));
        });

        it("relations are never edited; participants may delete", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "relations/r1"), {managerId: "alice", executorId: "bob"});
            });
            await assertFails(updateDoc(doc(dbOf("alice"), "relations/r1"), {executorId: "alice"}));
            await assertFails(updateDoc(doc(dbOf("alice"), "relations/r1"), {executorId: "carol"}));
            await assertFails(updateDoc(doc(dbOf("bob"), "relations/r1"), {status: "x"}));
            await assertFails(deleteDoc(doc(dbOf("mallory"), "relations/r1")));
            await assertSucceeds(getDoc(doc(dbOf("bob"), "relations/r1")));
            await assertSucceeds(deleteDoc(doc(dbOf("bob"), "relations/r1")));
        });
    });

    describe("plans: server-owned manager fields", () => {
        it("clients can't write managerSince / managerSinceUid", async () => {
            await assertFails(setDoc(doc(dbOf("alice"), "plans/new1"), {
                userId: "alice", managerId: "bob", state: "active", managerSince: Timestamp.fromMillis(0),
            }));
            await assertFails(setDoc(doc(dbOf("alice"), "plans/new2"), {
                userId: "alice", state: "active", managerSinceUid: "bob",
            }));
            await assertSucceeds(setDoc(doc(dbOf("alice"), "plans/new3"), {
                userId: "alice", managerId: "bob", state: "active",
            }));
            await assertFails(updateDoc(doc(dbOf("bob"), "plans/planA"), {managerSince: Timestamp.fromMillis(0)}));
            await assertFails(updateDoc(doc(dbOf("alice"), "plans/planA"), {managerSinceUid: "bob"}));
        });

        it("ordinary updates still work on a stamped plan", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await updateDoc(doc(ctx.firestore(), "plans/planA"), {
                    managerSince: Timestamp.fromMillis(Date.now() - 1000), managerSinceUid: "bob",
                });
            });
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "plans/planA"), {
                completedDates: [Timestamp.now()], lastUpdatedBy: "alice",
            }));
            await assertSucceeds(updateDoc(doc(dbOf("bob"), "plans/planA"), {
                verifiedDates: [Timestamp.now()], lastUpdatedBy: "bob",
            }));
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "plans/planA"), {managerId: deleteField()}));
        });
    });

    describe("actions: owner's own plan, manager 인정 only", () => {
        it("actions can only be added to the writer's own plan", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "plans/planB"), {userId: "bob", state: "active"});
            });
            const action = (userId, planId) => ({userId, planId, type: "done", note: "x"});
            await assertSucceeds(addDoc(collection(dbOf("alice"), "actions"), action("alice", "planA")));
            await assertFails(addDoc(collection(dbOf("mallory"), "actions"), action("mallory", "planA")));
            await assertFails(addDoc(collection(dbOf("alice"), "actions"), action("alice", "planB")));
            await assertFails(addDoc(collection(dbOf("alice"), "actions"), action("alice", "missing")));
            await assertFails(addDoc(collection(dbOf("alice"), "actions"), {userId: "alice", type: "done"}));
        });

        it("the owner can't move an action to another plan or owner", async () => {
            await assertFails(updateDoc(doc(dbOf("alice"), "actions/act1"), {planId: "planB"}));
            await assertFails(updateDoc(doc(dbOf("alice"), "actions/act1"), {userId: "bob"}));
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "actions/act1"), {
                type: "skipped", isReconciled: true, reconciledAt: serverTimestamp(),
            }));
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "actions/act1"), {
                proofPhotoPath: deleteField(), proofSource: deleteField(), proofTakenAt: deleteField(),
            }));
        });

        it("the manager may only add 인정 fields", async () => {
            await assertSucceeds(updateDoc(doc(dbOf("bob"), "actions/act1"), {
                verifiedBy: "bob", verifiedAt: serverTimestamp(), comment: "굿",
            }));
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/act1"), {type: "skipped"}));
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/act1"), {note: "바꿈"}));
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/act1"), {proofPhotoPath: "proofs/bob/x/y.jpg"}));
        });

        it("a managerId written on create must be the plan's manager (absent is fine)", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "plans/solo"), {userId: "alice", state: "active"});
            });
            const action = (planId, extra) => ({userId: "alice", planId, type: "done", ...extra});
            const add = (data) => addDoc(collection(dbOf("alice"), "actions"), data);
            await assertSucceeds(add(action("planA", {managerId: "bob"})));
            await assertSucceeds(add(action("planA", {})));
            await assertSucceeds(add(action("solo", {})));
            await assertFails(add(action("planA", {managerId: "mallory"})));
            await assertFails(add(action("planA", {managerId: "alice"})));
            await assertFails(add(action("solo", {managerId: "bob"})));
            // Like the proof batch: plan pointer + action in one commit.
            const db = dbOf("alice");
            const batch = writeBatch(db);
            batch.update(doc(db, "plans/planA"), {lastActionId: "act9", lastUpdatedBy: "alice"});
            batch.set(doc(db, "actions/act9"), action("planA", {managerId: "bob"}));
            await assertSucceeds(batch.commit());
        });

        it("an action whose owner is not the plan's owner gets no manager access", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "actions/injected"), {userId: "mallory", planId: "planA", type: "done"});
            });
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/injected"), {reaction: "🔥"}));
            await assertFails(getDoc(doc(dbOf("bob"), "actions/injected")));
        });
    });
});
