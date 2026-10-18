extends CanvasLayer
signal begin_requested
signal resume_requested
signal quit_requested
signal quality_requested
var hud: Control
var menu: PanelContainer
var pause_panel: PanelContainer
var ending: PanelContainer
var objective: Label
var prompt: Label
var subtitle: Label
var bearing: Label
var status: Label
var quality_button: Button
var crosshair: Label
var scan: ProgressBar
var shade: ColorRect
var _subtitle_time := 0.0
var _font: Font = preload("res://assets/fonts/Body.ttf")
var _title: Font = preload("res://assets/fonts/Title.ttf")
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 var root := Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var theme_ := Theme.new()
 theme_.default_font = _font
 theme_.default_font_size = 17
 root.theme = theme_
 shade = ColorRect.new()
 shade.color = Color(0.005,.015,.023,.28)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(shade)
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.add_child(hud)
 var brand := text(hud,"N / V     ·     K A S U M I   D I S T R I C T",14,Color("c5d3d4"))
 brand.position = Vector2(38,28)
 status = text(hud,"ENCRYPTED CARGO   /   OFFLINE",12,Color("7babad"))
 status.position = Vector2(38,52)
 objective = text(hud,"",18,Color("e2e4dc"))
 objective.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 objective.offset_left = 38
 objective.offset_top = -114
 objective.size = Vector2(600,65)
 objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 bearing = text(hud,"",13,Color("72bcc5"))
 bearing.position = Vector2(38,82)
 crosshair = text(hud,"·",25,Color(.8,.9,.9,.7))
 crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 crosshair.offset_left = -5
 crosshair.offset_top = -15
 prompt = text(hud,"",16,Color("a6e3df"))
 prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 prompt.offset_left = -250
 prompt.offset_top = 42
 prompt.size = Vector2(500,35)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 subtitle = text(hud,"",18,Color("e4d8c2"))
 subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 subtitle.offset_left = -430
 subtitle.offset_top = -178
 subtitle.size = Vector2(860,65)
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 scan = ProgressBar.new()
 scan.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 scan.offset_left = -140
 scan.offset_top = 33
 scan.size = Vector2(280,5)
 scan.show_percentage = false
 scan.max_value = 4
 scan.modulate = Color("dca879")
 hud.add_child(scan)
 scan.hide()
 var controls := text(hud,"WASD  MOVE     SHIFT  SPRINT     CTRL  CROUCH     E  INTERACT     ESC  PAUSE",11,Color("789397"))
 controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 controls.offset_left = 38
 controls.offset_top = -32
 menu = panel(root,Vector2(70,120),Vector2(515,480))
 var list := column(menu)
 text(list,"A   N I G H T   I N   K A S U M I",13,Color("7ac2cd"))
 var title := text(list,"NEON\nVEIL",77,Color("e7e4d9"))
 title.add_theme_font_override("font",_title)
 text(list,"One stolen memory. One final delivery.",18,Color("c2bfb2"))
 text(list,"First-person atmospheric exploration\nHeadphones recommended",14,Color("7e9b9f"))
 button(list,"ENTER THE DISTRICT",func():begin_requested.emit())
 quality_button = button(list,"VISUALS  /  CINEMATIC",func():quality_requested.emit())
 button(list,"EXIT",func():quit_requested.emit())
 pause_panel = panel(root,Vector2(410,200),Vector2(460,300))
 var pause_list := column(pause_panel)
 text(pause_list,"SIGNAL PAUSED",28,Color("d6e2df"))
 text(pause_list,"The city can wait.",16,Color("91a8ad"))
 button(pause_list,"RESUME",func():resume_requested.emit())
 button(pause_list,"SWITCH VISUAL QUALITY",func():quality_requested.emit())
 button(pause_list,"RETURN TO TITLE",func():quit_requested.emit())
 ending = panel(root,Vector2(100,150),Vector2(550,400))
 var end_list := column(ending)
 text(end_list,"TRANSMISSION COMPLETE",13,Color("edb88a"))
 var end_title := text(end_list,"A MEMORY\nOF DAYLIGHT",42,Color("f0e3c9"))
 end_title.add_theme_font_override("font",_title)
 text(end_list,"They could own the city.\nThey could not own what it remembered.\n\nYou delivered the stolen archive beyond the veil.",17,Color("c8c4b9"))
 button(end_list,"WALK THE DISTRICT AGAIN",func():begin_requested.emit())
 button(end_list,"RETURN TO TITLE",func():quit_requested.emit())
 show_title()
func text(parent: Node,value: String,size_: int,color: Color) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size",size_)
 label.add_theme_color_override("font_color",color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label
func panel(parent: Node,at: Vector2,size_: Vector2) -> PanelContainer:
 var p := PanelContainer.new()
 p.position = at
 p.custom_minimum_size = size_
 var style := StyleBoxFlat.new()
 style.bg_color = Color(.015,.032,.043,.88)
 style.border_color = Color(.25,.47,.5,.6)
 style.border_width_left = 2
 style.content_margin_left = 28
 style.content_margin_right = 28
 style.content_margin_top = 23
 style.content_margin_bottom = 23
 p.add_theme_stylebox_override("panel",style)
 parent.add_child(p)
 return p
func column(parent: Node) -> VBoxContainer:
 var v := VBoxContainer.new()
 v.add_theme_constant_override("separation",14)
 parent.add_child(v)
 return v
func button(parent: Node,title: String,callback: Callable) -> Button:
 var b := Button.new()
 b.text = title
 b.alignment = HORIZONTAL_ALIGNMENT_LEFT
 b.custom_minimum_size.y = 38
 var style := StyleBoxFlat.new()
 style.bg_color = Color(.075,.16,.18,.8)
 style.content_margin_left = 13
 style.content_margin_right = 13
 b.add_theme_stylebox_override("normal",style)
 var hover := style.duplicate()
 hover.bg_color = Color(.15,.29,.3,.95)
 b.add_theme_stylebox_override("hover",hover)
 b.add_theme_stylebox_override("focus",hover)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b
func show_title() -> void:
 menu.show()
 hud.hide()
 pause_panel.hide()
 ending.hide()
 shade.show()
func show_game() -> void:
 menu.hide()
 hud.show()
 pause_panel.hide()
 ending.hide()
 shade.hide()
func show_pause() -> void:
 pause_panel.show()
 shade.show()
func show_ending() -> void:
 ending.show()
 hud.hide()
 pause_panel.hide()
 shade.show()
func message(value: String,duration := 5.0) -> void:
 subtitle.text = value
 _subtitle_time = duration
func _process(delta: float) -> void:
 if not get_tree().paused:
  _subtitle_time -= delta
  if _subtitle_time <= 0: subtitle.text = ""
