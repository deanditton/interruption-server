locals {
  image    = "australia-southeast2-docker.pkg.dev/onair-340ad/interruption-servers/interruption-websocket@sha256:8ad737c757127a84165785324de273ec6f3eba2e74dfc3acd0d9f5ba9d19c132"
  location = "australia-southeast2"
  creds    = "path/to/service-account-credentials.json"
  project  = "onair-340ad"
}

provider "google" {
  credentials = file(local.creds)
  project     = local.project
  location    = local.location
}

# Artifact registry
resource "google_artifact_registry_repository" "server-artifact" {
  location      = local.location
  repository_id = "interruption-server"
  description   = "This resource is the repository for the docker image of interruptions backend currently only contains the websocket version"
  format        = "DOCKER"
}

resource "google_cloud_run_service" "my-service" {
  name     = "interruption-websocket-aus1"
  location = local.location
  template {
    spec {
      containers {
        image = server-arti
      }
    }
  }
}

