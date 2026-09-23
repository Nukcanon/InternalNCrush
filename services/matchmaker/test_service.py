import base64
import hashlib
import hmac
import json
import time
import unittest

from fastapi.testclient import TestClient
from services.matchmaker.main import Allocator, VERSION, create_app


class LobbyTest(unittest.TestCase):
    def setUp(self):
        self.state = Allocator(launch=False)
        self.client = TestClient(create_app(self.state))
        self.owner = self.session("OWNER")

    def session(self, nick):
        result = self.client.post("/v1/sessions", json={"nick": nick, "version": VERSION})
        self.assertEqual(result.status_code, 200)
        return {"Authorization": "Bearer " + result.json()["token"]}

    def create(self, headers=None, **options):
        response = self.client.post("/v1/rooms", headers=headers or self.owner, json=options)
        self.assertEqual(response.status_code, 200, response.text)
        room = self.state.rooms[response.json()["id"]]
        room.phase = "lobby"
        return room

    def test_auth_and_version(self):
        self.assertEqual(self.client.get("/v1/rooms").status_code, 401)
        self.assertEqual(self.client.get("/v1/rooms", headers={"Authorization": "Bearer forged"}).status_code, 401)
        self.assertEqual(self.client.post("/v1/sessions", json={"nick": "X", "version": "old"}).status_code, 409)
        self.assertEqual(self.client.get("/v1/rooms", headers=self.owner).status_code, 200)

    def test_capacity_and_strict_types(self):
        for options in [{"capacity": 32, "map": 13}, {"mode": -1}, {"map": 99}, {"capacity": True}, {"map": "13"}, {"admin": True}]:
            self.assertEqual(self.client.post("/v1/rooms", headers=self.owner, json=options).status_code, 422)
        room = self.create()
        self.assertEqual(room.options.capacity, 8)
        self.assertEqual(self.client.post("/v1/rooms", headers=self.owner, json={}).status_code, 409)

    def test_signed_expiring_ticket_and_reservations(self):
        room = self.create(capacity=2)
        guest = self.session("GUEST")
        third = self.session("THIRD")
        url = f"/v1/rooms/{room.id}/join"
        ticket = self.client.post(url, headers=self.owner).json()
        encoded, signature = ticket["ticket"].split(".")
        self.assertTrue(hmac.compare_digest(signature, hmac.new(room.key.encode(), encoded.encode(), hashlib.sha256).hexdigest()))
        claims = json.loads(base64.b64decode(encoded))
        self.assertTrue(claims["owner"])
        self.assertGreater(claims["exp"], time.time())
        self.assertLessEqual(claims["exp"], time.time() + 30)
        self.assertTrue(ticket["url"].startswith("wss://"))
        self.assertEqual(self.client.post(url, headers=guest).status_code, 200)
        self.assertEqual(self.client.post(url, headers=third).status_code, 409)
        room.reservations = {uid: time.time() - 1 for uid in room.reservations}
        self.assertEqual(self.client.post(url, headers=third).status_code, 200)

    def test_match_optional_mode_and_server_credential(self):
        room = self.create(mode=3)
        guest = self.session("GUEST")
        joined = self.client.post("/v1/match", headers=guest, json={"mode": None})
        self.assertEqual(joined.json()["room"]["id"], room.id)
        url = f"/internal/rooms/{room.id}/heartbeat"
        self.assertEqual(self.client.post(url, headers=self.owner, json={"players": [], "phase": "combat"}).status_code, 403)
        self.assertEqual(self.client.post(url, headers={"Authorization": "Bearer " + room.key}, json={"players": [], "phase": "combat"}).status_code, 200)
        third = self.session("THIRD")
        matched = self.client.post("/v1/match", headers=third, json={"mode": 1}).json()
        self.assertTrue(matched["pending"])
        self.assertEqual(matched["room"]["mode"], 1)

    def test_no_secrets_in_public_room(self):
        room = self.create()
        text = self.client.get("/v1/rooms", headers=self.owner).text
        self.assertNotIn(room.key, text)
        self.assertNotIn(room.owner, text)
        self.assertNotIn("ticket", text)

    def test_request_size_and_rate_bounds(self):
        self.assertEqual(self.client.post("/v1/rooms", headers=self.owner, content=b"x" * 4097).status_code, 413)
        failures = [self.client.get("/health").status_code for _ in range(100)]
        self.assertIn(429, failures)

    def test_stale_room_reaped(self):
        room = self.create()
        room.heartbeat = time.time() - 60
        self.state.maintain()
        self.assertNotIn(room.id, self.state.rooms)

    def test_session_expiry(self):
        for s in self.state.sessions.values():
            s.expires = 0
        self.assertEqual(self.client.get("/v1/rooms", headers=self.owner).status_code, 401)

    def test_only_owner_can_close_room(self):
        room = self.create()
        url = f"/v1/rooms/{room.id}"
        self.assertEqual(self.client.delete(url, headers=self.session("GUEST")).status_code, 403)
        self.assertEqual(self.client.delete(url, headers=self.owner).status_code, 200)
        self.assertNotIn(room.id, self.state.rooms)


if __name__ == "__main__":
    unittest.main()
