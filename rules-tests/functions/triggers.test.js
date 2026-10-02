// End-to-end checks of the Cloud Functions triggers on the local emulators.
// Run from rules-tests/: npm run emulators:functions
// (builds functions/, then starts auth+firestore+functions+storage for
// project demo-duounwan). In the emulator the functions record pushes in
// `emulatorPushes` instead of calling FCM.
const {describe, it, before} = require("node:test");
const assert = require("node:assert/strict");
const {randomUUID} = require("node:crypto");
const admin = require("firebase-admin");

const PROJECT_ID = "demo-duounwan";
admin.initializeApp({projectId: PROJECT_ID, storageBucket: `${PROJECT_ID}.appspot.com`});
const db = admin.firestore();
const {FieldValue, Timestamp} = admin.firestore;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitFor(check, {timeout = 20000, interval = 250, label = "condition"} = {}) {
    const started = Date.now();
    for (;;) {
        const value = await check();
        if (value) return value;
        if (Date.now() - started > timeout) throw new Error(`Timed out waiting for ${label}`);
        await sleep(interval);
    }
}

async function pushesTo(uid) {
    const snap = await db.collection("emulatorPushes").where("to", "==", uid).get();
    return snap.docs.map((doc) => doc.data());
}

/** Waits for `count` pushes to `uid`, then a little longer to catch extras. */
async function expectPushes(uid, count, label) {
    if (count > 0) {
        await waitFor(async () => (await pushesTo(uid)).length >= count, {label: `${label} push`});
    }
    await sleep(2500);
    const pushes = await pushesTo(uid);
    assert.equal(pushes.length, count, `${label}: expected ${count} push(es), got ${JSON.stringify(pushes)}`);
    return pushes;
}

const AUTH_EMULATOR = "http://127.0.0.1:9099";
const FUNCTIONS_EMULATOR = `http://127.0.0.1:5001/${PROJECT_ID}/us-central1`;

