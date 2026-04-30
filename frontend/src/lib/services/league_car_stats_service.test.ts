import { describe, it, expect } from 'vitest';
import { computeTeamAvg } from './league_car_stats_service.svelte';

describe('computeTeamAvg', () => {
    it('averages two full car slots', () => {
        const result = computeTeamAvg({
            '0': { aero: 10, powertrain: 12, chassis: 8, reliability: 6 },
            '1': { aero: 14, powertrain: 8,  chassis: 12, reliability: 10 },
        });
        expect(result.aero).toBe(12);
        expect(result.powertrain).toBe(10);
        expect(result.chassis).toBe(10);
        expect(result.reliability).toBe(8);
    });

    it('uses only the available slot when one is missing', () => {
        const result = computeTeamAvg({
            '0': { aero: 10, powertrain: 5, chassis: 7, reliability: 3 },
        });
        expect(result.aero).toBe(10);
        expect(result.powertrain).toBe(5);
        expect(result.chassis).toBe(7);
        expect(result.reliability).toBe(3);
    });

    it('returns zeros for empty carStats', () => {
        const result = computeTeamAvg({});
        expect(result.aero).toBe(0);
        expect(result.powertrain).toBe(0);
        expect(result.chassis).toBe(0);
        expect(result.reliability).toBe(0);
    });

    it('treats missing stat within a slot as 0 and excludes it from avg', () => {
        // car 0 has no reliability; car 1 has reliability 8
        const result = computeTeamAvg({
            '0': { aero: 10, powertrain: 10, chassis: 10 },
            '1': { aero: 10, powertrain: 10, chassis: 10, reliability: 8 },
        });
        // only car 1 contributes to reliability avg (car 0's value is 0, filtered out)
        expect(result.reliability).toBe(8);
    });

    it('rounds averages to nearest integer', () => {
        const result = computeTeamAvg({
            '0': { aero: 5, powertrain: 5, chassis: 5, reliability: 5 },
            '1': { aero: 6, powertrain: 6, chassis: 6, reliability: 6 },
        });
        // avg of 5 and 6 = 5.5, rounds to 6
        expect(result.aero).toBe(6);
    });

    it('handles three car slots by averaging all', () => {
        const result = computeTeamAvg({
            '0': { aero: 3, powertrain: 3, chassis: 3, reliability: 3 },
            '1': { aero: 6, powertrain: 6, chassis: 6, reliability: 6 },
            '2': { aero: 9, powertrain: 9, chassis: 9, reliability: 9 },
        });
        expect(result.aero).toBe(6);
    });
});
