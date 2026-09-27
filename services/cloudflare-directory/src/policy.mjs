export const CAPACITIES=[32,32,16,16,16,32,16,6,6,6,6,6,6,8,8,8,8,8,8,...Array(6).fill(8),...Array(6).fill(12)];
export const PHASES=['lobby','buy','combat','round_end','result'];
export function fail(status,detail){throw Object.assign(new Error(detail),{status});}
export function object(value){if(!value||typeof value!=='object'||Array.isArray(value))fail(422,'JSON 객체가 필요합니다.');return value;}
export function text(value,max){if(typeof value!=='string'||!value.trim()||value.length>max)fail(422,'문자열 형식을 확인하세요.');return value;}
export function integer(value,min,max){if(!Number.isInteger(value)||value<min||value>max)fail(422,'숫자 범위를 확인하세요.');return value;}
export function scope(value='internet'){if(!['internet','lan'].includes(value))fail(422,'로비 종류를 확인하세요.');return value;}
export function exact(value,keys){object(value);if(Object.keys(value).some(k=>!keys.includes(k)))fail(422,'지원하지 않는 설정입니다.');}
export function options(value){
  const base={name:'공개 경기',mode:0,map:13,capacity:8,map_random:true,map_rotation:false,minutes:10,target:60,team_respawns:60,capture_hold:60,capture_seconds:5,rounds:4,starting_cash:800,prep_seconds:30,round_minutes:5,bomb_seconds:45,buy_seconds:60,lives:0,next_teams:2,scope:'internet',locked:false};
  exact(value,Object.keys(base));const o={...base,...value};
  text(o.name,40);integer(o.mode,0,4);integer(o.map,0,30);integer(o.capacity,2,32);scope(o.scope);
  for(const [key,min,max] of [['minutes',0,180],['target',1,10000],['team_respawns',0,10000],['capture_hold',1,3600],['capture_seconds',1,60],['rounds',2,100],['starting_cash',0,8000],['prep_seconds',5,120],['round_minutes',1,60],['bomb_seconds',30,120],['buy_seconds',0,300],['lives',0,10],['next_teams',0,2]])integer(o[key],min,max);
  if(o.buy_seconds>o.round_minutes*60)fail(422,'구매 시간은 라운드 시간을 넘을 수 없습니다.');
  if(o.rounds%2)fail(422,'진행 라운드 수는 짝수여야 합니다.');
  for(const k of ['map_random','map_rotation','locked'])if(typeof o[k]!=='boolean')fail(422,'체크 설정을 확인하세요.');
  if(o.capacity%2||o.capacity>CAPACITIES[o.map]||(o.mode===4)!==(o.map>=19)||(o.mode===4&&o.capacity>12))fail(422,'맵 정원과 게임 모드가 맞지 않습니다.');
  return o;
}
export function relay(data,from,targets){
  if(!Number.isInteger(data.to)||data.to===from||(from!==1&&data.to!==1)||!targets.includes(data.to))return null;
  if(data.op==='sdp'&&['offer','answer'].includes(data.type)&&typeof data.sdp==='string'&&data.sdp.length<=20000)return {op:'sdp',from,type:data.type,sdp:data.sdp};
  if(data.op==='ice'&&typeof data.candidate==='string'&&data.candidate.length<=3000&&typeof data.mid==='string'&&data.mid.length<=64&&Number.isInteger(data.index)&&data.index>=0&&data.index<=16)return {op:'ice',from,candidate:data.candidate,mid:data.mid,index:data.index};
  return null;
}
