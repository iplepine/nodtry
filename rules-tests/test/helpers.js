const fs = require("node:fs");
const path = require("node:path");
const {initializeTestEnvironment} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "demo-duounwan";
const ROOT = path.join(__dirname, "..", "..");

/**
 * The Firestore rules under test: firestore.rules (deployed) by default,
 * firestore.rules.next when FIRESTORE_RULES says so (npm run test:next), or
 * `rulesFile` for a suite that only makes sense against one of them.
 */
function firestoreRulesFile(rulesFile) {
    return rulesFile || process.env.FIRESTORE_RULES || "firestore.rules";
}

async function createTestEnv({rulesFile} = {}) {
    return initializeTestEnvironment({
        projectId: PROJECT_ID,
        firestore: {rules: fs.readFileSync(path.join(ROOT, firestoreRulesFile(rulesFile)), "utf8")},
        storage: {rules: fs.readFileSync(path.join(ROOT, "storage.rules"), "utf8")},
    });
}

/** A fake JPEG payload of the given size (rules only look at size/contentType). */
function bytes(size) {
    const data = new Uint8Array(size);
    data[0] = 0xff;
    data[1] = 0xd8;
    return data;
}

module.exports = {PROJECT_ID, createTestEnv, firestoreRulesFile, bytes};
