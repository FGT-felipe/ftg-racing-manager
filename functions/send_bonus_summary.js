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

const adcPath = path.join(__dirname, "_adc_temp_notify.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function sendBonusNotifications() {
    console.log("Starting bonus summary notifications...");
    const teamsSnap = await db.collection("teams").get();
    
    for (const tDoc of teamsSnap.docs) {
        const tid = tDoc.id;
        const teamData = tDoc.data();
        
        // Find transactions related to R1 bonus correction
        const txSnap = await db.collection("teams").doc(tid).collection("transactions")
            .where("type", "==", "SPONSOR")
            .get();
        
        let totalR1Bonus = 0;
        let count = 0;
        txSnap.forEach(tx => {
            const d = tx.data();
            // Match the description used in fix_historical_bonuses.js
            if (d.description.includes("Sponsor Objective Met")) {
                totalR1Bonus += d.amount;
                count++;
            }
        });

        if (totalR1Bonus > 0) {
            console.log(`Sending summary to ${teamData.name}: $${totalR1Bonus} (${count} objectives)`);
            
            // 1. Dashboard Notification
            const notifRef = db.collection("teams").doc(tid).collection("notifications").doc();
            await notifRef.set({
                title: "GLOBAL ANNOUNCEMENT: Performance Bonuses Paid",
                message: `Attention Manager! We have completed the audit of the Round 1 sponsor objectives. Your team has successfully secured a total of $${totalR1Bonus.toLocaleString()} in performance bonuses. These funds have been deposited into your budget.`,
                type: "SUCCESS",
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false
            });

            // 2. Office News Facility
            const newsRef = db.collection("teams").doc(tid).collection("news").doc();
            await newsRef.set({
                title: "GLOBAL ANNOUNCEMENT: Performance Bonuses Paid",
                message: `Attention Manager! We have completed the audit of the Round 1 sponsor objectives. Your team has successfully secured a total of $${totalR1Bonus.toLocaleString()} in performance bonuses. These funds have been deposited into your budget.`,
                type: "SUCCESS",
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                teamId: tid
            });
        }
    }
    
    console.log("Notifications sent.");
    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
}

sendBonusNotifications().catch(e => {
    console.error(e);
    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
});
