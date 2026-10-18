extends CharacterBody3D
## All action windows are measured in seconds; movement and stamina are frame independent.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal died
signal combat_event(kind: String, position: Vector3)

@export var max_health: float = 120.0
@export var max_stamina: float = 100.0
@export var walk_speed: float = 4.2
@export var sprint_speed: float = 6.8
@export var acceleration: float = 22.0
@export var jump_velocity: float = 6.2

var health: float = 120.0
var stamina: float = 100.0
var dead: bool = false
var blocking: bool = false
var invulnerable: bool = false
var attack_state: String = ""
var input_enabled: bool = false
var is_sprinting: bool = false
var camera_rig: Node3D
var actor_visual: Node3D

const LIGHT_DURATION: Array[float] = [0.54, 0.57, 0.73]
const LIGHT_ACTIVE_START: Array[float] = [0.12, 0.14, 0.22]
const LIGHT_ACTIVE_END: Array[float] = [0.29, 0.32, 0.43]
const LIGHT_DAMAGE: Array[float] = [22.0, 25.0, 35.0]
const LIGHT_STAMINA: Array[float] = [10.0, 11.0, 15.0]
const LIGHT_KNOCKBACK: Array[float] = [2.8, 3.4, 5.3]
const HEAVY_DURATION: float = 1.04
const DODGE_DURATION: float = 0.52
const GRAVITY: float = 18.5

var _action_elapsed: float = 0.0
var _action_duration: float = 0.0
var _combo_index: int = 0
var _combo_requested: bool = false
var _buffered_action: String = ""
var _buffer_remaining: float = 0.0
var _stagger_remaining: float = 0.0
var _invulnerability_remaining: float = 0.8
var _stamina_delay: float = 0.0
var _dodge_direction: Vector3 = Vector3.FORWARD
var _impulse: Vector3 = Vector3.ZERO
var _move_direction: Vector3 = Vector3.ZERO
var _lock_target: Node3D
var _lock_occluded_time: float = 0.0
var _locomotion_phase: float = 0.0
var _hit_targets: Dictionary = {}
var _swing_emitted: bool = false
var _heavy_hitbox: BoxShape3D
var _light_hitbox: BoxShape3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.28
	floor_max_angle = deg_to_rad(46.0)
	health = max_health
	stamina = max_stamina
	camera_rig = get_node("CameraRig")
	_light_hitbox = BoxShape3D.new()
	_light_hitbox.size = Vector3(1.85, 1.85, 2.0)
	_heavy_hitbox = BoxShape3D.new()
	_heavy_hitbox.size = Vector3(2.2, 1.95, 2.45)
	var visual_path := "res://scripts/art/actor_visual.gd"
	if ResourceLoader.exists(visual_path):
		actor_visual = Node3D.new()
		actor_visual.name = "ActorVisual"
		actor_visual.set_script(load(visual_path))
		add_child(actor_visual)
		actor_visual.configure("player")
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		_animate("death", 0.0, 1.0)
		return
	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)
		_apply_gravity(delta)
		move_and_slide()
		_animate("idle", 0.0)
		return
	_update_lock_target(delta)
	_read_input()
	_update_action(delta)
	_update_movement(delta)
	_apply_gravity(delta)
	move_and_slide()
	if global_position.y < -12.0:
		_invulnerability_remaining = 0.0
		invulnerable = false
		receive_hit(max_health * 2.0, global_position + Vector3.FORWARD)
	_update_visual(delta)


func _update_timers(delta: float) -> void:
	_invulnerability_remaining = maxf(0.0, _invulnerability_remaining - delta)
	_stagger_remaining = maxf(0.0, _stagger_remaining - delta)
	_stamina_delay = maxf(0.0, _stamina_delay - delta)
	_buffer_remaining = maxf(0.0, _buffer_remaining - delta)
	if _buffer_remaining <= 0.0:
		_buffered_action = ""
	invulnerable = _invulnerability_remaining > 0.0 or (attack_state == "dodge" and _action_elapsed >= 0.035 and _action_elapsed <= 0.37)
	_impulse = _impulse.move_toward(Vector3.ZERO, 13.0 * delta)
	if not dead and _stamina_delay <= 0.0 and attack_state.is_empty() and not is_sprinting:
		var regen: float = 10.0 if blocking else 25.0
		_set_stamina(stamina + regen * delta)


