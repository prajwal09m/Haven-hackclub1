extends Control
## Ending B (true ending): the entity records were deleted. Detective M walks out of Room 6.

const PAGES: Array[String] = [
	"The registry is empty.\n\nNot hidden. Not rewritten. Empty.",
	"The terminal does not blink. No new messages.\nThe room smells of dust and old carpet, not wet pine.",
	"The door is only a door.\nNo knocking. No scratching. Nothing waits on the other side.",
	"In the forest, a circle of stones stands in the morning light.\nA grey robe lies folded on a log. Nobody is coming back for it.",
	"Detective M carries Clara Whitlow's diary down to the street.\nEleven names go to the council. Twelve, with hers.",
	"The sender never writes again.\n\nSomewhere, a prisoner is finally allowed to be a person.",
	"HAVEN\n\nTHE TRUE ENDING",
]

var _label: Label
var _button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.02, 0.03, 0.03)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", Color(0.75, 0.9, 0.78))
	_label.modulate.a = 0.0
	add_child(_label)
	_button = Button.new()
	_button.text = "QUIT"
	_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_button.offset_bottom = -40
	_button.visible = false
	_button.pressed.connect(GameState.quit_game)
	add_child(_button)
	_run()


func _run() -> void:
	for page in PAGES:
		_label.text = page
		var tween := create_tween()
		tween.tween_property(_label, "modulate:a", 1.0, 1.0)
		tween.tween_interval(3.2)
		tween.tween_property(_label, "modulate:a", 0.0, 0.8)
		await tween.finished
	_label.text = PAGES[PAGES.size() - 1]
	_label.modulate.a = 1.0
	GameState.complete_true_ending()
	_button.visible = true
