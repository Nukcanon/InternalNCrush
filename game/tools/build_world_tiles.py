"""Original, deterministic surface paintings. No external game assets used."""
from pathlib import Path
import random
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / 'assets/textures/world'
OUT.mkdir(parents=True, exist_ok=True)
N = 256
for kind in ['stone', 'brick', 'paving', 'concrete', 'wood', 'metal', 'roof', 'earth']:
    rng = random.Random('inc-world-127-' + kind)
    im = Image.new('RGB', (N, N), (176, 175, 169))
    d = ImageDraw.Draw(im)
    if kind in ['stone', 'brick', 'paving', 'roof']:
        h = {'stone':64, 'brick':32, 'paving':64, 'roof':32}[kind]
        w = {'stone':128, 'brick':80, 'paving':64, 'roof':32}[kind]
        d.rectangle((0, 0, N, N), fill=(90, 92, 88))
        for row, y in enumerate(range(-h, N+h, h)):
            for x in range(-w, N+w, w):
                xx = x + (w//2 if row % 2 and kind != 'paving' else 0)
                v = rng.randint(169, 210)
                d.rectangle((xx+2,y+2,xx+w-2,y+h-2),fill=(v,v,max(0,v-5)))
                d.line((xx+3,y+h-3,xx+w-3,y+h-3),fill=(v-27,)*3,width=2)
                d.line((xx+3,y+3,xx+w-3,y+3),fill=(min(240,v+17),)*3,width=1)
                for _ in range(18):
                    px=xx+rng.randrange(4,max(5,w-4));py=y+rng.randrange(4,h-4)
                    d.ellipse((px,py,px+2,py+1), fill=(v-18,)*3)
    elif kind == 'wood':
        for x in range(0,N,32):
            v=rng.randint(160,205);d.rectangle((x,0,x+30,N),fill=(v,v-4,v-13))
            for _ in range(12):
                xx=x+rng.randrange(2,29);yy=rng.randrange(N)
                d.line((xx,yy,xx+1,yy+rng.randrange(12,90)),fill=(v-20,v-24,v-30))
            for y in [8,248]:d.ellipse((x+6,y,x+8,y+2),fill=(72,)*3)
    elif kind == 'metal':
        for x in range(0,N,32):
            d.rectangle((x,0,x+3,N),fill=(119,124,128));d.line((x+4,0,x+4,N),fill=(210,214,211))
        for x in [10,246]:
            for y in [10,246]:d.ellipse((x-2,y-2,x+2,y+2),fill=(98,103,106))
    elif kind == 'concrete':
        d.line((0,1,N,1),fill=(133,137,134),width=2)
        d.line((1,0,1,N),fill=(133,137,134),width=2)
        for x in [12,244]:
            for y in [12,244]:d.ellipse((x-2,y-2,x+2,y+2),fill=(134,136,133))
    else:
        d.rectangle((0,0,N,N),fill=(168,162,143))
        for _ in range(350):
            x,y=rng.randrange(N),rng.randrange(N);v=rng.randrange(115,195)
            d.ellipse((x,y,x+rng.randrange(1,7),y+rng.randrange(1,4)),fill=(v,v,max(70,v-16)))
    # Low-amplitude grain stays below the scale of the readable joints.
    pixels=im.load()
    for y in range(N):
        for x in range(N):
            delta=rng.randint(-6,6);pixels[x,y]=tuple(max(0,min(255,c+delta)) for c in pixels[x,y])
    if (OUT/'SOURCES.json').exists() and kind in ['stone','brick','paving','concrete','wood','earth']:
        continue  # Preserve explicitly imported CC0 maps.
    im.save(OUT/(kind+'.png'),optimize=True)
    # Explicit repeat+mip import; Web preserves the same designs at half size.
    (OUT/(kind+'.png.import')).write_text('''[remap]
importer="texture"
type="CompressedTexture2D"

[deps]
source_file="res://assets/textures/world/'''+kind+'''.png"

[params]
compress/mode=0
mipmaps/generate=true
''')
print('WORLD_TILES', len(list(OUT.glob('*.png'))))
