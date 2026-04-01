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
        version: 'V1.6.0',
        date: '2026-03-31',
        entries: [
            { type: 'feature',     textKey: 'changelog_v160_1' },
            { type: 'feature',     textKey: 'changelog_v160_2' },
            { type: 'improvement', textKey: 'changelog_v160_3' },
            { type: 'fix',         textKey: 'changelog_v160_4' },
            { type: 'fix',         textKey: 'changelog_v160_5' },
        ],
    },
    {
        version: 'V1.5.8',
        date: '2026-03-31',
        entries: [
            { type: 'fix', textKey: 'changelog_v158_1' },
            { type: 'improvement', textKey: 'changelog_v158_2' },
            { type: 'improvement', textKey: 'changelog_v158_3' },
        ],
    },
    {
        version: 'V1.5.7',
        date: '2026-03-30',
        entries: [
            { type: 'ui', textKey: 'changelog_v157_1' },
            { type: 'improvement', textKey: 'changelog_v157_2' },
        ],
    },
    {
        version: 'V1.5.6',
        date: '2026-03-30',
        entries: [
            { type: 'improvement', textKey: 'changelog_v156_1' },
            { type: 'improvement', textKey: 'changelog_v156_2' },
        ],
    },
    {
        version: 'V1.5.5',
        date: '2026-03-30',
        entries: [
            { type: 'fix', textKey: 'changelog_v155_1' },
            { type: 'fix', textKey: 'changelog_v155_2' },
            { type: 'fix', textKey: 'changelog_v155_3' },
        ],
    },
    {
        version: 'V1.5.4',
        date: '2026-03-28',
        entries: [
            { type: 'fix', textKey: 'changelog_v154_1' },
        ],
    },
    {
        version: 'V1.5.3',
        date: '2026-03-26',
        entries: [
            { type: 'ui',          textKey: 'changelog_v153_1' },
            { type: 'ui',          textKey: 'changelog_v153_2' },
            { type: 'fix',         textKey: 'changelog_v153_3' },
            { type: 'fix',         textKey: 'changelog_v153_4' },
        ],
    },
    {
        version: 'V1.5.2',
        date: '2026-03-26',
        entries: [
            { type: 'fix', textKey: 'changelog_v152_1' },
            { type: 'fix', textKey: 'changelog_v152_2' },
            { type: 'fix', textKey: 'changelog_v152_3' },
        ],
    },
    {
        version: 'V1.5.1',
        date: '2026-03-26',
        entries: [
            { type: 'feature',     textKey: 'changelog_v151_1' },
            { type: 'feature',     textKey: 'changelog_v151_2' },
            { type: 'improvement', textKey: 'changelog_v151_3' },
            { type: 'improvement', textKey: 'changelog_v151_4' },
        ],
    },
    {
        version: 'V1.5.0',
        date: '2026-03-26',
        entries: [
            { type: 'feature', textKey: 'changelog_v150_1' },
            { type: 'feature', textKey: 'changelog_v150_2' },
            { type: 'improvement', textKey: 'changelog_v150_3' },
        ],
    },
    {
        version: 'V1.4.4',
        date: '2026-03-26',
        entries: [
            { type: 'fix', textKey: 'changelog_v144_1' },
            { type: 'fix', textKey: 'changelog_v144_2' },
            { type: 'fix', textKey: 'changelog_v144_3' },
        ],
    },
    {
        version: 'V1.4.3',
        date: '2026-03-26',
        entries: [
            { type: 'ui', textKey: 'changelog_v143_1' },
            { type: 'ui', textKey: 'changelog_v143_2' },
        ],
    },
    {
        version: 'V1.4.2',
        date: '2026-03-25',
        entries: [
            { type: 'fix', textKey: 'changelog_v142_1' },
            { type: 'fix', textKey: 'changelog_v142_2' },
        ],
    },
    {
        version: 'V1.4.1',
        date: '2026-03-25',
        entries: [
            { type: 'fix', textKey: 'changelog_v141_1' },
            { type: 'fix', textKey: 'changelog_v141_2' },
            { type: 'fix', textKey: 'changelog_v141_3' },
        ],
    },
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
