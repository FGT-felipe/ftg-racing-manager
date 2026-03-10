export interface DriverTitle {
    id: string;
    descriptionEn: string;
    descriptionEs: string;
    labelEn: string;
    labelEs: {
        mask: string;
        fem: string;
    };
}

export const DRIVER_TITLES: Record<string, DriverTitle> = {
    "Living Legend": {
        id: "Living Legend",
        descriptionEn: "Multiple champion with nothing left to prove; their presence defines the era.",
        descriptionEs: "Múltiple campeón con nada que demostrar; su presencia define la era.",
        labelEn: "Living Legend",
        labelEs: { mask: "Leyenda Viva", fem: "Leyenda Viva" }
    },
    "Era Dominator": {
        id: "Era Dominator",
        descriptionEn: "A driver in their prime who makes the rest of the field look a class below.",
        descriptionEs: "Piloto en su plenitud que hace que el resto parezca de una categoría inferior.",
        labelEn: "Era Dominator",
        labelEs: { mask: "Dominador de Época", fem: "Dominadora de Época" }
    },
    "The Heir": {
        id: "The Heir",
        descriptionEn: "The driver everyone knows will be champion as soon as they have the right car.",
        descriptionEs: "El piloto que todos saben que será campeón en cuanto tenga el coche adecuado.",
        labelEn: "The Heir",
        labelEs: { mask: "El Heredero", fem: "La Heredera" }
    },
    "Elite Veteran": {
        id: "Elite Veteran",
        descriptionEn: "Many years at the top, consistent, but has passed their peak pure speed.",
        descriptionEs: "Muchos años en la cima, consistente, pero ha pasado su pico de velocidad pura.",
        labelEn: "Elite Veteran",
        labelEs: { mask: "Veterano de Élite", fem: "Veterana de Élite" }
    },
    "Last Dance": {
        id: "Last Dance",
        descriptionEn: "A driver clearly in their farewell season, whether official or not.",
        descriptionEs: "Piloto claramente en su temporada de despedida, sea oficial o no.",
        labelEn: "Last Dance",
        labelEs: { mask: "Último Baile", fem: "Último Baile" }
    },
    "Solid Specialist": {
        id: "Solid Specialist",
        descriptionEn: "A grid staple for many years, guaranteed points, but likely never to be champion.",
        descriptionEs: "Un fijo de la parrilla por años, puntos garantizados, pero difícilmente será campeón.",
        labelEn: "Solid Specialist",
        labelEs: { mask: "Especialista Consolidado", fem: "Especialista Consolidada" }
    },
    "Young Wonder": {
        id: "Young Wonder",
        descriptionEn: "A rookie or second-year driver breaking records for their age.",
        descriptionEs: "Novato o piloto de segundo año rompiendo récords para su edad.",
        labelEn: "Young Wonder",
        labelEs: { mask: "Joven Maravilla", fem: "Joven Maravilla" }
    },
    "Rising Star": {
        id: "Rising Star",
        descriptionEn: "No longer a rookie, winning races and climbing the ranks quickly.",
        descriptionEs: "Ya no es novato, gana carreras y sube de rango rápidamente.",
        labelEn: "Rising Star",
        labelEs: { mask: "Estrella en Ascenso", fem: "Estrella en Ascenso" }
    },
    "Stuck Promise": {
        id: "Stuck Promise",
        descriptionEn: "Someone who entered with high expectations but whose results have flattened.",
        descriptionEs: "Alguien que entró con altas expectativas pero cuyos resultados se han estancado.",
        labelEn: "Stuck Promise",
        labelEs: { mask: "Promesa Estancada", fem: "Promesa Estancada" }
    },
    "Journeyman": {
        id: "Journeyman",
        descriptionEn: "Does the job, avoids errors, but rarely makes the headlines.",
        descriptionEs: "Cumple con su trabajo, evita errores, pero rara vez es titular.",
        labelEn: "Journeyman",
        labelEs: { mask: "Cumplidor de Oficio", fem: "Cumplidora de Oficio" }
    },
    "Unsung Driver": {
        id: "Unsung Driver",
        descriptionEn: "A driver who spends years in the category without leaving a significant mark.",
        descriptionEs: "Piloto que pasa años en la categoría sin dejar una marca significativa.",
        labelEn: "Unsung Driver",
        labelEs: { mask: "Sin Pena ni Gloria", fem: "Sin Pena ni Gloria" }
    },
    "Midfield Spark": {
        id: "Midfield Spark",
        descriptionEn: "Consistently pulls results above what the car allows, waiting for a big break.",
        descriptionEs: "Logra resultados por encima de lo que permite el coche, esperando su gran oportunidad.",
        labelEn: "Midfield Spark",
        labelEs: { mask: "Revulsivo de Media Tabla", fem: "Revulsiva de Media Tabla" }
    },
    "Past Glory": {
        id: "Past Glory",
        descriptionEn: "A former winner now struggling to even make it into the points.",
        descriptionEs: "Antiguo ganador que ahora lucha por entrar en los puntos.",
        labelEn: "Past Glory",
        labelEs: { mask: "Gloria Pasada", fem: "Gloria Pasada" }
    },
    "Grid Filler": {
        id: "Grid Filler",
        descriptionEn: "Present due to external circumstances rather than differential talent.",
        descriptionEs: "Presente por circunstancias externas más que por talento diferencial.",
        labelEn: "Grid Filler",
        labelEs: { mask: "Relleno de Parrilla", fem: "Relleno de Parrilla" }
    }
};

import { getLanguage } from "../utils/i18n";

export function getTitleInfo(titleId: string, gender: string = 'M') {
    const title = DRIVER_TITLES[titleId];
    if (!title) return null;

    const lang = getLanguage();

    if (lang === 'es') {
        return {
            label: gender === 'F' || gender === 'female' ? title.labelEs.fem : title.labelEs.mask,
            description: title.descriptionEs
        };
    }

    return {
        label: title.labelEn,
        description: title.descriptionEn
    };
}
