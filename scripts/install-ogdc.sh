#!/bin/bash

set -e

ENV="${1:-local}"

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
fi

# Add repos and build deps.
helm repo add minio https://charts.min.io/
helm repo add argo-workflows https://argoproj.github.io/argo-helm
helm dependency update helm/
helm dependency build helm/

# `qgnet-ogdc` is the "release name".
envsubst < "$VALUES_FILE" | helm install \
  "$RELEASE_NAME" "$THIS_DIR/../helm" \
  -n "$NAMESPACE" -f -
