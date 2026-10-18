"""Deterministic painted surface textures; no external asset dependencies."""
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
from pathlib import Path
import random
out=Path(__file__).resolve().parents[2]/'assets/textures'
out.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(128)
random.seed(128)
N=512

def grain(base, strength=12):
    a=np.zeros((N,N,3),dtype=float)+base
    for size,amp in [(8,strength),(32,strength*.4),(128,strength*.15)]:
        n=Image.fromarray(rng.integers(0,256,(size,size),dtype=np.uint8)).resize((N,N),Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(1))
        a+=(np.asarray(n)[:,:,None]/255-.5)*amp
    return Image.fromarray(np.uint8(np.clip(a,0,255)))

def brush(im,colors,count,lengths=(8,60)):
    d=ImageDraw.Draw(im,'RGBA')
    for _ in range(count):
        x,y=random.randrange(N),random.randrange(N); l=random.randrange(*lengths)
        c=random.choice(colors)
        d.line([(x,y),(x+l,y+random.randrange(-4,5))],fill=c,width=random.randrange(1,5))
    return im

im=grain((88,91,65),28); brush(im,[(128,127,85,28),(38,56,42,37),(155,132,91,20)],1400)
im.save(out/'painted_earth.png')
im=grain((156,145,119),28); brush(im,[(240,209,159,35),(75,78,68,25),(194,173,125,25)],1800)
d=ImageDraw.Draw(im,'RGBA')
for _ in range(25):
    x,y=random.randrange(N),random.randrange(N)
    d.line([(x,y),(x+3,y+14),(x-4,y+22),(x-3,y+45)],fill=(62,63,53,35),width=1)
im.save(out/'painted_plaster.png')
im=grain((94,70,49),22); d=ImageDraw.Draw(im,'RGBA')
for x in range(0,N,64):
    d.rectangle((x,0,x+2,N),fill=(26,22,18,145));d.line([(x+4,0),(x+4,N)],fill=(181,140,87,70),width=2)
for _ in range(1400):
    x,y=random.randrange(N),random.randrange(N)
    d.line([(x,y),(x+random.randrange(-2,3),y+random.randrange(8,140))],fill=random.choice([(32,27,23,30),(191,144,87,40),(120,99,65,50)]),width=1)
for _ in range(12):
    x,y=random.randrange(N),random.randrange(N)
    d.ellipse((x-3,y-10,x+3,y+10),outline=(25,24,22,100),width=2)
im.save(out/'painted_timber.png')
im=grain((67,79,91),12); d=ImageDraw.Draw(im,'RGBA')
for j in range(8):
 for i in range(-1,9):
    x=i*64+(j%2)*32;y=j*64
    c=random.choice([(70,83,98),(77,89,105),(62,79,92),(81,90,99),(58,73,86)])
    d.polygon([(x+2,y+2),(x+62,y+2),(x+59,y+63),(x+5,y+63)],fill=(*c,255))
    d.line([(x+5,y+63),(x+59,y+63)],fill=(21,32,44,220),width=3)
    d.line([(x+7,y+58),(x+55,y+58)],fill=(122,135,146,95),width=2)
    for _ in range(5):
      a=x+random.randrange(5,55);b=y+random.randrange(5,53)
      d.line([(a,b),(a+random.randrange(3,10),b)],fill=(139,150,160,35),width=2)
im.save(out/'painted_slate.png')
im=grain((114,117,111),24);brush(im,[(203,192,158,30),(54,67,62,40),(127,144,98,28)],1700)
d=ImageDraw.Draw(im,'RGBA')
for _ in range(15):
 x,y=random.randrange(N),random.randrange(N)
 d.line([(x,y),(x+10,y+5),(x+14,y+18)],fill=(43,49,46,75),width=2)
im.save(out/'painted_stone.png')
im=grain((146,121,88),25);brush(im,[(206,182,129,30),(68,62,43,30)],1700)
im.save(out/'painted_path.png')
print('Generated six painted 512px material textures')
