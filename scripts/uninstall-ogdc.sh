#!/bin/bash

set -e

ENV="${1:-local}"

# Default release name and namespace if not set in the environment.
export RELEASE_NAME="${RELEASE_NAME:-qgnet-ogdc}"
export NAMESPACE="${NAMESPACE:-qgnet}"

# Validate environment, only allow local, dev, prod. Defaults to local
if [[ "$ENV" != "local" && "$ENV" != "dev" && "$ENV" != "prod" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: $0 [local|dev|prod]"
    exit 1
fi

echo "Using env=${ENV}"
echo "Using namespace=${NAMESPACE}"
echo "Using release name=${RELEASE_NAME}"

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

helm uninstall $RELEASE_NAME -n $NAMESPACE

# Only remove CRDs in local environment. For dev/prod environments, CRDs are managed separately.
if [[ "$ENV" == "local" ]]; then
    echo "Removing Argo CRDs..."
    "$THIS_DIR/remove-argo-crds.sh"
fi

