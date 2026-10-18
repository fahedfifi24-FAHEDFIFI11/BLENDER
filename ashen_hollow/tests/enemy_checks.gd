extends SceneTree
## Run after editor import:
## godot --headless --path . --fixed-fps 60 --script res://tests/enemy_checks.gd
## An isolated physics fixture tests enemy behavior against a controlled target.

class TrainingTarget extends CharacterBody3D:
	var input_enabled: bool = true
	var dead: bool = false
	var received_count: int = 0
	var health: float = 10000.0
	var immune: bool = false
	func receive_hit(amount: float, _source: Vector3, _force: float = 3.0) -> bool:
		received_count += 1
		if immune:
			return false
		health -= amount
		return true

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
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	var floor_body: StaticBody3D = StaticBody3D.new()
	var floor_shape: CollisionShape3D = CollisionShape3D.new()
	var floor_box: BoxShape3D = BoxShape3D.new()
	floor_box.size = Vector3(60, 1, 60)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	stage.add_child(floor_body)
	var player: TrainingTarget = TrainingTarget.new()
	player.collision_layer = 2
	player.collision_mask = 1
	player.add_to_group("player")
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.height = 1.75
	capsule.radius = 0.35
	var player_shape: CollisionShape3D = CollisionShape3D.new()
	player_shape.shape = capsule
	player_shape.position.y = 0.875
	player.add_child(player_shape)
	stage.add_child(player)
	var scene: PackedScene = load("res://scenes/enemy.tscn") as PackedScene
	check(scene != null, "enemy scene resolves")
	if scene == null:
		quit(1)
		return
	var enemy: CharacterBody3D = scene.instantiate() as CharacterBody3D
	enemy.position = Vector3(0, 0, -1.45)
	enemy.rotation.y = PI
	enemy.set("patrol_radius", 0.0)
	stage.add_child(enemy)
	await physics_frame
	check(enemy.get("health") == 70.0, "bandit initialized with 70 HP")
	check(not enemy.get_node("HealthIndicator").visible, "health indicator initially hidden")
	enemy.call("_begin_attack", 1.45)
	await ticks(60)
	check(player.received_count == 1, "bandit physics strike hits exactly once")
	enemy.call("_check_attack_hit")
	enemy.call("_check_attack_hit")
	check(player.received_count == 1, "repeat overlap cannot multi-hit a swing")
	check(enemy.get("state") == "recover", "bandit enters recovery")
	check(enemy.call("receive_hit", 22.0, player.position, 3.0), "bandit accepts player damage")
	check(enemy.get("health") == 48.0 and enemy.get("state") == "stagger", "damage interrupts bandit attack into stagger")
	enemy.call("receive_hit", 100.0, player.position, 3.0)
	check(enemy.get("dead") and enemy.collision_layer == 0 and not enemy.is_in_group("enemies"), "death disables collision and targeting")
	check(not enemy.call("receive_hit", 20.0, player.position, 3.0), "dead enemy rejects repeated hits")
	enemy.call("reset_enemy")
	check(not enemy.get("dead") and enemy.get("health") == 70.0 and enemy.collision_layer == 4 and enemy.is_in_group("enemies"), "reset restores health, collision and targeting")
	check(enemy.position.distance_to(Vector3(0, 0, -1.45)) < 0.001, "reset restores spawn position")
	enemy.call("set_active", false)
	check(not enemy.call("receive_hit", 20.0, player.position, 3.0) and enemy.get("health") == 70.0, "dormant enemy rejects damage")
	var wall: StaticBody3D = StaticBody3D.new()
	var wall_collider: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(4, 3, 0.3)
	wall_collider.shape = wall_box
	wall.add_child(wall_collider)
	wall.position = Vector3(0, 1.5, -0.7)
	stage.add_child(wall)
	await ticks(2)
	check(not enemy.call("_has_line_of_sight", player.position), "wall blocks line of sight")
	enemy.call("_begin_attack", 1.45)
	enemy.call("_check_attack_hit")
	check(player.received_count == 1, "overlapping strike cannot damage through a wall")
	wall.queue_free()
	await ticks(2)
	enemy.call("set_active", true)
	enemy.call("_begin_attack", 1.45)
	player.input_enabled = false
	var frozen_timer: float = float(enemy.get("_timer"))
	await ticks(30)
	check(is_equal_approx(float(enemy.get("_timer")), frozen_timer), "enemy attack timer freezes while player input is disabled")
	player.input_enabled = true
	player.immune = true
	enemy.call("_begin_attack", 1.45)
	enemy.call("_check_attack_hit")
	var calls_after_immune_hit: int = player.received_count
	player.immune = false
	enemy.call("_check_attack_hit")
	check(player.received_count == calls_after_immune_hit and player.health == 9981.0, "dodge-rejected swing stays consumed when immunity ends")
	enemy.queue_free()
	await ticks(2)
	var creature: CharacterBody3D = scene.instantiate() as CharacterBody3D
	creature.set("enemy_kind", "creature")
	creature.set("active", false)
	creature.position = Vector3(0, 0, -3)
	stage.add_child(creature)
	await physics_frame
	check(creature.get("max_health") == 240.0, "creature has boss health")
	creature.call("set_active", true)
	creature.call("_begin_attack", 3.0)
	check(creature.get("attack_kind") == "lunge", "creature ranged opener is lunge")
	creature.call("_begin_attack", 1.5)
	check(creature.get("attack_kind") == "sweep", "creature alternates close sweep")
	creature.call("receive_hit", 20.0, player.position, 3.0)
	check(creature.get("state") == "windup", "creature poise resists single light interruption")
	creature.call("receive_hit", 36.0, player.position, 6.0)
	check(creature.get("state") == "stagger", "heavy hit breaks creature poise")
	print("ENEMY_CHECKS ", checks, " | FAILURES ", failures)
	stage.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
