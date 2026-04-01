/**
 * Transfer market resolver — runs hourly.
 *
 * T-028 Flow:
 * Finds drivers listed for transfer ≥24h. For each expired listing:
 *  - Finds the winner: the team with the highest bidAmount in pendingContracts
 *    that has status === 'accepted'. Teams that never negotiated or were rejected
 *    are skipped (Option A — commission lost, no transfer).
 *  - Executes the transfer using the winner's stored contract terms
 *    (role, replacedDriverId, salary, years).
 *  - Deducts the bid amount from winner's budget, credits seller.
 *  - Releases the replaced driver to free agent + auto-lists on market.
 *  - If no team has an accepted contract: driver is delisted normally.
 */

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";
import { addOfficeNews } from "../../shared/notifications";

// ─── Types ────────────────────────────────────────────────────────────────────

interface PendingContract {
  bidAmount: number;
  role: "main" | "secondary" | "equal";
  replacedDriverId: string;
  salary: number;
  years: number;
  status: "accepted" | "rejected";
}

// ─── Universe sync helper ─────────────────────────────────────────────────────

/**
 * Updates the universe/game_universe_v1 document after a transfer.
 * - If the driver already exists in a league.drivers[], updates their teamId.
 * - If not found and newTeamId belongs to a league, adds the driver entry.
 *
 * @param driverId     Firestore driver document ID.
 * @param driverData   Full driver data snapshot.
 * @param newTeamId    The team the driver now belongs to.
 */
async function syncDriverInUniverse(
  driverId: string,
  driverData: Record<string, unknown>,
  newTeamId: string
): Promise<void> {
  const uRef = db.collection("universe").doc("game_universe_v1");
  const uDoc = await uRef.get();
  if (!uDoc.exists) return;

  const uData = uDoc.data()!;
  const leagues: any[] = uData.leagues || [];

  let targetLeagueIdx = -1;
  for (let li = 0; li < leagues.length; li++) {
    const teamIds = (leagues[li].teams || []).map((t: any) => t.id);
    if (newTeamId && teamIds.includes(newTeamId)) {
      targetLeagueIdx = li;
      break;
    }
  }

  let updated = false;
  for (let li = 0; li < leagues.length; li++) {
    const di = (leagues[li].drivers || []).findIndex((d: any) => d.id === driverId);
    if (di !== -1) {
      leagues[li].drivers[di].teamId = newTeamId || "";
      updated = true;
      break;
    }
  }

  if (!updated && targetLeagueIdx !== -1) {
    leagues[targetLeagueIdx].drivers.push({
      id:               driverId,
      name:             driverData["name"] || "",
      teamId:           newTeamId,
      gender:           (driverData["gender"] as string) || "male",
      countryCode:      (driverData["countryCode"] as string) || "",
      points:           (driverData["points"] as number) || 0,
      seasonPoints:     (driverData["seasonPoints"] as number) || 0,
      wins:             (driverData["wins"] as number) || 0,
      seasonWins:       (driverData["seasonWins"] as number) || 0,
      podiums:          (driverData["podiums"] as number) || 0,
      seasonPodiums:    (driverData["seasonPodiums"] as number) || 0,
      races:            (driverData["races"] as number) || 0,
      seasonRaces:      (driverData["seasonRaces"] as number) || 0,
      championships:    (driverData["championships"] as number) || 0,
      championshipForm: (driverData["championshipForm"] as unknown[]) || [],
      careerHistory:    (driverData["careerHistory"] as unknown[]) || [],
    });
  }

  await uRef.update({ leagues });
}

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Resolves all expired transfer market listings.
 * Separated from the scheduler for emergency script invocation.
 */
