const fs = require('fs');
const path = require('path');

// --- Credential Setup (ADC Pattern) ---
try {
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

    const adcPath = path.join(__dirname, "_adc_migration_key.json");
    fs.writeFileSync(adcPath, JSON.stringify(adcCredentials, null, 2));
    process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
} catch (e) {
    console.warn("⚠️ Could not setup ADC automatically. Ensure GOOGLE_APPLICATION_CREDENTIALS is set manually if this fails.");
}
// --------------------------------------

const admin = require('firebase-admin');

// Map of Sponsor ID to their Metadata
const SPONSOR_METADATA = {
    // Title
    'liberty_petrol': { name: 'Liberty Petroleum', countryCode: 'US' },
    'samba_bio': { name: 'Samba Bio-Fuel', countryCode: 'BR' },
    'north_star': { name: 'North Star Precision', countryCode: 'CA' },
    'empire_state': { name: 'Empire State Capital', countryCode: 'US' },
    'titans_oil': { name: 'Titans Oil', countryCode: 'US' },
    'zen_sky': { name: 'Zenith Sky', countryCode: 'GB' },
    'global_tech': { name: 'Global Tech', countryCode: '' },
    
    // Major
    'sol_mexico': { name: 'Sol de México Logistics', countryCode: 'MX' },
    'aconcagua_energy': { name: 'Aconcagua Energy', countryCode: 'AR' },
    'sao_paulo_stream': { name: 'São Paulo Stream', countryCode: 'BR' },
    'spark_energy': { name: 'Spark Energy', countryCode: 'US' },
    'fast_logistics': { name: 'Fast Logistics', countryCode: 'DE' },
    'pampa_gear': { name: 'Pampa Gear', countryCode: 'AR' },
    'eco_pulse': { name: 'Eco Pulse', countryCode: '' },
    
    // Partner
    'maya_micro': { name: 'Maya Microchips', countryCode: 'MX' },
    'andes_techno': { name: 'Andes Techno', countryCode: 'CL' },
    'caribbean_surf': { name: 'Caribbean Surf', countryCode: 'VE' },
    'local_drinks': { name: 'Local Drinks', countryCode: 'AR' },
    'micro_chips': { name: 'Micro Chips', countryCode: 'US' },
    'nitro_gear': { name: 'Nitro Gear', countryCode: 'BR' },
};

if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'ftg-racing-manager'
    });
}

const db = admin.firestore();

async function migrateSponsors() {
    console.log("🚀 Starting Sponsor Migration...");
    const teamsSnap = await db.collection('teams').get();
    
    let teamsUpdated = 0;
    let contractsFixed = 0;
    let teamsWithDuplicates = [];

    for (const teamDoc of teamsSnap.docs) {
        const teamData = teamDoc.data();
        const sponsors = teamData.sponsors || {};
        let needsUpdate = false;
        
        const activeSponsorIds = new Set();
        const duplicates = [];

        const updatedSponsors = { ...sponsors };

        Object.entries(updatedSponsors).forEach(([slot, contract]) => {
            if (!contract.sponsorId) return;

            const meta = SPONSOR_METADATA[contract.sponsorId];
            
            // 1. Backfill Metadata if missing
            if (!contract.countryCode || !contract.localizedName) {
                if (meta) {
                    contract.countryCode = meta.countryCode;
                    contract.localizedName = meta.name; // For future-proofing
                    needsUpdate = true;
                    contractsFixed++;
                }
            }

            // 2. Identify Duplicates
            if (activeSponsorIds.has(contract.sponsorId)) {
                duplicates.push(`${contract.sponsorName} (${slot})`);
            }
            activeSponsorIds.add(contract.sponsorId);
        });

        if (duplicates.length > 0) {
            teamsWithDuplicates.push({
                name: teamData.name,
                duplicates: duplicates
            });
        }

        if (needsUpdate) {
            await teamDoc.ref.update({ sponsors: updatedSponsors });
            teamsUpdated++;
        }
    }

    console.log("\n✅ Migration Finished!");
    console.log(`- Teams updated: ${teamsUpdated}`);
    console.log(`- Contracts fixed: ${contractsFixed}`);
    
    if (teamsWithDuplicates.length > 0) {
        console.log("\n⚠️  DUPLICATE SPONSORS FOUND (The 'Exploit'):");
        teamsWithDuplicates.forEach(t => {
            console.log(`  • [${t.name}]: ${t.duplicates.join(', ')}`);
        });
        console.log("\nNew duplicates cannot be hired, but these will continue until they expire.");
    } else {
        console.log("\n✨ No duplicate sponsors found.");
    }
}

migrateSponsors().catch(console.error);
