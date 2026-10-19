# Required UE / Windows acceptance checks — not run in the cloud environment

1. Build the Editor target; reject all UHT/C++ errors. Run bootstrap and inspect its receipt.
2. Open GhostSignal and Play. Confirm floor/character/metre scale, imported material slots,
   clear initial camera, functional title buttons, no missing assets and no fatal log errors.
3. Move, sprint, crouch and jump. Orbit beside walls; test spring-arm collision. Check both
   descent and ascent of the market ramp, all three stair flights and rooftop headroom.
4. Talk to Ivo three times; dialogue must advance only nearby and facing him. Check the
   corporate gate cannot be bypassed and opens after its console is used.
5. Hack: misses lose a lock, one success is allowed per pulse, three distinct successes
   trigger security, walking away cancels. Pause must freeze hacking and AI timers.
6. Shoot both enemy roles; verify actual damage, hit feedback, ammo, reload and stagger.
   Both camera and muzzle traces must be blocked by solid cover. Enemies must hit the
   player when exposed, respect cover and stop attacking on death or menu states.
7. Defeat all five units. Roof access must open only then. Reach extraction via the stairs
   and use its terminal. Verify victory menu, replay, death/restart and return-to-title.
8. Test optional memory recovery once only; confirm it cannot skip the main quest.
9. Review silhouettes, signs, wet materials, lighting and fog in Unreal. Test Low/Medium/
   High/Epic, menu responsiveness, volume including weapon sounds, and interior ambience.
10. Package Shipping. Test the EXTRACTED ZIP on Windows without the editor running. Follow
    the complete mission, inspect logs for missing cooked assets, record GPU/driver/FPS
    and measured first-play duration. No performance or 10–15 minute claim before this.

The source's static checks and Blender reimports are not substitutes for these checks.
