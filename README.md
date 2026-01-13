# Agentic Demand Signal & Trend Activation (DSTA)

## Overview

The Agentic Dynamic Signal Target Ads (DSTA) solution is a powerful, automated marketing framework designed to help marketers forecast and activate advertising campaigns based on real-time demand signals. It uses an agentic architecture to integrate data from various sources (Google Ads, SA360, Weather, Pollen, etc.) and automate campaign management decisions.

For a comprehensive guide on the architecture, components, and detailed usage, please refer to the **[Implementation Guide](implementation_guide.md)**.

## Project Structure

*   **`agentic_dsta/`**: Contains the application source code, including agents, tools, and the FastAPI server.
    *   See [agentic_dsta/README.md](agentic_dsta/README.md) for local development instructions.
*   **`infra/`**: Contains the Infrastructure as Code (Terraform) and deployment scripts.
*   **`tests/`**: Contains unit and integration tests for the solution.

## Getting Started

### Deployment

This solution is deployed to Google Cloud Run using Terraform. For detailed prerequisites and step-by-step deployment instructions, please refer to the **[Implementation Guide](implementation_guide.md#7-installation-and-deployment)**.

### Local Development

For instructions on running the application locally for development and testing, please refer to the **[Application README](agentic_dsta/README.md)**.