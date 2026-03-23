/**
 * Centralized firebase-admin initialization.
 * Import `db` and `admin` from here — never call initializeApp() in other modules.
 */
import * as admin from "firebase-admin";

admin.initializeApp();

export const db = admin.firestore();
export { admin };
