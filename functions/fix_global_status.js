const admin = require("firebase-admin");

// Fetch service account key for ADC
const path = require("path");
const os = require("os");
const fs = require("fs");

try {
  const credentialsPath = path.join(os.homedir(), "AppData", "Roaming", "gcloud", "application_default_credentials.json");
  if (fs.existsSync(credentialsPath)) {
    process.env.GOOGLE_APPLICATION_CREDENTIALS = credentialsPath;
  }
} catch (e) {
  // Ignore
}

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: "ftg-racing-manager"
  });
} catch (e) {
  if (!/already exists/.test(e.message)) {
    console.error("Firebase init error:", e);
  }
}

const db = admin.firestore();

async function run() {
  console.log("Starting to fix globalStatus for all teams...");
  try {
    const snapshot = await db.collection("teams").get();
    let count = 0;
    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const ws = data.weekStatus || {};
      
      if (!ws.globalStatus || ws.globalStatus !== "practice") {
        ws.globalStatus = "practice";
        batch.update(doc.ref, { weekStatus: ws });
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
      console.log(`Successfully fixed globalStatus for ${count} teams.`);
    } else {
      console.log("No teams needed fixing.");
    }

  } catch (error) {
    console.error("Error fixing globalStatus:", error);
  }
  process.exit();
}

run();
