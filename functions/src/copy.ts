// Push copy for 둘운완 / DuoDone, in Korean (default) and English.
//
// The language follows the recipient: `users/{uid}.locale` ("en" → English,
// anything else or missing → Korean; see langOf). Every copy function takes
// an optional `lang` and defaults to Korean, so callers that do not pass one
// keep the pre-localization behaviour.
//
// Tone rules (docs/product/PIVOT_DUOUNWAN_SPEC.md §3):
//   - A push that relays something the partner did is written in the
//     partner's casual voice (반말): "{name} 오늘 러닝 끝! 인정해 줄래?".
//   - A push where the app itself informs (missed deadline, reminder,
//     connection status) uses 해요체.
//   - Never "{name}님"; only particle-free joins after a name
//     ("{name}의", "{name} 오늘 …").
//   - No app name in pushes (neither 둘운완 nor DuoDone), no surveillance
//     wording.
//   - Workout wording only when the plan carries `workoutType`; legacy plans
//     (no workoutType, e.g. old study plans) get neutral "약속" wording.
//
// English mirrors the app's own English terms (lib/l10n/app_en.arb): 약속 →
// "promise", 인정 → "props", 똑똑 → "knock", 휴식권 → "rest pass",
// 짝꿍 → "your partner".

export type PushCopy = {title: string; body: string};

/** Push copy language. */
export type Lang = "ko" | "en";

/**
 * The push language of a recipient: English for an `en` locale (the app
 * writes "ko" or "en"; "en-US"/"en_GB" are accepted too), Korean otherwise.
 */
export function langOf(locale: unknown): Lang {
    if (typeof locale !== "string") return "ko";
    return /^en([-_]|$)/i.test(locale.trim()) ? "en" : "ko";
}

export type WorkoutInfo = {
    /** Short label used in sentences, e.g. "러닝" / "run". */
    label: string;
    emoji: string;
    /** Word placed before "인증샷": "오운완" for workouts, "식단" for diet. */
    proofWord: string;
    /** Completion phrase after the label: "끝!" / "지켰어!". */
    doneWord: string;
    /** True for exercise; false for the diet tile (no "운동" wording). */
    isWorkout: boolean;
};

const WORKOUTS: {[type: string]: [string, string]} = {
    gym: ["헬스", "🏋️"],
    running: ["러닝", "🏃"],
    home_training: ["홈트", "🏠"],
    walking: ["걷기", "🚶"],
    pilates: ["필라테스", "🧘‍♀️"],
    yoga: ["요가", "🧘"],
    stretching: ["스트레칭", "🤸"],
    swimming: ["수영", "🏊"],
    climbing: ["클라이밍", "🧗"],
    cycling: ["자전거", "🚴"],
    hiking: ["등산", "⛰️"],
    strength: ["근력 운동", "💪"],
    other: ["운동", "💪"],
};

/** English labels, written to sit inside a sentence ("today's run"). */
const WORKOUTS_EN: {[type: string]: string} = {
    gym: "gym session",
    running: "run",
    home_training: "home workout",
    walking: "walk",
    pilates: "Pilates",
    yoga: "yoga",
    stretching: "stretching",
    swimming: "swim",
    climbing: "climbing",
    cycling: "ride",
    hiking: "hike",
    strength: "strength workout",
    other: "workout",
};

export const FALLBACK_PARTNER_LABEL = "짝꿍";
export const FALLBACK_PARTNER_LABEL_EN = "your partner";

/** Legacy phrases old app builds stored inside poke messages. */
const LEGACY_POKE_PHRASES = ["실천 메이트"];

export function workoutInfo(workoutType: unknown, lang: Lang = "ko"): WorkoutInfo | null {
    if (typeof workoutType !== "string" || !workoutType) return null;
    if (workoutType === "diet") {
        return lang === "en" ?
            {label: "diet", emoji: "🥗", proofWord: "diet", doneWord: "stuck to", isWorkout: false} :
            {label: "식단", emoji: "🥗", proofWord: "식단", doneWord: "지켰어!", isWorkout: false};
    }
    const entry = WORKOUTS[workoutType] ?? WORKOUTS.other;
    if (lang === "en") {
        const label = WORKOUTS_EN[workoutType] ?? WORKOUTS_EN.other;
        return {label, emoji: entry[1], proofWord: "workout", doneWord: "finished", isWorkout: true};
    }
    return {label: entry[0], emoji: entry[1], proofWord: "오운완", doneWord: "끝!", isWorkout: true};
}

