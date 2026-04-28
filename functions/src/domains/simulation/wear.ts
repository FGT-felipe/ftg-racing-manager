/**
 * Parts Wear Engine — T-007 Slice 2 (Full Formula)
 *
 * PURE module for wear formula + Firestore mutation helper.
 *
 * ⚠️  STRICT-MODE RULE: All variables used after conditional assignment MUST be
 * declared with `let varName = defaultValue` before the `if`.
 * See CLAUDE.md §5.1 and postmortem R2/R3.
 */

import * as logger from "firebase-functions/logger";
import { db, admin } from "../../shared/admin";
import { addOfficeNews } from "../../shared/notifications";

// ─── Types ────────────────────────────────────────────────────────────────────

export type ConditionTier = "green" | "yellow" | "orange" | "red";

export interface WearParams {
  trigger: "race" | "qualifying" | "special_event";
  partType: string;
  partLevel: number;
  circuitId: string;
  raceStyle: string;       // driver's raceStyle: 'mostRisky' | 'risky' | 'normal' | 'defensive'
  weather: string;         // 'dry' | 'wet' | 'rain'
  circuitStressMap: Record<string, Record<string, number>>; // from Firestore config
  baseDeltas: Record<string, number>;   // per partType, from Firestore config
  incidentMultiplier: number;
  hadIncident?: boolean;
}

export interface PartState {
  condition: number;
  maxCondition: number;
  level: number;
}

/** Firestore config shape for parts_wear. Code-defaults used when Firestore read fails. */
export interface PartsWearConfig {
  baseDeltas: { race: Record<string, number> };
  circuitStress: Record<string, Record<string, number>>;
  failureCurve: Record<string, number>;
  tierThresholds: { yellow: number; orange: number; red: number };
  incidentMultiplier: number;
  repairBudgetCap: { perRound: number; finalRoundMultiplier: number };
  formulaVersion: number;
}

export const PARTS_WEAR_CONFIG_DEFAULTS: PartsWearConfig = {
  baseDeltas: {
    race: { engine: 8, gearbox: 6, brakes: 5, frontWing: 4, rearWing: 4, suspension: 5 },
  },
  circuitStress: {
    mexico:          { engine: 0.3, gearbox: 0.1, brakes: 0.2, frontWing: 0.1, rearWing: 0.1, suspension: 0.1 },
    vegas:           { engine: 0.4, gearbox: 0.05, brakes: 0.1, frontWing: 0.1, rearWing: 0.1, suspension: 0.05 },
    interlagos:      { engine: 0.1, gearbox: 0.2, brakes: 0.3, frontWing: 0.1, rearWing: 0.1, suspension: 0.3 },
    miami:           { engine: 0.15, gearbox: 0.1, brakes: 0.2, frontWing: 0.15, rearWing: 0.15, suspension: 0.15 },
    san_pablo_street: { engine: 0.1, gearbox: 0.15, brakes: 0.4, frontWing: 0.2, rearWing: 0.2, suspension: 0.4 },
  },
  failureCurve: { green: 0.0, yellow: 0.002, orange: 0.015, red: 0.04 },
  tierThresholds: { yellow: 80, orange: 50, red: 30 },
  incidentMultiplier: 1.5,
  repairBudgetCap: { perRound: 150_000, finalRoundMultiplier: 2 },
  formulaVersion: 2,
};

const ALL_PART_TYPES = ["engine", "gearbox", "brakes", "frontWing", "rearWing", "suspension"];

// ─── Formula ─────────────────────────────────────────────────────────────────

/**
 * Returns the condition tier for a given condition value.
 * Pure — no side effects.
 */
export function getTierFromCondition(
  condition: number,
  thresholds = PARTS_WEAR_CONFIG_DEFAULTS.tierThresholds
): ConditionTier {
  if (condition >= thresholds.yellow) return "green";
  if (condition >= thresholds.orange) return "yellow";
  if (condition >= thresholds.red) return "orange";
  return "red";
}

/**
 * Computes the wear delta for a given part + race event.
 * Multiplicative formula: base × (1 + circuitStress) × driverModifier × trackCondModifier × carLevelModifier
 * Deterministic — no RNG.
 *
 * Returns 0 for qualifying and special_event (deferred to S3).
 */
export function computeWearDelta(params: WearParams): number {
  if (params.trigger !== "race") return 0;

  const base = params.baseDeltas[params.partType] ?? 5;

  // STRICT-MODE: all modifiers declared before any conditional
  let circuitStress = 0;
  let driverModifier = 1.0;
  let trackCondModifier = 1.0;
  let carLevelModifier = 1.0;

  // circuitStress from Firestore config
  if (params.circuitStressMap[params.circuitId]?.[params.partType] !== undefined) {
    circuitStress = params.circuitStressMap[params.circuitId][params.partType];
  }

  // driverModifier from raceStyle
  if (params.raceStyle === "mostRisky") driverModifier = 1.3;
  else if (params.raceStyle === "risky") driverModifier = 1.15;
  else if (params.raceStyle === "defensive") driverModifier = 0.9;

  // trackCondModifier from weather
  const weatherLower = (params.weather ?? "").toLowerCase();
  if (weatherLower.includes("rain") || weatherLower.includes("wet")) {
    trackCondModifier = 1.2;
  }

  // carLevelModifier: higher level → less wear (floor 0.6 at level ~9+)
  carLevelModifier = Math.max(0.6, 1 - (params.partLevel - 1) * 0.05);

  let delta = base * (1 + circuitStress) * driverModifier * trackCondModifier * carLevelModifier;

  // Incident bump
  if (params.hadIncident) {
    delta = delta * params.incidentMultiplier;
  }

  return delta;
}

