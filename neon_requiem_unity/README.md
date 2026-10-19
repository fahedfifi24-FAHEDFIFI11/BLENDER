# NEON REQUIEM — Ghosts in the Rain

**Unity 6 HDRP SOURCE DELIVERY. No Windows executable or running-game screenshots were produced.**

This cloud machine has Blender 4.3.2 but no Unity Editor, activated Unity installation,
Windows player module or C# compiler. The source has not been compiled, imported,
rendered or played in Unity. The project is not a verified finished game. In accordance
with the requested fallback, this archive contains the actual editable project source,
original assets, scene-generation code and a Windows build workflow. It does not contain
an unrelated executable or a concept image presented as a gameplay screenshot.

## Exact target and requirements

- Unity **6000.0.62f1**, with **Windows Build Support (Mono)** installed through Unity Hub.
  No installed Unity version was available to select; this is an explicit compatibility
  target, not a claim to use the latest installed LTS. Other 6000.0 patches need validation.
- HDRP **17.0.4**. Its official `6000.0/staging` package manifest states Unity `6000.0`.
- Unity Test Framework **1.4.5**. Unity Package Manager must resolve the declared packages.
- A normally activated Unity installation. No license credentials are included.
- A Windows PC with a suitable dedicated GPU; DX11 is the default non-ray-traced path.
- Python 3.9+ on PATH only for packaging the complete player with ZIP64.
- Blender and Python/Pillow/NumPy are optional for regenerating source art, not for Unity builds.

No package lockfile is fabricated: Unity has not resolved the dependency graph here.
The Unity package registry returned an HTTP proxy 403 in this cloud environment, including
an elevated retry. Official HDRP source was readable through raw.githubusercontent.com;
selected public API definitions were checked there. That is not a Unity compilation test.

## Generate the editable scene

1. Extract the entire ZIP to a writable directory, for example `C:\Games\NeonRequiem`.
2. Add that directory through Unity Hub and open it with the target editor.
3. Wait for package resolution and C# compilation. Fix any errors before continuing.
4. Choose **Neon Requiem → Generate District**.
5. Open `Assets/NR/Scenes/LowTide.unity` and press Play; select **Enter Low Tide District**.

Generation imports the original FBX/PNG/WAV files, creates real HDRP materials and pipeline
assets, places editable meshes/lights/probes/colliders/stations, wires references, saves the
scene, and sets build scenes. This is an editor authoring operation, not a runtime world
blockout. **The delivered archive does not contain a Unity-generated LowTide scene or
Generated materials yet**, because Unity could not run here. `SourceEntry.unity` is an
explicit setup notice, never included as the playable build scene. The generator must run
successfully to create the complete scene. It regenerates `Assets/NR/Generated` and LowTide;
keep manual art edits in a separate scene before regenerating.

The menu performs scene-reference and floor-presence checks, not a player walkthrough.
If Unity reports an API or import error, the project requires correction in that editor;
this source delivery does not guarantee that these unexecuted steps succeed unchanged.

## Build a standalone Windows game

