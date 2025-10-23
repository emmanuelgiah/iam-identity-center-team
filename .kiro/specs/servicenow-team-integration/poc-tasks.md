# ServiceNow-TEAM Integration POC - Implementation Tasks

## Overview

This task list provides a step-by-step implementation plan for the 1-2 week POC. Tasks are ordered to enable incremental progress with early validation points.

## Implementation Tasks

- [ ] 1. Project Setup and Infrastructure Foundation
  - Create project directory structure
  - Initialize Git repository
  - Set up Python virtual environment
  - Install required dependencies (boto3, requests, gql)
  - _Requirements: All requirements (foundational)_

- [ ] 2. CloudFormation Template - Core Resources
  - [ ] 2.1 Create base CloudFormation template with parameters
    - Define parameters for ServiceNow and TEAM credentials
    - Set up template metadata and description
    - _Requirements: 4.1, 4.2_
  
  - [ ] 2.2 Define DynamoDB table resource
    - Create table with ticket_id as partition key
    - Add GSI for team_request_id lookups
    - Enable encryption at rest
    - _Requirements: 1.5, 2.3_
  
  - [ ] 2.3 Define Secrets Manager resources
    - Create secret for ServiceNow credentials
    - Create secret for TEAM API credentials
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [ ] 2.4 Define IAM roles and policies
    - Create Lambda execution role
    - Attach policies for DynamoDB, Secrets Manager, CloudWatch
    - Follow least privilege principle
    - _Requirements: 3.4, 6.2_

- [ ] 3. Lambda Function - Create Request
  - [ ] 3.1 Create Lambda function handler skeleton
    - Set up function entry point
    - Define input validation schema
    - Implement basic error handling structure
    - _Requirements: 1.1, 1.2, 6.1_
  
  - [ ] 3.2 Implement ServiceNow API client
    - Create function to retrieve ServiceNow credentials from Secrets Manager
    - Implement REST API call to create incident ticket
    - Handle authentication (Basic Auth or OAuth)
    - Parse and validate ServiceNow response
    - _Requirements: 1.1, 3.1, 3.4_
  
  - [ ] 3.3 Implement TEAM GraphQL API client
    - Create function to retrieve TEAM credentials from Secrets Manager
    - Implement Cognito authentication flow
    - Build GraphQL mutation for createRequest
    - Parse and validate TEAM response
    - _Requirements: 1.1, 3.2, 3.4_
  
  - [ ] 3.4 Implement DynamoDB state storage
    - Create function to store request mapping
    - Store ticket_id, team_request_id, and metadata
    - Handle DynamoDB write errors
    - _Requirements: 1.3, 1.5_
  
  - [ ] 3.5 Implement end-to-end request creation flow
    - Orchestrate ServiceNow → TEAM → DynamoDB flow
    - Implement transaction-like behavior (rollback on failure)
    - Return both IDs to caller
    - _Requirements: 1.1, 1.3_
  
  - [ ] 3.6 Add comprehensive logging
    - Log all API calls with correlation IDs
    - Log request/response payloads (sanitized)
    - Implement structured JSON logging
    - _Requirements: 6.1, 6.3, 6.4_

- [ ] 4. Lambda Function - Query Status
  - [ ] 4.1 Create Lambda function handler for status queries
    - Set up function entry point
    - Define input validation (team_request_id)
    - _Requirements: 2.1, 2.4_
  
  - [ ] 4.2 Implement TEAM status query
    - Build GraphQL query for getRequest
    - Parse status from TEAM response
    - Handle not found errors
    - _Requirements: 2.1, 2.2_
  
  - [ ] 4.3 Implement DynamoDB lookup
    - Query DynamoDB by team_request_id (GSI)
    - Retrieve ServiceNow ticket number
    - _Requirements: 2.3_
  
  - [ ] 4.4 Format and return status response
    - Combine TEAM status with ServiceNow ticket info
    - Return structured response
    - _Requirements: 2.1, 2.5_

- [ ] 5. Lambda Function - List Requests
  - [ ] 5.1 Create Lambda function handler for listing
    - Set up function entry point
    - Implement pagination support (optional for POC)
    - _Requirements: 5.3_
  
  - [ ] 5.2 Implement DynamoDB scan/query
    - Scan DynamoDB table for all requests
    - Sort by created_at timestamp
    - Limit to most recent 50 requests
    - _Requirements: 5.3_
  
  - [ ] 5.3 Format and return list response
    - Return array of request summaries
    - Include ticket_id, team_request_id, status, created_at
    - _Requirements: 5.3_

- [ ] 6. API Gateway Configuration
  - [ ] 6.1 Add API Gateway to CloudFormation
    - Create REST API resource
    - Define API key for authentication
    - Set up usage plan and throttling
    - _Requirements: 4.1, 4.2_
  
  - [ ] 6.2 Define API endpoints
    - POST /requests → CreateRequestFunction
    - GET /requests/{id} → QueryStatusFunction
    - GET /requests → ListRequestsFunction
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 6.3 Configure Lambda integrations
    - Set up Lambda proxy integrations
    - Configure request/response mappings
    - Enable CORS (for future web UI)
    - _Requirements: 4.1_

