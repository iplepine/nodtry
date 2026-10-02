#!/usr/bin/env node
/*
 * Backfill: actions.managerId ← the current manager of the action's plan.
 *
 * firestore.rules.next lets a partner list the owner's actions only through
 * `actions.managerId`. From the functions release of the rules.next bundle on,
 * the Cloud Functions keep it in sync (onActionCompleted stamps every new
 * action; link, unlink, guard detach, plan and account deletion re-sync).
 * This brings the actions written before that in line. Run it after those
 * functions are deployed, before the rules flip, and once more right after
 * the flip (docs/operations/SECURITY_RULES.md, "읽기 축소 전환").
 *
 *   Dry run (default, read-only):
 *     node scripts/migrations/backfill_action_manager_ids.js --project <projectId>
 *   Apply:
 *     node scripts/migrations/backfill_action_manager_ids.js --project <projectId> --apply [--backup <file>]
 *
 * The value is planLinks.actionManagerFor (functions/lib, shared with the
 * triggers): the plan's managerId when the action is the plan owner's own
 * record, nothing otherwise. So the run also removes a wrong or stale
 * managerId, and the one of an action whose plan is gone. It never shares an
 * action with someone who is not linked with its owner (relations): the
 * actions of a plan whose manager is not a linked partner get no managerId,
 * and those plans are reported — detach them with clear_stale_manager_ids.js.
 *
 * Applying re-reads each chunk of actions (≤450) and their plans inside one
 * transaction right before writing, so a link / unlink during the run is
 * never overwritten with the scan's view. Before each write the previous
 * value is appended to a JSON-lines backup (default:
 * scripts/migrations/backups/backfill_action_manager_ids-<time>.jsonl,
 * git-ignored), one line per action:
 *   {"id", "planId", "at", "previous": {"present": bool, "managerId": value|null}, "next": uid|null}
 * (a retried transaction may log an action twice; the first line is the
 * original value). One failing chunk does not stop the run; the exit code is
 * 1 when any failed. Re-running is safe: in-sync actions are left alone.
 *
 * Credentials: Application Default Credentials
 * (`gcloud auth application-default login`) or GOOGLE_APPLICATION_CREDENTIALS.
 * Against the emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 ... --project demo-duounwan
 *
 * firebase-admin and the shared helpers come from functions/
 * (run `npm ci && npm run build` there first).
 */
"use strict";

const {
    FieldValue, loadFunctionsLib, parseArgs, openDb, paged, plain, openBackup, chunks, isId, pairKey,
} = require("./lib");

const {actionManagerFor} = loadFunctionsLib("planLinks");

function describeChange(from, to) {
    if (from === undefined) return "set";
    if (to === null) return "clear";
    return "change";
}

