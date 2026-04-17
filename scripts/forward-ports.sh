#!/bin/bash

set -e

export RELEASE_NAME="${RELEASE_NAME:-qgnet-ogdc}"
export NAMESPACE="${NAMESPACE:-qgnet}"

kubectl --namespace "$NAMESPACE" port-forward "services/${RELEASE_NAME}-argo-workflows-server" 2746:2746
