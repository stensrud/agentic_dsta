locals {
  all_secret_names = concat(var.secret_names, var.additional_secrets)
}

# Create the secret resources
resource "google_secret_manager_secret" "secrets" {
  for_each  = toset(local.all_secret_names)
  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}

# Create a version for each secret using the provided values
resource "google_secret_manager_secret_version" "secret_versions" {
  for_each      = google_secret_manager_secret.secrets
  secret        = each.value.id
  # Use the value from the map if it exists, otherwise use a placeholder.
  # This ensures Terraform doesn't block on a missing value during planning.
  secret_data   = lookup(var.secret_values, each.key, "placeholder-please-update-in-console")
  is_secret_data_base64 = false
}

# IAM binding to allow a service account to access these secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each  = var.service_account_email != "" ? toset(local.all_secret_names) : []
  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
  # Explicitly depend on the secret version to ensure the secret exists before granting access
  depends_on = [google_secret_manager_secret_version.secret_versions]
}
