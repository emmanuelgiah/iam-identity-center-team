# ServiceNow-TEAM Integration POC - Design Document

## Overview

This design document outlines the technical implementation for a 1-2 week POC demonstrating bidirectional integration between ServiceNow and AWS IAM Identity Center TEAM application. The solution is optimized for rapid development by a solo developer with CLI-based testing and CloudFormation deployment.

## Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                         AWS Cloud                             │
│                                                               │
│  ┌────────────┐                                              │
│  │ API Gateway│                                              │
│  │  (REST)    │                                              │
│  └─────┬──────┘                                              │
│        │                                                      │
│        ▼                                                      │
│  ┌────────────────────────────────────────────┐             │
│  │         Lambda Functions                    │             │
│  │  ┌──────────────┐  ┌──────────────┐       │             │
│  │  │CreateRequest │  │  StatusSync  │       │             │
│  │  └──────┬───────┘  └──────┬───────┘       │             │
│  │         │                  │                │             │
│  └─────────┼──────────────────┼────────────────┘             │
│            │                  │                               │
│     ┌──────▼──────┐    ┌─────▼──────┐                       │
│     │  DynamoDB   │    │  Secrets   │                       │
│     │   Table     │    │  Manager   │                       │
│     └─────────────┘    └────────────┘                       │
│                                                               │
└───────────────┬───────────────────────────┬──────────────────┘
                │                           │
                ▼                           ▼
        ┌───────────────┐          ┌──────────────┐
        │   ServiceNow  │          │     TEAM     │
        │   REST API    │          │  GraphQL API │
        └───────────────┘          └──────────────┘
```

### Component Details

#### 1. API Gateway
- **Purpose:** Expose REST endpoints for CLI and future integrations
- **Endpoints:**
  - `POST /requests` - Create new access request
  - `GET /requests/{ticketId}` - Get request status
  - `PUT /requests/{ticketId}/sync` - Manually trigger status sync
  - `GET /requests` - List all requests
- **Authentication:** API Key (for POC simplicity)
- **Throttling:** 100 requests/second (POC limit)

#### 2. Lambda Functions

**CreateRequestFunction**
- **Runtime:** Python 3.11
- **Memory:** 512 MB
- **Timeout:** 30 seconds
- **Responsibilities:**
  - Validate input parameters
  - Create ServiceNow incident ticket
  - Create TEAM access request
  - Store mapping in DynamoDB
  - Return both IDs to caller

**StatusSyncFunction**
- **Runtime:** Python 3.11
- **Memory:** 256 MB
- **Timeout:** 60 seconds
- **Trigger:** EventBridge (every 5 minutes) OR API Gateway
- **Responsibilities:**
  - Query TEAM for request status
  - Update ServiceNow ticket status
  - Update DynamoDB record
  - Log sync results

#### 3. DynamoDB Table

**Table Name:** `snow-team-integration`

**Schema:**
```json
{
  "ticket_id": "INC0012345",           // Partition Key
  "team_request_id": "req-abc123",
  "snow_status": "PENDING_APPROVAL",
  "team_status": "PENDING",
  "account_id": "123456789012",
  "permission_set": "PowerUserAccess",
  "duration_hours": 8,
  "justification": "Production incident",
  "requester_email": "user@example.com",
  "created_at": "2025-10-20T14:00:00Z",
  "updated_at": "2025-10-20T14:30:00Z",
  "last_sync_at": "2025-10-20T14:30:00Z",
  "sync_count": 3
}
```

**Indexes:**
- Primary Key: `ticket_id`
- GSI: `team_request_id` (for reverse lookups)

#### 4. Secrets Manager

**Secrets:**
- `snow-team-integration/servicenow-creds`
  ```json
  {
    "instance_url": "https://dev12345.service-now.com",
    "username": "integration_user",
    "password": "***",
    "client_id": "***",
    "client_secret": "***"
  }
  ```

- `snow-team-integration/team-creds`
  ```json
  {
    "api_endpoint": "https://team-api.amazonaws.com/graphql",
    "cognito_client_id": "***",
    "cognito_client_secret": "***",
    "cognito_token_url": "https://cognito-idp.us-east-1.amazonaws.com"
  }
  ```

## Data Flow

### Flow 1: Create Access Request

```
┌─────┐                                                    ┌──────────┐
│ CLI │                                                    │ServiceNow│
└──┬──┘                                                    └────┬─────┘
   │                                                            │
   │ 1. POST /requests                                         │
   │ {account, permission_set, duration, justification}        │
   ├──────────────────────────────────────┐                   │
   │                                       │                   │
   │                                       ▼                   │
   │                            ┌──────────────────┐          │
   │                            │ CreateRequest    │          │
   │                            │    Lambda        │          │
   │                            └────────┬─────────┘          │
   │                                     │                     │
   │                                     │ 2. Get credentials  │
   │                                     ├────────────────┐    │
   │                                     │                │    │
   │                                     │                ▼    │
   │                                     │         ┌──────────┐│
   │                                     │         │ Secrets  ││
   │                                     │         │ Manager  ││
   │                                     │         └──────────┘│
   │                                     │                     │
   │                                     │ 3. Create ticket    │
   │                                     ├────────────────────►│
   │                                     │                     │
   │                                     │ 4. Return ticket ID │
   │                                     │◄────────────────────┤
   │                                     │                     │
   │                                     │ 5. Create TEAM req  │
   │                                     ├────────────────┐    │
   │                                     │                │    │
   │                                     │                ▼    │
   │                                     │         ┌──────────┐│
   │                                     │         │   TEAM   ││
   │                                     │         │   API    ││
   │                                     │         └──────────┘│
   │                                     │                     │
   │                                     │ 6. Store mapping    │
   │                                     ├────────────────┐    │
   │                                     │                │    │
   │                                     │                ▼    │
   │                                     │         ┌──────────┐│
   │                                     │         │DynamoDB  ││
   │                                     │         └──────────┘│
   │                                     │                     │
   │ 7. Return {ticket_id, team_req_id} │                     │
   │◄────────────────────────────────────┤                     │
   │                                                            │
