#!/bin/bash

set -e

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

# Ensure that crds are cleaned up on skaffold exit. If this is not run after
# skaffold exits, then crds will be stuck in a "terminating" condition
# indefinitely and argo will fail.
cleanup() {
  "$THIS_DIR/remove-argo-crds.sh"
}

trap cleanup EXIT

skaffold dev
