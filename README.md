# Unified AI Workspace

A hub-and-spoke workspace that shares context, skills, and history across multiple AI CLI tools (Claude Code, KiloCode, Ralph TUI, Cline, Codex).

---

## Table of Contents

1. [Installation — New Machine Setup](#installation--new-machine-setup)
2. [Quick Start — Daily Workflow](#quick-start--daily-workflow)
3. [How It Works](#how-it-works)
4. [Directory Structure](#directory-structure)
5. [The `aiw` CLI Reference](#the-aiw-cli-reference)
6. [Daily Productivity Prompts](#daily-productivity-prompts)
7. [Choosing the Right Tool + Model](#choosing-the-right-tool--model)
8. [Model Upgrade Guide](#model-upgrade-guide)
9. [Managing Skills](#managing-skills)
10. [Context Management](#context-management)
11. [Chat History, Crash Recovery & Resume](#chat-history-crash-recovery--resume)
12. [Tool Handoffs](#tool-handoffs)
13. [Adding Projects, Tools, Skills](#adding-projects-tools-skills)
14. [Troubleshooting](#troubleshooting)

---

## Installation — New Machine Setup

### Prerequisites

- `git`, `python3` (required)
- AWS CLI v2 configured with Bedrock access (required for KiloCode model routing and `aiw models`)
- One or more AI CLI tools: `claude`, `kilo`, `cline`, `codex` (optional — install whichever you use)

### 1. Clone the repo

```bash
git clone <repo-url> ~/.ai-workspace
```

### 2. Run the setup script

```bash
bash ~/.ai-workspace/bin/aiw-setup
```

This will:
- Detect your environment (WSL, Linux, macOS)
- Create `config.toml` from the included `config.toml.example` template
- Prompt for your machine-specific paths (projects directory, skill sources)
- Create required directories (`sessions/`, `history/`, `output/`, `skills/`)
- Symlink `aiw` into `~/.local/bin/`
- Check for installed tools
- Generate the initial skill catalog

### 3. Add your projects

Edit `~/.ai-workspace/config.toml` and add `[projects.*]` sections for each of your repos:

```toml
[projects.my-project]
path = "/path/to/my-project"
context_overlay = "context/projects/my-project"
description = "Brief description"
tags = ["tag1", "tag2"]
```

### 4. Create context and sync

```bash
mkdir -p ~/.ai-workspace/context/projects/my-project
# Create CONTEXT.md, brief.md, decisions.md (see templates/new-project.md)
aiw sync
```

### 5. AWS Bedrock setup (for KiloCode model routing)

KiloCode models in `config.toml` use AWS Bedrock inference profiles by default (`amazon-bedrock/us.anthropic.claude-*`). This requires:

1. **Install AWS CLI v2** — [docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

2. **Configure credentials** with Bedrock access:
```bash
aws configure
# Or use SSO:
aws configure sso
```

3. **Verify Bedrock access:**
```bash
aws bedrock list-inference-profiles --region us-east-1 --query 'inferenceProfileSummaries[?contains(inferenceProfileId,`claude`)]' --output table
```

4. **Auto-detect latest models:**
```bash
aiw models update
```

**Not using Bedrock?** The model IDs in `config.toml` under `[tools.kilocode.models]` can be changed to any provider format that KiloCode supports (e.g., `anthropic/claude-sonnet-4-latest` for direct Anthropic API, or `openrouter/anthropic/claude-sonnet-4` for OpenRouter). Claude Code uses its own model setting independently — configure it via `/model` inside Claude Code or `~/.claude/settings.json`.

### Manual setup (without the script)

If you prefer to set up manually:

```bash
cp ~/.ai-workspace/config.toml.example ~/.ai-workspace/config.toml
# Edit config.toml — fill in your paths
mkdir -p ~/.ai-workspace/{sessions,history/sessions,history/sources,output,skills}
ln -sf ~/.ai-workspace/bin/aiw ~/.local/bin/aiw
aiw sync
```

### Updating an existing installation

`config.toml` contains your machine-specific paths and is safe to keep across `git pull`. All code files read paths from `config.toml` at runtime — no hardcoded paths in scripts.

---

## Quick Start — Daily Workflow

Your typical day starts like this:

```bash
# 1. Update your brief (what you're working on today)
aiw brief
#    → Editor opens ~/.ai-workspace/context/brief.md
#    → Update "Current Focus" and "Active Goals"
#    → Save and close

# 2. Sync context to all tools
aiw sync

# 3. Launch your tool of choice
aiw start claude n8n-workflows       # Deep architecture work
aiw start kilo-code n8n-workflows    # Feature implementation
aiw start kilo-quick n8n-workflows   # Quick fixes

# 4. Check status anytime
aiw status
```

**That's it.** Edit brief → sync → start tool. Every tool sees the same context.

---

## How It Works

```
                    ┌──────────────────────┐
                    │  ~/.ai-workspace/    │
                    │  context/CONTEXT.md  │  ← You edit these
                    │  context/brief.md    │
                    │  context/stuck.md    │
                    └──────────┬───────────┘
                               │
                         aiw sync
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                   │
     adapters/claude    adapters/kilocode    adapters/cline ...
            │                  │                   │
            ▼                  ▼                   ▼
      CLAUDE.md        .kilocode/rules/      .clinerules
     (per project)     + memory-bank/        (per project)
```

1. **Edit shared context** in `~/.ai-workspace/context/`
2. **Run `aiw sync`** — adapters regenerate tool-specific config files in every project
3. **Each tool reads its native format** — no manual copy-paste between tools

---

## Directory Structure

```
~/.ai-workspace/
├── config.toml           # Tool paths, project definitions, model aliases
├── config.toml.example   # Portable template (copy to config.toml on new machines)
├── README.md             # This file
│
├── context/              # SHARED CONTEXT — source of truth
│   ├── CONTEXT.md        # Stable: who you are, tech stack, conventions
│   ├── brief.md          # Dynamic: what you're working on RIGHT NOW
│   ├── stuck.md          # Active blockers with tracking IDs
│   ├── decisions.md      # Architecture decision log (append-only)
│   └── projects/         # Per-project overlays
│       ├── n8n-workflows/        {CONTEXT.md, brief.md, decisions.md}
│       ├── n8n-agentic-devops/   {CONTEXT.md, brief.md, decisions.md}
│       ├── n8n-devops-automation/{CONTEXT.md, brief.md, decisions.md}
│       └── agentcore-devops-demo/{CONTEXT.md, brief.md, decisions.md}
│
├── skills/               # Skill registry
│   ├── catalog.json      # 434 skills, searchable by tag/name
│   ├── plugins -> ...    # Symlink → Claude plugin skills
│   └── ralph -> ...      # Symlink → Ralph TUI skills
│
├── adapters/             # Per-tool config generators
│   ├── _shared/          # render-context.sh, session-logger.sh, discover-models.sh
│   ├── claude/           # → CLAUDE.md
│   ├── codex/            # → AGENTS.md
│   ├── kilocode/         # → .kilocode/rules/ + memory-bank/
│   ├── cline/            # → .clinerules
│   └── ralph/            # → progress.md
│
├── sessions/             # Session state + handoff templates
├── history/              # Unified history (symlinks to tool histories)
├── output/               # AI-generated files (date-partitioned)
├── templates/            # Templates for new skills/projects/tools
└── bin/
    ├── aiw               # CLI tool
    └── aiw-setup         # New machine bootstrap script
```

---

## The `aiw` CLI Reference

| Command | What It Does |
|---------|-------------|
| `aiw sync` | Regenerate ALL tool configs for ALL projects |
| `aiw sync <project>` | Regenerate configs for one project only |
| `aiw status` | Show active session, brief, projects, skill count |
| `aiw start <tool> [project]` | Sync context, then launch tool in project dir |
| `aiw switch <tool>` | End current session, handoff to another tool |
| `aiw resume [tool]` | Resume last session with context |
| `aiw brief [project]` | Open brief.md in editor (global or per-project) |
| `aiw stuck` | Open stuck.md in editor |
| `aiw skill list` | Show skill counts by source and top tags |
| `aiw skill list --tag=n8n` | List skills matching a tag |
| `aiw skill search <query>` | Search skills by name or description |
| `aiw skill add <path>` | Regenerate catalog (after adding a skill file) |
| `aiw models` | Show current models + variants vs Bedrock latest |
| `aiw models update` | Auto-detect latest models, update config + aliases |
| `aiw models update --dry-run` | Show what would change without writing |
| `aiw models set <role> <id>` | Pin a specific model to a role |
| `aiw models set-variant <role> <val>` | Set reasoning effort (high/max/minimal/default) |
| `aiw models reset` | Reset to auto-detected latest |
| `aiw start auto [project]` | Auto-detect best tool + model and launch |
| `aiw routing` | Show recent auto-routing decisions (last 20) |
| `aiw routing stats` | Show switch frequency per role/tool |
| `aiw routing clear` | Clear routing decision log |
| `aiw history --tool=X --date=Y` | Search session history |
| `aiw cleanup` | Remove old outputs, deduplicate history |
| `aiw help` | Full help text |
| `aiw version` | Show version |

### Tool Names for `aiw start`

| Name | Tool | Model | Cost Tier |
|------|------|-------|-----------|
| `auto` | Auto-detect | Picks best tool + model | varies |
| `claude` | Claude Code | Opus 4.6 (default) | 5 (highest) |
| `kilo-arch` | KiloCode | Opus 4.6 — architecture, design | 4 |
| `kilo-code` | KiloCode | Sonnet 4.5 — implementation | 3 |
| `kilo-review` | KiloCode | Sonnet 4 — code review | 2 |
| `kilo-quick` | KiloCode | Haiku 4.5 — quick fixes | 1 (cheapest) |
| `kilocode` | KiloCode | Default model | 3 |
| `cline` | Cline (VS Code) | Opens VS Code | 3 |
| `codex` | Codex CLI | Default model | 2 |
| `ralph` | Ralph TUI | No LLM | 0 |

### Cross-Tool Auto-Routing

`aiw start auto [project]` picks the best tool across all integrated tools, not just KiloCode roles.

**How it works:**

1. Asks "What are you working on?" (press Enter to skip)
2. Combines your answer with project signals (git state, branch, brief, tags)
3. Scores all 8 tool targets and picks the highest
4. Launches the winning tool with full context sync

**Scoring has two regimes:**
- **With task description:** User intent is dominant; project signals are scaled to tiebreaker weight (÷3). Margin thresholds are halved since the signal quality is high.
- **Without task description (Enter):** Project signals run at full strength, same as the original `auto_detect_role()` behavior. Falls back to `kilo-code` as safe default.

**Margin thresholds** prevent spurious tool switches:
- Claude needs margin ≥ 30 (or ≥ 15 with task description) — it's the most expensive
- Cross-tool (cline/codex/ralph) needs margin ≥ 25 (or ≥ 12 with task description)
- Within-KiloCode switches use existing upgrade/downgrade margins (20/10)

**Mid-session escalation:** The KiloCode per-prompt plugin (`~/.config/kilo/plugin.ts`) continuously classifies each prompt. If a prompt mid-session needs a different tool (e.g., you're in `kilo-code` but ask to "deeply trace through this multi-file codebase"), it can fork to Claude Code, Cline, or Codex.

**Configuration:** `~/.ai-workspace/config.toml`
- `[auto_detect.tool_routing]` — session-start routing (enabled, margins, interactive prompt)
- `[tools.kilocode.auto_routing]` — mid-session plugin routing (cross_tool_enabled, margins)

**Kill switch:** Set `enabled = "false"` in `[auto_detect.tool_routing]` to revert `aiw start auto` to KiloCode-only role detection.

**All tools remain directly accessible** by their original commands (`kilo`, `claude`, `codex`, `code`) — `aiw` adds context sync and session tracking on top.

### Auto-Sync Behavior

Context syncs automatically for most launch methods — no manual `aiw sync` needed:

| Launch Method | Auto-Syncs? | How |
|--------------|-------------|-----|
| `kilo-arch` / `kilo-code` / etc. | Yes | Aliases delegate to `aiw start` |
| `aiw start <tool> <project>` | Yes | Built-in sync before launch |
| `claude` (direct launch) | Yes | SessionStart hook in `~/.claude/settings.json` |
| VS Code sidebar (KiloCode/Cline) | Yes | `.vscode/tasks.json` runs sync on folder open |

**How each works:**
- **Bash aliases** delegate to `aiw start`, which syncs before launching
- **Claude Code** has a `SessionStart` hook in `~/.claude/settings.json` that runs `aiw sync` on new sessions
- **VS Code** has a `.vscode/tasks.json` in each project with `"runOn": "folderOpen"` that runs `aiw sync` when you open the folder

You still need manual `aiw sync` after editing context files mid-session (auto-sync only fires at launch/open).

---

## Daily Productivity Prompts

Copy-paste these into your AI tool at the start of each session for maximum effectiveness.

### Morning Start Prompt
```
Read CLAUDE.md for project context. Then read the active brief to understand
current goals. Summarize: (1) what I'm working on, (2) what's blocked,
(3) what's the next concrete step I should take.
```

### Resume After Break
```
I'm resuming work. Check the brief and stuck.md for current state.
What was I working on, and what's the next action?
```

### Before Starting a Task
```
I want to [describe task]. Before writing any code:
1. Read the relevant files
2. Identify which existing patterns to follow
3. List the files you'll modify
4. Describe your approach in 2-3 sentences
Then wait for my approval before proceeding.
```

### End of Session — Update Brief
```
Summarize what we accomplished this session. Update the project brief with:
- What changed
- What's pending
- Any new blockers
Write the update to ~/.ai-workspace/context/projects/<project>/brief.md
```

### When Stuck
```
I'm stuck on [describe problem].
1. List 3 different approaches to solve this
2. For each, describe the trade-off (speed vs reliability vs complexity)
3. Recommend one and explain why
```

### Code Review Prompt
```
Review the changes in this project. Check for:
- Security issues (OWASP top 10)
- n8n expression syntax errors
- Hardcoded values that should be in config nodes
- Missing error handling
- Broken audit chain (3-layer system)
```

### Workflow Debugging Prompt
```
This n8n workflow is failing. Help me debug:
1. Read the workflow JSON
2. Trace the execution path
3. Identify where data gets lost or transformed incorrectly
4. Suggest a fix with the exact node changes needed
```

### Architecture Decision Prompt
```
I need to decide [describe decision].
Document this as an architecture decision:
- Decision: what we chose
- Reason: why
- Impact: what changes
Append to ~/.ai-workspace/context/decisions.md
```

---

## Choosing the Right Tool + Model

### When to Use Each Tool

| Situation | Tool | Command |
|-----------|------|---------|
| **Complex multi-file changes** | Claude Code (Opus) | `aiw start claude` |
| **Architecture design & review** | KiloCode (Opus) | `aiw start kilo-arch` |
| **Feature implementation** | KiloCode (Sonnet 4.5) | `aiw start kilo-code` |
| **Quick edits, small fixes** | KiloCode (Haiku) | `aiw start kilo-quick` |
| **Code review** | KiloCode (Sonnet 4) | `aiw start kilo-review` |
| **VS Code integrated editing** | Cline | `aiw start cline` |
| **Task orchestration (PRDs)** | Ralph TUI | `aiw start ralph` |
| **CLI code generation** | Codex | `aiw start codex` |

### Model Selection Guide

| Model | Strengths | Cost | Speed | Use For |
|-------|-----------|------|-------|---------|
| **Opus 4.6** | Reasoning, architecture, complex code | $$$$ | Slow | Design decisions, multi-file refactors, debugging hard bugs |
| **Sonnet 4.5** | Balanced intelligence + speed | $$$ | Medium | Feature implementation, workflow building, moderate complexity |
| **Sonnet 4** | Good for analysis | $$ | Medium | Code review, validation, PR review |
| **Haiku 4.5** | Fast, cheap, good enough | $ | Fast | Typo fixes, simple edits, quick questions, boilerplate |

### Decision Flowchart

```
Is this a 1-line fix? ──Yes──→ kilo-quick (Haiku)
        │ No
Does it need deep reasoning? ──Yes──→ claude or kilo-arch (Opus)
        │ No
Is it code review? ──Yes──→ kilo-review (Sonnet 4)
        │ No
Default → kilo-code (Sonnet 4.5)
```

---

## Model Upgrade Guide

When Anthropic releases new models, one command updates everything:

```bash
aiw models update
```

This queries AWS Bedrock for the latest active Claude inference profiles, ranks them by version, and updates `config.toml`. The `.bashrc` aliases delegate to `aiw start`, which reads models from config at runtime — no need to `source ~/.bashrc` after model changes.

### How Auto-Detection Works

| Role | Selection Rule |
|------|---------------|
| `arch` | Newest Opus (highest version) |
| `code` | Newest Sonnet (highest version) |
| `quick` | Newest Haiku (highest version) |
| `review` | Second-newest Sonnet (cost-efficient for review) |

The `aiw` script reads model IDs from `config.toml` at runtime — no hardcoded IDs in the script itself.

### Model Management Commands

```bash
aiw models                  # Show current models + variants vs Bedrock latest
aiw models update           # Auto-detect and update config + aliases
aiw models update --dry-run # Preview changes without writing
aiw models set arch <id>    # Manually pin a model to a role
aiw models set-variant <role> <val>  # Set reasoning effort (high/max/minimal/default)
aiw models reset            # Remove pins, re-run auto-detection
```

### Reasoning Effort (Variants)

Each role has a configurable `--variant` that controls reasoning effort:

| Role | Default | Effect |
|------|---------|--------|
| `arch` | `high` | Deep reasoning for architecture |
| `code` | (default) | Balanced for implementation |
| `quick` | `minimal` | Fast responses, skip extended thinking |
| `review` | (default) | Standard for code reviews |

Variants are stored in `config.toml` under `[tools.kilocode.variants]` and read by `aiw start` at runtime.

```bash
aiw models set-variant arch max       # Maximum reasoning for architecture
aiw models set-variant quick default  # Remove minimal, use provider default
```

> **Note:** `--variant` currently works with `kilo run` (one-shot). The TUI will pass it when KiloCode adds support.

### Manual Overrides

To pin a specific model (e.g., keep an older Sonnet for review):
```bash
aiw models set review "amazon-bedrock/us.anthropic.claude-sonnet-4-20250514-v1:0"
```

To undo a pin and go back to auto-detection:
```bash
aiw models reset
```

### Update Claude Code Default

```bash
# Claude Code reads its model from settings
# Change via the /model command inside Claude Code
# Or edit ~/.claude/settings.json
```

### Verify After Update

```bash
aiw models              # Should show all ✓ up-to-date
aiw start kilo-code n8n-workflows  # Verify correct model launches
```

### Speed Tips

- **Use Haiku for everything that doesn't need deep reasoning** — it's 10x cheaper and 3x faster
- **Use `/fast` in Claude Code** to enable faster output (same Opus model, optimized)
- **Keep briefs short** — long context = slower responses. Aim for <50 lines per brief
- **Use project-specific briefs** instead of cramming everything into the global brief
- **Split large tasks** — give the AI one focused job at a time instead of everything at once

---

## Managing Skills

### View Your Skills

```bash
aiw skill list                    # Summary: counts by source, top tags
aiw skill list --tag=n8n          # Filter by tag
aiw skill list --tag=pdi          # Filter by tag
aiw skill search "salesforce"     # Search by name or description
aiw skill search "workflow"       # Search by keyword
```

### Skill Sources (Where Skills Live)

| Source | Location | Count | Managed By |
|--------|----------|-------|------------|
| Claude Plugin | `~/.claude/skills/.claude-plugin/` | 354 | Plugin system |
| Ralph TUI | `~/.agents/skills/` | 4 | Manual |
| Project-level | `n8n-workflows/.claude/skills/` | 8 | Per-project |

### Create a New Skill

1. **Create the skill file** in the appropriate location:

```bash
# For a Claude plugin skill:
mkdir -p ~/.claude/skills/.claude-plugin/pdi-my-category/skills/my-skill
cat > ~/.claude/skills/.claude-plugin/pdi-my-category/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill-name
description: >
  One paragraph describing when this skill triggers.
  Include specific phrases users might say.
---

# My Skill Name

## When to Use
Describe trigger scenarios.

## Instructions
Step-by-step guidance for the AI.

## Examples
Concrete input/output examples.
EOF
```

2. **Regenerate the catalog**:
```bash
aiw sync    # or: python3 ~/.ai-workspace/skills/generate-catalog.py
```

3. **Verify**:
```bash
aiw skill search "my-skill"
```

### Upgrade / Edit an Existing Skill

1. Find the skill file:
```bash
aiw skill search "skill-name"
# Note the path in the output
```

2. Edit the file directly at that path

3. Regenerate:
```bash
aiw sync
```

### Skill Best Practices

- **Description is everything** — it determines when the skill activates
- **Include trigger phrases** like "Use when the user says..."
- **Keep skills focused** — one skill per domain concern
- **Add concrete examples** — AI tools learn patterns from examples
- **Use tags via directory naming** — `pdi-n8n/` auto-tags as `n8n, pdi`

### Remove Duplicate Skills

```bash
# Skills are in ~/.claude/skills/.claude-plugin/
# Duplicates were previously cleaned (73 removed)
# Check for new duplicates:
find ~/.claude/skills/.claude-plugin -name "SKILL.md" | \
  xargs -I{} sh -c 'head -5 "{}" | grep "name:"' | sort | uniq -d
```

---

## Context Management

### What Goes Where

| File | What to Put Here | Update Frequency |
|------|-----------------|------------------|
| `context/CONTEXT.md` | Environment, tech stack, global conventions, tool preferences | Rarely (when stack changes) |
| `context/brief.md` | What you're working on RIGHT NOW, active goals, recent completions | Daily or per-session |
| `context/stuck.md` | Active blockers with tracking IDs | When blocked/unblocked |
| `context/decisions.md` | Architecture decisions with rationale | When making significant choices |
| `context/projects/<name>/CONTEXT.md` | Project architecture, patterns, schemas | When project architecture changes |
| `context/projects/<name>/brief.md` | Project-specific current work | Daily or per-session |
| `context/projects/<name>/decisions.md` | Project-specific decisions, solved problems | When solving hard problems |

### Writing an Effective Brief

A good brief gives the AI tool everything it needs to help you immediately:

```markdown
# Active Brief — n8n-workflows

## Current Focus
**Dashboard email threading fix** — Reply emails not grouping
correctly in Salesforce case feed.

## Active Goals
1. Fix email threading using relatedRecordId field
2. Test with 5 sample cases in dev environment
3. Deploy to production after verification

## What Changed Recently
- Switched from HTTP Request to native Salesforce node (OAuth fix)
- Updated approval state machine to separate approval from execution

## Pending
- [ ] DataTables migration (paused)
- [ ] Cost tracking workflow (not started)
```

**Keep it under 50 lines.** Long briefs slow down AI responses.

### The Brief → Sync → Work Cycle

```bash
# Morning: update what you're doing today
aiw brief n8n-workflows
# → Edit, save, close

# Sync to all tools
aiw sync

# Work in your tool
aiw start kilo-code n8n-workflows

# End of day: update what you accomplished
aiw brief n8n-workflows
# → Update "What Changed Recently", move completed items
# → Save, close

# Sync (so tomorrow any tool picks up where you left off)
aiw sync
```

---

## Chat History, Crash Recovery & Resume

### Is My Chat History Safe?

**Yes.** Each AI tool saves conversation history automatically, per-message, as it happens. The workspace does NOT control this — the tools do it natively.

| Tool | History Location | Format | Auto-saved? |
|------|-----------------|--------|-------------|
| Claude Code | `~/.claude/projects/-mnt-c-Users-ashok-palle/*.jsonl` | JSONL (one line per message) | Yes, per-message |
| KiloCode | `~/.local/state/kilo/prompt-history.jsonl` | JSONL | Yes, per-message |
| Codex | `~/.codex/history.jsonl` | JSONL | Yes, per-message |
| Cline | VS Code extension storage | Internal | Yes |
| Ralph TUI | Bead/task state files | JSON | Yes |

All history files are also symlinked into `~/.ai-workspace/history/sources/` for unified access.

### What Survives Crashes?

| Scenario | Chat History | Session Metadata | Brief/Context |
|----------|-------------|-----------------|---------------|
| Normal exit (Ctrl+C, `/exit`) | Saved | Archived cleanly | Whatever you last wrote |
| App hangs / frozen | Saved (except last in-flight response) | Recovered on next `aiw start` | Safe |
| Power off / crash | Saved (except last in-flight response) | Recovered on next `aiw start` | Safe |
| Terminal closed accidentally | Saved | Recovered (signal trap catches SIGHUP) | Safe |
| WSL restarts | Saved | Recovered on next `aiw start` | Safe (files on Windows `/mnt/c/`) |
| Machine reboot | Saved | Recovered on next `aiw start` | Safe |

**Key point:** JSONL files are append-only. Each message is written as it completes. A crash loses at most the in-flight response — all previous messages survive.

### Crash Recovery — How It Works

When you use `aiw start`, three protections activate:

1. **Signal traps** — catches Ctrl+C (`SIGINT`), terminal close (`SIGHUP`), and kill (`SIGTERM`) to properly archive the session before exiting
2. **Stale session detection** — if a previous session wasn't closed cleanly (crash, power off), `aiw start` detects it, archives it, and starts fresh
3. **Append-only history** — tool history files survive any interruption because they write line-by-line, not as a single file

### How to Resume After Any Interruption

**After a crash, power off, hang, or any unclean exit:**

```bash
# Option 1: Smart resume (shows last session info + brief + history)
aiw resume
# → Shows: what you were working on, current brief, blockers
# → Launches your default tool with synced context
# → Gives you a paste-ready prompt to pick up where you left off

# Option 2: Resume with a specific tool
aiw resume kilo-code
# → Same as above, but launches KiloCode instead of default

# Option 3: Manual start (if you know what you want)
aiw start claude n8n-workflows
# → Auto-detects and archives any stale session
# → Syncs context, launches tool
```

### What `aiw resume` Shows You

```
Resume Context

  Last session: claude on n8n-workflows (2026-02-12T13:10:47)

Project Brief:
  Production system is live and operational...
  Active Goals: maintain stability, dashboard improvements...

Active Blockers:
  (none)

Recent Tool History:
  (last 3 entries from the tool's native history)

Paste this into the tool to resume:

  I'm resuming work on n8n-workflows. Read CLAUDE.md for full context.
  Check the project brief for current goals. Pick up where we left off.
```

### The Brief Is Your Safety Net

Chat history tells you *what was said*. The brief tells you *what matters*.

**Best practice: update the brief before stopping work.** Then even after a crash, any tool can pick up exactly where you left off.

```bash
# End of session (or before stepping away):
aiw brief n8n-workflows
# → Update "Current Focus" with what you're mid-way through
# → Move completed items to "Recently Completed"
# → Note any gotchas or context the next session needs

aiw sync
# → Now every tool has your latest state
```

### What You Lose in a Crash

| Lost | Not Lost | How to Recover |
|------|----------|---------------|
| The AI's in-flight response (the one being generated when crash happened) | All previous messages | Re-ask the question |
| Unsaved brief edits (if editor was open) | The last saved version of brief.md | Re-edit with `aiw brief` |
| Session metadata timing (exact end time) | Session start time + tool + project | `aiw start` recovers this |

**Nothing critical is lost.** The worst case is re-asking one question.

---

## Tool Handoffs

### Switching Between Tools

```bash
# Start with Claude for architecture
aiw start claude n8n-workflows
# ... design the approach, get the plan ...
# Ctrl+C to exit

# Switch to KiloCode for implementation
aiw start kilo-code n8n-workflows
# ... implement the feature ...
# Ctrl+C to exit

# Quick fix with Haiku
aiw start kilo-quick n8n-workflows
```

### Pull Context Back from KiloCode

If KiloCode updated its memory bank during a session, pull changes back:

```bash
bash ~/.ai-workspace/adapters/kilocode/sync-memory-bank.sh n8n-workflows --pull
aiw sync   # Propagate to all other tools
```

---

## Adding Projects, Tools, Skills

### Add a New Project

```bash
# 1. Add to config
#    Edit ~/.ai-workspace/config.toml, add:
#    [projects.my-project]
#    path = "/path/to/my-project"
#    context_overlay = "context/projects/my-project"
#    description = "What this project does"
#    tags = ["tag1", "tag2"]

# 2. Create context files
mkdir -p ~/.ai-workspace/context/projects/my-project
# Create CONTEXT.md, brief.md, decisions.md (see templates/new-project.md)

# 3. Sync
aiw sync my-project
```

### Add a New AI Tool

See `~/.ai-workspace/templates/new-tool.md` for the step-by-step guide. Summary:
1. Add `[tools.<name>]` to config.toml
2. Create `adapters/<name>/generate.sh`
3. Update `aiw` CLI's sync and start commands
4. `aiw sync`

### Add a New Skill

See `~/.ai-workspace/templates/new-skill.md`. Summary:
1. Create the markdown file in the appropriate skills directory
2. `aiw sync` to regenerate the catalog
3. `aiw skill search "name"` to verify

---

## Troubleshooting

### `aiw sync` fails with errors
```bash
# Most common cause: Windows line endings
find ~/.ai-workspace -type f -name "*.sh" -exec sed -i 's/\r$//' {} +
aiw sync
```

### Tool doesn't see updated context
```bash
# Ensure you ran sync AFTER editing
aiw sync
# Verify the generated file
cat /path/to/project/CLAUDE.md | head -5
# Should show: "Auto-generated by aiw sync"
```

### KiloCode memory bank out of sync
```bash
# Push workspace → memory bank
bash ~/.ai-workspace/adapters/kilocode/sync-memory-bank.sh n8n-workflows --push

# Pull memory bank → workspace
bash ~/.ai-workspace/adapters/kilocode/sync-memory-bank.sh n8n-workflows --pull
```

### Skill not showing in catalog
```bash
# Regenerate catalog
python3 ~/.ai-workspace/skills/generate-catalog.py
aiw skill search "name"
```

### `aiw start` doesn't launch the tool
```bash
# Check the tool is installed and on PATH
which claude
which kilocode
which codex

# Check the project path exists
ls /path/to/<project>
```

### History is empty
The unified history index populates when you use `aiw start` to launch tools.
If you launch tools directly (not via `aiw`), raw history is still in:
- Claude: `~/.ai-workspace/history/sources/claude.jsonl`
- KiloCode: `~/.ai-workspace/history/sources/kilo.jsonl`
- Codex: `~/.ai-workspace/history/sources/codex.jsonl`

---

## File Discipline

| Category | Location | Persistence |
|----------|----------|-------------|
| Source code | Project directories | Permanent, git-tracked |
| Shared context | `.ai-workspace/context/` | Semi-permanent, you maintain |
| Tool configs | Project root (CLAUDE.md, etc.) | **Generated** — never edit directly |
| Skills | Canonical sources (plugin dirs) | Permanent |
| History | `.ai-workspace/history/` | Append-only |
| AI outputs | `.ai-workspace/output/` | Auto-cleaned after 30 days |

**Golden rule:** Never edit CLAUDE.md, AGENTS.md, .clinerules, or .kilocode/rules directly.
Edit the shared context in `~/.ai-workspace/context/`, then `aiw sync`.
