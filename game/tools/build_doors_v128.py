"""Original door leaves. Common 1.15 x 2.8 m opening, 30 distinct designs.
Frames, collision, interaction and motion are supplied by InteractiveDoor.
"""
import sys,pathlib,json,math
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
import build_themed_props as a
P=a.part;C=a.cylinder
ROOT=pathlib.Path(__file__).resolve().parents[1]
a.OUT=ROOT/'assets/models/doors_original';a.SOURCE=ROOT.parent/'art_source/doors_original'
a.OUT.mkdir(parents=True,exist_ok=True);a.SOURCE.mkdir(parents=True,exist_ok=True)
STYLES=['wood_panel','wood_plank','cottage','arched_plank','barn_cross','sliding_shoji','glass_store','frosted_office','lab_observation','hospital_swing','fire_exit','steel_security','warehouse_shutter','loading_bay','container','submarine','ship_bulkhead','maintenance_louver','server_access','vault','cell_gate','chain_gate','garden_gate','ornate_gate','station_ticket','school_classroom','hotel_panel','restroom','cold_store','garage_fold']
def leaf(style):
    timber=style in ['wood_panel','wood_plank','cottage','arched_plank','barn_cross','sliding_shoji','garden_gate','ornate_gate','school_classroom','hotel_panel']
    colour='wood' if timber else 'cream' if style in ['hospital_swing','cold_store','lab_observation','restroom'] else 'green' if style in ['fire_exit','station_ticket'] else 'blue'
    P('Solid leaf',(0,0,1.4),(1.15,.14,2.8),colour,.018)
    for face in [-1,1]:
        y=face*.09
        if style in ['wood_panel','cottage','hotel_panel']:
            for z,h in ([(.65,.83),(1.9,1.17)] if style!='hotel_panel' else [(.55,.60),(1.32,.60),(2.1,.60)]):
                P('Raised inset',(0,y,z),(.87,.045,h),'edge',.025)
                P('Panel centre',(0,y+face*.028,z),(.74,.015,h-.13),colour,.01)
        elif style in ['wood_plank','arched_plank','barn_cross','garden_gate']:
            for x in [-.44,-.22,0,.22,.44]:P('Individual plank',(x,y,1.4),(.20,.04,2.64),'edge',.006)
            for z in [.45,2.35]:P('Brace',(0,y+face*.04,z),(1.06,.06,.12),'metal')
            if style in ['barn_cross','garden_gate']:
                for angle in [-.42,.42]:
                    o=P('Diagonal brace',(0,y+face*.065,1.4),(.10,.07,2.1),'wood');o.rotation_euler.y=angle
            if style=='arched_plank':
                for i in range(9):
                    theta=math.pi*i/8;P('Arch studs',(.43*math.cos(theta),y+face*.06,2.20+.35*math.sin(theta)),(.045,.035,.045),'gold')
        elif style in ['warehouse_shutter','maintenance_louver','garage_fold','loading_bay','container']:
            if style in ['container','garage_fold']:
                for x in [-.44,-.22,0,.22,.44]:P('Vertical rib',(x,y,1.4),(.065,.065,2.6),'cream')
                if style=='container':
                    for x in [-.30,.30]:C('Locking bar',(x,y+face*.05,1.4),.027,2.5,'metal',segments=8)
            else:
                for i in range(16 if style=='warehouse_shutter' else 10):
                    P('Horizontal louver',(0,y,.2+i*(.16 if style=='warehouse_shutter' else .26)),(1.02,.06,.06),'metal' if i%2 else 'cream')
        elif style in ['submarine','ship_bulkhead','vault']:
            P('Reinforced centre',(0,y,1.4),(.95,.11,2.48),'metal',.10)
            C('Wheel rim',(0,y+face*.12,1.35),.29,.045,'cream',(math.pi/2,0,0),16)
            C('Wheel hub',(0,y+face*.16,1.35),.075,.08,'gold',(math.pi/2,0,0),10)
            for x in [-.43,.43]:
                for z in [.35,1.4,2.45]:P('Locking dog',(x,y+face*.09,z),(.13,.10,.10),'gold')
            if style!='vault':C('Porthole',(0,y+face*.08,2.12),.24,.035,'blue',(math.pi/2,0,0),16)
            else:P('Keypad',(.29,y+face*.15,1.95),(.18,.06,.30),'green')
        elif style in ['cell_gate','chain_gate','ornate_gate']:
            P('Dark backing',(0,y,1.5),(.95,.025,2.3),'metal')
            for x in [-.4,-.2,0,.2,.4]:P('Bars',(x,y+face*.045,1.5),(.038,.05,2.3),'cream' if style=='cell_gate' else 'gold')
            for z in [.4,1.5,2.6]:P('Crossbar',(0,y+face*.04,z),(1.02,.06,.04),'gold')
            if style=='chain_gate':
                for z in [.7,1.0,1.3,1.6,1.9,2.2]:P('Mesh rail',(0,y+face*.025,z),(.94,.03,.018),'cream')
            if style=='ornate_gate':C('Crest',(0,y+face*.065,1.8),.20,.03,'gold',(math.pi/2,0,0),12)
        else:
            glass_height=1.6 if style in ['glass_store','frosted_office','sliding_shoji'] else .65
            P('Window frame',(0,y,1.9),(.90,.06,glass_height+.12),'metal')
            P('Frosted glazing',(0,y+face*.04,1.9),(.77,.025,glass_height),'cream' if style=='sliding_shoji' else (.20,.45,.46,1))
            if style=='sliding_shoji':
                for x in [-.27,0,.27]:P('Lattice',(x,y+face*.06,1.9),(.03,.035,glass_height),'wood')
                for z in [1.35,1.62,1.9,2.17,2.44]:P('Lattice',(0,y+face*.06,z),(.80,.035,.035),'wood')
            if style in ['lab_observation','server_access','steel_security']:
                P('Reader',(.36,y+face*.10,1.20),(.16,.09,.25),'metal')
                P('Reader status',(.36,y+face*.15,1.24),(.10,.014,.08),'green')
            if style in ['hospital_swing','cold_store']:
                P('Kick plate',(0,y+face*.03,.29),(1.02,.035,.47),'metal')
            if style in ['restroom','school_classroom','station_ticket']:
                P('Nameplate',(0,y+face*.06,2.5),(.48,.025,.13),'gold')
        if style=='fire_exit':P('Panic bar',(0,y+face*.10,1.15),(.91,.11,.07),'cream')
        else:P('Pull handle',(.39,y+face*.14,1.16),(.055,.07,.33),'gold' if timber else 'cream',.012)
if __name__=='__main__':
    records=[a.export('door_'+style,lambda s=style:leaf(s)) for style in STYLES]
    (a.OUT/'manifest.json').write_text(json.dumps({'provenance':'Original Blender authored doors; no third-party sources','assets':records},indent=2))
    print('DOORS_COMPLETE',len(records))
