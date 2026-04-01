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
    const leagues = uData.leagues;

    // Load all real drivers into a map once
    const allDriversSnap = await db.collection("drivers").get();
    const realDrivers = {};
    for (const d of allDriversSnap.docs) {
        realDrivers[d.id] = { id: d.id, ...d.data() };
    }

    for (let li = 0; li < leagues.length; li++) {
        const league = leagues[li];
        console.log(`\nLeague ${li}: ${league.name}`);

        // Build set of teamIds in this league
        const leagueTeamIds = new Set((league.teams || []).map(t => t.id));

        // ── Sync existing drivers (stats + teamId) ────────────────────────────
        for (let di = 0; di < league.drivers.length; di++) {
            const uDriver = league.drivers[di];
            const real = realDrivers[uDriver.id];
            if (!real) continue;

            if (uDriver.teamId !== real.teamId) {
                console.log(`  Driver ${real.name}: teamId ${uDriver.teamId || "(none)"} → ${real.teamId || "(free agent)"}`);
            }

            leagues[li].drivers[di].teamId          = real.teamId || "";
            leagues[li].drivers[di].gender          = real.gender || "male";
            leagues[li].drivers[di].countryCode     = real.countryCode || "";
            leagues[li].drivers[di].points          = real.points || 0;
            leagues[li].drivers[di].seasonPoints    = real.seasonPoints || 0;
            leagues[li].drivers[di].wins            = real.wins || 0;
            leagues[li].drivers[di].seasonWins      = real.seasonWins || 0;
            leagues[li].drivers[di].podiums         = real.podiums || 0;
            leagues[li].drivers[di].seasonPodiums   = real.seasonPodiums || 0;
            leagues[li].drivers[di].races           = real.races || 0;
            leagues[li].drivers[di].seasonRaces     = real.seasonRaces || 0;
            leagues[li].drivers[di].championships   = real.championships || 0;
            leagues[li].drivers[di].championshipForm = real.championshipForm || [];
            leagues[li].drivers[di].careerHistory   = real.careerHistory || [];
        }

        // ── Add drivers assigned to league teams but missing from universe ────
        const knownDriverIds = new Set(leagues[li].drivers.map(d => d.id));

        for (const real of Object.values(realDrivers)) {
            if (!real.teamId || !leagueTeamIds.has(real.teamId)) continue;
            if (knownDriverIds.has(real.id)) continue;

            console.log(`  ➕ Adding new driver to universe: ${real.name} (${real.teamId})`);
            leagues[li].drivers.push({
                id:              real.id,
                name:            real.name,
                teamId:          real.teamId,
                gender:          real.gender || "male",
                countryCode:     real.countryCode || "",
                points:          real.points || 0,
                seasonPoints:    real.seasonPoints || 0,
                wins:            real.wins || 0,
                seasonWins:      real.seasonWins || 0,
                podiums:         real.podiums || 0,
                seasonPodiums:   real.seasonPodiums || 0,
                races:           real.races || 0,
                seasonRaces:     real.seasonRaces || 0,
                championships:   real.championships || 0,
                championshipForm: real.championshipForm || [],
                careerHistory:   real.careerHistory || [],
            });
        }

        // ── Sync teams ────────────────────────────────────────────────────────
        for (let ti = 0; ti < league.teams.length; ti++) {
            const uTeam = league.teams[ti];
            const tDoc = await db.collection("teams").doc(uTeam.id).get();
            if (!tDoc.exists) continue;
            const real = tDoc.data();

            leagues[li].teams[ti].points        = real.points || 0;
            leagues[li].teams[ti].seasonPoints  = real.seasonPoints || 0;
            leagues[li].teams[ti].wins          = real.wins || 0;
            leagues[li].teams[ti].seasonWins    = real.seasonWins || 0;
            leagues[li].teams[ti].podiums       = real.podiums || 0;
            leagues[li].teams[ti].seasonPodiums = real.seasonPodiums || 0;
            leagues[li].teams[ti].races         = real.races || 0;
            leagues[li].teams[ti].seasonRaces   = real.seasonRaces || 0;
            if (real.name) leagues[li].teams[ti].name = real.name;
        }
    }

    // ── Sync activeSeasonId ───────────────────────────────────────────────────
    let activeSeasonId;
    const masterLDoc = await db.collection("leagues").doc("ftg_world").get();
    if (masterLDoc.exists) {
        activeSeasonId = masterLDoc.data().currentSeasonId;
        console.log(`\nactiveSeasonId (from ftg_world): ${activeSeasonId || "(not found)"}`);
    }

    console.log("\n💾 Writing updated universe...");
    const updatePayload = { leagues };
    if (activeSeasonId) updatePayload.activeSeasonId = activeSeasonId;
    await uRef.update(updatePayload);
    console.log("✅ Universe synced!\n");

    // Verify
    const verify = await uRef.get();
    const vLeague = verify.data().leagues[0];
    console.log("Verification (League 0 — top 5 drivers by season points):");
    const topDrivers = [...vLeague.drivers].sort((a, b) => (b.seasonPoints || 0) - (a.seasonPoints || 0));
    for (let i = 0; i < Math.min(5, topDrivers.length); i++) {
        const d = topDrivers[i];
        console.log(`  ${i + 1}. ${d.name} (${d.teamId || "free agent"}) — ${d.seasonPoints} pts`);
    }

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

syncUniverse();
