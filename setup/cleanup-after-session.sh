#!/usr/bin/env bash
# OPTIONAL: run AFTER the session (and after the destroy demo) to remove
# the setup pieces too. Deleting the bucket deletes all state history.
set -euo pipefail
PROJECT_ID="${1:?Usage: ./setup/cleanup-after-session.sh <project-id>}"
read -r -p "Delete gs://${PROJECT_ID}-tfstate and terraform-sa? Type yes: " OK
[ "${OK}" = "yes" ] || { echo "Cancelled."; exit 0; }
gcloud storage rm -r "gs://${PROJECT_ID}-tfstate"
gcloud iam service-accounts delete "terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" --quiet
echo "Cleanup done. Remember to delete the Cloud Build triggers in the console."
