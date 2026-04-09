/**
 * Session gating for weekStatus.driverSetups reads.
 *
 * Background: `driverSetups[driverId]` holds practice, qualifying, and race
 * strategy state for the current race weekend. Post-race processing does NOT
 * clear these fields when a round completes, so the record from R(N) persists
 * unchanged into R(N+1) until the driver practices the new round.
 *
 * The `practice` sub-object is the only field that carries an explicit
 * `sessionId` (format: `${seasonId}_${raceEventId}`), written whenever practice
 * is saved. We use it as the source of truth for "does this record belong to
 * the current race weekend?"
 *
 * Rules:
 *  - No driverStatus at all → fresh team/driver, not stale.
 *  - practice.sessionId matches currentSessionId → valid, not stale.
 *  - practice.sessionId exists and differs → stale (previous round's record).
 *  - practice.sessionId missing → stale. All writes from v1.5+ tag it, so a
 *    missing tag means the record was written before the tagging was introduced
 *    and has to be treated as prior-round data.
 *
 * Components should treat `driverStatus` as `null` when `isStaleSession` is
 * true, so qualifyingAttempts, qualifyingRuns, qualifyingParcFerme, race, etc.
 * all fall back to their defaults (0 / [] / false / undefined).
 */
export function buildCurrentSessionId(
    seasonId: string | null | undefined,
    raceEventId: string | null | undefined,
): string | null {
    if (!seasonId || !raceEventId) return null;
    return `${seasonId}_${raceEventId}`;
}

export function isDriverStatusStale(
    driverStatus: any,
    currentSessionId: string | null,
): boolean {
    if (!driverStatus) return false; // nothing to hide
    if (!currentSessionId) return false; // can't compare yet
    const storedSessionId = driverStatus?.practice?.sessionId;
    if (!storedSessionId) return true; // missing tag → previous-round data
    return storedSessionId !== currentSessionId;
}
