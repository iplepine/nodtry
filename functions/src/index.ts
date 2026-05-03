import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

const KST_OFFSET_MS = 9 * 60 * 60 * 1000;
const MISSED_ACTION_GRACE_MINUTES = 30;

type KstDateParts = {
    year: number;
    month: number;
    day: number;
    weekday: number;
    minutes: number;
};

type PlanItemData = {
    title?: string;
    days?: number[];
    notificationTime?: {
        type?: string;
        hour?: number;
        minute?: number;
    };
};

function buildMessagePayload(
    token: string,
    title: string,
    body: string,
    data: {[key: string]: string},
): admin.messaging.Message {
    return {
        token,
        data: {
            ...data,
            title,
            body,
        },
        android: {
            priority: "high",
        },
        apns: {
            headers: {
                "apns-priority": "5",
                "apns-push-type": "background",
            },
            payload: {
                aps: {
                    contentAvailable: true,
                },
            },
        },
    };
}

function toKstParts(date: Date): KstDateParts {
    const shifted = new Date(date.getTime() + KST_OFFSET_MS);
    const jsDay = shifted.getUTCDay();
    const weekday = jsDay === 0 ? 7 : jsDay;
    return {
        year: shifted.getUTCFullYear(),
        month: shifted.getUTCMonth() + 1,
        day: shifted.getUTCDate(),
        weekday,
        minutes: shifted.getUTCHours() * 60 + shifted.getUTCMinutes(),
    };
}

function isSameKstDay(value: admin.firestore.Timestamp | undefined, target: KstDateParts): boolean {
    if (!value) return false;
    const parts = toKstParts(value.toDate());
    return parts.year === target.year &&
        parts.month === target.month &&
        parts.day === target.day;
}

function isBeforeKstDay(value: admin.firestore.Timestamp | undefined, target: KstDateParts): boolean {
    if (!value) return false;
    const parts = toKstParts(value.toDate());
    if (parts.year !== target.year) return parts.year < target.year;
    if (parts.month !== target.month) return parts.month < target.month;
    return parts.day < target.day;
}

function isAfterKstDay(value: admin.firestore.Timestamp | undefined, target: KstDateParts): boolean {
    if (!value) return false;
    const parts = toKstParts(value.toDate());
    if (parts.year !== target.year) return parts.year > target.year;
    if (parts.month !== target.month) return parts.month > target.month;
    return parts.day > target.day;
}

function hasCoveredToday(plan: admin.firestore.DocumentData, today: KstDateParts): boolean {
    const fields = ["completedDates", "skippedDates", "restedDates", "rescuedDates"];
    return fields.some((field) => {
        const values = plan[field] as admin.firestore.Timestamp[] | undefined;
        return values?.some((value) => isSameKstDay(value, today)) ?? false;
    });
}

function dueItemForMissedNotice(plan: admin.firestore.DocumentData, today: KstDateParts): PlanItemData | null {
    const items = (plan.items ?? []) as PlanItemData[];
    const dueItems = items.filter((item) => {
        const notificationTime = item.notificationTime;
        if (!item.days?.includes(today.weekday)) return false;
        if (!notificationTime || notificationTime.type === "none") return false;

        const hour = notificationTime.hour ?? 23;
        const minute = notificationTime.minute ?? 59;
        const dueMinutes = hour * 60 + minute + MISSED_ACTION_GRACE_MINUTES;
        return today.minutes >= dueMinutes;
    });

    dueItems.sort((a, b) => {
        const aTime = a.notificationTime;
        const bTime = b.notificationTime;
        const aMinutes = (aTime?.hour ?? 23) * 60 + (aTime?.minute ?? 59);
        const bMinutes = (bTime?.hour ?? 23) * 60 + (bTime?.minute ?? 59);
        return bMinutes - aMinutes;
    });

    return dueItems[0] ?? null;
}

