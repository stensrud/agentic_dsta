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
"""
Dry-run version of Google Ads updater tools.

These tools simulate changes without actually applying them to Google Ads.
They log what would have happened and return simulated success responses.

SEARCH_ACTIVATE_MODIFICATION: This file was added for dry-run support.
"""

import logging
from typing import Any, Dict, List, Optional

from google.adk.tools.base_toolset import BaseToolset
from google.adk.tools.function_tool import FunctionTool

# SEARCH_ACTIVATE_MODIFICATION: Use unified action logger
from agentic_dsta.core.action_logger import log_action as _unified_log_action, clear_actions, get_actions

logger = logging.getLogger(__name__)


def clear_dry_run_actions():
    """Clear the collected dry-run actions."""
    clear_actions()


def get_dry_run_actions() -> List[Dict[str, Any]]:
    """Get the collected dry-run actions."""
    return get_actions()


def _log_action(tool_name: str, params: Dict[str, Any], description: str) -> Dict[str, Any]:
    """Log a dry-run action and return simulated success."""
    _unified_log_action(
        tool_name=tool_name,
        params=params,
        description=description,
        simulated=True
    )
    logger.info(
        "[DRY-RUN] Would execute %s: %s",
        tool_name,
        description,
        extra={"params": params}
    )
    return {
        "success": True,
        "dry_run": True,
        "message": f"[DRY-RUN] {description}",
        "resource_name": f"simulated/{params.get('campaign_id', 'unknown')}"
    }


def dry_run_update_campaign_status(customer_id: str, campaign_id: str, status: str) -> Dict[str, Any]:
    """[DRY-RUN] Simulates enabling or pausing a Google Ads campaign.
    
    This is a dry-run version that logs the action without making actual changes.
    
    Args:
        customer_id: The Google Ads customer ID (without hyphens).
        campaign_id: The ID of the campaign to update.
        status: The desired status ("ENABLED" or "PAUSED").
    
    Returns:
        A dictionary indicating simulated success.
    """
    return _log_action(
        "update_google_ads_campaign_status",
        {"customer_id": customer_id, "campaign_id": campaign_id, "status": status},
        f"Change campaign {campaign_id} status to {status}"
    )


