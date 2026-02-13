#!/bin/bash
# Agentic DSTA Prerequisites Verification Script
# This script checks if all required GCP services, APIs, and permissions are in place.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Find the project root and .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/app/.env"

# Load variables from .env file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "Loading configuration from: $ENV_FILE"
    # Export variables from .env file (ignore comments and empty lines)
    set -a
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        # Remove any leading/trailing whitespace and quotes
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
        # Only export if key is valid
        if [[ $key =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            export "$key=$value"
        fi
    done < "$ENV_FILE"
    set +a
    echo ""
else
    echo -e "${YELLOW}Warning: .env file not found at $ENV_FILE${NC}"
    echo "Falling back to environment variables and gcloud config"
    echo ""
fi

# Get project ID from .env, environment, or gcloud config
PROJECT_ID="${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${VERTEX_AI_LOCATION:-${GOOGLE_CLOUD_LOCATION:-europe-west1}}"
SERVICE_ACCOUNT="${GOOGLE_ADS_SUBJECT_EMAIL:-}"

echo "=============================================="
echo "Agentic DSTA Prerequisites Verification"
echo "=============================================="
echo ""
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service Account: ${SERVICE_ACCOUNT:-<will auto-detect>}"
echo ""

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No project ID found. Set GOOGLE_CLOUD_PROJECT or run 'gcloud config set project <project-id>'${NC}"
    exit 1
fi

# Function to check if an API is enabled
check_api() {
    local api=$1
    local description=$2
    
    if gcloud services list --enabled --project="$PROJECT_ID" 2>/dev/null | grep -q "$api"; then
        echo -e "${GREEN}✓${NC} API enabled: $description ($api)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} API NOT enabled: $description ($api)"
        ((FAILED++))
        return 1
    fi
}

# Function to check if a role is granted to the service account
check_role() {
    local role=$1
    local sa_email=$2
    
    if gcloud projects get-iam-policy "$PROJECT_ID" --format="json" 2>/dev/null | \
       grep -q "\"role\": \"$role\"" && \
       gcloud projects get-iam-policy "$PROJECT_ID" --format="json" 2>/dev/null | \
       grep -q "$sa_email"; then
        echo -e "${GREEN}✓${NC} Role granted: $role"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} Role NOT granted: $role"
        ((FAILED++))
        return 1
    fi
}

# Function to check if a secret exists
check_secret() {
    local secret_name=$1
    
    if gcloud secrets describe "$secret_name" --project="$PROJECT_ID" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Secret exists: $secret_name"
        ((PASSED++))
        return 0
    else
        echo -e "${YELLOW}!${NC} Secret NOT found: $secret_name (may need to be created)"
        ((WARNINGS++))
        return 1
    fi
}

echo "=============================================="
echo "1. Checking Required APIs"
echo "=============================================="

# Core APIs (likely already enabled)
check_api "run.googleapis.com" "Cloud Run" || true
check_api "artifactregistry.googleapis.com" "Artifact Registry" || true
check_api "secretmanager.googleapis.com" "Secret Manager" || true
check_api "aiplatform.googleapis.com" "Vertex AI" || true
check_api "googleads.googleapis.com" "Google Ads API" || true

echo ""
echo "--- APIs needed for Agentic DSTA ---"

# Agentic DSTA specific APIs
check_api "firestore.googleapis.com" "Firestore" || true
check_api "apihub.googleapis.com" "API Hub" || true
check_api "weather.googleapis.com" "Weather API" || true
check_api "pollen.googleapis.com" "Pollen API" || true
check_api "airquality.googleapis.com" "Air Quality API" || true

echo ""
echo "=============================================="
echo "2. Checking Firestore Database"
echo "=============================================="

# Check if Firestore database exists
FIRESTORE_DB="${FIRESTORE_DB:-agentic-dsta-firestore}"
if gcloud firestore databases describe --database="$FIRESTORE_DB" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Firestore database exists: $FIRESTORE_DB"
    ((PASSED++))
elif gcloud firestore databases describe --database="(default)" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${YELLOW}!${NC} Default Firestore database exists, but '$FIRESTORE_DB' does not"
    echo "   You may want to create a dedicated database or use (default)"
    ((WARNINGS++))
else
    echo -e "${RED}✗${NC} No Firestore database found"
    echo "   Create with: gcloud firestore databases create --database=$FIRESTORE_DB --location=$REGION --type=firestore-native"
    ((FAILED++))
fi

echo ""
echo "=============================================="
echo "3. Checking Secret Manager Secrets"
echo "=============================================="

check_secret "GOOGLE_ADS_DEVELOPER_TOKEN" || true
check_secret "GOOGLE_API_KEY" || true
check_secret "USER_CLIENT_ID" || true
check_secret "USER_CLIENT_SECRET" || true
check_secret "USER_REFRESH_TOKEN" || true

echo ""
echo "=============================================="
echo "4. Checking IAM Roles"
echo "=============================================="

# Use service account from .env if available, otherwise try to find one
SA_EMAIL="${SERVICE_ACCOUNT:-}"

if [ -z "$SA_EMAIL" ]; then
    echo "No service account in .env, trying to auto-detect..."
    for sa in "agentic-dsta-runner@${PROJECT_ID}.iam.gserviceaccount.com" \
              "search-activate@${PROJECT_ID}.iam.gserviceaccount.com" \
              "${PROJECT_ID}@appspot.gserviceaccount.com"; do
        if gcloud iam service-accounts describe "$sa" --project="$PROJECT_ID" &>/dev/null; then
            SA_EMAIL="$sa"
            break
        fi
    done
fi

if [ -n "$SA_EMAIL" ]; then
    echo "Checking roles for service account: $SA_EMAIL"
    echo ""
    
    # Get all role bindings for this service account directly
    # This approach queries each role individually which is more reliable
    
    for role in "roles/datastore.user" \
                "roles/secretmanager.secretAccessor" \
                "roles/run.invoker" \
                "roles/aiplatform.admin" \
                "roles/apihub.admin"; do
        
        # Use gcloud to check if the SA has this specific role
        BINDING=$(gcloud projects get-iam-policy "$PROJECT_ID" \
            --flatten="bindings[].members" \
            --filter="bindings.role=$role AND bindings.members=serviceAccount:$SA_EMAIL" \
            --format="value(bindings.role)" 2>/dev/null)
        
        if [ -n "$BINDING" ]; then
            echo -e "${GREEN}✓${NC} Role granted: $role"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} Role NOT granted: $role"
            ((FAILED++))
        fi
    done
