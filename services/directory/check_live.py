"""HTTP + real WebSocket contract check shared by Docker and Workers local tests."""
import argparse
import asyncio
import json
import urllib.request
import urllib.error
import websockets

async def check(url, version):
    def request(path, data=None, token=''):
        headers={'Content-Type':'application/json'}
        if token:headers['Authorization']='Bearer '+token
        req=urllib.request.Request(url+path,data=None if data is None else json.dumps(data).encode(),headers=headers)
        with urllib.request.urlopen(req,timeout=10) as r:return json.load(r)
    assert request('/health')['role']=='directory-only'
    owner=request('/v1/sessions',{'nick':'Contract Host','version':version})['token']
    guest=request('/v1/sessions',{'nick':'Contract Guest','version':version})['token']
    room=request('/v1/rooms',{'name':'Contract validation','capacity':2,'map_random':False},owner)['id']
    ht=request('/v1/rooms/'+room+'/join',{},owner)
    ws_url=url.replace('http://','ws://').replace('https://','wss://')+'/v1/signal'
    async with websockets.connect(ws_url) as host:
        await host.send(json.dumps({'ticket':ht['ticket']}));assert json.loads(await host.recv())=={'op':'ready','peer':1}
        await host.send(json.dumps({'op':'status','phase':'combat','players':1,'map':13}))
        ping=json.loads(await host.recv());await host.send(json.dumps({'op':'pong','nonce':ping['nonce']}))
        gt=request('/v1/rooms/'+room+'/join',{},guest)
        async with websockets.connect(ws_url) as client:
            await client.send(json.dumps({'ticket':gt['ticket']}));assert json.loads(await client.recv())['peer']==2
            assert json.loads(await host.recv())['op']=='peer'
            await host.send(json.dumps({'op':'sdp','to':2,'type':'offer','sdp':'v=0'}))
            assert json.loads(await client.recv())=={'op':'sdp','from':1,'type':'offer','sdp':'v=0'}
            await client.send(json.dumps({'op':'ice','to':1,'mid':'0','index':0,'candidate':'contract'}))
            assert json.loads(await host.recv())['candidate']=='contract'
            try:
                async with websockets.connect(ws_url) as replay:
                    await replay.send(json.dumps({'ticket':gt['ticket']}));await replay.recv()
                raise AssertionError('One-use ticket was replayed')
            except websockets.ConnectionClosed:pass
            # Round-end/result heartbeats must keep the room registered too.
            await host.send(json.dumps({'op':'status','phase':'round_end','players':2,'map':13}))
            ping=json.loads(await host.recv());assert ping['op']=='ping'
            await host.send(json.dumps({'op':'pong','nonce':ping['nonce']}))
            listing=request('/v1/rooms',token=guest)['rooms'];assert any(r['id']==room for r in listing)
        assert json.loads(await host.recv())=={'op':'left','peer':2}
    for _ in range(20):
        if not any(r['id']==room for r in request('/v1/rooms',token=guest)['rooms']):break
        await asyncio.sleep(.1)
    else:raise AssertionError('Host departure left a stale room')
    print('DIRECTORY_LIVE_OK HTTP/auth/admission/SDP/ICE/replay/round_end/host departure')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('url');p.add_argument('--version',default='1.1.5');a=p.parse_args()
    asyncio.run(asyncio.wait_for(check(a.url.rstrip('/'),a.version),35))
