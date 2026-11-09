// Invite re-engagement: a gentle reminder to an inviter whose partner hasn't
// joined yet.
//
// The app upserts `invites/{inviterUid}` every time the user shares their
// invite (share sheet or code copy):
//   {inviterUid, code, createdAt, lastSharedAt, shareCount}
// (firestore.rules: only the inviter writes it, `lastSharedAt` is always the
// server time). Everything else on the doc is server-only:
//   remindersSent     reminders sent in the current share cycle (0..2)
//   remindersCycleAt  the `lastSharedAt` that `remindersSent` counts for — a
//                     new share starts a new cycle without the client having
//                     to reset anything
//   lastReminderAt    when the last reminder went out
//   connectedAt       when the inviter got a partner (onRelationCreated)
//
// An hourly job sends reminder #1 at >= 24h and #2 at >= 72h after the last
// share, at most 2 per cycle, only between 10:00 and 21:00 in the inviter's
// own time zone, and never once they have a partner or deleted their account.
//
// Push data.type `invite_reminder` is new: builds that don't know it show the
// notification and open the app without routing (notificationOpenTargetFor's
// default), so it is safe for every build.
import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import type {PushCopy} from "./copy";
import {localParts, resolveTimeZone} from "./time";

export const INVITE_COLLECTION = "invites";
export const INVITE_REMINDER_TYPE = "invite_reminder";

const HOUR_MS = 60 * 60 * 1000;
/** Reminder #n is due this long after the last share. */
export const INVITE_REMINDER_AFTER_MS: readonly number[] = [24 * HOUR_MS, 72 * HOUR_MS];
export const MAX_INVITE_REMINDERS = INVITE_REMINDER_AFTER_MS.length;
/** Two reminders are never closer than this (e.g. #1 held back by the night). */
export const INVITE_REMINDER_MIN_GAP_MS = 24 * HOUR_MS;
/** Shares older than this are not reminded about (no backlog on first deploy). */
export const INVITE_REMINDER_WINDOW_MS = 7 * 24 * HOUR_MS;
/** Local sending window: [10:00, 21:00). */
export const INVITE_REMINDER_EARLIEST_MINUTE = 10 * 60;
export const INVITE_REMINDER_LATEST_MINUTE = 21 * 60;

type Data = admin.firestore.DocumentData;

/** The fields of an `invites` doc the selection needs, as epoch millis. */
export type InviteState = {
    inviterUid: string;
    lastSharedAtMs: number;
    remindersSent: number;
    remindersCycleAtMs: number;
    lastReminderAtMs: number;
    connectedAtMs: number;
};

/** What the selection needs of the inviter's user doc (null: no such user). */
export type InviterInfo = {timezone?: unknown; locale?: unknown} | null;

export type InviteReminderPick = {
    inviterUid: string;
    /** 1 or 2. */
    reminder: number;
    locale: "ko" | "en";
};

function millis(value: unknown): number {
    if (value instanceof Timestamp) return value.toMillis();
    if (value instanceof Date) return value.getTime();
    if (typeof value === "number" && Number.isFinite(value)) return value;
    const toMillis = (value as {toMillis?: unknown} | null)?.toMillis;
    if (typeof toMillis === "function") return Number(toMillis.call(value)) || 0;
    return 0;
}

/** Reads an `invites` doc; null when it can't be reminded about at all. */
export function inviteStateOf(id: string, data: Data | undefined | null): InviteState | null {
    if (!data) return null;
    const inviterUid = typeof data.inviterUid === "string" && data.inviterUid ? data.inviterUid : id;
    if (inviterUid !== id) return null;
    const lastSharedAtMs = millis(data.lastSharedAt);
    if (lastSharedAtMs <= 0) return null;
    const sent = Number(data.remindersSent);
    return {
        inviterUid,
        lastSharedAtMs,
        remindersSent: Number.isFinite(sent) && sent > 0 ? Math.floor(sent) : 0,
        remindersCycleAtMs: millis(data.remindersCycleAt),
        lastReminderAtMs: millis(data.lastReminderAt),
        connectedAtMs: millis(data.connectedAt),
    };
}

/** Reminders already sent for the current share (a new share resets to 0). */
export function remindersInCycle(invite: InviteState): number {
    return invite.remindersCycleAtMs === invite.lastSharedAtMs ? invite.remindersSent : 0;
}

