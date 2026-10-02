// Push copy for 둘운완 (ko only for now).
//
// Tone rules (docs/product/PIVOT_DUOUNWAN_SPEC.md §3):
//   - A push that relays something the partner did is written in the
//     partner's casual voice (반말): "{name} 오늘 러닝 끝! 인정해 줄래?".
//   - A push where the app itself informs (missed deadline, reminder,
//     connection status) uses 해요체.
//   - Never "{name}님"; only particle-free joins after a name
//     ("{name}의", "{name} 오늘 …").
//   - No app name in pushes, no surveillance wording.
//   - Workout wording only when the plan carries `workoutType`; legacy plans
//     (no workoutType, e.g. old study plans) get neutral "약속" wording.

export type PushCopy = {title: string; body: string};

export type WorkoutInfo = {
    /** Short label used in sentences, e.g. "러닝". */
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

export const FALLBACK_PARTNER_LABEL = "짝꿍";

/** Legacy phrases old app builds stored inside poke messages. */
const LEGACY_POKE_PHRASES = ["실천 메이트"];

export function workoutInfo(workoutType: unknown): WorkoutInfo | null {
    if (typeof workoutType !== "string" || !workoutType) return null;
    if (workoutType === "diet") {
        return {label: "식단", emoji: "🥗", proofWord: "식단", doneWord: "지켰어!", isWorkout: false};
    }
    const entry = WORKOUTS[workoutType] ?? WORKOUTS.other;
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
 * partner, then the sender's display name, then "짝꿍".
 *
 * `nicknameApplies` is false when the nickname was not set for this sender
 * (an account still linked to more than one partner from before 1:1).
 */
export function partnerLabel(recipient: NamedUser, sender: NamedUser, nicknameApplies = true): string {
    const nickname = nicknameApplies ? clip(recipient?.partnerNickname, 10) : "";
    if (nickname) return nickname;
    const displayName = displayNameOf(sender);
    if (displayName) return displayName;
    return FALLBACK_PARTNER_LABEL;
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

function quotedTitle(itemTitle: string): string {
    return `'${clip(itemTitle, 30) || "약속"}'`;
}

export function defaultPokeMessage(workout: WorkoutInfo | null, hasPlan: boolean): string {
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

export function formatDays(days: unknown): string {
    if (!Array.isArray(days)) return "";
    const unique = Array.from(new Set(days.filter((d) => Number.isInteger(d) && d >= 1 && d <= 7) as number[]))
        .sort((a, b) => a - b);
    if (unique.length === 0) return "";
    if (unique.length === 7) return "매일";
    if (unique.join(",") === "1,2,3,4,5") return "평일";
    if (unique.join(",") === "6,7") return "주말";
    return unique.map((d) => WEEKDAY_LABELS[d - 1]).join("·");
}

export function formatDeadline(notificationTime: unknown): string {
    if (!notificationTime || typeof notificationTime !== "object") return "";
    const time = notificationTime as {type?: unknown; hour?: unknown; minute?: unknown};
    if (time.type === "none") return "";
    if (typeof time.hour !== "number") return "";
    const minute = typeof time.minute === "number" ? time.minute : 0;
    return `${String(time.hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}까지`;
}

export function planCreatedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    days: unknown;
    notificationTime: unknown;
    pendingApproval: boolean;
}): PushCopy {
    const {who, workout} = input;
    let title: string;
    let head: string;
    if (workout) {
        title = workout.isWorkout ?
            `🤙 ${who} 운동 약속 걸었어` :
            `🤙 ${who} ${workout.label} 약속 걸었어`;
        head = `${workout.emoji} ${workout.label}`;
    } else {
        title = `🤙 ${who} 약속 걸었어`;
        head = quotedTitle(input.itemTitle);
    }
    const schedule = [formatDays(input.days), formatDeadline(input.notificationTime)]
        .filter((part) => part).join(" ");
    const summary = [head, schedule].filter((part) => part).join(" · ");
    const ask = input.pendingApproval ? "확인해 줄래?" : "봐줄 거지? 👀";
    return {title, body: `${summary} · ${ask}`};
}

export function actionCompletedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    actionType: unknown;
    withProof: boolean;
    note?: unknown;
}): PushCopy | null {
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

/** Poke (똑똑) relayed from the partner. `message` must already be sanitized. */
export function pokeCopy(who: string, message: string): PushCopy {
    return {title: `✊ ${who}의 똑똑`, body: message};
}

/** One-tap reply to a poke ("지금 간다 🏃" / "오늘은 봐줘 🙏"). */
export function pokeReplyCopy(who: string, message: unknown): PushCopy {
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
}): PushCopy {
    const message = clip(input.message, 120);
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

export function planApprovedCopy(who: string): PushCopy {
    return {title: `✨ ${who} 약속 승인!`, body: "이제 시작이야. 같이 해 보자 💪"};
}

export function planRejectedCopy(who: string, comment: unknown): PushCopy {
    return {
        title: `🤝 ${who} 약속 조율 요청`,
        body: clip(comment, 120) || "약속 내용 같이 다시 정해 보자.",
    };
}

export function planChangedCopy(who: string): PushCopy {
    return {title: `📝 ${who} 약속 내용 바꿨어`, body: "바뀐 내용 확인해 줘!"};
}

export function missedCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    /** "yesterday": a late-night deadline judged just after midnight. */
    day?: "today" | "yesterday";
}): PushCopy {
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

export function verifyReminderCopy(input: {
    who: string;
    workout: WorkoutInfo | null;
    itemTitle: string;
    daysAgo: number | null;
}): PushCopy {
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
export function partnerConnectedCopy(partnerName: string): PushCopy {
    const name = isPlaceholderName(partnerName) ? "" : clip(partnerName, 20);
    return {
        title: name ? `🤝 ${name}의 짝꿍이 됐어요` : "🤝 짝꿍이 연결됐어요",
        body: "이제 서로의 약속을 봐줄 수 있어요. 모르는 사람이라면 앱에서 연결을 끊어 주세요.",
    };
}

export type ConnectFailReason = "owner_taken" | "self_taken" | "invalid_code";

/** To the person who entered the code when the server undid the link. */
export function partnerConnectFailedCopy(reason: ConnectFailReason): PushCopy {
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
