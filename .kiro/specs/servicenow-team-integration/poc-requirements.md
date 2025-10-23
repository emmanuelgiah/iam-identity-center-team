# ServiceNow-TEAM Integration POC Requirements

## Introduction

This is a **Proof of Concept (POC)** for integrating ServiceNow with AWS IAM Identity Center TEAM application. The POC demonstrates core bidirectional integration capabilities within a 1-2 week timeline for a solo developer, deployable via CloudFormation and testable via CLI.

**Key Constraints:**
- Timeline: 1-2 weeks
- Team: Solo developer
- Deployment: CloudFormation stack
- Testing: CLI-based (no frontend)
- Scope: Core integration only, minimal UI

## POC Scope

### In Scope (MVP)
- ServiceNow → TEAM: Create access request
- Query request status from TEAM
- Basic authentication (API key or OAuth)
- CloudFormation deployment
- CLI testing interface
- Basic error handling
- Simple state tracking in DynamoDB

### Out of Scope (Future)
- Bidirectional sync (TEAM → ServiceNow status updates)
- Complex approval workflows
- Real-time webhooks
- Advanced audit reporting
- ServiceNow UI customization
- Production-grade resilience
- Multi-region deployment

## Requirements

### Requirement 1: ServiceNow Request Creation

**User Story:** As a developer, I want to create a TEAM access request from ServiceNow via API, so that I can demonstrate the core integration flow.

#### Acceptance Criteria

1. WHEN I call the ServiceNow REST API with request details THEN the system SHALL create a corresponding TEAM request
2. WHEN creating a request THEN the system SHALL validate required fields (account_id, permission_set, duration, justification)
3. WHEN a request is created THEN the system SHALL return the TEAM request ID and ServiceNow ticket number
4. IF validation fails THEN the system SHALL return a 400 error with clear error message
5. WHEN a request is created THEN the system SHALL store the mapping between ServiceNow ticket and TEAM request ID

### Requirement 2: Status Query

**User Story:** As a developer, I want to query the status of a TEAM request, so that I can verify the request was created successfully.

#### Acceptance Criteria

1. WHEN I query a request via CLI THEN the system SHALL retrieve the current status from TEAM
2. WHEN displaying status THEN the system SHALL show TEAM status (pending, approved, denied, active, expired)
3. WHEN querying THEN the system SHALL also show the ServiceNow ticket number for reference
4. IF the TEAM request doesn't exist THEN the system SHALL return a 404 error
5. WHEN querying THEN the system SHALL log the query with timestamp

### Requirement 3: Authentication & Security

**User Story:** As a developer, I want secure API authentication, so that the integration is production-ready from a security perspective.

#### Acceptance Criteria

1. WHEN calling ServiceNow APIs THEN the system SHALL use Basic Auth or OAuth token
2. WHEN calling TEAM APIs THEN the system SHALL use AWS Cognito machine-to-machine authentication
3. WHEN storing credentials THEN the system SHALL use AWS Secrets Manager
4. WHEN API calls are made THEN the system SHALL use HTTPS/TLS
5. IF authentication fails THEN the system SHALL return a 401 error with retry guidance

### Requirement 4: CloudFormation Deployment

**User Story:** As a developer, I want to deploy the entire integration via CloudFormation, so that setup is automated and repeatable.

#### Acceptance Criteria

1. WHEN running `aws cloudformation deploy` THEN the system SHALL provision all required resources
2. WHEN deploying THEN the system SHALL create Lambda functions, API Gateway, Secrets, and IAM roles
3. WHEN deployment completes THEN the system SHALL output API endpoints and configuration values
4. IF deployment fails THEN the system SHALL rollback cleanly
5. WHEN deleting the stack THEN the system SHALL remove all resources except logs

### Requirement 5: CLI Testing Interface

**User Story:** As a developer, I want to test the integration via CLI commands, so that I can validate functionality without building a UI.

#### Acceptance Criteria

1. WHEN running `cli create-request` THEN the system SHALL create a request in both systems
2. WHEN running `cli get-status <team-request-id>` THEN the system SHALL show current TEAM status
3. WHEN running `cli list-requests` THEN the system SHALL show all requests from DynamoDB
4. IF commands fail THEN the system SHALL display helpful error messages
5. WHEN running commands THEN the system SHALL provide clear output with request IDs

### Requirement 6: Error Handling & Logging

**User Story:** As a developer, I want comprehensive logging, so that I can troubleshoot issues during POC demos.

#### Acceptance Criteria

1. WHEN any operation occurs THEN the system SHALL log to CloudWatch with structured JSON
2. WHEN errors occur THEN the system SHALL log stack traces and context
3. WHEN API calls are made THEN the system SHALL log request/response (excluding sensitive data)
4. WHEN viewing logs THEN developers SHALL see correlation IDs linking related operations
5. IF rate limits are hit THEN the system SHALL log and implement basic retry (3 attempts)

