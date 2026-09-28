"""40 roofs, 20 soffits, 40 ceilings; original diffuse/normal atlases."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/textures/district'
SOURCE=ROOT.parent/'art_source/roof_textures'
SOURCE.mkdir(parents=True,exist_ok=True)
N=256;G=8;CELL=N+G*2
atlas=Image.new('RGB',(CELL*10,CELL*10));normals=Image.new('RGB',atlas.size)
y,x=np.mgrid[:N,:N];u=x/N;v=y/N
families=['terracotta','slate','standing_seam','shingles','soffit_wood','soffit_panels','ceiling_acoustic','ceiling_plaster','ceiling_wood','ceiling_metal']
palettes=[(187,96,54),(89,115,133),(87,145,150),(137,117,89),(185,146,96),(211,209,182),(219,225,216),(229,215,185),(174,130,81),(165,184,191)]
rows=[]
for idx in range(100):
 family=idx//10;variant=idx%10
 rng=np.random.default_rng(13000+idx)
 a=(u*4+np.floor(v*4)%2*.5)%1
 b=v*4%1
 if family in [0,1,3]:
  relief=np.where((a<.04)|(b<.045),-.7,.12*np.cos(a*np.pi*2))
  if family==0:relief+=.32*np.sin(a*np.pi)
 elif family==2:
  a=u*4%1;relief=np.where(a<.06,.75,0.)+.025*np.cos(v*np.pi*8)
 elif family in [4,8]:
  a=u*4%1;relief=np.where(a<.04,-.45,0.)+.05*np.sin(u*np.pi*48+np.sin(v*np.pi*4))
 elif family==7:
  relief=.03*np.sin(u*np.pi*8)*np.cos(v*np.pi*6)+.025*np.cos(u*np.pi*18+v*np.pi*10)
 else:
  a=u*4%1;relief=np.where((a<.035)|(b<.035),-.45,0.)
  relief+=np.where(((x%16==0)&(y%16==0)) & (family==6),-.2,0.)
 base=np.array(palettes[family])*np.array([.97,1.,.99])
 blend=np.clip(np.minimum.reduce([u,v,1-u,1-v])*14,0,1)
 unit=np.sin(np.floor(u*4)*19.7+np.floor(v*4)*41.1+variant*17.3)*11
 weather=np.sin(u*np.pi*6+variant)*np.cos(v*np.pi*8-variant)*4
 wear=(unit+weather)*blend
 rgb=np.clip(base+relief[...,None]*36+wear[...,None]+rng.normal(0,1,(N,N,1))*blend[...,None],0,255).astype('uint8')
 dx=(np.roll(relief,-1,1)-np.roll(relief,1,1))*1.5
 dy=(np.roll(relief,-1,0)-np.roll(relief,1,0))*1.5
 normal=np.stack([-dx,-dy,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
 normal=np.clip((normal*.5+.5)*255,0,255).astype('uint8')
 name=f'{families[family]}_{variant:02d}'
 Image.fromarray(rgb).save(SOURCE/(name+'.png'))
 for target,data in [(atlas,rgb),(normals,normal)]:
  target.paste(Image.fromarray(np.pad(data,((G,G),(G,G),(0,0)),mode='wrap')),((idx%10)*CELL,(idx//10)*CELL))
 rows.append({'name':name,'index':idx,'kind':'roof' if idx<40 else 'soffit' if idx<60 else 'ceiling','original':True})
atlas.save(OUT/'roof_atlas.png');normals.save(OUT/'roof_normals.png')
(SOURCE/'manifest.json').write_text(json.dumps({'license':'CC0-1.0','assets':rows},indent=2))
print('ROOF_FINISHES 40 SOFFIT_FINISHES 20 CEILING_FINISHES 40 ATLAS',atlas.size)
