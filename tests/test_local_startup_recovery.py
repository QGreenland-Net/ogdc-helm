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


if __name__ == "__main__":
    unittest.main()
