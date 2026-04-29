/**
 * Formats a USD amount with smart scale selection:
 * - < $1,000,000 → "$750k"
 * - ≥ $1,000,000 → "$1.5M" (1 decimal, trailing .0 stripped)
 */
export function formatMoney(amount: number): string {
    if (Math.abs(amount) < 1_000_000) {
        return `$${Math.round(amount / 1_000)}k`;
    }
    const m = (amount / 1_000_000).toFixed(1);
    return `$${m.endsWith('.0') ? m.slice(0, -2) : m}M`;
}
