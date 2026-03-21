# FTG Racing Manager - AI Governance & Development Rules (GEMINI.md)

This file defines the mandatory development standards and operational constraints for AI agents. Adherence to these protocols is non-negotiable to maintain system integrity, financial balance, and a premium user experience.

## 🚨 MANDATORY: Pre-Development Documentation Review
Before modifying or creating any module, service, or feature, you **MUST** read all documentation located in:
`frontend/src/routes/admin/docs/`

Key documents to review every time:
- **Standards**: `human/estandares.md` and `ai/standards.md`.
- **Business Rules**: `human/reglas_negocio.md`.
- **System Architecture**: `human/servicios.md` and `ai/architecture.md`.
- **Incident History**: `human/postmortem_r2.md` and `human/postmortem_r3.md` (Crucial for preventing recurring simulation and state bugs).

## 🧪 Quality Assurance & Testing
- **Playwright Testing Prohibited**: Do NOT create, suggest, or attempt to run E2E tests using Playwright.
- **Manual QA**: All Quality Assurance and interface validation will be performed **manually by the user**. Your responsibility is to ensure code correctness and adherence to the standards before handing off for manual check.
- **Unit Testing**: Complex deterministic logic (finance, physics, simulation math) should be supported by Vitest unit tests as specified in the service documentation.

## 🚫 Anti-Hardcoding Policy
Hardcoding is strictly prohibited. Every project value must be managed through the established systems:
- **Text & UI**: Use the localization system (Arb files/i18n stores) for all user-facing strings.
- **Styles & Aesthetics**: Use Tailwind CSS exclusively. Design tokens (colors, surfaces) must reference definitions in `app.css`. Explicitly avoid inline styles or raw hex codes.
- **Business Constants**: Never hardcode values like fees, prizes, or limits directly in logic. Reference `reglas_negocio.md` and use centralized constants or Firestore configuration:
    - *Examples*: Team renaming fee ($500k), HQ Maintenance (Level * $15k), XP thresholds (500 XP), Fibonacci multipliers, etc.

## 🛠️ Software Development Standards

### 1. Reactivity & Framework (Svelte 5)
- **Rune Enforcement**: Use `$state`, `$derived`, and `$effect`. Legacy Svelte 4 `writable` stores are deprecated for reactive state.
- **Component snippets**: Use `{#snippet}` for complex UI fragments and layout delegation.

### 2. Architecture & Data Integrity
- **Service Isolation**: 
    - **Services** (`src/lib/services`): Stateless logic and pure API communication.
    - **Stores** (`src/lib/stores`): UI reactivity and Firestore listeners (`onSnapshot`).
    - **Prohibition**: Never perform direct Firestore calls (e.g., `doc()`, `getDoc()`) within `.svelte` component files.
- **Transactional Safety**: Every operation affecting the economy (`budget`, `balance`) or ownership (driver/team transfers) **MUST** be encapsulated in a Firestore `runTransaction` or a server-side Cloud Function.
- **Silent Failures**: Empty `catch` blocks are forbidden. Always log errors with contextual namespace: `[ServiceName:MethodName] Error description`.

### 3. UI/UX Excellence
- **No Browser Dialogs**: Use the `uiStore` for all modals and notifications. `alert()`, `confirm()`, and `prompt()` are strictly forbidden.
- **Mobile First**: All designs must be responsive, ensuring that compact mobile views scale gracefully to desktop dashboards.

### 4. Critical Logic Safety (Post-mortem Lessons)
- **Variable Declaration**: Always declare variables (e.g., `let variable = 0;`) before conditional assignment to prevent `ReferenceError` in strict mode.
- **Truthiness Checks**: Always check array length (`array.length > 0`) instead of just checking for the object's existence.
- **Sync Pipeline**: After manual simulations or data fixes, always execute the full pipeline including `node sync_universe.js` to propagate denormalized standings.
- **Deploy Verification**: After ANY fix to `functions/index.js`, you MUST remind the user to run `firebase deploy --only functions` AND verify in Firebase Console → Functions that the deployment timestamp matches. A local-only fix is NOT a deployed fix. (See `postmortem_r3.md` — the R2 fix was applied locally but never deployed, causing an identical failure 5 days later.)

## 📝 Documentation & Knowledge Maintenance
- **JSDoc**: Obligatory for all public methods in services and stores, detailing parameters and return types.
- **Auto-Update**: If you modify a business rule, data structure, or architectural pattern, you **MUST** update the corresponding Markdown file in the `/docs` directory to reflect the change.
