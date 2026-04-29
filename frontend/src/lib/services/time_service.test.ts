import { describe, it, expect } from 'vitest';
import { RaceWeekStatus } from './time_service.svelte';
import { timeService } from './time_service.svelte';

function makeDate(weekday: number, hour: number): Date {
    const d = new Date(2026, 0, 4); // Sunday 2026-01-04 anchor
    d.setDate(d.getDate() + weekday);
    d.setHours(hour, 0, 0, 0);
    return d;
}

describe('TimeService.getRaceWeekStatus()', () => {
    it('returns PRACTICE on Monday', () => {
        expect(timeService.getRaceWeekStatus(makeDate(1, 10))).toBe(RaceWeekStatus.PRACTICE);
    });
    it('returns PRACTICE on Wednesday', () => {
        expect(timeService.getRaceWeekStatus(makeDate(3, 9))).toBe(RaceWeekStatus.PRACTICE);
    });
    it('returns PRACTICE on Friday', () => {
        expect(timeService.getRaceWeekStatus(makeDate(5, 23))).toBe(RaceWeekStatus.PRACTICE);
    });
    it('returns PRACTICE on Saturday before 14:00', () => {
        expect(timeService.getRaceWeekStatus(makeDate(6, 13))).toBe(RaceWeekStatus.PRACTICE);
    });
    it('returns QUALIFYING on Saturday at 14:00', () => {
        expect(timeService.getRaceWeekStatus(makeDate(6, 14))).toBe(RaceWeekStatus.QUALIFYING);
    });
    it('returns RACE_STRATEGY on Saturday after 14:00', () => {
        expect(timeService.getRaceWeekStatus(makeDate(6, 18))).toBe(RaceWeekStatus.RACE_STRATEGY);
    });
    it('returns RACE_STRATEGY on Sunday before 14:00', () => {
        expect(timeService.getRaceWeekStatus(makeDate(0, 8))).toBe(RaceWeekStatus.RACE_STRATEGY);
    });
    it('returns RACE on Sunday 14:00–15:59', () => {
        expect(timeService.getRaceWeekStatus(makeDate(0, 14))).toBe(RaceWeekStatus.RACE);
        expect(timeService.getRaceWeekStatus(makeDate(0, 15))).toBe(RaceWeekStatus.RACE);
    });
    it('returns POST_RACE on Sunday from 16:00', () => {
        expect(timeService.getRaceWeekStatus(makeDate(0, 16))).toBe(RaceWeekStatus.POST_RACE);
        expect(timeService.getRaceWeekStatus(makeDate(0, 23))).toBe(RaceWeekStatus.POST_RACE);
    });
});

describe('TimeService.getIsRepairLocked()', () => {
    // makeDate uses Sun 2026-01-04 as anchor. getDay(): 0=Sun,1=Mon,...,6=Sat
    it('Saturday 12:59 (PRACTICE) → not locked', () => {
        const d = makeDate(6, 12); d.setMinutes(59);
        expect(timeService.getIsRepairLocked(d)).toBe(false);
    });
    it('Saturday 13:00 (still PRACTICE) → locked (1h pre-lock)', () => {
        expect(timeService.getIsRepairLocked(makeDate(6, 13))).toBe(true);
    });
    it('Saturday 14:00 (QUALIFYING) → locked', () => {
        expect(timeService.getIsRepairLocked(makeDate(6, 14))).toBe(true);
    });
    it('Saturday 18:00 (RACE_STRATEGY) → locked', () => {
        expect(timeService.getIsRepairLocked(makeDate(6, 18))).toBe(true);
    });
    it('Sunday 15:00 (RACE) → locked', () => {
        expect(timeService.getIsRepairLocked(makeDate(0, 15))).toBe(true);
    });
    it('Sunday 16:00 (POST_RACE) → locked', () => {
        expect(timeService.getIsRepairLocked(makeDate(0, 16))).toBe(true);
    });
    it('Monday 00:01 (PRACTICE) → not locked', () => {
        const d = makeDate(1, 0); d.setMinutes(1);
        expect(timeService.getIsRepairLocked(d)).toBe(false);
    });
    it('Wednesday midweek (PRACTICE) → not locked', () => {
        expect(timeService.getIsRepairLocked(makeDate(3, 14))).toBe(false);
    });
});

describe('TimeService.getTimeUntil()', () => {
    it('returns a Duration with valid fields for QUALIFYING', () => {
        const result = timeService.getTimeUntil(RaceWeekStatus.QUALIFYING);
        if (result !== null) {
            expect(result).toHaveProperty('days');
            expect(result).toHaveProperty('hours');
            expect(result).toHaveProperty('minutes');
            expect(result).toHaveProperty('seconds');
            expect(result.days).toBeGreaterThanOrEqual(0);
            expect(result.hours).toBeLessThan(24);
            expect(result.minutes).toBeLessThan(60);
            expect(result.seconds).toBeLessThan(60);
        }
    });
    it('returns null for unsupported statuses', () => {
        expect(timeService.getTimeUntil(RaceWeekStatus.PRACTICE)).toBeNull();
    });
});
