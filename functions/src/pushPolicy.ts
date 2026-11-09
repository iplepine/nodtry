// Per-recipient daily push cap: which pushes count as core, and whether one
// may still go out today. Kept free of Firestore so it can be unit-tested;
// index.ts `sendCopy` applies it in a transaction on pushQuota/{uid}_{day}.
//
// Policy (docs/operations/PUSH_POLICY.md):
//   - core      — the 둘운완 core loop (spec §4) and safety pushes. Always
//                 sent, never dropped by the cap (they still count).
//   - standard  — partner-initiated but not loop-critical. Sent while the
//                 recipient got fewer than DAILY_PUSH_CAP pushes today.
//   - secondary — extra encouragement and automatic nudges. Sent while the
//                 recipient got fewer than SECONDARY_PUSH_LIMIT pushes today.
//
// Why 8 / 5: a normal duo day is 2–5 pushes per person (partner's proof,
// 인정 of mine, maybe a missed notice, a knock and its reply). Secondary
// pushes stop at 5 so at least 3 of the 8 stay free for the pushes that keep
// the loop going; standard ones stop at 8; core ones are never held back,
// because missing a 인정 or a "partner missed" notice breaks the product,
// and each core type already has its own source limit (1 missed notice per
// plan per day, 1 knock per plan per day, 5 connect pushes per day, one push
// per recorded action).
import {LocalDateParts, localParts} from "./time";

export type PushTier = "core" | "standard" | "secondary";

/** Pushes per recipient-local day after which standard pushes are dropped. */
export const DAILY_PUSH_CAP = 8;
/** Pushes per recipient-local day after which secondary pushes are dropped. */
export const SECONDARY_PUSH_LIMIT = 5;
/** pushQuota docs carry `expireAt` this long after they were written (TTL). */
export const PUSH_QUOTA_TTL_MS = 3 * 24 * 60 * 60 * 1000;
/** plan_updated pushes of the same plan to the same person within this window are coalesced. */
export const PLAN_UPDATED_COALESCE_MS = 15 * 60 * 1000;

export const PUSH_QUOTA_COLLECTION = "pushQuota";

export type TierHints = {
    /** A cheer that lands on a day the recipient already recorded: a 인정. */
    verification?: boolean;
};

/**
 * The tier of a push from its `data` (the `type` values are a contract with
 * the app and are never changed here). Unknown types are secondary.
 */
export function pushTier(data: {[key: string]: string}, hints: TierHints = {}): PushTier {
    switch (data.type) {
    // Invite / connection: a link the owner never agreed to must never be
    // silent; a failed link must be explained.
    case "partner_connected":
    case "partner_connect_failed":
        return "core";
    // The partner's proof (the thing to 인정) is core; a skip or rest day is
    // information only.
    case "action_completed":
        return data.actionType === "done" ? "core" : "standard";
    // 인정 of my proof.
    case "action_verified":
        return "core";
    case "cheer":
        return hints.verification ? "core" : "secondary";
    // The answer to my own knock.
    case "poke_reply":
        return "core";
    // "Partner missed" — the "안 하면 짝꿍이 안다" step.
    case "action_missed":
        return "core";
    // A new promise to back, and the legacy approval answers.
    case "plan_proposed":
    case "plan_approved":
    case "plan_rejected":
        return "core";
    // A knock is already limited to one per plan per day at its source.
    case "poke":
    case "plan_updated":
        return "standard";
    // Automatic, repeated nudge; it is held and retried later when dropped.
    case "verify_reminder":
        return "secondary";
    default:
        return "secondary";
    }
}

export type QuotaDecision = {send: boolean; reason: "core" | "under_cap" | "daily_cap"};

/** Whether a push of `tier` may go out after `sentToday` pushes to the same recipient today. */
export function quotaDecision(tier: PushTier, sentToday: number): QuotaDecision {
    const count = Number.isFinite(sentToday) && sentToday > 0 ? sentToday : 0;
    if (tier === "core") return {send: true, reason: "core"};
    const limit = tier === "standard" ? DAILY_PUSH_CAP : SECONDARY_PUSH_LIMIT;
    return count < limit ? {send: true, reason: "under_cap"} : {send: false, reason: "daily_cap"};
}

/** "YYYYMMDD" of a local day. */
export function compactDayKey(parts: LocalDateParts): string {
    return `${parts.year}${String(parts.month).padStart(2, "0")}${String(parts.day).padStart(2, "0")}`;
}

/** pushQuota doc id for `uid` on the recipient-local day of `now` in `timeZone`. */
export function quotaDocId(uid: string, now: Date, timeZone: string): string {
    const safeUid = uid.replace(/[^A-Za-z0-9_-]/g, "_");
    return `${safeUid}_${compactDayKey(localParts(now, timeZone))}`;
}

/**
 * A serverLocks key that coalesces duplicate pushes, or null when the push is
 * never coalesced. Only plan_updated: saving several edits in a row would
 * otherwise send one "changed a promise" push per save.
 */
export function coalesceKey(recipientUid: string, data: {[key: string]: string}, nowMs: number): string | null {
    if (data.type === "plan_updated" && data.planId) {
        const bucket = Math.floor(nowMs / PLAN_UPDATED_COALESCE_MS);
        return `coalesce_plan_updated_${data.planId}_${recipientUid}_${bucket}`;
    }
    return null;
}
