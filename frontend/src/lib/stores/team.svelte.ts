import { db } from '$lib/firebase/config';
import { collection, query, where, onSnapshot, limit } from 'firebase/firestore';
import type { Team } from '$lib/types';
import { browser } from '$app/environment';

export function createTeamStore() {
    let currentTeam = $state<Team | null>(null);
    let isLoading = $state<boolean>(true);

    let unsubscribeFirestore: (() => void) | null = null;

    return {
        init(user: any) {
            if (unsubscribeFirestore) {
                unsubscribeFirestore();
                unsubscribeFirestore = null;
            }

            if (!user) {
                currentTeam = null;
                isLoading = false;
                return;
            }

            if (!browser || typeof db === 'undefined') {
                isLoading = false;
                return;
            }

            isLoading = true;

            const q = query(
                collection(db, 'teams'),
                where('managerId', '==', user.uid),
                limit(1)
            );

            unsubscribeFirestore = onSnapshot(
                q,
                (snapshot) => {
                    if (!snapshot.empty) {
                        const doc = snapshot.docs[0];
                        const data = doc.data();

                        currentTeam = {
                            id: doc.id,
                            name: data.name,
                            budget: data.budget,
                            prestige: data.prestige,
                            currentSeasonId: data.currentSeasonId,
                            weekStatus: data.weekStatus,
                            ...data
                        } as Team;

                        console.log(`Equipo encontrado: ${currentTeam.name}`);
                    } else {
                        currentTeam = null;
                        console.log(`ERROR: No hay equipo en Firestore para el UID: ${user.uid}`);
                    }
                    isLoading = false;
                },
                (error) => {
                    console.error('Error fetching team:', error);
                    isLoading = false;
                }
            );
        },
        get value() {
            return {
                team: currentTeam,
                loading: isLoading
            };
        },
        get formattedBudget() {
            if (!currentTeam) return '$0M';
            // simple formatter for million representation
            return `$${(currentTeam.budget / 1000000).toFixed(1)}M`;
        }
    };
}

// Global instance 
export const teamStore = createTeamStore();
