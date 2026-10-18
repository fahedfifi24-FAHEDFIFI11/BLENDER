"""Blender authored modular environment kit; metres, bevels and mechanical detailing."""
import bpy,math,random
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parents[1];random.seed(62)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
for name,color,metal,rough in [('metal',(0.13,.18,.21),.75,.3),('concrete',(.3,.34,.35),0,.8),('bronze',(.36,.24,.12),.7,.33),('dark',(.025,.04,.05),.4,.3),('glass',(.025,.095,.12),.75,.14),('ivory',(.65,.64,.55),.2,.38),('cyan',(.12,.7,.78),.2,.3),('amber',(.9,.38,.08),.1,.3)]:
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True;b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 if name in ['cyan','amber']:b.inputs['Emission Color'].default_value=(*color,1);b.inputs['Emission Strength'].default_value=2
 materials[name]=m
active=[]
def finish(o,name,mat,bevel=0):
 o.name=name;o.data.materials.append(materials[mat]);active.append(o)
 if bevel:
  mod=o.modifiers.new('Manufactured edge radius','BEVEL');mod.width=bevel;mod.segments=3
  mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL')
 return o
def box(name,loc,size,mat='metal',bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish(o,name,mat,bevel)
def cyl(name,loc,r,depth,mat='metal',axis='Z',vertices=32):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=depth,location=loc);o=bpy.context.object
 if axis=='Y':o.rotation_euler.x=math.pi/2
 if axis=='X':o.rotation_euler.y=math.pi/2
 for p in o.data.polygons:p.use_smooth=True
 return finish(o,name,mat,.012)
def beam(a,b,r=.04,mat='metal'):
 a,b=Vector(a),Vector(b);o=cyl('Conduit', (a+b)/2,r,(b-a).length,mat);o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def pipe(points,r=.08,mat='metal'):
 for a,b in zip(points,points[1:]):beam(a,b,r,mat)
 for p in points:cyl('Pipe union',p,r*1.3,.16,mat)
def asset(name,fn,index):
 global active
 active=[];fn()
 bpy.ops.object.select_all(action='DESELECT')
 for o in active:o.select_set(True)
 bpy.context.view_layer.objects.active=active[0];bpy.ops.object.convert(target='MESH')
 # Join per material for efficient runtime surfaces and draw calls.
 joined=[]
 groups={mat:[o for o in active if o.data.materials and o.data.materials[0].name==mat] for mat in materials}
 for mat,objs in groups.items():
  if not objs:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in objs:o.select_set(True)
  bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();o=objs[0];o.name=name+'_'+mat;joined.append(o)
 bpy.ops.object.select_all(action='DESELECT')
 for o in joined:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(P/'assets/models'/f'{name}.glb'),use_selection=True,export_format='GLB',export_yup=True,export_cameras=False,export_lights=False)
 for o in joined:o.location.x+=index*14
 print('ASSET',name,flush=True)
def facade():
 box('Poured concrete shell',(0,.4,5),(6,.8,10),'concrete',.06)
 for z in [0.3,3.6,6.6,9.8]:box('Horizontal expansion ledge',(0,-.14,z),(6.14,.44,.24),'metal')
 for x in [-2.9,2.9]:box('Structural upright',(x,-.12,5),(.24,.45,10),'metal')
 for z in [5.1,8.1]:
  for x in [-1.85,0,1.85]:
   box('Window recessed gasket',(x,-.06,z),(1.65,.2,2.28),'dark')
   box('Blue smoked glazing',(x,-.19,z),(1.48,.06,2.1),'glass')
   for off in [-.73,0,.73]:box('Slender window mullion',(x+off,-.25,z),(.04,.12,2.12),'bronze',.009)
   box('Window sill',(x,-.38,z-1.12),(1.74,.6,.13),'metal')
   for slat in range(5):box('Interior blinds',(x,-.23,z+.85-slat*.15),(1.45,.03,.035),'ivory',.003)
 for x in [-2.7,2.65]:pipe([(x,-.6,.3),(x,-.6,4),(x-.2,-.6,4.4),(x-.2,-.6,9.8)],.065)
 for x in [-1.8,0,1.8]:
  box('Storefront inset',(x,-.22,1.8),(1.68,.18,2.6),'dark')
  box('Storefront glass',(x,-.34,1.8),(1.5,.05,2.36),'glass')
  box('Storefront vertical mullion',(x,-.39,1.8),(.045,.1,2.4),'bronze',.008)
 box('Cantilevered canopy',(0,-1.1,3.4),(6.1,2.4,.2),'metal',.07)
 for x in [-2.7,2.7]:beam((x,0,4),(x,-2.1,3.4),.035)
 box('Canopy underlight',(0,-1.8,3.26),(4.9,.08,.045),'amber',.008)
def shutter():
 facade()
 box('Loading gate frame',(0,-.46,1.75),(3.6,.16,3.25),'metal')
 for z in range(20):box('Rolling shutter slat',(0,-.57,.27+z*.15),(3.3,.1,.12),'bronze',.018)
 box('Maintenance number plaque',(2.1,-.43,2.4),(.5,.06,.75),'ivory')
