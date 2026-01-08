import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onCheerCreated = functions.firestore
    .document("cheers/{cheerId}")
    .onCreate(async (snapshot, context) => {
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
    .onCreate(async (snapshot, context) => {
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
        if (!action || action.type !== "done") return;

        const userId = action.userId;
        const planId = action.planId;

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

            // 4. 메시지 페이로드 구성
            const messagePayload: admin.messaging.Message = {
                notification: {
                    title: "약속 실천 완료! 🌟",
                    body: `${senderName}님이 약속을 실천했어요! 확인하고 칭찬해 주세요.`,
                },
                data: {
                    type: "action_completed",
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
            console.log(`Successfully sent completion notification to ${managerId}`);
        } catch (error) {
            console.error("Error sending completion notification:", error);
        }
    });

export const onPlanUpdated = functions.firestore
    .document("plans/{planId}")
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        if (!before || !after) return;

        // 단순 상태 메시지나 응원 정보 업데이트는 제외 (중요한 변경만 감지)
        const isImportantChange =
            JSON.stringify(before.items) !== JSON.stringify(after.items) ||
            before.startDate?.seconds !== after.startDate?.seconds ||
            before.endDate?.seconds !== after.endDate?.seconds;

        if (!isImportantChange) return;

        const userId = after.userId;
        const managerId = after.managerId;
        if (!managerId) return;

        try {
            // 여기서는 일단 계획 생성자(userId)가 수정했다고 가정하고 매니저에게 알림
            // (추후 매니저가 수정할 경우 로직 분기 필요)
            const managerDoc = await admin.firestore().collection("users").doc(managerId).get();
            const fcmToken = managerDoc.data()?.fcmToken;
            if (!fcmToken) return;

            const userDoc = await admin.firestore().collection("users").doc(userId).get();
            const senderName = userDoc.exists ? userDoc.data()?.displayName || "파트너" : "파트너";

            const messagePayload: admin.messaging.Message = {
                notification: {
                    title: "약속 내용이 변경되었어요 📝",
                    body: `${senderName}님이 약속 내용을 변경했어요. 확인해 보세요!`,
                },
                data: {
                    type: "plan_updated",
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
            console.log(`Successfully sent update notification to ${managerId}`);
        } catch (error) {
            console.error("Error sending update notification:", error);
        }
    });
