extends CharacterBody3D
## Reusable combatant. All hit decisions use physics shapes and the player's
## receive_hit contract, so guard direction and dodge immunity stay authoritative.

signal defeated(enemy: Node)
signal health_changed(current: float, maximum: float)
signal combat_event(kind: String, position: Vector3)

@export_enum("bandit", "creature") var enemy_kind: String = "bandit"
@export var display_name: String = ""
@export var active: bool = true
@export var patrol_radius: float = 2.5

var max_health: float = 70.0
var health: float = 70.0
var dead: bool = false
var state: String = "patrol"
var attack_kind: String = "slash"

var _player: Node3D
var _visual: Node3D
var _home: Vector3
var _home_rotation: Vector3
var _spawned: bool = false
var _timer: float = 0.0
var _duration: float = 1.0
var _age: float = 0.0
var _patrol_index: int = 0
var _attack_index: int = 0
var _struck_player: bool = false
var _engaged: bool = false
var _lost_sight: float = 0.0
var _poise: int = 0
var _poise_timer: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _attack_direction: Vector3 = Vector3.FORWARD
var _gravity: float = 9.8
var _health_display: Node3D
var _health_fill: MeshInstance3D
var _health_label: Label3D
var _telegraph: MeshInstance3D
var _telegraph_material: StandardMaterial3D
var _attack_box: BoxShape3D = BoxShape3D.new()
var _attack_sphere: SphereShape3D = SphereShape3D.new()


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_home = global_position
	_home_rotation = rotation
	_spawned = true
	max_health = 240.0 if enemy_kind == "creature" else 70.0
	health = max_health
	if display_name.is_empty():
		display_name = "The Hollow Warden" if enemy_kind == "creature" else "Hollow Marauder"
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.52 if enemy_kind == "creature" else 0.34
	capsule.height = 2.2 if enemy_kind == "creature" else 1.75
	$CollisionShape3D.shape = capsule
	$CollisionShape3D.position.y = capsule.height * 0.5
	_build_visual()
	_build_indicators()
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_change_state("patrol", 2.0)


