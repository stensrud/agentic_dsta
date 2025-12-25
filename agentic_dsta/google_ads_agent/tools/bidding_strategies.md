In the Google Ads API, bidding strategies are managed through the Campaign resource for standard strategies and the BiddingStrategy resource for portfolio strategies.
Since the campaign_bidding_strategy field in the Campaign resource is a union field, you can technically change almost any strategy to another by simply sending a new one in a mutate request. However, there are strict contextual and campaign-type restrictions.

1. What CAN be changed to what?
Most "Standard" campaigns (Search, Display, Shopping) allow you to move between different bidding goals.
Manual CPC → Maximize Clicks (TARGET_SPEND): Moving from manual control to automated traffic volume.


Maximize Clicks → Maximize Conversions: Moving from a traffic goal to a performance goal (often done once a campaign has 30+ conversions).


Maximize Conversions → Target CPA: Refinement within the conversion goal (In the API, this is done by updating the target_cpa_micros field inside the maximize_conversions object).


Standard Strategy → Portfolio Strategy: Switching a campaign from its own local settings to a shared BiddingStrategy resource.
Resource to use: CampaignService
What to send: The Campaign object with a new bidding scheme set in the campaign_bidding_strategy union.
2. What CANNOT be changed (Common Errors)
Your AI agent will face errors if it attempts transitions that violate campaign type rules or context.
Transition Attempt
Result
Reason
Search Campaign  → Commission
OperationAccessDeniedError
Commission only works for Hotel campaigns.
Standard Scheme  → Portfolio Only Type
BiddingError
TARGET_ROAS is a Portfolio-only object. To use it in a Standard campaign, you must use MAXIMIZE_CONVERSION_VALUE with a target ROAS set inside it.
Video Campaign  → Manual CPC
BiddingError
Video campaigns typically require MANUAL_CPV or TARGET_CPV.
Search Campaign  → Manual CPM
BiddingError
Manual CPM is for Display Network Only campaigns.



Implementation Example: Maximize Clicks $\rightarrow$ Maximize Conversions
We need to identify that a campaign has enough data to switch from clicks to conversions, it would use the CampaignService.
Resource: Campaign
{
  "resourceName": "customers/123/campaigns/456",
  "maximizeConversions": {
    "targetCpaMicros": "10000000" // Optional: $10 Target CPA
  }
}

Note: Because campaign_bidding_strategy is a union, providing maximizeConversions automatically removes the previous targetSpend (Maximize Clicks) scheme.

Before making a change, have the agent check the Campaign.advertising_channel_type. 
For example, if it's PERFORMANCE_MAX, your agent should only ever use MAXIMIZE_CONVERSIONS or MAXIMIZE_CONVERSION_VALUE variants.


We also need a set of "Pre-flight Rules" that map Campaign Types to Allowed Bidding Strategies. Attempting to apply a strategy to an unsupported campaign type will cause the API to throw an OperationAccessDeniedError.

Here is the complete mapping of what can be changed to what, categorized by the advertising_channel_type.

1. Performance Max campaigns (PERFORMANCE_MAX)
These are highly automated. Your agent must stick to Smart Bidding only.
Allowed Strategies:


MAXIMIZE_CONVERSIONS (with optional target_cpa)
MAXIMIZE_CONVERSION_VALUE (with optional target_roas)


Prohibited: MANUAL_CPC, TARGET_IMPRESSION_SHARE, TARGET_SPEND (Maximize Clicks).


API Resource: Campaign (Standard) or BiddingStrategy (Portfolio).






Performance Max (PERFORMANCE_MAX)
Can you switch? Yes, but only between the two Smart Bidding types.
API Resource: Campaign


Compulsory Values: 
maximize_conversions (object) OR maximize_conversion_value (object).


Optional Values: 
target_cpa_micros (inside maximize_conversions).
target_roas (inside maximize_conversion_value).


Pre-flight Checklist:


Conversion Health: For maximize_conversion_value, verify that conversion actions have non-zero values assigned.


Learning Status: Do not switch if the campaign is currently in a "Learning" phase from a previous change (check bidding_strategy_system_status).

2. Search campaigns (SEARCH)
The most flexible type. Your agent can move between manual and fully automated strategies.
Allowed Strategies:


