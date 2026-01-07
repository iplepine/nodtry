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

            // 3. Construct Payload
            const payload: admin.messaging.MessagingPayload = {
                notification: {
                    title: "응원이 도착했어요! 🎉",
                    body: message ? `${senderName}: ${message}` : `${senderName}님이 응원을 보냈어요!`,
                    sound: "default",
                    badge: "1",
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    type: "cheer",
                    planId: cheer.planId,
                },
            };

            // 4. Send Message
            await admin.messaging().sendToDevice(fcmToken, payload);
            console.log(`Successfully sent message to ${toUserId}`);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });
