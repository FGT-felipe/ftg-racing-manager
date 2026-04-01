# Backlog — Show & Manage Roadmap

Read `ROADMAP.md` (at the repo root — it's gitignored, local only) and display the current state of the backlog.

If the user provides an argument after `/backlog`, handle these sub-commands:

---

## `/backlog add "<description>" [priority]`

Add a new item to the **Fixes / Backlog técnico** section of ROADMAP.md.

**Before writing:**
1. Scan ALL of ROADMAP.md for every occurrence of `T-\d+` (in both the Features table and the Fixes section).
2. Find the highest numeric value — the new item gets `T-{max+1}` (zero-padded to 3 digits, e.g. `T-010`).
3. If a priority is provided as a second argument (`U`, `H`, `N`, or `L`), use it. Otherwise default to `N`.

**Format to append** (before the closing `---` of the Fixes section):
```
- [ ] **T-XXX [P]** Description (YYYY-MM-DD)
```

**Example:**
```
/backlog add "Driver card shows wrong nationality flag when team changes country" H
```
→ Scans ROADMAP, finds T-009 is the max → appends:
```
- [ ] **T-010 [H]** Driver card shows wrong nationality flag when team changes country (2026-03-25)
```

**Priority scale:** U=Urgente · H=Alta · N=Normal · L=Low

---

## `/backlog feature "<description>"`

Add a new item to the **Backlog — Features** table. Before adding:
1. Scan ROADMAP.md for the highest `T-\d+` across both sections — assign `T-{max+1}`.
2. Estimate complexity points (3/5/8/13) based on what's already in the codebase.
3. Write a brief note explaining the estimate.
4. Insert the row in the correct position (sorted by points, ascending).

---

## `/backlog` (no argument)

Display the full roadmap in a readable format, highlighting:
- Items in **En progreso**
- Items in **Fixes** that are unresolved (unchecked)
- Next recommended feature to tackle (lowest pts in Backlog)
