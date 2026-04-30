import { getFirestore, collection, query, where, getDocs, documentId } from 'firebase/firestore';

export interface CarStatAvg {
    aero: number;
    powertrain: number;
    chassis: number;
    reliability: number;
}

export interface TeamChartData {
    teamId: string;
    name: string;
    position: number;
    aero: number;
    powertrain: number;
    chassis: number;
    reliability: number;
}

/**
 * Computes the average of each car stat across all car slots.
 * Pure function exported for unit tests.
 * @param carStats Record<slotIndex, Record<statKey, level>>
 */
export function computeTeamAvg(carStats: Record<string, Record<string, number>>): CarStatAvg {
    const slots = Object.values(carStats);
    const result: CarStatAvg = { aero: 0, powertrain: 0, chassis: 0, reliability: 0 };
    if (slots.length === 0) return result;
    for (const key of ['aero', 'powertrain', 'chassis', 'reliability'] as const) {
        const vals = slots.map(s => s[key] ?? 0).filter(v => v > 0);
        result[key] = vals.length > 0 ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : 0;
    }
    return result;
}

/**
 * Fetches carStats from Firestore for a list of teamIds and returns per-team averages.
 * Firestore `in` supports up to 30 IDs — league size never exceeds this limit.
 * @param teamIds Firestore document IDs to fetch
 * @returns Map of teamId → CarStatAvg
 */
export async function fetchLeagueCarStats(
    teamIds: string[]
): Promise<Map<string, CarStatAvg>> {
    if (teamIds.length === 0) return new Map();
    const db = getFirestore();
    const snap = await getDocs(
        query(collection(db, 'teams'), where(documentId(), 'in', teamIds))
    );
    const result = new Map<string, CarStatAvg>();
    for (const docSnap of snap.docs) {
        const data = docSnap.data();
        if (data.carStats) {
            result.set(docSnap.id, computeTeamAvg(data.carStats));
        }
    }
    return result;
}
