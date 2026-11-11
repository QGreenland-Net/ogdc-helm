#!/bin/bash

set -e

ENV="${1:-local}"

# Default release name and namespace if not set in the environment.
# These must match the values used when creating the admin resources
# (secrets, PVCs, DB cluster) in helm/admin/.
export RELEASE_NAME="${RELEASE_NAME:-qgnet-ogdc}"
export NAMESPACE="${NAMESPACE:-qgnet}"

# Validate environment
# Only allow local, dev, prod
# Defaults to local
# local: for local development with rancher desktop
# dev: for development/staging environment deployment on ADC dev-k8s cluster
# prod: for production environment (e.g. GKE, EKS, AKS)
if [[ "$ENV" != "local" && "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: $0 [local|dev|prod]"
    exit 1
fi

echo "Using env=${ENV}"
echo "Using namespace=${NAMESPACE}"
echo "Using release name=${RELEASE_NAME}"

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

if [[ "$ENV" == "local" ]]; then
    VALUES_FILE="$THIS_DIR/../helm/examples/values-local-cluster-ogdc-example.yaml"
    echo "Using OGDC_PV_HOST_PATH=${OGDC_PV_HOST_PATH}"
elif [[ "$ENV" == "dev" ]]; then
    VALUES_FILE="$THIS_DIR/../helm/examples/values-dev-cluster-ogdc-example.yaml"
elif [[ "$ENV" == "prod" ]]; then
    VALUES_FILE="$THIS_DIR/../helm/examples/values-prod-cluster-ogdc-example.yaml"
fi

# The S3 credentials Secret (`${RELEASE_NAME}-s3-credentials`) is created outside
# helm, from the `-s3-credentials` document in helm/admin/secrets.yaml. For `local`
# it is created here (with random values) when missing, to be used by the
# in-cluster SeaweedFS; for dev/prod it must already exist (edit secrets.yaml first).
S3_SECRET="${RELEASE_NAME}-s3-credentials"
if ! kubectl get secret "$S3_SECRET" -n "$NAMESPACE" >/dev/null 2>&1; then
    if [[ "$ENV" != "local" ]]; then
        echo "Secret $S3_SECRET not found in namespace $NAMESPACE."
        echo "Edit helm/admin/secrets.yaml and apply it first (see README.md)."
        exit 1
    fi
    echo "Creating Secret $S3_SECRET with random local credentials"
    awk -v RS='\n---\n' '/kind: Secret/ && /-s3-credentials/' "$THIS_DIR/../helm/admin/secrets.yaml" \
      | envsubst '${RELEASE_NAME}' \
      | while IFS= read -r line; do
          if [[ "$line" == *"your-value-here"* ]]; then
              echo "${line/your-value-here/$(openssl rand -hex 16)}"
          else
              echo "$line"
          fi
        done \
      | kubectl apply -n "$NAMESPACE" -f -
fi

# Add repos and build deps.
helm repo add argo-workflows https://argoproj.github.io/argo-helm
helm dependency update helm/
helm dependency build helm/

# Install OGDC with the appropriate values file for the environment.
envsubst '${RELEASE_NAME} ${NAMESPACE}' < "$VALUES_FILE" | helm install \
  "$RELEASE_NAME" "$THIS_DIR/../helm" \
  -n "$NAMESPACE" -f -
