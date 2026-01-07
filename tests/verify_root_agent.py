import logging
import os
import sys

# Add project root to sys.path
sys.path.append(os.getcwd())
sys.path.append(os.path.join(os.getcwd(), "agentic_dsta"))

try:
    from agentic_dsta.agents.decision_agent import agent
    import_error = None
except ImportError as e:
    agent = None
    import_error = e

def verify_root_agent():
    print("Attempting to import agentic_dsta.decision_agent.agent...")
    if agent:
        print("Module imported successfully.")
    else:
        print(f"Failed to import module: {import_error}")
        return

    if hasattr(agent, "root_agent"):
        print("SUCCESS: 'root_agent' found in agentic_dsta.decision_agent.agent.")
        print(f"Type: {type(agent.root_agent)}")
    else:
        print("FAILURE: 'root_agent' NOT found in agentic_dsta.decision_agent.agent.")
        sys.exit(1)

if __name__ == "__main__":
    verify_root_agent()
