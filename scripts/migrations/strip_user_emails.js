#!/usr/bin/env node
/*
 * Removes users/{uid}.email — the sign-in email that builds ≤80 copy onto the
 * profile doc, where any signed-in user can read it by uid (also under
 * firestore.rules.next, which only stops listing users).
 *
 * ONLY AFTER THE RULES FLIP (docs/operations/SECURITY_RULES.md, "읽기 축소
 * 전환", last step):
 *   - build ≥81 dominates and config/app.minBuild >= 81. Builds ≤80 write the
 *     auth email back onto the doc at every launch (real_user_repository) and
 *     read the partner's `email` as a name fallback, so stripping earlier is
 *     undone by them and blanks their partner names;
 *   - build ≥81 neither writes nor reads users.email (own email comes from
 *     FirebaseAuth).
 * `--apply` refuses to run while config/app.minBuild < 81 unless `--force`.
 * The Firebase Auth account keeps its email; only the Firestore copy goes.
 *
 *   Dry run (default, read-only):
 *     node scripts/migrations/strip_user_emails.js --project <projectId>
 *   Apply:
 *     node scripts/migrations/strip_user_emails.js --project <projectId> --apply [--backup <file>]
 *
 * Each chunk of users (≤450) is re-read inside a transaction right before the
 * write. The removed value is appended to a JSON-lines backup first
 * (default: scripts/migrations/backups/strip_user_emails-<time>.jsonl,
 * git-ignored), one line per user: {"id", "at", "previous": {"email"}}.
 * THE BACKUP HOLDS PERSONAL DATA (emails): keep it only on the operator's
 * machine and delete it once the release is confirmed (runbook: 30 days).
 * One failing chunk does not stop the run; the exit code is 1 when any
 * failed. Re-running is safe: users without the field are skipped.
 *
 * Credentials: Application Default Credentials
 * (`gcloud auth application-default login`) or GOOGLE_APPLICATION_CREDENTIALS.
 * Against the emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 ... --project demo-duounwan
 */
"use strict";

const {FieldValue, parseArgs, openDb, paged, plain, openBackup, chunks} = require("./lib");

/** First build that neither writes nor reads users.email. */
const MIN_BUILD = 81;

async function main() {
    const args = parseArgs(process.argv.slice(2), ["force"]);
    if (args.help || !args.project) {
        console.log("Usage: node scripts/migrations/strip_user_emails.js --project <projectId> " +
            "[--apply [--force]] [--backup <file>] [--verbose]");
        process.exit(args.help ? 0 : 1);
    }
    const db = openDb(args);

    const config = (await db.doc("config/app").get()).data() || {};
    const minBuild = Number(config.minBuild);
    const gateClosed = Number.isFinite(minBuild) && minBuild >= MIN_BUILD;
    console.log(`config/app.minBuild: ${config.minBuild ?? "(unset)"}` +
        `${gateClosed ? "" : ` — builds below ${MIN_BUILD} can still run and will write their email back`}`);

    let scanned = 0;
    const pending = [];
    for await (const doc of paged(db.collection("users").select("email"))) {
        scanned++;
        if ("email" in doc.data()) pending.push(doc.ref);
    }
    console.log(`users: ${scanned} scanned, ${pending.length} with an email field`);

    if (!args.apply) {
        console.log("Dry run only. Re-run with --apply to remove the field.");
        return;
    }
    if (!gateClosed && !args.force) {
        console.error(`Refusing to apply: set config/app.minBuild >= ${MIN_BUILD} first (or pass --force).`);
        process.exitCode = 2;
        return;
    }
    if (pending.length === 0) {
        console.log("Nothing to remove.");
        return;
    }

    const backup = openBackup(args, "strip_user_emails");
    console.log("The backup contains email addresses: delete it once the release is confirmed.");
    let removed = 0;
    let failed = 0;
    for (const chunk of chunks(pending)) {
        try {
            removed += await db.runTransaction(async (tx) => {
                const snaps = await tx.getAll(...chunk);
                let writes = 0;
                for (const snap of snaps) {
                    const user = snap.exists ? snap.data() : null;
                    if (!user || !("email" in user)) continue;
                    backup.append({id: snap.id, at: new Date().toISOString(), previous: {email: plain(user.email)}});
                    tx.update(snap.ref, {email: FieldValue.delete()});
                    writes++;
                }
                return writes;
            });
        } catch (error) {
            failed += chunk.length;
            console.error(`  chunk starting at ${chunk[0].id} failed:`, error.message || error);
        }
    }
    console.log(`Removed email from ${removed} users.`);
    if (failed) {
        console.log(`Failed: ${failed} users (re-run to retry them).`);
        process.exitCode = 1;
    }
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
