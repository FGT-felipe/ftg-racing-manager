/**
 * Simple name pools for generating randomized pilots.
 * Focus on variety and regional representation.
 */

const FIRST_NAMES = [
    "Lucas", "Mateo", "Max", "Sebastian", "Lewis", "Carlos", "Fernando", "Lando",
    "Pierre", "Charles", "Esteban", "Valtteri", "George", "Nico", "Daniel", "Oscar",
    "Logan", "Felipe", "Juan", "Diego", "Enzo", "Antonio", "Guillaume", "Hans",
    "Oliver", "Jack", "Noah", "Leo", "Theo", "Arthur", "Mick", "Frederic",
    "Elena", "Sophia", "Maya", "Isabella", "Camila", "Valentina", "Martina", "Lucia"
];

const LAST_NAMES = [
    "Rossi", "Garcia", "Smith", "Muller", "Vettel", "Alonso", "Sainz", "Hamilton",
    "Verstappen", "Leclerc", "Russell", "Norris", "Gasly", "Ocon", "Bottas", "Perez",
    "Ricciardo", "Piastri", "Sargeant", "Drogba", "Silva", "Bianchi", "Montoya",
    "Prost", "Senna", "Schumacher", "Berger", "Hulkenberg", "Magnussen", "Stroll"
];

const NATIONALITIES = [
    { code: 'GB', name: 'United Kingdom', emoji: '🇬🇧' },
    { code: 'FR', name: 'France', emoji: '🇫🇷' },
    { code: 'DE', name: 'Germany', emoji: '🇩🇪' },
    { code: 'IT', name: 'Italy', emoji: '🇮🇹' },
    { code: 'ES', name: 'Spain', emoji: '🇪🇸' },
    { code: 'MX', name: 'Mexico', emoji: '🇲🇽' },
    { code: 'BR', name: 'Brazil', emoji: '🇧🇷' },
    { code: 'AR', name: 'Argentina', emoji: '🇦🇷' },
    { code: 'CO', name: 'Colombia', emoji: '🇨🇴' },
    { code: 'US', name: 'United States', emoji: '🇺🇸' },
    { code: 'CA', name: 'Canada', emoji: '🇨🇦' },
    { code: 'AU', name: 'Australia', emoji: '🇦🇺' },
    { code: 'JP', name: 'Japan', emoji: '🇯🇵' },
    { code: 'NL', name: 'Netherlands', emoji: '🇳🇱' },
    { code: 'FI', name: 'Finland', emoji: '🇫🇮' }
];

export function getRandomName(): string {
    const first = FIRST_NAMES[Math.floor(Math.random() * FIRST_NAMES.length)];
    const last = LAST_NAMES[Math.floor(Math.random() * LAST_NAMES.length)];
    return `${first} ${last}`;
}

export function getRandomNationality(preferredCountry?: string) {
    if (preferredCountry) {
        const found = NATIONALITIES.find(n => n.code === preferredCountry || n.name === preferredCountry);
        if (found) return found;
    }
    return NATIONALITIES[Math.floor(Math.random() * NATIONALITIES.length)];
}
