import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
// Modular imports: the namespaced statics (admin.firestore.FieldValue) are lost
// behind the Functions emulator's admin stub.
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {
    ConnectFailReason,
    PushCopy,
    actionCompletedCopy,
    clip,
    defaultPokeMessage,
    displayNameOf,
    missedCopy,
    partnerConnectFailedCopy,
    partnerConnectedCopy,
    partnerLabel,
    planApprovedCopy,
    planChangedCopy,
    planCreatedCopy,
    planRejectedCopy,
    pokeCopy,
    pokeReplyCopy,
    reactionCopy,
    reactionEmoji,
    sanitizePokeMessage,
    verifyReminderCopy,
    workoutInfo,
} from "./copy";
import {
    DateLike,
    LocalDateParts,
    dayKey,
    isAfterLocalDay,
    isBeforeLocalDay,
    isSameLocalDay,
    localDaysAgo,
    localParts,
    previousLocalDay,
    resolveTimeZone,
} from "./time";
import {
    LATE_LOOKBACK_MINUTES,
    PlanItemData,
    dueItemForMissedNotice,
    hasCoveredToday,
    hasDateOn,
    hasTimedItem,
    lateItemFromYesterday,
} from "./schedule";
import {pairsOf, previousSeoulDay} from "./stats";
import {NOTIFICATION_ACTIONS_BUILD, buildMessagePayload, quickActionCategory} from "./push";
import {generateUniqueInviteCode, normalizeInviteCode} from "./inviteCode";
import {FieldOps, SYSTEM_LINK, actionManagerFor, managerStampFor, millisOf, unlinkUpdate} from "./planLinks";

admin.initializeApp();

/** First app build of the 둘운완 pivot (version 1.1.0+81). */
const PIVOT_BUILD = 81;
// A 'done' proof waiting longer than this nudges the manager to verify it, once.
const VERIFY_REMINDER_AFTER_MS = 24 * 60 * 60 * 1000;
// Don't nudge for very old proofs (avoids re-nudging historical backlog).
const VERIFY_REMINDER_WINDOW_MS = 72 * 60 * 60 * 1000;
// Verify reminders are held back outside the recipient's local daytime and
// picked up by a later hourly run (the 72h window leaves room for that).
const VERIFY_REMINDER_EARLIEST_HOUR = 9;
const VERIFY_REMINDER_LATEST_HOUR = 22;
// Server-only bookkeeping (dedupe / rate limits). Clients have no rules for
// it, so they can neither read nor write it. `expireAt` carries a TTL policy
// (see firestore.indexes.json fieldOverrides).
const LOCK_COLLECTION = "serverLocks";
const LOCK_TTL_MS = 3 * 24 * 60 * 60 * 1000;
// A link whose processing started this long ago without finishing (crashed
// instance) may be taken over by a retry.
const LINK_LOCK_STALE_MS = 5 * 60 * 1000;
// Retried triggers (failurePolicy) give up on events older than this.
const RELATION_EVENT_MAX_AGE_MS = 24 * 60 * 60 * 1000;
const PLAN_EVENT_MAX_AGE_MS = 60 * 60 * 1000;
// Abuse limits.
const CONNECT_PUSHES_PER_DAY = 5; // partner_connected / partner_connect_failed per recipient
const CHEERS_PER_HOUR = 20; // non-poke cheers (reactions, messages, replies) per sender → recipient
const INVITE_LOOKUPS_PER_HOUR = 30;
const INVITE_REDEEMS_PER_HOUR = 10;
const BATCH_LIMIT = 400;
const GET_ALL_CHUNK = 100;
// Actions re-synced per transaction (actions.managerId; the limit is 500 writes).
const ACTION_SYNC_CHUNK = 450;

/** users/{uid}/private/{doc}: owner-only data (rules), read here with the admin SDK. */
const PRIVATE_MESSAGING_DOC = "messaging";

type Data = admin.firestore.DocumentData;
type DocSnap = admin.firestore.QueryDocumentSnapshot;

const db = (): admin.firestore.Firestore => admin.firestore();

const FIELD_OPS: FieldOps = {
    deleteField: () => FieldValue.delete(),
    serverTimestamp: () => FieldValue.serverTimestamp(),
};

/**
 * Sends a message and cleans up dead tokens.
 *
 * When FCM reports the token as unregistered/invalid we delete it from the
 * recipient's user doc (and the private messaging doc) so we stop trying to
 * deliver to it and the client re-registers a fresh token on next launch.
 * Returns whether the send succeeded so callers can decide whether to mark
 * dedupe state.
 */
async function sendAndCleanup(
    message: admin.messaging.Message,
    recipientUserId: string,
): Promise<boolean> {
    if (process.env.FUNCTIONS_EMULATOR === "true") {
        // Local emulator only: record instead of calling FCM so emulator
        // tests can assert on what would have been sent.
        await db().collection("emulatorPushes").add({
            to: recipientUserId,
            notification: (message as {notification?: unknown}).notification ?? null,
            data: (message as {data?: unknown}).data ?? null,
            at: FieldValue.serverTimestamp(),
        });
        return true;
    }
    try {
        await admin.messaging().send(message);
        return true;
    } catch (error) {
        const code = (error as {code?: string})?.code ?? "";
        const deadTokenCodes = [
            "messaging/registration-token-not-registered",
            "messaging/invalid-registration-token",
            "messaging/invalid-argument",
        ];
        if (deadTokenCodes.includes(code)) {
            const userRef = db().collection("users").doc(recipientUserId);
            await Promise.all([
                userRef.update({fcmToken: FieldValue.delete()}).catch(() => undefined),
                userRef.collection("private").doc(PRIVATE_MESSAGING_DOC)
                    .update({fcmToken: FieldValue.delete()}).catch(() => undefined),
            ]);
            console.warn(`Removed dead FCM token for user ${recipientUserId} (${code})`);
        } else {
            console.error("FCM send error:", error);
        }
        return false;
    }
}

/**
 * Sends [copy] to the recipient. A push with buttons (see
 * quickActionCategory) carries its category; to builds that draw such
 * pushes themselves it goes data-only, so Android shows the buttons too.
 * Without [recipient] (or on older builds) it stays a plain notification.
 */
async function sendCopy(
    recipientUserId: string,
    fcmToken: string,
    copy: PushCopy,
    data: {[key: string]: string},
    recipient: Data | null = null,
): Promise<boolean> {
    const category = quickActionCategory(data);
    const dataOnly = category !== null && clientBuildOf(recipient) >= await notificationActionsBuild();
    return sendAndCleanup(
        buildMessagePayload(fcmToken, copy.title, copy.body, data, {category, dataOnly}),
        recipientUserId,
    );
}

// ---------------------------------------------------------------------------
// Small data helpers
// ---------------------------------------------------------------------------

function asId(value: unknown): string | null {
    return typeof value === "string" && value.length > 0 ? value : null;
}

/** `actionDate` (epoch millis) of an action's day for push data, when known. */
function actionDateData(action: Data): {actionDate?: string} {
    const millis = millisOf(action.date ?? action.createdAt);
    return millis > 0 ? {actionDate: String(millis)} : {};
}

async function getUser(uid: string | null): Promise<Data | null> {
    if (!uid) return null;
    const snap = await db().collection("users").doc(uid).get();
    return snap.exists ? snap.data() ?? null : null;
}

async function getPlan(planId: string | null): Promise<Data | null> {
    if (!planId) return null;
    const snap = await db().collection("plans").doc(planId).get();
    return snap.exists ? snap.data() ?? null : null;
}

/** Reads many docs of one collection in chunked getAll calls (missing → null). */
async function getDocs(collection: string, ids: Array<string | null | undefined>): Promise<Map<string, Data | null>> {
    const unique = Array.from(new Set(ids.filter((id): id is string => Boolean(id))));
    const result = new Map<string, Data | null>();
    for (let i = 0; i < unique.length; i += GET_ALL_CHUNK) {
        const refs = unique.slice(i, i + GET_ALL_CHUNK).map((id) => db().collection(collection).doc(id));
        const snaps = await db().getAll(...refs);
        snaps.forEach((snap) => result.set(snap.id, snap.exists ? snap.data() ?? null : null));
    }
    return result;
}

/**
 * The recipient's FCM token: on the user doc, or (once clients move it out of
 * the publicly readable doc) in users/{uid}/private/messaging.
 */
async function tokenOf(uid: string, user: Data | null): Promise<string | null> {
    const publicToken = asId(user?.fcmToken);
    if (publicToken) return publicToken;
    const snap = await db().collection("users").doc(uid).collection("private").doc(PRIVATE_MESSAGING_DOC).get();
    return asId(snap.data()?.fcmToken);
}

function clientBuildOf(user: Data | null): number {
    const value = Number(user?.clientBuild);
    return Number.isFinite(value) ? value : 0;
}

function timeZoneOf(user: Data | null): string {
    return resolveTimeZone(user?.timezone);
}