func _read_input() -> void:
	var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_move_direction = Vector3(move_input.x, 0.0, move_input.y).rotated(Vector3.UP, camera_rig.yaw)
	if Input.is_action_just_pressed("lock_on"):
		if is_instance_valid(_lock_target):
			_lock_target = null
		else:
			_lock_target = _find_lock_target()
	blocking = Input.is_action_pressed("block") and attack_state.is_empty() and _stagger_remaining <= 0.0 and stamina > 0.5 and is_on_floor()
	if Input.is_action_just_pressed("dodge"):
		if not start_dodge():
			_buffer_action("dodge")
	elif Input.is_action_just_pressed("heavy_attack"):
		if not attack_heavy():
			_buffer_action("heavy")
	elif Input.is_action_just_pressed("light_attack"):
		if not attack_light():
			_buffer_action("light")
	if Input.is_action_just_pressed("jump") and is_on_floor() and attack_state.is_empty() and _stagger_remaining <= 0.0 and not blocking:
		velocity.y = jump_velocity
		combat_event.emit("jump", global_position)
	if attack_state.is_empty() and _stagger_remaining <= 0.0 and not _buffered_action.is_empty():
		var next_action: String = _buffered_action
		_buffered_action = ""
		if next_action == "dodge":
			start_dodge()
		elif next_action == "heavy":
			attack_heavy()
		else:
			attack_light()


func _buffer_action(action: String) -> void:
	_buffered_action = action
	_buffer_remaining = 0.24


func attack_light() -> bool:
	if dead or not input_enabled or _stagger_remaining > 0.0:
		return false
	if attack_state.begins_with("light_") and _combo_index < 2:
		_combo_requested = true
		return true
	if not attack_state.is_empty() or stamina < LIGHT_STAMINA[0]:
		return false
	_begin_light(0)
	return true


func _begin_light(index: int) -> void:
	_combo_index = index
	attack_state = "light_%d" % (index + 1)
	_action_elapsed = 0.0
	_action_duration = LIGHT_DURATION[index]
	_combo_requested = false
	_hit_targets.clear()
	_swing_emitted = false
	blocking = false
	is_sprinting = false
	_spend_stamina(LIGHT_STAMINA[index])
	_face_attack_target()


func attack_heavy() -> bool:
	if dead or not input_enabled or _stagger_remaining > 0.0 or not attack_state.is_empty() or stamina < 27.0:
		return false
	attack_state = "heavy"
	_action_elapsed = 0.0
	_action_duration = HEAVY_DURATION
	_combo_requested = false
	_hit_targets.clear()
	_swing_emitted = false
	blocking = false
	is_sprinting = false
	_spend_stamina(27.0)
	_face_attack_target()
	return true


func start_dodge() -> bool:
	if dead or not input_enabled or _stagger_remaining > 0.0 or stamina < 23.0 or not is_on_floor():
		return false
	# Late recovery may be cancelled into a dodge; committed attack windups may not.
	if not attack_state.is_empty() and (attack_state == "dodge" or _action_elapsed < _action_duration * 0.72):
		return false
	attack_state = "dodge"
	_action_elapsed = 0.0
	_action_duration = DODGE_DURATION
	_combo_requested = false
	_buffered_action = ""
	blocking = false
	is_sprinting = false
	_dodge_direction = _move_direction.normalized() if _move_direction.length_squared() > 0.01 else -global_basis.z
	_dodge_direction.y = 0.0
	_dodge_direction = _dodge_direction.normalized()
	_spend_stamina(23.0)
	combat_event.emit("dodge", global_position)
	return true


