extends CanvasLayer

# Which item each slot shows. You can change these in the Inspector.
@export var slot_item_ids: Array[String] = ["flashlight", "key1"]
@export var slot_icons: Array[Texture2D] = []

# Grab the two slot nodes from the scene tree.
@onready var slots: Array[PanelContainer] = [
		$Anchor/Slots/Slot1,
		$Anchor/Slots/Slot2,
]

var inventory: Inventory


func _ready() -> void:
		# This HUD is a child of the player, so the player is our parent.
		inventory = get_parent().get_node_or_null("Inventory") as Inventory
		if inventory == null:
				push_warning("PickupHud: no Inventory node found on the player.")
				return

		# Run _on_inventory_changed whenever something is added or removed.
		inventory.item_added.connect(_on_inventory_changed)
		inventory.item_removed.connect(_on_inventory_changed)

		# Put the icons in once, then draw the starting state.
		for i in slots.size():
				if i < slot_icons.size():
						slots[i].get_node("VBox/Icon").texture = slot_icons[i]
		_refresh()


func _on_inventory_changed(_item_id: String, _count: int) -> void:
		_refresh()


func _refresh() -> void:
		for i in slots.size():
				if i >= slot_item_ids.size():
						continue
				var count := inventory.get_item_count(slot_item_ids[i])
				var icon: TextureRect = slots[i].get_node("VBox/Icon")
				var label: Label = slots[i].get_node("VBox/CountLabel")
				label.text = "%s x%d" % [slot_item_ids[i].to_upper().left(5), count]
				# Dim the icon when you don't own the item.
				icon.modulate = Color.WHITE if count > 0 else Color(1, 1, 1, 0.25)


# Called by the item thrower: brighten the selected slot, dim the other.
func set_selected_slot(index: int) -> void:
	for i in slots.size():
		slots[i].self_modulate = Color.WHITE if i == index else Color(0.55, 0.55, 0.55)
