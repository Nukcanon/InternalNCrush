"""Check wall contact behind every authored window/light anchor, on all maps."""
from pathlib import Path
import json, math
import numpy as np
ROOT = Path(__file__).resolve().parents[3]

def supported(tris, point, outward):
    # Cast toward the wall from 15 cm outside. Both triangle sides are valid.
    origin = np.array(point) + outward * .15
    direction = -outward
    edge1 = tris[:, 1] - tris[:, 0]
    edge2 = tris[:, 2] - tris[:, 0]
    h = np.cross(np.broadcast_to(direction, edge2.shape), edge2)
    det = np.einsum('ij,ij->i', edge1, h)
    inv = np.divide(1., det, out=np.zeros_like(det), where=np.abs(det)>1e-9)
    s = origin - tris[:, 0]
    u = inv * np.einsum('ij,ij->i', s, h)
    q = np.cross(s, edge1)
    v = inv * q.dot(direction)
    t = inv * np.einsum('ij,ij->i', edge2, q)
    return bool(np.any((np.abs(det)>1e-9)&(u>=-1e-5)&(v>=-1e-5)&(u+v<=1.00001)&(t>=0)&(t<=.20)))

def audit(data):
    triangles = np.array([v for g in data['groups'] if g['kind'] in ['wall','perimeter','quay_edge','tunnel'] for v in g['vertices']],dtype=float).reshape(-1,3,3)
    failures=[]
    for i,f in enumerate(data['facades']):
        n=np.array([math.sin(f[2]),0,math.cos(f[2])]); right=np.array([math.cos(f[2]),0,-math.sin(f[2])])
        base=np.array([f[0],f[4],f[1]],dtype=float)
        tests=[(x,y) for x in [-2.60,-1.65,-.70,.70,1.65,2.60] for y in [.87,2.67]]+[(0.,2.45)]
        missing=[(x,y) for x,y in tests if not supported(triangles,base+right*x+np.array([0,y,0]),n)]
        if missing:failures.append({'index':i,'anchor':f,'missing':missing})
    return failures

if __name__=='__main__':
    reports=[]
    for index in range(32):
        data=json.loads((ROOT/f'game/assets/arenas/districts/map_{index:02d}.json').read_text(encoding='utf-8'))
        failures=audit(data);reports.append({'map':index,'facades':len(data['facades']),'unsupported':failures})
        print(index,'facades',len(data['facades']),'unsupported',len(failures),flush=True)
    output=ROOT/'validation/facade-support.json';output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(reports,indent=2),encoding='utf-8')