function firstItem(plan: Data | null): PlanItemData {
    const items = Array.isArray(plan?.items) ? plan?.items as PlanItemData[] : [];
    return items[0] ?? {};
}

function utcDayKey(now = new Date()): string {
    return now.toISOString().slice(0, 10);
}

function utcHourKey(now = new Date()): string {
    return now.toISOString().slice(0, 13);
}

/** A retried event (failurePolicy) older than `maxAgeMs` is dropped instead of retried forever. */
function isExpiredEvent(context: functions.EventContext, maxAgeMs: number): boolean {
    const at = Date.parse(context.timestamp);
    if (!Number.isFinite(at) || Date.now() - at <= maxAgeMs) return false;
    console.error(`Dropping event ${context.eventId} from ${context.timestamp} (too old to retry)`);
    return true;
}

// ---------------------------------------------------------------------------
// Locks, markers and rate limits (serverLocks)
// ---------------------------------------------------------------------------

function lockRef(key: string): admin.firestore.DocumentReference {
    return db().collection(LOCK_COLLECTION).doc(key.replace(/[^A-Za-z0-9_.-]/g, "_").slice(0, 500));
}

function lockStamp(now = Date.now()): Data {
    return {at: Timestamp.fromMillis(now), expireAt: Timestamp.fromMillis(now + LOCK_TTL_MS)};
}

/** Atomically claims `serverLocks/{key}` once (until the TTL sweeps it). */
async function claimLock(key: string): Promise<boolean> {
    const ref = lockRef(key);
    return db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (snap.exists) return false;
        tx.set(ref, lockStamp());
        return true;
    });
}

async function releaseLock(key: string): Promise<void> {
    await lockRef(key).delete();
}

async function lockExists(key: string): Promise<boolean> {
    return (await lockRef(key).get()).exists;
}

/** Takes one of `max` tokens for `key` (a counter that the TTL sweeps away). */
async function takeToken(key: string, max: number): Promise<boolean> {
    const ref = lockRef(key);
    return db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const count = snap.exists ? Number(snap.data()?.count) || 0 : 0;
        if (count >= max) return false;
        tx.set(ref, {...lockStamp(), count: count + 1});
        return true;
    });
}

/**
 * Background events are delivered at least once: a push is sent only by the
 * first delivery of an event. Claimed right before sending, after the cheap
 * early returns.
 */
async function claimEvent(context: functions.EventContext): Promise<boolean> {
    if (!context.eventId) return true;
    const first = await claimLock(`evt_${context.eventId}`);
    if (!first) console.log(`Event ${context.eventId} already handled`);
    return first;
}

async function commitUpdates(
    updates: Array<{ref: admin.firestore.DocumentReference; data: Data}>,
): Promise<void> {
    for (let i = 0; i < updates.length; i += BATCH_LIMIT) {
        const batch = db().batch();
        for (const {ref, data} of updates.slice(i, i + BATCH_LIMIT)) {
            batch.update(ref, data);
        }
        await batch.commit();
    }
}

async function deleteQuery(query: admin.firestore.Query): Promise<number> {
    let total = 0;
    for (;;) {
        const snap = await query.limit(BATCH_LIMIT).get();
        if (snap.empty) return total;
        const batch = db().batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        total += snap.size;
        if (snap.size < BATCH_LIMIT) return total;
    }
}

function isNotFound(error: unknown): boolean {
    const code = (error as {code?: unknown})?.code;
    return code === 5 || code === "not-found";
}

/** update() that treats a doc deleted in the meantime as nothing to do. */
async function updateIfExists(ref: admin.firestore.DocumentReference, data: Data): Promise<void> {
    try {
        await ref.update(data);
    } catch (error) {
        if (!isNotFound(error)) throw error;
    }
}

/** Orders Firestore timestamps exactly (createTime has microsecond precision). */
function compareTimes(x: Timestamp | undefined, y: Timestamp | undefined): number {
    if (!x || !y) return millisOf(x) - millisOf(y);
    return x.seconds !== y.seconds ? x.seconds - y.seconds : x.nanoseconds - y.nanoseconds;
}

// ---------------------------------------------------------------------------
// Relations (짝꿍 links)
// ---------------------------------------------------------------------------

async function relationDocsBetween(a: string, b: string): Promise<DocSnap[]> {
    const relations = db().collection("relations");
    const [ab, ba] = await Promise.all([
        relations.where("managerId", "==", a).where("executorId", "==", b).get(),
        relations.where("managerId", "==", b).where("executorId", "==", a).get(),
    ]);
    return [...ab.docs, ...ba.docs];
}

/** True when a relation doc links `a` and `b` in either direction. */
async function arePartners(a: string | null, b: string | null): Promise<boolean> {
    if (!a || !b || a === b) return false;
    const relations = db().collection("relations");
    const [ab, ba] = await Promise.all([
        relations.where("managerId", "==", a).where("executorId", "==", b).limit(1).get(),
        relations.where("managerId", "==", b).where("executorId", "==", a).limit(1).get(),
    ]);
    return !ab.empty || !ba.empty;
}

/**
 * Counterpart uid → when the earliest relation doc with them was written
 * (server createTime, which clients cannot backdate).
 */
async function partnersOf(uid: string): Promise<Map<string, number>> {
    const relations = db().collection("relations");
    const [asManager, asExecutor] = await Promise.all([
        relations.where("managerId", "==", uid).get(),
        relations.where("executorId", "==", uid).get(),
    ]);
    const result = new Map<string, number>();
    const add = (other: unknown, doc: DocSnap) => {
        const id = asId(other);
        if (!id || id === uid) return;
        const at = millisOf(doc.createTime);
        const known = result.get(id);
        result.set(id, known === undefined ? at : Math.min(known, at));
    };
    asManager.docs.forEach((doc) => add(doc.data().executorId, doc));
    asExecutor.docs.forEach((doc) => add(doc.data().managerId, doc));
    return result;
}

/** Per-invocation cache of who is linked with whom. */
class Links {
    private readonly partners = new Map<string, Promise<Map<string, number>>>();

    partnersOf(uid: string): Promise<Map<string, number>> {
        let pending = this.partners.get(uid);
        if (!pending) {
            pending = partnersOf(uid);
            this.partners.set(uid, pending);
        }
        return pending;
    }

    async linked(a: string | null, b: string | null): Promise<boolean> {
        if (!a || !b || a === b) return false;
        return (await this.partnersOf(a)).has(b);
    }

    /**
     * Whether the recipient's `partnerNickname` was meant for `senderId`: the
     * nickname names one partner (`partnerNicknameFor` when the app wrote it),
     * so an account still linked to several partners from before 1:1 never
     * shows it for the others.
     */
    async nicknameApplies(recipientId: string, recipient: Data | null, senderId: string): Promise<boolean> {
        const namedFor = asId(recipient?.partnerNicknameFor);
        if (namedFor) return namedFor === senderId;
        return (await this.partnersOf(recipientId)).size <= 1;
    }
}

async function newUniqueInviteCode(): Promise<string> {
    return generateUniqueInviteCode(async (candidate) => {
        const taken = await db().collection("users").where("inviteCode", "==", candidate).limit(1).get();
        return !taken.empty;
    });
}

async function rotateInviteCode(uid: string, extra: Data = {}): Promise<void> {
    const ref = db().collection("users").doc(uid);
    const snap = await ref.get();
    if (!snap.exists) return;
    await ref.update({inviteCode: await newUniqueInviteCode(), ...extra});
}

/**
 * Users holding `code` (up to 3). Codes are unique by construction on the
 * server, but a client can still write any code when it creates its user doc;
 * when two hold the same code, every holder but the earliest account gets a
 * new one.
 */
async function codeHolders(code: string): Promise<DocSnap[]> {
    const snap = await db().collection("users").where("inviteCode", "==", code).limit(3).get();
    if (snap.size > 1) {
        const byAge = [...snap.docs].sort((x, y) => millisOf(x.createTime) - millisOf(y.createTime));
        await Promise.all(byAge.slice(1).map(async (doc) => {
            console.warn(`Invite code shared by ${snap.size} users; re-issuing ${doc.id}'s`);
            await rotateInviteCode(doc.id);
        }));
    }
    return snap.docs;
}

// ---------------------------------------------------------------------------
// actions.managerId — who besides the owner may read an action
// ---------------------------------------------------------------------------
//
// Every action carries its plan's current manager (planLinks.actionManagerFor)
// so firestore.rules.next can let the partner list it without a per-document
// plan lookup. The app may stamp it on create (rules: only the plan's
// manager); the server stamps what the app didn't and re-syncs on every
// change of a plan's manager (link, unlink, guard detach, account deletion)
// and on plan deletion. scripts/migrations/backfill_action_manager_ids.js
// does the same for actions written before this existed.

type DocRef = admin.firestore.DocumentReference;

/**
 * Makes each action's `managerId` match its plan's current manager: set when
 * the plan has one, removed when it has none, when the plan is gone, or when
 * the action is not the plan owner's. Each chunk re-reads its actions and
 * their plans inside one transaction, so a link or unlink racing with this
 * never leaves a stale value: whichever runs last sees the latest plan.
 * Returns how many actions changed.
 */