func _physics_process(delta: float) -> void:
	_age += delta
	_update_indicators()
	if dead:
		_timer += delta
		velocity = Vector3.ZERO
		if _visual and _timer > 3.8:
			_visual.visible = false
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	var player_ready: bool = is_instance_valid(_player) and bool(_player.get("input_enabled")) and not bool(_player.get("dead"))
	if not active or not player_ready:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= _gravity * delta
		move_and_slide()
		_telegraph.visible = false
		_set_motion("idle", 0.0, 0.0)
		return
	_timer += delta
	_poise_timer = maxf(0.0, _poise_timer - delta)
	if _poise_timer <= 0.0:
		_poise = 0
	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	var distance: float = to_player.length()
	var direction: Vector3 = to_player.normalized() if distance > 0.01 else -global_basis.z
	var desired: Vector3 = Vector3.ZERO
	match state:
		"patrol", "idle":
			if distance < _detection_range() and _has_line_of_sight(_player.global_position):
				_engaged = true
				_change_state("chase")
				combat_event.emit("enemy_alert", global_position + Vector3.UP)
			else:
				desired = _patrol_movement(delta)
		"chase":
			_face(direction, 7.0, delta)
			if _has_line_of_sight(_player.global_position):
				_lost_sight = 0.0
			else:
				_lost_sight += delta
			if (distance > 22.0 or _lost_sight > 7.0) and global_position.distance_to(_home) > 1.0:
				_change_state("return")
			elif distance < _attack_start_range() and _has_line_of_sight(_player.global_position):
				_begin_attack(distance)
			else:
				desired = _steer(direction) * (4.0 if enemy_kind == "creature" else 2.65)
		"return":
			var home_delta: Vector3 = _home - global_position
			home_delta.y = 0.0
			if distance < _detection_range() * 0.65 and _has_line_of_sight(_player.global_position):
				_change_state("chase")
			elif home_delta.length() < 0.7:
				_engaged = false
				_change_state("patrol")
			else:
				desired = _steer(home_delta.normalized()) * 1.8
				_face(home_delta.normalized(), 5.0, delta)
		"windup":
			if _timer < _duration - 0.24:
				_face(direction, 5.5, delta)
				_attack_direction = -global_basis.z
			if _timer >= _duration:
				_change_state("active", _active_duration())
				combat_event.emit("enemy_attack", global_position + Vector3.UP)
		"active":
			if attack_kind == "lunge":
				desired = _attack_direction * 7.2
			elif attack_kind == "slash":
				desired = _attack_direction * 1.0
			_check_attack_hit()
			if _timer >= _duration:
				_change_state("recover", _recovery_duration())
		"recover":
			if _timer >= _duration:
				_change_state("chase")
		"stagger":
			if _timer >= _duration:
				_change_state("chase")
	velocity.x = move_toward(velocity.x, desired.x + _knockback.x, delta * 20.0)
	velocity.z = move_toward(velocity.z, desired.z + _knockback.z, delta * 20.0)
	_knockback = _knockback.move_toward(Vector3.ZERO, 12.0 * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.15
	move_and_slide()
	_update_motion()
	_update_telegraph()


func _patrol_movement(delta: float) -> Vector3:
	if patrol_radius <= 0.05:
		return Vector3.ZERO
	var angles: Array[float] = [0.0, 2.1, 4.2]
	var angle: float = angles[_patrol_index % 3] + _home.x * 0.15
	var target: Vector3 = _home + Vector3(cos(angle), 0.0, sin(angle)) * patrol_radius
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	if offset.length() < 0.4:
		if state != "idle":
			_change_state("idle", 1.6)
		if _timer > _duration:
			_patrol_index += 1
			_change_state("patrol")
		return Vector3.ZERO
	var direction: Vector3 = offset.normalized()
	_face(direction, 3.0, delta)
	return _steer(direction) * (0.95 if enemy_kind == "creature" else 1.05)


func _begin_attack(distance: float) -> void:
	_attack_index += 1
	_struck_player = false
	if enemy_kind == "creature":
		attack_kind = "lunge" if distance > 2.6 or _attack_index % 2 == 1 else "sweep"
	else:
		attack_kind = "slash"
	if _visual and _visual.has_method("set_attack_variant"):
		_visual.call("set_attack_variant", attack_kind)
	_attack_direction = -global_basis.z
	var windup: float = 0.68
	if attack_kind == "lunge":
		windup = 0.80
	elif attack_kind == "sweep":
		windup = 1.05
	_change_state("windup", windup)
	combat_event.emit("enemy_windup", global_position + Vector3.UP)


func _attack_start_range() -> float:
	return 4.2 if enemy_kind == "creature" else 1.8


func _detection_range() -> float:
	return 11.0 if enemy_kind == "creature" else 8.5


func _active_duration() -> float:
	if attack_kind == "lunge":
		return 0.42
	return 0.28 if attack_kind == "sweep" else 0.21


func _recovery_duration() -> float:
	return 1.05 if enemy_kind == "creature" else 0.83


func _check_attack_hit() -> void:
	if _struck_player or not is_instance_valid(_player):
		return
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var origin: Vector3 = global_position + Vector3.UP * 1.0
	if attack_kind == "sweep":
		_attack_sphere.radius = 2.35
		query.shape = _attack_sphere
		query.transform = Transform3D(Basis.IDENTITY, origin)
	else:
		_attack_box.size = Vector3(1.4, 1.8, 1.9) if attack_kind == "lunge" else Vector3(1.15, 1.5, 1.4)
		query.shape = _attack_box
		query.transform = Transform3D(global_basis.orthonormalized(), origin + _attack_direction * 0.95)
	var hits: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(query, 8)
	for hit: Dictionary in hits:
		var target: Object = hit.get("collider")
		if target != _player or not _has_line_of_sight(_player.global_position):
			continue
		if attack_kind == "sweep":
			var offset: Vector3 = _player.global_position - global_position
			offset.y = 0.0
			if offset.length() > 0.1 and offset.normalized().dot(_attack_direction) < -0.45:
				continue
		_struck_player = true
		var damage: float = 19.0
		var force: float = 3.5
		if attack_kind == "lunge":
			damage = 25.0
			force = 5.0
		elif attack_kind == "sweep":
			damage = 29.0
			force = 6.0
		if _player.has_method("receive_hit"):
			_player.call("receive_hit", damage, global_position, force)
		break


func receive_hit(amount: float, source_position: Vector3, knockback: float = 3.0) -> bool:
	if dead or not active or amount <= 0.0:
		return false
	health = maxf(0.0, health - amount)
	_engaged = true
	_lost_sight = 0.0
	health_changed.emit(health, max_health)
	var push: Vector3 = global_position - source_position
	push.y = 0.0
	if push.length_squared() < 0.001:
		push = global_basis.z
	_knockback = push.normalized() * knockback * (0.65 if enemy_kind == "creature" else 1.0)
	if _visual and _visual.has_method("flash_hit"):
		_visual.call("flash_hit")
	combat_event.emit("enemy_hurt", global_position + Vector3.UP * 1.1)
	if health <= 0.0:
		_die()
		return true
	_poise += 3 if knockback >= 5.0 else 1
	_poise_timer = 2.0
	if enemy_kind == "bandit" or _poise >= 3:
		_poise = 0
		_change_state("stagger", 0.58 if enemy_kind == "creature" else 0.48)
	elif state == "patrol" or state == "idle" or state == "return":
		_change_state("chase")
	return true


func _die() -> void:
	dead = true
	health = 0.0
	_change_state("dead")
	collision_layer = 0
	remove_from_group("enemies")
	_telegraph.visible = false
	_health_display.visible = false
	velocity = Vector3.ZERO
	if _visual:
		if _visual.has_method("set_dead"):
			_visual.call("set_dead", true)
		_set_motion("death", 0.0, 0.0)
	combat_event.emit("enemy_death", global_position + Vector3.UP)
	defeated.emit(self)


func reset_enemy() -> void:
	if not _spawned:
		return
	dead = false
	health = max_health
	global_position = _home
	rotation = _home_rotation
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	_poise = 0
	_poise_timer = 0.0
	_attack_index = 0
	_patrol_index = 0
	_lost_sight = 0.0
	_struck_player = false
	_engaged = false
	collision_layer = 4
	if not is_in_group("enemies"):
		add_to_group("enemies")
	if _visual:
		_visual.visible = true
		if _visual.has_method("set_dead"):
			_visual.call("set_dead", false)
	_change_state("patrol", 2.0)
	_telegraph.visible = false
	health_changed.emit(health, max_health)
	_update_indicators()


func set_active(value: bool) -> void:
	active = value
	if not value:
		velocity = Vector3.ZERO
		if is_instance_valid(_telegraph):
			_telegraph.visible = false


func _change_state(next_state: String, duration: float = 1.0) -> void:
	state = next_state
	_timer = 0.0
	_duration = maxf(duration, 0.01)


func _face(direction: Vector3, speed: float, delta: float) -> void:
	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(speed * delta, 1.0))


