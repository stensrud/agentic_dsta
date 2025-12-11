resource "google_storage_bucket" "buckets" {
  for_each = var.buckets
  
  name                        = each.key
  project                     = var.project_id
  location                    = each.value.location
  storage_class               = each.value.storage_class
  force_destroy               = each.value.force_destroy
  uniform_bucket_level_access = each.value.uniform_bucket_level_access
  public_access_prevention    = each.value.public_access_prevention

  dynamic "soft_delete_policy" {
    for_each = each.value.retention_duration_seconds != null ? [1] : []
    content {
      retention_duration_seconds = each.value.retention_duration_seconds
    }
  }

  labels = merge({
    managed-by-cnrm = "true"
  }, each.value.labels)
}
