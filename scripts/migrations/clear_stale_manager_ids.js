#!/usr/bin/env node
/*
 * One-off migration: plans whose `managerId` has no matching relation.
 *
 * Before the 둘운완 release, disconnecting deleted only the relation docs and
 * left `plans.managerId` behind. With proof photos that stale managerId would
 * keep granting the ex-partner read access (storage.rules), so it must go.
 *
 *   Dry run (default, read-only):
 *     node scripts/migrations/clear_stale_manager_ids.js --project <projectId>
 *   Apply:
 *     node scripts/migrations/clear_stale_manager_ids.js --project <projectId> --apply [--backup <file>]
 *
 * Applying does exactly what the onRelationDeleted function does for a pair
 * (functions/src/planLinks.ts unlinkUpdate, shared via functions/lib):
 * managerId removed with the unlink time as the next manager's proof floor,
 * the partner's messages and the last-proof pointers cleared,
 * pending_approval → active, an in-progress promise (proposed/active) →
 * rejected, lastUpdatedBy = "system_unlink" (so onPlanUpdated sends no push).
 *
 * Each plan is re-read inside a transaction right before it is written, and
 * skipped when it was deleted, its managerId changed since the scan, or the
 * pair has linked again meanwhile (a link made during the run is never
 * undone). The previous values of every field the update touches are
 * appended to a JSON-lines backup first (default:
 * scripts/migrations/backups/clear_stale_manager_ids-<time>.jsonl, git-ignored),
 * so a plan detached by mistake can be restored. One failing plan does not
 * stop the run; the summary counts written / skipped / failed, and the exit
 * code is 1 when any failed. Re-running is safe: cleared plans have no
 * managerId any more.
 *
 * It also reports (never changes) users linked with more than one partner,
 * which the server-side 1:1 rule no longer allows.
 *
 * Credentials: Application Default Credentials
 * (`gcloud auth application-default login`) or GOOGLE_APPLICATION_CREDENTIALS.
 * Against the emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 ... --project demo-duounwan
 *
 * firebase-admin and the shared helpers come from functions/
 * (run `npm ci && npm run build` there first).
 */
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {createRequire} = require("node:module");

const FUNCTIONS_DIR = path.join(__dirname, "..", "..", "functions");
const functionsRequire = createRequire(path.join(FUNCTIONS_DIR, "package.json"));
const admin = functionsRequire("firebase-admin");
const {FieldValue, FieldPath} = functionsRequire("firebase-admin/firestore");

function loadPlanLinks() {
    const file = path.join(FUNCTIONS_DIR, "lib", "planLinks.js");
    if (!fs.existsSync(file)) {
        throw new Error(`${file} is missing: run \`npm ci && npm run build\` in functions/ first.`);
    }
    return require(file);
}
const {unlinkUpdate, PARTNER_CONTENT_FIELDS} = loadPlanLinks();
const FIELD_OPS = {deleteField: () => FieldValue.delete(), serverTimestamp: () => FieldValue.serverTimestamp()};
// Every field unlinkUpdate may change, for the backup.
const BACKUP_FIELDS = [
    "userId", "managerId", "state", "promise", "lastUpdatedBy", "managerSince", "managerSinceUid",
    "lastProofPhotoPath", "lastProofAt", ...PARTNER_CONTENT_FIELDS,
];

const PAGE_SIZE = 500;

function parseArgs(argv) {
    const args = {apply: false, project: null, verbose: false, backup: null};
    for (let i = 0; i < argv.length; i++) {
        const arg = argv[i];
        if (arg === "--apply") args.apply = true;
        else if (arg === "--dry-run") args.apply = false;
        else if (arg === "--verbose" || arg === "-v") args.verbose = true;
        else if (arg === "--project") args.project = argv[++i];
        else if (arg.startsWith("--project=")) args.project = arg.slice("--project=".length);
        else if (arg === "--backup") args.backup = argv[++i];
        else if (arg.startsWith("--backup=")) args.backup = arg.slice("--backup=".length);
        else if (arg === "--help" || arg === "-h") args.help = true;
        else throw new Error(`Unknown argument: ${arg}`);
    }
    return args;
}

const pairKey = (a, b) => [a, b].sort().join("|");
const isId = (value) => typeof value === "string" && value.length > 0;

async function* paged(query) {
    let last = null;
    for (;;) {
        let page = query.orderBy(FieldPath.documentId()).limit(PAGE_SIZE);
        if (last) page = page.startAfter(last);
        const snap = await page.get();
        for (const doc of snap.docs) yield doc;
        if (snap.size < PAGE_SIZE) return;
        last = snap.docs[snap.docs.length - 1];
    }
}

/** JSON-safe copy of a Firestore value (timestamps as ISO strings). */
function plain(value) {
    if (value === undefined) return null;
    if (value && typeof value.toDate === "function") return value.toDate().toISOString();
    if (Array.isArray(value)) return value.map(plain);
    if (value && typeof value === "object") {
        return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, plain(v)]));
    }
    return value;
}

function defaultBackupPath() {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    return path.join(__dirname, "backups", `clear_stale_manager_ids-${stamp}.jsonl`);
}

/**
 * Detaches one stale plan if it is still stale. Returns "written", or the
 * reason it was skipped.
 */
