# Delivery validation — NEON VEIL

Engine: **Godot 4.5 stable**, standard Linux editor and matching official Windows x64
release template. Blender: **4.3.2**. Official engine/template downloads were checked
against the upstream release's SHA-512 manifest before use.

- **42/42 source functional checks passed.** Actual main scene and imported Blender
  assets load. Movement/sprint/crouch, floor support, facing/proximity interaction,
  objective order, surveillance cover/interruption, pause, closed/open gate physics,
  delivery, cinematic completion and replay were exercised.
- **42/42 embedded-export checks passed.** The same harness loads the packed game data
  directly from `NeonVeil.exe` using Linux Godot. This verifies exported references and
  game behavior, but does not execute the Windows PE program.
- The Windows release is a real **x86-64 PE executable** containing the Godot runtime
  and embedded game data. Its imports reference Windows system DLLs; the export did
  not produce separate engine libraries or a separate PCK. The packager includes every
  file in the export directory, notices, controls and screenshots.
- **Forward+ visual review:** in-engine 1280×720 images were rendered and inspected using
  software Vulkan on Linux. UI placement, route readability, architecture, lighting and
  the amber overlook were reviewed. The supplied alley screenshot comes from the game.
- ZIP entries are CRC-checked and SHA-256 checksums are recorded beside the downloads.

## Limits

No Windows machine or physical gaming GPU was available. Native Windows launch,
controller/driver compatibility and real GPU frame rates are **not tested**. No hardware
performance or measured playtime claim is made. The intended target is Windows x64 with
a modern dedicated Vulkan-capable GPU. The Balanced preset reduces expensive effects.

The automated route uses fixture teleports between terminals alongside actual input and
collision tests. It is not a complete manual first-person playthrough. Audio teardown
waits 100 ms for the independent mixer thread after the scene is freed; gameplay timing
and assertions are unchanged.

This delivery is one compact, completed environment and courier route. It is not a large
city, an open-world game or a long campaign. Decorative shops and background towers are
scenery. Asset generators, editable Blender kit and Godot source are supplied separately.
