extends Node3D
## One complete, compact courier route with an interruptible surveillance encounter.
enum Stage { KEY, POWER, HIDE, GATE, DELIVERY, COMPLETE }
enum Mode { TITLE, PLAYING, PAUSED, ENDING, COMPLETE }
var stage := Stage.KEY
var mode := Mode.TITLE
var world: Node3D
var player: CharacterBody3D
var ui: CanvasLayer
var title_camera: Camera3D
var film_camera: Camera3D
var ambient: AudioStreamPlayer
var rain: AudioStreamPlayer
var sound: AudioStreamPlayer
var cover_time := 0.0
var high_quality := true
var elapsed := 0.0
var _ending_time := 0.0
var marker: Label3D
const LOCATIONS := {Stage.KEY:"key",Stage.POWER:"power",Stage.HIDE:"power",Stage.GATE:"gate",Stage.DELIVERY:"receiver"}
const OBJECTIVES := ["01  /  COLLECT THE ACCESS CIPHER\nFind the cipher terminal on the left.","02  /  RESTORE THE PRIVATE LINE\nReroute power at the relay beneath the right-hand awning.","03  /  STAY OUT OF THE SCAN\nCrouch beneath the relay awning until the patrol passes.","04  /  OPEN THE TRANSIT GATE\nAuthenticate at the terminal beside the red transit sign.","05  /  DELIVER THE STOLEN MEMORY\nReach the private uplink overlooking the amber veil.","06  /  THE MEMORY IS FREE"]
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 world = load("res://scripts/world.gd").new()
 world.name = "KasumiPassage"
 world.process_mode = Node.PROCESS_MODE_PAUSABLE
 add_child(world)
 player = load("res://scripts/player.gd").new()
 player.name = "Courier"
 player.position = Vector3(0,.2,17)
 player.process_mode = Node.PROCESS_MODE_PAUSABLE
 add_child(player)
 ui = load("res://scripts/interface.gd").new()
 add_child(ui)
 ui.begin_requested.connect(start_game)
 ui.resume_requested.connect(resume_game)
 ui.quit_requested.connect(quit_or_title)
 ui.quality_requested.connect(toggle_quality)
 title_camera = Camera3D.new()
 title_camera.position = Vector3(1.6,1.9,12.5)
 title_camera.fov = 68
 title_camera.far = 200
 add_child(title_camera)
 title_camera.look_at(Vector3(-1,3,-14))
 title_camera.make_current()
 film_camera = Camera3D.new()
 film_camera.far = 220
 add_child(film_camera)
 marker = world.label("◇",Vector3.ZERO,32,Color("99d6d6"))
 marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 marker.no_depth_test = false
 marker.hide()
 ambient = audio_loop("night",-12)
 rain = audio_loop("rain",-17)
 sound = AudioStreamPlayer.new()
 sound.process_mode = Node.PROCESS_MODE_PAUSABLE
 sound.volume_db = -10
 add_child(sound)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 for capture: String in ["title","alley","relay","reveal"]:
  if ("--capture-"+capture) in OS.get_cmdline_user_args():
   if capture != "title":
    start_game()
    player.enabled = false
    if capture == "relay":player.reset_at(Vector3(0,.1,-5))
    if capture == "reveal":
     stage = Stage.DELIVERY
     _update_objective()
     ui.message("MARA / The private uplink is ahead. Let them remember.",8)
     world.set_gate_open(true)
     player.reset_at(Vector3(0,.1,-29))
     player.camera.rotation.x = .16
   capture_after_frames(capture)
func audio_loop(id: String,volume: float) -> AudioStreamPlayer:
 var audio := AudioStreamPlayer.new()
 var stream: AudioStreamWAV = load("res://assets/audio/"+id+".wav").duplicate()
 stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 stream.loop_end = int(stream.get_length()*stream.mix_rate)
 audio.stream = stream
 audio.volume_db = volume
 audio.process_mode = Node.PROCESS_MODE_PAUSABLE
 add_child(audio)
 audio.play()
 return audio
func play_sound(id: String) -> void:
 sound.stream = load("res://assets/audio/"+id+".wav")
 sound.play()
