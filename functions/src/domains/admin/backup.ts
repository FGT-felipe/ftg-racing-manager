/**
 * Daily JSON backup of critical Firestore collections to Cloud Storage.
 *
 * Schedule: 03:00 COT (08:00 UTC) every day.
 * Bucket:   gs://ftg-racing-manager.firebasestorage.app
 * Path:     backups/YYYY-MM-DD/{collection}.json
 * Retention: 8 days — older folders are deleted automatically at the start of each run.
 *
 * Uses firebase-admin storage (no extra dependencies).
 * The Cloud Functions service account has implicit write access to the
 * project's default Firebase Storage bucket — no manual IAM setup required.
 */

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";

const BACKUP_BUCKET = "ftg-racing-manager.firebasestorage.app";
const BACKUP_COLLECTIONS = ["races", "teams", "seasons", "drivers"];
const BACKUP_RETENTION_DAYS = 8;

/**
 * Reads all documents in a Firestore collection.
 * Timestamps are preserved as { _seconds, _nanoseconds } — sufficient for disaster recovery.
 * @param collectionName Name of the top-level Firestore collection.
 * @returns Array of plain objects, each with an added `id` field.
 */
async function backupCollection(collectionName: string): Promise<object[]> {
  const snap = await db.collection(collectionName).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

/**
 * Writes one JSON file per collection to Cloud Storage under backups/YYYY-MM-DD/.
 * Then deletes any backup folders whose date is older than BACKUP_RETENTION_DAYS.
 */
export async function runDailyBackup(): Promise<void> {
  const bucket = admin.storage().bucket(BACKUP_BUCKET);
  const today = new Date().toISOString().split("T")[0]; // "YYYY-MM-DD"

  // 1. Write today's snapshot
  for (const collName of BACKUP_COLLECTIONS) {
    const docs = await backupCollection(collName);
    const json = JSON.stringify(docs, null, 2);
    const filePath = `backups/${today}/${collName}.json`;
    const file = bucket.file(filePath);
    await file.save(json, { contentType: "application/json" });
    logger.info(`[dailyBackup] Wrote ${filePath} (${docs.length} docs)`);
  }

  // 2. Delete backups older than BACKUP_RETENTION_DAYS
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - BACKUP_RETENTION_DAYS);

  const [files] = await bucket.getFiles({ prefix: "backups/" });
  for (const file of files) {
    const match = file.name.match(/^backups\/(\d{4}-\d{2}-\d{2})\//);
    if (!match) continue;
    const fileDate = new Date(match[1]);
    if (fileDate < cutoff) {
      await file.delete();
      logger.info(`[dailyBackup] Deleted expired backup: ${file.name}`);
    }
  }

  logger.info(`[dailyBackup] Completed for ${today}. Retention: last ${BACKUP_RETENTION_DAYS} days.`);
}

/**
 * Scheduled daily backup — 03:00 COT (08:00 UTC).
 * Backs up races, teams, seasons, drivers to Cloud Storage.
 * Retention: 8 days (auto-deletes older folders).
 */
export const scheduledDailyBackup = onSchedule({
  schedule: "0 3 * * *",
  timeZone: "America/Bogota",
  region: "us-central1",
}, async () => {
  try {
    await runDailyBackup();
  } catch (err) {
    logger.error("[dailyBackup] Backup failed:", err);
    throw err;
  }
});
