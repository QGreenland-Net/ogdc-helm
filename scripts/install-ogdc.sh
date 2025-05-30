#!/bin/bash

set -e

ENV="${1:-dev}"
NAMESPACE="${2:-qgnet}"

if [[ "$ENV" != "dev" && "$ENV" != "stage" && "$ENV" != "prod" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: $0 [dev|stage|prod] [namespace]"
    exit 1
fi

echo "Using env=${ENV}"
echo "Using namespace=${NAMESPACE}"

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

# This is used just in dev
if [ "$ENV" = "dev" ]; then
  if [ -z "$OGDC_PV_HOST_PATH" ]; then
    OGDC_PV_HOST_PATH="${THIS_DIR}/../ogdc-local-hostmount/"
  fi
  mkdir -p "${OGDC_PV_HOST_PATH}"
  OGDC_PV_HOST_PATH=$(realpath "${OGDC_PV_HOST_PATH}")
  echo "Using OGDC_PV_HOST_PATH=${OGDC_PV_HOST_PATH}"
fi

# Add repos and build deps.
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
  --set env="$ENV" \
  --set OgdcNamespace="$NAMESPACE" \
  --set QGNetWorkflowPVCName="$QGNET_WORKFLOW_PVC_NAME" \
  --set OgdcPVHostPath="$OGDC_PV_HOST_PATH" \
  "$RELEASE_NAME" "$THIS_DIR/../helm" \
  -n "$NAMESPACE" --create-namespace
