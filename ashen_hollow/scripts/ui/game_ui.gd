extends CanvasLayer
## The presentation layer owns no game state or pause state.
## All controls are built in code so this UI is reusable in any gameplay scene.

signal start_requested
signal resume_requested
signal restart_requested
signal quit_requested

const IVORY := Color("eadfca")
const MUTED := Color("aaa99e")
const GOLD := Color("ba9662")
const INK := Color("10171b")
const RED := Color("a84e49")
const GREEN := Color("afa66e")

var _title_font: Font
var _body_font: Font
var _root: Control
var _main: Control
var _hud: Control
var _modal: Control
var _modal_content: VBoxContainer
var _controls: Control
var _health: ProgressBar
var _stamina: ProgressBar
var _health_text: Label
var _objective_title: Label
var _objective_body: Label
var _objective_progress: ProgressBar
var _interaction: PanelContainer
var _interaction_label: Label
var _region: VBoxContainer
var _region_label: Label
var _message: VBoxContainer
var _message_label: Label
var _lock: VBoxContainer
var _lock_name: Label
var _lock_bar: ProgressBar
var _damage: ColorRect
var _hit: Label
var _toast_timer := 0.0
var _region_timer := 0.0
var _damage_amount := 0.0
var _hit_timer := 0.0
var _current_region := ""
var _ui_time := 0.0
var _main_button: Button
var _hud_visible := false

class Heraldry extends Control:
	var ink := Color("ba9662")
	func _draw() -> void:
		var c := size * 0.5
		var scale_factor := minf(size.x, size.y) / 90.0
		var pts := PackedVector2Array([Vector2(-23,-29), Vector2(23,-29), Vector2(23,5), Vector2(16,22), Vector2(0,34), Vector2(-16,22), Vector2(-23,5), Vector2(-23,-29)])
		for i in pts.size():
			pts[i] = c + pts[i] * scale_factor
		draw_polyline(pts, Color(ink, 0.65), 1.0, true)
		draw_line(c+Vector2(0,-30)*scale_factor,c+Vector2(0,22)*scale_factor,ink,1.8,true)
		draw_line(c+Vector2(-10,-11)*scale_factor,c+Vector2(10,-11)*scale_factor,ink,1.8,true)
		draw_line(c+Vector2(-3,-28)*scale_factor,c+Vector2(3,-28)*scale_factor,ink,1.8,true)
		draw_polyline(PackedVector2Array([c+Vector2(-5,12)*scale_factor,c+Vector2(0,22)*scale_factor,c+Vector2(5,12)*scale_factor]),ink,1.0,true)
		for side in [-1,1]:
			for j in 3:
				var p := c + Vector2(side * (11+j*3), 10-j*10) * scale_factor
				draw_line(p,p+Vector2(side*5,-6)*scale_factor,Color(ink,0.6),1.0,true)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_title_font = load("res://assets/fonts/Title.ttf") as Font
	_body_font = load("res://assets/fonts/Body.ttf") as Font
	_root = Control.new()
	_root.name = "Presentation"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_atmosphere()
	_build_hud()
	_build_main_menu()
	_build_modal()
	_build_controls()
	_build_feedback()
	show_main_menu()

func _label(text: String, font_size: int = 16, color: Color = IVORY, serif: bool = false) -> Label:
	var n := Label.new()
	n.text = text
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_theme_font_override("font", _title_font if serif else _body_font)
	n.add_theme_font_size_override("font_size", font_size)
	n.add_theme_color_override("font_color", color)
	n.add_theme_color_override("font_shadow_color", Color(0.015,0.02,0.025,0.8))
	n.add_theme_constant_override("shadow_offset_x", 1)
	n.add_theme_constant_override("shadow_offset_y", 2)
	return n

func _control(parent: Node, full: bool = false) -> Control:
	var n := Control.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	if full:
		n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return n

func _vbox(parent: Node, separation: int = 8) -> VBoxContainer:
	var n := VBoxContainer.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_theme_constant_override("separation", separation)
	parent.add_child(n)
	return n

func _rule(parent: Node, color: Color = Color(GOLD,0.42), width: float = 0.0) -> ColorRect:
	var line := ColorRect.new()
	line.color = color
	line.custom_minimum_size = Vector2(width,1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)
	return line

