output "service_account_email" {
  description = "The email address of the API Hub service identity."
  value       = "service-${data.google_project.project.number}@gcp-sa-apihub.iam.gserviceaccount.com"
}
