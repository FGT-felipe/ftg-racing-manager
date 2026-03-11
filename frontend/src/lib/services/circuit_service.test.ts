import { describe, it, expect } from 'vitest';
import { circuitService } from './circuit_service.svelte';

const KNOWN_CIRCUIT_IDS = ['mexico', 'vegas', 'interlagos', 'miami'];

describe('CircuitService', () => {
    describe('getCircuitProfile()', () => {
        it('returns the correct profile for "mexico"', () => {
            const profile = circuitService.getCircuitProfile('mexico');
            expect(profile.id).toBe('mexico');
            expect(profile.baseLapTime).toBeGreaterThan(0);
            expect(profile.laps).toBeGreaterThan(0);
        });

        it('returns the correct profile for "vegas"', () => {
            const profile = circuitService.getCircuitProfile('vegas');
            expect(profile.id).toBe('vegas');
        });

        it('is case-insensitive (handles uppercase input)', () => {
            const lower = circuitService.getCircuitProfile('mexico');
            const upper = circuitService.getCircuitProfile('MEXICO');
            expect(lower.id).toBe(upper.id);
        });

        it('returns a fallback profile for unknown circuit IDs', () => {
            const unknown = circuitService.getCircuitProfile('unknown-track-xyz');
            expect(unknown).toBeDefined();
            expect(unknown.baseLapTime).toBeGreaterThan(0);
        });
    });

    describe('aero/powertrain/chassis weights', () => {
        it('each known circuit has weights that sum to ~1.0', () => {
            for (const id of KNOWN_CIRCUIT_IDS) {
                const p = circuitService.getCircuitProfile(id);
                const sum = p.aeroWeight + p.powertrainWeight + p.chassisWeight;
                expect(sum).toBeCloseTo(1.0, 1);
            }
        });
    });

    describe('getAllCircuits()', () => {
        it('returns all hardcoded circuits', () => {
            const all = circuitService.getAllCircuits();
            expect(all.length).toBeGreaterThanOrEqual(KNOWN_CIRCUIT_IDS.length);
        });

        it('every circuit has a non-empty characteristics object', () => {
            const all = circuitService.getAllCircuits();
            for (const c of all) {
                expect(Object.keys(c.characteristics).length).toBeGreaterThan(0);
            }
        });
    });
});
