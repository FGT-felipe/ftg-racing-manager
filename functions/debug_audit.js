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

const adcPath = path.join(__dirname, "_adc_temp_audit_2.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function audit() {
    const tid = "team_cl_1771709065020_1"; // GBA Racing
    const raceId = "qRM0nhyt95JGXqgxLtnT_r1"; // R1

    console.log("Checking GBA Racing R1 results...");
    const drivers = await db.collection("drivers").where("teamId", "==", tid).get();
    const dIds = drivers.docs.map(d => d.id);
    console.log("Drivers:", dIds);

    const race = await db.collection("races").doc(raceId).get();
    const rd = race.data();
    dIds.forEach(id => {
        const pos = rd.finalPositions ? rd.finalPositions[id] : "N/A";
        const isDnf = (rd.dnfs || []).includes(id);
        console.log(`Driver ${id}: Pos ${pos} | DNF: ${isDnf}`);
    });

    const team = await db.collection("teams").doc(tid).get();
    const sponsors = team.data().sponsors || {};
    console.log("Sponsors Objectives:");
    Object.entries(sponsors).forEach(([slot, s]) => {
        console.log(` - ${slot}: ${s.sponsorName} | Obj: ${s.objectiveDescription} | Bonus: ${s.objectiveBonus}`);
    });

    const txs = await db.collection("teams").doc(tid).collection("transactions")
        .where("type", "==", "SPONSOR")
        .get();
    console.log(`Team has ${txs.size} SPONSOR transactions.`);
    txs.forEach(tx => {
        const d = tx.data();
        if (d.description.includes("Objective")) {
            console.log(` FOUND: ${d.description} | Date: ${d.date}`);
        }
    });

    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
}

audit().catch(e => {
    console.error(e);
    if (fs.existsSync(adcPath)) fs.unlinkSync(adcPath);
});
