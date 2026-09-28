"""118 original furnished objects, grouped by real use rather than colour swaps.
Small countertop equipment includes a supporting counter; no floating appliances.
All dimensions are metres, each exported object has one vertex-colour material.
"""
import pathlib,sys,math,json
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
import build_themed_props as a
P=a.part;C=a.cylinder
ROOT=pathlib.Path(__file__).resolve().parents[1]
a.OUT=ROOT/'assets/models/places_original';a.SOURCE=ROOT.parent/'art_source/places_original'
a.OUT.mkdir(parents=True,exist_ok=True);a.SOURCE.mkdir(parents=True,exist_ok=True)
CATALOG={
'seating':['dining_chair','school_chair','office_chair','armchair','patio_chair','bar_stool','picnic_bench','station_bench','folding_chair','wheelchair'],
'tables':['picnic_table','round_cafe_table','writing_desk','drafting_table','folding_table','billiard_table','reception_desk','console_table'],
'storage':['kitchen_cupboard','wardrobe','utility_cabinet','tool_chest','filing_cabinet','medicine_cabinet','equipment_locker','storage_bin','open_crate','metal_shelving','shoe_shelf','parcel_lockers'],
'kitchen':['stove_station','range_station','refrigerator','microwave_counter','oven_station','dishwashing_sink','kettle_counter','coffee_station','toaster_counter','food_service_counter'],
'office':['monitor_desk','computer_station','printer_station','server_rack','television_stand','radio_desk','telephone_station','projector_cart','pa_speaker','security_camera_post'],
'medical':['stretcher','medical_bed','iv_stand','oxygen_station','first_aid_station','defibrillator_station','medical_cart','examination_chair','scanner_station','privacy_screen'],
'industry':['forklift','pallet_jack','welding_cart','portable_generator','electrical_panel','industrial_press','conveyor','pipe_valve','boiler','fuel_pump','gas_cylinder_rack','bench_grinder','large_compressor','chain_hoist','rock_hopper','ventilation_duct'],
'street':['fire_hydrant','postbox','payphone','bus_shelter','ticket_machine','cash_machine','drinks_vending','snacks_vending','recycling_station','litter_bin','traffic_signal','street_lamp','bicycle_rack','bicycle','parking_meter','road_barrier'],
'coast':['lifering_rack','fishing_net_rack','anchor_display','mooring_buoy','harbour_beacon','dock_winch','gangway','fish_crates'],
'garden':['wheelbarrow','watering_can','shovel_rack','seedling_trays','terracotta_pots','garden_trellis','birdbath','beehive','water_butt','compost_bin'],
'construction':['cement_mixer','scaffold','ladder','toolbox_station','brick_stack','sawhorse','cable_drum','roadworks_sign']}
def frame(w=1.2,d=.7,h=.8,colour='metal'):
    for x in [-w*.43,w*.43]:
        for y in [-d*.4,d*.4]:P('Support',(x,y,h*.5),(.07,.07,h),colour)
    P('Top',(0,0,h),(w,d,.09),'edge',.015)
def wheel(x,y,z=.15,r=.14):C('Wheel',(x,y,z),r,.07,'metal',(0,math.pi/2,0),10)
def box_unit(w=.8,d=.6,h=1.4,colour='cream',drawers=0):
    P('Enclosure',(0,0,h*.5),(w,d,h),colour,.03)
    count=drawers or 1
    for k in range(count):
        z=(k+.5)*h/count
        P('Front panel',(0,-d*.5-.015,z),(w*.88,.035,h/count-.07),'edge' if colour=='wood' else 'blue' if colour=='cream' else 'cream',.012)
        P('Handle',(0,-d*.5-.06,z),(.22,.055,.035),'metal')
