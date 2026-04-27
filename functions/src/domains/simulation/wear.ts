/**
 * Parts Wear Engine — T-007 Slice 1 (Skeleton)
 *
 * PURE module for wear formula + Firestore mutation helper.
 * Formula is deterministic (no RNG) in Slice 1.
 *
 * ⚠️  STRICT-MODE RULE: All variables used after conditional assignment MUST be
 * declared with `let varName = defaultValue` before the `if`.
 * See CLAUDE.md §5.1 and postmortem R2/R3.
 */

import * as logger from "firebase-functions/logger";
import { db, admin } from "../../shared/admin";

// ─── Constants ────────────────────────────────────────────────────────────────

/** Condition points removed after every completed race (Slice 1 flat delta). */
const PARTS_BASE_RACE_DELTA = 8;

/** Current formula version — increment when formula changes between slices. */
const FORMULA_VERSION = 1;

// ─── Formula ─────────────────────────────────────────────────────────────────

/**
 * Computes the wear delta for a given trigger event.
 * Deterministic — no RNG in Slice 1.
 *
 * @param trigger - Event type: 'race' | 'qualifying' | 'special_event'
 * @returns Condition points to subtract (always >= 0)
 */
export function computeWearDelta(trigger: string): number {
  if (trigger === "race") return PARTS_BASE_RACE_DELTA;
  // qualifying and special_event deferred to Slice 2
  return 0;
}

// ─── Orchestrator ─────────────────────────────────────────────────────────────

/**
 * Reads the `parts/engine` sub-document for a team/car, applies the race wear
 * delta, and writes one `wear_log` document as an append-only audit entry.
 *
 * If the `parts/engine` document does not exist the function returns silently
 * (backward compat — teams not yet migrated are unaffected, AC#8).
 *
 * NEVER re-throws — caller wraps this in try/catch and does NOT block race
 * results on wear failures (AC#9).
 *
 * @param teamId - Firestore team document ID
 * @param carIndex - Car slot index (0 = Car A)
 * @param seasonId - Current season ID (for wear_log key)
 * @param roundId - Current round ID, e.g. 'r2' (for wear_log key)
 */
export async function applyWearDelta(
  teamId: string,
  carIndex: number,
  seasonId: string,
  roundId: string
): Promise<void> {
  const partRef = db
    .collection("teams")
    .doc(teamId)
    .collection("cars")
    .doc(String(carIndex))
    .collection("parts")
    .doc("engine");

  const partSnap = await partRef.get();

  // AC#8 — skip silently if part doc doesn't exist
  if (!partSnap.exists) return;

  const conditionBefore: number = (partSnap.data() as Record<string, unknown>)["condition"] as number ?? 100;
  const delta = computeWearDelta("race");
  const conditionAfter = Math.max(0, conditionBefore - delta);

  // Update part condition
  await partRef.update({
    condition: conditionAfter,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Write immutable wear_log entry
  const logDocId = `${seasonId}_${roundId}_${teamId}_${carIndex}`;
  await db.collection("wear_log").doc(logDocId).set({
    seasonId,
    roundId,
    teamId,
    carIndex,
    trigger: "race",
    partDeltas: [
      {
        partId: "engine",
        partType: "engine",
        conditionBefore,
        conditionAfter,
        delta,
      },
    ],
    computedAt: admin.firestore.FieldValue.serverTimestamp(),
    formulaVersion: FORMULA_VERSION,
  });

  logger.info(`[applyWearDelta] team=${teamId} car=${carIndex} engine: ${conditionBefore} → ${conditionAfter}`);
}
