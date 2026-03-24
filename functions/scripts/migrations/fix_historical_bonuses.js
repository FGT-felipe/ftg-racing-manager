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

const adcPath = path.join(__dirname, "_adc_temp_fix_v2.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

const FALLBACK_BONUSES = {
  "titans_oil": 250000,
  "global_tech": 200000,
  "zenith_sky": 300000,
  "fast_logistics": 100000,
  "spark_energy": 120000,
  "eco_pulse": 80000,
  "local_drinks": 30000,
  "micro_chips": 40000,
  "nitro_gear": 35000,
};

const FALLBACK_OBJECTIVES = {
  "titans_oil": "Finish Top 3",
  "global_tech": "Both in Points",
  "zenith_sky": "Race Win",
  "fast_logistics": "Finish Race",
  "spark_energy": "Finish Top 10",
  "eco_pulse": "Finish Top 10",
  "local_drinks": "Finish Race",
  "micro_chips": "Finish Top 10",
  "nitro_gear": "Fastest Lap"
};

function evaluateObjective(contract, raceData, teamDrivers) {
  const rawDesc = contract.objectiveDescription || FALLBACK_OBJECTIVES[contract.sponsorId] || "";
  const desc = rawDesc.toLowerCase();
  const finalPositions = raceData.finalPositions || {};
  const dnfs = raceData.dnfs || [];
  const fastLapDriver = raceData.fast_lap_driver;

  if (desc.includes("race win")) {
    return teamDrivers.some((id) => finalPositions[id] === 0 && !dnfs.includes(id));
  }
  if (desc.includes("finish top 3")) {
    return teamDrivers.some((id) => finalPositions[id] >= 0 && finalPositions[id] < 3 && !dnfs.includes(id));
  }
  if (desc.includes("finish top 10")) {
    return teamDrivers.some((id) => finalPositions[id] >= 0 && finalPositions[id] < 10 && !dnfs.includes(id));
  }
  if (desc.includes("both in points")) {
    return teamDrivers.every((id) => {
      const pos = finalPositions[id];
      return pos >= 0 && pos < 10 && !dnfs.includes(id);
    });
  }
  if (desc.includes("fastest lap")) {
    return teamDrivers.includes(fastLapDriver);
  }
  if (desc.includes("finish race")) {
    return teamDrivers.some((id) => !dnfs.includes(id));
  }
  return false;
}

async function fixHistoricalBonuses() {
    console.log("Starting historical bonus correction V2...");
    
    const raceId = "qRM0nhyt95JGXqgxLtnT_r1";
    const raceSnap = await db.collection("races").doc(raceId).get();
    
    if (!raceSnap.exists) {
        console.error("Race R1 not found.");
        return;
    }
    
    const rd = raceSnap.data();
    const driverIds = Object.keys(rd.finalPositions || {});
    const teamIdsSet = new Set();

    const driverTeamMap = {};
    const dSnaps = await db.collection("drivers").get();
    dSnaps.forEach(d => {
        const data = d.data();
        driverTeamMap[d.id] = data.teamId;
        if (driverIds.includes(d.id)) {
            teamIdsSet.add(data.teamId);
        }
    });

    console.log(`Processing ${teamIdsSet.size} teams...`);

    for (const tid of teamIdsSet) {
        const tDoc = await db.collection("teams").doc(tid).get();
        if (!tDoc.exists) continue;
        
        const teamData = tDoc.data();
        const sponsors = teamData.sponsors || {};
        const teamDrivers = Object.keys(driverTeamMap).filter(did => driverTeamMap[did] === tid);
        
        let totalBonus = 0;
        const awardedLogs = [];

        for (const [slot, contract] of Object.entries(sponsors)) {
            if (evaluateObjective(contract, rd, teamDrivers)) {
                // Check if already awarded
                const txSnap = await db.collection("teams").doc(tid).collection("transactions")
                    .where("type", "==", "SPONSOR")
                    .where("description", "==", `Sponsor Objective Met: ${contract.sponsorName} (${slot})`)
                    .get();
                
                if (txSnap.empty) {
                    const bonus = contract.objectiveBonus || FALLBACK_BONUSES[contract.sponsorId] || 0;
                    const finalDesc = contract.objectiveDescription || FALLBACK_OBJECTIVES[contract.sponsorId] || "Contract Objective";
                    if (bonus > 0) {
                        totalBonus += bonus;
                        awardedLogs.push({
                            slot,
                            name: contract.sponsorName,
                            bonus,
                            desc: finalDesc
                        });
                    }
                }
            }
        }

        if (totalBonus > 0) {
            console.log(`Awarding $${totalBonus} to ${teamData.name}:`);
            const batch = db.batch();
            const tRef = db.collection("teams").doc(tid);
            
            batch.update(tRef, {
                budget: admin.firestore.FieldValue.increment(totalBonus)
            });

            for (const item of awardedLogs) {
                console.log(` - ${item.name} (${item.slot}): $${item.bonus}`);
                const txRef = tRef.collection("transactions").doc();
                batch.set(txRef, {
                    id: txRef.id,
                    description: `Sponsor Objective Met: ${item.name} (${item.slot})`,
                    amount: item.bonus,
                    date: admin.firestore.FieldValue.serverTimestamp(),
                    type: "SPONSOR"
                });

                // 1. Notifications (Dashboard)
                const notifRef = tRef.collection("notifications").doc();
                batch.set(notifRef, {
                    title: "Sponsor Objective Met (R1)",
                    message: `Congratulations! We cross-checked R1 and met the ${item.name} objective: "${item.desc}". A bonus of $${item.bonus.toLocaleString()} has been awarded.`,
                    type: "SUCCESS",
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false
                });

                // 2. News (Office Facility)
                const newsRef = tRef.collection("news").doc();
                batch.set(newsRef, {
                    title: "Sponsor Bonus Awarded",
                    message: `${item.name} has paid the $${item.bonus.toLocaleString()} bonus for meeting the objective in R1.`,
                    type: "SUCCESS",
                    timestamp: admin.firestore.FieldValue.serverTimestamp(),
                    isRead: false,
                    teamId: tid
                });
            }
            await batch.commit();
        }
    }
    console.log("Correction complete.");
    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
}

fixHistoricalBonuses().catch(e => {
    console.error(e);
    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
});
