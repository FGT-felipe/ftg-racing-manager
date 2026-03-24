"use strict";
/**
 * Daily fitness recovery scheduler.
 * Extracted from scheduledDailyFitnessRecovery in functions/index.js (lines 2287–2344).
 *
 * Runs at midnight COT every day. Increments every driver's fitness by +1.5
 * (capped at 100). Uses chunked batches to respect Firestore's 500-op limit.
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
exports.scheduledDailyFitnessRecovery = void 0;
exports.runDailyFitnessRecovery = runDailyFitnessRecovery;
const logger = __importStar(require("firebase-functions/logger"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin_1 = require("../../shared/admin");
// ─── Core logic ───────────────────────────────────────────────────────────────
/**
 * Recovers fitness for all drivers by +1.5 per day (max 100).
 * Separated from the scheduler for emergency script invocation.
 */
async function runDailyFitnessRecovery() {
    logger.info("=== DAILY FITNESS RECOVERY START ===");
    try {
        const snapshot = await admin_1.db.collection("drivers").get();
        if (snapshot.empty) {
            logger.info("No drivers found. Skipping.");
            return;
        }
        const batches = [];
        let currentBatch = admin_1.db.batch();
        let opCount = 0;
        snapshot.docs.forEach((doc) => {
            const driver = doc.data();
            const stats = driver["stats"] ?? {};
            const currentFitness = stats["fitness"] || 50;
            if (currentFitness < 100) {
                const newFitness = Math.min(100, currentFitness + 1.5);
                currentBatch.update(doc.ref, { "stats.fitness": newFitness });
                opCount++;
                if (opCount === 500) {
                    batches.push(currentBatch.commit());
                    currentBatch = admin_1.db.batch();
                    opCount = 0;
                }
            }
        });
        if (opCount > 0) {
            batches.push(currentBatch.commit());
        }
        await Promise.all(batches);
        logger.info(`=== DAILY FITNESS RECOVERY COMPLETE. Batches: ${batches.length} ===`);
    }
    catch (error) {
        logger.error("Error in scheduledDailyFitnessRecovery:", error);
    }
}
// ─── Scheduled export ─────────────────────────────────────────────────────────
/** Scheduled fitness recovery — midnight COT every day. */
exports.scheduledDailyFitnessRecovery = (0, scheduler_1.onSchedule)({
    schedule: "0 0 * * *",
    timeZone: "America/Bogota",
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    await runDailyFitnessRecovery();
});
