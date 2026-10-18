# Ashen Hollow validation

Validated on Linux with Godot **4.6.3.stable.official.7d41c59c4**. The final run loaded the current gameplay scripts, procedural world, actor art, UI, audio and rain particles. Suites ran in separate headless processes. Integration was repeated to investigate exit diagnostics and validate a test teardown change.

| Suite | Passed | Failed | Process exit |
| --- | ---: | ---: | ---: |
| `tests/player_checks.gd` | 37 | 0 | 0 |
| `tests/enemy_checks.gd` | 22 | 0 | 0 |
| `tests/integration_checks.gd` | 51 | 0 | 0 |
| **Total** | **110** | **0** | |

## Reproduce

From the directory containing `project.godot`, after importing the project in Godot:

```sh
godot --headless --path . --fixed-fps 60 --script tests/player_checks.gd
godot --headless --path . --fixed-fps 60 --script tests/enemy_checks.gd
godot --headless --path . --fixed-fps 60 --script tests/integration_checks.gd
```

`--fixed-fps 60` makes timed physics fixtures deterministic. The cloud run used the absolute project path `/workspace/BLENDER/ashen_hollow` and these writable cache locations:

```sh
export XDG_DATA_HOME=/workspace/godot_tools/data
export XDG_CACHE_HOME=/workspace/godot_tools/cache
export XDG_CONFIG_HOME=/workspace/godot_tools/config
```

## Observed coverage

- Movement: floor collision, camera presence, WASD, acceleration/deceleration, sprint and stamina, jumping and landing.
- Player combat: three-hit combo and per-swing damage, heavy attack, dodge invulnerability, directional blocking, guard break, wall occlusion, lock-on release, death, respawn and menu input gates.
- Enemies: actual physics strike, single damage per swing, recovery, stagger, death/reset, dormant immunity, wall occlusion, menu gating, distinct creature attacks and poise.
- Live-scene integration: construction and input mappings, main-menu button wiring, world floor coverage, actual sword/enemy collision, actual enemy/player damage, block and dodge interactions, shrine distance and quest gates, one-time recovery reward, pause/resume, victory, Explore, restart and return to title.
- Regression cases: pausing during the victory delay still presents victory after resuming; delayed death/victory callbacks from an earlier run cannot interrupt a restart; repeated damage to a defeated bandit cannot inflate quest progress.

The paused-victory regression initially failed. The victory timer now pauses with gameplay, and the final regression passes.

## Exit diagnostics

The final player, enemy and integration runs completed without warnings or errors. An earlier integration run passed all 51 assertions and exited with code 0, but emitted these cleanup diagnostics **after its completion summary**:

```text
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
   at: cleanup (core/object/object.cpp:2663)
ERROR: 5 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:810)
```

The diagnostic `--verbose` run did not reproduce the warning, so it did not identify the retained resource types. The integration harness now drains three process frames after queuing scene deletion instead of exiting after one, giving deferred cleanup time to finish. Both verbose and ordinary runs after this change passed all 51 assertions and exited cleanly. No gameplay code or assertions were changed for this cleanup. The original resource owner was not established, so this observation is not a claim of a proven runtime memory-leak fix.

There were no GDScript parse errors or runtime-script errors in the final run. Raw cloud logs remain in `/tmp/ashen_hollow_final_checks/` for this workspace session: `player.log`, `enemy.log`, the original diagnostic-bearing `integration.log`, `integration_verbose.log`, and the clean final `integration_teardown.log` / `integration_teardown_normal.log`.

## Limits

These automated suites verify headless physics and lifecycle behavior. Quest traversal uses controlled repositioning and direct damage fixtures in addition to genuine combat collision checks; it is not a complete manual playthrough. They do not measure visual quality, combat feel, audio quality or real hardware performance.

Forward+ rendering was exercised separately on Linux with Mesa software Vulkan. The title screen, village encounter, and warden court were rendered and inspected. Screenshots are in `docs/screenshots/`. This does not establish a GPU frame-rate target or a native Windows playthrough.

## Windows export and packaged-content check

The official Godot 4.6.3 export template archive was downloaded over HTTPS and verified against its published SHA-512 checksum. Exporting `Windows Desktop` completed with exit 0 and no export errors. The output is an x86-64 PE Windows executable with embedded game data.

The Linux Godot engine then loaded that executable's **embedded game pack** and ran the same integration suite against its exported scenes and compiled scripts:

```sh
godot --headless --main-pack builds/windows/AshenHollow.exe --fixed-fps 60 --script /tmp/ashen_export_integration.gd
```

The external test script was an exact copy of `tests/integration_checks.gd`. This exported-content check passed **51/51 assertions**, exit 0, without warnings or errors. It verifies exported resource references and gameplay content, not execution of the Windows machine code. **Windows runtime gameplay has not been tested.**

## Source archive portability

The source ZIP was extracted into a new temporary directory without an existing `.godot`
cache. A fresh headless editor import and a 180-frame startup with `--fixed-fps 60`
both completed with exit 0 and no engine or script errors. Both release ZIPs passed
ZIP integrity checks; their SHA-256 hashes are published beside the downloads.
