/**
 * Shared TypeScript interfaces for the FTG Racing Manager backend.
 * Single source of truth for all data shapes flowing through the system.
 */

import type { CircuitIdealSetup } from "../config/circuits";

// ─── Driver ──────────────────────────────────────────────────────────────────

export interface DriverStats {
  cornering: number;
  braking: number;
  focus: number;
  fitness: number;
  adaptability: number;
  consistency: number;
  smoothness: number;
  overtaking: number;
  morale?: number;
  traits?: string[];
}

export interface Driver {
  id: string;
  teamId: string;
  name: string;
  salary: number;
  age: number;
  potential: number;
  stats: DriverStats;
  /** Index of the car slot this driver uses within the team (0 or 1). */
  carIndex?: number;
  seasonPoints?: number;
  seasonRaces?: number;
  seasonWins?: number;
  form?: number;
  championshipForm?: number;
  isTransferListed?: boolean;
}

// ─── Team ────────────────────────────────────────────────────────────────────

export interface CarStats {
  aero: number;
  powertrain: number;
  chassis: number;
  reliability?: number;
}

export interface Facility {
  level: number;
  [key: string]: unknown;
}

export interface WeekStatus {
  fitnessTrainerLevel?: number;
  upgradeCooldownWeeksLeft?: number;
  driverSetups?: Record<string, CarSetup>;
  [key: string]: unknown;
}

export interface Team {
  id: string;
  name: string;
  budget: number;
  managerId: string;
  /** True for AI-controlled bot teams. */
  isBot?: boolean;
  /** Map of car slot index (as string) to CarStats. */
  carStats?: Record<string, CarStats>;
  sponsors?: Record<string, SponsorContract>;
  facilities?: Record<string, Facility>;
  weekStatus?: WeekStatus;
  seasonPoints?: number;
  seasonRaces?: number;
  seasonWins?: number;
  lastRaceDebrief?: string;
  lastRaceResult?: string;
}

// ─── Car setup ───────────────────────────────────────────────────────────────

export type TyreCompound = "soft" | "medium" | "hard" | "wet";
export type DrivingStyle = "defensive" | "normal" | "offensive" | "mostRisky";

export interface CarSetup {
  frontWing: number;
  rearWing: number;
  suspension: number;
  gearRatio: number;
  tyreCompound: TyreCompound;
  qualifyingStyle: DrivingStyle;
  raceStyle: DrivingStyle;
  initialFuel: number;
  pitStops: TyreCompound[];
  pitStopStyles: DrivingStyle[];
  pitStopFuel: number[];
}

// ─── Sponsor ─────────────────────────────────────────────────────────────────

export interface SponsorContract {
  slot: string;
  sponsorId: string;
  sponsorName: string;
  objectiveDescription: string;
  objectiveBonus?: number;
  weeklyBasePayment?: number;
  racesRemaining: number;
  countryCode?: string;
}

// ─── Race ─────────────────────────────────────────────────────────────────────

export interface QualyResult {
  driverId: string;
  lapTime: number;
  position: number;
}

/**
 * Extended qualifying result written to the Race document and used as the
 * starting grid for the race simulation. Contains all fields produced by
 * runQualifyingLogic().
 */
export interface QualyGridEntry {
  driverId: string;
  driverName: string;
  teamId: string;
  teamName: string;
  lapTime: number;
  isCrashed: boolean;
  tyreCompound: TyreCompound;
  setupSubmitted: boolean;
  position?: number;
  gap?: number;
}

export interface LapEvent {
  lap: number;
  driverId: string;
  desc: string;
  type: "DNF" | "PIT" | "OVERTAKE" | "INFO";
}

export interface RaceLapLog {
  lap: number;
  lapTimes: Record<string, number>;
  positions: Record<string, number>;
  tyres: Record<string, TyreCompound>;
  events: LapEvent[];
}

export interface RaceData {
  finalPositions?: Record<string, number>;
  dnfs?: string[];
  fast_lap_driver?: string;
  countryCode?: string;
  setups?: Record<string, CarSetup>;
  raceLog?: RaceLapLog[];
  totalTimes?: Record<string, number>;
  fast_lap_time?: number;
  isFinished?: boolean;
  postRaceProcessed?: boolean;
  postRaceProcessingAt?: FirebaseFirestore.Timestamp | string;
  seasonId?: string;
  eventId?: string;
  qualyGrid?: QualyResult[];
  results?: {
    finalPositions?: Record<string, number>;
    dnfs?: string[];
  };
}

// ─── Season / Calendar ────────────────────────────────────────────────────────

export interface RaceEvent {
  id: string;
  trackName: string;
  circuitId: string;
  totalLaps?: number;
  weatherQualy?: string;
  weatherRace?: string;
  countryCode?: string;
  isCompleted?: boolean;
}

// ─── Notifications ────────────────────────────────────────────────────────────

export interface NewsEntry {
  title: string;
  message: string;
  type: string;
  teamId?: string;
}

// ─── Admin utilities ──────────────────────────────────────────────────────────

export interface AdminResult {
  success: boolean;
  error?: string;
  [key: string]: unknown;
}

// Re-export circuit types for convenience
export type { CircuitIdealSetup };
