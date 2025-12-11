resource "google_secret_manager_secret" "secrets" {
  # Use nonsensitive() to allow iterating over keys of a sensitive map
  for_each  = toset(nonsensitive(keys(var.secrets)))
  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secrets_version" {
  for_each    = toset(nonsensitive(keys(var.secrets)))
  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = var.secrets[each.key]
}

# IAM binding to allow a service account to access these secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each  = var.service_account_email != "" ? toset(nonsensitive(keys(var.secrets))) : []
  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"
}
