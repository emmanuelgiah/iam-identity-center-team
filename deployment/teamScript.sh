#!/bin/bash

# Get machine auth token
MACHINE_TOKEN=$(curl -s -X POST \
  'https://d3qaq330ewovw8-main.auth.us-east-1.amazoncognito.com/oauth2/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials' \
  -d 'client_id=6vbng6fgo3l0ascddmlbnnfoam' \
  -d 'client_secret=1embi9qr3e3ulp42mdr98linn3hmf7ibadeqi904crb8vms75q0d' \
  -d 'scope=api/admin' | jq -r '.access_token')

# Function to test a GraphQL operation
test_operation() {
  local name="$1"
  local query="$2"
  
  echo "=== Testing $name ==="
  result=$(curl -s -X POST \
    'https://hb5bn3l4pbg57nwjmdu7bkllzy.appsync-api.us-east-1.amazonaws.com/graphql' \
    -H "Authorization: $MACHINE_TOKEN" \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://main.d3qaq330ewovw8.amplifyapp.com' \
    -d "{\"query\": \"$query\"}")
  
  if echo "$result" | grep -q "errors"; then
    echo "❌ $name FAILED"
    echo "Error message:"
    echo "$result" | jq '.errors[0].message'
  else
    echo "✅ $name WORKS with machine auth"
    echo "Response data:"
    echo "$result" | jq '.data'
  fi
  echo "Full response:"
  echo "$result" | jq '.'
  echo "==============================="
  echo ""
}

# Test queries
test_operation "listRequests" "query { listRequests(limit: 5) { items { id email status createdAt } } }"
test_operation "getAccounts" "query { getAccounts }"
test_operation "getPermissions" "query { getPermissions }"
test_operation "getIdCGroups" "query { getIdCGroups }"
test_operation "getUsers" "query { getUsers }"
test_operation "listSettings" "query { listSettings { items { id value } } }"
test_operation "listApprovers" "query { listApprovers { items { id } } }"
test_operation "listEligibilities" "query { listEligibilities { items { id } } }"

# Test mutations
test_operation "publishPermissions" "mutation { publishPermissions }"
test_operation "publishOUs" "mutation { publishOUs }"
test_operation "publishPolicy" "mutation { publishPolicy }"

# Test additional operations that might work
test_operation "getSettings" "query { getSettings(id: \"default\") { id value } }"
test_operation "validateRequest" "query { validateRequest }"
test_operation "updateRequestData" "query { updateRequestData }"
