# Project Context — n8n-agentic-devops

## Architecture

Multi-agent architecture with 7 specialized agents coordinating through Redis pub/sub and PostgreSQL shared state.

### Agents

| Agent | Workflow | Purpose |
|-------|----------|---------|
| Master Orchestrator | `VALID_01_master_orchestrator.json` | Central intelligence, delegates to specialized agents |
| Perception | `VALID_02_perception_agent.json` | Multi-source data collection, anomaly detection |
| Action | `VALID_03_action_agent.json` | Executes remediation with rollback support |
| Complete Monitoring | `VALID_04_complete_monitoring.json` | Full monitoring pipeline |

### Communication

**Redis Pub/Sub Channels:**
- `agent.perception.*` — Sensor data from monitoring
- `agent.planning.*` — Task assignments
- `agent.action.*` — Execution commands
- `agent.memory.*` — Context updates
- `agent.learning.*` — Feedback loops

**PostgreSQL Tables:**
- `agent_state` — Current agent status
- `agent_memory` — Context storage
- `agent_goals` — Active objectives
- `agent_plans` — Execution plans
- `agent_results` — Outcome tracking

### Trigger

```bash
curl -X POST http://localhost:5678/webhook/start-orchestrator
```

## File Conventions

- `VALID_` prefix indicates production-ready workflows
- All other JSON files are drafts or experiments
