variable "project_id" {
  description = "Google Cloud project ID (passed in by Cloud Build)."
  type        = string
}

variable "region" {
  description = "The single region everything is built in."
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "Zone for the demo VM."
  type        = string
  default     = "asia-south1-a"
}

variable "subnet_cidr" {
  description = "Address range of the subnet (the building)."
  type        = string
  default     = "10.10.1.0/24"
}
