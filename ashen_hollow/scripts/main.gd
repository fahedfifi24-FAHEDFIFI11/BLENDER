extends Node3D
## Owns the short quest and scene lifecycle. Combat lives in reusable actors.

enum Mode { TITLE, PLAYING, PAUSED, DEAD, VICTORY }
enum Quest { ARRIVAL, BANDITS, SHRINE, WARDEN, COMPLETE }

var mode: int = Mode.TITLE
var quest_stage: int = Quest.ARRIVAL
var bandits_defeated: int = 0
var player: CharacterBody3D
var world: Node3D
var enemies: Node3D
var ui: CanvasLayer
var warden: CharacterBody3D
var title_camera: Camera3D
var effects: Node3D
var _elapsed: float = 0.0
var _region: String = ""
var _run_id: int = 0
var _last_lock: Node3D
var _is_test: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game")
	_is_test = "--smoke-test" in OS.get_cmdline_user_args()
	world = load("res://scripts/world/world.gd").new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	player = load("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(0, 0.2, 23)
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.set_input_enabled(false)
	enemies = Node3D.new()
	enemies.name = "Enemies"
	enemies.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(enemies)
	_spawn_enemy("bandit", "Roadside Deserter", Vector3(-4, 0.2, 4))
	_spawn_enemy("bandit", "Hollow Brigand", Vector3(4, 0.2, -3))
	_spawn_enemy("bandit", "Bellkeeper's Outcast", Vector3(-1, 0.2, -9))
	warden = _spawn_enemy("creature", "THE HOLLOW WARDEN", Vector3(0, 0.2, -35))
	warden.set_active(false)
	effects = load("res://scripts/effects.gd").new()
	effects.name = "AtmosphereAndFeedback"
	effects.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(effects)
	ui = load("res://scripts/ui/game_ui.gd").new()
	ui.name = "Interface"
	add_child(ui)
	ui.start_requested.connect(start_game)
	ui.resume_requested.connect(resume_game)
	ui.restart_requested.connect(start_game)
	ui.quit_requested.connect(_quit_or_title)
	player.health_changed.connect(_on_health_changed)
	player.stamina_changed.connect(_on_stamina_changed)
	player.died.connect(_on_player_died)
	player.combat_event.connect(_on_combat_event)
	title_camera = Camera3D.new()
	title_camera.name = "TitleCamera"
	title_camera.position = Vector3(3.8, 3.7, 16)
	title_camera.fov = 58
	title_camera.far = 130
	add_child(title_camera)
	title_camera.look_at(Vector3(-0.7, 2.3, -8), Vector3.UP)
	title_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_main_menu()
	if "--capture-title" in OS.get_cmdline_user_args():
		_capture_after_frames("title.png")
	if "--capture-game" in OS.get_cmdline_user_args():
		start_game()
		player.reset_at(Vector3(0, 0.1, 9))
		_capture_after_frames("gameplay.png")

func _spawn_enemy(kind: String, label: String, at: Vector3) -> CharacterBody3D:
	var enemy: CharacterBody3D = load("res://scenes/enemy.tscn").instantiate()
	enemy.enemy_kind = kind
	enemy.display_name = label
	enemy.position = at
	enemy.name = label.to_pascal_case()
	enemies.add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.combat_event.connect(_on_combat_event)
	return enemy

func start_game() -> void:
	_run_id += 1
	get_tree().paused = false
	mode = Mode.PLAYING
	quest_stage = Quest.ARRIVAL
	bandits_defeated = 0
	_region = ""
	world.set_shrine_awakened(false)
	for enemy in enemies.get_children():
		enemy.reset_enemy()
		enemy.set_active(enemy != warden)
	player.reset_at(Vector3(0, 0.2, 23))
	player.set_input_enabled(true)
	player.camera_rig.get_camera().make_current()
	ui.show_hud()
	ui.set_stats(player.health, player.max_health, player.stamina, player.max_stamina)
	_refresh_objective()
	ui.show_message("No bells. No voices. Only the road into Ashen Hollow.", 5.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	_elapsed += delta
	if mode == Mode.TITLE and is_instance_valid(title_camera):
		title_camera.position.x = 3.8 + sin(_elapsed * 0.075) * 0.35
		title_camera.look_at(Vector3(-0.7, 2.3, -8), Vector3.UP)
	if mode != Mode.PLAYING or not is_instance_valid(player):
		return
	ui.set_stats(player.health, player.max_health, player.stamina, player.max_stamina)
	if player.global_position.y < -15:
		player.receive_hit(9999.0, player.global_position + Vector3.FORWARD, 0.0)
	var current_region: String = world.get_region_name(player.global_position)
	if current_region != _region:
		_region = current_region
		ui.set_region(_region)
	if quest_stage == Quest.ARRIVAL and player.global_position.z < 11.5:
		quest_stage = Quest.BANDITS
		_refresh_objective()
		ui.show_message("Deserters watch the empty streets. Clear a path to the old shrine.", 5)
	var interaction: String = ""
	if quest_stage == Quest.SHRINE:
		var shrine: Vector3 = world.get_interaction_position()
		if player.global_position.distance_to(shrine + Vector3.UP * 0.3) < 3.7:
			interaction = "E  ·  Read the broken oath"
	ui.set_interaction(interaction)
	var target: Node3D = player.get_lock_target()
	if is_instance_valid(target) and not target.dead:
		ui.set_lock_target(target.display_name, target.health, target.max_health)
	else:
		ui.set_lock_target("", 0, 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if mode == Mode.PLAYING:
			pause_game()
		elif mode == Mode.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") and mode == Mode.PLAYING:
		try_interact()

func try_interact() -> bool:
	if mode != Mode.PLAYING or quest_stage != Quest.SHRINE:
		return false
	if player.global_position.distance_to(world.get_interaction_position() + Vector3.UP * 0.3) >= 3.7:
		return false
	quest_stage = Quest.WARDEN
	world.set_shrine_awakened(true)
	warden.set_active(true)
	_refresh_objective()
	ui.show_message('"We bound the hunger beneath our stones. Forgive us when it wakes."', 6)
	effects.play_event("bell", world.get_interaction_position())
	# The inscription grants a modest breath before the final fight.
	player.health = minf(player.max_health, player.health + 35.0)
	player.stamina = player.max_stamina
	return true

func _on_enemy_defeated(enemy: Node) -> void:
	if mode != Mode.PLAYING:
		return
	if enemy == warden:
		quest_stage = Quest.COMPLETE
		_refresh_objective()
		ui.show_message("The hollow falls silent. A single ember remains.", 5)
		effects.play_event("victory", enemy.global_position)
		var run: int = _run_id
		await get_tree().create_timer(3.0, false).timeout
		if run == _run_id and mode == Mode.PLAYING and not player.dead:
			mode = Mode.VICTORY
			player.set_input_enabled(false)
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			ui.show_victory()
	else:
		bandits_defeated += 1
		if bandits_defeated >= 3:
			quest_stage = Quest.SHRINE
			ui.show_message("The road is yours. Beyond the village, blue fire marks an old oath.", 5)
		_refresh_objective()

func _refresh_objective() -> void:
	match quest_stage:
		Quest.ARRIVAL:
			ui.set_objective("I · THE SILENT ROAD", "Follow the forest path into the abandoned village.", 0.0)
		Quest.BANDITS:
			ui.set_objective("II · EMPTY HEARTHS", "Defeat the village deserters  ·  %d / 3" % bandits_defeated, float(bandits_defeated) / 3.0)
		Quest.SHRINE:
			ui.set_objective("III · A BROKEN OATH", "Follow the path north. Investigate the blue-lit shrine.", 0.0)
		Quest.WARDEN:
			ui.set_objective("IV · THE HOLLOW WARDEN", "Enter the ruined circle beyond the shrine. Defeat its guardian.", 0.0)
		Quest.COMPLETE:
			ui.set_objective("V · AN EMBER REMAINS", "The curse is broken. Ashen Hollow remembers the dawn.", 1.0)

func pause_game() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.PAUSED
	player.set_input_enabled(false)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_pause(true)

func resume_game() -> void:
	if mode != Mode.PAUSED and mode != Mode.VICTORY:
		return
	get_tree().paused = false
	mode = Mode.PLAYING
	player.set_input_enabled(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui.show_hud()
	_refresh_objective()

func _quit_or_title() -> void:
	if mode == Mode.TITLE:
		get_tree().quit()
		return
	_run_id += 1
	get_tree().paused = false
	mode = Mode.TITLE
	player.set_input_enabled(false)
	title_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui.show_main_menu()

func _on_player_died() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.DEAD
	player.set_input_enabled(false)
	var run: int = _run_id
	await get_tree().create_timer(1.5).timeout
	if run == _run_id and mode == Mode.DEAD:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ui.show_death()

func _on_health_changed(_current: float, _maximum: float) -> void:
	if is_instance_valid(ui):
		ui.set_stats(player.health, player.max_health, player.stamina, player.max_stamina)

func _on_stamina_changed(_current: float, _maximum: float) -> void:
	if is_instance_valid(ui):
		ui.set_stats(player.health, player.max_health, player.stamina, player.max_stamina)

func _on_combat_event(kind: String, at: Vector3) -> void:
	if not is_instance_valid(effects):
		return
	effects.play_event(kind, at)
	if not is_instance_valid(ui):
		return
	if kind in ["hurt", "player_hurt", "damage"]:
		ui.set_damage_flash()
	elif kind in ["hit", "heavy_hit", "enemy_hurt"]:
		ui.set_hit_confirm()

func _capture_after_frames(filename: String) -> void:
	for frame in range(16):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://test-results")
	image.save_png("res://test-results/" + filename)
	print("CAPTURE_SAVED ", filename)
	get_tree().quit()
