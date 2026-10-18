"""Package the verified standalone export; preserve all required engine dependencies."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib,json
P=Path(__file__).resolve().parents[1]
D=P.parent/'neon_releases';D.mkdir(exist_ok=True)
B=P/'builds/windows';exe=B/'NeonVeil.exe'
assert exe.is_file() and exe.stat().st_size>90_000_000,'Missing real Windows release export'
with exe.open('rb') as f: assert f.read(2)==b'MZ','Not a Windows PE executable'
readme='''NEON VEIL — KASUMI PASSAGE | GODOT 4.5 | WINDOWS x64

Extract this entire ZIP. Run NeonVeil.exe. No Godot or Blender installation needed.
Keep every file beside the executable in place. Game data is embedded in the EXE.
Use a modern Windows x64 PC with Vulkan-capable graphics and current GPU drivers.

WASD: move | Mouse: look | Shift: sprint | Ctrl: crouch
E: use terminal while looking at it | Esc: pause / resume

Copy the cipher at the left terminal. Reroute the relay on the right.
Crouch beneath its awning until the patrol clears. Open the transit gate,
then deliver the archive at the private uplink. Follow the objective and diamond.
Balanced visuals reduce expensive fog/reflections. No save system; replay from title.

The Windows export contains the actual game and runtime. Functional checks and
Forward+ rendering were performed on Linux, including testing the exported embedded
game data. Native Windows execution and Windows GPU performance were not tested.

Original environment models, textures, music and sounds. DejaVu fonts and Godot
engine/dependency license notices are included in LICENSES.
'''
with ZipFile(D/'Neon_Veil_Windows.zip','w',ZIP_DEFLATED,compresslevel=9) as z:
 for f in sorted(B.rglob('*')):
  if f.is_file():z.write(f,str(Path('NeonVeil')/f.relative_to(B)))
 z.writestr('NeonVeil/READ_ME.txt',readme)
 for name in ['GODOT_LICENSE.txt','GODOT_THIRD_PARTY.txt']:z.write(P/'docs'/name,'NeonVeil/LICENSES/'+name)
 z.write(P/'assets/fonts/LICENSE.txt','NeonVeil/LICENSES/DEJAVU.txt')
 for f in (P/'docs/screenshots').glob('*.png'):z.write(f,'NeonVeil/SCREENSHOTS/'+f.name)
with ZipFile(D/'Neon_Veil_Source.zip','w',ZIP_DEFLATED,compresslevel=9) as z:
 for f in sorted(P.rglob('*')):
  r=f.relative_to(P)
  if f.is_file() and not any(x in {'.godot','builds','test-results','__pycache__'} for x in r.parts) and f.suffix not in {'.blend1','.pyc'}:z.write(f,str(Path('NeonVeil')/r))
manifest={'game':'NEON VEIL — Kasumi Passage','engine':'Godot 4.5 stable','artifacts':[]}
for f in sorted(D.glob('*.zip')):
 with ZipFile(f) as z: assert z.testzip() is None
 h=hashlib.sha256(f.read_bytes()).hexdigest()
 manifest['artifacts'].append({'file':f.name,'bytes':f.stat().st_size,'sha256':h})
 print(f.name,f.stat().st_size,h)
(D/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(D/'SHA256SUMS.txt').write_text(''.join(f"{x['sha256']}  {x['file']}\n" for x in manifest['artifacts']))
