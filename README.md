# OGDC-argo

Setup/config for OGDC's [Argo](https://argoproj.github.io/) installation using
[helm](https://helm.sh/).


* Argo will be installed to a namespace called `argo-helm`.
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

* Create a namespace called `argo-helm` (TODO: should this be `qgnet`, or will we use that namespace separately?):

```
kubectl create namespace argo-helm
```

* Create a PV/PVC. (TODO: Paths may need to be updated in
  `helm/admin/workfow-pv.yaml`. Can we standardize this/allow override via an
  envvar or local dev yaml file?).:

```
kubectl apply -f helm/admin/workfow-pv.yaml -n argo-helm
```

* Insatall argo with helm:

```
./scripts/install-argo.sh
```

* Verify argo install.

First, Port-forward the argo workflows server

```
./scripts/forward-ports.sh
```

Then, visit the argo dashboard: <http://localhost:2746>.


### Production setup

TODO: instructions for prod on ADC infrastructure.

### Uninstalling ogdc-argo

To uninstall the argo from the kubernetes cluster, use the
`./scripts/uninstal-argo.sh` script.


## Troubleshooting

List services in the `argo-helm` namespace:

```
$ kubectl get svc -n argo-helm
NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
qgnet-argo-minio                   ClusterIP   10.43.76.177    <none>        9000/TCP,9001/TCP   14m
qgnet-argo-dataone-gse             ClusterIP   10.43.86.129    <none>        80/TCP              14m
qgnet-argo-argo-workflows-server   ClusterIP   10.43.231.175   <none>        2746/TCP            14m
```


## TODOs

* Is the `values.yaml` at the root of the project necessary? Can it be moved into the `helm/` directory?
* Resolve TODOs above (e.g., how to override the PV location on local disk)