MANUAL_CPC
TARGET_SPEND (Maximize Clicks)
MAXIMIZE_CONVERSIONS (with optional target_cpa)
MAXIMIZE_CONVERSION_VALUE (with optional target_roas)
TARGET_IMPRESSION_SHARE


Prohibited: MANUAL_CPM (Search campaigns do not support impression-based manual bidding), COMMISSION.


API Resource: Campaign.
3. Display campaigns (DISPLAY)
Allowed Strategies:
MANUAL_CPC
MANUAL_CPM (Fixed cost per 1,000 impressions)
TARGET_CPM (Automated target for impressions)
MAXIMIZE_CONVERSIONS
MAXIMIZE_CONVERSION_VALUE


Prohibited: TARGET_IMPRESSION_SHARE (This is specific to Search results).


API Resource: Campaign.
4. Video campaigns (VIDEO)
Allowed Strategies:


MANUAL_CPV (Cost per view)
TARGET_CPV
TARGET_CPM
MAXIMIZE_CONVERSIONS (For "Video Action" campaigns)


Prohibited: MANUAL_CPC (Video uses views, not clicks, as the primary manual unit).


API Resource: Campaign.
5. Hotel campaigns (HOTEL)
Allowed Strategies:


MANUAL_CPC
PERCENT_CPC (Bid is a % of the room price)
COMMISSION (Pay only for stayed bookings)


Prohibited: TARGET_IMPRESSION_SHARE, MANUAL_CPM.


API Resource: Campaign.


Critical Technical Constraints for the Agent


The "Portfolio-Only" Restriction


If your agent wants to use the TargetCpa or TargetRoas objects directly (instead of nesting them inside Maximize Conversions), it must use a Portfolio strategy.
Correct: Point campaign.bidding_strategy to a resource name like customers/123/biddingStrategies/456.


Incorrect: Trying to set campaign.target_cpa directly on a campaign. The API will require you to use the maximize_conversions union field instead for standard campaigns.
Resource Summary for the Agent
Change Level
Resource to Use
Agent Logic Example
Entire Strategy Change
CampaignService
Change manual_cpc → maximize_conversions.
Target Adjustment (Standard)
CampaignService
Update maximize_conversions.target_cpa_micros.
Target Adjustment (Portfolio)
BiddingStrategyService
Update target_cpa.target_cpa_micros (affects all linked campaigns).
Individual Bid Change
AdGroupService or AdGroupCriterionService
Update cpc_bid_micros for specific keywords.




Implementation Logic:

GET campaign.advertising_channel_type and campaign.bidding_strategy_type.

VALIDATE: If advertising_channel_type == SEARCH, then TARGET_IMPRESSION_SHARE is a valid target.

EXECUTE: Send a mutate request via CampaignService setting the specific bidding scheme field (e.g., target_impression_share) which automatically clears the previous strategy.


Common Bidding Errors (BiddingError)
These occur when the bidding strategy configuration itself is invalid.
Error Enum
What it means for your Agent
BIDDING_STRATEGY_NOT_SUPPORTED
The strategy type (e.g., COMMISSION) is not supported by the campaign's network or channel.
INVALID_ANONYMOUS_BIDDING_STRATEGY_TYPE
You tried to set a portfolio-only strategy (like TARGET_CPA) directly on the campaign without using the proper union field (maximize_conversions).
CANNOT_ATTACH_BIDDING_STRATEGY_TO_CAMPAIGN
The specific strategy (usually a Portfolio one) cannot be linked to this campaign type.
BIDDING_STRATEGY_NOT_BELONG_TO_CUSTOMER
The agent tried to use a Portfolio BiddingStrategy ID that belongs to a different Manager (MCC) or Client account.


