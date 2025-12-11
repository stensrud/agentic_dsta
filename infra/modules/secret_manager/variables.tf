variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "secrets" {
  description = "Map of secret IDs to their values"
  type        = map(string)
  sensitive   = true
}

variable "service_account_email" {
  description = "Service account email to grant access to secrets"
  type        = string
  default     = ""
}
