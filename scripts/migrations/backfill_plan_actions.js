#!/usr/bin/env node
/*
 * Backfill: an `actions` document for every day of a plan's record arrays
 * that has none (plans 기록 배열 → actions 정규화, docs/work/
 * REMAINING_IMPROVEMENTS.md §3, 3–4단계).
 *
 * The app (build 88+) reads record days from actions first and from the
 * arrays for the rest; builds ≤ 1.1.2+87 and the Cloud Functions read only
 * the arrays, which keep being written. Nothing here changes or removes an
 * array. Once every day has its action, the arrays can stop being the source
 * (5단계, a later release).
 *
 *   Dry run (default, read-only) — counts of what would be created:
 *     node scripts/migrations/backfill_plan_actions.js --project <projectId> [--verbose]
 *   Verify (read-only) — array days vs action days per plan, mismatches listed:
 *     node scripts/migrations/backfill_plan_actions.js --project <projectId> --verify [--verbose]
 *   Apply:
 *     node scripts/migrations/backfill_plan_actions.js --project <projectId> --apply --guard-deployed [--backup <file>]
 *   Any mode for one owner or one plan (spot checks):
 *     ... --user <uid>   |   ... --plan <planId>
 *
 * What is created, per (plan, type, owner-local day) missing an action of
 * that type by the plan owner on that plan (functions/src/actionsBackfill.ts,
 * shared with the tests): `actions/backfill_{planId}_{type}_{YYYYMMDD}` =
 * {userId, planId, type, date: the array's moment, title, createdAt: the
 * same moment, backfilled: true}. The id is deterministic, so re-runs and
 * overlapping runs never duplicate a record; days are counted in the owner's
 * `users/{uid}.timezone` (default Asia/Seoul), like the functions.
 * `verifiedDates` is not backfilled (인정 lives on an existing record as
 * `verifiedBy`, whose author an array can't tell); --verify reports it.
 *
 * --guard-deployed is required with --apply: every new action fires
 * onActionCompleted. Only functions with the `backfilled` guard (this
 * commit) skip the partner push for it (they still stamp `managerId`, which
 * shares it with the partner under firestore.rules.next). Without that
 * deploy, a run would push "짝꿍이 했대요" for every backfilled record.
 *
 * Applying re-reads each plan and its actions inside one transaction right
 * before writing (≤450 creates per transaction), so a record written during
 * the run is never duplicated. Each created id is appended to a JSON-lines
 * backup (default: scripts/migrations/backups/backfill_plan_actions-<time>.jsonl,
 * git-ignored), one line per action: {"id", "planId", "type", "day", "at"} —
 * to undo, delete those ids (all carry `backfilled: true`). One failing plan
 * does not stop the run; the exit code is 1 when any failed. Re-running is
 * safe: covered days are left alone.
 *
 * Credentials: Application Default Credentials
 * (`gcloud auth application-default login`) or GOOGLE_APPLICATION_CREDENTIALS.
 * Against the emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 ... --project demo-duounwan
 *
 * firebase-admin and the shared helpers come from functions/
 * (run `npm ci && npm run build` there first).
 */
"use strict";

const {admin, FieldValue, CHUNK_SIZE, loadFunctionsLib, parseArgs, openDb, paged, openBackup} = require("./lib");

const {planActionBackfill, backfillActionData, compareRecordDays, hasMismatch, RECORD_TYPES} =
    loadFunctionsLib("actionsBackfill");
const {resolveTimeZone} = loadFunctionsLib("time");
const {Timestamp} = admin.firestore;

const PLAN_FIELDS = ["userId", "items", "completedDates", "skippedDates", "restedDates", "rescuedDates",
    "verifiedDates"];
const ACTION_FIELDS = ["userId", "planId", "type", "date", "verifiedBy"];

/** Takes `--<name> <value>` / `--<name>=<value>` out of `argv`. */
function takeOption(argv, name) {
    let value = null;
    const rest = [];
    for (let i = 0; i < argv.length; i++) {
        if (argv[i] === `--${name}`) value = argv[++i] ?? null;
        else if (argv[i].startsWith(`--${name}=`)) value = argv[i].slice(name.length + 3);
        else rest.push(argv[i]);
    }
    return {value, rest};
}

function usage() {
    return "Usage: node scripts/migrations/backfill_plan_actions.js --project <projectId> " +
        "[--verify | --apply --guard-deployed] [--user <uid> | --plan <planId>] [--backup <file>] [--verbose]";
}

