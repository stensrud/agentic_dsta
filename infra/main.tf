provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs for the project
resource "google_project_service" "apis" {
  for_each           = toset(var.gcp_apis)
  service            = each.key
  disable_on_destroy = false
}

# Service Account for Cloud Run
resource "google_service_account" "run_sa" {
  account_id   = var.run_sa_account_id
  display_name = var.run_sa_display_name
  project      = var.project_id
}

# IAM roles for Service Account
resource "google_project_iam_member" "run_sa_roles" {
  for_each = toset(var.run_sa_roles)
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

#--- Modules ---

module "firestore" {
  source        = "./modules/firestore"
  project_id    = var.project_id
  location_id   = var.firestore_location_id
  database_name = var.firestore_database_name
  database_type = var.firestore_database_type

  depends_on = [google_project_service.apis]
}

module "secret_manager" {
  source     = "./modules/secret_manager"
  project_id = var.project_id
  secrets = {
    GOOGLE_API_KEY             = var.google_api_key
    GOOGLE_ADS_DEVELOPER_TOKEN = var.google_ads_developer_token
    GOOGLE_ADS_CLIENT_ID       = var.google_ads_client_id
    GOOGLE_ADS_CLIENT_SECRET   = var.google_ads_client_secret
    GOOGLE_ADS_REFRESH_TOKEN   = var.google_ads_refresh_token
    GOOGLE_POLLEN_API_KEY      = var.google_pollen_api_key
    GOOGLE_WEATHER_API_KEY     = var.google_weather_api_key
  }
  service_account_email = google_service_account.run_sa.email

  depends_on = [google_project_service.apis]
}

module "apihub" {
  source          = "./modules/apihub"
  project_id      = var.project_id
  location        = var.region # This is the regional location for the instance itself
  specs_dir       = "${path.module}/${var.apihub_specs_dir}"
  vertex_location = var.apihub_vertex_location
  account_email   = var.account_email
  access_token    = var.access_token

  depends_on = [google_project_service.apis]
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  buckets = {
    "dsta-bucket-${var.project_id}" = {
      location                    = "US"
      storage_class               = "STANDARD"
      force_destroy               = false
      uniform_bucket_level_access = true
      public_access_prevention    = "enforced"
      retention_duration_seconds  = 604800
      labels                      = {}
    },
    # Using the manually created bucket name without project ID suffix
    "agentic-dsta-tf-state" = {
      location                    = "US"
      storage_class               = "STANDARD"
      force_destroy               = false
      uniform_bucket_level_access = false
      public_access_prevention    = "inherited"
      retention_duration_seconds  = 604800
      labels                      = {}
    }
  }
}

module "artifact_registry" {
  source        = "./modules/artifact_registry"
  project_id    = var.project_id
  location      = var.region
  repository_id = var.artifact_repository_id
  description   = var.artifact_repository_description
  format        = var.artifact_repository_format

  depends_on = [google_project_service.apis]
}

module "cloud_run_service" {
  source                = "./modules/cloud_run_service"
  service_name          = var.service_name
  project_id            = var.project_id
  location              = var.location != "" ? var.location : var.region
  image_url             = var.image_url != "" ? var.image_url : var.run_service_default_image_url
  container_port        = var.container_port
  allow_unauthenticated = var.allow_unauthenticated
  service_account_email = google_service_account.run_sa.email

  env_vars = merge(var.run_service_env_vars, {
    GOOGLE_CLOUD_PROJECT = var.project_id
    GOOGLE_CLOUD_LOCATION = var.region
  })
  secret_env_vars = {
    GOOGLE_API_KEY = {
      name    = module.secret_manager.secret_ids["GOOGLE_API_KEY"],
      version = "latest"
    },
    GOOGLE_ADS_DEVELOPER_TOKEN = {
      name    = module.secret_manager.secret_ids["GOOGLE_ADS_DEVELOPER_TOKEN"],
      version = "latest"
    },
    GOOGLE_ADS_CLIENT_ID = {
      name    = module.secret_manager.secret_ids["GOOGLE_ADS_CLIENT_ID"],
      version = "latest"
    },
    GOOGLE_ADS_CLIENT_SECRET = {
      name    = module.secret_manager.secret_ids["GOOGLE_ADS_CLIENT_SECRET"],
      version = "latest"
    },
    GOOGLE_ADS_REFRESH_TOKEN = {
      name    = module.secret_manager.secret_ids["GOOGLE_ADS_REFRESH_TOKEN"],
      version = "latest"
    },
    GOOGLE_POLLEN_API_KEY = {
      name    = module.secret_manager.secret_ids["GOOGLE_POLLEN_API_KEY"],
      version = "latest"
    },
    GOOGLE_WEATHER_API_KEY = {
      name    = module.secret_manager.secret_ids["GOOGLE_WEATHER_API_KEY"],
      version = "latest"
    }
  }
  depends_on = [google_project_service.apis, module.secret_manager]
}

# Service Account for Scheduler
resource "google_service_account" "scheduler_sa" {
  account_id   = var.scheduler_sa_account_id
  display_name = var.scheduler_sa_display_name
  project      = var.project_id
}

# Service Account for agentic-dsta-sa
data "google_service_account" "agentic_dsta_sa" {
  account_id = var.agentic_dsta_sa_account_id
  project    = var.project_id
}

# Grant agentic-dsta-sa SA permission to invoke cloud run service
resource "google_cloud_run_v2_service_iam_member" "agentic_dsta_sa_invoker" {
  provider = google-beta
  project  = module.cloud_run_service.project_id
  location = module.cloud_run_service.location
  name     = module.cloud_run_service.name
  role     = var.run_invoker_role
  member   = "serviceAccount:${data.google_service_account.agentic_dsta_sa.email}"
}

locals {
  session_id = "session-${timestamp()}"
}

# Scheduler job for sa-session-init-job
resource "google_cloud_scheduler_job" "sa_session_init_job" {
  project          = var.project_id
  region           = var.region
  name             = var.sa_session_init_scheduler_job_name
  description      = var.sa_session_init_scheduler_job_description
  schedule         = var.sa_session_init_scheduler_job_schedule
  time_zone        = var.sa_session_init_scheduler_job_timezone
  attempt_deadline = var.sa_session_init_scheduler_job_attempt_deadline

  retry_config {
    retry_count          = 0
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_doublings        = 5
  }

  http_target {
    http_method = "POST"
    uri         = "${module.cloud_run_service.service_url}/run_sse"
    body = base64encode(jsonencode({
      app_name = "decision_agent"
      user_id  = data.google_service_account.agentic_dsta_sa.email
      session_id = local.session_id
      new_message = {
        role  = "user"
        parts = [{ text = var.scheduler_new_message_text }]
      }
      streaming = false
    }))
    headers = {
      "Content-Type" = "application/json"
      "User-Agent"   = "Google-Cloud-Scheduler"
    }

    oidc_token {
      service_account_email = data.google_service_account.agentic_dsta_sa.email
      audience              = "${module.cloud_run_service.service_url}/run_sse"
    }
  }

  depends_on = [google_cloud_run_v2_service_iam_member.agentic_dsta_sa_invoker]
}

# Scheduler job for sa-run-sse-job
resource "google_cloud_scheduler_job" "sa_run_sse_job" {
  project          = var.project_id
  region           = var.region
  name             = var.sa_run_sse_scheduler_job_name
  description      = var.sa_run_sse_scheduler_job_description
  schedule         = var.sa_run_sse_scheduler_job_schedule
  time_zone        = var.sa_run_sse_scheduler_job_timezone
  attempt_deadline = var.sa_run_sse_scheduler_job_attempt_deadline

  retry_config {
    retry_count          = 0
    max_retry_duration   = "0s"
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_doublings        = 5
  }

  http_target {
    http_method = "POST"
    uri         = "${module.cloud_run_service.service_url}/run_sse"
    body = base64encode(jsonencode({
      app_name = "decision_agent"
      user_id  = data.google_service_account.agentic_dsta_sa.email
      session_id = local.session_id
      new_message = {
        role  = "user"
        parts = [{ text = var.scheduler_new_message_text }]
      }
      streaming = false
    }))
    headers = {
      "Content-Type" = "application/json"
      "User-Agent"   = "Google-Cloud-Scheduler"
    }

    oidc_token {
      service_account_email = data.google_service_account.agentic_dsta_sa.email
      audience              = "${module.cloud_run_service.service_url}/run_sse"
    }
  }

  depends_on = [google_cloud_run_v2_service_iam_member.agentic_dsta_sa_invoker]
}

output "debug_root_secrets_keys" {
  description = "Keys of the map constructed for secret_manager input"
  value = keys({
    GOOGLE_API_KEY             = var.google_api_key
    GOOGLE_ADS_DEVELOPER_TOKEN = var.google_ads_developer_token
    GOOGLE_ADS_CLIENT_ID       = var.google_ads_client_id
    GOOGLE_ADS_CLIENT_SECRET   = var.google_ads_client_secret
    GOOGLE_ADS_REFRESH_TOKEN   = var.google_ads_refresh_token
    GOOGLE_POLLEN_API_KEY      = var.google_pollen_api_key
    GOOGLE_WEATHER_API_KEY     = var.google_weather_api_key
  })
  sensitive = true # <--- ADD THIS
}

output "debug_root_var_google_api_key_is_null" {
  description = "Is var.google_api_key null?"
  value       = var.google_api_key == null
  sensitive   = true # <--- ADD THIS
}

output "debug_root_var_google_ads_developer_token_is_null" {
  description = "Is var.google_ads_developer_token null?"
  value       = var.google_ads_developer_token == null
  sensitive   = true # <--- ADD THIS
}

# Add similar _is_null checks for the other 5 secret vars if you want to be exhaustive,
# making sure to include sensitive = true for each.

# --- Scheduler Verification Outputs ---
output "scheduler_target_uri" {
  description = "The target URI being used for scheduler jobs"
  value       = "${module.cloud_run_service.service_url}/run_sse"
}

output "scheduler_oidc_service_account" {
  description = "The service account email being used for scheduler OIDC tokens"
  value       = data.google_service_account.agentic_dsta_sa.email
}

output "scheduler_session_id" {
  description = "The dynamic session ID being used for scheduler jobs"
  value       = local.session_id
}
