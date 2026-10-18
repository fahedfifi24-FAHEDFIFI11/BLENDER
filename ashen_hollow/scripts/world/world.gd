extends Node3D
## The authored Hollow: a woodland road, shuttered village and forgotten sanctuary.
## Units are meters. Structural collision is independent of the decorative mesh batches.

var spawn_point := Vector3(0, 0.2, 23)
var shrine_position := Vector3(0, 0, -22)
var arena_position := Vector3(0, 0, -35)
var _rng := RandomNumberGenerator.new()
var _m: Dictionary = {}
var _batches: Dictionary = {}
var _shrine_light: OmniLight3D
var _shrine_rune: MeshInstance3D
var _flames: Array[MeshInstance3D] = []
var _time := 0.0

func _ready() -> void:
	_rng.seed = 129450
	_materials()
	_lighting()
	_ground()
	_village()
	_woodland()
	_ruins()
	_story_props()
	_scenery()
	_flush_batches()
	_weather()

func get_region_name(pos: Vector3) -> String:
	if pos.z > 12: return "THE WIDOW'S ROAD"
	if pos.z > -15: return "ASHEN HOLLOW"
	if pos.z > -28: return "THE FORGOTTEN SHRINE"
	return "THE HOLLOW COURT"

func get_interaction_position() -> Vector3:
	return shrine_position

func set_shrine_awakened(value: bool) -> void:
	if is_instance_valid(_shrine_light):
		_shrine_light.light_color = Color("b2e2d0") if value else Color("7b99c2")
		_shrine_light.light_energy = 3.2 if value else 1.3
	if is_instance_valid(_shrine_rune):
		_shrine_rune.material_override = _m["rune_awake"] if value else _m["rune"]

func _process(delta: float) -> void:
	_time += delta
	for i in _flames.size():
		var flame: MeshInstance3D = _flames[i]
		flame.scale.y = 0.92 + 0.12 * sin(_time * 6.1 + i * 2.1)

func _mat(key: String, color: Color, texture: String = "", scale_uv: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.93
	if not texture.is_empty():
		mat.albedo_texture = load("res://assets/textures/painted_" + texture + ".png")
		mat.uv1_scale = Vector3.ONE * scale_uv
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_m[key] = mat
	return mat

func _materials() -> void:
	_mat("earth", Color("a4ac8c"), "earth", 28)
	_mat("path", Color("899a9e"), "path", 20)
	_mat("plaster", Color("b8b3a2"), "plaster", 2)
	_mat("plaster_pale", Color("e0d0b7"), "plaster", 2)
	_mat("timber", Color("b1a18f"), "timber", 1.5)
	_mat("door", Color("bca78c"), "timber", 1)
	_mat("slate", Color("abb7c6"), "slate", 2)
	_mat("stone", Color("b7c1bb"), "stone", 1.1)
	_mat("stone_dark", Color("717f7e"), "stone", 1)
	_mat("stone_light", Color("d6d4bd"), "stone", 1)
	_mat("iron", Color("363f44"))
	_mat("moss", Color("626c42"))
	_mat("bark", Color("8a8071"), "timber", 2)
	_mat("leaf", Color("394b41"))
	_mat("leaf_light", Color("536348"))
	_mat("leaf_dark", Color("263b36"))
	_mat("grass", Color("697450"))
	_mat("grass_light", Color("94936a"))
	_mat("burgundy", Color("734b50"))
	_mat("water", Color("30474f"))
	_mat("mountain", Color("364953"))
	_mat("mountain_far", Color("53616a"))
	# Roof and ribbon surfaces remain visible from both sides at steep camera angles.
	for key in ["slate", "plaster", "plaster_pale", "path"]:
		_m[key].cull_mode = BaseMaterial3D.CULL_DISABLED
	for key in ["leaf", "leaf_light", "leaf_dark"]:
		_m[key].albedo_texture = load("res://assets/textures/painted_earth.png")
		_m[key].uv1_scale = Vector3(2.3, 2.3, 2.3)
	for key in ["window", "flame", "rune", "rune_awake"]:
		var color: Color = Color("e4ad60") if key in ["window", "flame"] else Color("85aac8")
		if key == "rune_awake": color = Color("a4dfc9")
		var mat := _mat(key, color)
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8 if key in ["rune", "rune_awake"] else 2.3
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var grass: StandardMaterial3D = _m["grass"]
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var grass_light: StandardMaterial3D = _m["grass_light"]
	grass_light.cull_mode = BaseMaterial3D.CULL_DISABLED

func _lighting() -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "DuskAtmosphere"
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("182a3b")
	sky_mat.sky_horizon_color = Color("6b7b7f")
	sky_mat.ground_bottom_color = Color("20302b")
	sky_mat.ground_horizon_color = Color("6b7b7f")
	sky_mat.sky_curve = 0.22
	sky_mat.sun_angle_max = 5.0
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("91a9b8")
	env.ambient_light_energy = 0.67
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("788e96")
	env.fog_light_energy = 0.55
	env.fog_density = 0.012
	env.fog_height = 0.0
	env.fog_height_density = 0.14
	env.fog_sky_affect = 0.45
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 0.8
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "LastLight"
	sun.rotation_degrees = Vector3(-28, -36, 0)
	sun.light_color = Color("e3c4a1")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 72
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-65, 130, 0)
	fill.light_color = Color("829baf")
	fill.light_energy = 0.24
	add_child(fill)

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: String, collision: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = _m[material]
	node.position = pos
	parent.add_child(node)
	if collision: _box_collision(parent, pos, size)
	return node

