/**
 * Academy candidate factory — pure module.
 * Extracted from generateAcademyCandidate() in functions/index.js (lines 697–789).
 *
 * PURE MODULE: No Firestore calls, no side effects.
 * All inputs are plain data. Fully unit-testable without Firebase.
 */

// ─── Return type ──────────────────────────────────────────────────────────────

export interface AcademyCandidate {
  id: string;
  name: string;
  nationality: { code: string; name: string; flagEmoji: string };
  age: number;
  gender: "M" | "F";
  baseSkill: number;
  growthPotential: number;
  portraitUrl: string;
  status: "candidate";
  expiresAt: Date;
  salary: number;
  contractYears: number;
  statRangeMin: Record<string, number>;
  statRangeMax: Record<string, number>;
}

// ─── Core function ────────────────────────────────────────────────────────────

const ALL_STATS = [
  "cornering", "braking", "consistency", "smoothness",
  "adaptability", "overtaking", "defending", "focus", "fitness",
] as const;

const M_NAMES = ["John", "David", "Liam", "Carlos", "Mateo", "Luis", "Oliver", "Lucas"];
const F_NAMES = ["Emma", "Olivia", "Sophia", "Isabella", "Mia", "Ana", "Sofia", "Maria"];

const L_NAMES_LATAM = [
  "Rodríguez", "García", "Martínez", "López", "González", "Gómez", "Herrera",
  "Pérez", "Torres", "Vargas", "Morales", "Castillo", "Silva", "Ferreira",
  "Santos", "Oliveira", "Souza", "Lima", "Alves", "Rojas",
];
const L_NAMES_SOUTH_EUROPE = [
  "Rossi", "Ferrari", "Russo", "Romano", "Esposito", "Bianchi", "Costa",
  "García", "Alonso", "Sainz", "Fernández", "Jiménez", "Molina", "Moreno",
];
const L_NAMES_BRITISH = [
  "Smith", "Jones", "Williams", "Brown", "Taylor", "Davies", "Evans",
  "Wilson", "Thomas", "Roberts", "Walker", "Wright", "Harris", "Clarke",
];
const L_NAMES_GERMAN = [
  "Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner",
  "Becker", "Hoffmann", "Richter", "Koch", "Bauer", "Schäfer", "Wolf",
];

const LATAM_CODES = new Set(["CO", "BR", "AR", "MX", "PE", "CL", "VE", "EC"]);
const SOUTH_EUROPE_CODES = new Set(["ES", "IT", "PT"]);
const GERMAN_CODES = new Set(["DE", "AT", "CH"]);

function getLastNamePool(countryCode: string): string[] {
  if (LATAM_CODES.has(countryCode)) return L_NAMES_LATAM;
  if (SOUTH_EUROPE_CODES.has(countryCode)) return L_NAMES_SOUTH_EUROPE;
  if (GERMAN_CODES.has(countryCode)) return L_NAMES_GERMAN;
  return L_NAMES_BRITISH;
}

/**
 * Generates a new academy driver candidate for scouting.
 * Pure function — uses Math.random() internally, no side effects.
 *
 * @param academyLevel Team's academy upgrade level (1–5). Higher levels produce stronger candidates.
 * @param countryCode Team's country code for candidate nationality.
 * @param gender "M" for male, "F" for female.
 * @returns A new AcademyCandidate object. Expires in 7 days.
 */
export function generateAcademyCandidate(
  academyLevel: number,
  countryCode: string,
  gender: "M" | "F",
): AcademyCandidate {
  const level = Math.min(Math.max(academyLevel, 1), 5);

  let minCurrentStars: number;
  let maxCurrentStars: number;
  let minMaxStars: number;
  let maxMaxStars: number;

  switch (level) {
    case 1:
      minCurrentStars = 1.0; maxCurrentStars = 3.0;
      minMaxStars = 2.0; maxMaxStars = 3.5;
      break;
    case 2:
      minCurrentStars = 1.0; maxCurrentStars = 3.5;
      minMaxStars = 2.5; maxMaxStars = 4.0;
      break;
    case 3:
      minCurrentStars = 1.5; maxCurrentStars = 3.5;
      minMaxStars = 3.0; maxMaxStars = 4.5;
      break;
    case 4:
      minCurrentStars = 2.0; maxCurrentStars = 4.0;
      minMaxStars = 3.5; maxMaxStars = 5.0;
      break;
    case 5:
    default:
      minCurrentStars = 2.0; maxCurrentStars = 4.0;
      minMaxStars = 4.0; maxMaxStars = 5.0;
      break;
  }

  const currentStars = minCurrentStars + Math.random() * (maxCurrentStars - minCurrentStars);
  const actualMinMax = Math.max(currentStars, minMaxStars);
  const maxStars = actualMinMax + Math.random() * (maxMaxStars - actualMinMax);

  const baseSkill = Math.min(Math.max(Math.round(currentStars * 4), 2), 16);
  const maxSkill = Math.min(Math.max(Math.round(maxStars * 4), baseSkill), 20);
  const growthPotential = maxSkill - baseSkill;

  const statRangeMin: Record<string, number> = {};
  const statRangeMax: Record<string, number> = {};

  for (const statKey of ALL_STATS) {
    if (statKey === "fitness") {
      const minVal = 80 + Math.floor(Math.random() * 20);
      statRangeMin[statKey] = minVal;
      statRangeMax[statKey] = 100;
    } else {
      const variance = Math.floor(Math.random() * 2);
      const minVal = Math.min(Math.max(Math.round(baseSkill - 1 + variance), 1), 20);
      const maxVal = Math.min(Math.max(Math.round(baseSkill + growthPotential + variance), minVal), 20);
      statRangeMin[statKey] = minVal;
      statRangeMax[statKey] = maxVal;
    }
  }

  const firstPool = gender === "M" ? M_NAMES : F_NAMES;
  const firstName = firstPool[Math.floor(Math.random() * firstPool.length)];
  const lastPool = getLastNamePool(countryCode);
  const lastName = lastPool[Math.floor(Math.random() * lastPool.length)];
  const fullName = `${firstName} ${lastName}`;

  const timestamp = Date.now();
  const randomSuffix = Math.floor(Math.random() * 999999);
  const id = `young_${countryCode}_${timestamp}_${randomSuffix}`;
  const age = 16 + Math.floor(Math.random() * 4);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  return {
    id,
    name: fullName,
    nationality: { code: countryCode, name: countryCode, flagEmoji: "🌎" },
    age,
    gender,
    baseSkill,
    growthPotential,
    portraitUrl: `https://api.dicebear.com/7.x/notionists/png?seed=${id}&gender=${gender === "M" ? "male" : "female"}`,
    status: "candidate",
    expiresAt,
    salary: 10_000,
    contractYears: 1,
    statRangeMin,
    statRangeMax,
  };
}
