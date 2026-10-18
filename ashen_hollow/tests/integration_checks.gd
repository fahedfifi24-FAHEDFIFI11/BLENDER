extends SceneTree
## Run after editor import:
## godot --headless --path . --fixed-fps 60 --script res://tests/integration_checks.gd
## Loads the actual main scene and exercises scene lifecycle and quest gates.
## A real sword swing is checked. Quest traversal teleports and direct enemy
## damage are deliberate state-integration fixtures, not a full player playthrough.

var failures: int = 0
var checks: int = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS ", message)
	else:
		push_error("FAIL " + message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for frame: int in count:
		await physics_frame

func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	check(scene != null, "main scene resolves")
	if scene == null:
		quit(1)
		return
	var game: Node3D = scene.instantiate() as Node3D
	root.add_child(game)
	await ticks(2)
	var player: CharacterBody3D = game.get("player") as CharacterBody3D
	var world: Node3D = game.get("world") as Node3D
	var enemies: Node3D = game.get("enemies") as Node3D
	var ui: CanvasLayer = game.get("ui") as CanvasLayer
	var warden: CharacterBody3D = game.get("warden") as CharacterBody3D
	check(player != null and world != null and enemies != null and ui != null and warden != null, "actual main scene constructs player, world, enemies, UI and boss")
	if player == null or world == null or enemies == null or ui == null or warden == null:
		game.queue_free()
		await process_frame
		quit(1)
		return
	check(enemies.get_child_count() == 4, "main scene contains three bandits and the warden")
	check(int(game.get("mode")) == 0 and not bool(player.get("input_enabled")), "title mode disables player gameplay")
	check((ui.get("_main") as Control).visible and not (ui.get("_hud") as Control).visible, "main menu visible with HUD hidden")
	check(not bool(warden.get("active")), "warden initially dormant")
	var first_bandit: CharacterBody3D = enemies.get_child(0) as CharacterBody3D
	var title_position: Vector2 = Vector2(first_bandit.position.x, first_bandit.position.z)
	await ticks(20)
	check(Vector2(first_bandit.position.x, first_bandit.position.z).distance_to(title_position) < 0.001, "enemy patrol and combat remain frozen at title")
	var required_actions: Array[String] = ["move_left", "move_right", "move_forward", "move_back", "sprint", "jump", "dodge", "light_attack", "heavy_attack", "block", "lock_on", "interact", "pause"]
	var actions_complete: bool = true
	for action: String in required_actions:
		actions_complete = actions_complete and InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty()
	check(actions_complete, "all keyboard and mouse gameplay actions have bindings")
	(ui.get("_main_button") as Button).pressed.emit()
	await ticks(45)
	check(int(game.get("mode")) == 1 and bool(player.get("input_enabled")) and not paused, "Begin Journey button enters active unpaused gameplay")
	check(int(game.get("quest_stage")) == 0 and int(game.get("bandits_defeated")) == 0, "journey begins with arrival objective")
	check(player.is_on_floor() and absf(player.position.y) < 0.1, "actual world collision supports player at spawn")
	check((ui.get("_hud") as Control).visible and not (ui.get("_main") as Control).visible, "start_game switches from menu to HUD")
	var route_supported: bool = true
	for z: float in [23.0, 13.0, 5.0, -6.0, -16.0, -25.0, -35.0, -43.0]:
		var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(0, 3, z), Vector3(0, -2, z), 1)
		route_supported = route_supported and not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
	check(route_supported, "world collision floor covers forest, village, ruins and arena")
	check(not bool(game.call("try_interact")), "shrine cannot activate before village objective")
	check(not bool(warden.call("receive_hit", 9999.0, player.position, 0.0)) and float(warden.get("health")) == float(warden.get("max_health")), "dormant boss cannot be killed to skip quest")
	player.call("reset_at", Vector3(0, 0.2, 10))
	await ticks(2)
	check(int(game.get("quest_stage")) == 1, "entering village advances arrival to bandit objective")
	# Exercise the real player and real enemy physics together in a clear street.
	for enemy: Node in enemies.get_children():
		if enemy != first_bandit:
			enemy.call("set_active", false)
	first_bandit.position = Vector3(0, 0.1, 4.0)
	first_bandit.set("patrol_radius", 0.0)
	first_bandit.rotation.y = PI
	player.call("reset_at", Vector3(0, 0.1, 5.55))
	await ticks(3)
	check(bool(player.call("attack_light")), "real player starts light attack in live world")
	await ticks(25)
	check(is_equal_approx(float(first_bandit.get("health")), 48.0), "real player sword collision damages real bandit exactly once")
	check(float(player.get("stamina")) < float(player.get("max_stamina")), "real sword attack spends stamina")
	# Run the reciprocal shape query against the actual player's defense logic.
	first_bandit.call("reset_enemy")
	first_bandit.position = Vector3(0, 0.1, 4.0)
	first_bandit.rotation.y = PI
	first_bandit.call("set_active", false)
	player.call("reset_at", Vector3(0, 0.1, 5.45))
	await ticks(55)
	first_bandit.call("set_active", true)
	first_bandit.call("_begin_attack", 1.45)
	await ticks(60)
	check(is_equal_approx(float(player.get("health")), 101.0) and bool(first_bandit.get("_struck_player")), "real bandit active window damages real player exactly once")
	first_bandit.call("reset_enemy")
	first_bandit.position = Vector3(0, 0.1, 4.0)
	first_bandit.rotation.y = PI
	first_bandit.call("set_active", false)
	player.call("reset_at", Vector3(0, 0.1, 5.45))
	await ticks(55)
	Input.action_press("block")
	await ticks(2)
	first_bandit.call("set_active", true)
	first_bandit.call("_begin_attack", 1.45)
	await ticks(60)
	check(is_equal_approx(float(player.get("health")), 120.0) and bool(first_bandit.get("_struck_player")) and float(player.get("stamina")) < 90.0, "real bandit collision is blocked and spends player stamina")
	Input.action_release("block")
	first_bandit.call("reset_enemy")
	first_bandit.position = Vector3(0, 0.1, 4.0)
	first_bandit.rotation.y = PI
	first_bandit.call("set_active", false)
	player.call("reset_at", Vector3(0, 0.1, 5.45))
	await ticks(55)
	first_bandit.call("set_active", true)
	first_bandit.call("_begin_attack", 1.45)
	await ticks(35)
	check(bool(player.call("start_dodge")), "real player can time a dodge during enemy windup")
	await ticks(22)
	check(is_equal_approx(float(player.get("health")), 120.0) and bool(first_bandit.get("_struck_player")), "real enemy overlap is consumed by dodge invulnerability")
	# Restart removes all combat fixture modifications that belong to gameplay state.
	game.call("start_game")
	await ticks(3)
	check(float(first_bandit.get("health")) == 70.0 and first_bandit.position.distance_to(Vector3(-4, 0.2, 4)) < 0.4, "restart restores enemy health and original spawn")
	player.call("reset_at", Vector3(0, 0.2, 10))
	await ticks(2)
	for index: int in range(3):
		var bandit: Node3D = enemies.get_child(index) as Node3D
		bandit.call("receive_hit", 1000.0, player.position, 0.0)
	check(int(game.get("bandits_defeated")) == 3 and int(game.get("quest_stage")) == 2, "three enemy defeat signals unlock shrine objective")
	first_bandit.call("receive_hit", 1000.0, player.position, 0.0)
	check(int(game.get("bandits_defeated")) == 3, "repeated damage to defeated bandit cannot inflate quest progress")
	check(not bool(warden.get("active")) and not bool(game.call("try_interact")), "shrine interaction requires physical proximity")
	player.call("reset_at", (world.call("get_interaction_position") as Vector3) + Vector3(0, 0.2, 2.5))
	player.set("health", 60.0)
	player.set("stamina", 40.0)
	await ticks(2)
	check((ui.get("_interaction") as Control).visible, "shrine proximity displays interaction prompt")
	check(bool(game.call("try_interact")), "nearby shrine interaction succeeds")
	check(int(game.get("quest_stage")) == 3 and bool(warden.get("active")), "inscription wakes warden and advances objective")
	check(float(player.get("health")) == 95.0 and float(player.get("stamina")) == float(player.get("max_stamina")), "shrine grants documented recovery")
	check(not bool(game.call("try_interact")), "shrine reward cannot be repeatedly claimed")
	# Pause must freeze actor state, timers, stamina regeneration and world motion.
	player.set("stamina", 42.0)
	warden.call("_begin_attack", 3.0)
	game.call("pause_game")
	var enemy_timer: float = float(warden.get("_timer"))
	var paused_position: Vector3 = player.position
	await ticks(30)
	check(paused and int(game.get("mode")) == 2 and not bool(player.get("input_enabled")) and (ui.get("_modal") as Control).visible, "pause shows menu, freezes scene and disables player input")
	check(player.position.distance_to(paused_position) < 0.001 and float(player.get("stamina")) == 42.0 and is_equal_approx(float(warden.get("_timer")), enemy_timer), "paused physics and regeneration do not advance")
	check(not bool(game.call("try_interact")), "interaction is gated during pause")
	ui.emit_signal("resume_requested")
	check(not paused and int(game.get("mode")) == 1 and bool(player.get("input_enabled")), "resume restores gameplay")
	warden.call("receive_hit", 1000.0, player.position, 0.0)
	check(int(game.get("quest_stage")) == 4 and bool(warden.get("dead")), "warden defeat completes quest")
	game.call("pause_game")
	await ticks(200)
	check(int(game.get("mode")) == 2 and paused, "pause remains stable during pending victory presentation")
	game.call("resume_game")
	await ticks(190)
	check(int(game.get("mode")) == 4 and paused and not bool(player.get("input_enabled")), "quest completion presents victory even after pausing during its delay")
	check((ui.get("_modal") as Control).visible, "victory overlay is visible")
	game.call("resume_game")
	check(int(game.get("mode")) == 1 and not paused and int(game.get("quest_stage")) == 4, "victory Explore resumes completed world")
	# A new run must invalidate a delayed victory callback from the previous run.
	game.call("start_game")
	player.call("reset_at", Vector3(0, 0.2, 10))
	await ticks(2)
	for index: int in range(3):
		(enemies.get_child(index) as Node3D).call("receive_hit", 1000.0, player.position, 0.0)
	player.call("reset_at", (world.call("get_interaction_position") as Vector3) + Vector3(0, 0.2, 2.5))
	game.call("try_interact")
	warden.call("receive_hit", 1000.0, player.position, 0.0)
	game.call("start_game")
	await ticks(200)
	check(int(game.get("mode")) == 1 and int(game.get("quest_stage")) == 0 and not paused and not (ui.get("_modal") as Control).visible, "victory callback from a previous run cannot interrupt immediate restart")
	game.call("start_game")
	check(int(game.get("quest_stage")) == 0 and int(game.get("bandits_defeated")) == 0 and not paused, "restart clears quest and pause state")
	check(float(player.get("health")) == float(player.get("max_health")) and float(player.get("stamina")) == float(player.get("max_stamina")) and not bool(player.get("dead")), "restart fully restores player health, stamina and life")
	var enemies_reset: bool = true
	for enemy: Node in enemies.get_children():
		enemies_reset = enemies_reset and not bool(enemy.get("dead")) and float(enemy.get("health")) == float(enemy.get("max_health")) and int(enemy.get("collision_layer")) == 4
	check(enemies_reset and not bool(warden.get("active")), "restart restores all enemies and makes boss dormant")
	await ticks(55)
	check(bool(player.call("receive_hit", 1000.0, player.position + Vector3.FORWARD, 0.0)), "player can receive lethal damage after spawn immunity")
	check(int(game.get("mode")) == 3 and bool(player.get("dead")) and not bool(player.get("input_enabled")), "player death enters death state")
	await ticks(100)
	check(paused and (ui.get("_modal") as Control).visible, "death delay presents retry overlay")
	game.call("start_game")
	check(not paused and not bool(player.get("dead")) and int(game.get("quest_stage")) == 0, "retry starts a clean playable run")
	await ticks(55)
	player.call("receive_hit", 1000.0, player.position + Vector3.FORWARD, 0.0)
	game.call("start_game")
	await ticks(100)
	check(int(game.get("mode")) == 1 and not paused and not (ui.get("_modal") as Control).visible, "death callback from a previous run cannot interrupt immediate restart")
	game.call("_quit_or_title")
	check(int(game.get("mode")) == 0 and not bool(player.get("input_enabled")) and not paused and (ui.get("_main") as Control).visible, "quit to title returns to menu without closing scene")
	print("INTEGRATION_CHECKS ", checks, " | FAILURES ", failures)
	paused = false
	game.queue_free()
	# Let queued scene deletion and the audio/render server detachments complete
	# before requesting process exit. This does not advance any live game actors.
	for frame: int in range(3):
		await process_frame
	quit(1 if failures > 0 else 0)
