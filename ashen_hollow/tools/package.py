"""Package the editable project and existing Windows export; stdlib only."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import json

PROJECT = Path(__file__).resolve().parents[1]
DELIVERY = PROJECT.parent / "releases"
DELIVERY.mkdir(exist_ok=True)
EXE = PROJECT / "builds/windows/AshenHollow.exe"
if not EXE.is_file():
    raise SystemExit("Export Windows Desktop to builds/windows/AshenHollow.exe first.")

windows_readme = """ASHEN HOLLOW — WINDOWS x86-64

Extract this entire ZIP, then run AshenHollow.exe.
The game data is embedded in the executable. No Godot installation is required.
The default renderer is Forward+.
For an older GPU, try Play_Compatibility.bat (OpenGL, reduced rendering features).

CONTROLS
WASD move | Mouse camera | Shift sprint | Space jump | Left Ctrl dodge
Left mouse: light combo | Q: heavy | Hold right mouse: frontal block
Tab: lock/unlock | Mouse wheel while locked: change target | E: inspect shrine
Esc: pause/resume

QUEST
Follow the forest road. Defeat the three village bandits. Continue north to
the blue-lit shrine and press E. Defeat the Hollow Warden in the ruined court.
Reading the shrine restores 35 health and all stamina. Death offers a full restart.

VERIFICATION
Godot 4.6.3. 110 source-project automated checks passed. The exported embedded
game data passed 51 integration checks using the Linux Godot engine.
Forward+ screenshots were inspected on Linux. Native Windows execution has
not been tested in the build environment.

Fonts: DejaVu; see LICENSES. Engine: Godot, MIT; full engine notices included.
"""
windows_zip = DELIVERY / "Ashen_Hollow_Windows.zip"
with ZipFile(windows_zip, "w", ZIP_DEFLATED, compresslevel=9) as z:
    z.write(EXE, "AshenHollow/AshenHollow.exe")
    z.writestr("AshenHollow/READ_ME.txt", windows_readme)
    z.writestr("AshenHollow/Play_Compatibility.bat", '@echo off\r\ncd /d "%~dp0"\r\nstart "Ashen Hollow" "%~dp0AshenHollow.exe" --rendering-method gl_compatibility\r\n')
    for name in ("GODOT_LICENSE.txt", "GODOT_THIRD_PARTY.txt"):
        z.write(PROJECT / "docs" / name, "AshenHollow/LICENSES/" + name)
    z.write(PROJECT / "assets/fonts/LICENSE.txt", "AshenHollow/LICENSES/DEJAVU.txt")
    for image in sorted((PROJECT / "docs/screenshots").glob("*.png")):
        z.write(image, "AshenHollow/SCREENSHOTS/" + image.name)

source_zip = DELIVERY / "Ashen_Hollow_Source.zip"
excluded_dirs = {".godot", "builds", "test-results", "__pycache__", ".git"}
with ZipFile(source_zip, "w", ZIP_DEFLATED, compresslevel=9) as z:
    for path in sorted(PROJECT.rglob("*")):
        rel = path.relative_to(PROJECT)
        if not path.is_file() or any(part in excluded_dirs for part in rel.parts):
            continue
        if path.suffix in (".tmp", ".zip", ".pyc"):
            continue
        z.write(path, str(Path("AshenHollow") / rel))

manifest = {"project": "Ashen Hollow", "version": "0.1.0", "engine": "Godot 4.6.3", "artifacts": []}
for path in (windows_zip, source_zip):
    with ZipFile(path) as z:
        assert z.testzip() is None, path
        entries = len(z.namelist())
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    manifest["artifacts"].append({"file": path.name, "bytes": path.stat().st_size, "sha256": digest, "entries": entries})
    print(f"Verified {path.name}: {path.stat().st_size:,} bytes, {entries} entries, SHA256 {digest}")
(DELIVERY / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
(DELIVERY / "SHA256SUMS.txt").write_text("\n".join(f"{entry['sha256']}  {entry['file']}" for entry in manifest["artifacts"]) + "\n")
