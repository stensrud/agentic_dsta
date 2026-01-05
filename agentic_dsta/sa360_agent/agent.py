"""Decision agent for managing SA360 campaigns."""
import logging
import os
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(name)s - %(message)s'
)
from google.adk import agents
from .tools.sa360_utils import load_config
from .tools import sa360_toolset
from firestore_agent.tools.firestore_toolset import FirestoreToolset

model, instruction = load_config()

# Read the prompt from the external file.
with open(os.path.join(os.path.dirname(__file__), "prompt.txt"), "r", encoding='utf-8') as f:
    prompt = f.read()

# The root_agent definition for the decision_agent.
root_agent = agents.LlmAgent(
    instruction=prompt,
    model=model,
    name="sa360_agent",
    tools=[
        sa360_toolset.SA360Toolset(),
        FirestoreToolset(),
    ],
)
