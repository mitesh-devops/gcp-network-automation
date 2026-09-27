output "vm_external_ip" {
  description = "Public IP address of the demo VM."
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
}

output "website_url" {
  description = "Open this in a browser to see the demo page."
  value       = "http://${google_compute_instance.web.network_interface[0].access_config[0].nat_ip}"
}
