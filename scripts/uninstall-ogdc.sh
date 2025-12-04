#!/bin/bash

set -e

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

helm uninstall $RELEASE_NAME -n $NAMESPACE
"$THIS_DIR/remove-argo-crds.sh"

