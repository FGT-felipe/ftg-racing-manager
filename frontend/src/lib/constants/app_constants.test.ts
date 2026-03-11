import { describe, it, expect } from 'vitest';
import {
    MAX_PRACTICE_LAPS_PER_DRIVER,
    DEFAULT_DRIVERS_PER_TEAM,
    BOGOTA_TIMEZONE,
    ACADEMY_TRAINEE_WEEKLY_WAGE,
} from './app_constants';

describe('app_constants', () => {
    it('MAX_PRACTICE_LAPS_PER_DRIVER equals 6 (Flutter: kMaxPracticeLapsPerDriver)', () => {
        expect(MAX_PRACTICE_LAPS_PER_DRIVER).toBe(6);
    });

    it('DEFAULT_DRIVERS_PER_TEAM equals 2', () => {
        expect(DEFAULT_DRIVERS_PER_TEAM).toBe(2);
    });

    it('BOGOTA_TIMEZONE is the correct IANA identifier', () => {
        expect(BOGOTA_TIMEZONE).toBe('America/Bogota');
    });

    it('ACADEMY_TRAINEE_WEEKLY_WAGE equals 10000', () => {
        expect(ACADEMY_TRAINEE_WEEKLY_WAGE).toBe(10_000);
    });
});
