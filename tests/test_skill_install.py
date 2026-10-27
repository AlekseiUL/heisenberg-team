"""Run each actual installer's copy loop on colliding skill filenames."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SkillInstallLayout(unittest.TestCase):
    def test_each_installer_preserves_skill_directory(self):
        for name in ('setup.sh', 'setup-wizard.sh'):
            with self.subTest(installer=name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                repo = root / 'source'
                dest = root / 'installed'
                dest.mkdir()
                for skill in ('alpha', 'beta'):
                    directory = repo / 'skills' / skill
                    (directory / 'references').mkdir(parents=True)
                    (directory / 'SKILL.md').write_text(skill + '\n')
                    (directory / 'references' / 'core.md').write_text(skill + ' core\n')
                script = (ROOT / 'scripts' / name).read_text()
                match = re.search(r'^( +)for skill_dir in .*?^\1done', script, re.S | re.M)
                if match is None:
                    self.fail('installer skill loop not found')
                shell = ('set -eu\nSKILL_OK=0; SKILL_FAIL=0; SKILL_ERRORS=0\n'
                         'YELLOW=; NC=\n' + match.group(0) + '\n')
                result = subprocess.run(['bash', '-c', shell], text=True, capture_output=True,
                                        env=dict(os.environ, REPO_DIR=str(repo), SKILLS_DEST=str(dest)),
                                        timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(sorted(p.name for p in dest.iterdir()), ['alpha', 'beta'])
                for skill in ('alpha', 'beta'):
                    self.assertEqual((dest / skill / 'SKILL.md').read_text(), skill + '\n')
                    self.assertEqual((dest / skill / 'references' / 'core.md').read_text(), skill + ' core\n')


if __name__ == '__main__':
    unittest.main()