async function reconcileActionManagers(refs: DocRef[]): Promise<number> {
    const unique = Array.from(new Map(refs.map((ref) => [ref.path, ref])).values());
    let changed = 0;
    for (let i = 0; i < unique.length; i += ACTION_SYNC_CHUNK) {
        const chunk = unique.slice(i, i + ACTION_SYNC_CHUNK);
        changed += await db().runTransaction(async (tx) => {
            const actions = await tx.getAll(...chunk);
            const planIds = Array.from(new Set(actions.map((snap) => asId(snap.data()?.planId))))
                .filter((id): id is string => id !== null);
            const plans = new Map<string, Data | null>();
            if (planIds.length > 0) {
                const snaps = await tx.getAll(...planIds.map((id) => db().collection("plans").doc(id)));
                snaps.forEach((snap) => plans.set(snap.id, snap.exists ? snap.data() ?? null : null));
            }
            let writes = 0;
            for (const snap of actions) {
                const action = snap.data();
                if (!snap.exists || !action) continue;
                const planId = asId(action.planId);
                const want = actionManagerFor(action, planId ? plans.get(planId) ?? null : null);
                const upToDate = want === null ? !("managerId" in action) : action.managerId === want;
                if (upToDate) continue;
                tx.update(snap.ref, {managerId: want ?? FieldValue.delete()});
                writes++;
            }
            return writes;
        });
    }
    return changed;
}

async function refsOf(query: admin.firestore.Query): Promise<DocRef[]> {
    const snap = await query.select().get(); // references only
    return snap.docs.map((doc) => doc.ref);
}

/** Re-syncs managerId on every action of the given plans. */
async function syncPlanActions(planIds: string[]): Promise<number> {
    const actions = db().collection("actions");
    const refs = await Promise.all(planIds.map((planId) => refsOf(actions.where("planId", "==", planId))));
    return reconcileActionManagers(refs.flat());
}

/**
 * Takes a's and b's actions off each other's list (after their plans were
 * detached). Found by the stamp itself, so actions of deleted plans and of
 * plans re-pointed meanwhile are covered too.
 */
async function unshareActionsBetween(a: string, b: string): Promise<number> {
    const actions = db().collection("actions");
    const [ab, ba] = await Promise.all([
        refsOf(actions.where("userId", "==", a).where("managerId", "==", b)),
        refsOf(actions.where("userId", "==", b).where("managerId", "==", a)),
    ]);
    return reconcileActionManagers([...ab, ...ba]);
}

// ---------------------------------------------------------------------------
// Plans ↔ manager
// ---------------------------------------------------------------------------

function stampFields(managerId: string, sinceMs: number): Data {
    return {managerSince: Timestamp.fromMillis(sinceMs), managerSinceUid: managerId};
}

/**
 * Detaches every plan between a and b (both directions), then clears the
 * pair's actions.managerId. Plans first, so the action re-sync reads them
 * detached.
 */
async function unlinkPlansBetween(a: string, b: string): Promise<{plans: number; actions: number}> {
    const plans = db().collection("plans");
    const [aPlans, bPlans] = await Promise.all([
        plans.where("userId", "==", a).where("managerId", "==", b).get(),
        plans.where("userId", "==", b).where("managerId", "==", a).get(),
    ]);
    const docs = [...aPlans.docs, ...bPlans.docs];
    await commitUpdates(docs.map((doc) => ({ref: doc.ref, data: unlinkUpdate(doc.data(), FIELD_OPS)})));
    const actions = await unshareActionsBetween(a, b);
    return {plans: docs.length, actions};
}

/**
 * Points the owner's active plans at their new partner (spec §5: the code
 * owner's plans). A plan still pointing at someone else is stale — after a
 * successful 1:1 link the owner has no other partner — and is taken over
 * too. Each write carries the new manager's proof floor. Then their actions
 * are stamped for the new partner. Returns how many plans were re-pointed.
 */
async function assignPlansToPartner(ownerId: string, managerId: string): Promise<number> {
    const snap = await db().collection("plans")
        .where("userId", "==", ownerId)
        .where("state", "==", "active")
        .get();
    const nowMs = Date.now();
    const updates: Array<{ref: admin.firestore.DocumentReference; data: Data}> = [];
    for (const doc of snap.docs) {
        const plan = doc.data();
        const stamp = managerStampFor(plan, managerId, nowMs);
        if (asId(plan.managerId) === managerId && !stamp) continue;
        updates.push({
            ref: doc.ref,
            data: {
                managerId,
                lastUpdatedBy: SYSTEM_LINK,
                ...(stamp ? stampFields(managerId, stamp.sinceMs) : {}),
            },
        });
    }
    await commitUpdates(updates);
    // All of them now point at the partner (also those that already did).
    const stamped = await syncPlanActions(snap.docs.map((doc) => doc.id));
    if (stamped > 0) console.log(`${stamped} actions of ${ownerId} now shared with ${managerId}`);
    return updates.length;
}

/**
 * Keeps `plans.managerId` honest on every write that leaves one set: a
 * manager who is not a linked partner is detached, and a newly set manager
 * gets their proof floor. Returns false when the plan was detached.
 */
async function guardPlanManager(
    ref: admin.firestore.DocumentReference,
    planId: string,
    before: Data,
    after: Data,
    links: Links,
): Promise<boolean> {
    const userId = asId(after.userId);
    const managerId = asId(after.managerId);
    if (!userId || !managerId) return true;
    if (managerId === userId || !(await links.linked(userId, managerId))) {
        console.warn(`Plan ${planId}: manager ${managerId} is not linked, detaching`);
        await updateIfExists(ref, unlinkUpdate(after, FIELD_OPS));
        return false;
    }
    if (asId(after.managerSinceUid) !== managerId) {
        const basis = managerId === asId(before.managerId) ? after : before;
        const stamp = managerStampFor(basis, managerId, Date.now());
        if (stamp) await updateIfExists(ref, stampFields(managerId, stamp.sinceMs));
    }
    return true;
}

// ---------------------------------------------------------------------------
// Linking by invite code
// ---------------------------------------------------------------------------

type LinkClaim = "run" | "busy" | "finish" | "skip";

/**
 * One relation write (both docs of a pair, one commit) is processed once:
 * processing → linked (validated, plans assigned, push sent) → done (codes
 * rotated), or → undone. A failed run releases its claim and is retried.
 */
async function claimLink(key: string): Promise<LinkClaim> {
    const ref = lockRef(key);
    return db().runTransaction(async (tx) => {
        const now = Date.now();
        const snap = await tx.get(ref);
        const state = snap.exists ? snap.data()?.state : null;
        if (state === "done" || state === "undone") return "skip";
        if (state === "linked") return "finish";
        if (state === "processing" && now - millisOf(snap.data()?.at) < LINK_LOCK_STALE_MS) return "busy";
        tx.set(ref, {...lockStamp(now), state: "processing"});
        return "run";
    });
}

async function setLinkState(key: string, state: "linked" | "done" | "undone"): Promise<void> {
    await lockRef(key).set({...lockStamp(), state});
}

type LinkStamp = {inviterId: string; inviteeId: string; inviteCode: string};

/**
 * Who shared the code and which code was used. The app writes `inviterId` (the
 * code owner) and `inviteCode` on both docs, and firestore.rules makes the
 * writer the *other* participant, so the invitee is the person who entered
 * the code. Null when the docs carry no usable stamp.
 */
function stampOf(docs: DocSnap[], a: string, b: string): LinkStamp | null {
    let stamp: LinkStamp | null = null;
    for (const doc of docs) {
        const data = doc.data();
        const inviterId = asId(data.inviterId);
        const inviteCode = asId(data.inviteCode);
        if (!inviterId || !inviteCode || (inviterId !== a && inviterId !== b)) return null;
        const inviteeId = inviterId === a ? b : a;
        const createdBy = asId(data.createdBy);
        if (createdBy && createdBy !== inviteeId) return null;
        if (stamp && (stamp.inviterId !== inviterId || stamp.inviteCode !== inviteCode)) return null;
        stamp = {inviterId, inviteeId, inviteCode};
    }
    return stamp;
}

function isUnstamped(docs: DocSnap[]): boolean {
    return docs.every((doc) => !("inviterId" in doc.data()) && !("inviteCode" in doc.data()));
}

/**
 * Pre-pivot builds link without a stamp. They may only while ops keeps
 * config/app.legacyLinkUntil in the future (firestore.rules checks the same).
 */
async function legacyLinksOpen(): Promise<boolean> {
    const snap = await db().collection("config").doc("app").get();
    return millisOf(snap.data()?.legacyLinkUntil) > Date.now();
}

let actionsBuildCache: {value: number; at: number} | null = null;

/**
 * First build that gets data-only pushes with buttons: NOTIFICATION_ACTIONS_BUILD,
 * unless ops sets config/app.notificationActionsBuild (e.g. very high, to send
 * every build plain notifications again without a deploy). Cached 5 minutes.
 */
