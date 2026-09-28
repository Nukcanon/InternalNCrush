"""Recorded-source combat mix recipes. Executed by build_audio.py in its namespace.
No TTS, per-shot voice inference, runtime synthesis, or unlicensed game extracts.
"""
def gun_family(w):
 if w.get('laser'):return 'laser'
 if w.get('rocket'):return 'rocket'
 if w['kind']=='heal':return 'link'
 category=w.get('category','')
 if w['name']=='CHIME':return 'revolver'
 return {'권총':'pistol','돌격소총':'rifle','기관단총':'smg','기관총':'machinegun','산탄총':'shotgun','저격소총':'sniper','지정사수소총':'dmr','의료 카빈':'medic_rifle','의료 산탄총':'medic_shotgun'}.get(category,'rifle')

for wid,w in weapons.items():
 if w['kind']!='gun' or w.get('rocket') or w.get('laser'):continue
 family=gun_family(w);seed=int(hashlib.sha256(wid.encode()).hexdigest()[:8],16);rng=random.Random(seed)
 source={'pistol':'pistol','revolver':'pistol','smg':'minigun','machinegun':'rifle','rifle':'rifle','sniper':'rifle','dmr':'rifle','shotgun':'shotgun','medic_rifle':'rifle','medic_shotgun':'shotgun'}[family]
 suffix=['','2','3'][seed%3]
 pitch={'pistol':.94,'revolver':.78,'smg':1.20,'machinegun':.92,'rifle':1.04,'sniper':.72,'dmr':.86,'shotgun':.82,'medic_rifle':1.16,'medic_shotgun':.93}[family]*(.94+rng.random()*.12)
 duration={'sniper':.86,'shotgun':.66,'medic_shotgun':.58,'dmr':.60}.get(family,.38)
 blast=sample('q_'+source+suffix,pitch,duration)
 blast=[v*math.exp(-i/rate/(.18 if family in ['sniper','shotgun'] else .12)) for i,v in enumerate(blast)]
 if family=='pistol':blast=lowpass(blast,3800)
 bass=lowpass(sample('shot_01',.8+rng.random()*.25,duration),480)
 body_gain=.13+.12*min(1,w['damage']*w.get('pellets',1)/100)
 layers=[(blast,.88,0),(bass,body_gain,0),(lowpass(blast,2300),.09,.041+rng.random()*.026)]
 if family=='machinegun':
  # The only intentionally bright mechanical trail: quiet ejected links/cases.
  case=sample('impactMetal_light_1',1.75,.07)
  layers.extend([(case,.035,.085),(case,.018,.14)])
 if family.startswith('medic'):
  # Air-valve transient gives the pneumatic medical projectile its own identity.
  air=[rng.uniform(-1,1)*math.exp(-i/rate*48) for i in range(int(rate*.11))]
  layers.append((highpass(lowpass(air,6000),1700),.17,.018))
 output=mix(duration,*layers)
 # Keep sample RMS stable so louder high-damage weapons do not merely have a larger peak.
 rms=math.sqrt(sum(v*v for v in output)/max(1,len(output)))
 output=[v*.10/max(.001,rms) for v in output]
 gain=-7+7*min(1,max(0,(w['damage']*w.get('pellets',1)-10)/110))
 write('gun_'+wid,output,gain=round(gain,2),license='CC-BY-SA-3.0')
 manifest['gun_'+wid]['family']=family

# Cloth/flesh impacts use recorded transients, without the old synthesized drum fundamental.
flesh=highpass(lowpass(sample('impactSoft_medium_000',.92,.15),2300),110)
fabric=highpass(lowpass(sample('footstep_grass_0',1.65,.12),2600),400)
for key,gain in [('hit',0),('confirm',3),('body_impact',-3)]:
 write(key,mix(.16,(flesh,.95,0),(fabric,.26,.008)),'hit_volume' if key!='body_impact' else 'combat',gain)
for suffix,voice in [('', 'hurt_male'),('_female','hurt_female')]:
 grunt=sample(voice,1.,.60)
 armor=lowpass(sample('impactGeneric_light_000',.85,.11),1700)
 write('armor_hurt'+suffix,mix(.62,(grunt,.95,0),(armor,.22,.003)),gain=0)

