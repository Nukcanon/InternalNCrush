"""Two hundred original purpose-specific small set-dressing objects.
Each is a distinct named construction, not a colour-only duplicate.
These never become tactical cover; attach only to compatible work surfaces.
"""
import bpy,math,json,sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
import build_themed_props as a
ROOT=Path(__file__).resolve().parents[1];a.OUT=ROOT/'assets/models/setdress_original';a.SOURCE=ROOT.parent/'art_source/setdress_original'
a.OUT.mkdir(parents=True,exist_ok=True);a.SOURCE.mkdir(parents=True,exist_ok=True)
P=a.part;C=a.cylinder
CAT={
'produce':'apple_tray pear_basket orange_crate lemon_bowl tomato_tray aubergine_basket carrot_bundle cabbage_head melon_half pepper_basket',
'bakery':'baguette_board croissant_tray bread_loaf bread_rolls layer_cake fruit_pie pretzel_board muffin_tin biscuit_jar pastry_box',
'kitchen':'stock_pot frying_pan saucepan tea_kettle chopping_board dish_stack utensil_holder spice_rack colander mortar_pestle',
'office':'keyboard computer_mouse desk_phone stapler tape_dispenser pen_cup desk_calendar paper_tray hole_punch document_scanner',
'laboratory':'microscope beaker_set test_tube_rack mini_centrifuge bunsen_burner sample_box pipette_stand digital_balance reagent_bottle slide_tray',
'medical':'bandage_rolls first_aid_pouch stethoscope thermometer_box medicine_blister oxygen_mask syringe_tray medical_gloves gauze_tin splint_bundle',
'workshop':'claw_hammer spanner_set cordless_drill hand_saw bench_vice screwdriver_rack pliers socket_case measuring_tape soldering_iron',
'electrical':'multimeter battery_pack wire_spool circuit_board power_adapter fuse_box extension_reel terminal_block switch_unit charger_dock',
'harbour':'coiled_rope miniature_anchor mooring_cleat navigation_compass lifebuoy_small fishing_reel net_float signal_horn deck_shackle boat_pulley',
'construction':'brick_pile tile_bundle cement_bag spirit_level paint_roller caulking_gun trowel plaster_float work_gloves masonry_chisel',
'paper':'book_stack open_book ring_binder archive_folder rolled_blueprints folded_newspaper magazine_rack map_case clipboard index_card_box',
'garden':'hand_fork garden_trowel pruning_shears seed_packet_box nursery_pots bonsai_pot succulent_tray garden_tw ine_hank potting_scoop plant_labels',
'signage':'menu_stand price_board reserved_sign caution_placard directional_plaque opening_hours_board numbered_sign sale_stand information_holder queue_marker',
'sport':'football basketball tennis_racket tennis_ball_tin badminton_racket shuttle_box table_tennis_paddles baseball_glove skipping_rope water_flask',
'containers':'wooden_caddy wicker_basket wire_basket tool_tote insulated_box transparent_bin metal_parts_tray ceramic_bowl fabric_satchel parcel_box',
'cleaning':'cleaning_bucket spray_bottle folded_towels scrub_brush soap_dispenser detergent_jug sponge_stack dustpan floor_brush cleaning_caddy',
'packaged_food':'tin_can_group bottled_water milk_carton cereal_box rice_sack coffee_bag oil_bottle egg_carton tea_box stacked_tins',
'retail':'cash_tray card_reader shop_scale barcode_scanner receipt_printer shopping_bag folded_shirts hat_display shoe_pair jewelry_stand',
'mechanics':'brake_disc gear_pair piston crankshaft oil_filter spark_plug_box car_battery jack_stand hub_cap bearing_tray',
'utility':'hand_radio flashlight fire_extinguisher_small padlock key_board binoculars alarm_clock portable_speaker power_tool_case emergency_lamp'}
CAT['garden']='hand_fork garden_trowel pruning_shears seed_packet_box nursery_pots bonsai_pot succulent_tray twine_hank potting_scoop plant_labels'
def orb(pos,size,color):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=pos);o=bpy.context.object;o.scale=size
 attr=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
 for c in attr.data:c.color=a.COL.get(color,color)
def bar(p,q,r,color):
 d=Vector(q)-Vector(p);o=C('Handle',(Vector(p)+Vector(q))*.5,r,d.length,color,segments=8);o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
