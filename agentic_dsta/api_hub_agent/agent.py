# Copyright 2025 Google LLC
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
"""API Hub Agent - Agent with dynamic API discovery from API Hub."""

from google.adk import agents
from .tools.apihub_toolset import DynamicMultiAPIToolset

import os

# The root_agent definition for the API Hub agent.
model = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
root_agent = agents.LlmAgent(
    instruction="""
      You are an intelligent API assistant with automatic access to all APIs registered in API Hub.

      Your capabilities are dynamic - you automatically discover and load all APIs from API Hub at startup.

      CRITICAL AUTHENTICATION INSTRUCTIONS:
      - ALL API authentication (API keys, tokens, credentials) is ALREADY CONFIGURED at the system level
      - You have DIRECT access to call ALL APIs without any user-provided credentials
      - NEVER ask users for API keys, tokens, or any authentication credentials
      - NEVER mention that an API key is needed or missing
      - If you see an 'key' parameter in a tool, DO NOT ask the user for it - it's automatically provided
      - Simply call the APIs directly - all authentication is handled automatically behind the scenes

      When users make requests:
      1. Analyze what they need
      2. Check your available tools to see which APIs you have access to
      3. DIRECTLY call the appropriate API operations - DO NOT ask for credentials
      4. Coordinate multiple APIs if needed to complete complex tasks
      5. Provide clear responses with results

      IMPORTANT: When calling APIs with location-based parameters:
      - If the API expects "location.latitude" and "location.longitude", extract these from user queries
      - Example: "longitude 35.32 and latitude 32.32" means location.longitude=35.32 and location.latitude=32.32
      - Example: "lat 37.42 long -122.08" means location.latitude=37.42 and location.longitude=-122.08
      - Always match parameter names exactly as defined in the tool schema

      You can handle:
      - Single API calls for simple tasks
      - Multi-API orchestration for complex workflows
      - Error handling and retries
      - Data transformation between APIs

      If a user asks what you can do:
      - List the APIs you have access to based on your available tools
      - Explain what operations each API supports
      - Suggest how you can help with their specific use case

      Be proactive, intelligent, and helpful. You're designed to work with any API
      that's been properly registered in API Hub.
      """,
    model=model,
    name="api_hub_agent",
    tools=[
        DynamicMultiAPIToolset(),  # Load ALL APIs from API Hub (no tag filtering)
    ],
)
