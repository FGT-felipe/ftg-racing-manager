/**
 * RECOVERY SCRIPT: Restores qualyGrid and qualifyingResults for completed rounds
 * by reconstructing them from teams/{teamId}/news (QUALIFYING_RESULT type).
 *
 * ⚠️  This script WRITES to Firestore. It only touches race documents where
 *     isFinished === true AND qualyGrid is currently empty.
 *
 * What it restores per entry: driverName, teamId, teamName, position, isCrashed.
 * What it cannot restore: lapTime, gap, tyreCompound (not stored in news).
 * These fields will be set to 0 / "" — the UI shows "—" for missing times.
 *
 * Usage: node scripts/emergency/restore_qualy_from_news.js [--dry-run]
 *   --dry-run : prints what would be written without touching Firestore
 */
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'ftg-racing-manager' });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');

async function run() {
    console.log(`=== Qualifying Recovery Script${DRY_RUN ? ' [DRY RUN]' : ''} ===\n`);

    // ── Step 1: Collect all QUALIFYING_RESULT news from all teams ─────────────
    const teamsSnap = await db.collection('teams').get();
    console.log(`Loaded ${teamsSnap.size} teams.\n`);

    const roundGroups = {}; // hourKey → [{ driverName, teamId, teamName, position, isCrashed }]

    for (const tDoc of teamsSnap.docs) {
        const teamId = tDoc.id;
        const teamName = tDoc.data().name || teamId;

        const newsSnap = await db
            .collection('teams').doc(teamId)
            .collection('news')
            .where('type', '==', 'QUALIFYING_RESULT')
            .get();

        for (const nDoc of newsSnap.docs) {
            const n = nDoc.data();
            const ts = n.timestamp?.toDate ? n.timestamp.toDate() : new Date(n.timestamp);
            const hourKey = new Date(Math.round(ts.getTime() / 3600000) * 3600000).toISOString();

            if (!roundGroups[hourKey]) roundGroups[hourKey] = [];

            const lines = (n.message || '').split('\n').filter(Boolean);
            for (const line of lines) {
                const crashMatch = line.match(/^(.+): DNF \(Crash\)$/);
                const posMatch   = line.match(/^(.+): P(\d+)$/);
                if (crashMatch) {
                    roundGroups[hourKey].push({ driverName: crashMatch[1].trim(), teamId, teamName, position: 999, isCrashed: true });
                } else if (posMatch) {
                    roundGroups[hourKey].push({ driverName: posMatch[1].trim(), teamId, teamName, position: parseInt(posMatch[2]), isCrashed: false });
                }
            }
        }
    }

    const sortedSessions = Object.keys(roundGroups).sort();
    console.log(`Found ${sortedSessions.length} qualifying session(s) in news.\n`);

    // ── Step 2: Load completed race documents to find target rounds ───────────
    const racesSnap = await db.collection('races').get();
    const completedRaces = racesSnap.docs
        .filter(d => d.data().isFinished === true)
        .sort((a, b) => {
            // Sort by raceEventId suffix: _r1 < _r2 < _r3 etc.
            const numA = parseInt((a.id.match(/_r(\d+)$/) || [0,0])[1]);
            const numB = parseInt((b.id.match(/_r(\d+)$/) || [0,0])[1]);
            return numA - numB;
        });

    console.log(`Found ${completedRaces.length} completed race document(s):\n`);
    completedRaces.forEach(d => {
        const g = d.data().qualyGrid;
        console.log(`  ${d.id} — qualyGrid: ${g ? g.length : 'missing'} entries`);
    });
    console.log('');

    // Identify races that need restoration (qualyGrid is empty)
    const racesNeedingRestore = completedRaces.filter(d => {
        const g = d.data().qualyGrid;
        return !g || g.length === 0;
    });

    if (racesNeedingRestore.length === 0) {
        console.log('No completed races need restoration. Nothing to do.');
        process.exit(0);
    }

    console.log(`Races needing qualyGrid restoration: ${racesNeedingRestore.map(d => d.id).join(', ')}\n`);

    if (sortedSessions.length === 0) {
        console.log('ERROR: No qualifying news found. Cannot recover.');
        process.exit(1);
    }

    // ── Step 3: Load all drivers for ID lookup ────────────────────────────────
    console.log('Loading drivers for ID lookup...');
    const driversSnap = await db.collection('drivers').get();
    // Map: `${teamId}::${driverName}` → driverId
    const driverLookup = {};
    driversSnap.forEach(dDoc => {
        const d = dDoc.data();
        const key = `${d.teamId}::${d.name}`;
        driverLookup[key] = dDoc.id;
    });
    console.log(`Loaded ${driversSnap.size} drivers.\n`);

    // ── Step 4: Map sessions to races and write ───────────────────────────────
    // Sessions are sorted chronologically. Races needing restore are sorted by round number.
    // Pair them in order.
    const pairs = Math.min(racesNeedingRestore.length, sortedSessions.length);

    for (let i = 0; i < pairs; i++) {
        const raceDoc = racesNeedingRestore[i];
        const sessionKey = sortedSessions[i];
        const entries = roundGroups[sessionKey].sort((a, b) => a.position - b.position);

        console.log(`\n── Restoring ${raceDoc.id} from session ~${sessionKey} (${entries.length} drivers) ──`);

        const qualyGrid = entries.map(e => {
            const driverId = driverLookup[`${e.teamId}::${e.driverName}`] || null;
            if (!driverId) {
                console.warn(`  ⚠️  No driverId found for "${e.driverName}" (${e.teamName})`);
            }
            return {
                driverId:       driverId || '',
                driverName:     e.driverName,
                teamId:         e.teamId,
                teamName:       e.teamName,
                position:       e.position,
                isCrashed:      e.isCrashed,
                lapTime:        0,   // not available from news
                gap:            0,   // not available from news
                tyreCompound:   '',  // not available from news
                setupSubmitted: true,
                _restored:      true,
            };
        });

        qualyGrid.forEach(e => {
            const pos = e.isCrashed ? 'DNF' : `P${e.position}`;
            const idStatus = e.driverId ? `id:${e.driverId.substring(0,8)}` : 'NO_ID';
            console.log(`  ${pos.padEnd(5)} ${e.driverName.padEnd(25)} (${e.teamName}) [${idStatus}]`);
        });

        if (!DRY_RUN) {
            await raceDoc.ref.update({
                qualyGrid:          qualyGrid,
                qualifyingResults:  qualyGrid,
            });
            console.log(`  ✅ Written to Firestore.`);
        } else {
            console.log(`  [DRY RUN] Would write ${qualyGrid.length} entries to ${raceDoc.id}`);
        }
    }

    if (racesNeedingRestore.length > sortedSessions.length) {
        const unrecovered = racesNeedingRestore.slice(sortedSessions.length);
        console.log(`\n⚠️  Could not recover ${unrecovered.length} round(s) — no news data available:`);
        unrecovered.forEach(d => console.log(`  - ${d.id}`));
    }

    console.log('\n=== Recovery complete ===');
    process.exit(0);
}

run().catch(e => { console.error(e); process.exit(1); });