else
    echo -e "${YELLOW}!${NC} Could not find a service account to check roles for"
    echo "   Expected one of:"
    echo "   - agentic-dsta-runner@${PROJECT_ID}.iam.gserviceaccount.com"
    echo "   - search-activate@${PROJECT_ID}.iam.gserviceaccount.com"
    ((WARNINGS++))
fi

echo ""
echo "=============================================="
echo "5. Checking Cloud Run Services"
echo "=============================================="

# Check if search-activate service exists
if gcloud run services describe search-activate --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Cloud Run service exists: search-activate"
    ((PASSED++))
else
    echo -e "${YELLOW}!${NC} Cloud Run service 'search-activate' not found in $REGION"
    ((WARNINGS++))
fi

# Check if agentic-dsta service exists
if gcloud run services describe agentic-dsta --region="$REGION" --project="$PROJECT_ID" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Cloud Run service exists: agentic-dsta"
    ((PASSED++))
else
    echo -e "${YELLOW}!${NC} Cloud Run service 'agentic-dsta' not found (expected - needs to be deployed)"
    ((WARNINGS++))
fi

echo ""
echo "=============================================="
echo "6. Checking API Hub (if enabled)"
echo "=============================================="

if gcloud services list --enabled --project="$PROJECT_ID" 2>/dev/null | grep -q "apihub.googleapis.com"; then
    # Try to list APIs in API Hub
    if gcloud alpha apihub apis list --location="$REGION" --project="$PROJECT_ID" &>/dev/null; then
        API_COUNT=$(gcloud alpha apihub apis list --location="$REGION" --project="$PROJECT_ID" --format="value(name)" 2>/dev/null | wc -l)
        if [ "$API_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} API Hub has $API_COUNT registered APIs"
            ((PASSED++))
        else
            echo -e "${YELLOW}!${NC} API Hub is enabled but has no registered APIs"
            echo "   Run: cd agentic_dsta/infra/scripts/apihub && ./init_apihub.sh $PROJECT_ID $REGION ../config/specs"
            ((WARNINGS++))
        fi
    else
        echo -e "${YELLOW}!${NC} Could not query API Hub (may need 'gcloud alpha' component or different permissions)"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}!${NC} API Hub API not enabled - skipping API Hub checks"
    ((WARNINGS++))
fi

echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="
echo ""
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All critical checks passed!${NC}"
    echo "You can proceed with the integration."
    exit 0
else
    echo -e "${RED}Some critical checks failed.${NC}"
    echo "Please address the failed items before proceeding."
    echo ""
    echo "To enable missing APIs:"
    echo "  gcloud services enable <api-name> --project=$PROJECT_ID"
    echo ""
    echo "To grant missing roles:"
    echo "  gcloud projects add-iam-policy-binding $PROJECT_ID \\"
    echo "    --member='serviceAccount:<sa-email>' \\"
    echo "    --role='<role-name>'"
    exit 1
fi
