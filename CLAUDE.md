# FTG Racing Manager — Claude Development Guide

## 1. BMAD Method — The Primary Workflow (Mandatory)

This project is driven by the **BMAD Method** (Build More, Architect Dreams) — an agile, AI-driven development framework. **Any feature, bug fix, or improvement MUST go through a BMAD workflow.** Ad-hoc edits directly into files are forbidden except for trivial one-liners (typos, formatting, a missing import) — and even then, a short BMAD story is preferred.

### 1.1 Installed modules

- **BMAD Core + BMM (Build More Architect Dreams)** — v6.3.0
- **Location:** `_bmad/` (tracked), `_bmad-output/` (generated artifacts)
- **Claude Code integration:** 41 skills under `.claude/skills/bmad-*`
- **Help:** invoke the `bmad-help` skill at any time to get routed to the right workflow.

### 1.2 Decision tree — pick the right BMAD workflow

| User request | BMAD workflow | Key skills, in order |
|---|---|---|
| **New user-facing feature** (market, academy tab, new module) | Full pipeline: analysis → planning → solutioning → implementation | `bmad-product-brief` (or `bmad-prfaq`) → `bmad-create-prd` → `bmad-validate-prd` → `bmad-create-ux-design` (if UI) → `bmad-create-architecture` → `bmad-create-epics-and-stories` → `bmad-check-implementation-readiness` → `bmad-sprint-planning` → story cycle |
| **Bug fix** (any severity, including hotfix) | Quick Dev — unified intent-in / code-out | `bmad-quick-dev` → `bmad-code-review` → (if P1) hotfix gate in §15 |
| **Small improvement, chore, refactor, doc update** | Quick Dev | `bmad-quick-dev` |
| **Larger refactor / architectural change** | Full pipeline, starting at solutioning | `bmad-create-architecture` → `bmad-create-epics-and-stories` → story cycle |
| **Unfamiliar area or scope unclear** | Discovery first | `bmad-brainstorming` / `bmad-domain-research` / `bmad-technical-research` → then the appropriate track above |
| **Significant mid-flight change** | Course correction | `bmad-correct-course` |

### 1.3 The story cycle (canonical implementation loop)

Every feature story runs this loop, one story at a time, in a fresh chat per step:

```
bmad-create-story  (CS)  →  bmad-create-story:validate  (VS)  →  bmad-dev-story  (DS)  →  bmad-code-review  (CR)
                                                                              ↑                    │
                                                                              └────── if issues ───┘
```

At epic end: `bmad-retrospective` (ER) is optional but strongly recommended — it feeds lessons back into this document.

### 1.4 Artifacts — where BMAD writes

- **Planning artifacts** (PRDs, architectures, epics, stories): `_bmad-output/planning-artifacts/`
- **Implementation artifacts** (sprint status, story files, QA reports): `_bmad-output/implementation-artifacts/`
- **Project knowledge** (context, documentation): `docs/` and `frontend/src/routes/admin/docs/`

These paths are configured in `_bmad/bmm/config.yaml`. Do not hand-edit that file.

### 1.5 Hard rules

- **No code changes without a BMAD workflow.** If you find yourself about to call `Edit` or `Write` without having run at least `bmad-quick-dev`, stop and start the workflow.
- **One story, one branch, one PR.** See §11 and §15.1.
- **Context load is mandatory.** Before the first BMAD skill of a task, read the docs listed in §2.
- **Rules in §3 through §18 override any BMAD skill default** when they conflict. The skill produces the code; this file produces the constraints.
- **Prohibited BMAD skills in this project:**
  - `bmad-qa-generate-e2e-tests` — Playwright/automated E2E tests are banned (see §8). Use Vitest unit tests only.

---

## 2. Mandatory Pre-BMAD Context Load

Before the first BMAD skill invocation on any task, read the relevant documentation. These are the inputs the BMAD agents need to produce correct artifacts for **this** project:

```
frontend/src/routes/admin/docs/ai/
```

