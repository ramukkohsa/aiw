# Active Brief — n8n-workflows

## Current Status

Production system is **live and operational**. All 7 child provisioners, the parent router, approval checker, and 3-layer audit system are deployed.

## Active Goals

1. **Maintain production stability** — All workflows running on n8n with PostgreSQL RDS backend
2. **Dashboard improvements** — Real-time audit dashboard with resolution tracking
3. **DataTables migration** — Transitioning from basic table nodes to DataTables nodes
4. **Reporting expansion** — Weekly and EOD reports active, Salesforce cache refreshing hourly

## Pending / Future Work

- [ ] Complete DataTables migration across all workflows
- [ ] Cost tracking workflow (Phase 5 — not yet started)
- [ ] Formalize test coverage for CI/CD
- [ ] CloudWatch/Datadog monitoring integration for n8n metrics
- [ ] Create `how-to-create-childFlows.md` template guide

## Environment

- **Dev/Prod switching**: Single config node per workflow
- **n8n instance**: Running on Docker/ECS
- **Database**: AWS RDS PostgreSQL
- **AI**: Claude via AWS Bedrock
