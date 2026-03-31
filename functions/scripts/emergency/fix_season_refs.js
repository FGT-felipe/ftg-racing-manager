/**
 * fix_season_refs.js
 *
 * Fixes the season reference mismatch: ensures all leagues and teams point
 * to the single canonical season document for the current year.
 *
 * Architecture rule enforced:
 *   ONE season document per year, shared by ALL leagues.
 *   Source of truth: leagues/{id}.currentSeasonId
 *   Frontend reads: universe/game_universe_v1.activeSeasonId
 *
 * Usage:
 *   node fix_season_refs.js                                       ← dry-run
 *   node fix_season_refs.js --season-id <id>                      ← dry-run with explicit season
 *   node fix_season_refs.js --season-id <id> --execute            ← apply changes
 */

const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_fix.json");
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

const DRY_RUN = !process.argv.includes("--execute");
const seasonIdArgIdx = process.argv.indexOf("--season-id");
const EXPLICIT_SEASON_ID = seasonIdArgIdx !== -1 ? process.argv[seasonIdArgIdx + 1] : null;

async function fixSeasonRefs() {
    console.log(DRY_RUN
        ? "🔍 DRY-RUN — no writes will be made. Pass --execute to apply.\n"
        : "🚨 EXECUTE MODE — writing to Firestore.\n"
    );

    // ── Step 1: Read all leagues and find the canonical season per league ──────
    console.log("Step 1: Reading leagues collection...");
    const leaguesSnap = await db.collection("leagues").get();
    if (leaguesSnap.empty) {
        console.error("❌ No league documents found. Aborting.");
        process.exit(1);
    }

    // Build a map: leagueId → { currentSeasonId, name }
    const leagueMap = {};
    for (const lDoc of leaguesSnap.docs) {
        const data = lDoc.data();
        leagueMap[lDoc.id] = {
            name: data.name || lDoc.id,
            currentSeasonId: data.currentSeasonId || null,
        };
        const status = data.currentSeasonId ? `→ ${data.currentSeasonId}` : "❌ NO currentSeasonId";
        console.log(`  League [${lDoc.id}] "${data.name || lDoc.id}": ${status}`);
    }
    console.log();

    // ── Step 2: Find the master season (should be the same for all leagues) ───
    // Prefer explicit --season-id arg; fall back to ftg_world.currentSeasonId.
    let MASTER_SEASON_ID = EXPLICIT_SEASON_ID;
    if (!MASTER_SEASON_ID) {
        const masterLeague = leagueMap["ftg_world"];
        MASTER_SEASON_ID = masterLeague?.currentSeasonId || null;
    }
    if (!MASTER_SEASON_ID) {
        console.error("❌ Could not determine master season. Pass --season-id <id> explicitly.");
        process.exit(1);
    }
    console.log(`✅ Master season (from ftg_world): ${MASTER_SEASON_ID}\n`);

    // Verify the season document exists
    const seasonDoc = await db.collection("seasons").doc(MASTER_SEASON_ID).get();
    if (!seasonDoc.exists) {
        console.error(`❌ Season document "${MASTER_SEASON_ID}" not found in Firestore. Aborting.`);
        process.exit(1);
    }
    const seasonData = seasonDoc.data();
    console.log(`  Season verified: year=${seasonData.year}, rounds=${(seasonData.calendar || []).length}\n`);

    // ── Step 3: Audit leagues that point to a different season ────────────────
    console.log("Step 3: Auditing leagues...");
    const leaguesToFix = [];
    for (const [lId, lData] of Object.entries(leagueMap)) {
        if (lId === "ftg_world") continue; // already correct
        if (lData.currentSeasonId !== MASTER_SEASON_ID) {
            console.log(`  ⚠️  League [${lId}] has wrong season: "${lData.currentSeasonId}" → should be "${MASTER_SEASON_ID}"`);
            leaguesToFix.push(lId);
        } else {
            console.log(`  ✅ League [${lId}] already correct`);
        }
    }
    console.log();

    // ── Step 4: Audit teams that point to a different season ─────────────────
    console.log("Step 4: Auditing teams...");
    const teamsSnap = await db.collection("teams").get();
    const teamsToFix = [];
    for (const tDoc of teamsSnap.docs) {
        const data = tDoc.data();
        const tSeason = data.currentSeasonId;
        if (tSeason && tSeason !== MASTER_SEASON_ID) {
            console.log(`  ⚠️  Team [${tDoc.id}] "${data.name}": wrong season "${tSeason}" → "${MASTER_SEASON_ID}"`);
            teamsToFix.push(tDoc.id);
        } else if (!tSeason) {
            console.log(`  ⚠️  Team [${tDoc.id}] "${data.name}": no currentSeasonId → will set "${MASTER_SEASON_ID}"`);
            teamsToFix.push(tDoc.id);
        }
    }
    console.log();

    // ── Step 5: Check universe activeSeasonId ────────────────────────────────
    console.log("Step 5: Checking universe/game_universe_v1.activeSeasonId...");
    const uDoc = await db.collection("universe").doc("game_universe_v1").get();
    const uData = uDoc.data() || {};
    const currentActiveSeasonId = uData.activeSeasonId;
    const universeNeedsUpdate = currentActiveSeasonId !== MASTER_SEASON_ID;
    if (universeNeedsUpdate) {
        console.log(`  ⚠️  universe.activeSeasonId: "${currentActiveSeasonId || "(not set)"}" → "${MASTER_SEASON_ID}"`);
    } else {
        console.log(`  ✅ universe.activeSeasonId already correct`);
    }
    console.log();

    // ── Summary ───────────────────────────────────────────────────────────────
    const totalFixes = leaguesToFix.length + teamsToFix.length + (universeNeedsUpdate ? 1 : 0);
    console.log("─────────────────────────────────────────────");
    console.log(`Pre-flight summary:`);
    console.log(`  Leagues to fix:  ${leaguesToFix.length}`);
    console.log(`  Teams to fix:    ${teamsToFix.length}`);
    console.log(`  Universe update: ${universeNeedsUpdate ? "YES" : "no"}`);
    console.log(`  Total writes:    ${totalFixes}`);
    console.log("─────────────────────────────────────────────\n");

    if (totalFixes === 0) {
        console.log("✅ Everything is already correct. No changes needed.");
        cleanup(adcPath);
        return;
    }

    if (DRY_RUN) {
        console.log("🔍 Dry-run complete. Run with --execute to apply these changes.");
        cleanup(adcPath);
        return;
    }

    // ── Apply fixes ───────────────────────────────────────────────────────────
    console.log("Applying fixes...\n");

    // Fix leagues
    for (const lId of leaguesToFix) {
        await db.collection("leagues").doc(lId).update({ currentSeasonId: MASTER_SEASON_ID });
        console.log(`  ✅ League [${lId}] updated`);
    }

    // Fix teams in batches of 500
    const teamBatches = [];
    for (let i = 0; i < teamsToFix.length; i += 499) {
        teamBatches.push(teamsToFix.slice(i, i + 499));
    }
    for (const chunk of teamBatches) {
        const batch = db.batch();
        for (const tId of chunk) {
            batch.update(db.collection("teams").doc(tId), { currentSeasonId: MASTER_SEASON_ID });
        }
        await batch.commit();
    }
    console.log(`  ✅ ${teamsToFix.length} teams updated`);

    // Fix universe
    if (universeNeedsUpdate) {
        await db.collection("universe").doc("game_universe_v1").update({ activeSeasonId: MASTER_SEASON_ID });
        console.log(`  ✅ universe.activeSeasonId updated to ${MASTER_SEASON_ID}`);
    }

    console.log("\n✅ All fixes applied successfully.");
    cleanup(adcPath);
}

function cleanup(adcPath) {
    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

fixSeasonRefs().catch((e) => {
    console.error("❌ Fatal error:", e);
    try { fs.unlinkSync(adcPath); } catch (_) { }
    process.exit(1);
});