func start_game() -> void:
 get_tree().paused = false
 mode = Mode.PLAYING
 stage = Stage.KEY
 elapsed = 0
 cover_time = 0
 _ending_time = 0
 world.set_gate_open(false)
 world.gate.position.y = 0
 world.scan_active = false
 player.reset_at(Vector3(0,.15,17))
 player.enabled = true
 player.camera.make_current()
 ui.show_game()
 ui.scan.hide()
 ui.status.text = "ENCRYPTED CARGO   /   OFFLINE"
 ui.message("MARA / The archive is all we have left. Find my cipher. Keep the delivery off their network.",8)
 marker.show()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 _update_objective()
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("pause") and not event.is_echo():
  if mode == Mode.PLAYING:pause_game()
  elif mode == Mode.PAUSED:resume_game()
  elif mode == Mode.ENDING:
   mode = Mode.COMPLETE
   ui.show_ending()
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 if event.is_action_pressed("interact") and mode == Mode.PLAYING:try_interact()
func _process(delta: float) -> void:
 if mode == Mode.TITLE:
  title_camera.position.x = 1.6+sin(Time.get_ticks_msec()*.00007)*.18
  return
 if mode == Mode.ENDING:
  _ending_time += delta
  film_camera.position = film_camera.position.lerp(Vector3(0,2.9,-33),delta*.16)
  film_camera.look_at(Vector3(0,12,-61))
  if _ending_time > 7:
   mode = Mode.COMPLETE
   ui.show_ending()
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
  return
 if mode != Mode.PLAYING:return
 elapsed += delta
 if player.position.y < -6:player.reset_at(Vector3(0,.2,17))
 var target_id: String = LOCATIONS.get(stage,"")
 if not target_id.is_empty():
  var target: Node3D = world.terminals[target_id]
  marker.position = target.position+Vector3(0,2.35,0)
  var distance := player.position.distance_to(target.position)
  ui.bearing.text = "%s  /  %02d m" % [target_id.to_upper(),int(distance)]
  marker.visible = distance > 3
 ui.prompt.text = "[ E ]  " + _action_name() if can_interact() else ""
 if stage == Stage.HIDE:
  # The whole route remains playable; cover is a distinct positional AND crouch check.
  var sheltered: bool = player.position.x > 3.1 and player.position.z < -7.7 and player.position.z > -12.5 and player.crouching
  cover_time = minf(4,cover_time+delta) if sheltered else maxf(0,cover_time-delta*2)
  ui.scan.value = cover_time
  ui.status.text = "PATROL / COVER CONFIRMED" if sheltered else "PATROL / SEEK COVER · HOLD CTRL"
  if cover_time >= 4:
   stage = Stage.GATE
   world.scan_active = false
   ui.scan.hide()
   ui.status.text = "PATROL CLEARED   /   PRIVATE LINE READY"
   ui.message("MARA / You're clear. The transit gate will recognize my cipher. Go.",6)
   _update_objective()
func _action_name() -> String:
 return {Stage.KEY:"COPY ACCESS CIPHER",Stage.POWER:"REROUTE THE RELAY",Stage.GATE:"AUTHENTICATE GATE",Stage.DELIVERY:"TRANSMIT THE ARCHIVE"}.get(stage,"")
func can_interact() -> bool:
 if mode != Mode.PLAYING or stage in [Stage.HIDE,Stage.COMPLETE]:return false
 var target: Node3D = world.terminals[LOCATIONS[stage]]
 var point := target.global_position+Vector3(0,1.4,0)
 var offset: Vector3 = point-player.camera.global_position
 if offset.length()>2.6:return false
 if (-player.camera.global_basis.z).dot(offset.normalized())<.65:return false
 var query := PhysicsRayQueryParameters3D.create(player.camera.global_position,point-offset.normalized()*.65,1)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func try_interact() -> bool:
 if not can_interact():return false
 match stage:
  Stage.KEY:
   stage = Stage.POWER
   play_sound("terminal")
   ui.message("CIPHER COPIED / They erased the daylight records. This is the last unedited copy.",7)
   ui.status.text = "ACCESS CIPHER   /   ACQUIRED"
  Stage.POWER:
   stage = Stage.HIDE
   world.scan_active = true
   cover_time = 0
   ui.scan.show()
   play_sound("scan")
   ui.message("MARA / Patrol incoming. Stay by the relay, under the awning. Hold CTRL and keep low.",9)
  Stage.GATE:
   stage = Stage.DELIVERY
   world.set_gate_open(true)
   play_sound("door")
   ui.message("PRIVATE TRANSIT / Access granted. The uplink is beyond the gate.",6)
  Stage.DELIVERY:
   stage = Stage.COMPLETE
   mode = Mode.ENDING
   player.enabled = false
   marker.hide()
   ui.prompt.text = ""
   ui.status.text = "ARCHIVE RELEASED   /   ALL CHANNELS"
   ui.message("MARA / Look up. For one moment, let them remember the sun.",7)
   play_sound("ending")
   film_camera.global_transform = player.camera.global_transform
   film_camera.make_current()
   _ending_time = 0
 _update_objective()
 return true
func _update_objective() -> void:
 ui.objective.text = OBJECTIVES[stage]
func pause_game() -> void:
 if mode != Mode.PLAYING:return
 mode = Mode.PAUSED
 player.enabled = false
 get_tree().paused = true
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 ui.show_pause()
func resume_game() -> void:
 if mode != Mode.PAUSED:return
 get_tree().paused = false
 mode = Mode.PLAYING
 player.enabled = true
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 ui.show_game()
func toggle_quality() -> void:
 high_quality = not high_quality
 world.set_quality(high_quality)
 ui.quality_button.text = "VISUALS  /  " + ("CINEMATIC" if high_quality else "BALANCED")
 ui.message("Visual quality: " + ("Cinematic" if high_quality else "Balanced — fog and reflections reduced"),4)
func quit_or_title() -> void:
 if mode == Mode.TITLE:
  get_tree().quit()
  return
 get_tree().paused = false
 mode = Mode.TITLE
 player.enabled = false
 world.scan_active = false
 marker.hide()
 title_camera.make_current()
 ui.show_title()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func capture_after_frames(id: String) -> void:
 for i in 12:await get_tree().process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://test-results")
 get_viewport().get_texture().get_image().save_png("res://test-results/"+id+".png")
 print("CAPTURE ",id)
 get_tree().quit()
func _exit_tree() -> void:
 # Release active WAV playbacks before the audio server tears down.
 for audio in [ambient,rain,sound]:
  if is_instance_valid(audio):
   audio.stop()
   audio.stream = null
