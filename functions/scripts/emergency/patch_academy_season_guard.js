/**
 * patch_academy_season_guard.js
 *
 * Patches the two teams whose lastUpgradeSeasonId was incorrectly set to null
 * during the academy rollback. Sets it to the current active season ID so they
 * cannot upgrade again this season.
 *
 * Usage: node scripts/emergency/patch_academy_season_guard.js
 */

const fs = require("fs");
const path = require("path");

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

const adcPath = path.join(__dirname, "_adc_temp_patch_academy.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();

async function run() {
    const db = admin.firestore();

    // 1. Find current active season
    const seasonsSnap = await db.collection("seasons")
        .orderBy("startDate", "desc")
        .limit(1)
        .get();

    if (seasonsSnap.empty) {
        console.error("❌ No se encontró ninguna temporada activa.");
        cleanup();
        return;
    }

    const currentSeasonId = seasonsSnap.docs[0].id;
    console.log(`📅 Temporada activa: ${currentSeasonId}\n`);

    // 2. Find all teams with academy level 1 and lastUpgradeSeasonId == null
    //    (these are the ones affected by the rollback)
    const teamsSnap = await db.collection("teams")
        .where("facilities.youthAcademy.level", "==", 1)
        .get();

    let patched = 0;

    for (const teamDoc of teamsSnap.docs) {
        const teamId = teamDoc.id;
        const teamData = teamDoc.data();
        const teamName = teamData.name || teamId;

        const configRef = db.collection("teams").doc(teamId).collection("academy").doc("config");
        const configSnap = await configRef.get();
        if (!configSnap.exists) continue;

        const academyConfig = configSnap.data();
        if (academyConfig.lastUpgradeSeasonId !== null && academyConfig.lastUpgradeSeasonId !== undefined) continue;

        console.log(`🔧 Parcheando: ${teamName} (${teamId})`);

        const batch = db.batch();
        batch.update(configRef, { lastUpgradeSeasonId: currentSeasonId });
        batch.update(db.collection("teams").doc(teamId), {
            "facilities.youthAcademy.lastUpgradeSeasonId": currentSeasonId
        });
        await batch.commit();

        console.log(`   ✅ lastUpgradeSeasonId → "${currentSeasonId}"\n`);
        patched++;
    }

    if (patched === 0) {
        console.log("ℹ️  No se encontraron equipos con lastUpgradeSeasonId nulo.");
    } else {
        console.log(`✅ Patch completado para ${patched} equipo(s).`);
    }

    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) {}
}

run().catch(e => {
    console.error("❌ Error:", e);
    cleanup();
    process.exit(1);
});
