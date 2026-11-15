extends CanvasLayer

const PASSWORD := "1234"  # change this

@onready var panel: Panel = $Panel
@onready var label: Label = $Panel/Label
@onready var line_edit: LineEdit = $Panel/Label/LineEdit
@onready var button: Button = $Panel/Label/LineEdit/Button

func _ready() -> void:
	panel.visible = false
	label.text = "ENTER PASSWORD"
	button.pressed.connect(_on_button_pressed)
	line_edit.text_submitted.connect(func(_t): _on_button_pressed())

func open_computer() -> void:
	print("COMPUTER OPENED!")
	panel.visible = true
	line_edit.clear()
	line_edit.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # free the cursor
	var player = get_tree().root.find_child("Player", true, false)
	if player: player.set_ui_locked(true)  # false in close_computer()
	

func close_computer() -> void:
	panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # back to first-person
	var player = get_tree().root.find_child("Player", true, false)
	if player: player.set_ui_locked(true)  # false in close_computer()

func _on_button_pressed() -> void:
	if line_edit.text == PASSWORD:
		label.text = "ACCESS GRANTED"
		await get_tree().create_timer(1.0).timeout
		close_computer()
	else:
		label.text = "WRONG PASSWORD"
		line_edit.clear()

func _unhandled_input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("ui_cancel"):
		close_computer()
