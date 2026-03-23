/**
 * FTG Racing Manager — Cloud Functions entry point.
 *
 * This file contains zero logic. All function implementations live in their
 * respective domain modules under src/domains/. This file exists solely to
 * satisfy Firebase's requirement for a single entry point (lib/index.js after build).
 *
 * Cutover checklist (run BEFORE `firebase deploy --only functions`):
 *   1. npm run typecheck  — must exit 0
 *   2. npm run test       — all tests must pass
 *   3. npm run build      — compiles src/ → lib/
 *   4. Verify package.json "main" points to "lib/index.js"
 *   5. firebase deploy --only functions
 *   6. Verify in Firebase Console all scheduled functions have new timestamps
 *
 * Rollback: set "main" back to "index.js" in package.json, redeploy.
 */

export * from "./schedulers/jobs";
