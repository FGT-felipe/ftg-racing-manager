const fs = require("fs");
const path = require("path");

// 1. Read Firebase CLI credentials
const configPath = path.join(
    process.env.USERPROFILE || process.env.HOME,
    ".config", "configstore", "firebase-tools.json"
);
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));

// 2. Write an ADC-compatible JSON file
const adcCredentials = {
    type: "authorized_user",
    client_id: "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com",
    client_secret: "j9iVZfS8kkCEFUPaAeJV0sAi",
    refresh_token: config.tokens.refresh_token,
};

const adcPath = path.join(__dirname, "_adc_temp.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

// 3. Set Application Default Credentials for Google Auth
process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");

if (!admin.apps.length) {
    admin.initializeApp();
}

console.log("✅ Admin SDK Authenticated via CLI Token");

const { logger } = require("firebase-functions/v2");
logger.error = function (msg, err) {
    console.log("⭐⭐⭐ CAUGHT LOGGER ERROR ⭐⭐⭐");
    console.log(msg);
    if (err && err.stack) console.log(err.stack);
    else console.log(err);
};

// IMPORTANT: Require index.js AFTER setting GOOGLE_APPLICATION_CREDENTIALS
const myFunctions = require("./index.js");
const test = require("firebase-functions-test")();
const wrapped = test.wrap(myFunctions.forceRace);

async function run() {
    try {
        console.log("🏎️ Executing forceRace simulation...");
        const result = await wrapped({
            auth: { uid: "admin_user" }, // Mocks request.auth
            data: {}
        });
        console.log("✅ Result:", result);
    } catch (err) {
        console.error("❌ Error executing:", err);
    }

    // Cleanup
    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

run();
