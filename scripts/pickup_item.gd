extends Area3D
class_name PickupItem

@export var item_id: String = "medkit"
@export var display_name: String = "Medkit"
@export var amount: int = 1
## Optional: objective completed when this item is collected (empty = none).
@export var completes_objective_id: String = ""

func get_item_id() -> String:
	return item_id

func get_display_name() -> String:
	return display_name

func collect(collector: Node) -> void:
	if collector and collector.has_method("pickup_item"):
		collector.pickup_item(item_id, amount)
		if not completes_objective_id.is_empty():
			ObjectiveManager.complete_objective(completes_objective_id)
		queue_free()