## Technical Architecture (POC)

### Components

```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  ServiceNow │◄────────┤   Lambda     │────────►│    TEAM     │
│   (REST)    │         │  Integration │         │  (GraphQL)  │
└─────────────┘         └──────────────┘         └─────────────┘
                               │
                               ▼
                        ┌──────────────┐
                        │   DynamoDB   │
                        │ (State Store)│
                        └──────────────┘
```

### AWS Resources (CloudFormation)

1. **Lambda Functions:**
   - `CreateRequestFunction`: Handles ServiceNow → TEAM request creation
   - `StatusSyncFunction`: Handles TEAM → ServiceNow status updates
   - `CLIHandlerFunction`: Processes CLI commands

2. **API Gateway:**
   - REST API for ServiceNow integration
   - Endpoints: POST /requests, GET /requests/{id}, PUT /requests/{id}/status

3. **DynamoDB Table:**
   - Stores mapping between ServiceNow tickets and TEAM requests
   - Schema: `{ticket_id, team_request_id, status, created_at, updated_at}`

4. **Secrets Manager:**
   - ServiceNow credentials
   - TEAM API credentials

5. **IAM Roles:**
   - Lambda execution role with DynamoDB, Secrets Manager, CloudWatch access

6. **CloudWatch Log Groups:**
   - Structured logging for all Lambda functions

### Data Flow

**Request Creation:**
1. CLI calls API Gateway → CreateRequestFunction
2. Lambda retrieves credentials from Secrets Manager
3. Lambda creates ServiceNow ticket via REST API
4. Lambda creates TEAM request via GraphQL API
5. Lambda stores mapping in DynamoDB
6. Lambda returns both IDs to CLI

**Status Sync:**
1. CLI calls API Gateway → StatusSyncFunction (or triggered by EventBridge schedule)
2. Lambda queries TEAM for request status
3. Lambda updates ServiceNow ticket status
4. Lambda updates DynamoDB record
5. Lambda returns sync result

## Success Criteria (POC)

- ✅ Successfully create a request that appears in both ServiceNow and TEAM
- ✅ Can query TEAM status for any created request
- ✅ All components deploy via single CloudFormation command
- ✅ CLI can perform all core operations (create, query, list)
- ✅ Logs provide clear troubleshooting information
- ✅ Demo-ready: Can show end-to-end flow in 5 minutes

## Out of Scope (Explicitly)

- ServiceNow UI customization
- Real-time webhooks (polling is acceptable for POC)
- Complex approval workflows
- Multi-approver chains
- Session lifecycle management beyond status
- Production-grade error recovery
- Performance optimization
- Load testing
- Security penetration testing
- Comprehensive documentation

## Timeline (1-2 Weeks)

### Week 1: Core Integration
- **Days 1-2:** CloudFormation template + Lambda scaffolding
- **Days 3-4:** ServiceNow API integration + TEAM GraphQL integration
- **Day 5:** DynamoDB state management + basic CLI

### Week 2: Polish & Demo Prep
- **Days 1-2:** Status query logic + list functionality
- **Day 3:** Error handling + logging improvements
- **Day 4:** CLI enhancements + testing
- **Day 5:** Demo preparation + documentation

## Demo Script

```bash
# Deploy the stack
aws cloudformation deploy --template-file template.yaml --stack-name snow-team-poc

# Create a request
./cli create-request \
  --account 123456789012 \
  --permission-set PowerUserAccess \
  --duration 8 \
  --justification "Production incident response"

# Output: 
# ServiceNow Ticket: INC0012345
# TEAM Request: req-abc123
# Status: PENDING

# Check status
./cli get-status req-abc123

# Output:
# TEAM Request ID: req-abc123
# ServiceNow Ticket: INC0012345
# Status: PENDING
# Created: 2025-10-20 14:00:00 UTC
# Last Queried: 2025-10-20 14:30:00 UTC

# List all requests
./cli list-requests

# Output:
# Found 3 requests:
# 1. req-abc123 | INC0012345 | PENDING | 2025-10-20 14:00:00
# 2. req-def456 | INC0012346 | APPROVED | 2025-10-20 13:00:00
# 3. req-ghi789 | INC0012347 | ACTIVE | 2025-10-20 12:00:00
```

## Next Steps After POC

If POC is successful, the following would be prioritized for production:
1. **Bidirectional sync:** TEAM → ServiceNow status updates via webhooks
2. Real-time webhooks instead of polling
3. Comprehensive error recovery and retry logic
4. Approval workflow integration
5. ServiceNow UI components
6. Production monitoring and alerting
7. Security hardening and penetration testing
8. Performance optimization
9. Multi-region deployment
10. Disaster recovery procedures
11. User documentation and training

