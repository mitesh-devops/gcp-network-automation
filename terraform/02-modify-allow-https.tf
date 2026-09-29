# DEMO 2 (Modify): copy this file into terraform/ on a new branch.
# Expected plan: 1 to add, 0 to change, 0 to destroy.
resource "google_compute_firewall" "allow_https" {
  name          = "demo-allow-https"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
