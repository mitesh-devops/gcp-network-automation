# 5. VM: the "flat" where our website lives.
resource "google_compute_instance" "web" {
  name         = "demo-web"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    # An empty access_config block gives the VM a public IP address.
    access_config {}
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  # The VM needs the road (route) to download nginx, and the guard
  # (firewall) in place before visitors arrive, so it is built last.
  depends_on = [
    google_compute_route.internet,
    google_compute_firewall.allow_http,
    google_compute_firewall.allow_ssh_iap,
  ]
}
