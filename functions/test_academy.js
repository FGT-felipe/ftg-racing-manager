const myFunctions = require("./index.js");
const admin = require("firebase-admin");

const test = require("firebase-functions-test")();

const wrapped = test.wrap(myFunctions.postRaceProcessing);

// Create some mock data
const db = admin.firestore();

/**
 * Run the mock test for the academy logic.
 */
async function run() {
  await db.collection("teams").doc("teamA").set({
    id: "teamA",
    budget: 1000000,
    weekStatus: {
      upgradeCooldownWeeksLeft: 0,
    },
  });

  await db.collection("teams").doc("teamA").collection("academy").doc("config").set({
    academyLevel: 1,
    countryCode: "GB",
  });

  await db.collection("races").doc("race1").set({
    isFinished: true,
    postRaceProcessingAt: admin.firestore.FieldValue.serverTimestamp(),
    finalPositions: {
      "driver1": 1,
    },
  });

  await db.collection("drivers").doc("driver1").set({
    teamId: "teamA",
    salary: 520000,
  });

  console.log("Mock data created. Running function...");

  try {
    await wrapped({});
    console.log("Function executed.");

    const academyRef = db.collection("teams").doc("teamA").collection("academy").doc("config");
    const candidatesSnap = await academyRef.collection("candidates").get();
    console.log(`Generated ${candidatesSnap.size} candidates.`);
    candidatesSnap.forEach((doc) => {
      const data = doc.data();
      console.log(data.name, data.gender, "Stars Base:", data.baseSkill, data.growthPotential);
    });
  } catch (e) {
    console.error(e);
  }
}

run();
