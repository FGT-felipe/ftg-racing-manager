// ──────────────────────────────────────────────────────────────────────────────
// ECONOMY CONSTANTS — Single source of truth for all monetary values.
//
//
// HOW TO USE:
//   import 'package:ftg_racing_manager/utils/economy_constants.dart';
//
// DESIGN PRINCIPLES:
//   • A mid-pack team (P6-P8 finishes) should roughly break even each week
//     with race prizes + one decent sponsor.
//   • Top teams profit comfortably but never snowball uncontrollably.
//   • Bottom teams must rely on sponsors to survive; zero sponsors = slow bleed.
//   • Qualifying prizes are small bonuses, NOT game-changers by themselves.
//
// BALANCE TARGETS (per race week, 2-driver team):
//   Top team  (P1+P3, 40pts): Race ~$850k + Qualy ~$100k + Sponsors ~$200k ≈ $1.15M
//   Mid team  (P6+P8, 14pts): Race ~$330k + Sponsors ~$70k               ≈ $400k
//   Low team  (P15+P18, 0pts): Race ~$50k + Sponsors ~$30k               ≈ $80k
//
//   Typical weekly expenses for a developed team: $250k-$400k.
//
// WHEN ADDING NEW FEATURES:
//   1. Put any new monetary constant HERE.
//   2. Reference the balance targets above to ensure alignment.
//   3. Prefer scaling off existing constants rather than inventing new numbers.
// ──────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════
//  RACE PRIZES  (paid to each TEAM after race)
// ═══════════════════════════════════════════

/// Every team receives this just for participating in a race.
const int kRaceBaseParticipation = 50000;

/// Additional prize per championship point the team earns in that race.
/// Points system: [25, 18, 15, 12, 10, 8, 6, 4, 2, 1] for P1-P10.
const int kRacePrizePerPoint = 20000;

// ═══════════════════════════════════════════
//  QUALIFYING PRIZES (paid to each TEAM)
// ═══════════════════════════════════════════

/// Prize if a team's driver takes Pole Position (P1 in qualifying).
const int kQualyPrizePole = 75000;

/// Prize if a team's driver qualifies P2.
const int kQualyPrizeP2 = 40000;

/// Prize if a team's driver qualifies P3.
const int kQualyPrizeP3 = 25000;

/// Convenience list indexed by qualifying position (0-based).
/// qualyPrizes[0] = Pole, [1] = P2, [2] = P3.
const List<int> kQualyPrizesByPosition = [
  kQualyPrizePole, // P1
  kQualyPrizeP2, // P2
  kQualyPrizeP3, // P3
];

// ═══════════════════════════════════════════
//  CRASH PENALTIES
// ═══════════════════════════════════════════

/// Repair cost charged when a driver crashes.
const int kCrashRepairCost = 500000;

/// Medical cost charged when a driver crashes.
const int kCrashMedicalCost = 200000;

/// Total crash penalty (repair + medical).
const int kCrashTotalPenalty = kCrashRepairCost + kCrashMedicalCost;

// ═══════════════════════════════════════════
//  ACADEMY
// ═══════════════════════════════════════════

/// Weekly wage per academy trainee.
const int kAcademyTraineeWeeklyWage = 10000;

// ═══════════════════════════════════════════
//  FITNESS TRAINER
// ═══════════════════════════════════════════

/// Weekly cost of the fitness trainer, indexed by trainer level (0-5).
const List<int> kTrainerWeeklyCostByLevel = [
  0,
  0,
  50000,
  120000,
  250000,
  500000,
];
