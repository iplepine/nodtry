const test = require("node:test");
const assert = require("node:assert/strict");
const copy = require("../lib/copy");

// English pushes: no app name, no Korean left over, no "님", no surveillance words.
const BANNED_EN = /[가-힣]|DuoDone|둘운완|Nod&Try|Nodtry|monitor|watch|check(ed)? on|surveil/i;
const assertEnglish = (c) => {
    assert.ok(c, "copy expected");
    assert.doesNotMatch(c.title, BANNED_EN, c.title);
    assert.doesNotMatch(c.body, BANNED_EN, c.body);
};

test("langOf: 'en' is English, anything else or missing is Korean", () => {
    assert.equal(copy.langOf("en"), "en");
    assert.equal(copy.langOf("EN"), "en");
    assert.equal(copy.langOf("en-US"), "en");
    assert.equal(copy.langOf("en_GB"), "en");
    assert.equal(copy.langOf("ko"), "ko");
    assert.equal(copy.langOf("ja"), "ko");
    assert.equal(copy.langOf("eng"), "ko");
    assert.equal(copy.langOf(""), "ko");
    assert.equal(copy.langOf(undefined), "ko");
    assert.equal(copy.langOf(null), "ko");
    assert.equal(copy.langOf(42), "ko");
});

test("partnerLabel in English: nickname, then display name, then 'your partner'", () => {
    assert.equal(copy.partnerLabel({partnerNickname: "babe"}, {displayName: "Alex"}, true, "en"), "babe");
    assert.equal(copy.partnerLabel({}, {displayName: "Alex"}, true, "en"), "Alex");
    assert.equal(copy.partnerLabel({}, {displayName: "Me"}, true, "en"), "your partner");
    assert.equal(copy.partnerLabel(null, null, true, "en"), "your partner");
    assert.equal(copy.partnerLabel({partnerNickname: "babe"}, {}, false, "en"), "your partner");
    // Korean stays the default.
    assert.equal(copy.partnerLabel(null, null), "짝꿍");
});

test("Korean stays the default for every copy function", () => {
    assert.equal(copy.pokeCopy("자기", "x").title, "✊ 자기의 똑똑");
    assert.equal(copy.workoutInfo("running").label, "러닝");
    assert.equal(copy.partnerConnectedCopy("").title, "🤝 짝꿍이 연결됐어요");
    assert.equal(copy.fallbackItemTitle("today"), "오늘 약속");
    assert.equal(copy.fallbackItemTitle("yesterday"), "어제 약속");
    assert.equal(copy.formatDeadline({hour: 7, minute: 5}), "07:05까지");
});

test("English workout info and schedule wording", () => {
    const running = copy.workoutInfo("running", "en");
    assert.equal(running.label, "run");
    assert.equal(running.emoji, "🏃");
    assert.equal(running.isWorkout, true);
    assert.equal(copy.workoutInfo("unknown_tile", "en").label, "workout");
    assert.equal(copy.workoutInfo("diet", "en").isWorkout, false);
    assert.equal(copy.workoutInfo(undefined, "en"), null);
    assert.equal(copy.formatDays([1, 3, 5], "en"), "Mon·Wed·Fri");
    assert.equal(copy.formatDays([1, 2, 3, 4, 5], "en"), "Weekdays");
    assert.equal(copy.formatDays([6, 7], "en"), "Weekends");
    assert.equal(copy.formatDays([1, 2, 3, 4, 5, 6, 7], "en"), "Every day");
    assert.equal(copy.formatDeadline({type: "custom", hour: 21, minute: 0}, "en"), "by 21:00");
    assert.equal(copy.formatDeadline({type: "none", hour: 21}, "en"), "");
    assert.equal(copy.fallbackItemTitle("today", "en"), "today's promise");
    assert.equal(copy.fallbackItemTitle("yesterday", "en"), "yesterday's promise");
});