export function clip(value: unknown, max: number): string {
    if (typeof value !== "string") return "";
    const trimmed = value.replace(/\s+/g, " ").trim();
    const chars = Array.from(trimmed);
    if (chars.length <= max) return trimmed;
    return `${chars.slice(0, max - 1).join("")}…`;
}

type NamedUser = {partnerNickname?: unknown; displayName?: unknown} | null | undefined;

/**
 * Self-labels the app stores as displayName when the account has no name
 * (guests, Apple sign-in without a name): "나" / "Me". Shown to the partner
 * they read as the recipient themself ("⏰ 나 오늘 러닝 기록이 아직이에요"),
 * so they count as no name at all.
 */
const PLACEHOLDER_NAMES = new Set(["나", "me"]);

export function isPlaceholderName(value: unknown): boolean {
    if (typeof value !== "string") return false;
    return PLACEHOLDER_NAMES.has(value.trim().toLowerCase());
}

/** The user's display name (clipped), or "" when missing or a placeholder. */
export function displayNameOf(user: NamedUser, max = 20): string {
    if (isPlaceholderName(user?.displayName)) return "";
    return clip(user?.displayName, max);
}

/**
 * How the recipient sees the sender: the recipient's own nickname for their
 * partner, then the sender's display name, then "짝꿍" ("your partner" in
 * English).
 *
 * `nicknameApplies` is false when the nickname was not set for this sender
 * (an account still linked to more than one partner from before 1:1).
 */
export function partnerLabel(
    recipient: NamedUser,
    sender: NamedUser,
    nicknameApplies = true,
    lang: Lang = "ko",
): string {
    const nickname = nicknameApplies ? clip(recipient?.partnerNickname, 10) : "";
    if (nickname) return nickname;
    const displayName = displayNameOf(sender);
    if (displayName) return displayName;
    return lang === "en" ? FALLBACK_PARTNER_LABEL_EN : FALLBACK_PARTNER_LABEL;
}

/**
 * `who` at the start of an English sentence: only the "your partner"
 * fallback is capitalised; names and nicknames are kept as the user wrote
 * them.
 */
function capWho(who: string): string {
    return who === FALLBACK_PARTNER_LABEL_EN ? "Your partner" : who;
}

/** English possessive of a name: "Alex's", "your partner's". */
function possessive(who: string): string {
    return `${who}'s`;
}

/** A short emoji reaction, or ❤️ when the stored value is not one. */
export function reactionEmoji(value: unknown): string {
    if (typeof value !== "string") return "❤️";
    const trimmed = value.trim();
    if (!trimmed || trimmed === "poke" || trimmed === "reply") return "❤️";
    if (/[A-Za-z0-9가-힣]/.test(trimmed)) return "❤️";
    if (Array.from(trimmed).length > 4) return "❤️";
    return trimmed;
}

function quotedTitle(itemTitle: string, lang: Lang = "ko"): string {
    return `'${clip(itemTitle, 30) || (lang === "en" ? "promise" : "약속")}'`;
}

/**
 * The item title used when a legacy item has none (push copy and
 * `data.itemTitle`): "오늘 약속" / "어제 약속" in Korean.
 */
export function fallbackItemTitle(day: "today" | "yesterday", lang: Lang = "ko"): string {
    if (lang === "en") return day === "yesterday" ? "yesterday's promise" : "today's promise";
    return day === "yesterday" ? "어제 약속" : "오늘 약속";
}

