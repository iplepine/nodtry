// Time-zone aware date helpers.
//
// Deadlines and "today" are evaluated in the executor's own IANA time zone
// (`users/{uid}.timezone`, written by clients from build 81). Older clients
// never wrote it, so everything falls back to Asia/Seoul — the behaviour the
// app had before the pivot.

export const DEFAULT_TIME_ZONE = "Asia/Seoul";

export type LocalDateParts = {
    year: number;
    month: number;
    day: number;
    /** ISO weekday: Monday = 1 ... Sunday = 7 (matches plan item `days`). */
    weekday: number;
    /** Minutes since local midnight. */
    minutes: number;
};

/** Anything with a `toDate()` (Firestore Timestamp) or a plain Date. */
export type DateLike = {toDate(): Date} | Date | null | undefined;

const WEEKDAYS: {[key: string]: number} = {
    Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7,
};

const formatterCache = new Map<string, Intl.DateTimeFormat>();

function formatterFor(timeZone: string): Intl.DateTimeFormat {
    let formatter = formatterCache.get(timeZone);
    if (!formatter) {
        formatter = new Intl.DateTimeFormat("en-US", {
            timeZone,
            year: "numeric",
            month: "numeric",
            day: "numeric",
            weekday: "short",
            hour: "numeric",
            minute: "numeric",
            hourCycle: "h23",
        });
        formatterCache.set(timeZone, formatter);
    }
    return formatter;
}

/**
 * Returns a valid IANA zone for `value`, or Asia/Seoul when it is missing or
 * not recognised by the runtime's ICU data.
 */
export function resolveTimeZone(value: unknown): string {
    if (typeof value !== "string") return DEFAULT_TIME_ZONE;
    const trimmed = value.trim();
    if (!trimmed || trimmed.length > 64) return DEFAULT_TIME_ZONE;
    try {
        formatterFor(trimmed);
        return trimmed;
    } catch {
        return DEFAULT_TIME_ZONE;
    }
}

export function toDate(value: DateLike): Date | null {
    if (!value) return null;
    if (value instanceof Date) return value;
    if (typeof (value as {toDate?: unknown}).toDate === "function") {
        return (value as {toDate(): Date}).toDate();
    }
    return null;
}

export function localParts(date: Date, timeZone: string): LocalDateParts {
    const parts = formatterFor(resolveTimeZone(timeZone)).formatToParts(date);
    const get = (type: string): string => parts.find((p) => p.type === type)?.value ?? "";
    const hour = Number(get("hour")) % 24;
    return {
        year: Number(get("year")),
        month: Number(get("month")),
        day: Number(get("day")),
        weekday: WEEKDAYS[get("weekday")] ?? 1,
        minutes: hour * 60 + Number(get("minute")),
    };
}

function compareDay(a: LocalDateParts, b: LocalDateParts): number {
    if (a.year !== b.year) return a.year - b.year;
    if (a.month !== b.month) return a.month - b.month;
    return a.day - b.day;
}

export function isSameLocalDay(value: DateLike, target: LocalDateParts, timeZone: string): boolean {
    const date = toDate(value);
    if (!date) return false;
    return compareDay(localParts(date, timeZone), target) === 0;
}

export function isBeforeLocalDay(value: DateLike, target: LocalDateParts, timeZone: string): boolean {
    const date = toDate(value);
    if (!date) return false;
    return compareDay(localParts(date, timeZone), target) < 0;
}

export function isAfterLocalDay(value: DateLike, target: LocalDateParts, timeZone: string): boolean {
    const date = toDate(value);
    if (!date) return false;
    return compareDay(localParts(date, timeZone), target) > 0;
}

/**
 * The local day before `today`: its parts, and an instant on it (about 22:30
 * there — the 90-minute margin keeps it on that day across a DST shift).
 */
export function previousLocalDay(
    now: Date,
    today: LocalDateParts,
    timeZone: string,
): {at: Date; parts: LocalDateParts} {
    const at = new Date(now.getTime() - (today.minutes + 90) * 60 * 1000);
    return {at, parts: localParts(at, timeZone)};
}

/** `YYYY-MM-DD` for the local day, used in dedupe keys. */
export function dayKey(parts: LocalDateParts): string {
    const mm = String(parts.month).padStart(2, "0");
    const dd = String(parts.day).padStart(2, "0");
    return `${parts.year}-${mm}-${dd}`;
}

/**
 * Whole local days between `value` and `today` (0 = today, 1 = yesterday).
 * Negative when `value` lies in the future.
 */
export function localDaysAgo(value: DateLike, today: LocalDateParts, timeZone: string): number | null {
    const date = toDate(value);
    if (!date) return null;
    const p = localParts(date, timeZone);
    const a = Date.UTC(p.year, p.month - 1, p.day);
    const b = Date.UTC(today.year, today.month - 1, today.day);
    return Math.round((b - a) / (24 * 60 * 60 * 1000));
}
