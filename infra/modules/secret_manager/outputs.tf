output "secret_ids" {
  description = "The secret IDs of the managed secrets."
  value       = [for secret in google_secret_manager_secret.secrets : secret.secret_id]
}