export function defaultPokeMessage(workout: WorkoutInfo | null, hasPlan: boolean, lang: Lang = "ko"): string {
    if (lang === "en") {
        if (workout) return `Waiting on your ${workout.label} today 👀`;
        if (hasPlan) return "Waiting on today's promise 👀";
        return "Want to make a workout promise together? 👀";
    }
    if (workout) return `오늘 ${workout.label} 기다리고 있어 👀`;
    if (hasPlan) return "오늘 약속 기다리고 있어 👀";
    return "운동 약속 하나 같이 걸어 볼래? 👀";
}

/**
 * Old builds stored "똑똑! 실천 메이트가 …" as the poke text and the server
 * relays it verbatim. Replace those (and empty texts) with the new default.
 */
export function sanitizePokeMessage(message: unknown, fallback: string): string {
    const text = clip(message, 120);
    if (!text) return fallback;
    if (LEGACY_POKE_PHRASES.some((phrase) => text.includes(phrase))) return fallback;
    return text;
}

const WEEKDAY_LABELS = ["월", "화", "수", "목", "금", "토", "일"];
const WEEKDAY_LABELS_EN = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export function formatDays(days: unknown, lang: Lang = "ko"): string {
    if (!Array.isArray(days)) return "";
    const unique = Array.from(new Set(days.filter((d) => Number.isInteger(d) && d >= 1 && d <= 7) as number[]))
        .sort((a, b) => a - b);
    if (unique.length === 0) return "";
    const en = lang === "en";
    if (unique.length === 7) return en ? "Every day" : "매일";
    if (unique.join(",") === "1,2,3,4,5") return en ? "Weekdays" : "평일";
    if (unique.join(",") === "6,7") return en ? "Weekends" : "주말";
    const labels = en ? WEEKDAY_LABELS_EN : WEEKDAY_LABELS;
    return unique.map((d) => labels[d - 1]).join("·");
}

/**
 * The schedule part of a plan summary: "주 3회" / "3x a week" for a 주 N회 plan
 * (`weeklyTarget`, its items list all seven weekdays), the weekdays otherwise.
 */
export function formatSchedule(days: unknown, weeklyTarget: unknown, lang: Lang = "ko"): string {
    if (typeof weeklyTarget === "number" && Number.isInteger(weeklyTarget) &&
        weeklyTarget >= 1 && weeklyTarget <= 6) {
        return lang === "en" ? `${weeklyTarget}x a week` : `주 ${weeklyTarget}회`;
    }
    return formatDays(days, lang);
}