def dry_run_update_campaign_budget(
    customer_id: str, campaign_id: str, new_budget_micros: int
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating the budget for a Google Ads campaign.
    
    This is a dry-run version that logs the action without making actual changes.
    
    Args:
        customer_id: The Google Ads customer ID (without hyphens).
        campaign_id: The ID of the campaign to update.
        new_budget_micros: The new budget amount in micros.
    
    Returns:
        A dictionary indicating simulated success.
    """
    budget_amount = new_budget_micros / 1_000_000
    return _log_action(
        "update_google_ads_campaign_budget",
        {"customer_id": customer_id, "campaign_id": campaign_id, "new_budget_micros": new_budget_micros},
        f"Change campaign {campaign_id} budget to ${budget_amount:.2f}"
    )


def dry_run_update_campaign_geo_targets(
    customer_id: str,
    campaign_id: str,
    location_ids: List[str],
    negative: bool = False,
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating geo targeting for a Google Ads campaign.
    
    Args:
        customer_id: The Google Ads customer ID.
        campaign_id: The ID of the campaign to update.
        location_ids: A list of location IDs.
        negative: If True, sets as negative targets.
    
    Returns:
        A dictionary indicating simulated success.
    """
    target_type = "negative" if negative else "positive"
    return _log_action(
        "update_google_ads_campaign_geo_targets",
        {"customer_id": customer_id, "campaign_id": campaign_id, "location_ids": location_ids, "negative": negative},
        f"Update campaign {campaign_id} {target_type} geo targets to {location_ids}"
    )


def dry_run_update_ad_group_geo_targets(
    customer_id: str,
    ad_group_id: str,
    location_ids: List[str],
    negative: bool = False,
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating geo targeting for a Google Ads ad group.
    
    Args:
        customer_id: The Google Ads customer ID.
        ad_group_id: The ID of the ad group to update.
        location_ids: A list of location IDs.
        negative: If True, sets as negative targets.
    
    Returns:
        A dictionary indicating simulated success.
    """
    target_type = "negative" if negative else "positive"
    return _log_action(
        "update_google_ads_ad_group_geo_targets",
        {"customer_id": customer_id, "ad_group_id": ad_group_id, "location_ids": location_ids, "negative": negative},
        f"Update ad group {ad_group_id} {target_type} geo targets to {location_ids}"
    )


def dry_run_update_bidding_strategy(
    customer_id: str,
    campaign_id: str,
    strategy_type: str,
    strategy_details: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating the bidding strategy for a campaign.
    
    Args:
        customer_id: The Google Ads customer ID.
        campaign_id: The ID of the campaign to update.
        strategy_type: The target bidding strategy type.
        strategy_details: Optional strategy details.
    
    Returns:
        A dictionary indicating simulated success.
    """
    return _log_action(
        "update_google_ads_bidding_strategy",
        {"customer_id": customer_id, "campaign_id": campaign_id, "strategy_type": strategy_type, "strategy_details": strategy_details},
        f"Change campaign {campaign_id} bidding strategy to {strategy_type}"
    )


def dry_run_update_shared_budget(
    customer_id: str,
    budget_resource_name: str,
    new_amount_micros: int
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating a shared budget.
    
    Args:
        customer_id: The Google Ads customer ID.
        budget_resource_name: The resource name of the shared budget.
        new_amount_micros: The new budget amount in micros.
    
    Returns:
        A dictionary indicating simulated success.
    """
    budget_amount = new_amount_micros / 1_000_000
    return _log_action(
        "update_google_ads_shared_budget",
        {"customer_id": customer_id, "budget_resource_name": budget_resource_name, "new_amount_micros": new_amount_micros},
        f"Change shared budget {budget_resource_name} to ${budget_amount:.2f}"
    )


def dry_run_update_portfolio_bidding_strategy(
    customer_id: str,
    bidding_strategy_resource_name: str,
    strategy_type: str,
    strategy_details: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """[DRY-RUN] Simulates updating a portfolio bidding strategy.
    
    Args:
        customer_id: The Google Ads customer ID.
        bidding_strategy_resource_name: The resource name of the strategy.
        strategy_type: The new bidding strategy type.
        strategy_details: Optional strategy details.
    
    Returns:
        A dictionary indicating simulated success.
    """
    return _log_action(
        "update_google_ads_portfolio_bidding_strategy",
        {"customer_id": customer_id, "bidding_strategy_resource_name": bidding_strategy_resource_name, 
         "strategy_type": strategy_type, "strategy_details": strategy_details},
        f"Change portfolio strategy {bidding_strategy_resource_name} to {strategy_type}"
    )


class DryRunGoogleAdsUpdaterToolset(BaseToolset):
    """Dry-run toolset that simulates Google Ads updates without executing them.
    
    SEARCH_ACTIVATE_MODIFICATION: This class was added for dry-run support.
    """

    def __init__(self):
        super().__init__()
        self._update_campaign_status_tool = FunctionTool(
            func=dry_run_update_campaign_status,
        )
        self._update_campaign_budget_tool = FunctionTool(
            func=dry_run_update_campaign_budget,
        )
        self._update_campaign_geo_targets_tool = FunctionTool(
            func=dry_run_update_campaign_geo_targets,
        )
        self._update_ad_group_geo_targets_tool = FunctionTool(
            func=dry_run_update_ad_group_geo_targets
        )
        self._update_bidding_strategy_tool = FunctionTool(
            func=dry_run_update_bidding_strategy,
        )
        self._update_shared_budget_tool = FunctionTool(
            func=dry_run_update_shared_budget
        )
        self._update_portfolio_bidding_strategy_tool = FunctionTool(
            func=dry_run_update_portfolio_bidding_strategy
        )

    async def get_tools(
        self, readonly_context: Optional[Any] = None
    ) -> List[FunctionTool]:
        """Returns a list of dry-run tools in this toolset."""
        return [
            self._update_campaign_status_tool,
            self._update_campaign_budget_tool,
            self._update_campaign_geo_targets_tool,
            self._update_ad_group_geo_targets_tool,
            self._update_bidding_strategy_tool,
            self._update_shared_budget_tool,
            self._update_portfolio_bidding_strategy_tool,
        ]
