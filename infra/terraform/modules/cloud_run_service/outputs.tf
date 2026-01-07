# Output the URL of the service
output "service_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.default.uri
}

output "name" {
  description = "The name of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.default.name
}

output "location" {
  description = "The location of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.default.location
}

output "project_id" {
  description = "The project id of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.default.project
}
