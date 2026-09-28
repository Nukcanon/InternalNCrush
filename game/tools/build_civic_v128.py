"""Original facade windows and trees; one opaque vertex-colour mesh each."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_themed_props as a
ROOT=Path(__file__).resolve().parents[1]
def painted(obj,color):
 attr=obj.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
 for c in attr.data:c.color=a.COL.get(color,color)
 return obj
def branch(p,q,r,color='wood'):
 d=Vector(q)-Vector(p);o=a.cylinder('Connected branch',(Vector(p)+Vector(q))/2,r,d.length,color,segments=7);o.rotation_euler=d.to_track_quat('Z','Y').to_euler();return o
def crown(p,size,color):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=p);o=bpy.context.object;o.name='Leaf crown';o.scale=size;painted(o,color)
def window(family,variant):
 width=[1.20,1.45,1.8,2.1,1.05][variant];height=[1.65,1.35,1.6,1.15,1.95][variant]
 if family in [4,5,6]:width*=1.2
 frame=['cream','wood','edge','cream','metal','blue','cream','green'][family]
 a.part('Opaque glazing',(0,0,height/2),(width,.055,height),(.06,.15,.19,1))
 # Complete four-sided frame, in front of glazing. Shutters have a gap.
 for x in [-1,1]:a.part('Jamb',(x*(width/2+.045),-.055,height/2),(.09,.13,height+.18),frame,.012)
 for z in [-.045,height+.045]:a.part('Header sill',(0,-.055,z),(width,.13,.09),frame,.012)
 columns=1+variant%3 if family!=7 else 4
 rows=2 if family in [0,2,4,6] else 3 if family==7 else 1
 for j in range(1,columns):a.part('Mullion',(-width/2+width*j/columns,-.07,height/2),(.045,.10,height),frame)
 for j in range(1,rows):a.part('Transom',(0,-.07,height*j/rows),(width,.10,.045),frame)
 if family in [0,1,2]:
  for sign in [-1,1]:
   x=sign*(width/2+.28);a.part('Shutter',(x,.03,height/2),(.30,.07,height),'edge',.012)
   for j in range(4+variant):a.part('Shutter slat',(x,-.012,.10+j*(height-.2)/(3+variant)),(.26,.015,.027),'wood')
 if family==2:
  for j in range(9):
   x=-width/2+width*(j+.5)/9;rise=.28*math.sin(math.pi*(j+.5)/9)
   a.part('Stepped arch',(x,0,height+.15+rise),(width/9+.001,.15,.16),frame)
 if family==3:
  a.part('Deep sill',(0,-.14,-.13),(width+.28,.32,.12),'cream',.015)
  for j in range(3):a.part('Planter',(width*(j-1)*.28,-.18,-.03),(.22,.22,.14),'wood')
 if family==4:
  for j in range(4):a.part('Factory glazing brace',(0,-.07,height*j/4),(width,.05,.025),'metal')
 if family==5:
  a.part('Sun hood',(0,-.20,height+.20),(width+.30,.50,.07),'metal')
  for sign in [-1,1]:a.part('Hood bracket',(sign*width*.4,-.12,height+.07),(.045,.2,.25),'metal')
 if family==6:
  a.part('Observation blind housing',(0,-.10,height+.17),(width+.2,.22,.15),'cream',.02)
 if family==7:
  for sign in [-1,1]:a.part('Recess reveal',(sign*(width/2+.14),0,height/2),(.13,.22,height+.4),'cream',.02)
def tree(species,age):
 height=[2.2,4.4,6.5][age]*(.8 if species in [6,9] else 1.)
 radius=[.07,.15,.23][age];branch((0,0,0),(.08,0,height*.68),radius)
 green=[(.12,.30,.055,1),(.18,.40,.075,1),(.23,.35,.07,1)][age]
 if species in [1,2]:
  for j in range(4+age):
   z=height*.28+j*height*.12;r=height*.30*(1-j/(6+age))
   bpy.ops.mesh.primitive_cone_add(vertices=9,radius1=r,radius2=.03,depth=height*.30,location=(0,0,z));painted(bpy.context.object,green)
 elif species==3:
  for j in range(8):
   angle=j*math.tau/8;p=(math.cos(angle)*height*.26,math.sin(angle)*height*.26,height*.75)
   branch((0,0,height*.7),p,radius*.30);crown(p,(height*.14,height*.14,height*.22),green)
 elif species==4:
  for j in range(7):
   angle=j*math.tau/7;p=(math.cos(angle)*height*.20,math.sin(angle)*height*.20,height*.65)
   branch((0,0,height*.55),p,radius*.4);crown(p,(height*.20,height*.20,height*.33),green)
 elif species==5:
  for j in range(8):
   angle=j*math.tau/8;p=(math.cos(angle)*height*.33,math.sin(angle)*height*.33,height*.91)
   branch((0,0,height*.85),p,radius*.35,'green');crown(p,(height*.25,height*.10,height*.055),green)
 else:
  for j in range(5+age):
   angle=j*2.399;z=height*(.50+.055*(j%4));p=(math.cos(angle)*height*.19,math.sin(angle)*height*.19,z)
   branch((0,0,height*.40),p,radius*.45);size=height*(.21 if species==7 else .25)
   col=(.42,.24,.055,1) if species==8 else (.5,.30,.35,1) if species==9 else green
   crown(p,(size,size,size*(.65 if species==7 else .95)),col)
  crown((0,0,height*.82),(height*.21,height*.21,height*.2),green)
 if species==6:
  for j in range(8):
   angle=j*2.399;crown((math.cos(angle)*height*.2,math.sin(angle)*height*.2,height*.65),(.07,.07,.07),(.65,.10,.03,1))
if __name__=='__main__':
 packs=[('windows_original',40,lambda i:window(i//5,i%5)),('trees_original',30,lambda i:tree(i//3,i%3)),('windows_web',40,lambda i:window(i//5,i%5))]
 if '--web-only' in sys.argv:packs=packs[-1:]
 for pack,total,fn in packs:
  if pack=='windows_web':
   original_part=a.part
   a.part=lambda name,pos,size,color,bevel=0:original_part(name,pos,size,color,0)
  a.OUT=ROOT/'assets/models'/pack;a.SOURCE=ROOT.parent/'art_source'/pack;a.OUT.mkdir(parents=True,exist_ok=True);a.SOURCE.mkdir(parents=True,exist_ok=True)
  rows=[]
  for i in range(total):
   name=('window_' if pack.startswith('windows') else 'tree_')+f'{i:02d}';row=a.export(name,lambda i=i:fn(i));rows.append(row)
  (a.OUT/'manifest.json').write_text(json.dumps({'provenance':'Original local Blender construction; no third-party inputs','assets':rows},indent=2))
  print('CIVIC_MODELS_COMPLETE',pack,total)
