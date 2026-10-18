extends SceneTree
## godot --headless --path . --fixed-fps 60 --script res://tests/player_checks.gd

class DummyEnemy extends CharacterBody3D:
	var health: float = 500.0
	var max_health: float = 500.0
	var dead: bool = false
	var active: bool = true
	var hits: int = 0
	func receive_hit(amount: float, _source: Vector3, _force: float = 3.0) -> bool:
		health -= amount
		hits += 1
		return true

var failures: int = 0
var checks: int = 0
var player: CharacterBody3D
var enemy: DummyEnemy
var world: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	print(("PASS " if condition else "FAIL ") + message)
	if not condition:
		failures += 1

func settle(seconds: float) -> void:
	await create_timer(seconds).timeout
	await physics_frame

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_collider := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(30, 1, 30)
	floor_collider.shape = floor_shape
	floor_body.add_child(floor_collider)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3(0, 0.2, 0)
	player.set_input_enabled(true)
	enemy = DummyEnemy.new()
	enemy.collision_layer = 4
	enemy.collision_mask = 0
	var enemy_collider := CollisionShape3D.new()
	var enemy_shape := CapsuleShape3D.new()
	enemy_shape.radius = 0.4
	enemy_shape.height = 1.8
	enemy_collider.shape = enemy_shape
	enemy_collider.position.y = 0.9
	enemy.add_child(enemy_collider)
	world.add_child(enemy)
	enemy.add_to_group("enemies")
	enemy.global_position = Vector3(0, 0, -1.7)
	await settle(0.3)
	check(player.is_on_floor(), "player grounds on world collider")
	check(is_instance_valid(player.camera_rig.get_camera()), "orbit camera present")
	check(player.attack_light(), "light attack accepted")
	check(player.attack_light(), "second light queued")
	await settle(0.46)
	check(player.attack_state == "light_2", "buffer advances into second combo strike")
	player.attack_light()
	await settle(0.48)
	check(player.attack_state == "light_3", "third combo strike begins")
	await settle(0.8)
	check(enemy.hits == 3, "three-hit combo damages once per strike")
	check(is_equal_approx(enemy.health, 418.0), "combo damage totals 82")
	check(player.attack_state.is_empty(), "combo returns to locomotion")
	player.reset_at(Vector3(0, 0.05, 0))
	await settle(0.1)
	var before_heavy: float = enemy.health
	check(player.attack_heavy(), "heavy attack accepted")
	await settle(0.8)
	check(is_equal_approx(before_heavy - enemy.health, 49.0), "heavy damage 49")
	await settle(0.4)
	player.reset_at(Vector3(0, 0.05, 0))
	await settle(0.85)
	check(player.start_dodge(), "dodge accepted on floor")
	await settle(0.1)
	var before_dodge: float = player.health
	check(not player.receive_hit(20, Vector3(0, 0, -2)), "dodge i-frame rejects damage")
	check(player.health == before_dodge, "dodge preserves health")
	await settle(0.55)
	player.blocking = true
	var stamina_before: float = player.stamina
	check(not player.receive_hit(20, player.global_position + Vector3.FORWARD * 2.0), "front block rejects health damage")
	check(player.stamina < stamina_before, "block spends stamina")
	player.blocking = true
	check(player.receive_hit(20, player.global_position + Vector3.BACK * 2.0), "rear hit bypasses facing block")
	check(player.health == 100.0, "unblocked damage updates health")
	player.reset_at(Vector3(0, 0.05, 0))
	await settle(0.9)
	var wall := StaticBody3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(3, 3, 0.2)
	var wall_col := CollisionShape3D.new()
	wall_col.shape = wall_shape
	wall.add_child(wall_col)
	wall.position = Vector3(0, 1.5, -0.9)
	world.add_child(wall)
	await settle(0.1)
	var wall_before: float = enemy.health
	player.attack_light()
	await settle(0.65)
	check(enemy.health == wall_before, "world occlusion prevents sword damage through walls")
	wall.queue_free()
	await settle(0.1)
	player.cycle_lock_target()
	check(player.get_lock_target() == enemy, "lock-on picks eligible enemy")
	enemy.dead = true
	await settle(0.05)
	check(player.get_lock_target() == null, "dead target released")
	player._invulnerability_remaining = 0.0
	player.invulnerable = false
	check(player.receive_hit(999, Vector3(0, 0, -3)), "fatal hit lands")
	check(player.dead and player.health == 0.0, "death state")
	check(not player.attack_light(), "dead character cannot attack")
	player.reset_at(Vector3(2, 0.2, 3))
	check(not player.dead and player.health == 120 and player.stamina == 100, "reset restores complete vitals")
	check(player.global_position.is_equal_approx(Vector3(2, 0.2, 3)), "reset moves to spawn")
	await settle(0.3)
	var move_start: Vector3 = player.global_position
	Input.action_press("move_forward")
	await settle(0.6)
	check(player.global_position.z < move_start.z - 1.5, "WASD moves in camera forward direction")
	var walk_velocity: float = absf(player.velocity.z)
	Input.action_press("sprint")
	await settle(0.4)
	check(absf(player.velocity.z) > walk_velocity + 1.0, "sprint increases movement speed")
	check(player.stamina < player.max_stamina, "sprint consumes stamina")
	Input.action_release("sprint")
	Input.action_release("move_forward")
	await settle(0.35)
	check(Vector2(player.velocity.x, player.velocity.z).length() < 0.1, "release smoothly decelerates")
	Input.action_press("jump")
	await settle(0.13)
	Input.action_release("jump")
	check(player.global_position.y > 0.3, "jump leaves ground")
	await settle(0.8)
	check(player.is_on_floor(), "jump lands on world")
	player._set_stamina(5.0)
	player._invulnerability_remaining = 0.0
	player.invulnerable = false
	player.blocking = true
	check(player.receive_hit(24, player.global_position + Vector3.FORWARD * 2), "insufficient stamina causes guard break damage")
	check(player.stamina == 0.0 and player._stagger_remaining > 0.6 and not player.blocking, "guard break empties stamina and staggers")
	player.reset_at(Vector3.ZERO)
	await settle(0.9)
	Input.action_press("block")
	await settle(0.1)
	check(player.blocking, "block input enters guard on ground")
	Input.action_release("block")
	await settle(0.1)
	check(not player.blocking, "block input release exits guard")
	player.set_input_enabled(false)
	check(not player.attack_light() and not player.attack_heavy(), "menu input gate prevents attacks")
	print("PLAYER_CHECKS ", checks, " | FAILURES ", failures)
	quit(failures)
