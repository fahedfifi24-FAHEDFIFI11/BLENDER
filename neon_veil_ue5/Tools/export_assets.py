"""Run in Blender 4.3.2. Original FBX kit and articulated operative, metre units."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parents[1]
G=P/'SourceAssets/OriginalGLB'
OUT=P/'SourceAssets/Meshes'
OUT.mkdir(parents=True,exist_ok=True)
random.seed(63)
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1

def export(name):
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},axis_forward='-Y',axis_up='Z',apply_unit_scale=True,add_leaf_bones=False,bake_anim=False,use_mesh_modifiers=True)
 print('EXPORTED',name,flush=True)
for name in ['facade','shutter','hvac','terminal','stall','crate','gate','drone']:
 clear();bpy.ops.import_scene.gltf(filepath=str(G/(name+'.glb')))
 # The GLB scene's Y-up root is resolved to the Blender Z-up basis before FBX conversion.
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 for o in meshes:
  matrix=o.matrix_world.copy();o.parent=None;o.matrix_world=matrix
 bpy.ops.object.select_all(action='DESELECT')
 for o in meshes:o.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0]
 bpy.ops.object.join();bpy.context.object.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 export(name)
M={}
for key,c in [('metal',(.15,.2,.23)),('dark',(.025,.04,.05)),('bronze',(.38,.25,.12)),('concrete',(.3,.34,.35)),('ivory',(.57,.6,.55)),('cyan',(.15,.65,.8)),('amber',(.95,.38,.1)),('rain',(.5,.7,.8)),('holo',(.1,.55,.7))]:
 m=bpy.data.materials.new(key);m.diffuse_color=(*c,1);M[key]=m

def mat(obj,key,bevel=0):
 obj.data.materials.append(M[key])
 if bevel:
  b=obj.modifiers.new('Designed edge radius','BEVEL');b.width=bevel;b.segments=3
  obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
 return obj

def box(at,size,key='metal',bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return mat(o,key,bevel)
def ell(at,size,key='dark'):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=12,location=at);o=bpy.context.object;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for p in o.data.polygons:p.use_smooth=True
 return mat(o,key)
def beam(a,b,r=.03,key='metal'):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return mat(o,key,.006)
def finish(name):
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.join();bpy.context.object.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR');export(name)
def torso(guard=False):
 ell((0,0,.29),(.23,.13,.31),'dark');box((0,-.12,.34),(.43,.1,.43),'metal',.065)
 for x in [-.15,.15]:box((x,-.18,.39),(.11,.045,.25),'bronze' if guard else 'ivory',.025)
 box((0,-.185,.49),(.18,.025,.025),'amber' if guard else 'cyan',.004)
 for z in [.07,.14,.21]:box((0,-.13,z),(.35,.07,.055),'metal',.015)
 box((0,.15,.35),(.32,.14,.36),'metal',.06)
 for x in [-.23,.23]:box((x,-.025,.04),(.095,.16,.15),'bronze',.025)
for name,guard in [('courier_torso',False),('security_torso',True)]:clear();torso(guard);finish(name)
clear();ell((0,0,.135),(.115,.115,.145),'metal');box((0,-.105,.16),(.19,.055,.075),'dark',.025);box((0,-.139,.165),(.16,.013,.025),'cyan',.005);box((0,-.08,.035),(.14,.08,.08),'dark',.02);finish('courier_head')
clear();ell((0,0,-.25),(.115,.105,.27));box((0,-.085,-.24),(.17,.06,.3),'metal',.025);ell((0,-.035,-.47),(.11,.12,.09),'bronze');ell((0,.01,-.65),(.08,.085,.2));box((0,-.07,-.63),(.13,.05,.25),'metal',.025);box((0,-.055,-.82),(.18,.31,.13),'dark',.045);box((0,-.06,-.885),(.19,.32,.025),'metal',.009);finish('courier_leg')
clear();ell((0,0,-.08),(.115,.12,.14),'metal');ell((0,0,-.27),(.075,.075,.15));ell((0,-.01,-.4),(.07,.075,.08),'bronze');box((0,-.025,-.51),(.13,.16,.2),'metal',.045);ell((0,-.04,-.65),(.065,.075,.09));finish('courier_arm')
clear();box((0,-.28,0),(.14,.62,.14),'metal',.025);box((0,.075,.005),(.13,.2,.12),'dark',.025);beam((0,-.5,0),(0,-.94,0),.032);box((0,-.25,-.14),(.08,.13,.22),'dark');box((0,-.46,-.14),(.09,.13,.22),'bronze');box((0,-.2,.13),(.08,.16,.09),'metal');box((0,-.3,.13),(.04,.025,.045),'cyan',.004)
for y in [-.45,-.38,-.31]:box((.075,y,.01),(.025,.025,.09),'bronze',.004)
finish('rifle')
clear();box((0,0,-.105),(6,6,.2),'concrete',.025)
for x in [-2.8,-1.4,0,1.4,2.8]:box((x,0,-.001),(.018,5.9,.008),'dark',.002)
finish('paving')
clear()
verts=[(-1.5,0,0),(1.5,0,0),(-1.5,-4,-1.8),(1.5,-4,-1.8),(-1.5,0,-.2),(1.5,0,-.2),(-1.5,-4,-2),(1.5,-4,-2)]
mesh=bpy.data.meshes.new('AccessRamp');mesh.from_pydata(verts,[],[(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]);o=bpy.data.objects.new('Ramp',mesh);bpy.context.collection.objects.link(o);mat(o,'metal',.02)
for x in [-1.45,1.45]:beam((x,0,1),(x,-4,-.8),.035)
finish('ramp')
clear()
for i in range(12):
 y=-(i+.5)*4/12;top=(i+1)*2/12
 box((0,y,top-.075),(2,4/12,.15),'metal',.018)
 box((0,y+.14,top+.012),(1.92,.045,.02),'amber',.004)
for x in [-1,1]:
 beam((x,0,1),(x,-4,3),.035)
 for i in range(5):beam((x,-i,i*.5),(x,-i,i*.5+1),.025)
finish('stairs')
clear();box((0,0,2),(3.4,.75,4),'metal',.07)
for z in [.4,1.2,2,2.8,3.6]:box((0,-.43,z),(3.1,.12,.55),'bronze',.035)
finish('security_wall')
clear();box((0,0,0),(6,4,.12),'metal',.04)
for x in [-2.7,2.7]:beam((x,-1.8,-.1),(x,-1.8,-2.5),.04)
box((0,-1.85,-.09),(5.3,.07,.035),'amber',.009);finish('canopy')
clear()
for x in [-3,-2,-1,0,1,2,3]:beam((x,0,0),(x,0,1.2),.035)
beam((-3,0,1.2),(3,0,1.2),.045);beam((-3,0,.6),(3,0,.6),.025);finish('railing')
clear();box((0,0,9),(5,4,18),'concrete',.12)
for z in range(2,18,2):
 box((0,-2.07,z),(4.5,.1,.15),'metal')
 for x in [-1.6,-.8,0,.8,1.6]:box((x,-2.09,z+.5),(.45,.03,.65),'amber' if (z+int(x*5))%7==0 else 'dark',.01)
for x in [-2.4,2.4]:box((x,-2.12,9),(.13,.15,18),'metal')
finish('tower')
clear();box((0,0,0),(12,2,.22),'metal');
for x in range(-6,7):beam((x,-1,0),(x,-1,1.2),.035)
beam((-6,-1,1.2),(6,-1,1.2),.04);finish('skybridge')
clear()
for strand in range(4):
 points=[(-6+i,0, -1.1*(1-((-6+i)/6)**2)+strand*.15) for i in range(13)]
 for a,b in zip(points,points[1:]):beam(a,b,.012,'dark')
finish('cables')
clear()
for radius in [3.8,4.2,4.5]:
 bpy.ops.mesh.primitive_torus_add(major_radius=radius,minor_radius=.065 if radius<4 else .15,major_segments=80,minor_segments=12,rotation=(math.pi/2,0,0));mat(bpy.context.object,'amber' if radius<4.3 else 'metal')
for i in range(24):
 a=i*math.tau/24;o=box((math.sin(a)*4.25,-.1,math.cos(a)*4.25),(.15,.4,.65),'metal');o.rotation_euler.y=a
bpy.ops.mesh.primitive_cylinder_add(vertices=96,radius=3.65,depth=.12,rotation=(math.pi/2,0,0));mat(bpy.context.object,'amber');finish('reactor')
clear()
for z,r in [(-.7,.5),(-.3,.8),(.3,.8),(.7,.5)]:
 bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=.018,major_segments=48,minor_segments=8,location=(0,0,z));mat(bpy.context.object,'holo')
beam((0,0,-.85),(0,0,.85),.025,'holo');finish('hologram')
clear();box((0,-.5,0),(.008,1,.008),'cyan',0);finish('tracer')
clear();box((0,0,0),(.012,.012,.22),'rain',0);finish('rain_drop')
print('Original FBX kit complete.',flush=True)
