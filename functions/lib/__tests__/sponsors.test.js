"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const sponsors_1 = require("../domains/economy/sponsors");
// ─── Helpers ─────────────────────────────────────────────────────────────────
const makeContract = (desc, extra = {}) => ({
    slot: "title",
    sponsorId: "sponsor_1",
    sponsorName: "Test Sponsor",
    objectiveDescription: desc,
    racesRemaining: 5,
    ...extra,
});
const makeRaceData = (overrides = {}) => ({
    finalPositions: { d1: 1, d2: 5, d3: 3 },
    dnfs: [],
    fast_lap_driver: "d1",
    countryCode: "MX",
    ...overrides,
});
// ─── Tests ───────────────────────────────────────────────────────────────────
describe("evaluateObjective", () => {
    it('detects "race win" objective correctly', () => {
        const contract = makeContract("Score a race win");
        const raceWin = makeRaceData({ finalPositions: { d1: 1, d2: 4 } });
        const noWin = makeRaceData({ finalPositions: { d1: 2, d2: 4 } });
        expect((0, sponsors_1.evaluateObjective)(contract, raceWin, ["d1"])).toBe(true);
        expect((0, sponsors_1.evaluateObjective)(contract, noWin, ["d1"])).toBe(false);
        // DNF driver does not count as P1
        const dnfRace = makeRaceData({ finalPositions: { d1: 1, d2: 4 }, dnfs: ["d1"] });
        expect((0, sponsors_1.evaluateObjective)(contract, dnfRace, ["d1"])).toBe(false);
    });
    it('detects "finish top 3" for either driver', () => {
        const contract = makeContract("Finish top 3 in the race");
        // d2 is P2 → should pass
        const raceData = makeRaceData({ finalPositions: { d1: 4, d2: 2 } });
        expect((0, sponsors_1.evaluateObjective)(contract, raceData, ["d1", "d2"])).toBe(true);
        // d1 alone at P4 → fails
        expect((0, sponsors_1.evaluateObjective)(contract, raceData, ["d1"])).toBe(false);
        // Both outside top 3 → fails
        const outside = makeRaceData({ finalPositions: { d1: 4, d2: 5 } });
        expect((0, sponsors_1.evaluateObjective)(contract, outside, ["d1", "d2"])).toBe(false);
    });
    it('detects "double podium" requiring both drivers in top 3', () => {
        const contract = makeContract("Achieve double podium");
        // Both in podium → passes
        const bothPodium = makeRaceData({ finalPositions: { d1: 1, d2: 2 } });
        expect((0, sponsors_1.evaluateObjective)(contract, bothPodium, ["d1", "d2"])).toBe(true);
        // Only one in podium → fails
        const onePodium = makeRaceData({ finalPositions: { d1: 1, d2: 4 } });
        expect((0, sponsors_1.evaluateObjective)(contract, onePodium, ["d1", "d2"])).toBe(false);
        // DNF counts as 999 → fails even with good finish for other driver
        const withDnf = makeRaceData({ finalPositions: { d1: 1, d2: 2 }, dnfs: ["d2"] });
        expect((0, sponsors_1.evaluateObjective)(contract, withDnf, ["d1", "d2"])).toBe(false);
    });
    it('handles "home race win" only on matching countryCode', () => {
        const contract = makeContract("Score a home race win", { countryCode: "MX" });
        // Home race, d1 wins → passes
        const homeWin = makeRaceData({ finalPositions: { d1: 1 }, countryCode: "MX" });
        expect((0, sponsors_1.evaluateObjective)(contract, homeWin, ["d1"])).toBe(true);
        // Away race, d1 wins → fails
        const awayWin = makeRaceData({ finalPositions: { d1: 1 }, countryCode: "US" });
        expect((0, sponsors_1.evaluateObjective)(contract, awayWin, ["d1"])).toBe(false);
        // Home race but P2 → fails
        const homeNoWin = makeRaceData({ finalPositions: { d1: 2 }, countryCode: "MX" });
        expect((0, sponsors_1.evaluateObjective)(contract, homeNoWin, ["d1"])).toBe(false);
    });
    it("returns false for unrecognized objective strings", () => {
        const contract = makeContract("Achieve something completely unknown");
        const raceData = makeRaceData({ finalPositions: { d1: 1 } });
        expect((0, sponsors_1.evaluateObjective)(contract, raceData, ["d1"])).toBe(false);
    });
});