func _spacer(parent: Node, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)

func _style(bg: Color, border: Color = Color.TRANSPARENT, thickness: int = 0, padding: int = 14) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(thickness)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _button(text: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(270,48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", _body_font)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", IVORY if primary else MUTED)
	button.add_theme_color_override("font_hover_color", Color("fff1d5"))
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _style(Color(0.09,0.11,0.12,0.76) if primary else Color(0.04,0.06,0.07,0.20), Color(GOLD,0.7 if primary else 0.20), 1))
	button.add_theme_stylebox_override("hover", _style(Color(0.20,0.19,0.15,0.87), Color(GOLD,0.9), 1))
	button.add_theme_stylebox_override("pressed", _style(Color(0.13,0.13,0.11,0.92), GOLD, 1))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color(IVORY,0.65),1))
	button.pressed.connect(callback)
	return button

func _bar(color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.max_value = 100.0
	bar.value = 100.0
	var back := _style(Color(0.02,0.025,0.028,0.85),Color(GOLD,0.2),1,0)
	back.content_margin_top = 0
	back.content_margin_bottom = 0
	var fill := _style(color,Color.TRANSPARENT,0,0)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background",back)
	bar.add_theme_stylebox_override("fill",fill)
	return bar

func _shader_rect(parent: Node, code: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = code
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	return rect

func _build_atmosphere() -> void:
	_shader_rect(_root,"shader_type canvas_item; void fragment(){ vec2 p=UV*2.0-1.0; float edge=pow(clamp(length(p*vec2(0.72,0.90)),0.0,1.0),3.0); COLOR=vec4(0.015,0.023,0.028,edge*0.33); }")

func _build_main_menu() -> void:
	_main = _control(_root,true)
	_main.name = "MainMenu"
	_main.mouse_filter = Control.MOUSE_FILTER_STOP
	_shader_rect(_main,"shader_type canvas_item; void fragment(){ float a=mix(0.96,0.05,smoothstep(0.18,0.91,UV.x)); COLOR=vec4(0.025,0.043,0.050,a); }")
	var content := _vbox(_main,8)
	content.anchor_left = 0.072
	content.anchor_top = 0.115
	content.anchor_right = 0.49
	content.offset_right = 0
	var crest_row := HBoxContainer.new()
	crest_row.add_theme_constant_override("separation",14)
	content.add_child(crest_row)
	var crest := Heraldry.new()
	crest.custom_minimum_size = Vector2(45,52)
	crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_row.add_child(crest)
	var chapter := _label("A DARK FANTASY CHRONICLE",11,GOLD)
	chapter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	crest_row.add_child(chapter)
	_spacer(content,4)
	var title := _label("ASHEN\nHOLLOW",67,IVORY,true)
	title.add_theme_constant_override("line_spacing",-12)
	content.add_child(title)
	_spacer(content,6)
	var rule_row := HBoxContainer.new()
	content.add_child(rule_row)
	_rule(rule_row,Color(GOLD,0.7),56)
	_spacer(content,8)
	content.add_child(_label("Some embers refuse to die.",20,Color("c4b89f"),true))
	var story := _label("Beyond the old road, a village falls silent.\nFollow the last light into the hollow.",13,MUTED)
	story.add_theme_constant_override("line_spacing",5)
	content.add_child(story)
	_spacer(content,17)
	var buttons := _vbox(content,9)
	buttons.custom_minimum_size.x = 284
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_main_button = _button("BEGIN JOURNEY    ›",func(): start_requested.emit(),true)
	buttons.add_child(_main_button)
	buttons.add_child(_button("Controls",func(): _show_controls()))
	buttons.add_child(_button("Quit",func(): quit_requested.emit()))
	var footer := _label("CHAPTER I    /    THE LAST WATCH",11,Color(GOLD,0.78))
	_main.add_child(footer)
	footer.anchor_left = 0.072
	footer.anchor_top = 1.0
	footer.offset_top = -43
	var edition := _label("AN ORIGINAL PLAYABLE PROTOTYPE",9,Color(MUTED,0.65))
	_main.add_child(edition)
	edition.anchor_left = 1.0
	edition.anchor_right = 1.0
	edition.anchor_top = 1.0
	edition.offset_left = -290
	edition.offset_right = -35
	edition.offset_top = -41
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_hud() -> void:
	_hud = _control(_root,true)
	_hud.name = "GameplayHUD"
	_shader_rect(_hud,"shader_type canvas_item; void fragment(){ float a=(1.0-smoothstep(0.0,0.25,UV.y))*0.54 + smoothstep(0.85,1.0,UV.y)*0.32; COLOR=vec4(0.018,0.027,0.032,a); }")
	var stats := _vbox(_hud,6)
	stats.position = Vector2(32,27)
	stats.custom_minimum_size.x = 253
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation",14)
	stats.add_child(head)
	var name_tag := _label("THE WANDERER",11,Color(IVORY,0.9))
	name_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_tag)
	_health_text = _label("120 / 120",10,Color(MUTED,0.85))
	head.add_child(_health_text)
	_health = _bar(RED,10)
	stats.add_child(_health)
	_stamina = _bar(GREEN,5)
	stats.add_child(_stamina)
	var quest := _vbox(_hud,7)
	quest.anchor_left = 1.0
	quest.anchor_right = 1.0
	quest.offset_left = -315
	quest.offset_right = -32
	quest.offset_top = 29
	var quest_header := _label("THE HOLLOW CALLS",10,GOLD)
	quest_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quest.add_child(quest_header)
	_objective_title = _label("A village without voices",18,IVORY,true)
	_objective_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest.add_child(_objective_title)
	_objective_body = _label("Follow the old road to the village.",12,Color(MUTED,0.97))
	_objective_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest.add_child(_objective_body)
	_objective_progress = _bar(Color(GOLD,0.8),2)
	quest.add_child(_objective_progress)
	_objective_progress.value = 0
	_region = _vbox(_hud,4)
	_region.anchor_left = 0.28
	_region.anchor_right = 0.72
	_region.anchor_top = 0.22
	_region.add_child(_label_center("—   THE OLD ROAD   —",10,GOLD))
	_region_label = _label_center("The forgotten path",25,IVORY,true)
	_region.add_child(_region_label)
	_region.modulate.a = 0
	_lock = _vbox(_hud,6)
	_lock.anchor_left = 0.36
	_lock.anchor_right = 0.64
	_lock.offset_top = 30
	_lock_name = _label_center("",14,IVORY,true)
	_lock.add_child(_lock_name)
	_lock_bar = _bar(RED,5)
	_lock.add_child(_lock_bar)
	_lock.visible = false
	_message = _vbox(_hud,6)
	_message.anchor_left = 0.23
	_message.anchor_right = 0.77
	_message.anchor_top = 0.70
	_message_label = _label_center("",18,IVORY,true)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_child(_message_label)
	_message.modulate.a = 0
	_interaction = PanelContainer.new()
	_interaction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interaction.add_theme_stylebox_override("panel",_style(Color(INK,0.82),Color(GOLD,0.4),1,22))
	_hud.add_child(_interaction)
	_interaction.anchor_left = 0.5
	_interaction.anchor_right = 0.5
	_interaction.anchor_top = 1.0
	_interaction.anchor_bottom = 1.0
	_interaction.offset_left = -210
	_interaction.offset_right = 210
	_interaction.offset_top = -118
	_interaction.offset_bottom = -71
	_interaction_label = _label_center("[ E ]   Investigate",14,IVORY)
	_interaction.add_child(_interaction_label)
	_interaction.visible = false
	var controls := _label_center("LMB  Strike     Q  Heavy     RMB  Block     Ctrl  Dodge     Tab  Lock     Esc  Pause",11,Color(IVORY,0.70))
	_hud.add_child(controls)
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.anchor_right = 1.0
	controls.offset_top = -37
	controls.offset_bottom = -16
	var mark := _label_center("·",20,Color(IVORY,0.34))
	_hud.add_child(mark)
	mark.anchor_left = 0.5
	mark.anchor_right = 0.5
	mark.anchor_top = 0.5
	mark.anchor_bottom = 0.5
	mark.offset_left = -10
	mark.offset_right = 10
	mark.offset_top = -15
	mark.offset_bottom = 15

func _label_center(text: String, font_size: int = 16, color: Color = IVORY, serif: bool = false) -> Label:
	var label := _label(text,font_size,color,serif)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _build_modal() -> void:
	_modal = _control(_root,true)
	_modal.name = "SessionOverlay"
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.025,0.035,0.040,0.87)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_content = _vbox(center,12)
	_modal_content.custom_minimum_size.x = 410
	_modal.visible = false

