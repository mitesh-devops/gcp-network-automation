# 1. VPC network: our private "gated society".
#    We delete Google's automatic default route so that the route
#    to the internet is also written in code (see route.tf).
resource "google_compute_network" "vpc" {
  name                            = "demo-vpc"
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = true
}

# 2. Subnet: a "building" inside the society.
resource "google_compute_subnetwork" "subnet" {
  name          = "demo-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
