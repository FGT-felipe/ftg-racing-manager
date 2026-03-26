/**
 * Name pools for generating randomized pilots.
 * First names are split by gender; last names are grouped by cultural region.
 */

const M_FIRST_NAMES = [
    "Lucas", "Mateo", "Max", "Sebastian", "Lewis", "Carlos", "Fernando", "Lando",
    "Pierre", "Charles", "Esteban", "Valtteri", "George", "Nico", "Daniel", "Oscar",
    "Logan", "Felipe", "Juan", "Diego", "Enzo", "Antonio", "Guillaume", "Hans",
    "Oliver", "Jack", "Noah", "Leo", "Theo", "Arthur", "Mick", "Frederic"
];

const F_FIRST_NAMES = [
    "Elena", "Sophia", "Maya", "Isabella", "Camila", "Valentina", "Martina", "Lucia",
    "Sofia", "Ana", "Emma", "Olivia", "Mia", "Maria", "Laura", "Paula"
];

// Last name pools by cultural region
const LAST_NAMES_LATAM = [
    "Rodríguez", "García", "Martínez", "López", "González", "Gómez", "Herrera",
    "Pérez", "Torres", "Vargas", "Morales", "Castillo", "Silva", "Ferreira",
    "Santos", "Oliveira", "Souza", "Lima", "Alves", "Rojas"
];

const LAST_NAMES_SOUTH_EUROPE = [
    "Rossi", "Ferrari", "Russo", "Romano", "Esposito", "Bianchi", "Costa",
    "García", "Alonso", "Sainz", "Fernández", "Jiménez", "Molina", "Moreno"
];

const LAST_NAMES_BRITISH = [
    "Smith", "Jones", "Williams", "Brown", "Taylor", "Davies", "Evans",
    "Wilson", "Thomas", "Roberts", "Walker", "Wright", "Harris", "Clarke"
];

const LAST_NAMES_GERMAN = [
    "Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner",
    "Becker", "Hoffmann", "Richter", "Koch", "Bauer", "Schäfer", "Wolf"
];

// Countries that map to each region
const LATAM_CODES = new Set(["CO", "BR", "AR", "MX", "PE", "CL", "VE", "EC"]);
const SOUTH_EUROPE_CODES = new Set(["ES", "IT", "PT"]);
const GERMAN_CODES = new Set(["DE", "AT", "CH"]);

function getLastNamePool(countryCode?: string): string[] {
    if (!countryCode) return LAST_NAMES_BRITISH;
    if (LATAM_CODES.has(countryCode)) return LAST_NAMES_LATAM;
    if (SOUTH_EUROPE_CODES.has(countryCode)) return LAST_NAMES_SOUTH_EUROPE;
    if (GERMAN_CODES.has(countryCode)) return LAST_NAMES_GERMAN;
    return LAST_NAMES_BRITISH;
}

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

/**
 * Returns a random full name matching the given gender and cultural region.
 * @param gender 'M' for male, 'F' for female
 * @param countryCode ISO country code used to select culturally appropriate last name
 */
export function getRandomName(gender: 'M' | 'F', countryCode?: string): string {
    const firstPool = gender === 'M' ? M_FIRST_NAMES : F_FIRST_NAMES;
    const lastPool = getLastNamePool(countryCode);
    const first = firstPool[Math.floor(Math.random() * firstPool.length)];
    const last = lastPool[Math.floor(Math.random() * lastPool.length)];
    return `${first} ${last}`;
}

export function getRandomNationality(preferredCountry?: string) {
    if (preferredCountry) {
        const found = NATIONALITIES.find(n => n.code === preferredCountry || n.name === preferredCountry);
        if (found) return found;
    }
    return NATIONALITIES[Math.floor(Math.random() * NATIONALITIES.length)];
}
