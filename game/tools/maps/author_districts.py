import json,math,html
from pathlib import Path
from shapely.geometry import LineString,Point,box,Polygon
from shapely.ops import unary_union
from districts_v128 import LAYOUTS,TERRAIN,KEEP,BRIDGES,RECTANGLES
from vertical_districts import select as vertical_routes,COMPOSITIONS,STAIR_MAPS
import layouts_v14
from shapely.ops import substring as _substring
r=Path(__file__).resolve().parents[3];out=r/'game/assets/arenas';old=[{'players':c,'name':str(i+1)} for i,c in enumerate([32,32,16,16,16,32,16,6,6,6,6,6,6,8,8,8,8,8,8,8,8,8,8,8,8,12,12,12,12,12,12,16])]
# Authored district paths: each chain is a room/courtyard sequence, not a repeated open-field template.
chains=[
['50,92 24,88 14,70 26,62 14,44 28,32 18,14 50,8','50,92 58,78 43,65 54,50 42,36 55,24 50,8','50,92 80,85 88,65 74,55 86,38 73,24 82,12 50,8','26,62 43,65 74,55','28,32 42,36 73,24'],
['20,88 12,64 24,46 14,24 36,12 74,14','20,88 42,78 39,58 57,48 52,29 74,14','20,88 72,86 86,68 76,48 88,30 74,14','24,46 39,58 76,48','42,78 62,64 86,68'],
['50,92 22,82 14,59 30,47 16,28 39,10','50,92 53,74 44,55 60,40 48,24 39,10','50,92 83,82 76,63 90,48 77,32 80,14 39,10','30,47 44,55 76,63','16,28 48,24 77,32'],
['16,82 13,58 29,45 19,20 48,10','16,82 39,88 49,68 41,48 57,34 48,10','16,82 73,88 89,66 74,48 87,25 68,12 48,10','29,45 41,48 74,48','49,68 69,65 89,66'],
['48,92 18,85 11,64 25,49 12,29 33,11 54,9','48,92 43,72 59,58 47,42 60,25 54,9','48,92 80,82 90,62 75,47 87,27 73,12 54,9','25,49 47,42 75,47','43,72 67,72 80,82'],
['15,82 12,60 25,43 16,23 44,9','15,82 40,88 47,70 37,53 55,40 44,9','15,82 77,87 90,67 80,48 90,24 70,10 44,9','25,43 37,53 80,48','47,70 65,61 90,67'],
['48,92 16,83 14,59 31,48 16,28 42,9','48,92 44,73 60,60 45,44 60,26 42,9','48,92 83,82 85,58 72,45 87,25 64,10 42,9','14,59 44,73 85,58','31,48 45,44 72,45'],
['50,91 23,83 12,58 25,40 20,18 50,9','50,91 43,70 54,51 44,31 50,9','50,91 80,80 88,57 73,41 82,20 50,9','25,40 44,31 73,41','23,83 43,70 80,80'],
['48,90 18,80 12,53 26,34 20,12 51,9','48,90 50,70 40,52 59,34 51,9','48,90 80,82 89,59 75,43 84,18 51,9','26,34 40,52 75,43','18,80 50,70 80,82'],
['14,83 12,60 27,47 18,28 40,11','14,83 35,86 52,69 43,51 61,35 40,11','14,83 74,87 88,67 77,48 89,27 69,12 40,11','27,47 43,51 77,48','52,69 67,68 88,67'],
['50,92 20,79 13,55 30,41 19,18 50,8','50,92 55,73 42,53 57,33 50,8','50,92 83,79 86,55 72,40 80,18 50,8','13,55 42,53 86,55','30,41 57,33 72,40'],
['20,87 11,65 24,44 17,20 47,9','20,87 40,79 54,59 41,39 47,9','20,87 76,88 88,68 76,47 86,24 67,12 47,9','24,44 41,39 76,47','40,79 54,59 88,68'],
['49,92 23,82 12,60 28,44 16,23 49,8','49,92 42,71 55,54 43,32 49,8','49,92 80,81 88,59 73,42 85,20 49,8','28,44 43,32 73,42','23,82 42,71 80,81'],
['50,93 20,84 13,61 25,44 15,23 49,7','50,93 48,72 60,57 43,41 57,24 49,7','50,93 83,83 88,60 75,44 86,23 49,7','25,44 43,41 75,44','20,84 48,72 83,83'],
['20,86 11,63 25,47 18,22 48,9','20,86 42,84 48,65 40,45 57,27 48,9','20,86 76,87 88,67 78,47 88,24 68,12 48,9','25,47 40,45 78,47','48,65 62,58 88,67'],
['50,92 19,82 13,56 29,40 17,19 46,8','50,92 45,72 59,54 44,33 46,8','50,92 82,83 89,58 74,40 86,18 46,8','29,40 44,33 74,40','19,82 45,72 82,83'],
['18,84 12,60 27,43 19,20 49,8','18,84 39,86 53,68 42,49 60,30 49,8','18,84 77,87 90,66 76,45 88,21 68,12 49,8','27,43 42,49 76,45','39,86 53,68 90,66'],
['48,93 22,82 11,60 27,43 16,21 48,8','48,93 44,71 57,53 43,34 48,8','48,93 80,81 88,58 72,41 84,19 48,8','27,43 43,34 72,41','22,82 44,71 80,81'],
['18,87 11,65 24,48 16,25 40,10','18,87 42,86 51,67 40,47 59,29 40,10','18,87 78,86 90,65 76,46 88,24 67,11 40,10','24,48 40,47 76,46','51,67 66,61 90,65']]