func _update_action(delta: float) -> void:
	if attack_state.is_empty():
		return
	_action_elapsed += delta
	if attack_state == "dodge":
		invulnerable = _invulnerability_remaining > 0.0 or (_action_elapsed >= 0.035 and _action_elapsed <= 0.37)
	else:
		var active_start: float = 0.38 if attack_state == "heavy" else LIGHT_ACTIVE_START[_combo_index]
		var active_end: float = 0.63 if attack_state == "heavy" else LIGHT_ACTIVE_END[_combo_index]
		if _action_elapsed >= active_start and _action_elapsed <= active_end:
			if not _swing_emitted:
				_swing_emitted = true
				combat_event.emit("heavy_swing" if attack_state == "heavy" else "swing", global_position + Vector3.UP)
			_query_sword_hits()
		if attack_state.begins_with("light_") and _combo_requested and _action_elapsed >= _action_duration - 0.10:
			var next_index: int = _combo_index + 1
			if next_index < 3 and stamina >= LIGHT_STAMINA[next_index]:
				_begin_light(next_index)
				return
	if _action_elapsed >= _action_duration:
		attack_state = ""
		_combo_requested = false
		_hit_targets.clear()


func _update_movement(delta: float) -> void:
	var desired: Vector3 = Vector3.ZERO
	is_sprinting = false
	if _stagger_remaining > 0.0:
		desired = Vector3.ZERO
	elif attack_state == "dodge":
		var dodge_speed: float = lerpf(10.2, 4.8, clampf(_action_elapsed / DODGE_DURATION, 0.0, 1.0))
		desired = _dodge_direction * dodge_speed
	elif not attack_state.is_empty():
		var surge: float = 0.0
		if attack_state == "heavy":
			if _action_elapsed > 0.23 and _action_elapsed < 0.55:
				surge = 2.4
		elif _action_elapsed < 0.27:
			surge = 1.7
		desired = -global_basis.z * surge + _move_direction * 0.38
	else:
		is_sprinting = Input.is_action_pressed("sprint") and _move_direction.length_squared() > 0.01 and not blocking and stamina > 2.0 and not is_instance_valid(_lock_target)
		var speed: float = sprint_speed if is_sprinting else walk_speed
		if blocking:
			speed = 2.0
		desired = _move_direction * speed
		if is_sprinting:
			_spend_stamina(12.0 * delta)
	var movement_acceleration: float = acceleration if is_on_floor() else acceleration * 0.42
	if attack_state == "dodge":
		movement_acceleration = 100.0
	velocity.x = move_toward(velocity.x, desired.x + _impulse.x, movement_acceleration * delta)
	velocity.z = move_toward(velocity.z, desired.z + _impulse.z, movement_acceleration * delta)
	if attack_state.is_empty() and _stagger_remaining <= 0.0:
		var face_direction: Vector3 = _move_direction
		if is_instance_valid(_lock_target):
			face_direction = _lock_target.global_position - global_position
		if face_direction.length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(-face_direction.x, -face_direction.z), 1.0 - exp(-15.0 * delta))


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = maxf(velocity.y - GRAVITY * delta, -32.0)
	elif velocity.y < 0.0:
		velocity.y = -0.2


func _face_attack_target() -> void:
	var facing: Vector3 = Vector3.ZERO
	if is_instance_valid(_lock_target):
		facing = _lock_target.global_position - global_position
	elif _move_direction.length_squared() > 0.01:
		facing = _move_direction
	if facing.length_squared() > 0.01:
		rotation.y = atan2(-facing.x, -facing.z)