def tray(w=.38,d=.25):
 P('Tray base',(0,0,.015),(w,d,.03),'wood')
 for x in [-1,1]:P('Tray side',(x*(w/2-.012),0,.05),(.024,d,.07),'edge')
 for y in [-1,1]:P('Tray end',(0,y*(d/2-.012),.05),(w-.048,.024,.07),'edge')
def device(w=.22,d=.17,h=.08):
 P('Housing',(0,0,h/2),(w,d,h),'metal',.014);P('Display',(0,-d*.22,h+.005),(w*.58,d*.35,.012),'blue')
 for x in [-1,0,1]:C('Control',(x*w*.25,d*.28,h+.011),.014,.012,'cream',segments=8)
def bottle(x=0,y=0,h=.20,r=.045,color='blue'):
 C('Bottle body',(x,y,h*.4),r,h*.8,color,segments=10);C('Bottle shoulder',(x,y,h*.82),r*.7,h*.12,color,segments=10);C('Bottle cap',(x,y,h*.94),r*.4,h*.12,'cream',segments=8)
def tool(i):
 bar((-.15,0,.025),(.12,0,.025),.020 if i%2 else .016,'edge')
 if i%5==0:P('Hammer head',(.13,0,.035),(.055,.15,.05),'metal',.01)
 elif i%5==1:
  for x in [.11,.18]:P('Open jaw',(x,0,.025),(.03,.10,.035),'metal')
  P('Jaw back',(.145,.045,.025),(.07,.03,.035),'metal')
 elif i%5==2:
  device(.16,.10,.11);P('Drill grip',(.04,0,-.03),(.055,.06,.10),'green');bar((-.08,0,.07),(-.22,0,.07),.01,'metal')
 elif i%5==3:
  P('Saw blade',(.04,0,.03),(.30,.095,.009),'metal')
  for j in range(9):P('Teeth',(-.10+j*.03,-.054,.03),(.015,.02,.009),'metal')
 else:
  P('Vice body',(0,0,.04),(.14,.12,.08),'blue')
  for x in [-.065,.065]:P('Vice jaws',(x,0,.10),(.04,.15,.08),'metal')
  bar((-.16,0,.04),(.16,0,.04),.009,'metal')
