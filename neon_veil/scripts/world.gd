extends Node3D
var environment: Environment
var gate: Node3D
var gate_collision: StaticBody3D
var drone: Node3D
var drone_light: SpotLight3D
var terminals: Dictionary = {}
var lamps: Array[OmniLight3D] = []
var _materials: Dictionary = {}
var _assets: Dictionary = {}
var _time := 0.0
var gate_open := false
var scan_active := false
var _fog: FogVolume
var _font: Font = preload("res://assets/fonts/Body.ttf")
func _ready() -> void:
 _make_materials()
 _atmosphere()
 _street()
 _architecture()
 _details()
 _beyond()
 _weather()
 _finishing_details()
func _mat(name_: String,color: Color,metal: float,rough: float) -> StandardMaterial3D:
 var m := StandardMaterial3D.new()
 m.albedo_color = color
 m.metallic = metal
 m.roughness = rough
 if name_ in ["metal","concrete","bronze","asphalt"]:
  m.albedo_texture = load("res://assets/textures/"+name_+"_color.png")
  m.normal_enabled = true
  m.normal_texture = load("res://assets/textures/"+name_+"_normal.png")
  m.normal_scale = 0.45
  m.roughness_texture = load("res://assets/textures/"+name_+"_rough.png")
  m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 _materials[name_] = m
 return m
func _make_materials() -> void:
 _mat("metal",Color("a4bbc4"),.72,.5)
 _mat("concrete",Color("9babb0"),.1,.83)
 _mat("bronze",Color("d5bfa6"),.7,.43)
 _mat("dark",Color("111c24"),.55,.23)
 _mat("glass",Color("183b46"),.72,.14)
 _mat("ivory",Color("979c8d"),.3,.48)
 _mat("asphalt",Color.WHITE,.25,.35)
 for entry in [["cyan",Color("61d5e2")],["amber",Color("ff9d4d")],["red",Color("f45d55")],["violet",Color("aa85c2")],["white",Color("b6d5d7")]]:
  var m := _mat(entry[0],entry[1],.2,.28)
  m.emission_enabled = true
  m.emission = entry[1]
  m.emission_energy_multiplier = 2.2
func _atmosphere() -> void:
 var node := WorldEnvironment.new()
 environment = Environment.new()
 environment.background_mode = Environment.BG_SKY
 var sky := Sky.new()
 var sky_material := ProceduralSkyMaterial.new()
 sky_material.sky_top_color = Color("0c1927")
 sky_material.sky_horizon_color = Color("6d767a")
 sky_material.ground_bottom_color = Color("111b21")
 sky_material.ground_horizon_color = Color("6d767a")
 sky_material.sky_energy_multiplier = .45
 sky_material.ground_energy_multiplier = .35
 sky.sky_material = sky_material
 environment.sky = sky
 environment.background_color = Color("101b25")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("557482")
 environment.ambient_light_energy = .38
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 environment.tonemap_exposure = 1.1
 environment.glow_enabled = true
 environment.glow_intensity = .65
 environment.glow_bloom = .08
 environment.glow_hdr_threshold = 1.3
 environment.ssao_enabled = true
 environment.ssao_radius = 1.1
 environment.ssao_intensity = 1.1
 environment.ssr_enabled = true
 environment.ssr_max_steps = 48
 environment.ssr_fade_in = .1
 environment.ssr_fade_out = 2.0
 environment.fog_enabled = true
 environment.fog_density = .006
 environment.fog_light_color = Color("426976")
 environment.fog_light_energy = .35
 environment.volumetric_fog_enabled = true
 environment.volumetric_fog_density = .026
 environment.volumetric_fog_albedo = Color("768d99")
 environment.volumetric_fog_emission = Color("15232a")
 environment.volumetric_fog_emission_energy = .18
 environment.volumetric_fog_length = 80
 environment.volumetric_fog_detail_spread = 1.5
 node.environment = environment
 add_child(node)
 var moon := DirectionalLight3D.new()
 moon.rotation_degrees = Vector3(-65,-25,0)
 moon.light_color = Color("6c98b2")
 moon.light_energy = .25
 moon.shadow_enabled = true
 moon.directional_shadow_max_distance = 60
 add_child(moon)
