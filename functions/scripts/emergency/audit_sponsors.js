const admin = require('firebase-admin');
const fs = require('fs');

if (!admin.apps.length) {
    admin.initializeApp({
        projectId: 'ftg-racing-manager'
    });
}

const db = admin.firestore();

async function auditSponsors() {
    console.log("Starting Sponsor Audit...");
    const teamsSnap = await db.collection('teams').get();
    let totalTeams = 0;
    let teamsWithDuplicates = [];
    let contractsMissingCountry = 0;

    const sponsorData = {};

    teamsSnap.docs.forEach(doc => {
        totalTeams++;
        const team = doc.data();
        const sponsors = team.sponsors || {};
        const activeIds = new Set();
        const duplicates = [];

        Object.entries(sponsors).forEach(([slot, contract]) => {
            if (!contract.sponsorId) return;

            // Track missing country codes
            if (!contract.countryCode) {
                contractsMissingCountry++;
            }

            // Track duplicates
            if (activeIds.has(contract.sponsorId)) {
                duplicates.push({ slot, id: contract.sponsorId, name: contract.sponsorName });
            }
            activeIds.add(contract.sponsorId);
        });

        if (duplicates.length > 0) {
            teamsWithDuplicates.push({
                teamId: doc.id,
                teamName: team.name,
                duplicates: duplicates
            });
        }
    });

    const report = {
        timestamp: new Date().toISOString(),
        stats: {
            totalTeams,
            teamsWithDuplicates: teamsWithDuplicates.length,
            contractsMissingCountry
        },
        duplicates: teamsWithDuplicates
    };

    fs.writeFileSync('sponsor_audit_report.json', JSON.stringify(report, null, 2));
    console.log("Audit complete. Report saved to sponsor_audit_report.json");
    console.log(`Summary: ${teamsWithDuplicates.length} teams have duplicates. ${contractsMissingCountry} contracts missing countryCode.`);
}

auditSponsors().catch(console.error);
