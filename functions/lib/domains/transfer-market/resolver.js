"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveTransferMarket = void 0;
exports.runTransferMarketResolver = runTransferMarketResolver;
const logger = __importStar(require("firebase-functions/logger"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin_1 = require("../../shared/admin");
const notifications_1 = require("../../shared/notifications");
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
async function syncDriverInUniverse(driverId, driverData, newTeamId) {
    const uRef = admin_1.db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    if (!uDoc.exists)
        return;
    const uData = uDoc.data();
    const leagues = uData.leagues || [];
    let targetLeagueIdx = -1;
    for (let li = 0; li < leagues.length; li++) {
        const teamIds = (leagues[li].teams || []).map((t) => t.id);
        if (newTeamId && teamIds.includes(newTeamId)) {
            targetLeagueIdx = li;
            break;
        }
    }
    let updated = false;
    for (let li = 0; li < leagues.length; li++) {
        const di = (leagues[li].drivers || []).findIndex((d) => d.id === driverId);
        if (di !== -1) {
            leagues[li].drivers[di].teamId = newTeamId || "";
            updated = true;
            break;
        }
    }
    if (!updated && targetLeagueIdx !== -1) {
        leagues[targetLeagueIdx].drivers.push({
            id: driverId,
            name: driverData["name"] || "",
            teamId: newTeamId,
            gender: driverData["gender"] || "male",
            countryCode: driverData["countryCode"] || "",
            points: driverData["points"] || 0,
            seasonPoints: driverData["seasonPoints"] || 0,
            wins: driverData["wins"] || 0,
            seasonWins: driverData["seasonWins"] || 0,
            podiums: driverData["podiums"] || 0,
            seasonPodiums: driverData["seasonPodiums"] || 0,
            races: driverData["races"] || 0,
            seasonRaces: driverData["seasonRaces"] || 0,
            championships: driverData["championships"] || 0,
            championshipForm: driverData["championshipForm"] || [],
            careerHistory: driverData["careerHistory"] || [],
        });
    }
    await uRef.update({ leagues });
}
// ─── Core logic ───────────────────────────────────────────────────────────────
/**
 * Resolves all expired transfer market listings.
 * Separated from the scheduler for emergency script invocation.
 */
async function runTransferMarketResolver() {
    logger.info("=== TRANSFER MARKET RESOLVER START (T-028) ===");
    try {
        const now = admin_1.admin.firestore.Timestamp.now();
        const yesterday = new Date(now.toDate().getTime() - 24 * 60 * 60 * 1000);
        const yesterdayTs = admin_1.admin.firestore.Timestamp.fromDate(yesterday);
        const snapshot = await admin_1.db
            .collection("drivers")
            .where("isTransferListed", "==", true)
            .where("transferListedAt", "<=", yesterdayTs)
            .get();
        if (snapshot.empty) {
            logger.info("No expired transfer listings found.");
            return;
        }
        const batches = [];
        let currentBatch = admin_1.db.batch();
        let opCount = 0;
        for (const docSnap of snapshot.docs) {
            const driver = docSnap.data();
            const originalTeamId = driver["teamId"];
            // ── Find winning team: highest accepted contract ───────────────────────
            const pendingContracts = (driver["pendingContracts"] ?? {});
            let winnerTeamId = null;
            let winnerContract = null;
            for (const [teamId, contract] of Object.entries(pendingContracts)) {
                if (contract.status !== "accepted")
                    continue;
                if (!winnerContract || contract.bidAmount > winnerContract.bidAmount) {
                    winnerTeamId = teamId;
                    winnerContract = contract;
                }
            }
            if (winnerTeamId && winnerContract) {
                // ── Auction won by a team WITH accepted contract ──────────────────────
                const { bidAmount, role, replacedDriverId, salary, years } = winnerContract;
                const buyerRef = admin_1.db.collection("teams").doc(winnerTeamId);
                logger.info(`[Resolver] Winner: team=${winnerTeamId}, driver=${docSnap.id}, bid=$${bidAmount}`);
                // Determine carIndex from replaced driver
                let inheritedCarIndex = -1;
                if (replacedDriverId) {
                    const replacedSnap = await admin_1.db.collection("drivers").doc(replacedDriverId).get();
                    if (replacedSnap.exists) {
                        inheritedCarIndex = replacedSnap.data()?.carIndex ?? -1;
                        const replacedMarketValue = replacedSnap.data()?.marketValue ?? replacedSnap.data()?.salary ?? 100_000;
                        // Release replaced driver — auto-listed without listing fee
                        currentBatch.update(replacedSnap.ref, {
                            teamId: null,
                            role: "ex_driver",
                            carIndex: -1,
                            isTransferListed: true,
                            transferListedAt: admin_1.admin.firestore.Timestamp.now(),
                            marketValue: replacedMarketValue,
                            currentHighestBid: 0,
                            highestBidderTeamId: null,
                            pendingContracts: admin_1.admin.firestore.FieldValue.delete(),
                            rejectedNegotiationTeams: admin_1.admin.firestore.FieldValue.delete(),
                        });
                        opCount++;
                    }
                }
                // Transfer incoming driver to buyer team
                currentBatch.update(docSnap.ref, {
                    isTransferListed: false,
                    transferListedAt: admin_1.admin.firestore.FieldValue.delete(),
                    currentHighestBid: admin_1.admin.firestore.FieldValue.delete(),
                    highestBidderTeamId: admin_1.admin.firestore.FieldValue.delete(),
                    pendingContracts: admin_1.admin.firestore.FieldValue.delete(),
                    rejectedNegotiationTeams: admin_1.admin.firestore.FieldValue.delete(),
                    // Apply accepted contract terms
                    teamId: winnerTeamId,
                    role,
                    salary,
                    contractYearsRemaining: years,
                    carIndex: inheritedCarIndex,
                    // Clear any legacy pending fields from old flow
                    pendingNegotiation: admin_1.admin.firestore.FieldValue.delete(),
                    pendingBuyerTeamId: admin_1.admin.firestore.FieldValue.delete(),
                    pendingBidAmount: admin_1.admin.firestore.FieldValue.delete(),
                    pendingOriginalTeamId: admin_1.admin.firestore.FieldValue.delete(),
                });
                opCount++;
                // Debit buyer budget (the bid amount — commission was already deducted at bid time)
                currentBatch.update(buyerRef, {
                    budget: admin_1.admin.firestore.FieldValue.increment(-bidAmount),
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
                    const sellerRef = admin_1.db.collection("teams").doc(originalTeamId);
                    currentBatch.update(sellerRef, {
                        budget: admin_1.admin.firestore.FieldValue.increment(bidAmount),
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
                    await (0, notifications_1.addOfficeNews)(originalTeamId, {
                        title: "Piloto Vendido",
                        message: `${driver["name"]} fue vendido en el mercado de transferencias por $${bidAmount.toLocaleString()}.`,
                        type: "TRANSFER_SOLD",
                    });
                }
                await (0, notifications_1.addOfficeNews)(winnerTeamId, {
                    title: "Fichaje Completado",
                    message: `${driver["name"]} se une a tu equipo como ${role}. Fee de transferencia: $${bidAmount.toLocaleString()}.`,
                    type: "TRANSFER_WON",
                });
                await syncDriverInUniverse(docSnap.id, driver, winnerTeamId);
            }
            else {
                // ── No accepted contract found — driver delisted (Option A) ───────────
                logger.info(`[Resolver] No winner for driver=${docSnap.id} (no accepted contracts). Delisting.`);
                if (originalTeamId) {
                    currentBatch.update(docSnap.ref, {
                        isTransferListed: false,
                        transferListedAt: admin_1.admin.firestore.FieldValue.delete(),
                        currentHighestBid: admin_1.admin.firestore.FieldValue.delete(),
                        highestBidderTeamId: admin_1.admin.firestore.FieldValue.delete(),
                        pendingContracts: admin_1.admin.firestore.FieldValue.delete(),
                        rejectedNegotiationTeams: admin_1.admin.firestore.FieldValue.delete(),
                    });
                    opCount++;
                    await (0, notifications_1.addOfficeNews)(originalTeamId, {
                        title: "Piloto No Vendido",
                        message: `Ningún equipo completó la negociación con ${driver["name"]}. El piloto permanece en tu equipo.`,
                        type: "TRANSFER_UNSOLD",
                    });
                }
                else {
                    // Admin-generated free agent with no accepted contracts — delete
                    currentBatch.delete(docSnap.ref);
                    opCount++;
                }
            }
            if (opCount >= 400) {
                batches.push(currentBatch.commit());
                currentBatch = admin_1.db.batch();
                opCount = 0;
            }
        }
        if (opCount > 0) {
            batches.push(currentBatch.commit());
        }
        await Promise.all(batches);
        logger.info(`=== TRANSFER MARKET RESOLVER COMPLETE. Batches: ${batches.length} ===`);
    }
    catch (error) {
        logger.error("[Resolver] Error in resolveTransferMarket:", error);
    }
}
// ─── Scheduled export ─────────────────────────────────────────────────────────
/** Scheduled transfer market resolver — every hour. */
exports.resolveTransferMarket = (0, scheduler_1.onSchedule)({
    schedule: "0 * * * *",
    timeZone: "America/Bogota",
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    await runTransferMarketResolver();
});
