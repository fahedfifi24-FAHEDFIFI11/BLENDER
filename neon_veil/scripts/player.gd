extends CharacterBody3D
var camera: Camera3D
var enabled := false
var crouching := false
var _pitch := 0.0
var _stride := 0.0
var _step_clock := 0.0
var steps: AudioStreamPlayer3D
func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.28
 capsule.height = 1.72
 var collider := CollisionShape3D.new()
 collider.shape = capsule
 collider.position.y = 0.86
 add_child(collider)
 camera = Camera3D.new()
 camera.position.y = 1.66
 camera.fov = 74
 camera.near = 0.07
 camera.far = 220
 add_child(camera)
 steps = AudioStreamPlayer3D.new()
 steps.stream = load("res://assets/audio/step.wav")
 steps.volume_db = -14
 add_child(steps)
 floor_snap_length = 0.25
func _unhandled_input(event: InputEvent) -> void:
 if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
  rotate_y(-event.relative.x * 0.0022)
  _pitch = clampf(_pitch-event.relative.y*0.0022,-1.35,1.35)
  camera.rotation.x = _pitch
func _physics_process(delta: float) -> void:
 var axis := Input.get_vector("left","right","forward","back") if enabled else Vector2.ZERO
 crouching = enabled and Input.is_action_pressed("crouch")
 var speed := 1.45 if crouching else (4.8 if Input.is_action_pressed("sprint") else 3.0)
 var direction := basis * Vector3(axis.x,0,axis.y)
 velocity.x = move_toward(velocity.x,direction.x*speed,delta*15)
 velocity.z = move_toward(velocity.z,direction.z*speed,delta*15)
 velocity.y = -0.3 if is_on_floor() else velocity.y-18*delta
 move_and_slide()
 _stride += delta * Vector2(velocity.x,velocity.z).length()*2.1
 var moving := enabled and axis.length() > 0.1 and is_on_floor()
 camera.position.y = lerpf(camera.position.y,(1.08 if crouching else 1.66)+(sin(_stride)*0.018 if moving else 0.0),1-exp(-delta*12))
 camera.fov = lerpf(camera.fov,78.0 if moving and speed>4 else 74.0,delta*4)
 _step_clock -= delta
 if moving and _step_clock <= 0:
  steps.pitch_scale = randf_range(.85,1.1)
  steps.play()
  _step_clock = .38 if speed>4 else .57
func reset_at(at: Vector3) -> void:
 position = at
 velocity = Vector3.ZERO
 rotation = Vector3.ZERO
 _pitch = 0
 camera.rotation = Vector3.ZERO
 camera.position.y = 1.66
func _exit_tree() -> void:
 if is_instance_valid(steps):
  steps.stop()
  steps.stream = null