func box(at: Vector3,size: Vector3,material: String,solid := false,parent: Node3D = self) -> MeshInstance3D:
 var n := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 n.mesh = mesh
 n.material_override = _materials[material]
 n.position = at
 parent.add_child(n)
 if solid: collision(at,size,parent)
 return n
func collision(at: Vector3,size: Vector3,parent: Node3D = self) -> StaticBody3D:
 var b := StaticBody3D.new()
 b.position = at
 b.collision_layer = 1
 b.collision_mask = 0
 var c := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 c.shape = shape
 b.add_child(c)
 parent.add_child(b)
 return b
func model(id: String,at: Vector3,angle := 0.0) -> Node3D:
 if not _assets.has(id): _assets[id] = load("res://assets/models/"+id+".glb")
 var n: Node3D = _assets[id].instantiate()
 n.position = at
 n.rotation.y = angle
 add_child(n)
 _retouch(n)
 return n
func _retouch(n: Node) -> void:
 if n is MeshInstance3D:
  for i in n.mesh.get_surface_count():
   var m: Material = n.mesh.surface_get_material(i)
   if m and _materials.has(m.resource_name): n.set_surface_override_material(i,_materials[m.resource_name])
 for child in n.get_children(): _retouch(child)
func pipe(points: Array[Vector3],radius := .045,material := "metal") -> void:
 for i in range(points.size()-1):
  var a := points[i]
  var b := points[i+1]
  var n := MeshInstance3D.new()
  var mesh := CylinderMesh.new()
  mesh.top_radius = radius
  mesh.bottom_radius = radius
  mesh.height = a.distance_to(b)
  mesh.radial_segments = 12
  n.mesh = mesh
  n.material_override = _materials[material]
  n.position = (a+b)*.5
  add_child(n)
  var direction := (b-a).normalized()
  n.quaternion = Quaternion(Vector3.UP,direction)
func label(text_: String,at: Vector3,size: int,color: Color,angle := 0.0) -> Label3D:
 var l := Label3D.new()
 l.text = text_
 l.font = _font
 l.font_size = size
 l.pixel_size = .009
 l.modulate = color
 l.outline_size = 0
 l.no_depth_test = false
 l.position = at
 l.rotation.y = angle
 add_child(l)
 return l
func neon(text_: String,at: Vector3,color: String,angle := 0.0,size := 58) -> void:
 var width := maxf(1.2,text_.length()*.28)
 var n := Node3D.new()
 n.position = at
 n.rotation.y = angle
 add_child(n)
 box(Vector3.ZERO,Vector3(width+.45,1.02,.16),"metal",false,n)
 box(Vector3(0,-.43,.1),Vector3(width,.025,.035),color,false,n)
 var l := label(text_,at+Basis(Vector3.UP,angle)*Vector3(0,0,.11),size,_materials[color].emission,angle)
 l.modulate = _materials[color].emission * 1.8
 light(at+Basis(Vector3.UP,angle)*Vector3(0,0,.7),_materials[color].emission,2.0,5.5)
func light(at: Vector3,color: Color,energy: float,range_: float,shadow := false) -> OmniLight3D:
 var n := OmniLight3D.new()
 n.position = at
 n.light_color = color
 n.light_energy = energy
 n.omni_range = range_
 n.omni_attenuation = 1.25
 n.shadow_enabled = shadow
 n.light_volumetric_fog_energy = .65
 add_child(n)
 return n
