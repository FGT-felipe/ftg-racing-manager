import { initializeApp, getApps, getApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getFunctions } from 'firebase/functions';
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
import { browser } from '$app/environment';

// Replace with your actual Firebase config keys
// Ensure these match your existing project's variables
const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID
};

export const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
export const auth = getAuth(app);
export const db = getFirestore(app);
export const functions = getFunctions(app);

// App Check — guards Cloud Functions from unauthenticated/bot calls.
// Requires VITE_RECAPTCHA_SITE_KEY in .env.local.
// Steps to activate:
//   1. Firebase Console → App Check → Register your web app with reCAPTCHA v3
//   2. Copy the site key and add it to .env.local as VITE_RECAPTCHA_SITE_KEY
//   3. Uncomment enforceAppCheck in functions/src/domains/admin/tools.ts
//   4. Deploy functions
if (browser && import.meta.env.VITE_RECAPTCHA_SITE_KEY) {
    initializeAppCheck(app, {
        provider: new ReCaptchaV3Provider(import.meta.env.VITE_RECAPTCHA_SITE_KEY),
        isTokenAutoRefreshEnabled: true,
    });
}
