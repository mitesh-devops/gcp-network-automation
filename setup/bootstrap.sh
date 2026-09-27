#!/usr/bin/env bash
# ONE-TIME SETUP (run before the session, not during the demo).
# Creates the things the pipeline itself needs:
#   - APIs switched on
#   - the state bucket (Terraform's shared notebook), with versioning
#   - the service account (the robot's ID card) with only the roles it needs
# Usage: ./setup/bootstrap.sh <project-id> [region]
set -euo pipefail

PROJECT_ID="${1:?Usage: ./setup/bootstrap.sh <project-id> [region]}"
REGION="${2:-asia-south1}"
BUCKET="${PROJECT_ID}-tfstate"
SA_NAME="terraform-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Using project ${PROJECT_ID}, region ${REGION}"
gcloud config set project "${PROJECT_ID}" >/dev/null

echo "==> 1/4 Enabling APIs (takes a minute)"
gcloud services enable \
  compute.googleapis.com \
  cloudbuild.googleapis.com \
  iap.googleapis.com \
  secretmanager.googleapis.com \
  storage.googleapis.com \
  logging.googleapis.com

echo "==> 2/4 Creating the state bucket gs://${BUCKET} (versioned)"
if ! gcloud storage buckets describe "gs://${BUCKET}" >/dev/null 2>&1; then
  gcloud storage buckets create "gs://${BUCKET}" \
    --location="${REGION}" \
    --uniform-bucket-level-access
fi
gcloud storage buckets update "gs://${BUCKET}" --versioning

echo "==> 3/4 Creating the pipeline service account ${SA_EMAIL}"
if ! gcloud iam service-accounts describe "${SA_EMAIL}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SA_NAME}" \
    --display-name="Terraform pipeline (the robot)"
  sleep 10 # give IAM a moment to see the new account
fi

echo "==> 4/4 Granting the robot only the roles it needs"
for ROLE in \
  roles/compute.networkAdmin \
  roles/compute.securityAdmin \
  roles/compute.instanceAdmin.v1 \
  roles/logging.logWriter; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="${ROLE}" \
    --condition=None --quiet >/dev/null
  echo "    granted ${ROLE}"
done
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectAdmin" >/dev/null
echo "    granted roles/storage.objectAdmin on the state bucket"

cat << DONE

Setup complete. Values you will need when creating the Cloud Build triggers:
  Region            : ${REGION}
  Service account   : ${SA_EMAIL}
  _TF_STATE_BUCKET  : ${BUCKET}
DONE
