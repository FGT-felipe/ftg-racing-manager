# Audit — CLAUDE.md Violations

Run a full audit of the frontend codebase for violations of the development rules defined in CLAUDE.md. Check all of the following:

## 1. Direct Firestore in .svelte files
Search for `doc(`, `getDoc(`, `setDoc(`, `updateDoc(`, `addDoc(`, `collection(`, `onSnapshot(` in any `*.svelte` file under `frontend/src/routes/` and `frontend/src/lib/components/`. Report every match with file path and line number.

## 2. alert() / confirm() / prompt() calls
Search for `alert(`, `confirm(`, `prompt(` in any `.svelte` or `.svelte.ts` file. These are prohibited per §3.5.

## 3. Hardcoded monetary values / business constants
Search for numeric literals that look like fees, costs, or thresholds (e.g. `10_000`, `10000`, `500000`, `15000`) in `.svelte` and `.svelte.ts` files. Cross-reference with `frontend/src/lib/constants/economics.ts` — flag any value not already centralized.

## 4. Inline styles / raw hex colors
Search for `style="` and hex color patterns (`#[0-9a-fA-F]{3,6}`) in `.svelte` files. Flag any that aren't using CSS variables.

## 5. Missing i18n
Search for user-facing string literals (quoted strings in component markup that aren't i18n keys) in `.svelte` files. Flag anything that should go through `t()`.

## Output format
For each category, report:
- ✅ Clean — if no violations found
- ⚠️ N violations — list each as `file:line → snippet`

End with a summary count and recommended action.
