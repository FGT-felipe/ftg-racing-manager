import { db } from '$lib/firebase/config';
import { collection, getDocs } from 'firebase/firestore';

export class AcademyService {
    async getSelectedTraineesCount(teamId: string): Promise<number> {
        try {
            const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
            const snapshot = await getDocs(selectedRef);
            return snapshot.size;
        } catch (error) {
            console.error('Error fetching academy trainees count:', error);
            return 0;
        }
    }
}

export const academyService = new AcademyService();
