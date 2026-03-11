import { test, expect } from '@playwright/test';

test.describe('Racing Paddock - Card Logic', () => {
    test.beforeEach(async ({ page }) => {
        // Mock the authentication and team state to bypass redirects and DB pollution
        await page.addInitScript(() => {
            (window as any).__MOCK_AUTH__ = {
                user: { uid: 'test-user', email: 'test@example.com' },
                loading: false
            };
            (window as any).__MOCK_TEAM__ = {
                id: 'test-team',
                budget: 50000000,
                weekStatus: {
                    globalStatus: 'practice',
                    driverSetups: {}
                }
            };
            (window as any).__MOCK_DRIVERS__ = [
                {
                    id: 'driver-1',
                    name: 'Fernando Alonso',
                    role: 'Main',
                    gender: 'male',
                    carIndex: 0,
                    stats: { morale: 90, fitness: 85, overallRating: 92 }
                },
                {
                    id: 'driver-2',
                    name: 'Lance Stroll',
                    role: 'Secondary',
                    gender: 'male',
                    carIndex: 1,
                    stats: { morale: 60, fitness: 70, overallRating: 78 }
                }
            ];
            (window as any).__MOCK_SEASON__ = {
                id: 'test-season',
                leagueId: 'test-league',
                number: 1,
                year: 2026,
                calendar: [
                    {
                        id: 'r1',
                        trackName: 'Autodromo Hermanos Rodriguez',
                        countryCode: 'MX',
                        flagEmoji: '🇲🇽',
                        circuitId: 'mexico',
                        date: new Date(),
                        isCompleted: false,
                        totalLaps: 71,
                        weatherPractice: 'Sunny',
                        weatherQualifying: 'Cloudy',
                        weatherRace: 'Sunny'
                    }
                ]
            };
        });

        await page.goto('http://localhost:5174/racing');
    });

    test('should display the 3 session cards', async ({ page }) => {
        const practiceCard = page.locator('button#practice-card');
        const qualyCard = page.locator('button#qualy-card');
        const raceCard = page.locator('button#race-card');

        await expect(practiceCard).toBeVisible();
        await expect(qualyCard).toBeVisible();
        await expect(raceCard).toBeVisible();
    });

    test('qualy and race cards should be locked initially if no practice laps', async ({ page }) => {
        const qualyCard = page.locator('button#qualy-card');
        const raceCard = page.locator('button#race-card');

        // Check for the "disabled" attribute or the Lock icon presence
        await expect(qualyCard).toBeDisabled();
        await expect(raceCard).toBeDisabled();

        // Verify lock message
        await expect(page.getByText('PRACTICE REQUIRED TO UNLOCK').first()).toBeVisible();
    });

    test('practice card should be active by default', async ({ page }) => {
        const practiceCard = page.locator('button#practice-card');
        // Check for the active class logic (shadow or bgColor)
        await expect(practiceCard).toHaveClass(/bg-app-primary/);
    });

    test('should display next race info in the header', async ({ page }) => {
        // Round 1 of 9
        await expect(page.getByText('Round 1 of 9', { exact: false })).toBeVisible();
        // Track Name
        await expect(page.getByText('Autodromo Hermanos Rodriguez', { exact: false }).first()).toBeVisible();
        // Laps
        await expect(page.getByText('71 Laps', { exact: false })).toBeVisible();
        // Weather
        await expect(page.getByText('Sunny', { exact: false })).toBeVisible();
    });
});
