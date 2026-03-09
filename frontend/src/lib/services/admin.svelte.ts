import { db } from '$lib/firebase/config';
import {
    collection,
    getDocs,
    writeBatch,
    doc,
    deleteDoc,
    query,
    collectionGroup,
    serverTimestamp,
    setDoc,
    getDoc,
    where,
    updateDoc
} from 'firebase/firestore';

export const adminService = {
    /**
     * DANGEROUS: Port of DatabaseSeeder.nukeAndReseed
     * Wipes historical data and resets the universe.
     */
    async nukeAndReseed() {
        console.warn('☢️ NUKE: Starting total wipeout...');

        try {
            // 1. Delete Universe
            await deleteDoc(doc(db, 'universe', 'game_universe_v1'));
            console.log('NUKE: Universe deleted.');

            // 2. Clear Collection Groups (Drivers, Press News)
            const collectionGroups = ['drivers', 'press_news'];
            for (const cg of collectionGroups) {
                const snap = await getDocs(query(collectionGroup(db, cg)));
                if (!snap.empty) {
                    const batch = writeBatch(db);
                    snap.docs.forEach(d => batch.delete(d.ref));
                    await batch.commit();
                    console.log(`NUKE: ${cg} group cleared.`);
                }
            }

            // 3. Clear Standalone Collections
            const collections = [
                'teams',
                'leagues',
                'seasons',
                'divisions',
                'races',
                'driver_titles',
                'managers'
            ];

            for (const col of collections) {
                const snap = await getDocs(collection(db, col));
                if (!snap.empty) {
                    const batch = writeBatch(db);
                    snap.docs.forEach(d => batch.delete(d.ref));
                    await batch.commit();
                    console.log(`NUKE: ${col} collection cleared.`);
                }
            }

            console.log('NUKE: Wipe completed.');
            return true;
        } catch (e) {
            console.error('FATAL ERROR DURING NUKE:', e);
            throw e;
        }
    },

    /**
     * Port of MaintenanceService.fixRaceCalendars
     * Synchronizes calendars with the absolute truth from ftg_world.
     */
    async fixRaceCalendars() {
        console.log('Starting Race Calendar Maintenance...');
        const worldSeasonId = '3sh7fStGc55XxwmQHaJu';
        const targetSeasons = {
            'ftg_2th': 'Py9vb4IrLJGZPDCCCUkG',
            'ftg_karting': 'qRM0nhyt95JGXqgxLtnT',
        };

        try {
            const worldDoc = await getDoc(doc(db, 'seasons', worldSeasonId));
            if (!worldDoc.exists()) throw new Error('Reference world season not found');

            const worldData = worldDoc.data();
            const referenceMap = new Map();
            worldData.calendar.forEach((race: any) => {
                referenceMap.set(race.circuitId, race);
            });

            for (const [leagueId, seasonId] of Object.entries(targetSeasons)) {
                const seasonDoc = await getDoc(doc(db, 'seasons', seasonId));
                if (!seasonDoc.exists()) continue;

                const seasonData = seasonDoc.data();
                const calendar = [...seasonData.calendar];
                let changed = false;

                for (let i = 0; i < calendar.length; i++) {
                    const race = calendar[i];
                    if (race.isCompleted) continue;

                    const ref = referenceMap.get(race.circuitId);
                    if (!ref) continue;

                    if (race.totalLaps !== ref.totalLaps ||
                        race.weatherQualifying !== ref.weatherQualifying ||
                        race.weatherRace !== ref.weatherRace) {

                        calendar[i] = {
                            ...race,
                            totalLaps: ref.totalLaps,
                            weatherQualifying: ref.weatherQualifying,
                            weatherRace: ref.weatherRace
                        };
                        changed = true;
                    }
                }

                if (changed) {
                    await updateDoc(doc(db, 'seasons', seasonId), { calendar });
                    console.log(`Updated calendar for ${leagueId}`);
                }
            }
            return true;
        } catch (e) {
            console.error('Error fixing calendars:', e);
            throw e;
        }
    },

    /**
     * Port of FinanceService.applyGreatRebalanceTax
     */
    async applyGreatRebalanceTax() {
        console.log('Applying great rebalance tax...');
        try {
            const teamsSnap = await getDocs(collection(db, 'teams'));
            let batch = writeBatch(db);
            let opCount = 0;

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                const currentBudget = teamData.budget || 0;
                let newBudget = currentBudget;

                if (currentBudget > 3000000) {
                    newBudget = 3000000 + Math.floor((currentBudget - 3000000) * 0.2);
                } else if (currentBudget < 1500000) {
                    newBudget = 1500000;
                }

                if (newBudget !== currentBudget) {
                    const txRef = doc(collection(db, 'teams', tDoc.id, 'transactions'));
                    batch.set(txRef, {
                        id: txRef.id,
                        description: 'Great Economic Rebalance 2026',
                        amount: newBudget - currentBudget,
                        date: new Date().toISOString(),
                        type: 'TAX'
                    });
                    opCount++;
                }

                const weekStatus = { ...(teamData.weekStatus || {}) };
                weekStatus.sponsorNegotiations = {};

                batch.update(tDoc.ref, {
                    budget: newBudget,
                    sponsors: {},
                    weekStatus
                });
                opCount++;

                const notifRef = doc(collection(db, 'teams', tDoc.id, 'notifications'));
                batch.set(notifRef, {
                    teamId: tDoc.id,
                    title: 'Economic Rebalance',
                    message: `The Racing Federation has applied an economic rebalance. Your budget is now $${(newBudget / 1000000).toFixed(1)}M. Previous sponsors have been terminated.`,
                    type: 'INFO',
                    actionRoute: '/hq',
                    isRead: false,
                    timestamp: serverTimestamp()
                });
                opCount++;

                if (opCount >= 450) {
                    await batch.commit();
                    batch = writeBatch(db);
                    opCount = 0;
                }
            }

            if (opCount > 0) await batch.commit();
            return true;
        } catch (e) {
            console.error('Error applying tax:', e);
            throw e;
        }
    }
};
