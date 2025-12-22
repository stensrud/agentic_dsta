resource "google_project_service" "apihub_service" {
  project = var.project_id
  service = "apihub.googleapis.com"
}




data "google_project" "project" {
  project_id = var.project_id
}

# There is a delay between when the service is enabled and when the service account is created.
resource "time_sleep" "wait_for_service_identity" {
  create_duration = "60s"
  depends_on      = [google_project_service.apihub_service]
}

# Grant Admin role to service identity
resource "google_project_iam_member" "apihub_service_identity_permission" {
  for_each = toset([
    "roles/apihub.admin",
    "roles/apihub.runtimeProjectServiceAgent"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-apihub.iam.gserviceaccount.com"
  depends_on = [time_sleep.wait_for_service_identity]
}

# Initialization Script


# Registers APIs into API Hub so the agent can discover them.
# Using local-exec with sh because TF resources for apihub api/version/spec
# are not available in the current provider version, and bash is not available
# in g3terraform runner for local-exec.
resource "null_resource" "init_apihub" {
  triggers = merge({
    project_id = var.project_id
    location   = var.location
    }, {
    for f in var.spec_files :
    replace(f, ".", "_") => filemd5("${var.specs_dir}/${f}")
  })

  provisioner "local-exec" {
    command = "/bin/sh ${path.module}/../../scripts/init_apihub.sh ${var.project_id} ${var.location} ${var.specs_dir}"
    environment = {
      ACCOUNT_EMAIL = var.account_email
      ACCESS_TOKEN  = var.access_token
    }
  }

  depends_on = [
    google_project_iam_member.apihub_service_identity_permission
  ]
}