# Distinct district topology overrides (U, Y, S, T, rings and split campuses).
chains[1]=['18,15 12,35 18,58 29,80 53,89 77,76 88,52 83,27 77,12', '18,15 35,12 42,27 58,30 63,15 77,12', '18,58 33,54 39,69 53,73 64,60 88,52', '29,80 35,66 39,69', '58,30 70,39 83,27']
chains[3]=['15,84 27,72 39,70 48,52 43,35 59,22 78,12', '15,84 14,62 28,48 22,28 43,35', '48,52 66,56 82,70 91,52 81,35 59,22', '27,72 53,84 70,77 82,70', '22,28 25,12 45,13 59,22']
chains[4]=['12,87 28,82 36,66 23,51 36,35 57,29 65,13 88,10', '12,87 13,66 23,51 14,32 34,17 57,29', '36,66 58,75 77,68 70,48 85,33 88,10', '36,35 51,45 70,48', '58,75 51,57 51,45']
chains[5]=['10,87 24,79 25,62 43,54 38,38 58,24 76,26 89,12', '10,87 31,91 47,78 47,65 64,58 60,41 77,40 89,12', '25,62 12,47 19,27 38,38', '47,78 69,83 87,69 80,53 64,58', '43,54 47,65', '58,24 60,41']
chains[6]=['10,73 28,70 39,53 48,34 68,25 91,27', '10,73 13,51 29,36 48,34', '28,70 44,87 66,84 72,62 86,49 91,27', '39,53 57,50 72,62', '48,34 44,14 63,9 68,25', '57,50 67,41 86,49']
chains[7]=['18,87 14,64 30,55 26,34 42,13 72,11', '18,87 40,86 48,67 30,55', '48,67 70,76 88,62 80,43 62,39 72,11', '26,34 44,40 62,39', '40,86 70,76', '42,13 52,23 62,39']
chains[9]=['12,88 31,82 43,68 21,56 16,40 43,32 62,14 87,11', '12,88 13,70 21,56', '31,82 64,87 84,72 70,58 46,50 43,32', '43,68 46,50', '70,58 90,47 83,31 62,14', '16,40 23,19 42,14 62,14']
chains[10]=['19,86 11,61 17,38 35,16 58,10 83,23', '19,86 45,89 68,77 85,56 83,23', '17,38 36,43 51,30 68,32 83,23', '19,86 34,66 36,43', '34,66 52,64 68,77', '51,30 52,64']
chains[11]=['50,91 24,76 14,50 23,23 49,9', '50,91 76,77 89,48 74,21 49,9', '24,76 42,61 49,40 23,23', '42,61 65,61 89,48', '49,40 74,21', '49,40 65,61']
chains[12]=['12,73 29,77 43,58 52,45 70,28 87,14', '12,73 11,47 28,29 52,45', '29,77 50,91 76,81 78,57 52,45', '28,29 37,12 61,12 70,28', '78,57 92,39 87,14', '43,58 31,50 28,29']
chains[14]=['12,80 17,57 29,40 43,44 59,55 73,39 89,18', '12,80 34,88 43,70 43,44', '17,57 13,31 30,13 43,25 43,44', '59,55 64,80 83,82 92,61 73,39', '73,39 62,24 73,11 89,18', '43,70 59,55']
chains[15]=['12,86 12,58 27,40 16,21 42,12 66,16 86,30', '12,86 38,89 55,72 47,49 27,40', '47,49 66,48 86,30', '55,72 80,78 89,58 66,48', '27,40 44,29 66,16']
chains[16]=['15,85 12,61 31,45 40,24 63,12 87,24', '15,85 41,87 52,66 31,45', '52,66 76,80 91,61 75,43 87,24', '31,45 14,28 22,12 40,24', '40,24 56,40 75,43', '52,66 56,40']
chains[17]=['12,86 13,59 27,41 20,20 42,9 63,23 86,15', '12,86 40,90 52,70 44,51 27,41', '52,70 77,83 91,63 78,44 63,23', '44,51 59,43 78,44', '20,20 39,31 59,43', '91,63 92,34 86,15']
chains[18]=['19,88 12,65 15,42 29,21 51,9 77,15 90,36', '19,88 44,91 65,78 79,62 90,36', '15,42 34,46 46,29 68,32 90,36', '19,88 33,67 34,46', '33,67 54,58 79,62', '46,29 54,58']

