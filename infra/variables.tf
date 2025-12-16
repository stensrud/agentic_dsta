variable "project_id" {
  description = "The GCP project ID for the development environment"
  type        = string
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The location/region for Cloud Run service (defaults to var.region)"
  type        = string
  default     = "" # If empty, var.region will be used
}

variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
  default     = "agentic-dsta"
}

variable "image_url" {
  description = "The URL of the container image in Artifact Registry. Set by CI/CD."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "allow_unauthenticated" {
  description = "If true, allows unauthenticated invocations to the service (set to true for public access)"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service instance. If not provided, a dedicated SA will be created."
  type        = string
  default     = "" 
}

# --- Firestore Variables ---

variable "firestore_database_name" {
  description = "The name of the Firestore database"
  type        = string
  default     = "dsta-agentic-firestore"
}

variable "firestore_location_id" {
  description = "The location ID for the Firestore database (e.g. nam5 for us-central)"
  type        = string
  default     = "nam5"
}

variable "firestore_database_type" {
  description = "The type of the Firestore database"
  type        = string
  default     = "FIRESTORE_NATIVE"
}

# --- Artifact Registry Variables ---

variable "artifact_repository_id" {
  description = "The ID of the Artifact Registry repository"
  type        = string
  default     = "agentic-dsta-repo"
}

# --- API Hub Variables ---

# --- GCP APIs ---
variable "gcp_apis" {
  description = "List of GCP APIs to enable for the project."
  type        = list(string)
  default = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "firestore.googleapis.com",
    "apihub.googleapis.com",
    "aiplatform.googleapis.com",
    "iap.googleapis.com",
    "googleads.googleapis.com",
    "pollen.googleapis.com",
    "weather.googleapis.com",
    "cloudscheduler.googleapis.com",
  ]
}

# --- Service Accounts and IAM ---
variable "run_sa_account_id" {
  description = "The account ID for the Cloud Run service account."
  type        = string
  default     = "agentic-dsta-runner"
}

variable "run_sa_display_name" {
  description = "The display name for the Cloud Run service account."
  type        = string
  default     = "Agentic DSTA Cloud Run Runner"
}

