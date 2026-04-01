"use strict";
/**
 * Transfer market resolver — runs hourly.
 * Extracted from resolveTransferMarket in functions/index.js (lines 2349–2464).
 *
 * Finds drivers listed for transfer ≥24h. Processes bids:
 *  - If bid exists: transfers driver to winning team, debits buyer, credits seller,
 *    logs transactions, and syncs universe standings automatically.
 *  - If no bid: delist driver; if no team, delete the driver document.
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
 * Updates the universe/game_universe_v1 document after a transfer:
 *  - If the driver already exists in a league.drivers[], updates their teamId.
 *  - If not found and newTeamId belongs to a league, adds the driver entry.
 * Called after every resolved transfer so standings reflect changes immediately.
 *
 * @param driverId     Firestore driver document ID.
 * @param driverData   Full driver data snapshot (for building new entry if needed).
 * @param newTeamId    The team the driver now belongs to.
 */
async function syncDriverInUniverse(driverId, driverData, newTeamId) {
    const uRef = admin_1.db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    if (!uDoc.exists)
        return;
    const uData = uDoc.data();
    const leagues = uData.leagues || [];
    // Build set of all league teamIds to determine which league this team belongs to
    let targetLeagueIdx = -1;
    for (let li = 0; li < leagues.length; li++) {
        const teamIds = (leagues[li].teams || []).map((t) => t.id);
        if (newTeamId && teamIds.includes(newTeamId)) {
            targetLeagueIdx = li;
            break;
        }
    }
    let updated = false;
    // Update existing entry across all leagues
    for (let li = 0; li < leagues.length; li++) {
        const di = (leagues[li].drivers || []).findIndex((d) => d.id === driverId);
        if (di !== -1) {
            leagues[li].drivers[di].teamId = newTeamId || "";
            updated = true;
            break;
        }
    }
    // Add to target league if not found anywhere and we know the league
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
    logger.info("=== TRANSFER MARKET RESOLVER START ===");
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
        for (const doc of snapshot.docs) {
            const driver = doc.data();
            const highestBid = driver["currentHighestBid"] || 0;
            const highestBidderId = driver["highestBidderTeamId"];
            const originalTeamId = driver["teamId"];
            if (highestBid > 0 && highestBidderId) {
                // ── Auction won — enter pendingNegotiation phase ──
                // Driver stays on current team until the buyer completes contract negotiation.
                // The buyer has already paid the transfer fee (deducted below); it is not refunded
                // if negotiations fail. Actual teamId/role change happens in finalizeTransferAcquisition.
                currentBatch.update(doc.ref, {
                    isTransferListed: false,
                    transferListedAt: admin_1.admin.firestore.FieldValue.delete(),
                    currentHighestBid: admin_1.admin.firestore.FieldValue.delete(),
                    highestBidderTeamId: admin_1.admin.firestore.FieldValue.delete(),
                    pendingNegotiation: true,
                    pendingBuyerTeamId: highestBidderId,
                    pendingBidAmount: highestBid,
                    pendingOriginalTeamId: originalTeamId || null,
                });
                opCount++;
                // Debit buyer budget
                const buyerRef = admin_1.db.collection("teams").doc(highestBidderId);
                currentBatch.update(buyerRef, {
                    budget: admin_1.admin.firestore.FieldValue.increment(-highestBid),
                });
                opCount++;
                // Buyer transaction record
                const buyerTxRef = buyerRef.collection("transactions").doc();
                currentBatch.set(buyerTxRef, {
                    id: buyerTxRef.id,
                    description: `Transfer Market: ${driver["name"]} signed`,
                    amount: -highestBid,
                    date: new Date().toISOString(),
                    type: "TRANSFER",
                });
                opCount++;
                if (originalTeamId) {
                    // Credit seller budget
                    const sellerRef = admin_1.db.collection("teams").doc(originalTeamId);
                    currentBatch.update(sellerRef, {
                        budget: admin_1.admin.firestore.FieldValue.increment(highestBid),
                    });
                    opCount++;
                    // Seller transaction record
                    const sellerTxRef = sellerRef.collection("transactions").doc();
                    currentBatch.set(sellerTxRef, {
                        id: sellerTxRef.id,
                        description: `Transfer Market: ${driver["name"]} sold`,
                        amount: highestBid,
                        date: new Date().toISOString(),
                        type: "TRANSFER",
                    });
                    opCount++;
                    await (0, notifications_1.addOfficeNews)(originalTeamId, {
                        title: "Driver Sold",
                        message: `${driver["name"]} was successfully sold in the transfer market for $${highestBid.toLocaleString()}.`,
                        type: "TRANSFER_SOLD",
                    });
                }
                await (0, notifications_1.addOfficeNews)(highestBidderId, {
                    title: "Transfer Completed",
                    message: `${driver["name"]} has joined your team. Transfer fee: $${highestBid.toLocaleString()}.`,
                    type: "TRANSFER_WON",
                });
                // Sync universe standings automatically
                await syncDriverInUniverse(doc.id, driver, highestBidderId);
            }
            else {
                // ── Driver unsold ──
                if (originalTeamId) {
                    currentBatch.update(doc.ref, {
                        isTransferListed: false,
                        transferListedAt: admin_1.admin.firestore.FieldValue.delete(),
                        currentHighestBid: admin_1.admin.firestore.FieldValue.delete(),
                        highestBidderTeamId: admin_1.admin.firestore.FieldValue.delete(),
                    });
                    opCount++;
                    await (0, notifications_1.addOfficeNews)(originalTeamId, {
                        title: "Driver Unsold",
                        message: `Nobody bid on ${driver["name"]} in the transfer market. They remain in your team.`,
                        type: "TRANSFER_UNSOLD",
                    });
                }
                else {
                    // Admin-generated driver with no team — delete to keep pool clean
                    currentBatch.delete(doc.ref);
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
        logger.error("Error in resolveTransferMarket:", error);
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
