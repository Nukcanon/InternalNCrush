"""Original Blender-authored environment props. Run with Blender --background --python.

One mesh/material per exported prop, opaque vertex palette, no external textures.
Centimetre-scale bevels and material colour variation are baked into geometry.
"""
import bpy, json, math, pathlib, random
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/models/district_original'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT.parent / 'art_source/district_original'
SOURCE.mkdir(parents=True, exist_ok=True)
random.seed(128)
COL = {'wood':(.30,.13,.055,1), 'edge':(.56,.32,.14,1),
       'metal':(.09,.14,.17,1), 'cream':(.78,.70,.50,1),
       'green':(.12,.40,.22,1), 'red':(.65,.12,.055,1),
       'gold':(.85,.51,.09,1), 'blue':(.055,.25,.38,1)}

def part(name, pos, size, color, bevel=0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    o=bpy.context.object; o.name=name; o.dimensions=size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        m=o.modifiers.new('Edge highlights','BEVEL'); m.width=bevel; m.segments=1
        bpy.ops.object.modifier_apply(modifier=m.name)
    colors=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    c=COL.get(color,color)
    for d in colors.data: d.color=c
    return o

def start():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)

def cylinder(name,pos,radius,depth,color,rotation=(0,0,0),segments=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=segments,radius=radius,depth=depth,location=pos,rotation=rotation)
    o=bpy.context.object;o.name=name
    attr=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for c in attr.data:c.color=COL.get(color,color)
    return o

def pump():
    part('Concrete plinth',(0,0,.12),(2.1,1.2,.24),'cream',.035)
    part('Pump casing',(-.38,0,.62),(.82,.69,.83),'blue',.075)
    cylinder('Motor',(.38,0,.62),.25,.78,'metal',(0,math.pi/2,0))
    for x in [.1,.22,.34,.46,.58,.70]:cylinder('Motor cooling fin',(x,0,.62),.28,.035,'blue',(0,math.pi/2,0))
    for x in [-.65,.65]:
        cylinder('Pipe',(x,.43,.73),.10,1.3,'green')
        cylinder('Pipe flange',(x,.43,1.15),.18,.075,'metal')
        part('Pipe mounting',(x,.43,.28),(.28,.28,.12),'metal')
    cylinder('Gauge face',(-.38,-.36,.90),.12,.04,'cream',(math.pi/2,0,0))
    part('Gauge needle',(-.38,-.385,.92),(.015,.015,.11),'red')

def work_cart():
    for x in [-.72,.72]:
        for y in [-.43,.43]:cylinder('Rubber wheel',(x,y,.20),.19,.10,'metal',(math.pi/2,0,0))
    part('Chassis',(0,0,.35),(1.75,.95,.13),'metal',.025)
    for z in [.48,1.04]:part('Tool tray',(0,0,z),(1.8,.95,.085),'gold',.01)
    for x in [-.82,.82]:
        for y in [-.42,.42]:part('Frame',(x,y,.76),(.045,.045,.92),'metal')
        part('Handle',(x,0,1.21),(.07,.95,.055),'metal',.012)
    part('Tool box',(-.28,0,1.24),(.69,.47,.31),'red',.025)
    part('Box latch',(-.28,-.25,1.24),(.10,.03,.12),'cream')
    for x in [.23,.40,.57]:part('Wrench',(x,-.02,1.11),(.055,.58,.025),'cream',.006)

def planter():
    part('Stone planter',(0,0,.31),(2.3,1.05,.62),'cream',.05)
    part('Earth',(0,0,.635),(2.08,.84,.02),'wood')
    for x in [-.80,-.40,0,.40,.80]:
        cylinder('Stem',(x,0,.95),.025,.64,'wood',segments=6)
        for k in range(3):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.32,location=(x,(-.13 if k%2 else .12),.92+k*.15))
            o=bpy.context.object;o.scale=(.8,1,.65)
            attr=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
            for c in attr.data:c.color=COL['green'] if k%2 else (.25,.49,.12,1)

