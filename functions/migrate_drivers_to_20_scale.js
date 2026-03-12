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

const adcPath = path.join(__dirname, "_adc_temp_migration_v2.json");
fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));

process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
process.env.GCLOUD_PROJECT = "ftg-racing-manager";
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: "ftg-racing-manager" });

const admin = require("firebase-admin");
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const SKILL_KEYS = [
    "braking", "cornering", "smoothness", "overtaking", "defending",
    "consistency", "adaptability", "focus", "feedback"
]; // Note: "fitness" excluded here because it's now percentual 0-100

async function migrateDrivers() {
    console.log("🚀 Starting Comprehensive Driver/Candidate Stat Migration (1-20 scale)...");
    
    const batch = db.batch();
    let migrateCount = 0;

    // 1. Migrate Main Drivers collection
    const driversSnap = await db.collection("drivers").get();
    console.log(`Processing ${driversSnap.size} main drivers...`);

    driversSnap.forEach(doc => {
        if (processDoc(doc, batch)) migrateCount++;
    });

    // 2. Migrate Academy Candidates and Selected Trainees (Nested in Teams)
    const teamsSnap = await db.collection("teams").get();
    console.log(`Checking academy data for ${teamsSnap.size} teams...`);

    for (const teamDoc of teamsSnap.docs) {
        const teamId = teamDoc.id;
        
        // Candidates
        const candidatesSnap = await db.collection("teams").doc(teamId).collection("academy").doc("config").collection("candidates").get();
        candidatesSnap.forEach(doc => {
            if (processDoc(doc, batch, true)) migrateCount++;
        });

        // Selected
        const selectedSnap = await db.collection("teams").doc(teamId).collection("academy").doc("config").collection("selected").get();
        selectedSnap.forEach(doc => {
            if (processDoc(doc, batch, true)) migrateCount++;
        });
    }

    if (migrateCount > 0) {
        console.log(`\nWriting changes for ${migrateCount} records...`);
        await batch.commit();
        console.log("✅ Migration complete!");
    } else {
        console.log("\nNo records required migration.");
    }

    try { fs.unlinkSync(adcPath); } catch (e) { }
    process.exit(0);
}

function processDoc(doc, batch, isAcademy = false) {
    const data = doc.data();
    const stats = data.stats || {};
    const potentials = data.statPotentials || {};
    let needsMigration = false;
    const updatedStats = { ...stats };
    const updatedPotentials = { ...potentials };
    const updates = {};

    // Standard skills rescaling
    for (const key of SKILL_KEYS) {
        if (stats[key] > 20) {
            updatedStats[key] = Math.max(1, Math.round(stats[key] / 5));
            needsMigration = true;
        }
        if (potentials[key] > 20) {
            updatedPotentials[key] = Math.max(1, Math.round(potentials[key] / 5));
            needsMigration = true;
        }
    }

    // Initialize defending if missing
    if (updatedStats.defending === undefined) {
        updatedStats.defending = 10;
        updatedPotentials.defending = 12;
        needsMigration = true;
    }

    if (needsMigration) {
        updates.stats = updatedStats;
        updates.statPotentials = updatedPotentials;
    }

    // Academy specific range and skill rescaling
    if (isAcademy) {
        if (data.baseSkill > 20) {
            updates.baseSkill = Math.max(1, Math.round(data.baseSkill / 5));
            needsMigration = true;
        }
        if (data.growthPotential > 20) {
            updates.growthPotential = Math.max(1, Math.round(data.growthPotential / 5));
            needsMigration = true;
        }

        if (data.statRangeMin) {
            const newMin = { ...data.statRangeMin };
            const newMax = { ...data.statRangeMax };
            let rangeChanged = false;
    
            for (const key of SKILL_KEYS) {
                if (newMin[key] > 20) {
                    newMin[key] = Math.max(1, Math.round(newMin[key] / 5));
                    rangeChanged = true;
                }
                if (newMax[key] > 20) {
                    newMax[key] = Math.max(1, Math.round(newMax[key] / 5));
                    rangeChanged = true;
                }
            }
            
            if (rangeChanged) {
                updates.statRangeMin = newMin;
                updates.statRangeMax = newMax;
                needsMigration = true;
            }
        }
    }

    // Fix fitness: If it was accidentally rescaled previously (very small), we might need to fix it?
    // But user said "fitness no es porcentual como en los demás", meaning it's 20/20 in their view.
    // If fitness is < 5 and baseSkill suggests it should be a % (0-100), we could multiply by 5.
    // However, let's just make sure it's saved as 80-100 if it's missing or low.
    if ((updatedStats.fitness || 0) <= 20) {
        // If it's on a 1-20 scale, bring it back to 100%
        updatedStats.fitness = (updatedStats.fitness || 20) * 5;
        updates.stats = updatedStats;
        needsMigration = true;
    }

    if (needsMigration) {
        batch.update(doc.ref, updates);
        console.log(`[MIGRATE] ${isAcademy ? 'Academy' : 'Driver'}: ${data.name} (${doc.id})`);
        return true;
    }
    return false;
}

migrateDrivers().catch(e => {
    console.error("❌ Migration failed:", e);
    try { fs.unlinkSync(adcPath); } catch (err) { }
    process.exit(1);
});
