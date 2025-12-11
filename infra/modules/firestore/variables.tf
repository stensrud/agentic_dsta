variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "database_name" {
  description = "The name of the Firestore database"
  type        = string
  default     = "(default)"
}

variable "location_id" {
  description = "The location ID for the database"
  type        = string
}

variable "database_type" {
  description = "The type of the database (FIRESTORE_NATIVE or DATASTORE_MODE)"
  type        = string
  default     = "FIRESTORE_NATIVE"
}