async function notificationActionsBuild(): Promise<number> {
    if (actionsBuildCache && Date.now() - actionsBuildCache.at < 5 * 60 * 1000) {
        return actionsBuildCache.value;
    }
    let value = NOTIFICATION_ACTIONS_BUILD;
    try {
        const configured = Number((await db().collection("config").doc("app").get()).data()?.notificationActionsBuild);
        if (Number.isFinite(configured) && configured > 0) value = configured;
    } catch (error) {
        console.warn("config/app read failed, using the default actions build", error);
    }
    actionsBuildCache = {value, at: Date.now()};
    return value;
}

/** Marks docs as undone (so their delete trigger resets nothing), then deletes them. */
async function deleteAsUndone(docs: DocSnap[]): Promise<void> {
    await Promise.all(docs.map((doc) => lockRef(`relation_undo_${doc.id}`).set(lockStamp())));
    const batch = db().batch();
    docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
}

async function sendConnectPush(uid: string, copy: PushCopy, data: {[key: string]: string}): Promise<void> {
    const user = await getUser(uid);
    const token = await tokenOf(uid, user);
    if (!token) return;
    if (!(await takeToken(`connect_push_${uid}_${utcDayKey()}`, CONNECT_PUSHES_PER_DAY))) {
        console.warn(`Connect push to ${uid} skipped: daily limit`);
        return;
    }
    await sendCopy(uid, token, copy, data);
}

async function undoLink(
    key: string,
    docs: DocSnap[],
    why: string,
    notify: {uid: string; reason: ConnectFailReason} | null,
): Promise<void> {
    await deleteAsUndone(docs);
    await setLinkState(key, "undone");
    console.warn(`Relation ${docs.map((doc) => doc.id).join(",")} undone (${why})`);
    if (!notify) return;
    await sendConnectPush(notify.uid, partnerConnectFailedCopy(notify.reason), {
        type: "partner_connect_failed",
        reason: notify.reason,
    });
}

type LinkOutcome =
    | {linked: false}
    | {linked: true; legacy: false; inviterId: string; inviteeId: string}
    | {linked: true; legacy: true};

/**
 * Validates one relation write and either undoes it or applies the link:
 *   - a pair that is already linked by older docs: the duplicate is dropped;
 *   - the stamp must name the code owner and their current, unique code
 *     (unstamped writes only inside the legacy window);
 *   - 1:1: if either person already has an older link, the person who
 *     entered the code is told why (self_taken / owner_taken);
 *   - the code owner's active plans get the new partner as manager.
 */
async function settleLink(key: string, a: string, b: string, self: DocSnap, pairDocs: DocSnap[]): Promise<LinkOutcome> {
    const linkAt = millisOf(self.createTime);
    const batchDocs = pairDocs.filter((doc) => compareTimes(doc.createTime, self.createTime) === 0);
    if (pairDocs.some((doc) => compareTimes(doc.createTime, self.createTime) < 0)) {
        await undoLink(key, batchDocs, "pair already linked", null);
        return {linked: false};
    }

    const stamp = stampOf(batchDocs, a, b);
    let legacy = false;
    if (!stamp) {
        legacy = isUnstamped(batchDocs) && await legacyLinksOpen();
        if (!legacy) {
            await undoLink(key, batchDocs, "no verifiable invite code", null);
            return {linked: false};
        }
    }

    if (stamp) {
        const holders = await codeHolders(stamp.inviteCode);
        if (holders.length !== 1 || holders[0].id !== stamp.inviterId) {
            await undoLink(key, batchDocs, "invite code is not the owner's current code",
                {uid: stamp.inviteeId, reason: "invalid_code"});
            return {linked: false};
        }
    }

    // Only links at least as old as this one count; a newer conflicting link
    // is undone by its own trigger.
    const [partnersOfA, partnersOfB] = await Promise.all([partnersOf(a), partnersOf(b)]);
    partnersOfA.delete(b);
    partnersOfB.delete(a);
    const taken = (partners: Map<string, number>) => Array.from(partners.values()).some((at) => at <= linkAt);
    const aTaken = taken(partnersOfA);
    const bTaken = taken(partnersOfB);
    if (aTaken || bTaken) {
        if (!stamp) {
            await undoLink(key, batchDocs, "1:1 (legacy link)", null);
        } else {
            const inviteeTaken = stamp.inviteeId === a ? aTaken : bTaken;
            await undoLink(key, batchDocs, "1:1", {
                uid: stamp.inviteeId,
                reason: inviteeTaken ? "self_taken" : "owner_taken",
            });
        }
        return {linked: false};
    }

    if (!stamp) {
        // Unverified link (legacy window): nobody's plans are handed over.
        await setLinkState(key, "linked");
        return {linked: true, legacy: true};
    }
    const assigned = await assignPlansToPartner(stamp.inviterId, stamp.inviteeId);
    console.log(`Linked ${stamp.inviterId} (code owner) and ${stamp.inviteeId}; ${assigned} plans assigned`);
    await setLinkState(key, "linked");
    return {linked: true, legacy: false, inviterId: stamp.inviterId, inviteeId: stamp.inviteeId};
}

/**
 * The one partner_connected push: to the code owner, who did not write the
 * link, so a link they never agreed to is never silent. A legacy link (no
 * stamp) cannot tell who entered the code, so both are told.
 */
async function announceLink(outcome: LinkOutcome, a: string, b: string): Promise<void> {
    if (!outcome.linked) return;
    const pairs: Array<[string, string]> = outcome.legacy ?
        [[a, b], [b, a]] :
        [[outcome.inviterId, outcome.inviteeId]];
    for (const [to, other] of pairs) {
        const [recipient, partner] = await Promise.all([getUser(to), getUser(other)]);
        await sendConnectPush(to, partnerConnectedCopy(displayNameOf(partner)), {
            type: "partner_connected",
            partnerId: other,
            senderName: partnerLabel(recipient, partner, false),
        });
    }
}

/** Codes are single-use: both are re-issued once the link stands. */
async function finishLink(key: string, a: string, b: string): Promise<void> {
    await Promise.all([rotateInviteCode(a), rotateInviteCode(b)]);
    await setLinkState(key, "done");
}

// ---------------------------------------------------------------------------
// Triggers
// ---------------------------------------------------------------------------

function isPlanBetween(plan: Data | null, x: string, y: string): boolean {
    if (!plan) return false;
    const owner = asId(plan.userId);
    const manager = asId(plan.managerId);
    return (owner === x && manager === y) || (owner === y && manager === x);
}

export const onCheerCreated = functions.firestore
    .document("cheers/{cheerId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        const cheer = snapshot.data();
        if (!cheer) return;

        const toUserId = asId(cheer.toUserId);
        const fromUserId = asId(cheer.fromUserId);
        if (!toUserId || !fromUserId || toUserId === fromUserId) return;
        const planId = asId(cheer.planId);
        const reactionType = cheer.reactionType;

        try {
            // Only linked partners can reach each other.
            const links = new Links();
            if (!(await links.linked(toUserId, fromUserId))) { // caches the recipient's partners
                console.log(`Cheer ${snapshot.id}: sender is not linked with recipient, no push`);
                return;
            }

            const [recipient, sender, plan] = await Promise.all([
                getUser(toUserId),
                getUser(fromUserId),
                getPlan(planId),
            ]);
            const fcmToken = await tokenOf(toUserId, recipient);
            if (!fcmToken) {
                console.log(`User ${toUserId} has no FCM token`);
                return;
            }

            // The plan counts only when it really is one between these two;
            // otherwise a made-up planId would open a fresh poke budget.
            const pairPlan = isPlanBetween(plan, fromUserId, toUserId) ? plan : null;
            const who = partnerLabel(recipient, sender, await links.nicknameApplies(toUserId, recipient, fromUserId));
            const workout = workoutInfo(pairPlan?.workoutType);
            const timeZone = timeZoneOf(recipient);
            const today = localParts(new Date(), timeZone);

            let copy: PushCopy;
            let type: string;
            let message = clip(cheer.message, 120);
            if (reactionType === "poke") {
                // At most one poke push per plan (or per pair without a plan)
                // per recipient-local day.
                const [x, y] = [fromUserId, toUserId].sort();
                const key = pairPlan ?
                    `poke_plan_${planId}_${dayKey(today)}` :
                    `poke_pair_${x}_${y}_${dayKey(today)}`;
                if (!(await claimLock(key))) {
                    console.log(`Poke rate-limited: ${key}`);
                    return;
                }
                message = sanitizePokeMessage(cheer.message, defaultPokeMessage(workout, pairPlan !== null));
                copy = pokeCopy(who, message);
                type = "poke";
            } else {
                if (!(await takeToken(`cheer_rate_${fromUserId}_${toUserId}_${utcHourKey()}`, CHEERS_PER_HOUR))) {
                    console.log(`Cheer ${snapshot.id} rate-limited`);
                    return;
                }
                if (reactionType === "reply") {
                    copy = pokeReplyCopy(who, cheer.message);
                    type = "poke_reply";
                } else {
                    // A reaction on a day the executor already recorded is a
                    // 인정; otherwise it is encouragement.
                    const isVerification = pairPlan !== null && pairPlan.userId === toUserId &&
                        hasDateOn(pairPlan.completedDates, today, timeZone);
                    copy = reactionCopy({
                        who,
                        emoji: reactionEmoji(reactionType),
                        message: cheer.message,
                        isVerification,
                        workout,
                    });
                    type = "cheer";
                }
            }

            if (!(await claimEvent(context))) return;
            await sendCopy(toUserId, fcmToken, copy, {
                type,
                // Only a plan of these two is something to open.
                planId: pairPlan ? planId ?? "" : "",
                senderName: who,
                message,
            }, recipient);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });

