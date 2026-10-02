// storage.rules — 오운완 인증샷 (proofs/) and profile images (users/).
// Run: firebase emulators:exec --only firestore,storage --project demo-duounwan "npm test"
const {describe, it, before, beforeEach, after} = require("node:test");
const {assertFails, assertSucceeds} = require("@firebase/rules-unit-testing");
const {doc, setDoc, updateDoc, deleteField, Timestamp} = require("firebase/firestore");
const {ref, uploadBytes, getBytes, getMetadata, updateMetadata, deleteObject} = require("firebase/storage");
const {randomUUID} = require("node:crypto");
const {createTestEnv, bytes} = require("./helpers");

const JPEG = {contentType: "image/jpeg"};
const MB = 1024 * 1024;
// clearStorage() does not reach the bucket the test contexts use, so every
// test writes to its own object names instead.
let ALICE_PROOF = "";
let PROFILE = "";

describe("storage.rules", () => {
    let testEnv;

    before(async () => {
        testEnv = await createTestEnv();
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        const id = randomUUID();
        ALICE_PROOF = `proofs/alice/planA/${id}.jpg`;
        PROFILE = `users/alice/profile_${id}.jpg`;
        await testEnv.clearFirestore();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            const db = ctx.firestore();
            // alice's plan, watched by her partner bob.
            await setDoc(doc(db, "plans/planA"), {userId: "alice", managerId: "bob", state: "active"});
            // carol's plan (nobody else's).
            await setDoc(doc(db, "plans/planC"), {userId: "carol", state: "active"});
        });
    });

    const storageOf = (uid) => (uid ? testEnv.authenticatedContext(uid) : testEnv.unauthenticatedContext()).storage();

    async function seedAliceProof() {
        await assertSucceeds(uploadBytes(ref(storageOf("alice"), ALICE_PROOF), bytes(1024), JPEG));
    }

    it("owner can upload a JPEG proof into her own plan and read it back", async () => {
        await seedAliceProof();
        await assertSucceeds(getMetadata(ref(storageOf("alice"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("the plan's current manager (partner) can read the proof", async () => {
        await seedAliceProof();
        await assertSucceeds(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getMetadata(ref(storageOf("bob"), ALICE_PROOF)));
    });

    it("a third party and signed-out users cannot read the proof", async () => {
        await seedAliceProof();
        await assertFails(getBytes(ref(storageOf("mallory"), ALICE_PROOF)));
        await assertFails(getMetadata(ref(storageOf("mallory"), ALICE_PROOF)));
        await assertFails(getBytes(ref(storageOf(null), ALICE_PROOF)));
    });

    it("uploading under someone else's uid or into someone else's plan is denied", async () => {
        // alice writing into carol's folder
        await assertFails(uploadBytes(ref(storageOf("alice"), "proofs/carol/planC/x.jpg"), bytes(1024), JPEG));
        // alice using her own folder but carol's plan
        await assertFails(uploadBytes(ref(storageOf("alice"), "proofs/alice/planC/x.jpg"), bytes(1024), JPEG));
        // a plan that does not exist
        await assertFails(uploadBytes(ref(storageOf("alice"), "proofs/alice/nope/x.jpg"), bytes(1024), JPEG));
        // the partner cannot upload into alice's plan either
        await assertFails(uploadBytes(ref(storageOf("bob"), "proofs/alice/planA/x.jpg"), bytes(1024), JPEG));
        // signed out
        await assertFails(uploadBytes(ref(storageOf(null), "proofs/alice/planA/x.jpg"), bytes(1024), JPEG));
    });

    it("files of 3MB or more are denied", async () => {
        await assertFails(uploadBytes(ref(storageOf("alice"), "proofs/alice/planA/big.jpg"), bytes(3 * MB), JPEG));
        await assertFails(uploadBytes(ref(storageOf("alice"), "proofs/alice/planA/big2.jpg"), bytes(5 * MB), JPEG));
        await assertSucceeds(uploadBytes(ref(storageOf("alice"), ALICE_PROOF), bytes(3 * MB - 1), JPEG));
    });

    it("non-JPEG content types are denied", async () => {
        const path = ALICE_PROOF.replace(".jpg", "");
        await assertFails(uploadBytes(ref(storageOf("alice"), `${path}.png`), bytes(1024), {contentType: "image/png"}));
        await assertFails(uploadBytes(ref(storageOf("alice"), `${path}.heic`), bytes(1024), {contentType: "image/heic"}));
        await assertFails(uploadBytes(ref(storageOf("alice"), `${path}.bin`), bytes(1024)));
    });

    it("existing proofs cannot be overwritten or have metadata changed", async () => {
        await seedAliceProof();
        await assertFails(uploadBytes(ref(storageOf("alice"), ALICE_PROOF), bytes(2048), JPEG));
        await assertFails(updateMetadata(ref(storageOf("alice"), ALICE_PROOF), {customMetadata: {a: "b"}}));
    });

    it("only the owner can delete a proof", async () => {
        await seedAliceProof();
        await assertFails(deleteObject(ref(storageOf("bob"), ALICE_PROOF)));
        await assertFails(deleteObject(ref(storageOf("mallory"), ALICE_PROOF)));
        await assertSucceeds(deleteObject(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("after managerId is cleared (disconnect) the ex-partner can no longer read", async () => {
        await seedAliceProof();
        await assertSucceeds(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "plans/planA"), {managerId: deleteField()});
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertFails(getMetadata(ref(storageOf("bob"), ALICE_PROOF)));
        // the owner keeps access
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("a new manager replaces the old one", async () => {
        await seedAliceProof();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "plans/planA"), {managerId: "dave"});
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("dave"), ALICE_PROOF)));
    });

    it("profile images keep working as before", async () => {
        const path = PROFILE;
        await assertSucceeds(uploadBytes(ref(storageOf("alice"), path), bytes(1024), JPEG));
        await assertSucceeds(uploadBytes(ref(storageOf("alice"), PROFILE.replace(".jpg", ".png")), bytes(1024), {contentType: "image/png"}));
        await assertSucceeds(getMetadata(ref(storageOf("mallory"), path)));
        await assertFails(getMetadata(ref(storageOf(null), path)));
        await assertFails(uploadBytes(ref(storageOf("bob"), "users/alice/x.jpg"), bytes(1024), JPEG));
        await assertFails(uploadBytes(ref(storageOf("alice"), "users/alice/big.jpg"), bytes(5 * MB), JPEG));
        await assertSucceeds(deleteObject(ref(storageOf("alice"), path)));
    });

    it("everything else is denied", async () => {
        await assertFails(uploadBytes(ref(storageOf("alice"), "random/alice.jpg"), bytes(10), JPEG));
        await assertFails(getMetadata(ref(storageOf("alice"), "random/alice.jpg")));
    });
    it("the manager of a plan with the same id but another owner can't read", async () => {
        await seedAliceProof();
        // alice's plan is gone; mallory re-creates the id with her alt as manager.
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await setDoc(doc(ctx.firestore(), "plans/planA"), {userId: "mallory", managerId: "bob", state: "active"});
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertFails(getMetadata(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("a stamped manager reads only proofs taken since managerSince", async () => {
        await seedAliceProof();
        const stamp = async (fields) => testEnv.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "plans/planA"), fields);
        });
        await stamp({managerSince: Timestamp.fromMillis(Date.now() - 60 * 60 * 1000), managerSinceUid: "bob"});
        await assertSucceeds(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        // Became manager after the photo was taken: an earlier era stays hidden.
        await stamp({managerSince: Timestamp.fromMillis(Date.now() + 60 * 60 * 1000)});
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertFails(getMetadata(ref(storageOf("bob"), ALICE_PROOF)));
    });

    it("a stamp issued to someone else (or an unlink mark) grants nothing", async () => {
        await seedAliceProof();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "plans/planA"), {
                managerSince: Timestamp.fromMillis(Date.now() - 60 * 60 * 1000), managerSinceUid: "carol",
            });
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            await updateDoc(doc(ctx.firestore(), "plans/planA"), {managerSinceUid: ""});
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });

    it("after the plan is deleted only the owner can read its proofs", async () => {
        await seedAliceProof();
        await testEnv.withSecurityRulesDisabled(async (ctx) => {
            const {deleteDoc} = require("firebase/firestore");
            await deleteDoc(doc(ctx.firestore(), "plans/planA"));
        });
        await assertFails(getBytes(ref(storageOf("bob"), ALICE_PROOF)));
        await assertSucceeds(getBytes(ref(storageOf("alice"), ALICE_PROOF)));
    });
});
