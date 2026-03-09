import { initializeApp } from 'firebase/app';
import { getFirestore, collection, query, where, getDocs, doc, getDoc } from 'firebase/firestore';
import * as dotenv from 'dotenv';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

// Load env from .env.local
const envPath = join(process.cwd(), '.env.local');
if (!existsSync(envPath)) {
    console.error('Could not find .env.local at:', envPath);
    // try one level up just in case
    const fallbackPath = join(process.cwd(), '..', 'frontend', '.env.local');
    if (existsSync(fallbackPath)) {
        console.log('Found .env.local at fallback path:', fallbackPath);
    } else {
        process.exit(1);
    }
}

const envContent = readFileSync(envPath, 'utf8');
const env: Record<string, string> = {};
envContent.split('\n').forEach(line => {
    const [key, value] = line.split('=');
    if (key && value) env[key.trim()] = value.trim();
});

const firebaseConfig = {
    apiKey: env.VITE_FIREBASE_API_KEY,
    authDomain: env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: env.VITE_FIREBASE_PROJECT_ID,
    storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: env.VITE_FIREBASE_APP_ID
};

console.log('Using Firebase Config:', {
    projectId: firebaseConfig.projectId,
    authDomain: firebaseConfig.authDomain
});

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function diagnose() {
    console.log('--- FIRESTORE DIAGNOSTICS ---');

    console.log('Checking "teams" collection...');
    const teamsSnap = await getDocs(collection(db, 'teams'));
    console.log(`Found ${teamsSnap.size} teams in total.`);

    for (const teamDoc of teamsSnap.docs) {
        const data = teamDoc.data();
        console.log(`\nTeam Found: "${data.name}"`);
        console.log(`  ID: ${teamDoc.id}`);
        console.log(`  Manager ID (managerId): ${data.managerId}`);
        console.log(`  Budget: ${data.budget}`);
        console.log(`  Sponsors: ${Object.keys(data.sponsors || {}).length} active`);
        console.log(`  Facilities: ${Object.keys(data.facilities || {}).length} slots`);

        // Show facility levels if any
        Object.entries(data.facilities || {}).forEach(([key, val]: any) => {
            console.log(`    - Facility ${key}: Level ${val.level}`);
        });

        // Check drivers
        const driversSnap = await getDocs(query(collection(db, 'drivers'), where('teamId', '==', teamDoc.id)));
        console.log(`  Drivers assigned: ${driversSnap.size}`);
        driversSnap.docs.forEach(d => {
            const driverData = d.data();
            console.log(`    - Driver: ${driverData.name} (Salary: ${driverData.salary}, ID: ${d.id})`);
        });

        // Check transactions subcollection for this team
        const transSnap = await getDocs(collection(db, 'teams', teamDoc.id, 'transactions'));
        console.log(`  Transactions count: ${transSnap.size}`);

        // Check academy
        const selectedRef = collection(db, 'teams', teamDoc.id, 'academy', 'config', 'selected');
        const academySnap = await getDocs(selectedRef);
        console.log(`  Academy trainees: ${academySnap.size}`);
    }

    console.log('\n--- DIAGNOSTICS COMPLETE ---');
}

diagnose().catch(err => {
    console.error('Error during diagnostics:', err);
    process.exit(1);
});