export const onPlanCreated = functions
    .runWith({failurePolicy: true})
    .firestore.document("plans/{planId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        if (isExpiredEvent(context, PLAN_EVENT_MAX_AGE_MS)) return;
        const plan = snapshot.data();
        if (!plan) return;

        const managerId = asId(plan.managerId);
        const userId = asId(plan.userId);
        // No partner on the plan → nobody to notify (solo plan).
        if (!managerId || !userId) return;

        // A manager must be a linked partner; anything else (stale or forged)
        // is detached so it never grants proof-photo access. Errors here are
        // retried.
        const links = new Links();
        if (!(await guardPlanManager(snapshot.ref, context.params.planId, {}, plan, links))) return;

        try {
            const [manager, sender] = await Promise.all([getUser(managerId), getUser(userId)]);
            const fcmToken = await tokenOf(managerId, manager);
            if (!fcmToken) {
                console.log(`Manager ${managerId} has no FCM token`);
                return;
            }

            const who = partnerLabel(manager, sender, await links.nicknameApplies(managerId, manager, userId));
            const item = firstItem(plan);
            const copy = planCreatedCopy({
                who,
                workout: workoutInfo(plan.workoutType),
                itemTitle: clip(item.title, 30),
                days: item.days,
                notificationTime: item.notificationTime,
                pendingApproval: plan.state === "pending_approval",
            });

            if (!(await claimEvent(context))) return;
            await sendCopy(managerId, fcmToken, copy, {
                type: "plan_proposed",
                planId: context.params.planId,
                senderName: who,
                userId,
            });
        } catch (error) {
            console.error("Error sending plan notification:", error);
        }
    });

/**
 * A new action: stamps its `managerId` from the plan (every type; the app may
 * have written it already, or not at all — builds ≤80 never do), then relays
 * the owner's record to the manager. Stamping errors are retried; the push
 * is sent once per event.
 */
export const onActionCompleted = functions
    .runWith({failurePolicy: true})
    .firestore.document("actions/{actionId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        if (isExpiredEvent(context, PLAN_EVENT_MAX_AGE_MS)) return;
        const action = snapshot.data();
        if (!action) return;

        await reconcileActionManagers([snapshot.ref]);

        const userId = asId(action.userId);
        const planId = asId(action.planId);
        const type = action.type;
        // 'rescued' is written by the manager themself; nothing to relay.
        if (!userId || !planId || (type !== "done" && type !== "skipped" && type !== "rested")) return;

        try {
            const plan = await getPlan(planId);
            const managerId = asId(plan?.managerId);
            // Only the plan owner's own records are relayed.
            if (!plan || asId(plan.userId) !== userId || !managerId || managerId === userId) return;
            const links = new Links();
            if (!(await links.linked(managerId, userId))) return;

            const [manager, executor] = await Promise.all([getUser(managerId), getUser(userId)]);
            const fcmToken = await tokenOf(managerId, manager);
            if (!fcmToken) return;

            const hasProof = typeof action.proofPhotoPath === "string" && action.proofPhotoPath.length > 0;
            // Older builds cannot show the photo, so they get the plain copy.
            const withProof = type === "done" && hasProof && clientBuildOf(manager) >= PIVOT_BUILD;
            const who = partnerLabel(manager, executor, await links.nicknameApplies(managerId, manager, userId));
            const copy = actionCompletedCopy({
                who,
                workout: workoutInfo(plan.workoutType),
                itemTitle: clip(action.title, 30) || clip(firstItem(plan).title, 30),
                actionType: type,
                withProof,
                note: action.note,
            });
            if (!copy) return;

            if (!(await claimEvent(context))) return;
            await sendCopy(managerId, fcmToken, copy, {
                type: "action_completed",
                actionType: type,
                planId,
                senderName: who,
                userId,
                actionId: context.params.actionId,
                // The record's day: an earlier day's opens 기록, not today's card.
                ...actionDateData(action),
                hasProof: withProof ? "true" : "false",
            }, manager);
        } catch (error) {
            console.error("Error sending completion notification:", error);
        }
    });

function inPlanPeriod(plan: Data, day: LocalDateParts, timeZone: string): boolean {
    return !isAfterLocalDay(plan.startDate, day, timeZone) && !isBeforeLocalDay(plan.endDate, day, timeZone);
}

function awaitingRecord(plan: Data, day: LocalDateParts, timeZone: string): boolean {
    return inPlanPeriod(plan, day, timeZone) &&
        !hasCoveredToday(plan, day, timeZone) &&
        !isSameLocalDay(plan.lastMissedNotifiedAt, day, timeZone);
}

type MissedNotice = {
    doc: DocSnap;
    plan: Data;
    userId: string;
    managerId: string;
    item: PlanItemData;
    /** Set for a late item of the previous local day (dedupe key). */
    lateDay: string | null;
};

export const notifyMissedActions = functions
    .runWith({timeoutSeconds: 300})
    .pubsub.schedule("every 30 minutes")
    .timeZone("Asia/Seoul")
    .onRun(async () => {
        const now = new Date();
        const plansSnapshot = await db()
            .collection("plans")
            .where("state", "==", "active")
            .get();

        // Cheap filters first, without any read: a partner on the plan and at
        // least one item with a deadline.
        const candidates = plansSnapshot.docs.filter((doc) => {
            const plan = doc.data();
            const userId = asId(plan.userId);
            const managerId = asId(plan.managerId);
            return userId && managerId && userId !== managerId && hasTimedItem(plan);
        });
        // "Today" and the deadline are the executor's local ones.
        const executors = await getDocs("users", candidates.map((doc) => asId(doc.data().userId)));

        const due: MissedNotice[] = [];
        for (const doc of candidates) {
            const plan = doc.data();
            const userId = plan.userId as string;
            const managerId = plan.managerId as string;
            const timeZone = timeZoneOf(executors.get(userId) ?? null);
            const today = localParts(now, timeZone);
            if (awaitingRecord(plan, today, timeZone)) {
                const item = dueItemForMissedNotice(plan, today);
                if (item) {
                    due.push({doc, plan, userId, managerId, item, lateDay: null});
                    continue;
                }
            }
            // A late-night deadline of yesterday (e.g. 23:59) is judged now.
            if (today.minutes < LATE_LOOKBACK_MINUTES) {
                const yesterday = previousLocalDay(now, today, timeZone).parts;
                if (awaitingRecord(plan, yesterday, timeZone)) {
                    const item = lateItemFromYesterday(plan, yesterday, today);
                    if (item) due.push({doc, plan, userId, managerId, item, lateDay: dayKey(yesterday)});
                }
            }
        }

        const managers = await getDocs("users", due.map((entry) => entry.managerId));
        const links = new Links();
        let sentCount = 0;
        let detachedCount = 0;
        for (const entry of due) {
            const {doc, plan, userId, managerId, item, lateDay} = entry;
            try {
                if (!(await links.linked(managerId, userId))) {
                    // A stale manager (unlink cleanup missed): detach now.
                    await updateIfExists(doc.ref, unlinkUpdate(plan, FIELD_OPS));
                    detachedCount++;
                    continue;
                }
                const manager = managers.get(managerId) ?? null;
                const fcmToken = await tokenOf(managerId, manager);
                if (!fcmToken) continue;

                const lateKey = lateDay ? `missed_late_${doc.id}_${lateDay}` : null;
                if (lateKey && !(await claimLock(lateKey))) continue;

                const executor = executors.get(userId) ?? null;
                const who = partnerLabel(manager, executor, await links.nicknameApplies(managerId, manager, userId));
                const itemTitle = clip(item.title, 30) || (lateDay ? "어제 약속" : "오늘 약속");
                const copy = missedCopy({
                    who,
                    workout: workoutInfo(plan.workoutType),
                    itemTitle,
                    day: lateDay ? "yesterday" : "today",
                });

                // Send first, then mark dedupe state only on success — a failed
                // send is retried on the next 30-min run instead of being lost.
                const delivered = await sendCopy(managerId, fcmToken, copy, {
                    type: "action_missed",
                    planId: doc.id,
                    userId,
                    senderName: who,
                    itemTitle,
                    ...(lateDay ? {day: lateDay} : {}),
                }, manager);
                if (!delivered) {
                    if (lateKey) await releaseLock(lateKey).catch(() => undefined);
                    continue;
                }

                // lastMissedNotifiedAt describes today's notice (the app shows
                // it on today's card); yesterday's late notice is deduped by
                // its lock only.
                if (!lateDay) {
                    await doc.ref.update({
                        lastMissedNotifiedAt: FieldValue.serverTimestamp(),
                        lastMissedItemTitle: itemTitle,
                        lastUpdatedBy: "system_missed_action",
                    });
                }
                sentCount++;
            } catch (error) {
                console.error(`notifyMissedActions failed for plan ${doc.id}:`, error);
            }
        }

        console.log(`notifyMissedActions: ${plansSnapshot.size} active plans, ${candidates.length} ` +
            `with a partner and a deadline, ${due.length} due, ${sentCount} sent, ${detachedCount} detached`);
    });

