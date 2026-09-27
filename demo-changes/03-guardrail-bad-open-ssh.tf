# DEMO 3 (Guardrail): the risky change. Copy into terraform/ on a new branch.
# Expected: step "2-inspect-guardrail" FAILS (CKV_GCP_2) and the PR cannot merge.
# NEVER merge this.
resource "google_compute_firewall" "allow_ssh_anywhere" {
  name          = "demo-allow-ssh-anywhere"
  network       = google_compute_network.vpc.id
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
