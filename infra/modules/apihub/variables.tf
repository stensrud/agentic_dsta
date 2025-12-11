variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "location" {
  description = "The location for API Hub"
  type        = string
}

variable "instance_id" {
  description = "The ID of the API Hub instance"
  type        = string
  default     = "default-instance"
}

variable "specs_dir" {
  description = "Path to the directory containing OpenAPI specs"
  type        = string
}

variable "vertex_location" {
  description = "The multi-region for Vertex AI Search data (e.g., 'us' or 'eu')."
  type        = string
}