// Nudges the manager when a partner's 'done' proof has waited too long for
// verification. This is a reminder only — it never auto-verifies or skips,
// since partner confirmation is intentionally a human, relational step. Each
// proof is nudged at most once (tracked by `verifyReminderSentAt`).
export const notifyUnverifiedActions = functions
    .runWith({timeoutSeconds: 300})
    .pubsub.schedule("every 60 minutes")
    .timeZone("Asia/Seoul")
    .onRun(async () => {
        const now = new Date();
        const nowMs = now.getTime();
        const newerThan = Timestamp.fromMillis(nowMs - VERIFY_REMINDER_WINDOW_MS);
        const olderThan = Timestamp.fromMillis(nowMs - VERIFY_REMINDER_AFTER_MS);

        const snap = await db()
            .collection("actions")
            .where("type", "==", "done")
            .where("createdAt", ">=", newerThan)
            .where("createdAt", "<=", olderThan)
            .get();

        const pending = snap.docs.filter((doc) => {
            const action = doc.data();
            // Not verified and not nudged yet.
            return !action.verifiedBy && !action.verifyReminderSentAt &&
                asId(action.planId) && asId(action.userId);
        });
        const plans = await getDocs("plans", pending.map((doc) => asId(doc.data().planId)));
        const entries = pending.flatMap((doc) => {
            const action = doc.data();
            const plan = plans.get(action.planId) ?? null;
            const managerId = asId(plan?.managerId);
            const userId = action.userId as string;
            if (!plan || !managerId || managerId === userId || asId(plan.userId) !== userId) return [];
            return [{doc, action, plan, planId: action.planId as string, userId, managerId}];
        });
        const users = await getDocs("users", entries.flatMap((entry) => [entry.userId, entry.managerId]));

        const links = new Links();
        const detached = new Set<string>();
        let sentCount = 0;
        for (const {doc, action, plan, planId, userId, managerId} of entries) {
            try {
                if (detached.has(planId)) continue;
                const manager = users.get(managerId) ?? null;
                const executor = users.get(userId) ?? null;

                // Hold the nudge until the recipient's local daytime.
                const recipientTimeZone = resolveTimeZone(manager?.timezone ?? executor?.timezone);
                const recipientHour = Math.floor(localParts(now, recipientTimeZone).minutes / 60);
                if (recipientHour < VERIFY_REMINDER_EARLIEST_HOUR ||
                    recipientHour >= VERIFY_REMINDER_LATEST_HOUR) continue;

                if (!(await links.linked(managerId, userId))) {
                    await updateIfExists(db().collection("plans").doc(planId), unlinkUpdate(plan, FIELD_OPS));
                    detached.add(planId);
                    continue;
                }
                const fcmToken = await tokenOf(managerId, manager);
                if (!fcmToken) continue;

                const executorTimeZone = timeZoneOf(executor);
                const daysAgo = localDaysAgo(
                    (action.date ?? action.createdAt) as DateLike,
                    localParts(now, executorTimeZone),
                    executorTimeZone,
                );
                const who = partnerLabel(manager, executor, await links.nicknameApplies(managerId, manager, userId));
                const itemTitle = clip(action.title, 30) || "오늘 약속";
                const copy = verifyReminderCopy({
                    who,
                    workout: workoutInfo(plan.workoutType),
                    itemTitle,
                    daysAgo,
                });

                const delivered = await sendCopy(managerId, fcmToken, copy, {
                    type: "verify_reminder",
                    planId,
                    // The record to open on 기록.
                    actionId: doc.id,
                    ...actionDateData(action),
                    userId,
                    senderName: who,
                    itemTitle,
                });
                if (!delivered) continue;

                await doc.ref.update({
                    verifyReminderSentAt: FieldValue.serverTimestamp(),
                });
                sentCount++;
            } catch (error) {
                console.error(`notifyUnverifiedActions failed for action ${doc.id}:`, error);
            }
        }

        console.log(`notifyUnverifiedActions: ${snap.size} done actions in the window, ${entries.length} ` +
            `waiting, ${sentCount} reminders sent, ${detached.size} plans detached`);
    });

export const onPlanUpdated = functions
    .runWith({failurePolicy: true})
    .firestore.document("plans/{planId}")
    .onUpdate(async (
        change: functions.Change<functions.firestore.QueryDocumentSnapshot>,
        context: functions.EventContext,
    ) => {
        if (isExpiredEvent(context, PLAN_EVENT_MAX_AGE_MS)) return;
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return;

        const planId = context.params.planId as string;
        const userId = asId(after.userId);
        const managerId = asId(after.managerId);
        const lastUpdatedBy = asId(after.lastUpdatedBy);
        if (!userId) return;

        // 0. Every write that leaves a manager set re-checks that they are a
        //    linked partner (a stale or forged managerId would expose proof
        //    photos) and stamps a new manager's proof floor. Errors here are
        //    retried.
        const links = new Links();
        if (!(await guardPlanManager(change.after.ref, planId, before, after, links))) return;

        // 1. A new (or no) manager: the plan's actions follow, so the partner
        //    lists exactly the actions of the plans they manage
        //    (firestore.rules.next). Covers every path that re-points a plan —
        //    the app assigning its own plans after a link, the guard above
        //    detaching (its own update lands here), account deletion. Errors
        //    are retried.
        if (asId(before.managerId) !== managerId) {
            const synced = await syncPlanActions([planId]);
            if (synced > 0) console.log(`Plan ${planId}: managerId re-synced on ${synced} actions`);
        }

        try {
            // System writes (missed notice, link/unlink, cleanup) never push.
            if (!managerId || !lastUpdatedBy || lastUpdatedBy.startsWith("system_")) return;
            if (lastUpdatedBy !== userId && lastUpdatedBy !== managerId) return;
            // Notify the participant who did not make the change.
            const toUserId = lastUpdatedBy === userId ? managerId : userId;

            const hasNewPoke =
                after.lastPokeAt?.seconds !== before.lastPokeAt?.seconds ||
                (after.lastCheerType === "poke" && before.lastCheerType !== "poke");
            // Legacy approval flow: only the manager approves or asks to adjust.
            // An owner who edits an old pending plan into an active one gets
            // the "changed" push below instead.
            const byManager = lastUpdatedBy === managerId;
            const isApproved = byManager && after.state === "active" && before.state === "pending_approval";
            const isRejected = byManager && after.state === "rejected" && before.state === "pending_approval";
            const isVerified = (after.verifiedDates?.length || 0) > (before.verifiedDates?.length || 0);
            const isImportantChange =
                JSON.stringify(before.items) !== JSON.stringify(after.items) ||
                before.startDate?.seconds !== after.startDate?.seconds ||
                before.endDate?.seconds !== after.endDate?.seconds;
            if (!hasNewPoke && !isApproved && !isRejected && !isVerified && !isImportantChange) return;

            const [recipient, sender] = await Promise.all([getUser(toUserId), getUser(lastUpdatedBy)]);
            const fcmToken = await tokenOf(toUserId, recipient);
            if (!fcmToken) return;

            const nicknameApplies = await links.nicknameApplies(toUserId, recipient, lastUpdatedBy);
            const who = partnerLabel(recipient, sender, nicknameApplies);
            const workout = workoutInfo(after.workoutType);
            let copy: PushCopy;
            let type: string;

            if (hasNewPoke) {
                // A. 똑똑 — at most one push per plan per recipient-local day.
                const today = localParts(new Date(), timeZoneOf(recipient));
                const key = `poke_plan_${planId}_${dayKey(today)}`;
                if (!(await claimLock(key))) {
                    console.log(`Poke rate-limited: ${key}`);
                    return;
                }
                copy = pokeCopy(who, sanitizePokeMessage(
                    after.lastPokeMessage || after.lastCheerMessage,
                    defaultPokeMessage(workout, true),
                ));
                type = "poke";
            } else if (isApproved) {
                // B. Legacy approval of a pending plan.
                copy = planApprovedCopy(who);
                type = "plan_approved";
            } else if (isRejected) {
                // C. Legacy request to adjust a pending plan.
                copy = planRejectedCopy(who, after.lastComment);
                type = "plan_rejected";
            } else if (isVerified) {
                // D. 인정 by the manager. When the same write also stamped
                //    lastCheerAt, a cheers doc was created alongside and
                //    onCheerCreated sends the single 인정 push.
                if (lastUpdatedBy !== managerId) return;
                if (millisOf(after.lastCheerAt) !== millisOf(before.lastCheerAt)) return;
                copy = reactionCopy({
                    who,
                    emoji: after.lastCheerType !== before.lastCheerType ?
                        reactionEmoji(after.lastCheerType) : "❤️",
                    message: after.lastComment !== before.lastComment ? after.lastComment : undefined,
                    isVerification: true,
                    workout,
                });
                type = "action_verified";
            } else {
                // E. Items / period changed.
                copy = planChangedCopy(who);
                type = "plan_updated";
            }

            if (!(await claimEvent(context))) return;
            await sendCopy(toUserId, fcmToken, copy, {
                type,
                planId,
                senderName: who,
                lastComment: clip(after.lastComment, 120),
                lastCheerMessage: clip(after.lastCheerMessage, 120),
            });
        } catch (error) {
            console.error("Error sending update notification:", error);
        }
    });