func _street() -> void:
 var ground := box(Vector3(0,-.16,-10),Vector3(20,.3,64),"asphalt",true)
 var wet := ShaderMaterial.new()
 wet.shader = load("res://scripts/wet_street.gdshader")
 wet.set_shader_parameter("asphalt",load("res://assets/textures/asphalt_color.png"))
 wet.set_shader_parameter("normal_map",load("res://assets/textures/asphalt_normal.png"))
 wet.set_shader_parameter("puddles",load("res://assets/textures/puddle.png"))
 ground.material_override = wet
 # Raised curb lips stay outside the clear first-person route.
 for side in [-1.0,1.0]:
  box(Vector3(side*5.1,.04,-4),Vector3(1.5,.1,46),"concrete")
  for z in range(-26,20,2):
   box(Vector3(side*4.35,.018,z),Vector3(.13,.03,1.9),"ivory")
   box(Vector3(side*4.15,.012,z),Vector3(.21,.02,.8),"dark")
   for i in 6:box(Vector3(side*4.15,.028,z-.33+i*.13),Vector3(.22,.012,.025),"metal")
 collision(Vector3(-6.0,5,-5),Vector3(.5,10,50))
 collision(Vector3(6.0,5,-5),Vector3(.5,10,50))
 collision(Vector3(0,3,20),Vector3(14,6,.5))
 collision(Vector3(0,3,-40),Vector3(20,6,.5))
 # Authored lane markings, inspection covers, tactile paving and discarded paper.
 for z in [13,6,-1,-8,-15,-25,-32]:
  box(Vector3(0,.012,z),Vector3(.08,.025,1.2),"bronze")
 for z in [9,-5,-24]:
  box(Vector3(-1.6,.02,z),Vector3(1.4,.035,1.1),"metal")
  for x in 8:box(Vector3(-2.18+x*.16,.045,z),Vector3(.035,.025,.88),"dark")
 var rng := RandomNumberGenerator.new()
 rng.seed = 71
 for i in 26:
  var p := box(Vector3(rng.randf_range(-4,4),.025,rng.randf_range(-33,18)),Vector3(.14,.008,.22),"ivory")
  p.rotation.y = rng.randf()*TAU
func _architecture() -> void:
 for side in [-1.0,1.0]:
  var angle := PI*.5 if side<0 else -PI*.5
  for i in 7:
   var z := 15.0-i*6
   model("shutter" if (i+int(side))%3==0 else "facade",Vector3(side*6,0,z),angle)
   # Setbacks, roof parapets and service levels break the repeated silhouette.
   box(Vector3(side*(7.2+(i%2)*.5),15+(i%3)*2,z),Vector3(3.0,10+(i%3)*4,5.85),"concrete")
   for floor_ in 4:
    var y := 11.5+floor_*2.4
    for window in 3:
     var p := Vector3(side*5.68,y,z-1.8+window*1.8)
     box(p,Vector3(.08,1.3,1.05),"amber" if (floor_+window+i)%7==0 else "glass")
   model("hvac",Vector3(side*5.55,4.4,z+1.35),angle)
   if i%2==0:model("hvac",Vector3(side*5.55,7.2,z-1.2),angle)
   for y in [10.2,12.1]:pipe([Vector3(side*5.9,y,z-3),Vector3(side*5.9,y,z+3)],.09)
 # Skybridge and suspended utilities frame the amber reveal.
 box(Vector3(0,10,-17),Vector3(12,1.1,2.4),"metal")
 for x in range(-5,6):
  box(Vector3(x,10.9,-16),Vector3(.09,1.8,.09),"bronze")
  box(Vector3(x,10.9,-18),Vector3(.09,1.8,.09),"bronze")
 pipe([Vector3(-6,11.7,-16),Vector3(6,11.7,-16)],.045)
 for z in [11,1,-10]:
  for strand in 3:
   var points: Array[Vector3] = []
   for i in 13:
    var x := -6.0+i
    points.append(Vector3(x,7.4+strand*.18-(1-pow(x/6,2))*1.2,z+strand*.2))
   pipe(points,.018,"dark")
 neon("KASUMI",Vector3(-4.85,3.1,10),"cyan",PI*.5,60)
 neon("NOODLES / 24",Vector3(4.8,3.1,2.5),"amber",-PI*.5,43)
 neon("MEMORY EXCHANGE",Vector3(-4.8,3.3,-7),"violet",PI*.5,38)
 neon("TRANSIT 09",Vector3(0,4.9,-19.9),"red",0,52)
 # Street-facing blade signs are legible as compositions from the entrance.
 neon("H O T E L",Vector3(-3.7,5.4,-2),"cyan",0,42)
 neon("OPEN",Vector3(3.5,4.1,-9),"amber",0,55)
 label("SECTOR 09    /    KASUMI PASSAGE",Vector3(0,6.3,-19.8),28,Color("c0b4a0"))
 gate = model("gate",Vector3(0,0,-20))
 gate_collision = collision(Vector3(0,2,-20),Vector3(5.3,4,.7))
 collision(Vector3(-4.7,2,-20),Vector3(3.7,4,.7))
 collision(Vector3(4.7,2,-20),Vector3(3.7,4,.7))
