variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "buckets" {
  description = "Map of bucket names to configuration"
  type = map(object({
    location                    = string
    storage_class               = string
    force_destroy               = bool
    uniform_bucket_level_access = bool
    public_access_prevention    = string
    retention_duration_seconds  = optional(number)
    labels                      = optional(map(string))
  }))
}
