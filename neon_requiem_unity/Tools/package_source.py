"""Reproducible source-only ZIP. Run with the static-check dependencies installed."""
from pathlib import Path
import zipfile,tempfile,subprocess,json,hashlib,sys
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=True)
assert not out.is_relative_to(root),'Keep release archives outside project source'
z=out/'Neon_Requiem_Unity6_UNCOMPILED_Source.zip'
subprocess.run([sys.executable,str(root/'Tools/validate_source.py')],check=True)
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
 for f in sorted(root.rglob('*')):
  if f.is_file() and not any(x in f.relative_to(root).parts for x in ['Library','Temp','Builds','__pycache__']):archive.write(f,f.relative_to(root))
with zipfile.ZipFile(z) as archive:
 assert archive.testzip() is None
 assert 'Packages/manifest.json' in archive.namelist()
 assert not any(n.endswith('.exe') for n in archive.namelist())
 with tempfile.TemporaryDirectory(prefix='neon_requiem_check_') as directory:
  archive.extractall(directory)
  subprocess.run([sys.executable,str(Path(directory)/'Tools/validate_source.py')],check=True)
report={'file':z.name,'bytes':z.stat().st_size,'sha256':hashlib.sha256(z.read_bytes()).hexdigest(),'delivery':'Uncompiled Unity 6 HDRP source and original assets; NOT a standalone game','archive_integrity':'PASS','independent_extraction_static_check':'PASS','unity_editor':'UNAVAILABLE','windows_player':'NOT PRODUCED','actual_game_screenshots':0}
(out/'SOURCE_RELEASE.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