2. Operation Errors (OperationAccessDeniedError)
These occur when the agent attempts a change that is physically impossible for that campaign type.
Rule: If advertising_channel_type == SEARCH, then MANUAL_CPM is prohibited.
Error: OPERATION_NOT_PERMITTED_FOR_CAMPAIGN_TYPE
Agent Fix: Check the channel type before choosing the strategy.
3. Contextual Change Rules (What to check before mutating)
Before your agent sends a mutate request, have it perform these checks to ensure the change is allowed:
A. Budget Compatibility
Check: Is the campaign using a Shared Budget?
Constraint: Some bidding strategies (like certain Portfolio versions of Maximize Clicks) require a shared budget, while others (Standard Maximize Conversions) usually work best with a dedicated budget.
Resource: Campaign.campaign_budget.
B. Conversion Tracking Status
Check: Are there active conversion actions?
Constraint: If your agent tries to switch to MAXIMIZE_CONVERSIONS but customer_conversion_goal shows no active triggers, the strategy will technically "work" but the campaign will flatline (not spend).
Agent Logic: Do not switch to Smart Bidding unless metrics.conversions > 0 in the last 30 days.
C. Minimum Bid Thresholds
Check: Is the cpc_bid_micros too low?
Error: RangeError or BID_TOO_LOW.
Constraint: Google has internal floors for certain keywords/auctions. If your agent aggressively lowers bids to save money, it might trigger an error or simply stop the ad from showing.


Bidding strategy is categorised into Standard (Single) and Portfolio (Shared across multiple campaigns).

Each strategy is defined by a "bidding scheme" that must match its type. Attempting to use a portfolio-only scheme in a standard context (or vice versa) will result in a BiddingError.

Changing bidding strategy falls into 2 categories: structural transitions (changing the strategy type) and parameter updates (adjusting values within the strategy).

1. Structural Transitions (Type to Type)
Your agent can switch the core goal of a campaign. Because the campaign_bidding_strategy field in the Campaign resource is a "union" field, setting a new strategy automatically replaces the old one.

From
To
Use Case Example
Manual CPC
Maximize Conversions
Campaign has enough historical data and you want the AI to handle bid amounts to drive volume.
Maximize Conversions
Target ROAS
You’ve achieved conversion volume but now need to ensure a specific return on investment (profitability).
Standard Strategy
Portfolio Strategy
You want to group this campaign with 5 others to share a single bidding algorithm and budget.


Example (Agent Logic):
“If Campaign X has >30 conversions in 30 days and ROAS > 2.0, change campaign.manual_cpc to campaign.maximize_conversion_value with a target_roas of 2.5.”



We can perform 4 main types of changes:

1. Change the Bidding Strategy Type: 


https://developers.google.com/google-ads/api/reference/rpc/v22/Campaign#campaign_bidding_strategy
 
Switch a campaign from one strategy to another (e.g., moving from Manual CPC to Maximize Conversions).
What you can do: Switch between Standard strategies (set on the campaign) or attach a campaign to a Portfolio strategy.
API Resource: Campaign
Field: campaign_bidding_strategy (This is a union field, so setting one—like maximize_conversions—automatically clears the previous one).

2. Update Targets and Goals (Optimization)

This is the most common use case for AI agents—adjusting the "knobs" of an existing strategy based on performance data.
What you can do: * Change the Target CPA (Cost Per Acquisition) amount.
Change the Target ROAS (Return On Ad Spend) percentage.
Adjust the Target Impression Share percentage or location (e.g., moving from "anywhere" to "top of page").
API Resources:
Campaign: If using a Standard bidding strategy.
BiddingStrategy: If using a Portfolio strategy (changes here affect all campaigns linked to it).
AdGroup: If you want to override the campaign-level Target CPA or Target ROAS for a specific ad group.

3. Adjust Manual Bids

If your agent manages manual bidding, it can micro-manage individual bid amounts.
What you can do: Update the maximum CPC (cost-per-click) or CPM (cost-per-thousand impressions).
API Resources:
AdGroup: To set the cpc_bid_micros or cpm_bid_micros at the group level.
AdGroupCriterion: To set bids for specific keywords or segments.


4. Apply Bid Modifiers (Adjustments)

Your agent can increase or decrease bids based on specific conditions without changing the base strategy.
What you can do: Set percentage increases/decreases for Mobile vs. Desktop, specific geographic locations, or high-performing audiences.
API Resources:
CampaignCriterion: To set modifiers at the campaign level (e.g., +20% for "California").
AdGroupCriterion: To set modifiers at the ad group level (e.g., -10% for "Tablet").


Action
API Resource
Key Field(s)
Switch Strategy
Campaign
maximize_conversions, target_cpa, etc.
Update CPA/ROAS
Campaign or BiddingStrategy
target_cpa_micros, target_roas
Modify Keyword Bids
AdGroupCriterion
cpc_bid_micros
Device/Geo Bidding
CampaignCriterion
bid_modifier


