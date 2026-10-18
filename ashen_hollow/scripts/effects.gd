extends Node3D
## Small spatial sound/impact pool; all samples are original synthesized assets.
var _streams: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _ambient: AudioStreamPlayer

func _ready() -> void:
	_rng.seed = 1104
	for key in ["ambience", "light", "heavy", "hit", "block", "dodge", "bell", "victory", "hurt", "death"]:
		var file: String = "res://assets/audio/" + key + ".wav"
		if ResourceLoader.exists(file):
			_streams[key] = load(file)
	if _streams.has("ambience"):
		_ambient = AudioStreamPlayer.new()
		_ambient.stream = _streams["ambience"]
		_ambient.volume_db = -15
		add_child(_ambient)
		_ambient.play()
		_ambient.finished.connect(_ambient.play)

func play_event(kind: String, at: Vector3) -> void:
	var key: String = kind
	if kind.begins_with("light") or kind in ["attack", "swing", "enemy_attack"]:
		key = "light"
	if kind in ["heavy_swing", "heavy_hit"]:
		key = "heavy"
	if kind in ["enemy_hurt", "impact", "stagger"]:
		key = "hit"
	if kind in ["enemy_death", "player_death"]:
		key = "death"
	if kind in ["guard_break", "blocked", "parry"]:
		key = "block"
	if _streams.has(key):
		var audio := AudioStreamPlayer3D.new()
		audio.stream = _streams[key]
		audio.max_distance = 32
		audio.unit_size = 5
		audio.volume_db = -8 if key not in ["bell", "victory"] else -3
		audio.pitch_scale = _rng.randf_range(0.94, 1.06)
		add_child(audio)
		audio.global_position = at
		audio.finished.connect(audio.queue_free)
		audio.play()
	if key in ["hit", "block", "heavy"]:
		_impact(at + Vector3.UP * 1.1, key == "block")

func _impact(at: Vector3, metal: bool) -> void:
	var particles := CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 9 if metal else 7
	particles.lifetime = 0.25
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 130
	particles.initial_velocity_min = 1.3
	particles.initial_velocity_max = 3.1
	particles.gravity = Vector3(0, -8, 0)
	particles.scale_amount_min = 0.025
	particles.scale_amount_max = 0.065
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("e5bc76") if metal else Color("c49c70")
	var spark := SphereMesh.new()
	spark.radial_segments = 4
	spark.rings = 2
	spark.material = mat
	particles.mesh = spark
	add_child(particles)
	particles.global_position = at
	particles.emitting = true
	get_tree().create_timer(0.7).timeout.connect(particles.queue_free)
