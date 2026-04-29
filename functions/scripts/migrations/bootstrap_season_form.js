/**
 * Bootstrap script — T-124 S3.2
 * Backfills `team.seasonForm[]` for all teams in the active season.
 *
 * Algorithm:
 *   For each completed race in the season calendar:
 *   1. Read races/{seasonId}_{raceId} → finalPositions (driverId → finishPos)
 *   2. Map driver → team using the drivers collection
 *   3. Sum POINT_SYSTEM points per team for that race
 *   4. Accumulate season points across rounds
 *   5. Sort teams by cumulative pts → constructors position
 *   6. Append { round, trackName, position, pts } to each team's seasonForm[]
 *
 * SCOPE: Overwrites seasonForm[] on every team in the active season (idempotent — safe to re-run).
 *
 * Usage:
 *   node scripts/migrations/bootstrap_season_form.js            # dry-run (default)
 *   node scripts/migrations/bootstrap_season_form.js --write    # executes the writes
 */

const fs = require("fs");
const path = require("path");

// ─── Firebase auth ───────────────────────────────────────────────────────────
const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcCredentials = {
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
};
const adcPath = path.join(__dirname, "_adc_temp_bootstrap_season_form.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const DRY_RUN = !process.argv.includes("--write");
const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

async function run() {
    console.log(DRY_RUN ? "=== DRY RUN (pass --write to execute) ===" : "=== WRITING TO FIRESTORE ===");

    // 1. Find the active season
    const seasonsSnap = await db.collection("seasons").get();
    const activeSeason = seasonsSnap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .find(s => s.status === "active" || !s.status);

    if (!activeSeason) { console.error("No active season found."); process.exit(1); }
    console.log(`\nSeason: ${activeSeason.id} (year ${activeSeason.year ?? "?"}, ${activeSeason.number ?? "?"} rounds)`);

    const calendar = activeSeason.calendar ?? [];
    const completedRaces = calendar.filter(r => r.isCompleted);
    console.log(`Completed races: ${completedRaces.length} / ${calendar.length}`);

    // 2. Build set of trackNames we need to find
    const sId = activeSeason.id;
    const neededTracks = new Set(completedRaces.map(r => r.trackName));

    // Query ALL finished race docs and index by trackName — no season prefix filter
    // because R1-R4 may have been created under a different season doc ID
    const racesSnap = await db.collection("races")
        .where("isFinished", "==", true)
        .get();

    console.log(`Total finished race docs in collection: ${racesSnap.docs.length}`);

    const raceByTrack = {};
    for (const d of racesSnap.docs) {
        const data = d.data();
        const track = data.trackName;
        if (track && neededTracks.has(track)) {
            // Prefer the doc whose ID starts with current seasonId; otherwise keep first found
            if (!raceByTrack[track] || d.id.startsWith(`${sId}_`)) {
                raceByTrack[track] = { id: d.id, ...data };
            }
        }
    }

    console.log(`Matched race docs for this calendar: ${Object.keys(raceByTrack).length}`);
    for (const [track, doc] of Object.entries(raceByTrack)) {
        console.log(`  ${doc.id} → ${track}`);
    }

    // 3. Load all drivers to build driverId → teamId map
    const driversSnap = await db.collection("drivers").get();
    const driverTeam = {};
    for (const d of driversSnap.docs) {
        const data = d.data();
        if (data.teamId) driverTeam[d.id] = data.teamId;
    }
    console.log(`Drivers loaded: ${Object.keys(driverTeam).length}`);

    // 4. Collect all unique teamIds from drivers
    const allTeamIds = [...new Set(Object.values(driverTeam))];
    console.log(`Teams found: ${allTeamIds.length}`);

    // 5. Process each completed race in calendar order
    const cumulativePts = {};  // teamId → accumulated season pts so far
    for (const tid of allTeamIds) cumulativePts[tid] = 0;

    // seasonForm per team: teamId → SeasonFormEntry[]
    const seasonFormMap = {};
    for (const tid of allTeamIds) seasonFormMap[tid] = [];

    for (let i = 0; i < completedRaces.length; i++) {
        const rEvent = completedRaces[i];

        // Match race doc: first try constructed ID, then fall back to trackName lookup
        let rData = null;
        const constructedId = `${sId}_${rEvent.id}`;
        const directSnap = await db.collection("races").doc(constructedId).get();
        if (directSnap.exists) {
            rData = directSnap.data();
        } else if (raceByTrack[rEvent.trackName]) {
            rData = raceByTrack[rEvent.trackName];
            console.log(`  R${i + 1} matched by trackName: ${rEvent.trackName}`);
        } else {
            console.warn(`  R${i + 1} (${rEvent.trackName}): no matching race doc found — skipping`);
            continue;
        }

        const finalPositions = rData.finalPositions ?? {};  // driverId → 1-based finish position
        const dnfs = rData.dnfs ?? [];

        // Sum points per team for this race
        const racePts = {};
        for (const tid of allTeamIds) racePts[tid] = 0;

        const sorted = Object.keys(finalPositions).sort(
            (a, b) => finalPositions[a] - finalPositions[b]
        );

        for (let pos = 0; pos < sorted.length; pos++) {
            const driverId = sorted[pos];
            const tid = driverTeam[driverId];
            if (!tid) continue;
            const isDnf = dnfs.includes(driverId);
            const pts = (!isDnf && pos < POINT_SYSTEM.length) ? POINT_SYSTEM[pos] : 0;
            racePts[tid] = (racePts[tid] ?? 0) + pts;
        }

        // Accumulate season pts
        for (const tid of allTeamIds) {
            cumulativePts[tid] = (cumulativePts[tid] ?? 0) + (racePts[tid] ?? 0);
        }

        // Sort teams by cumulative pts → constructors position
        const ranked = [...allTeamIds].sort(
            (a, b) => (cumulativePts[b] ?? 0) - (cumulativePts[a] ?? 0)
        );

        const round = i + 1;
        console.log(`\n  R${round} — ${rEvent.trackName}`);
        for (let pos = 0; pos < ranked.length; pos++) {
            const tid = ranked[pos];
            const entry = {
                round,
                trackName: rEvent.trackName,
                position: pos + 1,
                pts: racePts[tid] ?? 0,
            };
            seasonFormMap[tid].push(entry);
            console.log(`    P${pos + 1}: ${tid} (race pts: ${entry.pts}, cumul: ${cumulativePts[tid]})`);
        }
    }

    // 5. Write to Firestore
    console.log("\n--- Pre-flight summary ---");
    for (const tid of allTeamIds) {
        console.log(`  ${tid}: ${seasonFormMap[tid].length} entries`);
    }

    if (DRY_RUN) {
        console.log("\nDry run complete. Run with --write to apply.");
        cleanup(adcPath);
        return;
    }

    const batch = db.batch();
    for (const tid of allTeamIds) {
        // SCOPE: only teams that have at least one form entry
        if (seasonFormMap[tid].length === 0) continue;
        batch.update(db.collection("teams").doc(tid), { seasonForm: seasonFormMap[tid] });
    }
    await batch.commit();
    console.log(`\nWrote seasonForm[] to ${allTeamIds.length} teams.`);
    cleanup(adcPath);
}

function cleanup(adcPath) {
    try { fs.unlinkSync(adcPath); } catch (_) {}
}

run().catch(e => { console.error(e); cleanup(adcPath); process.exit(1); });
