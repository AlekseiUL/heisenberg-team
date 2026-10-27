"""Runtime declarations and setup refusal must agree with Node 24 CI."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
GATE = 'process.exit(Number(process.versions.node.split(".")[0]) === 24 ? 0 : 1)'


class NodeRuntime(unittest.TestCase):
    def test_supported_runtime_and_bootstrap(self):
        self.assertEqual((ROOT / '.nvmrc').read_text().strip(), '24')
        self.assertEqual(subprocess.run(['node', '-e', GATE], check=False).returncode, 0)
        bootstrap = (ROOT / 'scripts/bootstrap-install.sh').read_text()
        self.assertIn('setup_24.x', bootstrap)
        self.assertIn('node@24', bootstrap)
        self.assertNotIn('setup_20.x', bootstrap)
        subprocess.run(['bash', '-n', str(ROOT / 'scripts/bootstrap-install.sh')], check=True)

    def test_unsupported_node_fails_before_configuration(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            node = root / 'node'
            node.write_text('#!/bin/sh\nif [ "$1" = --version ]; then echo v20.0.0; else exit 1; fi\n')
            node.chmod(0o755)
            claw = root / 'openclaw'
            claw.write_text('#!/bin/sh\necho offline-test-fixture\n')
            claw.chmod(0o755)
            env = dict(os.environ, HOME=tmp, PATH=tmp + os.pathsep + os.environ['PATH'])
            result = subprocess.run(['bash', str(ROOT / 'scripts/setup-wizard.sh')],
                                    cwd=tmp, env=env, input='', text=True, capture_output=True, timeout=10)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Node 24 LTS is required', result.stderr)
            self.assertFalse((root / '.openclaw').exists())


if __name__ == '__main__':
    unittest.main()
