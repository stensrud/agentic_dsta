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
"""Main application file for the FastAPI server."""

import os

from dotenv import load_dotenv
import fastapi
from google.adk.cli import fast_api
import uvicorn


# Load environment variables from .env file for local development
load_dotenv()


FastAPI = fastapi.FastAPI
get_fast_api_app = fast_api.get_fast_api_app

# Get the directory where main.py is located
AGENT_DIR = os.path.dirname(os.path.abspath(__file__))
# Use an in-memory SQLite database for sessions to avoid file locking issues in
# a scaled environment.
SESSION_SERVICE_URI = "sqlite:///:memory:"
# Example allowed origins for CORS
# For production environments, it is recommended to use a more restrictive list of allowed origins.
ALLOWED_ORIGINS = ["http://localhost", "http://localhost:8080"]
# Set web=True if you intend to serve a web interface, False otherwise
SERVE_WEB_INTERFACE = True

# Call the function to get the FastAPI app instance
# Ensure the agent directory name ('decision_agent') matches your agent folder
app: FastAPI = get_fast_api_app(
    agents_dir=AGENT_DIR,
    session_service_uri=SESSION_SERVICE_URI,
    allow_origins=ALLOWED_ORIGINS,
    web=SERVE_WEB_INTERFACE,
)

# You can add more FastAPI routes or configurations below if needed
# Example:
# @app.get("/hello")
# async def read_root():
#     return {"Hello": "World"}


def main():
  """Starts the FastAPI server."""
  # Use the PORT environment variable provided by Cloud Run, defaulting to 8080
  uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))

if __name__ == "__main__":
  main()
