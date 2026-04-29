/**
 * Unit tests for season-end prize distribution helpers (T-124 S1).
 * Zero Firebase calls — all functions are pure and deterministic.
 */

import {
  getSeasonPrizeForPosition,
  rankTeamsByPoints,
  findDriversChampion,
} from "../domains/economy/season-end";

// ─── Tests: getSeasonPrizeForPosition ────────────────────────────────────────
describe("getSeasonPrizeForPosition", () => {
  it("P1 receives $6M", () => expect(getSeasonPrizeForPosition(1)).toBe(6_000_000));
  it("P2 receives $4.5M", () => expect(getSeasonPrizeForPosition(2)).toBe(4_500_000));
  it("P3 receives $3M", () => expect(getSeasonPrizeForPosition(3)).toBe(3_000_000));
  it("P4 receives $2M", () => expect(getSeasonPrizeForPosition(4)).toBe(2_000_000));
  it("P5 receives $1.5M", () => expect(getSeasonPrizeForPosition(5)).toBe(1_500_000));
  it("P6 receives $1M", () => expect(getSeasonPrizeForPosition(6)).toBe(1_000_000));
  it("P7 receives $700k", () => expect(getSeasonPrizeForPosition(7)).toBe(700_000));
  it("P8 receives $500k", () => expect(getSeasonPrizeForPosition(8)).toBe(500_000));
  it("P9 receives $350k", () => expect(getSeasonPrizeForPosition(9)).toBe(350_000));
  it("P10 receives $200k", () => expect(getSeasonPrizeForPosition(10)).toBe(200_000));
  it("P11 returns 0 (beyond table)", () => expect(getSeasonPrizeForPosition(11)).toBe(0));
  it("P0 returns 0 (invalid)", () => expect(getSeasonPrizeForPosition(0)).toBe(0));
  it("all 10 positions return non-zero amounts", () => {
    for (let p = 1; p <= 10; p++) {
      expect(getSeasonPrizeForPosition(p)).toBeGreaterThan(0);
    }
  });
});

// ─── Tests: rankTeamsByPoints ─────────────────────────────────────────────────
describe("rankTeamsByPoints", () => {
  it("ranks teams descending by seasonPoints", () => {
    const teams = [
      { id: "t1", seasonPoints: 80 },
      { id: "t2", seasonPoints: 120 },
      { id: "t3", seasonPoints: 50 },
    ];
    const ranked = rankTeamsByPoints(teams);
    expect(ranked[0].id).toBe("t2");
    expect(ranked[1].id).toBe("t1");
    expect(ranked[2].id).toBe("t3");
  });

  it("assigns correct 1-based positions", () => {
    const teams = [
      { id: "t1", seasonPoints: 100 },
      { id: "t2", seasonPoints: 60 },
    ];
    const ranked = rankTeamsByPoints(teams);
    expect(ranked[0].position).toBe(1);
    expect(ranked[1].position).toBe(2);
  });

  it("tie-break: equal points preserves stable sort order (earlier index wins)", () => {
    const teams = [
      { id: "t1", seasonPoints: 100 },
      { id: "t2", seasonPoints: 100 },
    ];
    const ranked = rankTeamsByPoints(teams);
    expect(ranked[0].id).toBe("t1");
    expect(ranked[1].id).toBe("t2");
  });

  it("does not mutate the input array", () => {
    const teams = [
      { id: "t1", seasonPoints: 50 },
      { id: "t2", seasonPoints: 100 },
    ];
    const original = [...teams];
    rankTeamsByPoints(teams);
    expect(teams[0].id).toBe(original[0].id);
  });

  it("handles single team", () => {
    const ranked = rankTeamsByPoints([{ id: "solo", seasonPoints: 42 }]);
    expect(ranked).toHaveLength(1);
    expect(ranked[0].position).toBe(1);
  });

  it("handles empty array", () => {
    expect(rankTeamsByPoints([])).toHaveLength(0);
  });
});

// ─── Tests: findDriversChampion ───────────────────────────────────────────────
describe("findDriversChampion", () => {
  const base = { teamId: "t1", seasonWins: 0, seasonPodiums: 0 };

  it("returns driver with highest seasonPoints", () => {
    const drivers = [
      { ...base, id: "d1", seasonPoints: 200, seasonWins: 5, seasonPodiums: 10 },
      { ...base, id: "d2", seasonPoints: 250, seasonWins: 7, seasonPodiums: 12 },
      { ...base, id: "d3", seasonPoints: 100, seasonWins: 2, seasonPodiums: 4 },
    ];
    expect(findDriversChampion(drivers)!.id).toBe("d2");
  });

  it("tie-break by seasonWins when seasonPoints equal", () => {
    const drivers = [
      { ...base, id: "d1", seasonPoints: 200, seasonWins: 5, seasonPodiums: 10 },
      { ...base, id: "d2", seasonPoints: 200, seasonWins: 8, seasonPodiums: 9 },
    ];
    expect(findDriversChampion(drivers)!.id).toBe("d2");
  });

  it("tie-break by seasonPodiums when points and wins equal", () => {
    const drivers = [
      { ...base, id: "d1", seasonPoints: 200, seasonWins: 5, seasonPodiums: 12 },
      { ...base, id: "d2", seasonPoints: 200, seasonWins: 5, seasonPodiums: 9 },
    ];
    expect(findDriversChampion(drivers)!.id).toBe("d1");
  });

  it("tie-break by driverId lexicographic order as final resort", () => {
    const drivers = [
      { ...base, id: "driver_b", seasonPoints: 200, seasonWins: 5, seasonPodiums: 10 },
      { ...base, id: "driver_a", seasonPoints: 200, seasonWins: 5, seasonPodiums: 10 },
    ];
    expect(findDriversChampion(drivers)!.id).toBe("driver_a");
  });

  it("does not mutate input array", () => {
    const drivers = [
      { ...base, id: "d2", seasonPoints: 200, seasonWins: 5, seasonPodiums: 10 },
      { ...base, id: "d1", seasonPoints: 250, seasonWins: 7, seasonPodiums: 12 },
    ];
    const originalFirst = drivers[0].id;
    findDriversChampion(drivers);
    expect(drivers[0].id).toBe(originalFirst);
  });

  it("handles single driver", () => {
    const drivers = [{ ...base, id: "d1", seasonPoints: 50, seasonWins: 1, seasonPodiums: 3 }];
    expect(findDriversChampion(drivers)!.id).toBe("d1");
  });

  it("returns null for empty array", () => {
    expect(findDriversChampion([])).toBeNull();
  });
});