def reading_desk():
    part('Desktop',(0,0,.83),(2.25,1.15,.10),'edge',.025)
    for x in [-.9,.9]:
        for y in [-.4,.4]:part('Table leg',(x,y,.42),(.10,.10,.84),'wood',.008)
    part('Center divider',(0,.32,1.05),(2.14,.065,.34),'wood')
    for x in [-.55,.55]:
        part('Open book',(x,-.14,.91),(.48,.36,.045),'cream')
        part('Book spine',(x,-.14,.935),(.012,.36,.018),'wood')
        cylinder('Lamp base',(x,.19,.92),.13,.06,'metal')
        cylinder('Lamp neck',(x,.19,1.12),.02,.40,'metal',segments=8)
        part('Green lamp shade',(x,.15,1.34),(.43,.23,.13),'green',.04)

def dock_supply():
    part('Rescue cabinet',(0,0,.77),(1.35,.42,1.45),'red',.04)
    part('Recess',(0,-.23,.9),(1.16,.04,.99),'cream',.015)
    bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=6,location=(0,-.31,.94),rotation=(math.pi/2,0,0),major_radius=.34,minor_radius=.095)
    o=bpy.context.object;o.name='Life ring';a=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for p in o.data.polygons:
        col=COL['cream'] if abs(p.center.x)<.1 else COL['gold']
        for loop in p.loop_indices:a.data[loop].color=col
    for x in [-.46,.46]:part('Cabinet foot',(x,0,.08),(.13,.46,.16),'metal')

def bench():
    for x in [-.85,.85]:
        for y in [-.25,.25]:part('Bench legs',(x,y,.26),(.085,.085,.52),'metal')
        part('Back support',(x,.28,.68),(.08,.08,1.12),'metal')
    for j in range(5):part('Seat slat',(0,-.24+j*.12,.52),(2.1,.10,.065),'edge',.008)
    for j in range(3):part('Backrest slat',(0,.29,.76+j*.15),(2.1,.065,.12),'wood',.008)

def cafe():
    cylinder('Table foot',(0,0,.08),.35,.12,'metal')
    cylinder('Table stem',(0,0,.56),.05,1.,'metal')
    cylinder('Round table',(0,0,.95),.75,.08,'wood',segments=16)
    cylinder('Parasol pole',(0,0,1.4),.025,2.8,'cream',segments=8)
    bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=1.18,radius2=.1,depth=.38,location=(0,0,2.6))
    o=bpy.context.object;o.name='Octagonal parasol';a=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
    for p in o.data.polygons:
        for loop in p.loop_indices:a.data[loop].color=COL['red' if p.index%2 else 'cream']
    for x in [-.34,.34]:cylinder('Cup',(x,0,1.05),.055,.12,'cream',segments=8)

def timber_stack():
    for y in [-.63,.63]:part('Bearer',(0,y,.10),(2.2,.18,.2),'metal')
    for row in range(5):
        for col in range(4):part('Sawn timber',(-.73+col*.49,0,.30+row*.19),(.44,1.8,.15),'edge' if (row+col)%3 else 'wood',.01)
    for x in [-.70,.70]:part('Steel band',(x,0,.72),(.035,1.85,.99),'metal')

def cargo_pallet():
    for x in [-.68,0,.68]:part('Pallet block',(x,0,.09),(.17,1.2,.18),'wood')
    for y in [-.48,-.24,0,.24,.48]:part('Pallet board',(0,y,.20),(1.7,.19,.07),'edge')
    for x,y,z,w,d in [(-.4,0,.61,.65,1.),(.38,-.24,.61,.70,.47),(.38,.28,.55,.70,.46),(-.28,0,1.20,.9,.68)]:
        part('Carton',(x,y,z),(w,d,.7),'cream',.015)
        part('Packing tape',(x,y,z+.356),(.07,d,.008),'gold')
        part('Shipping label',(x,y-d*.5-.005,z),(.22,.008,.16),'blue')

