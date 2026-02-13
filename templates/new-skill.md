# Template: Creating a New Skill

## Steps

### 1. Choose a Location

| Type | Location | When to Use |
|------|----------|-------------|
| Claude Plugin | `~/.claude/skills/.claude-plugin/<category>/` | Shared across all projects |
| Ralph TUI | `~/.agents/skills/<skill-name>/SKILL.md` | Ralph-specific task skills |
| Project-level | `<project>/.claude/skills/<skill-name>/SKILL.md` | Project-specific skills |

### 2. Create the Skill File

Create a markdown file with frontmatter:

```markdown
---
name: my-skill-name
description: >
  One paragraph describing when this skill triggers and what it does.
  Include specific trigger words users might say.
---

# Skill Name

## When to Use

Describe the scenarios where this skill should activate.

## Instructions

Step-by-step instructions for the AI tool.

## Examples

Include concrete examples of input/output.
```

### 3. Register in Catalog

```bash
# Regenerate the skill catalog to include the new skill
aiw sync
# Or specifically:
python3 ~/.ai-workspace/skills/generate-catalog.py
```

### 4. Verify Discovery

```bash
# Search for your new skill
aiw skill search "my-skill-name"
```

## Best Practices

- **Description is critical** — it determines when the skill triggers
- **Include trigger words** in the description (e.g., "Use when the user says...")
- **Keep skills focused** — one skill per domain concern
- **Add examples** — concrete input/output pairs help AI tools understand intent
- **Tag appropriately** — use directory structure to auto-tag (e.g., `pdi-n8n/` → tags: n8n, pdi)
