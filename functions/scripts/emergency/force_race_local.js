/**
 * Sets up Application Default Credentials using Firebase CLI's refresh token,
 * then runs the race simulation logic.
 */
const fs = require("fs");
const path = require("path");

// 1. Read Firebase CLI credentials
const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

// 2. Write an ADC-compatible JSON file
const adcCredentials = {
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
};

const adcPath = path.join(__dirname, "_adc_temp.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

// 3. Set the environment variable BEFORE any google-cloud lib loads
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

// 4. Now initialize admin
const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

console.log("✅ Admin SDK initialized with ADC from Firebase CLI");
console.log("👤 User:", config.user.email);
console.log("");

async function main() {
    try {
        console.log("🔍 Verifying Firestore connection...");
        const uDoc = await db.collection("universe").doc("game_universe_v1").get();
        if (!uDoc.exists) { console.error("❌ No universe doc!"); process.exit(1); }
        console.log("✅ Connected!\n");

        const leagues = Object.values(uDoc.data().leagues || {});
        console.log(`Found ${leagues.length} league(s)\n`);

        for (const league of leagues) {
            console.log(`🏎️  ${league.name}`);

            let sId = league.currentSeasonId;
            let sDoc = sId ? await db.collection("seasons").doc(sId).get() : null;
            if (!sDoc || !sDoc.exists) {
                const fb = await db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
                if (fb.empty) { console.log("   ❌ No seasons"); continue; }
                sDoc = fb.docs[0]; sId = sDoc.id;
            }

            const season = sDoc.data();
            const rIdx = (season.calendar || []).findIndex(r => !r.isCompleted);
            if (rIdx === -1) { console.log("   ✅ All races done"); continue; }

            const rEvent = season.calendar[rIdx];
            const raceDocId = `${sId}_${rEvent.id}`;
            console.log(`   🏁 ${rEvent.trackName} → ${raceDocId}`);

            const rSnap = await db.collection("races").doc(raceDocId).get();
            if (!rSnap.exists) { console.log("   ❌ No race doc"); continue; }

            const rData = rSnap.data();
            console.log(`   Grid: ${rData.qualyGrid ? rData.qualyGrid.length : "NONE"} | Finished: ${!!rData.isFinished}`);
        }
    } catch (err) {
        console.error("❌ Error:", err.message);
    }

    // Cleanup temp file
    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

main();
