# Architecture Decision Log

> Append-only. Record significant decisions here so any AI tool can understand the rationale.

## Format

```
### YYYY-MM — Decision Title
**Decision**: What was decided
**Reason**: Why
**Impact**: What changed as a result
```

---

## 2025-01 — Parent-Child Workflow Pattern
**Decision**: Use a single parent workflow as AI router that delegates to specialized child workflows.
**Reason**: Keeps each tool provisioner independently deployable and testable. Parent handles routing logic, children handle tool-specific APIs.
**Impact**: 7 child workflows + 1 parent + 1 scheduler = clean separation of concerns.

## 2025-01 — 3-Layer Audit System
**Decision**: Implement three independent audit capture layers instead of relying on a single logger.
**Reason**: Single-layer logging missed failures when child workflows crashed before calling the logger.
**Impact**: Layer 1 (explicit call), Layer 2 (error handler auto-capture), Layer 3 (poller backup) — guarantees no execution goes untracked.

## 2025-01 — Separate Approval State from Execution State
**Decision**: Track `approval_status`/`approval_result` independently from `execution_status`.
**Reason**: Early design conflated approval and execution, causing bugs when retries were needed on approved cases.
**Impact**: Clean state machine with up to 3 retry attempts per approved case.

## 2025-01 — Configuration Node Pattern
**Decision**: Standardize all workflows with a config node containing URLs, credentials, and webhook IDs.
**Reason**: Avoid hardcoded values scattered across workflow nodes. Single point of change for dev/prod switching.
**Impact**: Every workflow follows the same pattern — Set node (parent) or Code node (children/standalone).

## 2025-02 — Unified AI Workspace
**Decision**: Create `.ai-workspace/` hub-and-spoke directory where shared context is maintained once and adapter scripts generate tool-specific config files.
**Reason**: Multiple AI tools (Claude Code, KiloCode, Ralph TUI, Cline, Codex) each maintained separate configs. Re-explaining context to every tool, 73 duplicate skills, no shared session state.
**Impact**: Single source of truth for context, skills, and history. `aiw sync` propagates changes to all tools. `aiw start/switch` enables tool handoffs.
