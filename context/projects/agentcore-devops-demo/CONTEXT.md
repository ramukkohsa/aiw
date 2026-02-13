# Project Context — agentcore-devops-demo

## Architecture

AWS Bedrock AgentCore demo for deploying AI agents as managed services. Uses Strands SDK for agent logic and agentcore CLI for deployment.

### Components

| Component | Purpose |
|-----------|---------|
| `src/` | Agent Python source code |
| `config/agent_config.yaml` | Agent behavior configuration |
| `config/remediation_playbooks.yaml` | Automated remediation recipes |
| `test_local.py` | Local agent testing |

### Commands

```bash
# Local testing
pip install bedrock-agentcore strands-agents boto3
python test_local.py

# Deploy to AgentCore
agentcore configure
agentcore launch --agent infrastructure-health-agent
```

## Technology Stack

- Python 3.10+
- AWS Bedrock AgentCore Runtime
- Strands Agents SDK
- boto3 (AWS SDK)
