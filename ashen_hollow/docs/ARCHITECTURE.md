# Architecture notes

The main scene creates a `World`, `Player`, `Enemies`, `Interface`, and effects director.
Player and enemy scenes are independently reusable `CharacterBody3D` actors. Gameplay
signals carry damage feedback and defeats to the main scene; the UI emits requests and
never controls the scene tree's pause state itself.

World geometry uses meters, Y up, and -Z forward. Collision layers are world=1,
player=2, enemies=4. Actors collide with the world; combat overlap queries explicitly
query opposing actor layers and use a world ray to reject hits through walls. An attack
records struck actor IDs so it deals damage once per active window.

Player action state, enemy FSM state, and character animation are separate. The art
script consumes named motions and normalized action phases. Damage can stagger actors
and interrupt attacks; a successful dodge or frontal block is resolved by the target's
`receive_hit` function. Creature poise allows it to resist isolated light hits.

The quest progresses through arrival → bandits → shrine → warden → complete. Shrine
interaction requires both the appropriate quest stage and physical proximity. Defeat
signals advance objectives. A run identifier guards delayed death/victory callbacks
against stale restarts. The victory presentation timer pauses with gameplay.

The root and UI can process pause/menu events while actor, world, and effects nodes use
pausable processing. Restart resets persistent enemy nodes rather than reloading the
entire environment. The default renderer is Forward+; geometry and materials also allow
an optional compatibility-renderer launch.

Cobblestones, leaves, grass, and rocks use `MultiMesh` batches. Most lanterns do not cast
shadows; a directional light supplies the primary shadow map. Procedural geometry is
generated once at startup, apart from character pose and cloak updates. This is a small
authored map, not an open-world streaming system.