| Document | When to read |
|---|---|
| `standards.md` | Always — governs code patterns |
| `architecture.md` | Always — state machines, critical fallbacks |
| `services.md` | When touching services, stores, or Cloud Functions |
| `database_schema.md` | When touching Firestore reads/writes |
| `weekend_pipeline.md` | When touching race simulation or scheduled functions |
| `human/postmortem_r2.md` / `human/postmortem_r3.md` | When modifying `functions/index.js` |
| `human/postmortem_admin_qualy_wipe.md` | When creating or modifying any admin tool |
| `human/postmortem_t004_academy_practice.md` | When changing a field's type or semantics (§13) |
| `human/postmortem_v17_session_gate_cascade.md` | When touching weekend state, `$effect`, or `arrayUnion` (§15) |

For a brownfield view of the repo that BMAD can consume, keep `bmad-generate-project-context` output fresh — re-run it after major refactors.

---

## 3. Technology Stack

This is a **Svelte 5 + Firebase** web application. The Flutter codebase (`lib/`) is **deprecated and must not be modified**. All new development happens in `frontend/`.

```
frontend/        ← SvelteKit 5 (active — all development here)
functions/       ← Firebase Cloud Functions v2 (Node.js 20, strict mode)
lib/             ← DEPRECATED Flutter code. Do not touch.
_bmad/           ← BMAD framework config (tracked)
_bmad-output/    ← BMAD generated artifacts (gitignored — see §10)
```

**Frontend stack:** SvelteKit · Svelte 5 Runes · TypeScript · Tailwind CSS · Firebase v10
**Backend:** Firestore · Cloud Functions v2 · Firebase Auth · Firebase Hosting

---

## 4. Core Development Rules (enforced in `bmad-dev-story` and `bmad-code-review`)

### 4.1 Reactivity (Svelte 5 Runes — Non-negotiable)

- **Use `$state()`** for reactive data from Firestore.
- **Use `$derived()`** for all computed values — formatting, filtering, transformations.
- **Use `$effect()`** sparingly — only for DOM integrations or Firebase SDK synchronization.
- **Never use** Svelte 4 `writable` / `readable` stores for local state.
- **Expose reactive state** via class getters, not raw store exports.

### 4.2 Architecture: Service / Store Separation

```
src/lib/services/*.svelte.ts  →  Stateless logic, pure Firebase API calls
src/lib/stores/*.svelte.ts    →  UI reactivity, Firestore onSnapshot listeners
src/routes/**/*.svelte        →  UI only — NO direct Firestore calls
```

**Hard rule:** Never call `doc()`, `getDoc()`, `setDoc()`, or `collection()` directly from a `.svelte` component file.

### 4.3 Transactional Safety

Every mutation that affects **budget**, driver/team **ownership**, or **economic fields** (`budget`, `value`, `salary`) **must** use `runTransaction` or a server-side Cloud Function.

Silent writes outside transactions are forbidden for these fields.

### 4.4 Error Handling

- Empty `catch` blocks are **forbidden**.
- All errors must be logged with namespace context:
  ```typescript
  console.error('[SponsorService:negotiate] Failed to write transaction:', e);
  ```
- Use `try/catch` at the boundary where recovery or user feedback is possible, not at every line.

### 4.5 UI/UX Standards

- **No browser dialogs.** `alert()`, `confirm()`, and `prompt()` are prohibited. Use `uiStore` and custom modal components.
- **Tailwind CSS only.** No inline styles, no raw hex codes. Custom colors reference variables defined in `app.css`.
- **Design tokens** — All surfaces and colors use CSS variables (`--app-primary`, `--app-surface`, `--app-bg`, etc.). Never reference design values by literal color.
- **Mobile First.** Design for mobile, then scale up to desktop dashboards.
- **Design aesthetic:** Premium Dark Gold — high contrast, subtle gradients, `backdrop-blur` for overlays.

### 4.6 Anti-Hardcoding

Every business value must be centralized:

- **Text:** Use the i18n utility (`src/lib/utils/i18n.ts`) for all user-facing strings.
- **Business constants:** Reference `reglas_negocio.md` and centralize in `src/lib/constants/`. Never embed fees, thresholds, or multipliers directly in logic.
  - Examples: Team rename fee ($500k), HQ maintenance (Level × $15k), XP threshold (500 XP), Fibonacci upgrade multipliers.
- **Firestore config:** Prefer Firestore-stored config for values that change over time.

---