func _details() -> void:
 model("stall",Vector3(4.5,0,1.5),-PI*.5)
 model("stall",Vector3(-4.6,0,-11),PI*.5)
 for p in [Vector3(-4.9,0,15),Vector3(-4.5,0,14.2),Vector3(4.9,0,-4),Vector3(-5,0,-14)]:
  model("crate",p,.15)
  collision(p+Vector3(0,.45,0),Vector3(1,.9,.8))
 for z in [16,7,-4,-15,-26,-35]:
  for x in [-3.6,3.6]:
   box(Vector3(x,.32,z),Vector3(.12,.64,.12),"metal")
   box(Vector3(x,.62,z),Vector3(.14,.07,.14),"amber")
 for record in [["key",Vector3(-4.2,0,6),PI*.5],["power",Vector3(4.35,0,-10),-PI*.5],["gate",Vector3(-3.3,0,-18.2),0.0],["receiver",Vector3(0,0,-35),0.0]]:
  var n := model("terminal",record[1],record[2])
  terminals[record[0]] = n
  collision(record[1]+Vector3(0,.8,0),Vector3(.85,1.6,.65))
  light(record[1]+Vector3(0,1.6,.4),Color("6fced1"),1.2,3)
 label("RELAY / 02",Vector3(4.15,2.2,-10),23,Color("a2dce0"),-PI*.5)
 label("PRIVATE UPLINK",Vector3(0,2.2,-35),23,Color("ffd0a1"))
 for z in [13,1,-11,-26]:
  var c := Color("60b5c7") if z>4 else Color("eea066")
  var l := light(Vector3(-3,4,z),c,3.0,8.5,true)
  lamps.append(l)
  box(Vector3(-3,4.5,z),Vector3(.5,.12,.8),"metal")
  box(Vector3(-3,4.42,z),Vector3(.38,.04,.65),"white")
  pipe([Vector3(-6,5,z),Vector3(-3,5,z),Vector3(-3,4.5,z)],.06)
 light(Vector3(3,3,-7),Color("a66d9f"),1.3,7)
 # A projecting service canopy visibly covers the entire crouch shelter.
 box(Vector3(4.5,3.15,-10),Vector3(3,.09,4.4),"metal")
 box(Vector3(3.05,3.08,-10),Vector3(.04,.04,4),"amber")
 pipe([Vector3(5.8,3.9,-8),Vector3(3.1,3.15,-8)],.035)
 pipe([Vector3(5.8,3.9,-12),Vector3(3.1,3.15,-12)],.035)
 # A yellow wall pipe and cable cabinets distinguish the relay shelter.
 pipe([Vector3(5.5,.2,-7.7),Vector3(5.5,2.5,-7.7),Vector3(5.5,2.5,-13)],.14,"bronze")
 box(Vector3(5.65,1.4,-11.7),Vector3(.4,1.4,.85),"metal")
 for z in [-11.9,-11.6]:box(Vector3(5.39,1.55,z),Vector3(.02,.08,.08),"red")
 drone = model("drone",Vector3(0,4,-8))
 drone.visible = false
 drone_light = SpotLight3D.new()
 drone_light.light_color = Color("fa7062")
 drone_light.light_energy = 7
 drone_light.spot_range = 10
 drone_light.spot_angle = 27
 drone_light.shadow_enabled = true
 drone_light.rotation_degrees.x = -65
 drone_light.light_volumetric_fog_energy = 2
 drone.add_child(drone_light)
