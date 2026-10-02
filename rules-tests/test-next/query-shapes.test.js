// The participant-scoped reads build ≥81 uses (contract with the app).
// Every shape here must be allowed — with the expected results — under BOTH
// firestore.rules (deployed; `npm test`) and firestore.rules.next (`npm run
// test:next`), so build 81 works before and after the flip.
// The denials that only rules.next adds live in firestore-next.test.js.
const {describe, it, before, beforeEach, after} = require("node:test");
const assert = require("node:assert/strict");
const {assertSucceeds} = require("@firebase/rules-unit-testing");
const {collection, doc, getDoc, getDocs, query, where, orderBy, or} = require("firebase/firestore");
const {createTestEnv, firestoreRulesFile} = require("../test/helpers");
const {seed, day} = require("./fixtures");

const ids = (snap) => snap.docs.map((d) => d.id).sort();

describe(`participant query shapes (${firestoreRulesFile()})`, () => {
    let testEnv;

    before(async () => {
        testEnv = await createTestEnv();
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await seed(testEnv);
    });

    const dbOf = (uid) => testEnv.authenticatedContext(uid).firestore();
    const run = async (q) => assertSucceeds(getDocs(q));

    describe("plans", () => {
        it("plans where userId == me", async () => {
            const db = dbOf("alice");
            assert.deepEqual(ids(await run(query(collection(db, "plans"), where("userId", "==", "alice")))),
                ["aPlan", "aSolo"]);
        });

        it("plans where managerId == me", async () => {
            const db = dbOf("alice");
            assert.deepEqual(ids(await run(query(collection(db, "plans"), where("managerId", "==", "alice")))),
                ["bPlan"]);
        });

        it("plans where userId == partner && managerId == me", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "plans"), where("userId", "==", "bob"), where("managerId", "==", "alice"));
            assert.deepEqual(ids(await run(q)), ["bPlan"]);
        });

        it("plans where (userId == me || managerId == me) — the home stream's OR query", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "plans"),
                or(where("userId", "==", "alice"), where("managerId", "==", "alice")));
            assert.deepEqual(ids(await run(q)), ["aPlan", "aSolo", "bPlan"]);
        });

        it("get one plan as its owner or its manager", async () => {
            await assertSucceeds(getDoc(doc(dbOf("alice"), "plans/aPlan")));
            await assertSucceeds(getDoc(doc(dbOf("alice"), "plans/bPlan")));
            await assertSucceeds(getDoc(doc(dbOf("bob"), "plans/aPlan")));
        });
    });

    describe("actions", () => {
        it("actions where userId == me (orderBy date)", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "actions"), where("userId", "==", "alice"), orderBy("date", "desc"));
            assert.deepEqual(ids(await run(q)), ["a1", "a2", "aLegacy"]);
        });

        it("actions where userId == partner && managerId == me (orderBy date)", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "actions"),
                where("userId", "==", "bob"), where("managerId", "==", "alice"), orderBy("date", "desc"));
            // bLegacy has no stamp yet: it shows up once backfill_action_manager_ids ran.
            assert.deepEqual(ids(await run(q)), ["b1"]);
        });

        it("actions where planId == X && managerId == me (partner's plan timeline)", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "actions"),
                where("planId", "==", "bPlan"), where("managerId", "==", "alice"), orderBy("date", "desc"));
            assert.deepEqual(ids(await run(q)), ["b1"]);
        });

        it("actions where planId == X && userId == me (own plan timeline, today's record)", async () => {
            const db = dbOf("alice");
            const timeline = query(collection(db, "actions"),
                where("planId", "==", "aPlan"), where("userId", "==", "alice"), orderBy("date", "desc"));
            assert.deepEqual(ids(await run(timeline)), ["a1", "aLegacy"]);
            const today = query(collection(db, "actions"),
                where("planId", "==", "aPlan"), where("userId", "==", "alice"),
                where("date", ">=", day(3)), where("date", "<=", day(4)));
            assert.deepEqual(ids(await run(today)), ["aLegacy"]);
        });

        it("actions where managerId == me (everything my partner shared with me)", async () => {
            const db = dbOf("alice");
            assert.deepEqual(ids(await run(query(collection(db, "actions"), where("managerId", "==", "alice")))),
                ["b1"]);
        });

        it("actions where (userId == me || managerId == me) — both sides of the history", async () => {
            const db = dbOf("alice");
            const q = query(collection(db, "actions"),
                or(where("userId", "==", "alice"), where("managerId", "==", "alice")));
            assert.deepEqual(ids(await run(q)), ["a1", "a2", "aLegacy", "b1"]);
        });

        it("get one action: owner, stamped manager, and the plan's manager for a legacy action", async () => {
            await assertSucceeds(getDoc(doc(dbOf("alice"), "actions/a1")));
            await assertSucceeds(getDoc(doc(dbOf("alice"), "actions/b1")));
            await assertSucceeds(getDoc(doc(dbOf("alice"), "actions/bLegacy")));
            await assertSucceeds(getDoc(doc(dbOf("bob"), "actions/aLegacy")));
        });
    });

    describe("relations, cheers, users, config", () => {
        it("relations where executorId == me / managerId == me / either", async () => {
            const db = dbOf("alice");
            const rel = collection(db, "relations");
            assert.deepEqual(ids(await run(query(rel, where("executorId", "==", "alice")))), ["rBA"]);
            assert.deepEqual(ids(await run(query(rel, where("managerId", "==", "alice")))), ["rAB"]);
            assert.deepEqual(ids(await run(query(rel,
                or(where("executorId", "==", "alice"), where("managerId", "==", "alice"))))), ["rAB", "rBA"]);
        });

        it("cheers where toUserId == me / fromUserId == me", async () => {
            const db = dbOf("alice");
            const cheers = collection(db, "cheers");
            assert.deepEqual(ids(await run(query(cheers, where("toUserId", "==", "alice")))), ["cBA"]);
            assert.deepEqual(ids(await run(query(cheers, where("fromUserId", "==", "alice")))), ["cAB"]);
            await assertSucceeds(getDoc(doc(db, "cheers/cBA")));
        });

        it("a partner's profile by uid, and config/app before sign-in", async () => {
            await assertSucceeds(getDoc(doc(dbOf("alice"), "users/bob")));
            await assertSucceeds(getDoc(doc(dbOf("alice"), "users/alice")));
            await assertSucceeds(getDoc(doc(testEnv.unauthenticatedContext().firestore(), "config/app")));
        });
    });
});
