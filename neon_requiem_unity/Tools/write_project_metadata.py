"""Deterministic GUIDs for supplied assets; Unity imports full model/texture metadata."""
from pathlib import Path
import hashlib
P=Path(__file__).resolve().parents[1]
def guid(path):return hashlib.md5(('neon-requiem/'+str(path.relative_to(P)).replace('\\','/')).encode()).hexdigest()
for f in sorted((P/'Assets').rglob('*')):
 if f.suffix=='.meta':continue
 meta=Path(str(f)+'.meta')
 if meta.exists():continue
 content='fileFormatVersion: 2\nguid: '+guid(f)+'\n'
 if f.is_dir():content+='folderAsset: yes\nDefaultImporter:\n  externalObjects: {}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n'
 elif f.suffix=='.cs':content+='MonoImporter:\n  externalObjects: {}\n  serializedVersion: 2\n  defaultReferences: []\n  executionOrder: 0\n  icon: {instanceID: 0}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n'
 # Minimal non-script metadata is intentionally completed by Unity's actual importer.
 meta.write_text('\n'.join(line.rstrip() for line in content.splitlines())+'\n')
print('Deterministic source asset GUIDs written')
