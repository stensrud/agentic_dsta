output "service_account_email" {
  description = "The email address of the API Hub service identity."
  value       = google_project_service_identity.apihub_service_identity.email
}
