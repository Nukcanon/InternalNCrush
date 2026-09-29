import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const handlers={},stores=new Map();let downloads=0;
const cacheAPI={
  async keys(){return [...stores.keys()];},
  async delete(key){return stores.delete(key);},
  async open(key){
    if(!stores.has(key))stores.set(key,new Map());
    const data=stores.get(key);
    return {async match(req){return data.get(req.url)?.clone();},async put(req,res){data.set(req.url,new Response(await res.arrayBuffer(),{status:res.status}));}};
  }
};
vm.runInNewContext(fs.readFileSync(new URL('./asset_cache_worker.js',import.meta.url),'utf8'),{
  self:{location:{origin:'https://game.test'},addEventListener:(type,fn)=>handlers[type]=fn},URL,caches:cacheAPI,
  fetch:async()=>{downloads++;return new Response('game-data');},
});
async function request(path,headers={}){
  let response;const work=[];
  handlers.fetch({request:new Request('https://game.test/play/'+path,{headers}),respondWith:value=>response=value,waitUntil:value=>work.push(value)});
  const result=await response;await Promise.all(work);return result;
}
assert.equal(await (await request('game-a.pck')).text(),'game-data');
assert.equal(await (await request('game-a.pck')).text(),'game-data');assert.equal(downloads,1);
await request('game-b.pck');assert.equal(downloads,2);
assert.equal(await request('build.json'),undefined);
assert.equal(await request('index.html'),undefined);
assert.equal(await request('game-b.pck',{range:'bytes=0-10'}),undefined);
await request('game-c.wasm');await request('game-d.pck');assert.equal(stores.size,1);assert.ok(stores.has('inc-immutable-v1-game-d'),'only the current build stays cached');
cacheAPI.open=async()=>({match:async()=>undefined,put:async()=>{throw Error('quota');}});
assert.equal(await (await request('game-e.pck')).text(),'game-data');
cacheAPI.open=async()=>{throw Error('storage unavailable');};
assert.equal(await (await request('game-f.pck')).text(),'game-data');
cacheAPI.open=async()=>({match:async()=>{throw Error('read failed');}});
assert.equal(await (await request('game-g.pck')).text(),'game-data');
console.log('ASSET_CACHE: reuse, update, bypass, bounded retention, quota/open/read fallback passed');
