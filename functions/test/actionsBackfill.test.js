// plans 기록 배열 → actions 백필 (scripts/migrations/backfill_plan_actions.js):
// the pure planning and verify comparison it runs.
const test = require("node:test");
const assert = require("node:assert/strict");
const bf = require("../lib/actionsBackfill");

const SEOUL = "Asia/Seoul";
const ts = (iso) => ({toDate: () => new Date(iso)});
// 12:00 KST on 2026-10-<n>.
const kst = (n, hour = 12) => ts(`2026-10-${String(n).padStart(2, "0")}T${String(hour).padStart(2, "0")}:00:00+09:00`);
const action = (type, day, extra = {}) => ({userId: "alice", planId: "p1", type, date: day, ...extra});

const plan = (fields = {}) => ({
    userId: "alice",
    managerId: "bob",
    items: [{title: "헬스장 가기", days: [1, 2, 3, 4, 5, 6, 7]}],
    completedDates: [kst(1), kst(2), kst(3)],
    skippedDates: [kst(4)],
    restedDates: [kst(5)],
    rescuedDates: [kst(6)],
    verifiedDates: [kst(1)],
    ...fields,
});

test("arrays only: one action per array day, deterministic ids", () => {
    const result = bf.planActionBackfill("p1", plan(), [], SEOUL);
    assert.equal(result.userId, "alice");
    assert.deepEqual(result.creates.map((c) => c.id), [
        "backfill_p1_done_20261001",
        "backfill_p1_done_20261002",
        "backfill_p1_done_20261003",
        "backfill_p1_skipped_20261004",
        "backfill_p1_rested_20261005",
        "backfill_p1_rescued_20261006",
    ]);
    assert.deepEqual(result.creates[0], {
        id: "backfill_p1_done_20261001", type: "done", day: "2026-10-01", date: kst(1).toDate(),
    });
    assert.deepEqual(result.covered, {done: 0, skipped: 0, rested: 0, rescued: 0});
});

test("actions only / fully covered: nothing to create", () => {
    const actions = [
        action("done", kst(1, 8)), action("done", kst(2)), action("done", kst(3, 23)),
        action("skipped", kst(4)), action("rested", kst(5)), action("rescued", kst(6)),
    ];
    const result = bf.planActionBackfill("p1", plan(), actions, SEOUL);
    assert.deepEqual(result.creates, []);
    assert.deepEqual(result.covered, {done: 3, skipped: 1, rested: 1, rescued: 1});
    // An actions-only plan (no arrays) has nothing to backfill either.
    const bare = plan({completedDates: [], skippedDates: [], restedDates: [], rescuedDates: []});
    assert.deepEqual(bf.planActionBackfill("p1", bare, actions, SEOUL).creates, []);
});

test("mixed: only the uncovered days, matching type by type", () => {
    const actions = [
        action("done", kst(2)),
        // A skip on a done day doesn't cover the done.
        action("skipped", kst(3)),
        action("rested", kst(5)),
    ];
    const result = bf.planActionBackfill("p1", plan(), actions, SEOUL);
    assert.deepEqual(result.creates.map((c) => `${c.type} ${c.day}`), [
        "done 2026-10-01", "done 2026-10-03", "skipped 2026-10-04", "rescued 2026-10-06",
    ]);
});

test("idempotent: the planned documents cover their own days", () => {
    const first = bf.planActionBackfill("p1", plan(), [], SEOUL);
    const written = first.creates.map((c) => bf.backfillActionData("p1", plan(), c));
    const again = bf.planActionBackfill("p1", plan(), written, SEOUL);
    assert.deepEqual(again.creates, []);
});

