const test = require("node:test");
const assert = require("node:assert/strict");
const together = require("../lib/together");
const copy = require("../lib/copy");
const policy = require("../lib/pushPolicy");
const push = require("../lib/push");

const BANNED = /님|애인|실천 메이트|Nod&Try|Nodtry|그래,해봐|공부|스터디|둘운완|DuoDone|감시|검사/;

test("togetherClaimOf: only a done record naming someone else and their plan", () => {
    const done = {type: "done", togetherWithUid: "bob", togetherPartnerPlanId: "planB"};
    assert.deepEqual(together.togetherClaimOf(done, "alice"), {partnerId: "bob", partnerPlanId: "planB"});
    assert.equal(together.togetherClaimOf({...done, type: "skipped"}, "alice"), null);
    assert.equal(together.togetherClaimOf({...done, type: "rested"}, "alice"), null);
    assert.equal(together.togetherClaimOf({...done, togetherWithUid: "alice"}, "alice"), null);
    assert.equal(together.togetherClaimOf({...done, togetherWithUid: ""}, "alice"), null);
    assert.equal(together.togetherClaimOf({...done, togetherPartnerPlanId: 7}, "alice"), null);
    assert.equal(together.togetherClaimOf({type: "done"}, "alice"), null);
    assert.equal(together.togetherClaimOf(done, null), null);
    assert.equal(together.togetherClaimOf(null, "alice"), null);
    // A 나도 했어 never asks back, even if a client copied the fields over.
    assert.equal(together.togetherClaimOf({...done, sharedProofFromUid: "bob"}, "alice"), null);
    assert.equal(together.togetherClaimOf({...done, togetherActionId: "a1"}, "alice"), null);
});

test("togetherPlanAccepts: the partner's own running plan only", () => {
    assert.equal(together.togetherPlanAccepts({userId: "bob", state: "active"}, "bob"), true);
    assert.equal(together.togetherPlanAccepts({userId: "bob", state: "completed"}, "bob"), false);
    assert.equal(together.togetherPlanAccepts({userId: "carol", state: "active"}, "bob"), false);
    assert.equal(together.togetherPlanAccepts(null, "bob"), false);
});

test("isTogetherConfirmation spots the partner's 나도 했어", () => {
    assert.equal(together.isTogetherConfirmation({type: "done", sharedProofFromUid: "alice"}), true);
    assert.equal(together.isTogetherConfirmation({type: "done", togetherActionId: "a1"}), true);
    assert.equal(together.isTogetherConfirmation({type: "done"}), false);
    assert.equal(together.isTogetherConfirmation(null), false);
});

test("one together_log per partner plan per day", () => {
    assert.equal(together.togetherLockKey("planB", "2026-11-10"), "together_planB_2026-11-10");
    assert.notEqual(together.togetherLockKey("planB", "2026-11-10"), together.togetherLockKey("planB", "2026-11-11"));
    assert.equal(together.TOGETHER_BUILD, 88);
});

test("together_log is core and carries the 나도 했어 button", () => {
    assert.equal(policy.pushTier({type: "together_log", planId: "planB"}), "core");
    assert.equal(policy.quotaDecision(policy.pushTier({type: "together_log"}), 50).send, true);
    assert.equal(push.quickActionCategory({type: "together_log", planId: "planB"}), "together_log");
    assert.equal(push.quickActionCategory({type: "together_log"}), null);
});

test("withSubjectJosa picks 이/가 like the app", () => {
    assert.equal(copy.withSubjectJosa("자기"), "자기가");
    assert.equal(copy.withSubjectJosa("짝꿍"), "짝꿍이");
    assert.equal(copy.withSubjectJosa("민준"), "민준이");
    assert.equal(copy.withSubjectJosa("곰돌이🐻"), "곰돌이🐻가");
    assert.equal(copy.withSubjectJosa("Tom"), "Tom이");
    assert.equal(copy.withSubjectJosa("Amy"), "Amy가");
    assert.equal(copy.withSubjectJosa("BTS"), "BTS가");
    assert.equal(copy.withSubjectJosa("10"), "10이");
    assert.equal(copy.withSubjectJosa("2"), "2가");
    assert.equal(copy.withSubjectJosa(""), "가");
});

test("together_log copy: ko 해요체 with the partner's question, en, neutral for non-workouts", () => {
    const running = copy.workoutInfo("running");
    const ko = copy.togetherLogCopy({who: "자기", workout: running});
    assert.equal(ko.title, "🤝 자기가 같이 운동했다고 기록했어요");
    assert.match(ko.body, /^같이 했어\?/);
    assert.match(ko.body, /나도 했어/);
    assert.doesNotMatch(`${ko.title} ${ko.body}`, BANNED);

    const fallback = copy.togetherLogCopy({who: "짝꿍", workout: running, lang: "ko"});
    assert.equal(fallback.title, "🤝 짝꿍이 같이 운동했다고 기록했어요");

    const neutral = copy.togetherLogCopy({who: "자기", workout: null});
    assert.doesNotMatch(`${neutral.title} ${neutral.body}`, /운동|오운완/);
    const diet = copy.togetherLogCopy({who: "자기", workout: copy.workoutInfo("diet")});
    assert.doesNotMatch(`${diet.title} ${diet.body}`, /운동/);

    const en = copy.togetherLogCopy({who: "your partner", workout: copy.workoutInfo("gym", "en"), lang: "en"});
    assert.equal(en.title, "🤝 Your partner logged a workout with you");
    assert.match(en.body, /I did too/);
    assert.doesNotMatch(`${en.title} ${en.body}`, /[가-힣]/);
});

test("together confirmed copy: partner voice, no 인증샷 도착", () => {
    const ko = copy.togetherConfirmedCopy({who: "자기", workout: copy.workoutInfo("gym")});
    assert.equal(ko.title, "🤝 자기도 같이 했어!");
    assert.match(ko.body, /인정해 줄래\?$/);
    assert.doesNotMatch(`${ko.title} ${ko.body}`, BANNED);
    assert.doesNotMatch(`${ko.title} ${ko.body}`, /인증샷/);
    const en = copy.togetherConfirmedCopy({who: "Alex", workout: null, lang: "en"});
    assert.equal(en.title, "🤝 Alex logged it too!");
    assert.doesNotMatch(en.body, /workout/i);
});
