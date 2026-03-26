/**
 * READ-ONLY: Exhaustive diagnostic for R3 qualifying recovery.
 * Checks every possible data source without modifying anything.
 *
 * Usage: node scripts/emergency/dump_r3_all_sources.js
 */
const fs = require("fs");
const path = require("path");

const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp.json");
fs.writeFileSync(adcPath, JSON.stringify({
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
}, null, 2));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function run() {
    console.log("=== R3 Qualifying — Full Source Diagnostic (READ-ONLY) ===\n");

    // ── Source 1: R3 race document ────────────────────────────────────────────
    console.log("── SOURCE 1: races/qRM0nhyt95JGXqgxLtnT_r3 ──");
    const r3 = await db.collection("races").doc("qRM0nhyt95JGXqgxLtnT_r3").get();
    if (!r3.exists) {
        console.log("  ❌ Document does not exist.\n");
    } else {
        const d = r3.data();
        console.log(`  isFinished: ${d.isFinished}`);
        console.log(`  qualyGrid length: ${d.qualyGrid ? d.qualyGrid.length : 'field missing'}`);
        console.log(`  qualifyingResults length: ${d.qualifyingResults ? d.qualifyingResults.length : 'field missing'}`);
        console.log(`  finalPositions keys: ${d.finalPositions ? Object.keys(d.finalPositions).length : 'none'}`);
        console.log(`  raceResults length: ${d.raceResults ? d.raceResults.length : 'field missing'}`);
        if (d.finalPositions && Object.keys(d.finalPositions).length > 0) {
            console.log("\n  finalPositions (race results — NOT qualifying order):");
            const sorted = Object.entries(d.finalPositions).sort((a, b) => a[1] - b[1]);
            sorted.forEach(([id, pos]) => console.log(`    P${pos}  driverId: ${id}`));
        }
    }

    // ── Source 2: notifications subcollections (same batch as news) ───────────
    console.log("\n── SOURCE 2: teams/{teamId}/notifications (QUALIFYING_RESULT) ──");
    const teamsSnap = await db.collection("teams").get();
    let notifCount = 0;
    const notifRounds = {};
    for (const tDoc of teamsSnap.docs) {
        const teamName = tDoc.data().name || tDoc.id;
        const snap = await db.collection("teams").doc(tDoc.id).collection("notifications")
            .where("type", "==", "QUALIFYING_RESULT").get();
        if (!snap.empty) {
            snap.docs.forEach(n => {
                const ts = n.data().timestamp?.toDate ? n.data().timestamp.toDate() : new Date();
                const key = new Date(Math.round(ts.getTime() / 3600000) * 3600000).toISOString();
                if (!notifRounds[key]) notifRounds[key] = [];
                const lines = (n.data().message || "").split("\n").filter(Boolean);
                lines.forEach(line => {
                    const m = line.match(/^(.+): P(\d+)$/) || line.match(/^(.+): DNF \(Crash\)$/);
                    if (m) notifRounds[key].push({ driverName: m[1].trim(), teamId: tDoc.id, teamName });
                });
                notifCount++;
            });
        }
    }
    const notifKeys = Object.keys(notifRounds).sort();
    console.log(`  Found ${notifCount} QUALIFYING_RESULT notifications across ${notifKeys.length} session(s).`);
    notifKeys.forEach((k, i) => console.log(`  Session ${i+1}: ~${k} — ${notifRounds[k].length} driver entries`));

    // ── Source 3: transactions — qualifying prize entries ─────────────────────
    console.log("\n── SOURCE 3: teams/{teamId}/transactions (Qualifying P1/P2/P3 Reward) ──");
    const txByRound = {};
    for (const tDoc of teamsSnap.docs) {
        const txSnap = await db.collection("teams").doc(tDoc.id).collection("transactions")
            .where("type", "==", "REWARD").get();
        txSnap.docs.forEach(tx => {
            const desc = tx.data().description || "";
            const m = desc.match(/^Qualifying (P[123]) Reward \((.+)\)$/);
            if (!m) return;
            const date = tx.data().date ? tx.data().date.substring(0, 10) : "unknown";
            if (!txByRound[date]) txByRound[date] = [];
            txByRound[date].push({ pos: m[1], driverName: m[2], teamId: tDoc.id, teamName: tDoc.data().name });
        });
    }
    const txDates = Object.keys(txByRound).sort();
    console.log(`  Found qualifying prize transactions on ${txDates.length} date(s):`);
    txDates.forEach(date => {
        const entries = txByRound[date].sort((a, b) => a.pos.localeCompare(b.pos));
        console.log(`\n  ${date}:`);
        entries.forEach(e => console.log(`    ${e.pos}  ${e.driverName} (${e.teamName})`));
    });

    // ── Source 4: drivers — poles statistic ───────────────────────────────────
    console.log("\n── SOURCE 4: drivers with poles > 0 ──");
    const driversSnap = await db.collection("drivers").where("poles", ">", 0).get();
    driversSnap.docs.forEach(d => {
        const dr = d.data();
        console.log(`  ${dr.name} (teamId: ${dr.teamId}) — poles: ${dr.poles}, seasonPoles: ${dr.seasonPoles || 0}`);
    });

    // ── Source 5: teams — poles statistic ─────────────────────────────────────
    console.log("\n── SOURCE 5: teams with poles > 0 ──");
    teamsSnap.docs.forEach(t => {
        if ((t.data().poles || 0) > 0) {
            console.log(`  ${t.data().name} — poles: ${t.data().poles}`);
        }
    });

    // ── Source 6: news with any qualifying-related type ───────────────────────
    console.log("\n── SOURCE 6: all distinct news types found (to spot alternate type strings) ──");
    const typesSeen = new Set();
    for (const tDoc of teamsSnap.docs.slice(0, 5)) { // sample first 5 teams
        const snap = await db.collection("teams").doc(tDoc.id).collection("news").get();
        snap.docs.forEach(n => typesSeen.add(n.data().type || "(no type)"));
    }
    console.log(`  Types found in news: ${[...typesSeen].join(", ")}`);

    try { fs.unlinkSync(adcPath); } catch (e) {}
    console.log("\n=== END — No data modified ===");
    process.exit(0);
}

run().catch(e => { console.error(e); try { fs.unlinkSync(adcPath); } catch (_) {} process.exit(1); });
