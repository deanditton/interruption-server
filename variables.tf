# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator.
# ---------------------------------------------------------------------------------------------------------------------

variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# ---------------------------------------------------------------------------------------------------------------------

variable "gcr_region" {
  description = "Name of the GCP region where the GCR registry is located. e.g: 'us' or 'eu'."
  type        = string
  default     = "australia-southeast2"
}


variable "location" {
  description = "The location (region or zone) to deploy the Cloud Run services. Note: Be sure to pick a region that supports Cloud Run."
  type        = string
  default     = "australia-southeast2"
}

variable "notification_service" {
  description = "The name of the Cloud Run service to deploy."
  type        = string
  default     = "interruption-notification-service"
}

variable "repository_name" {
  description = "Name of the Google Cloud Source Repository to create."
  type        = string
  default     = "interruption-server"
}

variable "image_name" {
  description = "The name of the image to deploy. Defaults to a publicly available image."
  type        = string
  default     = "gcr.io/cloudrun/hello"
}

variable "branch_name" {
  description = "Branch name used to trigger builds."
  type        = string
  default     = "main"
}

