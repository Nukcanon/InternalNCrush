"""Inspect all exported map triangles for degenerate/duplicate faces and tile leaks."""
import json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
reports=[]
for index in range(32):
 data=json.loads((ROOT/f'game/assets/arenas/districts/map_{index:02d}.json').read_text(encoding='utf-8'))
 seen=set();duplicates=0;degenerate=0;outside=0;count=0;kinds={}
 for group in data['groups']:
  kind=group['kind'];verts=group['vertices'];origin=group['origin']
  kinds[kind]=kinds.get(kind,0)+len(verts)//3
  for i in range(0,len(verts),3):
   points=verts[i:i+3];count+=1
   a,b,c=points;u=[b[j]-a[j] for j in range(3)];v=[c[j]-a[j] for j in range(3)]
   cross=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
   if sum(n*n for n in cross)<1e-14:degenerate+=1
   key=tuple(sorted(tuple(p) for p in points))
   if key in seen:duplicates+=1
   seen.add(key)
   if kind!='water' and any(abs(p[0]-origin[0])>12.0002 or abs(p[2]-origin[2])>12.0002 for p in points):outside+=1
 indoor=data.get('ceiling_height',0)>0
 assert not indoor or not kinds.get('soffit',0),(index,'indoor eaves')
 assert index!=16 or indoor,'high-rise must have an interior ceiling'
 reports.append(dict(map=index,name=data['name'],triangles=count,duplicates=duplicates,degenerate=degenerate,tile_leaks=outside,slivers_removed=len(data.get('removed_sliver_islands',[])),indoor=indoor,roof_triangles=kinds.get('roof',0),ceiling_triangles=kinds.get('ceiling',0),soffit_triangles=kinds.get('soffit',0)))
print(json.dumps(reports,ensure_ascii=False,indent=2))
assert not any(r['duplicates'] or r['degenerate'] or r['tile_leaks'] for r in reports),'Invalid map triangles'
print('SURFACE_AUDIT_PASS 32 maps')
