#!/bin/bash
set -e

PROJECT_ID=$1
LOCATION=$2
SPECS_DIR=$3

echo "Initializing API Hub in project $PROJECT_ID location $LOCATION"
echo "Specs dir: $SPECS_DIR"

ACCESS_TOKEN=$(gcloud auth print-access-token)
API_HUB_URL="https://apihub.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION"

create_api() {
  local api_id=$1
  local display_name=$2
  
  echo "Creating API: $api_id"
  curl -s -X POST "$API_HUB_URL/apis?apiId=$api_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"displayName\": \"$display_name\",
      \"owner\": {
         \"email\": \"$(gcloud config get-value account)\" 
      }
    }" || echo "API $api_id may already exist (ignoring error)"
}

create_version() {
  local api_id=$1
  local version_id=$2
  local display_name=$3
  
  echo "Creating Version: $version_id for API $api_id"
  curl -s -X POST "$API_HUB_URL/apis/$api_id/versions?versionId=$version_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"displayName\": \"$display_name\"
    }" || echo "Version $version_id may already exist"
}

create_spec() {
  local api_id=$1
  local version_id=$2
  local spec_id=$3
  local spec_file=$4
  
  echo "Creating Spec: $spec_id for Version $version_id"
  
  # Read and base64 encode content (for safety in JSON, though 'contents' field might prefer raw bytes if not JSON? 
  # API Hub spec says 'contents' is 'bytes'. In JSON REST, bytes are base64 encoded.
  local content_b64=$(base64 -w 0 < "$spec_file")
  
  curl -s -X POST "$API_HUB_URL/apis/$api_id/versions/$version_id/specs?specId=$spec_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"contents\": {
        \"contents\": \"$content_b64\",
        \"mimeType\": \"application/yaml\"
      },
      \"specType\": \"projects/$PROJECT_ID/locations/$LOCATION/specTypes/openapi\"
    }" || echo "Spec $spec_id creation failed (possibly exists)"
}

# Pollen API
create_api "pollen-api" "Google Pollen API"
create_version "pollen-api" "v1" "Version 1"
create_spec "pollen-api" "v1" "openapi-spec" "$SPECS_DIR/pollen-api-openapi.yaml"

# Weather API
create_api "weather-api" "Google Weather API"
create_version "weather-api" "v1" "Version 1"
create_spec "weather-api" "v1" "openapi-spec" "$SPECS_DIR/weather-api-openapi.yaml"

echo "API Hub initialization complete."