export const onCheerCreated = functions.firestore
    .document("cheers/{cheerId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        const cheer = snapshot.data();
        if (!cheer) return;

        const toUserId = cheer.toUserId;
        const fromUserId = cheer.fromUserId;
        const message = cheer.message;
        // reactionType might be used for constructing body or data
        // const reactionType = cheer.reactionType;

        try {
            // 1. Get Target User's FCM Token
            const userDoc = await admin.firestore().collection("users").doc(toUserId).get();
            if (!userDoc.exists) {
                console.log(`User ${toUserId} not found`);
                return;
            }

            const userData = userDoc.data();
            const fcmToken = userData?.fcmToken;

            if (!fcmToken) {
                console.log(`User ${toUserId} has no FCM token`);
                return;
            }

            // 2. Get Sender's Name (Optional, for better notification)
            let senderName = "친구";
            const senderDoc = await admin.firestore().collection("users").doc(fromUserId).get();
            if (senderDoc.exists) {
                senderName = senderDoc.data()?.displayName || "친구";
            }

            // 3. Construct Message
            const title = "응원이 도착했어요! 🎉";
            const body = message ? `${senderName}: ${message}` : `${senderName}님이 응원을 보냈어요!`;
            const messagePayload = buildMessagePayload(
                fcmToken,
                title,
                body,
                {
                    type: "cheer",
                    planId: cheer.planId || "",
                    senderName,
                    message: message || "",
                },
            );

            // 4. Send Message
            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent message to ${toUserId}`);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });

export const onPlanCreated = functions.firestore
    .document("plans/{planId}")
    .onCreate(async (snapshot: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
        const plan = snapshot.data();
        if (!plan) return;

        const managerId = plan.managerId;
        const userId = plan.userId;

        // managerId가 없으면 보낼 대상이 없음 (혼자 하는 계획 등)
        if (!managerId) return;

        try {
            // 1. 수신자(Manager)의 FCM 토큰 조회
            const managerDoc = await admin.firestore().collection("users").doc(managerId).get();
            if (!managerDoc.exists) {
                console.log(`Manager ${managerId} not found`);
                return;
            }

            const fcmToken = managerDoc.data()?.fcmToken;
            if (!fcmToken) {
                console.log(`Manager ${managerId} has no FCM token`);
                return;
            }

            // 2. 발신자(User)의 이름 조회
            let senderName = "친구";
            const senderDoc = await admin.firestore().collection("users").doc(userId).get();
            if (senderDoc.exists) {
                senderName = senderDoc.data()?.displayName || "친구";
            }

            // 3. 메시지 페이로드 구성
            const title = "새로운 약속 제안이 있어요 💌";
            const body = `${senderName}님이 새로운 약속을 함께하자고 제안했어요.`;
            const messagePayload = buildMessagePayload(
                fcmToken,
                title,
                body,
                {
                    type: "plan_proposed",
                    planId: context.params.planId,
                    senderName,
                    userId,
                },
            );

            // 4. 메시지 전송
            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent plan notification to ${managerId}`);
        } catch (error) {
            console.error("Error sending plan notification:", error);
        }
    });

