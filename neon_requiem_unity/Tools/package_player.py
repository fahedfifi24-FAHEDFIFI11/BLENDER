"""Archive an ACTUAL Unity Windows player; reject source-only/fake outputs."""
import sys,zipfile,hashlib
from pathlib import Path
root=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
assert not out.is_relative_to(root),'Output ZIP must be outside the player tree'
for name in ['NeonRequiem.exe','UnityPlayer.dll','NeonRequiem_Data/globalgamemanagers']:
 p=root/name;assert p.is_file() and p.stat().st_size>0,('Missing player file',name)
for name in ['NeonRequiem.exe','UnityPlayer.dll']:
 with (root/name).open('rb') as f:assert f.read(2)==b'MZ',('Not a Windows PE file',name)
assert (root/'MonoBleedingEdge').is_dir(),'Mono runtime missing'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,allowZip64=True) as z:
 for p in sorted(root.rglob('*')):
  if p.is_file():z.write(p,p.relative_to(root))
with zipfile.ZipFile(out) as z:assert z.testzip() is None
out.with_suffix('.sha256').write_text(hashlib.sha256(out.read_bytes()).hexdigest()+'  '+out.name+'\n')
print('Complete player ZIP written; this does not establish a successful playtest:',out)
