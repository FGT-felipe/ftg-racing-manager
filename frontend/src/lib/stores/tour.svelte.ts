export type TourStepPosition = 'top' | 'bottom' | 'left' | 'right';

export interface TourStep {
    id: string;
    route: string;
    targetSelector: string;
    titleKey: string;
    descriptionKey: string;
    position: TourStepPosition;
}

const TOUR_STEPS: TourStep[] = [
    {
        id: 'raceStatus',
        route: '/',
        targetSelector: '[data-tour="race-status-hero"]',
        titleKey: 'tour_step_race_status_title',
        descriptionKey: 'tour_step_race_status_desc',
        position: 'bottom',
    },
    {
        id: 'checklist',
        route: '/',
        targetSelector: '[data-tour="preparation-checklist"]',
        titleKey: 'tour_step_checklist_title',
        descriptionKey: 'tour_step_checklist_desc',
        position: 'top',
    },
    {
        id: 'standings',
        route: '/',
        targetSelector: '[data-tour="standings-card"]',
        titleKey: 'tour_step_standings_title',
        descriptionKey: 'tour_step_standings_desc',
        position: 'top',
    },
    {
        id: 'management',
        route: '/management',
        targetSelector: '[data-tour="nav-management"]',
        titleKey: 'tour_step_management_title',
        descriptionKey: 'tour_step_management_desc',
        position: 'right',
    },
    {
        id: 'racing',
        route: '/racing',
        targetSelector: '[data-tour="nav-racing"]',
        titleKey: 'tour_step_racing_title',
        descriptionKey: 'tour_step_racing_desc',
        position: 'right',
    },
    {
        id: 'facilities',
        route: '/facilities',
        targetSelector: '[data-tour="nav-facilities"]',
        titleKey: 'tour_step_facilities_title',
        descriptionKey: 'tour_step_facilities_desc',
        position: 'right',
    },
    {
        id: 'academy',
        route: '/academy',
        targetSelector: '[data-tour="nav-academy"]',
        titleKey: 'tour_step_academy_title',
        descriptionKey: 'tour_step_academy_desc',
        position: 'right',
    },
    {
        id: 'market',
        route: '/market',
        targetSelector: '[data-tour="nav-market"]',
        titleKey: 'tour_step_market_title',
        descriptionKey: 'tour_step_market_desc',
        position: 'right',
    },
    {
        id: 'settings',
        route: '/settings',
        targetSelector: '[data-tour="tour-reactivate"]',
        titleKey: 'tour_step_settings_title',
        descriptionKey: 'tour_step_settings_desc',
        position: 'top',
    },
];

export function createTourStore() {
    let isActive = $state(false);
    let currentStepIndex = $state(0);
    const steps = TOUR_STEPS;

    const currentStep = $derived(isActive ? (steps[currentStepIndex] ?? null) : null);
    const isFirstStep = $derived(currentStepIndex === 0);
    const isLastStep = $derived(currentStepIndex === steps.length - 1);

    function start() {
        currentStepIndex = 0;
        isActive = true;
    }

    function next() {
        if (!isActive) return;
        if (isLastStep) {
            complete();
        } else {
            currentStepIndex += 1;
        }
    }

    function prev() {
        if (!isActive || isFirstStep) return;
        currentStepIndex -= 1;
    }

    function skip() {
        isActive = false;
    }

    function complete() {
        isActive = false;
    }

    return {
        get isActive() { return isActive; },
        get currentStepIndex() { return currentStepIndex; },
        get steps() { return steps; },
        get currentStep() { return currentStep; },
        get isFirstStep() { return isFirstStep; },
        get isLastStep() { return isLastStep; },
        start,
        next,
        prev,
        skip,
        complete,
    };
}

export const tourStore = createTourStore();
