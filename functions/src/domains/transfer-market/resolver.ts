/**
 * Transfer market resolver — runs hourly.
 * Extracted from resolveTransferMarket in functions/index.js (lines 2349–2464).
 *
 * Finds drivers listed for transfer ≥24h. Processes bids:
 *  - If bid exists: transfers driver to winning team, credits seller.
 *  - If no bid: delist driver; if no team, delete the driver document.
 */

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";
import { addOfficeNews } from "../../shared/notifications";

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Resolves all expired transfer market listings.
 * Separated from the scheduler for emergency script invocation.
 */
export async function runTransferMarketResolver(): Promise<void> {
  logger.info("=== TRANSFER MARKET RESOLVER START ===");
  try {
    const now = admin.firestore.Timestamp.now();
    const yesterday = new Date(now.toDate().getTime() - 24 * 60 * 60 * 1000);
    const yesterdayTs = admin.firestore.Timestamp.fromDate(yesterday);

    const snapshot = await db
      .collection("drivers")
      .where("isTransferListed", "==", true)
      .where("transferListedAt", "<=", yesterdayTs)
      .get();

    if (snapshot.empty) {
      logger.info("No expired transfer listings found.");
      return;
    }

    const batches: Promise<FirebaseFirestore.WriteResult[]>[] = [];
    let currentBatch = db.batch();
    let opCount = 0;

    for (const doc of snapshot.docs) {
      const driver = doc.data() as Record<string, unknown>;
      const highestBid = (driver["currentHighestBid"] as number) || 0;
      const highestBidderId = driver["highestBidderTeamId"] as string | undefined;
      const originalTeamId = driver["teamId"] as string | undefined;

      if (highestBid > 0 && highestBidderId) {
        // ── Driver sold ──
        currentBatch.update(doc.ref, {
          isTransferListed: false,
          transferListedAt: admin.firestore.FieldValue.delete(),
          currentHighestBid: admin.firestore.FieldValue.delete(),
          highestBidderTeamId: admin.firestore.FieldValue.delete(),
          teamId: highestBidderId,
          salary: Math.max((driver["salary"] as number) || 10_000, 10_000),
          contractYearsRemaining: 1,
        });
        opCount++;

        if (originalTeamId) {
          currentBatch.update(db.collection("teams").doc(originalTeamId), {
            budget: admin.firestore.FieldValue.increment(highestBid),
          });
          opCount++;

          await addOfficeNews(originalTeamId, {
            title: "Driver Sold",
            message: `${driver["name"]} was successfully sold in the transfer market for $${(highestBid as number).toLocaleString()}.`,
            type: "TRANSFER_SOLD",
          });
        }

        await addOfficeNews(highestBidderId, {
          title: "Transfer Bid Won",
          message: `You won the bid for ${driver["name"]} for $${(highestBid as number).toLocaleString()}! They have joined your team.`,
          type: "TRANSFER_WON",
        });
      } else {
        // ── Driver unsold ──
        if (originalTeamId) {
          currentBatch.update(doc.ref, {
            isTransferListed: false,
            transferListedAt: admin.firestore.FieldValue.delete(),
            currentHighestBid: admin.firestore.FieldValue.delete(),
            highestBidderTeamId: admin.firestore.FieldValue.delete(),
          });
          opCount++;

          await addOfficeNews(originalTeamId, {
            title: "Driver Unsold",
            message: `Nobody bid on ${driver["name"]} in the transfer market. They remain in your team.`,
            type: "TRANSFER_UNSOLD",
          });
        } else {
          // Admin-generated driver with no team — delete to keep pool clean
          currentBatch.delete(doc.ref);
          opCount++;
        }
      }

      if (opCount >= 400) {
        batches.push(currentBatch.commit());
        currentBatch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);
    logger.info(`=== TRANSFER MARKET RESOLVER COMPLETE. Batches: ${batches.length} ===`);
  } catch (error) {
    logger.error("Error in resolveTransferMarket:", error);
  }
}

// ─── Scheduled export ─────────────────────────────────────────────────────────

/** Scheduled transfer market resolver — every hour. */
export const resolveTransferMarket = onSchedule({
  schedule: "0 * * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  await runTransferMarketResolver();
});
