import hashlib
import unittest
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect
from services.directory import main

class DirectoryTests(unittest.TestCase):
    def setUp(self):
        main.directory=main.Directory();self.state=main.directory
        self.context=TestClient(main.app);self.client=self.context.__enter__()
        self.owner=self.session('OWNER');self.guest=self.session('GUEST')
    def tearDown(self):self.context.__exit__(None,None,None)
    def session(self,nick):
        response=self.client.post('/v1/sessions',json={'nick':nick,'version':main.VERSION})
        self.assertEqual(response.status_code,200,response.text)
        return {'Authorization':'Bearer '+response.json()['token']}
    def room(self,**data):
        response=self.client.post('/v1/rooms',headers=self.owner,json=data)
        self.assertEqual(response.status_code,200,response.text);return response.json()['id']
    def ticket(self,room,headers):
        response=self.client.post('/v1/rooms/'+room+'/join',headers=headers,json={})
        self.assertEqual(response.status_code,200,response.text);return response.json()
    def test_health_no_game_process(self):
        self.assertEqual(self.client.get('/health').json()['role'],'directory-only')
        self.assertFalse(hasattr(self.state,'launch'))
        self.assertEqual(self.client.get('/v1/rooms').status_code,401)
        self.assertEqual(self.client.post('/v1/sessions',json={'nick':'x','version':'old'}).status_code,409)
    def test_room_rules_and_payload_limits(self):
        for data in [{'capacity':32,'map':13},{'capacity':7},{'mode':4,'map':13},{'mode':0,'map':19},{'name':'x'*41}]:
            self.assertEqual(self.client.post('/v1/rooms',headers=self.owner,json=data).status_code,422)
        self.assertEqual(self.client.post('/v1/rooms',headers=self.owner,content=b'x'*4097).status_code,413)
        room=self.room(capacity=12,map=25,mode=4)
        self.assertEqual(self.client.post('/v1/rooms',headers=self.owner,json={}).status_code,409)
        self.assertEqual(self.client.post('/v1/rooms/'+room+'/join',headers=self.guest,json={}).status_code,409)
    def test_signaling_isolation_and_host_departure(self):
        room=self.room();host_ticket=self.ticket(room,self.owner)
        with self.client.websocket_connect('/v1/signal') as host:
            host.send_json({'ticket':host_ticket['ticket']});self.assertEqual(host.receive_json(),{'op':'ready','peer':1})
            host.send_json({'op':'status','phase':'lobby','players':1,'map':13});ping=host.receive_json();host.send_json({'op':'pong','nonce':ping['nonce']})
            guest_ticket=self.ticket(room,self.guest)
            with self.client.websocket_connect('/v1/signal') as guest:
                guest.send_json({'ticket':guest_ticket['ticket']});self.assertEqual(guest.receive_json()['peer'],2)
                self.assertEqual(host.receive_json()['op'],'peer')
                guest.send_json({'op':'sdp','to':1,'type':'offer','sdp':'v=0'})
                self.assertEqual(host.receive_json(),{'op':'sdp','from':2,'type':'offer','sdp':'v=0'})
                # A guest cannot send arbitrary game state or route to another guest.
                guest.send_json({'op':'status','phase':'combat','players':31,'map':0})
                guest.send_json({'op':'sdp','to':99,'type':'offer','sdp':'forbidden'})
                guest.send_json({'op':'ice','to':1,'mid':'0','index':0,'candidate':'candidate:test'})
                self.assertEqual(host.receive_json()['candidate'],'candidate:test')
                self.assertEqual(self.state.rooms[room]['players'],1)
                with self.assertRaises(WebSocketDisconnect):
                    with self.client.websocket_connect('/v1/signal') as replay:
                        replay.send_json({'ticket':guest_ticket['ticket']});replay.receive_json()
            self.assertEqual(host.receive_json(),{'op':'left','peer':2})
        self.assertNotIn(room,self.state.rooms)
    def test_lan_visibility_and_admission(self):
        room=self.room(scope='lan')
        digest=hashlib.sha256(self.guest['Authorization'][7:].encode()).hexdigest()
        self.state.sessions[digest]['network']='different-network'
        self.assertEqual(self.client.get('/v1/rooms?scope=lan',headers=self.guest).json()['rooms'],[])
        self.assertEqual(self.client.post('/v1/rooms/'+room+'/join',headers=self.guest,json={}).status_code,403)
        self.assertEqual(len(self.client.get('/v1/rooms?scope=lan',headers=self.owner).json()['rooms']),1)
    def test_quick_match_elects_requester_host(self):
        result=self.client.post('/v1/match',headers=self.owner,json={'mode':4}).json()
        self.assertEqual(result['peer'],1);self.assertTrue(result['automatic'])
        self.assertEqual(result['room']['map'],19);self.assertEqual(result['room']['capacity'],8)
        self.assertFalse(any('process' in room for room in self.state.rooms.values()))
    def test_capacity_counts_pending_tickets(self):
        third=self.session('THIRD');room=self.room(capacity=2)
        with self.client.websocket_connect('/v1/signal') as host:
            host.send_json({'ticket':self.ticket(room,self.owner)['ticket']});host.receive_json()
            old=self.ticket(room,self.guest);fresh=self.ticket(room,self.guest)
            self.assertNotEqual(old['ticket'],fresh['ticket'])
            self.assertEqual(self.client.post('/v1/rooms/'+room+'/join',headers=third,json={}).status_code,409)
    def test_untrusted_browser_origin(self):
        with self.assertRaises(WebSocketDisconnect):
            with self.client.websocket_connect('/v1/signal',headers={'origin':'https://untrusted.example'}):pass

if __name__=='__main__':unittest.main()