## 5. Cloud Functions — Critical Safety Rules

> **Context:** Functions run in Node.js strict mode. Violations are silent — they fail in Firebase logs only, not in local console. These rules MUST be enforced by `bmad-code-review` before any `functions/` change is merged.

### 5.1 Variable Declaration (Postmortem R2/R3 — Critical)

**Always declare variables with `let` before any conditional assignment.**

```js
// WRONG — throws ReferenceError in strict mode
if (teamRole === "ex_driver") { extraCrash = 0.001; }
const crashed = Math.random() < (accProb + extraCrash);

// CORRECT
let extraCrash = 0;
if (teamRole === "ex_driver") { extraCrash = 0.001; }
const crashed = Math.random() < (accProb + extraCrash);
```

### 5.2 Array Guard Pattern (Postmortem R2/R3 — Critical)

**Always check `array.length > 0`, not just array existence. Empty arrays are truthy.**

```js
// WRONG — [] is truthy, causes false skip
if (rSnap.data().qualyGrid) { continue; }

// CORRECT
if (rSnap.data().qualyGrid?.length > 0) { continue; }
```

### 5.3 Deploy Verification Rule

After ANY fix to `functions/index.js`, remind the user to:
1. Run `firebase deploy --only functions`
2. Verify in Firebase Console → Functions that the deployment timestamp is current

A local-only fix is **not** a deployed fix. See `postmortem_r3.md` — R2's fix was applied locally but never deployed, causing an identical failure 5 days later.

### 5.4 Admin Tool Safety Rules (Postmortem admin_qualy_wipe — Critical)

**Every admin tool that iterates a collection must have an explicit scope guard and a `// SCOPE:` comment.**

```ts
// WRONG — touches ALL race documents including completed historical rounds
for (const rDoc of racesSnap.docs) {
    racesBatch.update(rDoc.ref, { qualyGrid: [] });
}

// CORRECT — scope guard protects completed documents
// SCOPE: Only unfinished races (isFinished !== true)
for (const rDoc of racesSnap.docs) {
    if (rDoc.data()?.isFinished === true) continue;
    racesBatch.update(rDoc.ref, { qualyGrid: [] });
}
```

**All admin tools that write to Firestore must support dry-run mode** and print a pre-flight summary of affected document IDs before executing any writes.

**Data durability rule:** Any field that feeds statistics, economic history, or classification records must be written to at least two places: the operational collection (mutable) and an immutable append-only collection. Example: `races/{id}.qualyGrid` (operational) + `qualifying_results/{id}` (immutable backup). See T-020.

### 5.5 Universe Sync (Manual Step)

The `/season/standings` page reads from `universe/game_universe_v1` (a denormalized aggregate). After any manual race simulation:

```bash
# Run from /functions directory
node sync_universe.js
```

This step is **not automatic**. Without it, standings remain stale.

---

## 6. Race Weekend State Machine

```
Monday 00:00 → Saturday 13:59  →  practice
Saturday 14:00                  →  qualifying
Saturday 15:00                  →  raceStrategy
Sunday 14:00                    →  race
Sunday 16:00                    →  postRace  (maps to "practice" in UI fallback)
```

**Critical fallback:** `weekStatus.globalStatus` does NOT exist in the backend. The `/racing` page derives status from `timeService.currentStatus`. When status is `POST_RACE`, the UI must map it to `"practice"` to render `GaragePanel` — not `RaceLivePanel` (empty).

**Timers:** Use `getTimeUntil(RaceWeekStatus.QUALIFYING)` for session countdowns — NOT `getTimeUntilNextEvent()`, which counts to the next state change and may return Monday 00:00.

---

## 7. Testing Policy

- **Playwright E2E tests are prohibited.** Do not create, suggest, or run Playwright tests. QA is performed manually by the team.
- **`bmad-qa-generate-e2e-tests` is prohibited** — this BMAD skill generates E2E/API automated tests. Do not invoke it. The only automated tests allowed are Vitest unit tests.
- **Vitest unit tests are required** for new deterministic logic (finance calculations, simulation math, service methods). `bmad-dev-story` must produce them alongside the implementation.
- **Test files live alongside their source:** `service.svelte.ts` → `service.test.ts`.
- **Async safety:** Gate all Firebase calls behind `browser` environment checks and/or `authStore.loading` checks to prevent SSR race conditions.