variable "run_sa_roles" {
  description = "IAM roles to grant to the Cloud Run service account."
  type        = list(string)
  default = [
    "roles/datastore.user",
    "roles/apihub.editor",
    "roles/aiplatform.user",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "scheduler_sa_account_id" {
  description = "The account ID for the Cloud Scheduler service account."
  type        = string
  default     = "dsta-scheduler"
}

variable "scheduler_sa_display_name" {
  description = "The display name for the Cloud Scheduler service account."
  type        = string
  default     = "DSTA Scheduler SA"
}

variable "agentic_dsta_sa_account_id" {
  description = "The account ID for agentic-dsta-sa service account to use in scheduler jobs."
  type        = string
  default     = "agentic-dsta-sa"
}

variable "run_invoker_role" {
  description = "IAM role for invoking Cloud Run services."
  type        = string
  default     = "roles/run.invoker"
}

# --- Artifact Registry Variables ---
variable "artifact_repository_description" {
  description = "The description of the Artifact Registry repository"
  type        = string
  default     = "Docker repository for Agentic DSTA"
}

variable "artifact_repository_format" {
  description = "The format of the Artifact Registry repository"
  type        = string
  default     = "DOCKER"
}

# --- API Hub Variables ---
variable "apihub_specs_dir" {
  description = "Path to the directory containing OpenAPI specs for API Hub"
  type        = string
  default     = "specs"
}

# --- Cloud Run Variables ---
variable "run_service_default_image_url" {
  description = "Default image URL to use for Cloud Run if image_url is not provided."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "run_service_env_vars" {
  description = "Environment variables to set in the Cloud Run container. GOOGLE_CLOUD_PROJECT and GOOGLE_CLOUD_LOCATION will be overridden with TF values."
  type        = map(string)
  default = {
    GOOGLE_GENAI_USE_VERTEXAI = "True"
  }
}

# --- Scheduler Variables ---

variable "dsta_automation_scheduler_job_name" {
  description = "Name of dsta-automation scheduler job."
  type        = string
  default     = "dsta-daily-automation"
}

variable "dsta_automation_scheduler_job_description" {
  description = "Description of dsta-automation scheduler job."
  type        = string
  default     = "Daily trigger for DSTA marketing automation agent"
}

variable "dsta_automation_scheduler_job_timezone" {
  description = "Timezone of dsta-automation scheduler job."
  type        = string
  default     = "UTC"
}

variable "dsta_automation_agent_name" {
  description = "Agent name for dsta-automation scheduler job payload."
  type        = string
  default     = "marketing_campaign_manager"
}

variable "dsta_automation_query" {
  description = "Query for dsta-automation scheduler job payload."
  type        = string
  default     = "Run daily check based on current demand signals and business rules."
}

variable "sa_session_init_scheduler_job_name" {
  description = "Name of sa-session-init-job scheduler job."
  type        = string
  default     = "sa-session-init-job"
}

variable "sa_session_init_scheduler_job_description" {
  description = "Description of sa-session-init-job scheduler job."
  type        = string
  default     = "Run analysis task for decision_agent using agentic-dsta-sa for initialization"
}

variable "sa_session_init_scheduler_job_schedule" {
  description = "Schedule for sa-session-init-job scheduler job."
  type        = string
  default     = "5 9 * * 1-5"
}

variable "sa_session_init_scheduler_job_timezone" {
  description = "Timezone of sa-session-init-job scheduler job."
  type        = string
  default     = "UTC"
}

variable "sa_session_init_scheduler_job_attempt_deadline" {
  description = "Attempt deadline of sa-session-init-job scheduler job."
  type        = string
  default     = "180s"
}

variable "sa_run_sse_scheduler_job_name" {
  description = "Name of sa-run-sse-job scheduler job."
  type        = string
  default     = "sa-run-sse-job"
}

variable "sa_run_sse_scheduler_job_description" {
  description = "Description of sa-run-sse-job scheduler job."
  type        = string
  default     = "Run analysis task for decision_agent using agentic-dsta-sa"
}

variable "sa_run_sse_scheduler_job_schedule" {
  description = "Schedule for sa-run-sse-job scheduler job."
  type        = string
  default     = "5 9 * * 1-5"
}

variable "sa_run_sse_scheduler_job_timezone" {
  description = "Timezone of sa-run-sse-job scheduler job."
  type        = string
  default     = "UTC"
}

variable "sa_run_sse_scheduler_job_attempt_deadline" {
  description = "Attempt deadline of sa-run-sse-job scheduler job."
  type        = string
  default     = "180s"
}

variable "scheduler_app_name" {
  description = "App name for scheduler job payload."
  type        = string
  default     = "decision_agent"
}

variable "scheduler_session_id" {
  description = "Session ID for scheduler job payload."
  type        = string
  default     = "session_1"
}

variable "scheduler_new_message_text" {
  description = "New message text for scheduler job payload."
  type        = string
  default     = "Analyse and update customerid: 4086619433"
}

variable "scheduler_cron" {
  description = "The cron schedule for the agent trigger"
  type        = string
  default     = "0 0 * * *"
}

# --- Secrets ---

variable "google_api_key" {
  description = "Google API Key"
  type        = string
  sensitive   = true
}

variable "google_ads_developer_token" {
  description = "Google Ads Developer Token"
  type        = string
  sensitive   = true
}

variable "google_ads_client_id" {
  description = "Google Ads Client ID"
  type        = string
  sensitive   = true
}

variable "google_ads_client_secret" {
  description = "Google Ads Client Secret"
  type        = string
  sensitive   = true
}

variable "google_ads_refresh_token" {
  description = "Google Ads Refresh Token"
  type        = string
  sensitive   = true
}

variable "google_pollen_api_key" {
  description = "Google Pollen API Key"
  type        = string
  sensitive   = true
}

variable "google_weather_api_key" {
  description = "Google Weather API Key"
  type        = string
  sensitive   = true
}

variable "apihub_vertex_location" {
  description = "The multi-region for API Hub Vertex AI Search data (e.g., 'us' or 'eu')."
  type        = string
  default     = "us"
}

variable "account_email" {
  description = "The service account email to use for API Hub initialization."
  type        = string
}

variable "access_token" {
  description = "The access token to use for API Hub initialization."
  type        = string
  sensitive   = true
}

