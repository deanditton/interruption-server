terraform {
  # The modules used in this example have been updated with 0.12 syntax, additionally we depend on a bug fixed in
  # version 0.12.7.
  required_version = ">= 0.12.7"

  required_providers {
    google = ">= 3.4"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GOOGLE CLOUD SOURCE REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------

resource "google_sourcerepo_repository" "default" {
  name = var.repository_name
}



# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A GOOGLE CLOUD ARTIFACT REPOSITORY
# ---------------------------------------------------------------------------------------------------------------------

resource "google_artifact_registry_repository" "server-artifact" {
  location      = var.location
  repository_id = "interruption-notification-server"
  description   = "This resource is the repository for the docker image of interruptions backend currently only contains the websocket version"
  format        = "DOCKER"
}
# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CLOUD RUN SERVICE
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloud_run_service" "notification_service" {
  name     = var.notification_service
  location = var.location

  template {
    spec {
      containers {
        image = local.notification_service_image
      }
    }
  }

#  traffic {
#    percent         = 100
#    latest_revision = true
#  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EXPOSE THE SERVICE PUBLICALLY
# We give all users the ability to invoke the service.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloud_run_service_iam_member" "allUsers" {
  service  = google_cloud_run_service.notification_service.name
  location = google_cloud_run_service.notification_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A CLOUD BUILD TRIGGER
# ---------------------------------------------------------------------------------------------------------------------

resource "google_cloudbuild_trigger" "cloud_build_trigger" {
  description = "Cloud Source Repository Trigger ${var.repository_name} (${var.branch_name})"

  trigger_template {
    branch_name = var.branch_name
    repo_name   = var.repository_name
  }

  # These substitutions have been defined in the sample app's cloudbuild.yaml file.
  # See: https://github.com/robmorgan/sample-docker-app/blob/master/cloudbuild.yaml#L43
  substitutions = {
    _LOCATION     = var.location
    _REPOSITORY   = var.repository_name
    _GCR_REGION   = var.gcr_region
    _SERVICE_NAME = var.notification_service
  }

  # The filename argument instructs Cloud Build to look for a file in the root of the repository.
  # Either a filename or build template (below) must be provided.
  filename = "cloudbuild.yaml"

  depends_on = [google_sourcerepo_repository.default]
}

# ---------------------------------------------------------------------------------------------------------------------
# PREPARE LOCALS
# ---------------------------------------------------------------------------------------------------------------------

locals {
  notification_service_image = var.image_name == "" ? "${var.gcr_region}.gcr.io/${var.project}/${var.notification_service}" : var.image_name
}