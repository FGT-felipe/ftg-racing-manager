const admin = require("firebase-admin");
try { admin.initializeApp(); } catch (e) { }
const db = admin.firestore();

async function list() {
    console.log("=== CHECKING LEAGUES ===");
    const leaguesSnap = await db.collection("leagues").get();
    for (const lDoc of leaguesSnap.docs) {
        const l = lDoc.data();
        console.log(`LEAGUE ID: ${lDoc.id} | NAME: ${l.name} | SEASON: ${l.currentSeasonId}`);

        if (l.currentSeasonId) {
            const sDoc = await db.collection("seasons").doc(l.currentSeasonId).get();
            if (sDoc.exists) {
                const s = sDoc.data();
                const completed = (s.calendar || []).filter(r => r.isCompleted).length;
                console.log(`  - SEASON FOUND. COMPLETED RACES: ${completed}`);
                if (completed > 0) {
                    const lastR = s.calendar.filter(r => r.isCompleted).pop();
                    console.log(`  - LAST COMPLETED: ${lastR.trackName} | ID: ${lastR.circuitId}`);
                }
            } else {
                console.log(`  - SEASON NOT FOUND: ${l.currentSeasonId}`);
            }
        }
    }
}

list().catch(console.error);
