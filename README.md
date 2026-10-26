# OGDC Helm charts for Kubernetes

[helm](https://helm.sh/) config for the OGDC, which is composed of:

* [Argo](https://argoproj.github.io/): for managing and executing OGDC workflows.
* S3 object storage: an external S3-compatible store (configured via
  `global.s3`) for argo artifacts and workflow outputs. For local development an
  in-cluster [SeaweedFS](https://github.com/seaweedfs/seaweedfs) can be enabled.
* [ogdc-runner](https://github.com/QGreenland-Net/ogdc-runner/) service API,
  which provides an API for users to submit OGDC recipes to the cluster for
  execution. The API translates OGDC recipes into argo workflows that are
  executed by Argo.
* [postgresql](https://www.postgresql.org): provides database backend for the
  `ogdc-runner` service API.
* [adminer](https://www.adminer.org/en/): UI for interacting with postgresql
  database.
  
These services are installed to the `qgnet` kubernetes namespace by default.

* A service account will be configured with the name `argo-workflow`. This
  service account has permissions to run workflows submitted by e.g.,
  `ogdc-runner`.
* No authentication mechanism is in place yet (TODO!)


## Prerequisites

### Argo Workflows CRDs

To install OGDC-Helm, you need to have Argo Workflows Custom Resource Definitions (CRDs) installed on your cluster. Installing CRDs requires **cluster-level permissions**.

**For dev/prod environments**, refer to the [DataONE k8s-cluster authorization documentation](https://github.com/DataONEorg/k8s-cluster/blob/main/authorization/custom-rolebindings/custom-rolebindings.md#qgnet-argo-workflows) for detailed instructions on installing the CRDs with proper permissions.

**For local environments** (Rancher Desktop), the CRDs are typically managed as part of the Helm chart installation process.


### Cloud Native PostgreSQL Operator

The [Cloud Native PostgreSQL](https://cloudnative-pg.io/) operator must be
installed on the cluster.

**For dev/prod environments**, the operator should already be installed on ADC k8s clusters.

**For local environments** (Rancher Desktop), manually install the operator:

```
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg \
  --namespace cnpg-system \
  --create-namespace \
  cnpg/cloudnative-pg
```

### Traefik Ingress Controller

For local Rancher Desktop deployments, OGDC uses Traefik for ingress.

Rancher Desktop's Kubernetes distribution normally includes Traefik in the
`kube-system` namespace. Confirm it is available before starting the local
stack:

```sh
kubectl get service traefik -n kube-system
kubectl get crd middlewares.traefik.io
```

The local Skaffold configuration port-forwards Traefik to:

```text
http://localhost:7777
https://localhost:7443
```

The OGDC API is exposed at `https://localhost:7443/api`, and signed download links are
exposed at `https://localhost:7443/storage`.

## Getting started


### Local dev cluster via Rancher desktop

This assumes [rancher desktop](https://rancherdesktop.io/) is
installed. QGreenland-net specific information on setting up Rancher desktop can
be found here:
<https://qgreenland-net.github.io/how-tos/#how-to-configure-rancher-desktop>

> [!TIP]
> For detailed information about configuring the installation, refer to the [helm/README.md](helm/README.md).

* Create a namespace called `qgnet` (or your preferred namespace):

```
kubectl create namespace qgnet
```

* Install the stack with helm:

> [!NOTE]
> By default, the install script uses the `local` environment and the `qgnet` namespace.
> You can optionally specify the environment (`local`, `dev`, or `prod`) and namespace.
> 
> In `local`, a PV will be created that's attached to a local directory called
> `ogdc-local-hostmount` where this repository is checked out. To override the
> location of the local directory used for persistent storage, set the
> `OGDC_PV_HOST_PATH` envvar to another location that's accessible by Rancher
> Desktop (in the user's home directory).

**Usage:**


1. Set common variables:

> [!NOTE]
> `RELEASE_NAME` defaults to `qgnet-ogdc` and `NAMESPACE` defaults to `qgnet`
> throughout the scripts and example values files. Override either envvar to
> deploy under a different name/namespace — the example values files use
> `${RELEASE_NAME}` / `${NAMESPACE}` placeholders that are substituted at
> install time via `envsubst`. The CNPG DB release name is always
> `${RELEASE_NAME}-db`, and the DB/S3/API secrets are named
> `${RELEASE_NAME}-db-postgres-secrets`, `${RELEASE_NAME}-s3-credentials`, and
> `${RELEASE_NAME}-api-secrets` respectively.
>
> For local development with `skaffold`, the defaults `qgnet-ogdc` / `qgnet`
> are expected (see `skaffold.yaml`).

```sh
export RELEASE_NAME=qgnet-ogdc   # default
export NAMESPACE=qgnet           # default
export OGDC_PV_HOST_PATH=/Users/yourname/your-pv-directory
```

2. Create the Workflow PV:

```sh
envsubst '${RELEASE_NAME} ${NAMESPACE} ${OGDC_PV_HOST_PATH}' \
  < helm/admin/workflow-pv.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Create the Workflow PVC:

```sh
envsubst '${RELEASE_NAME} ${NAMESPACE}' \
  < helm/admin/workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

4. Create credentials for S3 (`${RELEASE_NAME}-s3-credentials`), the API and postgresql:

   Every `your-value-here` in `helm/admin/secrets.yaml` must be replaced before the file is applied. `storageLinkSigningKey` must be at least 32 random characters (`openssl rand -hex 32`). Otherwise ogdc-service treats the key as not configured and answers `/storage` links with 503. Applying the file unchanged creates placeholder credentials.

   For local clusters only, either skip `secrets.yaml` and let `./scripts/install-ogdc.sh local` create `${RELEASE_NAME}-s3-credentials` with random values (it does this only when the Secret does not already exist), or create the S3 Secret with random values in one step:
```sh
envsubst '${RELEASE_NAME}' < helm/admin/secrets.yaml \
  | awk '/your-value-here/ { c="openssl rand -hex 16"; c | getline r; close(c); sub(/your-value-here/, r) } { print }' \
  | kubectl apply -n "$NAMESPACE" -f -
```

   For dev and prod, replace each `your-value-here` in `helm/admin/secrets.yaml` by hand before running the commands below. For local, do not run the first `envsubst` line below if you used the one-liner above, because it would overwrite the random values with placeholders.
```sh
# dev/prod: replace placeholders first. local: skip the secrets.yaml line if you used the one-liner above.
envsubst '${RELEASE_NAME}' < helm/admin/secrets.yaml          | kubectl apply -n "$NAMESPACE" -f -
envsubst '${RELEASE_NAME}' < helm/admin/postgres-secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

5. Create OGDC database.

> [!NOTE] this assumes the CNPG operator is installed on the cluster. See
> [Prerequisites](#Prerequisites) above.


Create a db cluster for OGDC with release-name `${RELEASE_NAME}-db` (e.g.
`qgnet-ogdc-db` for the local defaults) using the DataONE cnpg chart:

```sh
envsubst '${RELEASE_NAME}' < helm/examples/db-local-cluster-values.yaml | \
  helm install "${RELEASE_NAME}-db" oci://ghcr.io/dataoneorg/charts/cnpg \
    --version 1.1.2 --namespace "$NAMESPACE" -f -
```

6. Create the local TLS secret used by the Traefik ingress.

The local ingress uses HTTPS on `https://localhost:7443`, so Traefik needs a
Kubernetes TLS secret for `localhost`. The helper script creates a self-signed
certificate and stores it as `${RELEASE_NAME}-local-tls-cert` in `${NAMESPACE}`.
This matches `helm/examples/values-local-cluster-ogdc-example.yaml`.

```sh
./scripts/create-local-tls-cert.sh
```

#### Using skaffold

[Skaffold](https://skaffold.dev) can be used to install the OGDC and watch for
changes in a local environment. Use the `run-local.sh` script to use skaffold:


> [!NOTE]
> MacOS users may find that `brew` installs an old version of skaffold that may
> not work with this project's configuration. We recommend installing skaffold
> from source for the latest version.

> [!IMPORTANT]
> If you run `run-local.sh` directly, you must first add the required Helm
> repositories:
> ```sh 
> helm repo add argo https://argoproj.github.io/argo-helm
> helm repo update
> ```

```
./scripts/run-local.sh
```

This will build and deploy the stack to rancher desktop and watch the
ogdc-runner source for changes. If changes are made, the stack will be rebuilt
and redeployed to rancher desktop.

### S3 object storage

OGDC reads and writes workflow artifacts and outputs in an S3-compatible bucket
configured through `global.s3` (endpoint, region, bucket, forcePathStyle) and
the `${RELEASE_NAME}-s3-credentials` Secret (keys `accessKeyId`,
`secretAccessKey`, `storageLinkSigningKey`, see `helm/admin/secrets.yaml`).

* **local**: `localS3.enabled: true` (set by the local example values) deploys a
  single-pod SeaweedFS and creates the bucket. `./scripts/install-ogdc.sh local`
  creates the Secret with random values if it does not exist yet. SeaweedFS was
  chosen over MinIO because it is Apache-2.0 licensed, actively maintained, and
  MinIO's community edition is in maintenance mode.
* **dev / prod**: an external S3 at `https://s3.anacapa.nceas.ucsb.edu` with
  buckets `ogdc-dev` / `ogdc-prod` (TEMP/TBD: not provisioned yet). The chart
  does not create these buckets: the object store admin creates the bucket and
  issues keys with read, write, list and delete access to it.
* Public `/storage/<key>?expires=..&signature=..` links are served by
  ogdc-service itself, which streams the object from S3, so the bucket stays
  private and does not need to be reachable from outside the cluster.

Configuration details, the `/storage` link design, and the upgrade steps from
MinIO (chart < 0.5.0; data in the old MinIO PVC is not migrated automatically)
are in [helm/README.md](helm/README.md#s3-object-storage).

### Dev/Production setup

**Prerequisites:** The OGDC service depends on Argo Workflows, which requires Argo CRDs to be installed. For dev/prod environments, we manage the CRDs outside of the Helm charts. 

**Installing Argo CRDs:**

Choose one of the following options based on your cluster requirements:

- **Full CRDs**:
  ```bash
  kubectl apply --server-side --force-conflicts -k "https://github.com/argoproj/argo-workflows/manifests/base/crds/full?ref=<appVersion>"
  
  # Example with version v4.0.2:
  kubectl apply --server-side --force-conflicts -k "https://github.com/argoproj/argo-workflows/manifests/base/crds/full?ref=v4.0.2"
  ```

- **Minimal CRDs**:
  ```bash
  kubectl apply -k "https://github.com/argoproj/argo-workflows/manifests/base/crds/minimal?ref=<appVersion>"
  ```

For more information, see the [Argo Workflows CRD installation guide](https://github.com/argoproj/argo-helm/tree/main/charts/argo-workflows#using-argo-cd).

**Deploying the stack on the DataONE dev/prod cluster:**

> [!TIP]
> For detailed information about configuring the installation, refer to the [helm/README.md](helm/README.md).

1. Create the CephFS-backed PVCs (update the config in `cephfs-{release}-{function}-pvc.yaml` if needed), then apply:

```sh
export RELEASE_NAME=${RELEASE_NAME:-qgnet-ogdc}
export NAMESPACE=${NAMESPACE:-qgnet}

envsubst '${RELEASE_NAME} ${NAMESPACE}' < helm/admin/cephfs-releasename-workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

2. Create credentials for S3 (`${RELEASE_NAME}-s3-credentials`), the API and postgresql.:

> [!WARNING]
> Each of these secrets files need to be MANUALLY EDITED to reflect the desired secret values in dev/prod. If this is not done, public defaults will be used.

```sh
envsubst '${RELEASE_NAME}' < helm/admin/secrets.yaml          | kubectl apply -n "$NAMESPACE" -f -
envsubst '${RELEASE_NAME}' < helm/admin/postgres-secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Create a db cluster for OGDC with release-name `${RELEASE_NAME}-db` using
   the DataONE cnpg chart:

```sh
envsubst '${RELEASE_NAME}' < helm/examples/db-cluster-values.yaml | \
  helm install "${RELEASE_NAME}-db" oci://ghcr.io/dataoneorg/charts/cnpg \
    --version 1.1.2 --namespace "$NAMESPACE" -f -
```

4. Perform the installation for the OGDC service

- Specify environment (e.g., dev/prod):
  ```
  ./scripts/install-ogdc.sh dev
  ```

### Uninstalling ogdc

To uninstall the ogdc from the kubernetes cluster, use the
`./scripts/uninstall-ogdc.sh` script.

**Usage:**
```bash
# Specify environment (local, dev, or prod). Defaults to local.
./scripts/uninstall-ogdc.sh [local|dev|prod]
```

**Behavior:**
- In **local** environments: Automatically removes Argo CRDs after uninstalling the Helm release
- In **dev/prod** environments: Only uninstalls the Helm release; CRDs are preserved as they are managed separately

### Cleaning up Argo CRDs

The `./scripts/cleanup-argo-crds.sh` script is used to remove Argo Custom Resource Definitions (CRDs) from your cluster. 

**Main usage:** This script is primarily intended for **dev/prod environments** when upgrading Argo CRDs that are managed outside of the Helm install process. It removes existing Argo CRDs and workflow resources before installing newer versions.

> [!NOTE]
> This script is **not necessary for local installations**, where Argo CRDs are managed as part of the standard Helm chart installation and upgrade process.

**Usage:**
```sh
./scripts/cleanup-argo-crds.sh
```

This will:
- Remove all workflow resources across all namespaces
- Delete all Argo CRDs
- Force remove any stuck CRDs with finalizers

### Installing from GitHub Container Registry (GHCR)

The OGDC Helm chart is published to GHCR and can be installed directly without cloning this repository.

> [!NOTE]
> This method requires that prerequisite resources (PVs, PVCs, secrets) are already created. For local development, use the [Local dev cluster via Rancher desktop](#local-dev-cluster-via-rancher-desktop) method above.

**Install the latest development version:**

```bash
# Create namespace
kubectl create namespace qgnet

# Install chart
helm upgrade --install ogdc \
  oci://ghcr.io/qgreenland-net/charts/ogdc \
  --version latest \
  -n qgnet
```

**Install a specific release version:**

```bash
helm upgrade --install ogdc \
  oci://ghcr.io/qgreenland-net/charts/ogdc \
  --version 0.1.0 \
  -n qgnet
```

**With custom values file:**

```bash
envsubst < values-dev-cluster-ogdc.yaml | helm upgrade --install ${{ env.CHART_NAME }} \
  oci://${{ env.REGISTRY }}/${{ github.repository_owner }}/charts/${{ env.CHART_NAME }} \
  --version ${VERSION} \
  -f - \
  -n qgnet
```

**Available versions:**
- `latest` - Latest development build from main branch
- `0.1.0`, `0.2.0`, etc. - Specific release versions (created from git tags)


## Versioning and Releases

Version management and the creation of release tags are automated using **bump-my-version**.

* **Documentation:** [https://callowayproject.github.io/bump-my-version/](https://callowayproject.github.io/bump-my-version/)

Contributors should **not** manually update version numbers (e.g., in `helm/Chart.yaml`). All official version changes should be performed through this tool.

### How to Create a New Release

To perform a version bump and create a new release:

1.  Ensure all changes for the release are outlined in the CHANGELOG with the `## NEXT_VERSION` header. 
2.  Use the `bump-my-version` command followed by the part you wish to increment (`patch` or `minor`):
    * To bump the **patch** version (e.g., 0.1.0 → 0.1.1):
        ```bash
        bump-my-version patch
        ```
    * To bump the **minor** version (e.g., 0.1.0 → 0.2.0):
        ```bash
        bump-my-version minor
        ```
3.  The command will:
    * Update the version in all configured files (e.g., `helm/Chart.yaml`).

At this point bump-my-version has done it's job so you can create a tag and commit message for the new version.
-  Push the tag and commit that you created. 
-  This new tag will typically trigger a CI/CD workflow (e.g., GitHub Actions) to publish the new chart version to the GitHub Container Registry (GHCR).


## Troubleshooting

If something is not working as expected, start by listing services in the
`qgnet` namespace and confirming that `seaweedfs` (local only), `argo-workflows-server` and
`ogdc` services are running (prefixed with the namespace):

```
$ kubectl get svc -n qgnet
NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
qgnet-ogdc-seaweedfs                    ClusterIP   10.43.76.177    <none>        8333/TCP            14m
qgnet-ogdc-argo-workflows-server        ClusterIP   10.43.231.175   <none>        2746/TCP            14m
```

### Argo reports that its artifact repository is not configured

If you have submitted a workflow and Argo's interface reports that there is a
problem due to the artifact repository not being configured, check the S3
settings: `global.s3.endpoint` and `global.s3.bucket` must be reachable, the
`${RELEASE_NAME}-s3-credentials` Secret must exist, and the bucket must exist.
Locally (`localS3.enabled`), the SeaweedFS pod may still be starting or the
`${RELEASE_NAME}-seaweedfs-bucket` Job (which creates the bucket) may not have
finished yet; check both with `kubectl get pods,jobs -n qgnet` and try again
after a few minutes.


### Local Docker image is not found by Argo

If the Argo dashboard reports that a docker image that has been built locally
(e.g., for testing purposes) is not present with a pull policy of "Never" (in
dev), it may be because of a conflict between `rancher-desktop` and
`minikube`. Make sure your k8s config is setup to use the `rancher-desktop`
context when doing local development on the ogdc.


## Contributing

### Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) to maintain code quality and automatically generate documentation.

After cloning the repository, install the pre-commit hooks:

```bash
pre-commit install
```

This will ensure that:
- Code is properly formatted
- Helm chart documentation is automatically generated

### Auto-generated Files

> [!IMPORTANT]
> The `helm/README.md` file is **auto-generated** from the Helm chart's `values.yaml` using the [Bitnami readme-generator-for-helm](https://github.com/bitnami/readme-generator-for-helm). **Do not edit this file manually** as your changes will be overwritten.

To update the Helm chart documentation:
1. Edit the parameter descriptions in `helm/values.yaml` using the `## @param` annotation format
2. Run `pre-commit run --all-files` or commit your changes to automatically regenerate `helm/README.md`
