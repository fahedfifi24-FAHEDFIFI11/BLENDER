"""Blender 4.3.2: export the original kit and author Requiem infrastructure in metres."""
import bpy, math, json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parents[1]; OUT=P/'Assets/NR/Resources/NR/Models'
OUT.mkdir(parents=True,exist_ok=True);records=[]
def clear():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
M={}
def mat(key):
 if key not in M:
  m=bpy.data.materials.new(key);m.diffuse_color=(*{'metal':(.18,.23,.25),'bronze':(.38,.25,.12),'concrete':(.33,.37,.38),'dark':(.025,.035,.04),'amber':(.9,.34,.06),'cyan':(.06,.48,.6),'ivory':(.6,.65,.6)}[key],1);M[key]=m
 return M[key]
def finish_obj(o,key,bevel=.025):
 o.data.materials.append(mat(key))
 if bevel:
  b=o.modifiers.new('Manufactured rounded edges','BEVEL');b.width=bevel;b.segments=3
  o.modifiers.new('Weighted surface normals','WEIGHTED_NORMAL')
 return o
def box(at,scale,key='metal',bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);return finish_obj(o,key,bevel)
def beam(a,b,r=.07,key='metal'):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=20,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return finish_obj(o,key,.012)
def ring(at,r,minor=.04,key='bronze',rot=(math.pi/2,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_radius=r,minor_radius=minor,major_segments=32,minor_segments=10,location=at,rotation=rot);return finish_obj(bpy.context.object,key,0)
def export(name):
 objs=[o for o in bpy.context.scene.objects if o.type=='MESH'];bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
 bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_anim=False,add_leaf_bones=False)
 records.append({'name':name,'vertices':len(o.data.vertices),'dimensions_metres':list(o.dimensions),'materials':[m.name.split('.')[0] for m in o.data.materials]})
for f in sorted((P/'SourceArt/BaseFBX').glob('*.fbx')):
 clear();bpy.ops.import_scene.fbx(filepath=str(f));export(f.stem)
clear()
# Arched service ribs, repeated segments create a curved, layered silhouette.
for side in [-1,1]:
 beam((side*3.8,0,0),(side*3.8,0,3),.15)
 box((side*3.8,0,.15),(.65,.9,.3),'bronze')
for i in range(16):
 a,b=math.pi*i/16,math.pi*(i+1)/16
 beam((3.8*math.cos(a),0,3+1.5*math.sin(a)),(3.8*math.cos(b),0,3+1.5*math.sin(b)),.16)
 beam((3.65*math.cos(a),-.18,3+1.35*math.sin(a)),(3.65*math.cos(b),-.18,3+1.35*math.sin(b)),.025,'amber')
export('service_arch')
clear()
for x in [-.7,0,.65]:
 beam((x,0,.3),(x,0,4.5),.14 if x else .23)
 for z in [.6,1.4,2.7,4.1]:ring((x,0,z),.17 if x else .26,.035,'bronze',rot=(0,0,0))
beam((0,0,2.2),(0,-.45,2.2),.09,'bronze');ring((0,-.5,2.2),.32,.035)
for i in range(6):
 a=math.tau*i/6;beam((0,-.5,2.2),(.3*math.cos(a),-.5,2.2+.3*math.sin(a)),.015,'bronze')
for z in [1,3.5]:box((0,.12,z),(2,.15,.1),'dark')
export('pipe_bank')
clear()
for side in [-1,1]:box((side*1.9,0,1.8),(.2,.8,3.6),'bronze')
box((0,0,3.55),(4,.8,.2),'bronze')
for x in range(-8,9):beam((x*.21,-.14,.2),(x*.21,-.14,3.4),.035)
for z in [.3,1.3,2.4,3.4]:beam((-1.8,-.2,z),(1.8,-.2,z),.06)
export('security_grille')
clear()
for i in range(12):
 y=(i+.5)*.5;z=(i+1)/6
 box((0,y,z-.075),(3,.5,.15),'metal',.015)
 box((0,y-.23,z+.008),(2.9,.035,.012),'amber',.003)
for x in [-1.5,1.5]:
 beam((x,0,1),(x,6,3),.035)
 for i in range(7):beam((x,i,i/3),(x,i,i/3+1),.023)
export('ascent_stair')
clear()
# Dense turbine housing, fins, copper pipes and a framed inspection port.
box((0,0,1.3),(2.8,1.8,2.6),'metal',.15)
for x in [-1.2,1.2]:box((x,-1,1.3),(.18,.22,2.3),'bronze',.04)
ring((0,-1,1.4),.78,.09);ring((0,-1.02,1.4),.62,.025,'cyan')
for i in range(12):
 a=math.tau*i/12;beam((.15*math.cos(a),-1.05,1.4+.15*math.sin(a)),(.65*math.cos(a+.25),-1.05,1.4+.65*math.sin(a+.25)),.055)
for z in [.25,.4,2.35]:box((0,-1,z),(1.85,.16,.06),'dark')
for x in [-.9,.9]:beam((x,.7,2.4),(x,.7,3.1),.12,'bronze')
export('turbine')
clear()
# Raised ribs, gutters and edge-strip lamp make a structural deck, not a floating cube.
box((0,0,-.16),(8,6,.3),'concrete',.04)
for x in [-3.7,3.7]:
 box((x,0,.02),(.18,6,.08),'metal')
 for y in [-2.7,-1.8,-.9,0,.9,1.8,2.7]:box((x,y,.07),(.1,.4,.012),'amber',.002)
for x in range(-3,4):box((x,0,.001),(.015,5.8,.01),'dark',.002)
export('district_deck')
clear()
for i in range(24):
 a=math.tau*i/24;beam((math.cos(a),0,math.sin(a)),(math.cos(a+.12),0,math.sin(a+.12)),.025,'cyan')
for i in range(6):
 a=math.tau*i/6;beam((.35*math.cos(a),0,.35*math.sin(a)),(.8*math.cos(a),0,.8*math.sin(a)),.045,'bronze')
box((0,0,0),(.18,.12,.6),'amber');export('signal_emblem')
clear()
box((0,0,2.5),(6,.22,5),'concrete',.045)
for x in [-2.9,0,2.9]:box((x,-.16,2.5),(.11,.18,5),'metal',.018)
for z in [.25,1.8,3.3,4.8]:box((0,-.18,z),(5.85,.13,.065),'bronze',.01)
for x in [-2.2,-1.8,-1.4,1.4,1.8,2.2]:
 for z in [1,3.8]:box((x,-.21,z),(.19,.09,.65),'dark',.015)
export('service_wall')
clear()
box((0,0,0),(1.2,.28,.28),'metal',.06)
box((0,-.16,0),(1.02,.035,.15),'ivory',.025)
for x in [-.5,-.3,0,.3,.5]:box((x,-.19,0),(.025,.055,.23),'bronze',.008)
export('practical_fixture')
(P/'Validation/ASSET_AUTHORING.json').write_text(json.dumps(records,indent=2)+'\n')
print('REQUiEM_ASSETS_EXPORTED',len(records),flush=True)
