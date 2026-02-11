#!/usr/bin/env bash
set -euo pipefail

# Extract the --print_file value from cloudshell_open command in history
PRINT_FILE=$(cat ~/.bash_history | grep cloudshell_open | grep -oP '(?<=--print_file[=\s])\S+' | tail -1 | tr -d '"')

if [ -z "$PRINT_FILE" ]; then
    echo "No cloudshell_open command with --print_file parameter found in history"
    exit 1
fi

PROJECT_ID="$1"
GITHUB_REPO="$PRINT_FILE"
GITHUB_BRANCH="main"

SAFE_REPO_NAME=$(echo "$GITHUB_REPO" | tr '[:upper:]' '[:lower:]' | tr '/_' '-')
POOL_NAME="${SAFE_REPO_NAME:0:26}-pool"
PROVIDER_NAME="${SAFE_REPO_NAME:0:23}-provider"

echo "Setting up Workload Identity for GitHub"
echo "Project ID: $PROJECT_ID"
echo "GitHub repo: $GITHUB_REPO"
echo "Branch: $GITHUB_BRANCH"
echo "Workload Identity Pool: $POOL_NAME"
echo "OIDC Provider: $PROVIDER_NAME"

if ! gcloud iam workload-identity-pools describe "$POOL_NAME" --project="$PROJECT_ID" --location="global" >/dev/null 2>&1; then
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --display-name="GitHub Actions Pool for $GITHUB_REPO"
else
    echo "Workload Identity Pool $POOL_NAME already exists, skipping"
fi

if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
        --project="$PROJECT_ID" --location="global" --workload-identity-pool="$POOL_NAME" >/dev/null 2>&1; then
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --display-name="GitHub Actions Provider" \
        --issuer-uri="https://token.actions.githubusercontent.com" \
        --attribute-mapping="google.subject=assertion.sub,repository=assertion.repository,ref=assertion.ref"
else
    echo "OIDC Provider $PROVIDER_NAME already exists, skipping"
fi

PRINCIPAL="principalSet://iam.googleapis.com/projects/$PROJECT_ID/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_REPO"

EXISTS=$(gcloud projects get-iam-policy "$PROJECT_ID" \
    --format="json(bindings)" | \
    jq --arg role "roles/owner" --arg member "$PRINCIPAL" \
        '.bindings[] | select(.role==$role) | .members[] | select(.==$member)' | wc -l)

if [ "$EXISTS" -eq 0 ]; then
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --role="roles/owner" \
        --member="$PRINCIPAL" \
        --condition="expression=resource.name.startsWith('projects/$PROJECT_ID'),title=GitHubFullAccess,$GITHUB_BRANCH"
else
    echo "IAM binding for $GITHUB_REPO already exists, skipping"
fi

echo "Workload Identity setup complete!"
