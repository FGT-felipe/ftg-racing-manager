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

const adcPath = path.join(__dirname, "_adc_temp_diag.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

async function checkDrivers() {
    console.log("🔍 Fetching a few drivers to check data structure...");
    const snap = await db.collection("drivers").limit(3).get();

    snap.forEach(doc => {
        const data = doc.data();
        console.log(`\n--- Driver: ${doc.id} (${data.name}) ---`);
        console.log(`championshipForm: ${JSON.stringify(data.championshipForm || [], null, 2)}`);
        console.log(`history: ${JSON.stringify(data.history || "NOT FOUND", null, 2)}`);
        console.log(`careerHistory: ${JSON.stringify(data.careerHistory || "NOT FOUND", null, 2)}`);
        console.log(`totals: races=${data.races}, wins=${data.wins}, podiums=${data.podiums}`);
    });

    try { fs.unlinkSync(adcPath); } catch (e) { }

    process.exit(0);
}

checkDrivers().catch(e => {
    console.error(e);
    process.exit(1);
});
