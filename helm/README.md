# OGDC Helm Chart

![Version: 0.4.4](https://img.shields.io/badge/Version-0.4.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: develop](https://img.shields.io/badge/AppVersion-develop-informational?style=flat-square)

Helm chart for Kubernetes Deployment of OGDC
(https://github.com/QGreenland-Net/ogdc-helm)

**Homepage:** <https://github.com/QGreenland-Net/ogdc-helm>

## Source Code

* <https://github.com/QGreenland-Net/ogdc-helm>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://argoproj.github.io/argo-helm | argo-workflows | 0.45.26 |

## Overview

OGDC (Open Geospatial Data Cloud) is a Helm chart for deploying a complete geospatial data processing pipeline on Kubernetes. This chart includes:

- **Argo Workflows**: For orchestrating and managing data processing workflows
- **S3 object storage**: an external S3-compatible store (configured via `global.s3`) for artifacts and data
- **OGDC Runner**: The main application service
- **Cloud Native PostgresQL**: CNPG database cluster instance for OGDC backend. 

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installation

Refer to the [getting started](https://github.com/QGreenland-Net/ogdc-helm?tab=readme-ov-file#getting-started) guide for detailed installation instructions. 

## Parameters

### Global parameters


### Global Configuration

| Name                          | Description                                                                                                      | Value        |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------ |
| `global.defaultStorageClass`  | Global default StorageClass for Persistent Volume(s)                                                             | `local-path` |
| `global.s3.endpoint`          | S3 endpoint URL, including the scheme (e.g. https://s3.example.org[:port]). Required.                            | `""`         |
| `global.s3.region`            | S3 region (Ceph RGW uses `default`)                                                                              | `default`    |
| `global.s3.bucket`            | Bucket for workflow artifacts and outputs. Required.                                                             | `""`         |
| `global.s3.forcePathStyle`    | Use path-style addressing (`<endpoint>/<bucket>/<key>`); sets S3_ADDRESSING_STYLE to `path`, otherwise `virtual` | `true`       |
| `global.s3.credentialsSecret` | Name of the Secret holding keys `accessKeyId` and `secretAccessKey`                                              | `""`         |
| `nameOverride`                | String to partially override chart name-derived resource names                                                   | `""`         |
| `fullnameOverride`            | String to fully override chart name-derived resource names                                                       | `""`         |

### Argo Workflows Configuration

| Name                                                                                      | Description                                                                                | Value                                                                                            |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `argo-workflows.singleNamespace`                                                          | Restrict Argo to operate only in a single namespace                                        | `true`                                                                                           |
| `argo-workflows.crds.install`                                                             | Install and upgrade CRDs                                                                   | `true`                                                                                           |
| `argo-workflows.crds.keep`                                                                | Keep CRDs on chart uninstall                                                               | `false`                                                                                          |
| `argo-workflows.crds.annotations`                                                         | Annotations to be added to all CRDs                                                        | `{}`                                                                                             |
| `argo-workflows.createAggregateRoles`                                                     | Create ClusterRoles that extend existing ClusterRoles to interact with Argo Workflows CRDs | `true`                                                                                           |
| `argo-workflows.workflow.serviceAccount.create`                                           | Specifies whether a service account should be created                                      | `true`                                                                                           |
| `argo-workflows.workflow.serviceAccount.name`                                             | Service account which is used to run workflows                                             | `argo-workflow`                                                                                  |
| `argo-workflows.workflow.serviceAccount.automountServiceAccountToken`                     | Automount service account token for the workflow pods                                      | `true`                                                                                           |
| `argo-workflows.workflow.rbac.create`                                                     | Adds Role and RoleBinding for the above specified service account                          | `true`                                                                                           |
| `argo-workflows.controller.resources.requests.memory`                                     | Memory requests for the workflow controller                                                | `2Gi`                                                                                            |
| `argo-workflows.controller.resources.requests.cpu`                                        | CPU requests for the workflow controller                                                   | `500m`                                                                                           |
| `argo-workflows.controller.resources.limits.memory`                                       | Memory limits for the workflow controller                                                  | `4Gi`                                                                                            |
| `argo-workflows.controller.resources.limits.cpu`                                          | CPU limits for the workflow controller                                                     | `1000m`                                                                                          |
| `argo-workflows.controller.persistence.archive`                                           | Enable archiving completed workflows to PostgreSQL                                         | `true`                                                                                           |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[0].key`      | Label selector key for first workflow archive condition                                    | `ogdc/persist-workflow-in-archive`                                                               |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[0].operator` | Label selector operator for first workflow archive condition                               | `In`                                                                                             |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[0].values`   | Label selector values for first workflow archive condition                                 | `["true"]`                                                                                       |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[1].key`      | Label selector key for second workflow archive condition                                   | `workflows.argoproj.io/phase`                                                                    |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[1].operator` | Label selector operator for second workflow archive condition                              | `In`                                                                                             |
| `argo-workflows.controller.persistence.archiveLabelSelector.matchExpressions[1].values`   | Label selector values for second workflow archive condition                                | `["Succeeded"]`                                                                                  |
| `argo-workflows.controller.persistence.postgresql.host`                                   | PostgreSQL database host for workflow archive                                              | `qgnet-ogdc-db-cnpg-rw`                                                                          |
| `argo-workflows.controller.persistence.postgresql.database`                               | PostgreSQL database name for workflow archive                                              | `ogdc`                                                                                           |
| `argo-workflows.controller.persistence.postgresql.tableName`                              | PostgreSQL table name for workflow archive                                                 | `argo_workflows_archive`                                                                         |
| `argo-workflows.controller.persistence.postgresql.userNameSecret.name`                    | Secret name containing PostgreSQL username                                                 | `qgnet-ogdc-db-postgres-secrets`                                                                 |
| `argo-workflows.controller.persistence.postgresql.userNameSecret.key`                     | Secret key for PostgreSQL username                                                         | `username`                                                                                       |
| `argo-workflows.controller.persistence.postgresql.passwordSecret.name`                    | Secret name containing PostgreSQL password                                                 | `qgnet-ogdc-db-postgres-secrets`                                                                 |
| `argo-workflows.controller.persistence.postgresql.passwordSecret.key`                     | Secret key for PostgreSQL password                                                         | `password`                                                                                       |
| `argo-workflows.controller.workflowNamespaces`                                            | Namespaces where workflow controller will manage workflows                                 | `["qgnet"]`                                                                                      |
| `argo-workflows.controller.workflowDefaults.spec.podGC.strategy`                          | Automatically cleanup pods on successful workflow completion                               | `OnWorkflowSuccess`                                                                              |
| `argo-workflows.controller.metricsConfig.enabled`                                         | Enables prometheus metrics server                                                          | `false`                                                                                          |
| `argo-workflows.server.enabled`                                                           | Deploy the Argo Server                                                                     | `true`                                                                                           |
| `argo-workflows.server.resources.requests.memory`                                         | Memory requests for the workflow server                                                    | `1Gi`                                                                                            |
| `argo-workflows.server.resources.requests.cpu`                                            | CPU requests for the workflow server                                                       | `200m`                                                                                           |
| `argo-workflows.server.resources.limits.memory`                                           | Memory limits for the workflow server                                                      | `2Gi`                                                                                            |
| `argo-workflows.server.resources.limits.cpu`                                              | CPU limits for the workflow server                                                         | `500m`                                                                                           |
| `argo-workflows.server.authModes`                                                         | A list of supported authentication modes                                                   | `["server"]`                                                                                     |
| `argo-workflows.server.ingress.enabled`                                                   | Enable an ingress resource for the Argo server                                             | `false`                                                                                          |
| `argo-workflows.executor.resources.requests.memory`                                       | Memory requests for the workflow executor                                                  | `1Gi`                                                                                            |
| `argo-workflows.executor.resources.requests.cpu`                                          | CPU requests for the workflow executor                                                     | `200m`                                                                                           |
| `argo-workflows.executor.resources.limits.memory`                                         | Memory limits for the workflow executor                                                    | `4Gi`                                                                                            |
| `argo-workflows.executor.resources.limits.cpu`                                            | CPU limits for the workflow executor                                                       | `1000m`                                                                                          |
| `argo-workflows.artifactRepository.archiveLogs`                                           | Archive the main container logs as an artifact                                             | `false`                                                                                          |
| `argo-workflows.artifactRepository.s3.bucket`                                             | S3 bucket name (templated from global.s3.bucket)                                           | `{{ .Values.global.s3.bucket }}`                                                                 |
| `argo-workflows.artifactRepository.s3.endpoint`                                           | S3 host[:port] without scheme (templated from global.s3.endpoint)                          | `{{ .Values.global.s3.endpoint | trimPrefix "https://" | trimPrefix "http://" }}`                |
| `argo-workflows.artifactRepository.s3.region`                                             | S3 region (templated from global.s3.region)                                                | `{{ .Values.global.s3.region }}`                                                                 |
| `argo-workflows.artifactRepository.s3.accessKeySecret.name`                               | Secret name containing S3 access key (templated from global.s3.credentialsSecret)          | `{{ .Values.global.s3.credentialsSecret | default (printf "%s-s3-credentials" .Release.Name) }}` |
| `argo-workflows.artifactRepository.s3.accessKeySecret.key`                                | Secret key for S3 access key                                                               | `accessKeyId`                                                                                    |
| `argo-workflows.artifactRepository.s3.secretKeySecret.name`                               | Secret name containing S3 secret key (templated from global.s3.credentialsSecret)          | `{{ .Values.global.s3.credentialsSecret | default (printf "%s-s3-credentials" .Release.Name) }}` |
| `argo-workflows.artifactRepository.s3.secretKeySecret.key`                                | Secret key for S3 secret key                                                               | `secretAccessKey`                                                                                |
| `argo-workflows.artifactRepository.s3.insecure`                                           | Disable TLS for S3 connection                                                              | `false`                                                                                          |

### OGDC Configuration

| Name               | Description                                    | Value          |
| ------------------ | ---------------------------------------------- | -------------- |
| `image.repository` | OGDC container image repository                | `ogdc-runner`  |
| `image.tag`        | OGDC container image tag                       | `latest`       |
| `image.pullPolicy` | OGDC container image pull policy               | `IfNotPresent` |
| `environment`      | Deployment environment name (local, dev, prod) | `""`           |

### API Access - Authentication and Authorization

| Name                        | Description                                                | Value                                                                                                                        |
| --------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `auth.accessMode`           | Access mode (authenticated, read_only, open)               | `authenticated`                                                                                                              |
| `auth.oidcSecretName`       | Existing Kubernetes Secret containing the OIDC client JSON | `""`                                                                                                                         |
| `auth.oidcSecretKey`        | Secret key containing the OIDC client JSON                 | `client_secrets.json`                                                                                                        |
| `auth.oidcMountPath`        | OIDC Secret mount directory                                | `/etc/ogdc/oidc`                                                                                                             |
| `auth.roleName.admin`       | Scope name for the admin role                              | `ogdc:admin`                                                                                                                 |
| `resources.requests.memory` | Memory requests for OGDC service                           | `1Gi`                                                                                                                        |
| `resources.requests.cpu`    | CPU requests for OGDC service                              | `500m`                                                                                                                       |
| `resources.limits.memory`   | Memory limits for OGDC service                             | `2Gi`                                                                                                                        |
| `resources.limits.cpu`      | CPU limits for OGDC service                                | `1000m`                                                                                                                      |
| `ogdc_service_command`      | Command to start the OGDC FastAPI service                  | `. ./.venv/bin/activate && fastapi run --port 8000 --host 0.0.0.0 --forwarded-allow-ips='*' src/ogdc_runner/service/main.py` |
| `dataone_node_url`          | DataONE member node URL for metadata retrieval             | `https://arcticdata.io/metacat/d1/mn`                                                                                        |
| `ogdc_public_host`          | Public host (no scheme, no path) for external access.      | `api.test.dataone.org`                                                                                                       |
| `ogdc_public_s3_url`        | Public S3 endpoint URL for external access.                | `""`                                                                                                                         |
| `ogdc_workflow_pvc_name`    | Name of the PVC to use for workflow storage.               | `cephfs-qgnet-ogdc-workflow-pvc`                                                                                             |
| `ogdc_input_pvcs`           | Allowlist of pre-provisioned PVCs that recipes may         | `[]`                                                                                                                         |
| `ogdc_max_parallel_limit`   | Maximum number of parallel workflow tasks.                 | `5`                                                                                                                          |
| `ogdc_viz_workflow_image`   | Container image used for visualization workflow pods.      | `ghcr.io/permafrostdiscoverygateway/pdgworkflow:latest`                                                                      |

### OGDC Workflow Runtime Configuration

| Name                                                | Description                                           | Value              |
| --------------------------------------------------- | ----------------------------------------------------- | ------------------ |
| `argo_workflow_retry.enabled`                       | Enable workflow-level retry defaults.                 | `true`             |
| `argo_workflow_retry.limit`                         | Number of retry attempts for workflow tasks.          | `3`                |
| `argo_workflow_retry.policy`                        | Argo retry policy for workflow tasks.                 | `OnTransientError` |
| `viz_workflow.image_pull_policy`                    | Image pull policy for viz worker pods.                | `IfNotPresent`     |
| `viz_workflow.setup_image`                          | Container image used by the viz setup pod.            | `""`               |
| `viz_workflow.default_partition_size`               | Default partition size for viz parallel fan-out.      | `1000`             |
| `viz_workflow.resources.stage.requests.cpu`         | CPU requests for staging and web tile worker pods.    | `500m`             |
| `viz_workflow.resources.stage.requests.memory`      | Memory requests for staging and web tile worker pods. | `2Gi`              |
| `viz_workflow.resources.stage.limits.cpu`           | CPU limits for staging and web tile worker pods.      | `2`                |
| `viz_workflow.resources.stage.limits.memory`        | Memory limits for staging and web tile worker pods.   | `6Gi`              |
| `viz_workflow.resources.raster.requests.cpu`        | CPU requests for raster and composite worker pods.    | `1`                |
| `viz_workflow.resources.raster.requests.memory`     | Memory requests for raster and composite worker pods. | `4Gi`              |
| `viz_workflow.resources.raster.limits.cpu`          | CPU limits for raster and composite worker pods.      | `4`                |
| `viz_workflow.resources.raster.limits.memory`       | Memory limits for raster and composite worker pods.   | `12Gi`             |
| `viz_workflow.resources.threedtile.requests.cpu`    | CPU requests for 3D tile worker pods.                 | `2`                |
| `viz_workflow.resources.threedtile.requests.memory` | Memory requests for 3D tile worker pods.              | `4Gi`              |
| `viz_workflow.resources.threedtile.limits.cpu`      | CPU limits for 3D tile worker pods.                   | `4`                |
| `viz_workflow.resources.threedtile.limits.memory`   | Memory limits for 3D tile worker pods.                | `8Gi`              |
| `viz_workflow.resources.discovery.requests.cpu`     | CPU requests for discovery worker pods.               | `250m`             |
| `viz_workflow.resources.discovery.requests.memory`  | Memory requests for discovery worker pods.            | `512Mi`            |
| `viz_workflow.resources.discovery.limits.cpu`       | CPU limits for discovery worker pods.                 | `500m`             |
| `viz_workflow.resources.discovery.limits.memory`    | Memory limits for discovery worker pods.              | `1Gi`              |

### Local S3 (SeaweedFS) Configuration

| Name                                 | Description                                                         | Value                 |
| ------------------------------------ | ------------------------------------------------------------------- | --------------------- |
| `localS3.enabled`                    | Deploy a single-pod SeaweedFS S3 gateway plus a bucket-creation Job | `false`               |
| `localS3.image.repository`           | SeaweedFS image repository                                          | `chrislusf/seaweedfs` |
| `localS3.image.tag`                  | SeaweedFS image tag (pinned)                                        | `4.48`                |
| `localS3.image.pullPolicy`           | SeaweedFS image pull policy                                         | `IfNotPresent`        |
| `localS3.bucketJob.image.repository` | AWS CLI image used by the bucket-creation Job                       | `amazon/aws-cli`      |
| `localS3.bucketJob.image.tag`        | AWS CLI image tag (pinned)                                          | `2.17.0`              |
| `localS3.bucketJob.image.pullPolicy` | AWS CLI image pull policy                                           | `IfNotPresent`        |
| `localS3.persistence.enabled`        | Persist SeaweedFS data on a PVC (otherwise emptyDir)                | `true`                |
| `localS3.persistence.size`           | PVC size                                                            | `5Gi`                 |
| `localS3.persistence.storageClass`   | StorageClass; empty uses `global.defaultStorageClass`               | `""`                  |
| `localS3.resources.requests.cpu`     | CPU requests for the SeaweedFS pod                                  | `100m`                |
| `localS3.resources.requests.memory`  | Memory requests for the SeaweedFS pod                               | `256Mi`               |
| `localS3.resources.limits.cpu`       | CPU limits for the SeaweedFS pod                                    | `1`                   |
| `localS3.resources.limits.memory`    | Memory limits for the SeaweedFS pod                                 | `1Gi`                 |

### OGDC Service Ingress Configuration

| Name                                                 | Description                                                                  | Value              |
| ---------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------ |
| `ingress.enabled`                                    | Enable the OGDC service ingress                                              | `false`            |
| `ingress.ingressClassName`                           | Ingress class name                                                           | `traefik`          |
| `ingress.annotations.cert-manager.io/cluster-issuer` | ClusterIssuer to use for TLS certificates                                    | `letsencrypt-prod` |
| `ingress.apiPath`                                    | Ingress path for the OGDC API service                                        | `/api`             |
| `ingress.storagePath`                                | Ingress path for signed /storage download links (served by the OGDC service) | `/storage`         |
| `ingress.tls`                                        | Ingress TLS configuration                                                    | `[]`               |