func _clear_modal() -> void:
	for child in _modal_content.get_children():
		_modal_content.remove_child(child)
		child.queue_free()
	_modal.visible = true
	_controls.visible = false

func _modal_heading(kicker: String, heading: String, body: String) -> void:
	_modal_content.add_child(_label_center(kicker,10,GOLD))
	_spacer(_modal_content,3)
	_modal_content.add_child(_label_center(heading,43,IVORY,true))
	_rule(_modal_content,Color(GOLD,0.48))
	_spacer(_modal_content,4)
	var detail := _label_center(body,13,MUTED)
	detail.add_theme_constant_override("line_spacing",5)
	_modal_content.add_child(detail)
	_spacer(_modal_content,14)

func _build_controls() -> void:
	_controls = _control(_root,true)
	_controls.name = "ControlsOverlay"
	_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.025,0.035,0.040,0.97)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	_controls.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := _vbox(center,9)
	box.custom_minimum_size.x = 520
	box.add_child(_label_center("THE WANDERER'S HANDBOOK",10,GOLD))
	box.add_child(_label_center("Steel. Patience. Resolve.",34,IVORY,true))
	_spacer(box,6)
	_rule(box)
	var rows := [
		["W  A  S  D", "Move"],
		["MOUSE", "Look around"],
		["SHIFT  /  SPACE", "Sprint  /  Jump"],
		["LEFT MOUSE", "Light strike · press again to chain three attacks"],
		["Q  /  RIGHT MOUSE", "Heavy strike  /  Hold to block"],
		["CTRL", "Dodge · briefly evade incoming damage"],
		["TAB", "Lock on to a nearby enemy"],
		["E  /  ESC", "Investigate  /  Pause"]
	]
	for row in rows:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation",18)
		box.add_child(pair)
		var key := _label(row[0],11,GOLD)
		key.custom_minimum_size.x = 167
		pair.add_child(key)
		pair.add_child(_label(row[1],12,IVORY))
	_rule(box)
	var tip := _label_center("Every action has a cost. Let your stamina recover.\nFace your foe to block; dodge as their weapon falls.",12,MUTED)
	tip.add_theme_constant_override("line_spacing",4)
	box.add_child(tip)
	_spacer(box,10)
	box.add_child(_button("Return",_close_controls,true))
	_controls.hide()

