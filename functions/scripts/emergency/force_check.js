const fs = require("fs");
const path = require("path");
const configPath = path.join(process.env.USERPROFILE || process.env.HOME, ".config", "configstore", "firebase-tools.json");
const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
const adcPath = path.join(__dirname, "_adc_temp_check2.json");
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

async function check() {
    const sDoc = await db.collection("seasons").doc("qRM0nhyt95JGXqgxLtnT").get();
    const cal = sDoc.data().calendar;
    console.log("Season Calendar:");
    cal.forEach((r, i) => {
        const d = r.date;
        const dateStr = d && d.toDate ? d.toDate().toISOString() : d;
        console.log(`  R${i + 1}: ${r.trackName} | date: ${dateStr} | completed: ${r.isCompleted} | id: ${r.id}`);
    });

    // Check race docs
    const racesSnap = await db.collection("races").get();
    console.log("\nRace Documents:");
    racesSnap.forEach(d => {
        console.log(`  ${d.id} | finished: ${d.data().isFinished} | postRaceProcessed: ${d.data().postRaceProcessed}`);
    });
}
check().then(() => { try { fs.unlinkSync(adcPath); } catch (e) { } process.exit(0); });