def dry_click(seconds=.075,seed=913):
 rng=random.Random(seed)
 noise=[rng.uniform(-1,1)*math.exp(-i/rate*95) for i in range(int(rate*seconds))]
 return highpass(lowpass(noise,7800),1400)
def swish(seconds=.28):
 rng=random.Random(914)
 noise=[rng.uniform(-1,1)*math.sin(math.pi*i/(rate*seconds))**1.5 for i in range(int(rate*seconds))]
 return highpass(lowpass(noise,5800),850)
slide=swish()
seat=dry_click(.085,915)
write('ui',mix(.075,(dry_click(),.7,0),(dry_click(.04,916),.25,.022)),'ui_volume',-8)
write('reload',mix(.28,(slide,.75,0)),gain=0)
write('magazine',mix(.11,(seat,.95,0),(dry_click(.05,917),.35,.035)),gain=1)
write('bolt',mix(.18,(swish(.14),.6,0),(seat,.7,.11)),gain=0)
write('shell_insert',mix(.22,(swish(.18),.6,0),(seat,.6,.13)),gain=0)
write('action_close',mix(.11,(seat,.92,0)),gain=0)
write('rocket_insert',mix(.42,(swish(.37),.65,0),(seat,.38,.32)),gain=1)
write('switch',mix(.19,(slide,.38,0),(seat,.34,.07)),gain=-5)
write('bomb_defuse',mix(.32,(slide,.24,0),(seat,.45,.12),(seat,.30,.23)),gain=-5)
write('wrench_repair',mix(.18,(seat,.8,0),(lowpass(sample('impactMetal_heavy_000',1.3,.15),1400),.20,.006)),gain=0)
write('skill',mix(.32,(slide,.4,0),(seat,.25,.05)),gain=-4)

# Non-tonal propulsion/vent textures. No ringing UI sample layered into a firearm.
rng=random.Random(1302)
air=[rng.uniform(-1,1)*(1-math.exp(-i/rate*100))*math.exp(-i/rate*3) for i in range(int(rate*.7))]
write('rocket_flight',highpass(lowpass(air,5200),700),gain=-1)
write('laser_fire',highpass(lowpass([rng.uniform(-1,1)*(.65+.35*math.sin(i/rate*2*math.pi*95)) for i in range(int(rate*.12))],4500),600),gain=-7)
write('laser_vent',highpass(lowpass([rng.uniform(-1,1)*min(1,i/(rate*.04))*max(0,1-i/(rate*2)) for i in range(int(rate*2))],5000),650),gain=-1)
write('heal',mix(.23,(highpass(lowpass(air[:int(rate*.23)],3300),650),.26,0),(seat,.12,0)),gain=-3)
manifest['link_fire']=dict(manifest['heal'])
for key in ['explosion','bomb_explosion']:
 manifest[key]['gain_db']=5 if key=='bomb_explosion' else 4
# Short friction groan plus latch, original mechanically excited noise, not a chime.
rng=random.Random(1303);creak=[]
for i in range(int(rate*.70)):
 t=i/rate;env=math.sin(math.pi*t/.70)**.6
 creak.append((math.sin(2*math.pi*(125*t+8*t*t))*.18+rng.uniform(-1,1)*.13)*env*(.45+.55*abs(math.sin(t*33))))
write('door',mix(.77,(lowpass(creak,1900),.8,0),(seat,.4,.65)),gain=-1)

for wid,w in weapons.items():
 if w.get('rocket'):
  pitch=1.08 if w.get('single_load') else .88
  write('gun_'+wid,mix(.8,(sample('cannon_01',pitch,.8),.7,0),(highpass(lowpass(air,3800),650),.45,.035)),gain=-1 if w.get('single_load') else 1)
  manifest['gun_'+wid]['family']='rocket'
 if w.get('laser'):
  manifest['gun_'+wid]=dict(manifest['laser_fire']);manifest['gun_'+wid]['family']='laser'
write('turret_detect',mix(.16,(seat,.7,0),(slide,.25,.025)),gain=-3)
