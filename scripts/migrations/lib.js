// Shared plumbing of the migration scripts in this folder: arguments, admin
// SDK (from functions/), paging, JSON-lines backups, chunked transactions.
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const {createRequire} = require("node:module");

const FUNCTIONS_DIR = path.join(__dirname, "..", "..", "functions");
const functionsRequire = createRequire(path.join(FUNCTIONS_DIR, "package.json"));
const admin = functionsRequire("firebase-admin");
const {FieldValue, FieldPath} = functionsRequire("firebase-admin/firestore");

const PAGE_SIZE = 500;
/** Writes per transaction (Firestore allows 500). */
const CHUNK_SIZE = 450;

/** functions/lib/<name>.js, the compiled helpers the Cloud Functions use too. */
function loadFunctionsLib(name) {
    const file = path.join(FUNCTIONS_DIR, "lib", `${name}.js`);
    if (!fs.existsSync(file)) {
        throw new Error(`${file} is missing: run \`npm ci && npm run build\` in functions/ first.`);
    }
    return require(file);
}

/** --project <id> [--apply|--dry-run] [--backup <file>] [--verbose] plus `flags` (booleans). */
function parseArgs(argv, flags = []) {
    const args = {apply: false, project: null, verbose: false, backup: null, help: false};
    for (const flag of flags) args[flag] = false;
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
        else if (arg.startsWith("--") && flags.includes(arg.slice(2))) args[arg.slice(2)] = true;
        else throw new Error(`Unknown argument: ${arg}`);
    }
    return args;
}

/** Initializes the admin SDK for `project` (the emulator when FIRESTORE_EMULATOR_HOST is set). */
function openDb(args) {
    const emulator = process.env.FIRESTORE_EMULATOR_HOST;
    admin.initializeApp({projectId: args.project});
    console.log(`Project: ${args.project}${emulator ? ` (emulator ${emulator})` : ""}`);
    console.log(`Mode: ${args.apply ? "APPLY (writes)" : "dry run (read-only)"}`);
    return admin.firestore();
}

/** Every doc of `query`, in document-id order, a page at a time. */
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

/** An append-only JSON-lines file (default: backups/<script>-<time>.jsonl, git-ignored). */
function openBackup(args, scriptName) {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const file = path.resolve(args.backup || path.join(__dirname, "backups", `${scriptName}-${stamp}.jsonl`));
    fs.mkdirSync(path.dirname(file), {recursive: true});
    console.log(`Backup of previous values: ${file}`);
    return {file, append: (entry) => fs.appendFileSync(file, `${JSON.stringify(entry)}\n`)};
}

function chunks(items, size = CHUNK_SIZE) {
    const result = [];
    for (let i = 0; i < items.length; i += size) result.push(items.slice(i, i + size));
    return result;
}

const isId = (value) => typeof value === "string" && value.length > 0;
const pairKey = (a, b) => [a, b].sort().join("|");

module.exports = {
    admin, FieldValue, FieldPath, CHUNK_SIZE,
    loadFunctionsLib, parseArgs, openDb, paged, plain, openBackup, chunks, isId, pairKey,
};
