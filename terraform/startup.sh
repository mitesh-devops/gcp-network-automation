#!/bin/bash
# Runs once when the VM boots: install nginx and publish a simple page.
apt-get update -y
apt-get install -y nginx
cat > /var/www/html/index.html << 'HTML'
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Cloud Network Automation on GCP</title></head>
<body style="font-family: sans-serif; text-align: center; padding-top: 15vh; background: #16202E; color: #F5F3EE;">
  <h1>It works on first run</h1>
  <p>This network and server were built by Terraform on Nirma Uni, run by Google Cloud Build.</p>
</body>
</html>
HTML
systemctl enable --now nginx