- [ ] 7. CLI Tool Development
  - [ ] 7.1 Create CLI script skeleton
    - Set up argument parser (argparse or click)
    - Define subcommands: create-request, get-status, list-requests
    - Implement help text and usage examples
    - _Requirements: 5.1, 5.4, 5.5_
  
  - [ ] 7.2 Implement create-request command
    - Parse command-line arguments
    - Call API Gateway POST /requests endpoint
    - Display formatted response
    - Handle errors gracefully
    - _Requirements: 5.1_
  
  - [ ] 7.3 Implement get-status command
    - Parse team_request_id argument
    - Call API Gateway GET /requests/{id} endpoint
    - Display formatted status
    - _Requirements: 5.2_
  
  - [ ] 7.4 Implement list-requests command
    - Call API Gateway GET /requests endpoint
    - Display formatted table of requests
    - _Requirements: 5.3_
  
  - [ ] 7.5 Add CLI configuration file support
    - Support ~/.snow-team-cli/config for API endpoint and key
    - Allow environment variable overrides
    - _Requirements: 5.5_

- [ ] 8. Error Handling and Resilience
  - [ ] 8.1 Implement retry logic with exponential backoff
    - Add retry decorator for API calls
    - Configure max retries (3) and backoff (1s, 2s, 4s)
    - _Requirements: 6.5_
  
  - [ ] 8.2 Implement comprehensive error responses
    - Map exceptions to HTTP status codes
    - Return structured error JSON
    - Include error codes and messages
    - _Requirements: 6.1, 6.2_
  
  - [ ] 8.3 Add CloudWatch error metrics
    - Publish custom metrics for errors
    - Track error rates by type
    - _Requirements: 6.2_

- [ ] 9. Testing and Validation
  - [ ] 9.1 Create unit tests for Lambda functions
    - Mock ServiceNow API responses
    - Mock TEAM GraphQL responses
    - Test error handling paths
    - _Requirements: All_
  
  - [ ] 9.2 Create integration test script
    - Deploy to dev environment
    - Run end-to-end test via CLI
    - Verify DynamoDB records
    - Verify ServiceNow ticket creation
    - Verify TEAM request creation
    - _Requirements: All_
  
  - [ ] 9.3 Test error scenarios
    - Test invalid input validation
    - Test ServiceNow API failures
    - Test TEAM API failures
    - Test authentication failures
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 10. Documentation and Demo Preparation
  - [ ] 10.1 Create deployment guide
    - Document prerequisites (AWS CLI, credentials)
    - Document CloudFormation deployment steps
    - Document CLI installation and configuration
    - _Requirements: 4.3_
  
  - [ ] 10.2 Create demo script
    - Write step-by-step demo walkthrough
    - Prepare sample data for demo
    - Test demo flow end-to-end
    - _Requirements: All_
  
  - [ ] 10.3 Create architecture diagram
    - Document component interactions
    - Document data flow
    - Export as PNG/PDF for presentation
    - _Requirements: All_
  
  - [ ] 10.4 Create troubleshooting guide
    - Document common errors and solutions
    - Document how to view CloudWatch logs
    - Document how to verify DynamoDB records
    - _Requirements: 6.2, 6.3_

- [ ] 11. CloudFormation Outputs and Finalization
  - [ ] 11.1 Add CloudFormation outputs
    - Output API Gateway endpoint URL
    - Output API key
    - Output DynamoDB table name
    - _Requirements: 4.3_
  
  - [ ] 11.2 Create stack deletion script
    - Document cleanup steps
    - Ensure all resources are removed
    - _Requirements: 4.4_
  
  - [ ] 11.3 Final end-to-end validation
    - Deploy fresh stack
    - Run complete demo flow
    - Verify all functionality
    - Delete stack and verify cleanup
    - _Requirements: All_

## Task Dependencies

```
1 (Setup)
├─> 2 (CloudFormation Core)
    ├─> 3 (Create Request Lambda)
    │   └─> 6 (API Gateway)
    │       └─> 7 (CLI Tool)
    │           └─> 9 (Testing)
    │               └─> 10 (Documentation)
    │                   └─> 11 (Finalization)
    ├─> 4 (Query Status Lambda)
    │   └─> 6 (API Gateway)
    └─> 5 (List Requests Lambda)
        └─> 6 (API Gateway)
    
8 (Error Handling) - Can be done in parallel with 3-5
```

## Estimated Effort

| Task | Estimated Hours |
|------|----------------|
| 1. Project Setup | 2 hours |
| 2. CloudFormation Core | 4 hours |
| 3. Create Request Lambda | 8 hours |
| 4. Query Status Lambda | 4 hours |
| 5. List Requests Lambda | 3 hours |
| 6. API Gateway | 3 hours |
| 7. CLI Tool | 6 hours |
| 8. Error Handling | 4 hours |
| 9. Testing | 6 hours |
| 10. Documentation | 4 hours |
| 11. Finalization | 2 hours |
| **Total** | **46 hours** |

## Daily Schedule (10 days)

**Day 1-2:** Tasks 1-2 (Setup + CloudFormation)  
**Day 3-4:** Task 3 (Create Request Lambda)  
**Day 5:** Tasks 4-5 (Query + List Lambdas)  
**Day 6:** Tasks 6-7 (API Gateway + CLI)  
**Day 7:** Task 8 (Error Handling)  
**Day 8:** Task 9 (Testing)  
**Day 9:** Task 10 (Documentation)  
**Day 10:** Task 11 (Finalization + Demo Prep)

## Success Checkpoints

- ✅ **Day 2:** CloudFormation deploys successfully
- ✅ **Day 4:** Can create request in ServiceNow and TEAM via Lambda
- ✅ **Day 6:** CLI can create and query requests
- ✅ **Day 8:** All error scenarios handled gracefully
- ✅ **Day 10:** Demo-ready with documentation