test("one action per owner-local day, the day's first moment", () => {
    // 23:30 KST on the 1st and 00:30 KST on the 2nd are different days in
    // Seoul, the same UTC day — and two entries of the 2nd collapse.
    const p = plan({
        completedDates: [ts("2026-10-01T14:30:00Z"), ts("2026-10-01T15:30:00Z"), kst(2, 9)],
        skippedDates: [], restedDates: [], rescuedDates: [],
    });
    const seoul = bf.planActionBackfill("p1", p, [], SEOUL).creates;
    assert.deepEqual(seoul.map((c) => c.day), ["2026-10-01", "2026-10-02"]);
    assert.deepEqual(seoul[1].date, new Date("2026-10-01T15:30:00Z"));
    const utc = bf.planActionBackfill("p1", p, [], "UTC").creates;
    assert.deepEqual(utc.map((c) => c.day), ["2026-10-01", "2026-10-02"]);
    assert.deepEqual(utc[0].date, new Date("2026-10-01T14:30:00Z"));
});

test("only the owner's own actions on this plan count", () => {
    const actions = [
        // The partner's "같이 했어" record names alice's plan but is on theirs.
        {userId: "bob", planId: "bPlan", type: "done", date: kst(1), togetherPartnerPlanId: "p1"},
        {userId: "bob", planId: "p1", type: "done", date: kst(2)},
        {userId: "alice", planId: "other", type: "done", date: kst(3)},
    ];
    const p = plan({skippedDates: [], restedDates: [], rescuedDates: []});
    assert.equal(bf.planActionBackfill("p1", p, actions, SEOUL).creates.length, 3);
});

test("bad data: no owner plans nothing; junk array entries are skipped", () => {
    assert.deepEqual(bf.planActionBackfill("p1", plan({userId: ""}), [], SEOUL).creates, []);
    const p = plan({completedDates: [null, "x", 3, {}, kst(7)], skippedDates: "nope", restedDates: undefined,
        rescuedDates: []});
    assert.deepEqual(bf.planActionBackfill("p1", p, [], SEOUL).creates.map((c) => c.id), ["backfill_p1_done_20261007"]);
});

test("backfillActionData: an old record, marked, never relayed", () => {
    const planned = bf.planActionBackfill("p1", plan(), [], SEOUL).creates[0];
    const data = bf.backfillActionData("p1", plan(), planned);
    assert.deepEqual(data, {
        userId: "alice", planId: "p1", type: "done", date: planned.date, title: "헬스장 가기",
        createdAt: planned.date, backfilled: true,
    });
    assert.equal("managerId" in data, false);
    assert.equal(bf.isBackfilledAction(data), true);
    assert.equal(bf.isBackfilledAction({type: "done"}), false);
    assert.equal(bf.isBackfilledAction({backfilled: "true"}), false);
    assert.equal(bf.isBackfilledAction(null), false);
    assert.equal(bf.planTitleOf({items: []}), "");
});

test("compareRecordDays: per type and 인정, both directions", () => {
    const actions = [
        action("done", kst(1), {verifiedBy: "bob"}),
        action("done", kst(2), {verifiedBy: "bob"}),
        action("done", kst(8)),
        action("skipped", kst(4)), action("rested", kst(5)), action("rescued", kst(6)),
    ];
    const result = bf.compareRecordDays("p1", plan(), actions, SEOUL);
    const by = Object.fromEntries(result.map((c) => [c.kind, c]));
    assert.deepEqual(by.done, {kind: "done", arrays: 3, actions: 3,
        onlyInArrays: ["2026-10-03"], onlyInActions: ["2026-10-08"]});
    assert.deepEqual(by.verified, {kind: "verified", arrays: 1, actions: 2,
        onlyInArrays: [], onlyInActions: ["2026-10-02"]});
    assert.equal(by.skipped.onlyInArrays.length + by.skipped.onlyInActions.length, 0);
    assert.equal(bf.hasMismatch(result), true);

    const clean = bf.compareRecordDays("p1", plan({completedDates: [kst(1), kst(2), kst(8)], verifiedDates: [kst(1), kst(2)]}),
        actions, SEOUL);
    assert.equal(bf.hasMismatch(clean), false);
});
