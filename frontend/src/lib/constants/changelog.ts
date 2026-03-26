import type { TranslationKey } from '$lib/utils/i18n';

export type ChangelogEntryType = 'feature' | 'fix' | 'improvement' | 'ui';

export interface ChangelogEntry {
    type: ChangelogEntryType;
    textKey: TranslationKey;
}

export interface ChangelogVersion {
    version: string;
    date: string;
    entries: ChangelogEntry[];
}

/**
 * Release notes history. Add a new ChangelogVersion entry on each release.
 * All user-facing strings must reference i18n keys — never hardcode text here.
 */
export const CHANGELOG: ChangelogVersion[] = [
    {
        version: 'V1.4.0',
        date: '2026-03-25',
        entries: [
            { type: 'feature',     textKey: 'changelog_v140_1' },
            { type: 'feature',     textKey: 'changelog_v140_2' },
            { type: 'ui',          textKey: 'changelog_v140_3' },
        ],
    },
    {
        version: 'V1.3.1',
        date: '2026-03-25',
        entries: [
            { type: 'fix', textKey: 'changelog_v131_1' },
            { type: 'fix', textKey: 'changelog_v131_2' },
        ],
    },
    {
        version: 'V1.3.0',
        date: '2026-03-25',
        entries: [
            { type: 'feature', textKey: 'changelog_v130_1' },
            { type: 'ui',      textKey: 'changelog_v130_2' },
        ],
    },
    {
        version: 'V1.2.0',
        date: '2026-03-25',
        entries: [
            { type: 'feature',     textKey: 'changelog_v120_1' },
            { type: 'feature',     textKey: 'changelog_v120_2' },
            { type: 'improvement', textKey: 'changelog_v120_3' },
            { type: 'improvement', textKey: 'changelog_v120_4' },
            { type: 'ui',          textKey: 'changelog_v120_5' },
        ],
    },
    {
        version: 'V1.1.1',
        date: '2026-03-25',
        entries: [
            { type: 'fix', textKey: 'changelog_v111_1' },
            { type: 'fix', textKey: 'changelog_v111_2' },
            { type: 'ui',  textKey: 'changelog_v111_3' },
        ],
    },
    {
        version: 'V1.1.0',
        date: '2026-03-24',
        entries: [
            { type: 'improvement', textKey: 'changelog_v110_1' },
        ],
    },
    {
        version: 'V1.0.0',
        date: '2026-03-24',
        entries: [
            { type: 'feature', textKey: 'changelog_v100_1' },
            { type: 'ui',      textKey: 'changelog_v100_2' },
        ],
    },
];

/** The most recent version string — used to detect "unread" state. */
export const LATEST_VERSION = CHANGELOG[0].version;
