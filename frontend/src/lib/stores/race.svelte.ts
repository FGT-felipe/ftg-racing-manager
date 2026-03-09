import { db } from '$lib/firebase/config';
import { doc, collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore';

export interface RaceState {
    id: string;
    seasonId: string;
    circuitId: string;
    status: 'PENDING' | 'QUALIFYING' | 'RACING' | 'FINISHED';
    qualyGrid?: Record<string, number>; // driverId -> position
    finalPositions?: Record<string, number>; // driverId -> position
    dnfs?: string[];
    totalLaps: number;
}

export interface LapEvent {
    lap: number;
    driverId: string;
    desc: string;
    type: 'INFO' | 'OVERTAKE' | 'PIT' | 'DNF';
}

export interface LapData {
    lap: number;
    lapTimes: Record<string, number>; // driverId -> time in seconds
    positions: Record<string, number>; // driverId -> current lap position
    tyres: Record<string, string>; // driverId -> soft/medium/hard
    events: LapEvent[];
}

export function createRaceStore(seasonId: string, raceId: string) {
    let state = $state<{
        race: RaceState | null;
        currentLap: LapData | null;
        allLaps: LapData[];
        loading: boolean;
        error: Error | null;
    }>({
        race: null,
        currentLap: null,
        allLaps: [],
        loading: true,
        error: null
    });

    const raceDocId = `${seasonId}_${raceId}`;
    const raceRef = doc(db, 'races', raceDocId);
    const lapsRef = collection(raceRef, 'laps');

    // Real-time subscription to the main race document
    const unsubscribeRace = onSnapshot(
        raceRef,
        (snapshot) => {
            if (snapshot.exists()) {
                state.race = { id: snapshot.id, ...snapshot.data() } as RaceState;
            } else {
                state.race = null;
            }
            state.loading = false;
        },
        (error) => {
            console.error('Race subscription error:', error);
            state.error = error;
            state.loading = false;
        }
    );

    // Real-time subscription to the laps subcollection (ordered by lap number)
    const lapsQuery = query(lapsRef, orderBy('lap', 'asc'));
    const unsubscribeLaps = onSnapshot(
        lapsQuery,
        (snapshot) => {
            const laps = snapshot.docs.map((d) => d.data() as LapData);
            state.allLaps = laps;
            if (laps.length > 0) {
                state.currentLap = laps[laps.length - 1];
            }
        },
        (error) => {
            console.error('Laps subscription error:', error);
            state.error = error;
        }
    );

    return {
        get value() {
            return state;
        },
        destroy() {
            unsubscribeRace();
            unsubscribeLaps();
        }
    };
}
