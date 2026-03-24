/**
 * rollback_academy_level2.js
 *
 * Finds all teams with youthAcademy at level 2 (due to the season-guard bug),
 * reverts them to level 1, and refunds the upgrade cost ($1,000,000).
 *
 * Also records a credit transaction for auditability.
 *
 * Usage: node scripts/emergency/rollback_academy_level2.js
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

const adcPath = path.join(__dirname, "_adc_temp_academy_rollback.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();

const REFUND_AMOUNT = 1_000_000; // Level 1→2 upgrade cost = 1,000,000 * 1

async function run() {
    const db = admin.firestore();

    // Resolve current season ID to lock upgrades for this season after rollback
    const seasonsSnap = await db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
    const currentSeasonId = seasonsSnap.empty ? null : seasonsSnap.docs[0].id;
    console.log(`📅 Temporada activa: ${currentSeasonId}\n`);

    console.log("🔍 Buscando equipos con youthAcademy en nivel 2...\n");

    const teamsSnap = await db.collection("teams")
        .where("facilities.youthAcademy.level", "==", 2)
        .get();

    if (teamsSnap.empty) {
        console.log("✅ No se encontraron equipos con academia en nivel 2. Nada que revertir.");
        cleanup();
        return;
    }

    console.log(`📋 Equipos encontrados: ${teamsSnap.size}\n`);

    for (const teamDoc of teamsSnap.docs) {
        const teamId = teamDoc.id;
        const teamData = teamDoc.data();
        const teamName = teamData.name || teamId;
        const currentBudget = teamData.budget ?? 0;

        console.log(`─────────────────────────────────────`);
        console.log(`🏎️  Equipo: ${teamName} (${teamId})`);
        console.log(`   Budget actual: $${currentBudget.toLocaleString()}`);

        // Check academy config subcollection
        const configRef = db.collection("teams").doc(teamId).collection("academy").doc("config");
        const configSnap = await configRef.get();

        if (!configSnap.exists) {
            console.log(`   ⚠️  Sin documento de config en academy. Skipping.\n`);
            continue;
        }

        const academyConfig = configSnap.data();
        const academyLevel = academyConfig.academyLevel;

        if (academyLevel !== 2) {
            console.log(`   ℹ️  Academy config level es ${academyLevel} (no 2). Solo se revierte facilities.\n`);
        }

        const newBudget = currentBudget + REFUND_AMOUNT;
        const teamRef = db.collection("teams").doc(teamId);

        // Batch all writes atomically
        const batch = db.batch();

        // 1. Revert facilities.youthAcademy.level to 1
        batch.update(teamRef, {
            "facilities.youthAcademy.level": 1,
            budget: newBudget
        });

        // 2. Revert academy config level to 1 (clear lastUpgradeSeasonId so they can upgrade legitimately)
        batch.update(configRef, {
            academyLevel: 1,
            lastUpgradeSeasonId: currentSeasonId
        });

        // 3. Record refund transaction
        const txRef = db.collection("teams").doc(teamId).collection("transactions").doc();
        batch.set(txRef, {
            id: txRef.id,
            description: "Academy Level Refund: Unauthorized upgrade reversal",
            amount: REFUND_AMOUNT,
            date: new Date().toISOString(),
            type: "REFUND"
        });

        await batch.commit();

        console.log(`   ✅ Revertido a nivel 1`);
        console.log(`   💰 Reembolso: +$${REFUND_AMOUNT.toLocaleString()}`);
        console.log(`   💳 Nuevo budget: $${newBudget.toLocaleString()}\n`);
    }

    console.log(`─────────────────────────────────────`);
    console.log(`\n✅ Rollback completado para ${teamsSnap.size} equipo(s).`);
    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) {}
}

run().catch(e => {
    console.error("❌ Error durante el rollback:", e);
    cleanup();
    process.exit(1);
});
