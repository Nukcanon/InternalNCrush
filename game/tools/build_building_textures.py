"""100 original seamless building finishes, packed into one guttered atlas."""
from pathlib import Path
from PIL import Image
import numpy as np, json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/textures/district';OUT.mkdir(parents=True,exist_ok=True)
SOURCE=ROOT.parent/'art_source/district_textures';SOURCE.mkdir(parents=True,exist_ok=True)
N=128;G=4;CELL=N+2*G;atlas=Image.new('RGB',(CELL*10,CELL*10));rows=[]
normal_atlas=Image.new('RGB',atlas.size)
y,x=np.mgrid[0:N,0:N];u=x/N;v=y/N
families=['brick','plaster','concrete','stone','wood','metal','roof_tiles','roof_seams','pavers','ceramic']
palettes=[(181,103,65),(204,190,153),(153,170,168),(178,163,128),(143,102,52),(112,148,155),(182,93,54),(88,123,132),(163,157,124),(170,193,183)]
for family in range(10):
 for variant in range(10):
  idx=family*10+variant;rng=np.random.default_rng(128000+idx)
  grain=rng.normal(0,1.5,(N,N));pat=np.zeros((N,N));base=np.array(palettes[family],float)
  base=base*np.array([.87+(variant%3)*.10,.91+(variant//3%3)*.075,.90+(variant%4)*.06])
  if family in [0,3,6,8,9]:
   nx=2+variant%4;ny=3+variant//3;row=np.floor(v*ny);a=(u*nx+(row%2)*(.5 if family!=9 else 0))%1;b=(v*ny)%1
   mortar=(a<.035)|(b<.055);bevel=(a<.085)|(b<.12)
   pat=np.where(mortar,-34,np.where(bevel,7,0))+4*np.sin(row*7+np.floor(u*nx+row%2*.5)*3)
   if family==3:pat+=3*np.sin(u*31+v*17)
   if family==6:pat+=12*np.cos(a*np.pi*2)
   if family==8 and variant%2:pat+=np.where((x+y)%(16+variant)<2,-9,0)
  elif family==4:
   a=(u*(3+variant%4))%1;pat=np.where(a<.04,-27,0)+5*np.sin(u*(16+variant*2)*np.pi*2+np.sin(v*np.pi*4))
   pat+=3*np.sin(u*np.pi*80+np.sin(v*np.pi*2)*2)
  elif family in [5,7]:
   a=(u*(3+variant%4))%1;pat=8*np.cos(a*np.pi*2)+np.where(a<.07,-20,0)
   rivet=(((u*4)%1-.5)**2+((v*4)%1-.5)**2)<.012;pat+=rivet*13
  elif family==1:
   pat=3*np.sin(u*np.pi*8)*np.cos(v*np.pi*6)+grain*.6
  else:
   pat=3*np.sin(u*np.pi*6)*np.cos(v*np.pi*10);pat+=np.where((x%(32+variant*0))<1,-6,0) if variant>4 else 0
  rgb=np.clip(base+pat[...,None]+grain[...,None],0,255).astype('uint8');im=Image.fromarray(rgb)
  name=f'{families[family]}_{variant:02d}';im.save(SOURCE/(name+'.png'))
  padded=np.pad(rgb,((G,G),(G,G),(0,0)),mode='wrap');atlas.paste(Image.fromarray(padded),((idx%10)*CELL,(idx//10)*CELL))
  # Derive normals from authored relief, never colour or random colour grain.
  height=pat/80.
  dx=(np.roll(height,-1,1)-np.roll(height,1,1))*.7
  dy=(np.roll(height,-1,0)-np.roll(height,1,0))*.7
  normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1)
  normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
  normal=np.clip((normal*.5+.5)*255,0,255).astype('uint8')
  normal_atlas.paste(Image.fromarray(np.pad(normal,((G,G),(G,G),(0,0)),mode='wrap')),((idx%10)*CELL,(idx//10)*CELL))
  rows.append({'id':idx,'name':name,'family':families[family],'pixels':N})
atlas.save(OUT/'building_atlas.png');(OUT/'manifest.json').write_text(json.dumps({'original':True,'tile':N,'gutter':G,'columns':10,'assets':rows},indent=2))
normal_atlas.save(OUT/'building_normals.png')
# Shared small tiling detail maps: different relief frequencies and amplitudes.
for name,height in {
 'cloth':.10*np.sin(u*np.pi*32)*np.cos(v*np.pi*32),
 'skin':.015*np.sin(u*np.pi*44)*np.sin(v*np.pi*38),
 'metal':.025*np.sin(u*np.pi*64)+.012*np.cos(v*np.pi*16),
 'wood':.08*np.sin(u*np.pi*24+np.sin(v*np.pi*4)),
}.items():
 dx=(np.roll(height,-1,1)-np.roll(height,1,1))*2
 dy=(np.roll(height,-1,0)-np.roll(height,1,0))*2
 normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 Image.fromarray(np.clip((normal*.5+.5)*255,0,255).astype('uint8')).save(OUT/(name+'_normal.png'))
print('BUILDING_TEXTURES',len(rows),'ATLAS',atlas.size)
