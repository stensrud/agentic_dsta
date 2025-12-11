output "secret_ids" {
  description = "Map of secret keys to their resource IDs"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.secret_id }
}

output "debug_module_secrets_keys" {
  description = "Keys received in var.secrets by the module"
  value       = keys(var.secrets)
  sensitive   = true 
}
