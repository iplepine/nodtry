// Invite re-engagement on the emulators: the link and account-deletion
// triggers keep invites/{uid} right, and the hourly job (run directly, with a
// fixed clock and a recording sender) sends the right reminders once.
// Run from rules-tests/: npm run emulators:functions
const {describe, it, before} = require("node:test");
const assert = require("node:assert/strict");
const path = require("node:path");
const {randomUUID} = require("node:crypto");
const admin = require("firebase-admin");

const PROJECT_ID = "demo-duounwan";
if (admin.apps.length === 0) admin.initializeApp({projectId: PROJECT_ID});
const db = admin.firestore();
const {FieldValue, Timestamp} = admin.firestore;

// The job runs on the functions package's own firebase-admin (its own app).
const FUNCTIONS_DIR = path.join(__dirname, "..", "..", "functions");
const fnAdmin = require(path.join(FUNCTIONS_DIR, "node_modules", "firebase-admin"));
if (fnAdmin.apps.length === 0) fnAdmin.initializeApp({projectId: PROJECT_ID});
const inviteReminder = require(path.join(FUNCTIONS_DIR, "lib", "inviteReminder"));

const HOUR = 60 * 60 * 1000;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const uid = (prefix) => `${prefix}_${randomUUID().slice(0, 8)}`;

async function waitFor(check, {timeout = 20000, interval = 250, label = "condition"} = {}) {
    const started = Date.now();
    for (;;) {
        const value = await check();
        if (value) return value;
        if (Date.now() - started > timeout) throw new Error(`Timed out waiting for ${label}`);
        await sleep(interval);
    }
}

async function makeUser(id, extra = {}) {
    await db.doc(`users/${id}`).set({
        displayName: id.split("_")[0],
        fcmToken: `token-${id}`,
        inviteCode: `INV${randomUUID().slice(0, 5).toUpperCase()}`,
        createdAt: Timestamp.now(),
        ...extra,
    });
}

async function shareInvite(id, sharedAtMs, extra = {}) {
    await db.doc(`invites/${id}`).set({
        inviterUid: id,
        code: (await db.doc(`users/${id}`).get()).data().inviteCode,
        createdAt: Timestamp.fromMillis(sharedAtMs),
        lastSharedAt: Timestamp.fromMillis(sharedAtMs),
        shareCount: 1,
        ...extra,
    });
}

/** Like the app's connectWithCode batch, stamped with the inviter's code. */
async function link(inviter, enterer) {
    const code = (await db.doc(`users/${inviter}`).get()).data().inviteCode;
    const fields = {
        status: "active", createdAt: FieldValue.serverTimestamp(), connectedAt: FieldValue.serverTimestamp(),
        inviterId: inviter, inviteCode: code,
    };
    const batch = db.batch();
    batch.set(db.collection("relations").doc(), {managerId: inviter, executorId: enterer, ...fields});
    batch.set(db.collection("relations").doc(), {managerId: enterer, executorId: inviter, ...fields});
    await batch.commit();
}

function recordingDeps() {
    const sent = [];
    return {
        sent,
        deps: {
            tokenOf: async (id, user) => user?.fcmToken ?? null,
            send: async (to, token, copy, data) => {
                sent.push({to, token, copy, data});
                return true;
            },
        },
    };
}

