import { db } from '$lib/firebase/config';
import { collection, query, where, onSnapshot, limit } from 'firebase/firestore';
import { authStore } from '$lib/stores/auth.svelte';
import { browser } from '$app/environment';
import type { Team } from '$lib/types';
import { TEAM_RENAME_COST } from '$lib/constants/economics';
import { formatMoney } from '$lib/utils/format';

export function createTeamStore() {
    let currentTeam = $state<Team | null>(null);
    let isLoading = $state<boolean>(true);

    let unsubscribeFirestore: (() => void) | null = null;

    return {
        init(user: any) {
            // Support for Playwright/Testing Mocking
            if (browser && (window as any).__MOCK_TEAM__) {
                console.debug('[TeamStore] Initialization: Mock data detected and applied.');
                currentTeam = (window as any).__MOCK_TEAM__;
                isLoading = false; 
                return;
            }

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
                            leagueId: data.leagueId,
                            budget: data.budget,
                            prestige: data.prestige,
                            currentSeasonId: data.currentSeasonId,
                            weekStatus: data.weekStatus,
                            ...data
                        } as Team;

                        console.debug('[TeamStore] Snapshot update: active team data synchronized.', { 
                            id: currentTeam.id, 
                            name: currentTeam.name,
                            leagueId: currentTeam.leagueId
                        });
                    } else {
                        currentTeam = null;
                        console.error('[TeamStore] Snapshot update error: No team document found for authenticated manager UID:', user.uid);
                    }
                    isLoading = false;
                },
                (error) => {
                    console.error('[TeamStore] Snapshot subscription failed:', error);
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
            if (!currentTeam) return '$0';
            return formatMoney(currentTeam.budget);
        },
        async claimTeam(teamId: string) {
            const user = authStore.user;
            if (!user) throw new Error("Authentication required");

            const { doc, runTransaction } = await import('firebase/firestore');
            const teamRef = doc(db, 'teams', teamId);

            await runTransaction(db, async (transaction) => {
                const teamDoc = await transaction.get(teamRef);

                if (!teamDoc.exists()) {
                    throw new Error("Team does not exist");
                }

                const data = teamDoc.data();
                if (data?.managerId) {
                    throw new Error("Team already taken");
                }

                transaction.update(teamRef, {
                    managerId: user.uid,
                    isBot: false
                });
            });
        },
        async renameTeam(newName: string) {
            if (!currentTeam) throw new Error("No team active");
            const newNameTrimmed = newName.trim();
            if (!newNameTrimmed || newNameTrimmed === currentTeam.name) return;

            const { doc, runTransaction } = await import('firebase/firestore');
            const teamRef = doc(db, 'teams', currentTeam.id);
            const nameChangeCost = TEAM_RENAME_COST;

            await runTransaction(db, async (transaction) => {
                const teamDoc = await transaction.get(teamRef);
                if (!teamDoc.exists()) throw new Error("Team not found");

                const data = teamDoc.data();
                const currentCount = data.nameChangeCount || 0;
                const budget = data.budget || 0;
                const isFirstChange = currentCount === 0;

                if (!isFirstChange && budget < nameChangeCost) {
                    throw new Error("Insufficient budget for name change");
                }

                const costApplied = isFirstChange ? 0 : nameChangeCost;

                transaction.update(teamRef, {
                    name: newNameTrimmed,
                    budget: budget - costApplied,
                    nameChangeCount: currentCount + 1
                });
            });
        },
        async updateTransferBudgetPercentage(percentage: number) {
            if (!currentTeam) return;
            const { doc, updateDoc } = await import('firebase/firestore');
            const teamRef = doc(db, 'teams', currentTeam.id);
            await updateDoc(teamRef, {
                transferBudgetPercentage: percentage
            });
        }
    };
}

// Global instance 
export const teamStore = createTeamStore();
