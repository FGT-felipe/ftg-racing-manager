/**
 * Daily fitness recovery scheduler.
 * Extracted from scheduledDailyFitnessRecovery in functions/index.js (lines 2287–2344).
 *
 * Runs at midnight COT every day. Increments every driver's fitness by +1.5
 * (capped at 100). Uses chunked batches to respect Firestore's 500-op limit.
 */

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../../shared/admin";

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Recovers fitness for all drivers by +1.5 per day (max 100).
 * Separated from the scheduler for emergency script invocation.
 */
export async function runDailyFitnessRecovery(): Promise<void> {
  logger.info("=== DAILY FITNESS RECOVERY START ===");
  try {
    const snapshot = await db.collection("drivers").get();

    if (snapshot.empty) {
      logger.info("No drivers found. Skipping.");
      return;
    }

    const batches: Promise<FirebaseFirestore.WriteResult[]>[] = [];
    let currentBatch = db.batch();
    let opCount = 0;

    snapshot.docs.forEach((doc) => {
      const driver = doc.data() as Record<string, unknown>;
      const stats = (driver["stats"] as Record<string, number>) ?? {};
      const currentFitness = stats["fitness"] || 50;

      if (currentFitness < 100) {
        const newFitness = Math.min(100, currentFitness + 1.5);
        currentBatch.update(doc.ref, { "stats.fitness": newFitness });
        opCount++;

        if (opCount === 500) {
          batches.push(currentBatch.commit());
          currentBatch = db.batch();
          opCount = 0;
        }
      }
    });

    if (opCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);
    logger.info(`=== DAILY FITNESS RECOVERY COMPLETE. Batches: ${batches.length} ===`);
  } catch (error) {
    logger.error("Error in scheduledDailyFitnessRecovery:", error);
  }
}

// ─── Scheduled export ─────────────────────────────────────────────────────────

/** Scheduled fitness recovery — midnight COT every day. */
export const scheduledDailyFitnessRecovery = onSchedule({
  schedule: "0 0 * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  await runDailyFitnessRecovery();
});
