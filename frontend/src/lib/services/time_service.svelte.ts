export enum RaceWeekStatus {
    PRACTICE = "practice",
    QUALIFYING = "qualifying",
    RACE_STRATEGY = "raceStrategy",
    RACE = "race",
    POST_RACE = "postRace"
}

export interface Duration {
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
}

class TimeService {
    /**
     * Gets the current time in Bogota (UTC-5)
     */
    get nowBogota(): Date {
        const now = new Date();
        // Bogota is UTC-5
        const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
        return new Date(utc + (3600000 * -5));
    }

    get currentStatus(): RaceWeekStatus {
        return this.getRaceWeekStatus(this.nowBogota);
    }

    /**
     * In Parc Fermé, setup is locked after Qualifying starts (Saturday 14:00)
     * until the race is over (Sunday 16:00).
     */
    get isSetupLocked(): boolean {
        const status = this.currentStatus;
        return (
            status === RaceWeekStatus.QUALIFYING ||
            status === RaceWeekStatus.RACE_STRATEGY ||
            status === RaceWeekStatus.RACE
        );
    }

    /**
     * Returns true when part repairs are locked for a given Bogota-timezone date.
     * Locked from Saturday 13:00 COT (1h before qualifying) through all non-practice
     * states (qualifying, raceStrategy, race, postRace) until Monday 00:00 COT.
     *
     * @param date - Bogota-timezone Date to evaluate
     */
    getIsRepairLocked(date: Date): boolean {
        const status = this.getRaceWeekStatus(date);
        if (status !== RaceWeekStatus.PRACTICE) return true;
        // 1-hour pre-lock: Saturday 13:00–13:59 is still PRACTICE status
        return date.getDay() === 6 && date.getHours() >= 13;
    }

    /**
     * Returns true when part repairs are locked.
     * Locked from Saturday 13:00 COT (1h before qualifying) through Sunday postRace
     * until Monday 00:00 COT. Prevents last-minute repairs before parc fermé.
     */
    get isRepairLocked(): boolean {
        return this.getIsRepairLocked(this.nowBogota);
    }

    getWeekDay(date: Date): number {
        return date.getDay(); // 0=Sun, 1=Mon ... 6=Sat
    }

    getRaceWeekStatus(date: Date): RaceWeekStatus {
        const weekday = date.getDay();
        const hour = date.getHours();

        // Monday(1) - Friday(5): Practice
        if (weekday >= 1 && weekday <= 5) {
            return RaceWeekStatus.PRACTICE;
        }

        // Saturday(6)
        if (weekday === 6) {
            if (hour < 14) return RaceWeekStatus.PRACTICE;
            if (hour === 14) return RaceWeekStatus.QUALIFYING;
            return RaceWeekStatus.RACE_STRATEGY;
        }

        // Sunday(0)
        if (weekday === 0) {
            if (hour < 14) return RaceWeekStatus.RACE_STRATEGY;
            if (hour >= 14 && hour < 16) return RaceWeekStatus.RACE;
            return RaceWeekStatus.POST_RACE;
        }

        // Default or Monday 00:00 case
        return RaceWeekStatus.PRACTICE;
    }

    getTimeUntil(targetStatus: RaceWeekStatus): Duration | null {
        const now = this.nowBogota;
        const weekday = now.getDay();

        let target = new Date(now);
        target.setMinutes(0);
        target.setSeconds(0);
        target.setMilliseconds(0);

        switch (targetStatus) {
            case RaceWeekStatus.QUALIFYING:
                // Saturday 14:00
                const daysUntilQualy = (6 - weekday + 7) % 7;
                target.setDate(now.getDate() + daysUntilQualy);
                target.setHours(14);
                // If it's Saturday and past 14:00, move to next week
                if (daysUntilQualy === 0 && now.getHours() >= 14) {
                    target.setDate(target.getDate() + 7);
                }
                break;
            case RaceWeekStatus.RACE:
                // Sunday 14:00
                const daysUntilRace = (0 - weekday + 7) % 7;
                target.setDate(now.getDate() + daysUntilRace);
                target.setHours(14);
                // If it's Sunday and past 14:00, move to next week
                if (daysUntilRace === 0 && now.getHours() >= 14) {
                    target.setDate(target.getDate() + 7);
                }
                break;
            case RaceWeekStatus.POST_RACE:
                // Sunday 16:00 — when weekly academy/economy processing runs
                const daysUntilPostRace = (0 - weekday + 7) % 7;
                target.setDate(now.getDate() + daysUntilPostRace);
                target.setHours(16);
                // If it's Sunday and past 16:00, move to next week
                if (daysUntilPostRace === 0 && now.getHours() >= 16) {
                    target.setDate(target.getDate() + 7);
                }
                break;
            default:
                return null;
        }

        const diff = target.getTime() - now.getTime();
        if (diff < 0) return null;

        return {
            days: Math.floor(diff / (1000 * 60 * 60 * 24)),
            hours: Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
            minutes: Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60)),
            seconds: Math.floor((diff % (1000 * 60)) / 1000)
        };
    }

    getTimeUntilNextEvent(): number {
        const now = this.nowBogota;
        const status = this.getRaceWeekStatus(now);

        let target = new Date(now);
        target.setMinutes(0);
        target.setSeconds(0);
        target.setMilliseconds(0);

        const weekday = now.getDay();
        const hour = now.getHours();

        if (status === RaceWeekStatus.PRACTICE) {
            // Next is Qualifying (Saturday 14:00)
            const daysUntil = (6 - weekday + 7) % 7;
            target.setDate(now.getDate() + daysUntil);
            target.setHours(14);
            if (daysUntil === 0 && hour >= 14) target.setDate(target.getDate() + 7);
        } else if (status === RaceWeekStatus.QUALIFYING) {
            // Next is Race Strategy (Saturday 15:00)
            target.setHours(15);
        } else if (status === RaceWeekStatus.RACE_STRATEGY) {
            // Next is Race (Sunday 14:00)
            const daysUntil = (0 - weekday + 7) % 7;
            target.setDate(now.getDate() + daysUntil);
            target.setHours(14);
        } else if (status === RaceWeekStatus.RACE) {
            // Next is Post Race (Sunday 16:00)
            target.setHours(16);
        } else {
            // Next is Practice (Monday 00:00)
            const daysUntil = (1 - weekday + 7) % 7;
            target.setDate(now.getDate() + (daysUntil === 0 ? 7 : daysUntil));
            target.setHours(0);
        }

        return Math.max(0, target.getTime() - now.getTime());
    }

    formatDuration(duration: Duration | null): string {
        if (!duration) return "00:00:00";
        const { days, hours, minutes } = duration;
        if (days > 0) {
            return `${days}d ${hours}h ${minutes}m`;
        }
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    }
}

export const timeService = new TimeService();