/**
 * Rolls a per-lap failure check for a given tier.
 * Uses Math.random() — same approach as existing simulateLap crash rolls.
 * Returns true if the part fails this lap.
 */
export function failureRoll(
  tier: ConditionTier,
  failureCurve: Record<string, number>
): boolean {
  const prob = failureCurve[tier] ?? 0;
  if (prob <= 0) return false;
  return Math.random() < prob;
}

// ─── Orchestrator ─────────────────────────────────────────────────────────────

/**
 * Applies post-race wear delta to all 6 parts for a team.
 * Accepts a pre-loaded partsMap to avoid N+1 reads.
 * Writes one wear_log entry per team (formulaVersion: 2).
 * Sends tier-down notifications via sendOfficeNotification.
 *
 * NEVER re-throws — caller wraps in try/catch (AC#9).
 *
 * @param teamId - Firestore team document ID
 * @param carIndex - Car slot index (0 = Car A)
 * @param seasonId - Current season ID
 * @param roundId - Current round ID, e.g. 'r8'
 * @param partsMap - Pre-loaded parts keyed by partType (missing = skip silently)
 * @param params - Race params for formula (circuitId, raceStyle, weather, config)
 * @param hadIncident - Whether this driver had a crash/DNF this race (for incident bump)
 */
export async function applyWearDelta(
  teamId: string,
  carIndex: number,
  seasonId: string,
  roundId: string,
  partsMap: Record<string, PartState>,
  params: {
    circuitId: string;
    raceStyle: string;
    weather: string;
    config: PartsWearConfig;
  },
  hadIncident: boolean = false
): Promise<void> {
  const batch = db.batch();
  const partDeltas: Record<string, unknown>[] = [];
  const tierDowns: { partType: string; oldTier: ConditionTier; newTier: ConditionTier }[] = [];

  for (const partType of ALL_PART_TYPES) {
    const partState = partsMap[partType];
    if (!partState) continue; // AC#13 — skip silently if part not migrated

    const conditionBefore = partState.condition;
    const delta = computeWearDelta({
      trigger: "race",
      partType,
      partLevel: partState.level,
      circuitId: params.circuitId,
      raceStyle: params.raceStyle,
      weather: params.weather,
      circuitStressMap: params.config.circuitStress,
      baseDeltas: params.config.baseDeltas.race,
      incidentMultiplier: params.config.incidentMultiplier,
      hadIncident,
    });

    const conditionAfter = Math.max(0, conditionBefore - delta);

    const partRef = db
      .collection("teams")
      .doc(teamId)
      .collection("cars")
      .doc(String(carIndex))
      .collection("parts")
      .doc(partType);

    batch.update(partRef, {
      condition: conditionAfter,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    partDeltas.push({ partId: partType, partType, conditionBefore, conditionAfter, delta });

    // Check for tier-down
    const oldTier = getTierFromCondition(conditionBefore, params.config.tierThresholds);
    const newTier = getTierFromCondition(conditionAfter, params.config.tierThresholds);
    const tierOrder: ConditionTier[] = ["green", "yellow", "orange", "red"];
    if (tierOrder.indexOf(newTier) > tierOrder.indexOf(oldTier)) {
      tierDowns.push({ partType, oldTier, newTier });
    }
  }

  // Write wear_log (immutable, append-only)
  const logDocId = `${seasonId}_${roundId}_${teamId}_${carIndex}`;
  const logRef = db.collection("wear_log").doc(logDocId);
  batch.set(logRef, {
    seasonId,
    roundId,
    teamId,
    carIndex,
    trigger: "race",
    partDeltas,
    computedAt: admin.firestore.FieldValue.serverTimestamp(),
    formulaVersion: params.config.formulaVersion,
  });

  await batch.commit();

  // Send tier-down notifications (after batch — failures here are non-blocking)
  for (const td of tierDowns) {
    try {
      await addOfficeNews(teamId, {
        title: "Part condition warning",
        message: `${td.partType} dropped to ${td.newTier} tier — open the Garage to repair.`,
        type: "warning",
      });
    } catch (notifErr) {
      logger.warn(`[applyWearDelta] tier-down notification failed for team ${teamId} part ${td.partType}`, notifErr);
    }
  }

  logger.info(`[applyWearDelta] team=${teamId} car=${carIndex} round=${roundId} parts=${partDeltas.length} tier-downs=${tierDowns.length}`);
}