export async function runTransferMarketResolver(): Promise<void> {
  logger.info("=== TRANSFER MARKET RESOLVER START (T-028) ===");
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

    for (const docSnap of snapshot.docs) {
      const driver = docSnap.data() as Record<string, unknown>;
      const originalTeamId = driver["teamId"] as string | undefined;

      // ── Find winning team: highest accepted contract ───────────────────────
      const pendingContracts = (driver["pendingContracts"] ?? {}) as Record<string, PendingContract>;
      let winnerTeamId: string | null = null;
      let winnerContract: PendingContract | null = null;

      for (const [teamId, contract] of Object.entries(pendingContracts)) {
        if (contract.status !== "accepted") continue;
        if (!winnerContract || contract.bidAmount > winnerContract.bidAmount) {
          winnerTeamId = teamId;
          winnerContract = contract;
        }
      }

      if (winnerTeamId && winnerContract) {
        // ── Auction won by a team WITH accepted contract ──────────────────────
        const { bidAmount, role, replacedDriverId, salary, years } = winnerContract;
        const buyerRef = db.collection("teams").doc(winnerTeamId);

        logger.info(`[Resolver] Winner: team=${winnerTeamId}, driver=${docSnap.id}, bid=$${bidAmount}`);

        // Determine carIndex from replaced driver
        let inheritedCarIndex = -1;
        if (replacedDriverId) {
          const replacedSnap = await db.collection("drivers").doc(replacedDriverId).get();
          if (replacedSnap.exists) {
            inheritedCarIndex = (replacedSnap.data()?.carIndex as number) ?? -1;
            const replacedMarketValue = replacedSnap.data()?.marketValue ?? replacedSnap.data()?.salary ?? 100_000;

            // Release replaced driver — auto-listed without listing fee
            currentBatch.update(replacedSnap.ref, {
              teamId: null,
              role: "ex_driver",
              carIndex: -1,
              isTransferListed: true,
              transferListedAt: admin.firestore.Timestamp.now(),
              marketValue: replacedMarketValue,
              currentHighestBid: 0,
              highestBidderTeamId: null,
              pendingContracts: admin.firestore.FieldValue.delete(),
              rejectedNegotiationTeams: admin.firestore.FieldValue.delete(),
            });
            opCount++;
          }
        }

        // Transfer incoming driver to buyer team
        currentBatch.update(docSnap.ref, {
          isTransferListed: false,
          transferListedAt: admin.firestore.FieldValue.delete(),
          currentHighestBid: admin.firestore.FieldValue.delete(),
          highestBidderTeamId: admin.firestore.FieldValue.delete(),
          pendingContracts: admin.firestore.FieldValue.delete(),
          rejectedNegotiationTeams: admin.firestore.FieldValue.delete(),
          // Apply accepted contract terms
          teamId: winnerTeamId,
          role,
          salary,
          contractYearsRemaining: years,
          carIndex: inheritedCarIndex,
          // Clear any legacy pending fields from old flow
          pendingNegotiation: admin.firestore.FieldValue.delete(),
          pendingBuyerTeamId: admin.firestore.FieldValue.delete(),
          pendingBidAmount: admin.firestore.FieldValue.delete(),
          pendingOriginalTeamId: admin.firestore.FieldValue.delete(),
        });
        opCount++;

        // Debit buyer budget (the bid amount — commission was already deducted at bid time)
        currentBatch.update(buyerRef, {
          budget: admin.firestore.FieldValue.increment(-bidAmount),
        });
        opCount++;

        // Buyer transaction record
        const buyerTxRef = buyerRef.collection("transactions").doc();
        currentBatch.set(buyerTxRef, {
          id: buyerTxRef.id,
          description: `Transfer Market: ${driver["name"]} firmado como ${role} (${years} temporadas)`,
          amount: -bidAmount,
          date: new Date().toISOString(),
          type: "TRANSFER",
        });
        opCount++;

        if (originalTeamId) {
          // Credit seller budget
          const sellerRef = db.collection("teams").doc(originalTeamId);
          currentBatch.update(sellerRef, {
            budget: admin.firestore.FieldValue.increment(bidAmount),
          });
          opCount++;

          // Seller transaction record
          const sellerTxRef = sellerRef.collection("transactions").doc();
          currentBatch.set(sellerTxRef, {
            id: sellerTxRef.id,
            description: `Transfer Market: ${driver["name"]} vendido`,
            amount: bidAmount,
            date: new Date().toISOString(),
            type: "TRANSFER",
          });
          opCount++;

          await addOfficeNews(originalTeamId, {
            title: "Piloto Vendido",
            message: `${driver["name"]} fue vendido en el mercado de transferencias por $${bidAmount.toLocaleString()}.`,
            type: "TRANSFER_SOLD",
          });
        }

        await addOfficeNews(winnerTeamId, {
          title: "Fichaje Completado",
          message: `${driver["name"]} se une a tu equipo como ${role}. Fee de transferencia: $${bidAmount.toLocaleString()}.`,
          type: "TRANSFER_WON",
        });

        await syncDriverInUniverse(docSnap.id, driver, winnerTeamId);

      } else {
        // ── No accepted contract found — driver delisted (Option A) ───────────
        logger.info(`[Resolver] No winner for driver=${docSnap.id} (no accepted contracts). Delisting.`);

        if (originalTeamId) {
          currentBatch.update(docSnap.ref, {
            isTransferListed: false,
            transferListedAt: admin.firestore.FieldValue.delete(),
            currentHighestBid: admin.firestore.FieldValue.delete(),
            highestBidderTeamId: admin.firestore.FieldValue.delete(),
            pendingContracts: admin.firestore.FieldValue.delete(),
            rejectedNegotiationTeams: admin.firestore.FieldValue.delete(),
          });
          opCount++;

          await addOfficeNews(originalTeamId, {
            title: "Piloto No Vendido",
            message: `Ningún equipo completó la negociación con ${driver["name"]}. El piloto permanece en tu equipo.`,
            type: "TRANSFER_UNSOLD",
          });
        } else {
          // Admin-generated free agent with no accepted contracts — delete
          currentBatch.delete(docSnap.ref);
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
    logger.error("[Resolver] Error in resolveTransferMarket:", error);
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
