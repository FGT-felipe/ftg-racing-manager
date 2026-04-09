"use strict";
/**
 * Central Cloud Functions registration hub.
 * Re-exports all scheduled functions and onCall handlers from their domains.
 *
 * Firebase deploys whatever is exported from the entry point (src/index.ts → lib/index.js).
 * Keeping this file as a flat re-export list makes it easy to:
 *  - See all deployed functions at a glance.
 *  - Enable/disable a function by commenting it out here.
 *  - Verify no duplicates from domain files.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.scheduledHourlyMaintenance = exports.scheduledDailyBackup = exports.syncUniverseCallable = exports.restoreDriversHistory = exports.forceFixGBA = exports.megaFixDebriefs = exports.resolveTransferMarket = exports.scheduledDailyFitnessRecovery = exports.postRaceProcessing = exports.forceRace = exports.scheduledRace = exports.forceQualy = exports.scheduledQualifying = void 0;
const v2_1 = require("firebase-functions/v2");
// Limit all functions to 10 concurrent instances unless overridden per-function
(0, v2_1.setGlobalOptions)({ maxInstances: 10 });
// ─── Simulation ───────────────────────────────────────────────────────────────
var qualifying_1 = require("../domains/simulation/qualifying");
Object.defineProperty(exports, "scheduledQualifying", { enumerable: true, get: function () { return qualifying_1.scheduledQualifying; } });
Object.defineProperty(exports, "forceQualy", { enumerable: true, get: function () { return qualifying_1.forceQualy; } });
var race_engine_1 = require("../domains/simulation/race-engine");
Object.defineProperty(exports, "scheduledRace", { enumerable: true, get: function () { return race_engine_1.scheduledRace; } });
Object.defineProperty(exports, "forceRace", { enumerable: true, get: function () { return race_engine_1.forceRace; } });
// ─── Economy ──────────────────────────────────────────────────────────────────
var post_race_1 = require("../domains/economy/post-race");
Object.defineProperty(exports, "postRaceProcessing", { enumerable: true, get: function () { return post_race_1.postRaceProcessing; } });
// ─── Fitness ──────────────────────────────────────────────────────────────────
var recovery_1 = require("../domains/fitness/recovery");
Object.defineProperty(exports, "scheduledDailyFitnessRecovery", { enumerable: true, get: function () { return recovery_1.scheduledDailyFitnessRecovery; } });
// ─── Transfer Market ──────────────────────────────────────────────────────────
var resolver_1 = require("../domains/transfer-market/resolver");
Object.defineProperty(exports, "resolveTransferMarket", { enumerable: true, get: function () { return resolver_1.resolveTransferMarket; } });
// ─── Admin Tools ──────────────────────────────────────────────────────────────
var tools_1 = require("../domains/admin/tools");
Object.defineProperty(exports, "megaFixDebriefs", { enumerable: true, get: function () { return tools_1.megaFixDebriefs; } });
Object.defineProperty(exports, "forceFixGBA", { enumerable: true, get: function () { return tools_1.forceFixGBA; } });
Object.defineProperty(exports, "restoreDriversHistory", { enumerable: true, get: function () { return tools_1.restoreDriversHistory; } });
Object.defineProperty(exports, "syncUniverseCallable", { enumerable: true, get: function () { return tools_1.syncUniverseCallable; } });
// ─── Backup ───────────────────────────────────────────────────────────────────
var backup_1 = require("../domains/admin/backup");
Object.defineProperty(exports, "scheduledDailyBackup", { enumerable: true, get: function () { return backup_1.scheduledDailyBackup; } });
// ─── Maintenance ──────────────────────────────────────────────────────────────
var checker_1 = require("../schedulers/checker");
Object.defineProperty(exports, "scheduledHourlyMaintenance", { enumerable: true, get: function () { return checker_1.scheduledHourlyMaintenance; } });
