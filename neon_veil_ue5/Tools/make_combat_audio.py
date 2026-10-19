from pathlib import Path
import wave
import numpy as np
P=Path(__file__).resolve().parents[1]/'SourceAssets/Audio'
rng=np.random.default_rng(64);rate=44100
for name,duration in [('shot',.28),('reload',1.4),('hurt',.35),('impact',.25),('vent',12),('thunder',4)]:
 t=np.arange(int(rate*duration))/rate;n=rng.normal(0,1,len(t))
 if name=='shot':a=(n*.35+np.sin(2*np.pi*(110*t-40*t*t))*.35)*np.exp(-t*25)
 elif name=='reload':
  a=np.zeros(len(t))
  for delay in [.02,.5,1.05]:
   dt=np.maximum(0,t-delay);a+=(n*.12+np.sin(2*np.pi*620*dt)*.08)*np.exp(-dt*60)*(t>=delay)
 elif name=='vent':a=np.sin(2*np.pi*55*t)*.045+np.convolve(n,np.ones(60)/60,'same')*.1
 elif name=='thunder':a=np.convolve(n,np.ones(200)/200,'same')*1.5*np.sin(np.pi*t/duration)**2
 else:a=(n*.2+np.sin(2*np.pi*85*t)*.2)*np.exp(-t*16)
 with wave.open(str(P/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes((np.clip(a,-.9,.9)*32767).astype('<i2').tobytes())
print('Six original combat/ventilation/weather sounds generated.')
