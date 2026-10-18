extends SceneTree
var checks := 0
var failures := 0
var game: Node3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks += 1
 if ok:print("PASS ",label)
 else:
  failures += 1
  push_error("FAIL "+label)
func ticks(n: int) -> void:
 for i in n:await physics_frame
func approach(id: String,offset: Vector3) -> void:
 var target: Node3D = game.world.terminals[id]
 game.player.reset_at(target.position+offset)
 await ticks(3)
 game.player.camera.look_at(target.position+Vector3(0,1.4,0))
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await ticks(3)
 check(game.world != null and game.player != null and game.ui != null,"main scene constructs the complete environment, courier and interface")
 check(game.world.terminals.size()==4,"four authored interactive terminals exist")
 check(game.mode==0 and not game.player.enabled,"title disables movement")
 check(not game.try_interact(),"interaction rejected on title")
 check(game.world.environment.ssr_enabled and game.world.environment.volumetric_fog_enabled,"cinematic preset enables wet reflections and volumetric fog")
 game.toggle_quality()
 check(not game.world.environment.ssr_enabled and not game.world.environment.volumetric_fog_enabled,"balanced preset disables expensive reflection/fog effects")
 game.toggle_quality()
 check(game.world.environment.ssr_enabled,"cinematic preset restores effects")
 for id: String in ["facade","shutter","hvac","terminal","stall","crate","gate","drone"]:
  check(load("res://assets/models/"+id+".glb") != null,"Blender asset resolves: "+id)
 game.start_game()
 await ticks(30)
 check(game.stage==0 and game.mode==1 and game.player.enabled,"begin enters fresh playable route")
 check(game.player.is_on_floor() and absf(game.player.position.y)<.1,"street collision supports first-person character")
 var start: Vector3 = game.player.position
 Input.action_press("forward")
 await ticks(60)
 Input.action_release("forward")
 var walk_distance: float = start.z-game.player.position.z
 check(walk_distance>2.4,"W input moves courier through actual world physics")
 Input.action_press("crouch")
 await ticks(30)
 check(game.player.crouching and game.player.camera.position.y<1.15,"Ctrl lowers camera and enters crouch state")
 Input.action_release("crouch")
 await ticks(20)
 var before: Vector3 = game.player.position
 Input.action_press("sprint")
 Input.action_press("forward")
 await ticks(60)
 Input.action_release("forward")
 Input.action_release("sprint")
 check(before.z-game.player.position.z>walk_distance*1.4,"sprint increases actual travel speed")
 check(not game.try_interact(),"terminal use rejected at distance")
 await approach("receiver",Vector3(0,.15,1.7))
 check(not game.try_interact() and game.stage==0,"uplink cannot skip the courier route")
 await approach("key",Vector3(1.7,.15,0))
 game.player.camera.rotation = Vector3.ZERO
 check(not game.can_interact(),"terminal requires looking toward its screen")
 game.player.camera.look_at(game.world.terminals.key.position+Vector3(0,1.4,0))
 check(game.try_interact() and game.stage==1,"copy cipher advances to relay objective")
 check(not game.try_interact(),"cipher cannot trigger the next objective twice")
 await approach("power",Vector3(-1.7,.15,0))
 check(game.try_interact() and game.stage==2 and game.world.scan_active,"relay activates surveillance encounter")
 await ticks(260)
 check(game.stage==2 and game.cover_time==0,"standing exposed cannot complete the patrol")
 game.player.reset_at(Vector3(3.55,.1,-10))
 Input.action_press("crouch")
 await ticks(70)
 check(game.cover_time>0.9 and game.cover_time<2,"crouched shelter accumulates safe cover time")
 Input.action_release("crouch")
 await ticks(50)
 check(game.cover_time<.1,"leaving crouch interrupts cover progress")
 Input.action_press("crouch")
 await ticks(60)
 game.pause_game()
 var progress: float = game.cover_time
 await ticks(120)
 check(paused and is_equal_approx(game.cover_time,progress),"pause freezes surveillance timer")
 check(not game.try_interact(),"pause rejects interactions")
 game.resume_game()
 await ticks(200)
 Input.action_release("crouch")
 check(game.stage==3 and not game.world.scan_active,"remaining concealed clears patrol and unlocks gate objective")
 check(game.world.gate_collision.collision_layer==1,"gate retains physical collision before authentication")
 game.player.reset_at(Vector3(0,.1,-18))
 Input.action_press("forward")
 await ticks(80)
 Input.action_release("forward")
 check(game.player.position.z > -19.5,"closed gate physically blocks passage")
 await approach("gate",Vector3(0,.15,1.7))
 check(game.try_interact() and game.stage==4 and game.world.gate_open,"gate authentication begins opening and advances delivery")
 await ticks(210)
 check(game.world.gate.position.y>4 and game.world.gate_collision.collision_layer==0,"raised gate clears physical passage")
 game.player.reset_at(Vector3(0,.1,-18))
 Input.action_press("forward")
 await ticks(150)
 Input.action_release("forward")
 check(game.player.position.z < -24,"courier walks through open gate")
 await approach("receiver",Vector3(0,.15,1.7))
 check(game.try_interact() and game.stage==5 and game.mode==3,"archive transmission reaches the cinematic ending")
 check(not game.player.enabled and game.film_camera.current,"ending disables controls and selects cinematic camera")
 await ticks(440)
 check(game.mode==4 and game.ui.ending.visible,"ending completes with replay/title choices")
 game.start_game()
 check(game.stage==0 and game.mode==1 and not game.world.gate_open and not game.world.scan_active,"replay resets route and encounter")
 game.quit_or_title()
 check(game.mode==0 and not game.player.enabled and game.ui.menu.visible,"return to title restores menu")
 print("PLAYTHROUGH_CHECKS ",checks," | FAILURES ",failures)
 paused = false
 game.queue_free()
 for i in 4:await process_frame
 # Dummy audio mixes on a real-time thread even during unthrottled fixed-fps tests.
 # Allow one buffer cycle to release stopped WAV playbacks before engine teardown.
 OS.delay_msec(100)
 quit(1 if failures else 0)
