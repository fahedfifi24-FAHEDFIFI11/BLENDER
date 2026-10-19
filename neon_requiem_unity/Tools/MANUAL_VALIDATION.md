# Required acceptance run in Unity and on the Windows EXE

All items below are **unrun** in the source-authoring environment.

1. Generate LowTide in Unity 6000.0.62f1. Require zero C# errors, missing scripts/materials,
   import exceptions and scene validator errors. Check FBX scale: facade height ~10 m;
   stairs rise 2 m per flight. Confirm all stairs point toward +Z.
2. Review ordinary first-person views in the market, undercity and platform. Inspect exposure,
   fog, signs from the intended front, normals, wetness and probe reflections. No pink surfaces,
   visible collision-only gaps, overlapping floors, primitive placeholder art or black view.
3. Start. Test WASD, acceleration, mouse, sprint, jump, pause and mouse capture. Crouch under
   cover; attempt to stand under obstruction. Confirm no head clipping or escape through walls.
4. Walk to the west listening market without jumping gaps. Interact with MOTHER. Corporate
   gate opens only after the conversation. All three relays are reachable and count once.
5. Cipher cannot run before three relays. Wrong symbols reset the sequence. Triangle → circle
   → cross recovers the signal. Opening the UI must not auto-submit the opening E key.
6. Drone detects unobstructed players, loses visibility behind cover, stops shooting through
   walls, reacts to Q within 12 m, resumes after 5 s and respects 12 s jammer cooldown.
   Verify damage, death, restart and complete reset of mission/gates/drone.
7. Override unlocks the ascent. Traverse all 24 metres of stairs without jumping, reach the
   guarded platform and transmit. Ending camera must not clip, UI must reach completion.
8. Collect the three optional memories. Check readability, objective marker occlusion/placement,
   audio inside/outside, pause/resume, graphics changes and correct state after restart.
9. Run all 11 EditMode tests. Then build Win64; launch the actual EXE from a separate extracted
   ZIP. Repeat the full route, not just the editor scene. Preserve real test/build logs.
10. Record GPU, resolution, settings, frame time and actual completion duration. Tune for 1080p.
    Capture F12 screenshots of all three areas from the running player and inspect the images.
    Do not present Blender renders or editor mockups as gameplay captures.
