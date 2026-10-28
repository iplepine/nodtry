const test = require("node:test");
const assert = require("node:assert/strict");
const push = require("../lib/push");

test("quickActionCategory picks buttons by push type", () => {
    assert.equal(push.quickActionCategory({type: "action_completed", actionType: "done"}), "partner_proof");
    assert.equal(push.quickActionCategory({type: "action_completed", actionType: "skipped"}), null);
    assert.equal(push.quickActionCategory({type: "poke", planId: "p1"}), "poke_reply");
    assert.equal(push.quickActionCategory({type: "poke", planId: ""}), null);
    assert.equal(push.quickActionCategory({type: "action_missed", planId: "p1"}), "partner_missed");
    assert.equal(push.quickActionCategory({type: "action_missed", planId: "p1", day: "2026-10-27"}), null);
    assert.equal(push.quickActionCategory({type: "cheer"}), null);
});

test("a plain push keeps the shared notification and no category", () => {
    const m = push.buildMessagePayload("t", "T", "B", {type: "cheer"});
    assert.deepEqual(m.notification, {title: "T", body: "B"});
    assert.equal(m.android.notification.channelId, "general_notifications");
    assert.equal(m.apns.payload.aps.category, undefined);
    assert.equal(m.data.category, undefined);
});

test("a push with buttons carries the category on iOS and in data", () => {
    const m = push.buildMessagePayload("t", "T", "B", {type: "poke"}, {category: "poke_reply"});
    assert.equal(m.apns.payload.aps.category, "poke_reply");
    assert.equal(m.data.category, "poke_reply");
    assert.ok(m.notification, "older builds still get a system notification");
});

test("data-only drops the shared and Android notification but keeps the iOS alert", () => {
    const m = push.buildMessagePayload("t", "T", "B", {type: "poke"}, {category: "poke_reply", dataOnly: true});
    assert.equal(m.notification, undefined);
    assert.equal(m.android.notification, undefined);
    assert.equal(m.android.priority, "high");
    assert.deepEqual(m.apns.payload.aps.alert, {title: "T", body: "B"});
    assert.equal(m.data.title, "T");
    assert.equal(m.data.body, "B");
});
