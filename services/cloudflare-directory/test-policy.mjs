import test from 'node:test';
import assert from 'node:assert/strict';
import {options,relay,scope} from './src/policy.mjs';
test('strict room rules prevent over-capacity or incompatible maps',()=>{
  assert.equal(options({}).capacity,8);
  for(const v of [{capacity:32,map:13},{capacity:7},{mode:4,map:13},{mode:0,map:19},{mode:4,map:25,capacity:16},{locked:1},{unknown:true}])assert.throws(()=>options(v));
  assert.equal(options({mode:4,map:25,capacity:12}).capacity,12);
});
test('signaling is restricted to host-client pairs and approved payloads',()=>{
  const data={op:'sdp',to:3,type:'offer',sdp:'v=0',uid:'forged'};
  assert.equal(relay(data,2,[1,3]),null);
  assert.deepEqual(relay({...data,to:1},2,[1]),{op:'sdp',from:2,type:'offer',sdp:'v=0'});
  assert.equal(relay({op:'status',to:1,players:30},2,[1]),null);
  assert.equal(relay({op:'ice',to:1,mid:'0',index:999,candidate:'bad'},2,[1]),null);
  assert.throws(()=>scope('other'));
});
