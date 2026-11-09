// 주 N회 자유 요일 (plans.weeklyTarget): must-do days and the missed-notice
// gate. The vectors are shared with test/models/weekly_target_test.dart.
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const weekly = require("../lib/weekly");
const time = require("../lib/time");
const copy = require("../lib/copy");

const vectors = JSON.parse(fs.readFileSync(
    path.join(__dirname, "..", "..", "test", "fixtures", "weekly_target_vectors.json"), "utf8"));
const flags = (s) => s.split("").map((c) => c === "1");
const str = (list) => list.map((b) => (b ? "1" : "0")).join("");
const ts = (iso) => ({toDate: () => new Date(iso)});

test("shared vectors: evaluateWeeklyWeek matches the app", () => {
    assert.ok(vectors.cases.length >= 10);
    for (const c of vectors.cases) {
        const week = weekly.evaluateWeeklyWeek(c.target, flags(c.inPeriod), flags(c.credited));
        assert.equal(week.target, c.weekTarget, c.name);
        assert.equal(week.credited, c.creditedCount, c.name);
        assert.equal(str(week.mustDo), c.mustDo, c.name);
    }
});

test("weeklyTargetOf accepts only ints 1-6", () => {
    assert.equal(weekly.weeklyTargetOf({weeklyTarget: 3}), 3);
    assert.equal(weekly.weeklyTargetOf({weeklyTarget: 1}), 1);
    assert.equal(weekly.weeklyTargetOf({weeklyTarget: 6}), 6);
    for (const bad of [0, 7, 2.5, "3", null, undefined]) {
        assert.equal(weekly.weeklyTargetOf({weeklyTarget: bad}), null, String(bad));
    }
    assert.equal(weekly.weeklyTargetOf({}), null);
    assert.equal(weekly.weeklyTargetOf(null), null);
});

test("prorated targets for partial weeks", () => {
    assert.equal(weekly.weeklyTargetForAvailableDays(3, 7), 3);
    assert.equal(weekly.weeklyTargetForAvailableDays(3, 2), 1);
    assert.equal(weekly.weeklyTargetForAvailableDays(3, 5), 3);
    assert.equal(weekly.weeklyTargetForAvailableDays(6, 1), 1);
    assert.equal(weekly.weeklyTargetForAvailableDays(6, 0), 0);
});

// A 주 3회 plan from Monday Nov 2 2026 (KST) for 28 days.
const seoulPlan = (extra = {}) => ({
    weeklyTarget: 3,
    startDate: ts("2026-11-01T15:00:00Z"), // Mon Nov 2, 00:00 KST
    endDate: ts("2026-11-29T14:59:59Z"), // Sun Nov 29, 23:59 KST
    items: [{title: "러닝", days: [1, 2, 3, 4, 5, 6, 7], notificationTime: {type: "custom", hour: 21, minute: 0}}],
    completedDates: [],
    ...extra,
});

test("server must-do days in the owner's zone", () => {
    const tz = "Asia/Seoul";
    const at = (iso) => time.localParts(new Date(iso), tz);
    const plan = seoulPlan();
    // Thu Nov 5 22:00 KST: four days left, three needed — neutral.
    assert.equal(weekly.weeklyAllowsMissedNotice(plan, at("2026-11-05T13:00:00Z"), tz), false);
    // Fri Nov 6: three left, three needed — must-do.
    assert.equal(weekly.weeklyAllowsMissedNotice(plan, at("2026-11-06T13:00:00Z"), tz), true);

    // Done Mon + Tue (KST): only Sunday is must-do.
    const twoDone = seoulPlan({completedDates: [ts("2026-11-02T10:00:00Z"), ts("2026-11-03T10:00:00Z")]});
    assert.equal(weekly.weeklyAllowsMissedNotice(twoDone, at("2026-11-06T13:00:00Z"), tz), false);
    assert.equal(weekly.weeklyAllowsMissedNotice(twoDone, at("2026-11-07T13:00:00Z"), tz), false);
    assert.equal(weekly.weeklyAllowsMissedNotice(twoDone, at("2026-11-08T13:00:00Z"), tz), true);

    // A rest pass and a rescue credit the week like a done day.
    const credited = seoulPlan({
        completedDates: [ts("2026-11-02T10:00:00Z")],
        restedDates: [ts("2026-11-03T10:00:00Z")],
        rescuedDates: [ts("2026-11-04T10:00:00Z")],
    });
    assert.equal(weekly.weeklyAllowsMissedNotice(credited, at("2026-11-08T13:00:00Z"), tz), false);

    // A skip is not a credit.
    const skipped = seoulPlan({skippedDates: [ts("2026-11-02T10:00:00Z")]});
    assert.equal(weekly.weeklyAllowsMissedNotice(skipped, at("2026-11-06T13:00:00Z"), tz), true);

    // The next week starts over on Monday.
    assert.equal(weekly.weeklyAllowsMissedNotice(twoDone, at("2026-11-09T13:00:00Z"), tz), false);
    assert.equal(weekly.weeklyAllowsMissedNotice(twoDone, at("2026-11-13T13:00:00Z"), tz), true);
});

