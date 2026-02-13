# Template: Adding a New Project

## Steps

### 1. Add to config.toml

```toml
[projects.my-project]
path = "/mnt/c/Users/ashok.palle/my-project"
context_overlay = "context/projects/my-project"
description = "Brief description of the project"
tags = ["tag1", "tag2"]
```

### 2. Create Context Overlay

```bash
mkdir -p ~/.ai-workspace/context/projects/my-project
```

Create three files:

#### CONTEXT.md — Stable project context
```markdown
# Project Context — my-project

## Architecture
Describe the system architecture, components, and how they interact.

## Technology Stack
List frameworks, databases, cloud services.

## Key Patterns
Document important patterns and conventions specific to this project.

## File Layout
```
my-project/
├── src/
├── config/
└── ...
```
```

#### brief.md — Current work status
```markdown
# Active Brief — my-project

## Current Status
What state is the project in?

## Active Goals
1. Goal one
2. Goal two

## Pending Work
- [ ] Task one
- [ ] Task two
```

#### decisions.md — Architecture decision log
```markdown
# Decision History — my-project

_No decisions recorded yet._
```

### 3. Sync

```bash
aiw sync my-project
```

This generates CLAUDE.md, AGENTS.md, .clinerules, and .kilocode/rules/ in the project directory.

### 4. Verify

```bash
# Check the generated files
ls my-project/CLAUDE.md my-project/AGENTS.md my-project/.clinerules
cat my-project/CLAUDE.md | head -20
```

## Optional: Add to .gitignore

If the project is git-tracked, add generated files to .gitignore:

```
CLAUDE.md
AGENTS.md
.clinerules
.kilocode/
progress.md
```
