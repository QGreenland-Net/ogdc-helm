#!/bin/bash

set -e

KEY_OUT=$(mktemp)
CERT_OUT=$(mktemp)

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEY_OUT" -out "$CERT_OUT" -subj "/CN=localhost/O=localhost"

NAMESPACE="${NAMESPACE:-qgnet}"
kubectl create -n "$NAMESPACE" secret tls ingress-nginx-tls-cert --cert="$CERT_OUT" --key="$KEY_OUT"

rm "$KEY_OUT" "$CERT_OUT"
