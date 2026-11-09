// "같이 했어" — one log (and at most one proof photo) covers both partners.
// No rules change: these pin down that the existing firestore.rules (and
// firestore.rules.next) and storage.rules already allow exactly the shared
// flow, and nothing more.
// Run: firebase emulators:exec --only firestore,storage --project demo-duounwan "npm test"
//      (and "npm run test:next" against firestore.rules.next)
const {describe, it, before, beforeEach, after} = require("node:test");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {doc, getDoc, setDoc, updateDoc, deleteField, arrayUnion, Timestamp, serverTimestamp} = require("firebase/firestore");
const {ref, uploadBytes, getBytes, deleteObject} = require("firebase/storage");
const {randomUUID} = require("node:crypto");
const {createTestEnv, bytes} = require("./helpers");

const JPEG = {contentType: "image/jpeg"};

describe("같이 했어 (shared log + shared proof photo)", () => {
    let testEnv;
    let SOURCE = "";
    let ALICE_PROOF = "";

    before(async () => {
        testEnv = await createTestEnv();
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        SOURCE = `a_${randomUUID()}`;
        ALICE_PROOF = `proofs/alice/planA/${SOURCE}.jpg`;
        await testEnv.clearFirestore();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            const db = ctx.firestore();
            const since = Timestamp.fromMillis(Date.now() - 60 * 60 * 1000);
            // The couple manage each other's plan (stamped by the server).
            await setDoc(doc(db, "plans/planA"), {
                userId: "alice", managerId: "bob", state: "active",
                managerSince: since, managerSinceUid: "bob", completedDates: [],
            });
            await setDoc(doc(db, "plans/planB"), {
                userId: "bob", managerId: "alice", state: "active",
                managerSince: since, managerSinceUid: "alice", completedDates: [],
            });
        });
    });

    const dbOf = (uid) => testEnv.authenticatedContext(uid).firestore();
    const storageOf = (uid) => testEnv.authenticatedContext(uid).storage();

    /** Alice logs "같이 했어" with a photo: object, action, plan mark. */
    async function aliceLogsTogether() {
        await assertSucceeds(uploadBytes(ref(storageOf("alice"), ALICE_PROOF), bytes(1024), JPEG));
        await assertSucceeds(setDoc(doc(dbOf("alice"), `actions/${SOURCE}`), {
            userId: "alice", planId: "planA", type: "done", title: "헬스", note: null,
            date: Timestamp.now(), createdAt: serverTimestamp(), managerId: "bob",
            proofPhotoPath: ALICE_PROOF, proofSource: "camera",
            togetherWithUid: "bob", togetherPartnerPlanId: "planB",
        }));
        await assertSucceeds(updateDoc(doc(dbOf("alice"), "plans/planA"), {
            completedDates: arrayUnion(Timestamp.now()),
            lastActionId: SOURCE,
            lastProofPhotoPath: ALICE_PROOF,
            lastProofAt: Timestamp.now(),
            lastTogether: {actionId: SOURCE, withUid: "bob", planId: "planB", at: Timestamp.now()},
        }));
    }

    /** Bob's 나도 했어: his own done on his plan, pointing at Alice's photo. */
    function bobConfirmation(extra = {}) {
        return {
            userId: "bob", planId: "planB", type: "done", title: "헬스", note: null,
            date: Timestamp.now(), createdAt: serverTimestamp(), managerId: "alice",
            proofPhotoPath: ALICE_PROOF, proofSource: "camera",
            sharedProofFromUid: "alice", togetherActionId: SOURCE,
            ...extra,
        };
    }

    it("the logger can tag her own record and mark her plan", async () => {
        await aliceLogsTogether();
    });

    it("the partner reads the claim as the manager of her plan", async () => {
        await aliceLogsTogether();
        await assertSucceeds(getDoc(doc(dbOf("bob"), `actions/${SOURCE}`)));
        await assertSucceeds(getDoc(doc(dbOf("bob"), "plans/planA")));
        // A stranger can't (single-doc get is participant-scoped in both rule sets).
        await assertFails(getDoc(doc(dbOf("mallory"), `actions/${SOURCE}`)));
    });

    it("nobody can log for the partner: only their own tap writes their record", async () => {
        await aliceLogsTogether();
        // Alice can't write Bob's record, nor a record of hers into his plan.
        await assertFails(setDoc(doc(dbOf("alice"), "actions/forged"), bobConfirmation()));
        await assertFails(setDoc(doc(dbOf("alice"), "actions/forged2"), {...bobConfirmation(), userId: "alice"}));
        // As his plan's manager she may only add 인정 to Bob's records, never
        // turn one into a shared record.
        await assertSucceeds(setDoc(doc(dbOf("bob"), "actions/b0"), {
            userId: "bob", planId: "planB", type: "done", date: Timestamp.now(), managerId: "alice",
        }));
        await assertFails(updateDoc(doc(dbOf("alice"), "actions/b0"), {
            proofPhotoPath: ALICE_PROOF, sharedProofFromUid: "alice",
        }));
    });

    it("나도 했어: the partner's own record may point at the logger's photo", async () => {
        await aliceLogsTogether();
        await assertSucceeds(setDoc(doc(dbOf("bob"), "actions/b1"), bobConfirmation()));
        await assertSucceeds(updateDoc(doc(dbOf("bob"), "plans/planB"), {
            completedDates: arrayUnion(Timestamp.now()),
            lastActionId: "b1",
            lastActionNote: null,
        }));
        // The logger (manager of the partner's plan) sees the confirmation.
        await assertSucceeds(getDoc(doc(dbOf("alice"), "actions/b1")));
    });

    it("the partner reads the shared photo from his own record (manager since managerSince)", async () => {
        await aliceLogsTogether();
        await assertSucceeds(setDoc(doc(dbOf("bob"), "actions/b1"), bobConfirmation()));
        // Bob's record names Alice's path; Storage only asks whether he manages planA.
        await assertSucceeds(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
        // Pointing at it from a record grants a stranger nothing.
        await assertFails(getBytes(ref(storageOf("mallory"), ALICE_PROOF)));
        // Only the owner deletes it.
        await assertFails(deleteObject(ref(storageOf("bob"), ALICE_PROOF)));
    });

    it("after a disconnect (or a new partner) the shared reference opens nothing", async () => {
        await aliceLogsTogether();
        await assertSucceeds(setDoc(doc(dbOf("bob"), "actions/b1"), bobConfirmation()));
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            const db = ctx.firestore();
            // onRelationDeleted clears the managers; Bob later links with Carol.
            await updateDoc(doc(db, "plans/planA"), {managerId: deleteField(), managerSinceUid: deleteField()});
            await updateDoc(doc(db, "plans/planB"), {managerId: "carol", managerSinceUid: "carol"});
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        // Bob's new partner manages Bob's plan, not Alice's: the old path stays closed.
        await assertFails(getBytes(ref(storageOf("carol"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("once the logger deletes her photo, the partner's reference simply fails", async () => {
        await aliceLogsTogether();
        await assertSucceeds(setDoc(doc(dbOf("bob"), "actions/b1"), bobConfirmation()));
        await assertSucceeds(deleteObject(ref(storageOf("alice"), ALICE_PROOF)));
        // The app treats this as "no photo" (ProofPhoto.hideWhenUnavailable).
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        // Bob's record itself stays readable to both.
        await assertSucceeds(getDoc(doc(dbOf("bob"), "actions/b1")));
        await assertSucceeds(getDoc(doc(dbOf("alice"), "actions/b1")));
    });
});
