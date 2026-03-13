/**
 * Converts ISO 3166-1 alpha-2 country code to a reliable flag image URL.
 * Uses flagcdn.com for high-quality, stable results.
 */
export function getFlagUrl(countryCode: string | null | undefined): string | null {
    if (!countryCode) return null;
    
    let normalized = countryCode.toUpperCase().trim();

    const nameMap: Record<string, string> = {
        'USA': 'US', 'UNITED STATES': 'US',
        'UK': 'GB', 'UNITED KINGDOM': 'GB',
        'BRAZIL': 'BR', 'MEXICO': 'MX', 'ARGENTINA': 'AR',
        'CANADA': 'CA', 'COLOMBIA': 'CO', 'CHILE': 'CL',
        'GERMANY': 'DE', 'FRANCE': 'FR', 'ITALY': 'IT',
        'SPAIN': 'ES', 'JAPAN': 'JP', 'NETHERLANDS': 'NL',
        'AUSTRALIA': 'AU'
    };

    if (nameMap[normalized]) {
        normalized = nameMap[normalized];
    }

    if (normalized.length !== 2) return null;
    
    // flagcdn.com requires lowercase codes
    return `https://flagcdn.com/w80/${normalized.toLowerCase()}.png`;
}

/**
 * Converts ISO 3166-1 alpha-2 country code to a regional indicator emoji.
 * Note: Windows does not support colorful country flags and shows ISO letters instead.
 */
export function getFlagEmoji(countryCode: string | null | undefined): string {
    if (!countryCode) return "🏁";
    
    let normalized = countryCode.toUpperCase().trim();
    // ... nameMap logic ...
    const nameMap: Record<string, string> = {
        'USA': 'US', 'UNITED STATES': 'US',
        'UK': 'GB', 'UNITED KINGDOM': 'GB',
        'BRAZIL': 'BR', 'MEXICO': 'MX', 'ARGENTINA': 'AR',
        'CANADA': 'CA', 'COLOMBIA': 'CO', 'CHILE': 'CL',
        'GERMANY': 'DE', 'FRANCE': 'FR', 'ITALY': 'IT',
        'SPAIN': 'ES', 'JAPAN': 'JP', 'NETHERLANDS': 'NL',
        'AUSTRALIA': 'AU'
    };
    if (nameMap[normalized]) normalized = nameMap[normalized];

    if (normalized.length !== 2) return "🏁";
    
    const codePoints = normalized
        .split("")
        .map((char) => 127397 + char.charCodeAt(0));
    
    try {
        return String.fromCodePoint(...codePoints);
    } catch (e) {
        return "🏁";
    }
}

/**
 * Maps country codes to full names (optional, could be expanded)
 */
export function getCountryName(countryCode: string): string {
    const names: Record<string, string> = {
        'US': 'United States',
        'BR': 'Brazil',
        'MX': 'Mexico',
        'AR': 'Argentina',
        'CA': 'Canada',
        'VE': 'Venezuela',
        'CO': 'Colombia',
        'CL': 'Chile'
    };
    return names[countryCode.toUpperCase()] || countryCode;
}
