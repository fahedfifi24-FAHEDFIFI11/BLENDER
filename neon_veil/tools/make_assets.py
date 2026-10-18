"""Original tileable material maps and synthesized soundscape; no downloaded assets."""
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
import wave
P=Path(__file__).resolve().parents[1];rng=np.random.default_rng(417)
n=512;y,x=np.mgrid[:n,:n]
def smooth(a,r):return np.asarray(Image.fromarray(np.uint8(a)).filter(ImageFilter.GaussianBlur(r))).astype(float)/255
noise=smooth(rng.uniform(0,255,(n,n)),3)
broad=smooth(rng.uniform(0,255,(n,n)),22)
fine=rng.uniform(-1,1,(n,n))
for name,color in [('concrete',(91,103,105)),('metal',(54,65,72)),('asphalt',(32,39,45)),('bronze',(108,79,52))]:
 h=.45+noise*.25+fine*.025
 if name=='concrete':
  seams=(x%128<2)|(y%256<2); h[seams]-=.18
 if name=='metal' or name=='bronze':
  seams=(x%256<3)|(y%128<3);h[seams]-=.2
  h+=np.sin(x*.45)*.008
 if name=='asphalt':h+=fine*.07
 col=np.clip(np.array(color)[None,None,:]*(.65+h[:,:,None])+(broad[:,:,None]-.5)*90,0,255)
 Image.fromarray(col.astype('uint8')).save(P/'assets/textures'/f'{name}_color.png')
 gy,gx=np.gradient(h);normal=np.dstack((-gx*3,-gy*3,np.ones_like(h)));normal/=np.linalg.norm(normal,axis=2,keepdims=True)
 Image.fromarray(np.uint8((normal*.5+.5)*255)).save(P/'assets/textures'/f'{name}_normal.png')
 Image.fromarray(np.uint8(np.clip(.3+noise*.7+fine*.06,0,1)*255)).save(P/'assets/textures'/f'{name}_rough.png')
# Seamless low-frequency puddle mask, periodic waves avoid visible tile boundaries.
puddle=np.zeros((n,n))
for _ in range(16):
 a,b=rng.integers(1,7,2);puddle+=np.sin(2*np.pi*(a*x+b*y)/n+rng.uniform(0,6.28))/np.sqrt(a*a+b*b)
puddle=(puddle-puddle.min())/(puddle.max()-puddle.min())
Image.fromarray(np.uint8(puddle*255)).save(P/'assets/textures/puddle.png')
rate=22050
def save(name,a):
 a=np.clip(a,-.95,.95); a=np.column_stack((a,np.roll(a,71))) if a.ndim==1 else a
 with wave.open(str(P/'assets/audio'/f'{name}.wav'),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes((a*32767).astype('<i2').tobytes())
t=np.arange(rate*24)/rate
pad=np.zeros(len(t))
for freq,amp in [(55,.12),(82.5,.055),(110,.035),(130.813,.035),(164.814,.025),(220,.018)]:
 # Integer cycles give clean 24-second loop; slow tremolo, stereo phase drift.
 freq=round(freq*24)/24;pad+=np.sin(2*np.pi*freq*t+.2*np.sin(2*np.pi*t/24))*amp*(.7+.3*np.sin(2*np.pi*t/24+.3))
noise=rng.normal(0,.025,len(t));rain=np.convolve(noise,np.ones(5)/5,'same')
save('night',pad+rain)
t=np.arange(rate*12)/rate
rain=rng.normal(0,.035,len(t));save('rain',rain)
for name,freq,duration in [('terminal',660,.4),('relay',110,1.6),('door',75,2.2),('scan',180,2.8),('ending',220,4)]:
 t=np.arange(int(rate*duration))/rate;env=np.sin(np.pi*t/duration)**2
 a=(np.sin(2*np.pi*freq*t)+.3*np.sin(2*np.pi*freq*1.5*t))*.14*env
 if name=='door':a+=rng.normal(0,.06,len(t))*env
 save(name,a)
t=np.arange(int(rate*.17))/rate;save('step',rng.normal(0,.13,len(t))*np.exp(-t*28))
print('Generated 13 original material maps and 8 original stereo sounds.')