def hvac():
 box('Air handling housing',(0,0,.7),(1.6,.8,1.4),'ivory',.09)
 box('Fan dark cavity',(-.23,-.43,.75),(1.05,.07,1.05),'dark')
 cyl('Fan rim',(-.23,-.49,.75),.47,.12,'metal','Y')
 cyl('Fan interior',(-.23,-.56,.75),.41,.02,'dark','Y')
 for i in range(9):
  a=i*math.tau/9;o=box('Fan blade',(-.23+math.sin(a)*.23,-.58,.75+math.cos(a)*.23),(.2,.03,.38),'metal',.035);o.rotation_euler.y=a
 cyl('Fan hub',(-.23,-.62,.75),.12,.09,'bronze','Y')
 for x in range(9):box('Protective grille',(-.65+x*.105,-.66,.75),(.018,.025,.94),'metal',.004)
 for z in range(8):box('Vent louvre',(.57,-.46,.3+z*.11),(.28,.1,.045),'metal',.006)
 pipe([(.62,0,0),(.62,0,-.3),(1,0,-.3),(1,0,-1.1)],.045)
def terminal():
 box('Terminal base',(0,0,.1),(.85,.65,.2),'metal',.06)
 box('Console plinth',(0,0,.65),(.62,.44,1.1),'dark',.07)
 box('Control housing',(0,-.05,1.4),(.83,.36,.8),'metal',.065)
 box('Screen gasket',(0,-.25,1.47),(.7,.07,.49),'dark',.02)
 box('Screen',(0,-.3,1.47),(.6,.025,.39),'cyan',.015)
 for x in [-.23,0,.23]:cyl('Input button',(x,-.28,1.09),.04,.03,'amber','Y',16)
 for i in range(5):box('Cooling slot',(.33,.02,.42+i*.08),(.02,.3,.026),'metal',.005)
def stall():
 box('Food kiosk cabinet',(0,0,.55),(2.7,1.1,1.1),'metal',.07)
 box('Service counter',(0,-.17,1.13),(2.95,1.55,.13),'ivory',.04)
 for x in [-1.32,1.32]:box('Kiosk post',(x,.28,1.85),(.08,.08,1.55),'bronze')
 box('Canvas valance',(0,0,2.68),(3.2,1.6,.18),'bronze',.035)
 box('Light strip',(0,-.7,2.57),(2.7,.06,.04),'amber',.008)
 for x in [-.8,-.2,.4]:
  cyl('Cooking pot',(x,0,1.3),.22,.26,'metal');cyl('Pot lid',(x,0,1.46),.235,.04,'ivory');cyl('Lid handle',(x,0,1.51),.035,.06,'dark')
 for x in [-1,1]:
  for z in [.35,.65,.95]:box('Counter panel',(x,-.57,z),(.5,.05,.25),'bronze')
def crate():
 box('Shipping case',(0,0,.45),(.95,.75,.9),'metal',.075)
 for z in [.12,.76]:box('Case reinforcement',(0,0,z),(1.01,.81,.08),'bronze')
 for x in [-.35,.35]:box('Case rib',(x,-.4,.45),(.07,.05,.6),'ivory')
 box('Shipping label',(0,-.405,.47),(.3,.02,.21),'ivory',.005)
 box('Recessed handle',(0,-.42,.77),(.24,.05,.06),'dark')
def door():
 for x in [-2.7,2.7]:box('Gate pier',(x,0,2.25),(.65,1,4.5),'concrete',.06)
 box('Gate lintel',(0,0,4.35),(6.1,1.2,.5),'metal',.08)
 for x in [-1.25,1.25]:
  box('Armored gate leaf',(x,0,2.1),(2.45,.4,4.15),'metal',.06)
  for z in [.5,1.2,1.9,2.6,3.3]:box('Gate pressed panel',(x,-.24,z),(2.1,.13,.5),'bronze',.04)
  box('Gate vertical light',(x,-.32,2),(.04,.04,3.2),'amber',.005)
def drone():
 box('Drone body',(0,0,0),(1.5,.8,.45),'metal',.14)
 box('Surveillance visor',(0,-.43,-.05),(.75,.1,.16),'dark',.04)
 cyl('Scanner lens',(0,-.5,-.05),.12,.05,'cyan','Y')
 for x in [-1,1]:
  beam((0,0,0),(x,0,0),.08)
  cyl('Ducted rotor',(x,0,0),.42,.16,'metal')
  cyl('Rotor center',(x,0,.1),.31,.02,'dark')
  for a in [0,math.pi/2]:o=box('Rotor blade',(x,0,.12),(.65,.08,.025),'bronze',.01);o.rotation_euler.z=a
for i,(name,fn) in enumerate([('facade',facade),('shutter',shutter),('hvac',hvac),('terminal',terminal),('stall',stall),('crate',crate),('gate',door),('drone',drone)]):asset(name,fn,i)
bpy.context.scene.unit_settings.system='METRIC'
bpy.ops.wm.save_as_mainfile(filepath=str(P/'source_art/Neon_Veil_Kit.blend'))
