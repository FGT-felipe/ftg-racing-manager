/**
 * Session gating helpers for weekStatus.driverSetups.
 *
 * Since v1.7.4, processPostRace clears `weekStatus.driverSetups` between rounds,
 * so the old proxy-based `isDriverStatusStale` (which checked practice.sessionId
 * to gate ALL subsystems) is no longer needed and has been removed.
 *
 * Each subsystem now gates by its own session tag:
 *  - Qualifying: `qualifyingSessionId`
 *  - Race strategy: `raceSessionId`
 *  - Practice: `practice.sessionId`
 *
 * `buildCurrentSessionId` remains as the canonical way to build the session tag
 * for comparison and tagging on write.
 */
export function buildCurrentSessionId(
    seasonId: string | null | undefined,
    raceEventId: string | null | undefined,
): string | null {
    if (!seasonId || !raceEventId) return null;
    return `${seasonId}_${raceEventId}`;
}
