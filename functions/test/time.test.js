// Run with `npm test` (builds first). Uses only node:test — no extra deps.
const test = require("node:test");
const assert = require("node:assert/strict");
const time = require("../lib/time");
const schedule = require("../lib/schedule");

const ts = (iso) => ({toDate: () => new Date(iso)});

test("resolveTimeZone falls back to Asia/Seoul", () => {
    assert.equal(time.resolveTimeZone("America/Los_Angeles"), "America/Los_Angeles");
    assert.equal(time.resolveTimeZone(undefined), "Asia/Seoul");
    assert.equal(time.resolveTimeZone(""), "Asia/Seoul");
    assert.equal(time.resolveTimeZone("Not/AZone"), "Asia/Seoul");
    assert.equal(time.resolveTimeZone(42), "Asia/Seoul");
});

test("localParts computes the local day, weekday and minutes", () => {
    const instant = new Date("2026-10-02T15:30:00Z");
    assert.deepEqual(time.localParts(instant, "Asia/Seoul"), {
        year: 2026, month: 10, day: 3, weekday: 6, minutes: 30,
    });
    assert.deepEqual(time.localParts(instant, "America/Los_Angeles"), {
        year: 2026, month: 10, day: 2, weekday: 5, minutes: 8 * 60 + 30,
    });
});

test("local day comparisons use the given zone", () => {
    const tz = "America/Los_Angeles";
    const today = time.localParts(new Date("2026-10-02T20:00:00Z"), tz); // Oct 2, 13:00 LA
    assert.equal(time.isSameLocalDay(ts("2026-10-03T05:00:00Z"), today, tz), true); // Oct 2, 22:00 LA
    assert.equal(time.isSameLocalDay(ts("2026-10-03T05:00:00Z"), today, "Asia/Seoul"), false);
    assert.equal(time.isBeforeLocalDay(ts("2026-10-01T12:00:00Z"), today, tz), true);
    assert.equal(time.isAfterLocalDay(ts("2026-10-04T12:00:00Z"), today, tz), true);
    assert.equal(time.isSameLocalDay(null, today, tz), false);
    assert.equal(time.dayKey(today), "2026-10-02");
});

test("localDaysAgo counts calendar days", () => {
    const tz = "Asia/Seoul";
    const today = time.localParts(new Date("2026-10-02T03:00:00Z"), tz); // Oct 2, 12:00 KST
    assert.equal(time.localDaysAgo(ts("2026-10-01T15:30:00Z"), today, tz), 0); // Oct 2, 00:30 KST
    assert.equal(time.localDaysAgo(ts("2026-10-01T14:30:00Z"), today, tz), 1); // Oct 1, 23:30 KST
    assert.equal(time.localDaysAgo(undefined, today, tz), null);
});

test("missed notice fires 30-60 min after a 21:00 deadline in the executor's zone", () => {
    const plan = {
        items: [{title: "러닝", days: [5], notificationTime: {type: "custom", hour: 21, minute: 0}}],
    };
    const tz = "America/Los_Angeles";
    // Friday Oct 2 2026, LA times (UTC-7).
    const at = (utc) => time.localParts(new Date(utc), tz);
    assert.equal(schedule.dueItemForMissedNotice(plan, at("2026-10-03T04:15:00Z")), null); // 21:15
    assert.equal(schedule.dueItemForMissedNotice(plan, at("2026-10-03T04:30:00Z")).title, "러닝"); // 21:30
    // The same instant is Saturday afternoon in Seoul: not due there.
    assert.equal(
        schedule.dueItemForMissedNotice(plan, time.localParts(new Date("2026-10-03T04:30:00Z"), "Asia/Seoul")),
        null,
    );
});

test("items without a time are never relayed", () => {
    const plan = {items: [{title: "x", days: [1, 2, 3, 4, 5, 6, 7], notificationTime: {type: "none"}}]};
    const late = time.localParts(new Date("2026-10-02T14:59:00Z"), "Asia/Seoul"); // 23:59 KST
    assert.equal(schedule.dueItemForMissedNotice(plan, late), null);
});