def seating(name):
    wide=1.7 if name in ['picnic_bench','station_bench'] else .62
    stool=name=='bar_stool';height=.78 if stool else .47
    frame(wide,.58,height,'wood' if name in ['dining_chair','picnic_bench'] else 'metal')
    if not stool:
        for x in [-wide*.43,wide*.43]:P('Back support',(x,.23,.75),(.05,.06,.63),'metal')
        if name in ['patio_chair','station_bench']:
            for z in [.68,.80,.92]:P('Back slat',(0,.25,z),(wide,.055,.07),'green')
        else:P('Backrest',(0,.25,.83),(wide,.10,.40),'blue' if name in ['office_chair','school_chair'] else 'green',.025)
    if name in ['armchair','wheelchair','office_chair']:
        for side in [-1,1]:P('Armrest',(side*wide*.51,0,.68),(.09,.50,.10),'cream',.02)
    if name=='armchair':P('Cushion',(0,0,.55),(.61,.52,.17),'green',.05)
    if name=='office_chair':
        C('Seat pedestal',(0,0,.25),.07,.4,'metal')
        for side in [-1,1]:P('Caster base',(side*.18,0,.10),(.4,.065,.06),'metal');wheel(side*.34,0,.08,.07)
    if name=='wheelchair':
        for side in [-1,1]:wheel(side*.40,.12,.32,.30);wheel(side*.31,-.33,.1,.09)
        P('Footrest',(0,-.53,.13),(.54,.35,.07),'metal')
    if name=='folding_chair':
        for side in [-1,1]:
            o=P('Cross brace',(side*.24,0,.3),(.035,.065,.72),'cream');o.rotation_euler.x=.55
def tables(name):
    w=2.2 if name in ['picnic_table','billiard_table','reception_desk'] else 1.35
    d=1.1 if name=='billiard_table' else .72
    frame(w,d,.78)
    if name=='round_cafe_table':C('Circular top',(0,0,.84),.7,.07,'cream',segments=20)
    elif name=='picnic_table':
        for y in [-.75,.75]:P('Bench seat',(0,y,.48),(2.2,.30,.10),'wood');P('Crossbar',(0,y*.5,.27),(1.8,.09,.12),'wood')
    elif name=='billiard_table':
        P('Felt',(0,0,.84),(2.10,1.03,.035),'green')
        for x in [-1.04,1.04]:P('Cushion rail',(x,0,.90),(.10,1.1,.10),'wood')
        for y in [-.52,.52]:P('Cushion rail',(0,y,.90),(2.2,.10,.10),'wood')
        for x in [-.20,0,.20]:C('Ball',(x,0,.89),.045,.06,'cream',segments=8)
    elif name=='drafting_table':
        o=P('Drawing board',(0,0,.94),(1.35,.85,.05),'cream');o.rotation_euler.x=.23
        P('Ruler',(0,-.25,1.03),(1.2,.035,.025),'metal')
    elif name=='reception_desk':
        P('Front',(0,-.32,.55),(2.2,.10,1.1),'wood');P('Raised counter',(0,-.26,1.12),(2.3,.4,.09),'cream')
    elif name=='writing_desk':
        for z in [.30,.52]:P('Drawer',(-.42,0,z),(.38,.62,.19),'wood');P('Pull',(-.42,-.33,z),(.14,.04,.03),'gold')
    elif name=='console_table':P('Lower shelf',(0,0,.20),(1.25,.60,.055),'wood')
    elif name=='folding_table':
        for x in [-.42,.42]:P('Folding hinge',(x,0,.73),(.12,.54,.07),'gold')
def storage(name):
    if name in ['open_crate','storage_bin']:
        w=1.2 if name=='storage_bin' else .8
        P('Bottom',(0,0,.07),(w,.7,.14),'wood')
        for x in [-w*.5,w*.5]:P('Side',(x,0,.39),(.07,.7,.64),'green' if name=='storage_bin' else 'edge')
        for y in [-.35,.35]:P('Side',(0,y,.39),(w,.07,.64),'green' if name=='storage_bin' else 'edge')
    elif name in ['metal_shelving','shoe_shelf']:
        h=2.1 if name=='metal_shelving' else 1.1
        for x in [-.6,.6]:P('Upright',(x,0,h*.5),(.065,.42,h),'metal')
        for z in [.1,h*.34,h*.66,h]:P('Shelf',(0,0,z),(1.3,.55,.055),'cream')
        for x in [-.38,0,.38]:P('Stored box',(x,.04,h*.4),(.26,.35,.22),'wood')
    else:
        h=1.25 if name in ['tool_chest','filing_cabinet'] else 2.0
        box_unit(1.2 if name in ['wardrobe','parcel_lockers'] else .8,.55,h,'wood' if name=='wardrobe' else 'cream',6 if name=='tool_chest' else 4 if name=='filing_cabinet' else 3 if name=='parcel_lockers' else 1)
        if name in ['medicine_cabinet','equipment_locker']:
            P('Observation panel',(0,-.32,1.45),(.52,.02,.55),'green')
        if name=='utility_cabinet':
            for z in [.3,.4,.5]:P('Air louver',(0,-.30,z),(.6,.02,.025),'metal')
        if name=='kitchen_cupboard':P('Counter lip',(0,0,2.04),(.96,.67,.07),'edge')
