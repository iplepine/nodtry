// 주 N회 자유 요일: a workout promise kept N times a week on any days
// (`plans.weeklyTarget`, an int 1-6; missing = the classic fixed weekdays).
//
// Mirror of lib/models/weekly_target.dart — both run the vectors in
// test/fixtures/weekly_target_vectors.json, so keep them in step.
//
// - A week is Monday-Sunday in the owner's time zone (users/{uid}.timezone).
//   Only its days inside the plan period count; a partial week asks for a
//   prorated target.
// - A day credits the week with a done record, a rescue or a rest pass.
// - An unlogged day is neutral while the week can still be completed. A day
//   is must-do when the days left in the week (that day included) are no more
//   than the credits still needed; the missed-notice job relays a weekly plan
//   only on such a day. Must-do is decided from the credits before the day.
import {DateLike, LocalDateParts, localParts, toDate} from "./time";

export const WEEKLY_TARGET_MIN = 1;
export const WEEKLY_TARGET_MAX = 6;

const DAY_MS = 24 * 60 * 60 * 1000;

type PlanLike = {[key: string]: unknown};

/** The plan's weekly target, or null for a fixed-weekday (or malformed) one. */
export function weeklyTargetOf(plan: PlanLike | null | undefined): number | null {
    const value = plan?.weeklyTarget;
    if (typeof value !== "number" || !Number.isInteger(value)) return null;
    if (value < WEEKLY_TARGET_MIN || value > WEEKLY_TARGET_MAX) return null;
    return value;
}

/** Target of a week with only `availableDays` inside the period (rounded up). */
export function weeklyTargetForAvailableDays(target: number, availableDays: number): number {
    if (availableDays <= 0 || target <= 0) return 0;
    if (availableDays >= 7) return target;
    const prorated = Math.ceil((target * availableDays) / 7);
    return Math.min(prorated, target, availableDays);
}

/** `needed` credits still missing and only `remaining` days (this one included) left. */
export function weeklyIsMustDo(needed: number, remaining: number): boolean {
    return needed > 0 && remaining <= needed;
}

export type WeeklyWeek = {
    target: number;
    credited: number;
    creditedDays: boolean[];
    mustDo: boolean[];
};

/** One week from per-weekday flags (index 0 = Monday). */
export function evaluateWeeklyWeek(weeklyTarget: number, inPeriod: boolean[], credited: boolean[]): WeeklyWeek {
    const available = inPeriod.filter((d) => d).length;
    const target = weeklyTargetForAvailableDays(weeklyTarget, available);
    const creditedDays = inPeriod.map((d, i) => d && Boolean(credited[i]));
    const mustDo = new Array<boolean>(7).fill(false);
    let before = 0;
    let remaining = available;
    for (let i = 0; i < 7; i++) {
        if (!inPeriod[i]) continue;
        mustDo[i] = weeklyIsMustDo(target - before, remaining);
        if (creditedDays[i]) before++;
        remaining--;
    }
    return {target, credited: before, creditedDays, mustDo};
}

function keyOfParts(parts: {year: number; month: number; day: number}): number {
    return parts.year * 10000 + parts.month * 100 + parts.day;
}

function keyOf(value: DateLike, timeZone: string): number | null {
    const date = toDate(value);
    return date ? keyOfParts(localParts(date, timeZone)) : null;
}

function keysOf(values: unknown, timeZone: string): Set<number> {
    const keys = new Set<number>();
    if (!Array.isArray(values)) return keys;
    for (const value of values) {
        const key = keyOf(value as DateLike, timeZone);
        if (key !== null) keys.add(key);
    }
    return keys;
}

/**
 * The week containing the local day `day` for a weekly `plan`, in the
 * owner's `timeZone`, or null for a fixed-weekday plan.
 */
export function weeklyWeekOf(plan: PlanLike, day: LocalDateParts, timeZone: string): WeeklyWeek | null {
    const target = weeklyTargetOf(plan);
    if (target === null) return null;
    const startKey = keyOf(plan.startDate as DateLike, timeZone);
    const endKey = keyOf(plan.endDate as DateLike, timeZone);
    const credits = new Set<number>([
        ...keysOf(plan.completedDates, timeZone),
        ...keysOf(plan.restedDates, timeZone),
        ...keysOf(plan.rescuedDates, timeZone),
    ]);
    // Calendar arithmetic on the local date, done in UTC so no zone applies.
    const monday = Date.UTC(day.year, day.month - 1, day.day) - (day.weekday - 1) * DAY_MS;
    const inPeriod: boolean[] = [];
    const credited: boolean[] = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(monday + i * DAY_MS);
        const key = keyOfParts({year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate()});
        inPeriod.push((startKey === null || key >= startKey) && (endKey === null || key <= endKey));
        credited.push(credits.has(key));
    }
    return evaluateWeeklyWeek(target, inPeriod, credited);
}

