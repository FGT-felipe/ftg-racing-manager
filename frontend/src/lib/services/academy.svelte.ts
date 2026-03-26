import { db } from '$lib/firebase/config';
import { 
    collection, 
    query, 
    where, 
    getDocs, 
    doc, 
    writeBatch,
    type DocumentReference 
} from 'firebase/firestore';
import type { YoungDriver } from '$lib/types';
import { getRandomName, getRandomNationality } from '../utils/names';
import { ACADEMY_SALARY_BASE, ACADEMY_SALARY_RANGE } from '../constants/economics';

export class AcademyService {
    async getSelectedTraineesCount(teamId: string): Promise<number> {
        const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
        const snap = await getDocs(selectedRef);
        return snap.size;
    }

    /**
     * Generates a set of initial candidates for a new academy.
     */
    generateInitialCandidates(count: number = 2, preferredCountry?: string, academyLevel: number = 1): YoungDriver[] {
        const candidates: YoungDriver[] = [];

        for (let i = 0; i < count; i++) {
            const country = getRandomNationality(preferredCountry);
            const gender: 'M' | 'F' = Math.random() < 0.5 ? 'M' : 'F';
            
            // Stats balance for "Junior" feel:
            // Level 1: current stars ~1-2 (skill 4-8), potential ~3-4 (skill 10-14)
            const currentBase = 2 + (academyLevel * 2); 
            const potentialBase = 8 + (academyLevel * 2);

            const baseSkill = currentBase + Math.floor(Math.random() * 4); // L1: 4-8
            const maxSkill = potentialBase + Math.floor(Math.random() * 4); // L1: 10-14
            const potentialStars = Math.round(maxSkill / 4.0);
            
            // Expiry in 2 weeks
            const expiresAt = new Date();
            expiresAt.setDate(expiresAt.getDate() + 14);

            const candidate: YoungDriver = {
                id: crypto.randomUUID(),
                name: getRandomName(gender, country.code),
                age: 15 + Math.floor(Math.random() * 4), // 15-18
                gender: gender,
                nationality: {
                    code: country.code,
                    name: country.name,
                    flagEmoji: country.emoji
                },
                countryCode: country.code,
                baseSkill: baseSkill,
                maxSkill: maxSkill,
                growthPotential: maxSkill - baseSkill,
                potentialStars: potentialStars,
                salary: ACADEMY_SALARY_BASE + Math.floor(Math.random() * ACADEMY_SALARY_RANGE),
                status: 'candidate',
                expiresAt: expiresAt,
                isMarkedForPromotion: false,
                statRangeMin: {
                    braking: baseSkill, cornering: baseSkill, smoothness: baseSkill,
                    overtaking: baseSkill, consistency: baseSkill, adaptability: baseSkill,
                    focus: baseSkill
                },
                statRangeMax: {
                    braking: maxSkill, cornering: maxSkill, smoothness: maxSkill,
                    overtaking: maxSkill, consistency: maxSkill, adaptability: maxSkill,
                    focus: maxSkill
                }
            };
            candidates.push(candidate);
        }

        return candidates;
    }

    /**
     * Saves generated candidates to Firestore.
     * Note: This should ideally be called within a transaction or batch if done during purchase.
     */
    async saveCandidates(teamId: string, candidates: YoungDriver[]) {
        const batch = writeBatch(db);
        const candidatesCol = collection(db, 'teams', teamId, 'academy', 'config', 'candidates');

        candidates.forEach(c => {
            const ref = doc(candidatesCol, c.id);
            batch.set(ref, c);
        });

        await batch.commit();
    }
}

export const academyService = new AcademyService();