def kitchen(name):
    if name=='refrigerator':
        box_unit(.9,.75,1.95,drawers=2);P('Vent',(0,-.40,.15),(.65,.025,.08),'metal');return
    frame(1.25,.75,.85)
    if name in ['stove_station','range_station']:
        P('Cooktop',(0,0,.93),(1.12,.69,.08),'cream')
        for x in [-.30,.30]:
            for y in [-.19,.19]:C('Burner',(x,y,.99),.13,.025,'metal',segments=12)
        P('Control strip',(0,-.35,.96),(1.1,.08,.08),'metal')
        if name=='range_station':P('Hood',(0,.2,1.85),(1.24,.70,.30),'metal',.10);P('Duct',(0,.30,2.25),(.38,.35,.60),'cream')
    elif name in ['microwave_counter','oven_station','toaster_counter']:
        w=.75 if name!='toaster_counter' else .40;h=.5 if name!='oven_station' else .7
        P('Appliance',(0,0,.90+h*.5),(w,.50,h),'cream',.04)
        P('Window',(0,-.27,.90+h*.5),(w*.73,.025,h*.6),'metal')
        for x in [-w*.22,w*.22]:C('Control',(x,-.30,.92+h*.8),.025,.03,'gold',(math.pi/2,0,0),8)
    elif name=='dishwashing_sink':
        P('Sink rim',(0,0,.92),(1.12,.70,.06),'cream')
        P('Basin',(0,0,.95),(.75,.48,.025),'metal')
        C('Tap',(0,.25,1.13),.03,.35,'cream',segments=8)
        P('Spout',(0,.13,1.30),(.055,.28,.045),'cream')
    elif name=='kettle_counter':
        C('Kettle',(0,0,1.12),.18,.34,'blue',segments=12)
        P('Handle',(.23,0,1.17),(.06,.075,.25),'metal')
        P('Handle top',(.15,0,1.28),(.21,.075,.055),'metal')
    elif name=='coffee_station':
        P('Machine',(0,.08,1.18),(.57,.4,.54),'metal',.04)
        P('Face',(0,-.14,1.30),(.43,.04,.20),'cream')
        C('Cup',(0,-.20,1.02),.065,.13,'cream',segments=10)
    else:
        for x in [-.40,0,.40]:P('Serving pan',(x,0,.97),(.32,.52,.10),'cream',.03)
        for x in [-.58,.58]:P('Canopy post',(x,.2,1.3),(.04,.04,.85),'metal')
        P('Display canopy',(0,.1,1.7),(1.3,.65,.07),'green')