/**
 * Whether the missed-notice job may relay `plan` for the local day `day`:
 * always for a fixed-weekday plan (its own weekday rules apply), and for a
 * weekly plan only on a must-do day.
 */
export function weeklyAllowsMissedNotice(plan: PlanLike, day: LocalDateParts, timeZone: string): boolean {
    const week = weeklyWeekOf(plan, day, timeZone);
    if (week === null) return true;
    return week.mustDo[day.weekday - 1];
}

function partsOfUtcDay(ms: number): LocalDateParts {
    const d = new Date(ms);
    const weekday = d.getUTCDay() === 0 ? 7 : d.getUTCDay();
    return {year: d.getUTCFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), weekday, minutes: 0};
}

/**
 * A weekly plan's 내기 tally up to the local day `cutoff` (inclusive), in the
 * owner's zone: distinct done days, and missed must-do days (each week's
 * shortfall). Mirrors `Plan.completedDayCount` / `Plan.failedDayCount` in the
 * app. Null for a fixed-weekday plan or one without a period.
 */
export function weeklySettlementTally(
    plan: PlanLike,
    cutoff: LocalDateParts,
    timeZone: string,
): {successDays: number; failDays: number} | null {
    if (weeklyTargetOf(plan) === null) return null;
    const start = toDate(plan.startDate as DateLike);
    const end = toDate(plan.endDate as DateLike);
    if (!start || !end) return null;
    const s = localParts(start, timeZone);
    const e = localParts(end, timeZone);
    const startMs = Date.UTC(s.year, s.month - 1, s.day);
    const lastMs = Math.min(Date.UTC(e.year, e.month - 1, e.day), Date.UTC(cutoff.year, cutoff.month - 1, cutoff.day));
    const done = keysOf(plan.completedDates, timeZone);
    let successDays = 0;
    let failDays = 0;
    let week: WeeklyWeek | null = null;
    for (let ms = startMs; ms <= lastMs; ms += DAY_MS) {
        const day = partsOfUtcDay(ms);
        if (week === null || day.weekday === 1) week = weeklyWeekOf(plan, day, timeZone);
        if (done.has(keyOfParts(day))) successDays++;
        const i = day.weekday - 1;
        if (week && week.mustDo[i] && !week.creditedDays[i]) failDays++;
    }
    return {successDays, failDays};
}

type PromiseLike = {
    status?: unknown;
    settledAt?: unknown;
    settledSuccessDays?: unknown;
    settledFailDays?: unknown;
    settlementResult?: unknown;
    reward?: {targetDays?: unknown} | null;
    penalty?: {targetDays?: unknown} | null;
};

function targetDaysOf(value: {targetDays?: unknown} | null | undefined): number | null {
    if (!value || typeof value !== "object") return null;
    const n = Number(value.targetDays);
    return Number.isFinite(n) ? n : 1;
}

/** `promise.settlementResult` for a tally (same rule as the app's settlePromise). */
export function settlementResultOf(promise: PromiseLike, successDays: number, failDays: number): string {
    const reward = targetDaysOf(promise.reward);
    const penalty = targetDaysOf(promise.penalty);
    const rewardMet = reward !== null && successDays >= reward;
    const penaltyMet = penalty !== null && failDays >= penalty;
    if (rewardMet && penaltyMet) return "both_met";
    if (rewardMet) return "reward_achieved";
    if (penaltyMet) return "penalty_triggered";
    return "neither_met";
}

/**
 * The fix for a 주 N회 plan's 내기 that was just settled (status turned
 * `settled`) with the wrong tally — an app build without `weeklyTarget`
 * (≤ 1.1.2+87) counts every unlogged day of its seven listed weekdays as a
 * miss. Returns the `promise.*` field values to write, or null when the plan
 * is not weekly, nothing was just settled, or the stored tally is right.
 */
export function weeklySettlementCorrection(
    before: PlanLike,
    after: PlanLike,
    timeZone: string,
    now: Date,
): {[field: string]: number | string} | null {
    const promise = after.promise as PromiseLike | undefined;
    const previous = before.promise as PromiseLike | undefined;
    if (!promise || promise.status !== "settled" || previous?.status === "settled") return null;
    const end = toDate(after.endDate as DateLike);
    const settledAt = toDate(promise.settledAt as DateLike) ?? now;
    const cutoffAt = end && end.getTime() < settledAt.getTime() ? end : settledAt;
    const tally = weeklySettlementTally(after, localParts(cutoffAt, timeZone), timeZone);
    if (!tally) return null;
    const result = settlementResultOf(promise, tally.successDays, tally.failDays);
    if (promise.settledSuccessDays === tally.successDays && promise.settledFailDays === tally.failDays &&
        promise.settlementResult === result) return null;
    return {
        "promise.settledSuccessDays": tally.successDays,
        "promise.settledFailDays": tally.failDays,
        "promise.settlementResult": result,
    };
}