/**
 * A deleted plan takes its proof photos with it, and its actions stop
 * pointing at them. Without this the photos stayed in Storage and their paths
 * stayed on actions that anyone signed in can list. The actions also lose
 * their managerId: with the plan gone they are the owner's alone.
 */
export const onPlanDeleted = functions
    .runWith({failurePolicy: true})
    .firestore.document("plans/{planId}")
    .onDelete(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        if (isExpiredEvent(context, RELATION_EVENT_MAX_AGE_MS)) return;
        const userId = asId(snapshot.data()?.userId);
        const planId = context.params.planId as string;
        if (!userId) return;

        await admin.storage().bucket().deleteFiles({prefix: `proofs/${userId}/${planId}/`});
        const actions = await db().collection("actions").where("planId", "==", planId).get();
        const withProof = actions.docs.filter((doc) =>
            doc.data().userId === userId && (doc.data().proofPhotoPath || doc.data().proofTakenAt));
        await Promise.all(withProof.map((doc) => doc.ref.update({
            proofPhotoPath: FieldValue.delete(),
            proofSource: FieldValue.delete(),
            proofTakenAt: FieldValue.delete(),
        }).catch((error) => {
            if (!isNotFound(error)) throw error; // deleted meanwhile (account deletion)
        })));
        const unshared = await reconcileActionManagers(actions.docs.map((doc) => doc.ref));
        console.log(`Plan ${planId} deleted: proofs removed, ${withProof.length} actions cleared, ` +
            `${unshared} unshared`);
    });

/**
 * Server side of connecting by invite code. The app writes the two relation
 * docs (or redeemInviteCode does); this validates the write and applies it
 * once per write:
 *   1. The stamp must name the code owner and their current, unique code;
 *      the rules already make the writer the other person (the invitee).
 *   2. 1:1 — if either person already has another partner, the link is
 *      undone and the person who entered the code is told why.
 *   3. The code owner's active plans get the new partner as manager, and
 *      their actions the partner as managerId.
 *   4. One partner_connected push, to the code owner.
 *   5. Both invite codes are re-issued (codes are single-use).
 * Errors are retried (failurePolicy); each step is safe to repeat.
 */
export const onRelationCreated = functions
    .runWith({failurePolicy: true})
    .firestore.document("relations/{relationId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        if (isExpiredEvent(context, RELATION_EVENT_MAX_AGE_MS)) return;
        const relation = snapshot.data();
        const managerId = asId(relation?.managerId);
        const executorId = asId(relation?.executorId);
        if (!managerId || !executorId) return;
        if (managerId === executorId) {
            await deleteAsUndone([snapshot]);
            return;
        }
        const [a, b] = [managerId, executorId].sort();

        const pairDocs = await relationDocsBetween(a, b);
        const self = pairDocs.find((doc) => doc.id === snapshot.id);
        if (!self) return; // already undone or unlinked
        const batchIds = pairDocs
            .filter((doc) => compareTimes(doc.createTime, self.createTime) === 0)
            .map((doc) => doc.id)
            .sort();
        const key = `relation_link_${batchIds.join("_")}`;

        const claim = await claimLink(key);
        if (claim === "busy" || claim === "skip") return;
        if (claim === "finish") {
            await finishLink(key, a, b);
            return;
        }

        let outcome: LinkOutcome;
        try {
            outcome = await settleLink(key, a, b, self, pairDocs);
        } catch (error) {
            await releaseLock(key).catch(() => undefined);
            throw error;
        }
        if (!outcome.linked) return;
        await announceLink(outcome, a, b);
        await finishLink(key, a, b);
    });

/**
 * Disconnect cleanup. Plans between the two lose their manager (and whatever
 * the partner wrote on them), and their actions their managerId, every
 * time — that is idempotent, so it never waits on a lock. Once per deleted link, each person left without any
 * partner gets a fresh invite code and loses the nickname they had for the
 * ex. A link the server undid resets nothing. Errors are retried.
 */
export const onRelationDeleted = functions
    .runWith({failurePolicy: true})
    .firestore.document("relations/{relationId}")
    .onDelete(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        if (isExpiredEvent(context, RELATION_EVENT_MAX_AGE_MS)) return;
        const relation = snapshot.data();
        const managerId = asId(relation?.managerId);
        const executorId = asId(relation?.executorId);
        if (!managerId || !executorId || managerId === executorId) return;
        const [a, b] = [managerId, executorId].sort();

        // The other doc of the pair (or a newer link) still links them.
        if (await arePartners(a, b)) return;

        const detached = await unlinkPlansBetween(a, b);
        console.log(`Unlinked ${a} and ${b}; detached ${detached.plans} plans, unshared ${detached.actions} actions`);
        if (await lockExists(`relation_undo_${snapshot.id}`)) return;

        const createdMs = millisOf(snapshot.createTime);
        const key = createdMs ? `relation_unlink_${a}_${b}_${createdMs}` : null;
        if (key && !(await claimLock(key))) return;
        try {
            await resetAfterUnlink(a, b);
        } catch (error) {
            if (key) await releaseLock(key).catch(() => undefined);
            throw error;
        }
    });

async function resetAfterUnlink(a: string, b: string): Promise<void> {
    await Promise.all([[a, b], [b, a]].map(async ([uid, ex]) => {
        const ref = db().collection("users").doc(uid);
        const [snap, remaining] = await Promise.all([ref.get(), partnersOf(uid)]);
        if (!snap.exists) return;
        const user = snap.data() ?? {};
        const update: Data = {};
        if (remaining.size === 0) update.inviteCode = await newUniqueInviteCode();
        // Keep the nickname only when the app says it names a partner who is
        // still linked.
        const namedFor = asId(user.partnerNicknameFor);
        const keepNickname = namedFor !== null && namedFor !== ex && remaining.has(namedFor);
        if (!keepNickname && ("partnerNickname" in user || "partnerNicknameFor" in user)) {
            update.partnerNickname = FieldValue.delete();
            update.partnerNicknameFor = FieldValue.delete();
        }
        if (Object.keys(update).length > 0) await ref.update(update);
    }));
}

/**
 * Relation docs are never edited (rules: update is denied). Should one be
 * re-pointed anyway (console, admin script), it is removed: its delete
 * trigger cleans up the new pair, and the old pair is detached here.
 */
export const onRelationUpdated = functions
    .runWith({failurePolicy: true})
    .firestore.document("relations/{relationId}")
    .onUpdate(async (
        change: functions.Change<functions.firestore.QueryDocumentSnapshot>,
        context: functions.EventContext,
    ) => {
        if (isExpiredEvent(context, RELATION_EVENT_MAX_AGE_MS)) return;
        const before = change.before.data();
        const after = change.after.data();
        const was = [asId(before?.managerId), asId(before?.executorId)];
        const now = [asId(after?.managerId), asId(after?.executorId)];
        if (was[0] === now[0] && was[1] === now[1]) return;

        console.warn(`Relation ${change.after.id} was re-pointed (${was.join("→")} to ${now.join("→")}); removing it`);
        await deleteAsUndone([change.after]);
        const [a, b] = was;
        if (a && b && a !== b && !(await arePartners(a, b))) await unlinkPlansBetween(a, b);
    });

/**
 * Account deletion cleanup. The app deletes plans/relations/user before
 * deleting the auth account, but can stop half-way; this is the backstop and
 * also removes what the app never deleted (actions, cheers, Storage files,
 * what the user wrote on the partner's records).
 */
