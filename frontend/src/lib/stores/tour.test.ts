import { describe, it, expect, beforeEach } from 'vitest';
import { createTourStore } from './tour.svelte';

describe('TourStore', () => {
    let store: ReturnType<typeof createTourStore>;

    beforeEach(() => {
        store = createTourStore();
    });

    it('starts inactive with currentStep null', () => {
        expect(store.isActive).toBe(false);
        expect(store.currentStep).toBeNull();
    });

    it('start() activates the tour at step 0', () => {
        store.start();
        expect(store.isActive).toBe(true);
        expect(store.currentStepIndex).toBe(0);
        expect(store.currentStep).not.toBeNull();
        expect(store.currentStep?.id).toBe('raceStatus');
    });

    it('next() advances to the next step', () => {
        store.start();
        store.next();
        expect(store.currentStepIndex).toBe(1);
        expect(store.currentStep?.id).toBe('checklist');
    });

    it('prev() goes back one step', () => {
        store.start();
        store.next();
        store.next();
        store.prev();
        expect(store.currentStepIndex).toBe(1);
    });

    it('prev() does nothing on the first step', () => {
        store.start();
        store.prev();
        expect(store.currentStepIndex).toBe(0);
    });

    it('skip() deactivates the tour', () => {
        store.start();
        store.skip();
        expect(store.isActive).toBe(false);
        expect(store.currentStep).toBeNull();
    });

    it('complete() deactivates the tour', () => {
        store.start();
        store.complete();
        expect(store.isActive).toBe(false);
        expect(store.currentStep).toBeNull();
    });

    it('next() on the last step calls complete() and deactivates', () => {
        store.start();
        const totalSteps = store.steps.length;
        for (let i = 0; i < totalSteps - 1; i++) {
            store.next();
        }
        expect(store.isLastStep).toBe(true);
        store.next();
        expect(store.isActive).toBe(false);
        expect(store.currentStep).toBeNull();
    });

    it('next() does nothing when inactive', () => {
        store.next();
        expect(store.isActive).toBe(false);
        expect(store.currentStepIndex).toBe(0);
    });

    it('start() always resets to step 0', () => {
        store.start();
        store.next();
        store.next();
        store.start();
        expect(store.currentStepIndex).toBe(0);
        expect(store.isActive).toBe(true);
    });
});