func _box_collision(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.position = pos
	body.add_child(col)
	parent.add_child(body)

func _cylinder(parent: Node3D, pos: Vector3, bottom: float, top: float, height: float, material: String, sides: int = 12) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	node.mesh = mesh
	node.material_override = _m[material]
	node.position = pos
	parent.add_child(node)
	return node

func _beam(parent: Node3D, a: Vector3, b: Vector3, width: float, material: String, depth: float = -1) -> MeshInstance3D:
	if depth < 0: depth = width
	var node := _box(parent, (a + b) * 0.5, Vector3(width, a.distance_to(b), depth), material)
	var dir := (b - a).normalized()
	if absf(dir.dot(Vector3.FORWARD)) < 0.98:
		node.basis = Basis.looking_at(dir, Vector3.FORWARD) * Basis(Vector3.RIGHT, PI * 0.5)
	else:
		node.basis = Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
	return node

func _mesh(parent: Node3D, name_: String, vertices: PackedVector3Array, indices: PackedInt32Array, material: String, uvs: PackedVector2Array = PackedVector2Array()) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in vertices.size():
		if uvs.size() == vertices.size(): st.set_uv(uvs[i])
		st.add_vertex(vertices[i])
	for i in indices: st.add_index(i)
	st.generate_normals()
	var n := MeshInstance3D.new()
	n.name = name_
	n.mesh = st.commit()
	n.material_override = _m[material]
	parent.add_child(n)
	return n

func _ground() -> void:
	_box(self, Vector3(0, -0.25, -9), Vector3(54, 0.5, 82), "earth", true).name = "WalkableGround"
	for x in [-27.0, 27.0]: _box_collision(self, Vector3(x, 3, -9), Vector3(0.8, 7, 84))
	for z in [-50.0, 32.0]: _box_collision(self, Vector3(0, 3, z), Vector3(56, 7, 0.8))
	# A hand-shaped road ribbon with gently changing width.
	var verts := PackedVector3Array()
	var uv := PackedVector2Array()
	var inds := PackedInt32Array()
	for i in 81:
		var z := 31.0 - i
		var width := 3.6 if z > 12 else 4.9
		if z < -15: width = 3.4
		if z < -28: width = 8.5
		width += 0.3 * sin(z * 0.7)
		var center := sin(z * 0.15) * 0.45
		verts.append(Vector3(center - width, 0.012, z))
		verts.append(Vector3(center + width, 0.012, z))
		uv.append(Vector2(0, float(i) / 80))
		uv.append(Vector2(1, float(i) / 80))
		if i < 80:
			var j := i * 2
			inds.append_array(PackedInt32Array([j, j + 1, j + 2, j + 1, j + 3, j + 2]))
	_mesh(self, "WindingPilgrimRoad", verts, inds, "path", uv)
	# Individual raised cobbles are a single instanced draw batch per stone tone.
	var pebble := SphereMesh.new()
	pebble.radial_segments = 16
	pebble.rings = 6
	for row in 83:
		var z := 12.5 - row * 0.32
		for col in 19:
			if _rng.randf() < 0.13: continue
			var x := -4.5 + col * 0.49 + (row % 2) * 0.24
			var pos := Vector3(x + _rng.randf_range(-0.04, 0.04), 0.018, z + _rng.randf_range(-0.035, 0.035))
			_batch("cobbles_" + str(col % 3), pebble, ["stone", "stone_dark", "stone_light"][col % 3], Transform3D(Basis.from_euler(Vector3(0, _rng.randf_range(-0.14, 0.14), 0)).scaled(Vector3(0.46, 0.045, 0.29)), pos))
	# The court's concentric, broken stone paving.
	for ring in 8:
		var radius := 1.4 + ring * 0.84
		var count := int(TAU * radius / 0.72)
		for i in count:
			if _rng.randf() < 0.08: continue
			var angle := TAU * float(i) / count
			var position_ := arena_position + Vector3(cos(angle) * radius, 0.026, sin(angle) * radius)
			_batch("arena_stone", pebble, "stone_dark", Transform3D(Basis(Vector3.UP, -angle).scaled(Vector3(0.76, 0.06, 0.58)), position_))

func _roof(parent: Node3D, width: float, depth: float, y: float, height: float) -> void:
	var w := width * 0.5 + 0.55
	var d := depth * 0.5 + 0.55
	var vertices := PackedVector3Array([Vector3(-w,y,-d),Vector3(-w,y,d),Vector3(0,y+height,-d),Vector3(0,y+height,d),Vector3(w,y,-d),Vector3(w,y,d)])
	var uvs := PackedVector2Array([Vector2(0,0),Vector2(0,2),Vector2(1,0),Vector2(1,2),Vector2(0,0),Vector2(0,2)])
	_mesh(parent,"HandLaidSlateRoof",vertices,PackedInt32Array([0,1,2,1,3,2,2,3,4,3,5,4]),"slate",uvs)
	for z in [-d, d]:
		_mesh(parent,"Gable",PackedVector3Array([Vector3(-width*.5,y,z*.9),Vector3(width*.5,y,z*.9),Vector3(0,y+height,z*.9)]),PackedInt32Array([0,2,1] if z < 0 else [0,1,2]),"plaster")
		_beam(parent,Vector3(-w,y,z),Vector3(0,y+height,z),0.18,"timber")
		_beam(parent,Vector3(w,y,z),Vector3(0,y+height,z),0.18,"timber")
		_beam(parent,Vector3(0,y,z),Vector3(0,y+height-.1,z),0.14,"timber")
		_beam(parent,Vector3(-w*.52,y,z),Vector3(0,y+height*.63,z),0.12,"timber")
		_beam(parent,Vector3(w*.52,y,z),Vector3(0,y+height*.63,z),0.12,"timber")
	_beam(parent,Vector3(0,y+height+.03,-d-.1),Vector3(0,y+height+.03,d+.1),0.22,"timber")
	for x in [-w,w]: _beam(parent,Vector3(x,y,-d),Vector3(x,y,d),0.17,"timber")

func _window(parent: Node3D, pos: Vector3, width: float = 0.9, height: float = 1.25, lit: bool = true) -> void:
	_box(parent,pos,Vector3(width+.22,height+.22,.16),"timber")
	_box(parent,pos+Vector3(0,0,.09),Vector3(width,height,.02),"window" if lit else "iron")
	_box(parent,pos+Vector3(0,0,.12),Vector3(.085,height,.06),"timber")
	_box(parent,pos+Vector3(0,.05,.12),Vector3(width,.075,.06),"timber")
	_box(parent,pos+Vector3(0,-height*.5-.1,.15),Vector3(width+.4,.12,.32),"stone")
	for side in [-1.0,1.0]:
		var shutter := _box(parent,pos+Vector3(side*(width*.5+.29),0,.1),Vector3(.34,height+.07,.08),"door")
		shutter.rotation_degrees.y = side * 16

func _house(position_: Vector3, width: float, depth: float, height: float, angle: float, lighted: bool, variant: int) -> void:
	var h := Node3D.new()
	h.name = "TimberHouse_%d" % variant
	h.position = position_
	h.rotation.y = angle
	add_child(h)
	_box(h,Vector3(0,.35,0),Vector3(width+.18,.7,depth+.18),"stone",true)
	_box(h,Vector3(0,height*.5+.35,0),Vector3(width,height-.3,depth),"plaster_pale" if variant%2 else "plaster",true)
	var front := depth*.5+.05
	for y in [.78, height*.51, height]:
		_box(h,Vector3(0,y,front),Vector3(width+.15,.18,.2),"timber")
		_box(h,Vector3(0,y,-front),Vector3(width+.15,.18,.2),"timber")
		for x in [-width*.5,width*.5]: _box(h,Vector3(x,y,0),Vector3(.2,.18,depth),"timber")
	for x in [-width*.5,-width*.25,0.0,width*.25,width*.5]:
		_box(h,Vector3(x,height*.5+.35,front),Vector3(.19,height-.3,.2),"timber")
		_box(h,Vector3(x,height*.5+.35,-front),Vector3(.19,height-.3,.2),"timber")
	for side in [-1.0,1.0]:
		var x: float = side*width*.5
		for z in [-depth*.5,0.0,depth*.5]: _box(h,Vector3(x,height*.5+.35,z),Vector3(.2,height-.3,.19),"timber")
		_beam(h,Vector3(x,.9,-depth*.4),Vector3(x,height*.48,-.15),.13,"timber")
		_beam(h,Vector3(x,height*.54,.15),Vector3(x,height-.15,depth*.4),.13,"timber")
		_beam(h,Vector3(side*width*.49,height*.53,front+.02),Vector3(side*width*.27,height-.12,front+.02),.13,"timber")
	# Broad plank door with wrought straps and an amber transom.
	_box(h,Vector3(0,1.25,front+.06),Vector3(1.12,2.1,.12),"timber")
	_box(h,Vector3(0,1.2,front+.15),Vector3(.9,1.9,.07),"door")
	for y in [.65,1.65]: _box(h,Vector3(0,y,front+.2),Vector3(.85,.08,.04),"iron")
	_box(h,Vector3(.3,1.2,front+.22),Vector3(.07,.15,.07),"iron")
	_box(h,Vector3(0,.09,front+.35),Vector3(1.5,.18,.7),"stone",true)
	_window(h,Vector3(-width*.29,1.7,front+.06),.77,1.2,lighted)
	_window(h,Vector3(width*.29,1.7,front+.06),.77,1.2,lighted and variant%2==0)
	if height > 3.7:
		for x in [-width*.25,width*.25]: _window(h,Vector3(x,height*.75,front+.06),.8,1.1,lighted)
	_roof(h,width,depth,height,height*.49)
	# Painted masonry chimney with a deep soot cap.
	_box(h,Vector3(width*.28,height+height*.38,-depth*.18),Vector3(.75,2.5,.85),"stone",true)
	_box(h,Vector3(width*.28,height+height*.38+1.2,-depth*.18),Vector3(.94,.2,1.04),"stone_dark")
	for y in range(4): _box(h,Vector3(width*.28,height+y*.42,-depth*.18+.43),Vector3(.75,.025,.015),"stone_dark")
	if lighted:
		_lantern(h,Vector3(-1.1,2.5,front+.55),false)
	# Eroded steps and weeds soften the building's foot.
	for i in 9:
		var x := _rng.randf_range(-width*.5,width*.5)
		_rock(position_+Basis(Vector3.UP,angle)*Vector3(x,.07,front+.5),Vector3(.3,.17,.25),"stone_dark")

func _village() -> void:
	_house(Vector3(-9.5,0,7),6.4,6.3,4.4,PI*.48,true,0)
	_house(Vector3(10.4,0,3),7.3,7.8,5.2,-PI*.49,true,1)
	_house(Vector3(-10.1,0,-5.6),6.8,7.2,4.8,PI*.53,false,2)
	_house(Vector3(11.2,0,-9.5),6.5,6.3,4.1,-PI*.52,true,3)
	_house(Vector3(-19,0,-12),5.2,5.7,3.5,.15,false,4)
	_house(Vector3(21.2,0,16),5.4,5.5,3.7,-.4,false,5)
	# The empty inn's hanging crest, a warm point of recognition in the mist.
	var sign := Node3D.new()
	sign.position = Vector3(6.1,0,6)
	add_child(sign)
	_beam(sign,Vector3(0,0,0),Vector3(0,3.7,0),.17,"timber")
	_beam(sign,Vector3(0,3.5,0),Vector3(-1.1,3.5,0),.15,"timber")
	_box(sign,Vector3(-.7,2.98,0),Vector3(.78,.74,.12),"door")
	var crest := _cylinder(sign,Vector3(-.7,3,.075),.23,.23,.02,"stone_light",16)
	crest.rotation_degrees.x=90
	_box(sign,Vector3(-.7,3.0,.1),Vector3(.06,.32,.02),"burgundy")
	# Village well off the main combat corridor.
	var well := Node3D.new()
	well.position=Vector3(-6.2,0,-.4)
	add_child(well)
	for layer in 3:
		for i in 12:
			var a:=TAU*(i+float(layer%2)*.5)/12
			var b:=_box(well,Vector3(cos(a)*1.0,.2+layer*.31,sin(a)*1.0),Vector3(.5,.3,.35),"stone")
			b.rotation.y=-a+PI*.5
	_cylinder(well,Vector3(0,.18,0),.8,.8,.06,"water",24)
	for x in [-1.2,1.2]: _box(well,Vector3(x,1.6,0),Vector3(.18,3.2,.2),"timber",true)
	_beam(well,Vector3(-1.3,2.7,0),Vector3(1.3,2.7,0),.16,"timber")
	_roof(well,2.9,1.7,3.0,.8)
	_box_collision(well,Vector3(0,.55,0),Vector3(2.0,1.1,2.0))
	# Broken fences frame side yards while leaving all encounters open.
	for side in [-1.0,1.0]:
		_fence(Vector3(side*17.0,0,9),Vector3(side*17.0,0,-7),7)
		_fence(Vector3(side*6.1,0,10),Vector3(side*16.5,0,10),6)
	for pos in [Vector3(-4.9,0,13),Vector3(5.2,0,-1),Vector3(-5.3,0,-12)]: _lantern(self,pos+Vector3(0,3.1,0),true)

func _fence(a: Vector3,b: Vector3,count: int) -> void:
	for i in count+1:
		var p:=a.lerp(b,float(i)/count)
		_box(self,p+Vector3(0,.65,0),Vector3(.14,1.3,.14),"timber")
		if i<count and i!=count/2:
			var q:=a.lerp(b,float(i+1)/count)
			_beam(self,p+Vector3(0,.95,0),q+Vector3(0,.92,0),.1,"timber")
			_beam(self,p+Vector3(0,.47,0),q+Vector3(0,.5,0),.1,"timber")

func _lantern(parent: Node3D,pos: Vector3,post: bool) -> void:
	if post:
		_box(parent,Vector3(pos.x,pos.y*.5,pos.z),Vector3(.16,pos.y,.16),"timber")
		_beam(parent,pos+Vector3(0,.06,0),pos+Vector3(.55,.06,0),.12,"iron")
		pos+=Vector3(.5,-.38,0)
	_box(parent,pos,Vector3(.21,.36,.21),"flame")
	for y in [-.21,.21]: _box(parent,pos+Vector3(0,y,0),Vector3(.34,.08,.34),"iron")
	for x in [-.14,.14]:
		for z in [-.14,.14]: _box(parent,pos+Vector3(x,0,z),Vector3(.035,.4,.035),"iron")
	_cylinder(parent,pos+Vector3(0,.33,0),.26,.06,.2,"iron",4)
	var light:=OmniLight3D.new()
	light.position=pos+Vector3(0,0,.2)
	light.light_color=Color("ffba71")
	light.light_energy=1.7
	light.omni_range=6.8
	light.omni_attenuation=1.5
	light.shadow_enabled=false
	parent.add_child(light)

func _batch(key: String, mesh: Mesh, material: String, transform_: Transform3D) -> void:
	if not _batches.has(key): _batches[key]={"mesh":mesh,"mat":material,"items":[]}
	_batches[key]["items"].append(transform_)

func _flush_batches() -> void:
	for key in _batches:
		var data: Dictionary=_batches[key]
		var mm:=MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=data["mesh"]
		mm.instance_count=data["items"].size()
		for i in mm.instance_count: mm.set_instance_transform(i,data["items"][i])
		var node:=MultiMeshInstance3D.new()
		node.name=key
		node.multimesh=mm
		node.material_override=_m[data["mat"]]
		add_child(node)
	_batches.clear()

func _rock(pos: Vector3,size: Vector3,material: String="stone") -> void:
	var mesh:=SphereMesh.new()
	mesh.radial_segments=7
	mesh.rings=3
	_batch("rocks_"+material,mesh,material,Transform3D(Basis.from_euler(Vector3(_rng.randf_range(-.2,.2),_rng.randf()*TAU,.1)).scaled(size),pos))

func _tree(pos: Vector3,height: float,variant: int) -> void:
	var lean:=Vector3(_rng.randf_range(-.5,.5),0,_rng.randf_range(-.4,.4))
	var trunk:=Node3D.new()
	trunk.position=pos
	add_child(trunk)
	var radius:=height*.035
	var cylinder:=CylinderMesh.new()
	cylinder.bottom_radius=1
	cylinder.top_radius=.65
	cylinder.height=1
	cylinder.radial_segments=9
	var basis:=Basis.from_euler(Vector3(lean.z*.07,0,lean.x*.07)).scaled(Vector3(radius,height*.73,radius))
	_batch("TreeTrunks",cylinder,"bark",Transform3D(basis,pos+Vector3(0,height*.365,0)))
	# Fine buttress roots and angular branching produce distinctive silhouettes.
	for i in 4:
		var a:=i*TAU/4+.3
		_beam(trunk,Vector3(cos(a)*radius*2.3,.04,sin(a)*radius*2.3),Vector3(0,height*.14,0),radius*.45,"bark")
	for i in 5:
		var a:=i*2.4+variant
		var origin:=Vector3(0,height*(.43+i*.055),0)+lean*.4
		var end:=origin+Vector3(cos(a)*height*.22,height*.17,sin(a)*height*.22)
		_beam(trunk,origin,end,radius*.7,"bark")
		_beam(trunk,end,end+Vector3(cos(a+.4)*height*.1,height*.13,sin(a+.4)*height*.1),radius*.35,"bark")
	if variant%6!=0:
		var leafmesh:=SphereMesh.new()
		leafmesh.radial_segments=9
		leafmesh.rings=5
		for i in 10:
			var a:=i*2.399
			var crown:=Vector3(cos(a)*height*.16,height*(.66+(i%3)*.08),sin(a)*height*.16)+lean
			var scale_:=Vector3(height*.35,height*.19,height*.31)*_rng.randf_range(.7,1.1)
			var material: String=["leaf","leaf_dark","leaf_light"][i%3]
			_batch("Canopies_"+material,leafmesh,material,Transform3D(Basis.from_euler(Vector3(.1,a,.12)).scaled(scale_),pos+crown))
	_box_collision(self,pos+Vector3(0,height*.25,0),Vector3(radius*1.6,height*.5,radius*1.6))

func _grass_mesh() -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var a:=i*2.4
		var base:=Vector3(cos(a)*.13,0,sin(a)*.13)
		var tangent:=Vector3(cos(a+PI*.5),0,sin(a+PI*.5))*.055
		var tip:=base+Vector3(cos(a)*.15,.42+(i%3)*.08,sin(a)*.15)
		for v in [base-tangent,tip,base+tangent]: st.add_vertex(v)
	st.generate_normals()
	return st.commit()

func _woodland() -> void:
	for side in [-1.0,1.0]:
		for i in 22:
			var pos:=Vector3(side*_rng.randf_range(6,25),0,_rng.randf_range(12,31))
			_tree(pos,_rng.randf_range(6,11),i)
		for i in 14:
			var pos:=Vector3(side*_rng.randf_range(20,26),0,_rng.randf_range(-44,10))
			_tree(pos,_rng.randf_range(6,10),i+3)
		for z in [-17.0,-26.0,-43.0]: _tree(Vector3(side*14.5,0,z),_rng.randf_range(7,9),0)
	var grassmesh:=_grass_mesh()
	for i in 3200:
		var x:=_rng.randf_range(-26,26)
		var z:=_rng.randf_range(-48,31)
		var road_width:=3.9 if z>12 else 5.2
		if z<-28: road_width=9.2
		if absf(x)<road_width: continue
		# Leave building interiors clean, but grass creeps along their stone foundations.
		var scale_:=_rng.randf_range(.55,1.35)
		_batch("Grass_"+str(i%2),grassmesh,"grass" if i%2==0 else "grass_light",Transform3D(Basis(Vector3.UP,_rng.randf()*TAU).scaled(Vector3(scale_,scale_,scale_)),Vector3(x,.015,z)))
	for i in 100:
		var pos:=Vector3(_rng.randf_range(-25,25),.09,_rng.randf_range(-47,30))
		if absf(pos.x)<5: continue
		_rock(pos,Vector3(_rng.randf_range(.4,1.6),_rng.randf_range(.25,.8),_rng.randf_range(.4,1.2)),"stone_dark")
	# A leaning roadside memorial and a discarded traveler’s bundle.
	var cross:=Node3D.new()
	cross.position=Vector3(-4.7,0,20)
	cross.rotation_degrees.z=-8
	add_child(cross)
	_box(cross,Vector3(0,.7,0),Vector3(.15,1.4,.13),"timber")
	_box(cross,Vector3(0,.95,0),Vector3(.66,.13,.13),"timber")
	_rock(Vector3(-4.7,.12,20),Vector3(.85,.3,.7),"stone_dark")
	_lantern(self,Vector3(4.8,2.9,22),true)

func _pillar(pos: Vector3,height: float,broken: bool = false) -> void:
	_box(self,pos+Vector3(0,.16,0),Vector3(1.4,.32,1.4),"stone",true)
	_box(self,pos+Vector3(0,.42,0),Vector3(1.05,.2,1.05),"stone_light")
	for layer in int(height/.58):
		var block:=_box(self,pos+Vector3(0,.71+layer*.58,0),Vector3(.78,.55,.78),"stone")
		block.rotation.y=_rng.randf_range(-.025,.025)
	_box_collision(self,pos+Vector3(0,height*.5,0),Vector3(.8,height,.8))
	if not broken:
		_box(self,pos+Vector3(0,height+.22,0),Vector3(1.18,.27,1.18),"stone_light")
		_box(self,pos+Vector3(0,height+.44,0),Vector3(1.4,.18,1.4),"stone")
	else:
		var rock:=_box(self,pos+Vector3(.13,height-.05,.05),Vector3(.68,.42,.6),"stone_dark")
		rock.rotation_degrees=Vector3(13,17,9)

func _arch(pos: Vector3,width: float,height: float) -> void:
	for side in [-1.0,1.0]: _pillar(pos+Vector3(side*width*.5,0,0),height,false)
	var radius:=width*.5
	for i in 33:
		var angle:=PI*float(i)/32
		var a:=Vector3(cos(angle)*radius,height+sin(angle)*radius,0)
		var block:=_box(self,pos+a,Vector3(.61,.70,.95),"stone" if i%3 else "stone_light")
		block.rotation.z=angle-PI*.5

func _weather() -> void:
	# A sparse, windblown drizzle complements the height fog without hiding combat.
	var rain := CPUParticles3D.new()
	rain.name = "FineDuskRain"
	rain.amount = 650
	rain.lifetime = 4.0
	rain.preprocess = 3.8
	rain.position = Vector3(0, 11, -8)
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(25, 2, 39)
	rain.direction = Vector3(0.12, -1, 0.04)
	rain.spread = 4.0
	rain.initial_velocity_min = 3.8
	rain.initial_velocity_max = 5.2
	rain.gravity = Vector3(0.25, -0.4, 0)
	rain.local_coords = false
	var drop := BoxMesh.new()
	drop.size = Vector3(0.008, 0.13, 0.008)
	var rain_mat := StandardMaterial3D.new()
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.albedo_color = Color(0.57, 0.69, 0.74, 0.23)
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = rain_mat
	rain.mesh = drop
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rain)