```

### Flow 2: Status Synchronization

```
┌──────────────┐                                        ┌──────────┐
│  EventBridge │                                        │   TEAM   │
│  (5 min)     │                                        │   API    │
└──────┬───────┘                                        └────┬─────┘
       │                                                      │
       │ 1. Trigger                                          │
       ├──────────────────────┐                              │
       │                      │                              │
       │                      ▼                              │
       │           ┌──────────────────┐                      │
       │           │   StatusSync     │                      │
       │           │     Lambda       │                      │
       │           └────────┬─────────┘                      │
       │                    │                                │
       │                    │ 2. Get all pending requests    │
       │                    ├────────────────┐               │
       │                    │                │               │
       │                    │                ▼               │
       │                    │         ┌──────────┐           │
       │                    │         │DynamoDB  │           │
       │                    │         └──────────┘           │
       │                    │                                │
       │                    │ 3. Query TEAM status           │
       │                    ├───────────────────────────────►│
       │                    │                                │
       │                    │ 4. Return status               │
       │                    │◄───────────────────────────────┤
       │                    │                                │
       │                    │ 5. Update ServiceNow           │
       │                    ├────────────────┐               │
       │                    │                │               │
       │                    │                ▼               │
       │                    │         ┌──────────┐           │
       │                    │         │ServiceNow│           │
       │                    │         └──────────┘           │
       │                    │                                │
       │                    │ 6. Update DynamoDB             │
       │                    ├────────────────┐               │
       │                    │                │               │
       │                    │                ▼               │
       │                    │         ┌──────────┐           │
       │                    │         │DynamoDB  │           │
       │                    │         └──────────┘           │
```

## API Specifications

### ServiceNow REST API Integration

**Create Incident Ticket**
```http
POST https://{instance}.service-now.com/api/now/table/incident
Authorization: Basic {base64(username:password)}
Content-Type: application/json

{
  "short_description": "TEAM Access Request: {permission_set} for {account_id}",
  "description": "Justification: {justification}\nDuration: {duration} hours",
  "category": "Access Request",
  "subcategory": "AWS IAM Identity Center",
  "urgency": "3",
  "impact": "3",
  "caller_id": "{requester_email}",
  "u_team_request_id": "{team_request_id}",
  "u_account_id": "{account_id}",
  "u_permission_set": "{permission_set}"
}

Response:
{
  "result": {
    "number": "INC0012345",
    "sys_id": "abc123...",
    "state": "1"  // New
  }
}
```

**Update Incident Status**
```http
PATCH https://{instance}.service-now.com/api/now/table/incident/{sys_id}
Authorization: Basic {base64(username:password)}
Content-Type: application/json

