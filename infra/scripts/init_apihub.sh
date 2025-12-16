#!/bin/sh
set -e

PROJECT_ID=$1
LOCATION=$2
SPECS_DIR=$3

echo "Initializing API Hub in project $PROJECT_ID location $LOCATION"
echo "Specs dir: $SPECS_DIR"

if [ -z "$ACCOUNT_EMAIL" ]; then
  echo "Error: ACCOUNT_EMAIL environment variables must be set."
  exit 1
fi


if [ -z "$ACCESS_TOKEN" ]; then
  echo "Error: Failed to retrieve access token for $ACCOUNT_EMAIL."
  exit 1
fi

# Source variables
. "$(dirname "$0")/apihub_vars.sh"

API_HUB_URL="https://apihub.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION"

create_api() {
  local api_id=$1
  local display_name=$2

  echo "Creating API: $api_id"
  curl -s -k -X POST "$API_HUB_URL/apis?apiId=$api_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"displayName\": \"$display_name\",
      \"owner\": {
         \"email\": \"$ACCOUNT_EMAIL\"
      }
    }" || echo "API $api_id creation possibly failed or already exists"
}

create_version() {
  local api_id=$1
  local version_id=$2
  local display_name=$3

  echo "Creating Version: $version_id for API $api_id"
  curl -s -k -X POST "$API_HUB_URL/apis/$api_id/versions?versionId=$version_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"displayName\": \"$display_name\"
    }" || echo "Version $version_id for API $api_id creation possibly failed or already exists"
}

create_spec() {
  local api_id=$1
  local version_id=$2
  local spec_id=$3
  local spec_file=$4

  echo "Creating Spec: $spec_id for API $api_id Version $version_id"

  if [ ! -f "$spec_file" ]; then
    echo "Error: Spec file not found: $spec_file"
    return 1
  fi

  content_b64=$(base64 -w 0 < "$spec_file")

  SPEC_TYPE_ATTR_NAME="projects/$PROJECT_ID/locations/$LOCATION/attributes/$SPEC_TYPE_ATTRIBUTE_ID"

  # JSON payload for creating the spec
  JSON_PAYLOAD=$(cat <<EOF
{
  "displayName": "$SPEC_DISPLAY_NAME_PREFIX $api_id",
  "specType": {
    "attribute": "$SPEC_TYPE_ATTR_NAME",
    "enumValues": {
      "values": [{"id": "$SPEC_TYPE_ID"}]
    }
  },
  "contents": {
    "contents": "$content_b64",
    "mimeType": "$SPEC_MIME_TYPE"
  }
}
EOF
)

  echo "Payload for $spec_id:"
  echo "$JSON_PAYLOAD"

  curl -s -k -X POST "$API_HUB_URL/apis/$api_id/versions/$version_id/specs?specId=$spec_id" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" || echo "Spec $spec_id creation failed for API $api_id Version $version_id"
}

# Pollen API
create_api "$POLLEN_API_ID" "$POLLEN_API_DISPLAY_NAME"
create_version "$POLLEN_API_ID" "$API_VERSION_ID" "$API_VERSION_DISPLAY_NAME"
create_spec "$POLLEN_API_ID" "$API_VERSION_ID" "$API_SPEC_ID" "$SPECS_DIR/$POLLEN_API_SPEC_FILE"

# Weather API
create_api "$WEATHER_API_ID" "$WEATHER_API_DISPLAY_NAME"
create_version "$WEATHER_API_ID" "$API_VERSION_ID" "$API_VERSION_DISPLAY_NAME"
create_spec "$WEATHER_API_ID" "$API_VERSION_ID" "$API_SPEC_ID" "$SPECS_DIR/$WEATHER_API_SPEC_FILE"

# Air Quality API
create_api "$AIR_QUALITY_API_ID" "$AIR_QUALITY_API_DISPLAY_NAME"
create_version "$AIR_QUALITY_API_ID" "$API_VERSION_ID" "$API_VERSION_DISPLAY_NAME"
create_spec "$AIR_QUALITY_API_ID" "$API_VERSION_ID" "$API_SPEC_ID" "$SPECS_DIR/$AIR_QUALITY_API_SPEC_FILE"

echo "API Hub initialization complete."