func _build_feedback() -> void:
	_damage = _shader_rect(_root,"shader_type canvas_item; uniform float intensity=0.0; void fragment(){ vec2 p=UV*2.0-1.0; float edge=smoothstep(0.32,1.2,length(p)); COLOR=vec4(0.39,0.035,0.025,edge*intensity); }")
	_hit = _label_center("×",28,Color(IVORY,0.9))
	_root.add_child(_hit)
	_hit.anchor_left = 0.5
	_hit.anchor_right = 0.5
	_hit.anchor_top = 0.5
	_hit.anchor_bottom = 0.5
	_hit.offset_left = -20
	_hit.offset_right = 20
	_hit.offset_top = -23
	_hit.offset_bottom = 23
	_hit.modulate.a = 0

func _show_controls() -> void:
	_controls.show()
	var buttons := _controls.find_children("*","Button",true,false)
	if not buttons.is_empty():
		buttons[0].grab_focus()

func _close_controls() -> void:
	_controls.hide()
	_main_button.grab_focus()

func _input(event: InputEvent) -> void:
	if _controls.visible and event.is_action_pressed("pause") and not event.is_echo():
		_close_controls()
		get_viewport().set_input_as_handled()

func show_main_menu() -> void:
	_hud_visible = false
	_main.show()
	_hud.hide()
	_modal.hide()
	_controls.hide()
	_damage_amount = 0
	_hit_timer = 0
	_main_button.grab_focus()

func show_hud() -> void:
	_hud_visible = true
	_main.hide()
	_hud.show()
	_modal.hide()
	_controls.hide()

