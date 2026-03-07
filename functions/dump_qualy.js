const admin = require('firebase-admin');

// Initialize generic admin (relies on default credentials, should work if CLI is logged in)
admin.initializeApp({
    projectId: 'ftg-racing-manager'
});

const db = admin.firestore();

async function run() {
    try {
        const seasonId = '3sh7fStGc55XxwmQHaJu';
        console.log(`Querying races for season: ${seasonId}...`);
        const snap = await db.collection('races').where('seasonId', '==', seasonId).get();

        console.log(`Found ${snap.docs.length} races.`);

        for (const d of snap.docs) {
            const data = d.data();
            const st = data.status;
            const qg = data.qualyGrid;
            const qr = data.qualifyingResults;

            console.log(`\n\n--- Race Document: ${d.id} ---`);
            console.log(`Status: ${st}`);

            if (qg && qg.length > 0) {
                console.log(`\n\n>> QUALIFYING RESULTS (${qg.length} drivers):`);
                qg.forEach((r, i) => {
                    console.log(`${r.position}. ${r.driverName} (${r.teamName}) - Time: ${r.lapTime} - Gap: +${r.gap} - ${r.tyreCompound}`);
                });
            } else if (qr && qr.length > 0) {
                console.log(`\n\n>> QUALIFYING RESULTS (from QR field) (${qr.length} drivers):`);
                qr.forEach((r, i) => {
                    console.log(`${r.position}. ${r.driverName} (${r.teamName}) - Time: ${r.lapTime} - Gap: +${r.gap} - ${r.tyreCompound}`);
                });
            } else {
                console.log(`>> NO QUALIFYING DATA FOUND in this race.`);
            }
        }
    } catch (e) {
        console.error('Error fetching data:', e.message);
    }
}

run();
