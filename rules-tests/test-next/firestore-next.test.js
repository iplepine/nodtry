// firestore.rules.next only: what the narrowed reads deny (strangers, broad
// and cross-user queries of builds ≤80) and the owner's managerId guard.
// The allowed participant shapes are in query-shapes.test.js.
const {describe, it, before, beforeEach, after} = require("node:test");
const assert = require("node:assert/strict");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {
    collection, doc, getDoc, getDocs, query, where, orderBy, limit, updateDoc, deleteField, setDoc, or,
} = require("firebase/firestore");
const {createTestEnv} = require("../test/helpers");
const {seed} = require("./fixtures");

describe("firestore.rules.next: reads only for participants", () => {
    let testEnv;

    before(async () => {
        testEnv = await createTestEnv({rulesFile: "firestore.rules.next"});
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await seed(testEnv);
    });

    const dbOf = (uid) => (uid ? testEnv.authenticatedContext(uid) : testEnv.unauthenticatedContext()).firestore();
    const fails = (q) => assertFails(getDocs(q));

    describe("users", () => {
        it("get by uid: any signed-in user; signed out: denied", async () => {
            await assertSucceeds(getDoc(doc(dbOf("mallory"), "users/alice")));
            await assertFails(getDoc(doc(dbOf(null), "users/alice")));
        });

        it("list is denied — no invite-code lookup, no enumeration", async () => {
            const users = (uid) => collection(dbOf(uid), "users");
            await fails(query(users("alice"), where("inviteCode", "==", "BOBB2345"), limit(1)));
            await fails(query(users("alice"), where("inviteCode", "==", "ALIC2345")));
            await fails(users("mallory"));
            await fails(query(users("mallory"), where("email", "==", "alice@example.com")));
            await fails(users(null));
        });

        it("writes are unchanged", async () => {
            await assertSucceeds(updateDoc(doc(dbOf("alice"), "users/alice"), {clientBuild: 81, timezone: "Asia/Seoul"}));
            await assertFails(updateDoc(doc(dbOf("bob"), "users/alice"), {displayName: "x"}));
            await assertFails(updateDoc(doc(dbOf("alice"), "users/alice"), {inviteCode: "ZZZZ2345"}));
        });
    });

    describe("plans", () => {
        it("a stranger can neither get nor query someone's plans", async () => {
            await assertFails(getDoc(doc(dbOf("mallory"), "plans/aPlan")));
            await assertFails(getDoc(doc(dbOf("mallory"), "plans/aSolo")));
            await assertFails(getDoc(doc(dbOf(null), "plans/aPlan")));
            await fails(query(collection(dbOf("mallory"), "plans"), where("userId", "==", "alice")));
            await fails(query(collection(dbOf("mallory"), "plans"), where("managerId", "==", "bob")));
            await fails(collection(dbOf("mallory"), "plans"));
        });

        it("the build ≤80 partner query (userId == partner, no managerId filter) is denied", async () => {
            await fails(query(collection(dbOf("alice"), "plans"), where("userId", "==", "bob")));
            await fails(query(collection(dbOf("alice"), "plans"), where("state", "==", "active")));
        });

        it("the partner's solo plan (not managed by me) stays private", async () => {
            await assertFails(getDoc(doc(dbOf("bob"), "plans/aSolo")));
        });

        it("after an unlink (managerId cleared) the ex-partner loses the plan", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await updateDoc(doc(ctx.firestore(), "plans/bPlan"), {managerId: deleteField()});
            });
            await assertFails(getDoc(doc(dbOf("alice"), "plans/bPlan")));
            const managed = await assertSucceeds(getDocs(query(collection(dbOf("alice"), "plans"),
                where("managerId", "==", "alice"))));
            assert.equal(managed.size, 0);
        });
    });

    describe("actions", () => {
        it("a stranger can neither get nor query someone's actions", async () => {
            for (const id of ["a1", "a2", "aLegacy"]) {
                await assertFails(getDoc(doc(dbOf("mallory"), `actions/${id}`)));
            }
            await assertFails(getDoc(doc(dbOf(null), "actions/a1")));
            await fails(query(collection(dbOf("mallory"), "actions"), where("userId", "==", "alice")));
            await fails(query(collection(dbOf("mallory"), "actions"), where("managerId", "==", "bob")));
            await fails(query(collection(dbOf("mallory"), "actions"), where("planId", "==", "aPlan")));
            await fails(collection(dbOf("mallory"), "actions"));
        });

        it("the build ≤80 queries (userId in [me, partner], planId only, userId == partner) are denied", async () => {
            const actions = collection(dbOf("alice"), "actions");
            await fails(query(actions, where("userId", "in", ["alice", "bob"]), orderBy("date", "desc")));
            await fails(query(actions, where("planId", "==", "bPlan"), orderBy("date", "desc")));
            await fails(query(actions, where("planId", "==", "aPlan"), orderBy("date", "desc")));
            await fails(query(actions, where("userId", "==", "bob"), orderBy("date", "desc")));
            await fails(query(actions, where("type", "==", "done")));
        });

        it("an OR query is allowed only when every branch is", async () => {
            const actions = collection(dbOf("alice"), "actions");
            await fails(query(actions, or(where("userId", "==", "alice"), where("userId", "==", "bob"))));
        });

        it("a manager lists only the partner's actions stamped for them", async () => {
            // bob manages aPlan only; aSolo's action has neither a stamp nor a manager.
            await assertFails(getDoc(doc(dbOf("bob"), "actions/a2")));
            await fails(query(collection(dbOf("bob"), "actions"), where("userId", "==", "alice")));
            const listed = await assertSucceeds(getDocs(query(collection(dbOf("bob"), "actions"),
                where("userId", "==", "alice"), where("managerId", "==", "bob"))));
            assert.deepEqual(listed.docs.map((d) => d.id), ["a1"]);
        });

        it("a legacy action of a plan whose owner is someone else gets no manager access", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                await setDoc(doc(ctx.firestore(), "actions/injected"), {userId: "mallory", planId: "aPlan", type: "done"});
            });
            await assertFails(getDoc(doc(dbOf("bob"), "actions/injected")));
        });

        it("after an unlink (managerId cleared on plan and actions) the ex-partner loses them", async () => {
            await testEnv.withSecurityRulesDisabled(async (ctx) => {
                const db = ctx.firestore();
                await updateDoc(doc(db, "plans/bPlan"), {managerId: deleteField()});
                await updateDoc(doc(db, "actions/b1"), {managerId: deleteField()});
            });
            await assertFails(getDoc(doc(dbOf("alice"), "actions/b1")));
            await assertFails(getDoc(doc(dbOf("alice"), "actions/bLegacy")));
            const listed = await assertSucceeds(getDocs(query(collection(dbOf("alice"), "actions"),
                where("userId", "==", "bob"), where("managerId", "==", "alice"))));
            assert.equal(listed.size, 0);
        });
    });

    describe("actions: managerId writes", () => {
        it("the owner may keep, drop, or re-sync managerId to the plan's manager — nothing else", async () => {
            const ref = (uid, id) => doc(dbOf(uid), `actions/${id}`);
            await assertFails(updateDoc(ref("alice", "aLegacy"), {managerId: "mallory"}));
            await assertFails(updateDoc(ref("alice", "a2"), {managerId: "bob"})); // aSolo has no manager
            await assertSucceeds(updateDoc(ref("alice", "aLegacy"), {managerId: "bob"}));
            await assertSucceeds(updateDoc(ref("alice", "a1"), {note: "굿", managerId: "bob"}));
            await assertSucceeds(updateDoc(ref("alice", "a1"), {managerId: deleteField()}));
        });

        it("the manager can't touch managerId", async () => {
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/a1"), {managerId: deleteField()}));
            await assertFails(updateDoc(doc(dbOf("bob"), "actions/aLegacy"), {managerId: "bob"}));
            await assertSucceeds(updateDoc(doc(dbOf("bob"), "actions/aLegacy"), {reaction: "🔥"}));
        });
    });

    describe("relations and cheers", () => {
        it("only participants read relations", async () => {
            await assertFails(getDoc(doc(dbOf("alice"), "relations/rMC")));
            await fails(collection(dbOf("alice"), "relations"));
            await fails(query(collection(dbOf("alice"), "relations"), where("managerId", "==", "mallory")));
            await fails(query(collection(dbOf(null), "relations"), where("managerId", "==", "alice")));
        });

        it("only the sender and the recipient read cheers", async () => {
            await assertFails(getDoc(doc(dbOf("alice"), "cheers/cMC")));
            await assertFails(getDoc(doc(dbOf("mallory"), "cheers/cBA")));
            await fails(collection(dbOf("alice"), "cheers"));
            await fails(query(collection(dbOf("alice"), "cheers"), where("toUserId", "==", "carol")));
            await fails(query(collection(dbOf("alice"), "cheers"), where("planId", "==", "aPlan")));
        });
    });
});