identities=[
('항만 블록망','창고군 / 세관 / 선착장','운하 지하로 -4m, 하역 고가 +6m'),('U형 도크','건선거 / 정비동 / 화물역','도크 바닥 -6m, 양쪽 크레인 통로 +8m'),('이중 공장 고리','용광로 / 조립실 / 제어동','서비스 터널 -4m, 연결 데크 +6m'),('엇갈린 연구 캠퍼스','실험동 / 온실 / 자료실','지하 서비스 -4m, 실험동 2층 +5m'),('갈라진 협곡','관측소 / 암벽길 / 안테나동','협곡 -6m, 완만한 언덕 +8m'),('S형 운하 도시','수문 / 주택 / 하역장','수문 하부 -4m, 교량 +6m'),('갈래형 터미널','대합실 / 승강장 / 상가','지하 연결 -5m, 보행교 +6m'),('중정 세 개','회랑 / 카페 / 주택','배수로 -3m, 발코니 +4m'),('정비소 블록','작업장 / 부품실 / 차고','검사 피트 -3m, 사무실 +4m'),('굽은 구시가','상점 / 골목 / 주택','지하 창고 -3m, 옥상길 +5m'),('계단식 과수원','농가 / 테라스 / 저장고','저장고 -3m, 언덕 +5m'),('회전형 전력소','변전실 / 제어실 / 케이블실','케이블 지하 -4m, 점검대 +5m'),('불규칙 광장군','분수 / 아케이드 / 문화관','하부 통로 -3m, 회랑 +4m'),('물류 구획망','하역실 / 창고 / 검문소','하부 통로 -4m, 연결 데크 +5m'),('비대칭 쌍둥이 동','실험실 / 중정 / 격리동','저층 연결 -4m, 2층 +5m'),('접힌 공장 구역','압연실 / 작업장 / 보일러','보일러실 -4m, 크레인길 +6m'),('분리된 옥상군','아파트 / 사무실 / 계단실','골목 0m, 옥상 +5/+9m'),('환상 시장','시장 / 식당 / 창고','창고 지하 -3m, 상점 2층 +4m'),('갈래형 채석장','절개지 / 사무동 / 터널','터널 -5m, 언덕 +6/+10m')]
# Larger defusal layouts retain identity but add distinct outer circulation districts and rooms.
defdesc=[('성채와 시장','시장 / 주택 / 성벽길','시장 지하 -3m, 성벽 +5m'),('이중 원자로 고리','냉각실 / 제어실 / 원자로','서비스 지하 -5m, 제어층 +5m'),('갈라진 수로','교각 / 저지대 / 관리소','수로 -4m, 고가 +7m'),('기록동과 중정','서고 / 로비 / 열람실','서고 지하 -4m, 갤러리 +5m'),('부두와 선체','선체 / 창고 / 선착장','선체 하부 -4m, 갑판 +6m'),('계단식 수도원','회랑 / 예배당 / 정원','묘실 -4m, 언덕 +7m'),('대형 용광로 구역','원료장 / 주조실 / 제어동','정비 터널 -5m, 작업교 +7m'),('온실 연쇄','온실 / 연구동 / 저수조','배수실 -4m, 연결 데크 +5m'),('지하 역과 금고','승강장 / 보안실 / 지상 로비','지하 -6m, 연결층 -3m'),('해안 절벽 기지','관제동 / 차고 / 해안길','해안 -5m, 관제 데크 +8m'),('서버동 미로','서버홀 / 냉각실 / 사무동','전력 지하 -4m, 정비층 +5m'),('산성 테라스','외성 / 병영 / 내성','배수로 -4m, 성벽 +6/+10m')]
rects={0,2,8,13,25};specs=json.loads((r/'game/assets/arenas/defusal_specs.json').read_text())
result=[]
def coords(s):return [tuple(map(float,p.split(','))) for p in s.split()]
def polys(g):
 if g.is_empty:return []
 if g.geom_type=='Polygon':return [[list(g.exterior.coords),*[list(x.coords) for x in g.interiors]]]
 if hasattr(g,'geoms'):return sum((polys(x) for x in g.geoms),[])
 return []
