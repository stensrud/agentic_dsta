# API Hub Instance
resource "google_apihub_api_hub_instance" "default" {
  provider = google-beta
  project  = var.project_id
  location = var.location # Instance region

  api_hub_instance_id = var.instance_id

  config {
    vertex_location = var.vertex_location
  }
}

# Initialization Script
# Registers APIs into API Hub so the agent can discover them.
resource "null_resource" "init_apihub" {
  triggers = {
    project_id = var.project_id
    location   = var.location
    # Trigger re-run if specs change
    pollen_spec_hash  = filemd5("${var.specs_dir}/pollen-api-openapi.yaml")
    weather_spec_hash = filemd5("${var.specs_dir}/weather-api-openapi.yaml")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/../../scripts/init_apihub.sh ${var.project_id} ${var.location} ${var.specs_dir}"
  }

  depends_on = [
    google_apihub_api_hub_instance.default
  ]
}
