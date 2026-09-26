"""Reproducible, sample-based mix. See SOUND_CREDITS.md for source/adaptation licenses.
No network, ffmpeg, or third-party Python modules are needed on build machines.
"""
from pathlib import Path
import array,hashlib,io,json,math,random,sys,wave,zipfile
root=Path(__file__).resolve().parents[1];dest=root/'assets/audio';dest.mkdir(exist_ok=True,parents=True)
rate=44100;manifest={};weapons=json.loads((root/'assets/weapons.json').read_text());sources={}
with zipfile.ZipFile(root/'tools/audio_source.zip') as archive:
 for name in archive.namelist():
  if not name.endswith('.wav'):continue
  with wave.open(io.BytesIO(archive.read(name)),'rb') as source:
   assert source.getnchannels()==1 and source.getsampwidth()==2 and source.getframerate()==rate
   pcm=array.array('h',source.readframes(source.getnframes()))
   if sys.byteorder!='little':pcm.byteswap()
   values=[v/32768 for v in pcm];peak=max(map(abs,values),default=1)
   sources[name[:-4]]=[v*.8/max(.001,peak) for v in values]
# Small recorded human/weapon foley excerpts, normalized offline to mono PCM.
for path in sorted((root/'tools/foley').glob('*.wav')):
 with wave.open(str(path),'rb') as f:
  assert f.getnchannels()==1 and f.getsampwidth()==2 and f.getframerate()==rate
  pcm=array.array('h',f.readframes(f.getnframes()))
  if sys.byteorder!='little':pcm.byteswap()
  values=[v/32768 for v in pcm];peak=max(map(abs,values),default=1)
  sources[path.stem]=[v*.8/max(.001,peak) for v in values]
def sample(name,pitch=1.,seconds=None):
 data=sources[name];count=int(len(data)/pitch)
 if seconds is not None:count=min(count,int(seconds*rate))
 out=[]
 for i in range(count):
  at=i*pitch;idx=int(at);fraction=at-idx
  out.append(data[idx]*(1-fraction)+data[min(idx+1,len(data)-1)]*fraction)
 return out
def lowpass(values,hz):
 alpha=1-math.exp(-2*math.pi*hz/rate);lp=0;out=[]
 for v in values:lp+=alpha*(v-lp);out.append(lp)
 return out
def highpass(values,hz):return [a-b for a,b in zip(values,lowpass(values,hz))]
def mix(duration,*layers):
 out=[0.]*int(duration*rate)
 for values,gain,delay in layers:
  start=int(delay*rate)
  for i,v in enumerate(values[:max(0,len(out)-start)]):out[start+i]+=v*gain
 return out
def write(name,values,category='combat',gain=0,license='CC0-1.0'):
 # Remove DC and leave headroom. Millisecond fades prevent clicks at cut boundaries.
 mean=sum(values)/max(1,len(values));values=[v-mean for v in values];peak=max(map(abs,values),default=1);factor=.89/max(.89,peak)
 for i in range(len(values)):
  values[i]*=factor*min(1,i/44,(len(values)-1-i)/260)
 pcm=array.array('h',(int(max(-.95,min(.95,v))*32767) for v in values))
 if sys.byteorder!='little':pcm.byteswap()
 data=pcm.tobytes()
 with wave.open(str(dest/(name+'.wav')),'wb') as f:f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(data)
 manifest[name]={'file':'res://assets/audio/'+name+'.wav','category':category,'gain_db':gain,'sha256':hashlib.sha256(data).hexdigest(),'license':license,'duration':round(len(values)/rate,3)}
for index,(wid,w) in enumerate(weapons.items()):
 if w['kind']!='gun':continue
 role=int(w['role']);side=w['slot']==1;variant=index%3
 base='pistol' if side else ['rifle','rifle','minigun','shotgun','minigun','rifle'][role]
 suffix=['','2','3'][variant];pitch=(1.04 if side else [.97,.75,.88,.84,1.24,1.10][role])*(.95+(index%5)*.024)
 duration=.45 if side else [.64,.99,.70,.94,.41,.55][role]
 blast=sample('q_'+base+suffix,pitch,duration)
 decay=.095 if side else [.12,.23,.16,.22,.08,.12][role]
 blast=[v*(.05+.95*math.exp(-i/rate/decay)) for i,v in enumerate(blast)]
 bass=lowpass(sample('cannon_01',.95 if side else .74,duration),310)
 action=highpass(sample('impactMetal_light_'+str(variant),1.4,.15),950)
 tail=lowpass(blast,1900)
 output=mix(duration,(blast,.79,0),(bass,.15 if side else .33,0),(action,.13,.055),(tail,.13,.063),(tail,.045,.124))
 write('gun_'+wid,output,gain=-2 if role in [1,3] and not side else -4,license='CC-BY-SA-3.0')
