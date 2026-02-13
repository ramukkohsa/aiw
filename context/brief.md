# Active Brief — Global

> What am I working on right now? Update this file, then run `aiw sync`.

## Current Focus

**Unified AI Workspace** — Building hub-and-spoke workspace (`.ai-workspace/`) to share context, skills, and history across Claude Code, KiloCode, Ralph TUI, Cline, and Codex.

## Active Goals

1. **n8n-workflows stability** — production system live, all 7 child provisioners operational
2. **Dashboard improvements** — real-time audit dashboard with resolution tracking
3. **DataTables migration** — transitioning from basic table nodes to DataTables nodes

## Blockers

See `stuck.md` for active blockers.

## Recently Completed

### 2026-02-12 — Auto-Sync Everywhere + Skill Upgrades

- **Claude Code SessionStart hook** — `~/.claude/settings.json` now runs `aiw sync` on every new `claude` session (startup event)
- **VS Code auto-sync** — `.vscode/tasks.json` added to all 4 projects with `runOn: folderOpen` — KiloCode/Cline in VS Code sidebar now auto-sync
- **`.bashrc` aliases simplified** — changed from `kilocode --model X --variant Y` to `aiw start kilo-*` (static aliases, model read from config at runtime)
- **All launch methods now auto-sync** — terminal aliases, `aiw start`, `claude` direct, and VS Code folder open
- **Skill upgrades (366 → 434 skills)** — installed from PDI ADO repo (pdi-claude + pdi-development-tools updates), 5 generic plugins (architecture, security, troubleshooting, deployment, code-analysis), 3 Anthropic official skills (mcp-builder, pdf, xlsx)
- **Skill marketplace URLs** saved to `config.toml` `[skills.marketplaces]` for future reference
- **All 3 docs updated** — README, AIW-Documentation.md, AIW-Commands-and-Prompts.md

### 2026-02-12 — Dynamic Model Discovery + Variant Support

- **`aiw models` command** — queries AWS Bedrock for latest Claude inference profiles, compares against config, shows table with model + variant + status
- **`aiw models update`** — auto-detects latest models per role (arch/code/quick/review), updates `config.toml`
- **`aiw models set <role> <id>`** — manual model pin per role
- **`aiw models set-variant <role> <val>`** — set reasoning effort per role (high/max/minimal/default)
- **`aiw models reset`** — re-run auto-detection
- **`discover-models.sh`** — new Python-based script at `adapters/_shared/` that ranks Bedrock profiles by family and version
- **`cmd_start()` refactored** — reads model + variant from `config.toml` at runtime (no more hardcoded IDs in the script)
- **`config.toml`** is now the single source of truth: `[tools.kilocode.models]` + `[tools.kilocode.variants]`

### Earlier

- Cleaned 73 duplicate skills from user-level Claude skills
- Set up Ralph TUI PRD/beads skills
- Configured KiloCode memory bank for n8n-workflows
- Completed `.ai-workspace` setup — directory structure, adapters, CLI tool
