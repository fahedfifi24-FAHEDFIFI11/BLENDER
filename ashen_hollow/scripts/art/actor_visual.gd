extends Node3D
## Original modeled actors with layered materials and articulated action choreography.
## Visual-only; physics, damage and action timing belong to the actor controller.

var actor_kind := "player"
var motion := "idle"
var motion_speed := 0.0
var action_phase := 0.0
var attack_variant := "lunge"
var clock := 0.0
var hit_time := 0.0
var dead_visual := false
var death_amount := 0.0
var cloth_tick := 0.0
var body: Node3D
var head: Node3D
var right_arm: Node3D
var left_arm: Node3D
var right_forearm: Node3D
var left_forearm: Node3D
var right_leg: Node3D
var left_leg: Node3D
var right_shin: Node3D
var left_shin: Node3D
var weapon: Node3D
var cloak: MeshInstance3D
var materials: Dictionary = {}
var glow_material: StandardMaterial3D
var flash_material: StandardMaterial3D
var visible_meshes: Array[MeshInstance3D] = []


func configure(kind: String) -> void:
	actor_kind = kind
	for child in get_children():
		remove_child(child)
		child.queue_free()
	visible_meshes.clear()
	materials.clear()
	_make_materials()
	body = _pivot("Articulated body", self, Vector3.ZERO)
	if actor_kind == "creature":
		_build_creature()
	else:
		_build_human()
	set_process(true)


func set_motion(state: String, speed: float, phase: float = 0.0) -> void:
	motion = state
	motion_speed = speed
	action_phase = clampf(phase, 0.0, 1.0)

func set_attack_variant(kind: String) -> void:
	attack_variant = kind


func set_dead(value: bool) -> void:
	dead_visual = value
	if not value:
		death_amount = 0.0
		visible = true


func flash_hit() -> void:
	hit_time = 0.12
	for mesh in visible_meshes:
		mesh.material_overlay = flash_material


func set_facing(angle: float) -> void:
	rotation.y = angle


func _process(delta: float) -> void:
	if not is_instance_valid(body):
		return
	clock += delta
	if hit_time > 0.0:
		hit_time -= delta
		if hit_time <= 0.0:
			for mesh in visible_meshes:
				mesh.material_overlay = null
	_animate(delta)
	if is_instance_valid(cloak):
		cloth_tick += delta
		if cloth_tick >= 0.05:
			cloth_tick = 0.0
			_update_cloak()


func _make_materials() -> void:
	materials["steel"] = _painted(Color("617584"), Color("a6b6b7"), 0.52, 0.68, 17)
	materials["edge"] = _painted(Color("b2c2c8"), Color("dde0cc"), 0.36, 0.80, 29)
	materials["armor"] = _painted(Color("202d32"), Color("435451"), 0.67, 0.52, 11)
	materials["leather"] = _painted(Color("282322"), Color("54443a"), 0.91, 0.06, 34)
	materials["cloth"] = _painted(Color("282d30"), Color("485354"), 0.96, 0.0, 63)
	materials["cloak"] = _painted(Color("30232e"), Color("61433f"), 0.98, 0.0, 83)
	materials["gold"] = _painted(Color("6e5636"), Color("b19b65"), 0.55, 0.58, 99)
	materials["skin"] = _painted(Color("98725b"), Color("c3a081"), 0.98, 0.0, 22)
	materials["hair"] = _painted(Color("262623"), Color("64665c"), 0.96, 0.0, 8)
	materials["bone"] = _painted(Color("6a7063"), Color("bbb49b"), 0.96, 0.0, 52)
	materials["beast"] = _painted(Color("171e22"), Color("384742"), 0.96, 0.0, 71)
	materials["beast_plates"] = _painted(Color("343332"), Color("666253"), 0.88, 0.12, 74)
	materials["bandit"] = _painted(Color("35382d"), Color("646448"), 0.98, 0.0, 72)
	glow_material = StandardMaterial3D.new()
	glow_material.albedo_color = Color("c8e4cd")
	glow_material.emission_enabled = true
	glow_material.emission = Color("83bba5")
	glow_material.emission_energy_multiplier = 1.4
	glow_material.roughness = 0.65
	flash_material = StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_material.albedo_color = Color(1.0, 0.77, 0.54, 0.35)


