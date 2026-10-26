import hashlib, json, pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class Drift(unittest.TestCase):
    def test_shared_component_digests(self):
        lock=json.loads((ROOT/'shared-components.lock.json').read_text())
        self.assertTrue(lock['files'])
        for name,digest in lock['files'].items():
            self.assertEqual(hashlib.sha256((ROOT/name).read_bytes()).hexdigest(),digest,name)
if __name__=='__main__': unittest.main()
