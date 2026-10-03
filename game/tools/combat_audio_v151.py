"""1.5.1 sounds the user chose from their own files (tools/foley/user_*.wav, cut
from the clips they supplied): the rocket launch, flight and explosion a little
lower; the shotgun's shell and pump a little lower; the rocket reload louder with
a room tail; the ARC beam from a laser-weld recording with its sharp edges eased.
The LINK heal hum (a medigun-like swirling buzz) and the FIX welding arc are
synthesized here. Executed by build_audio.py after combat_audio_v150.py.
"""
LOW=.94 # "a little lower" (the user): tape-speed pitch, about one semitone
def faded(values,head=.004,tail=.04):
 n=len(values);h=max(1,int(rate*head));t=max(1,int(rate*tail))
 return [v*min(1.,i/h,(n-1-i)/t) for i,v in enumerate(values)]
def seamless(values,fade):
 # loop body: the tail that runs past the loop length is blended into its head
 n=len(values)-fade;out=values[:n]
 for i in range(fade):
  k=i/fade;out[i]=values[i]*k+values[n+i]*(1-k)
 return out
def soften(values,drive=2.2):
 # rounds the sharp spikes (soft clip) after a gentle top cut
 peak=max(map(abs,values),default=1.);k=math.tanh(drive)
 return [math.tanh(v/peak*drive)/k*peak for v in values]

# --- rockets (user_rocket: launch at 0.02 s, explosion from 1.52 s) -----------------
# (each launcher a touch apart in pitch: every attack weapon keeps its own sound file)
for k,wid in enumerate(sorted(w for w in weapons if weapons[w].get('rocket'))):
 p=LOW*(1.-.035*k)
 write('gun_'+wid,faded(excerpt('user_rocket',.02,1.08/p,p),.002,.25),gain=2);manifest['gun_'+wid]['family']='rocket'
# flight: the launch's own fading whoosh, re-triggered every 0.5 s (CombatFx.sync_rockets)
whoosh=excerpt('user_rocket',.18,.52/LOW,LOW)
level=math.sqrt(sum(v*v for v in whoosh)/len(whoosh))
whoosh=[v*.16/max(.0005,level) for v in whoosh]
write('rocket_flight',faded(whoosh,.12,.2),gain=-2)
# (round 2, the user: too loud for a rocket - it is the planted bomb's blast now, louder;
# the rocket keeps the 1.5.0 explosion)
write('bomb_explosion',faded(excerpt('user_rocket',1.52,2.62/LOW,LOW),.001,.5),gain=7)
write('rocket_explosion',blast(1.,3.2,1504),gain=8) # (round 3: louder)

# --- shotgun shell loading (user_shotgun_reload) -----------------------------------
write('shell_insert',faded(excerpt('user_shotgun_reload',.08,.32/LOW,LOW),.002,.05),gain=2) # (round 2: louder)
write('pump',faded(excerpt('user_shotgun_reload',3.18,.50/LOW,LOW),.002,.06),gain=-1)

# --- rocket reload: louder, with a room tail -----------------------------------------
# (round 2: then the user's pipe swing and pipe bang, each starting just before the one
# before it ends, so the three run on without a gap)
slide=excerpt('user_rocket_reload',.05,.40);swing=sample('user_pipe_swing');bang=sample('user_pipe_bang')
dry=mix(1.25,(slide,1.,0),(swing,.75,.30),(bang,.12,.30+.17)) # (1.5.2: the last bang well down, about 17 dB)
write('rocket_insert',mix(2.3,(dry,1.,0),(reverb(lowpass(dry,3200),1.3,1800.,2.3),.55,.01)),gain=3)

# --- ARC beam: the weld recording, spikes rounded, as a loop --------------------------
weld=sample('user_laser_weld')
weld=highpass(lowpass(lowpass(weld,5200),5200),140)
# (round 2: mixed with the user's 80s power-up, its edges rounded as well)
power=highpass(lowpass(lowpass(sample('user_powerup'),4200),4200),160)
n=min(len(weld),len(power))
write_loop('laser_loop',seamless([w*.8+v*.45 for w,v in zip(soften(weld)[:n],soften(power)[:n])],int(rate*.3)),gain=-6)

# --- LINK heal: a swirling electric hum (2 s loop, every rate a whole cycle) -----------
def medigun(seconds=2.):
 out=[]
 for i in range(int(rate*seconds)):
  t=i/rate;sw=math.sin(2*math.pi*1.*t)
  hum=0.
  for h,amp in ((1,1.),(2,.6),(3,.42),(4,.3),(5,.2),(7,.12),(9,.07)):
   hum+=amp*math.sin(2*math.pi*110*h*t+.45*math.sin(2*math.pi*5*t)*h**.5)
  zing=math.sin(2*math.pi*1320*t+2.2*math.sin(2*math.pi*6*t))*(.55+.45*math.sin(2*math.pi*3*t))
  ring=math.sin(2*math.pi*660*t+1.1*sw)
  out.append(hum*.34*(.82+.18*math.sin(2*math.pi*12*t))+zing*.16+ring*.12)
 return lowpass(out,3600)