export const onActionCompleted = functions.firestore
    .document("actions/{actionId}")
    .onCreate(async (snapshot, context) => {
        const action = snapshot.data();
        if (!action) return;

        const userId = action.userId;
        const planId = action.planId;
        const type = action.type;

        try {
            // 1. 해당 계획의 매니저 ID 찾기
            const planDoc = await admin.firestore().collection("plans").doc(planId).get();
            if (!planDoc.exists) return;
            const managerId = planDoc.data()?.managerId;
            if (!managerId) return;

            // 2. 매니저의 FCM 토큰 조회
            const managerDoc = await admin.firestore().collection("users").doc(managerId).get();
            if (!managerDoc.exists) return;
            const fcmToken = managerDoc.data()?.fcmToken;
            if (!fcmToken) return;

            // 3. 발신자(수행자) 이름 조회
            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            const senderName = userDoc.exists ? userDoc.data()?.displayName || "파트너" : "파트너";

            // 4. 메시지 구성 (행동 타입에 따라)
            let title = "약속 실천 완료! 🌟";
            let body = `${senderName}님이 약속을 실천했어요! 확인하고 칭찬해 주세요.`;

            if (type === "skipped") {
                title = "약속을 건너뛰었어요 ↩️";
                body = `${senderName}님이 오늘 약속은 건너뛰기로 했어요.`;
            } else if (type === "rested") {
                title = "오늘은 쉬어갈게요 🌿";
                body = `${senderName}님이 오늘 약속은 쉬어가기로 했어요.`;
            }

            const messagePayload = buildMessagePayload(
                fcmToken,
                title,
                body,
                {
                    type: "action_completed",
                    actionType: type || "",
                    planId: planId,
                    senderName,
                    userId,
                },
            );

            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent action notification (${type}) to ${managerId}`);
        } catch (error) {
            console.error("Error sending completion notification:", error);
        }
    });

export const notifyMissedActions = functions.pubsub
    .schedule("every 30 minutes")
    .timeZone("Asia/Seoul")
    .onRun(async () => {
        const today = toKstParts(new Date());
        const plansSnapshot = await admin.firestore()
            .collection("plans")
            .where("state", "==", "active")
            .get();

        let sentCount = 0;
        for (const planDoc of plansSnapshot.docs) {
            const plan = planDoc.data();
            const userId = plan.userId as string | undefined;
            const managerId = plan.managerId as string | undefined;
            if (!userId || !managerId) continue;

            const startDate = plan.startDate as admin.firestore.Timestamp | undefined;
            const endDate = plan.endDate as admin.firestore.Timestamp | undefined;
            if (isAfterKstDay(startDate, today) || isBeforeKstDay(endDate, today)) continue;
            if (hasCoveredToday(plan, today)) continue;

            const lastMissedNotifiedAt = plan.lastMissedNotifiedAt as admin.firestore.Timestamp | undefined;
            if (isSameKstDay(lastMissedNotifiedAt, today)) continue;

            const dueItem = dueItemForMissedNotice(plan, today);
            if (!dueItem) continue;

            const managerDoc = await admin.firestore().collection("users").doc(managerId).get();
            const fcmToken = managerDoc.data()?.fcmToken;
            if (!fcmToken) continue;

            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            const senderName = userDoc.exists ? userDoc.data()?.displayName || "파트너" : "파트너";
            const itemTitle = dueItem.title || "오늘 약속";

            const title = "약속 시간이 지났어요";
            const body = `${senderName}님이 아직 '${itemTitle}' 약속을 처리하지 않았어요. 한 번 물어봐 주세요.`;

            await planDoc.ref.update({
                lastMissedNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
                lastMissedItemTitle: itemTitle,
                lastUpdatedBy: "system_missed_action",
            });

            await admin.messaging().send(buildMessagePayload(
                fcmToken,
                title,
                body,
                {
                    type: "action_missed",
                    planId: planDoc.id,
                    userId,
                    senderName,
                    itemTitle,
                },
            ));
            sentCount++;
        }

        console.log(`notifyMissedActions sent ${sentCount} missed action notifications`);
    });

export const onPlanUpdated = functions.firestore
    .document("plans/{planId}")
    .onUpdate(async (change: functions.Change<functions.firestore.QueryDocumentSnapshot>, context: functions.EventContext) => {
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return;

        const userId = after.userId;
        const managerId = after.managerId;
        const lastUpdatedBy = after.lastUpdatedBy;

        // 알림을 보낼 대상 (수정한 사람이 아닌 다른 사람)
        const toUserId = (lastUpdatedBy === userId) ? managerId : userId;
        if (!toUserId) return;

        try {
            // 1. 수신자 FCM 토큰 조회
            const targetUserDoc = await admin.firestore().collection("users").doc(toUserId).get();
            const fcmToken = targetUserDoc.data()?.fcmToken;
            if (!fcmToken) return;

            // 2. 발신자 이름 조회
            let senderName = "파트너";
            if (lastUpdatedBy) {
                const senderDoc = await admin.firestore().collection("users").doc(lastUpdatedBy).get();
                senderName = senderDoc.exists ? senderDoc.data()?.displayName || "파트너" : "파트너";
            }

            // 3. 변경 내용 분석 및 알림 내용 구성
            let title = "";
            let body = "";
            let type = "plan_updated";

            const hasNewPoke =
                after.lastPokeAt?.seconds !== before.lastPokeAt?.seconds ||
                (after.lastCheerType === "poke" && before.lastCheerType !== "poke");

            // A. 찌르기 (Poke) 감지
            if (hasNewPoke) {
                title = "똑똑! ✊";
                body = after.lastPokeMessage ||
                    after.lastCheerMessage ||
                    `${senderName}님이 똑똑! 신호를 보냈어요.`;
                type = "poke";
            }
            // B. 계획 승인 감지
            else if (after.state === "active" && before.state === "pending_approval") {
                title = "약속이 승인되었어요! ✨";
                body = `${senderName}님이 약속을 승인했어요. 이제 함께 시작해 봐요!`;
                type = "plan_approved";
            }
            // C. 계획 반려 감지
            else if (after.state === "rejected" && before.state === "pending_approval") {
                title = "약속 조율이 필요해요 🤝";
                body = after.lastComment ? `${senderName}: ${after.lastComment}` : `${senderName}님이 약속 조율을 요청했어요.`;
                type = "plan_rejected";
            }
            // D. 실천 확인 감지 (Manager verified User's action)
            else if ((after.verifiedDates?.length || 0) > (before.verifiedDates?.length || 0)) {
                if (lastUpdatedBy === managerId) { // 매니저가 확인했을 때만 실행자에게 알림
                    title = "약속 실천 확인! ✅";
                    body = `${senderName}님이 오늘의 실천을 확인했어요. 잘하셨어요!`;
                    type = "action_verified";
                } else return;
            }
            // E. 일반적인 중요 변경사항 (아이템, 기간 등)
            else {
                const isImportantChange =
                    JSON.stringify(before.items) !== JSON.stringify(after.items) ||
                    before.startDate?.seconds !== after.startDate?.seconds ||
                    before.endDate?.seconds !== after.endDate?.seconds;

                if (isImportantChange) {
                    title = "약속 내용이 변경되었어요 📝";
                    body = `${senderName}님이 약속 내용을 변경했어요. 확인해 보세요!`;
                    type = "plan_updated";
                } else {
                    return; // 알림 보낼 만큼 중요한 변경이 아님
                }
            }

            const messagePayload = buildMessagePayload(
                fcmToken,
                title,
                body,
                {
                    type: type,
                    planId: context.params.planId,
                    senderName,
                    lastComment: after.lastComment || "",
                    lastCheerMessage: after.lastCheerMessage || "",
                },
            );

            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent ${type} notification to ${toUserId}`);
        } catch (error) {
            console.error("Error sending update notification:", error);
        }
    });
