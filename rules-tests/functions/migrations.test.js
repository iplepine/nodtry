// The migrations in scripts/migrations, run against the emulators (with the
// triggers live, as in production). Run from rules-tests/: npm run emulators:functions
const {describe, it} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {execFile} = require("node:child_process");
const {promisify} = require("node:util");
const {randomUUID} = require("node:crypto");
const admin = require("firebase-admin");

const PROJECT_ID = "demo-duounwan";
if (admin.apps.length === 0) admin.initializeApp({projectId: PROJECT_ID});
const db = admin.firestore();
const {FieldValue, Timestamp} = admin.firestore;

const MIGRATIONS = path.join(__dirname, "..", "..", "scripts", "migrations");
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const uid = (prefix) => `${prefix}_${randomUUID().slice(0, 8)}`;

async function waitFor(check, {timeout = 20000, label = "condition"} = {}) {
    const started = Date.now();
    for (;;) {
        if (await check()) return;
        if (Date.now() - started > timeout) throw new Error(`Timed out waiting for ${label}`);
        await sleep(250);
    }
}

/** Runs a migration script; resolves {code, out} (never rejects on a non-zero exit). */
async function migrate(script, args) {
    try {
        const {stdout, stderr} = await promisify(execFile)(process.execPath,
            [path.join(MIGRATIONS, script), "--project", PROJECT_ID, ...args], {env: process.env});
        return {code: 0, out: stdout + stderr};
    } catch (error) {
        return {code: error.code, out: `${error.stdout}${error.stderr}`};
    }
}

function readBackup(file) {
    if (!fs.existsSync(file)) return [];
    return fs.readFileSync(file, "utf8").trim().split("\n").filter(Boolean).map((line) => JSON.parse(line));
}

const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "duounwan-migrations-"));

