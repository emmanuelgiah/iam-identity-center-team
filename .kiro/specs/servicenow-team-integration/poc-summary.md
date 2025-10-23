# ServiceNow-TEAM Integration POC - Quick Reference

## Executive Summary

**Objective:** Demonstrate integration between ServiceNow ITSM and AWS IAM Identity Center TEAM for temporary elevated access management.

**Timeline:** 10 days (1-2 weeks)  
**Effort:** ~46 hours  
**Deployment:** CloudFormation stack  
**Testing:** CLI-based (no UI)

## What Gets Built

### Core Flow
```
User → CLI → API Gateway → Lambda → ServiceNow (create ticket)
                                  → TEAM (create request)
                                  → DynamoDB (store mapping)
```

### Components
1. **3 Lambda Functions:**
   - CreateRequest: Orchestrates request creation in both systems
   - QueryStatus: Retrieves current TEAM status
   - ListRequests: Lists all requests from DynamoDB

2. **API Gateway:** REST endpoints for CLI access

3. **DynamoDB Table:** Stores mapping between ServiceNow tickets and TEAM requests

4. **Secrets Manager:** Stores ServiceNow and TEAM credentials

5. **CLI Tool:** Python script for testing (create, query, list)

## Demo Flow (5 minutes)

```bash
# 1. Deploy the stack
aws cloudformation deploy --template-file template.yaml --stack-name snow-team-poc

# 2. Create a request
./cli create-request \
  --account 123456789012 \
  --permission-set PowerUserAccess \
  --duration 8 \
  --justification "Production incident response"

# Output:
# ✓ ServiceNow Ticket: INC0012345
# ✓ TEAM Request: req-abc123
# ✓ Status: PENDING

# 3. Query status
./cli get-status req-abc123

# Output:
# TEAM Request: req-abc123
# ServiceNow Ticket: INC0012345
# Status: PENDING
# Created: 2025-10-20 14:00:00 UTC

# 4. List all requests
./cli list-requests

# Output:
# Found 3 requests:
# 1. req-abc123 | INC0012345 | PENDING | 2025-10-20 14:00:00
# 2. req-def456 | INC0012346 | APPROVED | 2025-10-20 13:00:00
# 3. req-ghi789 | INC0012347 | ACTIVE | 2025-10-20 12:00:00
```

## What's NOT in POC (Future Phases)

- ❌ Bidirectional sync (TEAM → ServiceNow automatic updates)
- ❌ Real-time webhooks
- ❌ ServiceNow UI customization
- ❌ Complex approval workflows
- ❌ Production-grade error recovery
- ❌ Multi-region deployment

## Key Files to Create

```
project/
├── template.yaml                 # CloudFormation template
├── lambda/
│   ├── create_request.py        # Lambda: Create request
│   ├── query_status.py          # Lambda: Query status
│   ├── list_requests.py         # Lambda: List requests
│   ├── servicenow_client.py     # ServiceNow API wrapper
│   ├── team_client.py           # TEAM GraphQL wrapper
│   └── requirements.txt         # Python dependencies
├── cli/
│   └── snow-team-cli.py         # CLI tool
├── tests/
│   ├── test_create_request.py
│   ├── test_query_status.py
│   └── test_integration.py
└── docs/
    ├── deployment-guide.md
    ├── demo-script.md
    └── architecture-diagram.png
```

## Prerequisites

### AWS Resources Needed
- AWS Account with admin access
- AWS CLI configured
- Python 3.11+ installed

### ServiceNow Access
- ServiceNow instance URL (e.g., dev12345.service-now.com)
- Integration user credentials (username/password or OAuth)
- Permissions to create incident tickets

### TEAM Access
- TEAM API endpoint URL
- Cognito client ID and secret for machine-to-machine auth
- Permissions to create access requests

## Success Criteria

- ✅ Single CloudFormation command deploys entire stack
- ✅ CLI can create requests in both ServiceNow and TEAM
- ✅ CLI can query TEAM status for any request
- ✅ CLI can list all requests
- ✅ All operations complete in < 30 seconds
- ✅ Comprehensive CloudWatch logs for troubleshooting
- ✅ Demo can be completed in 5 minutes

## Customer Value Proposition

**Problem:** Waters Corporation needs to integrate their existing ServiceNow ITSM platform with AWS IAM Identity Center TEAM for temporary elevated access management.

**Solution:** This POC demonstrates:
1. **Familiar Interface:** Users request access through ServiceNow (their existing tool)
2. **Automated Provisioning:** Requests automatically create TEAM access requests
3. **Audit Trail:** All requests tracked in both systems
4. **Easy Deployment:** Single CloudFormation command
5. **Extensible:** Foundation for future bidirectional sync and approval workflows

**Next Steps After POC:**
- Phase 2: Bidirectional sync (TEAM → ServiceNow status updates)
- Phase 3: Approval workflow integration
- Phase 4: ServiceNow UI customization
- Phase 5: Production hardening and monitoring

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Deployment | CloudFormation | Customer requirement, easy to package |
| Testing | CLI | No frontend needed for POC, faster development |
| Sync Direction | Unidirectional (SN→TEAM) | Simplifies POC, bidirectional is future phase |
| State Storage | DynamoDB | Serverless, low cost, easy to query |
| Authentication | Secrets Manager | Secure, integrated with Lambda |
| Logging | CloudWatch | Native AWS integration |
| Runtime | Python 3.11 | Fast development, good library support |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| ServiceNow API changes | Use stable REST API v2, version lock |
| TEAM API rate limits | Implement exponential backoff, log rate limit errors |
| Credential expiry | Store in Secrets Manager, implement refresh logic |
| Demo environment issues | Test in dev environment 24 hours before demo |
| Scope creep | Strict adherence to POC requirements, defer enhancements |

## Questions for Customer Meeting

1. **ServiceNow Access:** Do you have a dev/test ServiceNow instance we can use?
2. **TEAM Environment:** Is there a TEAM dev environment for testing?
3. **Credentials:** Can you provide integration user credentials before we start?
4. **Approval Workflow:** What's your current approval process? (For future phases)
5. **Timeline:** Is 1-2 weeks acceptable for POC delivery?
6. **Success Criteria:** What would make this POC successful for you?

## Contact & Support

**Developer:** [Your Name]  
**Timeline:** 10 days starting [Start Date]  
**Demo Date:** [Demo Date]  
**Repository:** [Git Repo URL]