test("hasCoveredToday checks every record list in the executor's zone", () => {
    const tz = "Asia/Seoul";
    const today = time.localParts(new Date("2026-10-02T03:00:00Z"), tz);
    assert.equal(schedule.hasCoveredToday({completedDates: [ts("2026-10-01T16:00:00Z")]}, today, tz), true);
    assert.equal(schedule.hasCoveredToday({restedDates: [ts("2026-10-02T10:00:00Z")]}, today, tz), true);
    assert.equal(schedule.hasCoveredToday({skippedDates: [ts("2026-10-01T10:00:00Z")]}, today, tz), false);
    assert.equal(schedule.hasCoveredToday({}, today, tz), false);
});

test("late deadlines (after 23:00) are judged in the first two hours of the next day", () => {
    const tz = "Asia/Seoul";
    const at = (utc) => time.localParts(new Date(utc), tz);
    const item = (hour, minute) => ({title: `${hour}:${minute}`, days: [5], notificationTime: {type: "custom", hour, minute}});
    // Friday Oct 2 2026 KST. The 30-minute cron runs at :00 and :30.
    const friday2330 = at("2026-10-02T14:30:00Z");
    const plan = (h, m) => ({items: [item(h, m)]});

    // 23:00 is due at 23:30 the same day.
    assert.equal(schedule.dueItemForMissedNotice(plan(23, 0), friday2330).title, "23:0");
    // 23:20 → due 23:50: no run that day; 23:59 → due 00:29.
    assert.equal(schedule.dueItemForMissedNotice(plan(23, 20), friday2330), null);
    assert.equal(schedule.dueItemForMissedNotice(plan(23, 59), friday2330), null);

    const saturday0000 = at("2026-10-02T15:00:00Z");
    const saturday0030 = at("2026-10-02T15:30:00Z");
    const saturday0230 = at("2026-10-02T17:30:00Z");
    const yesterday = time.previousLocalDay(new Date("2026-10-02T15:00:00Z"), saturday0000, tz).parts;
    assert.equal(yesterday.weekday, 5);
    assert.equal(time.dayKey(yesterday), "2026-10-02");

    assert.equal(schedule.lateItemFromYesterday(plan(23, 20), yesterday, saturday0000).title, "23:20");
    assert.equal(schedule.lateItemFromYesterday(plan(23, 59), yesterday, saturday0000), null); // due 00:29
    assert.equal(schedule.lateItemFromYesterday(plan(23, 59), yesterday, saturday0030).title, "23:59");
    // Items judged on their own day are not looked at again.
    assert.equal(schedule.lateItemFromYesterday(plan(23, 0), yesterday, saturday0030), null);
    assert.equal(schedule.lateItemFromYesterday(plan(21, 0), yesterday, saturday0030), null);
    // Only right after midnight.
    assert.equal(schedule.lateItemFromYesterday(plan(23, 59), yesterday, saturday0230), null);
    // Not scheduled yesterday (Thursday-only item).
    const thursday = {items: [{...item(23, 59), days: [4]}]};
    assert.equal(schedule.lateItemFromYesterday(thursday, yesterday, saturday0030), null);
    // No time, no relay.
    const untimed = {items: [{title: "x", days: [5], notificationTime: {type: "none"}}]};
    assert.equal(schedule.lateItemFromYesterday(untimed, yesterday, saturday0030), null);
});

test("previousLocalDay stays on the previous day across a DST change", () => {
    const tz = "America/New_York";
    // Nov 1 2026: clocks go back at 02:00. 01:30 EST (06:30Z) is after the change.
    const now = new Date("2026-11-01T06:30:00Z");
    const today = time.localParts(now, tz);
    assert.equal(today.day, 1);
    const prev = time.previousLocalDay(now, today, tz);
    assert.equal(prev.parts.day, 31);
    assert.equal(prev.parts.month, 10);
});

test("hasTimedItem is a time-zone-free pre-filter", () => {
    assert.equal(schedule.hasTimedItem({items: [{days: [1], notificationTime: {type: "custom", hour: 9}}]}), true);
    assert.equal(schedule.hasTimedItem({items: [{days: [1], notificationTime: {type: "none"}}]}), false);
    assert.equal(schedule.hasTimedItem({items: [{days: [], notificationTime: {type: "custom", hour: 9}}]}), false);
    assert.equal(schedule.hasTimedItem({}), false);
});
