# NEON VEIL — GHOST SIGNAL / UE 5.4 source delivery

**This archive is source, not a packaged Windows game. No UE executable was produced.**
The authoring environment has Blender and Godot, but no Unreal Editor, UnrealBuildTool,
UnrealHeaderTool, Windows SDK or UE Windows packaging toolchain. C++ compilation,
Unreal asset import, gameplay, lighting, performance and Windows launch are **unverified**.
The existing Godot game is a separate earlier delivery, not a UE build.

This source targets **Unreal Engine 5.4.x** and implements a compact third-person mission:
a neon street → sunken broker market → restricted corporate facility → timing-based hack
→ security encounter → switchback roof stair → extraction. The 10–15 minute brief remains
a playtesting target; no measured duration or AAA visual-quality claim is made.

## Build the actual game on Windows

Required: a licensed UE **5.4.x** installation with Windows support, Visual Studio 2022
with **Game development with C++**, MSVC v143 and a Windows 10/11 SDK, plus **Python 3.9+**
on PATH for ZIP64 packaging. Blender and NumPy are optional: all FBX/PNG/WAV assets are
already included. Use a modern DirectX 12 dedicated GPU for playtesting.

1. Extract this entire source ZIP to a writable directory such as `C:\Games\NeonVeil`.
2. Open PowerShell in that project directory and run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Tools\Build-Windows.ps1 -UEPath "C:\Program Files\Epic Games\UE_5.4"
   ```

   The script builds **NeonVeilEditor Win64 Development**, runs the Editor Python import,
   creates and saves the startup map, then uses **RunUAT BuildCookRun** to compile, cook,
   stage and archive **Win64 Shipping** with prerequisites. It checks exit codes, a fresh
   import receipt, the actual game binary and cooked containers before making a ZIP.
   These commands have **not been executed here**; any compile/import errors require
   correction in the target UE environment before the project is considered playable.

3. On success, the result is `BuildOutput\Neon_Veil_UE5_Windows.zip` plus its SHA-256 file.
   Extract all contents and run `NeonVeil.exe`. The complete Engine/Binaries/Content/Paks
   tree is included, not just the bootstrap EXE.
4. Run the target-machine checks in `Tools/MANUAL_VALIDATION.md` before distributing it as
   a tested game. A successful package alone does not establish working gameplay.

To generate the editable imported project first and inspect it before packaging:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-Windows.ps1 -UEPath "C:\Program Files\Epic Games\UE_5.4" -SourceOnly
```

Open `NeonVeil.uproject`, open `/Game/Maps/GhostSignal`, and press Play. The map has a native
layout actor and PlayerStart. Geometry, lights, character art and encounter actors are
constructed at runtime from the original imported asset kit. The editor viewport is not
a prebuilt art scene. Bootstrap regenerates `/Game/NV` and the generated startup map;
keep manual edits separately when rerunning it.

If a command fails, inspect the console and `Saved\Logs\NeonVeil.log`; the script stops
instead of presenting an incomplete package as a finished build. Do not substitute the
previous Godot executable. Editor plugins are editor-only; packaged runtime requires none.

## Implemented in source — pending Unreal execution

- Third-person accelerated movement, sprint, capsule crouch, jump, collision-aware
  spring-arm camera, shoulder aim and articulated original armored operative meshes.
- One automatic firearm: 18-round magazine, timed reload, camera aim trace plus a muzzle
  obstruction trace, hit confirmation, original emissive tracers and weapon sounds.
- Two security behaviors: a ranged marksman with a telegraphed shot/retreat, and a fast
  close-range breacher. Both have health, stagger, death and collision-aware local steering.
- Broker dialogue, cipher-gated corporate access, a three-pulse timing hack, five-enemy
  encounter, locked roof access and explicit extraction completion. One optional memory
  discovery supplies a recovery patch. Death/restart resets mission, gates and enemies.
- Main/pause/death/victory menus; health/ammo/objectives/proximity prompts; Low/Medium/High/
  Epic scalability and volume controls. Quality is persisted by UE GameUserSettings.
- Twenty-seven original FBX assets: architecture, shops, machines, cover, operative parts,
  rifle, actual stairs/ramps/rails, signage structures, skyline and reactor. Thirteen
  material maps and fourteen original WAV sounds are included.
- Material import generates PBR, wet-road and emissive/translucent materials. Native
  scene code adds Lumen-compatible lighting, volumetric fog, controlled bloom, mesh rain,
  moving holograms/drone, thunder and an interior/exterior rain-audio transition.
- Nanite is enabled for selected environment meshes by the import script; Lumen, Virtual
  Shadow Maps and TSR are configured. Their resulting look/performance is not verified.

Character animation uses articulated static components, not a production skeletal
animation/IK system. Rain is instanced mesh animation, **not Niagara**. There is no voice
acting, multiplayer, save system or controller mapping. The rooftop gate opens the exit
route; a separate unlockable shortcut system is not implemented. Background towers are
scenery. The native world uses original FBX surfaces rather than visible engine cubes.

## Controls

WASD move · mouse look · Shift sprint · Ctrl crouch · Space jump · RMB aim · LMB fire ·
R reload · E interact/advance dialogue/lock a hacking pulse · Esc pause/resume.

## Files and checks

`Source/NeonVeil/` contains movement/combat, enemies, authored district, mission and HUD.
`Config/` contains startup map, input, renderer and packaging configuration.
`SourceAssets/` contains the actual assets, not download placeholders.
`Tools/` contains import, build, package and validation scripts.

Verified here: JSON/project inputs and Python syntax; references to supplied mesh/audio
files; WAV format; binary FBX headers; **all 27 FBX assets reimported in Blender** with
nonempty geometry/materials and metre-scale bounds. See `SOURCE_VALIDATION.json` and
`FBX_VALIDATION.json`. These checks do **not** validate C++ APIs or Unreal gameplay.

Original models, maps and sounds were created for NEON VEIL. No paid asset packs or
third-party character downloads are required. Unreal Engine is not redistributed in
this source archive; use your installed licensed engine for building and distribution.
