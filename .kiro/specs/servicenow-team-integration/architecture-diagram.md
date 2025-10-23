# ServiceNow-TEAM Integration POC - Architecture Diagrams

## High-Level Architecture

```mermaid
graph TB
    subgraph "User Interface"
        CLI[CLI Tool<br/>Python Script]
    end
    
    subgraph "AWS Cloud"
        API[API Gateway<br/>REST Endpoints]
        
        subgraph "Lambda Functions"
            L1[CreateRequest<br/>Lambda]
            L2[QueryStatus<br/>Lambda]
            L3[ListRequests<br/>Lambda]
        end
        
        DB[(DynamoDB<br/>Request Mapping)]
        SEC[Secrets Manager<br/>Credentials]
        CW[CloudWatch<br/>Logs & Metrics]
    end
    
    subgraph "External Systems"
        SN[ServiceNow<br/>ITSM Platform]
        TEAM[AWS TEAM<br/>IAM Identity Center]
    end
    
    CLI -->|HTTPS| API
    API --> L1
    API --> L2
    API --> L3
    
    L1 -->|Get Creds| SEC
    L1 -->|Create Ticket| SN
    L1 -->|Create Request| TEAM
    L1 -->|Store Mapping| DB
    L1 -->|Log| CW
    
    L2 -->|Get Creds| SEC
    L2 -->|Query Status| TEAM
    L2 -->|Lookup| DB
    L2 -->|Log| CW
    
    L3 -->|Scan| DB
    L3 -->|Log| CW
    
    style CLI fill:#e1f5ff
    style API fill:#fff4e1
    style L1 fill:#e8f5e9
    style L2 fill:#e8f5e9
    style L3 fill:#e8f5e9
    style DB fill:#f3e5f5
    style SEC fill:#ffebee
    style SN fill:#e3f2fd
    style TEAM fill:#e3f2fd
```

## Request Creation Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI
    participant API as API Gateway
    participant Lambda as CreateRequest<br/>Lambda
    participant Secrets as Secrets<br/>Manager
    participant SN as ServiceNow
    participant TEAM as TEAM API
    participant DB as DynamoDB
    
    User->>CLI: create-request<br/>--account 123456789012<br/>--permission-set PowerUserAccess
    CLI->>API: POST /requests<br/>{account, permission_set, duration}
    API->>Lambda: Invoke
    
    Lambda->>Secrets: Get ServiceNow credentials
    Secrets-->>Lambda: Return credentials
    
    Lambda->>SN: POST /api/now/table/incident<br/>Create ticket
    SN-->>Lambda: Return ticket: INC0012345
    
    Lambda->>Secrets: Get TEAM credentials
    Secrets-->>Lambda: Return credentials
    
    Lambda->>TEAM: GraphQL mutation<br/>createRequest
    TEAM-->>Lambda: Return request: req-abc123
    
    Lambda->>DB: PutItem<br/>{ticket_id, team_request_id, ...}
    DB-->>Lambda: Success
    
    Lambda-->>API: Return {ticket_id, team_request_id}
    API-->>CLI: 200 OK
    CLI-->>User: ✓ ServiceNow: INC0012345<br/>✓ TEAM: req-abc123
```

## Status Query Flow

```mermaid
sequenceDiagram
    participant User
    participant CLI
    participant API as API Gateway
    participant Lambda as QueryStatus<br/>Lambda
    participant Secrets as Secrets<br/>Manager
    participant TEAM as TEAM API
    participant DB as DynamoDB
    
    User->>CLI: get-status req-abc123
    CLI->>API: GET /requests/req-abc123
    API->>Lambda: Invoke
    
    Lambda->>DB: Query by team_request_id (GSI)
    DB-->>Lambda: Return {ticket_id, metadata}
    
    Lambda->>Secrets: Get TEAM credentials
    Secrets-->>Lambda: Return credentials
    
    Lambda->>TEAM: GraphQL query<br/>getRequest(req-abc123)
    TEAM-->>Lambda: Return {status, details}
    
    Lambda-->>API: Return {ticket_id, status, created_at}
    API-->>CLI: 200 OK
    CLI-->>User: TEAM: req-abc123<br/>ServiceNow: INC0012345<br/>Status: PENDING
```

## Component Interaction Matrix

```mermaid
graph LR
    subgraph "Components"
        CLI[CLI Tool]
        API[API Gateway]
        L1[CreateRequest]
        L2[QueryStatus]
        L3[ListRequests]
        DB[(DynamoDB)]
        SEC[Secrets]
        SN[ServiceNow]
        TEAM[TEAM]
    end
    
    CLI -.->|HTTPS| API
    API -.->|Invoke| L1
    API -.->|Invoke| L2
    API -.->|Invoke| L3
    
    L1 -.->|Read| SEC
    L1 -.->|Write| DB
    L1 -.->|REST| SN
    L1 -.->|GraphQL| TEAM
    
    L2 -.->|Read| SEC
    L2 -.->|Read| DB
    L2 -.->|GraphQL| TEAM
    
    L3 -.->|Read| DB