test("English plan created copy", () => {
    const c = copy.planCreatedCopy({
        who: "Alex", workout: copy.workoutInfo("gym", "en"), itemTitle: "Gym",
        days: [1, 3, 5], notificationTime: {type: "custom", hour: 21, minute: 0},
        pendingApproval: false, lang: "en",
    });
    assertEnglish(c);
    assert.equal(c.title, "🤙 Alex made a workout promise");
    assert.equal(c.body, "🏋️ Gym session · Mon·Wed·Fri by 21:00 · You've got my back, right? 👀");

    const fallback = copy.planCreatedCopy({
        who: "your partner", workout: null, itemTitle: "Read a book", days: [1, 2, 3, 4, 5],
        notificationTime: {type: "none"}, pendingApproval: true, lang: "en",
    });
    assertEnglish(fallback);
    assert.equal(fallback.title, "🤙 Your partner made a promise");
    assert.equal(fallback.body, "'Read a book' · Weekdays · Can you take a look?");

    const diet = copy.planCreatedCopy({
        who: "Sam", workout: copy.workoutInfo("diet", "en"), itemTitle: "", days: [], notificationTime: null,
        pendingApproval: false, lang: "en",
    });
    assert.equal(diet.title, "🤙 Sam made a diet promise");
    assert.doesNotMatch(diet.title + diet.body, /workout/i);
});

test("English completed copy: proof, plain, legacy, skip, rest", () => {
    const run = copy.workoutInfo("running", "en");
    const proof = copy.actionCompletedCopy({
        who: "Alex", workout: run, itemTitle: "", actionType: "done", withProof: true, lang: "en",
    });
    assertEnglish(proof);
    assert.equal(proof.title, "📸 Alex's workout proof is here!");
    assert.equal(proof.body, "🏃 Check my run photo and give me props?");

    const plain = copy.actionCompletedCopy({
        who: "your partner", workout: run, itemTitle: "", actionType: "done", withProof: false, lang: "en",
    });
    assertEnglish(plain);
    assert.equal(plain.title, "🏃 Your partner finished today's run!");
    assert.equal(plain.body, "Give me props?");
    assert.doesNotMatch(plain.title + plain.body, /photo|proof/);

    const withNote = copy.actionCompletedCopy({
        who: "Alex", workout: run, itemTitle: "", actionType: "done", withProof: false, note: "5k PR", lang: "en",
    });
    assert.equal(withNote.body, "\"5k PR\" Give me props?");

    const diet = copy.actionCompletedCopy({
        who: "Alex", workout: copy.workoutInfo("diet", "en"), itemTitle: "", actionType: "done",
        withProof: false, lang: "en",
    });
    assert.equal(diet.title, "🥗 Alex stuck to the diet today!");
    assert.doesNotMatch(diet.title + diet.body, /workout/i);

    const legacy = copy.actionCompletedCopy({
        who: "Alex", workout: null, itemTitle: "Read 20 pages", actionType: "done", withProof: false, lang: "en",
    });
    assertEnglish(legacy);
    assert.equal(legacy.title, "✅ Alex kept today's promise!");
    assert.match(legacy.body, /'Read 20 pages'/);
    assert.doesNotMatch(legacy.title + legacy.body, /workout/i);

    const skipped = copy.actionCompletedCopy({
        who: "Alex", workout: run, itemTitle: "", actionType: "skipped", withProof: false, lang: "en",
    });
    assertEnglish(skipped);
    assert.equal(skipped.body, "Skipping today's run.");

    const rested = copy.actionCompletedCopy({
        who: "Alex", workout: run, itemTitle: "", actionType: "rested", withProof: false, lang: "en",
    });
    assertEnglish(rested);
    assert.match(rested.body, /rest pass/);
    assert.doesNotMatch(rested.body, /tomorrow/i);

    assert.equal(copy.actionCompletedCopy({
        who: "a", workout: null, itemTitle: "", actionType: "rescued", withProof: false, lang: "en",
    }), null);
});

