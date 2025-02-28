#!/bin/bash

set -e

ENV="$1"

if [ "$#" -ne 1 ]; then
    echo "Must provide environment"
    exit 1
fi
echo "Using ENV=${ENV}"

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

# This is used just in dev
# TODO: only enable this behavior in dev.
if [ "$ENV" = "dev" ]; then
  if [ -z "$OGDC_PV_HOST_PATH" ]; then
    OGDC_PV_HOST_PATH="${THIS_DIR}/../ogdc-local-hostmount/"
  fi
  mkdir -p ${OGDC_PV_HOST_PATH}
  OGDC_PV_HOST_PATH=$(realpath "${OGDC_PV_HOST_PATH}")
  echo "Using OGDC_PV_HOST_PATH=${OGDC_PV_HOST_PATH}"
fi

# Add repos and bulid deps.
# TODO: should this be unnecessary? Helm knows where our dependencies live
# because we list them in the `Chart.yaml`.
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency update helm/
helm dependency build helm/

RELEASE_NAME="qgnet-ogdc"
echo "Using RELEASE_NAME=${RELEASE_NAME}"
QGNET_WORKFLOW_PVC_NAME="${RELEASE_NAME}-workflow-pvc"
echo "Using QGNET_WORKFLOW_PVC_NAME=${QGNET_WORKFLOW_PVC_NAME}"

# `qgnet-ogdc` is the "release name".
helm install --set ENV="$ENV" --set QGNetWorkflowPVCName="$QGNET_WORKFLOW_PVC_NAME" --set OgdcPVHostPath="$OGDC_PV_HOST_PATH" $RELEASE_NAME "$THIS_DIR/../helm" -n qgnet
