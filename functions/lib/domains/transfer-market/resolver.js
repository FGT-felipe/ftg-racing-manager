"use strict";
/**
 * Transfer market resolver — runs hourly.
 * Extracted from resolveTransferMarket in functions/index.js (lines 2349–2464).
 *
 * Finds drivers listed for transfer ≥24h. Processes bids:
 *  - If bid exists: transfers driver to winning team, credits seller.
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
                // ── Bid won — enter pending negotiation phase ──
                // Transfer fee flows immediately: deducted from buyer, credited to seller.
                // If personal-terms negotiation fails, money is not refunded.
                currentBatch.update(doc.ref, {
                    isTransferListed: false,
                    transferListedAt: admin_1.admin.firestore.FieldValue.delete(),
                    currentHighestBid: admin_1.admin.firestore.FieldValue.delete(),
                    highestBidderTeamId: admin_1.admin.firestore.FieldValue.delete(),
                    // Pending negotiation metadata
                    pendingNegotiation: true,
                    pendingBuyerTeamId: highestBidderId,
                    pendingBidAmount: highestBid,
                    pendingOriginalTeamId: originalTeamId || null,
                });
                opCount++;
                // Deduct transfer fee from buyer's budget
                currentBatch.update(admin_1.db.collection("teams").doc(highestBidderId), {
                    budget: admin_1.admin.firestore.FieldValue.increment(-highestBid),
                });
                opCount++;
                // Credit seller's budget immediately (they get paid regardless of negotiation outcome)
                if (originalTeamId) {
                    currentBatch.update(admin_1.db.collection("teams").doc(originalTeamId), {
                        budget: admin_1.admin.firestore.FieldValue.increment(highestBid),
                    });
                    opCount++;
                    await (0, notifications_1.addOfficeNews)(originalTeamId, {
                        title: "Driver Transfer Agreed",
                        message: `${driver["name"]} has been sold for $${highestBid.toLocaleString()}. Funds added to your budget.`,
                        type: "TRANSFER_SOLD",
                    });
                }
                await (0, notifications_1.addOfficeNews)(highestBidderId, {
                    title: "Bid Won — Negotiate Contract",
                    message: `You won the bid for ${driver["name"]} ($${highestBid.toLocaleString()} paid). Go to the Transfer Market to negotiate their personal terms.`,
                    type: "TRANSFER_WON",
                });
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
