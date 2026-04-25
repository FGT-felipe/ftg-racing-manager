# Backlog — DEPRECATED

⚠️ **This skill is deprecated as of v1.7.7.**

Task management now uses **Shortcut (MCP)** exclusively. Use the following Shortcut MCP commands instead:

- **View active work:** `mcp__shortcut__iterations-get-active`
- **Create a story:** `mcp__shortcut__stories-create`
- **Update a story:** `mcp__shortcut__stories-update`
- **Search stories:** `mcp__shortcut__stories-search`

For roadmap tracking (local development notes), edit `ROADMAP.md` directly — it remains a local gitignored document for sprint planning and post-mortem notes.

---

## Historical reference (deprecated, do not use)

The old `/backlog` subcommands have been superseded by the Shortcut API:

- **`/backlog add`** → Use `mcp__shortcut__stories-create`
- **`/backlog feature`** → Use `mcp__shortcut__stories-create` with type=`feature`
- **`/backlog`** → Use `mcp__shortcut__stories-search` with filters (status, team, etc.)
