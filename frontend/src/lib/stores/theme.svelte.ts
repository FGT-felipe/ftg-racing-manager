import { browser } from '$app/environment';

export type Theme = 'dark' | 'light';

export function createThemeStore() {
    let currentTheme = $state<Theme>('dark');

    // Initialization logic
    if (browser) {
        const storedTheme = localStorage.getItem('theme') as Theme | null;
        if (storedTheme) {
            currentTheme = storedTheme;
        } else {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            currentTheme = prefersDark ? 'dark' : 'light';
        }
    }

    return {
        get value() {
            return currentTheme;
        },
        toggleTheme() {
            currentTheme = currentTheme === 'dark' ? 'light' : 'dark';
            if (browser) {
                localStorage.setItem('theme', currentTheme);
            }
        }
    };
}

// Global instance
export const themeStore = createThemeStore();
