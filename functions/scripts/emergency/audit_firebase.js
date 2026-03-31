/**
 * audit_firebase.js
 *
 * Read-only Firebase inventory and consistency audit.
 * Produces a structured report of all active collections, season doc health,
 * season reference consistency across leagues/teams/universe, race doc coverage,
 * and qualifying_results backup coverage.
 *
 * This script NEVER writes to Firestore.
 *
 * Usage:
 *   node audit_firebase.js
 *
 * Exit codes:
 *   0 — audit complete (warnings may exist)
 *   1 — fatal error (could not connect or missing critical doc)
 */

const fs = require("fs");
const path = require("path");

// ── Auth setup ────────────────────────────────────────────────────────────────
const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_audit.json");
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

// ── Helpers ───────────────────────────────────────────────────────────────────
const SEP  = "─".repeat(60);
const SEP2 = "═".repeat(60);

function ok(msg)   { console.log(`  ✅ ${msg}`); }
function warn(msg) { console.log(`  ⚠️  ${msg}`); }
function err(msg)  { console.log(`  ❌ ${msg}`); }
function info(msg) { console.log(`  ${msg}`); }

let warningCount = 0;
function flag(msg) { warningCount++; warn(msg); }

// ── Main ──────────────────────────────────────────────────────────────────────
async function audit() {
    console.log(SEP2);
    console.log("  FTG Racing Manager — Firebase Audit");
    console.log(`  ${new Date().toISOString()}`);
    console.log(SEP2);

    // ── 1. Collections inventory ─────────────────────────────────────────────
    console.log("\n=== 1. COLLECTIONS INVENTORY ===");
    console.log(SEP);

    const knownCollections = [
        "universe",
        "leagues",
        "seasons",
        "races",
        "qualifying_results",
        "teams",
        "drivers",
        "managers",
    ];

    const counts = {};
    for (const col of knownCollections) {
        const snap = await db.collection(col).get();
        counts[col] = snap.size;
        info(`${col.padEnd(22)} ${snap.size} docs`);
    }

    // ── 2. Season docs analysis ──────────────────────────────────────────────
    console.log("\n=== 2. SEASON DOCS ===");
    console.log(SEP);

    const seasonsSnap = await db.collection("seasons").get();
    const leaguesSnap = await db.collection("leagues").get();

    // Build set of all referenced season IDs
    const referencedSeasonIds = new Set();
    for (const lDoc of leaguesSnap.docs) {
        const sid = lDoc.data().currentSeasonId;
        if (sid) referencedSeasonIds.add(sid);
    }

    for (const sDoc of seasonsSnap.docs) {
        const data = sDoc.data();
        const cal = data.calendar || [];
        const completed = cal.filter(r => r.isCompleted).length;
        const total = cal.length;
        const isReferenced = referencedSeasonIds.has(sDoc.id);

        if (isReferenced) {
            ok(`[${sDoc.id}] year=${data.year || "?"} | rounds: ${completed}/${total} completed | ACTIVE`);
        } else {
            flag(`[${sDoc.id}] year=${data.year || "?"} | rounds: ${completed}/${total} completed | ORPHAN (not referenced by any league)`);
        }
    }

    if (seasonsSnap.size > referencedSeasonIds.size) {
        flag(`${seasonsSnap.size - referencedSeasonIds.size} orphaned season doc(s) detected`);
    }

    // ── 3. Season ref consistency ────────────────────────────────────────────
    console.log("\n=== 3. SEASON REF CONSISTENCY ===");
    console.log(SEP);

    // Determine master season from ftg_world league
    const masterLeagueDoc = await db.collection("leagues").doc("ftg_world").get();
    const masterSeasonId = masterLeagueDoc.exists
        ? masterLeagueDoc.data().currentSeasonId
        : null;

    if (!masterSeasonId) {
        err("leagues/ftg_world.currentSeasonId is missing — cannot determine master season");
    } else {
        info(`Master season (from ftg_world): ${masterSeasonId}`);
    }
    console.log();

    // Check all leagues
    info("Leagues:");
    for (const lDoc of leaguesSnap.docs) {
        const data = lDoc.data();
        const sid = data.currentSeasonId;
        if (!sid) {
            flag(`leagues/${lDoc.id} — currentSeasonId MISSING`);
        } else if (masterSeasonId && sid !== masterSeasonId) {
            flag(`leagues/${lDoc.id} — currentSeasonId mismatch: "${sid}" (expected "${masterSeasonId}")`);
        } else {
            ok(`leagues/${lDoc.id} → ${sid}`);
        }
    }
    console.log();

    // Check universe.activeSeasonId
    info("Universe:");
    const uDoc = await db.collection("universe").doc("game_universe_v1").get();
    if (!uDoc.exists) {
        err("universe/game_universe_v1 not found");
    } else {
        const uData = uDoc.data();
        const uSid = uData.activeSeasonId;
        if (!uSid) {
            flag("universe/game_universe_v1.activeSeasonId MISSING");
        } else if (masterSeasonId && uSid !== masterSeasonId) {
            flag(`universe/game_universe_v1.activeSeasonId mismatch: "${uSid}" (expected "${masterSeasonId}")`);
        } else {
            ok(`universe/game_universe_v1.activeSeasonId → ${uSid}`);
        }

        // Check universe leagues[] currentSeasonId
        const uLeagues = uData.leagues || [];
        let uLeagueMismatches = 0;
        for (const ul of uLeagues) {
            if (masterSeasonId && ul.currentSeasonId !== masterSeasonId) {
                uLeagueMismatches++;
            }
        }
        if (uLeagueMismatches > 0) {
            flag(`universe.leagues[] — ${uLeagueMismatches} league(s) have wrong currentSeasonId`);
        } else {
            ok(`universe.leagues[] — all ${uLeagues.length} league(s) currentSeasonId correct`);
        }
    }

    // ── 4. Race docs coverage ────────────────────────────────────────────────
    console.log("\n=== 4. RACE DOCS COVERAGE ===");
    console.log(SEP);

    const racesSnap = await db.collection("races").get();

    // Build known season IDs from seasons collection
    const knownSeasonIds = new Set(seasonsSnap.docs.map(d => d.id));

    let orphanRaces = 0;
    let finishedRaces = 0;
    let pendingRaces = 0;

    for (const rDoc of racesSnap.docs) {
        const data = rDoc.data();
        const seasonId = data.seasonId || rDoc.id.split("_")[0];
        const hasKnownSeason = knownSeasonIds.has(seasonId);

        if (!hasKnownSeason) {
            flag(`races/${rDoc.id} — seasonId "${seasonId}" not found in seasons collection`);
            orphanRaces++;
        } else if (data.isFinished) {
            finishedRaces++;
        } else {
            pendingRaces++;
        }
    }

    if (orphanRaces === 0) {
        ok(`All ${racesSnap.size} race doc(s) reference a valid season`);
    }
    info(`Finished: ${finishedRaces} | Pending: ${pendingRaces} | Orphan: ${orphanRaces}`);

    // ── 5. qualifying_results backup coverage ────────────────────────────────
    console.log("\n=== 5. QUALIFYING_RESULTS BACKUP COVERAGE ===");
    console.log(SEP);

    const qrSnap = await db.collection("qualifying_results").get();
    const qrIds = new Set(qrSnap.docs.map(d => d.id));

    // Find all finished races that should have a qualifying_results doc
    const racesWithQualyGrid = racesSnap.docs.filter(d => {
        const data = d.data();
        return data.qualyGrid?.length > 0;
    });

    let missingBackups = [];
    for (const rDoc of racesWithQualyGrid) {
        if (!qrIds.has(rDoc.id)) {
            missingBackups.push(rDoc.id);
        }
    }

    if (missingBackups.length === 0) {
        ok(`All ${racesWithQualyGrid.length} race(s) with qualyGrid have a qualifying_results backup`);
    } else {
        for (const id of missingBackups) {
            flag(`qualifying_results/${id} — MISSING backup for race with qualyGrid`);
        }
    }

    info(`qualifying_results docs: ${qrSnap.size} | races with qualyGrid: ${racesWithQualyGrid.length}`);

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log("\n" + SEP2);
    console.log("  AUDIT SUMMARY");
    console.log(SEP2);
    for (const [col, count] of Object.entries(counts)) {
        console.log(`  ${col.padEnd(22)} ${count} docs`);
    }
    console.log(SEP);

    if (warningCount === 0) {
        console.log("  ✅ No issues found. Firebase state is consistent.");
    } else {
        console.log(`  ⚠️  ${warningCount} warning(s) found. Review items above.`);
        console.log("  If season refs are inconsistent, run: node fix_season_refs.js");
        console.log("  If universe is stale, run:           node sync_universe.js");
    }
    console.log(SEP2 + "\n");
}

// ── Run ───────────────────────────────────────────────────────────────────────
audit()
    .catch((e) => {
        console.error("❌ Fatal error:", e);
        process.exit(1);
    })
    .finally(() => {
        try { fs.unlinkSync(adcPath); } catch (_) {}
        process.exit(0);
    });
