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
Run logging for tracking agent actions and decisions.

SEARCH_ACTIVATE_MODIFICATION: This file was added for run logging support.
"""

import logging
import os
from datetime import datetime
from typing import Any, Dict, List, Optional

from google.cloud import firestore

logger = logging.getLogger(__name__)

# Firestore collection for run logs
RUN_LOGS_COLLECTION = "AgenticRunLogs"

# Global database client (lazy initialization)
_db: Optional[firestore.Client] = None


def _get_db() -> firestore.Client:
    """Get or create the Firestore client."""
    global _db
    if _db is None:
        database_id = os.environ.get("FIRESTORE_DB", "(default)")
        project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
        _db = firestore.Client(project=project_id, database=database_id)
    return _db


def log_run_start(
    customer_id: str,
    usecase: str,
    dry_run: bool = False,
    triggered_by: str = "scheduler"
) -> str:
    """
    Log the start of an agent run.
    
    Args:
        customer_id: The Google Ads customer ID.
        usecase: The use case (google_ads or sa360).
        dry_run: Whether this is a dry-run.
        triggered_by: What triggered the run (scheduler, manual, api).
    
    Returns:
        The run ID for this run.
    """
    try:
        db = _get_db()
        run_doc = {
            "customer_id": customer_id,
            "usecase": usecase,
            "dry_run": dry_run,
            "triggered_by": triggered_by,
            "status": "running",
            "started_at": datetime.utcnow().isoformat(),
            "completed_at": None,
            "actions": [],
            "error": None,
            "summary": None
        }
        
        # Create document with auto-generated ID
        doc_ref = db.collection(RUN_LOGS_COLLECTION).document()
        doc_ref.set(run_doc)
        
        run_id = doc_ref.id
        logger.info(
            "Run started: run_id=%s, customer_id=%s, dry_run=%s",
            run_id, customer_id, dry_run
        )
        return run_id
    except Exception as e:
        logger.error("Failed to log run start: %s", e)
        # Return a temporary ID so the run can continue
        return f"temp-{datetime.utcnow().timestamp()}"


def log_run_action(
    run_id: str,
    action: Dict[str, Any]
) -> None:
    """
    Log an action taken during a run.
    
    Args:
        run_id: The run ID from log_run_start.
        action: The action details dictionary.
    """
    if run_id.startswith("temp-"):
        logger.warning("Skipping action log for temp run_id: %s", run_id)
        return
    
    try:
        db = _get_db()
        doc_ref = db.collection(RUN_LOGS_COLLECTION).document(run_id)
        
        # Append action to the actions array
        doc_ref.update({
            "actions": firestore.ArrayUnion([action])
        })
        
        logger.debug("Action logged: run_id=%s, tool=%s", run_id, action.get("tool"))
    except Exception as e:
        logger.error("Failed to log action: %s", e)


def log_run_complete(
    run_id: str,
    status: str = "success",
    summary: Optional[str] = None,
    error: Optional[str] = None,
    actions: Optional[List[Dict[str, Any]]] = None
) -> None:
    """
    Log the completion of an agent run.
    
    Args:
        run_id: The run ID from log_run_start.
        status: The final status (success, error, cancelled).
        summary: Optional summary of what was done.
        error: Optional error message if status is error.
        actions: Optional list of all actions (for bulk update).
    """
    if run_id.startswith("temp-"):
        logger.warning("Skipping completion log for temp run_id: %s", run_id)
        return
    
    try:
        db = _get_db()
        doc_ref = db.collection(RUN_LOGS_COLLECTION).document(run_id)
        
        update_data = {
            "status": status,
            "completed_at": datetime.utcnow().isoformat(),
            "error": error,
            "summary": summary
        }
        
        # If actions provided, replace the entire array
        if actions is not None:
            update_data["actions"] = actions
        
        doc_ref.update(update_data)
        
        logger.info(
            "Run completed: run_id=%s, status=%s, actions=%d",
            run_id, status, len(actions) if actions else 0
        )
    except Exception as e:
        logger.error("Failed to log run completion: %s", e)


def get_run_history(
    customer_id: str,
    limit: int = 20,
    include_dry_runs: bool = True
) -> List[Dict[str, Any]]:
    """
    Get run history for a customer.
    
    Args:
        customer_id: The Google Ads customer ID.
        limit: Maximum number of runs to return.
        include_dry_runs: Whether to include dry-run results.
    
    Returns:
        List of run documents, newest first.
    
    Note: This query requires a Firestore composite index on AgenticRunLogs
    collection with fields: customer_id (ascending), started_at (descending).
    See SEARCH_ACTIVATE_MODIFICATIONS.md for index creation instructions.
    """
    try:
        db = _get_db()
        query = db.collection(RUN_LOGS_COLLECTION).where(
            filter=firestore.FieldFilter("customer_id", "==", customer_id)
        ).order_by("started_at", direction=firestore.Query.DESCENDING).limit(limit)
        
        docs = query.stream()
        runs = []
        for doc in docs:
            run_data = doc.to_dict()
            run_data["id"] = doc.id
            if include_dry_runs or not run_data.get("dry_run", False):
                runs.append(run_data)
        
        return runs
    except Exception as e:
        logger.error("Failed to get run history: %s", e)
        return []


def get_run_by_id(run_id: str) -> Optional[Dict[str, Any]]:
    """
    Get a specific run by ID.
    
    Args:
        run_id: The run ID.
    
    Returns:
        The run document, or None if not found.
    """
    try:
        db = _get_db()
        doc = db.collection(RUN_LOGS_COLLECTION).document(run_id).get()
        if doc.exists:
            run_data = doc.to_dict()
            run_data["id"] = doc.id
            return run_data
        return None
    except Exception as e:
        logger.error("Failed to get run: %s", e)
        return None
