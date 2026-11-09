// "같이 했어": when the couple worked out together, one log (and at most one
// proof photo) covers both. Kept free of Firestore so it can be unit-tested;
// index.ts `onActionCompleted` applies it.
//
// Data contract (all optional, additive — spec §9):
//   - actions/{id} (the logger's own `done`): `togetherWithUid` (the partner)
//     + `togetherPartnerPlanId` (the partner's plan the log is for).
//   - plans/{id} (the logger's plan): `lastTogether` {actionId, withUid,
//     planId, at} so the partner's app can show "{name}가 같이 했대요".
//   - actions/{id} (the partner's own `done`, written only when *they* tap
//     나도 했어): `sharedProofFromUid` (the logger) + `togetherActionId` (the
//     logger's action) and, when the logger attached one, `proofPhotoPath`
//     pointing at the logger's photo with the original `proofSource`.
//
// The partner gets ONE push, `together_log`, instead of the usual
// `action_completed`. Builds that can't confirm (< TOGETHER_BUILD) keep
// getting `action_completed`; a `together_log` that reaches an old build
// anyway opens nothing (unknown types are ignored there).

/** First app build that shows the "같이 했대요" card and the 나도 했어 button. */
export const TOGETHER_BUILD = 88;

type Data = {[key: string]: unknown};

export type TogetherClaim = {
    /** The partner the logger says they worked out with. */
    partnerId: string;
    /** The partner's plan the log is for. */
    partnerPlanId: string;
};

function str(value: unknown): string | null {
    return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * The "같이 했어" claim of a new action, or null: only a `done` record of
 * `ownerId` that names someone else and one of their plans.
 */
export function togetherClaimOf(action: Data | null | undefined, ownerId: string | null): TogetherClaim | null {
    if (!action || action.type !== "done" || !ownerId) return null;
    const partnerId = str(action.togetherWithUid);
    const partnerPlanId = str(action.togetherPartnerPlanId);
    if (!partnerId || !partnerPlanId || partnerId === ownerId) return null;
    // A confirmation (나도 했어) never asks back.
    if (isTogetherConfirmation(action)) return null;
    return {partnerId, partnerPlanId};
}

/** Whether the partner's plan can take the claim: theirs and running. */
export function togetherPlanAccepts(plan: Data | null | undefined, partnerId: string): boolean {
    if (!plan) return false;
    return str(plan.userId) === partnerId && plan.state === "active";
}

/**
 * Whether an action is the partner's 나도 했어 (it carries the logger's
 * `sharedProofFromUid` / `togetherActionId`).
 */
export function isTogetherConfirmation(action: Data | null | undefined): boolean {
    if (!action) return false;
    return str(action.sharedProofFromUid) !== null || str(action.togetherActionId) !== null;
}

/**
 * serverLocks key of the one `together_log` push per partner plan per
 * partner-local day (`day` = time.dayKey). A second claim the same day goes
 * out as a plain `action_completed`.
 */
export function togetherLockKey(partnerPlanId: string, day: string): string {
    return `together_${partnerPlanId}_${day}`;
}
