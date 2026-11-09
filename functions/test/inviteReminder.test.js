// Run with `npm test` (builds first). The pure selection of invite reminders.
const test = require("node:test");
const assert = require("node:assert/strict");
const {Timestamp} = require("firebase-admin/firestore");
const reminder = require("../lib/inviteReminder");

const HOUR = 60 * 60 * 1000;
// 2026-11-09 14:00 in Seoul (05:00 UTC) — inside the 10:00–21:00 window.
const NOW = new Date("2026-11-09T05:00:00Z");
const NOW_MS = NOW.getTime();

function invite(overrides = {}) {
    return {
        inviterUid: "alice",
        lastSharedAtMs: NOW_MS - 25 * HOUR,
        remindersSent: 0,
        remindersCycleAtMs: 0,
        lastReminderAtMs: 0,
        connectedAtMs: 0,
        ...overrides,
    };
}

const seoulUser = {timezone: "Asia/Seoul", locale: "ko"};

test("reminder #1 is due from 24h after the share, not before", () => {
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: NOW_MS - 23 * HOUR}), NOW_MS), null);
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: NOW_MS - 24 * HOUR}), NOW_MS), 1);
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: NOW_MS - 50 * HOUR}), NOW_MS), 1);
});

test("reminder #2 is due from 72h after the share, once #1 went out", () => {
    const shared = NOW_MS - 73 * HOUR;
    const afterFirst = {
        lastSharedAtMs: shared, remindersSent: 1, remindersCycleAtMs: shared, lastReminderAtMs: shared + 24 * HOUR,
    };
    assert.equal(reminder.dueReminder(invite(afterFirst), NOW_MS), 2);
    assert.equal(reminder.dueReminder(invite({...afterFirst, lastSharedAtMs: NOW_MS - 71 * HOUR,
        remindersCycleAtMs: NOW_MS - 71 * HOUR}), NOW_MS), null);
});

test("two reminders are at least 24h apart", () => {
    const shared = NOW_MS - 73 * HOUR;
    // #1 was held back by the night until 10 hours ago.
    const late = invite({
        lastSharedAtMs: shared, remindersSent: 1, remindersCycleAtMs: shared, lastReminderAtMs: NOW_MS - 10 * HOUR,
    });
    assert.equal(reminder.dueReminder(late, NOW_MS), null);
});

test("at most two reminders per share", () => {
    const shared = NOW_MS - 100 * HOUR;
    const done = invite({
        lastSharedAtMs: shared, remindersSent: 2, remindersCycleAtMs: shared, lastReminderAtMs: NOW_MS - 30 * HOUR,
    });
    assert.equal(reminder.dueReminder(done, NOW_MS), null);
});

test("sharing again starts a new cycle", () => {
    const oldShare = NOW_MS - 120 * HOUR;
    const reshared = invite({
        lastSharedAtMs: NOW_MS - 25 * HOUR,
        remindersSent: 2,
        remindersCycleAtMs: oldShare,
        lastReminderAtMs: NOW_MS - 48 * HOUR,
    });
    assert.equal(reminder.remindersInCycle(reshared), 0);
    assert.equal(reminder.dueReminder(reshared, NOW_MS), 1);
    // A fresh share is not reminded about the same day.
    assert.equal(reminder.dueReminder(invite({...reshared, lastSharedAtMs: NOW_MS - HOUR}), NOW_MS), null);
});

test("a connection after the latest share stops reminders; an older one doesn't", () => {
    const shared = NOW_MS - 30 * HOUR;
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: shared, connectedAtMs: shared + HOUR}), NOW_MS), null);
    // Connected, unlinked later, then shared again.
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: shared, connectedAtMs: shared - 10 * HOUR}), NOW_MS), 1);
});

test("shares older than a week are left alone", () => {
    assert.equal(reminder.dueReminder(invite({lastSharedAtMs: NOW_MS - 8 * 24 * HOUR}), NOW_MS), null);
});

