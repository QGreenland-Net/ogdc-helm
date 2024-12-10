#!/bin/bash

set -e

kubectl --namespace argo-helm port-forward services/qgnet-argo-argo-workflows-server 2746:2746
