import tempfile
import unittest
import zipfile
from pathlib import Path
from nas import setup

class SetupTests(unittest.TestCase):
    def test_config_scopes_and_validation(self):
        a=setup.configuration('lobby.example.com','nas')
        b=setup.configuration('lobby.example.com','linux','admin@example.com')
        self.assertEqual(a['BIND_IP'],'127.0.0.1');self.assertEqual(b['HTTP_PORT'],'80')
        for name in ['https://example.com','localhost','example.com\nTOKEN=bad','$(whoami).com']:
            with self.assertRaises(ValueError):setup.domain(name)
    def test_preserve_existing_relay_secret_and_backup(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'.env';p.write_text('TURN_SECRET=local-test-secret\nTURN_URLS=turn:relay.example.com:3478\n')
            setup.save_config(setup.configuration('lobby.example.com','nas'),p)
            self.assertEqual(setup.read_env(p)['TURN_SECRET'],'local-test-secret')
            self.assertEqual(len(list(Path(d).glob('.env.backup-*'))),1)
    def test_upload_archive_has_small_server_no_game(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/'upload.zip';setup.package(p,include_config=False)
            with zipfile.ZipFile(p) as z:
                self.assertIn('InternalNCrush-NAS/services/directory/main.py',z.namelist())
                self.assertIn('InternalNCrush-NAS/nas/.env.example',z.namelist())
                self.assertNotIn('InternalNCrush-NAS/nas/.env',z.namelist())
                self.assertFalse(any('/game/' in n or 'godot' in n.lower() for n in z.namelist()))

if __name__=='__main__':unittest.main()
