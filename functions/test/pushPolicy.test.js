const test = require("node:test");
const assert = require("node:assert/strict");
const policy = require("../lib/pushPolicy");

test("core loop and safety pushes are core", () => {
    for (const data of [
        {type: "partner_connected"},
        {type: "partner_connect_failed", reason: "invalid_code"},
        {type: "action_completed", actionType: "done"},
        {type: "action_missed", planId: "p1"},
        {type: "action_missed", planId: "p1", day: "2026-11-08"},
        {type: "plan_approved"},
        {type: "plan_rejected"},
    ]) {
        assert.equal(policy.pushTier(data), "core", JSON.stringify(data));
    }
    assert.equal(policy.pushTier({type: "cheer"}, {verification: true}), "core");
    assert.equal(policy.pushTier({type: "action_verified"}, {verification: true}), "core");
    assert.equal(policy.pushTier({type: "poke_reply"}, {answersKnock: true}), "core");
    assert.equal(policy.pushTier({type: "plan_proposed"}, {proposalWithinLimit: true}), "core");
});

test("only the loop-critical instance is core; repeats fall back under the cap", () => {
    // Later 인정 of the same plan today (or a 인정 that could not claim the lock).
    assert.equal(policy.pushTier({type: "cheer"}, {verification: false}), "secondary");
    assert.equal(policy.pushTier({type: "action_verified"}), "standard");
    assert.equal(policy.pushTier({type: "action_verified"}, {verification: false}), "standard");
    // A reply with no knock delivered today, or a second reply.
    assert.equal(policy.pushTier({type: "poke_reply"}), "standard");
    assert.equal(policy.pushTier({type: "poke_reply"}, {answersKnock: false}), "standard");
    // Proposals past the daily core budget.
    assert.equal(policy.pushTier({type: "plan_proposed"}), "standard");
    assert.equal(policy.pushTier({type: "plan_proposed"}, {proposalWithinLimit: false}), "standard");
    assert.equal(policy.PLAN_PROPOSALS_CORE_PER_DAY, 3);
    // Hints never promote another type.
    assert.equal(policy.pushTier({type: "poke"}, {verification: true, answersKnock: true}), "standard");
    assert.equal(policy.pushTier({type: "verify_reminder"}, {verification: true}), "secondary");
});

test("tier lock keys", () => {
    // Same keys the knock limit has always used (existing locks keep working).
    assert.equal(policy.pokeLockKey("p1", "b", "a", "2026-11-09"), "poke_plan_p1_2026-11-09");
    assert.equal(policy.pokeLockKey(null, "b", "a", "2026-11-09"), "poke_pair_a_b_2026-11-09");
    assert.equal(policy.pokeLockKey(null, "a", "b", "2026-11-09"), "poke_pair_a_b_2026-11-09");
    assert.equal(policy.replyCoreLockKey("p1", "a", "b", "2026-11-09"), "reply_core_plan_p1_2026-11-09");
    assert.equal(policy.replyCoreLockKey(null, "b", "a", "2026-11-09"), "reply_core_pair_a_b_2026-11-09");
    assert.equal(policy.verifyCoreLockKey("p1", "2026-11-09"), "verify_core_p1_2026-11-09");
    assert.equal(policy.planProposalTokenKey("a", "b", "2026-11-09"), "plan_proposed_core_a_b_2026-11-09");
});

test("informational pushes are standard, extras and nudges secondary", () => {
    assert.equal(policy.pushTier({type: "action_completed", actionType: "skipped"}), "standard");
    assert.equal(policy.pushTier({type: "action_completed", actionType: "rested"}), "standard");
    assert.equal(policy.pushTier({type: "poke", planId: "p1"}), "standard");
    assert.equal(policy.pushTier({type: "plan_updated"}), "standard");
    assert.equal(policy.pushTier({type: "cheer"}), "secondary");
    assert.equal(policy.pushTier({type: "cheer"}, {verification: false}), "secondary");
    assert.equal(policy.pushTier({type: "verify_reminder"}), "secondary");
    assert.equal(policy.pushTier({type: "something_new"}), "secondary");
    assert.equal(policy.pushTier({}), "secondary");
});