func _query_sword_hits() -> void:
	var heavy: bool = attack_state == "heavy"
	var parameters := PhysicsShapeQueryParameters3D.new()
	parameters.shape = _heavy_hitbox if heavy else _light_hitbox
	parameters.transform = Transform3D(global_basis, global_position + Vector3.UP * 1.0 - global_basis.z * (1.25 if heavy else 1.15))
	parameters.collision_mask = 4
	parameters.collide_with_bodies = true
	parameters.collide_with_areas = false
	parameters.exclude = [get_rid()]
	var intersections: Array[Dictionary] = get_world_3d().direct_space_state.intersect_shape(parameters, 16)
	for intersection: Dictionary in intersections:
		var enemy: Node3D = intersection.get("collider") as Node3D
		if not is_instance_valid(enemy) or not enemy.has_method("receive_hit"):
			continue
		var enemy_id: int = enemy.get_instance_id()
		if _hit_targets.has(enemy_id) or not _has_line_of_sight(enemy):
			continue
		_hit_targets[enemy_id] = true
		var damage: float = 49.0 if heavy else LIGHT_DAMAGE[_combo_index]
		var force: float = 6.2 if heavy else LIGHT_KNOCKBACK[_combo_index]
		if enemy.receive_hit(damage, global_position, force):
			combat_event.emit("heavy_hit" if heavy else "hit", enemy.global_position + Vector3.UP * 1.1)
			camera_rig.add_shake(0.075 if heavy else 0.042)


func _has_line_of_sight(other: Node3D) -> bool:
	var ray := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.05, other.global_position + Vector3.UP * 1.05, 1)
	ray.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func receive_hit(amount: float, source_position: Vector3, knockback: float = 3.0) -> bool:
	if dead or invulnerable or amount <= 0.0:
		return false
	var away: Vector3 = global_position - source_position
	away.y = 0.0
	if away.length_squared() <= 0.001:
		away = global_basis.z
	away = away.normalized()
	var facing_attacker: bool = (-global_basis.z).dot(-away) >= 0.12
	if blocking and facing_attacker:
		var guard_cost: float = amount * 0.72 + 5.0
		if stamina >= guard_cost:
			_spend_stamina(guard_cost)
			_impulse = away * knockback * 0.22
			combat_event.emit("block", global_position + Vector3.UP * 1.1)
			camera_rig.add_shake(0.035)
			return false
		_set_stamina(0.0)
		blocking = false
		_stagger_remaining = 0.72
		_stamina_delay = 1.1
		amount *= 0.75
		combat_event.emit("guard_break", global_position + Vector3.UP)
	else:
		_stagger_remaining = 0.29
	health = maxf(0.0, health - amount)
	health_changed.emit(health, max_health)
	attack_state = ""
	_combo_requested = false
	_buffered_action = ""
	blocking = false
	is_sprinting = false
	_impulse = away * knockback
	_invulnerability_remaining = 0.23
	invulnerable = true
	if is_instance_valid(actor_visual) and actor_visual.has_method("flash_hit"):
		actor_visual.flash_hit()
	camera_rig.add_shake(0.095)
	combat_event.emit("hurt", global_position + Vector3.UP)
	if health <= 0.0:
		_die()
	return true


func _die() -> void:
	dead = true
	blocking = false
	is_sprinting = false
	attack_state = ""
	_lock_target = null
	_impulse = Vector3.ZERO
	velocity = Vector3.ZERO
	if is_instance_valid(actor_visual) and actor_visual.has_method("set_dead"):
		actor_visual.set_dead(true)
	combat_event.emit("death", global_position + Vector3.UP)
	died.emit()


func reset_at(spawn_position: Vector3) -> void:
	global_position = spawn_position
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	_impulse = Vector3.ZERO
	_move_direction = Vector3.ZERO
	health = max_health
	stamina = max_stamina
	dead = false
	blocking = false
	is_sprinting = false
	attack_state = ""
	_combo_requested = false
	_buffered_action = ""
	_stagger_remaining = 0.0
	_stamina_delay = 0.0
	_invulnerability_remaining = 0.8
	invulnerable = true
	_lock_target = null
	_hit_targets.clear()
	if is_instance_valid(actor_visual) and actor_visual.has_method("set_dead"):
		actor_visual.set_dead(false)
	if is_instance_valid(camera_rig):
		camera_rig.yaw = 0.0
		camera_rig.pitch = -0.19
		camera_rig.snap_to_target()
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)


