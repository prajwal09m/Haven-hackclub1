extends CanvasLayer
class_name ObjectiveUI
## Objective checklist (top-left) + "OBJECTIVE COMPLETE" toast (top-center).
## Purely reactive: listens to ObjectiveManager signals and never completes objectives itself.

const NOTIFICATION_VISIBLE_TIME := 2.5
const NOTIFICATION_FADE_TIME := 0.3
const COLOR_ACTIVE := Color(0.88, 0.86, 0.80)
const COLOR_DONE := Color(0.45, 0.47, 0.42)
const COLOR_ACCENT := Color(0.75, 0.15, 0.12)

var _checklist_box: VBoxContainer
var _toast_panel: PanelContainer
var _toast_title: Label
var _toast_queue: Array[String] = []
var _toast_busy := false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS # toasts keep animating while paused
	_build_checklist()
	_build_toast()
	ObjectiveManager.objectives_changed.connect(_refresh_checklist)
	ObjectiveManager.objective_completed.connect(_on_objective_completed)
	_refresh_checklist()


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _build_checklist() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	add_child(margin)
	_checklist_box = VBoxContainer.new()
	_checklist_box.add_theme_constant_override("separation", 4)
	_checklist_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_checklist_box)


func _build_toast() -> void:
	_toast_panel = PanelContainer.new()
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.offset_top = 40
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.border_width_bottom = 2
	style.border_color = COLOR_ACCENT
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_toast_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(box)
	var header := _make_label(14, COLOR_ACCENT)
	header.text = "OBJECTIVE COMPLETE"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(header)
	_toast_title = _make_label(20, COLOR_ACTIVE)
	_toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_toast_title)
	_toast_panel.modulate.a = 0.0
	_toast_panel.visible = false
	add_child(_toast_panel)


func _refresh_checklist() -> void:
	for child in _checklist_box.get_children():
		_checklist_box.remove_child(child)
		child.queue_free()
	var header := _make_label(14, COLOR_ACCENT)
	header.text = "OBJECTIVES"
	_checklist_box.add_child(header)
	for objective in ObjectiveManager.get_objectives():
		var row := _make_label(16, COLOR_DONE if objective["completed"] else COLOR_ACTIVE)
		row.text = ("✓  " if objective["completed"] else "•  ") + objective["title"]
		_checklist_box.add_child(row)


func _on_objective_completed(_objective_id: String, objective_title: String) -> void:
	_toast_queue.append(objective_title)
	if not _toast_busy:
		_play_toast_queue()


func _play_toast_queue() -> void:
	_toast_busy = true
	while not _toast_queue.is_empty():
		_toast_title.text = _toast_queue.pop_front()
		_toast_panel.visible = true
		var tween := create_tween()
		tween.tween_property(_toast_panel, "modulate:a", 1.0, NOTIFICATION_FADE_TIME)
		tween.tween_interval(NOTIFICATION_VISIBLE_TIME - NOTIFICATION_FADE_TIME * 2.0)
		tween.tween_property(_toast_panel, "modulate:a", 0.0, NOTIFICATION_FADE_TIME)
		await tween.finished
	_toast_panel.visible = false
	_toast_busy = false