for i,m in enumerate(old):
 # 1.4: compact footprints (about -25%) so every street can carry detailed
 # facades; objectives keep their normalized spacing.
 cap=m['players'];dim=(264,264) if cap==32 else (184,184) if cap==16 else (104,104) if cap==8 else (90,100)
 if 19<=i<31:dim=(112,140) if cap==8 else (184,220)
 if i==31:dim=(240,240)
 if i==31:
  paths=[coords(v) for v in ['50,92 28,84 14,64 22,42 15,19 40,10','50,92 52,72 46,50 54,30 40,10','50,92 80,84 90,62 77,43 85,20 63,12 40,10','22,42 46,50 77,43','28,84 52,72 80,84']];ident=('야외 훈련 캠퍼스','거리 사격 / 이동 표적 / 장비 실습','0m, +4m, +8m, +12m의 4개 높이')
 elif i<19:
  # 1.4: point-symmetric chains (layouts_v14) replace the 1.2.8 chains.
  paths=[coords(x) for x in layouts_v14.chains(i)];ident=identities[i]
 else:
  s=specs[str(i)];sx,sy=(32,40) if i<25 else (38,46)
  pts=[((p[0]/sx+1)*44+6,(p[1]/sy+1)*44+6) for p in s['points']]
  paths=[[pts[a],pts[b]] for a,b in s['links']]
  # New room chains through separate exterior districts and cross-connections.
  pa,pb=pts[2],pts[3];spawn=pts[0];defend=pts[1];k=i-19
  left=[spawn,(18,85),(9,68),(19,55),(10,36),(22,22),pa]
  right=[spawn,(81,84),(91,66),(79,52),(90,32),(76,17),pb]
  middle=[(19,55),(32,61),(43,50),(56,57),(68,44),(79,52)]
  if k%3==1:left=[spawn,(14,82),(13,57),(29,47),(14,28),pa];middle=[(29,47),(43,39),(56,57),(79,52)]
  if k%3==2:right=[spawn,(86,84),(88,60),(71,45),(87,22),pb];middle=[(19,55),(38,66),(54,47),(71,45)]
  paths.extend([left,right,middle,[pa,(33,13),defend,(68,10),pb]]);ident=defdesc[k]
 if i in LAYOUTS and i>=19:
  paths=[coords(x) for x in LAYOUTS[i]]
  if i>=19:
   pts=[paths[0][0],paths[0][-1],paths[0][max(1,len(paths[0])//2)],paths[1][max(1,len(paths[1])//2)]]
 # Convert normalized district coordinates to metre geometry; corridors keep human-scale widths.
 def world(p):return (p[0]*dim[0]/100,p[1]*dim[1]/100)
 paths=[[world(p) for p in chain] for chain in paths]
 width=(8 if cap==32 else 6 if cap==16 else 4.5 if cap==8 else 3.75) if i<19 or i==31 else (4.5 if cap==8 else 5.5)
 # Break long sightlines with offset vestibules; do not scale corridor widths with map area.
 authored_paths=paths
 bent=[]
 def half_turn(q):return (round(dim[0]-q[0],4),round(dim[1]-q[1],4))
 for ci,chain in enumerate(paths):
  new=[chain[0]]
  for ei,(a,b) in enumerate(zip(chain,chain[1:])):
   dx,dy=b[0]-a[0],b[1]-a[1];length=math.hypot(dx,dy)
   if length>(32 if cap>=16 else 24):
    if i<19:
     # A segment and its half-turn image bend identically (canonical orientation).
     ka=(round(a[0],3),round(a[1],3),round(b[0],3),round(b[1],3));ma,mb=half_turn(a),half_turn(b)
     candidates=[(a,b,False,False),(b,a,False,True),(ma,mb,True,False),(mb,ma,True,True)]
     ca,cb,mirrored,reverse=min(candidates,key=lambda c:(round(c[0][0],3),round(c[0][1],3),round(c[1][0],3),round(c[1][1],3)))
     cdx,cdy=cb[0]-ca[0],cb[1]-ca[1];sign=1 if int(abs(ca[0]*7.1+ca[1]*3.3+cb[0]*1.7+cb[1]*5.9))%2 else -1
     shift=(5.5 if cap>=16 else 3.5)*sign
     pts=[(ca[0]+cdx*t-cdy/length*shift,ca[1]+cdy*t+cdx/length*shift) for t in [.36,.67]]
     if mirrored:pts=[half_turn(q) for q in pts]
     if reverse:pts=pts[::-1]
     new.extend(pts)
    else:
     shift=(5.5 if cap>=16 else 3.5)*(1 if (ei+ci+i)%2 else -1)
     for t in [.36,.67]:new.append((a[0]+dx*t-dy/length*shift,a[1]+dy*t+dx/length*shift))
   new.append(b)
  bent.append(new)
 paths=bent
 # Bend points are passage corners, not additional oversized courtyards.
 rooms=list(dict.fromkeys(p for ch in authored_paths for p in ch));floors=[];ceiling_rooms=[]
 for chain in paths:floors.append(LineString(chain).buffer(width/2,join_style=2,cap_style=2))
 for j,(x,y) in enumerate(rooms):
  k=j
  if i<19:
   # Size by a hash of the canonical point so half-turn partners match.
   cx,cy=min((round(x,3),round(y,3)),(round(dim[0]-x,3),round(dim[1]-y,3)));k=int(abs(cx*13.7+cy*7.3))
  rw=(28 if cap==32 else 22 if cap==16 else 18 if cap==12 else 15 if cap==8 else 13)+(k%3)*2;rh=(24 if cap==32 else 20 if cap>=12 else 13 if cap==8 else 11)+(k%4)*1.5
  floors.append(box(x-rw/2,y-rh/2,x+rw/2,y+rh/2))
  if (j>1 if i>=19 else (x,y) not in (paths[0][0],paths[0][-1])) and k%3==1:ceiling_rooms.append([x-rw/2,y-rh/2,x+rw/2,y+rh/2])
 # Side buildings contain linked rooms and a second exit, rather than decorative solid boxes.
 districts=0
 base_rooms=list(dict.fromkeys(p for ch in authored_paths for p in ch))
 for j,(x,y) in enumerate(base_rooms):
  if i in LAYOUTS or i<19 or j<2 or j%2:continue
  vx,vy=dim[0]/2-x,dim[1]/2-y;length=max(1,math.hypot(vx,vy));vx/=length;vy/=length
  offset=20 if cap>=16 or cap==12 else 12;span=10 if cap>=16 or cap==12 else 6
  a=(x+vx*offset-vy*span,y+vy*offset+vx*span)
  b=(x+vx*(offset+span),y+vy*(offset+span))
  cc=(x+vx*offset+vy*span,y+vy*offset-vx*span)
  branch=[(x,y),a,b,cc,(x,y)]
  floors.append(LineString(branch).buffer(1.35,join_style=2,cap_style=2))
  for bx,by in [a,b,cc]:
   floors.append(box(bx-6,by-5,bx+6,by+5));ceiling_rooms.append([bx-6,by-5,bx+6,by+5])
  districts+=3
 floor=unary_union(floors).buffer(0)
 # Irregular perimeter follows connected districts rather than clipping rectangle corners.
 border=box(0,0,*dim) if i in rects else floor.buffer(7 if cap>=16 else 4,join_style=2).simplify(2,preserve_topology=True)
 if i<19:
  upper_chain,lower_chain,upper_height,lower_height=[],[],0.,0.
  up,low=layouts_v14.routes(i)
  if up:
   # A deck never turns sharply (a hairpin would fold the deck onto itself):
   # shrink the symmetric window until every interior turn is under 60 degrees.
   def turns(chain):
    worst=0.
    for a,b,c in zip(chain,chain[1:],chain[2:]):
     u=(b[0]-a[0],b[1]-a[1]);v=(c[0]-b[0],c[1]-b[1]);lu=math.hypot(*u);lv=math.hypot(*v)
     if lu<1e-6 or lv<1e-6:continue
     worst=max(worst,math.degrees(math.acos(max(-1.,min(1.,(u[0]*v[0]+u[1]*v[1])/lu/lv)))))
    return worst
   # Ramps also start on level ground: a ramp climbing a terrain slope adds
   # both gradients (too steep to walk).
   axis,stops,levels=layouts_v14.terrain(i)
   def ground(q):
    t=(q[0]/dim[0]) if axis=='x' else (q[1]/dim[1])
    for (s0,s1),(h0,h1) in zip(zip(stops,stops[1:]),zip(levels,levels[1:])):
     if s0<=t<=s1:return h0+(h1-h0)*(t-s0)/max(s1-s0,1e-9)
    return levels[-1]
   def ramps_level(chain):
    line=LineString(chain);run=min(abs(up[3])*3.5,line.length*.45)
    for d in [x*.5 for x in range(int(run*2)+1)]+[line.length-x*.5 for x in range(int(run*2)+1)]:
     a=line.interpolate(max(0.,d-.5));b=line.interpolate(min(line.length,d+.5))
     if abs(ground((a.x,a.y))-ground((b.x,b.y)))>.05:return False
    return True
   lo,hi=up[1],up[2]
   while True:
    upper_chain=list(_substring(LineString(paths[up[0]]),lo,hi,normalized=True).coords)
    if (turns(upper_chain)<60. and ramps_level(upper_chain)) or hi-lo<.2:break
    lo+=.01;hi-=.01
   upper_height=up[3]
   if turns(upper_chain)>=60. or not ramps_level(upper_chain) or LineString(upper_chain).length<abs(up[3])*7.5:upper_chain=[];upper_height=0.
  if low:lower_chain=list(_substring(LineString(paths[low[0]]),low[1],low[2],normalized=True).coords);lower_height=low[3]
 elif i<31:
  (upper_chain,upper_height),(lower_chain,lower_height)=vertical_routes(i,paths)
 else:upper_chain,lower_chain,upper_height,lower_height=paths[1],paths[0],4.2,-4.2
 if i not in BRIDGES and i!=31 and i>=19:upper_chain=[];lower_chain=[];upper_height=lower_height=0.
 upper=LineString(upper_chain).buffer(max(2.7,width*.70)/2,join_style=2) if upper_chain else Polygon()
 if upper_chain and i<19:
  # Ground passes beside each deck ramp: where a ramp is still low it blocks
  # the lane beneath it, which would otherwise cut the lane into an island.
  deck=LineString(upper_chain);run=min(abs(upper_height)*3.5,deck.length*.45)+2.
  for a,b in [(0.,run),(deck.length-run,deck.length)]:
   floor=unary_union([floor,_substring(deck,a,b).buffer(max(2.7,width*.70)/2+2.2,join_style=2)]).buffer(0)
  border=box(0,0,*dim) if i in rects else floor.buffer(7 if cap>=16 else 4,join_style=2).simplify(2,preserve_topology=True)
 lower=LineString(lower_chain).buffer(max(2.7,width*.65)/2,join_style=2) if lower_chain else Polygon()
 spawn=paths[0][0] if i<19 or i==31 else world(pts[0]);enemy=paths[0][-1] if i<19 or i==31 else world(pts[1])
 targets=[authored_paths[k][len(authored_paths[k])//2] for k in range(3)] if i<19 or i==31 else [world(pts[2]),world(pts[3])]
 if i<19:targets[2]=half_turn(targets[0])  # side objectives are half-turn partners
 item={'paths':paths,'upper_path':upper_chain,'lower_path':lower_chain,'id':i+1,'name':m['name'],'capacity':cap,'dimensions':dim,'rectangle':i in rects,'identity':ident,'floor':polys(floor),'border':polys(border),'upper':polys(upper),'lower':polys(lower),'stairs':[list(p) for chain in [upper_chain,lower_chain] if chain for p in [chain[0],chain[-1]]],'spawns':[spawn,enemy],'targets':targets,'corridor_m':width,'side_corridor_m':2.7,'rooms':len(rooms)+districts,'connected':floor.geom_type=='Polygon','mode':'연습장' if i==31 else '설치/해체' if i>=19 else '일반전'}
 result.append(item)
 item['ceiling_rooms']=ceiling_rooms
 item['terrain']=layouts_v14.terrain(i) if i<19 else TERRAIN.get(i,None);item['elevated_crossing']=i in BRIDGES or (i<19 and bool(upper_chain));item['authored_revision']=128
 item['upper_height']=upper_height;item['lower_height']=lower_height
 item['composition']='supported_crossing' if i in BRIDGES else 'grounded_terraces' if i in TERRAIN else 'rectangular_district' if i in RECTANGLES else 'practice_towers'
 item['stairs_enabled']=i in STAIR_MAPS
 item['identity']=('지형 단차 · 계단/경사 연결' if i in TERRAIN else '교각으로 지지한 고가 연결' if i in BRIDGES else '지상 구획과 실내외 동선' if i in RECTANGLES else '다층 야외 연습장')
assert all(m['connected'] for m in result)
assert len([m for m in result if m['rectangle']])==5
names=['항구','조선소','제철소','연구소','사막 기지','운하','중앙역','구시가지','정비 공장','산동네','과수원','발전소','분수 광장','물류 창고','실험 단지','폐공장','고층 빌딩','재래시장','채석장','요새','원전','수로교','도서관','폐선장','수도원','용광로','온실','지하 금고','해안 기지','서버 센터','산성','훈련장']
for m,name in zip(result,names):m['previous_name']=m['name'];m['name']=name
(out/'district_specs.json').write_text(json.dumps(result,ensure_ascii=False),encoding='utf-8')
print('32 proposed plans; all ground-route unions connected; rectangles exactly one per capacity.')
