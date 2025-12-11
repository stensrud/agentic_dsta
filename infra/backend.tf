terraform {
  backend "gcs" {
    bucket  = "agentic-dsta-tf-state"
    prefix  = "terraform/agentic_dsta"
  }
}