def office(name):
    if name in ['monitor_desk','computer_station','radio_desk']:
        frame(1.4,.75,.75)
        P('Display',(0,.18,1.12),(.67,.10,.44),'metal',.025)
        P('Screen',(0,.119,1.12),(.58,.015,.35),'blue')
        P('Keyboard',(0,-.18,.82),(.60,.20,.035),'cream')
        if name=='computer_station':P('Tower',(.47,.15,1.02),(.22,.38,.48),'cream');P('Vent',(.47,-.05,1.04),(.15,.02,.25),'metal')
        if name=='radio_desk':
            for x in [-.21,.21]:C('Dial',(x,.105,1.10),.065,.025,'gold',(math.pi/2,0,0),10)
            C('Antenna',(.29,.2,1.66),.014,.6,'metal',segments=6)
    elif name=='server_rack':
        box_unit(.80,.85,2.1,'metal',7)
        for z in [.3,.55,.8,1.05,1.3,1.55,1.8]:
            for x in [-.23,-.12]:P('Status LED',(x,-.48,z),(.045,.02,.035),'green')
    elif name in ['printer_station','projector_cart']:
        frame(.95,.65,.7);P('Housing',(0,0,.94),(.80,.57,.40),'cream',.045)
        if name=='printer_station':P('Paper tray',(0,-.30,.88),(.50,.38,.04),'metal');P('Scanner lid',(0,0,1.17),(.82,.60,.07),'blue')
        else:C('Lens',(0,-.32,.99),.095,.10,'blue',(math.pi/2,0,0),12)
    elif name in ['television_stand','pa_speaker']:
        frame(1.1,.45,.55)
        P('Cabinet',(0,0,1.15),(1.05,.24,.9),'metal',.035)
        if name=='television_stand':P('Screen',(0,-.135,1.15),(.94,.025,.76),'blue')
        else:
            for z,r in [(1.38,.12),(.99,.25)]:C('Speaker cone',(0,-.15,z),r,.06,'cream',(math.pi/2,0,0),16)
    elif name=='security_camera_post':
        C('Post',(0,0,1.05),.055,2.1,'metal',segments=10)
        P('Camera',(0,-.20,2.0),(.25,.55,.22),'cream',.03);P('Lens',(0,-.49,2.0),(.14,.025,.12),'blue')
        P('Base',(0,0,.07),(.48,.48,.14),'cream')
    else:
        box_unit(.55,.45,.95)
        P('Telephone base',(0,0,1.04),(.40,.3,.12),'metal',.03)
        P('Handset',(0,-.06,1.15),(.43,.065,.07),'blue',.025)
def medical(name):
    if name in ['stretcher','medical_bed']:
        frame(.8,2.,.68);P('Mattress',(0,0,.79),(.8,1.9,.18),'cream',.06)
        P('Pillow',(0,.68,.94),(.6,.36,.15),'green',.04)
        for x in [-.42,.42]:
            for y in [-.75,.75]:wheel(x,y)
            if name=='medical_bed':P('Side rail',(x,0,1.03),(.045,1.55,.06),'metal')
    elif name in ['iv_stand','oxygen_station']:
        P('Base',(0,0,.08),(.55,.55,.12),'metal');C('Post',(0,0,1.),.035,1.9,'cream',segments=8)
        if name=='iv_stand':P('Hook rail',(0,0,1.95),(.6,.04,.04),'metal');P('IV bag',(.20,0,1.65),(.16,.09,.29),'blue')
        else:C('Cylinder',(0,0,.65),.17,1.15,'green');C('Valve',(0,0,1.26),.06,.09,'gold')
    elif name=='privacy_screen':
        for x in [-.6,.6]:P('Post',(x,0,.95),(.05,.05,1.9),'metal');P('Foot',(x,0,.055),(.08,.60,.08),'metal')
        P('Fabric screen',(0,0,1.05),(1.15,.025,1.5),'green')
    elif name=='examination_chair':
        seating('armchair');P('Foot extension',(0,-.65,.44),(.56,.75,.10),'cream')
    elif name=='scanner_station':
        frame(.95,.7,.82);P('Scan console',(0,0,1.1),(.75,.55,.48),'cream',.035)
        P('Display',(0,-.29,1.18),(.55,.02,.31),'blue');P('Probe cradle',(.51,0,1.02),(.17,.25,.06),'metal')
    else:
        frame(.7,.55,.8)
        if name=='medical_cart':
            for z in [.2,.5]:P('Tray',(0,0,z),(.72,.55,.06),'cream')
            for x in [-.3,.3]:
                for y in [-.2,.2]:wheel(x,y,.08,.065)
        else:
            P('Medical case',(0,0,1.05),(.60,.34,.42),'green' if name=='first_aid_station' else 'gold',.035)
            P('Medical emblem',(0,-.18,1.05),(.23,.025,.07),'cream');P('Medical emblem',(0,-.18,1.05),(.07,.025,.23),'cream')
