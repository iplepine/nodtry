// Pure helpers for a plan's link to its manager (the partner who watches it).
// Used by the Cloud Functions and, compiled (lib/planLinks.js), by
// scripts/migrations/clear_stale_manager_ids.js and
// backfill_action_manager_ids.js so they all write the same thing.

export const SYSTEM_LINK = "system_link";
export const SYSTEM_UNLINK = "system_unlink";

/**
 * `managerSinceUid` after an unlink. It matches no uid, so a manager assigned
 * afterwards reads none of the plan's proofs until the server stamps them
 * (storage.rules), and `managerSince` keeps the unlink time as the floor.
 */
export const UNLINKED_MARK = "";

/**
 * How far before the assignment a newly assigned manager may read proofs.
 * 0 = strict: a partner only sees photos taken after they were linked, so a
 * harvested or mistaken link never exposes earlier photos (D-007 privacy-first).
 * Never reaches back past an unlink either way.
 */
export const NEW_MANAGER_LOOKBACK_MS = 0;

/** Fields on the owner's plan that carry what the partner wrote or sent. */
export const PARTNER_CONTENT_FIELDS = [
    "lastCheerMessage",
    "lastCheerType",
    "lastCheerAt",
    "lastComment",
    "lastPokeMessage",
    "lastPokeAt",
    "lastPokeAcknowledgedAt",
];

/** Field transforms of the Firestore SDK in use (admin in functions and scripts). */
export type FieldOps = {
    deleteField(): unknown;
    serverTimestamp(): unknown;
};

type PlanLike = {[key: string]: unknown};

export function millisOf(value: unknown): number {
    if (!value) return 0;
    if (typeof value === "number") return value;
    if (value instanceof Date) return value.getTime();
    const candidate = value as {toMillis?: () => number; toDate?: () => Date};
    if (typeof candidate.toMillis === "function") return candidate.toMillis();
    if (typeof candidate.toDate === "function") return candidate.toDate().getTime();
    return 0;
}

function asId(value: unknown): string | null {
    return typeof value === "string" && value.length > 0 ? value : null;
}

/**
 * Detaches a plan from its manager (disconnect, account deletion, a manager
 * who is not a linked partner):
 *   - managerId removed; the unlink time becomes the proof floor for whoever
 *     manages the plan next (managerSince / managerSinceUid = UNLINKED_MARK);
 *   - the last-proof pointers and everything the partner wrote on the plan
 *     (cheers, comments, pokes) are cleared;
 *   - pending_approval → active, an in-progress 내기 (proposed/active) →
 *     rejected;
 *   - lastUpdatedBy = system_unlink, so onPlanUpdated sends no push.
 */
export function unlinkUpdate(plan: PlanLike, ops: FieldOps): {[key: string]: unknown} {
    const update: {[key: string]: unknown} = {
        managerId: ops.deleteField(),
        lastUpdatedBy: SYSTEM_UNLINK,
        managerSince: ops.serverTimestamp(),
        managerSinceUid: UNLINKED_MARK,
        lastProofPhotoPath: ops.deleteField(),
        lastProofAt: ops.deleteField(),
    };
    for (const field of PARTNER_CONTENT_FIELDS) update[field] = ops.deleteField();
    if (plan.state === "pending_approval") update.state = "active";
    const promise = plan.promise as {status?: unknown} | null | undefined;
    if (promise?.status === "proposed" || promise?.status === "active") {
        update["promise.status"] = "rejected";
    }
    return update;
}

/**
 * The `managerId` an action should carry: its plan's current manager, so the
 * partner can list it (firestore.rules.next). Null — no field — when the plan
 * is gone or has no manager, when the "manager" is the owner, or when the
 * action is not the plan owner's own record. `plan` is the action's plan
 * (plans/{action.planId}), or null when it doesn't exist.
 */
export function actionManagerFor(action: PlanLike, plan: PlanLike | null): string | null {
    if (!plan) return null;
    const owner = asId(plan.userId);
    const manager = asId(plan.managerId);
    if (!owner || !manager || manager === owner) return null;
    return asId(action.userId) === owner ? manager : null;
}

/**
 * The proof floor for `managerId` when they become the plan's manager, given
 * the plan as it was before. storage.rules lets the manager read only proofs
 * created at or after `managerSince`, and only while `managerSinceUid` is
 * their uid. Null when nothing needs stamping:
 *   - the plan is already stamped for them, or
 *   - they managed it before stamps existed (no stamp at all): they keep the
 *     access they had.
 * Otherwise the floor is
 *   - now, when another manager held the plan until now (their era stays
 *     hidden);
 *   - max(unlink time, now - 1 day) after an unlink;
 *   - now - 1 day for a plan's first manager.
 */
export function managerStampFor(
    before: PlanLike,
    managerId: string,
    nowMs: number,
): {sinceMs: number} | null {
    const stampedFor = before.managerSinceUid;
    if (stampedFor === managerId) return null;
    const previous = asId(before.managerId);
    if (previous === managerId && typeof stampedFor !== "string") return null;

    const recent = nowMs - NEW_MANAGER_LOOKBACK_MS;
    if (previous && previous !== managerId) return {sinceMs: nowMs};
    if (stampedFor === UNLINKED_MARK) return {sinceMs: Math.max(millisOf(before.managerSince), recent)};
    // Stamped for someone else who left without an unlink (e.g. the owner
    // cleared managerId in an edit): hide their era.
    if (typeof stampedFor === "string") return {sinceMs: nowMs};
    return {sinceMs: recent};
}
