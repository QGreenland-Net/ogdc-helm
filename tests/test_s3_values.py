"""Render-contract tests for the S3 object storage values (`global.s3`, `localS3`).

They run `helm template` against the example overlays and check the rendered
manifests with plain string matching, so they need only `helm` and the chart
dependencies (`helm dependency build helm/`), not PyYAML or a cluster.
"""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHART = ROOT / "helm"
EXAMPLES = CHART / "examples"
RELEASE = "s3test"
NAMESPACE = "s3test-ns"
ARGO_CONFIGMAP = "charts/argo-workflows/templates/controller/workflow-controller-config-map.yaml"


def _overlay(env: str) -> str:
    """Return the example overlay for `env` with the envsubst placeholders filled in."""
    text = (EXAMPLES / f"values-{env}-cluster-ogdc-example.yaml").read_text()
    return text.replace("${RELEASE_NAME}", RELEASE).replace("${NAMESPACE}", NAMESPACE)


def _render(*, env: str | None = None, extra: list[str] | None = None, show: str | None = None):
    """Run `helm template` and return the completed process (never raises on failure)."""
    args = ["helm", "template", RELEASE, str(CHART), "--namespace", NAMESPACE]
    with tempfile.NamedTemporaryFile("w", suffix=".yaml") as values:
        if env is not None:
            values.write(_overlay(env))
            values.flush()
            args += ["-f", values.name]
        args += extra or []
        if show is not None:
            args += ["--show-only", show]
        return subprocess.run(args, capture_output=True, text=True, check=False)


def _ok(**kwargs) -> str:
    """Render and return stdout, failing the calling test with helm's stderr."""
    result = _render(**kwargs)
    if result.returncode != 0:
        raise AssertionError(result.stderr)
    return result.stdout


class RenderGuardsTest(unittest.TestCase):
    def test_base_values_refuse_to_render_without_endpoint(self):
        result = _render()
        self.assertNotEqual(0, result.returncode)
        self.assertIn("global.s3.endpoint is required", result.stderr)

    def test_bucket_is_required(self):
        result = _render(extra=["--set", "global.s3.endpoint=https://s3.example.test"])
        self.assertNotEqual(0, result.returncode)
        self.assertIn("global.s3.bucket is required", result.stderr)

    def test_removed_minio_values_fail_with_migration_message(self):
        for flag in ("minio.mode=standalone", "ogdc_s3_endpoint=http://old-minio:9000"):
            with self.subTest(flag=flag):
                result = _render(env="dev", extra=["--set", flag])
                self.assertNotEqual(0, result.returncode)
                self.assertIn("removed in chart 0.5.0", result.stderr)

    def test_example_overlays_render(self):
        for env in ("local", "dev", "prod"):
            with self.subTest(env=env):
                self.assertNotIn("minio", _ok(env=env).lower())


class ServiceS3ConfigTest(unittest.TestCase):
    def test_configmap_carries_s3_settings(self):
        configmap = _ok(env="dev", show="templates/configmap.yaml")
        for line in (
            'S3_ENDPOINT_URL: "https://s3.anacapa.nceas.ucsb.edu"',
            'INTERNAL_S3_ENDPOINT_URL: "https://s3.anacapa.nceas.ucsb.edu"',
            'S3_BUCKET: "ogdc-dev"',
            'S3_REGION: "default"',
            'S3_ADDRESSING_STYLE: "path"',
            'PUBLIC_S3_ENDPOINT_URL: "https://ogdc.test.dataone.org/storage"',
        ):
            self.assertIn(line, configmap)

    def test_virtual_addressing_when_path_style_is_off(self):
        configmap = _ok(
            env="dev",
            extra=["--set", "global.s3.forcePathStyle=false"],
            show="templates/configmap.yaml",
        )
        self.assertIn('S3_ADDRESSING_STYLE: "virtual"', configmap)

    def test_service_reads_all_three_keys_from_credentials_secret(self):
        deployment = _ok(env="dev", show="templates/deployment.yaml")
        self.assertEqual(3, deployment.count(f'name: "{RELEASE}-s3-credentials"'))
        for key in ("accessKeyId", "secretAccessKey", "storageLinkSigningKey"):
            self.assertIn(f"key: {key}", deployment)

    def test_credentials_secret_override_reaches_every_consumer(self):
        extra = ["--set", "global.s3.credentialsSecret=custom-s3"]
        deployment = _ok(env="local", extra=extra, show="templates/deployment.yaml")
        seaweedfs = _ok(env="local", extra=extra, show="templates/seaweedfs-deployment.yaml")
        argo = _ok(env="local", extra=extra, show=ARGO_CONFIGMAP)
        self.assertEqual(3, deployment.count('name: "custom-s3"'))
        self.assertEqual(2, seaweedfs.count('name: "custom-s3"'))
        self.assertEqual(2, argo.count("name: custom-s3"))
        self.assertNotIn("s3-credentials", deployment + seaweedfs + argo)


class ArgoArtifactRepositoryTest(unittest.TestCase):
    def test_dev_artifact_repository_is_templated_from_global_s3(self):
        argo = _ok(env="dev", show=ARGO_CONFIGMAP)
        self.assertIn("bucket: ogdc-dev", argo)
        # Argo wants host[:port]; the scheme is stripped from global.s3.endpoint.
        self.assertIn("endpoint: s3.anacapa.nceas.ucsb.edu\n", argo)
        self.assertIn("region: default", argo)
        self.assertIn("insecure: false", argo)
        self.assertIn(f"name: {RELEASE}-s3-credentials", argo)

    def test_local_artifact_repository_uses_plain_http_seaweedfs(self):
        argo = _ok(env="local", show=ARGO_CONFIGMAP)
        self.assertIn(f"endpoint: {RELEASE}-seaweedfs:8333", argo)
        self.assertIn("insecure: true", argo)


class StorageRoutingTest(unittest.TestCase):
    def test_storage_path_targets_ogdc_service_unstripped(self):
        ingress = _ok(env="dev", extra=["--set", "ingress.enabled=true"], show="templates/ingress.yaml")
        storage = ingress.split('path: "/storage"', 1)[1]
        self.assertIn(f"name: {RELEASE}-service", storage)
        self.assertIn("number: 8000", storage)
        middleware = _ok(env="dev", show="templates/middleware.yaml")
        self.assertIn('- "^/api"', middleware)
        self.assertNotIn("storage", middleware.split("stripPrefixRegex", 1)[1])


class LocalSeaweedfsTest(unittest.TestCase):
    def test_local_renders_seaweedfs_and_bucket_job(self):
        rendered = _ok(env="local")
        for name in (
            f"name: {RELEASE}-seaweedfs\n",
            f"name: {RELEASE}-seaweedfs-bucket\n",
            "helm.sh/hook: post-install,post-upgrade",
        ):
            self.assertIn(name, rendered)

    def test_dev_and_prod_render_no_seaweedfs(self):
        for env in ("dev", "prod"):
            with self.subTest(env=env):
                self.assertNotIn("seaweedfs", _ok(env=env))


if __name__ == "__main__":
    unittest.main()
