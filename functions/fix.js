const admin = require("firebase-admin");
async function fixDB() {
  const db = admin.firestore();
  console.log("Fetching teams...");
  const snap = await db.collection("teams").get();
  let cnt = 0;
  for (const doc of snap.docs) {
    const ws = doc.data().weekStatus || {};
    if (ws.globalStatus !== "practice") {
      ws.globalStatus = "practice";
      await doc.ref.update({ weekStatus: ws });
      cnt++;
      console.log("Updated team:", doc.id);
    }
  }
  console.log("FIX_DB_COMPLETED. Teams updated:", cnt);
}
fixDB().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