---

## 8. Documentation Maintenance

When you modify a business rule, data structure, service interface, or architectural pattern, update the corresponding markdown file as part of the story — not after. `bmad-dev-story` is not complete until the matching doc is updated.

| Change type | Update file |
|---|---|
| New/changed service or store | `ai/services.md` |
| New/changed data shape | `ai/database_schema.md` |
| New business rule or economic value | `human/reglas_negocio.md` |
| New/changed component pattern | `ai/components.md` |
| Simulation or Cloud Function logic | `ai/weekend_pipeline.md` |
| **Any version bump** | `README.md` — update the `**Version:**` line |

**JSDoc is mandatory** for all public methods in services and stores (parameters, return types, side effects).

---

## 9. Emergency Recovery Protocol

If any automated simulation fails, run from `functions/` in order:

```bash
node scripts/emergency/force_race_local.js qualy  # 1. Re-run qualifying
node scripts/emergency/force_race_local.js race    # 2. Re-run race  (or force_race_wrapper.js)
node scripts/emergency/force_post_race.js          # 3. Force economy processing
node scripts/emergency/sync_universe.js            # 4. Sync Standings UI
```

**Do not skip steps.** Each depends on the previous completing cleanly (Exit code 0).

> **Note:** `reset_all.js` and `run_simulation.js` do not exist. Use `force_race_local.js` or `force_race_wrapper.js` for manual race simulation.

Recovery operations bypass BMAD — they are operational runbooks, not feature work. Document any recovery in a post-incident BMAD retrospective (`bmad-retrospective`) so the cause feeds back into the rules.

---

## 10. Version Control Conventions

### 10.1 Branch Naming

Every branch must use one of these prefixes — never use `feature/` for work that isn't a new user-facing feature:

| Prefix | When to use | BMAD workflow |
|---|---|---|
| `feature/` | New user-facing module or functionality | Full pipeline |
| `fix/` | Bug fix (any severity) | Quick Dev |
| `chore/` | Tech debt, refactoring, docs, tooling, deps — no user-facing change | Quick Dev |
| `hotfix/` | Urgent production fix branched directly from `main` | Quick Dev + §15 gate |

**Format:** `<type>/<version>-<short-description>` when tied to a version, or `<type>/<short-description>` for isolated work. When the work is a BMAD story, include the story ID: `feature/v1.2.0-E02-S05-transfer-filters`.

```
feature/v1.2.0-E02-S05-transfer-market-filters
fix/v1.1.2-driver-name-truncation
chore/v1.1.1-tech-debt
hotfix/qualifying-crash-loop
```

### 10.2 Commit Messages — Conventional Commits

Format: `<type>(<scope>): <imperative description>`

| Type | When |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `chore` | Tooling, deps, config |
| `refactor` | Code restructure with no behavior change |
| `docs` | Documentation only |
| `style` | Formatting, i18n, visual tweaks |
| `test` | Adding or fixing tests |

### 10.3 Pull Request Structure

Every PR must include these three sections:

```markdown
## Motivation
<Why this change was needed — the problem, constraint, or decision behind it.>

## Summary
<What changed — bullet points.>

## BMAD trail
<Links/paths to the BMAD artifacts: PRD, architecture, story, code-review report.>

## Test plan
<Checklist of what to verify manually.>
```

The **Motivation** section is mandatory — it's the long-term record of *why*, which is never obvious from the diff alone. The **BMAD trail** section makes the provenance of the change auditable.

### 10.4 Versioning Strategy

- **Patch** (`1.1.x`) — fixes and chore branches
- **Minor** (`1.x.0`) — feature branches adding new functionality
- **Major** (`x.0.0`) — reserved for architectural rewrites

### 10.5 `.gitignore` expectations

- `_bmad-output/` — **gitignored** (regenerable artifacts; keep PRs clean)
- `_bmad/` — **tracked** (installation config is part of the project contract)

---

## 11. Story Cycle Execution Discipline

When the user requests multiple fixes or tasks in a single message, **execute them as separate BMAD stories, sequentially, one at a time**. Do not parallelize work across independent stories.

