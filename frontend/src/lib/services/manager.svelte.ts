import { db } from '$lib/firebase/config';
import { collection, query, where, getDocs } from 'firebase/firestore';

export interface ManagerProfile {
    name: string;
    country: string;
}

export const managerService = {
    /**
     * Fetches manager display profiles for a list of teams.
     * Batches queries in groups of 30 to respect Firestore `in` limit.
     * @param teams - Array of { id, managerId } pairs to look up.
     * @returns Map of teamId → { name, country }.
     */
    async fetchManagerProfiles(
        teams: { id: string; managerId: string }[]
    ): Promise<Record<string, ManagerProfile>> {
        const managerIds = teams.map((t) => t.managerId);
        const map: Record<string, ManagerProfile> = {};

        for (let i = 0; i < managerIds.length; i += 30) {
            const chunk = managerIds.slice(i, i + 30);
            const snap = await getDocs(
                query(collection(db, 'managers'), where('uid', 'in', chunk))
            );
            for (const docSnap of snap.docs) {
                const d = docSnap.data();
                const matchedTeam = teams.find((t) => t.managerId === docSnap.id);
                if (matchedTeam) {
                    map[matchedTeam.id] = {
                        name: `${d.firstName ?? ''} ${d.lastName ?? ''}`.trim(),
                        country: d.country ?? '',
                    };
                }
            }
        }

        return map;
    },
};
