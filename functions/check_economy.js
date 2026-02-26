const admin = require("firebase-admin");

try {
  // If we have a local service account config, use it. Otherwise use default.
  // We can just try default first
  admin.initializeApp();
} catch (e) {
  console.log("Error initializing firebase admin:", e);
}

/**
 * Analyzes the current game economy and outputs team budgets
 */
async function checkEconomy() {
  const db = admin.firestore();

  const allTeams = await db.collection("teams").get();
  console.log(`\n--- ALL TEAMS (${allTeams.size}) ---`);

  let totalBudget = 0;
  const playerBudgets = [];

  allTeams.forEach((doc) => {
    const t = doc.data();
    const isPlayer = t.isPlayer === true;
    const isAcademy = t.isAcademy === true;
    if (!isAcademy) {
      console.log(`[${isPlayer ? "PLAYER" : "AI"}] ${t.name.padEnd(25)} ` +
        `| Budget: $${(t.budget || 0).toLocaleString()}`);
      if (isPlayer) {
        playerBudgets.push({name: t.name, budget: t.budget || 0});
      }
      totalBudget += (t.budget || 0);
    }
  });

  const avgStr = Math.round(totalBudget / allTeams.size).toLocaleString();
  console.log(`\nAvg Budget (no academies): $${avgStr}`);

  if (playerBudgets.length > 0) {
    console.log(`\n--- PLAYER TEAMS ---`);
    playerBudgets.forEach((p) => {
      console.log(`${p.name.padEnd(25)} ` +
        `| Budget: $${p.budget.toLocaleString()}`);
    });
  }
}

checkEconomy().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
