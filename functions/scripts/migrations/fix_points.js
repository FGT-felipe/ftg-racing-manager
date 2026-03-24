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

const adcPath = path.join(__dirname, "_adc_temp_points.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function check() {
    const sDoc = await db.collection("seasons").doc("qRM0nhyt95JGXqgxLtnT").get();
    console.log("Season FTG world races:");
    if (sDoc.exists) {
        const calendar = sDoc.data().calendar;
        calendar.forEach((r, i) => {
            console.log(`Race ${i + 1}: ${r.trackName} - isCompleted: ${r.isCompleted}`);
        });
    }

    const raceRef = await db.collection("races").doc("qRM0nhyt95JGXqgxLtnT_r1").get();
    if (raceRef.exists) {
        console.log(`\nWorld Championship Race 1: isFinished=${raceRef.data().isFinished}`);
    } else {
        console.log("\nWorld Championship Race 1 DOES NOT EXIST IN DATABASE!");
    }

    const tDoc = await db.collection("teams").doc("team_cl_1771709065020_1").get();
    if (tDoc.exists) {
        console.log("\nMy Team:");
        console.log("Points:", tDoc.data().points);
        console.log("Budget:", tDoc.data().budget);
        console.log("Races:", tDoc.data().races);
        console.log("Season Points:", tDoc.data().seasonPoints);
    }
}
check();
