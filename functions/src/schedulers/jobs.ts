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

import { setGlobalOptions } from "firebase-functions/v2";

// Limit all functions to 10 concurrent instances unless overridden per-function
setGlobalOptions({ maxInstances: 10 });

// ─── Simulation ───────────────────────────────────────────────────────────────

export {
  scheduledQualifying,
  forceQualy,
} from "../domains/simulation/qualifying";

export {
  scheduledRace,
  forceRace,
} from "../domains/simulation/race-engine";

// ─── Economy ──────────────────────────────────────────────────────────────────

export { postRaceProcessing } from "../domains/economy/post-race";

// ─── Fitness ──────────────────────────────────────────────────────────────────

export { scheduledDailyFitnessRecovery } from "../domains/fitness/recovery";

// ─── Transfer Market ──────────────────────────────────────────────────────────

export { resolveTransferMarket } from "../domains/transfer-market/resolver";

// ─── Admin Tools ──────────────────────────────────────────────────────────────

export {
  megaFixDebriefs,
  forceFixGBA,
  restoreDriversHistory,
} from "../domains/admin/tools";
