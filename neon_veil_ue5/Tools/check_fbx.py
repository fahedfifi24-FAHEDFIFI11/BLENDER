"""Actual Blender FBX reimport validation, not Unreal validation."""
import bpy,json
from pathlib import Path
from mathutils import Vector
P=Path(__file__).resolve().parents[1]
results=[]
for f in sorted((P/'SourceAssets/Meshes').glob('*.fbx')):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.fbx(filepath=str(f))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 assert meshes,f
 points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
 dimensions=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
 assert all(d>0 for d in dimensions),(f,dimensions)
 assert all(len(o.data.polygons)>0 for o in meshes),f
 mats=sorted(set(m.name.split('.')[0] for o in meshes for m in o.data.materials if m))
 assert set(mats)<={'metal','dark','bronze','concrete','ivory','cyan','amber','rain','holo','glass'},(f,mats)
 if f.stem=='facade':assert 9.5<dimensions[2]<10.5,dimensions
 results.append({'asset':f.name,'blender_dimensions_metres':[round(d,4) for d in dimensions],'materials':mats,'mesh_count':len(meshes)})
(P/'FBX_VALIDATION.json').write_text(json.dumps({'scope':'Blender reimport only; not Unreal import or playtesting','assets':results},indent=2))
print('FBX_REIMPORT_PASS',len(results),flush=True)
