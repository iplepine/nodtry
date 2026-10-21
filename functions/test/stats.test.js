const test = require("node:test");
const assert = require("node:assert/strict");
const stats = require("../lib/stats");

test("seoulDayWindow covers the Seoul calendar day", () => {
    // 2026-10-21 16:00Z = 2026-10-22 01:00 KST
    const w = stats.seoulDayWindow(new Date("2026-10-21T16:00:00Z"));
    assert.equal(w.key, "2026-10-22");
    assert.equal(w.start.toISOString(), "2026-10-21T15:00:00.000Z");
    assert.equal(w.end.toISOString(), "2026-10-22T15:00:00.000Z");
});

test("seoulDayWindow: 14:59Z is still the same KST day, 15:00Z starts the next", () => {
    assert.equal(stats.seoulDayWindow(new Date("2026-10-21T14:59:59Z")).key, "2026-10-21");
    assert.equal(stats.seoulDayWindow(new Date("2026-10-21T15:00:00Z")).key, "2026-10-22");
});

test("previousSeoulDay at 00:10 KST reports the day that just ended", () => {
    const w = stats.previousSeoulDay(new Date("2026-10-21T15:10:00Z")); // 00:10 KST on 22nd
    assert.equal(w.key, "2026-10-21");
    assert.equal(w.start.toISOString(), "2026-10-20T15:00:00.000Z");
    assert.equal(w.end.toISOString(), "2026-10-21T15:00:00.000Z");
});

test("pairsOf rounds up", () => {
    assert.equal(stats.pairsOf(0), 0);
    assert.equal(stats.pairsOf(4), 2);
    assert.equal(stats.pairsOf(5), 3);
});