def industry(name):
    if name in ['forklift','pallet_jack']:
        P('Drive base',(0,.1,.3),(.95,1.15,.35),'gold',.04)
        for x in [-.47,.47]:
            for y in [-.27,.48]:wheel(x,y,.22,.20)
        for x in [-.3,.3]:P('Fork',(x,-.98,.17),(.16,1.65,.09),'metal')
        if name=='forklift':
            for x in [-.36,.36]:P('Mast',(x,-.38,1.25),(.10,.13,2.3),'metal')
            P('Operator seat',(0,.23,.80),(.5,.45,.15),'metal');P('Roof',(0,.25,1.85),(1.05,.9,.08),'gold')
            for x in [-.44,.44]:P('Roof support',(x,.52,1.30),(.07,.07,1.1),'metal')
        else:P('Handle',(0,.45,.95),(.065,.06,1.15),'metal');P('Grip',(0,.45,1.48),(.55,.07,.07),'metal')
    elif name in ['boiler','large_compressor','gas_cylinder_rack']:
        P('Mount',(0,0,.12),(1.5,.9,.24),'metal')
        if name=='gas_cylinder_rack':
            for x in [-.48,0,.48]:C('Cylinder',(x,0,.94),.19,1.55,'green');C('Valve',(x,0,1.76),.05,.10,'gold')
            P('Safety rail',(0,-.25,1.0),(1.4,.05,.06),'cream')
        else:
            C('Pressure vessel',(0,0,.9),.53,1.25,'blue',(0,math.pi/2,0) if name=='large_compressor' else (0,0,0),16)
            C('Gauge',(0,-.56,1.15),.11,.04,'cream',(math.pi/2,0,0),12)
            P('Pipe',(.63,0,1.1),(.08,.10,1.6),'metal')
    elif name in ['industrial_press','chain_hoist','rock_hopper']:
        P('Foundation',(0,0,.15),(1.5,1.1,.3),'metal')
        for x in [-.55,.55]:P('Upright',(x,0,1.15),(.15,.22,2.),'green')
        P('Crosshead',(0,0,2.05),(1.3,.40,.22),'green')
        if name=='industrial_press':C('Ram',(0,0,1.6),.14,.70,'cream');P('Press table',(0,0,.75),(1.2,.8,.14),'metal')
        elif name=='chain_hoist':C('Chain',(0,0,1.4),.025,1.3,'metal',segments=6);P('Hook',(0,0,.75),(.20,.12,.12),'gold')
        else:P('Hopper',(0,0,1.1),(1.1,.85,.85),'gold',.18)
    elif name=='conveyor':
        frame(1.0,2.3,.75)
        for i in range(12):C('Roller',(0,-1.03+i*.187,.85),.075,.92,'cream',(0,math.pi/2,0),8)
    elif name=='pipe_valve':
        P('Support',(0,0,.18),(1.4,.6,.36),'cream');C('Pipe',(0,0,.65),.22,1.6,'green',(0,math.pi/2,0))
        C('Valve stem',(0,0,.98),.05,.5,'metal');C('Wheel',(0,0,1.24),.24,.04,'red',segments=12)
    elif name=='ventilation_duct':
        P('Duct',(0,0,.65),(1.1,.8,1.3),'cream');P('Outlet',(0,-.42,.75),(.94,.06,1.0),'metal')
        for z in [.35,.55,.75,.95,1.15]:P('Vent blade',(0,-.47,z),(.86,.08,.055),'cream')
    elif name=='bench_grinder':
        frame(1.15,.65,.8);C('Motor',(0,0,1.04),.18,.6,'green',(0,math.pi/2,0))
        for x in [-.4,.4]:C('Grinding wheel',(x,0,1.04),.24,.08,'metal',(0,math.pi/2,0),16)
    else:
        w=1.2 if name=='portable_generator' else .7
        box_unit(w,.65,1.2,'gold' if name=='portable_generator' else 'green',2 if name=='electrical_panel' else 1)
        if name=='welding_cart':C('Gas tank',(.46,.12,.73),.15,1.35,'blue');wheel(-.4,0);wheel(.4,0)
        elif name=='fuel_pump':P('Display',(0,-.37,.94),(.42,.025,.19),'metal');P('Hose',(.43,0,.67),(.055,.055,1.1),'metal')
        else:
            for z in [.35,.48,.61]:P('Vent',(0,-.35,z),(w*.74,.025,.035),'metal')