func _beyond() -> void:
 # Monumental turbine sun, built as nested rings and radial vanes rather than a cube.
 var center := Vector3(0,13,-61)
 for ring in [[8.6,.65,"metal"],[7.8,.35,"bronze"],[7.25,.12,"amber"],[6.6,.08,"amber"]]:
  var n := MeshInstance3D.new()
  var m := TorusMesh.new()
  m.inner_radius = ring[0]-ring[1]
  m.outer_radius = ring[0]+ring[1]
  m.rings = 96
  m.ring_segments = 16
  n.mesh = m
  n.material_override = _materials[ring[2]]
  n.position = center
  n.rotation.x = PI*.5
  add_child(n)
 var disc := MeshInstance3D.new()
 var circle := CylinderMesh.new()
 circle.top_radius = 6.45
 circle.bottom_radius = 6.45
 circle.height = .2
 circle.radial_segments = 96
 disc.mesh = circle
 var sun_surface := ShaderMaterial.new()
 sun_surface.shader = load("res://scripts/reactor.gdshader")
 disc.material_override = sun_surface
 disc.position = center+Vector3(0,0,-.5)
 disc.rotation.x = PI*.5
 add_child(disc)
 for i in 32:
  var a := i*TAU/32
  var n := box(center+Vector3(sin(a)*7.8,cos(a)*7.8,.35),Vector3(.16,1.5,.6),"metal")
  n.rotation.z = -a
 for side in [-1,1]:
  box(Vector3(side*10,10,-60),Vector3(3,23,6),"concrete")
  for i in 8:box(Vector3(side*10,2+i*2.6,-56.9),Vector3(3.3,.22,.3),"metal")
 light(Vector3(0,13,-51),Color("ff8f37"),12,38)
 light(Vector3(0,5,-34),Color("dc8958"),2.4,16)
 var fog := FogVolume.new()
 fog.position = Vector3(0,12,-52)
 fog.size = Vector3(70,35,35)
 var material := FogMaterial.new()
 material.density = .055
 material.albedo = Color("d79562")
 material.emission = Color("c26828")
 fog.material = material
 add_child(fog)
 _fog = fog
 # A service balcony with rail, pipes and distant skyline behind the final terminal.
 for side in [-1.0,1.0]:
  collision(Vector3(side*5,2,-32),Vector3(.3,4,16))
  for z in range(-39,-24,2):box(Vector3(side*5,.65,z),Vector3(.08,1.3,.08),"metal")
  pipe([Vector3(side*5,1.3,-39),Vector3(side*5,1.3,-24)],.045)
 for x in range(-30,31,7):
  if abs(x)<10: continue
  var height: float = 24.0+abs(x%13)*1.6
  box(Vector3(x,height*.5,-65-abs(x%9)),Vector3(5,height,8),"dark")
  for y in range(4,int(height)-2,3):
   box(Vector3(x,y,-60.8-abs(x%9)),Vector3(3.8,.13,.02),"amber" if y%3==0 else "cyan")
func _weather() -> void:
 var rain := CPUParticles3D.new()
 rain.name = "Rain"
 rain.amount = 1100
 rain.lifetime = 2.5
 rain.preprocess = 2.5
 rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
 rain.emission_box_extents = Vector3(5,0.2,29)
 rain.position = Vector3(0,12,-9)
 rain.direction = Vector3(-.1,-1,0)
 rain.spread = 3
 rain.gravity = Vector3(0,-2,0)
 rain.initial_velocity_min = 8
 rain.initial_velocity_max = 11
 var mesh := QuadMesh.new()
 mesh.size = Vector2(.012,.25)
 var m := StandardMaterial3D.new()
 m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 m.albedo_color = Color(.55,.72,.8,.19)
 m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 mesh.material = m
 rain.mesh = mesh
 add_child(rain)
 for at in [Vector3(-3.9,.2,3),Vector3(3.9,.2,-13),Vector3(-3.6,.2,-27)]:
  var steam := FogVolume.new()
  steam.position = at+Vector3.UP*.8
  steam.size = Vector3(1.7,2.5,2.8)
  steam.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
  var fm := FogMaterial.new()
  fm.density = .15
  fm.albedo = Color("92aeb3")
  steam.material = fm
  add_child(steam)
func set_gate_open(value: bool) -> void:
 gate_open = value
 gate_collision.collision_layer = 1
func set_quality(high: bool) -> void:
 environment.ssr_enabled = high
 environment.ssao_enabled = high
 environment.volumetric_fog_enabled = high
 for lamp in lamps: lamp.shadow_enabled = high
