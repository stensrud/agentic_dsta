terraform {
  backend "gcs" {
    bucket  = "${var.resource_prefix}-tf-state"
    prefix  = "terraform/agentic_dsta"
  }
}