def street(name):
    if name in ['traffic_signal','street_lamp','parking_meter']:
        h=2.8 if name!='parking_meter' else 1.3
        C('Pole',(0,0,h*.5),.06,h,'metal',segments=10);P('Foundation',(0,0,.08),(.44,.44,.16),'cream')
        if name=='traffic_signal':
            P('Signal',(0,-.1,2.40),(.34,.25,.85),'metal',.035)
            for z,c in [(2.66,'red'),(2.40,'gold'),(2.14,'green')]:C('Signal lens',(0,-.24,z),.10,.045,c,(math.pi/2,0,0),12)
        elif name=='street_lamp':P('Lamp arm',(0,-.32,h),(.08,.70,.08),'metal');P('Lamp',(0,-.66,h-.08),(.40,.60,.16),'cream',.05)
        else:P('Meter head',(0,0,h),(.28,.21,.42),'green',.03);P('Display',(0,-.12,h),(.18,.02,.11),'metal')
    elif name=='bus_shelter':
        for x in [-1.2,1.2]:P('Post',(x,.30,1.2),(.08,.08,2.4),'metal')
        P('Roof',(0,0,2.42),(2.6,1.5,.12),'green');P('Rear panel',(0,.34,1.3),(2.45,.035,1.7),'blue')
        P('Bench',(0,.10,.52),(2.1,.43,.12),'wood')
        for x in [-.7,.7]:P('Leg',(x,.1,.26),(.08,.18,.52),'metal')
    elif name=='fire_hydrant':
        C('Hydrant',(0,0,.48),.18,.78,'red');C('Cap',(0,0,.91),.22,.10,'red')
        C('Outlet',(0,0,.64),.10,.65,'cream',(0,math.pi/2,0),10)
    elif name in ['bicycle','bicycle_rack']:
        if name=='bicycle_rack':
            for x in [-.6,0,.6]:P('Rack upright',(x,0,.43),(.04,.04,.86),'metal');P('Rack return',(x,.42,.43),(.04,.04,.86),'metal');P('Rack top',(x,.21,.86),(.04,.46,.04),'metal')
        else:
            for y in [-.55,.55]:wheel(0,y,.34,.32)
            for y,ang in [(-.23,-.55),(.20,.55)]:
                o=P('Frame tube',(0,y,.52),(.045,.055,.85),'green');o.rotation_euler.x=ang
            P('Seat',(0,.15,.91),(.21,.30,.055),'metal');P('Handlebar',(0,-.55,1.02),(.52,.05,.055),'cream')
    elif name=='road_barrier':
        for x in [-.7,.7]:P('Foot',(x,0,.07),(.35,.65,.14),'metal');P('Post',(x,0,.51),(.055,.055,.9),'cream')
        P('Barrier board',(0,0,.85),(1.7,.12,.25),'gold')
        for x in [-.6,0,.6]:P('Warning stripe',(x,-.07,.85),(.20,.025,.25),'metal')
    elif name in ['litter_bin','recycling_station']:
        for x in ([-.44,.44] if name=='recycling_station' else [0]):
            P('Bin',(x,0,.49),(.68,.58,.98),'green',.045);P('Lid',(x,0,1.01),(.72,.63,.10),'cream',.02)
            P('Opening',(x,-.31,.83),(.44,.025,.15),'metal')
    else:
        box_unit(.80 if 'vending' in name else .58,.6,1.9,'green' if name=='postbox' else 'cream')
        if name=='postbox':P('Mail slot',(0,-.34,1.5),(.39,.025,.06),'metal')
        elif name=='payphone':P('Receiver',(0,-.37,1.3),(.12,.10,.40),'metal');P('Canopy',(0,-.15,2.02),(.8,.9,.12),'blue')
        else:
            P('Display',(0,-.34,1.35),(.51,.025,.63),'blue')
            P('Dispensing slot',(0,-.35,.52),(.44,.03,.19),'metal')
            if 'vending' in name:
                for z in [1.13,1.36,1.59]:
                    for x in [-.16,0,.16]:P('Product',(x,-.365,z),(.10,.045,.12),'gold' if name=='snacks_vending' else 'green')
