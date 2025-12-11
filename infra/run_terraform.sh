
#!/bin/bash
/google/bin/releases/g3terraform/runner_main --base_service_dir=$(pwd) --config_dir=. "$@"

gcloud builds submit --tag us-central1-docker.pkg.dev/styagi-test/agentic-dsta-repo/agentic-dsta

gcloud builds submit --config ./docker-config.yaml  ../agentic_dsta