test("the cap keeps core, then drops secondary at 5 and standard at 8", () => {
    assert.equal(policy.DAILY_PUSH_CAP, 8);
    assert.equal(policy.SECONDARY_PUSH_LIMIT, 5);
    assert.ok(policy.SECONDARY_PUSH_LIMIT < policy.DAILY_PUSH_CAP);

    for (const count of [0, 4]) {
        assert.equal(policy.quotaDecision("secondary", count).send, true);
        assert.equal(policy.quotaDecision("standard", count).send, true);
    }
    for (const count of [5, 7]) {
        assert.deepEqual(policy.quotaDecision("secondary", count), {send: false, reason: "daily_cap"});
        assert.equal(policy.quotaDecision("standard", count).send, true);
    }
    for (const count of [8, 50]) {
        assert.equal(policy.quotaDecision("secondary", count).send, false);
        assert.deepEqual(policy.quotaDecision("standard", count), {send: false, reason: "daily_cap"});
    }
    for (const count of [0, 8, 1000]) {
        assert.deepEqual(policy.quotaDecision("core", count), {send: true, reason: "core"});
    }
    // A broken counter never blocks.
    assert.equal(policy.quotaDecision("secondary", NaN).send, true);
    assert.equal(policy.quotaDecision("secondary", -3).send, true);
});

test("a simulated busy day: core always arrives, extras stop", () => {
    const sent = [];
    let count = 0;
    const offer = (data, hints) => {
        const decision = policy.quotaDecision(policy.pushTier(data, hints), count);
        if (decision.send) {
            count++;
            sent.push(data.type);
        }
        return decision.send;
    };
    for (let i = 0; i < 6; i++) offer({type: "cheer"});
    assert.equal(sent.length, 5, "only five extra cheers");
    assert.equal(offer({type: "plan_updated"}), true);
    assert.equal(offer({type: "action_completed", actionType: "skipped"}), true);
    assert.equal(offer({type: "poke", planId: "p"}), true);
    assert.equal(count, 8);
    assert.equal(offer({type: "poke", planId: "q"}), false, "standard stops at the cap");
    assert.equal(offer({type: "action_missed", planId: "p"}), true, "core still arrives");
    assert.equal(offer({type: "cheer"}, {verification: true}), true, "a 인정 still arrives");
    assert.equal(offer({type: "poke_reply"}, {answersKnock: true}), true, "the reply to a knock still arrives");
    // A chatty client cannot ride core past the cap.
    assert.equal(offer({type: "cheer"}, {verification: false}), false, "a second 인정 cheer is an extra");
    assert.equal(offer({type: "poke_reply"}), false, "a reply without a knock is standard");
    assert.equal(offer({type: "plan_proposed"}), false, "a fourth proposal is standard");
});

test("the quota day is the recipient's local day", () => {
    // 2026-11-09 15:30 UTC: already the 10th in Seoul, still the 9th in LA.
    const now = new Date(Date.UTC(2026, 10, 9, 15, 30));
    assert.equal(policy.quotaDocId("uidA", now, "Asia/Seoul"), "uidA_20261110");
    assert.equal(policy.quotaDocId("uidA", now, "America/Los_Angeles"), "uidA_20261109");
    // Unknown zones fall back to Asia/Seoul.
    assert.equal(policy.quotaDocId("uidA", now, "Not/AZone"), "uidA_20261110");
    assert.equal(policy.quotaDocId("a/b", now, "Asia/Seoul"), "a_b_20261110");
    assert.equal(policy.compactDayKey({year: 2026, month: 1, day: 5, weekday: 1, minutes: 0}), "20260105");
});

test("plan_updated pushes coalesce per plan and recipient within 15 minutes", () => {
    const base = Date.UTC(2026, 10, 9, 3, 0);
    const key = policy.coalesceKey("bob", {type: "plan_updated", planId: "p1"}, base);
    assert.ok(key);
    assert.equal(policy.coalesceKey("bob", {type: "plan_updated", planId: "p1"}, base + 60 * 1000), key);
    assert.notEqual(policy.coalesceKey("bob", {type: "plan_updated", planId: "p1"}, base + 15 * 60 * 1000), key);
    assert.notEqual(policy.coalesceKey("bob", {type: "plan_updated", planId: "p2"}, base), key);
    assert.notEqual(policy.coalesceKey("amy", {type: "plan_updated", planId: "p1"}, base), key);
    assert.equal(policy.coalesceKey("bob", {type: "plan_updated", planId: ""}, base), null);
    for (const type of ["cheer", "poke", "action_completed", "action_missed", "verify_reminder"]) {
        assert.equal(policy.coalesceKey("bob", {type, planId: "p1"}, base), null, type);
    }
});
