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

const adcPath = path.join(__dirname, "_adc_temp_audit_6.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function audit() {
    let output = "";
    const log = (msg) => {
        console.log(msg);
        output += msg + "\n";
    };

    try {
        log("Starting audit...");
        const raceId = "qRM0nhyt95JGXqgxLtnT_r1"; // R1
        const race = await db.collection("races").doc(raceId).get();
        if (!race.exists) {
            log("Race not found");
        } else {
            const rd = race.data();
            log("Race ID: " + raceId);
            log("Keys: " + Object.keys(rd).join(", "));
            
            if (rd.results) {
                log("Results Keys: " + Object.keys(rd.results).join(", "));
            }
            
            // Sample driver
            const firstDriverId = Object.keys(rd.finalPositions || {})[0];
            if (firstDriverId) {
                 log(`Sample Driver (${firstDriverId}):`);
                 log(` - Final Pos: ${rd.finalPositions[firstDriverId]}`);
                 if (rd.startingPositions) log(` - Start Pos (root): ${rd.startingPositions[firstDriverId]}`);
                 if (rd.results && rd.results.startingPositions) log(` - Start Pos (results): ${rd.results.startingPositions[firstDriverId]}`);
                 if (rd.results && rd.results.initialGrid) log(` - Initial Grid (results): ${rd.results.initialGrid[firstDriverId]}`);
            }
            
            log("Fastest Lap Driver: " + (rd.fast_lap_driver || "NOT FOUND"));
            
            // Check Toro Rojo
            const trSnap = await db.collection("teams").where("name", "==", "Toro Rojo").get();
            if (!trSnap.empty) {
                const tr = trSnap.docs[0];
                log("\nToro Rojo Sponsors:\n" + JSON.stringify(tr.data().sponsors, null, 2));
            }
        }

    } catch (e) {
        log("AUDIT ERROR: " + e.message);
    } finally {
        fs.writeFileSync(path.join(__dirname, "audit_final_report.txt"), output);
        if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
        process.exit(0);
    }
}

audit();
