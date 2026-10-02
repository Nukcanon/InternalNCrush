"""1.5.0 combat audio (the user's reference videos, analysed for their character
only - nothing from them is used): gunshots with a hard transient, a mid-range
body and an outdoor echo tail; deep rocket launches and explosions with long
rumbles; a roaring rocket flight; metallic reload clicks from the recorded CC0
foley instead of filtered-noise swishes; a grenade pin, throw and bounce.
Executed by build_audio.py in its namespace, after every earlier recipe, so
these win. Only the credited sources (SOUND_CREDITS.md) are used.
"""
def excerpt(name,start,seconds,pitch=1.):
 data=sample(name,pitch);a=int(start*rate/pitch);return data[a:a+int(seconds*rate)]
def env_decay(values,tau,attack=.0015):
 return [v*min(1.,i/(rate*attack+1))*math.exp(-i/rate/tau) for i,v in enumerate(values)]
def sharp(values,lead=.002):
 # start just before the loudest part's onset (no slow pre-roll)
 peak=max(map(abs,values),default=1.);first=next((i for i,v in enumerate(values) if abs(v)>.25*peak),0)
 return values[max(0,first-int(lead*rate)):]
def noise(seconds,seed):
 r=random.Random(seed);return [r.uniform(-1,1) for _ in range(int(rate*seconds))]
def reverb(values,seconds,damp=2400.,length=None):
 # Schroeder: four damped combs into two allpasses; RT60 = `seconds`.
 n=int(rate*(length if length else len(values)/rate+seconds));src=values+[0.]*(n-len(values))
 out=[0.]*n
 for ms in (29.7,37.1,41.1,43.7):
  d=int(rate*ms/1000.);g=10**(-3*ms/1000./seconds);buf=[0.]*d;k=0;lp=0.;a=1-math.exp(-2*math.pi*damp/rate)
  for i in range(n):
   y=buf[k];lp+=a*(y-lp);buf[k]=src[i]+lp*g;out[i]+=y*.25;k=(k+1)%d
 for ms,g in ((5.,.7),(1.7,.7)):
  d=int(rate*ms/1000.);buf=[0.]*d;k=0;res=[0.]*n
  for i in range(n):
   b=buf[k];x=out[i]+g*b;res[i]=b-g*x;buf[k]=x;k=(k+1)%d
  out=res
 return out
def normalize_rms(values,target):
 rms=math.sqrt(sum(v*v for v in values)/max(1,len(values)));return [v*target/max(.0005,rms) for v in values]

# --- gunshots --------------------------------------------------------------
TAIL={'pistol':.75,'revolver':1.0,'smg':.7,'machinegun':.8,'rifle':.9,'sniper':1.6,'dmr':1.15,'shotgun':1.25,'medic_rifle':.7,'medic_shotgun':1.0}
BODY_TAU={'pistol':.05,'revolver':.08,'smg':.04,'machinegun':.06,'rifle':.06,'sniper':.12,'dmr':.09,'shotgun':.11,'medic_rifle':.05,'medic_shotgun':.09}
for wid,w in weapons.items():
 if w['kind']!='gun' or w.get('rocket') or w.get('laser'):continue
 family=gun_family(w);seed=int(hashlib.sha256((wid+'v150').encode()).hexdigest()[:8],16);rng=random.Random(seed)
 source={'pistol':'pistol','revolver':'pistol','smg':'minigun','machinegun':'rifle','rifle':'rifle','sniper':'rifle','dmr':'rifle','shotgun':'shotgun','medic_rifle':'rifle','medic_shotgun':'shotgun'}[family]
 suffix=['','2','3'][seed%3]
 power=min(1.,w['damage']*w.get('pellets',1)/120.)
 pitch={'pistol':1.0,'revolver':.8,'smg':1.15,'machinegun':.9,'rifle':1.0,'sniper':.74,'dmr':.86,'shotgun':.8,'medic_rifle':1.1,'medic_shotgun':.92}[family]*(.95+rng.random()*.1)
 length=TAIL[family]
 core=sharp(sample('q_'+source+suffix,pitch,.6))
 body=env_decay(lowpass(lowpass(core,2600),2600),BODY_TAU[family])
 snap=env_decay(highpass(noise(.02,seed),1800),.0025,.0003)
 thump=env_decay(lowpass(lowpass(sharp(sample('shot_01',.75+rng.random()*.15,.5)),170),170),.07+.06*power)
 dry=mix(length,(body,1.,0),(snap,.30+.15*(1-power),0),(thump,.35+.55*power,0))
 if family=='machinegun':
  case=sample('impactMetal_light_1',1.75,.07);dry=mix(length,(dry,1.,0),(case,.03,.09))
 if family.startswith('medic'):
  dry=mix(length,(dry,1.,0),(highpass(lowpass(env_decay(noise(.11,seed+1),.02),6000),1700),.15,.018))
 # the outdoor echo: a darker, later copy that rings out over `length`
 tail=reverb(lowpass(dry[:int(rate*.12)],1900),length*.85,1800.,length)
 out=mix(length,(dry,1.,0),(tail,.38+.12*power,.012))
 out=highpass(highpass([v*min(1.,(len(out)-i)/(rate*.08)) for i,v in enumerate(out)],55),55) # (no sub-sonic drift from the filtered layers)
 # level set by the shot itself (first 0.25 s), so the tail's length does not change it
 head=out[:int(rate*.25)];scale=.16/max(.0005,math.sqrt(sum(x*x for x in head)/len(head)));out=[v*scale for v in out]
 gain=-7+7*min(1,max(0,(w['damage']*w.get('pellets',1)-10)/110))
 write('gun_'+wid,out,gain=round(gain,2),license='CC-BY-SA-3.0')
 manifest['gun_'+wid]['family']=family

