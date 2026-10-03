"""1.5.4 sounds from the user's own clips (tools/foley/user_*.wav) and Kenney's RPG Audio
(CC0, tools/foley/k_door*.wav / k_creak*.wav). Executed by build_audio.py after
combat_audio_v151.py, whose helpers (faded, fit, rms, written, kept_gain, onset, ...) it uses.
"""
def biquad_lowpass(values,hz,q=.7071):
 w=2*math.pi*hz/rate;alpha=math.sin(w)/(2*q);c=math.cos(w);a0=1+alpha
 b0=(1-c)/2/a0;b1=(1-c)/a0;b2=b0;a1=-2*c/a0;a2=(1-alpha)/a0
 out=[];x1=x2=y1=y2=0.
 for x in values:
  y=b0*x+b1*x1+b2*x2-a1*y1-a2*y2;x2,x1,y2,y1=x1,x,y1,y;out.append(y)
 return out
def steep_lowpass(values,hz):
 # 8th-order Butterworth (four biquads): everything above hz is really gone, ~48 dB/octave
 for q in (.5098,.6013,.8999,2.5629):values=biquad_lowpass(values,hz,q)
 return values
def resampled(values,pitch):
 n=int(len(values)/pitch);out=[]
 for i in range(n):
  at=i*pitch;k=int(at);f=at-k;out.append(values[k]*(1-f)+values[min(k+1,len(values)-1)]*f)
 return out
def leveled(values,reference):
 # scaled to the loudness (RMS) of a level reference
 return [v*reference/max(1e-6,rms(values)) for v in values]
def normal(values):return leveled(values,1.)

# the medic kit starts with the user's healing chime, its whole high end cut away (above 2.2 kHz),
# much quieter than the old cue
chime=faded(excerpt('user_medkit_chime',0.,1.25),.002,.35)
write('medkit',leveled(steep_lowpass(chime,2200),rms(written('deploy'))),gain=kept_gain('deploy',-9.))

# a skill: the first hit of the user's reveal clip when it starts, the second when it ends
skill_level=rms(written('skill'));skill_gain=kept_gain('skill')
write('skill',leveled(faded(excerpt('user_skill_reveal',.08,1.17),.003,.25),skill_level),gain=skill_gain)
write('skill_end',leveled(faded(excerpt('user_skill_reveal',1.22,1.2),.003,.3),skill_level),gain=round(skill_gain-2.,1))

# sliding access doors: three motor slides from the user's sci-fi door clip (one at random)
door_level=rms(written('door'));door_gain=kept_gain('door')
for k,(start,length) in enumerate(((.55,.8),(3.95,1.),(19.95,1.2))):
 write('door' if k==0 else 'door_v%d'%k,leveled(faded(highpass(excerpt('user_scifi_door',start,length),80),.01,.2),door_level),gain=door_gain)
manifest['door']['variants']=3
# hinged access doors (Kenney RPG Audio): opening with a little creak, closing with a latch
for k in range(2):
 opening=mix(1.1,(normal(sample('k_doorOpen_%d'%(k+1))),1.,0.),(normal(sample('k_creak%d'%(k+1))),.3,.04))
 write('door_swing_open' if k==0 else 'door_swing_open_v%d'%k,leveled(faded(opening,.003,.2),door_level),gain=door_gain)
manifest['door_swing_open']['variants']=2
for k in range(4):
 write('door_swing_close' if k==0 else 'door_swing_close_v%d'%k,leveled(faded(sample('k_doorClose_%d'%(k+1)),.002,.1),door_level),gain=door_gain)
manifest['door_swing_close']['variants']=4

# slide: one broom stroke under the clothes drop
stroke=faded(excerpt('user_sweeping',5.95,.6),.01,.2)
clothes=faded(onset(sample('user_clothes_drop2'))[:int(rate*.6)],.002,.2)
write('slide',leveled(mix(.75,(normal(stroke),.6,0.),(normal(clothes),.45,.05)),rms(written('slide'))),gain=kept_gain('slide'))

# engineer placement: the start of the user's robot clip, three machines starting at once
robot=faded(excerpt('user_robot',.38,.87),.005,.25)
machines=faded(mix(1.,(robot,1.,0.),(resampled(robot,1.19),.7,.06),(resampled(robot,.86),.6,.11)),.005,.25)
write('engineer_deploy',leveled(machines,rms(written('deploy'))),gain=kept_gain('deploy'))

# a mark landing: the user's reception bell, short and soft
write('mark',leveled(faded(excerpt('user_bell',.05,1.1),.002,.6),rms(written('confirm'))*.5),gain=kept_gain('confirm'))

# the bipod taking hold: one metal clack, quiet (heard within 10 m - AudioBank)
write('bipod',leveled(faded(onset(sample('user_metal_crunch')),.002,.08),rms(written('deploy'))),gain=kept_gain('deploy',-12.))

# wading: one slosh of the user's walking-in-water clip per step, 1.3x faster and 5 dB down
for k,t in enumerate((.51,1.33,2.58,3.84)):
 key='step_water_%d'%k
 piece=faded(highpass(excerpt('user_water_walk',t-.10,.62/1.3,1.3),90),.004,.14)
 write(key,leveled(piece,rms(written(key))),gain=kept_gain(key,-5.))

# grenade and rocket blasts: much quieter (8 dB) and the tail cut short - full for 0.55 s, then
# gone within about a second
boom=written('explosion');gain=kept_gain('explosion',-8.)
short=[v*(1. if i<rate*.55 else math.exp(-(i-rate*.55)/(rate*.22))) for i,v in enumerate(boom[:int(rate*1.25)])]
for key in ('explosion','rocket_explosion'):write(key,faded(short,.001,.2),gain=gain)