func _ruins() -> void:
	# A broad ruined processional arch leads to the arena without obstructing combat.
	_arch(Vector3(0,0,-27.7),11.6,3.3)
	for x in [-8.2,8.2]:
		_pillar(Vector3(x,0,-19),3.0,true)
		_pillar(Vector3(x,0,-36),4.3,false)
		_pillar(Vector3(x,0,-43),2.4,true)
		for z in [-31.0,-40.0]: _pillar(Vector3(x,0,z),_rng.randf_range(1.4,2.7),true)
	# Broken sanctuary wall: visible joints and uneven, missing masonry courses.
	for side in [-1.0,1.0]:
		for row in 4:
			for i in 8:
				if row>1 and _rng.randf()<.38: continue
				var p:=Vector3(side*11.5,.28+row*.5,-28-i*1.85+(row%2)*.65)
				_box(self,p,Vector3(.85,.46,1.73),"stone_dark",row<2)
		for i in 12:
			_rock(Vector3(side*_rng.randf_range(9.0,12.5),.13,_rng.randf_range(-45,-19)),Vector3(.6,.35,.7),"stone")
	# Central monument: a carved altar holding the long-forgotten oath.
	_cylinder(self,shrine_position+Vector3(0,.12,0),1.7,1.7,.24,"stone_dark",24)
	_cylinder(self,shrine_position+Vector3(0,.31,0),1.35,1.35,.17,"stone",16)
	_cylinder(self,shrine_position+Vector3(0,.61,0),.85,.65,.5,"stone_dark",8)
	_box(self,shrine_position+Vector3(0,.96,0),Vector3(1.6,.2,1.15),"stone_light")
	_box_collision(self,shrine_position+Vector3(0,.5,0),Vector3(1.6,1.0,1.15))
	# A stylized stone sword with a warm metal crossguard.
	_box(self,shrine_position+Vector3(0,1.57,0),Vector3(.13,1.25,.08),"stone_light")
	_box(self,shrine_position+Vector3(0,2.15,0),Vector3(.65,.1,.12),"iron")
	_box(self,shrine_position+Vector3(0,2.39,0),Vector3(.11,.45,.11),"door")
	_shrine_rune=_cylinder(self,shrine_position+Vector3(0,2.69,0),.16,.10,.2,"rune",6)
	_shrine_light=OmniLight3D.new()
	_shrine_light.position=shrine_position+Vector3(0,1.8,.5)
	_shrine_light.omni_range=6.5
	_shrine_light.light_color=Color("7b99c2")
	_shrine_light.light_energy=1.3
	add_child(_shrine_light)
	for i in 8:
		var a:=i*TAU/8
		var rune:=_box(self,shrine_position+Vector3(sin(a)*1.45,.246,cos(a)*1.45),Vector3(.05,.012,.17),"rune")
		rune.rotation.y=a
	for pos in [Vector3(-5.4,0,-22),Vector3(5.4,0,-22),Vector3(-6.6,0,-34),Vector3(6.6,0,-34)]: _brazier(pos)
	# A ruined apse behind the guardian, framing the ending vista.
	for i in 13:
		var a:=PI*float(i)/12
		var x:=cos(a)*9
		var z:=-43-sin(a)*3.5
		for layer in int(2+sin(a)*3):
			var b:=_box(self,Vector3(x,.35+layer*.62,z),Vector3(1.6,.58,.8),"stone_dark",layer<2)
			b.rotation.y=-a+PI*.5

