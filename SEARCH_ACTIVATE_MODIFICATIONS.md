# Agentic DSTA Modifications for Search Activate Integration

This document tracks all modifications made to the `agentic_dsta` codebase for integration with the Search Activate project. These changes should be reviewed when upgrading to a new version of agentic_dsta.

## Summary of Changes

| File | Change Type | Description |
|------|-------------|-------------|
| `agents/decision_agent/agent.py` | Bug fix | Pass `LOCATION` to `DynamicMultiAPIToolset` |
| `agents/marketing_agent/agent.py` | Bug fix | Add `LOCATION` env var and pass to `DynamicMultiAPIToolset` |
| `agents/decision_agent/agent.py` | Feature | Add `dry_run` parameter support |
| `tools/google_ads/dry_run_updater.py` | New file | Dry-run updater toolset that simulates changes |
| `tools/google_ads/google_ads_client.py` | Bug fix | Fetch `login_customer_id` from Firestore for MCC support |
| `tools/google_ads/google_ads_updater.py` | Feature | Add action logging for real operations |
| `core/action_logger.py` | New file | Unified action logging for both dry-run and real runs |
| `core/run_logger.py` | New file | Run logging to Firestore |
| `main.py` | Feature | Add `dry_run`, `triggered_by` parameters and run history endpoints |

---

## Detailed Changes

### 1. `agentic_dsta/agents/decision_agent/agent.py`

**Issue:** `DynamicMultiAPIToolset()` was instantiated without the `location` parameter, defaulting to `us-central1` even though `GOOGLE_CLOUD_LOCATION` was already read from environment.

**Fix:** Pass the location to the toolset.

```python
# Before (line 57):
DynamicMultiAPIToolset(),

# After:
DynamicMultiAPIToolset(location=LOCATION),
```

---

### 2. `agentic_dsta/agents/marketing_agent/agent.py`

**Issue:** Same as above - `DynamicMultiAPIToolset()` defaulted to `us-central1`. Additionally, `LOCATION` variable was not defined in this file.

**Fix:** 
1. Add `LOCATION` environment variable reading
2. Pass location to the toolset

```python
# Added after line 32:
LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")

# Changed (line 44):
# Before:
DynamicMultiAPIToolset(),

# After:
DynamicMultiAPIToolset(location=LOCATION),
```

---

### 3. `agentic_dsta/tools/google_ads/google_ads_client.py` - MCC Support

**Issue:** The `get_google_ads_client()` function was using `customer_id` as `login_customer_id`, which fails when accessing sub-accounts under an MCC (Manager Customer Center).

**Fix:** Added `_get_login_customer_id()` function that fetches the `logincustomerid` from the Firestore `GoogleAdsConfig` collection and uses it when creating the client.

```python
# Added helper function:
def _get_login_customer_id(customer_id: str) -> str:
    """Fetch the login_customer_id from Firestore GoogleAdsConfig."""
    # Looks up GoogleAdsConfig/{customer_id} and returns logincustomerid field
    # Falls back to customer_id if not found

# Modified client creation:
login_customer_id = _get_login_customer_id(customer_id)
return google.ads.googleads.client.GoogleAdsClient(
    credentials,
    login_customer_id=login_customer_id,  # Was: customer_id
    developer_token=developer_token,
    use_proto_plus=True,
)
```

**Why this works:** Our Firestore sync (`agentic-firestore-sync.ts`) already writes the correct `logincustomerid` from PostgreSQL to Firestore when syncing configs.

---

### 4. `agentic_dsta/tools/google_ads/dry_run_updater.py` (NEW FILE)

**Purpose:** Provides a dry-run version of Google Ads updater tools that simulate changes without executing them.

**Key Components:**
- `DryRunGoogleAdsUpdaterToolset`: A toolset that mirrors `GoogleAdsUpdaterToolset` but logs actions instead of executing them
- `clear_dry_run_actions()`: Clears the collected actions list
- `get_dry_run_actions()`: Returns the collected actions
- Individual dry-run functions for each update operation

**To recreate after upgrade:**
1. Create the file `tools/google_ads/dry_run_updater.py`
2. Copy all update functions from `google_ads_updater.py` but replace actual API calls with logging
3. Maintain same function signatures for compatibility
4. Use the unified action logger (`core/action_logger.py`) for logging

---

### 5. `agentic_dsta/core/action_logger.py` (NEW FILE)

**Purpose:** Provides unified action logging that works for both dry-run and real runs. This enables tracking of all changes made by the agent, regardless of mode.

