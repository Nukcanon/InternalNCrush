"""Bake CC0 MakeHuman anatomy into the game's existing 15-joint rest pose.

Only mesh/target data is redistributed; no MakeHuman application code is used.
The input files, exact upstream revision and licenses are in assets/human/source.
This converter uses only Python's standard library and is reproducible offline.
"""
from pathlib import Path
import json, math

ROOT = Path(__file__).resolve().parents[1] / 'assets/human'
def add(a,b): return [x+y for x,y in zip(a,b)]
def sub(a,b): return [x-y for x,y in zip(a,b)]
def mul(a,s): return [x*s for x in a]
def dot(a,b): return sum(x*y for x,y in zip(a,b))
def length(a): return math.sqrt(dot(a,a))
def unit(a): return mul(a,1/max(length(a),1e-9))
def cross(a,b): return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def mix(a,b,t): return add(mul(a,1-t),mul(b,t))
def clamp(x): return max(0,min(1,x))
def smooth(a,b,x):
    t=clamp((x-a)/(b-a));return t*t*(3-2*t)
def rotate_to_down(v,axis):
    a=unit(axis);b=[0,-1,0];c=dot(a,b);k=cross(a,b)
    return add(add(v,cross(k,v)),mul(cross(k,cross(k,v)),1/max(1+c,1e-8)))

