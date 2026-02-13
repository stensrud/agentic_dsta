# SEARCH_ACTIVATE_MODIFICATION: New file for unified action logging
"""
Unified action logging for both dry-run and real Google Ads operations.

This module provides a shared mechanism to track all actions (simulated or real)
performed during agent runs, enabling visibility into what the agent does.
"""

from datetime import datetime
from typing import Any, Dict, List
import threading

# Thread-safe action storage
_lock = threading.Lock()
_actions: List[Dict[str, Any]] = []


def log_action(
    tool_name: str,
    params: Dict[str, Any],
    description: str,
    simulated: bool = False,
    result: Dict[str, Any] | None = None
) -> Dict[str, Any]:
    """
    Log an action performed by the agent.
    
    Args:
        tool_name: Name of the tool/function called
        params: Parameters passed to the tool
        description: Human-readable description of what was done
        simulated: True if this was a dry-run simulation
        result: The result of the operation (for real runs)
    
    Returns:
        The action record that was logged
    """
    action = {
        "timestamp": datetime.utcnow().isoformat(),
        "tool": tool_name,
        "params": params,
        "description": description,
        "simulated": simulated,
    }
    
    if result is not None:
        action["result"] = result
    
    with _lock:
        _actions.append(action)
    
    return action


def clear_actions() -> None:
    """Clear all logged actions. Call at the start of a new run."""
    with _lock:
        _actions.clear()


def get_actions() -> List[Dict[str, Any]]:
    """Get a copy of all logged actions."""
    with _lock:
        return list(_actions)


def get_action_count() -> int:
    """Get the number of logged actions."""
    with _lock:
        return len(_actions)
