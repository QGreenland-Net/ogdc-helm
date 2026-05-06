## v0.3.0 (2026-04-14)

- Support S3 outputs and local ingress via nginx for workflow data downloads
- Configure Argo Workflows archival with label selector and success match expression
- Add authentication secrets and `OGDC_JWT_SECRET_KEY` for the OGDC API
- Add DataOne member node environment variable
- Move environment variables into a ConfigMap and use `configMapRef`
- Update ingress to set and update hostname and pathType
- Add README.md for the helm chart using the bitnami autogen tool, with pre-commit hook
- Update uninstall script to only remove CRDs for local installs
- Add notes on managing CRDs for dev/prod clusters

## v0.2.0 (2025-11-25)

- Add skaffold configuration for local development
- Add deployment configuration for ogdc-runner service
- Add postgresql and adminer services to deployment


## v0.1.0 (2025-10-30)

- Initial changelog file
- Add bumpversion config
