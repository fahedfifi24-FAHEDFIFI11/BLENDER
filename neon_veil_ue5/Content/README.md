# Generated Unreal content

`Tools/bootstrap.py` imports the supplied FBX/PNG/WAV sources into `/Game/NV` and creates
`/Game/Maps/GhostSignal.umap` after the native Editor module has compiled.

No `.uasset` or `.umap` was fabricated without Unreal. The shipped source does not yet
contain cooked content or a compiled game. The map's native `NVDistrict` actor assembles
the authored layout during BeginPlay; use Play In Editor to inspect it after bootstrap.
