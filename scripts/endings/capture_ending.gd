extends Control
## Ending A: transformation. Static and distortion, the capture text, a fictional system error,
## then a clean quit. GameState has already saved the capture counter before this scene loads.

const MESSAGES: Array[String] = [
	"HOLD STILL.",
	"IT DOESN'T HURT. THAT IS THE WORST PART.",
	"YOUR HANDS ARE LONGER THAN THEY WERE.",
	"YOU REMEMBER ROOM 6. YOU REMEMBER WRITING THE EMAILS.",
	"DETECTIVE M. IS NO LONGER PRESENT.",
]

var _static_rect: ColorRect
var _material: ShaderMaterial
var _label: Label
var _dialog: PanelContainer
var _closing := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(black)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	add_child(_label)
	_static_rect = ColorRect.new()
	_static_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_static_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://shaders/static_distortion.gdshader")
	_material.set_shader_parameter("intensity", 1.0)
	_material.set_shader_parameter("noise_mix", 1.0)
	_static_rect.material = _material
	add_child(_static_rect)
	ProcAudio.play(self, "static", -8.0, true)
	_run_sequence()


func _run_sequence() -> void:
	for message in MESSAGES:
		_label.text = message
		var tween := create_tween()
		tween.tween_method(func(value: float) -> void: _material.set_shader_parameter("noise_mix", value), 1.0, 0.25, 0.6)
		tween.tween_interval(1.6)
		tween.tween_method(func(value: float) -> void: _material.set_shader_parameter("noise_mix", value), 0.25, 1.0, 0.4)
		await tween.finished
	_label.text = ""
	await get_tree().create_timer(0.8).timeout
	_show_error_dialog()


func _show_error_dialog() -> void:
	_static_rect.visible = false
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.33, 0.33)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_dialog = PanelContainer.new()
	_dialog.set_anchors_preset(Control.PRESET_CENTER)
	_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dialog.custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.75, 0.75, 0.75)
	style.set_border_width_all(3)
	style.border_color = Color(0.95, 0.95, 0.95)
	style.set_content_margin_all(14)
	_dialog.add_theme_stylebox_override("panel", style)
	add_child(_dialog)
	var box := VBoxContainer.new()
	_dialog.add_child(box)
	var title := Label.new()
	title.text = "HAVEN.EXE - Fatal Error"
	title.add_theme_color_override("font_color", Color.WHITE)
	var bar := PanelContainer.new()
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.0, 0.0, 0.55)
	bar.add_theme_stylebox_override("panel", bar_style)
	bar.add_child(title)
	box.add_child(bar)
	var message := Label.new()
	message.text = "\nAn exception 0E has occurred at 0028:4D48A1 in HOLLOW.SYS.\n\nENTITY HANDLE 'M' HAS BEEN REASSIGNED.\nThe player process can no longer be separated from the creature.\n\nThis is not a crash. Haven will now close.\n"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_color_override("font_color", Color.BLACK)
	box.add_child(message)
	var ok := Button.new()
	ok.text = "  OK  "
	ok.pressed.connect(_close_game)
	box.add_child(ok)
	# Closes by itself too, so the ending never needs a manual kill.
	get_tree().create_timer(12.0).timeout.connect(_close_game)


func _close_game() -> void:
	if _closing:
		return
	_closing = true
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	await get_tree().create_timer(0.5).timeout
	GameState.finish_capture_ending_and_quit()