def coast(name):
    if name in ['lifering_rack','fishing_net_rack']:
        for x in [-.55,.55]:P('Post',(x,0,.9),(.07,.07,1.8),'wood')
        P('Crossbar',(0,0,1.73),(1.3,.08,.08),'wood')
        if name=='lifering_rack':
            C('Ring',(0,-.08,1.18),.37,.10,'red',(math.pi/2,0,0),16)
            C('Ring centre',(0,-.14,1.18),.21,.025,'cream',(math.pi/2,0,0),16)
        else:
            for x in [-.4,-.2,0,.2,.4]:P('Net strand',(x,0,1.0),(.023,.025,1.3),'green')
            for z in [.4,.65,.9,1.15,1.4,1.65]:P('Net strand',(0,0,z),(1.0,.025,.023),'green')
    elif name=='anchor_display':
        P('Plinth',(0,0,.08),(1.1,.6,.16),'cream');P('Shank',(0,0,.8),(.12,.13,1.5),'metal')
        P('Stock',(0,0,1.3),(.8,.12,.10),'metal')
        for x in [-.35,.35]:
            o=P('Fluke',(x,0,.37),(.18,.18,.75),'metal');o.rotation_euler.y=-.6 if x<0 else .6
    elif name in ['mooring_buoy','harbour_beacon']:
        C('Base',(0,0,.3),.48,.6,'red',segments=12);C('Post',(0,0,1.0),.08,1.2,'cream')
        if name=='harbour_beacon':P('Light housing',(0,0,1.6),(.38,.38,.35),'gold',.04)
    elif name=='dock_winch':
        P('Base',(0,0,.15),(1.2,.8,.3),'metal');C('Drum',(0,0,.60),.29,.85,'edge',(0,math.pi/2,0),12)
        for x in [-.48,.48]:C('Flange',(x,0,.60),.40,.06,'green',(0,math.pi/2,0),12)
    elif name=='gangway':
        P('Walkway',(0,0,.17),(1.1,2.6,.20),'wood')
        for x in [-.54,.54]:P('Handrail',(x,0,.98),(.045,2.6,.05),'cream')
        for y in [-1.1,0,1.1]:
            for x in [-.54,.54]:P('Railing post',(x,y,.60),(.045,.045,.78),'cream')
    else:
        for x in [-.36,.36]:
            for z in [.2,.6]:P('Fish box',(x,0,z),(.67,.8,.35),'blue',.02)