**Required process for every story:**
1. Pick the first story (prioritize by urgency if indicated).
2. Invoke `bmad-create-story` (or `bmad-quick-dev` for small scopes) — do not skip straight to code.
3. Investigate fully — read all relevant files before writing code. The BMAD dev agent will prompt for this; do not short-circuit it.
4. Implement the fix via `bmad-dev-story`.
5. Verify correctness (right fields, conditions, data flow) — then run `bmad-code-review`.
6. Only then move to the next story.

**Rationale:** Parallel execution causes assumptions to go unverified and fixes to target the wrong fields or conditions — leading to bugs that are worse than the originals. This rule is why BMAD's story cycle is sequential by design.

---

## 12. Type & Semantics Change Propagation (Postmortem T-004 — Critical)

When the **type** or **semantics** of a field shared between store and components changes, it is mandatory to grep every consumer **before** writing a single line of code. This check must happen inside `bmad-create-story` (during planning), not during `bmad-dev-story`.

**Rule:** Before changing a field's type (e.g. `string` → `{ id, sessionId }`) or its semantics (e.g. "a lock exists" → "a lock exists owned by someone else"), run:

```bash
grep -r "fieldName" frontend/src --include="*.ts" --include="*.svelte"
```

Then update **every** consumption point in the same commit. A type change with N consumers must produce N updates — not 1.

### 12.1 Concrete cases that must trigger this process

| Situation | Mandatory action |
|---|---|
| Firestore field changes from primitive to object | Grep + update truthiness guards (`if (x)` → `if (x?.id)`) |
| Lock semantics change ("exists" → "belongs to another") | Grep + update every `!!field` in the UI |
| Component prop changes from conditional to always-present | Grep + verify every consumer of the prop |
| Data available from two sources (raw snapshot vs gated getter) | Always use the public store getter — never the raw snapshot from a component |

### 12.2 Product decision verification — before implementation

Before writing code, re-read the product decision as agreed during planning (`bmad-create-prd` / `bmad-create-story`). If the implementation contradicts what was agreed, **stop and correct** — do not assume your own interpretation is valid.

Example from T-004: the planning explicitly agreed "the same trainee can run multiple stints; the lock only prevents rotating to a different trainee." The implementation did the opposite. The user had to report it as a bug.

### 12.3 Pre-commit verification checklist

After any change that touches a shared field, verify explicitly:

1. Are all `if (field)` still valid with the new type?
2. Are all props that depend on this field updated?
3. Does the UI consume the store's getter or the raw snapshot? (must be the getter)
4. Does the fix cover the backend (store/service) **and** the frontend (component)?

See `human/postmortem_t004_academy_practice.md` — 5 bugs in a single feature from not following this process. This checklist is part of `bmad-code-review`'s exit criteria for any story touching shared fields.

---

## 13. Implement Exactly What Was Agreed in Planning

Product decisions are agreed during BMAD planning (`bmad-create-prd`, `bmad-create-story`, `bmad-create-story:validate`). Implementation must honor those decisions to the letter — no reinterpreting, no simplifying, no "improving" without authorization.

**Before writing code, re-read the agreed product decision.** If there is ambiguity, ask. Do not assume.

If the implementation contradicts what was agreed, it is a bug introduced by the developer — not by the user.

**Forbidden:**
- Shipping a "simplified" version of what was requested without notice
- Making product decisions unilaterally during implementation
- Ignoring answers given during the planning Q&A

**Planning exists to prevent rework. If it is ignored, the rework is the developer's responsibility.**

This rule is why BMAD separates `bmad-create-story:validate` (signs off the spec) from `bmad-dev-story` (implements the spec). Skipping VS or deviating from it in DS is a process violation.

---

## 14. Root Cause Discipline & State Lifecycle (Postmortem v1.7.x)

Four consecutive releases (v1.7.0 → v1.7.3 hotfix) shipped patches to the same subsystem (`weekStatus.driverSetups`) without anyone fixing the actual root cause: `processPostRace` doesn't clear the record between rounds. The rules below codify the lessons. See `human/postmortem_v17_session_gate_cascade.md`. `bmad-code-review` must enforce every subsection below before approving a story.

### 14.1 Identify root cause before writing the fix