def build(theme,i):
 if theme=='produce':
  tray();sizes=[(.045,.045,.045),(.038,.038,.06),(.045,.045,.045),(.06,.032,.035),(.045,.045,.033),(.035,.03,.08),(.017,.017,.09),(.12,.1,.08),(.14,.07,.07),(.035,.035,.05)]
  color=['red','gold','gold','gold','red',(.18,.08,.22,1),'gold','green','green','red'][i]
  for j in range(1 if i in [7,8] else 6):orb((-.12+(j%3)*.12,-.06+(j//3)*.12,.08),sizes[i],color)
 elif theme=='bakery':
  tray(.42,.28)
  if i==0:
   for j in range(2):orb((0,-.06+j*.12,.08),(.18,.035,.04),'gold')
  elif i in [4,5]:
   C('Baked round',(0,0,.075),.12,.09,'gold',segments=16)
   if i==4:C('Icing',(0,0,.13),.12,.025,'cream',segments=16)
   else:
    for j in [-1,0,1]:P('Lattice',(0,j*.06,.13),(.2,.016,.012),'cream')
  elif i==8:
   C('Jar',(0,0,.12),.10,.2,'cream');C('Lid',(0,0,.23),.11,.025,'edge')
  elif i==9:P('Pastry box',(0,0,.09),(.32,.23,.12),'cream',.01)
  else:
   for j in range(2+i%4):orb((-.13+j*.07,0,.075),(.045,.07 if i==1 else .04,.04+i*.003),'gold')
 elif theme=='kitchen':
  if i in [0,2,3,8,9]:
   C('Vessel',(0,0,.09),.09,.16,'metal' if i!=9 else 'cream')
   for x in [-1,1]:P('Vessel handle',(x*.12,0,.11),(.07,.035,.025),'metal')
   if i==3:bar((.07,0,.07),(.16,0,.15),.025,'metal');C('Lid',(0,0,.19),.1,.02,'metal')
   elif i==9:bar((0,0,.08),(.09,0,.24),.025,'cream')
  elif i==1:C('Pan',(0,0,.025),.13,.035,'metal');bar((.10,0,.03),(.32,0,.03),.025,'wood')
  elif i==4:P('Cutting board',(0,0,.012),(.34,.23,.024),'edge',.018);tool(3)
  elif i==5:
   for j in range(5):C('Plate',(0,0,.015+j*.018),.12,.018,'cream',segments=16)
  elif i==6:
   C('Holder',(0,0,.06),.045,.12,'metal')
   for j in range(4):bar((j*.02-.03,0,.05),(j*.02-.03,0,.23+j*.015),.008,'wood')
  else:
   tray()
   for j in range(5):bottle(-.14+j*.07,0,.12,.025,'cream')
 elif theme in ['office','electrical','laboratory','retail','utility']:
  widths=[.35,.07,.19,.16,.13,.10,.20,.28,.13,.32];device(widths[i],.09+(i%3)*.055,.045+(i%4)*.03)
  if theme=='office':
   if i==0:
    for x in range(10):
     for y in range(3):P('Key',(-.15+x*.033,-.027+y*.026,.055),(.027,.021,.012),'cream')
   elif i in [2,8]:bar((-.075,0,.12),(.075,0,.12),.025,'metal')
   elif i==5:
    for j in range(5):bar((j*.014-.028,0,.02),(j*.014-.028,0,.2+j*.008),.004,'gold')
   elif i in [6,7]:P('Paper',(0,0,.085),(.18,.14,.012),'cream')
  elif theme=='laboratory':
   if i in [1,2,6,8]:
    for j in range(1 if i==8 else 4):bottle(-.09+j*.06,0,.16+j*.025,.02,'cream')
   elif i==0:bar((0,0,.05),(0,0,.25),.02,'metal');bar((0,0,.22),(.10,0,.29),.025,'metal')
   elif i==4:bar((0,0,.06),(0,0,.24),.025,'gold')
   elif i==3:C('Rotor lid',(0,0,.1),.085,.02,'cream')
  elif theme=='electrical':
   if i in [1,3,5,7]:
    for j in range(4):C('Terminal',(-.06+j*.04,0,.16),.012,.05,'gold')
   elif i in [2,6]:C('Wire reel',(0,0,.12),.09,.1,'red',segments=14)
  elif theme=='retail':
   if i==2:C('Weighing pan',(0,0,.19),.12,.02,'metal')
   elif i in [5,6]:P('Goods',(0,0,.14),(.24,.20,.06),'cream' if i==5 else 'blue')
   elif i==8:
    for x in [-.06,.06]:orb((x,0,.075),(.055,.13,.035),'wood')
   elif i==9:bar((0,0,.05),(0,0,.25),.012,'gold');bar((-.1,0,.25),(.1,0,.25),.012,'gold')
  else:
   if i in [1,3,6]:C('Optical barrel',(0,0,.13),.035,.18,'metal',(math.pi/2,0,0))
   elif i==2:bottle(0,0,.25,.055,'red')
   elif i==9:P('Light',(0,-.07,.14),(.14,.025,.12),'cream')
 elif theme in ['workshop','construction','garden','mechanics']:
  if theme=='workshop':tool(i)
  elif theme=='construction':
   if i in [0,1,2]:
    for j in range(3):P('Stack',((j%2)*.12-.06,0,.025+j*.025),(.20,.13,.04),'red' if i==0 else 'cream')
   else:tool(i)
  elif theme=='garden':
   if i in [4,5,6]:
    C('Pot',(0,0,.065),.065,.13,'edge')
    for j in range(4):bar((0,0,.10),(.035*math.cos(j),.035*math.sin(j),.20+j*.025),.008,'green');orb((.035*math.cos(j),.035*math.sin(j),.20+j*.025),(.035,.025,.025),'green')
   elif i==3:P('Seed carton',(0,0,.06),(.25,.15,.12),'cream')
   elif i==7:C('Twine',(0,0,.06),.06,.12,'edge')
   else:tool(i)
  else:
   if i in [0,1,4,8,9]:
    C('Machined part',(0,0,.04),.12-i*.004,.08,'metal',segments=16)
    for j in range(8):a.part('Gear tooth',(.12*math.cos(j*math.tau/8),.12*math.sin(j*math.tau/8),.04),(.035,.035,.07),'metal')
   elif i in [2,3]:bar((-.13,0,.06),(.13,0,.06),.035,'metal');C('Piston',(0,0,.12),.06,.13,'metal')
   else:device(.22,.13,.13)
 elif theme in ['paper','signage']:
  if theme=='paper':
   for j in range(1+i%4):P('Paper object',(j*.006,0,.015+j*.03),(.16+(i%3)*.04,.23,.025),'cream' if i in [1,4,5,8] else 'blue',.005)
   if i in [1,8]:P('Spine',(0,0,.025),(.012,.23,.018),'wood')
   if i==6:
    for x in [-.12,.12]:P('Rack side',(x,0,.09),(.025,.24,.18),'wood')
  else:
   P('Weighted foot',(0,0,.018),(.19,.12,.035),'metal');bar((0,0,.02),(0,0,.13),.012,'metal');P('Sign board',(0,0,.22),(.18+i%3*.035,.025,.14+i%2*.04),'cream',.006)
   for j in range(1+i%4):P('Raised lettering',(-.04+j*.03,-.017,.23),(.018,.008,.045),'blue')
 elif theme in ['containers','cleaning','packaged_food','medical']:
  if (theme=='cleaning' and i in [1,4,5]) or (theme=='packaged_food' and i in [0,1,6,9]):
   for j in range(1+i%3):bottle(j*.07-.04,0,.16+i*.006,.03,'cream' if theme=='cleaning' else 'blue')
  elif theme=='medical' and i in [0,6,8]:
   tray(.24,.16)
   for j in range(3):C('Sterile item',(-.07+j*.07,0,.065),.025,.07,'cream')
  elif i%3==0:
   C('Container',(0,0,.08),.10,.16,'cream')
   bar((-.1,0,.14),(-.1,0,.23),.009,'metal');bar((.1,0,.14),(.1,0,.23),.009,'metal');bar((-.1,0,.23),(.1,0,.23),.009,'metal')
  else:
   P('Container body',(0,0,.05),(.21+i*.008,.16,.1),'cream' if theme in ['medical','packaged_food'] else 'green',.012)
   if i%2:P('Fastener',(0,-.085,.07),(.04,.012,.03),'metal')
   else:
    for j in range(3):P('Contents',(-.06+j*.06,0,.12),(.05,.12,.04),'edge')
 elif theme=='harbour':
  if i in [0,4,7,9]:
   bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=5,major_radius=.10,minor_radius=.024,location=(0,0,.035));o=bpy.context.object;attr=o.data.color_attributes.new(name='Color',type='BYTE_COLOR',domain='CORNER')
   for c in attr.data:c.color=a.COL['red' if i==4 else 'edge']
  elif i in [1,2]:
   bar((0,0,.02),(0,0,.19),.018,'metal');bar((-.1,0,.04),(.1,0,.04),.02,'metal')
   for x in [-.1,.1]:bar((x,0,.04),(x*.8,0,.09),.016,'metal')
  else:device(.16,.13,.10);C('Marine fitting',(0,0,.16),.06,.04,'gold',segments=12)
 else:
  if i in [0,1,3]:orb((0,0,.1),(.1,.1,.1),'edge' if i==1 else 'cream')
  elif i in [2,4,6]:
   bar((0,-.14,.025),(0,.06,.025),.014,'wood');orb((0,.10,.027),(.08,.11,.016),'cream')
   for j in range(5):P('Strings',(-.055+j*.027,.1,.045),(.004,.14,.003),'metal')
  elif i==9:bottle(0,0,.22,.05,'blue')
  else:tray(.20,.15);orb((0,0,.10),(.075,.065,.05),'edge')
if __name__=='__main__':
 rows=[]
 for theme,names in CAT.items():
  names=names.split();assert len(names)==10,(theme,names)
  for i,name in enumerate(names):
   row=a.export('set_'+name,lambda t=theme,i=i:build(t,i));row['theme']=theme;row['non_collision']=True;rows.append(row)
 assert len(rows)==200
 (a.OUT/'manifest.json').write_text(json.dumps({'provenance':'Original authored tabletop set dressing; no third-party inputs','assets':rows},indent=2))
 print('SETDRESS_COMPLETE',len(rows))
