extends Node3D
class_name PlayerFlashlight
## First-person flashlight. You "own" it when the Inventory holds the item "flashlight".
## F (the existing "flashlight" input action) or clicking it in the inventory toggles the beam.

const ITEM_ID := "flashlight"

## Give the flashlight as soon as the player spawns (untick in the Inspector to make it a pickup again).
@export var start_with_flashlight := true

var is_on := false

var _player: PlayerController
var _inventory: Inventory

@onready var viewmodel: Node3D = $Viewmodel
@onready var beam: SpotLight3D = $Beam


func _ready() -> void:
	_player = get_parent().get_parent() as PlayerController # Camera3D -> Player
	_inventory = _player.get_node_or_null("Inventory") as Inventory
	if _inventory == null:
		push_warning("PlayerFlashlight: no Inventory on the player.")
		return
	_inventory.item_added.connect(_on_item_added)
	_inventory.item_removed.connect(_on_inventory_changed)
	_inventory.item_used.connect(_on_item_used)
	if start_with_flashlight and not is_owned():
		_inventory.add_item(ITEM_ID)
	_update()


func is_owned() -> bool:
	return _inventory != null and _inventory.get_item_count(ITEM_ID) > 0


func set_on(value: bool) -> void:
	is_on = value
	_update()


func toggle() -> void:
	if not is_owned():
		return
	set_on(not is_on)
	ProcAudio.play(self, "click", -6.0)


func _update() -> void:
	viewmodel.visible = is_owned()
	beam.visible = is_owned() and is_on


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight") and not _player.input_locked:
		toggle()


func _on_item_added(item_id: String, count: int) -> void:
	if item_id == ITEM_ID and count == 1:
		GameState.show_hint("Flashlight acquired. Press F to turn it on.", 4.0)
	_update()


func _on_inventory_changed(_item_id: String, _count: int) -> void:
	_update()


## Clicking the flashlight in the inventory screen "uses" (consumes) it, so give it back and toggle.
func _on_item_used(item_id: String) -> void:
	if item_id != ITEM_ID:
		return
	_inventory.add_item(ITEM_ID)
	toggle()
