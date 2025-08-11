#!/bin/bash

set -e

echo "=== Cleaning up Argo CRDs ==="

# Delete any existing workflow resources first
echo "Removing workflow resources..."
kubectl delete workflows --all --all-namespaces --ignore-not-found=true || true
kubectl delete workflowtemplates --all --all-namespaces --ignore-not-found=true || true
kubectl delete clusterworkflowtemplates --all --ignore-not-found=true || true

# Remove all Argo CRDs
echo "Removing Argo CRDs..."
kubectl get crds -o name | grep argoproj.io | xargs -r kubectl delete || true

# Force remove any stuck CRDs
echo "Checking for stuck CRDs..."
for crd in $(kubectl get crds -o name | grep argoproj.io | cut -d/ -f2); do
    echo "Force removing $crd..."
    kubectl patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
done

echo "✅ Cleanup complete. You can now run the install script."
