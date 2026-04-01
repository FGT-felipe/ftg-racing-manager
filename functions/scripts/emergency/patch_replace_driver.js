/**
 * patch_replace_driver.js
 *
 * Recovery: assigns Kendall Thomas the role of Luis Díaz in GBA Racing,
 * and releases Luis Díaz from the team.
 *
 * Usage:
 *   node patch_replace_driver.js            ← dry-run
 *   node patch_replace_driver.js --execute  ← apply
 */

const fs = require("fs");
const path = require("path");

const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_replace.json");
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
const TEAM_ID    = "team_cl_1771709065020_1";
const KENDALL_ID = "3ssarFMlDYmnXDep2be8";

async function main() {
    console.log(DRY_RUN ? "🔍 DRY-RUN\n" : "🚨 EXECUTE\n");

    // Find Luis Díaz in GBA Racing
    const luisSnap = await db.collection("drivers")
        .where("teamId", "==", TEAM_ID)
        .where("name", "==", "Luis Díaz")
        .get();

    if (luisSnap.empty) {
        console.error("❌ Luis Díaz not found in GBA Racing. Aborting.");
        cleanup(); return;
    }

    const luisDoc = luisSnap.docs[0];
    const luis = luisDoc.data();
    const luisRole = luis.role;

    // Kendall
    const kendallDoc = await db.collection("drivers").doc(KENDALL_ID).get();
    if (!kendallDoc.exists) {
        console.error("❌ Kendall Thomas not found. Aborting.");
        cleanup(); return;
    }

    console.log(`Luis Díaz  [${luisDoc.id}] role: ${luisRole} → released`);
    console.log(`Kendall Thomas [${KENDALL_ID}] role: (none) → ${luisRole}`);

    if (DRY_RUN) {
        console.log("\n🔍 Dry-run complete. Run with --execute to apply.");
        cleanup(); return;
    }

    const batch = db.batch();

    // Kendall gets Luis's role
    batch.update(db.collection("drivers").doc(KENDALL_ID), {
        role: luisRole,
    });

    // Luis leaves the team
    batch.update(luisDoc.ref, {
        teamId: "",
        role: "ex_driver",
        contractYearsRemaining: 0,
    });

    // Transaction record for GBA Racing
    const txRef = db.collection("teams").doc(TEAM_ID).collection("transactions").doc();
    batch.set(txRef, {
        id: txRef.id,
        description: `Transfer Market: Kendall Thomas signed (replaced Luis Díaz)`,
        amount: -1390500,
        date: new Date().toISOString(),
        type: "TRANSFER",
    });

    await batch.commit();

    // News + notification
    const newsRef = db.collection("teams").doc(TEAM_ID).collection("news").doc();
    const notifRef = db.collection("teams").doc(TEAM_ID).collection("notifications").doc();
    const newsBatch = db.batch();
    const payload = {
        title: "Transfer Completed",
        message: `Kendall Thomas has joined GBA Racing as ${luisRole}, replacing Luis Díaz ($1,390,500).`,
        type: "TRANSFER_WON",
        teamId: TEAM_ID,
        isRead: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    };
    newsBatch.set(newsRef, payload);
    newsBatch.set(notifRef, payload);
    await newsBatch.commit();

    console.log("✅ Done:");
    console.log(`   Kendall Thomas → role: ${luisRole}`);
    console.log(`   Luis Díaz → ex_driver, teamId: ""`);
    console.log(`   Transaction logged: -$1,390,500 TRANSFER`);
    console.log(`   News + notification sent`);

    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) {}
    process.exit(0);
}

main().catch(e => { console.error("❌ Fatal:", e); cleanup(); });
