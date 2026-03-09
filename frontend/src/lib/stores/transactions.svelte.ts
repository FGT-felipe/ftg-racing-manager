import { db } from '$lib/firebase/config';
import {
    collection,
    query,
    orderBy,
    limit,
    onSnapshot
} from 'firebase/firestore';
import { teamStore } from './team.svelte';

export interface Transaction {
    id: string;
    description: string;
    amount: number;
    date: string;
    type: string;
}

export function createTransactionStore() {
    let transactions = $state<Transaction[]>([]);
    let isLoading = $state(true);
    let unsubscribe: (() => void) | null = null;

    function init() {
        $effect(() => {
            const teamId = teamStore.value.team?.id;

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            if (!teamId) {
                transactions = [];
                isLoading = false;
                return;
            }

            isLoading = true;
            const q = query(
                collection(db, 'teams', teamId, 'transactions'),
                orderBy('date', 'desc'),
                limit(50)
            );

            unsubscribe = onSnapshot(q, (snapshot) => {
                transactions = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                })) as Transaction[];
                isLoading = false;
            }, (error) => {
                console.error("Error fetching transactions:", error);
                isLoading = false;
            });

            return () => {
                if (unsubscribe) unsubscribe();
            };
        });
    }

    return {
        get transactions() { return transactions; },
        get isLoading() { return isLoading; },
        init
    };
}

export const transactionStore = createTransactionStore();