func _has_line_of_sight(target_position: Vector3) -> bool:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, target_position + Vector3.UP, 1)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _steer(direction: Vector3) -> Vector3:
	var origin: Vector3 = global_position + Vector3.UP * 0.65
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + direction * 1.2, 1)
	query.exclude = [get_rid()]
	if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return direction
	for angle: float in [0.85, -0.85, 1.45, -1.45]:
		var candidate: Vector3 = direction.rotated(Vector3.UP, angle)
		query.to = origin + candidate * 1.3
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return candidate
	return Vector3.ZERO


func _update_motion() -> void:
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var motion: String = "idle"
	var phase: float = clampf(_timer / _duration, 0.0, 1.0)
	match state:
		"chase": motion = "run"
		"patrol", "return": motion = "walk" if speed > 0.1 else "idle"
		"windup": motion = "windup"
		"active": motion = "attack"
		"recover": motion = "recover"
		"stagger": motion = "stagger"
	_set_motion(motion, speed, phase)


func _set_motion(motion: String, speed: float, phase: float) -> void:
	if _visual and _visual.has_method("set_motion"):
		_visual.call("set_motion", motion, speed, phase)


func _build_visual() -> void:
	if ResourceLoader.exists("res://scripts/art/actor_visual.gd"):
		var visual_script: Script = load("res://scripts/art/actor_visual.gd") as Script
		_visual = Node3D.new()
		_visual.name = "ActorVisual"
		_visual.set_script(visual_script)
		add_child(_visual)
		if _visual.has_method("configure"):
			_visual.call("configure", enemy_kind)
	else:
		_visual = Node3D.new()
		add_child(_visual)
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		var mesh: CapsuleMesh = CapsuleMesh.new()
		mesh.height = 2.2 if enemy_kind == "creature" else 1.75
		mesh.radius = 0.5 if enemy_kind == "creature" else 0.32
		mesh_instance.mesh = mesh
		mesh_instance.position.y = mesh.height * 0.5
		_visual.add_child(mesh_instance)