# (round 2, the user's power-charge: its middle, the sharp top cut away, as the loop)
charge=highpass(lowpass(lowpass(sample('user_charge'),2600),2600),90)
write_loop('link_loop',seamless(soften(charge,1.6),int(rate*.5)),gain=-14) # (round 3: much quieter; round 4/5: louder again; rounds 6-8: down 3, 2 and 2 dB; 1.5.2: 2 dB more)

# --- FIX repair: a welding arc - crackle, hiss and a mains buzz (loop) -------------
def welding(seconds=2.4,seed=1511):
 r=random.Random(seed);n=int(rate*seconds);out=[0.]*n
 # crackle: short decaying clicks, denser in bursts
 i=0
 while i<n:
  burst=.5+.5*math.sin(2*math.pi*1.7*i/rate+r.uniform(0,.3))
  i+=int(rate/(180+420*burst)*r.uniform(.3,1.7))
  if i>=n:break
  amp=r.uniform(.25,1.)*(.4+.6*burst);tau=r.uniform(.0006,.003)
  for k in range(int(rate*tau*6)):
   if i+k<n:out[i+k]+=amp*math.exp(-k/(rate*tau))*r.uniform(-1,1)
 crackle=highpass(lowpass(out,7200),1400)
 hiss=highpass(noise(seconds,seed+1),3000)
 sizzle=[h*(.35+.25*math.sin(2*math.pi*.9*j/rate)+.1*r.uniform(-1,1)) for j,h in enumerate(hiss)]
 buzz=[(1. if math.sin(2*math.pi*100*j/rate)>0 else -1.)*.5+math.sin(2*math.pi*200*j/rate)*.3 for j in range(n)]
 return [c*.9+s*.35+b*.05 for c,s,b in zip(crackle,sizzle,lowpass(buzz,900))]
write_loop('repair_loop',seamless(welding(),int(rate*.4)),gain=-9)

# --- round 2: melee, hits and hurt voices (the user's files) ------------------------
def kept_gain(key,shift=0.):
 return round(float(manifest.get(key,{}).get('gain_db',0))+shift,1)
def written(key):
 with wave.open(str(dest/(key+'.wav')),'rb') as f:
  pcm=array.array('h',f.readframes(f.getnframes()))
 if sys.byteorder!='little':pcm.byteswap()
 return [v/32768 for v in pcm]
# (both swings last the same, as the attacks do: the knife's tail trimmed, the wrench's padded)
def fit(values,seconds):
 n=int(rate*seconds);return (values+[0.]*n)[:n]
sword=sample('user_sword')
write('knife_swing',sword,gain=kept_gain('knife_swing')) # (1.5.2: the user's sword swing as it is - only its leading silence cut)
write('knife_flesh',faded(sample('user_knife_stab'),.002,.04),gain=kept_gain('knife_flesh'))
write('wrench_swing',fit(faded(sample('user_swing'),.003,.05),len(sword)/rate),gain=kept_gain('wrench_swing')) # (padded to the sword's length)
write('wrench_flesh',faded(sample('user_wood_hit'),.002,.1),gain=kept_gain('wrench_flesh'))
write('body_impact',faded(sample('user_bullet_hit'),.001,.08),gain=kept_gain('body_impact'))
# hurt: four short "oof"s a little quieter (one picked at random, AudioBank.variant_stream);
# the armoured hit keeps its plate clank under the voice
def voices(key,clips,shift,armour=None):
 g=kept_gain(key,shift)
 for k,clip in enumerate(clips):
  out=clip if armour is None else mix(max(len(clip),len(armour))/rate,(clip,1.,0),(armour,.55,0))
  write(key if k==0 else key+'_v%d'%k,faded(out,.002,.05),gain=g)
 manifest[key]['variants']=len(clips)
male=[sample('user_oof_%d'%k) for k in range(4)]
female=[sample('user_female_hurt',p) for p in (1.,.95,1.06,1.12)]
clank=written('armor_hurt');clank_f=written('armor_hurt_female')
voices('hurt',male,-2.);voices('armor_hurt',male,-2.,clank)
voices('hurt_female',female,2.);voices('armor_hurt_female',female,2.,clank_f)

# --- round 3 -----------------------------------------------------------------------
# a pistol's magazine seating (the user's clip: the magazine slides in and clicks home)
write('pistol_magazine',faded(sample('user_pistol_mag'),.002,.03),gain=kept_gain('magazine',1.))
# the wrench on a friendly turret or cover: an impact wrench's burst, kept moderate
write('wrench_repair',faded(highpass(sample('user_impact_wrench'),120),.004,.06),gain=kept_gain('wrench_repair',-4.))

