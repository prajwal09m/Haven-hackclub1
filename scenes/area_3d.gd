extends Area3D

var computer_ui

func _ready() -> void:
	computer_ui = get_tree().root.find_child("ComputerUI", true, false)
	if computer_ui:
		print("COMPUTER UI FOUND!")
	else:
		print("COMPUTER UI NOT FOUND!")

	input_ray_pickable = true
	input_event.connect(_on_input_event)

func _on_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if computer_ui:
			computer_ui.open_computer()
			
func interact() -> void:
	if computer_ui:
		computer_ui.open_computer()
