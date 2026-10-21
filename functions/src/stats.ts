// Daily operations stats. Pure helpers live here so they can be unit-tested
// without Firestore; the scheduled job in index.ts does the reads.

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

export type DayWindow = {
    /** `YYYY-MM-DD` of the Asia/Seoul day this window covers. */
    key: string;
    /** Inclusive start, exclusive end (UTC instants). */
    start: Date;
    end: Date;
};

/** The Asia/Seoul calendar day that contains `instant`, as a UTC window. */
export function seoulDayWindow(instant: Date): DayWindow {
    const seoulMs = instant.getTime() + KST_OFFSET_MS;
    const startSeoulMs = Math.floor(seoulMs / DAY_MS) * DAY_MS;
    const start = new Date(startSeoulMs - KST_OFFSET_MS);
    return {
        key: new Date(startSeoulMs).toISOString().slice(0, 10),
        start,
        end: new Date(start.getTime() + DAY_MS),
    };
}

/** The Seoul day before the one containing `now` (what the nightly job reports). */
export function previousSeoulDay(now: Date): DayWindow {
    return seoulDayWindow(new Date(seoulDayWindow(now).start.getTime() - 1));
}

/** Relations are written in pairs (one doc per person), so halve and round up. */
export function pairsOf(relationDocs: number): number {
    return Math.ceil(relationDocs / 2);
}
