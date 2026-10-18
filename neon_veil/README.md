# NEON VEIL — Kasumi Passage

A compact, complete first-person courier experience built with **Godot 4.5 Forward+**.
One rainy street, a private transit gate, and an industrial overlook beneath an amber
reactor. The focus is a carefully composed environment, not a large city.

## Play

Extract the complete `Neon_Veil_Windows.zip` and run `NeonVeil.exe`.
The game data and Godot runtime are embedded; no editor installation is needed.
Windows x64 with a modern Vulkan-capable dedicated GPU is the intended target.
Choose **Balanced** on the title menu if cinematic reflections and volumetric fog are
expensive on your GPU. Balanced keeps the same game and geometry.

- **WASD:** walk. **Mouse:** look. **Shift:** sprint. **Ctrl:** crouch.
- **E:** use the indicated terminal while looking at it. **Esc:** pause/resume.
- Follow the objective and diamond marker. Copy the cipher, reroute the relay, crouch
  under the right-hand relay awning until the patrol leaves, authenticate the gate,
  then transmit the archive at the overlook.
- The closing sequence offers replay. This short experience has no save system.

Crouching lowers the viewpoint and slows movement; the route does not require crawling
through low tunnels. There is no combat or jump mechanic. The surveillance encounter
requires staying concealed, with interrupted progress if you stand or leave cover.

## Art and source

Eight original Blender assets provide beveled architecture, shutter shops, HVAC fans,
food stalls, cargo cases, terminals, a mechanical gate and a surveillance drone. The
editable kit is `source_art/Neon_Veil_Kit.blend`; runtime assets are GLB. Original
albedo/normal/roughness maps, animated puddle shading, rain, volumetric shafts, SSR,
a local reflection probe, and a restrained palette support the scene.

The skyline is scenery beyond the playable street. Terminals are interactive; decorative
storefronts and distant buildings are not enterable. No human voice acting is included;
radio dialogue appears as subtitles over an original synthesized stereo soundscape.

Open `project.godot` with Godot **4.5 standard** to edit. Run the main scene with F5.
Asset generators require Blender 4.3.2 and Python with NumPy/Pillow, but playing or
editing the supplied runtime assets needs neither. No plugins or online services.

## Verify / export

```sh
godot --headless --editor --import --quit
godot --headless --path . --fixed-fps 60 --script tests/playthrough.gd
godot --headless --export-release "Windows Desktop" builds/windows/NeonVeil.exe
python tools/package.py
```

Install the matching official **4.5 stable** Windows release template before exporting.
Tests exercise actual movement, collision, interaction gates, cover timing, pause,
restart and the complete objective sequence. Fixture teleports move between interaction
locations; this is not a human playthrough or a Windows performance benchmark.

Windows packaging and embedded game data are checked on Linux. Native Windows execution
is unavailable in the build environment. See `docs/VALIDATION.md` for recorded results.

Original game assets/code/audio were created for this project. Fonts are DejaVu;
license in `assets/fonts/LICENSE.txt`. Godot and dependency notices are included in `docs`.