Before any P1 fix, write one sentence: *"the bug happens because X writes/doesn't write Y, read by Z."* If you can't write that sentence, you don't understand the bug yet — do not start coding. This sentence belongs in the BMAD story's problem statement.

When the bad data comes from an upstream write (or absent write), the fix belongs upstream. Patching the read is acceptable only when the upstream is out of scope, **and that case must be logged as debt in the PR description with an explicit TODO**.

### 14.2 Bug-in-other-faces check

Before closing any fix, ask: *"can this same bug appear in a different component that reads the same field?"* If yes, fix it at the source or touch every consumer in the same PR. Do not ship a fix that just relocates the bug.

> v1.7.1 patched `PreparationChecklist`. v1.7.3 patched `QualifyingSetupTab`, `PracticePanel`, `RaceSetupTab`, `StrategyPanel`, and `PreparationChecklist` again. Five components, same root cause, five independent patches.

### 14.3 Walk the state machine before closing the PR

When the change touches a phased subsystem (race weekend, hiring flow, transfer market), write in the PR body how the code behaves in **every phase × every user branch**. For race weekend: 4 phases (practice → qualifying → race strategy → race) × 2 user paths (with practice / without practice) = 8 cells. Skipping a cell is a guaranteed bug in that cell.

> v1.7.3 fixed the tyre compound revert for users who practiced. The "user did not practice this round" branch was never walked. The bug surfaced ~3 hours later in production with players in the active session.

### 14.4 `$effect` never resets state on snapshot re-runs

`$effect` re-runs on every snapshot of the watched store, including unrelated writes (budget, sponsors, charge fees). Resetting `$state` inside `$effect` based on a derived value silently destroys live user input.

State resets inside `$effect` are only allowed when the trigger is a deliberate input change (e.g. `driverId` switch). Track the previous input in a `let` outside `$state` and compare before resetting:

```ts
let loadedDriverId: string | null = null;
$effect(() => {
    if (driverId !== loadedDriverId) {
        loadedDriverId = driverId;
        setup = { ...defaults }; // reset only on driver switch
    }
    // ... load logic that does not clobber live user input
});
```

### 14.5 Strip user-editable fields in every load branch

When a `$effect` loads a saved Firestore object onto a `$state` the user is editing, strip the fields the user controls live (e.g. `tyreCompound`, active sliders) **from every load branch**, not only the main one. The bug always surfaces in the branch you forgot.

```ts
const { tyreCompound: _q, ...quali } = qualifyingObj;  setup = { ...setup, ...quali };
const { tyreCompound: _p, ...prac  } = practiceObj;     setup = { ...setup, ...prac  };
```

### 14.6 `arrayUnion` requires an explicit lifecycle

Any array field written with `arrayUnion` must have a documented "first write of scope" condition that **overwrites** instead of appending. If the data is per-session, the overwrite fires when the sessionId changes.

```ts
async saveQualyResult(..., isFreshSession: boolean) {
    await updateDoc(ref, {
        qualifyingRuns: isFreshSession ? [run] : arrayUnion(run),
    });
}
```

Without this, R(N-1) entries leak into R(N+1) until a manual cleanup is done.

### 14.7 Gate by own sessionId — never by proxy

To check whether data belongs to the current session, compare the sessionId **owned by that data** (`qualifyingSessionId` for qualifying, `raceSessionId` for race strategy). Never use a sibling subsystem's session field as a proxy. A driver may qualify without practicing — using `practice.sessionId` as the qualifying gate hides their fresh data.

### 14.8 Cross-boundary state needs explicit cleanup

Any field that survives beyond its natural lifecycle (across rounds, sessions, requests) is debt unless a cleanup mechanism exists. Document the lifecycle (creation → mutation → cleanup) in `weekend_pipeline.md` or `database_schema.md` before merging.

---

## 15. Hotfix & Deploy Gate

### 15.1 One story, one branch, one objective

If a second bug surfaces during implementation, open a new BMAD story and a new branch. Branch ballooning is prohibited during hotfix windows. The only exception: bugs that block QA of the original fix — and even then, log them explicitly in the PR as separate BMAD story IDs.

