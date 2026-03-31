/**
 * fix_calendar_completed.js
 *
 * Fixes two issues caused by season document fragmentation:
 *
 * 1. Copies isCompleted=true from qRM0nhyt95JGXqgxLtnT (source of truth for
 *    race completions) into 3sh7fStGc55XxwmQHaJu (master FTG World season).
 *    Fixes: calendar shows R1 instead of R5.
 *
 * 2. Injects currentSeasonId="3sh7fStGc55XxwmQHaJu" into every league object
 *    inside universe/game_universe_v1.leagues[].
 *    Fixes: qualifying uses wrong season → creates race docs for wrong season.
 *
 * Usage:
 *   node fix_calendar_completed.js              ← dry-run
 *   node fix_calendar_completed.js --execute    ← apply
 */

const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_cal.json");
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
const MASTER_SEASON_ID = "3sh7fStGc55XxwmQHaJu";
const SOURCE_SEASON_ID  = "qRM0nhyt95JGXqgxLtnT"; // has correct isCompleted state

async function main() {
    console.log(DRY_RUN
        ? "🔍 DRY-RUN — no writes. Pass --execute to apply.\n"
        : "🚨 EXECUTE MODE — writing to Firestore.\n"
    );

    // ── Fix 1: Sync isCompleted flags ────────────────────────────────────────
    console.log("Fix 1: Syncing isCompleted flags...");

    const sourceDoc = await db.collection("seasons").doc(SOURCE_SEASON_ID).get();
    const masterDoc = await db.collection("seasons").doc(MASTER_SEASON_ID).get();

    if (!sourceDoc.exists) { console.error(`❌ Source season ${SOURCE_SEASON_ID} not found`); process.exit(1); }
    if (!masterDoc.exists) { console.error(`❌ Master season ${MASTER_SEASON_ID} not found`); process.exit(1); }

    const sourceCal = sourceDoc.data().calendar || [];
    const masterCal = masterDoc.data().calendar || [];

    // Build completed set from source
    const completedIds = new Set(sourceCal.filter(e => e.isCompleted).map(e => e.id));
    console.log(`  Source completed rounds: ${[...completedIds].join(", ") || "(none)"}`);

    let calendarChanged = false;
    const updatedMasterCal = masterCal.map(e => {
        if (completedIds.has(e.id) && !e.isCompleted) {
            console.log(`  ✎  ${e.id} "${e.trackName}": isCompleted false → true`);
            calendarChanged = true;
            return { ...e, isCompleted: true };
        }
        return e;
    });

    if (!calendarChanged) {
        console.log("  ✅ Master calendar already in sync — no changes needed");
    }

    // ── Fix 2: Inject currentSeasonId into universe leagues array ────────────
    console.log("\nFix 2: Injecting currentSeasonId into universe leagues...");

    const uDoc = await db.collection("universe").doc("game_universe_v1").get();
    if (!uDoc.exists) { console.error("❌ Universe doc not found"); process.exit(1); }

    const uData = uDoc.data();
    const leagues = uData.leagues || [];
    let leaguesChanged = false;

    const updatedLeagues = leagues.map(l => {
        if (l.currentSeasonId !== MASTER_SEASON_ID) {
            console.log(`  ✎  League "${l.name}": currentSeasonId "${l.currentSeasonId || "(unset)"}" → "${MASTER_SEASON_ID}"`);
            leaguesChanged = true;
            return { ...l, currentSeasonId: MASTER_SEASON_ID };
        }
        console.log(`  ✅ League "${l.name}": already correct`);
        return l;
    });

    // ── Summary ───────────────────────────────────────────────────────────────
    console.log("\n─────────────────────────────────────────────");
    console.log("Pre-flight summary:");
    console.log(`  Calendar rounds to mark completed: ${updatedMasterCal.filter(e => completedIds.has(e.id)).length}`);
    console.log(`  Universe leagues to update:        ${updatedLeagues.filter((l,i) => l.currentSeasonId !== (leagues[i]?.currentSeasonId)).length}`);
    console.log("─────────────────────────────────────────────\n");

    if (DRY_RUN) {
        console.log("🔍 Dry-run complete. Run with --execute to apply.");
        cleanup();
        return;
    }

    // ── Apply ─────────────────────────────────────────────────────────────────
    if (calendarChanged) {
        await db.collection("seasons").doc(MASTER_SEASON_ID).update({ calendar: updatedMasterCal });
        console.log(`✅ ${MASTER_SEASON_ID} calendar updated`);
    }

    if (leaguesChanged) {
        await db.collection("universe").doc("game_universe_v1").update({ leagues: updatedLeagues });
        console.log("✅ universe/game_universe_v1 leagues updated");
    }

    console.log("\n✅ All fixes applied.");
    cleanup();
}

function cleanup() {
    try { fs.unlinkSync(adcPath); } catch (e) {}
    process.exit(0);
}

main().catch(e => { console.error("❌ Fatal:", e); cleanup(); });