async function main() {
    const args = parseArgs(process.argv.slice(2));
    if (args.help || !args.project) {
        console.log("Usage: node scripts/migrations/backfill_action_manager_ids.js --project <projectId> " +
            "[--apply] [--backup <file>] [--verbose]");
        process.exit(args.help ? 0 : 1);
    }
    const db = openDb(args);

    // 1. Linked pairs (a managerId is only ever added for a linked partner).
    const pairs = new Set();
    for await (const doc of paged(db.collection("relations").select("managerId", "executorId"))) {
        const {managerId, executorId} = doc.data();
        if (isId(managerId) && isId(executorId) && managerId !== executorId) pairs.add(pairKey(managerId, executorId));
    }
    const linked = (a, b) => isId(a) && isId(b) && pairs.has(pairKey(a, b));
    // What the triggers write, except that nobody unlinked is ever added.
    const targetFor = (action, plan) => {
        const want = actionManagerFor(action, plan);
        return want !== null && !linked(plan.userId, want) ? null : want;
    };

    // 2. Every plan's owner and manager.
    const plans = new Map();
    const stalePlans = new Set();
    for await (const doc of paged(db.collection("plans").select("userId", "managerId"))) {
        const plan = doc.data();
        plans.set(doc.id, plan);
        if (isId(plan.managerId) && plan.managerId !== plan.userId && !linked(plan.userId, plan.managerId)) {
            stalePlans.add(doc.id);
        }
    }

    // 3. Actions whose managerId differs from what their plan says.
    const counts = {scanned: 0, inSync: 0, set: 0, change: 0, clear: 0, staleManager: 0};
    const pending = [];
    for await (const doc of paged(db.collection("actions").select("userId", "planId", "managerId"))) {
        counts.scanned++;
        const action = doc.data();
        const planId = isId(action.planId) ? action.planId : null;
        const plan = planId ? plans.get(planId) ?? null : null;
        const want = targetFor(action, plan);
        const have = "managerId" in action ? action.managerId : undefined;
        if (plan && isId(plan.managerId) && want === null && stalePlans.has(planId)) counts.staleManager++;
        if (want === null ? have === undefined : have === want) {
            counts.inSync++;
            continue;
        }
        const kind = describeChange(have, want);
        counts[kind]++;
        pending.push({ref: doc.ref, id: doc.id, planId});
        if (args.verbose) {
            console.log(`  ${kind} ${doc.id} (plan ${planId}): ${have === undefined ? "-" : have} → ${want || "-"}`);
        }
    }

    console.log(`relations: ${pairs.size} linked pairs; plans: ${plans.size}, ` +
        `${stalePlans.size} with a manager who is not a linked partner`);
    if (args.verbose) for (const id of stalePlans) console.log(`  stale manager on plan ${id}`);
    console.log(`actions: ${counts.scanned} scanned, ${counts.inSync} in sync, ${counts.set} to stamp, ` +
        `${counts.change} to re-point, ${counts.clear} to clear ` +
        `(${counts.staleManager} of a plan whose manager is not linked: kept unshared)`);
    if (stalePlans.size > 0) console.log("Detach the stale plans with clear_stale_manager_ids.js.");

    if (!args.apply) {
        console.log("Dry run only. Re-run with --apply to write.");
        return;
    }
    if (pending.length === 0) {
        console.log("Nothing to change.");
        return;
    }

    const backup = openBackup(args, "backfill_action_manager_ids");
    let written = 0;
    let skipped = 0;
    let failed = 0;
    for (const chunk of chunks(pending)) {
        try {
            const result = await db.runTransaction(async (tx) => {
                const snaps = await tx.getAll(...chunk.map((entry) => entry.ref));
                const planIds = [...new Set(snaps.map((snap) => snap.data()?.planId).filter(isId))];
                const fresh = new Map();
                if (planIds.length > 0) {
                    const planSnaps = await tx.getAll(...planIds.map((id) => db.collection("plans").doc(id)));
                    planSnaps.forEach((snap) => fresh.set(snap.id, snap.exists ? snap.data() : null));
                }
                let writes = 0;
                let unchanged = 0;
                for (const snap of snaps) {
                    const action = snap.exists ? snap.data() : null;
                    if (!action) {
                        unchanged++;
                        continue;
                    }
                    const plan = isId(action.planId) ? fresh.get(action.planId) ?? null : null;
                    const want = targetFor(action, plan);
                    const present = "managerId" in action;
                    if (want === null ? !present : action.managerId === want) {
                        unchanged++;
                        continue;
                    }
                    backup.append({
                        id: snap.id,
                        planId: action.planId ?? null,
                        at: new Date().toISOString(),
                        previous: {present, managerId: present ? plain(action.managerId) : null},
                        next: want,
                    });
                    tx.update(snap.ref, {managerId: want ?? FieldValue.delete()});
                    writes++;
                }
                return {writes, unchanged};
            });
            written += result.writes;
            skipped += result.unchanged;
        } catch (error) {
            failed += chunk.length;
            console.error(`  chunk starting at ${chunk[0].id} failed:`, error.message || error);
        }
    }
    console.log(`Updated managerId on ${written} actions; ${skipped} changed or synced meanwhile (left alone).`);
    if (failed) {
        console.log(`Failed: ${failed} actions (re-run to retry them).`);
        process.exitCode = 1;
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
