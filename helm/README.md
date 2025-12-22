# OGDC Helm Chart

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: develop](https://img.shields.io/badge/AppVersion-develop-informational?style=flat-square)

Helm chart for Kubernetes Deployment of OGDC
(https://github.com/QGreenland-Net/ogdc-helm)

**Homepage:** <https://github.com/QGreenland-Net/ogdc-helm>

## Source Code

* <https://github.com/QGreenland-Net/ogdc-helm>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://argoproj.github.io/argo-helm | argo-workflows | 0.45.26 |
| https://charts.min.io/ | minio | 5.4.0 |

## Overview

OGDC (Open Geospatial Data Cloud) is a Helm chart for deploying a complete geospatial data processing pipeline on Kubernetes. This chart includes:

- **Argo Workflows**: For orchestrating and managing data processing workflows
- **MinIO**: S3-compatible object storage for artifacts and data
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

| Name                         | Description                                             | Value               |
| ---------------------------- | ------------------------------------------------------- | ------------------- |
| `global.passwordsSecret`     | The name of the Secret containing application passwords | `myrelease-secrets` |
| `global.defaultStorageClass` | Global default StorageClass for Persistent Volume(s)    | `local-path`        |

### Argo Workflows Configuration

| Name                                                                  | Description                                                                                | Value                            |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | -------------------------------- |
| `argo-workflows.singleNamespace`                                      | Restrict Argo to operate only in a single namespace                                        | `false`                          |
| `argo-workflows.crds.install`                                         | Install and upgrade CRDs                                                                   | `true`                           |
| `argo-workflows.crds.keep`                                            | Keep CRDs on chart uninstall                                                               | `false`                          |
| `argo-workflows.crds.annotations`                                     | Annotations to be added to all CRDs                                                        | `{}`                             |
| `argo-workflows.createAggregateRoles`                                 | Create ClusterRoles that extend existing ClusterRoles to interact with Argo Workflows CRDs | `true`                           |
| `argo-workflows.workflow.serviceAccount.create`                       | Specifies whether a service account should be created                                      | `true`                           |
| `argo-workflows.workflow.serviceAccount.name`                         | Service account which is used to run workflows                                             | `argo-workflow`                  |
| `argo-workflows.workflow.serviceAccount.automountServiceAccountToken` | Automount service account token for the workflow pods                                      | `true`                           |
| `argo-workflows.workflow.rbac.create`                                 | Adds Role and RoleBinding for the above specified service account                          | `true`                           |
| `argo-workflows.controller.resources.requests.memory`                 | Memory requests for the workflow controller                                                | `2Gi`                            |
| `argo-workflows.controller.resources.requests.cpu`                    | CPU requests for the workflow controller                                                   | `500m`                           |
| `argo-workflows.controller.resources.limits.memory`                   | Memory limits for the workflow controller                                                  | `4Gi`                            |
| `argo-workflows.controller.resources.limits.cpu`                      | CPU limits for the workflow controller                                                     | `1000m`                          |
| `argo-workflows.controller.workflowNamespaces`                        | Specify all namespaces where this workflow controller instance will manage workflows       | `["qgnet"]`                      |
| `argo-workflows.controller.workflowDefaults.spec.podGC.strategy`      | Automatically cleanup pods on successful workflow completion                               | `OnWorkflowSuccess`              |
| `argo-workflows.controller.metricsConfig.enabled`                     | Enables prometheus metrics server                                                          | `false`                          |
| `argo-workflows.server.enabled`                                       | Deploy the Argo Server                                                                     | `true`                           |
| `argo-workflows.server.resources.requests.memory`                     | Memory requests for the workflow server                                                    | `1Gi`                            |
| `argo-workflows.server.resources.requests.cpu`                        | CPU requests for the workflow server                                                       | `200m`                           |
| `argo-workflows.server.resources.limits.memory`                       | Memory limits for the workflow server                                                      | `2Gi`                            |
| `argo-workflows.server.resources.limits.cpu`                          | CPU limits for the workflow server                                                         | `500m`                           |
| `argo-workflows.server.authModes`                                     | A list of supported authentication modes                                                   | `["server"]`                     |
| `argo-workflows.server.ingress.enabled`                               | Enable an ingress resource for the Argo server                                             | `false`                          |
| `argo-workflows.server.ingress.ingressClassName`                      | Ingress class name                                                                         | `nginx`                          |
| `argo-workflows.server.ingress.annotations`                           | Additional ingress annotations                                                             | `{}`                             |
| `argo-workflows.server.ingress.hosts`                                 | Ingress hosts                                                                              | `["api.test.dataone.org"]`       |
| `argo-workflows.server.ingress.paths`                                 | Ingress endpoint paths                                                                     | `["/ogdc(/|$)(.*)"]`             |
| `argo-workflows.server.ingress.pathType`                              | Path type                                                                                  | `ImplementationSpecific`         |
| `argo-workflows.server.ingress.servicePort`                           | Ingress service backend port                                                               | `2746`                           |
| `argo-workflows.server.ingress.tls`                                   | Ingress TLS configuration                                                                  | `[]`                             |
| `argo-workflows.executor.resources.requests.memory`                   | Memory requests for the workflow executor                                                  | `1Gi`                            |
| `argo-workflows.executor.resources.requests.cpu`                      | CPU requests for the workflow executor                                                     | `200m`                           |
| `argo-workflows.executor.resources.limits.memory`                     | Memory limits for the workflow executor                                                    | `4Gi`                            |
| `argo-workflows.executor.resources.limits.cpu`                        | CPU limits for the workflow executor                                                       | `1000m`                          |
| `argo-workflows.artifactRepository.archiveLogs`                       | Archive the main container logs as an artifact                                             | `false`                          |
| `argo-workflows.artifactRepository.s3.bucket`                         | S3 bucket name                                                                             | `argo-workflows`                 |
| `argo-workflows.artifactRepository.s3.endpoint`                       | S3 endpoint                                                                                | `{{ .Release.Name }}-minio:9000` |
| `argo-workflows.artifactRepository.s3.accessKeySecret.name`           | Secret name containing S3 access key                                                       | `myrelease-secrets`              |
| `argo-workflows.artifactRepository.s3.accessKeySecret.key`            | Secret key for S3 access key                                                               | `rootUser`                       |
| `argo-workflows.artifactRepository.s3.secretKeySecret.name`           | Secret name containing S3 secret key                                                       | `myrelease-secrets`              |
| `argo-workflows.artifactRepository.s3.secretKeySecret.key`            | Secret key for S3 secret key                                                               | `rootPassword`                   |
| `argo-workflows.artifactRepository.s3.insecure`                       | Disable TLS for S3 connection                                                              | `true`                           |

### MinIO Configuration

| Name                              | Description                                       | Value               |
| --------------------------------- | ------------------------------------------------- | ------------------- |
| `minio.mode`                      | MinIO mode (standalone or distributed)            | `standalone`        |
| `minio.replicas`                  | Number of MinIO containers running                | `1`                 |
| `minio.buckets`                   | List of buckets to be created after minio install | `[]`                |
| `minio.persistence.enabled`       | Enable persistence using Persistent Volume Claims | `true`              |
| `minio.existingSecret`            | Use existing Secret that store MinIO credentials  | `myrelease-secrets` |
| `minio.resources.requests.memory` | Memory requests for minio                         | `1Gi`               |
| `minio.resources.requests.cpu`    | CPU requests for minio                            | `200m`              |
| `minio.resources.limits.memory`   | Memory limits for minio                           | `2Gi`               |
| `minio.resources.limits.cpu`      | CPU limits for minio                              | `500m`              |

### OGDC Configuration

| Name                   | Description                     | Value                                                                                         |
| ---------------------- | ------------------------------- | --------------------------------------------------------------------------------------------- |
| `image.repository`     | OGDC container image repository | `ogdc-runner`                                                                                 |
| `image.tag`            | OGDC container image tag        | `latest`                                                                                      |
| `ogdc_service_command` | Command to run the OGDC service | `. ./.venv/bin/activate && fastapi run --port 8000 --host 0.0.0.0 src/ogdc_runner/service.py` |