func set_input_enabled(value: bool) -> void:
	input_enabled = value
	if not value:
		blocking = false
		is_sprinting = false
		attack_state = ""
		_combo_requested = false
		_buffered_action = ""
		_move_direction = Vector3.ZERO
		_lock_target = null


func is_attacking() -> bool:
	return attack_state.begins_with("light_") or attack_state == "heavy"


func get_lock_target() -> Node3D:
	if is_instance_valid(_lock_target) and not _lock_target.get("dead"):
		return _lock_target
	return null


func _valid_lock_candidates() -> Array[Node3D]:
	var candidates: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Node3D = node as Node3D
		if not is_instance_valid(enemy) or enemy.get("dead") or enemy.get("active") == false:
			continue
		if global_position.distance_squared_to(enemy.global_position) <= 22.0 * 22.0 and _has_line_of_sight(enemy):
			candidates.append(enemy)
	return candidates


func _find_lock_target() -> Node3D:
	var best: Node3D
	var best_score: float = INF
	var camera_forward: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, camera_rig.yaw)
	for candidate: Node3D in _valid_lock_candidates():
		var offset: Vector3 = candidate.global_position - global_position
		var distance_to: float = offset.length()
		offset.y = 0.0
		var alignment: float = camera_forward.dot(offset.normalized())
		if alignment < -0.15 and distance_to > 3.0:
			continue
		var score: float = distance_to + (1.0 - alignment) * 8.0
		if score < best_score:
			best_score = score
			best = candidate
	return best


func cycle_lock_target(direction: int = 1) -> void:
	var candidates: Array[Node3D] = _valid_lock_candidates()
	if candidates.is_empty():
		_lock_target = null
		return
	candidates.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var a_direction: Vector3 = a.global_position - global_position
		var b_direction: Vector3 = b.global_position - global_position
		return atan2(a_direction.x, a_direction.z) < atan2(b_direction.x, b_direction.z))
	var index: int = candidates.find(_lock_target)
	_lock_target = candidates[posmod(index + direction, candidates.size())]
	_lock_occluded_time = 0.0


func _update_lock_target(delta: float) -> void:
	if not is_instance_valid(_lock_target):
		_lock_target = null
		return
	if _lock_target.get("dead") or global_position.distance_squared_to(_lock_target.global_position) > 24.0 * 24.0:
		_lock_target = null
		return
	_lock_occluded_time = 0.0 if _has_line_of_sight(_lock_target) else _lock_occluded_time + delta
	if _lock_occluded_time > 0.6:
		_lock_target = null


func _spend_stamina(amount: float) -> void:
	_set_stamina(stamina - amount)
	_stamina_delay = 0.65


func _set_stamina(value: float) -> void:
	var previous: float = stamina
	stamina = clampf(value, 0.0, max_stamina)
	if absf(previous - stamina) > 0.001:
		stamina_changed.emit(stamina, max_stamina)


func _update_visual(delta: float) -> void:
	var speed: float = Vector2(velocity.x, velocity.z).length()
	_locomotion_phase = fposmod(_locomotion_phase + delta * maxf(speed, 0.5) * 0.48, 1.0)
	if _stagger_remaining > 0.0:
		_animate("stagger", speed, clampf(1.0 - _stagger_remaining / 0.3, 0.0, 1.0))
	elif not attack_state.is_empty():
		_animate(attack_state, speed, clampf(_action_elapsed / maxf(_action_duration, 0.01), 0.0, 1.0))
	elif not is_on_floor():
		_animate("jump", speed, 0.5)
	elif blocking:
		_animate("block", speed, _locomotion_phase)
	elif speed > 0.12:
		_animate("sprint" if is_sprinting else "run", speed, _locomotion_phase)
	else:
		_animate("idle", 0.0, _locomotion_phase)


func _animate(state: String, speed: float, phase: float = 0.0) -> void:
	if is_instance_valid(actor_visual) and actor_visual.has_method("set_motion"):
		actor_visual.set_motion(state, speed, phase)
