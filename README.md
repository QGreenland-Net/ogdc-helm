# OGDC Helm charts for Kubernetes

[helm](https://helm.sh/) config for the OGDC, which is composed of:

* [Argo](https://argoproj.github.io/): for managing and executing OGDC workflows.
* [Minio](https://github.com/minio/minio): provides an artifact registry for argo
* `ogdc`: TODO. We expect this service will provide an API/webhook that utilizes
  the [ogdc-runner](https://github.com/QGreenland-Net/ogdc-runner/) to submit
  OGDC recipes to Argo.
  
These services are installed to the `qgnet` kubernetes namespace by default.

* A service account will be configured with the name `argo-workflow`. This
  service account has permissions to run workflows submitted by e.g.,
  `ogdc-runner`.
* No authentication mechanism is in place yet (TODO!)


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

```sh
export RELEASE_NAME=qgnet-ogdc
export NAMESPACE=qgnet
export OGDC_PV_HOST_PATH=/Users/yourname/your-pv-directory
```

2. Create the Workflow PV (update the hostPath in `helm/admin/workflow-pv.yaml` first), then apply:

```sh
envsubst < helm/admin/workflow-pv.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Create the Workflow PVC:

```sh
envsubst < helm/admin/workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

4. Create credentials for MinIO:
```sh
envsubst < helm/admin/secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

5. Perform the installation for the OGDC service

- Default (local environment, qgnet namespace):
  ```
  ./scripts/install-ogdc.sh
  ```
- Specify environment (e.g., local):
  ```
  ./scripts/install-ogdc.sh local
  ```
  Valid environments: `local`, `dev`, `prod`. Namespace is optional (defaults to `qgnet`).

* Verify Argo install.

First, port-forward the Argo Workflows server:

```
./scripts/forward-ports.sh
```

Then, visit the Argo dashboard: <http://localhost:2746>.


### Dev/Production setup

For deploying the stack on the DataONE dev cluster:

1. Create the CephFS-backed PVCs (update the config in `cephfs-{release}-{function}-pvc.yaml` if needed), then apply:

```sh
export RELEASE_NAME=${RELEASE_NAME:-qgnet-ogdc}
export NAMESPACE=${NAMESPACE:-qgnet}

envsubst < helm/admin/cephfs-releasename-minio-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
envsubst < helm/admin/cephfs-releasename-workflow-pvc.yaml | kubectl apply -n "$NAMESPACE" -f -
```

2. Create credentials for MinIO:
```sh
envsubst < helm/admin/secrets.yaml | kubectl apply -n "$NAMESPACE" -f -
```

3. Perform the installation for the OGDC service

- Specify environment (e.g., dev) and/or namespace:
  ```
  ./scripts/install-ogdc.sh dev my-namespace
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
