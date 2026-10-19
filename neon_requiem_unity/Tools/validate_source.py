"""Static/source checks. Requires tree-sitter==0.25.2, tree-sitter-c-sharp==0.23.1, Pillow.
This NEVER substitutes for Unity compilation, package resolution or an EXE playtest.
"""
from pathlib import Path
import json,re,ast,wave,hashlib
from PIL import Image
from tree_sitter import Language,Parser
import tree_sitter_c_sharp
P=Path(__file__).resolve().parents[1]
parser=Parser(Language(tree_sitter_c_sharp.language()))
scripts=list((P/'Assets').rglob('*.cs'))
for p in scripts:
 tree=parser.parse(p.read_bytes());assert not tree.root_node.has_error,('C# grammar error',p)
for p in (P/'Tools').glob('*.py'):ast.parse(p.read_text(),filename=str(p))
for p in (P/'Assets').rglob('*.asmdef'):json.loads(p.read_text())
manifest=json.loads((P/'Packages/manifest.json').read_text())
assert manifest['dependencies']['com.unity.render-pipelines.high-definition']=='17.0.4'
assert '6000.0.62f1' in (P/'ProjectSettings/ProjectVersion.txt').read_text()
models={p.stem:p for p in (P/'Assets/NR/Resources/NR/Models').glob('*.fbx')}
world=(P/'Assets/NR/Editor/DistrictBuilder.cs').read_text()
referenced=set(re.findall(r'Asset\("([a-z_]+)"',world))|{'terminal','security_grille'}
assert referenced<=models.keys(),('Missing model',referenced-models.keys())
assert len(models)==25,len(models)
for path in models.values():assert path.read_bytes().startswith(b'Kaydara FBX Binary'),path
sources='\n'.join(p.read_text() for p in scripts)
sounds={p.stem for p in (P/'Assets/NR/Resources/NR/Audio').glob('*.wav')}
used=set(re.findall(r'(?:OneShot|Loop)\("([a-z_]+)"',sources))|{'relay','scan'}
assert used<=sounds,('Missing sound',used-sounds)
for path in (P/'Assets/NR/Resources/NR/Audio').glob('*.wav'):
 with wave.open(str(path)) as w:assert w.getnframes()>100 and w.getnchannels() in (1,2) and w.getsampwidth()==2,path
for path in (P/'Assets/NR/Textures').glob('*.png'):
 with Image.open(path) as im:
  im.verify()
  if path.stem.endswith('_mask'):assert im.mode=='RGBA',path
for name in ['asphalt','concrete','metal','bronze']:
 for suffix in ['color','normal','mask']:assert (P/'Assets/NR/Textures'/(name+'_'+suffix+'.png')).exists()
for name in re.findall(r'Sign\("([a-z_]+)"',world):assert (P/'Assets/NR/Textures'/('sign_'+name+'.png')).is_file(),name
asset_guids={}
for path in (P/'Assets').rglob('*'):
 if path.suffix=='.meta':continue
 meta=Path(str(path)+'.meta');assert meta.exists(),('Missing GUID',path)
 guid=re.search(r'^guid: ([0-9a-f]{32})$',meta.read_text(),re.M).group(1)
 assert guid not in asset_guids,('Duplicate GUID',path,asset_guids.get(guid));asset_guids[guid]=str(path.relative_to(P))
entry=(P/'Assets/NR/Scenes/SourceEntry.unity').read_text()
for guid in re.findall(r'guid: ([0-9a-f]{32})',entry):assert guid in asset_guids,guid
assert 'SourceEntry.unity' not in (P/'Assets/NR/Editor/WindowsBuild.cs').read_text()
assert not list(P.rglob('*.exe')),'Source delivery must not contain an unrelated EXE'
tests=(P/'Assets/NR/Tests/Editor/MissionRulesTests.cs').read_text().count('[Test]');assert tests==11
reimport=json.loads((P/'Validation/BLENDER_REIMPORT.json').read_text());assert reimport['result']=='PASS' and len(reimport['assets'])==len(models)
result={'scope':'Source syntax and asset packaging only; NOT Unity compilation or gameplay','static_checks':'PASS','csharp_files_parsed':len(scripts),'csharp_type_check':'NOT RUN - Unity/C# toolchain unavailable','unity_import':'NOT RUN','unity_scene_generation':'NOT RUN','unity_editmode_tests':{'included':tests,'executed':0,'status':'NOT RUN'},'fbx_reimports':len(models),'png_files':len(list((P/'Assets/NR/Textures').glob('*.png'))),'wav_files':len(sounds),'windows_exe':'NOT PRODUCED','playtest':'NOT RUN','actual_game_screenshots':0}
(P/'Validation/SOURCE_CHECKS.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