**Key Components:**
- `log_action()`: Log an action (simulated or real)
- `clear_actions()`: Clear actions at start of a run
- `get_actions()`: Get all logged actions
- `get_action_count()`: Get count of logged actions

**Usage:**
```python
from agentic_dsta.core.action_logger import log_action, clear_actions, get_actions

# At start of run
clear_actions()

# After each successful operation
log_action(
    tool_name="update_google_ads_campaign_status",
    params={"customer_id": "123", "campaign_id": "456", "status": "PAUSED"},
    description="Paused campaign 456",
    simulated=False,  # True for dry-run
    result={"success": True, "resource_name": "..."}
)

# At end of run
actions = get_actions()
```

**To recreate after upgrade:**
1. Create the file `core/action_logger.py`
2. Implement thread-safe action storage

---

### 6. `agentic_dsta/tools/google_ads/google_ads_updater.py` - Action Logging

**Purpose:** Added action logging to real Google Ads updater functions so that both dry-run and real runs track their actions.

**Changes:**
1. Import action logger: `from agentic_dsta.core.action_logger import log_action`
2. Add `log_action()` calls after each successful API mutation

**Functions modified:**
- `update_google_ads_campaign_status()`
- `update_google_ads_campaign_budget()`
- `update_google_ads_bidding_strategy()`
- `update_google_ads_campaign_geo_targets()`
- `update_google_ads_ad_group_geo_targets()`
- `update_google_ads_shared_budget()`
- `update_google_ads_portfolio_bidding_strategy()`

**To recreate after upgrade:**
1. Add import for action_logger
2. Add `log_action()` call after each successful mutation, before returning result

---

### 7. `agentic_dsta/core/run_logger.py` (NEW FILE)

**Purpose:** Provides run logging functionality that stores run history in Firestore.

**Key Components:**
- `log_run_start()`: Creates a new run record
- `log_run_action()`: Appends an action to a run
- `log_run_complete()`: Marks a run as complete with summary
- `get_run_history()`: Gets run history for a customer
- `get_run_by_id()`: Gets a specific run's details

**Firestore Collection:** `AgenticRunLogs`

**Required Firestore Index:** This feature requires a composite index. See the 
"Required Firestore Indexes" section below for setup instructions.

**To recreate after upgrade:**
1. Create the file `core/run_logger.py`
2. Implement the logging functions as documented

---

### 8. `agentic_dsta/agents/decision_agent/agent.py` - Dry-Run Support

**Changes:**
1. Import dry-run updater and run logger
2. Add `dry_run` parameter to `create_agent()` function
3. Add `dry_run` and `triggered_by` parameters to `run_decision_agent()` function
4. Return run results instead of None
5. Log run start/completion

**Code changes (search for `SEARCH_ACTIVATE_MODIFICATION` comments):**

```python
# Imports added:
from agentic_dsta.tools.google_ads.dry_run_updater import DryRunGoogleAdsUpdaterToolset
from agentic_dsta.core.action_logger import clear_actions, get_actions
from agentic_dsta.core.run_logger import log_run_start, log_run_complete

# create_agent signature changed:
def create_agent(instruction: str, model: str = DEFAULT_MODEL, dry_run: bool = False) -> agents.LlmAgent:

# Inside create_agent:
updater_toolset = DryRunGoogleAdsUpdaterToolset() if dry_run else GoogleAdsUpdaterToolset()

# run_decision_agent signature changed:
async def run_decision_agent(
    customer_id: str, 
    usecase: Optional[str] = "GoogleAds",
    dry_run: bool = False,
    triggered_by: str = "scheduler"
) -> dict:

# At start of run:
clear_actions()  # Clears action log for both modes

# At end of run:
actions = get_actions()  # Gets all logged actions (both simulated and real)
```

---

### 9. `agentic_dsta/main.py` - API Changes

**Changes:**
1. Import run logger functions
2. Add `dry_run` and `triggered_by` parameters to `/scheduler/init_and_run` endpoint
3. Add new endpoints for run history

**New Endpoints:**
- `GET /runs/{customer_id}`: Get run history for a customer
- `GET /runs/{customer_id}/{run_id}`: Get details of a specific run

**To recreate after upgrade:**
1. Search for `SEARCH_ACTIVATE_MODIFICATION` comments
2. Re-apply the parameter additions to `/scheduler/init_and_run`
3. Re-add the run history endpoints

---

## When Upgrading agentic_dsta

