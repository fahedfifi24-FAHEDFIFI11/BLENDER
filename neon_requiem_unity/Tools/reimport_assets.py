"""Run with Blender --background --python-exit-code 2 --python Tools/reimport_assets.py."""
import bpy,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parents[1];results=[]
for f in sorted((P/'Assets/NR/Resources/NR/Models').glob('*.fbx')):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(f))
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert objects,f
 vertices=sum(len(o.data.vertices) for o in objects);assert vertices>0,f
 points=[o.matrix_world@Vector(c) for o in objects for c in o.bound_box]
 size=[max(v[i] for v in points)-min(v[i] for v in points) for i in range(3)]
 assert min(size)>.005,f
 if f.stem=='facade':assert 9.8<size[2]<10.2,(f,size)
 if f.stem=='ascent_stair':assert 5.9<size[1]<6.2 and 3<size[2]<3.2,(f,size)
 results.append({'file':f.name,'vertices':vertices,'world_bounds_metres':size})
(P/'Validation/BLENDER_REIMPORT.json').write_text(json.dumps({'result':'PASS','scope':'Blender FBX import, geometry and scale only; NOT Unity import','assets':results},indent=2)+'\n')
print('NR_FBX_REIMPORT_PASS',len(results))
