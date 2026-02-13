# Shared Context — Ashok Palle DevOps Workspace

> This file is tool-agnostic. It is read by all AI tools via their adapters.
> Edit this file directly — run `aiw sync` to propagate changes.

## Who Am I Working With

Ashok Palle — DevOps engineer building automation platforms on n8n, AWS, and AI agent frameworks. Works in WSL2 on Windows, uses AWS Bedrock for AI model access.

## Environment

| Component | Detail |
|-----------|--------|
| OS | Windows 11 + WSL2 (Ubuntu) |
| AI Models | AWS Bedrock — Claude Opus 4.6, Sonnet 4.5, Sonnet 4, Haiku 4.5 |
| AI Tools | Claude Code, KiloCode, Ralph TUI, Cline, Codex |
| Runtime | Node.js 22, Python 3.10+, Docker |
| Cloud | AWS (Bedrock, SES, ECS, Lambda, RDS, CloudFront, S3) |
| Integrations | Azure DevOps, GitHub, JIRA, Bitbucket, Jenkins, JFrog, Okta, Arnica, Salesforce, Microsoft Teams |

## Projects

### n8n-workflows (Primary)
Production-grade DevOps automation platform. Parent-child workflow pattern where an AI router (Claude) classifies Salesforce DevOps cases and delegates to 7 specialized child workflows for tool provisioning. Includes 3-layer audit system, approval state machine, real-time dashboard, and scheduled reports.

### n8n-agentic-devops
Multi-agent architecture with 7 specialized agents coordinating through Redis pub/sub and PostgreSQL shared state. Agents: Master Orchestrator, Perception, Planning, Action, Memory, Learning, Communication.

### n8n-devops-automation
Infrastructure monitoring with full observability stack — n8n + PostgreSQL + Redis + Grafana + Prometheus via Docker Compose.

### agentcore-devops-demo
AWS Bedrock AgentCore Python demo for deploying AI agents as managed services. Uses Strands SDK for agent logic and agentcore CLI for deployment.

## Global Conventions

### Code Style
- n8n expressions: `{{ }}` syntax with `$json`, `$node`, `$input` variables
- Node types: `nodes-base.<name>`, `nodes-langchain.<name>`
- SQL: snake_case for tables, columns, views
- Python: Ruff formatting, Pyright strict typing, UV package manager
- Workflow JSON: descriptive hyphenated names; `VALID_` prefix = production-ready

### Architecture Principles
- **Configuration Node Pattern**: No hardcoded URLs/credentials in workflow nodes — use config nodes
- **Parent-Child Contract**: Standardized input/output between parent router and child workflows
- **3-Layer Audit**: Explicit logging + error handler + poller backup — no execution goes untracked
- **Separate State Machines**: Approval state (pending→done) tracked independently from execution state (not_started→success/failed)

### Do NOT
- Modify production workflow JSON directly — export, edit, validate, import
- Use HTTP Request node for Salesforce (use native node for OAuth refresh)
- Hardcode environment-specific values outside config nodes
- Break the 3-layer audit chain
- Mix approval state with execution state
- Delete archive tables without updating UNION views

## AI Tool Preferences

| Tool | Use Case | Model |
|------|----------|-------|
| Claude Code | Architecture, complex features, multi-file changes | Opus 4.6 |
| KiloCode (kilo-arch) | Architecture review, design decisions | Opus 4.6 |
| KiloCode (kilo-code) | Feature implementation, workflow building | Sonnet 4.5 |
| KiloCode (kilo-quick) | Quick fixes, simple edits | Haiku 4.5 |
| KiloCode (kilo-review) | Code review, validation | Sonnet 4 |
| Ralph TUI | Task orchestration, PRD-driven development | Configurable |
| Cline | VS Code integrated editing | Configurable |
| Codex | CLI-based code generation | Configurable |
