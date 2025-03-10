#!/bin/bash

set -e

RELEASE_NAME="qgnet-ogdc"
NAMESPACE="qgnet"

helm uninstall $RELEASE_NAME -n $NAMESPACE
