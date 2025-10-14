#!/bin/bash

set -e

ENV="${1:-local}"
NAMESPACE="${2:-qgnet}"

# Validate environment
# Only allow local, dev, prod
# Defaults to local
# local: for local development with rancher desktop
# dev: for development/staging environment deployment on ADC dev-k8s cluster
# prod: for production environment (e.g. GKE, EKS, AKS)
if [[ "$ENV" != "local" && "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: $0 [local|dev|prod] [namespace]"
    exit 1
fi

echo "Using env=${ENV}"
echo "Using namespace=${NAMESPACE}"

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

if [[ "$ENV" == "local" ]]; then
    VALUES_FILE="$THIS_DIR/../helm/examples/values-local-cluster-ogdc-example.yaml"
elif [[ "$ENV" == "dev" ]]; then
    VALUES_FILE="$THIS_DIR/../helm/examples/values-dev-cluster-ogdc-example.yaml"
fi

helm repo add minio https://charts.min.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update helm/
helm dependency build helm/

RELEASE_NAME="qgnet-ogdc"
NAMESPACE="qgnet"
echo "Using RELEASE_NAME=${RELEASE_NAME}"
QGNET_WORKFLOW_PVC_NAME="${RELEASE_NAME}-workflow-pvc"
echo "Using QGNET_WORKFLOW_PVC_NAME=${QGNET_WORKFLOW_PVC_NAME}"

# `qgnet-ogdc` is the "release name".
helm install \
  "$RELEASE_NAME" "$THIS_DIR/../helm" \
  -n "$NAMESPACE" --create-namespace \
  -f "$VALUES_FILE"
