# Release Check — Pre-merge Checklist

Run the full pre-release checklist before merging any feature or fix branch. Work through each step in order and report results.

## Step 0 — Working tree sanity check (BLOCKING)

Run `git status --short` and `git diff main --name-only`.

- **Every modified file must be accounted for.** If a file appears in the diff that is not part of this branch's feature, STOP and investigate before continuing.
- Any uncommitted change in `functions/lib/` that is NOT part of this branch must be resolved first: either committed to its own branch, or restored to main state via `git checkout main -- <file>`.
- Do NOT proceed with the checklist while there are ghost modifications in the working tree.

## Step 1 — Hardcoding audit
Run `/audit` to check for CLAUDE.md violations. Block release if any Category 1 (Firestore in .svelte) or Category 2 (alert/confirm) violations are found.

## Step 2 — i18n completeness
- Verify all new `t()` keys added in this branch exist in BOTH `en` and `es` sections of `frontend/src/lib/utils/i18n.ts`.
- Check that no new user-facing strings were added without going through `t()`.

## Step 3 — Constants check
- Verify any new business value (fee, cost, threshold, multiplier) is exported from `frontend/src/lib/constants/economics.ts` or the appropriate constants file — not embedded inline.

## Step 4 — Changelog
- Confirm a new entry was added to `frontend/src/lib/constants/changelog.ts` for this version.
- Confirm the corresponding i18n key(s) exist in `i18n.ts`.

## Step 5 — Version bump & README
- Confirm `APP_VERSION` in `frontend/src/lib/constants/app_constants.ts` matches the release version.
- Confirm `**Version:**` line in root `README.md` matches the release version.

## Step 6 — Cloud Functions (if functions/ was modified)
- Remind: run `firebase deploy --only functions` and verify timestamp in Firebase Console.
- Check for undeclared variables before conditionals (postmortem R2/R3 pattern).
- Check for `array.length > 0` guards (not just array existence).

## Step 7 — Universe sync (if race simulation was modified)
- If any race simulation logic changed, remind to run `node sync_universe.js` from `functions/`.

## Output
Print a checklist with ✅/⚠️/❌ per step. If anything is ❌, block merge and list what needs fixing.