/** A guest account on the auth emulator: {uid, idToken}. */
async function signUpAnonymously() {
    const res = await fetch(`${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({returnSecureToken: true}),
    });
    const body = await res.json();
    return {uid: body.localId, idToken: body.idToken};
}

/** Calls an onCall function like the app's SDK does: {result} or {error}. */
async function callFunction(name, data, idToken) {
    const headers = {"Content-Type": "application/json"};
    if (idToken) headers.Authorization = `Bearer ${idToken}`;
    const res = await fetch(`${FUNCTIONS_EMULATOR}/${name}`, {method: "POST", headers, body: JSON.stringify({data})});
    return res.json();
}

function uid(prefix) {
    return `${prefix}_${randomUUID().slice(0, 8)}`;
}

async function makeUser(id, extra = {}) {
    await db.doc(`users/${id}`).set({
        displayName: id.split("_")[0],
        fcmToken: `token-${id}`,
        inviteCode: `OLD${randomUUID().slice(0, 5).toUpperCase()}`,
        createdAt: Timestamp.now(),
        ...extra,
    });
}

async function codeOf(id) {
    return (await db.doc(`users/${id}`).get()).data().inviteCode;
}

/**
 * Mimics the app's connectWithCode batch (code enterer = `enterer`): both docs
 * carry the code owner (`inviterId`) and the code they hold right now.
 * `{stamp: false}` writes them like a pre-둘운완 build.
 */
async function link(inviter, enterer, {stamp = true, ...extra} = {}) {
    const fields = {status: "active", createdAt: FieldValue.serverTimestamp(), connectedAt: FieldValue.serverTimestamp()};
    if (stamp) Object.assign(fields, {inviterId: inviter, inviteCode: await codeOf(inviter)});
    Object.assign(fields, extra);
    const batch = db.batch();
    batch.set(db.collection("relations").doc(), {managerId: inviter, executorId: enterer, ...fields});
    batch.set(db.collection("relations").doc(), {managerId: enterer, executorId: inviter, ...fields});
    await batch.commit();
}

async function relationDocs(a, b) {
    const [ab, ba] = await Promise.all([
        db.collection("relations").where("managerId", "==", a).where("executorId", "==", b).get(),
        db.collection("relations").where("managerId", "==", b).where("executorId", "==", a).get(),
    ]);
    return [...ab.docs, ...ba.docs];
}

/** Like disconnectByUser: deletes the pair's docs one by one. */
async function unlink(a, b) {
    for (const doc of await relationDocs(a, b)) await doc.ref.delete();
}

async function plan(id) {
    return (await db.doc(`plans/${id}`).get()).data();
}

async function relationCount(a, b) {
    const [ab, ba] = await Promise.all([
        db.collection("relations").where("managerId", "==", a).where("executorId", "==", b).get(),
        db.collection("relations").where("managerId", "==", b).where("executorId", "==", a).get(),
    ]);
    return ab.size + ba.size;
}

/** Links a pair and waits until the link trigger finished (plans assigned). */
async function linkedPair(prefixA = "alice", prefixB = "bob") {
    const a = uid(prefixA);
    const b = uid(prefixB);
    await makeUser(a, {createdAt: Timestamp.fromMillis(Date.now() - 86400000)});
    await makeUser(b);
    await db.doc(`plans/${a}_plan`).set({
        userId: a, state: "active", workoutType: "running",
        items: [{title: "러닝", days: [1, 2, 3, 4, 5, 6, 7], notificationTime: {type: "custom", hour: 21, minute: 0}}],
    });
    await link(a, b);
    await waitFor(async () => (await db.doc(`plans/${a}_plan`).get()).data().managerId === b, {label: "link"});
    await expectPushes(a, 1, "partner_connected");
    return {a, b, planId: `${a}_plan`};
}

describe("Cloud Functions triggers (emulator)", () => {
    before(async () => {
        await waitFor(async () => {
            try {
                const res = await fetch(`http://127.0.0.1:5001/${PROJECT_ID}/us-central1/__probe`);
                return res.status > 0;
            } catch {
                return false;
            }
        }, {label: "functions emulator"});
    });

    it("onRelationCreated: one push to the inviter, codes rotated, inviter's plan gets a manager", async () => {
        const a = uid("alice");
        const b = uid("bob");
        await makeUser(a, {createdAt: Timestamp.fromMillis(Date.now() - 86400000)});
        await makeUser(b);
        const oldCodes = [(await db.doc(`users/${a}`).get()).data().inviteCode, (await db.doc(`users/${b}`).get()).data().inviteCode];
        await db.doc(`plans/${a}_p1`).set({userId: a, state: "active", workoutType: "gym", items: []});
        await db.doc(`plans/${a}_p2`).set({userId: a, state: "completed", items: []});
        await db.doc(`plans/${b}_p1`).set({userId: b, state: "active", items: []});

        await link(a, b);

        const pushes = await expectPushes(a, 1, "partner_connected");
        assert.equal(pushes[0].data.type, "partner_connected");
        assert.equal(pushes[0].data.partnerId, b);
        assert.match(pushes[0].notification.title, /짝꿍/);
        assert.doesNotMatch(pushes[0].notification.title + pushes[0].notification.body, /님/);
        await expectPushes(b, 0, "invitee");

        const p1 = (await db.doc(`plans/${a}_p1`).get()).data();
        assert.equal(p1.managerId, b);
        assert.equal(p1.state, "active");
        assert.equal(p1.lastUpdatedBy, "system_link");
        // The new manager's proof floor: the link time (strict, no look-back),
        // so photos taken before the link stay hidden from the new partner.
        assert.equal(p1.managerSinceUid, b);
        assert.ok(Math.abs(Date.now() - p1.managerSince.toMillis()) < 10 * 60 * 1000);
        assert.equal((await db.doc(`plans/${a}_p2`).get()).data().managerId, undefined);
        // Only the code owner's plans are handed over; the app assigns the
        // enterer's own plans itself.
        assert.equal((await db.doc(`plans/${b}_p1`).get()).data().managerId, undefined);

        const newCodes = [(await db.doc(`users/${a}`).get()).data().inviteCode, (await db.doc(`users/${b}`).get()).data().inviteCode];
        newCodes.forEach((code, i) => {
            assert.notEqual(code, oldCodes[i]);
            assert.match(code, /^[A-HJKMNP-Z2-9]{8}$/);
        });
        assert.equal(await relationCount(a, b), 2);
    });

    it("onRelationCreated: 1:1 is enforced and the code enterer is told", async () => {
        const {a, b} = await linkedPair();
        const c = uid("carol");
        await makeUser(c);
        await link(a, c); // carol enters alice's code while alice is linked with bob

        await waitFor(async () => (await relationCount(a, c)) === 0, {label: "undo"});
        const pushes = await expectPushes(c, 1, "connect failed");
        assert.equal(pushes[0].data.type, "partner_connect_failed");
        assert.equal(pushes[0].data.reason, "owner_taken");
        assert.equal(await relationCount(a, b), 2);
        await expectPushes(a, 1, "no extra push to the owner");
    });

    it("onRelationCreated: a stamped but stale invite code is rejected", async () => {
        const a = uid("alice");
        const b = uid("bob");
        await makeUser(a, {inviteCode: "ABCDEFGH"});
        await makeUser(b);
        await link(a, b, {inviteCode: "ZZZZZZZZ"});
        await waitFor(async () => (await relationCount(a, b)) === 0, {label: "undo stale code"});
        const pushes = await expectPushes(b, 1, "invalid code");
        assert.equal(pushes[0].data.reason, "invalid_code");
    });

    it("인정 via cheer + plan update sends exactly one push", async () => {
        const {a, b, planId} = await linkedPair();
        await db.doc(`plans/${planId}`).update({completedDates: FieldValue.arrayUnion(Timestamp.now()), lastUpdatedBy: a});
        await db.collection("cheers").add({
            fromUserId: b, toUserId: a, planId, reactionType: "🔥", createdAt: FieldValue.serverTimestamp(),
        });
        await db.doc(`plans/${planId}`).update({
            lastCheerType: "🔥", lastCheerAt: Timestamp.now(), lastUpdatedBy: b,
            verifiedDates: FieldValue.arrayUnion(Timestamp.now()),
        });
        const pushes = await expectPushes(a, 2, "인정 (cheer path)"); // 1 = partner_connected
        const verify = pushes.find((p) => p.data.type !== "partner_connected");
        assert.equal(verify.data.type, "cheer");
        assert.equal(verify.notification.title, "🔥 bob의 인정 도착!");
    });

    it("인정 via plan update only (verifyPlan path) sends exactly one push", async () => {
        const {a, b, planId} = await linkedPair();
        await db.doc(`plans/${planId}`).update({
            verifiedDates: FieldValue.arrayUnion(Timestamp.now()), lastUpdatedBy: b,
        });
        const pushes = await expectPushes(a, 2, "인정 (verifyPlan path)");
        assert.equal(pushes.filter((p) => p.data.type === "action_verified").length, 1);
    });

    it("partnerNickname is the sender label; poke is rate-limited and legacy text replaced", async () => {
        const {a, b, planId} = await linkedPair();
        await db.doc(`users/${a}`).update({partnerNickname: "오빠"});
        const legacy = "똑똑! 실천 메이트가 기다리고 있어요. 오늘 약속을 정리해볼까요?";
        await db.doc(`plans/${planId}`).update({lastPokeAt: Timestamp.now(), lastPokeMessage: legacy, lastUpdatedBy: b});
        await waitFor(async () => (await pushesTo(a)).some((p) => p.data.type === "poke"), {label: "poke"});
        await db.doc(`plans/${planId}`).update({
            lastPokeAt: Timestamp.fromMillis(Date.now() + 5000), lastPokeMessage: "한 번 더!", lastUpdatedBy: b,
        });
        await db.collection("cheers").add({fromUserId: b, toUserId: a, planId, reactionType: "poke", message: "또!"});
        const pushes = (await expectPushes(a, 2, "poke")).filter((p) => p.data.type === "poke");
        assert.equal(pushes.length, 1);
        assert.equal(pushes[0].notification.title, "✊ 오빠의 똑똑");
        assert.equal(pushes[0].notification.body, "오늘 러닝 기다리고 있어 👀");
    });

    it("poke reply uses the new poke_reply type", async () => {
        const {a, b, planId} = await linkedPair();
        await db.collection("cheers").add({fromUserId: a, toUserId: b, planId, reactionType: "reply", message: "지금 간다 🏃"});
        const pushes = await expectPushes(b, 1, "reply");
        assert.equal(pushes[0].data.type, "poke_reply");
        assert.equal(pushes[0].notification.title, "💬 alice의 답장");
        assert.equal(pushes[0].notification.body, "지금 간다 🏃");
    });

    it("strangers cannot push through cheers", async () => {
        const a = uid("alice");
        const m = uid("mallory");
        await makeUser(a);
        await makeUser(m);
        await db.collection("cheers").add({fromUserId: m, toUserId: a, reactionType: "poke", message: "hi"});
        await expectPushes(a, 0, "stranger poke");
    });

    it("onActionCompleted: proof copy only for recipients on the pivot build", async () => {
        const {a, b, planId} = await linkedPair();
        const proofAction = {
            userId: a, planId, type: "done", title: "러닝",
            proofPhotoPath: `proofs/${a}/${planId}/x.jpg`, createdAt: FieldValue.serverTimestamp(),
        };
        await db.collection("actions").add(proofAction);
        let pushes = await expectPushes(b, 1, "old build");
        assert.equal(pushes[0].notification.title, "🏃 alice 오늘 러닝 끝!");
        assert.equal(pushes[0].data.hasProof, "false");

        await db.doc(`users/${b}`).update({clientBuild: 81});
        await db.collection("actions").add(proofAction);
        pushes = await expectPushes(b, 2, "pivot build");
        const proof = pushes.find((p) => p.data.hasProof === "true");
        assert.equal(proof.notification.title, "📸 alice 오운완 인증샷 도착!");
        assert.match(proof.notification.body, /인정해 줄래\?/);
    });

    it("onPlanCreated: workout copy for the partner", async () => {
        const {a, b} = await linkedPair();
        await db.doc(`plans/${a}_new`).set({
            userId: a, managerId: b, state: "active", workoutType: "gym",
            items: [{title: "헬스", days: [1, 3, 5], notificationTime: {type: "custom", hour: 7, minute: 30}}],
        });
        const pushes = await expectPushes(b, 1, "plan created");
        assert.equal(pushes[0].data.type, "plan_proposed");
        assert.equal(pushes[0].notification.title, "🤙 alice 운동 약속 걸었어");
        assert.equal(pushes[0].notification.body, "🏋️ 헬스 · 월·수·금 07:30까지 · 봐줄 거지? 👀");
    });

    it("a manager that is not a linked partner is detached", async () => {
        const a = uid("alice");
        const m = uid("mallory");
        await makeUser(a);
        await makeUser(m);
        await db.doc(`plans/${a}_x`).set({userId: a, state: "active", items: []});
        await db.doc(`plans/${a}_x`).update({managerId: m, lastUpdatedBy: a});
        await waitFor(async () => (await db.doc(`plans/${a}_x`).get()).data().managerId === undefined,
            {label: "detach on update"});
        await db.doc(`plans/${a}_y`).set({userId: a, managerId: m, state: "pending_approval", items: []});
        await waitFor(async () => (await db.doc(`plans/${a}_y`).get()).data().managerId === undefined,
            {label: "detach on create"});
        assert.equal((await db.doc(`plans/${a}_y`).get()).data().state, "active");
        await expectPushes(m, 0, "no push to the stranger");
    });

    it("onRelationDeleted: plans detached both ways, 내기 rejected, codes rotated, nickname cleared", async () => {
        const {a, b, planId} = await linkedPair();
        await db.doc(`plans/${b}_pending`).set({
            userId: b, managerId: a, state: "pending_approval", items: [], promise: {status: "active"},
        });
        await db.doc(`plans/${planId}`).update({
            promise: {status: "proposed"}, lastCheerMessage: "화이팅", lastComment: "굿",
            lastProofPhotoPath: `proofs/${a}/${planId}/x.jpg`, lastProofAt: Timestamp.now(), lastUpdatedBy: "system_test",
        });
        await db.doc(`users/${a}`).update({partnerNickname: "자기"});
        await sleep(1000);
        const codesBefore = [(await db.doc(`users/${a}`).get()).data().inviteCode, (await db.doc(`users/${b}`).get()).data().inviteCode];

        // Like disconnectByUser: delete the docs one by one.
        const docs = [
            ...(await db.collection("relations").where("managerId", "==", a).where("executorId", "==", b).get()).docs,
            ...(await db.collection("relations").where("managerId", "==", b).where("executorId", "==", a).get()).docs,
        ];
        for (const doc of docs) await doc.ref.delete();

        await waitFor(async () => (await db.doc(`plans/${planId}`).get()).data().managerId === undefined,
            {label: "unlink alice's plan"});
        const aPlan = (await db.doc(`plans/${planId}`).get()).data();
        assert.equal(aPlan.promise.status, "rejected");
        assert.equal(aPlan.lastUpdatedBy, "system_unlink");
        // The unlink time is the proof floor for whoever comes next, and what
        // bob wrote on alice's plan is gone.
        assert.equal(aPlan.managerSinceUid, "");
        assert.ok(aPlan.managerSince);
        for (const field of ["lastCheerMessage", "lastComment", "lastProofPhotoPath", "lastProofAt"]) {
            assert.equal(aPlan[field], undefined, field);
        }
        await waitFor(async () => (await db.doc(`plans/${b}_pending`).get()).data().managerId === undefined,
            {label: "unlink bob's plan"});
        const bPlan = (await db.doc(`plans/${b}_pending`).get()).data();
        assert.equal(bPlan.state, "active");
        assert.equal(bPlan.promise.status, "rejected");

        await waitFor(async () => (await db.doc(`users/${a}`).get()).data().partnerNickname === undefined,
            {label: "nickname cleared"});
        const codesAfter = [(await db.doc(`users/${a}`).get()).data().inviteCode, (await db.doc(`users/${b}`).get()).data().inviteCode];
        assert.notEqual(codesAfter[0], codesBefore[0]);
        assert.notEqual(codesAfter[1], codesBefore[1]);
        // No "approved" push for the pending → active flip.
        await expectPushes(b, 0, "no push on unlink");
    });

    it("onAuthUserDeleted removes the user's data and detaches the partner", async () => {
        const user = await admin.auth().createUser({});
        const a = user.uid;
        const b = uid("bob");
        await makeUser(a, {createdAt: Timestamp.fromMillis(Date.now() - 86400000)});
        await makeUser(b);
        await link(a, b);
        await waitFor(async () => (await pushesTo(a)).length === 1, {label: "link before delete"});
        await db.doc(`plans/${b}_watched`).set({userId: b, managerId: a, state: "active", items: []});
        await db.doc(`plans/${a}_own`).set({userId: a, state: "active", items: []});
        await db.collection("actions").add({userId: a, planId: `${a}_own`, type: "done"});
        await db.collection("cheers").add({fromUserId: a, toUserId: b, reactionType: "❤️"});
        await db.collection("cheers").add({fromUserId: b, toUserId: a, reactionType: "poke"});
        const bAction = await db.collection("actions").add({
            userId: b, planId: `${b}_watched`, type: "done", verifiedBy: a, verifiedAt: Timestamp.now(),
            reaction: "🔥", partnerMessage: "멋져", comment: "굿",
        });
        await db.doc(`users/${a}/private/messaging`).set({fcmToken: "private-token"});
        const bucket = admin.storage().bucket();
        await bucket.file(`proofs/${a}/${a}_own/x.jpg`).save(Buffer.from("x"), {contentType: "image/jpeg"});
        await bucket.file(`users/${a}/profile.jpg`).save(Buffer.from("x"), {contentType: "image/jpeg"});
        await waitFor(async () => (await bAction.get()).data().managerId === a, {label: "bob's action shared with a"});

        await admin.auth().deleteUser(a);

        await waitFor(async () => !(await db.doc(`users/${a}`).get()).exists, {label: "user doc deleted"});
        assert.equal((await db.collection("actions").where("userId", "==", a).get()).size, 0);
        assert.equal((await db.collection("cheers").where("fromUserId", "==", a).get()).size, 0);
        assert.equal((await db.collection("cheers").where("toUserId", "==", a).get()).size, 0);
        assert.equal((await db.collection("plans").where("userId", "==", a).get()).size, 0);
        assert.equal(await relationCount(a, b), 0);
        assert.equal((await db.doc(`plans/${b}_watched`).get()).data().managerId, undefined);
        const [proofs] = await bucket.getFiles({prefix: `proofs/${a}/`});
        const [profiles] = await bucket.getFiles({prefix: `users/${a}/`});
        assert.equal(proofs.length + profiles.length, 0);
        // What alice wrote on bob's record is gone; bob's record stays.
        await waitFor(async () => (await bAction.get()).data().managerId === undefined, {label: "unshared on deletion"});
        const kept = (await bAction.get()).data();
        assert.equal(kept.type, "done");
        assert.equal(kept.reaction, undefined);
        assert.equal(kept.partnerMessage, undefined);
        assert.equal(kept.comment, undefined);
        assert.equal((await db.doc(`users/${a}/private/messaging`).get()).exists, false);
    });
    it("1:1: when the code enterer is the one already linked, only they are told (self_taken)", async () => {
        // The enterer's id sorts first, so a sort-order guess would blame the owner.
        const {a: enterer} = await linkedPair("aaa", "bbb");
        const owner = uid("zzz");
        await makeUser(owner);
        await link(owner, enterer);
        await waitFor(async () => (await relationCount(owner, enterer)) === 0, {label: "undo"});
        const pushes = (await expectPushes(enterer, 2, "self_taken")).filter((p) => p.data.type !== "partner_connected");
        assert.equal(pushes[0].data.type, "partner_connect_failed");
        assert.equal(pushes[0].data.reason, "self_taken");
        await expectPushes(owner, 0, "the free code owner");
    });

    it("an unstamped link is undone silently outside the legacy window", async () => {
        const a = uid("alice");
        const b = uid("bob");
        await makeUser(a);
        await makeUser(b);
        await db.doc(`plans/${b}_solo`).set({userId: b, state: "active", items: []});
        await link(a, b, {stamp: false});
        await waitFor(async () => (await relationCount(a, b)) === 0, {label: "undo unstamped"});
        await expectPushes(a, 0, "unstamped owner");
        await expectPushes(b, 0, "unstamped enterer");
        assert.equal((await plan(`${b}_solo`)).managerId, undefined);
    });

    it("inside the legacy window an unstamped link stands, both are told, no plans are handed over", async () => {
        await db.doc("config/app").set({legacyLinkUntil: Timestamp.fromMillis(Date.now() + 3600000)}, {merge: true});
        try {
            const a = uid("alice");
            const b = uid("bob");
            await makeUser(a);
            await makeUser(b);
            await db.doc(`plans/${a}_solo`).set({userId: a, state: "active", items: []});
            await db.doc(`plans/${b}_solo`).set({userId: b, state: "active", items: []});
            await link(a, b, {stamp: false});
            const [toA] = await expectPushes(a, 1, "legacy link (a)");
            const [toB] = await expectPushes(b, 1, "legacy link (b)");
            assert.equal(toA.data.type, "partner_connected");
            assert.equal(toB.data.partnerId, a);
            assert.equal(await relationCount(a, b), 2);
            assert.equal((await plan(`${a}_solo`)).managerId, undefined);
            assert.equal((await plan(`${b}_solo`)).managerId, undefined);
        } finally {
            await db.doc("config/app").set({legacyLinkUntil: Timestamp.fromMillis(0)}, {merge: true});
        }
    });

    it("a code held by two users links nobody, and the newer holder's code is re-issued", async () => {
        const owner = uid("vic");
        await makeUser(owner, {inviteCode: "VICT2345"});
        await sleep(50);
        const copier = uid("mal");
        await makeUser(copier, {inviteCode: "VICT2345"});
        const enterer = uid("pat");
        await makeUser(enterer);
        await db.doc(`plans/${enterer}_p`).set({userId: enterer, state: "active", items: []});
        // The app's lookup picked the copier.
        await link(copier, enterer, {inviteCode: "VICT2345"});
        await waitFor(async () => (await relationCount(copier, enterer)) === 0, {label: "undo ambiguous"});
        const [failed] = await expectPushes(enterer, 1, "ambiguous code");
        assert.equal(failed.data.reason, "invalid_code");
        await expectPushes(copier, 0, "copier");
        assert.equal(await codeOf(owner), "VICT2345");
        assert.notEqual(await codeOf(copier), "VICT2345");
        assert.equal((await plan(`${enterer}_p`)).managerId, undefined);
    });

    it("a backdated createdAt does not beat an existing partner (server createTime decides)", async () => {
        const {a, b} = await linkedPair();
        const c = uid("carol");
        await makeUser(c);
        await link(a, c, {createdAt: Timestamp.fromMillis(1000)});
        await waitFor(async () => (await relationCount(a, c)) === 0, {label: "undo backdated"});
        const [failed] = await expectPushes(c, 1, "backdated");
        assert.equal(failed.data.reason, "owner_taken");
        assert.equal(await relationCount(a, b), 2);
    });

    it("linking an already-linked pair again is dropped quietly", async () => {
        const {a, b} = await linkedPair();
        const codes = [await codeOf(a), await codeOf(b)];
        await link(a, b);
        await waitFor(async () => (await relationCount(a, b)) === 2, {label: "duplicate dropped"});
        await sleep(2000);
        assert.equal(await relationCount(a, b), 2);
        await expectPushes(a, 1, "no second connected push");
        await expectPushes(b, 0, "no failure push");
        assert.deepEqual([await codeOf(a), await codeOf(b)], codes);
    });

    it("a quick unlink → re-link → unlink still detaches every time (no time-window lock)", async () => {
        const {a, b, planId} = await linkedPair();
        const codeBefore = await codeOf(a);
        await unlink(a, b);
        await waitFor(async () => (await plan(planId)).managerId === undefined, {label: "first unlink"});
        // b enters the code a has after the unlink.
        await waitFor(async () => (await codeOf(a)) !== codeBefore, {label: "code re-issued on unlink"});

        await link(a, b);
        await waitFor(async () => (await plan(planId)).managerId === b, {label: "re-link within 2 minutes"});
        await expectPushes(a, 2, "second partner_connected");
        // Re-assigned after an unlink: the floor is the unlink, not a day back.
        const relinked = await plan(planId);
        assert.equal(relinked.managerSinceUid, b);
        assert.ok(Date.now() - relinked.managerSince.toMillis() < 10 * 60 * 1000);

        await unlink(a, b);
        await waitFor(async () => (await plan(planId)).managerId === undefined, {label: "second unlink"});
        assert.equal((await plan(planId)).managerSinceUid, "");
    });

    it("an undone link does not re-issue codes, but detaches what the enterer assigned", async () => {
        const {a, b} = await linkedPair();
        const c = uid("carol");
        await makeUser(c);
        await db.doc(`plans/${c}_p`).set({userId: c, state: "active", items: []});
        const codesBefore = [await codeOf(a), await codeOf(c)];
        await link(a, c);
        // Like the app right after connectWithCode.
        await db.doc(`plans/${c}_p`).update({managerId: a, lastUpdatedBy: "system_link"});
        await waitFor(async () => (await relationCount(a, c)) === 0, {label: "undo"});
        await waitFor(async () => (await plan(`${c}_p`)).managerId === undefined, {label: "enterer's plan detached"});
        await sleep(2000);
        assert.deepEqual([await codeOf(a), await codeOf(c)], codesBefore);
        assert.equal(await relationCount(a, b), 2);
    });

    it("a manager set by the app gets a proof floor stamped by the server", async () => {
        const {a, b} = await linkedPair();
        await db.doc(`plans/${b}_mine`).set({userId: b, state: "active", items: []});
        await db.doc(`plans/${b}_mine`).update({managerId: a, lastUpdatedBy: "system_link"});
        await waitFor(async () => (await plan(`${b}_mine`)).managerSinceUid === a, {label: "stamp"});
        assert.ok((await plan(`${b}_mine`)).managerSince);
    });

    it("actions.managerId follows the plan: stamped on create, shared on link, cleared on unlink", async () => {
        const a = uid("alice");
        const b = uid("bob");
        await makeUser(a, {createdAt: Timestamp.fromMillis(Date.now() - 86400000)});
        await makeUser(b);
        const planId = `${a}_plan`;
        await db.doc(`plans/${planId}`).set({userId: a, state: "active", items: []});
        const earlier = await db.collection("actions").add({userId: a, planId, type: "done"});
        await sleep(1500);
        assert.equal((await earlier.get()).data().managerId, undefined, "solo plan: nothing to share");

        await link(a, b);
        await waitFor(async () => (await plan(planId)).managerId === b, {label: "link"});
        await waitFor(async () => (await earlier.get()).data().managerId === b, {label: "earlier action shared on link"});

        // Like builds ≤80 (no managerId): the server stamps it, whatever the type.
        const legacy = await db.collection("actions").add({userId: a, planId, type: "skipped"});
        const rescued = await db.collection("actions").add({userId: a, planId, type: "rescued"});
        // A wrong stamp (the admin SDK skips the rules) is corrected …
        const forged = await db.collection("actions").add({userId: a, planId, type: "rested", managerId: "mallory"});
        // … and a record that isn't the plan owner's is never shared.
        const injected = await db.collection("actions").add({userId: b, planId, type: "done", managerId: b});
        for (const [ref, want, label] of [[legacy, b, "legacy"], [rescued, b, "rescued"], [forged, b, "forged"],
            [injected, undefined, "injected"]]) {
            await waitFor(async () => (await ref.get()).data().managerId === want, {label: `stamp (${label})`});
        }

        await unlink(a, b);
        await waitFor(async () => (await plan(planId)).managerId === undefined, {label: "unlink"});
        for (const ref of [earlier, legacy, rescued, forged]) {
            await waitFor(async () => (await ref.get()).data().managerId === undefined, {label: `unshare ${ref.id}`});
        }
        const kept = (await earlier.get()).data();
        assert.equal(kept.type, "done");
        assert.equal(kept.userId, a);
    });

    it("a plan the app points at the partner shares its actions; a guard detach unshares them", async () => {
        const {a, b} = await linkedPair();
        const mine = `${b}_mine`;
        await db.doc(`plans/${mine}`).set({userId: b, state: "active", items: []});
        const action = await db.collection("actions").add({userId: b, planId: mine, type: "done"});
        // Like the app right after connectWithCode: it assigns its own plans.
        await db.doc(`plans/${mine}`).update({managerId: a, lastUpdatedBy: "system_link"});
        await waitFor(async () => (await action.get()).data().managerId === a, {label: "shared via onPlanUpdated"});

        const m = uid("mallory");
        await makeUser(m);
        await db.doc(`plans/${mine}`).update({managerId: m, lastUpdatedBy: b});
        await waitFor(async () => (await plan(mine)).managerId === undefined, {label: "guard detach"});
        await waitFor(async () => (await action.get()).data().managerId === undefined, {label: "unshared after detach"});
        await expectPushes(m, 0, "no push to the stranger");
    });

    it("onPlanDeleted removes the plan's proofs and clears the photo fields on its actions", async () => {
        const {a, planId} = await linkedPair();
        const bucket = admin.storage().bucket();
        const path = `proofs/${a}/${planId}/act.jpg`;
        await bucket.file(path).save(Buffer.from("x"), {contentType: "image/jpeg"});
        const other = `proofs/${a}/other_plan/act.jpg`;
        await bucket.file(other).save(Buffer.from("x"), {contentType: "image/jpeg"});
        const action = await db.collection("actions").add({
            userId: a, planId, type: "done", note: "굿", proofPhotoPath: path, proofSource: "camera",
            proofTakenAt: Timestamp.now(),
        });
        await waitFor(async () => Boolean((await action.get()).data().managerId), {label: "stamped"});
        await db.doc(`plans/${planId}`).delete();
        await waitFor(async () => (await action.get()).data().proofPhotoPath === undefined, {label: "action cleared"});
        await waitFor(async () => (await action.get()).data().managerId === undefined, {label: "action unshared"});
        const kept = (await action.get()).data();
        assert.equal(kept.note, "굿");
        assert.equal(kept.proofSource, undefined);
        assert.equal(kept.proofTakenAt, undefined);
        const [left] = await bucket.getFiles({prefix: `proofs/${a}/${planId}/`});
        assert.equal(left.length, 0);
        const [untouched] = await bucket.getFiles({prefix: `proofs/${a}/other_plan/`});
        assert.equal(untouched.length, 1);
    });

    it("a relation re-pointed behind the rules' back is removed and the old pair detached", async () => {
        const {a, b, planId} = await linkedPair();
        const m = uid("mallory");
        await makeUser(m);
        const [first] = await relationDocs(a, b);
        await first.ref.update({managerId: m, executorId: first.data().executorId === a ? a : b});
        await waitFor(async () => !(await first.ref.get()).exists, {label: "re-pointed doc removed"});
        // One doc of the pair is left, so they are still linked.
        assert.equal(await relationCount(a, b), 1);
        assert.equal((await plan(planId)).managerId, b);
    });

    it("placeholder names and a nickname meant for someone else are not used as the label", async () => {
        const {a, b, planId} = await linkedPair();
        await db.doc(`users/${b}`).update({displayName: "나"});
        await db.doc(`users/${a}`).update({partnerNickname: "여보", partnerNicknameFor: "someone_else"});
        await db.collection("cheers").add({fromUserId: b, toUserId: a, planId, reactionType: "reply", message: "지금 간다"});
        const reply = (await expectPushes(a, 2, "reply")).find((p) => p.data.type === "poke_reply");
        assert.equal(reply.notification.title, "💬 짝꿍의 답장");
    });

    it("a legacy pending plan edited active by its owner is a change, not an approval", async () => {
        const {a, b} = await linkedPair();
        await db.doc(`plans/${a}_old`).set({
            userId: a, managerId: b, state: "pending_approval", items: [{title: "x", days: [1]}],
            startDate: Timestamp.fromMillis(Date.now() - 86400000 * 3),
        });
        await expectPushes(b, 1, "plan proposed");
        await db.doc(`plans/${a}_old`).update({
            state: "active", startDate: Timestamp.now(), lastUpdatedBy: a,
        });
        const pushes = await expectPushes(b, 2, "owner edit");
        assert.equal(pushes.filter((p) => p.data.type === "plan_approved").length, 0);
        assert.equal(pushes.filter((p) => p.data.type === "plan_updated").length, 1);
    });

    it("a poke with a made-up planId shares the pair's daily budget", async () => {
        const {a, b} = await linkedPair();
        await db.collection("cheers").add({fromUserId: b, toUserId: a, planId: "fake_1", reactionType: "poke"});
        await waitFor(async () => (await pushesTo(a)).some((p) => p.data.type === "poke"), {label: "first poke"});
        await db.collection("cheers").add({fromUserId: b, toUserId: a, planId: "fake_2", reactionType: "poke"});
        await db.collection("cheers").add({fromUserId: a, toUserId: b, reactionType: "poke"});
        const pokes = (await expectPushes(a, 2, "pokes to a")).filter((p) => p.data.type === "poke");
        assert.equal(pokes.length, 1);
        await expectPushes(b, 0, "pair budget is shared");
    });

    it("redeemInviteCode / resolveInviteCode link through the server", async () => {
        const owner = uid("owner");
        await makeUser(owner, {displayName: "주인"});
        await db.doc(`plans/${owner}_p`).set({userId: owner, state: "active", items: []});
        const caller = await signUpAnonymously();
        await makeUser(caller.uid);

        const bad = await callFunction("resolveInviteCode", {code: "nope"}, caller.idToken);
        assert.equal(bad.error.details.reason, "code_format");
        const unauthenticated = await callFunction("resolveInviteCode", {code: await codeOf(owner)}, null);
        assert.equal(unauthenticated.error.status, "UNAUTHENTICATED");
        const own = await callFunction("resolveInviteCode", {code: await codeOf(caller.uid)}, caller.idToken);
        assert.equal(own.error.details.reason, "self_code");

        const code = await codeOf(owner);
        const found = await callFunction("resolveInviteCode", {code: code.toLowerCase()}, caller.idToken);
        assert.deepEqual(found.result, {uid: owner, displayName: "주인", profileImageUrl: null});

        const redeemed = await callFunction("redeemInviteCode", {code}, caller.idToken);
        assert.deepEqual(redeemed.result, {partnerId: owner, alreadyLinked: false});
        await waitFor(async () => (await plan(`${owner}_p`)).managerId === caller.uid, {label: "callable link"});
        const [connected] = await expectPushes(owner, 1, "callable partner_connected");
        assert.equal(connected.data.partnerId, caller.uid);
        const docs = await relationDocs(owner, caller.uid);
        assert.equal(docs.length, 2);
        assert.ok(docs.every((doc) => doc.data().createdBy === caller.uid && doc.data().inviterId === owner));
        await waitFor(async () => (await codeOf(owner)) !== code, {label: "code re-issued"});

        const reused = await callFunction("redeemInviteCode", {code}, caller.idToken);
        assert.equal(reused.error.details.reason, "not_found");
        const other = await signUpAnonymously();
        await makeUser(other.uid);
        const taken = await callFunction("redeemInviteCode", {code: await codeOf(owner)}, other.idToken);
        assert.equal(taken.error.details.reason, "owner_taken");
    });
});