describe("invite reminders (emulator)", () => {
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

    it("onRelationCreated marks the inviter's invite connected", async () => {
        const a = uid("alice");
        const b = uid("bob");
        await makeUser(a);
        await makeUser(b);
        await shareInvite(a, Date.now() - HOUR);
        await link(a, b);
        const connected = await waitFor(async () => (await db.doc(`invites/${a}`).get()).data().connectedAt,
            {label: "connectedAt"});
        assert.ok(connected.toMillis() > Date.now() - 5 * 60 * 1000);
        // The invitee never shared: no doc is made for them.
        assert.equal((await db.doc(`invites/${b}`).get()).exists, false);
    });

    it("account deletion removes the invite", async () => {
        const user = await admin.auth().createUser({});
        await makeUser(user.uid);
        await shareInvite(user.uid, Date.now() - HOUR);
        await admin.auth().deleteUser(user.uid);
        await waitFor(async () => !(await db.doc(`invites/${user.uid}`).get()).exists, {label: "invite deleted"});
    });

    it("the job sends #1 then #2, once each, and skips the connected, the deleted and the night", async () => {
        // 14:00 in Seoul, today.
        const now = new Date();
        now.setUTCHours(5, 0, 0, 0);
        const nowMs = now.getTime();

        const first = uid("first");
        const english = uid("english");
        const second = uid("second");
        const partnered = uid("partnered");
        const partner = uid("partner");
        const night = uid("night");
        const gone = uid("gone");
        await Promise.all([
            makeUser(first, {timezone: "Asia/Seoul", locale: "ko"}),
            makeUser(english, {locale: "en"}),
            makeUser(second),
            makeUser(partnered),
            makeUser(partner),
            makeUser(night, {timezone: "America/New_York"}), // 00:00 there
            makeUser(gone),
        ]);
        await shareInvite(first, nowMs - 25 * HOUR);
        await shareInvite(english, nowMs - 25 * HOUR);
        const shared73 = nowMs - 73 * HOUR;
        await shareInvite(second, shared73, {
            remindersSent: 1,
            remindersCycleAt: Timestamp.fromMillis(shared73),
            lastReminderAt: Timestamp.fromMillis(shared73 + 30 * HOUR),
        });
        // Linked before this share's doc existed, so nothing marked it
        // connected: the job finds the partner itself.
        const codeBefore = (await db.doc(`users/${partner}`).get()).data().inviteCode;
        await link(partner, partnered);
        await waitFor(async () => (await db.doc(`users/${partner}`).get()).data().inviteCode !== codeBefore,
            {label: "link settled"});
        await shareInvite(partnered, nowMs - 25 * HOUR);
        await shareInvite(night, nowMs - 25 * HOUR);
        await shareInvite(gone, nowMs - 25 * HOUR);
        await db.doc(`users/${gone}`).delete();

        const mine = new Set([first, english, second, partnered, night, gone]);
        const run = async () => {
            const {sent, deps} = recordingDeps();
            await inviteReminder.runInviteReminders(deps, now);
            return sent.filter((push) => mine.has(push.to));
        };

        const sent = await run();
        const byUser = new Map(sent.map((push) => [push.to, push]));
        assert.deepEqual([...byUser.keys()].sort(), [english, first, second].sort());
        assert.deepEqual(byUser.get(first).data, {type: "invite_reminder", reminder: "1"});
        assert.equal(byUser.get(first).copy.body, "링크를 한 번 더 보내볼까요?");
        assert.match(byUser.get(english).copy.title, /partner/);
        assert.deepEqual(byUser.get(second).data, {type: "invite_reminder", reminder: "2"});

        const firstDoc = (await db.doc(`invites/${first}`).get()).data();
        assert.equal(firstDoc.remindersSent, 1);
        assert.equal(firstDoc.remindersCycleAt.toMillis(), nowMs - 25 * HOUR);
        assert.equal((await db.doc(`invites/${second}`).get()).data().remindersSent, 2);
        assert.ok((await db.doc(`invites/${partnered}`).get()).data().connectedAt);

        // The same hour again: nothing more.
        assert.deepEqual(await run(), []);
    });

    it("a failed send is not counted", async () => {
        const now = new Date();
        now.setUTCHours(5, 0, 0, 0);
        const id = uid("fail");
        await makeUser(id);
        await shareInvite(id, now.getTime() - 25 * HOUR);
        await inviteReminder.runInviteReminders({
            tokenOf: async (_, user) => user?.fcmToken ?? null,
            send: async () => false,
        }, now);
        const data = (await db.doc(`invites/${id}`).get()).data();
        assert.equal(data.remindersSent, undefined);
        assert.equal(data.lastReminderAt, undefined);
    });
});