> `fix/v1.7.3-trainee-standings-name` started as a cosmetic naming fix. It ended up touching 6 files and merging 5 P1s in a single commit, with no individual review. Three hours later, two of them had returned in production.

### 15.2 Hotfix walkthrough is mandatory

Before deploying any hotfix to production, write in chat (this is the content that feeds `bmad-checkpoint-preview`):
- *the bug was X*
- *the previous line did Y*
- *the new line does Z*
- *the new version does NOT fail in scenarios A, B, C because ...*

If you can't write that, the fix is not ready.

### 15.3 `/deploy` requires explicit text confirmation

A green build is not authorization to deploy. **A green `bmad-code-review` is not authorization to deploy.** After `npm run build` succeeds, **stop and wait** for the user to type a confirmation (`ship`, `deploy`, `go`) before uploading to hosting. The user is the only QA gate; bypassing it ships untested fixes to live players.

### 15.4 Reporting a fix

When telling the user a bug is fixed, cite four things: file, line, exact change, and **why** the new code prevents the failure. "Fixed, deploying" without those four pieces does not count. These four items must also appear in the BMAD story's closing notes.

---

## 16. Flutter Deprecation Status

The Flutter codebase (`lib/`, `android/`, `pubspec.yaml`) is **100% migrated** to Svelte. It is kept for reference only. **Do not modify any Flutter files.** BMAD workflows must never target `lib/` or `android/`.

All features previously in Flutter are now implemented in `frontend/`. The Flutter code may be deleted from the repository at any time.

---

## 17. Vertical Slice Discipline (Mandatory)

Every épica, story, and multi-layer bug fix **must** be designed as a vertical slice — an end-to-end deliverable that traverses every layer it needs (UI → service/store → Firestore → Cloud Function/sim → tests → docs) — never as a horizontal layer (a story that ships only the backend, a story that ships only the UI).

**Why:** Horizontal layers ship dead code. A "Firestore model" story without a UI is invisible to the player and untestable end-to-end. A "UI" story without backing services is a fake demo. Both produce integration debt that surfaces weeks later as "we need to wire this up." Vertical slices ship working software at every merge — the player can use the feature on day 1, even in skeleton form.

### 17.1 Skeleton + Slices structure

When an épica decomposes into multiple stories, the structure is mandatory:

- **Slice 1 — Skeleton:** the simplest possible end-to-end path. Hardcoded values are fine. Only one happy path, one user, one circuit. **Must work end-to-end** — a player can complete the flow even if it's bare.
- **Slice 2..N:** each slice adds one capability, vertically. New compound, new factor in a formula, new validation, new user branch. Each slice ships its own UI + service + DB + tests + docs.

A slice is **not** complete until: UI works, service is called, Firestore writes/reads, simulation/CF integrates, tests pass, and the relevant doc (`weekend_pipeline.md`, `services.md`, `database_schema.md`, `business_rules.md`) is updated.

### 17.2 What counts as a layer in this project

For FTG Racing Manager, a vertical slice typically traverses:

| Layer | Example artifacts |
|---|---|
| UI | `frontend/src/routes/**/*.svelte`, `frontend/src/lib/components/` |
| Service | `frontend/src/lib/services/*.svelte.ts` (stateless logic, transactions) |
| Store | `frontend/src/lib/stores/*.svelte.ts` (UI reactivity, snapshot listeners) |
| Schema | Firestore collection shape + rules |
| Cloud Function | `functions/src/**` (sim engines, scheduled jobs, post-race) |
| Tests | Vitest unit tests next to source |
| Docs | `frontend/src/routes/admin/docs/ai/*.md` |

A story that touches **two or more** of UI, Service, Schema, or CF is multi-layer and must be a vertical slice. Pure UI tweaks (color, copy, layout) and pure docs/chores are exempt.

### 17.3 Bug fixes that span layers

If a bug requires changes in more than one layer (e.g. CF writes wrong field + UI reads it wrong), do **not** open one fix per layer. Either:
- **Single vertical slice:** one branch, one PR, all layers fixed together with tests covering the round-trip.
- **Two stories with explicit dependency:** if the surface area is too big for one PR, the second story declares "blocked by Story #X (root cause)" and does **not** ship until the first is merged. The patch story must be tagged as debt and removed when the root fix lands.

