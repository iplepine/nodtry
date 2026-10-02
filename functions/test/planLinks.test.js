const test = require("node:test");
const assert = require("node:assert/strict");
const links = require("../lib/planLinks");

const DELETE = Symbol("delete");
const NOW = Symbol("now");
const ops = {deleteField: () => DELETE, serverTimestamp: () => NOW};
const DAY = 24 * 60 * 60 * 1000;
const T = Date.UTC(2026, 9, 3, 12, 0, 0);
const ts = (ms) => ({toMillis: () => ms});

test("unlinkUpdate detaches, sets the unlink floor and clears what the partner wrote", () => {
    const update = links.unlinkUpdate({state: "pending_approval", promise: {status: "active"}}, ops);
    assert.equal(update.managerId, DELETE);
    assert.equal(update.lastUpdatedBy, "system_unlink");
    assert.equal(update.managerSince, NOW);
    assert.equal(update.managerSinceUid, links.UNLINKED_MARK);
    assert.equal(update.lastProofPhotoPath, DELETE);
    assert.equal(update.lastProofAt, DELETE);
    for (const field of ["lastCheerMessage", "lastCheerType", "lastComment", "lastPokeMessage",
        "lastPokeAcknowledgedAt"]) {
        assert.equal(update[field], DELETE, field);
    }
    assert.equal(update.state, "active");
    assert.equal(update["promise.status"], "rejected");

    const plain = links.unlinkUpdate({state: "active", promise: {status: "settled"}}, ops);
    assert.equal(plain.state, undefined);
    assert.equal(plain["promise.status"], undefined);
    assert.equal(links.unlinkUpdate({state: "active", promise: {status: "proposed"}}, ops)["promise.status"],
        "rejected");
    // Never touches the owner's own record of the day.
    assert.equal("lastActionNote" in plain, false);
    assert.equal("lastActionId" in plain, false);
});

test("a plan's first manager sees the last day of proofs", () => {
    assert.deepEqual(links.managerStampFor({}, "bob", T), {sinceMs: T - links.NEW_MANAGER_LOOKBACK_MS});
});

test("after an unlink the next manager never sees the earlier era", () => {
    const unlinkedAt = T - 2 * 60 * 60 * 1000; // 2h ago
    const plan = {managerSince: ts(unlinkedAt), managerSinceUid: links.UNLINKED_MARK};
    const floor = Math.max(unlinkedAt, T - links.NEW_MANAGER_LOOKBACK_MS);
    assert.deepEqual(links.managerStampFor(plan, "carol", T), {sinceMs: floor});
    // An unlink long ago: the usual one-day look-back.
    const old = {managerSince: ts(T - 10 * DAY), managerSinceUid: links.UNLINKED_MARK};
    assert.deepEqual(links.managerStampFor(old, "carol", T), {sinceMs: T - links.NEW_MANAGER_LOOKBACK_MS});
    // The client already pointed the plan at carol; the server stamps the same floor.
    assert.deepEqual(links.managerStampFor({...plan, managerId: "carol"}, "carol", T), {sinceMs: floor});
});

test("taking a plan over from another manager starts now", () => {
    assert.deepEqual(links.managerStampFor({managerId: "bob"}, "carol", T), {sinceMs: T});
    assert.deepEqual(
        links.managerStampFor({managerId: "bob", managerSince: ts(T - DAY), managerSinceUid: "bob"}, "carol", T),
        {sinceMs: T},
    );
    // Stamped for someone who left without a server unlink.
    assert.deepEqual(links.managerStampFor({managerSince: ts(T - DAY), managerSinceUid: "bob"}, "carol", T),
        {sinceMs: T});
});

test("nothing to stamp for the same manager", () => {
    assert.equal(links.managerStampFor({managerId: "bob", managerSinceUid: "bob"}, "bob", T), null);
    assert.equal(links.managerStampFor({managerSinceUid: "bob"}, "bob", T), null);
    // Managed before stamps existed: keeps the access it had.
    assert.equal(links.managerStampFor({managerId: "bob"}, "bob", T), null);
});

test("millisOf reads Firestore timestamps, dates and numbers", () => {
    assert.equal(links.millisOf(ts(5)), 5);
    assert.equal(links.millisOf(new Date(7)), 7);
    assert.equal(links.millisOf(9), 9);
    assert.equal(links.millisOf(null), 0);
    assert.equal(links.millisOf({toDate: () => new Date(11)}), 11);
});

test("an action carries its plan's current manager, and only the owner's actions do", () => {
    const plan = {userId: "alice", managerId: "bob"};
    assert.equal(links.actionManagerFor({userId: "alice", planId: "p"}, plan), "bob");
    // Already stamped for someone else (stale): the plan decides.
    assert.equal(links.actionManagerFor({userId: "alice", managerId: "carol"}, plan), "bob");
    // Not the owner's record (injected into the plan before the rules caught it).
    assert.equal(links.actionManagerFor({userId: "mallory"}, plan), null);
    // No manager, a self-manager, a missing plan, garbage ids.
    assert.equal(links.actionManagerFor({userId: "alice"}, {userId: "alice"}), null);
    assert.equal(links.actionManagerFor({userId: "alice"}, {userId: "alice", managerId: "alice"}), null);
    assert.equal(links.actionManagerFor({userId: "alice"}, {userId: "alice", managerId: ""}), null);
    assert.equal(links.actionManagerFor({userId: "alice"}, null), null);
    assert.equal(links.actionManagerFor({}, {managerId: "bob"}), null);
});