test("English knock, reply, reactions and plan changes", () => {
    const fallback = copy.defaultPokeMessage(copy.workoutInfo("yoga", "en"), true, "en");
    assert.equal(fallback, "Waiting on your yoga today 👀");
    assert.equal(copy.defaultPokeMessage(null, true, "en"), "Waiting on today's promise 👀");
    assertEnglish({title: "", body: copy.defaultPokeMessage(null, false, "en")});
    // A legacy stored text is replaced with the English default.
    assert.equal(copy.sanitizePokeMessage("똑똑! 실천 메이트가 기다리고 있어요.", fallback), fallback);

    const poke = copy.pokeCopy("your partner", fallback, "en");
    assertEnglish(poke);
    assert.equal(poke.title, "✊ Knock knock from your partner");

    const reply = copy.pokeReplyCopy("your partner", "", "en");
    assertEnglish(reply);
    assert.equal(reply.title, "💬 Your partner replied");
    assert.equal(reply.body, "Replied to your knock");
    // The partner's own words are relayed as written.
    assert.equal(copy.pokeReplyCopy("Alex", "지금 간다 🏃", "en").body, "지금 간다 🏃");

    const props = copy.reactionCopy({
        who: "Alex", emoji: "🔥", isVerification: true, workout: copy.workoutInfo("running", "en"), lang: "en",
    });
    assertEnglish(props);
    assert.equal(props.title, "🔥 Props from Alex!");
    assert.equal(props.body, "Props on your run! Nice work 👏");
    const cheer = copy.reactionCopy({who: "your partner", emoji: "❤️", isVerification: false, workout: null, lang: "en"});
    assertEnglish(cheer);
    assert.equal(cheer.title, "❤️ Your partner sent you a cheer!");

    for (const c of [
        copy.planApprovedCopy("Alex", "en"),
        copy.planRejectedCopy("Alex", "", "en"),
        copy.planChangedCopy("your partner", "en"),
    ]) {
        assertEnglish(c);
    }
    assert.equal(copy.planChangedCopy("your partner", "en").title, "📝 Your partner changed a promise");
});

test("English system copy: missed, verify reminder, connection", () => {
    const run = copy.workoutInfo("running", "en");
    const missed = copy.missedCopy({who: "Alex", workout: run, itemTitle: "", lang: "en"});
    assertEnglish(missed);
    assert.equal(missed.title, "⏰ Alex hasn't logged today's run yet");
    assert.equal(missed.body, "Want to send a cheer or a knock?");

    const legacy = copy.missedCopy({who: "your partner", workout: null, itemTitle: "Journal", lang: "en"});
    assertEnglish(legacy);
    assert.equal(legacy.title, "⏰ Your partner hasn't logged today's promise yet");
    assert.match(legacy.body, /'Journal'/);

    const yesterday = copy.missedCopy({who: "your partner", workout: run, itemTitle: "", day: "yesterday", lang: "en"});
    assertEnglish(yesterday);
    assert.equal(yesterday.title, "⏰ No record of your partner's run yesterday");
    assert.doesNotMatch(yesterday.title + yesterday.body, /today/i);

    const reminder = copy.verifyReminderCopy({who: "Alex", workout: run, itemTitle: "", daysAgo: 1, lang: "en"});
    assertEnglish(reminder);
    assert.equal(reminder.title, "👀 Alex's record is waiting for props");
    assert.equal(reminder.body, "Take a look at yesterday's run and give props?");
    assert.match(copy.verifyReminderCopy({who: "A", workout: null, itemTitle: "Read", daysAgo: 5, lang: "en"}).body,
        /an earlier 'Read'/);

    assert.equal(copy.partnerConnectedCopy("Alex", "en").title, "🤝 You and Alex are now partners");
    assert.equal(copy.partnerConnectedCopy("Me", "en").title, "🤝 Your partner is connected");
    assertEnglish(copy.partnerConnectedCopy("", "en"));
    for (const reason of ["owner_taken", "self_taken", "invalid_code"]) {
        const failed = copy.partnerConnectFailedCopy(reason, "en");
        assertEnglish(failed);
        assert.equal(failed.title, "Couldn't connect");
    }
});