async function detachIfStillStale(db, scanned, appendBackup) {
    const relations = db.collection("relations");
    const {userId, managerId} = scanned.data();
    return db.runTransaction(async (tx) => {
        const [fresh, ab, ba] = await Promise.all([
            tx.get(scanned.ref),
            tx.get(relations.where("managerId", "==", userId).where("executorId", "==", managerId).limit(1)),
            tx.get(relations.where("managerId", "==", managerId).where("executorId", "==", userId).limit(1)),
        ]);
        if (!fresh.exists) return "deleted";
        const plan = fresh.data();
        if (plan.managerId !== managerId || plan.userId !== userId) return "changed";
        if (!ab.empty || !ba.empty) return "linked again";
        const previous = {};
        for (const field of BACKUP_FIELDS) {
            if (field in plan) previous[field] = plain(plan[field]);
        }
        appendBackup({id: fresh.id, at: new Date().toISOString(), previous});
        tx.update(fresh.ref, unlinkUpdate(plan, FIELD_OPS));
        return "written";
    });
}

async function main() {
    const args = parseArgs(process.argv.slice(2));
    if (args.help || !args.project) {
        console.log("Usage: node scripts/migrations/clear_stale_manager_ids.js --project <projectId> " +
            "[--apply] [--backup <file>] [--verbose]");
        process.exit(args.help ? 0 : 1);
    }

    const emulator = process.env.FIRESTORE_EMULATOR_HOST;
    admin.initializeApp({projectId: args.project});
    const db = admin.firestore();
    console.log(`Project: ${args.project}${emulator ? ` (emulator ${emulator})` : ""}`);
    console.log(`Mode: ${args.apply ? "APPLY (writes)" : "dry run (read-only)"}`);

    // 1. Every linked pair, and each user's partners.
    const pairs = new Set();
    const partnersByUser = new Map();
    let relationCount = 0;
    for await (const doc of paged(db.collection("relations"))) {
        relationCount++;
        const {managerId, executorId} = doc.data();
        if (!isId(managerId) || !isId(executorId) || managerId === executorId) continue;
        pairs.add(pairKey(managerId, executorId));
        for (const [me, other] of [[managerId, executorId], [executorId, managerId]]) {
            if (!partnersByUser.has(me)) partnersByUser.set(me, new Set());
            partnersByUser.get(me).add(other);
        }
    }

    // 2. Plans whose managerId is not a linked partner of the owner.
    const stale = [];
    let planCount = 0;
    let managedCount = 0;
    for await (const doc of paged(db.collection("plans"))) {
        planCount++;
        const plan = doc.data();
        if (!isId(plan.managerId)) continue;
        managedCount++;
        const linked = isId(plan.userId) && plan.userId !== plan.managerId &&
            pairs.has(pairKey(plan.userId, plan.managerId));
        if (!linked) stale.push(doc);
    }

    const multiPartner = [...partnersByUser.entries()].filter(([, partners]) => partners.size > 1);

    console.log(`relations: ${relationCount} docs, ${pairs.size} linked pairs`);
    console.log(`plans: ${planCount} total, ${managedCount} with a managerId, ${stale.length} stale`);
    const byState = {};
    for (const doc of stale) {
        const plan = doc.data();
        const key = `${plan.state || "?"}${plan.promise && plan.promise.status ? ` / promise ${plan.promise.status}` : ""}`;
        byState[key] = (byState[key] || 0) + 1;
        if (args.verbose) {
            const title = Array.isArray(plan.items) && plan.items[0] ? plan.items[0].title : "";
            console.log(`  stale plan ${doc.id} owner=${plan.userId} manager=${plan.managerId} state=${plan.state} "${title || ""}"`);
        }
    }
    for (const [key, count] of Object.entries(byState)) console.log(`  ${key}: ${count}`);
    console.log(`users linked with more than one partner (report only): ${multiPartner.length}`);
    if (args.verbose) {
        for (const [uid, partners] of multiPartner) console.log(`  ${uid}: ${[...partners].join(", ")}`);
    }

    if (!args.apply) {
        console.log("Dry run only. Re-run with --apply to clear the stale managerIds.");
        return;
    }
    if (stale.length === 0) {
        console.log("Nothing to clear.");
        return;
    }

    const backupPath = path.resolve(args.backup || defaultBackupPath());
    fs.mkdirSync(path.dirname(backupPath), {recursive: true});
    const appendBackup = (entry) => fs.appendFileSync(backupPath, `${JSON.stringify(entry)}\n`);
    console.log(`Backup of previous values: ${backupPath}`);

    const outcomes = {};
    let failed = 0;
    for (const doc of stale) {
        try {
            const outcome = await detachIfStillStale(db, doc, appendBackup);
            outcomes[outcome] = (outcomes[outcome] || 0) + 1;
            if (args.verbose && outcome !== "written") console.log(`  skipped ${doc.id}: ${outcome}`);
        } catch (error) {
            failed++;
            console.error(`  failed ${doc.id}:`, error.message || error);
        }
    }
    const skipped = Object.entries(outcomes).filter(([key]) => key !== "written");
    console.log(`Cleared managerId on ${outcomes.written || 0} plans.`);
    console.log(`Skipped: ${skipped.length ? skipped.map(([key, n]) => `${n} ${key}`).join(", ") : "none"}.`);
    if (failed) {
        console.log(`Failed: ${failed} (re-run to retry them).`);
        process.exitCode = 1;
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
