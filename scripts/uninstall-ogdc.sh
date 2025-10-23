#!/bin/bash

set -e

helm uninstall $RELEASE_NAME -n $NAMESPACE

# Force remove any stuck CRDs
echo "Checking for stuck CRDs..."
for crd in $(kubectl get crds -o name | grep argoproj.io | cut -d/ -f2); do
    echo "Force removing $crd..."
    kubectl patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
done

echo "Removing Argo CRDs..."
kubectl get crds -o name | grep argoproj.io | xargs -r kubectl delete || true