export function formatDeadline(notificationTime: unknown, lang: Lang = "ko"): string {
    if (!notificationTime || typeof notificationTime !== "object") return "";
    const time = notificationTime as {type?: unknown; hour?: unknown; minute?: unknown};
    if (time.type === "none") return "";
    if (typeof time.hour !== "number") return "";
    const minute = typeof time.minute === "number" ? time.minute : 0;
    const clock = `${String(time.hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
    return lang === "en" ? `by ${clock}` : `${clock}까지`;
}

export function planCreatedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    days: unknown;
    /** `plans.weeklyTarget` (주 N회), when set. */
    weeklyTarget?: unknown;
    notificationTime: unknown;
    pendingApproval: boolean;
    lang?: Lang;
}): PushCopy {
    const {who, workout} = input;
    const lang = input.lang ?? "ko";
    const en = lang === "en";
    let title: string;
    let head: string;
    if (workout) {
        if (en) {
            title = workout.isWorkout ?
                `🤙 ${capWho(who)} made a workout promise` :
                `🤙 ${capWho(who)} made a ${workout.label} promise`;
        } else {
            title = workout.isWorkout ?
                `🤙 ${who} 운동 약속 걸었어` :
                `🤙 ${who} ${workout.label} 약속 걸었어`;
        }
        head = `${workout.emoji} ${en ? capitalize(workout.label) : workout.label}`;
    } else {
        title = en ? `🤙 ${capWho(who)} made a promise` : `🤙 ${who} 약속 걸었어`;
        head = quotedTitle(input.itemTitle, lang);
    }
    const schedule = [
        formatSchedule(input.days, input.weeklyTarget, lang),
        formatDeadline(input.notificationTime, lang),
    ].filter((part) => part).join(" ");
    const summary = [head, schedule].filter((part) => part).join(" · ");
    const ask = en ?
        (input.pendingApproval ? "Can you take a look?" : "You've got my back, right? 👀") :
        (input.pendingApproval ? "확인해 줄래?" : "봐줄 거지? 👀");
    return {title, body: `${summary} · ${ask}`};
}

function capitalize(value: string): string {
    return value ? value[0].toUpperCase() + value.slice(1) : value;
}

export function actionCompletedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    actionType: unknown;
    withProof: boolean;
    note?: unknown;
    lang?: Lang;
}): PushCopy | null {
    if (input.lang === "en") return actionCompletedCopyEn(input);
    const {who, workout} = input;
    const note = clip(input.note, 60);
    if (input.actionType === "done") {
        if (input.withProof) {
            const title = workout ?
                `📸 ${who} ${workout.proofWord} 인증샷 도착!` :
                `📸 ${who} 인증샷 도착!`;
            const body = note ? `"${note}" 인정해 줄래?` :
                workout ? `${workout.emoji} ${workout.label} 인증샷 보고 인정해 줄래?` :
                    `${quotedTitle(input.itemTitle)} 인증샷 보고 인정해 줄래?`;
            return {title, body};
        }
        const title = workout ?
            `${workout.emoji} ${who} 오늘 ${workout.label} ${workout.doneWord}` :
            `✅ ${who} 오늘 약속 완료!`;
        const body = note ? `"${note}" 인정해 줄래?` :
            workout ? "인정해 줄래?" : `${quotedTitle(input.itemTitle)} 했어. 인정해 줄래?`;
        return {title, body};
    }
    if (input.actionType === "skipped") {
        return {
            title: `↩️ ${who} 오늘은 건너뛸래`,
            body: workout ?
                `오늘 ${workout.label} 건너뛰기로 했어.` :
                `오늘 ${quotedTitle(input.itemTitle)} 건너뛰기로 했어.`,
        };
    }
    if (input.actionType === "rested") {
        // Not "내일": the next scheduled day may be days away (월·수·금).
        return {title: `🌿 ${who} 오늘은 쉬어 갈게`, body: "휴식권 썼어. 다음엔 꼭 할게!"};
    }
    return null;
}

function actionCompletedCopyEn(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    actionType: unknown;
    withProof: boolean;
    note?: unknown;
}): PushCopy | null {
    const {who, workout} = input;
    const Who = capWho(who);
    const note = clip(input.note, 60);
    const quoted = quotedTitle(input.itemTitle, "en");
    if (input.actionType === "done") {
        if (input.withProof) {
            const title = workout ?
                `📸 ${possessive(Who)} ${workout.proofWord} proof is here!` :
                `📸 ${possessive(Who)} proof photo is here!`;
            const body = note ? `"${note}" Give me props?` :
                workout ? `${workout.emoji} Check my ${workout.label} photo and give me props?` :
                    `Check my ${quoted} photo and give me props?`;
            return {title, body};
        }
        const title = workout ?
            (workout.isWorkout ?
                `${workout.emoji} ${Who} ${workout.doneWord} today's ${workout.label}!` :
                `${workout.emoji} ${Who} ${workout.doneWord} the ${workout.label} today!`) :
            `✅ ${Who} kept today's promise!`;
        const body = note ? `"${note}" Give me props?` :
            workout ? "Give me props?" : `Did ${quoted}. Give me props?`;
        return {title, body};
    }
    if (input.actionType === "skipped") {
        return {
            title: `↩️ ${Who} is skipping today`,
            body: workout ?
                `Skipping today's ${workout.label}.` :
                `Skipping ${quoted} today.`,
        };
    }
    if (input.actionType === "rested") {
        // Not "tomorrow": the next scheduled day may be days away.
        return {title: `🌿 ${Who} is taking a rest day`, body: "Used a rest pass. I'll get it next time!"};
    }
    return null;
}

/** Poke (똑똑) relayed from the partner. `message` must already be sanitized. */
export function pokeCopy(who: string, message: string, lang: Lang = "ko"): PushCopy {
    if (lang === "en") return {title: `✊ Knock knock from ${who}`, body: message};
    return {title: `✊ ${who}의 똑똑`, body: message};
}

