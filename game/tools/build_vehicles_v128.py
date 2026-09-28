"""Thirty original, metre-scaled vehicles and vessels. Blender background entry.

Opaque vertex-colour material; wheels, windows and equipment are geometry.
No downloaded source, texture dependencies or paid provider. Z up in Blender.
"""
import sys, pathlib, math, json
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
import build_themed_props as a
import bpy

ROOT=pathlib.Path(__file__).resolve().parents[1]
a.OUT=ROOT/'assets/models/transport_original'
a.SOURCE=ROOT.parent/'art_source/transport_original'
a.OUT.mkdir(parents=True,exist_ok=True);a.SOURCE.mkdir(parents=True,exist_ok=True)
P=a.part;C=a.cylinder
GLASS=(.08,.19,.23,1); RUBBER=(.035,.045,.05,1)

def wheel(x,y,r=.34):
    C('Tyre',(x,y,r),r,.22,RUBBER,(0,math.pi/2,0),12)
    C('Wheel hub',(x+(.12 if x>0 else -.12),y,r),r*.52,.03,'cream',(0,math.pi/2,0),10)

def cabin(width,length,height,cy,z,paint):
    P('Cabin',(0,cy,z),(width,length,height),paint,.13)
    P('Windshield',(0,cy-length*.5-.012,z+.10),(width*.82,.028,height*.59),GLASS,.04)
    P('Rear window',(0,cy+length*.5+.012,z+.10),(width*.75,.028,height*.54),GLASS,.025)
    for x in [-1,1]:
        P('Side glazing',(x*(width*.5+.015),cy,z+.10),(.025,length*.77,height*.55),GLASS,.025)
        P('Window pillar',(x*(width*.5+.034),cy,z+.10),(.025,.065,height*.63),paint)
        P('Door handle',(x*(width*.5+.04),cy+.28,z-.22),(.045,.17,.04),'cream')
        P('Mirror',(x*(width*.5+.15),cy-length*.32,z+.02),(.22,.22,.13),paint,.03)

