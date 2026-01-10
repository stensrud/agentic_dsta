
import pytest
from unittest.mock import MagicMock, patch, AsyncMock
from fastapi.testclient import TestClient
import os

# Ensure we can import from agentic_dsta
import sys
sys.path.append(os.getcwd())

from agentic_dsta.main import app

client = TestClient(app)


import asyncio



def test_scheduler_init_and_run_success():
    async def run_test():
        payload = {
            "app_name": "decision_agent",
            "new_message": {
                "parts": [{"text": "Analyse and update customerid: 4086619433"}],
                "role": "user"
            },
            "session_id": "session-2026-01-04T15:39:43Z",
            "streaming": False,
            "user_id": "test-v5-runner@gta-solutions-agentic-dsta.iam.gserviceaccount.com",
            "customer_id": "4086619433"
        }

        # Patch run_decision_agent
        # Patch where it is used in main.py because it is imported at top level
        with patch("agentic_dsta.main.run_decision_agent", new_callable=AsyncMock) as mock_run_agent:
            
            # Mock successful run
            mock_run_agent.return_value = {"status": "success"}

            # We also need to patch starlette.concurrency.run_in_threadpool to simply await
            # OR we trust that it runs the mock.
            # However, run_in_threadpool runs sync functions in a thread.
            # Our mock is a MagicMock (sync). So it should work fine.

            response = client.post(
                "/scheduler/init_and_run",
                json=payload,
                headers={"Authorization": "Bearer token"}
            )

            assert response.status_code == 200
            # Expecting success message from endpoint
            assert response.json() == {'message': 'Decision agent run completed for 4086619433', 'status': 'success'}

            # Verify run_decision_agent was called with correct customer_id
            mock_run_agent.assert_called_once_with("4086619433", None)

    asyncio.run(run_test())

def test_scheduler_init_and_run_session_failure():
    async def run_test():
        payload = {
            "app_name": "decision_agent",
            "new_message": {
                # Invalid text format for regex to fail or we can mock exception
                "parts": [{"text": "No customer id here"}],
                "role": "user"
            }
        }

        # When customer_id extraction fails, it raises ValueError
        # Endpoint catches None customer_id? No, get_customer_id raises ValueError.
        # But endpoint code: customer_id = get_customer_id_from_task(...)

        # Checking logic in main.py:
        # try:
        #     customer_id = get_customer_id_from_task(task)
        # except ValueError as e:
        #     raise HTTPException(status_code=400, detail=str(e))

        response = client.post("/scheduler/init_and_run", json=payload)
        assert response.status_code == 400
        assert "Missing customer_id" in response.json()["detail"]

    asyncio.run(run_test())


