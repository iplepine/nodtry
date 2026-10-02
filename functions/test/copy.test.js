const test = require("node:test");
const assert = require("node:assert/strict");
const copy = require("../lib/copy");

const BANNED = /님|실천 메이트|Nod&Try|Nodtry|그래,해봐|공부|스터디|둘운완|DuoDone/;
const assertClean = (c) => {
    assert.ok(c, "copy expected");
    assert.doesNotMatch(c.title, BANNED);
    assert.doesNotMatch(c.body, BANNED);
};
const assertNeutral = (c) => {
    assertClean(c);
    assert.doesNotMatch(`${c.title} ${c.body}`, /운동|오운완/);
};

test("partnerLabel prefers the recipient's nickname, then display name, then 짝꿍", () => {
    assert.equal(copy.partnerLabel({partnerNickname: "자기"}, {displayName: "박정호"}), "자기");
    assert.equal(copy.partnerLabel({partnerNickname: "  "}, {displayName: "박정호"}), "박정호");
    assert.equal(copy.partnerLabel({}, {}), "짝꿍");
    assert.equal(copy.partnerLabel(null, null), "짝꿍");
    assert.equal(Array.from(copy.partnerLabel({partnerNickname: "아주아주아주긴애칭입니다"}, null)).length, 10);
});

test("workoutInfo maps tiles and treats diet as non-workout", () => {
    assert.equal(copy.workoutInfo("running").label, "러닝");
    assert.equal(copy.workoutInfo("diet").isWorkout, false);
    assert.equal(copy.workoutInfo("unknown_tile").label, "운동");
    assert.equal(copy.workoutInfo(undefined), null);
    assert.equal(copy.workoutInfo(""), null);
});

test("completed copy: proof variant vs plain vs neutral", () => {
    const running = copy.workoutInfo("running");
    const proof = copy.actionCompletedCopy({
        who: "자기", workout: running, itemTitle: "러닝", actionType: "done", withProof: true,
    });
    assertClean(proof);
    assert.match(proof.title, /^📸 자기 오운완 인증샷 도착!$/);
    assert.match(proof.body, /인정해 줄래\?/);

    const plain = copy.actionCompletedCopy({
        who: "자기", workout: running, itemTitle: "러닝", actionType: "done", withProof: false,
    });
    assertClean(plain);
    assert.equal(plain.title, "🏃 자기 오늘 러닝 끝!");
    assert.doesNotMatch(plain.title + plain.body, /인증샷/);

    const legacy = copy.actionCompletedCopy({
        who: "짝꿍", workout: null, itemTitle: "영어 단어 20개", actionType: "done", withProof: false,
    });
    assertNeutral(legacy);
    assert.match(legacy.body, /'영어 단어 20개'/);

    for (const actionType of ["skipped", "rested"]) {
        assertNeutral(copy.actionCompletedCopy({
            who: "짝꿍", workout: null, itemTitle: "독서", actionType, withProof: false,
        }));
    }
    assert.equal(copy.actionCompletedCopy({
        who: "a", workout: null, itemTitle: "", actionType: "rescued", withProof: false,
    }), null);
});

test("diet plans never say 운동 or 오운완", () => {
    const diet = copy.workoutInfo("diet");
    const done = copy.actionCompletedCopy({who: "여보", workout: diet, itemTitle: "", actionType: "done", withProof: true});
    assert.doesNotMatch(done.title + done.body, /운동|오운완/);
    const created = copy.planCreatedCopy({
        who: "여보", workout: diet, itemTitle: "", days: [1, 2, 3, 4, 5, 6, 7], notificationTime: null,
        pendingApproval: false,
    });
    assert.doesNotMatch(created.title + created.body, /운동/);
});

test("plan created copy summarises the schedule", () => {
    const c = copy.planCreatedCopy({
        who: "오빠",
        workout: copy.workoutInfo("gym"),
        itemTitle: "헬스",
        days: [1, 3, 5],
        notificationTime: {type: "custom", hour: 21, minute: 0},
        pendingApproval: false,
    });
    assertClean(c);
    assert.equal(c.title, "🤙 오빠 운동 약속 걸었어");
    assert.equal(c.body, "🏋️ 헬스 · 월·수·금 21:00까지 · 봐줄 거지? 👀");

    const legacy = copy.planCreatedCopy({
        who: "짝꿍", workout: null, itemTitle: "책 읽기", days: [1, 2, 3, 4, 5],
        notificationTime: {type: "none"}, pendingApproval: true,
    });
    assertNeutral(legacy);
    assert.equal(legacy.body, "'책 읽기' · 평일 · 확인해 줄래?");
    assert.equal(copy.formatDays([6, 7]), "주말");
    assert.equal(copy.formatDays([7, 1, 1]), "월·일");
    assert.equal(copy.formatDays("x"), "");
});

