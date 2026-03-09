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

const adcPath = path.join(__dirname, "_adc_temp_postrace.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();

async function run() {
    const db = admin.firestore();
    console.log("🛠️ Ajustando postRaceProcessed y postRaceProcessingAt...");

    // Find ALL finished races
    const racesSnap = await db.collection("races")
        .where("isFinished", "==", true)
        .get();

    let updatedCount = 0;
    for (const doc of racesSnap.docs) {
        // If it's literally null or undefined or already false
        if (!doc.data().postRaceProcessed) {
            await doc.ref.update({
                postRaceProcessed: false,
                postRaceProcessingAt: admin.firestore.Timestamp.fromDate(new Date("2020-01-01"))
            });
            updatedCount++;
            console.log(`⏱️ Ajustado: ${doc.id}`);
        }
    }

    console.log(`✅ ${updatedCount} carreras ajustadas. Ejecutando wrapper post-race...`);

    const myFunctions = require("./index.js");
    const test = require("firebase-functions-test")();
    const wrapped = test.wrap(myFunctions.postRaceProcessing);

    try {
        await wrapped({});
        console.log("🎉 postRaceProcessing terminó exitosamente.");
    } catch (e) {
        console.error("❌ Error running postRaceProcessing:", e);
    }

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

run();
