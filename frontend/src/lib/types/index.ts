export interface League {
    id: string;
    name: string;
}

export interface RaceEvent {
    id: string;
    trackName: string;
    countryCode: string;
    flagEmoji: string;
    circuitId: string;
    date: Date;
    isCompleted: boolean;
    totalLaps: number;
    weatherPractice: string;
    weatherQualifying: string;
    weatherRace: string;
}

export interface Season {
    id: string;
    leagueId: string;
    number: number;
    year: number;
    calendar: RaceEvent[];
    startDate: Date;
}

export interface Division {
    id: string;
    leagueId: string;
    name: string;
    level: number;
}

export interface Transaction {
    id: string;
    description: string;
    amount: number;
    date: Date;
    type: 'SPONSOR' | 'SALARY' | 'UPGRADE' | 'REWARD' | 'PRACTICE' | 'OTHER';
}

export interface NewsItem {
    headline: string;
    body: string;
    imageUrl?: string | null;
    date: Date;
    source: string;
}

export enum SponsorTier {
    title = 'title',
    major = 'major',
    partner = 'partner'
}

export enum SponsorSlot {
    rearWing = 'rearWing',
    frontWing = 'frontWing',
    sidepods = 'sidepods',
    nose = 'nose',
    halo = 'halo'
}

export enum SponsorPersonality {
    aggressive = 'aggressive',
    professional = 'professional',
    friendly = 'friendly'
}

export interface SponsorOffer {
    id: string;
    name: string;
    tier: SponsorTier;
    signingBonus: number;
    weeklyBasePayment: number;
    objectiveBonus: number;
    objectiveDescription: string;
    countryCode?: string;
    consecutiveFailuresAllowed: number;
    personality: SponsorPersonality;
    contractDuration: number;
    isAdminBonusApplied: boolean;
    attemptsMade: number;
    lockedUntil?: Date | null;
}

export interface ActiveContract {
    sponsorId: string;
    sponsorName: string;
    slot: SponsorSlot;
    currentFailures: number;
    weeklyBasePayment: number;
    objectiveBonus: number;
    objectiveDescription: string;
    countryCode?: string;
    racesRemaining: number;
}

export interface Team {
    id: string;
    leagueId?: string | null;
    name: string;
    managerId?: string | null;
    isBot: boolean;
    budget: number;
    prestige?: number;
    currentSeasonId?: string | null;
    points: number;
    races: number;
    wins: number;
    podiums: number;
    poles: number;

    seasonPoints: number;
    seasonRaces: number;
    seasonWins: number;
    seasonPodiums: number;
    seasonPoles: number;
    nameChangeCount: number;
    lastRaceDebrief?: string | null;
    lastRaceResult?: string | null;

    carStats: Record<string, Record<string, number>>; // Usually '0' and '1' mapped to aero, powertrain, chassis, reliability
    weekStatus: Record<string, any>;
    sponsors: Record<string, ActiveContract>;
    facilities: Record<string, Facility>;
    transferBudgetPercentage: number;
}

export enum FacilityType {
    teamOffice = 'teamOffice',
    garage = 'garage',
    youthAcademy = 'youthAcademy',
    pressRoom = 'pressRoom',
    scoutingOffice = 'scoutingOffice',
    racingSimulator = 'racingSimulator',
    gym = 'gym',
    rdOffice = 'rdOffice',
    carMuseum = 'carMuseum'
}

export interface Facility {
    type: FacilityType;
    level: number;
    isLocked: boolean;
    maintenanceCost: number;
    lastUpgradeSeasonId?: string | null;
}

export enum DriverTrait {
    firstLapHero = 'firstLapHero',
    famousFamily = 'famousFamily',
    rainMaster = 'rainMaster',
    aggressive = 'aggressive',
    tyreSaver = 'tyreSaver',
    veteran = 'veteran',
    youngProdigy = 'youngProdigy'
}

export interface ChampionshipForm {
    event: string;
    pos: string;
    pts: number;
    date: string;
}

export interface CareerHistoryItem {
    year: number;
    teamName: string;
    series: string;
    races: number;
    wins: number;
    podiums: number;
    isChampion: boolean;
}


export interface Driver {
    id: string;
    teamId?: string | null;
    carIndex: number; // 0 for Car A, 1 for Car B
    name: string;
    age: number;
    potential: number;
    points: number;
    gender: string;
    championships: number;
    races: number;
    wins: number;
    podiums: number;
    poles: number;

    seasonPoints: number;
    seasonRaces: number;
    seasonWins: number;
    seasonPodiums: number;
    seasonPoles: number;

    stats: Record<string, number>;
    statPotentials: Record<string, number>;
    traits: DriverTrait[];
    championshipForm: ChampionshipForm[];
    careerHistory?: CareerHistoryItem[];
    contract?: { endDate?: string; [key: string]: any; };
    countryCode: string;

    role: string;
    salary: number;
    contractYearsRemaining: number;
    weeklyGrowth: Record<string, number>;
    portraitUrl?: string | null;
    specialty?: string | null;
    statusTitle: string;

    isTransferListed: boolean;
    transferListedAt?: Date | null;
    currentHighestBid: number;
    highestBidderTeamId?: string | null;
    highestBidderTeamName?: string | null;
    negotiationAttempts: number;
    marketValue: number;

    // Post-bid negotiation (set by resolver when auction closes with a bid)
    pendingNegotiation?: boolean;
    pendingBuyerTeamId?: string | null;
    pendingBidAmount?: number;
    pendingOriginalTeamId?: string | null;
}

export interface YoungDriver {
    id: string;
    name: string;
    age: number;
    gender: 'M' | 'F';
    nationality: {
        code: string;
        name: string;
        flagEmoji: string;
    };
    countryCode: string;
    baseSkill: number;
    maxSkill: number;
    growthPotential: number;
    potentialStars: number;
    salary: number;
    portraitUrl?: string | null;
    status: 'candidate' | 'selected';
    selectedAt?: Date | null;
    expiresAt?: Date | null;
    isMarkedForPromotion: boolean;
    statRangeMin: Record<string, number>;
    statRangeMax: Record<string, number>;
    pendingAction?: boolean;
    pendingActionType?: string | null;
    weeklyEventMessage?: string | null;
    weeklyStatDiffs?: Record<string, number>;
    trainingProgress?: Record<string, number>;
    specialty?: string | null;
}

export interface AppNotification {
    id: string;
    title: string;
    message: string;
    type: string;
    eventType?: string | null;
    timestamp: Date;
    isRead: boolean;
    actionRoute?: string | null;
}

export interface LeagueNotification {
    id: string;
    title: string;
    message: string;
    type: string;
    timestamp: Date;
    leagueId: string;
    eventType?: string | null;
    pilotName?: string | null;
    managerName?: string | null;
    teamName?: string | null;
    payload?: Record<string, any> | null;
    isArchived: boolean;
}

export enum TyreCompound {
    soft = 'soft',
    medium = 'medium',
    hard = 'hard',
    wet = 'wet'
}

export enum DriverStyle {
    defensive = 'defensive',
    normal = 'normal',
    offensive = 'offensive',
    mostRisky = 'mostRisky'
}

export interface CarSetup {
    frontWing: number;
    rearWing: number;
    suspension: number;
    gearRatio: number;
    tyreCompound: TyreCompound;
    pitStops: TyreCompound[];
    initialFuel: number;
    pitStopFuel: number[];
    qualifyingStyle: DriverStyle;
    raceStyle: DriverStyle;
    pitStopStyles: DriverStyle[];
}
