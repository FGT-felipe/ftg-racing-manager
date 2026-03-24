/**
 * Circuit profiles for the FTG Racing Manager simulation engine.
 * Mirrors the circuit data previously hardcoded in functions/index.js (lines 87–188).
 */

// ─── Types ───────────────────────────────────────────────────────────────────

export interface CircuitIdealSetup {
  frontWing: number;
  rearWing: number;
  suspension: number;
  gearRatio: number;
}

export interface Circuit {
  id: string;
  countryCode?: string;
  baseLapTime: number;
  laps: number;
  tyreWearMultiplier: number;
  fuelConsumptionMultiplier: number;
  aeroWeight: number;
  powertrainWeight: number;
  chassisWeight: number;
  idealSetup: CircuitIdealSetup;
}

// ─── Circuit data ─────────────────────────────────────────────────────────────

const CIRCUITS: Record<string, Circuit> = {
  "mexico": {
    id: "mexico", countryCode: "MX", baseLapTime: 76.0, laps: 71,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.4, chassisWeight: 0.2,
    idealSetup: { frontWing: 80, rearWing: 75, suspension: 50, gearRatio: 85 },
  },
  "vegas": {
    id: "vegas", countryCode: "US", baseLapTime: 92.0, laps: 50,
    tyreWearMultiplier: 0.8, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.2, powertrainWeight: 0.6, chassisWeight: 0.2,
    idealSetup: { frontWing: 25, rearWing: 20, suspension: 70, gearRatio: 90 },
  },
  "interlagos": {
    id: "interlagos", countryCode: "BR", baseLapTime: 70.5, laps: 71,
    tyreWearMultiplier: 1.2, fuelConsumptionMultiplier: 1.2,
    aeroWeight: 0.3, powertrainWeight: 0.3, chassisWeight: 0.4,
    idealSetup: { frontWing: 65, rearWing: 60, suspension: 45, gearRatio: 55 },
  },
  "miami": {
    id: "miami", countryCode: "US", baseLapTime: 90.0, laps: 57,
    tyreWearMultiplier: 1.0, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.3, chassisWeight: 0.3,
    idealSetup: { frontWing: 55, rearWing: 50, suspension: 60, gearRatio: 65 },
  },
  "san_pablo_street": {
    id: "san_pablo_street", countryCode: "BR", baseLapTime: 82.0, laps: 40,
    tyreWearMultiplier: 1.3, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.2, chassisWeight: 0.6,
    idealSetup: { frontWing: 85, rearWing: 80, suspension: 30, gearRatio: 35 },
  },
  "indianapolis": {
    id: "indianapolis", countryCode: "US", baseLapTime: 72.0, laps: 73,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.3, powertrainWeight: 0.4, chassisWeight: 0.3,
    idealSetup: { frontWing: 40, rearWing: 35, suspension: 75, gearRatio: 80 },
  },
  "montreal": {
    id: "montreal", countryCode: "CA", baseLapTime: 73.0, laps: 70,
    tyreWearMultiplier: 0.9, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.4, chassisWeight: 0.4,
    idealSetup: { frontWing: 45, rearWing: 40, suspension: 55, gearRatio: 70 },
  },
  "texas": {
    id: "texas", countryCode: "US", baseLapTime: 94.0, laps: 56,
    tyreWearMultiplier: 1.4, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.5, powertrainWeight: 0.2, chassisWeight: 0.3,
    idealSetup: { frontWing: 75, rearWing: 70, suspension: 50, gearRatio: 60 },
  },
  "buenos_aires": {
    id: "buenos_aires", countryCode: "AR", baseLapTime: 74.0, laps: 72,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.3, powertrainWeight: 0.2, chassisWeight: 0.5,
    idealSetup: { frontWing: 65, rearWing: 60, suspension: 45, gearRatio: 50 },
  },
};

const GENERIC_CIRCUIT: Circuit = {
  id: "generic",
  baseLapTime: 85.0,
  laps: 50,
  tyreWearMultiplier: 1.0,
  fuelConsumptionMultiplier: 1.0,
  aeroWeight: 0.33,
  powertrainWeight: 0.34,
  chassisWeight: 0.33,
  idealSetup: { frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50 },
};

// ─── Public API ───────────────────────────────────────────────────────────────

/**
 * Returns the circuit profile for the given ID.
 * Falls back to GENERIC_CIRCUIT if the circuit is not found.
 * @param circuitId The circuit identifier (e.g. "mexico", "vegas").
 */
export function getCircuit(circuitId: string): Circuit {
  return CIRCUITS[circuitId] ?? GENERIC_CIRCUIT;
}
