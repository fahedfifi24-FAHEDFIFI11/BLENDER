"""Packaging-input checks only. This does NOT compile C++ or execute Unreal."""
from pathlib import Path
import json,ast,re,wave
P=Path(__file__).resolve().parents[1]
project=json.loads((P/'NeonVeil.uproject').read_text())
assert project['EngineAssociation']=='5.4'
assert project['Modules'][0]['Name']=='NeonVeil'
cpp='\n'.join(p.read_text() for p in (P/'Source/NeonVeil').glob('*.cpp'))
models={p.stem for p in (P/'SourceAssets/Meshes').glob('*.fbx')}
required=set(re.findall(r'Asset\("([a-z_]+)"',cpp))
required.update(['facade','shutter','courier_torso','security_torso','courier_head','courier_arm','courier_leg','rifle','rain_drop'])
assert required<=models,('Missing meshes',required-models)
for f in (P/'SourceAssets/Meshes').glob('*.fbx'):
 assert f.read_bytes().startswith(b'Kaydara FBX Binary'),f
sounds={p.stem for p in (P/'SourceAssets/Audio').glob('*.wav')}
required_audio=set(re.findall(r'Play\("([a-z_]+)"',cpp))|{'night','rain','vent'}
assert required_audio<=sounds,('Missing audio',required_audio-sounds)
for f in (P/'SourceAssets/Audio').glob('*.wav'):
 with wave.open(str(f)) as w:
  assert w.getnframes()>0 and w.getnchannels() in (1,2) and w.getsampwidth()==2,f
for f in (P/'Tools').glob('*.py'):ast.parse(f.read_text(),filename=str(f))
config=(P/'Config/DefaultEngine.ini').read_text()
assert 'GlobalDefaultGameMode=/Script/NeonVeil.NVGameMode' in config
assert '/Game/Maps/GhostSignal' in config
assert 'DirectoriesToAlwaysCook=(Path="/Game/NV")' in (P/'Config/DefaultGame.ini').read_text()
for name in ['NeonVeil.Target.cs','NeonVeilEditor.Target.cs','NeonVeil/NeonVeil.Build.cs']:
 assert (P/'Source'/name).is_file(),name
assert (P/'Source/NeonVeil/NVGame.h').read_text().count('GENERATED_BODY()')==5
report={'scope':'Static packaging inputs only. No Unreal compilation, import, gameplay or Windows packaging was performed.','result':'PASS','fbx_files':len(models),'wav_files':len(sounds),'python_syntax':'PASS','native_compile':'NOT RUN — UE5 unavailable','ue_asset_import':'NOT RUN — UE5 unavailable','windows_package':'NOT PRODUCED','windows_playtest':'NOT RUN'}
(P/'SOURCE_VALIDATION.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
