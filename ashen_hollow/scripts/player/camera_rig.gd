extends Node3D
## Independent orbit camera. The SpringArm casts against the world, never actors.

@export var sensitivity: float = 0.0023
@export var distance: float = 4.7
var yaw: float = 0.0
var pitch: float = -0.19
var target: Node3D
var camera: Camera3D
var _pivot: Node3D
var _arm: SpringArm3D
var _shake: float = 0.0
var _shake_clock: float = 0.0
var _initialized: bool = false


func _ready() -> void:
	set_as_top_level(true)
	target = get_parent() as Node3D
	_pivot = Node3D.new()
	_pivot.name = "Pitch"
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.name = "CollisionArm"
	_arm.spring_length = distance
	_arm.margin = 0.18
	_arm.collision_mask = 1
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.18
	_arm.shape = camera_shape
	_pivot.add_child(_arm)
	if target is CollisionObject3D:
		_arm.add_excluded_object(target.get_rid())
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 68.0
	camera.near = 0.08
	camera.far = 180.0
	camera.current = true
	_arm.add_child(camera)
	snap_to_target()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(target) or not target.get("input_enabled") or target.get("dead"):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var locked: Node3D = target.get_lock_target()
		if not is_instance_valid(locked):
			yaw -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -0.72, 0.35)
	elif event is InputEventMouseButton and event.pressed and is_instance_valid(target.get_lock_target()):
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target.cycle_lock_target(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target.cycle_lock_target(-1)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if not _initialized:
		snap_to_target()
	var desired_position: Vector3 = target.global_position + Vector3(0.0, 1.42, 0.0)
	global_position = global_position.lerp(desired_position, 1.0 - exp(-18.0 * delta))
	var locked: Node3D = target.get_lock_target()
	if is_instance_valid(locked):
		var to_target: Vector3 = locked.global_position - target.global_position
		if to_target.length_squared() > 0.02:
			var lock_yaw := atan2(-to_target.x, -to_target.z)
			yaw = lerp_angle(yaw, lock_yaw, 1.0 - exp(-6.5 * delta))
	rotation = Vector3(0.0, yaw, 0.0)
	_pivot.rotation.x = pitch
	_shake_clock += delta
	_shake = move_toward(_shake, 0.0, delta * 0.32)
	camera.h_offset = sin(_shake_clock * 67.0) * _shake
	camera.v_offset = cos(_shake_clock * 83.0) * _shake * 0.65
	var desired_fov: float = 73.0 if target.get("is_sprinting") else 68.0
	camera.fov = lerpf(camera.fov, desired_fov, 1.0 - exp(-5.0 * delta))


func snap_to_target() -> void:
	if is_instance_valid(target):
		global_position = target.global_position + Vector3(0.0, 1.42, 0.0)
		rotation = Vector3(0.0, yaw, 0.0)
		if is_instance_valid(_pivot):
			_pivot.rotation.x = pitch
		_initialized = true


func add_shake(strength: float = 0.05) -> void:
	_shake = minf(maxf(_shake, strength), 0.16)


func get_camera() -> Camera3D:
	return camera
