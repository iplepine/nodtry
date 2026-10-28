// FCM message building, kept free of Firestore so it can be unit-tested.
import type * as admin from "firebase-admin";

/**
 * First build that draws data-only partner pushes itself, with action
 * buttons (Android), and handles the buttons of a push (both platforms).
 */
export const NOTIFICATION_ACTIONS_BUILD = 86;

/**
 * The notification category (action buttons) of a push, or null for none.
 * The names are a contract with the app (`kQuickActionCategories`).
 */
export function quickActionCategory(data: {[key: string]: string}): string | null {
    switch (data.type) {
    case "action_completed":
        // 인정 is for a workout, not for a skip or a rest.
        return data.actionType === "done" ? "partner_proof" : null;
    case "poke":
        return data.planId ? "poke_reply" : null;
    case "action_missed":
        // Today's miss only: yesterday's is answered from 기록.
        return data.day ? null : "partner_missed";
    default:
        return null;
    }
}

export type MessageOptions = {
    /** iOS `aps.category` and `data.category`: the push's buttons. */
    category?: string | null;
    /**
     * Leave out the shared/Android `notification` so the app draws the push
     * itself (with its buttons). iOS still gets the alert from `aps`.
     */
    dataOnly?: boolean;
};

export function buildMessagePayload(
    token: string,
    title: string,
    body: string,
    data: {[key: string]: string},
    options: MessageOptions = {},
): admin.messaging.Message {
    const category = options.category ?? null;
    const message: admin.messaging.Message = {
        token,
        data: {
            ...data,
            title,
            body,
            ...(category ? {category} : {}),
        },
        android: options.dataOnly ? {
            priority: "high",
        } : {
            priority: "high",
            notification: {
                channelId: "general_notifications",
                sound: "default",
            },
        },
        apns: {
            headers: {
                "apns-priority": "10",
                "apns-push-type": "alert",
            },
            payload: {
                aps: {
                    alert: {
                        title,
                        body,
                    },
                    sound: "default",
                    ...(category ? {category} : {}),
                },
            },
        },
    };
    if (!options.dataOnly) message.notification = {title, body};
    return message;
}