```

## Data Model

```mermaid
erDiagram
    REQUEST {
        string ticket_id PK
        string team_request_id
        string snow_status
        string team_status
        string account_id
        string permission_set
        int duration_hours
        string justification
        string requester_email
        timestamp created_at
        timestamp updated_at
        timestamp last_query_at
    }
    
    SERVICENOW_TICKET {
        string number
        string sys_id
        string state
        string description
    }
    
    TEAM_REQUEST {
        string request_id
        string status
        string account_id
        string permission_set_arn
    }
    
    REQUEST ||--|| SERVICENOW_TICKET : "maps to"
    REQUEST ||--|| TEAM_REQUEST : "maps to"
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Developer Workstation"
        DEV[Developer]
        CFN[CloudFormation<br/>Template]
    end
    
    subgraph "AWS Account"
        subgraph "CloudFormation Stack"
            API[API Gateway]
            L1[Lambda: CreateRequest]
            L2[Lambda: QueryStatus]
            L3[Lambda: ListRequests]
            DB[(DynamoDB Table)]
            SEC[Secrets Manager]
            IAM[IAM Roles]
            CW[CloudWatch Logs]
        end
    end
    
    DEV -->|aws cloudformation deploy| CFN
    CFN -->|Creates| API
    CFN -->|Creates| L1
    CFN -->|Creates| L2
    CFN -->|Creates| L3
    CFN -->|Creates| DB
    CFN -->|Creates| SEC
    CFN -->|Creates| IAM
    CFN -->|Creates| CW
    
    style DEV fill:#e1f5ff
    style CFN fill:#fff4e1
    style API fill:#e8f5e9
    style L1 fill:#e8f5e9
    style L2 fill:#e8f5e9
    style L3 fill:#e8f5e9
```

## Security Architecture

```mermaid
graph TB
    subgraph "Security Layers"
        subgraph "Authentication"
            APIKEY[API Gateway<br/>API Key]
            OAUTH[ServiceNow<br/>OAuth/Basic Auth]
            COGNITO[TEAM<br/>Cognito M2M]
        end
        
        subgraph "Authorization"
            IAM[IAM Roles<br/>Least Privilege]
            POLICY[Resource Policies]
        end
        
        subgraph "Encryption"
            TLS[TLS 1.2+<br/>In Transit]
            KMS[KMS<br/>At Rest]
        end
        
        subgraph "Secrets Management"
            SEC[Secrets Manager<br/>Credential Storage]
            ROT[Automatic Rotation]
        end
    end
    
    APIKEY --> IAM
    OAUTH --> SEC
    COGNITO --> SEC
    IAM --> POLICY
    SEC --> KMS
    SEC --> ROT
    
    style APIKEY fill:#ffebee
    style OAUTH fill:#ffebee
    style COGNITO fill:#ffebee
    style IAM fill:#e8f5e9
    style SEC fill:#e3f2fd
```

## Error Handling Flow

```mermaid
graph TD
    START[API Request] --> VALIDATE{Input Valid?}
    VALIDATE -->|No| ERR400[Return 400<br/>Bad Request]
    VALIDATE -->|Yes| AUTH{Authenticated?}
    
    AUTH -->|No| ERR401[Return 401<br/>Unauthorized]
    AUTH -->|Yes| PROCESS[Process Request]
    
    PROCESS --> SN_CALL{ServiceNow<br/>Success?}
    SN_CALL -->|No| RETRY1{Retry<br/>< 3?}
    RETRY1 -->|Yes| BACKOFF1[Exponential<br/>Backoff]
    BACKOFF1 --> SN_CALL
    RETRY1 -->|No| ERR502[Return 502<br/>ServiceNow Error]
    
    SN_CALL -->|Yes| TEAM_CALL{TEAM<br/>Success?}
    TEAM_CALL -->|No| RETRY2{Retry<br/>< 3?}
    RETRY2 -->|Yes| BACKOFF2[Exponential<br/>Backoff]
    BACKOFF2 --> TEAM_CALL
    RETRY2 -->|No| ROLLBACK[Rollback<br/>ServiceNow Ticket]
    ROLLBACK --> ERR502B[Return 502<br/>TEAM Error]
    
    TEAM_CALL -->|Yes| DB_WRITE{DynamoDB<br/>Success?}
    DB_WRITE -->|No| ERR500[Return 500<br/>Internal Error]
    DB_WRITE -->|Yes| SUCCESS[Return 200<br/>Success]
    
    style ERR400 fill:#ffebee
    style ERR401 fill:#ffebee
    style ERR502 fill:#ffebee
    style ERR502B fill:#ffebee
    style ERR500 fill:#ffebee
    style SUCCESS fill:#e8f5e9
```

## Future State: Bidirectional Sync (Phase 2)

```mermaid
graph TB
    subgraph "Current POC"
        CLI1[CLI] --> API1[API Gateway]
        API1 --> L1[CreateRequest]
        L1 --> SN1[ServiceNow]
        L1 --> TEAM1[TEAM]
    end
    
    subgraph "Future: Bidirectional Sync"
        TEAM2[TEAM] -->|Webhook| EB[EventBridge]
        EB --> L4[StatusSync<br/>Lambda]
        L4 --> SN2[ServiceNow]
        L4 --> DB2[(DynamoDB)]
        
        SN2 -.->|Status Update| NOTIFY[SNS<br/>Notifications]
        NOTIFY -.->|Email| USER[User]
    end
    
    style CLI1 fill:#e1f5ff
    style L4 fill:#fff4e1
    style NOTIFY fill:#fff4e1
```

## Cost Estimate (Monthly)

```mermaid
pie title Estimated Monthly Cost (100 requests/day)
    "Lambda Invocations" : 5
    "API Gateway" : 10
    "DynamoDB" : 5
    "Secrets Manager" : 2
    "CloudWatch Logs" : 3
    "Total: ~$25/month" : 0
```