def vehicle(style,length,width=1.8,paint='green'):
    truck=style not in ['compact','hatch','sedan','estate','taxi','utility','pickup','van','minibus','ambulance']
    radius=.43 if truck else .34
    P('Chassis',(0,0,.58),(width*.87,length,.28),'metal',.06)
    P('Body',(0,0,.85),(width,length*.94,.59),paint,.11)
    axle_y=[-length*.31,length*.30]
    if length>6.4:axle_y.append(length*.13)
    for y in axle_y:
        for side in [-1,1]:wheel(side*width*.5,y,radius)
    for y in [-length*.48,length*.48]:
        P('Bumper',(0,y,.61),(width*1.02,.16,.18),'cream',.025)
        for side in [-1,1]:P('Lamp',(side*width*.35,y*1.025,.92),(width*.21,.06,.15),'cream' if y<0 else 'red',.02)
    P('Grille',(0,-length*.482,.81),(width*.38,.045,.24),'metal')
    for x in [-.24,-.12,0,.12,.24]:P('Grille slat',(x,-length*.508,.81),(.022,.022,.22),'cream')
    if truck:
        cabin(width*.94,1.65,1.3,-length*.32,1.69,paint)
        bed_y=length*.12;bed_l=length*.60
        P('Flatbed',(0,bed_y,1.13),(width,bed_l,.14),'edge',.02)
        if style in ['box','reefer','delivery']:
            P('Cargo enclosure',(0,bed_y,2.0),(width*.98,bed_l,1.7),'cream',.06)
            for x in [-1,1]:
                for y in range(6):P('Cargo ribs',(x*width*.5,bed_y-bed_l*.4+y*bed_l*.16,2.0),(.035,.035,1.55),'metal')
            P('Rear doors',(0,bed_y+bed_l*.5+.02,1.98),(width*.88,.05,1.5),paint)
            for x in [-.20,.20]:P('Locking rods',(x,bed_y+bed_l*.5+.065,2.0),(.04,.04,1.35),'cream')
            if style=='reefer':P('Cooling unit',(0,bed_y-bed_l*.5-.2,2.4),(1.1,.35,.65),'metal',.04)
        elif style=='tanker':
            C('Tank',(0,bed_y,1.86),width*.46,bed_l,'cream',(math.pi/2,0,0),16)
            for y in [bed_y-bed_l*.3,bed_y+bed_l*.3]:
                C('Tank hoop',(0,y,1.86),width*.475,.08,'metal',(math.pi/2,0,0),16)
            C('Filler',(0,bed_y,2.83),.20,.16,'metal')
        elif style in ['dump','refuse']:
            for x in [-1,1]:P('Hopper side',(x*width*.47,bed_y,1.65),(.12,bed_l,1.1),paint,.02)
            for y in [bed_y-bed_l*.48,bed_y+bed_l*.48]:P('Hopper end',(0,y,1.65),(width,.12,1.1),paint,.02)
            if style=='refuse':P('Compactor',(0,bed_y,2.),(width*.75,bed_l*.5,.55),'cream',.15)
        elif style in ['crane','tow']:
            C('Turntable',(0,bed_y,1.35),.5,.3,'metal')
            P('Boom upright',(0,bed_y,2.1),(.3,.35,1.6),'gold',.035)
            o=P('Boom',(0,bed_y+.75,2.8),(.28,2.1,.28),'gold',.035);o.rotation_euler.x=-.24
            C('Hoist cable',(0,bed_y+1.65,2.1),.025,.9,'metal',segments=6)
            P('Hook',(0,bed_y+1.65,1.63),(.20,.12,.15),'metal')
        elif style=='fire':
            P('Equipment lockers',(0,bed_y,1.65),(width*.96,bed_l,1.0),'red',.03)
            for y in [bed_y-.8,bed_y,bed_y+.8]:
                for x in [-1,1]:P('Locker door',(x*width*.49,y,1.65),(.04,.66,.72),'cream',.015)
            for x in [-.33,.33]:P('Ladder rail',(x,bed_y,2.3),(.07,bed_l,.08),'cream')
            for k in range(12):P('Ladder rung',(0,bed_y-bed_l*.45+k*bed_l*.08,2.3),(.66,.045,.05),'cream')
        else:
            for y in [bed_y-.7,bed_y+.7]:P('Cargo stack',(0,y,1.55),(width*.78,1.1,.72),'wood',.025)
    else:
        long_roof=style in ['estate','van','minibus','ambulance','utility']
        cab_l=length*(.65 if long_roof else .49)
        cab_h=1.15 if style in ['van','minibus','ambulance'] else .80
        cabin(width*.91,cab_l,cab_h,-.15 if style=='pickup' else .05,1.15+cab_h*.5,paint)
        if style=='pickup':
            for x in [-1,1]:P('Pickup bed rail',(x*width*.45,length*.32,1.24),(.13,length*.32,.33),paint)
        if style in ['taxi','ambulance']:
            P('Roof sign',(0,0,1.25+cab_h),(.7,.35,.18),'gold' if style=='taxi' else 'red',.03)
        if style=='utility':
            for x in [-.55,.55]:P('Roof rack',(x,0,2.10),(.065,2.1,.08),'metal')
        if style=='minibus':
            for side in [-1,1]:
                for y in [-1.,0,1.]:P('Bus window pillar',(side*width*.47,y,1.87),(.04,.075,.65),paint)

def hull(width,length,depth):
    # Pointed bow, broad transom and a narrowing keel, not a rectangular slab.
    top=[(-width*.5,length*.45,depth),(width*.5,length*.45,depth),(width*.5,-length*.28,depth),(0,-length*.55,depth),(-width*.5,-length*.28,depth)]
    bottom=[(x*.58,y*.85,-depth*.32) for x,y,z in top]
    verts=top+bottom;faces=[tuple(range(5)),tuple(range(9,4,-1))]
    faces += [(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)]
    mesh=bpy.data.meshes.new('Hull');mesh.from_pydata(verts,[],faces);mesh.update()
    ob=bpy.data.objects.new('Hull',mesh);bpy.context.collection.objects.link(ob)
    colors=mesh.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for d in colors.data:d.color=(.10,.30,.35,1)

