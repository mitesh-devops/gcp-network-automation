# 3. Firewall rules: the "security guard".

# Web visitors may come in on port 80.
resource "google_compute_firewall" "allow_http" {
  name          = "demo-allow-http"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# SSH (port 22) is allowed ONLY from Google's IAP range, never the open internet.
resource "google_compute_firewall" "allow_ssh_iap" {
  name          = "demo-allow-ssh-iap"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
