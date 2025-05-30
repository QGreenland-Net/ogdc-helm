#!/bin/bash

set -e

ENV="${1:-dev}"
NAMESPACE="${2:-qgnet}"
RELEASE_NAME="qgnet-ogdc"

if [[ "$ENV" != "dev" && "$ENV" != "stage" && "$ENV" != "prod" ]]; then
    echo "Invalid environment: $ENV"
    echo "Usage: $0 [dev|stage|prod] [namespace]"
    exit 1
fi

echo "Using env=${ENV}"
echo "Using namespace=${NAMESPACE}"

# Check if kubectl can connect to the cluster
echo "Checking Kubernetes connection..."
if ! kubectl get namespace ${NAMESPACE}; then
    echo "Error: Cannot connect to Kubernetes cluster or namespace ${NAMESPACE} does not exist"
    exit 1
fi

# Get PostgreSQL credentials from Kubernetes secret
PG_USER=$(kubectl get secret --namespace ${NAMESPACE} "${RELEASE_NAME}-postgresql-credentials" -o jsonpath="{.data.postgres-username}" | base64 --decode)
PG_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} "${RELEASE_NAME}-postgresql-credentials" -o jsonpath="{.data.postgres-password}" | base64 --decode)
PG_PORT=5432
PG_SERVICE_NAME="svc/${RELEASE_NAME}-postgresql"
PG_DB=$RELEASE_NAME

echo -e "\nPostgreSQL connection details:"
echo "PostgreSQL credentials:"
echo "User: ${PG_USER}"
echo "Database: ${PG_DB}"
echo "Port: ${PG_PORT}"

echo  -e "\nYou can now connect to PostgreSQL using the following command:"
echo "PGPASSWORD=${PG_PASSWORD} psql -h localhost -U ${PG_USER} -d ${PG_DB}"

echo  -e "\nConnecting to PostgreSQL at localhost:${PG_PORT}"
kubectl port-forward --namespace ${NAMESPACE} svc/${RELEASE_NAME}-postgresql ${PG_PORT}
