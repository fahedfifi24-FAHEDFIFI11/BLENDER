"""UE 5.4 Editor Python: import the original kit, create materials and a startup map.
Run through Build-Windows.ps1 after the native Editor target has compiled.
This file is syntax-checked outside Unreal, but requires real Unreal execution.
"""
import json
from pathlib import Path
import unreal as u
ROOT=Path(u.Paths.project_dir()).resolve()
ASSETS=ROOT/'SourceAssets'
LIB=u.EditorAssetLibrary
EDIT=u.MaterialEditingLibrary

def require(condition,message):
 if not condition: raise RuntimeError(message)

def import_file(path,dest,options=None):
 task=u.AssetImportTask()
 for key,value in dict(filename=str(path),destination_path=dest,destination_name=path.stem,automated=True,replace_existing=True,save=True).items():task.set_editor_property(key,value)
 if options:task.set_editor_property('options',options)
 u.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
 obj=LIB.load_asset(dest+'/'+path.stem)
 require(obj is not None,'Import failed: '+str(path))
 return obj

def expr(mat,cls,**properties):
 obj=EDIT.create_material_expression(mat,cls)
 for key,val in properties.items():obj.set_editor_property(key,val)
 return obj

def connect(a,pin,b,target):
 require(EDIT.connect_material_expressions(a,pin,b,target),'Material connection failed: '+target)

def material(name,color,metal=.0,rough=.5,texture=None,emission=0,transparent=False):
 path='/Game/NV/Materials/M_'+name
 mat=LIB.load_asset(path)
 if mat is None:mat=u.AssetToolsHelpers.get_asset_tools().create_asset('M_'+name,'/Game/NV/Materials',u.Material,u.MaterialFactoryNew())
 EDIT.delete_all_material_expressions(mat)
 mat.set_editor_property('two_sided',transparent)
 if transparent:mat.set_editor_property('blend_mode',u.BlendMode.BLEND_TRANSLUCENT)
 tint=expr(mat,u.MaterialExpressionConstant3Vector,constant=u.LinearColor(*color,1))
 base=tint
 if texture:
  sample=expr(mat,u.MaterialExpressionTextureSample,texture=LIB.load_asset('/Game/NV/Textures/'+texture+'_color'))
  mul=expr(mat,u.MaterialExpressionMultiply);connect(sample,'RGB',mul,'A');connect(tint,'',mul,'B');base=mul
  normal=expr(mat,u.MaterialExpressionTextureSample,texture=LIB.load_asset('/Game/NV/Textures/'+texture+'_normal'),sampler_type=u.MaterialSamplerType.SAMPLERTYPE_NORMAL)
  EDIT.connect_material_property(normal,'RGB',u.MaterialProperty.MP_NORMAL)
 EDIT.connect_material_property(base,'',u.MaterialProperty.MP_BASE_COLOR)
 m=expr(mat,u.MaterialExpressionConstant,r=metal);EDIT.connect_material_property(m,'',u.MaterialProperty.MP_METALLIC)
 r=expr(mat,u.MaterialExpressionConstant,r=rough)
 if name=='wet':
  dry=expr(mat,u.MaterialExpressionConstant,r=.55)
  mask=expr(mat,u.MaterialExpressionTextureSample,texture=LIB.load_asset('/Game/NV/Textures/puddle'))
  blend=expr(mat,u.MaterialExpressionLinearInterpolate)
  connect(dry,'',blend,'A');connect(r,'',blend,'B');connect(mask,'R',blend,'Alpha');r=blend
 EDIT.connect_material_property(r,'',u.MaterialProperty.MP_ROUGHNESS)
 if emission:
  e=expr(mat,u.MaterialExpressionConstant,r=emission);mul=expr(mat,u.MaterialExpressionMultiply)
  connect(tint,'',mul,'A');connect(e,'',mul,'B');EDIT.connect_material_property(mul,'',u.MaterialProperty.MP_EMISSIVE_COLOR)
 if transparent:
  alpha=expr(mat,u.MaterialExpressionConstant,r=.28 if name=='rain' else .45)
  EDIT.connect_material_property(alpha,'',u.MaterialProperty.MP_OPACITY)
 EDIT.recompile_material(mat);LIB.save_asset(path)
 return mat