def garden(name):
    if name=='wheelbarrow':
        P('Tray',(0,0,.64),(.85,1.,.30),'green',.12);wheel(0,-.50,.27,.26)
        for x in [-.35,.35]:P('Handle',(x,.65,.58),(.055,1.2,.055),'wood');P('Leg',(x,.25,.31),(.05,.06,.6),'metal')
    elif name=='watering_can':
        C('Can',(0,0,.31),.25,.55,'green');o=C('Spout',(.40,0,.34),.045,.60,'green',(0,math.pi/3,0),8)
        P('Handle',(-.32,0,.40),(.05,.09,.40),'metal');P('Handle bridge',(-.22,0,.59),(.25,.09,.045),'metal')
    elif name in ['shovel_rack','garden_trellis']:
        for x in [-.6,.6]:P('Post',(x,0,1.),(.07,.07,2.),'wood')
        for z in [.3,1.,1.8]:P('Rail',(0,0,z),(1.3,.05,.07),'edge')
        for x in [-.4,0,.4]:
            P('Upright',(x,0,1.),(.045,.05,1.8),'wood')
            if name=='shovel_rack':P('Spade',(x,-.04,.25),(.23,.06,.34),'metal',.04)
    elif name in ['seedling_trays','terracotta_pots']:
        frame(1.3,.75,.72)
        for x in [-.43,0,.43]:
            for y in [-.18,.18]:
                C('Pot',(x,y,.85),.13,.21,'wood',segments=8);P('Plant',(x,y,1.05),(.18,.15,.22),'green',.05)
    elif name=='birdbath':C('Pedestal',(0,0,.40),.13,.8,'cream');C('Bowl',(0,0,.84),.45,.15,'cream',segments=16)
    elif name=='water_butt':C('Barrel',(0,0,.60),.43,1.2,'green');C('Lid',(0,0,1.24),.45,.07,'metal');P('Tap',(0,-.46,.3),(.07,.16,.06),'gold')
    else:
        box_unit(.9,.7,1.0,'edge',3 if name=='beehive' else 1)
        if name=='beehive':P('Landing board',(0,-.42,.25),(.73,.24,.055),'wood');P('Roof',(0,0,1.07),(1.03,.85,.12),'cream')
        else:
            for z in [.2,.4,.6,.8]:P('Slat',(0,-.37,z),(.8,.055,.05),'wood')
def construction(name):
    if name=='cement_mixer':
        frame(.9,.7,.65);C('Mixing drum',(0,0,1.1),.42,.75,'gold',(math.pi/3,0,0),14)
        for x in [-.48,.48]:wheel(x,0,.25,.24)
    elif name in ['scaffold','ladder']:
        h=2.5;w=1.2 if name=='scaffold' else .55
        for x in [-w*.5,w*.5]:P('Upright',(x,0,h*.5),(.055,.08,h),'metal')
        for z in [.2,.5,.8,1.1,1.4,1.7,2.,2.3]:P('Rung',(0,0,z),(w,.07,.045),'cream')
        if name=='scaffold':
            P('Platform',(0,0,1.95),(1.45,.85,.08),'wood')
            for x in [-.6,.6]:P('Outrigger',(x,0,.08),(.09,1.1,.08),'metal')
    elif name=='cable_drum':
        C('Cable',(0,0,.55),.43,.75,'metal',(0,math.pi/2,0),16)
        for x in [-.42,.42]:C('Flange',(x,0,.55),.55,.08,'edge',(0,math.pi/2,0),16)
    elif name=='brick_stack':
        P('Pallet',(0,0,.08),(1.25,.8,.16),'wood')
        for row in range(4):
            for x in [-.43,0,.43]:
                for y in [-.23,.23]:P('Brick',(x+(.05 if row%2 else 0),y,.24+row*.17),(.38,.40,.14),'red',.005)
    elif name=='sawhorse':
        P('Beam',(0,0,.83),(1.2,.14,.12),'wood')
        for x in [-.45,.45]:
            for side in [-1,1]:
                o=P('Leg',(x,side*.2,.4),(.08,.08,.86),'edge');o.rotation_euler.x=side*.40
    elif name=='roadworks_sign':
        for x in [-.3,.3]:P('Stand',(x,0,.55),(.045,.09,1.1),'metal')
        P('Sign',(0,0,1.15),(.95,.06,.70),'gold',.025);P('Warning stripe',(0,-.04,1.15),(.13,.02,.5),'metal')
    else:
        frame(.9,.55,.7);P('Toolbox',(0,0,.91),(.73,.45,.35),'red',.025)
        P('Handle',(0,0,1.14),(.30,.05,.05),'metal')
BUILDERS={key:globals()[key] for key in CATALOG}
if __name__=='__main__':
    records=[]
    for theme,names in CATALOG.items():
        for name in names:
            row=a.export(name,lambda n=name,t=theme:BUILDERS[t](n));row['theme']=theme;records.append(row)
    assert len(records)==118
    (a.OUT/'manifest.json').write_text(json.dumps({'provenance':'Original Blender authored furnished props; no third-party sources','assets':records},indent=2))
    print('PLACE_PROPS_COMPLETE',len(records))