func _process(delta: float) -> void:
 _time += delta
 gate.position.y = move_toward(gate.position.y,4.5 if gate_open else 0.0,delta*1.4)
 gate_collision.collision_layer = 0 if gate.position.y > 2.1 else 1
 if scan_active:
  drone.visible = true
  drone.position = Vector3(sin(_time*.45)*2.7,3.8+sin(_time)*.1,-10+cos(_time*.45)*3)
  drone.rotation.y = sin(_time*.45)*.4
 else:
  drone.visible = false
 if lamps.size()>1:lamps[1].light_energy = 2.9+sin(_time*7)*.07+sin(_time*13)*.03

func _finishing_details() -> void:
 # One local reflection capture complements SSR at screen edges and under awnings.
 var probe := ReflectionProbe.new()
 probe.position = Vector3(0,3,-7)
 probe.size = Vector3(15,12,58)
 probe.origin_offset = Vector3(0,-1,0)
 probe.box_projection = true
 probe.interior = false
 probe.intensity = .85
 probe.max_distance = 90
 probe.mesh_lod_threshold = 2
 probe.update_mode = ReflectionProbe.UPDATE_ONCE
 add_child(probe)
 # Vertical shop blades and layered advertising interrupt the horizontal canopy rhythm.
 var sign := Node3D.new()
 sign.position = Vector3(3.7,5.7,5)
 add_child(sign)
 box(Vector3.ZERO,Vector3(.95,3.5,.22),"metal",false,sign)
 box(Vector3(-.49,0,.13),Vector3(.035,3.25,.04),"red",false,sign)
 var vertical := label("R\nA\nM\nE\nN",Vector3(3.7,5.7,5.15),36,Color("e98e70"))
 vertical.line_spacing = -2
 label("HOT BROTH / LATE NIGHTS",Vector3(3.5,2.3,2),20,Color("c8b99d"),-PI*.5)
 neon("DREAM ARCHIVE",Vector3(-3.8,4.0,-12),"violet",0,27)
 # Advertising lightbox: dense typography on a framed wall panel.
 var ad := Node3D.new()
 ad.position = Vector3(-5.42,1.9,12)
 ad.rotation.y = PI*.5
 add_child(ad)
 box(Vector3.ZERO,Vector3(1.25,2.05,.12),"metal",false,ad)
 box(Vector3(0,0,.08),Vector3(1.08,1.88,.025),"dark",false,ad)
 label("REMEMBER\nTOMORROW",Vector3(-5.3,2.33,12),21,Color("c1dad9"),PI*.5)
 label("MEMORY CARE\n09 — 24 HOURS",Vector3(-5.3,1.38,12),13,Color("6fb6be"),PI*.5)
 # Thin circular emblem in the advertising panel.
 var emblem := MeshInstance3D.new()
 var ring := TorusMesh.new()
 ring.inner_radius = .28
 ring.outer_radius = .295
 ring.rings = 48
 ring.ring_segments = 8
 emblem.mesh = ring
 emblem.material_override = _materials["cyan"]
 emblem.position = Vector3(-5.3,1.85,12)
 emblem.rotation.z = PI*.5
 add_child(emblem)
 # A sloped cloth awning over the tea stall and a warm pool below it.
 var awning := box(Vector3(-4.4,2.85,-11),Vector3(2.8,.06,3.3),"bronze")
 awning.rotation.z = .12
 for z in [-12.4,-11.8,-11.2,-10.6,-10]:
  pipe([Vector3(-5.7,2.98,z),Vector3(-3.15,2.67,z)],.018,"dark")
 light(Vector3(-4.4,2.3,-11),Color("f0ab73"),1.2,4)
 # Narrow volumetric shafts from practical spot fixtures.
 for at in [Vector3(-4,6,7),Vector3(4,6,-13)]:
  var spot := SpotLight3D.new()
  spot.position = at
  spot.rotation_degrees = Vector3(-67,20 if at.x<0 else -20,0)
  spot.light_color = Color("84bdcf") if at.x<0 else Color("d69e83")
  spot.light_energy = 3
  spot.light_volumetric_fog_energy = 2
  spot.spot_range = 13
  spot.spot_angle = 32
  spot.shadow_enabled = true
  add_child(spot)

 light(Vector3(4.3,2.4,12),Color("e9a66e"),1.8,6)
