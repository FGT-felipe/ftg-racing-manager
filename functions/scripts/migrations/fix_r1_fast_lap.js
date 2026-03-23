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

const adcPath = path.join(__dirname, "_adc_temp_fast_lap.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function fixR1() {
    const raceId = "qRM0nhyt95JGXqgxLtnT_r1";
    const raceRef = db.collection("races").doc(raceId);
    const snap = await raceRef.get();
    
    if (!snap.exists) {
        console.log("Race r1 not found");
        return;
    }
    
    const data = snap.data();
    const totalTimes = data.totalTimes || {};
    const laps = data.totalLaps || 50;
    
    let fastLapTime = 999999;
    let fastLapDriver = "";
    
    Object.entries(totalTimes).forEach(([id, t]) => {
        if (data.dnfs && data.dnfs.includes(id)) return;
        const avg = t / laps;
        if (avg < fastLapTime) {
            fastLapTime = avg;
            fastLapDriver = id;
        }
    });
    
    console.log(`Calculated Fast Lap for R1: ${fastLapTime}s by ${fastLapDriver}`);
    
    // Update race document
    await raceRef.update({
        fast_lap_time: fastLapTime,
        fast_lap_driver: fastLapDriver
    });
    console.log("Race r1 updated.");
    
    // Check for sponsor bonuses
    // We'll search for teams that have the "Fastest Lap" objective
    const teamsSnap = await db.collection("teams").get();
    for (const teamDoc of teamsSnap.docs) {
        const team = teamDoc.data();
        const sponsors = team.sponsors || {};
        
        for (const [sid, s] of Object.entries(sponsors)) {
            const desc = s.objectiveDescription || "";
            if (desc.includes("Fastest Lap")) {
                // This team has a fastest lap objective
                // Now check if their driver is the fastLapDriver
                // We need to check the drivers belonging to this team
                const driversSnap = await db.collection("drivers").where("teamId", "==", teamDoc.id).get();
                const driverIds = driversSnap.docs.map(d => d.id);
                
                if (driverIds.includes(fastLapDriver)) {
                    console.log(`Team ${team.name} (${teamDoc.id}) MET THE FASTEST LAP OBJECTIVE!`);
                    const bonus = s.objectiveBonus || 150000;
                    console.log(`Granting bonus of $${bonus}...`);
                    
                    await teamDoc.ref.update({
                        budget: admin.firestore.FieldValue.increment(bonus)
                    });
                    
                    // Add a news entry
                    await teamDoc.ref.collection("news").add({
                        title: "Sponsor Bonus Received!",
                        message: `Congratulations! Your team achieved the Fastest Lap in Round 1. ${s.sponsorName} has paid the objective bonus of $${bonus.toLocaleString()}.`,
                        type: "FINANCIAL",
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        isRead: false
                    });
                }
            }
        }
    }
    
    fs.unlinkSync(adcPath);
    console.log("Done.");
}

fixR1();
