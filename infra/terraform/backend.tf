terraform {
  backend "gcs" {
    # Bucket is provided dynamically by the deploy.sh script
    # using -backend-config="bucket=..."
    prefix  = "terraform/agentic_dsta"
  }
}