def fan():
    part('Ventilation enclosure',(0,0,.92),(1.7,.6,1.8),'cream',.035)
    cylinder('Fan recess',(0,-.32,.95),.68,.04,'metal',(math.pi/2,0,0),24)
    for j in range(5):
        angle=j*math.tau/5
        o=part('Fan blade',(.28*math.cos(angle),-.36,.95+.28*math.sin(angle)),(.65,.04,.19),'blue',.03);o.rotation_euler.y=-angle
    cylinder('Fan hub',(0,-.4,.95),.13,.09,'gold',(math.pi/2,0,0))
    for x in [-.57,-.38,-.19,0,.19,.38,.57]:part('Protective grille',(x,-.45,.95),(.015,.018,1.30),'metal')

def transformer():
    part('Transformer base',(0,0,.12),(1.7,1.2,.24),'cream',.025)
    part('Transformer housing',(0,0,.84),(1.24,.8,1.35),'green',.035)
    for side in [-1,1]:
        for j in range(7):part('Cooling fins',(side*.70,-.35+j*.115,.8),(.20,.055,1.07),'metal')
    for x in [-.4,0,.4]:
        cylinder('Insulator core',(x,0,1.65),.055,.40,'metal')
        for z in [1.54,1.63,1.72]:cylinder('Porcelain insulator',(x,0,z),.10,.04,'cream',segments=8)

def fountain():
    cylinder('Stone base',(0,0,.12),1.15,.24,'cream',segments=16)
    cylinder('Basin',(0,0,.32),1.02,.22,'edge',segments=16)
    cylinder('Water surface',(0,0,.438),.91,.018,'blue',segments=16)
    cylinder('Central column',(0,0,.83),.18,.90,'cream')
    cylinder('Upper bowl',(0,0,1.27),.47,.15,'cream',segments=16)
    cylinder('Upper water',(0,0,1.35),.39,.014,'blue',segments=16)

def solar():
    for x in [-.8,.8]:
        part('Foot',(x,0,.08),(.24,1.2,.16),'cream')
        part('Front support',(x,-.43,.53),(.06,.06,.9),'metal')
        part('Back support',(x,.43,.78),(.06,.06,1.4),'metal')
    panel=part('Solar frame',(0,0,1.12),(2.,1.4,.065),'metal');panel.rotation_euler.x=.48
    for x in range(6):
        for y in range(4):
            yy=-.51+y*.34
            cell=part('Solar cell',(-.82+x*.33,yy*math.cos(.48),1.16+yy*math.sin(.48)),(.30,.31,.015),'blue');cell.rotation_euler.x=.48

def greenhouse():
    for x in [-.95,.95]:
        for y in [-.38,.38]:part('Potting bench legs',(x,y,.42),(.06,.06,.84),'metal')
    part('Potting bench',(0,0,.85),(2.1,.95,.09),'edge')
    for x in [-.72,-.24,.24,.72]:
        for y in [-.22,.22]:
            cylinder('Terracotta pot',(x,y,.99),.15,.23,'red',segments=8)
            part('Stem',(x,y,1.23),(.025,.025,.38),'green')
            for side in [-1,1]:
                leaf=part('Leaf',(x+side*.09,y,1.25),(.20,.12,.025),'green');leaf.rotation_euler.y=side*.5

def hose_reel():
    for x in [-.55,.55]:
        part('Reel frame',(x,0,.49),(.08,.8,.98),'metal')
        cylinder('Reel flange',(x,0,.78),.49,.065,'gold',(0,math.pi/2,0),16)
    for x in [-.4,-.3,-.2,-.1,0,.1,.2,.3,.4]:
        cylinder('Wound hose',(x,0,.78),.37,.09,'green',(0,math.pi/2,0),16)
    part('Crank',(.69,0,.62),(.07,.07,.40),'metal')
    cylinder('Crank handle',(.81,0,.44),.045,.25,'wood',(0,math.pi/2,0),8)

def stone_bench():
    for x in [-.70,.70]:part('Carved support',(x,0,.30),(.30,.56,.60),'cream',.04)
    part('Stone seat',(0,0,.64),(2.1,.73,.16),'cream',.045)
    for x in [-.8,.8]:part('Scroll end',(x,.2,.80),(.25,.32,.22),'edge',.035)

