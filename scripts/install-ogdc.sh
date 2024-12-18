#!/bin/bash

set -e

ENV="$1"

if [ "$#" -ne 1 ]; then
    echo "Must provide environment"
    exit 1
fi

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

# This is used just in dev
# TODO: only enable this behavior in dev.
if [ "$ENV" = "dev" ]; then
  if [ -z "$OGDC_PV_HOST_PATH" ]; then
    OGDC_PV_HOST_PATH=$(realpath "${THIS_DIR}/../ogdc-local-hostmount/")
  fi
  mkdir -p OGDC_PV_HOST_PATH
else
    echo "env is not dev"
fi

helm repo add minio https://charts.min.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency build helm/
# `qgnet-ogdc` is the "release name".
helm install --set OgdcPVHostPath="$OGDC_PV_HOST_PATH" qgnet-ogdc "$THIS_DIR/../helm" -n qgnet