def bake(gender):
    vertices=[];faces=[];face_uvs=[];uvs=[];groups={};group=''
    for line in (ROOT/'source/base.obj').read_text().splitlines():
        fields=line.split()
        if not fields:continue
        if fields[0]=='v':vertices.append(list(map(float,fields[1:4])))
        elif fields[0]=='vt':uvs.append([float(fields[1]),1-float(fields[2])])
        elif fields[0]=='g':group=fields[1];groups.setdefault(group,set())
        elif fields[0]=='f':
            ids=[int(x.split('/')[0])-1 for x in fields[1:]];groups[group].update(ids)
            if group=='body':
                faces.append(ids);face_uvs.append([int(x.split('/')[1])-1 for x in fields[1:]])
    for name in [f'caucasian-{gender}-young.target',f'universal-{gender}-young-averagemuscle-averageweight.target']:
        for line in (ROOT/'source'/name).read_text().splitlines():
            f=line.split()
            if len(f)==4 and f[0].isdigit():vertices[int(f[0])]=add(vertices[int(f[0])],list(map(float,f[1:])))
    def joint(name):
        ids=groups['joint-'+name];return [sum(vertices[i][k] for i in ids)/len(ids) for k in range(3)]
    head=joint('head');neck=joint('neck');pelvis=joint('pelvis')
    segments={};dest={}
    shoulder_width=.195 if gender=='female' else .207
    arm_lift=.070 if gender=='female' else 0.
    for side,prefix,arm,leg in [(1,'l',6,12),(-1,'r',3,9)]:
        shoulder=joint(prefix+'-shoulder');elbow=joint(prefix+'-elbow');wrist=joint(prefix+'-hand');finger=joint(prefix+'-finger-3-2')
        hip=joint(prefix+'-upper-leg');knee=joint(prefix+'-knee');ankle=joint(prefix+'-ankle');toe=joint(prefix+'-foot-1')
        for bone,start,end,target,target_end in [(arm,shoulder,elbow,[side*shoulder_width,1.345+arm_lift,0],[side*shoulder_width,1.065+arm_lift,0]),(arm+1,elbow,wrist,[side*shoulder_width,1.065+arm_lift,0],[side*shoulder_width,.790+arm_lift,0]),(arm+2,wrist,finger,[side*shoulder_width,.790+arm_lift,0],[side*shoulder_width,.685+arm_lift,0]),(leg,hip,knee,[side*.099,.915,0],[side*.099,.5,0]),(leg+1,knee,ankle,[side*.099,.5,0],[side*.099,.085,0])]:
            segments[bone]=(start,end,target,target_end);dest[bone]=target
        dest[leg+2]=[side*.099,.085,0];segments[leg+2]=(ankle,toe,dest[leg+2],[side*.099,.02,-.13])
    def torso(v):
        knots=[(pelvis[1]-.8,.85),(pelvis[1],.94),(2.0,1.075),(4.33,1.29),(5.2458,1.37),(neck[1],1.49),(head[1],1.60)]
        y=v[1];ny=1.60+(y-head[1])*.1
        for (a,ta),(b,tb) in zip(knots,knots[1:]):
            if y<=b:ny=ta+(y-a)/(b-a)*(tb-ta);break
        hz=smooth(5.5,6.3,y);zcenter=.1*(1-hz)+head[2]*hz
        width=.095 if gender=='female' else .105
        nx=v[0]*(width*(1-hz)+.1*hz)
        if gender=='female':
            # Raise the clavicle and deltoid together with the arm rest pose.
            ny+=.065*smooth(1.12,1.34,ny)*(1-smooth(1.43,1.51,ny))*smooth(.035,.12,abs(nx))
        # Natural trapezius slope: neck stays high; outer deltoid sits lower.
        ny-=.026*smooth(.06,.20,abs(nx))*smooth(1.22,1.34,ny)*(1-smooth(1.41,1.49,ny))
        return [nx,ny,-(v[2]-zcenter)*.1]
    def transform(v,bone):
        if bone in [0,1,2]:return torso(v)
        a,b,t,u=segments[bone];axis=sub(b,a);rel=sub(v,a)
        if bone in [11,14]:
            return add(t,[rel[0]*.10,rel[1]*.10,-rel[2]*.10])
        along=dot(rel,unit(axis));perp=sub(rel,mul(unit(axis),along))
        mapped=rotate_to_down(perp,axis)
        # Source +Z is forward; Godot operator forward is -Z.
        mapped=[mapped[0]*.1,mapped[1]*.1,-mapped[2]*.1]
        return add(add(t,mapped),mul(sub(u,t),along/max(length(axis),1e-6)))
    def influence(v):
        x,y,z=v;side='l' if x>0 else 'r';arm=6 if x>0 else 3;leg=12 if x>0 else 9
        shoulder=joint(side+'-shoulder');elbow=joint(side+'-elbow');wrist=joint(side+'-hand');hip=joint(side+'-upper-leg');knee=joint(side+'-knee');ankle=joint(side+'-ankle')
        if y<hip[1]+.4 and (abs(x)<2.6 or y<-.5):
            if y<ankle[1]+.20:return [(leg+1,1-smooth(ankle[1]+.20,ankle[1]-.15,y)),(leg+2,smooth(ankle[1]+.20,ankle[1]-.15,y))]
            legweight=smooth(hip[1]+.40,hip[1]-.30,y)
            lower=smooth(knee[1]+.45,knee[1]-.45,y)
            return [(0,1-legweight),(leg,legweight*(1-lower)),(leg+1,legweight*lower)]
        if abs(x)>1.15 and y<5.85 and (y>1.7 or (abs(x)>2.6 and y>-.5)):
            upper=smooth(1.12,abs(shoulder[0])+.28,abs(x))
            # Project along the full limb to distinguish forearm from upper arm.
            a=segments[arm][0];b=segments[arm][1];t=dot(sub(v,a),unit(sub(b,a)))/length(sub(b,a))
            low=smooth(.80,1.15,t)
            a=segments[arm+1][0];b=segments[arm+1][1];t=dot(sub(v,a),unit(sub(b,a)))/length(sub(b,a))
            hand=smooth(.88,1.13,t)
            return [(1,1-upper),(arm,upper*(1-low)),(arm+1,upper*low*(1-hand)),(arm+2,upper*low*hand)]
        h=smooth(neck[1]-.15,neck[1]+.5,y);c=smooth(.7,2.7,y)
        return [(0,(1-c)*(1-h)),(1,c*(1-h)),(2,h)]
    used=sorted(groups['body']);mapping={v:i for i,v in enumerate(used)};points=[];weights=[];kinds=[];facial=[]
    for i in used:
        v=vertices[i];w=[(b,s) for b,s in influence(v) if s>.00001];weights.append(w)
        p=[0,0,0]
        for bone,weight in w:p=add(p,mul(transform(v,bone),weight))
        # Cover anatomy with tailored cloth, keeping real joint/limb contours.
        dominant=max(w,key=lambda q:q[1])[0]
        if dominant in [5,8]:kind=3
        elif dominant in [4,7] and p[1]<1.035:kind=0
        # Keep the whole jaw and upper neck as skin. A narrow neck cylinder
        # clipped the projecting chin and relaxed it into the shirt surface.
        elif dominant==2 or p[1]>1.49 or (p[1]>1.47 and abs(p[0])<.061 and abs(p[2])<.059):kind=0
        elif p[1]<1.025 and dominant not in [3,4,5,6,7,8]:kind=2
        else:kind=1
        if dominant in [11,14]:kind=4
        points.append(p);kinds.append(kind)
        facial.append([round(v[0]*.1,6),round((v[1]-head[1])*.1,6),round(-(v[2]-head[2])*.1,6)])
    adjacency=[set() for _ in points]
    for face in faces:
        for a,b in zip(face,face[1:]+face[:1]):adjacency[mapping[a]].add(mapping[b]);adjacency[mapping[b]].add(mapping[a])
    # Relax the clothing surface over muscles, then add a small fabric allowance.
    for _ in range(6):
        previous=points[:]
        for i,p in enumerate(previous):
            if kinds[i] in [1,2] and adjacency[i]:
                avg=[sum(previous[j][k] for j in adjacency[i])/len(adjacency[i]) for k in range(3)]
                points[i]=mix(p,avg,.35)
    triangles=[];triangle_uvs=[]
    for face,face_uv in zip(faces,face_uvs):
        ids=[mapping[i] for i in face]
        for j in range(1,len(ids)-1):
            triangles.append([ids[0],ids[j],ids[j+1]])
            triangle_uvs.append([uvs[face_uv[k]] for k in [0,j,j+1]])
    normals=[[0.,0.,0.] for p in points]
    for a,b,c in triangles:
        normal=cross(sub(points[b],points[a]),sub(points[c],points[a]))
        # Axis reflection changed winding; these point inward until inverted.
        for i in [a,b,c]:normals[i]=sub(normals[i],normal)
    normals=[unit(n) for n in normals]
    for i in range(len(points)):
        if kinds[i] in [1,2]:
            p=points[i];allowance=.009 if kinds[i]==1 else .011
            # Subtle, nonperiodic fold bands at elbow, waist, knee and ankle.
            fold=sum(math.exp(-((p[1]-y)/.045)**2) for y in [.12,.47,.56,1.04,1.11])
            allowance+=.0035*fold*math.sin(p[1]*95+p[0]*17+p[2]*22)
            points[i]=add(p,mul(normals[i],allowance))
    # Godot clockwise winding is the same index order after reflecting Z.
    result={'vertices':[[round(x,6) for x in p] for p in points],'faces':triangles,'weights':[[[b,round(w,6)] for b,w in q] for q in weights],'kinds':kinds,'face_coordinates':facial,'eyes':[]}
    result['face_uvs']=triangle_uvs
    for side in ['r','l']:
        p=torso(joint(side+'-eye'));result['eyes'].append([round(p[0],6),round(p[1]-1.6,6),round(p[2],6)])
    (ROOT/f'{gender}.json').write_text(json.dumps(result,separators=(',',':')))
    print(gender,len(points),'vertices',len(triangles),'triangles',result['eyes'])
if __name__=='__main__':
    for gender in ['male','female']:bake(gender)
    male=json.loads((ROOT/'male.json').read_text())
    female=json.loads((ROOT/'female.json').read_text())
    for i,body in enumerate(male['vertices']):
        weight=smooth(1.53,1.60,body[1])
        female['vertices'][i]=[round(v,6) for v in mix(body,female['vertices'][i],weight)]
        female['weights'][i]=male['weights'][i]
        female['kinds'][i]=male['kinds'][i]
    (ROOT/'female.json').write_text(json.dumps(female,separators=(',',':')))
    print('Female: male body/neck/shoulders and skin weights; female face above jaw')