def compressor():
    for x in [-.58,.58]:cylinder('Wheel',(x,0,.21),.21,.16,'metal',(0,math.pi/2,0))
    cylinder('Air tank',(0,0,.53),.32,1.38,'gold',(0,math.pi/2,0),16)
    part('Motor',(0,0,1.02),(.60,.50,.43),'metal',.035)
    for x in [-.24,-.12,0,.12,.24]:part('Cooling fin',(x,0,1.03),(.04,.57,.37),'cream')
    for x in [-.64,.64]:part('Handle rail',(x,.23,.88),(.045,.045,.78),'metal')
    part('Handle',(0,.23,1.28),(1.35,.06,.06),'red',.012)

def fruit_cart():
    for x in [-.73,.73]:cylinder('Cart wheel',(x,0,.36),.35,.09,'metal',(0,math.pi/2,0),16)
    part('Wood cart',(0,0,.73),(1.4,1.,.42),'edge',.02)
    for x in [-.48,.48]:part('Pull handle',(x,-1.,.69),(.055,1.4,.055),'wood')
    for y in [-.52,.52]:part('Raised side',(0,y,1.03),(1.5,.05,.27),'wood')
    for x in [-.50,-.25,0,.25,.50]:
        for y in [-.3,0,.3]:cylinder('Melon',(x,y,1.05),.13,.20,'green',segments=8)

def bakery():
    part('Display base',(0,0,.46),(1.95,.75,.92),'wood',.025)
    for z in [.96,1.3,1.64]:
        part('Bakery shelf',(0,0,z),(2.,.82,.055),'edge')
        for x in [-.72,-.36,0,.36,.72]:
            o=cylinder('Bread loaf',(x,-.05,z+.10),.10,.49,'gold',(math.pi/2,0,0),8)
    for x in [-.97,.97]:part('Shelf post',(x,.29,1.05),(.06,.06,1.4),'cream')

def fish_table():
    for x in [-.83,.83]:
        for y in [-.3,.3]:part('Steel leg',(x,y,.43),(.06,.06,.86),'metal')
    part('Fishmongers tray',(0,0,.9),(2.,.9,.14),'blue',.02)
    part('Ice bed',(0,0,.985),(1.86,.76,.035),'cream')
    for x in [-.70,-.35,0,.35,.70]:
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,0,1.05))
        o=bpy.context.object;o.scale=(.105,.31,.075);a=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
        for c in a.data:c.color=(.38,.59,.62,1)
        tail=part('Fish tail',(x,.29,1.04),(.17,.12,.025),'metal');tail.rotation_euler.z=.5

def bollards():
    part('Mooring foundation',(0,0,.12),(1.35,.65,.24),'cream',.035)
    for x in [-.38,.38]:
        cylinder('Mooring post',(x,0,.52),.15,.76,'metal')
        cylinder('Post cap',(x,0,.92),.22,.10,'metal')
    cylinder('Crossbar',(0,0,.77),.08,1.3,'gold',(0,math.pi/2,0))

def rope_crate():
    part('Rope crate',(0,0,.43),(1.1,1.05,.86),'wood',.02)
    for x in [-.42,.42]:part('Corner brace',(x,-.53,.45),(.07,.04,.86),'cream')
    for j in range(4):
        bpy.ops.mesh.primitive_torus_add(major_segments=12,minor_segments=5,major_radius=.32,minor_radius=.045,location=(0,0,.87+j*.08))
        o=bpy.context.object;a=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
        for c in a.data:c.color=COL['edge']

def drill():
    part('Drill base',(0,0,.12),(.95,.85,.24),'metal',.02)
    cylinder('Column',(0,.20,.91),.085,1.6,'cream')
    part('Motor head',(0,0,1.70),(.68,.71,.35),'green',.035)
    part('Work plate',(0,-.12,.78),(.87,.65,.065),'metal')
    cylinder('Drill bit',(0,-.22,1.21),.025,.63,'cream',segments=8)
    part('Feed lever',(.47,-.02,1.45),(.05,.05,.65),'metal')
    cylinder('Grip',(.47,-.02,1.16),.065,.17,'red',segments=8)