The default is the single vertical slice. The two-story option is only for genuinely large fixes and must be approved during `bmad-create-story`.

### 17.4 Anti-patterns (forbidden)

- **"Backend-only" story:** a story that adds a Firestore field but doesn't surface it in the UI in the same PR. Future-UI-story is a smell — if the field has no consumer today, don't write it today.
- **"UI-only" story for a feature that needs data:** mocked data in components is not a slice. The store/service must be wired to real Firestore in the same PR.
- **"Refactor first, feature second":** restructuring a service before there's a story that uses the new shape is speculative work. Fold the refactor into the slice that needs it, or defer.
- **"Tests in a follow-up":** tests are part of the slice. A slice without tests is incomplete — `bmad-code-review` rejects it.
- **"Docs at the end of the épica":** docs are updated per slice, not at the end. Drift between code and docs is the bug.

### 17.5 Where this rule is enforced

| Skill / phase | Enforcement |
|---|---|
| `bmad-create-epics-and-stories` | Story decomposition must produce vertical slices, named `Skeleton`, `Slice 2: <capability>`, etc. Reject horizontal layers. |
| `bmad-create-story` | The story spec must list every layer it touches. If only one layer is listed and the work is multi-layer, the story is rejected. |
| `bmad-quick-dev` | For multi-layer bugs, the unified flow must produce a single vertical slice — not split fixes by layer. |
| `bmad-code-review` | Any PR is rejected if it ships a layer without its consumer (orphan field, dead service, mocked component). The reviewer asks: *"Can a player use this end-to-end after this merge?"* — if no, the PR is not a slice. |

### 17.6 Vertical slice in Shortcut

When an épica is mapped to Shortcut:
- The **Epic description** lists slices as `Slice N: <name>` with the capability each one delivers.
- Each Story under the épica corresponds to **exactly one slice**.
- Story descriptions must include a **"Layers touched"** section enumerating UI / Service / Schema / CF / Tests / Docs deliverables for that slice.
- A story tagged as part of an épica without that section is incomplete and must be rewritten before implementation starts.

---

## 18. File Verification Before Implementation (Mandatory)

Before writing a single line of code, every BMAD workflow that touches the UI **must locate the exact files** that correspond to each surface named in the story or task. Documentation and story specs name surfaces by concept ("the Garage page", "the Engineering tab") — the actual file path must be verified in the codebase, not assumed from the name.

### 18.1 The rule

When a story or task references a UI surface, component, service, or route by name, run a file search before opening any editor:

```bash
# Find all route files matching the surface concept
find frontend/src/routes -name "*.svelte" | grep -i "<keyword>"

# Find all components matching the concept
find frontend/src/lib/components -name "*.svelte" | grep -i "<keyword>"
```

If more than one file matches, read both and confirm with the user which one is the active surface before proceeding.

### 18.2 When this check is mandatory

| Situation | Required action |
|---|---|
| Story names a page or route ("the Garage page", "the Engineering tab") | `find` routes, list all matches, verify with user if >1 |
| Story names a component ("GaragePanel", "StrategyPanel") | `find` components, grep for usages, confirm which route renders it |
| Story names a service or store by concept ("the parts service") | Grep `src/lib/services` and `src/lib/stores` for matching files |
| Refactor touches a shared component | Grep every route that imports it before editing |

### 18.3 When ambiguity is found

If two files match the same concept (e.g. `facilities/garage/+page.svelte` and `facilities/engineering/+page.svelte` both look like "the garage"), **stop and ask the user** which one is the active surface. Do not guess. Do not edit both and hope one is right.

### 18.4 Where this rule is enforced

This check runs inside `bmad-dev-story` as the first action of Phase 1 (investigation), before reading any file content. It also runs in `bmad-quick-dev` before the first `Edit` call. `bmad-code-review` must verify that the PR touches the file the user actually navigates to — if the changed file is not reachable from the app's navigation, the PR is rejected.

> **Origin:** T-007 S1 — all wear UI code was implemented in `facilities/garage/+page.svelte` while the user navigates to `facilities/engineering/+page.svelte`. The files are structurally identical, causing the entire implementation to be invisible until re-applied to the correct file. A 5-second `find` before the first edit would have prevented the full rework.