def vessel(style,length,width):
    depth=.50 if length<6 else .85
    hull(width,length,depth)
    P('Deck',(0,length*.05,depth+.035),(width*.84,length*.61,.08),'edge')
    if style in ['rowboat','canoe','skiff']:
        for y in [-length*.17,length*.16]:P('Thwart',(0,y,depth+.18),(width*.88,.27,.12),'wood',.015)
        for side in [-1,1]:P('Oar',(side*width*.54,0,depth+.24),(.045,length*.70,.045),'cream')
    else:
        cy=length*.16 if style in ['fishing','trawler'] else -length*.16
        if style not in ['barge','pontoon']:
            cabin(width*.68,length*.24,1.05,cy,depth+.65,'cream')
            C('Mast',(0,cy,depth+2.),.055,1.4,'metal',segments=8)
        for side in [-1,1]:
            for j in range(5):C('Railing post',(side*width*.45,-length*.24+j*length*.15,depth+.32),.028,.60,'cream',segments=6)
            P('Handrail',(side*width*.45,length*.06,depth+.63),(.045,length*.62,.045),'cream')
        if style in ['fishing','trawler']:
            for x in [-width*.23,width*.23]:
                P('Fishing crate',(x,-length*.12,depth+.25),(.6,.7,.4),'blue')
            C('Net drum',(0,length*.30,depth+.5),.34,width*.55,'green',(0,math.pi/2,0),10)
        elif style=='tug':
            for side in [-1,1]:
                for y in [-length*.20,0,length*.22]:C('Fender',(side*width*.51,y,depth),.27,.18,RUBBER,(0,math.pi/2,0),10)
            C('Exhaust',(width*.20,cy,depth+1.75),.13,1.1,'red',segments=10)
        elif style=='barge':
            for y in [-length*.2,length*.1]:P('Freight container',(0,y,depth+.8),(width*.73,length*.25,1.5),'red',.025)
        elif style=='rescue':
            for side in [-1,1]:C('Rescue float',(side*width*.40,0,depth+.13),.21,length*.65,'red',(math.pi/2,0,0),10)
        elif style=='ferry':
            for y in [-length*.10,length*.05,length*.25]:P('Passenger bench',(0,y,depth+.38),(width*.7,.34,.14),'green')
        elif style=='pontoon':
            for x in [-width*.35,width*.35]:C('Pontoon',(x,0,0),.35,length*.87,'metal',(math.pi/2,0,0),12)
        elif style=='sailboat':
            C('Sail mast',(0,0,depth+2.),.06,4.,'wood',segments=8)
            P('Furled sail',(0,0,depth+2.1),(.18,.20,3.6),'cream')

CARS=[('compact',3.25,1.55),('hatch',3.8,1.72),('sedan',4.45,1.82),('estate',4.8,1.84),('taxi',4.55,1.84),('utility',4.2,1.92),('pickup',5.1,1.95),('van',5.2,2.),('minibus',6.0,2.15),('ambulance',5.8,2.15)]
TRUCKS=[('flatbed',6.,2.3),('box',6.3,2.3),('reefer',6.6,2.4),('delivery',5.8,2.2),('tanker',7.4,2.5),('dump',6.4,2.5),('refuse',7.,2.5),('crane',7.4,2.5),('tow',6.8,2.4),('fire',7.8,2.5)]
BOATS=[('rowboat',3.2,1.3),('canoe',4.2,.9),('skiff',4.8,1.8),('rescue',5.5,2.1),('fishing',7.2,2.6),('trawler',10.,3.5),('tug',9.,3.8),('barge',13.,4.5),('ferry',11.,3.7),('pontoon',6.,2.8)]
if __name__=='__main__':
    records=[]
    for i,(style,length,width) in enumerate(CARS+TRUCKS):
        paint=['green','cream','blue','red','gold'][i%5]
        row=a.export('vehicle_'+style,lambda s=style,l=length,w=width,c=paint:vehicle(s,l,w,c))
        row.update(category='road',length_m=length,width_m=width);records.append(row)
    for style,length,width in BOATS:
        row=a.export('vessel_'+style,lambda s=style,l=length,w=width:vessel(s,l,w))
        row.update(category='river' if length<6.1 else 'sea',length_m=length,width_m=width);records.append(row)
    (a.OUT/'manifest.json').write_text(json.dumps({'provenance':'Original Blender authored transport; no third-party sources','assets':records},indent=2))
    print('TRANSPORT_COMPLETE',len(records))
