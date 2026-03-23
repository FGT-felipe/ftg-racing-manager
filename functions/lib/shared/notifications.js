"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addOfficeNews = addOfficeNews;
/**
 * Notification helpers for sending in-game messages to teams.
 * Note: addPressNews() is intentionally excluded — it is dead code (commented out in index.js).
 */
const admin_1 = require("./admin");
/**
 * Sends an office news notification to a specific team.
 * Writes to two subcollections atomically via batch:
 *  - teams/{teamId}/news        (Office facility feed)
 *  - teams/{teamId}/notifications (Dashboard / store notifications)
 *
 * @param teamId The target team's document ID.
 * @param data   The notification payload.
 */
async function addOfficeNews(teamId, data) {
    const batch = admin_1.db.batch();
    const newsRef = admin_1.db.collection("teams").doc(teamId).collection("news").doc();
    batch.set(newsRef, {
        ...data,
        teamId,
        isRead: false,
        timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
    });
    const notifRef = admin_1.db.collection("teams").doc(teamId).collection("notifications").doc();
    batch.set(notifRef, {
        ...data,
        isRead: false,
        timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
}
