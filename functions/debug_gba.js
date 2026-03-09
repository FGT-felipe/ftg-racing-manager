const admin = require("firebase-admin");
try { admin.initializeApp(); } catch (e) { }
const db = admin.firestore();

async function debug() {
    console.log("=== SEARCHING FOR GBA Racing ===");
    const teamSnap = await db.collection("teams").where("name", "==", "GBA Racing").get();
    if (teamSnap.empty) {
        console.log("NOT FOUND by name 'GBA Racing'");
        return;
    }

    const team = teamSnap.docs[0].data();
    const tid = teamSnap.docs[0].id;
    console.log(`FOUND: ID ${tid} | League: ${team.leagueId}`);

    if (team.leagueId) {
        const lDoc = await db.collection("leagues").doc(team.leagueId).get();
        if (lDoc.exists) {
            const league = lDoc.data();
            const sId = league.currentSeasonId;
            console.log(`LEAGUE: ${league.name} | CURRENT SEASON: ${sId}`);

            if (sId) {
                const sDoc = await db.collection("seasons").doc(sId).get();
                if (sDoc.exists) {
                    const season = sDoc.data();
                    console.log(`SEASON FOUND. Calendar size: ${season.calendar ? season.calendar.length : 0}`);
                    // Find last completed race
                    let lastCompletedIdx = -1;
                    if (season.calendar) {
                        for (let i = season.calendar.length - 1; i >= 0; i--) {
                            if (season.calendar[i].isCompleted) {
                                lastCompletedIdx = i;
                                break;
                            }
                        }
                    }

                    if (lastCompletedIdx !== -1) {
                        const rEvent = season.calendar[lastCompletedIdx];
                        const raceDocId = `${sId}_${rEvent.id}`;
                        console.log(`LAST COMPLETED RACE: ${rEvent.trackName} | ID: ${rEvent.id} | DOC: ${raceDocId}`);

                        const rSnap = await db.collection("races").doc(raceDocId).get();
                        if (rSnap.exists) {
                            console.log("RACE DOC FOUND!");
                            const rData = rSnap.data();
                            if (rData.results && rData.results.sorted) {
                                console.log(`RESULTS FOUND. Drivers: ${rData.results.sorted.length}`);
                            } else {
                                console.log("NO RESULTS in race doc.");
                            }
                        } else {
                            console.log("RACE DOC NOT FOUND in 'races' collection.");
                        }
                    } else {
                        console.log("NO COMPLETED RACES in season calendar.");
                    }
                }
            }
        }
    }
}

debug().catch(console.error);
