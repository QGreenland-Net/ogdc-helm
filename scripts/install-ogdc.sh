#!/bin/bash

set -e

THIS_DIR="$( cd "$(dirname "$0")"; pwd -P )"

helm repo add minio https://charts.min.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency build helm/
# `qgnet-ogdc` is the "release name".
helm install qgnet-ogdc "$THIS_DIR/../helm" -n qgnet