test("the week boundary follows the owner's zone, not UTC", () => {
    // Sunday Nov 8 23:30 in Los Angeles is Monday 07:30 UTC.
    const la = "America/Los_Angeles";
    const plan = {
        weeklyTarget: 1,
        startDate: ts("2026-11-02T08:00:00Z"), // Mon Nov 2 00:00 PST
        endDate: ts("2026-11-30T07:59:59Z"),
        completedDates: [],
    };
    const sundayNight = time.localParts(new Date("2026-11-09T07:30:00Z"), la);
    assert.equal(sundayNight.weekday, 7);
    assert.equal(weekly.weeklyAllowsMissedNotice(plan, sundayNight, la), true);
    // A done record written Sunday evening LA (Monday UTC) credits that week.
    const doneSunday = {...plan, completedDates: [ts("2026-11-09T03:00:00Z")]};
    const week = weekly.weeklyWeekOf(doneSunday, sundayNight, la);
    assert.equal(week.credited, 1);
    // Read in Seoul the same instant is Monday of the next week.
    const seoul = time.localParts(new Date("2026-11-09T07:30:00Z"), "Asia/Seoul");
    assert.equal(seoul.weekday, 1);
});

test("fixed-weekday plans are never gated", () => {
    const plan = {items: [{days: [5], notificationTime: {type: "custom", hour: 21, minute: 0}}]};
    const tz = "Asia/Seoul";
    assert.equal(weekly.weeklyAllowsMissedNotice(plan, time.localParts(new Date(), tz), tz), true);
    assert.equal(weekly.weeklyWeekOf(plan, time.localParts(new Date(), tz), tz), null);
});

test("plan-created copy names 주 N회 instead of 매일", () => {
    const base = {
        who: "민지", workout: null, itemTitle: "러닝", days: [1, 2, 3, 4, 5, 6, 7],
        notificationTime: {type: "custom", hour: 21, minute: 0}, pendingApproval: false,
    };
    assert.match(copy.planCreatedCopy({...base, weeklyTarget: 3}).body, /주 3회 21:00까지/);
    assert.match(copy.planCreatedCopy({...base, weeklyTarget: 3, lang: "en"}).body, /3x a week by 21:00/);
    assert.match(copy.planCreatedCopy(base).body, /매일 21:00까지/);
    assert.equal(copy.formatSchedule([1, 3], 9, "ko"), "월·수");
});

test("weekly 내기 tally: missed must-do days only, in the owner's zone", () => {
    const tz = "Asia/Seoul";
    // Mirrors test/models/weekly_target_test.dart "4-week math": done Mon 9/28,
    // Tue 9/29 and Sat 10/10 (KST) on a 주 3회 plan of 9/28-10/25.
    const plan = {
        weeklyTarget: 3,
        startDate: ts("2026-09-27T15:00:00Z"),
        endDate: ts("2026-10-25T14:59:59Z"),
        completedDates: [ts("2026-09-28T10:00:00Z"), ts("2026-09-29T10:00:00Z"), ts("2026-10-10T10:00:00Z")],
    };
    const at = (iso) => time.localParts(new Date(iso), tz);
    assert.deepEqual(weekly.weeklySettlementTally(plan, at("2026-10-12T03:00:00Z"), tz),
        {successDays: 3, failDays: 3});
    // To the end: weeks 3 and 4 add 3 misses each.
    assert.deepEqual(weekly.weeklySettlementTally(plan, at("2026-11-01T03:00:00Z"), tz), {successDays: 3, failDays: 9});
    assert.equal(weekly.weeklySettlementTally({...plan, weeklyTarget: undefined}, at("2026-11-01T03:00:00Z"), tz), null);
});

test("a weekly 내기 settled by an old build is recounted once", () => {
    const tz = "Asia/Seoul";
    const plan = {
        weeklyTarget: 3,
        startDate: ts("2026-09-27T15:00:00Z"),
        endDate: ts("2026-10-25T14:59:59Z"),
        // Three a week: Mon, Wed, Fri of each of the four weeks (19:00 KST).
        completedDates: [0, 7, 14, 21].flatMap((week) => [0, 2, 4].map((day) =>
            ts(new Date(Date.UTC(2026, 8, 28 + week + day, 10)).toISOString()))),
    };
    const promise = {
        reward: {title: "치킨", targetDays: 12},
        penalty: {title: "설거지", targetDays: 3},
    };
    const before = {...plan, promise: {...promise, status: "active"}};
    // What build ≤87 writes: 28 scheduled days - 12 done = 16 "misses".
    const after = {...plan, promise: {
        ...promise, status: "settled", settledAt: ts("2026-10-26T01:00:00Z"),
        settledSuccessDays: 12, settledFailDays: 16, settlementResult: "both_met",
    }};
    const fix = weekly.weeklySettlementCorrection(before, after, tz, new Date("2026-10-26T01:00:05Z"));
    assert.deepEqual(fix, {
        "promise.settledSuccessDays": 12,
        "promise.settledFailDays": 0,
        "promise.settlementResult": "reward_achieved",
    });
    // Already right, already settled before, or a fixed-weekday plan: nothing.
    const fixed = {...after, promise: {...after.promise, settledFailDays: 0, settlementResult: "reward_achieved"}};
    assert.equal(weekly.weeklySettlementCorrection(before, fixed, tz, new Date()), null);
    assert.equal(weekly.weeklySettlementCorrection(after, after, tz, new Date()), null);
    assert.equal(weekly.weeklySettlementCorrection(
        {...before, weeklyTarget: undefined}, {...after, weeklyTarget: undefined}, tz, new Date()), null);
    assert.equal(weekly.settlementResultOf({penalty: {targetDays: 2}}, 0, 2), "penalty_triggered");
    assert.equal(weekly.settlementResultOf({}, 5, 5), "neither_met");
});
