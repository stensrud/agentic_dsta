# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Shared utility for initializing the Google Ads API client."""

import os
import google.ads.googleads.client
from google.ads.googleads.errors import GoogleAdsException
import logging
from agentic_dsta.tools import auth_utils
# SEARCH_ACTIVATE_MODIFICATION: Import Firestore for login_customer_id lookup
from agentic_dsta.tools.firestore.firestore_toolset import FirestoreToolset

logger = logging.getLogger(__name__)

# SEARCH_ACTIVATE_MODIFICATION: Cache for login_customer_id lookups
_login_customer_id_cache: dict = {}

def _get_login_customer_id(customer_id: str) -> str:
    """
    Fetch the login_customer_id from Firestore GoogleAdsConfig.
    
    SEARCH_ACTIVATE_MODIFICATION: This function was added to support MCC accounts.
    When accessing sub-accounts under an MCC, the login_customer_id header must be
    set to the MCC ID, not the sub-account ID.
    
    Args:
        customer_id: The Google Ads customer ID.
    
    Returns:
        The login_customer_id to use (MCC ID), or customer_id if not found.
    """
    # Check cache first
    if customer_id in _login_customer_id_cache:
        return _login_customer_id_cache[customer_id]
    
    try:
        firestore_toolset = FirestoreToolset()
        doc = firestore_toolset.get_document(collection="GoogleAdsConfig", document_id=customer_id)
        if doc and doc.get("data"):
            login_id = doc["data"].get("logincustomerid")
            if login_id:
                # Convert to string and remove any hyphens
                login_id = str(login_id).replace("-", "")
                _login_customer_id_cache[customer_id] = login_id
                logger.info(
                    "Using login_customer_id from Firestore config",
                    extra={"customer_id": customer_id, "login_customer_id": login_id}
                )
                return login_id
    except Exception as e:
        logger.warning(
            "Failed to fetch login_customer_id from Firestore, using customer_id: %s",
            e,
            extra={"customer_id": customer_id}
        )
    
    # Fallback to using customer_id as login_customer_id
    _login_customer_id_cache[customer_id] = customer_id
    return customer_id


def get_google_ads_client(customer_id: str):
  logger.debug("get_google_ads_client called", extra={'customer_id': customer_id})
  """Initializes and returns a GoogleAdsClient.\n\n  Authentication is controlled by auth_utils.get_credentials, potentially using\n  the GOOGLE_ADS_FORCE_USER_CREDS environment variable to force user creds\n  from Secret Manager.\n  """
  scopes = ["https://www.googleapis.com/auth/adwords"]
  try:
      credentials = auth_utils.get_credentials(
          scopes=scopes,
          service_name="Google Ads",
          force_user_creds_env="GOOGLE_ADS_FORCE_USER_CREDS"
      )

      if not credentials:
          logger.error("Failed to obtain credentials for Google Ads client")
          return None

      developer_token = os.environ.get("GOOGLE_ADS_DEVELOPER_TOKEN")
      if not developer_token:
          logger.error("GOOGLE_ADS_DEVELOPER_TOKEN not set in environment.")
          return None

      # SEARCH_ACTIVATE_MODIFICATION: Fetch login_customer_id from Firestore config
      login_customer_id = _get_login_customer_id(customer_id)
      
      return google.ads.googleads.client.GoogleAdsClient(
          credentials,
          login_customer_id=login_customer_id,
          developer_token=developer_token,
          use_proto_plus=True,
      )
  except GoogleAdsException as ex:
    logger.error(
        "Failed to create GoogleAdsClient",
        exc_info=True,
        extra={'customer_id': customer_id}
    )
    if hasattr(ex, 'failure') and ex.failure:
      for error in ex.failure.errors:
        logger.error(
            "Google Ads API Error: %s - %s",
            error.error_code,
            error.message,
            extra={
                'customer_id': customer_id,
                'error_code': str(error.error_code),
                'error_message': error.message
            }
        )
    return None
  except Exception as e:
      logger.exception(f"Error creating GoogleAdsClient: {e}")
      return None
