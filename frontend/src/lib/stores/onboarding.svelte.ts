import { db } from '$lib/firebase/config';
import { collection, onSnapshot } from 'firebase/firestore';
import { browser } from '$app/environment';

/**
 * Minimal team shape needed for the team-selection onboarding view.
 * Overlaid on top of the universe snapshot to reflect live availability.
 */
export interface LiveTeam {
    id: string;
    isBot: boolean;
    managerId?: string;
    budget: number;
    seasonPoints?: number;
    [key: string]: unknown;
}

/**
 * Minimal driver shape needed to display team rosters during onboarding.
 */
export interface LiveDriver {
    id: string;
    teamId: string;
    name: string;
    countryCode?: string;
    [key: string]: unknown;
}

/**
 * Store for the team-selection onboarding page.
 * Subscribes to the full `teams` and `drivers` collections so the page
 * can overlay live availability (isBot, budget) on the universe snapshot.
 *
 * Only active while `init()` is in scope — call it once inside the component.
 */
function createOnboardingStore() {
    let teams = $state<LiveTeam[]>([]);
    let drivers = $state<LiveDriver[]>([]);
    let loading = $state(true);
    let error = $state<string | null>(null);

    let unsubTeams: (() => void) | null = null;
    let unsubDrivers: (() => void) | null = null;

    /** Start real-time listeners for teams + drivers. */
    function init() {
        $effect(() => {
            if (!browser) return;

            loading = true;

            unsubTeams = onSnapshot(
                collection(db, 'teams'),
                (snap) => {
                    teams = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() } as LiveTeam));
                    checkLoaded();
                },
                (err) => {
                    console.error('[onboardingStore] teams error:', err);
                    error = err.message;
                }
            );

            unsubDrivers = onSnapshot(
                collection(db, 'drivers'),
                (snap) => {
                    drivers = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() } as LiveDriver));
                    checkLoaded();
                },
                (err) => {
                    console.error('[onboardingStore] drivers error:', err);
                    error = err.message;
                }
            );

            return () => {
                unsubTeams?.();
                unsubDrivers?.();
                unsubTeams = null;
                unsubDrivers = null;
            };
        });
    }

    function checkLoaded() {
        if (teams.length > 0 && drivers.length >= 0) {
            loading = false;
        }
    }

    return {
        get teams() { return teams; },
        get drivers() { return drivers; },
        get loading() { return loading; },
        get error() { return error; },
        init,
    };
}

export const onboardingStore = createOnboardingStore();