{
  "state": "2",  // In Progress
  "work_notes": "TEAM request status: APPROVED. Session activated."
}
```

### TEAM GraphQL API Integration

**Create Access Request**
```graphql
mutation CreateRequest {
  createRequest(input: {
    accountId: "123456789012"
    permissionSetArn: "arn:aws:sso:::permissionSet/ssoins-xxx/ps-xxx"
    durationHours: 8
    justification: "Production incident response"
    requesterEmail: "user@example.com"
  }) {
    requestId
    status
    createdAt
  }
}
```

**Query Request Status**
```graphql
query GetRequestStatus {
  getRequest(requestId: "req-abc123") {
    requestId
    status
    accountId
    permissionSetArn
    approvals {
      approverEmail
      status
      timestamp
    }
    session {
      status
      startTime
      endTime
    }
  }
}
```

## Status Mapping

### ServiceNow States → TEAM Status

| ServiceNow State | State Code | TEAM Status | Description |
|------------------|------------|-------------|-------------|
| New | 1 | PENDING | Request created, awaiting approval |
| In Progress | 2 | APPROVED | Approved, session being provisioned |
| On Hold | 3 | PENDING | Awaiting additional information |
| Resolved | 6 | ACTIVE | Session is active |
| Closed | 7 | EXPIRED | Session completed or expired |
| Canceled | 8 | DENIED | Request denied or canceled |

### TEAM Status → ServiceNow States

| TEAM Status | ServiceNow State | Work Notes |
|-------------|------------------|------------|
| PENDING | New (1) | "Awaiting approval from {approver}" |
| APPROVED | In Progress (2) | "Request approved. Provisioning session..." |
| DENIED | Canceled (8) | "Request denied. Reason: {reason}" |
| ACTIVE | Resolved (6) | "Session active. Expires at {end_time}" |
| EXPIRED | Closed (7) | "Session expired at {end_time}" |
| TERMINATED | Closed (7) | "Session terminated. Reason: {reason}" |

## Error Handling

### Error Categories

1. **Validation Errors (400)**
   - Missing required fields
   - Invalid account ID format
   - Invalid duration (must be 1-12 hours)
   - Invalid permission set

2. **Authentication Errors (401)**
   - Invalid ServiceNow credentials
   - Expired TEAM token
   - Missing API key

3. **Not Found Errors (404)**
   - ServiceNow ticket not found
   - TEAM request not found
   - DynamoDB record not found

4. **External Service Errors (502/503)**
   - ServiceNow API unavailable
   - TEAM API unavailable
   - Rate limit exceeded

5. **Internal Errors (500)**
   - DynamoDB write failure
   - Secrets Manager access denied
   - Unexpected exception

### Retry Strategy

```python
def retry_with_backoff(func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return func()
        except (ConnectionError, Timeout) as e:
            if attempt == max_retries - 1:
                raise
            wait_time = 2 ** attempt  # Exponential backoff: 1s, 2s, 4s
            time.sleep(wait_time)
            logger.warning(f"Retry {attempt + 1}/{max_retries} after {wait_time}s")
```

## Logging Strategy

### Log Structure

```json
{
  "timestamp": "2025-10-20T14:30:00.123Z",
  "level": "INFO",
  "correlation_id": "req-abc123",
  "function": "CreateRequestFunction",
  "event": "request_created",
  "details": {
    "ticket_id": "INC0012345",
    "team_request_id": "req-abc123",
    "account_id": "123456789012",
    "duration_hours": 8
  },
  "duration_ms": 1234
}
```

### Log Levels

- **DEBUG:** Detailed request/response payloads (sanitized)
- **INFO:** Normal operations (request created, status synced)
- **WARN:** Retryable errors, rate limits
- **ERROR:** Non-retryable errors, validation failures
- **CRITICAL:** System failures, data inconsistencies

## Security Considerations

### Authentication
- ServiceNow: Basic Auth or OAuth 2.0 (stored in Secrets Manager)
- TEAM: AWS Cognito machine-to-machine OAuth
- API Gateway: API Key (POC) → IAM Auth (production)

### Data Protection
- All API calls use HTTPS/TLS 1.2+
- Credentials stored in AWS Secrets Manager with encryption at rest
- DynamoDB encryption at rest enabled
- CloudWatch Logs encrypted

### IAM Permissions (Least Privilege)

```yaml
LambdaExecutionRole:
  Policies:
    - DynamoDB: GetItem, PutItem, UpdateItem, Query on snow-team-integration table
    - Secrets Manager: GetSecretValue on snow-team-integration/* secrets
    - CloudWatch Logs: CreateLogGroup, CreateLogStream, PutLogEvents
    - (No S3, EC2, or other unnecessary permissions)
```

## Testing Strategy

### Unit Tests
- Mock ServiceNow API responses
- Mock TEAM GraphQL responses
- Test status mapping logic
- Test error handling paths

### Integration Tests
- Deploy to dev environment
- Create real ServiceNow ticket
- Create real TEAM request (dev instance)
- Verify DynamoDB records
- Verify status synchronization

### CLI Test Commands

```bash
# Test 1: Create request
./cli create-request \
  --account 123456789012 \
  --permission-set PowerUserAccess \
  --duration 8 \
  --justification "Testing POC"

# Expected: Returns ticket_id and team_request_id

# Test 2: Get status
./cli get-status INC0012345

# Expected: Shows synchronized status from both systems

# Test 3: Manual sync
./cli sync-status INC0012345

# Expected: Triggers immediate sync, shows updated status

# Test 4: List all requests
./cli list-requests

# Expected: Shows all requests with sync status
```

## Deployment

### CloudFormation Parameters

```yaml
Parameters:
  ServiceNowInstance:
    Type: String
    Description: ServiceNow instance URL (e.g., dev12345.service-now.com)
  
  ServiceNowUsername:
    Type: String
    Description: ServiceNow integration user
    NoEcho: true
  
  ServiceNowPassword:
    Type: String
    Description: ServiceNow password
    NoEcho: true
  
  TEAMApiEndpoint:
    Type: String
    Description: TEAM GraphQL API endpoint
  
  TEAMCognitoClientId:
    Type: String
    Description: Cognito client ID for TEAM API
    NoEcho: true
  
  TEAMCognitoClientSecret:
    Type: String
    Description: Cognito client secret
    NoEcho: true
```

### Deployment Commands

```bash
# Package Lambda code
cd lambda
zip -r ../lambda-package.zip .
cd ..

# Deploy stack
aws cloudformation deploy \
  --template-file template.yaml \
  --stack-name snow-team-integration-poc \
  --parameter-overrides \
    ServiceNowInstance=dev12345.service-now.com \
    ServiceNowUsername=integration_user \
    ServiceNowPassword=*** \
    TEAMApiEndpoint=https://team-api.amazonaws.com/graphql \
    TEAMCognitoClientId=*** \
    TEAMCognitoClientSecret=*** \
  --capabilities CAPABILITY_IAM

# Get outputs
aws cloudformation describe-stacks \
  --stack-name snow-team-integration-poc \
  --query 'Stacks[0].Outputs'
```

## Monitoring & Observability

### CloudWatch Metrics

- `RequestsCreated` - Count of requests created
- `StatusSyncs` - Count of status sync operations
- `SyncErrors` - Count of sync failures
- `APILatency` - P50, P95, P99 latency for API calls

### CloudWatch Alarms

- `HighErrorRate` - Error rate > 5% over 5 minutes
- `SyncFailures` - More than 3 consecutive sync failures
- `APILatencyHigh` - P95 latency > 5 seconds

### CloudWatch Dashboard

```
┌─────────────────────────────────────────────────────┐
│  ServiceNow-TEAM Integration POC Dashboard          │
├─────────────────────────────────────────────────────┤
│  Requests Created (24h): 42                         │
│  Status Syncs (24h): 126                            │
│  Error Rate: 0.8%                                   │
│  Avg Latency: 1.2s                                  │
├─────────────────────────────────────────────────────┤
│  [Graph: Requests Created Over Time]                │
│  [Graph: Sync Success Rate]                         │
│  [Graph: API Latency Distribution]                  │
└─────────────────────────────────────────────────────┘
```

## Future Enhancements (Post-POC)

1. **Real-time Webhooks:** Replace polling with event-driven updates
2. **Approval Workflow:** Integrate ServiceNow approval engine
3. **Session Management:** Track active sessions, send expiry warnings
4. **Audit Reports:** Generate compliance reports from DynamoDB
5. **ServiceNow UI:** Custom forms and dashboards
6. **Multi-region:** Deploy to multiple AWS regions
7. **Disaster Recovery:** Cross-region replication
8. **Performance:** Caching, batch operations
9. **Advanced Error Recovery:** Dead letter queues, manual reconciliation
10. **Production Monitoring:** PagerDuty integration, runbooks