/**
 * Which reminder (1 or 2) is due for [invite] at [nowMs], ignoring the local
 * time window; null when none is.
 */
export function dueReminder(invite: InviteState, nowMs: number): number | null {
    // Connected after the latest share: nothing to remind about.
    if (invite.connectedAtMs > 0 && invite.connectedAtMs >= invite.lastSharedAtMs) return null;
    const age = nowMs - invite.lastSharedAtMs;
    if (age > INVITE_REMINDER_WINDOW_MS) return null;
    const sent = remindersInCycle(invite);
    if (sent >= MAX_INVITE_REMINDERS) return null;
    if (age < INVITE_REMINDER_AFTER_MS[sent]) return null;
    if (sent > 0 && nowMs - invite.lastReminderAtMs < INVITE_REMINDER_MIN_GAP_MS) return null;
    return sent + 1;
}

/** Whether [now] is inside the sending window in [timeZone]. */
export function inReminderHours(now: Date, timeZone: unknown): boolean {
    const minutes = localParts(now, resolveTimeZone(timeZone)).minutes;
    return minutes >= INVITE_REMINDER_EARLIEST_MINUTE && minutes < INVITE_REMINDER_LATEST_MINUTE;
}

/** `users.locale` 'en' → English; anything else (or nothing) → Korean. */
export function reminderLocale(user: InviterInfo): "ko" | "en" {
    const locale = typeof user?.locale === "string" ? user.locale.trim().toLowerCase() : "";
    return locale === "en" || locale.startsWith("en-") || locale.startsWith("en_") ? "en" : "ko";
}

/**
 * The reminders to send now: invites whose next reminder is due, whose
 * inviter still exists, and for whom it is daytime. The partner check (a
 * query) comes after this, in the job.
 */
export function selectInviteReminders(
    invites: InviteState[],
    users: Map<string, InviterInfo>,
    now: Date,
): InviteReminderPick[] {
    const nowMs = now.getTime();
    const picks: InviteReminderPick[] = [];
    for (const invite of invites) {
        const reminder = dueReminder(invite, nowMs);
        if (reminder === null) continue;
        const user = users.get(invite.inviterUid) ?? null;
        if (!user) continue; // deleted account
        if (!inReminderHours(now, user.timezone)) continue;
        picks.push({inviterUid: invite.inviterUid, reminder, locale: reminderLocale(user)});
    }
    return picks;
}

/** The reminder's text (system voice: 해요체; no app name, no "{name}님"). */
export function inviteReminderCopy(reminder: number, locale: "ko" | "en"): PushCopy {
    if (locale === "en") {
        return reminder <= 1 ? {
            title: "💌 Your partner hasn't joined yet",
            body: "Want to send them the link one more time?",
        } : {
            title: "💌 Still waiting for your partner",
            body: "Workouts stick better with two. Send the invite link once more?",
        };
    }
    return reminder <= 1 ? {
        title: "💌 짝꿍이 아직 안 들어왔어요",
        body: "링크를 한 번 더 보내볼까요?",
    } : {
        title: "💌 짝꿍을 기다리고 있어요",
        body: "둘이 하면 더 오래 가요. 초대 링크를 한 번 더 보내볼까요?",
    };
}

// ---------------------------------------------------------------------------
// Firestore side
// ---------------------------------------------------------------------------

const db = (): admin.firestore.Firestore => admin.firestore();

function isNotFound(error: unknown): boolean {
    const code = (error as {code?: unknown})?.code;
    return code === 5 || code === "not-found";
}

/** True when [uid] is in any relation (짝꿍 link), either direction. */
async function hasPartner(uid: string): Promise<boolean> {
    const relations = db().collection("relations");
    const [asManager, asExecutor] = await Promise.all([
        relations.where("managerId", "==", uid).limit(1).get(),
        relations.where("executorId", "==", uid).limit(1).get(),
    ]);
    return !asManager.empty || !asExecutor.empty;
}

/** onRelationCreated: both people of a new link stop getting reminders. */
export async function markInvitesConnected(uids: string[]): Promise<void> {
    await Promise.all(uids.map(async (uid) => {
        try {
            await db().collection(INVITE_COLLECTION).doc(uid).update({connectedAt: FieldValue.serverTimestamp()});
        } catch (error) {
            if (!isNotFound(error)) throw error; // never shared an invite: nothing to mark
        }
    }));
}

