import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CHART = ROOT / "helm"
LOCAL_VALUES = CHART / "examples" / "values-local-cluster-ogdc-example.yaml"


class LocalStartupRecoveryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rendered = subprocess.run(
            [
                "helm",
                "template",
                "t04e2e",
                str(CHART),
                "--namespace",
                "t04e2e",
                "-f",
                str(LOCAL_VALUES),
            ],
            check=True,
            capture_output=True,
            text=True,
        ).stdout

    def test_local_service_command_is_not_a_reload_supervisor(self):
        self.assertIn("fastapi run --port 8000 --host 0.0.0.0 src/ogdc_runner/service/main.py", self.rendered)
        self.assertNotIn("fastapi dev", self.rendered)

    def test_service_readiness_probe_remains_version_endpoint(self):
        service = self.rendered.split("# Source: ogdc/templates/deployment.yaml", 1)[1].split("\n---", 1)[0]
        self.assertIn("path: /version", service)
        self.assertIn("port: 8000", service)

    def test_argo_controller_and_server_are_namespace_scoped(self):
        documents = self.rendered.split("\n---\n")
        deployments = {
            document.split("name: ", 1)[1].splitlines()[0].strip(): document
            for document in documents
            if "kind: Deployment" in document
            and "app.kubernetes.io/name: argo-workflows-" in document
        }
        controller = next(value for key, value in deployments.items() if "workflow-controller" in key)
        server = next(value for key, value in deployments.items() if key.endswith("-server"))
        self.assertIn('"--namespaced"', controller)
        self.assertIn('"--namespaced"', server)

    def test_argo_workflow_rbac_is_namespaced(self):
        documents = self.rendered.split("\n---\n")
        controller_rbac = [
            document for document in documents
            if "name: t04e2e-argo-workflows-workflow-controller" in document
            and "\nkind: ClusterRole\n" in document
        ]
        server_rbac = [
            document for document in documents
            if "name: t04e2e-argo-workflows-server" in document
            and "\nkind: ClusterRole\n" in document
        ]
        self.assertEqual([], controller_rbac)
        self.assertEqual([], server_rbac)
        for role_name in ("workflow-controller", "server"):
            roles = [
                document for document in documents
                if f"name: t04e2e-argo-workflows-{role_name}\n" in document
                and "\nkind: Role\n" in document
            ]
            self.assertTrue(roles, f"expected namespace Role for {role_name}")
            self.assertTrue(all('namespace: "t04e2e"' in role for role in roles))


if __name__ == "__main__":
    unittest.main()