/** One-tap reply to a poke ("지금 간다 🏃" / "오늘은 봐줘 🙏"). */
export function pokeReplyCopy(who: string, message: unknown, lang: Lang = "ko"): PushCopy {
    if (lang === "en") {
        return {title: `💬 ${capWho(who)} replied`, body: clip(message, 120) || "Replied to your knock"};
    }
    return {title: `💬 ${who}의 답장`, body: clip(message, 120) || "똑똑에 답장했어"};
}

/**
 * A reaction from the partner. `isVerification` means the executor had already
 * recorded today, so the reaction is a 인정; otherwise it is plain 응원
 * (e.g. sent after a missed-deadline notice).
 */
export function reactionCopy(input: {
    who: string;
    emoji: string;
    message?: unknown;
    isVerification: boolean;
    workout: WorkoutInfo | null;
    lang?: Lang;
}): PushCopy {
    const message = clip(input.message, 120);
    if (input.lang === "en") {
        if (input.isVerification) {
            const subject = input.workout ? input.workout.label : "promise";
            return {
                title: `${input.emoji} Props from ${input.who}!`,
                body: message || `Props on your ${subject}! Nice work 👏`,
            };
        }
        return {
            title: `${input.emoji} ${capWho(input.who)} sent you a cheer!`,
            body: message || "You can do it! I'll be waiting 💪",
        };
    }
    if (input.isVerification) {
        const subject = input.workout ? input.workout.label : "약속";
        return {
            title: `${input.emoji} ${input.who}의 인정 도착!`,
            body: message || `${subject} 인정! 잘했어 👏`,
        };
    }
    return {
        title: `${input.emoji} ${input.who}의 응원 도착!`,
        body: message || "할 수 있어! 기다릴게 💪",
    };
}

export function planApprovedCopy(who: string, lang: Lang = "ko"): PushCopy {
    if (lang === "en") {
        return {title: `✨ ${capWho(who)} approved your promise!`, body: "Here we go. Let's do this together 💪"};
    }
    return {title: `✨ ${who} 약속 승인!`, body: "이제 시작이야. 같이 해 보자 💪"};
}

export function planRejectedCopy(who: string, comment: unknown, lang: Lang = "ko"): PushCopy {
    if (lang === "en") {
        return {
            title: `🤝 ${capWho(who)} wants to adjust the promise`,
            body: clip(comment, 120) || "Let's set the promise again together.",
        };
    }
    return {
        title: `🤝 ${who} 약속 조율 요청`,
        body: clip(comment, 120) || "약속 내용 같이 다시 정해 보자.",
    };
}

export function planChangedCopy(who: string, lang: Lang = "ko"): PushCopy {
    if (lang === "en") return {title: `📝 ${capWho(who)} changed a promise`, body: "Take a look at what changed!"};
    return {title: `📝 ${who} 약속 내용 바꿨어`, body: "바뀐 내용 확인해 줘!"};
}

export function missedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    /** "yesterday": a late-night deadline judged just after midnight. */
    day?: "today" | "yesterday";
    lang?: Lang;
}): PushCopy {
    if (input.lang === "en") return missedCopyEn(input);
    if (input.day === "yesterday") {
        const subject = input.workout ? input.workout.label : "약속";
        return {
            title: `⏰ ${input.who} 어제 ${subject} 기록이 없어요`,
            body: input.workout ?
                "응원 한 번 보내 볼까요?" :
                `${quotedTitle(input.itemTitle)} 기록이 없어요. 응원 한 번 보내 볼까요?`,
        };
    }
    if (input.workout) {
        return {
            title: `⏰ ${input.who} 오늘 ${input.workout.label} 기록이 아직이에요`,
            body: "응원이나 똑똑 한 번 보내 볼까요?",
        };
    }
    return {
        title: `⏰ ${input.who} 오늘 약속 기록이 아직이에요`,
        body: `${quotedTitle(input.itemTitle)} 기록이 아직 없어요. 응원이나 똑똑 한 번 보내 볼까요?`,
    };
}

