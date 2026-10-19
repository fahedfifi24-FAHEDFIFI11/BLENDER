"""Pack original roughness into HDRP mask channels; draw original diegetic signage."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops
import numpy as np
P=Path(__file__).resolve().parents[1];T=P/'Assets/NR/Textures'
for name,metal in [('asphalt',18),('concrete',5),('metal',195),('bronze',175)]:
 rough=Image.open(T/(name+'_rough.png')).convert('L');smooth=ImageChops.invert(rough)
 if name=='asphalt':
  puddle=Image.open(T/'puddle.png').convert('L').resize(rough.size);a=np.asarray(smooth).astype(float);m=np.asarray(puddle)/255.;smooth=Image.fromarray(np.uint8(np.clip(a*(1-m)+245*m,0,255)))
 Image.merge('RGBA',(Image.new('L',rough.size,metal),Image.new('L',rough.size,235),Image.new('L',rough.size,128),smooth)).save(T/(name+'_mask.png'))
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
items={
 'market':('LOW TIDE','NIGHT MARKET / 04:17 / RAIN FORECAST: ALWAYS'),
 'mother':('M O T H E R','LISTENING BOOTH  /  WEST MARKET'),
 'undercity':('SERVICE / 09','THREE RELAYS KEEP THE CITY BREATHING'),
 'cipher':('MAINTENANCE KEY','TRIANGLE  >  CIRCLE  >  CROSS'),
 'ascent':('SKYLINE ACCESS','ASCEND / TRANSMISSION PLATFORM'),
 'noodles':('AFTER THE RAIN','BROTH / TEA / A PLACE TO WAIT'),
 'memory':('WE WERE HERE','THEY CANNOT SELL WHAT WE REMEMBER'),
 'corporate':('A U R A L','YOUR MEMORIES. OUR WEATHER.'),
}
for name,(title,sub) in items.items():
 im=Image.new('RGB',(1024,256),(12,22,26));d=ImageDraw.Draw(im);color=(227,159,80) if name in ['market','mother','noodles','ascent'] else (103,176,184)
 d.rectangle((8,8,1015,247),outline=color,width=3);d.line((38,195,985,195),fill=color,width=2)
 f=ImageFont.truetype(font,61 if len(title)<19 else 48);d.text((38,65),title,font=f,fill=color)
 d.text((40,211),sub,font=ImageFont.truetype(font,19),fill=(156,176,173))
 for x in range(40,280,12):d.rectangle((x,26,x+3,40),fill=color)
 im.save(T/('sign_'+name+'.png'))
# Soft alpha streak for mesh particles, authored mathematically rather than opaque squares.
a=np.zeros((64,64,4),dtype=np.uint8)
for y in range(64):
 for x in range(64):a[y,x]=[180,206,215,int(190*np.exp(-((x-32)/7)**2)*np.sin(np.pi*y/63)**2)]
Image.fromarray(a).save(T/'rain_particle.png')
print('HDRP masks and 8 original signs written')

# A soft radial opacity sprite for slow ventilation steam.
y,x=np.mgrid[-1:1:64j,-1:1:64j]
steam=np.zeros((64,64,4),dtype=np.uint8);steam[:,:,:3]=[174,189,195]
steam[:,:,3]=np.uint8(95*np.clip(1-x*x-y*y,0,1)**2)
Image.fromarray(steam).save(T/'steam_particle.png')
