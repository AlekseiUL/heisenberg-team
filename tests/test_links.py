"""Exercise the actual CLI exit status, including nested document paths."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

CHECKER = Path(__file__).resolve().parents[1] / 'scripts/check_links.py'


class LinkGate(unittest.TestCase):
    def check(self, text, nested=False, target=True):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'docs/nested').mkdir(parents=True)
            if target:
                (root / 'docs/target.md').write_text('# Target\n')
            source = root / ('docs/nested/page.md' if nested else 'README.md')
            source.write_text(text)
            return subprocess.run([sys.executable, str(CHECKER), str(root)],
                                  capture_output=True, text=True)

    def test_valid_root(self):
        self.assertEqual(self.check('[ok](docs/target.md#section)').returncode, 0)

    def test_missing_fails(self):
        result = self.check('[bad](docs/missing.md)')
        self.assertEqual(result.returncode, 1)
        self.assertIn('docs/missing.md', result.stdout)

    def test_nested_relative(self):
        self.assertEqual(self.check('[ok](../target.md)', nested=True).returncode, 0)

    def test_nested_missing_fails(self):
        self.assertEqual(self.check('[bad](../missing.md)', nested=True).returncode, 1)

    def test_code_and_external_not_files(self):
        text = '```md\n[example](missing.md)\n```\n`[code](missing.md)`\n[web](https://example.com)\n[anchor](#here)\n'
        self.assertEqual(self.check(text).returncode, 0)

    def test_url_encoding_and_title(self):
        self.assertEqual(self.check('[ok](docs/%74arget.md "Title")').returncode, 0)

    def test_reference_link_fails(self):
        self.assertEqual(self.check('[bad][missing]\n\n[missing]: docs/missing.md\n').returncode, 1)


if __name__ == '__main__':
    unittest.main()
