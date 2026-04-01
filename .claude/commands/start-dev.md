# Start Dev — Kickoff for any fix or feature

Entry point for all development work. Accepts a task ID from ROADMAP.md.

Example: `/start-dev T-003`

---

## Step 1 — Load task context

Read `ROADMAP.md` and find the task by ID. Extract:
- Type: **fix** (from Fixes section) or **feature** (from Features table)
- Priority (U/H/N/L)
- Complexity points (features only)
- Description and existing notes

Show a one-line summary: `[T-XXX | Fix/Feature | Priority] Title`

---

## Step 2 — Read mandatory docs

Always read:
- `frontend/src/routes/admin/docs/ai/standards.md`
- `frontend/src/routes/admin/docs/ai/architecture.md`
- `frontend/src/routes/admin/docs/ai/services.md`
- `frontend/src/routes/admin/docs/ai/database_schema.md`

If the task touches Cloud Functions, race simulation, or scheduled jobs, also read:
- `frontend/src/routes/admin/docs/ai/weekend_pipeline.md`
- `functions/postmortem_r2.md` / `functions/postmortem_r3.md` (if modifying `functions/index.js`)

---

## Step 3 — Initial analysis

Before asking questions, do a quick scan of the relevant codebase areas:
- Find files most likely affected (services, stores, components, CF functions)
- Identify what already exists vs. what needs to be built from scratch
- Flag any risks or constraints found in docs or code (transactions, CF strict mode, state machine, etc.)

Do NOT write any code yet.

---

## Step 4 — Ask product and technical questions

Based on your analysis, ask the user the questions that need answers before planning can begin. Separate them into two groups:

**Producto** — scope, UX decisions, business rules, edge cases the user must define.
**Técnicas** — implementation choices where more than one valid approach exists and the decision affects architecture.

Keep questions concise and numbered. Do not ask about things you can already determine from the docs or the existing code.

Wait for the user's answers before proceeding.

---

## Step 5 — Propose branch name

Following CLAUDE.md §9.1:
- New user-facing feature → `feature/v<next-minor>-<slug>`
- Bug fix or tech task → `fix/v<next-patch>-<slug>` or `chore/v<next-patch>-<slug>`
- Urgent production fix → `hotfix/<slug>`

Show the next logical version based on current `APP_VERSION` in `app_constants.ts`.

---

## Step 6 — Present the work plan

Write a structured plan covering:

1. **Firestore schema** — new fields, collections, or index changes required
2. **Services / Stores** — what to create, what to extend, public method signatures
3. **Cloud Functions** — new or modified functions, strict-mode risks to watch
4. **UI components** — new components, routes, or modifications to existing ones
5. **i18n** — list of new key groups needed (en + es)
6. **Constants** — new business values to centralize
7. **Tests** — Vitest unit tests required for new deterministic logic
8. **Docs to update** — which `ai/*.md` files need updating after the work

Present the plan clearly and tell the user:
> "Revisá el plan. Cuando lo apruebes (o me indiques ajustes), creo la rama y arrancamos."

Do NOT create the branch or write any code until the user explicitly approves.

---

## Step 7 — On approval

Once the user approves (with or without adjustments):
1. Create the branch: `git checkout -b <branch-name>`
2. Confirm the branch was created
3. Begin implementation following the approved plan, task by task
4. Mark each sub-task complete as you go