func set_stats(health: float, max_health: float, stamina: float, max_stamina: float) -> void:
	_health.max_value = maxf(1.0,max_health)
	_health.value = clampf(health,0.0,max_health)
	_stamina.max_value = maxf(1.0,max_stamina)
	_stamina.value = clampf(stamina,0.0,max_stamina)
	_health_text.text = "%d / %d" % [ceili(maxf(health,0.0)),int(max_health)]
	var fill := _stamina.get_theme_stylebox("fill") as StyleBoxFlat
	fill.bg_color = Color("c9784a") if stamina < max_stamina * 0.20 else GREEN

func set_objective(title: String, body: String, progress: float = 0.0) -> void:
	_objective_title.text = title
	_objective_body.text = body
	_objective_progress.value = clampf(progress,0.0,1.0) * 100.0

func set_interaction(text: String) -> void:
	_interaction.visible = not text.is_empty()
	_interaction_label.text = text

func show_message(text: String, seconds: float = 3.0) -> void:
	_message_label.text = text
	_toast_timer = maxf(seconds,0.3)
	_message.modulate.a = 0.0

func set_region(text: String) -> void:
	if text == _current_region or text.is_empty():
		return
	_current_region = text
	_region_label.text = text
	var eyebrow := _region.get_child(0) as Label
	eyebrow.text = "—   ASHEN HOLLOW   —"
	_region_timer = 4.5
	_region.modulate.a = 0.0

func set_lock_target(target_name: String, current: float, maximum: float) -> void:
	_lock.visible = not target_name.is_empty() and maximum > 0.0 and current > 0.0
	_lock_name.text = target_name
	_lock_bar.max_value = maxf(maximum,1.0)
	_lock_bar.value = current

func show_pause(paused: bool) -> void:
	if not paused:
		_modal.hide()
		_controls.hide()
		return
	_clear_modal()
	_modal_heading("A MOMENT OF STILLNESS","Journey paused","The hollow will wait.")
	var resume := _button("Resume journey",func(): _modal.hide(); resume_requested.emit(),true)
	_modal_content.add_child(resume)
	_modal_content.add_child(_button("Restart journey",func(): restart_requested.emit()))
	_modal_content.add_child(_button("Quit to title",func(): quit_requested.emit()))
	resume.grab_focus()

func show_death() -> void:
	_clear_modal()
	_modal_heading("THE EMBER FADES","You have fallen","Even the longest night yields to another dawn.\nReturn to the old road and try again.")
	var retry := _button("Rise again",func(): restart_requested.emit(),true)
	_modal_content.add_child(retry)
	_modal_content.add_child(_button("Return to title",func(): quit_requested.emit()))
	retry.grab_focus()

func show_victory() -> void:
	_clear_modal()
	_modal_heading("CHAPTER COMPLETE","A light remains","The guardian is vanquished. The hollow grows still.\nFor now, the old road is safe.")
	var explore := _button("Continue exploring",func(): _modal.hide(); resume_requested.emit(),true)
	_modal_content.add_child(explore)
	_modal_content.add_child(_button("Begin a new journey",func(): restart_requested.emit()))
	_modal_content.add_child(_button("Return to title",func(): quit_requested.emit()))
	explore.grab_focus()

func set_damage_flash() -> void:
	_damage_amount = 0.65

func set_hit_confirm() -> void:
	_hit_timer = 0.16

func _process(delta: float) -> void:
	_ui_time += delta
	_damage_amount = move_toward(_damage_amount,0.0,delta * 1.35)
	if _damage != null:
		(_damage.material as ShaderMaterial).set_shader_parameter("intensity",_damage_amount)
	if _hit != null:
		_hit_timer = maxf(_hit_timer - delta,0.0)
		_hit.modulate.a = minf(1.0,_hit_timer * 12.0) if _hud_visible else 0.0
	if not _hud_visible or get_tree().paused:
		return
	_toast_timer = maxf(_toast_timer-delta,0.0)
	_region_timer = maxf(_region_timer-delta,0.0)
	_message.modulate.a = move_toward(_message.modulate.a,1.0 if _toast_timer > 0.5 else 0.0,delta * 2.5)
	_region.modulate.a = move_toward(_region.modulate.a,1.0 if _region_timer > 0.8 else 0.0,delta * 1.8)
