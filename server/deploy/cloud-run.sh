#!/usr/bin/env bash
# Deploys the MealPal API to Cloud Run. Run from the repo's server/ folder.
#   PROJECT=<gcp project id> deploy/cloud-run.sh setup    # once: APIs, service account, secrets access
#   PROJECT=<gcp project id> deploy/cloud-run.sh deploy   # every release
# Secrets are created by hand first, so no key passes through this script:
#   gcloud secrets create anthropic-api-key --data-file=-   (paste the key, then Ctrl-D)
#   openssl rand -base64 32 | tr -d '\n' | gcloud secrets create mealpal-app-key --data-file=-
set -euo pipefail

: "${PROJECT:?set PROJECT to the Google Cloud project id}"
REGION="${REGION:-asia-southeast1}"
SERVICE="${SERVICE:-mealpal-api}"
SA="mealpal-api@${PROJECT}.iam.gserviceaccount.com"
LOCK="anthropic/claude-lock.json"

case "${1:-}" in
  setup)
    gcloud services enable run.googleapis.com cloudbuild.googleapis.com \
      artifactregistry.googleapis.com secretmanager.googleapis.com --project "$PROJECT"
    gcloud iam service-accounts describe "$SA" --project "$PROJECT" >/dev/null 2>&1 ||
      gcloud iam service-accounts create mealpal-api --project "$PROJECT" \
        --display-name "MealPal API (Cloud Run)"
    # The service reads only its two secrets; nothing else in the project.
    for secret in anthropic-api-key mealpal-app-key; do
      gcloud secrets add-iam-policy-binding "$secret" --project "$PROJECT" \
        --member "serviceAccount:${SA}" --role roles/secretmanager.secretAccessor >/dev/null
    done
    echo "setup done for ${PROJECT}"
    ;;
  deploy)
    planner=$(jq -r '.resources["./agents/meal-planner.md"].id' "$LOCK")
    environment=$(jq -r '.resources["./environments/planner.yaml"].id' "$LOCK")
    # Scale to zero; at most two instances, which also caps how fast anyone can spend.
    gcloud run deploy "$SERVICE" --project "$PROJECT" --region "$REGION" --source . \
      --service-account "$SA" --allow-unauthenticated \
      --cpu 1 --memory 512Mi --min-instances 0 --max-instances 2 \
      --set-env-vars "MEALPAL_AGENT_PLANNER_ID=${planner},MEALPAL_AGENT_ENVIRONMENT_ID=${environment}" \
      --set-secrets "ANTHROPIC_API_KEY=anthropic-api-key:latest,MEALPAL_API_APP_KEY=mealpal-app-key:latest"
    ;;
  *)
    echo "usage: PROJECT=<id> $0 setup|deploy" >&2
    exit 2
    ;;
esac
