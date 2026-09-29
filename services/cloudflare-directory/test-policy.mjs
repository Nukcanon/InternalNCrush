import test from 'node:test';
import assert from 'node:assert/strict';
import {options,relay,scope,version} from './src/policy.mjs';
test('releases at or above the minimum are accepted without redeploying',()=>{
  for(const v of ['1.3.5','1.3.6','1.4.0','2.0.0'])assert.equal(version(v,'1.3.5'),v);
  for(const v of ['1.3.4','1.2.9','0.9.9'])assert.throws(()=>version(v,'1.3.5'),/업데이트/);
  for(const v of [undefined,'','1.3','1.3.5.1','v1.3.5',135])assert.throws(()=>version(v,'1.3.5'));
});
test('strict room rules prevent over-capacity or incompatible maps',()=>{
  assert.equal(options({}).capacity,8);
  for(const v of [{capacity:32,map:13},{capacity:7},{mode:4,map:13},{mode:0,map:19},{mode:4,map:25,capacity:16},{locked:1},{unknown:true}])assert.throws(()=>options(v));
  assert.equal(options({mode:4,map:25,capacity:12}).capacity,12);
});

test('mode settings preserve selected rules and reject invalid values',()=>{
  const chosen={minutes:0,target:175,team_respawns:22,capture_hold:35,capture_seconds:12,rounds:8,starting_cash:2500,prep_seconds:20,round_minutes:7,bomb_seconds:75,buy_seconds:90,lives:10,next_teams:2};
  for(const [key,value] of Object.entries(chosen))assert.equal(options(chosen)[key],value);
  assert.equal(options({}).rounds,4);assert.equal(options({}).prep_seconds,30);
  for(const v of [{rounds:3},{rounds:0},{minutes:-1},{lives:11},{round_minutes:0},{target:0},{starting_cash:8001},{minutes:true},{bomb_seconds:29},{bomb_seconds:121},{buy_seconds:-1},{buy_seconds:301},{round_minutes:1,buy_seconds:61}])assert.throws(()=>options(v));
});
test('signaling is restricted to host-client pairs and approved payloads',()=>{
  const data={op:'sdp',to:3,type:'offer',sdp:'v=0',uid:'forged'};
  assert.equal(relay(data,2,[1,3]),null);
  assert.deepEqual(relay({...data,to:1},2,[1]),{op:'sdp',from:2,type:'offer',sdp:'v=0'});
  assert.equal(relay({op:'status',to:1,players:30},2,[1]),null);
  assert.equal(relay({op:'ice',to:1,mid:'0',index:999,candidate:'bad'},2,[1]),null);
  assert.throws(()=>scope('other'));
});
