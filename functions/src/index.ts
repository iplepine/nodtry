import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";

admin.initializeApp();

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
            const messagePayload: admin.messaging.Message = {
                notification: {
                    title: "응원이 도착했어요! 🎉",
                    body: message ? `${senderName}: ${message}` : `${senderName}님이 응원을 보냈어요!`,
                },
                data: {
                    type: "cheer",
                    planId: cheer.planId || "",
                },
                token: fcmToken,
                android: {
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

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
            const messagePayload: admin.messaging.Message = {
                notification: {
                    title: "새로운 약속 제안이 있어요 💌",
                    body: `${senderName}님이 새로운 약속을 함께하자고 제안했어요.`,
                },
                data: {
                    type: "plan_proposed",
                    planId: context.params.planId,
                },
                token: fcmToken,
                android: {
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

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

            const messagePayload: admin.messaging.Message = {
                notification: { title, body },
                data: {
                    type: "action_completed",
                    actionType: type || "",
                    planId: planId,
                },
                token: fcmToken,
                android: {
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent action notification (${type}) to ${managerId}`);
        } catch (error) {
            console.error("Error sending completion notification:", error);
        }
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

            // A. 찌르기 (Poke) 감지
            if (after.lastCheerType === "poke" && before.lastCheerType !== "poke") {
                title = "똑똑! ✊";
                body = after.lastCheerMessage || `${senderName}님이 똑똑! 신호를 보냈어요.`;
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

            const messagePayload: admin.messaging.Message = {
                notification: { title, body },
                data: {
                    type: type,
                    planId: context.params.planId,
                },
                token: fcmToken,
                android: {
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        sound: "default",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: "default",
                            badge: 1,
                        },
                    },
                },
            };

            await admin.messaging().send(messagePayload);
            console.log(`Successfully sent ${type} notification to ${toUserId}`);
        } catch (error) {
            console.error("Error sending update notification:", error);
        }
    });
