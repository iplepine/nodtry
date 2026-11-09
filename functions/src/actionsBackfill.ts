// plans 기록 배열 → actions 정규화 (docs/work/REMAINING_IMPROVEMENTS.md §3).
//
// Pure planning for scripts/migrations/backfill_plan_actions.js (which loads
// the compiled lib/actionsBackfill.js) and the guard the triggers use:
//   - planActionBackfill: the `actions` documents a plan's record arrays
//     still lack — one per (type, owner-local day) with a deterministic id,
//     so a re-run (or two runs at once) never duplicates a record;
//   - compareRecordDays: the verify mode, array days vs action days per type;
//   - isBackfilledAction: such a document, which no trigger relays (the
//     record happened long ago and was pushed back then, if ever).
//
// The arrays stay the written source for builds ≤ 1.1.2+87 and the functions;
// nothing here changes or removes them.

import {DateLike, dayKey, localParts, toDate} from "./time";

/** The `actions.type` of each record array (never changed, spec §9). */
export const RECORD_ARRAYS = {
    done: "completedDates",
    skipped: "skippedDates",
    rested: "restedDates",
    rescued: "rescuedDates",
} as const;

export type RecordType = keyof typeof RECORD_ARRAYS;

export const RECORD_TYPES = Object.keys(RECORD_ARRAYS) as RecordType[];

/** `actions.backfilled`: written by the backfill, never by an app. */
export const BACKFILLED_FIELD = "backfilled";

type Data = {[key: string]: unknown};

/** The fields of an `actions` document this module reads. */
export type ActionLike = {
    userId?: unknown;
    planId?: unknown;
    type?: unknown;
    date?: unknown;
    verifiedBy?: unknown;
};

export type PlannedAction = {
    /** Deterministic `actions` doc id ([backfillActionId]). */
    id: string;
    type: RecordType;
    /** Owner-local `YYYY-MM-DD`. */
    day: string;
    /** The array's (first) moment of that day: the record's `date`. */
    date: Date;
};

export type PlanBackfill = {
    planId: string;
    /** The plan owner, or null when the plan has none (nothing is planned). */
    userId: string | null;
    creates: PlannedAction[];
    /** Array days that already have an action of their type, per type. */
    covered: {[type in RecordType]: number};
};

export function isBackfilledAction(action: Data | null | undefined): boolean {
    return action?.[BACKFILLED_FIELD] === true;
}

/** `backfill_{planId}_{type}_{YYYYMMDD}`. */
export function backfillActionId(planId: string, type: RecordType, day: string): string {
    return `backfill_${planId}_${type}_${day.replace(/-/g, "")}`;
}

function asId(value: unknown): string | null {
    return typeof value === "string" && value.length > 0 ? value : null;
}

function dateOf(value: unknown): Date | null {
    const date = toDate(value as DateLike);
    return date && Number.isFinite(date.getTime()) ? date : null;
}

function dayOf(value: unknown, timeZone: string): string | null {
    const date = dateOf(value);
    return date ? dayKey(localParts(date, timeZone)) : null;
}

/** Each local day of the array `field` of `plan` once, with its first moment, oldest first. */
function arrayDays(plan: Data, field: string, timeZone: string): Map<string, Date> {
    const days = new Map<string, Date>();
    const values = Array.isArray(plan[field]) ? plan[field] as unknown[] : [];
    for (const value of values) {
        const date = dateOf(value);
        if (!date) continue;
        const day = dayKey(localParts(date, timeZone));
        const known = days.get(day);
        if (!known || date < known) days.set(day, date);
    }
    return new Map([...days.entries()].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)));
}

/** The plan owner's own actions of `planId` (a partner's "같이 했어" names the plan but isn't on it). */
function ownActions(planId: string, userId: string, actions: ActionLike[]): ActionLike[] {
    return actions.filter((a) => a.planId === planId && a.userId === userId);
}

function actionDays(actions: ActionLike[], test: (a: ActionLike) => boolean, timeZone: string): Set<string> {
    const days = new Set<string>();
    for (const action of actions) {
        if (!test(action)) continue;
        const day = dayOf(action.date, timeZone);
        if (day) days.add(day);
    }
    return days;
}