/** The plans in scope, as {id, data}. */
async function loadPlans(db, scope) {
    const plans = db.collection("plans");
    if (scope.plan) {
        const snap = await plans.doc(scope.plan).get();
        return snap.exists ? [{id: snap.id, data: snap.data()}] : [];
    }
    const query = scope.user ? plans.where("userId", "==", scope.user) : plans;
    const result = [];
    for await (const doc of paged(query.select(...PLAN_FIELDS))) result.push({id: doc.id, data: doc.data()});
    return result;
}

/** The actions of the plans in scope, grouped by planId. */
async function loadActions(db, scope, planIds) {
    const byPlan = new Map(planIds.map((id) => [id, []]));
    const actions = db.collection("actions");
    let query = actions;
    if (scope.plan) query = actions.where("planId", "==", scope.plan);
    else if (scope.user) query = actions.where("userId", "==", scope.user);
    for await (const doc of paged(query.select(...ACTION_FIELDS))) {
        const action = doc.data();
        byPlan.get(action.planId)?.push(action);
    }
    return byPlan;
}

/** Each plan owner's time zone (users/{uid}.timezone). */
async function loadTimeZones(db, userIds) {
    const zones = new Map();
    const ids = [...new Set(userIds.filter((id) => typeof id === "string" && id))];
    for (let i = 0; i < ids.length; i += 100) {
        const refs = ids.slice(i, i + 100).map((id) => db.collection("users").doc(id));
        const snaps = await db.getAll(...refs, {fieldMask: ["timezone"]});
        for (const snap of snaps) zones.set(snap.id, resolveTimeZone(snap.data()?.timezone));
    }
    return (uid) => zones.get(uid) ?? resolveTimeZone(null);
}

function summarizeVerify(plans, actionsByPlan, zoneOf, verbose) {
    const totals = Object.fromEntries([...RECORD_TYPES, "verified"].map((kind) =>
        [kind, {arrays: 0, actions: 0, onlyInArrays: 0, onlyInActions: 0}]));
    let mismatched = 0;
    for (const {id, data} of plans) {
        const comparison = compareRecordDays(id, data, actionsByPlan.get(id) ?? [], zoneOf(data.userId));
        for (const c of comparison) {
            const t = totals[c.kind];
            t.arrays += c.arrays;
            t.actions += c.actions;
            t.onlyInArrays += c.onlyInArrays.length;
            t.onlyInActions += c.onlyInActions.length;
        }
        if (!hasMismatch(comparison)) continue;
        mismatched++;
        console.log(`  plan ${id} (owner ${data.userId || "-"}):`);
        for (const c of comparison) {
            if (c.onlyInArrays.length === 0 && c.onlyInActions.length === 0) continue;
            const list = (days) => (verbose || days.length <= 5 ? days.join(", ") : `${days.slice(0, 5).join(", ")}, …`);
            console.log(`    ${c.kind}: arrays ${c.arrays} days, actions ${c.actions} days` +
                (c.onlyInArrays.length ? `; only in arrays: ${list(c.onlyInArrays)}` : "") +
                (c.onlyInActions.length ? `; only in actions: ${list(c.onlyInActions)}` : ""));
        }
    }
    console.log(`verify: ${plans.length} plans, ${mismatched} with a mismatch`);
    for (const [kind, t] of Object.entries(totals)) {
        console.log(`  ${kind}: ${t.arrays} array days, ${t.actions} action days, ` +
            `${t.onlyInArrays} only in arrays, ${t.onlyInActions} only in actions`);
    }
    console.log("Only in arrays: what --apply creates (verified excepted). Only in actions: days the app " +
        "(build 88+) shows from actions that older builds and the functions don't (their arrays lack them).");
}

