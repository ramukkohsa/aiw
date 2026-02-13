# Decision History — n8n-workflows

## Solved Problems

### Email Threading with Salesforce
**Problem**: Reply emails not threading correctly in Salesforce case feed.
**Solution**: Use Salesforce `emailSimple` API with `relatedRecordId` field.

### OAuth Token Refresh
**Problem**: HTTP Request node failed when Salesforce OAuth tokens expired.
**Solution**: Switch to native Salesforce node which handles token refresh automatically.

### Org-Wide Email Sender
**Problem**: `senderAddress` in n8n email config required an ID, causing failures.
**Solution**: Use the actual email address string, not the Salesforce ID.

### Dashboard Links Blocked by CSP
**Problem**: Clickable links in n8n audit dashboard blocked by Content Security Policy headers.
**Solution**: Implemented copy-to-clipboard JavaScript workaround.

### Audit Capture Gaps
**Problem**: Some workflow executions were never logged.
**Solution**: Added Layer 3 (Execution Poller every 15 min) as safety net.

## Key Constraints

- n8n webhook URLs change between environments — must use config node
- Salesforce SOQL has specific syntax requirements
- Teams notifications require specific adaptive card JSON format
- PostgreSQL RDS connection strings differ between dev/prod
- n8n expression syntax: `{{ }}` with `$json`, `$node` variables
