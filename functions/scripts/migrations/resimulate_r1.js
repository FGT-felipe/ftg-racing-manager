/**
 * FULL RESET & RE-SIMULATE R1
 * 1. Reset all driver/team stats to 0 (only 1 race has happened)
 * 2. Delete old race doc and laps
 * 3. Re-run the simulation with fixed crash rates
 * 4. Re-apply points, prizes
 * 5. Sync universe document
 */
const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_resim.json");
fs.writeFileSync(adcPath, JSON.stringify({
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
}, null, 2));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

// Load the SimEngine from index.js (it's a const at the top)
// We need to require index.js to get SimEngine
// But index.js initializes admin too, so we need the wrapper approach
const { logger } = require("firebase-functions/v2");
logger.error = (m, e) => { console.error("ERROR:", m, e?.message || e); };
logger.info = (m) => { console.log("INFO:", m); };
logger.warn = (m) => { console.log("WARN:", m); };

const myFuncs = require("./index.js");

// Access SimEngine - it's not exported, we need to extract it
// Actually let's just re-define the fixed simulateRace inline since we can't access SimEngine directly

const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

async function main() {
    const raceDocId = "qRM0nhyt95JGXqgxLtnT_r1";
    const seasonId = "qRM0nhyt95JGXqgxLtnT";

    console.log("═══════════════════════════════════════");
    console.log("  FULL R1 RESET & RE-SIMULATION");
    console.log("═══════════════════════════════════════\n");

    // ── Step 1: Reset all driver stats ──
    console.log("Step 1: Resetting driver stats...");
    const driversSnap = await db.collection("drivers").get();
    const resetBatch1 = db.batch();
    let dCount = 0;
    for (const d of driversSnap.docs) {
        resetBatch1.update(d.ref, {
            points: 0, seasonPoints: 0,
            wins: 0, seasonWins: 0,
            podiums: 0, seasonPodiums: 0,
            races: 0, seasonRaces: 0,
        });
        dCount++;
    }
    await resetBatch1.commit();
    console.log(`  ✅ Reset ${dCount} drivers\n`);

    // ── Step 2: Reset team stats (keep budget from pre-race) ──
    console.log("Step 2: Resetting team stats...");
    const teamsSnap = await db.collection("teams").get();
    const resetBatch2 = db.batch();
    for (const t of teamsSnap.docs) {
        resetBatch2.update(t.ref, {
            points: 0, seasonPoints: 0,
            wins: 0, seasonWins: 0,
            podiums: 0, seasonPodiums: 0,
            races: 0, seasonRaces: 0,
        });
    }
    await resetBatch2.commit();
    console.log(`  ✅ Reset ${teamsSnap.size} teams\n`);

    // ── Step 3: Delete old laps subcollection ──
    console.log("Step 3: Clearing old race data...");
    const lapsSnap = await db.collection("races").doc(raceDocId).collection("laps").get();
    if (!lapsSnap.empty) {
        const delBatch = db.batch();
        lapsSnap.forEach(d => delBatch.delete(d.ref));
        await delBatch.commit();
        console.log(`  Deleted ${lapsSnap.size} lap docs`);
    }

    // ── Step 4: Mark race as not finished ──
    await db.collection("races").doc(raceDocId).update({
        isFinished: false,
        postRaceProcessed: admin.firestore.FieldValue.delete(),
        postRaceProcessingAt: admin.firestore.FieldValue.delete(),
        finalPositions: admin.firestore.FieldValue.delete(),
        totalTimes: admin.firestore.FieldValue.delete(),
        dnfs: admin.firestore.FieldValue.delete(),
        raceLog: admin.firestore.FieldValue.delete(),
        completedAt: admin.firestore.FieldValue.delete(),
        liveDurationSeconds: admin.firestore.FieldValue.delete(),
    });

    // Also reset calendar
    const sDc = await db.collection("seasons").doc(seasonId).get();
    const cal = sDc.data().calendar;
    cal[0].isCompleted = false;
    await db.collection("seasons").doc(seasonId).update({ calendar: cal });
    console.log("  ✅ Race doc and calendar reset\n");

    // ── Step 5: Re-run the race simulation via forceRace ──
    console.log("Step 5: Re-running race simulation with FIXED crash rates...");
    const test = require("firebase-functions-test")();
    const wrapped = test.wrap(myFuncs.forceRace);
    const result = await wrapped({ auth: { uid: "admin_user" }, data: {} });
    console.log("  Result:", result);
    console.log("");

    // ── Step 6: Verify results ──
    console.log("Step 6: Verifying results...");
    const raceDoc = await db.collection("races").doc(raceDocId).get();
    const rData = raceDoc.data();
    const fp = rData.finalPositions || {};
    const dnfs = rData.dnfs || [];
    const sorted = Object.keys(fp).sort((a, b) => fp[a] - fp[b]);

    console.log(`  Total drivers: ${sorted.length}`);
    console.log(`  DNFs: ${dnfs.length}`);
    console.log(`  Finishers: ${sorted.length - dnfs.length}\n`);

    console.log("  TOP 10:");
    for (let i = 0; i < Math.min(10, sorted.length); i++) {
        const did = sorted[i];
        const isDnf = dnfs.includes(did);
        const dDoc = await db.collection("drivers").doc(did).get();
        const name = dDoc.exists ? dDoc.data().name : did;
        const pts = !isDnf && i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0;
        console.log(`  ${i + 1}. ${name} → ${isDnf ? 'DNF' : `P${i + 1}`} (+${pts}pts) | DB pts: ${dDoc.data()?.seasonPoints || 0}`);
    }

    // ── Step 7: Sync universe ──
    console.log("\nStep 7: Syncing universe document...");
    const uRef = db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    const leagues = uDoc.data().leagues;

    for (let li = 0; li < leagues.length; li++) {
        for (let di = 0; di < leagues[li].drivers.length; di++) {
            const dDoc = await db.collection("drivers").doc(leagues[li].drivers[di].id).get();
            if (dDoc.exists) {
                const r = dDoc.data();
                leagues[li].drivers[di].points = r.points || 0;
                leagues[li].drivers[di].seasonPoints = r.seasonPoints || 0;
                leagues[li].drivers[di].wins = r.wins || 0;
                leagues[li].drivers[di].seasonWins = r.seasonWins || 0;
                leagues[li].drivers[di].podiums = r.podiums || 0;
                leagues[li].drivers[di].seasonPodiums = r.seasonPodiums || 0;
                leagues[li].drivers[di].races = r.races || 0;
                leagues[li].drivers[di].seasonRaces = r.seasonRaces || 0;
            }
        }
        for (let ti = 0; ti < leagues[li].teams.length; ti++) {
            const tDoc = await db.collection("teams").doc(leagues[li].teams[ti].id).get();
            if (tDoc.exists) {
                const r = tDoc.data();
                leagues[li].teams[ti].points = r.points || 0;
                leagues[li].teams[ti].seasonPoints = r.seasonPoints || 0;
                leagues[li].teams[ti].wins = r.wins || 0;
                leagues[li].teams[ti].seasonWins = r.seasonWins || 0;
                leagues[li].teams[ti].podiums = r.podiums || 0;
                leagues[li].teams[ti].seasonPodiums = r.seasonPodiums || 0;
                leagues[li].teams[ti].races = r.races || 0;
                leagues[li].teams[ti].seasonRaces = r.seasonRaces || 0;
                if (r.name) leagues[li].teams[ti].name = r.name;
            }
        }
    }
    await uRef.update({ leagues });
    console.log("  ✅ Universe synced!\n");

    console.log("═══════════════════════════════════════");
    console.log("  ✅ DONE! Race R1 re-simulated");
    console.log("═══════════════════════════════════════");

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