func _brazier(pos: Vector3) -> void:
	_cylinder(self,pos+Vector3(0,.14,0),.52,.45,.28,"stone",8)
	_cylinder(self,pos+Vector3(0,.68,0),.22,.16,.9,"iron",8)
	_cylinder(self,pos+Vector3(0,1.16,0),.2,.43,.22,"iron",10)
	for i in 3:
		var flame:=_cylinder(self,pos+Vector3((i-1)*.13,1.48,0),.14,.015,.54-i*.05,"flame",7)
		_flames.append(flame)
	var light:=OmniLight3D.new()
	light.position=pos+Vector3(0,1.7,0)
	light.light_color=Color("e9a466")
	light.light_energy=2.2
	light.omni_range=7.5
	add_child(light)

func _barrel(pos: Vector3, rotation_: float=0) -> void:
	var b:=Node3D.new()
	b.position=pos
	b.rotation.y=rotation_
	add_child(b)
	_cylinder(b,Vector3(0,.5,0),.36,.36,1,"door",12)
	for y in [.13,.49,.87]: _cylinder(b,Vector3(0,y,0),.373,.373,.065,"iron",12)
	_cylinder(b,Vector3(0,1.01,0),.32,.32,.025,"timber",12)
	_box_collision(b,Vector3(0,.5,0),Vector3(.7,1,.7))

