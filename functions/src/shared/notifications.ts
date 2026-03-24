/**
 * Notification helpers for sending in-game messages to teams.
 * Note: addPressNews() is intentionally excluded — it is dead code (commented out in index.js).
 */
import { db, admin } from "./admin";
import type { NewsEntry } from "./types";

/**
 * Sends an office news notification to a specific team.
 * Writes to two subcollections atomically via batch:
 *  - teams/{teamId}/news        (Office facility feed)
 *  - teams/{teamId}/notifications (Dashboard / store notifications)
 *
 * @param teamId The target team's document ID.
 * @param data   The notification payload.
 */
export async function addOfficeNews(teamId: string, data: NewsEntry): Promise<void> {
  const batch = db.batch();

  const newsRef = db.collection("teams").doc(teamId).collection("news").doc();
  batch.set(newsRef, {
    ...data,
    teamId,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  const notifRef = db.collection("teams").doc(teamId).collection("notifications").doc();
  batch.set(notifRef, {
    ...data,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();
}