# --- round 4 -----------------------------------------------------------------------
# rocket and grenade blasts: the user's explosion, its long tail cut to ~2.3 s, punchier
boom=sample('user_explosion')
boom=[v*(1. if i<rate*.9 else math.exp(-(i-rate*.9)/(rate*.45))) for i,v in enumerate(boom[:int(rate*2.3)])]
boom=soften(boom,1.8)
write('explosion',faded(boom,.001,.15),gain=5)
write('rocket_explosion',faded(boom,.001,.15),gain=5)
# held skill sounds, heard round the hero while the skill lasts (Actor.update_skill_hums)
write_loop('invulnerable_loop',seamless(lowpass(sample('user_mech_powerup'),5000),int(rate*.45)),gain=-9)
# (round 5, the user: the shield's loop repeated too plainly) a 12 s weave of different
# stretches of the clip, each a little higher or lower, faded in and out over each other
def weave(name,seconds,pieces,fade=.5):
 out=[0.]*int(rate*seconds);at=0.;k=0
 while at<seconds:
  start,length,pitch=pieces[k%len(pieces)];k+=1
  piece=excerpt(name,start,length,pitch);n=len(piece);f=int(rate*fade)
  piece=[v*min(1.,i/f,(n-1-i)/f) for i,v in enumerate(piece)]
  a=int(at*rate)
  for i,v in enumerate(piece):out[(a+i)%len(out)]+=v
  at+=length-fade
 return out
shield=weave('user_energy_charge',12.,[(.05,1.7,1.),(.9,1.6,.95),(.4,1.8,1.05),(1.2,1.5,.98),(.2,1.7,1.03),(.7,1.6,.93),(1.0,1.7,1.07)])
# (round 6, the user: not that - a deep transformer "boooom" hum instead) synthesized: a
# 60 Hz mains hum with its harmonics, the 120 Hz magnetostriction buzz on top, a slow swell;
# every frequency makes whole cycles in 4 s, so it loops without a seam
def transformer(seconds=4.):
 # (three loops' worth filtered, the middle one kept: a filter started cold clicked at the seam)
 out=[]
 for i in range(int(rate*seconds*3)):
  t=i/rate;swell=.78+.22*math.sin(2*math.pi*.5*t)
  hum=0.
  for h,amp in ((1,1.),(2,.85),(3,.5),(4,.42),(5,.22),(6,.2),(8,.1),(10,.06)):
   hum+=amp*math.sin(2*math.pi*60*h*t+h*.7+.25*math.sin(2*math.pi*.25*t))
  buzz=math.tanh(math.sin(2*math.pi*120*t)*3.)*.22
  out.append((math.tanh(hum*.55)*.9+buzz)*swell)
 n=int(rate*seconds);return lowpass(lowpass(out,1800),1800)[n:2*n]
write_loop('shield_loop',transformer(),gain=-16) # (round 7: louder; 1.5.2: 2 dB down; 1.5.3: 11 dB more)

# --- 1.5.3 -------------------------------------------------------------------------
# a round stopped by the heavy's shield: the user's elevator power-down ding, 1.5x as fast, 4 dB down
ding=sample('user_shield_ding',1.5)
write('shield_block',faded(ding,.001,.01),gain=-4)
# a throwable's bounce off the ground 8 dB quieter
manifest['bounce']['gain_db']=kept_gain('bounce',-8.)
# the weapon switch (the user's pick, candidate C): a quick cloth swish and a crisp click - the
# magazine-release click a little lower - at the level the old switch sound had
def onset(values,floor=.03):
 peak=max(map(abs,values),default=1.);first=next((i for i,v in enumerate(values) if abs(v)>floor*peak),0)
 return values[max(0,first-40):]
def clipped(values,seconds,fade):
 v=values[:int(rate*seconds)];f=int(rate*fade);return [s*min(1.,i/44,(len(v)-1-i)/f) for i,s in enumerate(v)]
def rms(values):return math.sqrt(sum(v*v for v in values)/max(1,len(values)))
before=rms(written('switch'))
swap=mix(.32,(clipped(onset(sample('k_cloth1',1.3)),.16,.05),.45,0),(clipped(onset(sample('mag_release_z',.9)),.14,.04),.6,.09))
write('switch',[v*before/max(1e-6,rms(swap)) for v in swap],gain=kept_gain('switch'))

# --- 1.5.4 ---------------------------------------------------------------------------
# putting the armour plate on (the user's own clip: clothes dropping), at the level the old deploy cue had
clothes=faded(fit(sample('user_clothes_drop'),.7),.002,.15)
level=rms(written('deploy'))
write('plate_on',[v*level/max(1e-6,rms(clothes))*1.4 for v in clothes],gain=kept_gain('deploy'))
