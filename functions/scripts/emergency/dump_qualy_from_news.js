/**
 * READ-ONLY diagnostic: reconstructs qualifying grids from teams/{teamId}/news.
 * Does NOT modify any data.
 *
 * Usage: node scripts/emergency/dump_qualy_from_news.js
 */
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'ftg-racing-manager' });
const db = admin.firestore();

async function run() {
    console.log('=== Qualifying Recovery Diagnostic (READ-ONLY) ===\n');

    // 1. Load all teams
    const teamsSnap = await db.collection('teams').get();
    console.log(`Found ${teamsSnap.size} teams.\n`);

    // qualyNewsMap: { timestamp_bucket → { driverId/driverName → { position, driverName, teamId, teamName } } }
    // We group by rounded timestamp (to the hour) to identify rounds
    const roundGroups = {}; // key = ISO date hour → entries[]

    for (const tDoc of teamsSnap.docs) {
        const teamId = tDoc.id;
        const teamData = tDoc.data();
        const teamName = teamData.name || teamId;

        const newsSnap = await db
            .collection('teams').doc(teamId)
            .collection('news')
            .where('type', '==', 'QUALIFYING_RESULT')
            .get();

        if (newsSnap.empty) {
            console.log(`  [${teamName}] — No QUALIFYING_RESULT news found.`);
            continue;
        }

        for (const nDoc of newsSnap.docs) {
            const n = nDoc.data();
            const ts = n.timestamp?.toDate ? n.timestamp.toDate() : new Date(n.timestamp);
            // Round to nearest hour to group qualifying runs
            const hourKey = new Date(Math.round(ts.getTime() / 3600000) * 3600000).toISOString();

            if (!roundGroups[hourKey]) roundGroups[hourKey] = [];

            // Parse message: each line is "{driverName}: P{pos}" or "{driverName}: DNF (Crash)"
            const lines = (n.message || '').split('\n').filter(Boolean);
            for (const line of lines) {
                const crashMatch = line.match(/^(.+): DNF \(Crash\)$/);
                const posMatch   = line.match(/^(.+): P(\d+)$/);
                if (crashMatch) {
                    roundGroups[hourKey].push({
                        driverName: crashMatch[1].trim(),
                        teamId,
                        teamName,
                        position: 999,
                        isCrashed: true,
                    });
                } else if (posMatch) {
                    roundGroups[hourKey].push({
                        driverName: posMatch[1].trim(),
                        teamId,
                        teamName,
                        position: parseInt(posMatch[2]),
                        isCrashed: false,
                    });
                }
            }
        }
    }

    // 2. Print reconstructed grids per round
    const sortedKeys = Object.keys(roundGroups).sort();
    if (sortedKeys.length === 0) {
        console.log('\nNO qualifying news found in any team. Data cannot be recovered from this source.');
        process.exit(1);
    }

    console.log(`\nFound ${sortedKeys.length} qualifying session(s) in news:\n`);
    sortedKeys.forEach((key, idx) => {
        const entries = roundGroups[key].sort((a, b) => a.position - b.position);
        console.log(`\n=== Qualifying Round ${idx + 1} (run at ~${key}) — ${entries.length} drivers ===`);
        entries.forEach(e => {
            const pos = e.isCrashed ? 'DNF' : `P${e.position}`;
            console.log(`  ${pos.padEnd(5)} ${e.driverName.padEnd(25)} (${e.teamName})`);
        });
    });

    console.log('\n=== END — No data was modified ===');
    process.exit(0);
}

run().catch(e => { console.error(e); process.exit(1); });
