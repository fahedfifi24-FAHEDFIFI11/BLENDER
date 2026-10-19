"""Archive the COMPLETE UE staged tree. Does not turn source into an executable."""
from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
import hashlib,sys
root=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
assert (root/'NeonVeil.exe').is_file(),'Missing packaged bootstrap executable'
assert list((root/'NeonVeil/Binaries/Win64').glob('NeonVeil*.exe')),'Missing actual UE game binary'
assert list(root.rglob('*.utoc')) and list(root.rglob('*.ucas')),'Missing cooked data'
assert not out.is_relative_to(root),'ZIP must be outside the input tree'
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
 for p in sorted(root.rglob('*')):
  if p.is_file():z.write(p,str(Path('NeonVeil')/p.relative_to(root)))
with ZipFile(out) as z:assert z.testzip() is None
h=hashlib.sha256()
with out.open('rb') as f:
 for data in iter(lambda:f.read(8*1024*1024),b''):h.update(data)
out.with_suffix('.zip.sha256').write_text(h.hexdigest()+'  '+out.name+'\n')
print('ZIP64 archive verified:',out,'bytes:',out.stat().st_size)
