const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_sync.json");
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

async function syncUniverse() {
    console.log("🔄 Syncing universe document with real data from collections...\n");

    const uRef = db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    const uData = uDoc.data();
    const leagues = uData.leagues; // array

    for (let li = 0; li < leagues.length; li++) {
        const league = leagues[li];
        console.log(`League ${li}: ${league.name}`);

        // Sync drivers
        for (let di = 0; di < league.drivers.length; di++) {
            const uDriver = league.drivers[di];
            const dDoc = await db.collection("drivers").doc(uDriver.id).get();
            if (dDoc.exists) {
                const real = dDoc.data();
                const changed = (uDriver.points !== (real.points || 0)) || (uDriver.seasonPoints !== (real.seasonPoints || 0));
                if (changed) {
                    console.log(`  Driver ${uDriver.name}: pts ${uDriver.points} → ${real.points || 0}, sPts ${uDriver.seasonPoints} → ${real.seasonPoints || 0}`);
                }
                leagues[li].drivers[di].points = real.points || 0;
                leagues[li].drivers[di].seasonPoints = real.seasonPoints || 0;
                leagues[li].drivers[di].wins = real.wins || 0;
                leagues[li].drivers[di].seasonWins = real.seasonWins || 0;
                leagues[li].drivers[di].podiums = real.podiums || 0;
                leagues[li].drivers[di].seasonPodiums = real.seasonPodiums || 0;
                leagues[li].drivers[di].races = real.races || 0;
                leagues[li].drivers[di].seasonRaces = real.seasonRaces || 0;
                leagues[li].drivers[di].championships = real.championships || 0;
                leagues[li].drivers[di].championshipForm = real.championshipForm || [];
                leagues[li].drivers[di].careerHistory = real.careerHistory || [];

            }
        }

        // Sync teams
        for (let ti = 0; ti < league.teams.length; ti++) {
            const uTeam = league.teams[ti];
            const tDoc = await db.collection("teams").doc(uTeam.id).get();
            if (tDoc.exists) {
                const real = tDoc.data();
                const changed = (uTeam.points !== (real.points || 0)) || (uTeam.seasonPoints !== (real.seasonPoints || 0));
                if (changed) {
                    console.log(`  Team ${uTeam.name}: pts ${uTeam.points} → ${real.points || 0}, sPts ${uTeam.seasonPoints} → ${real.seasonPoints || 0}`);
                }
                leagues[li].teams[ti].points = real.points || 0;
                leagues[li].teams[ti].seasonPoints = real.seasonPoints || 0;
                leagues[li].teams[ti].wins = real.wins || 0;
                leagues[li].teams[ti].seasonWins = real.seasonWins || 0;
                leagues[li].teams[ti].podiums = real.podiums || 0;
                leagues[li].teams[ti].seasonPodiums = real.seasonPodiums || 0;
                leagues[li].teams[ti].races = real.races || 0;
                leagues[li].teams[ti].seasonRaces = real.seasonRaces || 0;
                // Sync name too in case user changed it
                if (real.name) leagues[li].teams[ti].name = real.name;
            }
        }
    }

    // Sync activeSeasonId from ftg_world league so the frontend reads the correct season
    let activeSeasonId;
    const masterLDoc = await db.collection("leagues").doc("ftg_world").get();
    if (masterLDoc.exists) {
        activeSeasonId = masterLDoc.data().currentSeasonId;
        console.log(`activeSeasonId (from ftg_world): ${activeSeasonId || "(not found)"}`);
    }

    console.log("\n💾 Writing updated universe...");
    const updatePayload = { leagues };
    if (activeSeasonId) updatePayload.activeSeasonId = activeSeasonId;
    await uRef.update(updatePayload);
    console.log("✅ Universe synced!\n");

    // Verify
    const verify = await uRef.get();
    const vLeague = verify.data().leagues[0];
    console.log("Verification (League 0):");
    const topDrivers = [...vLeague.drivers].sort((a, b) => (b.seasonPoints || 0) - (a.seasonPoints || 0));
    for (let i = 0; i < Math.min(5, topDrivers.length); i++) {
        console.log(`  ${i + 1}. ${topDrivers[i].name} - ${topDrivers[i].seasonPoints} pts`);
    }

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

syncUniverse();
