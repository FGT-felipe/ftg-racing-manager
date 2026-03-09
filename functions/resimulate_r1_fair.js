const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_resim_fair.json");
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

const { logger } = require("firebase-functions/v2");
logger.error = (m, e) => { console.error("ERROR:", m, e?.message || e); };
logger.info = (m) => { };
logger.warn = (m) => { };

const myFuncs = require("./index.js");

const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
const TARGET_TIME = new Date("2026-03-08T22:00:00Z"); // Delete everything after this

async function cleanupTeams() {
    console.log("Step 0: Cleaning up transactions, budget, and notifications...");

    const qSnap = await db.collection("races").doc("qRM0nhyt95JGXqgxLtnT_r1").get();
    const qGrid = qSnap.data().qualyGrid || [];
    const teamIds = [...new Set(qGrid.map(g => g.teamId).filter(id => id && !id.includes("bot")))];

    let totalTxsDeleted = 0;
    let totalNotifsDeleted = 0;

    for (const tid of teamIds) {
        const tRef = db.collection("teams").doc(tid);

        // Process transactions
        const txSnap = await tRef.collection("transactions").get();
        let budgetDelta = 0;
        const batch = db.batch();

        for (const tx of txSnap.docs) {
            const data = tx.data();
            let txDate;
            if (data.date && data.date.toDate) {
                txDate = data.date.toDate();
            } else if (typeof data.date === "string") {
                txDate = new Date(data.date);
            }

            if (txDate && txDate > TARGET_TIME) {
                batch.delete(tx.ref);
                budgetDelta -= (data.amount || 0);
                totalTxsDeleted++;
            }
        }

        // Process notifications
        const notifSnap = await tRef.collection("notifications").get();
        for (const notif of notifSnap.docs) {
            const data = notif.data();
            let nDate;
            if (data.timestamp && data.timestamp.toDate) {
                nDate = data.timestamp.toDate();
            } else if (typeof data.timestamp === "string") {
                nDate = new Date(data.timestamp);
            }

            if (nDate && nDate > TARGET_TIME) {
                batch.delete(notif.ref);
                totalNotifsDeleted++;
            }
        }

        if (budgetDelta !== 0) {
            batch.update(tRef, { budget: admin.firestore.FieldValue.increment(budgetDelta) });
        }
        await batch.commit();
    }
}

async function main() {
    const raceDocId = "qRM0nhyt95JGXqgxLtnT_r1";
    const seasonId = "qRM0nhyt95JGXqgxLtnT";

    console.log("═══════════════════════════════════════");
    console.log("  R1 DEFINITIVE FAIR RESIMULATION");
    console.log("═══════════════════════════════════════\n");

    await cleanupTeams();

    // 1: Reset driver stats
    const driversSnap = await db.collection("drivers").get();
    const resetBatch1 = db.batch();
    for (const d of driversSnap.docs) {
        resetBatch1.update(d.ref, {
            points: 0, seasonPoints: 0,
            wins: 0, seasonWins: 0,
            podiums: 0, seasonPodiums: 0,
            races: 0, seasonRaces: 0,
        });
    }
    await resetBatch1.commit();

    // 2: Reset team stats
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

    // 3: Clear old race laps
    const lapsSnap = await db.collection("races").doc(raceDocId).collection("laps").get();
    if (!lapsSnap.empty) {
        const delBatch = db.batch();
        lapsSnap.forEach(d => delBatch.delete(d.ref));
        await delBatch.commit();
    }

    // 4: Reset race document
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
    const sDc = await db.collection("seasons").doc(seasonId).get();
    const cal = sDc.data().calendar;
    cal[0].isCompleted = false;
    await db.collection("seasons").doc(seasonId).update({ calendar: cal });

    // 5: Re-run simulation
    console.log("Step 1: Re-running natural simulation...");
    const test = require("firebase-functions-test")();
    const wrapped = test.wrap(myFuncs.forceRace);
    await wrapped({ auth: { uid: "admin_user" }, data: {} });

    // 6: Trigger postRaceProcessing
    console.log("Step 2: Processing outcomes and economy...");
    const wrappedPost = test.wrap(myFuncs.postRaceProcessing);
    await wrappedPost({});

    // 7: Verify Results
    console.log("\nStep 3: Verifying final results...");
    const raceDoc = await db.collection("races").doc(raceDocId).get();
    const fp = raceDoc.data().finalPositions || {};
    const sorted = Object.keys(fp).sort((a, b) => fp[a] - fp[b]);

    console.log("  TOP 10:");
    for (let i = 0; i < Math.min(10, sorted.length); i++) {
        const did = sorted[i];
        const dDoc = await db.collection("drivers").doc(did).get();
        const name = dDoc.exists ? dDoc.data().name : did;
        const tDoc = await db.collection("teams").doc(dDoc.exists ? dDoc.data().teamId : "").get();
        const tname = tDoc.exists ? tDoc.data().name : "Bot";
        const pts = i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0;

        // Read their total laps and total time for verification
        const tt = raceDoc.data().totalTimes || {};
        const totalTime = tt[did] || 0;
        console.log(`  ${i + 1}. ${name} (${tname}) → +${pts}pts [Time: ${Math.round(totalTime)}s]`);
    }

    // 8: Sync universe
    console.log("\nStep 4: Syncing universe document...");
    const uRef = db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    const leagues = uDoc.data().leagues;

    for (let li = 0; li < leagues.length; li++) {
        for (let di = 0; di < leagues[li].drivers.length; di++) {
            const dDk = await db.collection("drivers").doc(leagues[li].drivers[di].id).get();
            if (dDk.exists) {
                const r = dDk.data();
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
            const tDk = await db.collection("teams").doc(leagues[li].teams[ti].id).get();
            if (tDk.exists) {
                const r = tDk.data();
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

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
