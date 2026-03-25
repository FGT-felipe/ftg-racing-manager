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
        version: 'V1.0.0',
        date: '2026-03-24',
        entries: [
            { type: 'feature', textKey: 'changelog_v100_1' },
            { type: 'ui',      textKey: 'changelog_v100_2' },
        ],
    },
    {
        version: 'V4.1.6',
        date: '2026-03-23',
        entries: [
            { type: 'ui',          textKey: 'changelog_v416_1' },
            { type: 'ui',          textKey: 'changelog_v416_2' },
            { type: 'ui',          textKey: 'changelog_v416_3' },
            { type: 'feature',     textKey: 'changelog_v416_4' },
            { type: 'feature',     textKey: 'changelog_v416_5' },
            { type: 'improvement', textKey: 'changelog_v416_6' },
            { type: 'improvement', textKey: 'changelog_v416_7' },
            { type: 'fix',         textKey: 'changelog_v416_8' },
            { type: 'fix',         textKey: 'changelog_v416_9' },
        ],
    },
];

/** The most recent version string — used to detect "unread" state. */
export const LATEST_VERSION = CHANGELOG[0].version;