export const onAuthUserDeleted = functions.auth.user().onDelete(async (user) => {
    const uid = user.uid;
    const plans = db().collection("plans");
    const actions = db().collection("actions");
    const relations = db().collection("relations");
    const bucket = admin.storage().bucket();

    const steps: Array<[string, () => Promise<unknown>]> = [
        ["plans managed by the user", async () => {
            const snap = await plans.where("managerId", "==", uid).get();
            await commitUpdates(snap.docs.map((doc) => ({ref: doc.ref, data: unlinkUpdate(doc.data(), FIELD_OPS)})));
            return snap.size;
        }],
        // After the step above, so the re-sync reads those plans detached.
        ["actions shared with the user", async () =>
            reconcileActionManagers(await refsOf(actions.where("managerId", "==", uid)))],
        ["the user's reactions on partner records", async () => {
            const snap = await actions.where("verifiedBy", "==", uid).get();
            await commitUpdates(snap.docs.map((doc) => ({
                ref: doc.ref,
                data: {
                    partnerMessage: FieldValue.delete(),
                    reaction: FieldValue.delete(),
                    comment: FieldValue.delete(),
                },
            })));
            return snap.size;
        }],
        ["relations (manager)", () => deleteQuery(relations.where("managerId", "==", uid))],
        ["relations (executor)", () => deleteQuery(relations.where("executorId", "==", uid))],
        ["own plans", () => deleteQuery(plans.where("userId", "==", uid))],
        ["actions", () => deleteQuery(actions.where("userId", "==", uid))],
        ["cheers sent", () => deleteQuery(db().collection("cheers").where("fromUserId", "==", uid))],
        ["cheers received", () => deleteQuery(db().collection("cheers").where("toUserId", "==", uid))],
        ["proof photos", () => bucket.deleteFiles({prefix: `proofs/${uid}/`})],
        ["profile images", () => bucket.deleteFiles({prefix: `users/${uid}/`})],
        ["user doc and its private data", () => db().recursiveDelete(db().collection("users").doc(uid))],
    ];

    for (const [name, step] of steps) {
        try {
            const result = await step();
            console.log(`Account cleanup ${uid}: ${name} done${typeof result === "number" ? ` (${result})` : ""}`);
        } catch (error) {
            console.error(`Account cleanup ${uid}: ${name} failed`, error);
        }
    }
});

// ---------------------------------------------------------------------------
// Callables: invite codes resolved on the server
// ---------------------------------------------------------------------------
//
// With these the app no longer needs to query `users` by inviteCode (which is
// why users are listable today). firestore.rules.next denies list on users;
// it becomes firestore.rules once builds ≤80 are gone (SECURITY_RULES.md).
// Client creates on relations could be denied the same way later.

function requireCaller(context: functions.https.CallableContext): string {
    const uid = context.auth?.uid;
    if (!uid) throw new functions.https.HttpsError("unauthenticated", "Sign in first.");
    return uid;
}

async function requireToken(key: string, max: number): Promise<void> {
    if (!(await takeToken(key, max))) {
        throw new functions.https.HttpsError("resource-exhausted", "Too many attempts. Try again later.",
            {reason: "rate_limited"});
    }
}

/** The single holder of `code`, or an HttpsError the app maps to its messages. */
async function ownerOfCode(rawCode: unknown, callerId: string): Promise<DocSnap> {
    const code = normalizeInviteCode(rawCode);
    if (!code) {
        throw new functions.https.HttpsError("invalid-argument", "Not an invite code.", {reason: "code_format"});
    }
    const holders = await codeHolders(code);
    if (holders.length !== 1) {
        throw new functions.https.HttpsError("not-found", "No such invite code.", {reason: "not_found"});
    }
    if (holders[0].id === callerId) {
        throw new functions.https.HttpsError("failed-precondition", "This is your own code.", {reason: "self_code"});
    }
    return holders[0];
}

/**
 * `resolveInviteCode({code})` → `{uid, displayName, profileImageUrl}` of the
 * code owner, for the "connect with …?" sheet. Rate-limited per caller.
 */
export const resolveInviteCode = functions.https.onCall(async (data, context) => {
    const uid = requireCaller(context);
    await requireToken(`invite_lookup_${uid}_${utcHourKey()}`, INVITE_LOOKUPS_PER_HOUR);
    const owner = await ownerOfCode(data?.code, uid);
    const profile = owner.data();
    return {
        uid: owner.id,
        displayName: typeof profile.displayName === "string" ? profile.displayName : null,
        profileImageUrl: typeof profile.profileImageUrl === "string" ? profile.profileImageUrl : null,
    };
});

/**
 * `redeemInviteCode({code})` → `{partnerId, alreadyLinked}`. Links the caller
 * with the code owner: checks 1:1 and the code inside a transaction and writes
 * both relation docs (stamped like the app's, plus `createdBy`).
 * onRelationCreated then assigns plans, sends the push and re-issues the
 * codes. Errors carry `details.reason`: code_format, not_found, self_code,
 * self_taken, owner_taken, rate_limited.
 */
export const redeemInviteCode = functions.https.onCall(async (data, context) => {
    const uid = requireCaller(context);
    await requireToken(`invite_redeem_${uid}_${utcHourKey()}`, INVITE_REDEEMS_PER_HOUR);
    const owner = await ownerOfCode(data?.code, uid);
    const ownerId = owner.id;
    const code = owner.data().inviteCode as string;

    const relations = db().collection("relations");
    const result = await db().runTransaction(async (tx) => {
        const [ownerSnap, mine1, mine2, theirs1, theirs2] = await Promise.all([
            tx.get(owner.ref),
            tx.get(relations.where("managerId", "==", uid)),
            tx.get(relations.where("executorId", "==", uid)),
            tx.get(relations.where("managerId", "==", ownerId)),
            tx.get(relations.where("executorId", "==", ownerId)),
        ]);
        if (ownerSnap.data()?.inviteCode !== code) return "not_found";
        const counterparts = (snaps: admin.firestore.QuerySnapshot[], me: string) => new Set(snaps.flatMap((snap) =>
            snap.docs.map((doc) => (doc.data().managerId === me ? doc.data().executorId : doc.data().managerId))));
        const mine = counterparts([mine1, mine2], uid);
        const theirs = counterparts([theirs1, theirs2], ownerId);
        if (mine.has(ownerId)) return "already_linked";
        if (mine.size > 0) return "self_taken";
        if (theirs.size > 0) return "owner_taken";

        const stamp = {
            status: "active",
            inviterId: ownerId,
            inviteCode: code,
            createdBy: uid,
            createdAt: FieldValue.serverTimestamp(),
            connectedAt: FieldValue.serverTimestamp(),
        };
        tx.create(relations.doc(), {managerId: ownerId, executorId: uid, ...stamp});
        tx.create(relations.doc(), {managerId: uid, executorId: ownerId, ...stamp});
        return "linked";
    });

    if (result === "not_found") {
        throw new functions.https.HttpsError("not-found", "No such invite code.", {reason: "not_found"});
    }
    if (result === "self_taken" || result === "owner_taken") {
        throw new functions.https.HttpsError("failed-precondition", "Already linked.", {reason: result});
    }
    return {partnerId: ownerId, alreadyLinked: result === "already_linked"};
});

/**
 * Nightly operations stats for the Asia/Seoul day that just ended, written to
 * dailyStats/{YYYY-MM-DD} (server-only: no client rule matches it). Counts use
 * Firestore aggregation; only `activeUsers` reads docs (userId field only).
 * Re-running a day overwrites it, so a retry is harmless.
 */
export const aggregateDailyStats = functions
    .runWith({timeoutSeconds: 300})
    .pubsub.schedule("10 0 * * *")
    .timeZone("Asia/Seoul")
    .onRun(async () => {
        const day = previousSeoulDay(new Date());
        const from = Timestamp.fromDate(day.start);
        const to = Timestamp.fromDate(day.end);
        const inDay = (collection: string, field: string) =>
            db().collection(collection).where(field, ">=", from).where(field, "<", to);
        const count = async (query: admin.firestore.Query) => (await query.count().get()).data().count;

        const [
            newUsers, newRelationDocs, doneRecords, cheers,
            totalUsers, totalRelationDocs, activePlans, doneSnap,
        ] = await Promise.all([
            count(inDay("users", "createdAt")),
            count(inDay("relations", "createdAt")),
            count(db().collection("actions").where("type", "==", "done")
                .where("createdAt", ">=", from).where("createdAt", "<", to)),
            count(inDay("cheers", "createdAt")),
            count(db().collection("users")),
            count(db().collection("relations")),
            count(db().collection("plans").where("state", "==", "active")),
            db().collection("actions").where("type", "==", "done")
                .where("createdAt", ">=", from).where("createdAt", "<", to)
                .select("userId").get(),
        ]);
        const activeUsers = new Set(doneSnap.docs.map((d) => d.get("userId"))).size;

        await db().collection("dailyStats").doc(day.key).set({
            date: day.key,
            newUsers,
            newCouples: pairsOf(newRelationDocs),
            doneRecords,
            activeUsers,
            cheers,
            totalUsers,
            totalCouples: pairsOf(totalRelationDocs),
            activePlans,
            computedAt: FieldValue.serverTimestamp(),
        });
        functions.logger.info("dailyStats written", {date: day.key, newUsers, doneRecords, activeUsers});
    });
