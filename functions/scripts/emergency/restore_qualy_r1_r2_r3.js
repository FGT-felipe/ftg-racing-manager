/**
 * RECOVERY SCRIPT: Restores qualyGrid + qualifyingResults for R1, R2, R3
 * by reading teams/{teamId}/notifications (QUALIFYING_RESULT type).
 *
 * Sources used:
 *  - notifications: positions for all human-team drivers (20/22 per round)
 *  - transactions: validates P1/P2/P3 per round (cross-reference)
 *  - races/{id}.finalPositions: identifies the 2 bot-team drivers missing from notifications
 *  - drivers collection: resolves driverIds and names for bot-team drivers
 *
 * What is restored: driverId, driverName, teamId, teamName, position, isCrashed
 * What cannot be restored: lapTime, gap, tyreCompound (not stored in notifications)
 * These will be 0/"" — the UI shows "—" for zero times.
 *
 * Usage:
 *   node scripts/emergency/restore_qualy_r1_r2_r3.js            (dry run — no writes)
 *   node scripts/emergency/restore_qualy_r1_r2_r3.js --write    (executes writes)
 */

const fs   = require("fs");
const path = require("path");

const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config     = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath    = path.join(__dirname, "_adc_temp.json");
fs.writeFileSync(adcPath, JSON.stringify({
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
}, null, 2));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;

const admin  = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db     = admin.firestore();
const WRITE  = process.argv.includes("--write");

