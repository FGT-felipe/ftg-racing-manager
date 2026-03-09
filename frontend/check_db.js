import { db } from './src/lib/firebase/config.js';
import { collection, getDocs } from 'firebase/firestore';

async function checkCollections() {
    try {
        const teamsSnap = await getDocs(collection(db, 'teams'));
        console.log(`Teams found: ${teamsSnap.size}`);
        teamsSnap.docs.forEach(doc => {
            console.log(`- Team: ${doc.data().name} (${doc.id}), League: ${doc.data().leagueId}`);
        });

        const managersSnap = await getDocs(collection(db, 'managers'));
        console.log(`Managers found: ${managersSnap.size}`);
    } catch (error) {
        console.error('Error checking collections:', error);
    }
}

checkCollections();
