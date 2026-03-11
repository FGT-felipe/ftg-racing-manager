import { 
    Trophy, 
    PieChart, 
    Gavel, 
    Wrench
} from "lucide-svelte";

export interface ManagerRole {
    id: string;
    title: string;
    desc: string;
    icon: any; 
    pros: string[];
    cons: string[];
}

export const MANAGER_ROLES: ManagerRole[] = [
    {
        id: "ex_driver",
        title: "Ex-Driver",
        desc: "A veteran of the track with deep technical understanding.",
        icon: Trophy,
        pros: [
            "+5 driver feedback for setup",
            "+2% driver race pace",
            "+10 driver morale during race",
            "Unlocks Risky Driver Style",
        ],
        cons: [
            "Drivers salary is 20% higher",
            "+5% higher risk of race crashes",
        ],
    },
    {
        id: "business",
        title: "Business Mogul",
        desc: "Focused on the bottom line and maximizing revenue.",
        icon: PieChart,
        pros: [
            "+15% better financial sponsorship deals",
            "-10% facility upgrade costs",
        ],
        cons: [
            "-2% driver race pace",
            "-10% driver morale if sponsor goals fail",
        ],
    },
    {
        id: "bureaucrat",
        title: "Bureaucrat",
        desc: "Expert in regulations and infrastructure optimization.",
        icon: Gavel,
        pros: [
            "-10% facility purchase and upgrade costs",
            "+1 extra youth academy driver per level",
        ],
        cons: ["Car part upgrade cooldown is 2 weeks (not 1)"],
    },
    {
        id: "engineer",
        title: "Lead Engineer",
        desc: "Technical wizard focused on car performance.",
        icon: Wrench,
        pros: [
            "Can upgrade 2 car parts simultaneously",
            "-10% tyre wear",
            "+5% Qualifying success probability",
        ],
        cons: ["-5% driver XP gain", "Car part upgrades cost double"],
    },
];

export function getRoleById(id: string): ManagerRole | undefined {
    return MANAGER_ROLES.find(r => r.id === id);
}
