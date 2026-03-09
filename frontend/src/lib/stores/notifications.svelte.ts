import { db } from '$lib/firebase/config';
import {
    collection,
    query,
    orderBy,
    limit,
    onSnapshot,
    doc,
    updateDoc,
    deleteDoc,
    Timestamp
} from 'firebase/firestore';
import { teamStore } from './team.svelte';

export interface AppNotification {
    id: string;
    title: string;
    message: string;
    type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR';
    isRead: boolean;
    timestamp: any;
    actionRoute?: string;
}

export function createNotificationStore() {
    let notifications = $state<AppNotification[]>([]);
    let isLoading = $state(true);
    let unsubscribe: (() => void) | null = null;

    function init() {
        // We watch the teamStore.currentTeam as the source of truth
        $effect(() => {
            const teamId = teamStore.value.team?.id;

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            if (!teamId) {
                notifications = [];
                isLoading = false;
                return;
            }

            isLoading = true;
            const q = query(
                collection(db, 'teams', teamId, 'notifications'),
                orderBy('timestamp', 'desc'),
                limit(20)
            );

            unsubscribe = onSnapshot(q, (snapshot) => {
                notifications = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                })) as AppNotification[];
                isLoading = false;
            }, (error) => {
                console.error("Error fetching notifications:", error);
                isLoading = false;
            });

            return () => {
                if (unsubscribe) unsubscribe();
            };
        });
    }

    return {
        get notifications() { return notifications; },
        get isLoading() { return isLoading; },
        get unreadCount() { return notifications.filter(n => !n.isRead).length; },
        init,
        async markAsRead(notificationId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;
            await updateDoc(doc(db, 'teams', teamId, 'notifications', notificationId), {
                isRead: true
            });
        },
        async deleteNotification(notificationId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;
            await deleteDoc(doc(db, 'teams', teamId, 'notifications', notificationId));
        },
        async addNotification(data: { title: string, message: string, type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR', actionRoute?: string }) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const { addDoc, serverTimestamp } = await import('firebase/firestore');
            await addDoc(collection(db, 'teams', teamId, 'notifications'), {
                ...data,
                isRead: false,
                timestamp: serverTimestamp()
            });
        }
    };
}

export const notificationStore = createNotificationStore();