# --- rockets -----------------------------------------------------------------
for wid,w in weapons.items():
 if not w.get('rocket'):continue
 r=random.Random(1501+len(wid))
 boom=env_decay(lowpass(lowpass(sharp(sample('cannon_01',.62 if w.get('single_load') else .55,1.4)),210),210),.32,.004)
 ignite=env_decay(highpass(sharp(sample('fw_02',.9,.5)),700),.09)
 # the motor's whoosh: noise whose band slides down as the rocket leaves
 count=int(rate*1.2);hiss=[];lp=0.;hp=0.
 src=noise(1.2,1502)
 for i in range(count):
  t=i/count;cut=1600-1100*t;a=1-math.exp(-2*math.pi*cut/rate);lp+=a*(src[i]-lp);hp+=.02*(lp-hp)
  hiss.append((lp-hp)*min(1.,t*25)*(1-t)**1.4)
 dry=mix(2.6,(boom,1.8,0),(ignite,.1,0),(hiss,.14,.02))
 tail=reverb(lowpass(dry[:int(rate*.35)],700),2.2,900.,2.6)
 out=mix(2.6,(dry,1.,0),(tail,.42,.02))
 out=highpass(highpass([v*min(1.,(len(out)-i)/(rate*.2)) for i,v in enumerate(out)],32),32)
 write('gun_'+wid,out,gain=1 if w.get('single_load') else 2)
 manifest['gun_'+wid]['family']='rocket'
# Flight: a rough roar (not a thin hiss), re-triggered every 0.5 s with overlap.
src=noise(.62,1503);roar=[];lp=0.;lp2=0.
for i,v in enumerate(src):
 t=i/len(src);lp+=.09*(v-lp);lp2+=.012*(v-lp2)
 roar.append(((lp-lp2)*1.6+lp2*.9)*(.75+.25*math.sin(i/rate*2*math.pi*23))*math.sin(math.pi*t)**.6)
write('rocket_flight',highpass(lowpass(roar,2400),120),gain=-2)

# --- explosions ----------------------------------------------------------------
def blast(scale,seconds,seed):
 deep=env_decay(lowpass(lowpass(sharp(sample('cannon_01',.45*scale,seconds)),130),130),.55*seconds/3.,.006)
 mid=env_decay(lowpass(sharp(sample('bang_03',.75*scale,1.6)),1100),.35)
 crack=env_decay(highpass(sharp(sample('bang_03',1.,.3)),1600),.05)
 rumble=env_decay(lowpass(lowpass(noise(seconds,seed),85),85),seconds*.33,.03)
 dry=mix(seconds,(deep,1.,0),(mid,.55,0),(crack,.22,0),(rumble,2.2,.01))
 tail=reverb(lowpass(dry[:int(rate*.5)],500),seconds*.8,600.,seconds)
 out=mix(seconds,(dry,1.,0),(tail,.35,.03))
 return highpass(highpass([v*min(1.,(len(out)-i)/(rate*.35)) for i,v in enumerate(out)],30),30)
write('explosion',blast(1.,3.2,1504),gain=4)
write('bomb_explosion',blast(.85,4.2,1505),gain=5)

# --- grenade -------------------------------------------------------------------
pin_click=sharp(excerpt('k_metalClick',.24,.12))
write('pin',mix(.3,(highpass(pin_click,900),.9,0),(env_decay(highpass(sample('k_impactTin_medium_002',1.5,.12),1500),.06),.35,.035),(reverb(highpass(pin_click[:int(rate*.03)],2500),.25,5000.,.25),.12,.01)),gain=-4)
whoosh=highpass(lowpass(lowpass([v*math.sin(math.pi*min(1.,i/(rate*.3)))**1.6 for i,v in enumerate(noise(.3,1506))],1900),1900),220)
write('throw',mix(.32,(whoosh,1.,0),(env_decay(highpass(sample('k_cloth1',1.3,.2),600),.08),.25,0)),gain=0)
clunk=env_decay(lowpass(sharp(sample('k_impactMetal_medium_003',.9,.3)),3200),.08)
write('bounce',mix(.3,(clunk,.85,0),(env_decay(lowpass(sharp(sample('k_impactWood_heavy_000',1.1,.2)),900),.05),.6,0),(env_decay(highpass(sample('k_impactTin_medium_001',1.2,.1),1500),.03),.25,.004)),gain=-1)

# --- reloads: metal clicks from the recorded foley -----------------------------------
click=highpass(sharp(excerpt('k_metalClick',.24,.14)),1100)
write('reload',mix(.34,(highpass(sample('mag_release_z',1.,.34),300),.9,0),(click,.4,.035)),gain=-1)
seat_click=highpass(sharp(excerpt('clipload1_b',.05,.2)),400)
write('magazine',mix(.32,(highpass(excerpt('mag_insert_z',.12,.3),350),.75,0),(seat_click,.7,.02),(env_decay(highpass(sample('rd_metal_hit03',1.25,.12),1800),.03),.25,.024)),gain=-1)
rack=highpass(sharp(excerpt('action_rack',0.,.62)),250)
write('bolt',[v*min(1.,(len(rack)-i)/(rate*.08)) for i,v in enumerate(rack)],gain=-2)
shell=highpass(excerpt('shell_load',.4,.34),300)
write('shell_insert',mix(.34,(shell,.9,0),(click,.15,.03)),gain=-2)
close=lowpass(highpass(sharp(excerpt('rack_dry',.86,.26)),400),4200)
write('action_close',close,gain=-3)
