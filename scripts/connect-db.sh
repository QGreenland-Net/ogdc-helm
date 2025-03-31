#!/bin/bash

# Enable debugging
set -x

# Don't exit immediately on error to see what's failing
# set -e 

ENV="$1"

if [ "$#" -ne 1 ]; then
    echo "Must provide environment"
    exit 1
fi

echo "Using ENV=${ENV}"

RELEASE_NAME="qgnet-ogdc"
NAMESPACE="qgnet"

# Check if kubectl can connect to the cluster
echo "Checking Kubernetes connection..."
if ! kubectl get namespace ${NAMESPACE}; then
    echo "Error: Cannot connect to Kubernetes cluster or namespace ${NAMESPACE} does not exist"
    exit 1
fi

# Get PostgreSQL credentials from Kubernetes secret
PG_USER=postgres
PG_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} "${RELEASE_NAME}-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode)
PG_PORT=5432
PG_SERVICE_NAME="svc/${RELEASE_NAME}-postgresql"
PG_DB=$PG_USER

echo "Connecting to PostgreSQL at localhost:${PG_PORT}"

# Kill existing process using the port if any
EXISTING_PID=$(lsof -ti :${PG_PORT} 2>/dev/null)
if [ -n "$EXISTING_PID" ]; then
    echo "Port ${PG_PORT} is in use by process ${EXISTING_PID}, killing it..."
    kill -9 $EXISTING_PID
    sleep 2
fi

# Port forward PostgreSQL service
echo "Starting port-forward for PostgreSQL..."
kubectl port-forward --namespace ${NAMESPACE} ${PG_SERVICE_NAME} ${PG_PORT}:${PG_PORT} &
PORT_FORWARD_PID=$!
trap "kill ${PORT_FORWARD_PID} 2>/dev/null || true" EXIT

# Wait for port to be available
echo "Waiting for port ${PG_PORT} to become available..."
RETRY_COUNT=0
MAX_RETRIES=10

until nc -z localhost ${PG_PORT} 2>/dev/null; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ ${RETRY_COUNT} -ge ${MAX_RETRIES} ]; then
        echo "Error: Port forwarding failed after ${MAX_RETRIES} attempts"
        exit 1
    fi
    echo "Waiting for port forwarding to be established (attempt ${RETRY_COUNT}/${MAX_RETRIES})..."
    sleep 2
done

echo "Port forwarding established!"

# Connect to PostgreSQL
echo "Attempting to connect to PostgreSQL..."
if ! PGPASSWORD=${PG_PASSWORD} psql -h localhost -U ${PG_USER} -d ${PG_DB} -c "SELECT 1;"; then
    echo "Failed to connect to PostgreSQL. Please check your credentials and port forwarding."
    exit 1
fi

echo "Successfully connected to PostgreSQL."