#!/bin/bash

set -e

KEY_OUT=$(mktemp)
CERT_OUT=$(mktemp)

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEY_OUT" -out "$CERT_OUT" -subj "/CN=localhost/O=localhost"

NAMESPACE="${NAMESPACE:-qgnet}"
RELEASE_NAME="${RELEASE_NAME:-qgnet-ogdc}"
kubectl create -n "$NAMESPACE" secret tls "${RELEASE_NAME}-local-tls-cert" \
  --cert="$CERT_OUT" \
  --key="$KEY_OUT" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

rm "$KEY_OUT" "$CERT_OUT"
