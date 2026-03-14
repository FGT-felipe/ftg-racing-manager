import { db } from '$lib/firebase/config';
import { doc, onSnapshot } from 'firebase/firestore';
import { browser } from '$app/environment';
import { authStore } from './auth.svelte';

export interface ManagerProfile {
    uid: string;
    firstName: string;
    lastName: string;
    role: string;
    reputation: number;
    country: string;
    nationality: string;
    gender: string;
    birthDate: string;
    backgroundId: string;
    teamId?: string;
}

export function createManagerStore() {
    let profile = $state<ManagerProfile | null>(null);
    let isLoading = $state(true);
    let unsubscribe: (() => void) | null = null;

    function init() {
        $effect(() => {
            const user = authStore.user;

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            if (!user) {
                profile = null;
                isLoading = false;
                return;
            }

            if (!browser) return;

            isLoading = true;
            unsubscribe = onSnapshot(doc(db, 'managers', user.uid), (snapshot) => {
                if (snapshot.exists()) {
                    profile = {
                        uid: snapshot.id,
                        ...snapshot.data()
                    } as ManagerProfile;
                } else {
                    profile = null;
                }
                isLoading = false;
            }, (error) => {
                console.error("Error fetching manager profile:", error);
                isLoading = false;
            });

            return () => {
                if (unsubscribe) unsubscribe();
            };
        });
    }

    return {
        async createProfile(data: {
            firstName: string;
            lastName: string;
            nationality: string;
            country: string;
            gender: string;
            birthDate: string;
            backgroundId: string;
        }) {
            const user = authStore.user;
            if (!user) return;

            const { setDoc, serverTimestamp } = await import('firebase/firestore');

            const profileData = {
                uid: user.uid,
                ...data,
                reputation: 50,
                teamId: '',
                createdAt: serverTimestamp()
            };

            await setDoc(doc(db, 'managers', user.uid), profileData);
        },
        get profile() { return profile; },
        get isLoading() { return isLoading; },
        init
    };
}

export const managerStore = createManagerStore();