test("only between 10:00 and 21:00 local time", () => {
    const at = (iso) => new Date(iso);
    // Seoul = UTC+9.
    assert.equal(reminder.inReminderHours(at("2026-11-09T00:59:00Z"), "Asia/Seoul"), false); // 09:59
    assert.equal(reminder.inReminderHours(at("2026-11-09T01:00:00Z"), "Asia/Seoul"), true); // 10:00
    assert.equal(reminder.inReminderHours(at("2026-11-09T11:59:00Z"), "Asia/Seoul"), true); // 20:59
    assert.equal(reminder.inReminderHours(at("2026-11-09T12:00:00Z"), "Asia/Seoul"), false); // 21:00
    // No / unknown zone → Asia/Seoul.
    assert.equal(reminder.inReminderHours(at("2026-11-09T12:30:00Z"), undefined), false);
    assert.equal(reminder.inReminderHours(at("2026-11-09T05:00:00Z"), "Not/AZone"), true);
    // 05:00 UTC is 21:00 in Los Angeles (PST) on Nov 8.
    assert.equal(reminder.inReminderHours(at("2026-11-09T05:00:00Z"), "America/Los_Angeles"), false);
    assert.equal(reminder.inReminderHours(at("2026-11-09T20:00:00Z"), "America/Los_Angeles"), true); // 12:00
});

test("selectInviteReminders picks who gets which reminder now", () => {
    const shared73 = NOW_MS - 73 * HOUR;
    const invites = [
        invite({inviterUid: "first"}),
        invite({inviterUid: "second", lastSharedAtMs: shared73, remindersSent: 1, remindersCycleAtMs: shared73,
            lastReminderAtMs: shared73 + 26 * HOUR}),
        invite({inviterUid: "fresh", lastSharedAtMs: NOW_MS - 2 * HOUR}),
        invite({inviterUid: "deleted"}),
        invite({inviterUid: "asleep"}),
        invite({inviterUid: "english"}),
        invite({inviterUid: "connected", connectedAtMs: NOW_MS - HOUR}),
    ];
    const users = new Map([
        ["first", seoulUser],
        ["second", {}],
        ["fresh", seoulUser],
        ["asleep", {timezone: "America/Los_Angeles"}],
        ["english", {timezone: "Asia/Seoul", locale: "en"}],
        ["connected", seoulUser],
    ]);
    assert.deepEqual(reminder.selectInviteReminders(invites, users, NOW), [
        {inviterUid: "first", reminder: 1, locale: "ko"},
        {inviterUid: "second", reminder: 2, locale: "ko"},
        {inviterUid: "english", reminder: 1, locale: "en"},
    ]);
});

test("inviteStateOf reads a Firestore doc", () => {
    const shared = Timestamp.fromMillis(NOW_MS - 30 * HOUR);
    assert.deepEqual(reminder.inviteStateOf("alice", {
        inviterUid: "alice",
        code: "ABCD2345",
        lastSharedAt: shared,
        shareCount: 3,
        remindersSent: 1,
        remindersCycleAt: shared,
        lastReminderAt: Timestamp.fromMillis(NOW_MS - 5 * HOUR),
    }), {
        inviterUid: "alice",
        lastSharedAtMs: NOW_MS - 30 * HOUR,
        remindersSent: 1,
        remindersCycleAtMs: NOW_MS - 30 * HOUR,
        lastReminderAtMs: NOW_MS - 5 * HOUR,
        connectedAtMs: 0,
    });
    // Not shared yet (serverTimestamp pending) or someone else's uid.
    assert.equal(reminder.inviteStateOf("alice", {inviterUid: "alice"}), null);
    assert.equal(reminder.inviteStateOf("alice", {inviterUid: "bob", lastSharedAt: shared}), null);
    assert.equal(reminder.inviteStateOf("alice", undefined), null);
});

test("locale: 'en' gets English, everything else Korean", () => {
    assert.equal(reminder.reminderLocale({locale: "en"}), "en");
    assert.equal(reminder.reminderLocale({locale: "en-US"}), "en");
    assert.equal(reminder.reminderLocale({locale: "ko"}), "ko");
    assert.equal(reminder.reminderLocale({locale: "ja"}), "ko");
    assert.equal(reminder.reminderLocale({}), "ko");
    assert.equal(reminder.reminderLocale(null), "ko");
});

test("copy follows the tone rules", () => {
    for (const n of [1, 2]) {
        const ko = reminder.inviteReminderCopy(n, "ko");
        const text = `${ko.title} ${ko.body}`;
        assert.match(text, /짝꿍/);
        assert.match(text, /(요|까요)[?.!]?/);
        assert.doesNotMatch(text, /님|애인|둘운완|감시|확인해/);
        const en = reminder.inviteReminderCopy(n, "en");
        assert.ok(en.title && en.body);
        assert.doesNotMatch(`${en.title} ${en.body}`, /[가-힣]/);
    }
    assert.equal(reminder.inviteReminderCopy(1, "ko").body, "링크를 한 번 더 보내볼까요?");
});
