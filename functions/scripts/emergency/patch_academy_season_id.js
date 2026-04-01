/**
 * patch_academy_season_id.js
 *
 * Emergency patch for academies where lastUpgradeSeasonId was saved as null
 * due to a bug in upgradeAcademy() that fell back to data.currentSeasonId
 * (a field that may not exist on the team document).
 *
 * Impact: without lastUpgradeSeasonId set, canUpgrade always returns true,
 * allowing teams to upgrade multiple times per season — a gameplay balance exploit.
 *
 * What it does:
 *  1. Reads the current season ID from universe/game_universe_v1.currentSeasonId
 *  2. Scans all teams/{teamId}/academy/config documents
 *  // SCOPE: Only academies with academyLevel > 1 AND lastUpgradeSeasonId == null
 *  //        (level 1 = purchased this season or first season; eligible for upgrade)
 *  3. DRY-RUN: prints affected team IDs and their current academyLevel
 *  4. EXECUTE: sets lastUpgradeSeasonId = currentSeasonId on both:
 *              - teams/{teamId}/academy/config
 *              - teams/{teamId}.facilities.youthAcademy.lastUpgradeSeasonId
 *
 * Usage:
 *   node patch_academy_season_id.js            ← dry-run (safe, no writes)
 *   node patch_academy_season_id.js --execute  ← apply writes
 */

const fs = require("fs");
const path = require("path");

const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_patch_academy.json");
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

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) {}
}

async function main() {
    console.log(DRY_RUN
        ? "🔍 DRY-RUN — no writes. Pass --execute to apply.\n"
        : "🚨 EXECUTE MODE — writing to Firestore.\n"
    );

    // Step 1 — Get current season ID from universe doc
    const universeSnap = await db.collection("universe").doc("game_universe_v1").get();
    if (!universeSnap.exists) {
        console.error("❌ universe/game_universe_v1 not found. Aborting.");
        cleanup(); return;
    }
    const currentSeasonId = universeSnap.data().currentSeasonId;
    if (!currentSeasonId) {
        console.error("❌ currentSeasonId not found in universe doc. Aborting.");
        cleanup(); return;
    }
    console.log(`✅ Current season ID: ${currentSeasonId}\n`);

    // Step 2 — Get all teams
    const teamsSnap = await db.collection("teams").get();
    if (teamsSnap.empty) {
        console.log("No teams found.");
        cleanup(); return;
    }

    const affected = [];

    for (const teamDoc of teamsSnap.docs) {
        const teamId = teamDoc.id;
        const configRef = db.collection("teams").doc(teamId).collection("academy").doc("config");
        const configSnap = await configRef.get();

        // SCOPE: Only teams with an active academy config
        if (!configSnap.exists) continue;

        const cfg = configSnap.data();
        const academyLevel = cfg.academyLevel || 0;
        const lastUpgradeSeasonId = cfg.lastUpgradeSeasonId ?? null;

        // SCOPE: Only academies with level > 1 and lastUpgradeSeasonId == null
        // (level 1 with null = purchased this season, legitimately eligible to upgrade)
        if (academyLevel <= 1) continue;
        if (lastUpgradeSeasonId !== null) continue;

        affected.push({ teamId, academyLevel, teamName: teamDoc.data().name ?? teamId });
    }

    // Step 3 — Pre-flight summary
    console.log(`📋 Affected teams (academyLevel > 1, lastUpgradeSeasonId = null): ${affected.length}\n`);
    for (const t of affected) {
        console.log(`  [${t.teamId}] ${t.teamName} — academyLevel: ${t.academyLevel}`);
    }

    if (affected.length === 0) {
        console.log("\n✅ No teams need patching.");
        cleanup(); return;
    }

    if (DRY_RUN) {
        console.log("\n⚠️  Dry-run complete. Run with --execute to apply.");
        cleanup(); return;
    }

    // Step 4 — Apply patches
    console.log("\n🔧 Applying patches...\n");
    let patched = 0;

    for (const t of affected) {
        const configRef = db.collection("teams").doc(t.teamId).collection("academy").doc("config");
        const teamRef = db.collection("teams").doc(t.teamId);

        const batch = db.batch();

        batch.update(configRef, {
            lastUpgradeSeasonId: currentSeasonId
        });

        batch.update(teamRef, {
            "facilities.youthAcademy.lastUpgradeSeasonId": currentSeasonId
        });

        await batch.commit();
        console.log(`  ✅ [${t.teamId}] ${t.teamName} — patched lastUpgradeSeasonId = ${currentSeasonId}`);
        patched++;
    }

    console.log(`\n✅ Done. ${patched} team(s) patched.`);
    cleanup();
}

main().catch((e) => {
    console.error("Fatal error:", e);
    cleanup();
    process.exit(1);
});
