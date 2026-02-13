# Project Context — n8n-workflows

## Architecture

Production-grade DevOps automation platform built on **n8n** with a parent-child workflow pattern. AI-powered case routing using Claude processes Salesforce DevOps cases and delegates to 7 specialized child workflows for tool provisioning.

### Core Components

| Component | Purpose |
|-----------|---------|
| `DevOps-Cases-parent.json` | AI Router — receives Salesforce cases, classifies via Claude, routes to child workflows |
| `Manager-Approval-Checker.json` | Scheduler — runs every 30 min, checks email approvals, executes approved cases (max 3 retries) |
| 7 Child Provisioners | Tool-specific access management (ADO, GitHub, JIRA, Bitbucket, Jenkins, JFrog, Okta, Arnica) |
| 3-Layer Audit System | Layer 1: Audit-Logger (child calls), Layer 2: Global Error Handler (auto-capture), Layer 3: Execution Poller (15 min backup) |
| Dashboard & Reports | Real-time HTML dashboard, weekly/EOD email reports, Salesforce cache |

### Directory Layout

```
n8n-workflows/
├── .claude/commands/       → 5 custom agent commands (mcp-builder, python-dev, aws-deploy, skill-creator, full-stack-dev)
├── .claude/skills/         → 6 skill sets (AWS, Python, MCP, n8n, Claude skill creator)
├── azure-workflows/        → Azure DevOps license cleanup (2 workflows)
├── github-workflows/       → GitHub user audit & Copilot cleanup (2 workflows)
├── jenkins-workflows-deploy/ → Jenkinsfile for n8n deployment
└── parent-child/           → Main production system
    ├── .claude/            → Workflow-level context
    ├── audit-dashboard/    → Dashboard, reports, cache workflows (9 files)
    ├── migrations/         → SQL schema migrations
    ├── test-flows-for-db/  → DB test utilities
    └── *.json              → 14 core workflow files
```

## Technology Stack

- **n8n** v1.0+ — Workflow automation engine
- **PostgreSQL** (AWS RDS) — Audit database with 11 tables
- **Claude AI** — Case routing (parent) + error analysis (Haiku)
- **AWS**: SES (email), ECS, Lambda, CloudFront
- **Integrations**: Azure DevOps, GitHub, JIRA, Bitbucket, Jenkins, JFrog, Okta, Arnica, Salesforce, Microsoft Teams

## Key Patterns

### Approval State Machine
```
approval_status:  pending → done
approval_result:  approved | rejected | timeout
execution_status: not_started → in_progress → success | failed | exhausted
```
Retry up to 3 times on failure. Separate approval tracking from execution tracking.

### Data Retention
- **Live table** (`approval_queue`): Last 90 days + all pending
- **Archive table** (`approval_queue_archive`): Completed cases >90 days
- **UNION view** (`approval_queue_all`): All dashboards/reports query this

### Error Handling — 3-Layer Audit
1. Child workflow calls Audit-Logger on completion
2. Global Error Handler catches failures automatically
3. Execution Poller (15 min) catches anything missed

## Database Schema (PostgreSQL)

Key tables: `approval_queue`, `approval_queue_archive`, `workflow_executions`, `agent_state`, `agent_memory`, `agent_goals`, `agent_plans`, `agent_results`

Key view: `approval_queue_all` (UNION of live + archive)

## Workflow IDs (Quick Reference)

| Workflow | n8n ID |
|----------|--------|
| DevOps-Cases-parent | `aU9gcymbsKQfHLOv` |
| Manager-Approval-Checker | `3ueBprSimpEqQo3D` |

Full ID list in `parent-child/SYSTEM-DOCUMENTATION.md`.
