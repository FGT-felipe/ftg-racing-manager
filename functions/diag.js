// Diagnostic: query Firestore from functions dir using firebase-admin with ADC
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });
process.env.GCLOUD_PROJECT = "ftg-racing-manager";

const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

async function main() {
    // 1. List all seasons
    console.log("=== SEASONS ===");
    const seasons = await db.collection("seasons").get();
    for (const s of seasons.docs) {
        const d = s.data();
        const cal = d.calendar || [];
        const nextRace = cal.find(r => !r.isCompleted);
        console.log(`Season: ${s.id} | calLen: ${cal.length}`);
        if (nextRace) {
            console.log(`  NextRace: id=${nextRace.id} track=${nextRace.trackName} circuit=${nextRace.circuitId}`);
            console.log(`  ExpectedDocId: ${s.id}_${nextRace.id}`);
        } else {
            console.log("  All completed");
        }
        // Also show the LAST completed race
        const lastCompleted = [...cal].reverse().find(r => r.isCompleted);
        if (lastCompleted) {
            console.log(`  LastCompleted: id=${lastCompleted.id} track=${lastCompleted.trackName}`);
            console.log(`  LastCompDocId: ${s.id}_${lastCompleted.id}`);
        }
    }

    // 2. List all race documents
    console.log("\n=== RACE DOCUMENTS ===");
    const races = await db.collection("races").get();
    for (const r of races.docs) {
        const d = r.data();
        const hasQR = !!d.qualifyingResults;
        const hasQG = !!d.qualyGrid;
        const qLen = (d.qualifyingResults || d.qualyGrid || []).length;
        console.log(`Race: ${r.id} | status: ${d.status} | hasQR: ${hasQR} | hasQG: ${hasQG} | qLen: ${qLen}`);
    }

    // 3. Check specific team
    console.log("\n=== TEAMS ===");
    const teams = await db.collection("teams").get();
    for (const t of teams.docs) {
        const d = t.data();
        const ws = d.weekStatus || {};
        console.log(`Team: ${t.id} (${d.name}) | raceStrategy: ${ws.raceStrategy} (${typeof ws.raceStrategy})`);
    }

    process.exit(0);
}

main().catch(e => { console.error(e.message); process.exit(1); });