/**
 * The actions `plan` (id `planId`) needs so that every day of its record
 * arrays has one: for each type, each owner-local day (in `timeZone`, the
 * owner's) of the array with no action of that type by the owner on that
 * plan. `actions` are the plan's existing actions (any owner; others are
 * ignored). Idempotent: a day with an action — the backfill's own included —
 * is never planned again.
 */
export function planActionBackfill(
    planId: string,
    plan: Data,
    actions: ActionLike[],
    timeZone: string,
): PlanBackfill {
    const covered = {done: 0, skipped: 0, rested: 0, rescued: 0};
    const userId = asId(plan.userId);
    if (!userId) return {planId, userId: null, creates: [], covered};
    const own = ownActions(planId, userId, actions);
    const creates: PlannedAction[] = [];
    for (const type of RECORD_TYPES) {
        const have = actionDays(own, (a) => a.type === type, timeZone);
        for (const [day, date] of arrayDays(plan, RECORD_ARRAYS[type], timeZone)) {
            if (have.has(day)) {
                covered[type]++;
                continue;
            }
            creates.push({id: backfillActionId(planId, type, day), type, day, date});
        }
    }
    return {planId, userId, creates, covered};
}

/** The plan's first item title (denormalized onto every action), or "". */
export function planTitleOf(plan: Data): string {
    const items = Array.isArray(plan.items) ? plan.items as Data[] : [];
    const title = items[0]?.title;
    return typeof title === "string" ? title : "";
}

/**
 * The document of a planned action. Times are Dates; the script converts
 * them. `createdAt` is the record's own moment, not the run's: the
 * scheduled jobs that look at recent `createdAt` (verify reminders, daily
 * stats) must not count a months-old record as new. No `managerId`: the
 * onCreate trigger stamps it from the plan, as for every action.
 */
export function backfillActionData(planId: string, plan: Data, planned: PlannedAction): Data {
    return {
        userId: plan.userId,
        planId,
        type: planned.type,
        date: planned.date,
        title: planTitleOf(plan),
        createdAt: planned.date,
        [BACKFILLED_FIELD]: true,
    };
}

export type DayComparison = {
    /** A record type, or `verified` (`verifiedDates` vs `actions.verifiedBy`). */
    kind: RecordType | "verified";
    arrays: number;
    actions: number;
    onlyInArrays: string[];
    onlyInActions: string[];
};

function compareSets(kind: DayComparison["kind"], arrays: Set<string>, actions: Set<string>): DayComparison {
    const sorted = (values: string[]) => values.sort();
    return {
        kind,
        arrays: arrays.size,
        actions: actions.size,
        onlyInArrays: sorted([...arrays].filter((day) => !actions.has(day))),
        onlyInActions: sorted([...actions].filter((day) => !arrays.has(day))),
    };
}

/**
 * Array-derived vs actions-derived record days of a plan, per type and for
 * 인정 (`verifiedDates` vs records with `verifiedBy`), in the owner's
 * `timeZone`. The app shows the union of the two; builds ≤ 1.1.2+87 and the
 * functions show only the arrays.
 */
export function compareRecordDays(
    planId: string,
    plan: Data,
    actions: ActionLike[],
    timeZone: string,
): DayComparison[] {
    const userId = asId(plan.userId);
    const own = userId ? ownActions(planId, userId, actions) : [];
    const days = (field: string) => new Set(arrayDays(plan, field, timeZone).keys());
    const result = RECORD_TYPES.map((type) =>
        compareSets(type, days(RECORD_ARRAYS[type]), actionDays(own, (a) => a.type === type, timeZone)));
    result.push(compareSets("verified", days("verifiedDates"),
        actionDays(own, (a) => asId(a.verifiedBy) !== null, timeZone)));
    return result;
}

export function hasMismatch(comparison: DayComparison[]): boolean {
    return comparison.some((c) => c.onlyInArrays.length > 0 || c.onlyInActions.length > 0);
}
