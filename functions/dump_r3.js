
const admin = require("firebase-admin");
admin.initializeApp({ projectId: "ftg-racing-manager" });
const db = admin.firestore();

async function main() {
  const r3 = await db.collection("races").doc("qRM0nhyt95JGXqgxLtnT_r3").get();
  if (!r3.exists) { console.log("R3 NOT FOUND"); return; }
  const data = r3.data();
  console.log("Status:", data.status);
  console.log("IsFinished:", data.isFinished);
  console.log("PostRaceProcessed:", data.postRaceProcessed);
  console.log("QualyGrid Length:", data.qualyGrid ? data.qualyGrid.length : 0);
  console.log("FinalPositions keys:", data.finalPositions ? Object.keys(data.finalPositions).length : 0);
  process.exit(0);
}
main().catch(console.error);

