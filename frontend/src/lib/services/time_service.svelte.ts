export enum RaceWeekStatus {
    PRACTICE = "practice",
    QUALIFYING = "qualifying",
    RACE_STRATEGY = "raceStrategy",
    RACE = "race",
    POST_RACE = "postRace"
}

class TimeService {
    // We use a simplified version of the logic from Flutter's TimeService
    // Assuming the user's local time is what we compare against for now, 
    // but we can adjust to Bogota (UTC-5) if needed.

    get currentStatus(): RaceWeekStatus {
        const now = new Date();
        const weekday = now.getDay(); // 0=Sun, 1=Mon ... 6=Sat
        const hour = now.getHours();

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

        // Sunday(0) - In JS getDay(), Sunday is 0
        if (weekday === 0) {
            if (hour < 14) return RaceWeekStatus.RACE_STRATEGY;
            if (hour >= 14 && hour < 16) return RaceWeekStatus.RACE;
            return RaceWeekStatus.POST_RACE;
        }

        return RaceWeekStatus.PRACTICE;
    }

    getRaceWeekStatus(now: Date, raceDate: Date | null): RaceWeekStatus {
        if (!raceDate) return RaceWeekStatus.PRACTICE;

        // Simplified logic: for the race week, we use the weekday/hour logic
        // If 'now' is not in the same week as 'raceDate', we might need more complex logic.
        // For the purpose of the dashboard, which shows the NEXT race, we assume we are in the correct week or before it.

        const weekday = now.getDay();
        const hour = now.getHours();

        if (weekday >= 1 && weekday <= 5) return RaceWeekStatus.PRACTICE;
        if (weekday === 6) {
            if (hour < 14) return RaceWeekStatus.PRACTICE;
            if (hour === 14) return RaceWeekStatus.QUALIFYING;
            return RaceWeekStatus.RACE_STRATEGY;
        }
        if (weekday === 0) {
            if (hour < 14) return RaceWeekStatus.RACE_STRATEGY;
            if (hour >= 14 && hour < 16) return RaceWeekStatus.RACE;
            return RaceWeekStatus.POST_RACE;
        }

        return RaceWeekStatus.PRACTICE;
    }

    getTimeUntil(targetStatus: RaceWeekStatus): Duration | null {
        const now = new Date();
        const weekday = now.getDay();

        let target = new Date(now);
        target.setMinutes(0);
        target.setSeconds(0);
        target.setMilliseconds(0);

        switch (targetStatus) {
            case RaceWeekStatus.QUALIFYING:
                // Saturday 14:00
                const daysUntilSat = (6 - weekday + 7) % 7;
                target.setDate(now.getDate() + daysUntilSat);
                target.setHours(14);
                break;
            case RaceWeekStatus.RACE:
                // Sunday 14:00
                const daysUntilSun = (0 - weekday + 7) % 7;
                target.setDate(now.getDate() + daysUntilSun);
                target.setHours(14);
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
}

export interface Duration {
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
}

export const timeService = new TimeService();
