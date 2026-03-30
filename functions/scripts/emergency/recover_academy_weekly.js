/**
 * recover_academy_weekly.js
 *
 * Recovery script: generates weekly academy XP and events for all teams
 * WITHOUT touching budget, salaries, weekStatus, or sponsors.
 *
 * Use when postRaceProcessing ran with an empty teamIdsSet (R4 incident)
 * and academy events were never generated for that round.
 *
 * Safe to run after-the-fact — only writes to academy/config/selected/{driverId}:
 *   - weeklyGrowth (XP accumulation)
 *   - weeklyStatDiffs
 *   - weeklyEventMessage
 *   - stats (if XP threshold reached)
 *   - pendingAction / pendingActionType (if event roll triggers)
 *   - specialty (if threshold reached)
 *
 * Usage:
 *   cd functions/scripts/emergency
 *   node recover_academy_weekly.js          ← dry run (preview only)
 *   node recover_academy_weekly.js --apply  ← write to Firestore
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

const adcPath = path.join(__dirname, "_adc_temp_academy_recovery.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const DRY_RUN = !process.argv.includes("--apply");

if (DRY_RUN) {
    console.log("🔍 DRY RUN — no writes will happen. Pass --apply to execute.\n");
} else {
    console.log("✍️  APPLY MODE — writing to Firestore.\n");
}

const POSITIVE_EVENTS = {
    adaptability: [
        "amazed the engineers with their pace in the rain.",
        "quickly adapted to a drastic change in the weather.",
    ],
    cornering: [
        "spent extra hours perfecting their line through curves.",
        "demonstrated impeccable cornering in the simulator.",
    ],
    smoothness: [
        "showed great finesse with the tires.",
        "remarkably improved their driving fluidness.",
    ],
    braking: [
        "showed great skill and confidence in braking late.",
        "adjusted their braking technique to gain time.",
    ],
    overtaking: [
        "performed brilliant overtaking maneuvers in their last race.",
        "showed perfect calculated aggressiveness for passing.",
    ],
    consistency: [
        "remained unshakable under pressure, maintaining constant lap times.",
        "did not make a single mistake throughout the testing week.",
    ],
    focus: [
        "was extremely concentrated, ignoring external distractions.",
        "perfectly read the team's signals during the session.",
    ],
    fitness: [
        "passed all physical tests with the best score in the group.",
        "showed superior physical endurance in long runs.",
    ],
};

const NEGATIVE_EVENTS = [
    { stat: "focus",        diff: -1, msg: "was distracted by personal matters and their focus dropped." },
    { stat: "adaptability", diff: -1, msg: "struggled to adapt to recent circuit changes." },
    { stat: "braking",      diff: -1, msg: "suffered a minor incident, losing confidence in braking." },
];

async function processAcademyForTeam(tid, teamData) {
    const configRef = db.collection("teams").doc(tid).collection("academy").doc("config");
    const configDoc = await configRef.get();
    if (!configDoc.exists) return;

    const ac = configDoc.data();
    const academyLevel = ac.academyLevel || 1;
    const mRole = teamData.managerId ? (teamData.managerRole || "") : "";

    const selectedRef = configRef.collection("selected");
    const selectedSnap = await selectedRef.get();

    if (selectedSnap.empty) {
        console.log(`  [${tid}] No selected drivers — skipping.`);
        return;
    }

    const batch = db.batch();
    let driverCount = 0;

    for (const sDoc of selectedSnap.docs) {
        const yDriver = sDoc.data();

        let curWeekly = yDriver.weeklyGrowth || 0;
        const growthPot = yDriver.growthPotential || 5;
        const levelBonus = (academyLevel - 1) * 8;
        let xpGain = Math.floor(Math.random() * (growthPot * 15)) + 40 + levelBonus;

        if (mRole === "engineer") xpGain = Math.floor(xpGain * 0.95);
        if (yDriver.isMarkedForPromotion) xpGain = Math.floor(xpGain * 1.25);

        curWeekly += xpGain;

        const statDiffs = {};
        let eventMsg = "";
        const updates = {
            weeklyGrowth: curWeekly,
            weeklyStatDiffs: {},
            weeklyEventMessage: "",
        };

        if (curWeekly >= 500) {
            curWeekly -= 500;
            updates.weeklyGrowth = curWeekly;
            updates.baseSkill = (yDriver.baseSkill || 10) + 1;
            updates.growthPotential = Math.max((yDriver.growthPotential || 5) - 1, 1);

            const statsObj = { ...(yDriver.stats || { cornering: 6, braking: 6, consistency: 6, smoothness: 6, adaptability: 6, overtaking: 6, focus: 6, fitness: 6 }) };
            const keys = Object.keys(statsObj).filter(k => k !== "fitness");
            const boostedStat = keys[Math.floor(Math.random() * keys.length)];
            statsObj[boostedStat] += 1;
            statDiffs[boostedStat] = 1;

            const pool = POSITIVE_EVENTS[boostedStat] || ["Continued their steady progression in the program."];
            eventMsg = `${yDriver.name} ${pool[Math.floor(Math.random() * pool.length)]}`;
            updates.stats = statsObj;
        } else if (Math.random() < 0.15) {
            const neg = NEGATIVE_EVENTS[Math.floor(Math.random() * NEGATIVE_EVENTS.length)];
            eventMsg = `${yDriver.name} ${neg.msg}`;
            statDiffs[neg.stat] = neg.diff;
            const statsObj = { ...(yDriver.stats || {}) };
            if (statsObj[neg.stat]) statsObj[neg.stat] = Math.max(1, statsObj[neg.stat] + neg.diff);
            updates.stats = statsObj;
        }

        if (!yDriver.pendingAction) {
            const roll = Math.random();
            if (roll < 0.06) {
                updates.pendingAction = true;
                updates.pendingActionType = "INTENSIVE_TRAINING";
            } else if (roll < 0.26) {
                updates.pendingAction = true;
                updates.pendingActionType = ["SPONSOR_SHOOT", "TECHNICAL_TEST", "MENTOR_REQUEST"][Math.floor(Math.random() * 3)];
            }
        }

        if (!yDriver.specialty && yDriver.baseSkill >= 8) {
            const s = yDriver.stats || {};
            if (s.adaptability >= 11) updates.specialty = "Rainmaster";
            else if (s.smoothness >= 11) updates.specialty = "Tyre Whisperer";
            else if (s.braking >= 11) updates.specialty = "Late Braker";
            else if (s.overtaking >= 11) updates.specialty = "Defensive Minister";
        }

        updates.weeklyStatDiffs = statDiffs;
        updates.weeklyEventMessage = eventMsg;

        const xpLabel = curWeekly >= 500 ? "📈 GROWTH" : `XP: +${xpGain} (total ${updates.weeklyGrowth})`;
        const eventLabel = eventMsg ? `"${eventMsg}"` : "(no event this week)";
        console.log(`    ${yDriver.name}: ${xpLabel} | ${eventLabel}`);

        if (!DRY_RUN) {
            batch.update(sDoc.ref, updates);
        }

        driverCount++;
    }

    if (!DRY_RUN && driverCount > 0) {
        await batch.commit();
        console.log(`  ✅ [${tid}] ${driverCount} driver(s) updated.`);
    } else {
        console.log(`  👁  [${tid}] ${driverCount} driver(s) previewed (dry run).`);
    }
}

async function run() {
    const teamsSnap = await db.collection("teams").get();
    console.log(`Found ${teamsSnap.size} teams. Processing academy for each...\n`);

    for (const tDoc of teamsSnap.docs) {
        const tid = tDoc.id;
        const teamData = tDoc.data();
        if (teamData.isBot) continue; // skip bot teams — no academy

        console.log(`🏫 Team: ${teamData.name || tid}`);
        try {
            await processAcademyForTeam(tid, teamData);
        } catch (e) {
            console.error(`  ❌ Error processing ${tid}:`, e.message);
        }
    }

    console.log("\n" + (DRY_RUN ? "🔍 Dry run complete. Run with --apply to write." : "🎉 Academy recovery complete."));

    try { fs.unlinkSync(adcPath); } catch (e) { /* ignore */ }
    process.exit(0);
}

run();