def lathe():
    for x in [-.73,.73]:part('Lathe pedestal',(x,0,.45),(.48,.7,.9),'green',.025)
    part('Bed',(0,0,.95),(2.,.70,.16),'metal')
    part('Headstock',(-.73,0,1.25),(.46,.62,.55),'green',.025)
    part('Tailstock',(.72,0,1.14),(.37,.43,.35),'green',.015)
    cylinder('Workpiece',(0,0,1.28),.11,1.05,'cream',(0,math.pi/2,0),12)
    cylinder('Hand wheel',(.20,-.42,1.03),.16,.05,'gold',(math.pi/2,0,0))

def lockers():
    for x in [-.52,0,.52]:
        part('Locker',(x,0,1.02),(.5,.6,2.04),'blue',.015)
        part('Door',(x,-.315,1.06),(.44,.028,1.86),'green',.01)
        part('Handle',(x+.12,-.35,1.06),(.035,.035,.18),'cream')
        for z in [1.66,1.72,1.78]:part('Louvre',(x,-.34,z),(.30,.018,.018),'metal')

def lab_sink():
    part('Cabinet',(0,0,.49),(1.65,.8,.98),'cream',.02)
    part('Worktop',(0,0,1.01),(1.75,.9,.065),'metal')
    part('Sink recess',(-.35,-.04,1.05),(.67,.54,.012),'blue')
    for x in [-.59,-.05]:cylinder('Faucet upright',(x,.22,1.18),.025,.30,'cream',segments=8)
    part('Faucet spout',(-.32,.22,1.33),(.58,.045,.045),'cream')
    for x in [-.42,.42]:part('Cabinet handle',(x,-.415,.78),(.24,.035,.035),'metal')

def sample_rack():
    for x in [-.70,.70]:
        for y in [-.28,.28]:part('Frame',(x,y,.95),(.055,.055,1.9),'metal')
    for z in [.15,.7,1.25,1.8]:
        part('Sample shelf',(0,0,z),(1.5,.66,.04),'cream')
        if z<1.7:
            for x in [-.51,-.17,.17,.51]:
                cylinder('Sample bottle',(x,0,z+.20),.095,.31,'blue',segments=8)
                cylinder('Bottle cap',(x,0,z+.38),.065,.065,'gold',segments=8)

def memorial():
    part('Plinth',(0,0,.15),(1.5,.9,.3),'cream',.035)
    part('Memorial stone',(0,0,1.02),(1.18,.34,1.5),'cream',.08)
    part('Bronze plaque',(0,-.19,1.10),(.83,.035,.58),'wood',.015)
    for z in [.93,1.02,1.11,1.20]:part('Inscription',(0,-.212,z),(.56,.008,.012),'gold')

def notice_board():
    for x in [-.65,.65]:part('Board post',(x,0,1.15),(.10,.10,2.3),'wood')
    part('Board',(0,0,1.55),(1.75,.16,1.2),'edge',.015)
    part('Cork',(0,-.087,1.55),(1.59,.018,1.04),'cream')
    for x,z in [(-.48,1.75),(-.09,1.48),(.44,1.72),(.45,1.23)]:part('Notice',(x,-.102,z),(.32,.009,.35),'blue' if x>0 else 'gold')