for variant in range(4):
 step=sample('footstep_concrete_'+str(variant),.94+variant*.025,.39)
 gear=highpass(sample('impactGeneric_light_000',1.6+variant*.06,.12),1700)
 write('step_stone_'+str(variant),mix(.42,(step,.82,0),(gear,.045,.07)),gain=-1)
 plate=sample('impactPlate_light_'+str(variant),.74,.35)
 write('step_metal_'+str(variant),mix(.47,(step,.60,0),(plate,.22,.012),(gear,.045,.05)),gain=-1)
 grass=sample('footstep_grass_'+str(variant),.87,.4)
 rng=random.Random(800+variant);noise=[rng.uniform(-1,1)*max(0,math.sin(i/rate/.37*math.pi))**2 for i in range(int(.37*rate))]
 splash=highpass(lowpass(noise,3200),400)
 write('step_water_'+str(variant),mix(.49,(grass,.48,0),(step,.28,0),(splash,.42,.015)),gain=-1)
metal=sample('impactMetal_light_0',1.2,.19);soft=sample('impactSoft_medium_000',1.4,.13);glass=sample('impactGlass_light_000',1.3,.2)
# Dry body/cloth impact: a short low-mid thump, no bright metallic click.
rng=random.Random(706)
body=[]
for i in range(int(.34*rate)):
 t=i/rate
 envelope=(1-math.exp(-t*700))*math.exp(-t*26)
 body.append((math.sin(2*math.pi*(115*t+2.8*(1-math.exp(-t*35))))*.66+rng.uniform(-1,1)*.34)*envelope)
thud=lowpass(sample('impactSoft_medium_000',.58,.34),750)
cloth=lowpass(highpass(sample('footstep_grass_0',.72,.2),180),1250)
write('body_impact',mix(.22,(body,.70,0),(thud,.75,0),(cloth,.18,.006)),gain=0)
for suffix,voice in [('', 'hurt_male'),('_female','hurt_female')]:
 grunt=sample(voice,1.,.60)
 write('hurt'+suffix,mix(.62,(grunt,.95,0),(cloth,.045,.004)),gain=0)
 write('armor_hurt'+suffix,mix(.62,(grunt,.93,0),(lowpass(sample('impactMetal_heavy_000',.95,.13),1100),.12,.004)),gain=0)
write('hit',mix(.19,(body,.65,0),(thud,.55,0),(cloth,.12,.006)),'hit_volume',-1)
write('confirm',mix(.32,(metal,.44,0),(glass,.26,.045)),'hit_volume',-4)
write('ui',sample('ui_click_001',1.15,.12),'ui_volume',-10)
write('switch',mix(.23,(metal,.3,0),(sample('ui_close_001',1.1,.16),.42,.03)),gain=-9)
# Dry sliding fabric, spring/latch and metal close; no UI notification samples.
slide=highpass(lowpass(sample('footstep_grass_1',1.5,.16),3000),650)
catch=highpass(sample('impactMetal_light_1',1.8,.10),650)
write('reload',mix(.19,(slide,.3,0),(catch,.20,.08)),gain=-3)
write('magazine',mix(.26,(slide,.55,0),(sample('impactGeneric_light_000',1.2,.13),.40,.085),(catch,.65,.13)),gain=-1)
write('bolt',mix(.49,(sample('action_rack',2.,.49),.85,0),(catch,.25,.26)),gain=0,license='CC-BY-3.0')
write('action_close',mix(.14,(catch,.62,0),(soft,.25,.008)),gain=-2)
write('shell_insert',sample('shell_load',1.45,.56),gain=0,license='CC-BY-3.0')
write('rocket_insert',mix(.38,(slide,.38,0),(lowpass(sample('impactMetal_heavy_000',.90,.23),1800),.5,.14)),gain=-1)
write('heal',mix(.30,(sample('ui_glass_003',.95,.3),.23,0),(glass,.09,.09)),gain=-13)
write('deploy',mix(.65,(sample('impactMetal_heavy_000',.85,.6),.53,0),(metal,.22,.10)),gain=-5)
write('bomb_beep',[math.sin(i/rate*2*math.pi*1500)*math.sin(math.pi*i/(rate*.09))**.5 for i in range(int(rate*.09))],gain=-12)
write('bomb_defuse',mix(.34,(metal,.45,0),(sample('impactPlate_light_1',1.7,.14),.23,.09),(metal,.25,.21)),gain=-9)
for name in ['bomb_planted','bomb_dropped','bomb_defused']:
 with wave.open(str(root/'tools/announcer'/(name+'.wav')),'rb') as voice:
  assert voice.getframerate()==rate and voice.getnchannels()==1 and voice.getsampwidth()==2
  pcm=array.array('h',voice.readframes(voice.getnframes()))
  if sys.byteorder!='little':pcm.byteswap()
  write(name,[v/32768 for v in pcm],category='announcer',gain=0,license='Windows SAPI generated speech; see SOUND_CREDITS.md')
