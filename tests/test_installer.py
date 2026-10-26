import os, pathlib, shutil, subprocess, tempfile, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Install(unittest.TestCase):
    def test_install_update_and_fixture_rollback(self):
        with tempfile.TemporaryDirectory() as td:
            home=pathlib.Path(td); target=home/'team'
            env={**os.environ,'HOME':td,'OPENCLAW_AGENTS_DIR':str(target)}
            def run():
                p=subprocess.run(['bash',str(ROOT/'scripts/deploy-team.sh')],env=env,text=True,capture_output=True,timeout=20)
                self.assertEqual(p.returncode,0,p.stdout+p.stderr)
            run()
            local=target/'heisenberg/references/team-board.md'; local.write_text('user board\n')
            snapshot=home/'snapshot'; shutil.copytree(target,snapshot)
            run()
            self.assertEqual(local.read_text(),'user board\n')
            for config in (ROOT/'configs').glob('*.openclaw.json.example'):
                agent=config.name.split('.')[0]
                dest=target/agent/'openclaw.json.example'
                if dest.exists(): self.assertEqual(dest.read_bytes(),config.read_bytes())
            # No native uninstall command exists: exercise rollback of a synthetic tree only.
            shutil.rmtree(target); shutil.copytree(snapshot,target)
            self.assertEqual(local.read_text(),'user board\n')
if __name__=='__main__': unittest.main()