/** Account deletion: the inviter's doc goes with them. */
export async function deleteInviteOf(uid: string): Promise<void> {
    await db().collection(INVITE_COLLECTION).doc(uid).delete();
}

/**
 * Counts reminder [reminder] on the doc, if it is still the one due (another
 * run or a new share may have changed it). Returns the fields to put back
 * should the send fail, or null when nothing was claimed.
 */
async function claimReminder(uid: string, reminder: number, nowMs: number): Promise<Data | null> {
    const ref = db().collection(INVITE_COLLECTION).doc(uid);
    return db().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const invite = inviteStateOf(uid, snap.data());
        if (!invite || dueReminder(invite, nowMs) !== reminder) return null;
        const data = snap.data() ?? {};
        tx.update(ref, {
            remindersSent: reminder,
            remindersCycleAt: Timestamp.fromMillis(invite.lastSharedAtMs),
            lastReminderAt: Timestamp.fromMillis(nowMs),
        });
        const restore = (field: string) => (field in data ? data[field] : FieldValue.delete());
        return {
            remindersSent: restore("remindersSent"),
            remindersCycleAt: restore("remindersCycleAt"),
            lastReminderAt: restore("lastReminderAt"),
        };
    });
}

/** The send helpers of index.ts, passed in so this module has no import cycle. */
export type InviteReminderDeps = {
    tokenOf: (uid: string, user: Data | null) => Promise<string | null>;
    send: (
        recipientUserId: string,
        fcmToken: string,
        copy: PushCopy,
        data: {[key: string]: string},
        recipient: Data | null,
    ) => Promise<boolean>;
};

/** Reads users docs in chunks (missing → absent from the map). */
async function usersOf(uids: string[]): Promise<Map<string, Data>> {
    const result = new Map<string, Data>();
    for (let i = 0; i < uids.length; i += 100) {
        const refs = uids.slice(i, i + 100).map((uid) => db().collection("users").doc(uid));
        const snaps = await db().getAll(...refs);
        snaps.forEach((snap) => {
            if (snap.exists) result.set(snap.id, snap.data() ?? {});
        });
    }
    return result;
}

export async function runInviteReminders(deps: InviteReminderDeps, now = new Date()): Promise<void> {
    const nowMs = now.getTime();
    const snap = await db()
        .collection(INVITE_COLLECTION)
        .where("lastSharedAt", ">=", Timestamp.fromMillis(nowMs - INVITE_REMINDER_WINDOW_MS))
        .get();
    const invites = snap.docs
        .map((doc) => inviteStateOf(doc.id, doc.data()))
        .filter((invite): invite is InviteState => invite !== null && dueReminder(invite, nowMs) !== null);
    const users = await usersOf(invites.map((invite) => invite.inviterUid));
    const picks = selectInviteReminders(invites, users, now);

    let sent = 0;
    let connected = 0;
    for (const pick of picks) {
        const uid = pick.inviterUid;
        try {
            if (await hasPartner(uid)) {
                // Linked without onRelationCreated marking it (or before this
                // feature): stop for this share.
                await markInvitesConnected([uid]);
                connected++;
                continue;
            }
            const user = users.get(uid) ?? null;
            const token = await deps.tokenOf(uid, user);
            if (!token) continue;
            const restore = await claimReminder(uid, pick.reminder, nowMs);
            if (!restore) continue;
            const delivered = await deps.send(uid, token, inviteReminderCopy(pick.reminder, pick.locale), {
                type: INVITE_REMINDER_TYPE,
                reminder: String(pick.reminder),
            }, user);
            if (delivered) {
                sent++;
            } else {
                // Not counted, so a later run tries again.
                await db().collection(INVITE_COLLECTION).doc(uid).update(restore).catch(() => undefined);
            }
        } catch (error) {
            console.error(`sendInviteReminders failed for ${uid}:`, error);
        }
    }
    console.log(`sendInviteReminders: ${snap.size} recent invites, ${invites.length} due, ` +
        `${picks.length} in daytime, ${sent} sent, ${connected} already connected`);
}

/** The hourly scheduled function (exported from index.ts). */
export function inviteReminderFunction(deps: InviteReminderDeps): functions.CloudFunction<unknown> {
    return functions
        .runWith({timeoutSeconds: 300})
        .pubsub.schedule("every 60 minutes")
        .timeZone("Asia/Seoul")
        .onRun(async () => {
            await runInviteReminders(deps);
        });
}