def stall():
    for x in [-1.08,1.08]:
        for y in [-.48,.48]: part('Timber upright',(x,y,1.2),(.09,.09,2.4),'wood',.01)
    part('Counter',(0,0,.84),(2.35,1.15,.12),'edge',.015)
    for j in range(10): part('Counter planks',(-1.04+j*.23,-.50,.43),(.215,.07,.73),'wood',.006)
    for j in range(8):
        o=part('Striped canvas',(-1.08+j*.31,0,2.37),(.31,1.5,.035),'green' if j%2 else 'cream')
        o.rotation_euler.x=.12
        part('Canvas valance',(-1.08+j*.31,-.74,2.19),(.31,.04,.19),'green' if j%2 else 'cream')
    for x in [-.75,0,.75]:
        part('Produce tray',(x,0,.94),(.67,.76,.10),'wood')
        for y in [-.38,.38]: part('Tray rim',(x,y,1.04),(.69,.045,.18),'edge')
        for k in range(8):
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.105,location=(x+(k%3-1)*.17,-.22+(k//3)*.20,1.065))
            o=bpy.context.object; a=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
            for d in a.data: d.color=COL[['red','gold','green'][int((x+.75)/.75)]]

def bookcase():
    for x in [-1.05,1.05]: part('Side panel',(x,0,1.3),(.12,.48,2.6),'wood',.014)
    part('Back',(0,.22,1.3),(2.1,.065,2.6),'wood')
    for z in [.09,.69,1.29,1.89,2.53]: part('Shelf',(0,0,z),(2.2,.58,.09),'edge',.008)
    for row in range(4):
        x=-.96
        for k in range(12):
            width=random.uniform(.08,.14); height=random.uniform(.30,.47)
            col=['red','green','blue','cream','wood'][(k+row*3)%5]
            part('Book',(x+width*.5,-.06,.16+row*.6+height*.5),(width,.31,height),col,.003)
            part('Spine band',(x+width*.5,-.22,.22+row*.6),(width*.8,.008,.022),'gold')
            x+=width+.02

def cabinet():
    part('Equipment enclosure',(0,0,1.12),(1.25,.75,2.2),'cream',.045)
    part('Recessed face',(0,-.386,1.12),(1.08,.035,1.96),'metal',.012)
    for z in [.43,.90,1.37,1.84]:
        part('Instrument module',(0,-.43,z),(.96,.085,.38),'blue',.008)
        part('Display',(-.21,-.478,z),(.39,.012,.19),'green')
        for k in range(3): part('Control button',(.10+k*.12,-.49,z-.07),(.055,.02,.055),'gold' if k==0 else 'cream',.006)
        for k in range(4): part('Vent',(0,-.48,z+.13),(.76,.01,.012),'metal')
    for x in [-.43,.43]: part('Foot',(x,0,.04),(.17,.59,.08),'metal')

def export(name, fn):
    start(); fn()
    bpy.ops.object.select_all(action='SELECT'); bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
    bpy.ops.object.join(); obj=bpy.context.object; obj.name=name
    mat=bpy.data.materials.new(name+' palette'); mat.use_nodes=True
    nodes=mat.node_tree.nodes; bsdf=nodes.get('Principled BSDF'); bsdf.inputs['Roughness'].default_value=.78
    vertex=nodes.new('ShaderNodeVertexColor'); vertex.layer_name='Color'; mat.node_tree.links.new(vertex.outputs['Color'],bsdf.inputs['Base Color'])
    obj.data.materials.clear(); obj.data.materials.append(mat)
    obj.data.calc_loop_triangles(); triangles=len(obj.data.loop_triangles)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True)
    return {'name':name,'triangles':triangles,'bytes':(OUT/(name+'.glb')).stat().st_size,'materials':1}

def main():
    records=[export(name,fn) for name,fn in [('produce_stall',stall),('library_bookcase',bookcase),('instrument_cabinet',cabinet),('water_pump',pump),('work_cart',work_cart),('garden_planter',planter),('reading_desk',reading_desk),('dock_rescue',dock_supply),('park_bench',bench),('cafe_parasol',cafe),('timber_stack',timber_stack),('cargo_pallet',cargo_pallet),('ventilation_fan',fan),('transformer',transformer),('stone_fountain',fountain),('solar_array',solar),('potting_bench',greenhouse),('hose_reel',hose_reel),('stone_bench',stone_bench),('air_compressor',compressor),('fruit_cart',fruit_cart),('bakery_display',bakery),('fish_table',fish_table),('mooring_bollards',bollards),('rope_crate',rope_crate),('drill_press',drill),('workshop_lathe',lathe),('staff_lockers',lockers),('laboratory_sink',lab_sink),('sample_rack',sample_rack),('memorial_stone',memorial),('notice_board',notice_board)]]
    (OUT/'manifest.json').write_text(json.dumps({'provenance':'Original project assets authored with Blender; no third-party source assets','assets':records},indent=2))
    print('THEMED_PROPS_COMPLETE '+json.dumps(records))

if __name__ == "__main__":
    main()
