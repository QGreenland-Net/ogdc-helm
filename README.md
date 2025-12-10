# OGDC Helm charts for Kubernetes

[helm](https://helm.sh/) config for the OGDC, which is composed of:

* [Argo](https://argoproj.github.io/): for managing and executing OGDC workflows.
* [Minio](https://github.com/minio/minio): provides an artifact registry for
  argo with automatic garbage collection.
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

## Getting started


### Local dev cluster via Rancher desktop

This assumes [rancher desktop](https://rancherdesktop.io/) is
installed. QGreenland-net specific information on setting up Rancher desktop can
be found here:
<https://qgreenland-net.github.io/how-tos/#how-to-configure-rancher-desktop>

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
> for local development, the `RELEASE_NAME` is always expected to be
> `qgnet-ogdc` and the `NAMESPACE` is expected to `qgnet`. These values are
> expected by `skaffold` (see `skaffold.yaml`).

```sh
export RELEASE_NAME=qgnet-ogdc
export NAMESPACE=qgnet
export OGDC_PV_HOST_PATH=/Users/yourname/your-pv-directory
```

2. Create the Workflow and postgres PVs:

```sh
envsubst < helm/admin/workflow-pv.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Create the Workflow and postgres PVCs:

```sh
envsubst < helm/admin/workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

4. Create credentials for MinIO and postgresql:
```sh
envsubst < helm/admin/secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
envsubst < helm/admin/postgres-secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

5. Create OGDC database.

> [!NOTE] this assumes the CNPG operator is installed on the cluster. See
> [Prerequisites](#Prerequisites) above.


Create a db cluster for OGDC with release-name `ogdc-db` using the DataONE cnpg
chart:

```sh
helm install ogdc-db oci://ghcr.io/dataoneorg/charts/cnpg -f helm/admin/db-local-cluster-values.yaml  --version 1.0.0 --namespace qgnet
```

#### Using skaffold

[Skaffold](https://skaffold.dev) can be used to install the OGDC and watch for
changes in a local environment. Use the `run-local.sh` script to use skaffold:


> [!NOTE]
> MacOS users may find that `brew` installs an old version of skaffold that may
> not work with this project's configuration. We recommend installing skaffold
> from source for the latest version.

```
./scripts/run-local.sh
```

This will build and deploy the stack to rancher desktop and watch the
ogdc-runner source for changes. If changes are made, the stack will be rebuilt
and redeployed to rancher desktop.

### Dev/Production setup

For deploying the stack on the DataONE dev/prod cluster:

1. Create the CephFS-backed PVCs (update the config in `cephfs-{release}-{function}-pvc.yaml` if needed), then apply:

```sh
export RELEASE_NAME=${RELEASE_NAME:-qgnet-ogdc}
export NAMESPACE=${NAMESPACE:-qgnet}

envsubst < helm/admin/cephfs-releasename-minio-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
envsubst < helm/admin/cephfs-releasename-workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
envsubst < helm/admin/cephfs-releasename-postgres-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

2. Create credentials for MinIO and postgresql.:

> [!WARNING]
> Each of these secrets files need to be MANUALLY EDITED to reflect the desired secret values in dev/prod. If this is not done, public deafults will be used.

```sh
envsubst < helm/admin/secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
envsubst < helm/admin/postgres-secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Create a db cluster for OGDC with release-name `ogdc-db` using the DataONE
   cnpg chart:

```sh
helm install ogdc-db oci://ghcr.io/dataoneorg/charts/cnpg -f helm/admin/db-cluster-values.yaml  --version 1.0.0 --namespace qgnet
```

4. Perform the installation for the OGDC service

- Specify environment (e.g., dev/prod):
  ```
  ./scripts/install-ogdc.sh dev
  ```

### Uninstalling ogdc

To uninstall the ogdc from the kubernetes cluster, use the
`./scripts/uninstall-ogdc.sh` script.

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
`qgnet` namespace and confirming that `minio`, `argo-workflows-server` and
`ogdc` services are running (prefixed with the namespace):

```
$ kubectl get svc -n qgnet
NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
qgnet-argo-minio                   ClusterIP   10.43.76.177    <none>        9000/TCP,9001/TCP   14m
qgnet-argo-argo-workflows-server   ClusterIP   10.43.231.175   <none>        2746/TCP            14m
```

### Argo reports that its artifact repository is not configured

If you have submitted a workflow and Argo's interface reports that there is a
problem due to the artifact repository not being configured, it might just be
that the `minio` service is not yet fully operational. Try again after a few
minutes!

> [!TODO]
> Is there a way to tell helm to setup minio before the `argo-workflows-server`
> so we do not run into this issue in the future?


### Local Docker image is not found by Argo

If the Argo dashboard reports that a docker image that has been built locally
(e.g., for testing purposes) is not present with a pull policy of "Never" (in
dev), it may be because of a conflict between `rancher-desktop` and
`minikube`. Make sure your k8s config is setup to use the `rancher-desktop`
context when doing local development on the ogdc.