func _painted(dark: Color, light: Color, roughness: float, metallic: float, seed_value: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.roughness = roughness
	mat.metallic = metallic
	mat.albedo_color = Color.WHITE
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.035
	noise.fractal_octaves = 3
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([dark, light])
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = gradient
	mat.albedo_texture = texture
	return mat


func _pivot(label: String, parent: Node3D, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = label
	parent.add_child(node)
	node.position = at
	return node


func _mesh(label: String, parent: Node3D, source: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = source
	instance.material_override = mat
	parent.add_child(instance)
	instance.position = at
	visible_meshes.append(instance)
	return instance


func _box(label: String, parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var primitive := BoxMesh.new()
	primitive.size = size
	return _mesh(label, parent, primitive, at, mat)


func _ellipsoid(label: String, parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var primitive := SphereMesh.new()
	primitive.radius = 1.0
	primitive.height = 2.0
	primitive.radial_segments = 16
	primitive.rings = 10
	var instance := _mesh(label, parent, primitive, at, mat)
	instance.scale = size
	return instance


func _taper(label: String, parent: Node3D, rings: Array, mat: Material, sides: int = 12) -> MeshInstance3D:
	# Rings store horizontal radius, height, depth radius. Elliptical anatomy avoids capsule silhouettes.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings.size() - 1):
		for i in range(sides):
			var a := TAU * float(i) / float(sides)
			var b := TAU * float(i + 1) / float(sides)
			var lower: Vector3 = rings[r]
			var upper: Vector3 = rings[r + 1]
			var points: Array[Vector3] = [
				Vector3(cos(a) * lower.x, lower.y, sin(a) * lower.z),
				Vector3(cos(b) * lower.x, lower.y, sin(b) * lower.z),
				Vector3(cos(a) * upper.x, upper.y, sin(a) * upper.z),
				Vector3(cos(b) * upper.x, upper.y, sin(b) * upper.z)]
			for k in [0, 2, 1, 1, 2, 3]:
				var u := float(i + (1 if k == 1 or k == 3 else 0)) / float(sides)
				var v := float(r + (1 if k >= 2 else 0)) / float(rings.size() - 1)
				surface.set_uv(Vector2(u, v))
				surface.add_vertex(points[k])
	surface.generate_normals()
	return _mesh(label, parent, surface.commit(), Vector3.ZERO, mat)


func _segment(label: String, parent: Node3D, start: Vector3, end: Vector3, radius: float, end_radius: float, mat: Material, sides: int = 10) -> MeshInstance3D:
	var primitive := CylinderMesh.new()
	primitive.top_radius = end_radius
	primitive.bottom_radius = radius
	primitive.height = start.distance_to(end)
	primitive.radial_segments = sides
	primitive.rings = 1
	var instance := _mesh(label, parent, primitive, (start + end) * 0.5, mat)
	instance.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	return instance


func _build_human() -> void:
	var is_bandit := actor_kind == "bandit"
	var outer: Material = materials["leather"] if is_bandit else materials["armor"]
	_taper("Padded gambeson", body, [Vector3(.14,.86,.10),Vector3(.19,.98,.12),Vector3(.19,1.25,.12),Vector3(.22,1.37,.13),Vector3(.12,1.46,.10)], materials["cloth"])
	_taper("Shaped cuirass", body, [Vector3(.17,1.0,.105),Vector3(.205,1.15,.14),Vector3(.23,1.34,.145),Vector3(.18,1.40,.12),Vector3(.105,1.43,.085)], outer)
	_taper("Broad worn belt", body, [Vector3(.18,.96,.12),Vector3(.19,1.035,.125)], materials["leather"])
	_box("Belt buckle", body, Vector3(.015,.998,-.133),Vector3(.072,.053,.025),materials["gold"])
	_box("Buckle recess", body, Vector3(.015,.998,-.15),Vector3(.046,.027,.008),materials["leather"])
	for side in [-1.0, 1.0]:
		var hip_plate := _taper("Layered hip armour", body,[Vector3(.105,.0,.06),Vector3(.105,-.11,.065),Vector3(.08,-.20,.035)],outer)
		hip_plate.position = Vector3(side * .15,.97,-.075)
		hip_plate.rotation.z = side * .12
		var pectoral := _ellipsoid("Forged breastplate",body,Vector3(side * .10,1.29,-.105),Vector3(.12,.12,.057),outer)
		pectoral.rotation.z = side * -.16
		for y in [1.14,1.21,1.37]:
			_ellipsoid("Brass armour rivet", body, Vector3(side*.17,y,-.11),Vector3(.012,.012,.007),materials["gold"])
	# Diagonal baldric and a sheathed secondary knife enrich the silhouette.
	var baldric := _box("Diagonal leather baldric",body,Vector3(-.012,1.22,-.155),Vector3(.050,.45,.024),materials["leather"])
	baldric.rotation.z = -.53
	_box("Strap clasp",body,Vector3(.055,1.34,-.173),Vector3(.062,.046,.017),materials["gold"]).rotation.z = -.53
	var pouch := _ellipsoid("Travel pouch", body, Vector3(-.20,.92,.02),Vector3(.075,.105,.065),materials["leather"])
	pouch.rotation.z = -.14
	_box("Pouch flap",body,Vector3(-.20,.96,-.035),Vector3(.12,.075,.018),materials["leather"])
	_ellipsoid("Pouch stud",body,Vector3(-.20,.94,-.05),Vector3(.009,.009,.006),materials["gold"])
	_build_limbs(false)
	_build_head(is_bandit)
	weapon = _pivot("Sword hand socket", right_forearm, Vector3(0,-.27,-.018))
	_build_sword(weapon, is_bandit)
	var scabbard := _pivot("Back scabbard",body,Vector3(-.12,1.25,.19))
	scabbard.rotation.z = -.32
	_segment("Leather sword sheath",scabbard,Vector3(0,-.68,0),Vector3(0,.31,0),.027,.033,materials["leather"],8)
	_segment("Sheath metal tip",scabbard,Vector3(0,-.7,0),Vector3(0,-.61,0),.023,.03,materials["steel"],8)
	_segment("Travel blade grip",scabbard,Vector3(0,.35,0),Vector3(0,.52,0),.022,.021,materials["leather"],8)
	_box("Travel blade crossguard",scabbard,Vector3(0,.32,0),Vector3(.15,.025,.045),materials["gold"])
	_ellipsoid("Travel blade pommel",scabbard,Vector3(0,.54,0),Vector3(.035,.035,.024),materials["steel"])
	cloak = MeshInstance3D.new()
	cloak.name = "Wind touched weathered cloak"
	body.add_child(cloak)
	var cloth_material: StandardMaterial3D = (materials["bandit"] if is_bandit else materials["cloak"]).duplicate()
	cloth_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cloak.material_override = cloth_material
	visible_meshes.append(cloak)
	_update_cloak()
	for side in [-1.0,1.0]:
		_ellipsoid("Cloak collar folds",body,Vector3(side*.11,1.425,.045),Vector3(.17,.065,.14),materials["bandit"] if is_bandit else materials["cloak"])
		_ellipsoid("Cloak clasp",body,Vector3(side*.085,1.44,-.095),Vector3(.02,.02,.012),materials["gold"])


func _build_limbs(beast: bool) -> void:
	var shoulder_y := 1.58 if beast else 1.38
	var shoulder_x := .32 if beast else .245
	var upper_len := .39 if beast else .275
	var lower_len := .37 if beast else .26
	var outer: Material = materials["beast"] if beast else materials["leather"]
	var armor: Material = materials["beast_plates"] if beast else materials["armor"]
	if actor_kind == "bandit":
		armor = materials["leather"]
	for side in [-1.0,1.0]:
		var arm := _pivot("Left shoulder" if side < 0 else "Right shoulder",body,Vector3(side*shoulder_x,shoulder_y,0))
		_taper("Upper arm",arm,[Vector3(.075,.035,.075),Vector3(.09,-.07,.075),Vector3(.065,-upper_len,.06)],outer)
		var forearm := _pivot("Elbow",arm,Vector3(0,-upper_len,0))
		_taper("Sculpted vambrace",forearm,[Vector3(.065,.035,.06),Vector3(.075,-.06,.07),Vector3(.055,-lower_len+.02,.05)],armor)
		_ellipsoid("Gauntlet",forearm,Vector3(0,-lower_len,0),Vector3(.065,.075,.06),outer)
		if beast:
			for finger in range(4):
				var x := (float(finger)-1.5)*.026
				_segment("Long talon",forearm,Vector3(x,-lower_len-.02,-.015),Vector3(x*1.2,-lower_len-.19,-.07),.013,.002,materials["bone"],6)
			for index in range(3):
				_segment("Shoulder spine",arm,Vector3(side*.04,-float(index)*.05,.03),Vector3(side*(.15+float(index)*.025),.13-float(index)*.07,.09),.043,.003,materials["beast_plates"],7)
		else:
			_ellipsoid("Shoulder pauldron",arm,Vector3(side*.015,.002,.0),Vector3(.125,.11,.115),armor)
			_ellipsoid("Pauldron lower lames",arm,Vector3(side*.017,-.065,.0),Vector3(.115,.065,.11),armor)
			for j in range(3):
				_taper("Bracer lames",forearm,[Vector3(.071,-.035-float(j)*.055,.071),Vector3(.064,-.052-float(j)*.055,.065)],materials["steel"] if actor_kind == "player" else materials["gold"],10)
		var leg := _pivot("Left hip" if side < 0 else "Right hip",body,Vector3(side*(.16 if beast else .105),.99 if beast else .88,.025))
		var thigh_len := .43 if beast else .38
		var shin_len := .43 if beast else .36
		_taper("Thigh",leg,[Vector3(.11,.02,.115),Vector3(.10,-.12,.105),Vector3(.071,-thigh_len,.073)],outer)
		var shin := _pivot("Knee",leg,Vector3(0,-thigh_len,0))
		_taper("Shin greave",shin,[Vector3(.078,.01,.08),Vector3(.082,-.10,.08),Vector3(.055,-shin_len,.055)],armor)
		_ellipsoid("Knee guard",shin,Vector3(0,.01,-.065),Vector3(.085,.087,.045),armor)
		var boot := _taper("Boot with shaped toe",shin,[Vector3(.064,-shin_len+.08,.07),Vector3(.075,-shin_len-.02,.12),Vector3(.076,-shin_len-.09,.13)],outer)
		boot.position.z = -.035
		if not beast:
			_box("Boot sole",shin,Vector3(0,-shin_len-.10,-.035),Vector3(.14,.035,.25),materials["leather"])
		if side > 0:
			right_arm=arm
			right_forearm=forearm
			right_leg=leg
			right_shin=shin
		else:
			left_arm=arm
			left_forearm=forearm
			left_leg=leg
			left_shin=shin


func _build_head(hooded: bool) -> void:
	head = _pivot("Head and expression",body,Vector3(0,1.49,0))
	_segment("Neck",head,Vector3(0,-.07,0),Vector3(0,.085,0),.065,.069,materials["skin"])
	_taper("Face and jaw",head,[Vector3(.045,.025,.055),Vector3(.085,.065,.082),Vector3(.105,.15,.091),Vector3(.102,.235,.087),Vector3(.068,.275,.065),Vector3(.0,.29,.0)],materials["skin"],16)
	for side in [-1.0,1.0]:
		_ellipsoid("Ear",head,Vector3(side*.105,.14,.0),Vector3(.021,.038,.023),materials["skin"])
		_ellipsoid("Shadowed eye socket",head,Vector3(side*.040,.176,-.082),Vector3(.026,.014,.012),materials["hair"])
		_ellipsoid("Amber eye",head,Vector3(side*.041,.175,-.092),Vector3(.009,.006,.004),materials["gold"])
		var brow := _box("Strong brow",head,Vector3(side*.039,.196,-.088),Vector3(.058,.015,.018),materials["hair"])
		brow.rotation.z = side*.10
		_ellipsoid("Cheekbone",head,Vector3(side*.061,.134,-.069),Vector3(.038,.036,.023),materials["skin"])
	_segment("Nose bridge",head,Vector3(0,.185,-.092),Vector3(0,.126,-.115),.014,.020,materials["skin"],8)
	_ellipsoid("Lower lip",head,Vector3(0,.091,-.079),Vector3(.030,.007,.008),materials["skin"])
	if hooded:
		var hood := _taper("Deep travel hood",head,[Vector3(.135,-.02,.11),Vector3(.15,.13,.13),Vector3(.145,.29,.12),Vector3(.085,.36,.075),Vector3(0,.38,0)],materials["bandit"],12)
		hood.position.z = .055
		# Hood rim frames an unobstructed face at the front.
		for side in [-1.0,1.0]:
			_segment("Hood folded rim",head,Vector3(side*.11,.05,-.075),Vector3(side*.12,.25,-.07),.028,.028,materials["bandit"])
		_ellipsoid("Hood brow",head,Vector3(0,.285,-.064),Vector3(.13,.045,.065),materials["bandit"])
		_box("Face scarf",head,Vector3(0,.059,-.085),Vector3(.16,.072,.025),materials["leather"])
	else:
		_ellipsoid("Swept dark hair",head,Vector3(0,.24,.035),Vector3(.112,.089,.095),materials["hair"])
		for side in [-1.0,1.0]:
			for index in range(4):
				var z := -.005+float(index)*.034
				_segment("Sculpted hair lock",head,Vector3(side*.095,.24,z),Vector3(side*(.103+float(index)*.004),.012-float(index)*.018,z+.03),.027,.008,materials["hair"],7)
		_ellipsoid("Short weathered beard",head,Vector3(0,.043,-.044),Vector3(.071,.035,.047),materials["hair"])
		_segment("Temple silver streak",head,Vector3(-.101,.24,.005),Vector3(-.110,.055,.035),.007,.003,materials["steel"],5)
		_segment("Old cheek scar",head,Vector3(.071,.17,-.084),Vector3(.053,.122,-.087),.003,.002,materials["skin"],4)


func _build_sword(parent: Node3D, bandit: bool) -> void:
	_segment("Wrapped sword grip",parent,Vector3(0,-.04,0),Vector3(0,.14,0),.024,.022,materials["leather"],10)
	for i in range(6):
		_taper("Grip winding",parent,[Vector3(.025,float(i)*.027-.04,.025),Vector3(.025,float(i)*.027-.028,.025)],materials["gold"],10)
	_ellipsoid("Sword pommel",parent,Vector3(0,.175,0),Vector3(.041,.045,.032),materials["steel"])
	var guard := _box("Crossguard",parent,Vector3(0,-.09,0),Vector3(.23,.034,.048),materials["gold"])
	guard.rotation.z = .04
	for side in [-1.0,1.0]:
		_segment("Guard swept quillon",parent,Vector3(side*.08,-.09,0),Vector3(side*.145,-.135,0),.024,.012,materials["gold"],8)
	# Diamond cross-section yields actual broad blade faces and sharp steel edges.
	var blade_length := .70 if bandit else .85
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections: Array[Vector3] = [Vector3(.042,-.12,.014),Vector3(.042,-.18,.014),Vector3(.031,-blade_length,.012),Vector3(0,-blade_length-.15,0)]
	for r in range(sections.size()-1):
		var s: Vector3 = sections[r]
		var t: Vector3 = sections[r+1]
		var ring_a: Array[Vector3] = [Vector3(-s.x,s.y,0),Vector3(0,s.y,-s.z),Vector3(s.x,s.y,0),Vector3(0,s.y,s.z)]
		var ring_b: Array[Vector3] = [Vector3(-t.x,t.y,0),Vector3(0,t.y,-t.z),Vector3(t.x,t.y,0),Vector3(0,t.y,t.z)]
		for edge in range(4):
			var next := (edge+1)%4
			for vertex in [ring_a[edge],ring_b[edge],ring_a[next],ring_a[next],ring_b[edge],ring_b[next]]:
				surface.set_uv(Vector2(float(edge)/4.0,absf(vertex.y)))
				surface.add_vertex(vertex)
	surface.generate_normals()
	_mesh("Tempered diamond-section blade",parent,surface.commit(),Vector3.ZERO,materials["edge"])
	_box("Dark blade fuller",parent,Vector3(0,-.41,-.014),Vector3(.008,.47,.002),materials["steel"])


func _build_creature() -> void:
	_taper("Hunched guardian torso",body,[Vector3(.17,.87,.13),Vector3(.22,1.13,.16),Vector3(.30,1.42,.21),Vector3(.33,1.61,.21),Vector3(.18,1.77,.16)],materials["beast"])
	_build_limbs(true)
	for side in [-1.0,1.0]:
		for i in range(5):
			var rib := _ellipsoid("Ancient rib plating",body,Vector3(side*(.15-float(i)*.01),1.50-float(i)*.075,-.158),Vector3(.16,.027,.047),materials["beast_plates"])
			rib.rotation.z=side*(.22+float(i)*.04)
		for i in range(4):
			_segment("Matted shoulder mane",body,Vector3(side*.24,1.65-float(i)*.05,.13),Vector3(side*(.37+float(i)*.025),1.46-float(i)*.06,.23),.08,.004,materials["beast"],7)
	for i in range(7):
		_segment("Spinal ridge",body,Vector3(0,1.13+float(i)*.08,.16),Vector3(0,1.18+float(i)*.09,.28),.05,.004,materials["beast_plates"],7)
	head = _pivot("Antlered skull",body,Vector3(0,1.79,-.12))
	_ellipsoid("Dark cranium",head,Vector3(0,.04,0),Vector3(.16,.20,.16),materials["beast"])
	_taper("Elongated old bone face",head,[Vector3(.06,-.16,.07),Vector3(.105,-.06,.11),Vector3(.136,.13,.11),Vector3(.08,.23,.08),Vector3(.0,.25,.0)],materials["bone"],10).position.z=-.11
	_ellipsoid("Long skull muzzle",head,Vector3(0,-.095,-.205),Vector3(.068,.10,.075),materials["bone"])
	_ellipsoid("Black nose recess",head,Vector3(0,-.13,-.267),Vector3(.043,.037,.012),materials["beast"])
	for side in [-1.0,1.0]:
		var socket := _ellipsoid("Hollow eye socket",head,Vector3(side*.083,.075,-.202),Vector3(.046,.033,.018),materials["beast"])
		socket.rotation.z=side*-.25
		_ellipsoid("Pale watchful eye",head,Vector3(side*.082,.074,-.218),Vector3(.023,.010,.008),glow_material)
		_segment("Brow horn",head,Vector3(side*.07,.14,-.19),Vector3(side*.15,.16,-.10),.027,.004,materials["bone"],7)
		_segment("Hanging fang",head,Vector3(side*.041,-.13,-.23),Vector3(side*.043,-.24,-.24),.016,.001,materials["bone"],7)
		var antler_points: Array[Vector3] = [Vector3(side*.11,.18,.0),Vector3(side*.22,.33,.025),Vector3(side*.30,.48,.04),Vector3(side*.35,.66,-.015)]
		for i in range(antler_points.size()-1):
			_segment("Crown antler",head,antler_points[i],antler_points[i+1],.04-float(i)*.01,.03-float(i)*.013,materials["beast_plates"],8)
		_segment("Antler inner tine",head,antler_points[1],Vector3(side*.12,.55,-.03),.024,.002,materials["bone"],7)
		_segment("Antler outer tine",head,antler_points[2],Vector3(side*.47,.53,.08),.018,.002,materials["bone"],7)
		_segment("Backward crown tine",head,antler_points[1],Vector3(side*.30,.43,.22),.024,.002,materials["beast_plates"],7)
		_segment("Long pointed ear",head,Vector3(side*.13,.10,.02),Vector3(side*.32,.18,.06),.061,.002,materials["beast"],8)
	weapon = _pivot("Right claw socket",right_forearm,Vector3(0,-.37,0))


func _update_cloak() -> void:
	if not is_instance_valid(cloak):
		return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 12
	var rows := 13
	var verts: Array[Vector3] = []
	var run_wind := minf(motion_speed / 6.0, 1.0)
	for row in range(rows+1):
		var v := float(row)/float(rows)
		for col in range(columns+1):
			var u := float(col)/float(columns)
			var side := u*2.0-1.0
			var width := lerpf(.21,.32,v)
			var folds := sin(u*TAU*3.0+v*1.5)*(.015+.018*v)
			var flutter := sin(clock*3.5+u*5.0-v*4.2)*v*v*(.026+run_wind*.07)
			var hem := (sin(u*19.0)*.018+cos(u*32.0)*.012)*pow(v,8.0)
			verts.append(Vector3(side*width,1.43-v*.96+hem,.14+v*.10+folds+flutter+run_wind*v*v*.23))
	for row in range(rows):
		for col in range(columns):
			var a := row*(columns+1)+col
			var b := a+1
			var c := a+columns+1
			var d := c+1
			for index in [a,b,c,b,d,c]:
				surface.set_uv(Vector2(float(index%(columns+1))/float(columns),float(index/(columns+1))/float(rows)))
				surface.add_vertex(verts[index])
	surface.generate_normals()
	cloak.mesh = surface.commit()


func _animate(delta: float) -> void:
	var beast := actor_kind == "creature"
	var moving := motion in ["walk","run","sprint","chase","patrol"]
	var gait := sin(clock*(10.5 if motion == "sprint" else 8.5))
	var walk_amount := clampf(motion_speed/4.0,0.0,1.0) if moving else 0.0
	var breath := sin(clock*2.2)*.009
	var torso_rot := Vector3(.10 if beast else 0.0,0,0)
	var torso_pos := Vector3(0,breath+absf(gait)*walk_amount*.025,0)
	var ra := Vector3(-gait*walk_amount*.47,.0,-.12 if beast else -.075)
	var la := Vector3(gait*walk_amount*.47,.0,.12 if beast else .075)
	var rf := Vector3(-.15,0,0)
	var lf := Vector3(-.18,0,0)
	var rl := Vector3(gait*walk_amount*.65,0,0)
	var ll := Vector3(-gait*walk_amount*.65,0,0)
	var rs := Vector3(maxf(-gait,0.0)*walk_amount*.72,0,0)
	var ls := Vector3(maxf(gait,0.0)*walk_amount*.72,0,0)
	var sword_rot := Vector3(.38,0,.16)
	var p := action_phase
	if motion in ["light_1","light_2","light_3","attack"]:
		var strike := smoothstep(.23,.58,p)
		var release := smoothstep(.68,1.0,p)
		var weight := 1.0-release
		var swing_id := 1
		if motion == "light_2": swing_id=2
		if motion == "light_3": swing_id=3
		if beast:
			ra=Vector3(lerpf(2.3,.7,strike),lerpf(-.8,.65,strike),-.34)*weight
			la=Vector3(lerpf(2.0,.85,strike),lerpf(.8,-.65,strike),.34)*weight
			torso_rot.x=lerpf(-.13,.35,strike)*weight
			torso_pos.z=-sin(p*PI)*.12
			if attack_variant == "sweep":
				ra=Vector3(1.5,lerpf(-1.2,1.2,strike),-.85)*weight
				la=Vector3(1.2,lerpf(-.7,.9,strike),.7)*weight
				torso_rot.y=lerpf(-.9,.9,strike)*weight
		elif swing_id == 1:
			ra=Vector3(lerpf(2.0,.95,strike),lerpf(-.5,.55,strike),lerpf(-1.0,.35,strike))*weight
			rf=Vector3(-.35,0,0)
			torso_rot.y=lerpf(-.55,.55,strike)*weight
			sword_rot=Vector3(.75,0,lerpf(-.7,.55,strike))
		elif swing_id == 2:
			ra=Vector3(lerpf(1.3,1.55,strike),lerpf(.8,-.65,strike),lerpf(.4,-.65,strike))*weight
			rf=Vector3(-.5,0,0)
			torso_rot.y=lerpf(.6,-.65,strike)*weight
			sword_rot=Vector3(.85,0,lerpf(.5,-.7,strike))
		else:
			ra=Vector3(lerpf(2.9,.95,strike),-.10,-.12)*weight
			la=Vector3(lerpf(2.6,.85,strike),.2,.2)*weight
			rf=Vector3(-.50*(1.0-strike),0,0)
			torso_rot.x=lerpf(-.17,.18,strike)*weight
			sword_rot=Vector3(.75,0,0)
	elif motion in ["heavy","windup"]:
		var raise := smoothstep(0.0,.24,p)
		var strike := smoothstep(.45,.65,p) if motion == "heavy" else 0.0
		var release := smoothstep(.76,1.0,p) if motion == "heavy" else 0.0
		var weight := 1.0-release
		ra=Vector3(lerpf(2.75,1.02,strike)*raise,-.12,-.22)*weight
		la=Vector3(lerpf(2.63,.92,strike)*raise,.12,.22)*weight
		rf=Vector3(-.70*(1.0-strike),0,0)
		lf=Vector3(-.70*(1.0-strike),0,0)
		torso_rot.x=lerpf(-.17,.23,strike)*raise*weight
		torso_pos.y=-.06*sin(p*PI)
		sword_rot=Vector3(.80,0,0)
	elif motion == "block":
		ra=Vector3(1.00,-.35,-.12)
		rf=Vector3(1.0,0,0)
		la=Vector3(1.15,.40,.25)
		lf=Vector3(.75,0,0)
		sword_rot=Vector3(.38,0,.90)
		torso_rot.y=-.15
		torso_pos.y=-.04
	elif motion == "dodge":
		torso_rot.x=-TAU*p
		torso_pos.y=-.27*sin(p*PI)
		torso_pos.z=-.13*sin(p*PI)
		rl.x=-.85
		ll.x=-.85
		rs.x=1.3
		ls.x=1.3
		ra=Vector3(1.0,0,-.25)
		la=Vector3(1.0,0,.25)
	elif motion == "jump":
		rl.x=-.30
		ll.x=.25
		rs.x=.52
		ls.x=.3
		ra.z=-.35
		la.z=.35
	elif motion == "stagger":
		torso_rot.x=-.20*sin(p*PI)
		torso_rot.z=.11*sin(p*TAU)
		ra.z=-.35
		la.z=.35
	elif motion == "recover":
		ra.x=.9*(1.0-p)
		la.x=.5*(1.0-p)
		torso_rot.x=.13*(1.0-p)
	if dead_visual or motion == "death":
		death_amount = minf(death_amount+delta*1.8,1.0)
		torso_rot=Vector3(0,0,death_amount*1.48)
		torso_pos=Vector3(.32*death_amount,-.70*death_amount,0)
		ra=Vector3(.20,0,-.35)
		la=Vector3(.45,0,.25)
		rl.x=.12
		ll.x=-.12
	var blend := clampf(delta*20.0,0.0,1.0)
	body.position=body.position.lerp(torso_pos,blend)
	body.rotation=body.rotation.lerp(torso_rot,blend)
	right_arm.rotation=right_arm.rotation.lerp(ra,blend)
	left_arm.rotation=left_arm.rotation.lerp(la,blend)
	right_forearm.rotation=right_forearm.rotation.lerp(rf,blend)
	left_forearm.rotation=left_forearm.rotation.lerp(lf,blend)
	right_leg.rotation=right_leg.rotation.lerp(rl,blend)
	left_leg.rotation=left_leg.rotation.lerp(ll,blend)
	right_shin.rotation=right_shin.rotation.lerp(rs,blend)
	left_shin.rotation=left_shin.rotation.lerp(ls,blend)
	weapon.rotation=weapon.rotation.lerp(sword_rot,blend)
	head.rotation.x=sin(clock*1.3)*.015
	head.rotation.y=sin(clock*.7)*.025 if motion == "idle" else 0.0
