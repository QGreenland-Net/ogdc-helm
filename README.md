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
> By default, the install script uses the `dev` environment and the `qgnet` namespace.
> You can optionally specify the environment (`dev`, `stage`, or `prod`) and namespace.
> 
> In `dev`, a PV will be created that's attached to a local directory called
> `ogdc-local-hostmount` where this repository is checked out. To override the
> location of the local directory used for persistent storage, set the
> `OGDC_PV_HOST_PATH` envvar to another location that's accessible by Rancher
> Desktop (in the user's home directory).

**Usage:**

- Default (dev environment, qgnet namespace):
  ```
  ./scripts/install-ogdc.sh
  ```
- Specify environment (e.g., stage) and/or namespace:
  ```
  ./scripts/install-ogdc.sh stage my-namespace
  ```
  Valid environments: `dev`, `stage`, `prod`. Namespace is optional (defaults to `qgnet`).

* Verify argo install.

First, Port-forward the argo workflows server

```
./scripts/forward-ports.sh
```

Then, visit the argo dashboard: <http://localhost:2746>.


### Production setup

TODO: instructions for prod on ADC infrastructure.

### Uninstalling ogdc

To uninstall the ogdc from the kubernetes cluster, use the
`./scripts/uninstal-ogdc.sh` script.


## Troubleshooting

If something is not working as expect, start by listing services in the
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


### local Docker image is not found by Argo

If the Argo dashboard reports that a docker image that has been built locally
(e.g., for testing purposes) is not present with a pull policy of "Never" (in
dev), it may be because of a conflict between `rancher-desktop` and
`minikube`. Make sure your k8s config is setup to use the `rancher-desktop`
context when doing local development on the ogdc.
