/**
 * Converts ISO 3166-1 alpha-2 country code to a regional indicator emoji.
 * e.g., "US" -> "🇺🇸", "AR" -> "🇦🇷"
 */
export function getFlagEmoji(countryCode: string | null | undefined): string {
    if (!countryCode) return "🏁";
    
    // Some codes might be special or lowercase
    const normalizedCode = countryCode.toUpperCase();
    
    // REGIONAL INDICATOR SYMBOL LETTER A is 127462 (0x1F1E6)
    // LATIN CAPITAL LETTER A is 65
    // Offset is 127397
    const codePoints = normalizedCode
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
