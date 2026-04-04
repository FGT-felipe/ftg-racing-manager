/**
 * migrate_race_season_ids.js
 *
 * Copies race documents from an old season ID to a new season ID.
 * Use this when race documents were written under a stale/deprecated
 * season ID and the app's activeSeasonId has changed.
 *
 * SCOPE: Only copies races/{OLD_ID}_r{N} → races/{NEW_ID}_r{N}.
 * Does NOT modify the originals. Does NOT touch any other collection.
 * SCOPE guard: skips any round that already exists under the new season ID.
 *
 * Usage:
 *   node migrate_race_season_ids.js --old <oldSeasonId> --new <newSeasonId>
 *     ← dry-run: prints what would be copied
 *
 *   node migrate_race_season_ids.js --old <oldSeasonId> --new <newSeasonId> --execute
 *     ← applies writes to Firestore
 *
 * Example:
 *   node migrate_race_season_ids.js --old qRM0nhyt95JGXqgxLtnT --new 3sh7fStGc55XxwmQHaJu
 */

const fs = require("fs");
const path = require("path");

const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_migrate.json");
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

// ── CLI args ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const DRY_RUN = !args.includes("--execute");
const oldIdx = args.indexOf("--old");
const newIdx = args.indexOf("--new");

if (oldIdx === -1 || newIdx === -1) {
    console.error("❌ Usage: node migrate_race_season_ids.js --old <oldId> --new <newId> [--execute]");
    process.exit(1);
}

const OLD_SEASON_ID = args[oldIdx + 1];
const NEW_SEASON_ID = args[newIdx + 1];

if (!OLD_SEASON_ID || !NEW_SEASON_ID) {
    console.error("❌ Both --old and --new must have values.");
    process.exit(1);
}

const MAX_ROUNDS = 20;

// ── Main ─────────────────────────────────────────────────────────────────────
async function migrateRaceSeasonIds() {
    console.log(DRY_RUN
        ? "🔍 DRY-RUN — no writes will be made. Pass --execute to apply.\n"
        : "🚨 EXECUTE MODE — writing to Firestore.\n"
    );
    console.log(`  Old season ID: ${OLD_SEASON_ID}`);
    console.log(`  New season ID: ${NEW_SEASON_ID}\n`);

    // ── Step 1: Discover all source race documents ────────────────────────────
    console.log("Step 1: Scanning source race documents...");
    const sources = [];

    for (let r = 1; r <= MAX_ROUNDS; r++) {
        const docId = `${OLD_SEASON_ID}_r${r}`;
        const snap = await db.collection("races").doc(docId).get();
        if (!snap.exists) continue;
        sources.push({ round: r, docId, data: snap.data() });
        const flags = [];
        if (snap.data().isFinished) flags.push("race:done");
        if (snap.data().qualyGrid?.length > 0 || snap.data().qualifyingResults?.length > 0) flags.push("qualy:done");
        console.log(`  Found: ${docId} [${flags.join(", ") || "no flags"}]`);
    }

    if (sources.length === 0) {
        console.log("  ⚠️  No race documents found under old season ID. Nothing to migrate.");
        cleanup();
        return;
    }
    console.log();

    // ── Step 2: Check which targets already exist ─────────────────────────────
    console.log("Step 2: Checking target documents...");
    const toCopy = [];
    const skipped = [];

    for (const src of sources) {
        const targetId = `${NEW_SEASON_ID}_r${src.round}`;
        const targetSnap = await db.collection("races").doc(targetId).get();
        if (targetSnap.exists) {
            console.log(`  ⏭  SKIP: ${targetId} already exists — not overwriting`);
            skipped.push(targetId);
        } else {
            console.log(`  📋 COPY: ${src.docId} → ${targetId}`);
            toCopy.push({ src, targetId });
        }
    }
    console.log();

    // ── Pre-flight summary ────────────────────────────────────────────────────
    console.log("─────────────────────────────────────────────");
    console.log("Pre-flight summary:");
    console.log(`  Documents to copy: ${toCopy.length}`);
    console.log(`  Skipped (already exist): ${skipped.length}`);
    console.log(`  Old season ID: ${OLD_SEASON_ID}`);
    console.log(`  New season ID: ${NEW_SEASON_ID}`);
    if (toCopy.length > 0) {
        console.log("\n  Will create:");
        toCopy.forEach(({ src, targetId }) => {
            console.log(`    races/${src.docId} → races/${targetId}`);
        });
    }
    console.log("─────────────────────────────────────────────\n");

    if (toCopy.length === 0) {
        console.log("✅ Nothing to copy. All rounds already exist under the new season ID.");
        cleanup();
        return;
    }

    if (DRY_RUN) {
        console.log("🔍 Dry-run complete. Run with --execute to apply these changes.");
        cleanup();
        return;
    }

    // ── Apply writes ──────────────────────────────────────────────────────────
    console.log("Applying writes...\n");
    for (const { src, targetId } of toCopy) {
        // Copy the entire document, preserving all fields
        await db.collection("races").doc(targetId).set(src.data);
        console.log(`  ✅ Created: races/${targetId}`);
    }

    console.log(`\n✅ Migration complete. ${toCopy.length} document(s) copied.`);
    console.log("   NOTE: Original documents under old season ID were NOT modified.");
    console.log("   Run sync_universe.js if standings need refreshing.");
    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (_) { }
    process.exit(0);
}

migrateRaceSeasonIds().catch((e) => {
    console.error("❌ Fatal error:", e);
    try { fs.unlinkSync(adcPath); } catch (_) { }
    process.exit(1);
});