Open PowerShell in the project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\Tools\Build-Windows.ps1 -UnityEditor "C:\Program Files\Unity\Hub\Editor\6000.0.62f1\Editor\Unity.exe"
```

The script generates the scene, requires all 11 EditMode mission-rule tests to pass, builds
Win64 with the Mono runtime, verifies fresh receipts and player files, and archives the
**whole player tree**. On success the result is `Builds\Neon_Requiem_Windows.zip`.
Extract all files together and run `NeonRequiem.exe`; the end player needs no Unity Editor.
This command has **not** been executed in this environment. Logs go to `Validation/`.

Use `-GenerateOnly` to stop after generating the editable project. For direct editor tests,
open **Window → General → Test Runner → EditMode** and run `NeonRequiem.Tests`.
Perform `Tools/MANUAL_VALIDATION.md` on the actual Windows build before distributing it as tested.

## Implemented in source, awaiting Unity execution

- First-person accelerated movement, mouse look, sprint, crouch with head clearance, jump,
  collision, restrained camera motion and footsteps.
- A warm west market, cool service corridor and amber skyline ascent built from an original
  modular kit. New infrastructure includes curved ribs, pipe/valve banks, turbine housings,
  service panels, practical fixtures, guarded stairs, structural decks and a signal emblem.
- Mission: listen to MOTHER → restore three distinct relays → enter a three-symbol cipher →
  evade a line-of-sight security drone → disable security → ascend → transmit and end.
- Gates enforce mission order. Invalid/duplicate actions cannot skip progression. Three
  optional memories supply environmental story. A drone jam lasts five seconds and has a
  twelve-second recharge. Cover/crouching reduce exposure; death supports restart.
- Title/pause/death/completion UI, objective and proximity cues, integrity, alert and jammer
  indicators, adjustable audio/mouse sensitivity, Medium/High/Ultra rendering settings.
- Original 25 FBX models, texture maps and signage, 14 WAV sounds and a source Blender kit.
  Requiem additions are generated by `Tools/author_kit.py`; editable meshes are also FBX.
- HDRP Lit PBR materials with normals and proper RGBA mask channels; wet smoothness varies
  with the original puddle mask. Filmic ACES, restrained bloom, exposure adaptation, TAA,
  volumetric fog, SSR, SSAO and selected shadowed practical lights are configured.
- Three on-enable realtime reflection probes provide an off-screen fallback. Medium disables
  SSR, High enables SSR, Ultra additionally enables screen-space GI. No baked GI is supplied.
- Bounded particle rain and ventilation steam, rotating signage, floating security drone, original ambient
  music/rain/vent/interaction sounds, an interior rain-volume transition and ending camera.
- F12 captures a real frame after the game is actually running, to the player log's reported
  `Application.persistentDataPath/Screenshots` directory. No such captures exist yet.

## Honest scope and visual limitations

This is authored source for a compact experience, not a verified AAA-quality environment.
The 8–12 minute target and 1080p performance have not been measured. Expect tuning and a
visual polish pass in Unity; orientation, material appearance, exposure and collision need
real editor review. Character/NPC crowds, voiced dialogue, save/load and combat weapons
are not included. MOTHER is an audio/text listening terminal, not a character model.

Hardware ray-tracing support is logged at runtime, but **no ray-traced mode is enabled or
claimed tested**. Adaptive Probe Volumes are disabled because no probe bake was possible.
Animated screens use HDRP materials and transforms/property blocks, **not authored Shader
Graph assets**. The delivered surface detail is in meshes/textures, not a decal system.
There are no baked lightmaps, occlusion data or authored LOD tiers. Shared meshes/materials
use instancing-compatible materials, bounded particles and a restricted number of shadow
lights; resulting draw calls/performance are unmeasured. These omissions are deliberate
limits of this unexecuted source fallback, not hidden completed features.

## Controls

WASD move · mouse look · Shift sprint · Ctrl crouch · Space jump · E interact · Q jam drone ·
Esc pause/back · A/D select cipher symbol · Enter submit · F12 actual screenshot.

## Validation and asset rights

`Validation/SOURCE_CHECKS.json` distinguishes passed static checks from unrun Unity tests.
`Validation/BLENDER_REIMPORT.json` records actual FBX reimport/geometry/scale checks.
C# syntax parsing does not resolve Unity APIs or prove gameplay. Eleven NUnit tests are
included; none has been run in Unity here. No EXE build, performance or screenshot claim
is made by these reports.

All model geometry, texture content and audio were authored for this repository, including
reused original NEON VEIL assets. No paid packs or third-party game assets are required.
Rendered signage uses the installed DejaVu Sans font; no font binary is redistributed.
Unity and HDRP are dependencies obtained from Unity, not redistributed engine binaries.
