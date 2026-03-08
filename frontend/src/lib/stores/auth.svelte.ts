import {
    onAuthStateChanged,
    signOut as firebaseSignOut,
    GoogleAuthProvider,
    signInWithPopup,
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    type User
} from 'firebase/auth';
import { auth } from '$lib/firebase/config';
import { goto } from '$app/navigation';
import { browser } from '$app/environment';

export function createAuthStore() {
    let user = $state<User | null>(null);
    let loading = $state<boolean>(true);

    onAuthStateChanged(auth, (firebaseUser) => {
        console.log('🛡️ Auth State Changed:', firebaseUser ? `User logged in: ${firebaseUser.uid}` : 'No user');
        user = firebaseUser;
        // Only flip loading flag once Firebase has resolved the session
        if (loading) {
            loading = false;
        }
    });

    return {
        get user() {
            return user;
        },
        get loading() {
            return loading;
        },
        get isAdmin() {
            // Placeholder admin check until custom claims are implemented from SimEngine
            // Example: return user?.uid === 'YOUR_ADMIN_UID';
            return false;
        },
        async loginWithGoogle() {
            try {
                const provider = new GoogleAuthProvider();
                await signInWithPopup(auth, provider);
                if (browser) await goto('/');
            } catch (error) {
                console.error("Google login error:", error);
                throw error;
            }
        },
        async loginWithEmail(email: string, pass: string) {
            try {
                await signInWithEmailAndPassword(auth, email, pass);
                if (browser) await goto('/');
            } catch (error) {
                console.error("Email login error:", error);
                throw error;
            }
        },
        async registerWithEmail(email: string, pass: string) {
            try {
                await createUserWithEmailAndPassword(auth, email, pass);
                if (browser) await goto('/');
            } catch (error) {
                console.error("Email register error:", error);
                throw error;
            }
        },
        async signOut() {
            try {
                await firebaseSignOut(auth);
            } catch (error) {
                console.error("Error signing out:", error);
            }
        }
    };
}

export const authStore = createAuthStore();