write('bomb_explosion',mix(3.6,(sample('bang_03',.62,3.2),.7,0),(sample('cannon_01',.42,3.4),.8,.035),(lowpass(sample('cannon_01',.29,3.1),180),.7,.18)),gain=0)
write('explosion',mix(2.1,(sample('bang_03',.87,1.9),.88,0),(sample('cannon_01',.68,2.),.72,.015),(lowpass(sample('cannon_01',.42,1.9),230),.65,.035)),gain=3)
write('flash',mix(.7,(highpass(sample('shot_01',1.3,.6),650),.55,0),(glass,.3,.025)),gain=1)
write('skill',mix(.64,(sample('ui_glass_003',.77,.6),.47,0),(sample('ui_open_002',.75,.5),.30,.06)),gain=-7)
write('smoke',mix(.9,(highpass(sample('shot_01',1.55,.24),500),.62,0),(sample('fw_02',1.15,.85),.3,.07)),gain=0)
# Original short whoosh + low impact for the replay portrait cut (CC0).
rng=random.Random(707)
sting=[]
for i in range(int(.55*rate)):
 t=i/rate
 sweep=rng.uniform(-1,1)*math.sin(min(1,t/.12)*math.pi*.5)*math.exp(-t*24)*.18
 hit=max(0,t-.075)
 impact=(math.sin(2*math.pi*(80*hit+1.8*(1-math.exp(-hit*25))))*.7+rng.uniform(-1,1)*.13)*(1-math.exp(-hit*900))*math.exp(-hit*14) if t>.075 else 0
 sting.append(sweep+impact)
write('kill_sting',lowpass(sting,2200),gain=-4)
# Original short two-tone acquisition chirp; existing effects are unchanged.
alert=[]
for i in range(int(.10*rate)):
 t=i/rate; local=t if t<.045 else t-.055
 envelope=max(0.,math.sin(min(1.,max(0.,local)/.04)*math.pi)) if (t<.04 or t>=.055) else 0.
 alert.append(math.sin(2*math.pi*(1450 if t<.045 else 1850)*t)*envelope*.32)
write('turret_detect',alert,gain=-4)
# Original melee cues use existing licensed sources, preserving all gun/hit audio.
rng=random.Random(122)
wind=[rng.uniform(-1,1)*math.sin(math.pi*i/(rate*.18))**1.5 for i in range(int(rate*.18))]
write('melee_swing',highpass(lowpass(wind,5000),600),gain=1)
write('melee_flesh',mix(.24,(body,.68,0),(thud,.85,0),(cloth,.2,.006)),gain=1)
write('rocket_launch',mix(.9,(sample('cannon_01',1.15,.9),.65,0),(sample('fw_02',.7,.8),.5,.05)),gain=-2)
write('flash_ring',[math.sin(2*math.pi*2300*i/rate)*.22*min(1.,i/(rate*.02))*min(1.,(rate*4.5-i)/(rate*.7)) for i in range(int(rate*4.5))],gain=-10)
write('knife_wall',mix(.24,(metal,.48,0),(sample('impactPlate_light_1',1.5,.22),.32,.025)),gain=-5)
write('wrench_wall',mix(.30,(sample('impactMetal_heavy_000',1.05,.30),.62,0),(metal,.20,.04)),gain=-4)
(root/'assets/audio_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('AUDIO_BUILT',len(manifest),'sample-based clips;',sum(k.startswith('gun_') for k in manifest),'distinct weapon mixes')