func _story_props() -> void:
	for pos in [Vector3(-6.0,0,3.5),Vector3(-6.7,0,3.8),Vector3(6.9,0,-5.2),Vector3(7.1,0,-6.1)]: _barrel(pos)
	for pos in [Vector3(6.6,.4,1.3),Vector3(-6.3,.4,-9.4)]:
		_box(self,pos,Vector3(.85,.8,.85),"door",true)
		for x in [-.36,.36]: _box(self,pos+Vector3(x,0,.44),Vector3(.07,.78,.04),"timber")
		_beam(self,pos+Vector3(-.4,-.32,.45),pos+Vector3(.4,.32,.45),.09,"timber")
	# An abandoned cart, one wheel tilted into the verge, with torn burgundy covering.
	var cart:=Node3D.new()
	cart.position=Vector3(5.9,0,15.5)
	cart.rotation_degrees=Vector3(0,-12,-6)
	add_child(cart)
	_box(cart,Vector3(0,.65,0),Vector3(1.8,.17,2.4),"door",true)
	for side in [-1.0,1.0]:
		for y in [.9,1.15]: _box(cart,Vector3(side*.87,y,0),Vector3(.1,.2,2.4),"door")
		for z in [-1.1,1.1]: _box(cart,Vector3(side*.87,1.0,z),Vector3(.13,.95,.13),"timber")
		var torus:=TorusMesh.new()
		torus.inner_radius=.44
		torus.outer_radius=.56
		torus.rings=16
		torus.ring_segments=6
		var wheel:=MeshInstance3D.new()
		wheel.mesh=torus
		wheel.material_override=_m["timber"]
		wheel.position=Vector3(side*1.06,.55,.18)
		wheel.rotation_degrees.z=90
		cart.add_child(wheel)
		for i in 6:
			var a:=i*PI/3
			_beam(cart,Vector3(side*1.06,.55,.18),Vector3(side*1.06,.55+cos(a)*.48,.18+sin(a)*.48),.055,"timber")
		_beam(cart,Vector3(side*.65,.65,1.1),Vector3(side*.65,.35,3),.12,"timber")
	_box(cart,Vector3(0,.85,-.2),Vector3(1.5,.18,1.5),"burgundy")
	# A few fallen roof tiles and a cold campfire tell of a recent occupation.
	for i in 15:
		var p:=Vector3(_rng.randf_range(-7,-5.5),.06,_rng.randf_range(-7,-3))
		var tile:=_box(self,p,Vector3(.22,.04,.34),"slate")
		tile.rotation.y=_rng.randf()*TAU
	for i in 9:
		var a:=i*TAU/9
		_rock(Vector3(5.8+sin(a)*.65,.08,-11+cos(a)*.65),Vector3(.3,.2,.28),"stone_dark")
	for i in 4:
		var log:=_cylinder(self,Vector3(5.8,.12,-11),.09,.07,1,"bark",7)
		log.rotation_degrees=Vector3(90,i*43,0)

