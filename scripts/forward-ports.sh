#!/bin/bash

set -e

kubectl --namespace qgnet port-forward services/qgnet-ogdc-argo-workflows-server 2746:2746
