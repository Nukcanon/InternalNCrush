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

# --- 1.4.2 hit marker, melee and slide set -----------------------------------
# Recorded CC0 foley from Kenney "RPG Audio" and "Impact Sounds" (tools/foley/k_*.wav,
# converted to mono 44.1 kHz), trimmed, filtered and layered with generated air.
def fade(values,seconds):
 n=max(1,int(rate*seconds))
 return [v*min(1.,(len(values)-1-i)/n) for i,v in enumerate(values)]
def air(seconds,low,high,seed,swell=1.15):
 # Air past a moving blade or tool: band-limited noise that swells and dies.
 r=random.Random(seed);count=int(rate*seconds)
 noise=[r.uniform(-1,1)*math.sin(math.pi*min(1.,i/count*swell))**2 for i in range(count)]
 return highpass(lowpass(lowpass(noise,high),high),low)
def scrape(seconds,seed):
 # Body sliding over ground: broadband friction with random grit bursts.
 r=random.Random(seed);count=int(rate*seconds);out=[];grit=0.
 for i in range(count):
  t=i/count
  if r.random()<.0035:grit=r.uniform(.4,1.)
  grit*=.9985
  out.append(r.uniform(-1,1)*min(1.,t*14)*(1.-t)**1.3*(.5+.5*grit))
 return highpass(lowpass(lowpass(out,2200),2200),230)
# Hit marker on every bullet that lands: a short unpitched "tuk" (the old
# 0.16 s clip rang at ~640 Hz and turned into "ting-ting-ting" on automatic fire).
tuk=lowpass(sample('k_impactPunch_medium_001',1.3,.075),2400)
write('hit',mix(.08,(fade(tuk,.035),.95,0),(dry_click(.03,921),.22,0)),'hit_volume',-2)
thump=lowpass(sample('k_impactPunch_heavy_000',1.1,.16),1600)
write('confirm',mix(.18,(fade(thump,.07),.9,0),(fade(tuk,.035),.55,.045)),'hit_volume',0)
# Swings: the same 0.22 s for knife and wrench (same attack speed).
blade=highpass(sample('k_drawKnife3',1.3,.18),1800)
knife_swing=mix(.22,(air(.2,700,5200,931),1.,0),(fade(blade,.07),.26,.025))
write('knife_swing',knife_swing,gain=-1)
write('melee_swing',knife_swing,gain=-1)
rattle=highpass(sample('k_metalClick',1.,.1),1500)
write('wrench_swing',mix(.22,(air(.22,170,1400,932,1.05),1.,0),(fade(rattle,.04),.1,.03)),gain=1)
# Knife on a body: a slice with a soft body underneath.
slice_=sample('k_knifeSlice',1.05,.32)
soft_body=lowpass(sample('k_impactPunch_medium_000',1.1,.16),900)
write('knife_flesh',mix(.34,(fade(slice_,.12),.85,0),(fade(soft_body,.06),.42,0)),gain=0)
# Knife on a wall: the blade bites in (chop) with a short metallic tick.
chop=sample('k_chop',1.15,.2)
tick=highpass(sample('k_impactTin_medium_001',1.25,.12),1200)
write('knife_wall',mix(.22,(fade(chop,.06),.8,0),(fade(tick,.05),.32,0)),gain=-1)
# Wrench on a body: a dull, heavy thud.
punch=lowpass(sample('k_impactPunch_heavy_000',.95,.28),1800)
low=sample('k_impactSoft_heavy_000',1.,.25)
write('wrench_flesh',mix(.3,(fade(punch,.1),.9,0),(fade(low,.1),.7,0)),gain=1)
# Wrench repairing a turret: a clear "clang" (the only bright ring in the set).
pot=sample('k_metalPot3',1.05,.5)
ping=highpass(sample('k_impactMetal_medium_000',1.25,.2),900)
write('wrench_repair',mix(.5,(fade(pot,.25),.8,0),(fade(ping,.08),.4,0)),gain=-3)
# Wrench on a wall: a dull clang, lowpassed metal on a wooden knock.
clang=lowpass(sample('k_impactMetal_medium_003',.8,.25),2200)
knock=sample('k_impactWood_heavy_000',1.,.2)
write('wrench_wall',mix(.28,(fade(clang,.12),.85,0),(fade(knock,.08),.6,0)),gain=0)
# Slide: friction over the ground, jacket rustle and the first foot contact.
rustle=highpass(sample('k_cloth1',1.,.6),300)
plant=lowpass(sample('k_footstep_concrete_000',.9,.11),3000)
write('slide',mix(.7,(scrape(.66,941),.85,0),(fade(rustle,.2),.35,.02),(plant,.5,0)),gain=-2)

