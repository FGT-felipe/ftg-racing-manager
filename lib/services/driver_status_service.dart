import '../models/core_models.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DriverStatusService {
  static String calculateTitle(Driver driver) {
    final age = driver.age;
    final races = driver.races;
    final wins = driver.wins;
    final podiums = driver.podiums;
    final potential = driver.potential;

    // --- The Olympus ---
    if (wins >= 15 && potential >= 4 && races >= 80) {
      return "Living Legend";
    }
    if (wins >= 8 && potential == 5 && age <= 31) {
      return "Era Dominator";
    }
    if (potential == 5 && age <= 24) {
      return driver.gender == 'F' ? "The Heiress" : "The Heir";
    }

    // --- The Old Guard ---
    if (age >= 38) {
      return "Last Dance";
    }
    if (age >= 34 && potential >= 4 && races >= 100) {
      return "Elite Veteran";
    }
    if (races >= 80 && wins < 5 && podiums >= 10) {
      return "Solid Specialist";
    }

    // --- The Raw Side (Past Glory prioritized over New Blood/Reality for vets) ---
    if (age >= 34 && wins >= 5 && potential < 4) {
      return "Past Glory";
    }

    // --- New Blood ---
    if (age <= 21 && potential >= 4 && races < 30) {
      return "Young Wonder";
    }
    if (age < 26 && potential >= 4 && (wins > 0 || podiums > 5)) {
      return "Rising Star";
    }
    if (age >= 26 && potential >= 4 && wins == 0 && races >= 50) {
      return "Stuck Promise";
    }

    // --- Grid Reality ---
    if (potential == 3 && (podiums >= 3 || races > 40)) {
      // Check if they consistent but not top tier
      if (podiums >= 5) return "Midfield Spark";
      return driver.gender == 'F' ? "Journeywoman" : "Journeyman";
    }

    if (races >= 40 && podiums == 0) {
      return "Unsung Driver";
    }

    if (races >= 40 && (wins == 0 || podiums < 5)) {
      return driver.gender == 'F' ? "Journeywoman" : "Journeyman";
    }

    // --- The Raw Side (Grid Filler) ---
    if (potential <= 2 && races >= 20) {
      return "Grid Filler";
    }

    // Fallbacks based on profile
    if (age < 24 && potential >= 3) return "Rising Star";
    if (potential <= 2) return "Grid Filler";

    return driver.gender == 'F' ? "Journeywoman" : "Journeyman";
  }

  static String getLocalizedTitle(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context);
    switch (title) {
      case "Living Legend":
        return l10n.statusLivingLegend;
      case "Era Dominator":
        return l10n.statusEraDominator;
      case "The Heir":
        return l10n.statusTheHeir;
      case "The Heiress":
        return l10n.statusTheHeiress;
      case "Elite Veteran":
        return l10n.statusEliteVeteran;
      case "Last Dance":
        return l10n.statusLastDance;
      case "Solid Specialist":
        return l10n.statusSolidSpecialist;
      case "Young Wonder":
        return l10n.statusYoungWonder;
      case "Rising Star":
        return l10n.statusRisingStar;
      case "Stuck Promise":
        return l10n.statusStuckPromise;
      case "Journeyman":
        return l10n.statusJourneyman;
      case "Journeywoman":
        return l10n.statusJourneywoman;
      case "Unsung Driver":
        return l10n.statusUnsungDriver;
      case "Midfield Spark":
        return l10n.statusMidfieldSpark;
      case "Past Glory":
        return l10n.statusPastGlory;
      case "Grid Filler":
        return l10n.statusGridFiller;
      default:
        return l10n.statusUnknown;
    }
  }

  static String getLocalizedDescription(BuildContext context, String title) {
    final l10n = AppLocalizations.of(context);
    switch (title) {
      case "Living Legend":
        return l10n.descLivingLegend;
      case "Era Dominator":
        return l10n.descEraDominator;
      case "The Heir":
      case "The Heiress":
        return l10n.descTheHeir;
      case "Elite Veteran":
        return l10n.descEliteVeteran;
      case "Last Dance":
        return l10n.descLastDance;
      case "Solid Specialist":
        return l10n.descSolidSpecialist;
      case "Young Wonder":
        return l10n.descYoungWonder;
      case "Rising Star":
        return l10n.descRisingStar;
      case "Stuck Promise":
        return l10n.descStuckPromise;
      case "Journeyman":
      case "Journeywoman":
        return l10n.descJourneyman;
      case "Unsung Driver":
        return l10n.descUnsungDriver;
      case "Midfield Spark":
        return l10n.descMidfieldSpark;
      case "Past Glory":
        return l10n.descPastGlory;
      case "Grid Filler":
        return l10n.descGridFiller;
      default:
        return l10n.descUnknown;
    }
  }

  static Map<String, String> getAllTitles() {
    return {
      "Living Legend":
          "Multiple champion with nothing left to prove; their presence defines the era.",
      "Era Dominator":
          "A driver in their prime who makes the rest of the field look a class below.",
      "The Heir":
          "The driver everyone knows will be champion as soon as they have the right car.",
      "The Heiress":
          "The driver everyone knows will be champion as soon as they have the right car.",
      "Elite Veteran":
          "Many years at the top, consistent, but has passed their peak pure speed.",
      "Last Dance":
          "A driver clearly in their farewell season, whether official or not.",
      "Solid Specialist":
          "A grid staple for 10 years, guaranteed points, but likely never to be champion.",
      "Young Wonder":
          "A rookie or second-year driver breaking records for their age.",
      "Rising Star":
          "No longer a rookie, winning races and climbing the ranks quickly.",
      "Stuck Promise":
          "Someone who entered with high expectations but whose results have flattened.",
      "Journeyman":
          "Does the job, avoids errors, but rarely makes the headlines.",
      "Journeywoman":
          "Does the job, avoids errors, but rarely makes the headlines.",
      "Unsung Driver":
          "A driver who spends years in the category without leaving a statistical mark.",
      "Midfield Spark":
          "Consistently pulls results above what the car allows, waiting for a big break.",
      "Past Glory":
          "A former winner now struggling to even make it into the points.",
      "Grid Filler":
          "Present due to circumstances like open seats or sponsorships rather than talent.",
    };
  }
}
