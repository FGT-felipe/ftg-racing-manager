// Quick diagnostic script to see what's in Firestore for race documents
const admin = require("firebase-admin");

admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function main() {
    // 1. List all seasons
    console.log("=== SEASONS ===");
    const seasons = await db.collection("seasons").get();
    for (const s of seasons.docs) {
        const d = s.data();
        const cal = d.calendar || [];
        const nextRace = cal.find(r => !r.isCompleted);
        console.log(`Season: ${s.id} | calendar length: ${cal.length}`);
        if (nextRace) {
            console.log(`  Next race: id=${nextRace.id} track=${nextRace.trackName} circuitId=${nextRace.circuitId}`);
            console.log(`  Expected raceDocId: ${s.id}_${nextRace.id}`);
        } else {
            console.log("  All races completed");
        }
    }

    // 2. List all race documents
    console.log("\n=== RACE DOCUMENTS ===");
    const races = await db.collection("races").get();
    for (const r of races.docs) {
        const d = r.data();
        const hasQualyResults = !!d.qualifyingResults;
        const hasQualyGrid = !!d.qualyGrid;
        const qualyLen = d.qualifyingResults?.length || d.qualyGrid?.length || 0;
        console.log(`Race: ${r.id} | status: ${d.status} | hasQualifyingResults: ${hasQualyResults} | hasQualyGrid: ${hasQualyGrid} | gridLength: ${qualyLen}`);
        if (hasQualyResults || hasQualyGrid) {
            const sample = (d.qualifyingResults || d.qualyGrid)[0];
            console.log(`  Sample entry keys: ${Object.keys(sample)}`);
        }
    }

    // 3. Check team weekStatus
    console.log("\n=== TEAMS weekStatus ===");
    const teams = await db.collection("teams").get();
    for (const t of teams.docs) {
        const d = t.data();
        const ws = d.weekStatus || {};
        console.log(`Team: ${t.id} (${d.name}) | raceStrategy: ${ws.raceStrategy} (${typeof ws.raceStrategy})`);
    }

    process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
