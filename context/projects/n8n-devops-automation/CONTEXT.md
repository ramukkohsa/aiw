# Project Context — n8n-devops-automation

## Architecture

Infrastructure monitoring platform with full observability stack, managed via Docker Compose.

### Services

| Service | Port | Purpose |
|---------|------|---------|
| n8n | 5678 | Workflow automation engine |
| PostgreSQL | 5432 | Data storage |
| Redis | 6379 | Message queue / pub-sub |
| Grafana | 3000 | Dashboards and visualization |
| Prometheus | 9090 | Metrics collection |

### Commands

```bash
cd setup/
docker-compose up -d          # Start all services
docker-compose logs -f n8n    # Follow n8n logs
docker-compose down           # Stop all services
```

## File Layout

```
n8n-devops-automation/
├── setup/
│   └── docker-compose.yml    # Full stack definition
└── workflows/                # Monitoring workflow JSON files
```