func _scenery() -> void:
	# Layered mountains and distant towers, intentionally soft and simplified by fog.
	for layer in 2:
		var verts:=PackedVector3Array()
		var inds:=PackedInt32Array()
		for i in 25:
			var x:=-100.0+i*8.5
			var y:=_rng.randf_range(12,27)+layer*7
			var z:=-66.0-layer*30
			verts.append(Vector3(x,-4,z))
			verts.append(Vector3(x,y,z))
			if i<24:
				var j:=i*2
				inds.append_array(PackedInt32Array([j,j+1,j+2,j+1,j+3,j+2]))
		_mesh(self,"DistantRidge",verts,inds,"mountain_far" if layer else "mountain")
	for p in [Vector3(19,0,-28),Vector3(-21,0,-39),Vector3(13,0,-54)]:
		var tower:=Node3D.new()
		tower.position=p
		add_child(tower)
		_box(tower,Vector3(0,5,0),Vector3(3.8,10,3.7),"stone_dark",true)
		_box(tower,Vector3(0,9.9,0),Vector3(4.2,.4,4.1),"stone")
		for x in [-1.6,0.0,1.6]:
			for z in [-1.6,1.6]: _box(tower,Vector3(x,10.6,z),Vector3(.7,1.1,.7),"stone_dark")
		_cylinder(tower,Vector3(0,13,0),2.6,0,5.6,"slate",4).rotation_degrees.y=45
		for y in [5.0,8.0]: _box(tower,Vector3(0,y,1.86),Vector3(.45,1.7,.04),"iron")
		_box(tower,Vector3(0,8,1.9),Vector3(.2,1.3,.02),"window")
	# Drifting seeds / faint drizzle animated in a cheap single MultiMesh shader.
	var weather_mesh:=QuadMesh.new()
	weather_mesh.size=Vector2(.016,.14)
	var weather_shader:=Shader.new()
	weather_shader.code="shader_type spatial; render_mode unshaded, cull_disabled, depth_draw_never; void vertex(){ VERTEX.y += mod(INSTANCE_CUSTOM.x + TIME * 0.6, 6.0) - 3.0; VERTEX.x += sin(TIME * 0.5 + INSTANCE_CUSTOM.y * 9.0) * 0.2; } void fragment(){ ALBEDO=vec3(0.72,0.79,0.79); ALPHA=0.12; }"
	var weather_mat:=ShaderMaterial.new()
	weather_mat.shader=weather_shader
	var mm:=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_custom_data=true
	mm.mesh=weather_mesh
	mm.instance_count=240
	for i in mm.instance_count:
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(_rng.randf_range(-23,23),_rng.randf_range(2,8),_rng.randf_range(-46,30))))
		mm.set_instance_custom_data(i,Color(_rng.randf()*6,_rng.randf(),0,1))
	var weather:=MultiMeshInstance3D.new()
	weather.name="DriftingMistRain"
	weather.multimesh=mm
	weather.material_override=weather_mat
	weather.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(weather)
