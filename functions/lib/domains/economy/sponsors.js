"use strict";
/**
 * Sponsor objective evaluation — pure module.
 * Extracted from evaluateObjective() in functions/index.js (lines 26–81).
 *
 * PURE MODULE: No Firestore calls, no side effects.
 * All inputs are plain data objects. Fully unit-testable without Firebase.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.evaluateObjective = evaluateObjective;
/**
 * Evaluates whether a sponsor's race objective was met.
 * Pure function — deterministic given the same inputs.
 *
 * @param contract The active sponsor contract.
 * @param raceData The finalized race document data.
 * @param teamDrivers Array of driver IDs belonging to the team.
 * @returns true if the objective condition was satisfied.
 */
function evaluateObjective(contract, raceData, teamDrivers) {
    const desc = (contract.objectiveDescription || "").toLowerCase();
    const finalPositions = raceData.finalPositions ?? {};
    const dnfs = raceData.dnfs ?? [];
    const fastLapDriver = raceData.fast_lap_driver;
    const raceCountry = raceData.countryCode ?? "";
    const sponsorCountry = contract.countryCode ?? "";
    /** Returns driver's finishing position, or 999 if DNF or unknown. */
    const getPos = (id) => dnfs.includes(id) ? 999 : (finalPositions[id] ?? 999);
    // ⚠️  "home race win" is checked BEFORE "race win" because the latter is a
    // substring of the former. Checking in reverse order would make home-race-win
    // unreachable — a latent bug in the original index.js that is fixed here.
    if (desc.includes("home race win")) {
        const isHomeRace = Boolean(raceCountry && sponsorCountry && raceCountry === sponsorCountry);
        if (!isHomeRace)
            return false;
        return teamDrivers.some((id) => getPos(id) === 1);
    }
    if (desc.includes("race win")) {
        return teamDrivers.some((id) => getPos(id) === 1);
    }
    if (desc.includes("finish top 3")) {
        return teamDrivers.some((id) => getPos(id) <= 3);
    }
    if (desc.includes("finish top 5")) {
        return teamDrivers.some((id) => getPos(id) <= 5);
    }
    if (desc.includes("finish top 8")) {
        return teamDrivers.some((id) => getPos(id) <= 8);
    }
    if (desc.includes("finish top 10")) {
        return teamDrivers.some((id) => getPos(id) <= 10);
    }
    if (desc.includes("finish top 16")) {
        return teamDrivers.some((id) => getPos(id) <= 16);
    }
    if (desc.includes("double podium")) {
        const podiumDrivers = teamDrivers.filter((id) => getPos(id) <= 3);
        return podiumDrivers.length >= 2;
    }
    if (desc.includes("both in points")) {
        return teamDrivers.every((id) => getPos(id) <= 10);
    }
    if (desc.includes("fastest lap")) {
        return fastLapDriver !== undefined && teamDrivers.includes(fastLapDriver);
    }
    if (desc.includes("finish race")) {
        return teamDrivers.some((id) => !dnfs.includes(id));
    }
    return false;
}