When upgrading to a new version of agentic_dsta:

### Step-by-Step Upgrade Process

1. **Backup current modifications**: Copy the modified files before upgrading
2. **Apply the upgrade**: Update the agentic_dsta codebase
3. **Re-apply API Hub location fixes**: 
   - Check if upstream has fixed the API Hub location issue
   - If not, search for `DynamicMultiAPIToolset()` calls and ensure they pass `location=LOCATION`
4. **Copy new files**: 
   - Copy `tools/google_ads/dry_run_updater.py` to the new version
   - Copy `core/run_logger.py` to the new version
5. **Re-apply google_ads_client.py changes**:
   - Add `_get_login_customer_id()` helper function
   - Modify `get_google_ads_client()` to use the helper
6. **Re-apply agent.py changes**:
   - Add imports for dry-run updater and run logger
   - Add `dry_run` parameter to `create_agent()` and `run_decision_agent()`
   - Add run logging calls
7. **Re-apply main.py changes**:
   - Add `dry_run` and `triggered_by` parameters to `/scheduler/init_and_run`
   - Add run history endpoints
8. **Test**: Run with `dry_run=True` to verify everything works

### Quick Verification

After upgrade, search for `SEARCH_ACTIVATE_MODIFICATION` in the codebase. All our custom changes are marked with this comment.

```bash
grep -r "SEARCH_ACTIVATE_MODIFICATION" agentic_dsta/
```

## Required Firestore Indexes

The run logging feature requires a composite index on the `AgenticRunLogs` collection.
This must be created for each new environment.

### Option 1: Create via gcloud CLI

```bash
gcloud firestore indexes composite create \
  --project=YOUR_PROJECT_ID \
  --database=agentic-dsta-firestore \
  --collection-group=AgenticRunLogs \
  --field-config field-path=customer_id,order=ascending \
  --field-config field-path=started_at,order=descending
```

### Option 2: Create via Firebase Console

If the index doesn't exist, the first query will fail with an error message containing
a direct link to create the index. Click the link to create it automatically.

### Option 3: Create via firestore.indexes.json

Add this to your Firestore configuration:

```json
{
  "indexes": [
    {
      "collectionGroup": "AgenticRunLogs",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "customer_id", "order": "ASCENDING" },
        { "fieldPath": "started_at", "order": "DESCENDING" }
      ]
    }
  ]
}
```

Then deploy with: `firebase deploy --only firestore:indexes`

---

## Environment Variables Required

The following environment variables must be set for proper operation:

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_CLOUD_PROJECT` | GCP project ID | `search-activate` |
| `GOOGLE_CLOUD_LOCATION` | GCP region for Vertex AI and API Hub | `europe-west1` |
| `FIRESTORE_DB` | Firestore database name | `agentic-dsta-firestore` |
| `GOOGLE_ADS_DEVELOPER_TOKEN` | Google Ads API developer token | |
| `GOOGLE_API_KEY` | **Required** for Weather, Pollen, Air Quality APIs | |

**Creating the API Key:**
1. Go to Google Cloud Console > APIs & Services > Credentials
2. Click "Create Credentials" > "API Key"
3. Restrict the key to: Weather API, Pollen API, Air Quality API
4. Add to `.env`: `GOOGLE_API_KEY=your-api-key`

---

## API Usage Examples

### Running with Dry-Run Mode

```bash
# Dry run - simulate changes without applying them
curl -X POST http://localhost:8002/scheduler/init_and_run \
  -H "Content-Type: application/json" \
  -d '{
    "app_name": "decision_agent",
    "customer_id": "1234567890",
    "usecase": "GoogleAds",
    "dry_run": true,
    "triggered_by": "manual"
  }'

# Response includes simulated actions:
# {
#   "status": "success",
#   "run_id": "abc123",
#   "dry_run": true,
#   "actions": [
#     {
#       "timestamp": "2026-02-05T12:00:00.000Z",
#       "tool": "update_google_ads_campaign_status",
#       "params": {"customer_id": "1234567890", "campaign_id": "999", "status": "PAUSED"},
#       "description": "Change campaign 999 status to PAUSED",
#       "simulated": true
#     }
#   ]
# }
```

### Getting Run History

```bash
# Get recent runs for a customer
curl http://localhost:8002/runs/1234567890?limit=10&include_dry_runs=true

# Get details of a specific run
curl http://localhost:8002/runs/1234567890/abc123
```

---

*Last updated: 2026-02-13*