/** Plans and creates for one plan, re-read inside a transaction; returns {created, failed?}. */
async function applyPlan(db, planId, zoneOf, backup) {
    const planRef = db.collection("plans").doc(planId);
    const actionsQuery = db.collection("actions").where("planId", "==", planId);
    let created = 0;
    for (;;) {
        const wrote = await db.runTransaction(async (tx) => {
            const planSnap = await tx.get(planRef);
            if (!planSnap.exists) return 0;
            const plan = planSnap.data();
            const actions = (await tx.get(actionsQuery)).docs.map((doc) => doc.data());
            const {creates} = planActionBackfill(planId, plan, actions, zoneOf(plan.userId));
            const batch = creates.slice(0, CHUNK_SIZE);
            if (batch.length === 0) return 0;
            const refs = batch.map((c) => db.collection("actions").doc(c.id));
            const existing = await tx.getAll(...refs);
            let writes = 0;
            batch.forEach((planned, i) => {
                // Same id = same (plan, type, day): written by an earlier run.
                if (existing[i].exists) return;
                const data = backfillActionData(planId, plan, planned);
                tx.create(refs[i], {
                    ...data,
                    date: Timestamp.fromDate(planned.date),
                    createdAt: Timestamp.fromDate(planned.date),
                    backfilledAt: FieldValue.serverTimestamp(),
                });
                backup.append({id: planned.id, planId, type: planned.type, day: planned.day,
                    at: new Date().toISOString()});
                writes++;
            });
            return writes;
        });
        created += wrote;
        // A full chunk may leave more; anything else is done.
        if (wrote < CHUNK_SIZE) return created;
    }
}

async function main() {
    const user = takeOption(process.argv.slice(2), "user");
    const plan = takeOption(user.rest, "plan");
    const args = parseArgs(plan.rest, ["verify", "guard-deployed"]);
    const scope = {user: user.value, plan: plan.value};
    if (args.help || !args.project || (scope.user && scope.plan) || (args.verify && args.apply)) {
        console.log(usage());
        process.exit(args.help ? 0 : 1);
    }
    if (args.apply && !args["guard-deployed"]) {
        console.error("--apply needs --guard-deployed: deploy the functions with the `backfilled` guard " +
            "(onActionCompleted / notifyUnverifiedActions skip backfilled actions) first, or every created " +
            "action pushes the partner.");
        process.exit(1);
    }
    const db = openDb(args);
    if (scope.user) console.log(`Scope: plans of user ${scope.user}`);
    if (scope.plan) console.log(`Scope: plan ${scope.plan}`);

    const plans = await loadPlans(db, scope);
    const actionsByPlan = await loadActions(db, scope, plans.map((p) => p.id));
    const zoneOf = await loadTimeZones(db, plans.map((p) => p.data.userId));

    if (args.verify) {
        summarizeVerify(plans, actionsByPlan, zoneOf, args.verbose);
        return;
    }

    const counts = Object.fromEntries(RECORD_TYPES.map((type) => [type, 0]));
    const covered = Object.fromEntries(RECORD_TYPES.map((type) => [type, 0]));
    const pending = [];
    let noOwner = 0;
    for (const {id, data} of plans) {
        const result = planActionBackfill(id, data, actionsByPlan.get(id) ?? [], zoneOf(data.userId));
        if (!result.userId) noOwner++;
        for (const type of RECORD_TYPES) covered[type] += result.covered[type];
        for (const c of result.creates) counts[c.type]++;
        if (result.creates.length === 0) continue;
        pending.push(id);
        if (args.verbose) {
            console.log(`  plan ${id} (owner ${result.userId}): ` +
                result.creates.map((c) => `${c.type} ${c.day}`).join(", "));
        }
    }
    const total = Object.values(counts).reduce((a, b) => a + b, 0);
    console.log(`plans: ${plans.length} scanned, ${pending.length} missing actions` +
        (noOwner ? `, ${noOwner} without an owner (skipped)` : ""));
    for (const type of RECORD_TYPES) {
        console.log(`  ${type}: ${covered[type]} array days covered, ${counts[type]} to create`);
    }
    console.log(`actions to create: ${total}`);

    if (!args.apply) {
        console.log("Dry run only. Re-run with --apply --guard-deployed to write (or --verify to compare).");
        return;
    }
    if (pending.length === 0) {
        console.log("Nothing to create.");
        return;
    }

    const backup = openBackup(args, "backfill_plan_actions");
    let created = 0;
    let failed = 0;
    for (const planId of pending) {
        try {
            created += await applyPlan(db, planId, zoneOf, backup);
        } catch (error) {
            failed++;
            console.error(`  plan ${planId} failed:`, error.message || error);
        }
    }
    console.log(`Created ${created} actions (${total - created} covered meanwhile or already there).`);
    if (failed) {
        console.log(`Failed: ${failed} plans (re-run to retry them).`);
        process.exitCode = 1;
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
