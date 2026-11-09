// firestore.rules — invites/{inviterUid} (invite re-engagement). Runs against
// firestore.rules.next too (`npm run test:next`): the rules are the same.
const {describe, it, before, beforeEach, after} = require("node:test");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {
    doc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, collection, query, where, serverTimestamp, increment,
    Timestamp,
} = require("firebase/firestore");
const {createTestEnv} = require("./helpers");

describe("firestore.rules: invites", () => {
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
            await setDoc(doc(db, "users/alice"), {displayName: "Alice", inviteCode: "ABCD2345"});
            await setDoc(doc(db, "users/bob"), {displayName: "Bob", inviteCode: "BOBB2345"});
            await setDoc(doc(db, "invites/bob"), {
                inviterUid: "bob",
                code: "BOBB2345",
                createdAt: Timestamp.fromMillis(1000),
                lastSharedAt: Timestamp.fromMillis(1000),
                shareCount: 1,
                remindersSent: 1,
                remindersCycleAt: Timestamp.fromMillis(1000),
            });
        });
    });

    const dbOf = (uid) => (uid ? testEnv.authenticatedContext(uid) : testEnv.unauthenticatedContext()).firestore();

    const firstShare = (uid, extra = {}) => ({
        inviterUid: uid,
        code: "ABCD2345",
        createdAt: serverTimestamp(),
        lastSharedAt: serverTimestamp(),
        shareCount: 1,
        ...extra,
    });

    const reshare = (extra = {}) => ({
        code: "BOBB2345",
        lastSharedAt: serverTimestamp(),
        shareCount: increment(1),
        ...extra,
    });

    it("the inviter creates their own doc with server timestamps", async () => {
        await assertSucceeds(setDoc(doc(dbOf("alice"), "invites/alice"), firstShare("alice")));
    });

    it("nobody creates someone else's doc, or one without signing in", async () => {
        await assertFails(setDoc(doc(dbOf("alice"), "invites/carol"), firstShare("carol")));
        await assertFails(setDoc(doc(dbOf("alice"), "invites/carol"), firstShare("alice")));
        await assertFails(setDoc(doc(dbOf(null), "invites/alice"), firstShare("alice")));
    });

    it("create: whitelisted fields and types only", async () => {
        const ref = doc(dbOf("alice"), "invites/alice");
        await assertFails(setDoc(ref, firstShare("alice", {remindersSent: 0})));
        await assertFails(setDoc(ref, firstShare("alice", {connectedAt: serverTimestamp()})));
        await assertFails(setDoc(ref, firstShare("alice", {extra: true})));
        await assertFails(setDoc(ref, firstShare("alice", {lastSharedAt: Timestamp.fromMillis(1000)})));
        await assertFails(setDoc(ref, firstShare("alice", {createdAt: Timestamp.fromMillis(1000)})));
        await assertFails(setDoc(ref, firstShare("alice", {shareCount: 5})));
        await assertFails(setDoc(ref, firstShare("alice", {code: 42})));
        await assertFails(setDoc(ref, firstShare("alice", {code: "x".repeat(40)})));
    });

    it("the inviter re-shares: code, lastSharedAt and shareCount + 1", async () => {
        await assertSucceeds(updateDoc(doc(dbOf("bob"), "invites/bob"), reshare()));
    });

    it("update: no server-only fields, no backdating, no count jumps", async () => {
        const ref = doc(dbOf("bob"), "invites/bob");
        await assertFails(updateDoc(ref, reshare({remindersSent: 0})));
        await assertFails(updateDoc(ref, reshare({remindersCycleAt: null})));
        await assertFails(updateDoc(ref, reshare({connectedAt: serverTimestamp()})));
        await assertFails(updateDoc(ref, reshare({createdAt: serverTimestamp()})));
        await assertFails(updateDoc(ref, reshare({inviterUid: "alice"})));
        await assertFails(updateDoc(ref, reshare({lastSharedAt: Timestamp.fromMillis(5000)})));
        await assertFails(updateDoc(ref, reshare({shareCount: 10})));
        await assertFails(updateDoc(doc(dbOf("alice"), "invites/bob"), reshare()));
    });

    it("only the inviter reads their doc; nobody lists or deletes", async () => {
        await assertSucceeds(getDoc(doc(dbOf("bob"), "invites/bob")));
        await assertFails(getDoc(doc(dbOf("alice"), "invites/bob")));
        await assertFails(getDoc(doc(dbOf(null), "invites/bob")));
        await assertFails(getDocs(query(collection(dbOf("bob"), "invites"), where("inviterUid", "==", "bob"))));
        await assertFails(deleteDoc(doc(dbOf("bob"), "invites/bob")));
    });
});
