#!/bin/bash

set -e

if [ -z "$RELEASE_NAME" ]; then
    echo "RELEASE_NAME envvar must be set."
    exit 1
fi

kubectl --namespace qgnet port-forward "services/${RELEASE_NAME}-argo-workflows-server" 2746:2746