def main():
 require((ASSETS/'Meshes/facade.fbx').exists(),'SourceAssets missing: extract the complete source ZIP.')
 for path in ['Meshes','Materials','Textures','Audio']:LIB.make_directory('/Game/NV/'+path)
 LIB.make_directory('/Game/Maps')
 for path in sorted((ASSETS/'Textures').glob('*.png')):
  tex=import_file(path,'/Game/NV/Textures')
  if path.stem.endswith('_normal'):
   tex.set_editor_property('compression_settings',u.TextureCompressionSettings.TC_NORMALMAP)
   tex.set_editor_property('srgb',False)
  elif path.stem.endswith('_rough') or path.stem=='puddle':tex.set_editor_property('srgb',False)
  LIB.save_loaded_asset(tex)
 palette={
  'metal':((.85,.95,1),.75,.38,'metal',0,False),
  'concrete':((.8,.9,.95),.05,.75,'concrete',0,False),
  'bronze':((1,.85,.65),.65,.36,'bronze',0,False),
  'dark':((.025,.045,.06),.3,.45,None,0,False),
  'glass':((.025,.09,.13),.65,.12,None,0,False),
  'ivory':((.65,.68,.63),.25,.4,None,0,False),
  'cyan':((.12,.62,.8),.1,.25,None,4,False),
  'amber':((1,.36,.06),.1,.25,None,4,False),
  'rain':((.3,.5,.6),0,.3,None,.3,True),
  'holo':((.08,.6,.75),0,.3,None,3,True),
  'wet':((.8,.9,1),.1,.075,'asphalt',0,False),
 }
 mats={name:material(name,*args) for name,args in palette.items()}
 imported=[]
 for path in sorted((ASSETS/'Meshes').glob('*.fbx')):
  opts=u.FbxImportUI()
  opts.set_editor_property('import_mesh',True)
  opts.set_editor_property('import_as_skeletal',False)
  opts.set_editor_property('import_materials',False)
  opts.set_editor_property('import_textures',False)
  opts.set_editor_property('import_animations',False)
  opts.set_editor_property('automated_import_should_detect_type',False)
  opts.set_editor_property('mesh_type_to_import',u.FBXImportType.FBXIT_STATIC_MESH)
  data=opts.get_editor_property('static_mesh_import_data')
  for key,value in dict(combine_meshes=True,auto_generate_collision=True,generate_lightmap_u_vs=False,convert_scene=True,convert_scene_unit=True,force_front_x_axis=True,import_uniform_scale=1.0).items():data.set_editor_property(key,value)
  mesh=import_file(path,'/Game/NV/Meshes',opts)
  body=mesh.get_editor_property('body_setup')
  require(body is not None,'Missing collision body: '+path.stem)
  body.set_editor_property('collision_trace_flag',u.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
  slots=mesh.get_editor_property('static_materials')
  for index,slot in enumerate(slots):
   name=str(slot.get_editor_property('material_slot_name')).split('.')[0].lower()
   if path.stem=='paving' and name!='dark':name='wet'
   require(name in mats,'Unexpected material slot '+name+' in '+path.name)
   mesh.set_material(index,mats[name])
  if path.stem in ['facade','shutter','tower','hvac','reactor','security_wall']:
   settings=mesh.get_editor_property('nanite_settings');settings.set_editor_property('enabled',True);mesh.set_editor_property('nanite_settings',settings)
  LIB.save_loaded_asset(mesh);imported.append('/Game/NV/Meshes/'+path.stem)
 # Fail visibly on unit-conversion errors rather than shipping an incorrectly scaled level.
 bounds=LIB.load_asset('/Game/NV/Meshes/facade').get_bounds()
 require(400<bounds.box_extent.z<600,'Facade scale must be ~10 metres tall; inspect FBX unit conversion before packaging.')
 for path in sorted((ASSETS/'Audio').glob('*.wav')):
  wave=import_file(path,'/Game/NV/Audio')
  wave.set_editor_property('looping',path.stem in ['night','rain','vent'])
  LIB.save_loaded_asset(wave)
 district=u.load_class(None,'/Script/NeonVeil.NVDistrict')
 require(district is not None,'Compile NeonVeilEditor before running bootstrap.py.')
 require(u.EditorLevelLibrary.new_level('/Game/Maps/GhostSignal'),'Could not create startup map.')
 actor=u.EditorLevelLibrary.spawn_actor_from_class(district,u.Vector(0,0,0))
 actor.set_actor_label('Kasumi District — runtime authored layout')
 start=u.EditorLevelLibrary.spawn_actor_from_class(u.PlayerStart,u.Vector(100,0,100))
 start.set_actor_label('Courier Arrival')
 require(u.EditorLevelLibrary.save_current_level(),'Saving GhostSignal map failed.')
 LIB.save_directory('/Game/NV',only_if_is_dirty=False,recursive=True)
 require(LIB.does_asset_exist('/Game/Maps/GhostSignal'),'Startup map is absent.')
 receipt={'engine':u.SystemLibrary.get_engine_version(),'map':'/Game/Maps/GhostSignal','meshes':imported,'material_count':len(mats),'gameplay_tested':False}
 (ROOT/'Saved').mkdir(exist_ok=True)
 (ROOT/'Saved/BootstrapReceipt.json').write_text(json.dumps(receipt,indent=2))
 u.log('NEON_VEIL_BOOTSTRAP_COMPLETE: imported assets and startup map saved; gameplay is not yet tested.')
main()
