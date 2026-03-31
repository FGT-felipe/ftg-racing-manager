import { Cloud, CloudRain, Sun } from 'lucide-svelte';

/**
 * Returns the appropriate Lucide icon component for a weather condition string.
 * Matches against "rain"/"wet" → CloudRain, "cloud" → Cloud, else → Sun.
 * @param condition Raw weather string from Firestore (e.g. "DRY", "WET", "Cloudy")
 */
export function getWeatherIcon(condition: string) {
    const c = condition.toLowerCase();
    if (c.includes('rain') || c.includes('wet')) return CloudRain;
    if (c.includes('cloud')) return Cloud;
    return Sun;
}

/**
 * Returns the Tailwind text-color class for a weather condition string.
 * @param condition Raw weather string from Firestore
 */
export function getWeatherColor(condition: string): string {
    const c = condition.toLowerCase();
    if (c.includes('rain') || c.includes('wet')) return 'text-blue-400';
    if (c.includes('cloud')) return 'text-slate-400';
    return 'text-yellow-400';
}