describe("migrations (emulator)", () => {
    it("backfill_action_manager_ids: dry run writes nothing, --apply syncs, a re-run is a no-op", async () => {
        const a = uid("alice");
        const b = uid("bob");
        const m = uid("mallory");
        for (const id of [a, b, m]) {
            await db.doc(`users/${id}`).set({displayName: id, inviteCode: `C${randomUUID().slice(0, 7).toUpperCase()}`});
        }
        const shared = `${a}_shared`;
        await db.doc(`plans/${shared}`).set({userId: a, state: "active", items: []});
        // a ⇄ b, stamped like the app's connectWithCode (onRelationCreated
        // undoes unstamped links); the server hands a's plan to b.
        const stamp = {inviterId: a, inviteCode: (await db.doc(`users/${a}`).get()).data().inviteCode,
            status: "active", createdAt: FieldValue.serverTimestamp()};
        const batch = db.batch();
        batch.set(db.collection("relations").doc(), {managerId: a, executorId: b, ...stamp});
        batch.set(db.collection("relations").doc(), {managerId: b, executorId: a, ...stamp});
        await batch.commit();
        await waitFor(async () => (await db.doc(`plans/${shared}`).get()).data().managerId === b, {label: "link"});

        const add = (data) => db.collection("actions").add({userId: a, type: "done", date: Timestamp.now(), ...data});
        const legacy = [await add({planId: shared}), await add({planId: shared, type: "skipped"})];
        const wrong = await add({planId: shared});
        const orphan = await add({planId: `${a}_deleted`});
        for (const ref of [...legacy, wrong]) {
            await waitFor(async () => (await ref.get()).data().managerId === b, {label: "trigger stamp"});
        }
        await sleep(1000); // the orphan's trigger (nothing to stamp) has run too
        // Turn them into what builds ≤80 left behind (actions have no update trigger).
        for (const ref of legacy) await ref.update({managerId: FieldValue.delete()});
        await wrong.update({managerId: m});
        await orphan.update({managerId: b});

        const mine = [...legacy, wrong, orphan];
        const state = async () => Object.fromEntries(await Promise.all(
            mine.map(async (ref) => [ref.id, (await ref.get()).data().managerId ?? null])));

        const before = await state();
        const dry = await migrate("backfill_action_manager_ids.js", []);
        assert.equal(dry.code, 0, dry.out);
        assert.match(dry.out, /Dry run only/);
        assert.deepEqual(await state(), before);

        const backup = path.join(scratch, "backfill.jsonl");
        const applied = await migrate("backfill_action_manager_ids.js", ["--apply", "--backup", backup]);
        assert.equal(applied.code, 0, applied.out);
        const after = await state();
        assert.deepEqual(after, {[legacy[0].id]: b, [legacy[1].id]: b, [wrong.id]: b, [orphan.id]: null});
        const byId = Object.fromEntries(readBackup(backup).map((line) => [line.id, line]));
        assert.deepEqual(byId[legacy[0].id].previous, {present: false, managerId: null});
        assert.equal(byId[legacy[0].id].next, b);
        assert.deepEqual(byId[wrong.id].previous, {present: true, managerId: m});
        assert.deepEqual(byId[orphan.id].previous, {present: true, managerId: b});
        assert.equal(byId[orphan.id].next, null, "plan gone: unshared");

        const again = path.join(scratch, "backfill-again.jsonl");
        const rerun = await migrate("backfill_action_manager_ids.js", ["--apply", "--backup", again]);
        assert.equal(rerun.code, 0, rerun.out);
        const ids = new Set(mine.map((ref) => ref.id));
        assert.deepEqual(readBackup(again).filter((line) => ids.has(line.id)), []);
        assert.deepEqual(await state(), after);
    });

    it("strip_user_emails: refuses before minBuild 81, then removes the field with a backup", async () => {
        const withEmail = uid("e");
        const withNull = uid("n");
        const without = uid("w");
        await db.doc(`users/${withEmail}`).set({displayName: "E", email: "e@example.com", inviteCode: "EEEE2345"});
        await db.doc(`users/${withNull}`).set({displayName: "N", email: null});
        await db.doc(`users/${without}`).set({displayName: "W"});
        const configRef = db.doc("config/app");
        const config = (await configRef.get()).data() || {};
        await configRef.set({minBuild: 80}, {merge: true});
        try {
            const dry = await migrate("strip_user_emails.js", []);
            assert.equal(dry.code, 0, dry.out);
            assert.equal((await db.doc(`users/${withEmail}`).get()).data().email, "e@example.com");

            const refused = await migrate("strip_user_emails.js", ["--apply"]);
            assert.equal(refused.code, 2, refused.out);
            assert.equal((await db.doc(`users/${withEmail}`).get()).data().email, "e@example.com");

            await configRef.set({minBuild: 81}, {merge: true});
            const backup = path.join(scratch, "emails.jsonl");
            const applied = await migrate("strip_user_emails.js", ["--apply", "--backup", backup]);
            assert.equal(applied.code, 0, applied.out);
            for (const id of [withEmail, withNull, without]) {
                const user = (await db.doc(`users/${id}`).get()).data();
                assert.equal("email" in user, false, id);
                assert.ok(user.displayName);
            }
            assert.equal((await db.doc(`users/${withEmail}`).get()).data().inviteCode, "EEEE2345");
            const lines = readBackup(backup);
            assert.deepEqual(lines.find((line) => line.id === withEmail).previous, {email: "e@example.com"});
            assert.deepEqual(lines.find((line) => line.id === withNull).previous, {email: null});
            assert.equal(lines.some((line) => line.id === without), false);

            const rerun = await migrate("strip_user_emails.js", ["--apply", "--backup", path.join(scratch, "e2.jsonl")]);
            assert.equal(rerun.code, 0, rerun.out);
            assert.match(rerun.out, /Nothing to remove/);
        } finally {
            await configRef.set({minBuild: config.minBuild ?? FieldValue.delete()}, {merge: true});
        }
    });
});