async function run() {
    console.log(`=== Qualifying Recovery — R1 / R2 / R3 ${WRITE ? "[WRITE MODE]" : "[DRY RUN — pass --write to execute]"} ===\n`);

    // ── 1. Load all teams and their QUALIFYING_RESULT notifications ──────────
    const teamsSnap   = await db.collection("teams").get();
    const teamNameMap = {};                             // teamId → teamName
    teamsSnap.docs.forEach(t => { teamNameMap[t.id] = t.data().name || t.id; });

    // sessions: { hourKey → [{ driverName, teamId, teamName, position, isCrashed }] }
    const sessions = {};

    for (const tDoc of teamsSnap.docs) {
        const notifSnap = await db.collection("teams").doc(tDoc.id)
            .collection("notifications")
            .where("type", "==", "QUALIFYING_RESULT")
            .get();

        for (const nDoc of notifSnap.docs) {
            const ts = nDoc.data().timestamp?.toDate
                ? nDoc.data().timestamp.toDate() : new Date(nDoc.data().timestamp);
            const key = new Date(Math.round(ts.getTime() / 3600000) * 3600000).toISOString();
            if (!sessions[key]) sessions[key] = [];

            const lines = (nDoc.data().message || "").split("\n").filter(Boolean);
            for (const line of lines) {
                const crash = line.match(/^(.+): DNF \(Crash\)$/);
                const pos   = line.match(/^(.+): P(\d+)$/);
                if (crash) {
                    sessions[key].push({ driverName: crash[1].trim(), teamId: tDoc.id,
                        teamName: teamNameMap[tDoc.id], position: 999, isCrashed: true });
                } else if (pos) {
                    sessions[key].push({ driverName: pos[1].trim(), teamId: tDoc.id,
                        teamName: teamNameMap[tDoc.id], position: parseInt(pos[2]), isCrashed: false });
                }
            }
        }
    }

    const sortedKeys = Object.keys(sessions).sort();
    console.log(`Found ${sortedKeys.length} qualifying session(s) in notifications.\n`);

    // ── 2. Load qualifying transactions for validation ───────────────────────
    // txByDate: { "YYYY-MM-DD" → [{ pos, driverName, teamName }] }
    const txByDate = {};
    for (const tDoc of teamsSnap.docs) {
        const txSnap = await db.collection("teams").doc(tDoc.id)
            .collection("transactions").where("type", "==", "REWARD").get();
        txSnap.docs.forEach(tx => {
            const m = (tx.data().description || "").match(/^Qualifying (P[123]) Reward \((.+)\)$/);
            if (!m) return;
            const date = (tx.data().date || "").substring(0, 10);
            if (!txByDate[date]) txByDate[date] = [];
            txByDate[date].push({ pos: m[1], driverName: m[2], teamName: tDoc.data().name });
        });
    }
    const txDates = Object.keys(txByDate).sort();
    console.log("Qualifying prize transactions (P1/P2/P3 validation):");
    txDates.forEach(d => {
        const e = txByDate[d].sort((a, b) => a.pos.localeCompare(b.pos));
        console.log(`  ${d}: ${e.map(x => `${x.pos} ${x.driverName}`).join(" | ")}`);
    });
    console.log("");

    // ── 3. Load all drivers for ID lookup ────────────────────────────────────
    const driversSnap = await db.collection("drivers").get();
    const driverByKey = {};    // `${teamId}::${name}` → { id, name, teamId, teamName }
    const driverById  = {};    // driverId → { name, teamId, teamName }
    driversSnap.docs.forEach(d => {
        const dr = d.data();
        driverByKey[`${dr.teamId}::${dr.name}`] = { id: d.id, name: dr.name, teamId: dr.teamId, teamName: dr.teamName || teamNameMap[dr.teamId] || "" };
        driverById[d.id] = { name: dr.name, teamId: dr.teamId, teamName: dr.teamName || teamNameMap[dr.teamId] || "" };
    });

    // ── 4. Load all race documents that need restoration ──────────────────────
    const racesSnap  = await db.collection("races").get();
    const raceDocsNeedingRestore = racesSnap.docs
        .filter(d => d.data().isFinished === true && (!d.data().qualyGrid || d.data().qualyGrid.length === 0))
        .sort((a, b) => {
            const na = parseInt((a.id.match(/_r(\d+)$/) || [0, 0])[1]);
            const nb = parseInt((b.id.match(/_r(\d+)$/) || [0, 0])[1]);
            return na - nb;
        });

    console.log(`Race documents needing restoration (${raceDocsNeedingRestore.length}):`);
    raceDocsNeedingRestore.forEach(d => console.log(`  ${d.id} — finalPositions: ${Object.keys(d.data().finalPositions || {}).length} drivers`));
    console.log("");

    if (sortedKeys.length < raceDocsNeedingRestore.length) {
        console.warn(`⚠️  Only ${sortedKeys.length} notification session(s) found for ${raceDocsNeedingRestore.length} races. Will recover what's available.\n`);
    }

    // ── 5. Pair sessions → race documents and build qualyGrids ───────────────
    const pairs = Math.min(raceDocsNeedingRestore.length, sortedKeys.length);

    for (let i = 0; i < pairs; i++) {
        const raceDoc    = raceDocsNeedingRestore[i];
        const sessionKey = sortedKeys[i];
        const raceData   = raceDoc.data();
        const entries    = sessions[sessionKey].sort((a, b) => a.position - b.position);

        // Cross-check: find P1 from transactions on same date
        const sessionDate = sessionKey.substring(0, 10);
        const txDate = txDates.find(d => {
            const diff = Math.abs(new Date(d).getTime() - new Date(sessionDate).getTime());
            return diff < 2 * 86400000; // within 2 days
        });
        const p1tx = txDate ? (txByDate[txDate].find(x => x.pos === "P1") || null) : null;
        const p1notif = entries.find(e => e.position === 1);

        console.log(`\n══ Round ${i + 1}: ${raceDoc.id} ← session ~${sessionKey} ══`);
        console.log(`  Notification entries: ${entries.length}`);
        if (p1tx && p1notif) {
            const match = p1tx.driverName === p1notif.driverName;
            console.log(`  P1 cross-check: notif="${p1notif.driverName}" tx="${p1tx.driverName}" → ${match ? "✅ MATCH" : "⚠️  MISMATCH"}`);
        }

        // Build the set of driverIds already accounted for from notifications
        const knownDriverIds = new Set();
        const qualyGrid = entries.map(e => {
            const key     = `${e.teamId}::${e.driverName}`;
            const drInfo  = driverByKey[key];
            const driverId = drInfo?.id || "";
            if (driverId) knownDriverIds.add(driverId);
            if (!drInfo) console.warn(`  ⚠️  No driverId for "${e.driverName}" (${e.teamName})`);
            return {
                driverId:      driverId,
                driverName:    e.driverName,
                teamId:        e.teamId,
                teamName:      e.teamName,
                position:      e.position,
                isCrashed:     e.isCrashed,
                lapTime:       0,
                gap:           0,
                tyreCompound:  "",
                setupSubmitted: true,
                _restored:     true,
            };
        });

        // ── Fill missing drivers from finalPositions (bot team) ──────────────
        const finalPositions = raceData.finalPositions || {};
        const missingIds = Object.keys(finalPositions).filter(id => !knownDriverIds.has(id));
        if (missingIds.length > 0) {
            console.log(`  Filling ${missingIds.length} missing driver(s) from finalPositions:`);
            // Assign them the next available positions after the last known position
            const usedPositions = new Set(qualyGrid.map(e => e.position));
            let nextPos = 1;
            for (const driverId of missingIds) {
                while (usedPositions.has(nextPos)) nextPos++;
                const drInfo = driverById[driverId];
                if (!drInfo) { console.warn(`    ⚠️  driverId ${driverId} not found in drivers collection`); continue; }
                console.log(`    Position ~${nextPos}: ${drInfo.name} (${drInfo.teamName || teamNameMap[drInfo.teamId]})`);
                qualyGrid.push({
                    driverId,
                    driverName:    drInfo.name,
                    teamId:        drInfo.teamId,
                    teamName:      drInfo.teamName || teamNameMap[drInfo.teamId] || "",
                    position:      nextPos,
                    isCrashed:     false,
                    lapTime:       0,
                    gap:           0,
                    tyreCompound:  "",
                    setupSubmitted: false,
                    _restored:     true,
                    _positionApproximate: true,
                });
                usedPositions.add(nextPos);
                nextPos++;
            }
        }

        // Sort final grid by position
        qualyGrid.sort((a, b) => a.position - b.position);

        console.log(`\n  Final grid (${qualyGrid.length} drivers):`);
        qualyGrid.forEach(e => {
            const pos   = e.isCrashed ? "DNF" : `P${e.position}`;
            const idOk  = e.driverId ? "✓" : "✗";
            const approx = e._positionApproximate ? " [pos≈]" : "";
            console.log(`    ${pos.padEnd(5)} ${e.driverName.padEnd(25)} (${e.teamName})  id:${idOk}${approx}`);
        });

        if (WRITE) {
            await raceDoc.ref.update({ qualyGrid, qualifyingResults: qualyGrid });
            console.log(`\n  ✅ Written to Firestore: ${raceDoc.id}`);
        } else {
            console.log(`\n  [DRY RUN] Would write ${qualyGrid.length} entries to ${raceDoc.id}`);
        }
    }

    if (raceDocsNeedingRestore.length > sortedKeys.length) {
        console.log(`\n⚠️  Unrecoverable rounds (no notification data):`);
        raceDocsNeedingRestore.slice(sortedKeys.length).forEach(d => console.log(`  - ${d.id}`));
    }

    try { fs.unlinkSync(adcPath); } catch (_) {}
    console.log("\n=== Done ===");
    process.exit(0);
}

run().catch(e => { console.error(e); try { fs.unlinkSync(adcPath); } catch (_) {} process.exit(1); });