# --- 1.4.2 LINK beam: continuous hum while connected (medigun / caduceus style) ---
def write_loop(name,values,gain=0):
 # Seamless loop: no edge fades (write() adds them), DC removed, peak headroom.
 mean=sum(values)/len(values);values=[v-mean for v in values];peak=max(map(abs,values));factor=.89/max(.89,peak)
 pcm=array.array('h',(int(max(-.95,min(.95,v*factor))*32767) for v in values))
 if sys.byteorder!='little':pcm.byteswap()
 data=pcm.tobytes()
 with wave.open(str(dest/(name+'.wav')),'wb') as f:f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(data)
 manifest[name]={'file':'res://assets/audio/'+name+'.wav','category':'combat','gain_db':gain,'sha256':hashlib.sha256(data).hexdigest(),'license':'CC0-1.0','duration':round(len(values)/rate,3),'loop':True}
def beam_hum(seconds,base,seed):
 # Every partial and modulator completes whole cycles in `seconds`, and the noise
 # repeats, so filtering three copies and keeping the middle one loops cleanly.
 n=int(rate*seconds);r=random.Random(seed);grain=[r.uniform(-1,1) for _ in range(n)]
 tone=[];air_=[]
 for i in range(3*n):
  t=(i%n)/rate;pulse=.5+.5*math.sin(2*math.pi*3/seconds*2*t)
  hum=math.sin(2*math.pi*base*t)*.55+math.sin(2*math.pi*(base+1/seconds)*t)*.35+math.sin(2*math.pi*base*2*t)*.30+math.sin(2*math.pi*base*3*t)*.10
  sparkle=math.sin(2*math.pi*base*6*t+.9*math.sin(2*math.pi*12/seconds*t))*.07
  tone.append(hum*(.72+.28*pulse)+sparkle*(.5+.5*pulse));air_.append(grain[i%n]*(.55+.45*pulse))
 tone=lowpass(tone,3600);air_=highpass(lowpass(lowpass(air_,5200),5200),1600)
 return [a+b*.22 for a,b in zip(tone[n:2*n],air_[n:2*n])]
write_loop('link_loop',beam_hum(2.,220.,961),gain=-9)
write_loop('repair_loop',beam_hum(2.,165.,962),gain=-10)
def sweep(seconds,f0,f1,seed,rise=True):
 r=random.Random(seed);out=[];phase=0.;count=int(rate*seconds)
 for i in range(count):
  t=i/count;f=f0+(f1-f0)*(t*t*(3-2*t));phase+=2*math.pi*f/rate
  env=math.sin(math.pi*min(1.,t*1.6))**.8 if rise else (1-t)**1.6*min(1.,t*40)
  out.append((math.sin(phase)*.6+math.sin(phase*2)*.25+r.uniform(-1,1)*.18)*env)
 return lowpass(lowpass(out,4200),4200)
# Connect: a rising "wooo" into the hum; disconnect: a short falling release.
write('link_start',mix(.36,(sweep(.34,150,440,963),.9,0),(fade(highpass(sample('k_cloth1',1.6,.2),1500),.1),.12,0)),gain=-6)
write('link_stop',mix(.3,(sweep(.28,440,130,964,False),.8,0)),gain=-8)