test("legacy poke texts are replaced, others kept", () => {
    const fallback = copy.defaultPokeMessage(copy.workoutInfo("running"), true);
    assert.equal(fallback, "오늘 러닝 기다리고 있어 👀");
    assert.equal(copy.sanitizePokeMessage("똑똑! 실천 메이트가 기다리고 있어요. 오늘 약속을 정리해볼까요?", fallback), fallback);
    assert.equal(copy.sanitizePokeMessage("", fallback), fallback);
    assert.equal(copy.sanitizePokeMessage(undefined, fallback), fallback);
    assert.equal(copy.sanitizePokeMessage("헬스장 문 닫기 전에 가자 🏃", fallback), "헬스장 문 닫기 전에 가자 🏃");
    assert.equal(copy.defaultPokeMessage(null, true), "오늘 약속 기다리고 있어 👀");
    assertClean(copy.pokeCopy("자기", fallback));
});

test("reply, reaction and system copies stay particle-safe", () => {
    const reply = copy.pokeReplyCopy("자기", "지금 간다 🏃");
    assert.equal(reply.title, "💬 자기의 답장");
    assert.equal(reply.body, "지금 간다 🏃");

    const verified = copy.reactionCopy({
        who: "자기", emoji: copy.reactionEmoji("🔥"), isVerification: true, workout: copy.workoutInfo("yoga"),
    });
    assert.equal(verified.title, "🔥 자기의 인정 도착!");
    assertClean(verified);
    const cheer = copy.reactionCopy({who: "짝꿍", emoji: "❤️", isVerification: false, workout: null});
    assertNeutral(cheer);
    assert.match(cheer.title, /응원/);

    assert.equal(copy.reactionEmoji("poke"), "❤️");
    assert.equal(copy.reactionEmoji("thumbs_up"), "❤️");
    assert.equal(copy.reactionEmoji("👏"), "👏");

    assertNeutral(copy.missedCopy({who: "짝꿍", workout: null, itemTitle: "독서"}));
    assertClean(copy.missedCopy({who: "자기", workout: copy.workoutInfo("running"), itemTitle: "러닝"}));
    assertNeutral(copy.verifyReminderCopy({who: "짝꿍", workout: null, itemTitle: "독서", daysAgo: 1}));
    assertClean(copy.partnerConnectedCopy("박정호"));
    assertClean(copy.partnerConnectedCopy(""));
    for (const reason of ["owner_taken", "self_taken", "invalid_code"]) {
        assertClean(copy.partnerConnectFailedCopy(reason));
    }
    assertClean(copy.planApprovedCopy("자기"));
    assertClean(copy.planRejectedCopy("자기", ""));
    assertClean(copy.planChangedCopy("자기"));
});

test("placeholder self-names ('나', 'Me') never become the partner label", () => {
    assert.equal(copy.isPlaceholderName("나"), true);
    assert.equal(copy.isPlaceholderName(" Me "), true);
    assert.equal(copy.isPlaceholderName("me"), true);
    assert.equal(copy.isPlaceholderName("나래"), false);
    assert.equal(copy.isPlaceholderName(undefined), false);
    assert.equal(copy.partnerLabel({}, {displayName: "나"}), "짝꿍");
    assert.equal(copy.partnerLabel({}, {displayName: "Me"}), "짝꿍");
    assert.equal(copy.partnerLabel({partnerNickname: "자기"}, {displayName: "나"}), "자기");
    assert.equal(copy.displayNameOf({displayName: "나"}), "");
    assert.equal(copy.displayNameOf({displayName: "박정호"}), "박정호");

    const missed = copy.missedCopy({
        who: copy.partnerLabel({}, {displayName: "나"}), workout: copy.workoutInfo("running"), itemTitle: "러닝",
    });
    assert.equal(missed.title, "⏰ 짝꿍 오늘 러닝 기록이 아직이에요");
    assert.equal(copy.partnerConnectedCopy("나").title, "🤝 짝꿍이 연결됐어요");
    assert.equal(copy.partnerConnectedCopy("Me").title, "🤝 짝꿍이 연결됐어요");
    assert.equal(copy.partnerConnectedCopy("박정호").title, "🤝 박정호의 짝꿍이 됐어요");
});

test("a nickname set for another partner is not used", () => {
    const recipient = {partnerNickname: "여보"};
    assert.equal(copy.partnerLabel(recipient, {displayName: "친구"}, false), "친구");
    assert.equal(copy.partnerLabel(recipient, {displayName: "나"}, false), "짝꿍");
    assert.equal(copy.partnerLabel(recipient, {displayName: "친구"}, true), "여보");
});

test("rest copy does not promise 'tomorrow'", () => {
    const rested = copy.actionCompletedCopy({
        who: "자기", workout: copy.workoutInfo("running"), itemTitle: "러닝", actionType: "rested", withProof: false,
    });
    assert.equal(rested.body, "휴식권 썼어. 다음엔 꼭 할게!");
    assert.doesNotMatch(rested.body, /내일/);
});

test("a late deadline judged after midnight says 어제", () => {
    const workout = copy.missedCopy({
        who: "자기", workout: copy.workoutInfo("diet"), itemTitle: "야식 참기", day: "yesterday",
    });
    assertClean(workout);
    assert.equal(workout.title, "⏰ 자기 어제 식단 기록이 없어요");
    assert.doesNotMatch(workout.title + workout.body, /오늘|운동/);
    const neutral = copy.missedCopy({who: "짝꿍", workout: null, itemTitle: "일기", day: "yesterday"});
    assertNeutral(neutral);
    assert.match(neutral.body, /'일기'/);
});
