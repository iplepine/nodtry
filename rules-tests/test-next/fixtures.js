// Shared data for the participant-scoped query tests.
//
//   alice ⇄ bob      linked pair (alice manages bob's bPlan, bob manages aPlan)
//   mallory ⇄ carol  another pair; to alice and bob they are strangers
//
// Actions carry the denormalized `managerId` (stamped by the app or the
// server) except the *Legacy ones, written by builds ≤80 before the backfill.
const {doc, setDoc, Timestamp} = require("firebase/firestore");

const day = (n) => Timestamp.fromMillis(Date.UTC(2026, 9, n, 3));

async function seed(testEnv) {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
        const db = ctx.firestore();
        const put = (path, data) => setDoc(doc(db, path), data);
        await put("config/app", {minBuild: 1, latestBuild: 81});

        await put("users/alice", {displayName: "Alice", inviteCode: "ALIC2345", email: "alice@example.com"});
        await put("users/bob", {displayName: "Bob", inviteCode: "BOBB2345", email: "bob@example.com"});
        await put("users/mallory", {displayName: "Mallory", inviteCode: "MALL2345"});
        await put("users/carol", {displayName: "Carol", inviteCode: "CARO2345"});

        await put("plans/aPlan", {userId: "alice", managerId: "bob", state: "active"});
        await put("plans/aSolo", {userId: "alice", state: "active"});
        await put("plans/bPlan", {userId: "bob", managerId: "alice", state: "active"});
        await put("plans/mPlan", {userId: "mallory", managerId: "carol", state: "active"});

        await put("actions/a1", {userId: "alice", planId: "aPlan", managerId: "bob", type: "done", date: day(1)});
        await put("actions/a2", {userId: "alice", planId: "aSolo", type: "done", date: day(2)});
        await put("actions/aLegacy", {userId: "alice", planId: "aPlan", type: "done", date: day(3)});
        await put("actions/b1", {userId: "bob", planId: "bPlan", managerId: "alice", type: "done", date: day(1)});
        await put("actions/bLegacy", {userId: "bob", planId: "bPlan", type: "skipped", date: day(2)});
        await put("actions/m1", {userId: "mallory", planId: "mPlan", managerId: "carol", type: "done", date: day(1)});

        await put("relations/rAB", {managerId: "alice", executorId: "bob", status: "active"});
        await put("relations/rBA", {managerId: "bob", executorId: "alice", status: "active"});
        await put("relations/rMC", {managerId: "mallory", executorId: "carol", status: "active"});
        await put("relations/rCM", {managerId: "carol", executorId: "mallory", status: "active"});

        await put("cheers/cBA", {fromUserId: "bob", toUserId: "alice", reactionType: "poke", planId: "aPlan"});
        await put("cheers/cAB", {fromUserId: "alice", toUserId: "bob", reactionType: "reply", planId: "aPlan"});
        await put("cheers/cMC", {fromUserId: "mallory", toUserId: "carol", reactionType: "poke"});
    });
}

module.exports = {seed, day};
