terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # Remote state = Terraform's shared notebook, kept in a versioned GCS bucket.
  # The bucket name is passed in by Cloud Build at "terraform init" time.
  backend "gcs" {
    prefix = "network"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