function missedCopyEn(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    day?: "today" | "yesterday";
}): PushCopy {
    const Who = capWho(input.who);
    const quoted = quotedTitle(input.itemTitle, "en");
    if (input.day === "yesterday") {
        const subject = input.workout ? input.workout.label : "promise";
        return {
            title: `⏰ No record of ${possessive(input.who)} ${subject} yesterday`,
            body: input.workout ?
                "Want to send a cheer?" :
                `${capitalize(quoted)} wasn't logged. Want to send a cheer?`,
        };
    }
    if (input.workout) {
        return {
            title: `⏰ ${Who} hasn't logged today's ${input.workout.label} yet`,
            body: "Want to send a cheer or a knock?",
        };
    }
    return {
        title: `⏰ ${Who} hasn't logged today's promise yet`,
        body: `${quoted} isn't logged yet. Want to send a cheer or a knock?`,
    };
}

export function verifyReminderCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    daysAgo: number | null;
    lang?: Lang;
}): PushCopy {
    if (input.lang === "en") {
        const subject = input.workout ? input.workout.label : quotedTitle(input.itemTitle, "en");
        const when = input.daysAgo === 0 ? `today's ${subject}` :
            input.daysAgo === 1 ? `yesterday's ${subject}` :
                input.daysAgo === 2 ? `the ${subject} from 2 days ago` : `an earlier ${subject}`;
        return {
            title: `👀 ${possessive(capWho(input.who))} record is waiting for props`,
            body: `Take a look at ${when} and give props?`,
        };
    }
    const day = input.daysAgo === 0 ? "오늘" :
        input.daysAgo === 1 ? "어제" :
            input.daysAgo === 2 ? "그저께" : "지난";
    const subject = input.workout ? input.workout.label : quotedTitle(input.itemTitle);
    return {
        title: `👀 ${input.who}의 기록이 인정을 기다려요`,
        body: `${day} ${subject} 기록, 확인하고 인정해 줄래요?`,
    };
}

/**
 * To the code owner once the pair is linked. `partnerName` is the other
 * person's name ("" or a placeholder name gives the nameless title).
 */
export function partnerConnectedCopy(partnerName: string, lang: Lang = "ko"): PushCopy {
    const name = isPlaceholderName(partnerName) ? "" : clip(partnerName, 20);
    if (lang === "en") {
        return {
            title: name ? `🤝 You and ${name} are now partners` : "🤝 Your partner is connected",
            body: "Now you can back each other's promises. If you don't know this person, disconnect in the app.",
        };
    }
    return {
        title: name ? `🤝 ${name}의 짝꿍이 됐어요` : "🤝 짝꿍이 연결됐어요",
        body: "이제 서로의 약속을 봐줄 수 있어요. 모르는 사람이라면 앱에서 연결을 끊어 주세요.",
    };
}

export type ConnectFailReason = "owner_taken" | "self_taken" | "invalid_code";

/** To the person who entered the code when the server undid the link. */
export function partnerConnectFailedCopy(reason: ConnectFailReason, lang: Lang = "ko"): PushCopy {
    if (lang === "en") {
        const title = "Couldn't connect";
        if (reason === "self_taken") {
            return {title, body: "You already have a partner. Disconnect first, then try again."};
        }
        if (reason === "invalid_code") {
            return {title, body: "That code has changed. Ask your partner for a new one."};
        }
        return {title, body: "That code is already connected to someone else. Ask your partner for a new one."};
    }
    if (reason === "self_taken") {
        return {
            title: "연결하지 못했어요",
            body: "이미 연결된 짝꿍이 있어요. 기존 연결을 끊은 뒤 다시 시도해 주세요.",
        };
    }
    if (reason === "invalid_code") {
        return {
            title: "연결하지 못했어요",
            body: "코드가 바뀌었어요. 상대에게 새 코드를 받아 주세요.",
        };
    }
    return {
        title: "연결하지 못했어요",
        body: "이미 다른 짝꿍과 연결된 코드예요. 상대에게 새 코드를 받아 주세요.",
    };
}
