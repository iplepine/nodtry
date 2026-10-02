// Pure plan-schedule checks used by the scheduled notifiers.
import {DateLike, LocalDateParts, isSameLocalDay} from "./time";

export const MISSED_ACTION_GRACE_MINUTES = 30;
const MINUTES_PER_DAY = 24 * 60;
/**
 * The missed-notice job runs every 30 minutes, so the last run of a local day
 * is at 23:30 (23:45 in zones with a :15/:45 offset). An item whose deadline
 * plus grace falls after 23:30 — or past midnight — can't be judged on its
 * own day and is judged on the next day's first runs instead.
 */
export const LATE_DUE_AFTER_MINUTES = 23 * 60 + 30;
/** How long after local midnight such late items are still relayed. */
export const LATE_LOOKBACK_MINUTES = 120;

export type PlanItemData = {
    title?: string;
    days?: number[];
    notificationTime?: {
        type?: string;
        hour?: number;
        minute?: number;
    };
};

type PlanLike = {[key: string]: unknown};

function dueMinutesOf(item: PlanItemData): number {
    const hour = item.notificationTime?.hour ?? 23;
    const minute = item.notificationTime?.minute ?? 59;
    return hour * 60 + minute + MISSED_ACTION_GRACE_MINUTES;
}

function deadlineMinutesOf(item: PlanItemData): number {
    return (item.notificationTime?.hour ?? 23) * 60 + (item.notificationTime?.minute ?? 59);
}

function timedItemsOn(plan: PlanLike, weekday: number): PlanItemData[] {
    const items = (Array.isArray(plan.items) ? plan.items : []) as PlanItemData[];
    return items.filter((item) => {
        const notificationTime = item.notificationTime;
        if (!Array.isArray(item.days) || !item.days.includes(weekday)) return false;
        return Boolean(notificationTime) && notificationTime?.type !== "none";
    });
}

/** Whether any item has a deadline at all (cheap pre-filter, no time zone needed). */
export function hasTimedItem(plan: PlanLike): boolean {
    const items = (Array.isArray(plan.items) ? plan.items : []) as PlanItemData[];
    return items.some((item) => Array.isArray(item.days) && item.days.length > 0 &&
        Boolean(item.notificationTime) && item.notificationTime?.type !== "none");
}

function latestFirst(items: PlanItemData[]): PlanItemData | null {
    const sorted = [...items].sort((a, b) => deadlineMinutesOf(b) - deadlineMinutesOf(a));
    return sorted[0] ?? null;
}

export function hasDateOn(values: unknown, today: LocalDateParts, timeZone: string): boolean {
    if (!Array.isArray(values)) return false;
    return values.some((value) => isSameLocalDay(value as DateLike, today, timeZone));
}

/** Whether the executor already recorded anything for `today`. */
export function hasCoveredToday(plan: PlanLike, today: LocalDateParts, timeZone: string): boolean {
    const fields = ["completedDates", "skippedDates", "restedDates", "rescuedDates"];
    return fields.some((field) => hasDateOn(plan[field], today, timeZone));
}

/**
 * The latest item scheduled for `today` whose deadline (+ grace) has passed,
 * evaluated in the executor's local time. Items without a time
 * (`notificationTime.type === "none"`) are never relayed.
 */
export function dueItemForMissedNotice(plan: PlanLike, today: LocalDateParts): PlanItemData | null {
    return latestFirst(timedItemsOn(plan, today.weekday)
        .filter((item) => today.minutes >= dueMinutesOf(item)));
}

/**
 * A late item of `yesterday` (deadline + grace after 23:30, e.g. "23:59, 오늘
 * 안에") that is due by now, evaluated during the first
 * {@link LATE_LOOKBACK_MINUTES} after the executor's local midnight. Earlier
 * items were already judged on their own day.
 */
export function lateItemFromYesterday(
    plan: PlanLike,
    yesterday: LocalDateParts,
    today: LocalDateParts,
): PlanItemData | null {
    if (today.minutes >= LATE_LOOKBACK_MINUTES) return null;
    return latestFirst(timedItemsOn(plan, yesterday.weekday).filter((item) => {
        const due = dueMinutesOf(item);
        return due > LATE_DUE_AFTER_MINUTES && today.minutes + MINUTES_PER_DAY >= due;
    }));
}
