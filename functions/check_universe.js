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

const adcPath = path.join(__dirname, "_adc_temp_univ.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

async function checkUniverse() {
    console.log("🔍 Fetching universe document...");
    const doc = await db.collection("universe").doc("game_universe_v1").get();

    if (doc.exists) {
        const data = doc.data();
        console.log(`Universe CreatedAt: ${data.createdAt}`);
        if (data.leagues && data.leagues.length > 0) {
            const firstLeague = data.leagues[0];
            console.log(`League: ${firstLeague.name}`);
            if (firstLeague.drivers && firstLeague.drivers.length > 0) {
                const firstDriver = firstLeague.drivers[0];
                console.log(`Sample Driver in Universe: ${firstDriver.name}`);
                console.log(`Fields in Universe Driver: ${Object.keys(firstDriver).join(", ")}`);
                if (firstDriver.history) {
                    console.log("✅ FOUND 'history' field in Universe Driver!");
                    console.log(JSON.stringify(firstDriver.history, null, 2));
                }
            }
        }
    } else {
        console.log("❌ Universe document NOT FOUND");
    }

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

checkUniverse().catch(e => {
    console.error(e);
    process.exit(1);
});