func _build_indicators() -> void:
	_health_display = Node3D.new()
	_health_display.name = "HealthIndicator"
	_health_display.visible = false
	_health_display.position.y = 3.05 if enemy_kind == "creature" else 2.24
	add_child(_health_display)
	var background: MeshInstance3D = _indicator_quad(Color(0.035, 0.028, 0.04), Vector2(1.23, 0.10))
	_health_display.add_child(background)
	_health_fill = _indicator_quad(Color(0.69, 0.24, 0.17), Vector2(1.17, 0.055))
	_health_fill.position.z = 0.004
	_health_display.add_child(_health_fill)
	_health_label = Label3D.new()
	_health_label.name = "EnemyName"
	_health_label.text = display_name
	_health_label.font_size = 28
	_health_label.pixel_size = 0.0032
	_health_label.position.y = 0.16
	_health_label.modulate = Color(0.86, 0.80, 0.66)
	_health_label.outline_modulate = Color(0.05, 0.04, 0.045)
	_health_label.outline_size = 7
	_health_label.no_depth_test = false
	_health_display.add_child(_health_label)
	_telegraph = MeshInstance3D.new()
	_telegraph.name = "AttackTelegraph"
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.70 if enemy_kind == "creature" else 0.45
	ring.outer_radius = 0.77 if enemy_kind == "creature" else 0.50
	ring.rings = 40
	ring.ring_segments = 8
	_telegraph.mesh = ring
	_telegraph.position.y = 0.045
	_telegraph_material = StandardMaterial3D.new()
	_telegraph_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_telegraph_material.albedo_color = Color(0.95, 0.42, 0.12)
	_telegraph.material_override = _telegraph_material
	_telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_telegraph.visible = false
	add_child(_telegraph)


func _indicator_quad(color: Color, size: Vector2) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = size
	instance.mesh = quad
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _update_indicators() -> void:
	if not is_instance_valid(_health_display):
		return
	_health_display.visible = not dead and active and (_engaged or health < max_health)
	if not _health_display.visible:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera:
		_health_display.global_basis = camera.global_basis.orthonormalized()
	var ratio: float = clampf(health / max_health, 0.001, 1.0)
	_health_fill.scale.x = ratio
	_health_fill.position.x = -1.17 * (1.0 - ratio) * 0.5
	if state == "windup" and enemy_kind == "creature":
		_health_label.text = display_name + ("  ·  LUNGE" if attack_kind == "lunge" else "  ·  SWEEP")
	else:
		_health_label.text = display_name


func _update_telegraph() -> void:
	_telegraph.visible = state == "windup" or state == "active"
	if state == "windup":
		var phase: float = clampf(_timer / _duration, 0.0, 1.0)
		var radius_scale: float = lerpf(1.0, 1.48, phase)
		_telegraph.scale = Vector3(radius_scale, 0.25, radius_scale)
		_telegraph_material.albedo_color = Color(0.72, 0.38, 0.14).lerp(Color(1.0, 0.12, 0.045), phase)
	elif state == "active":
		_telegraph_material.albedo_color = Color(0.92, 0.13, 0.055)
