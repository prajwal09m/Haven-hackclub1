extends PickupItem
class_name DroppedPickup
## A pickup that lives on a physics body (dropped or thrown by the player).
## Picking it up gives the item back and removes the whole body, not just this Area3D.


func collect(collector: Node) -> void:
	if collector and collector.has_method("pickup_item"):
		collector.pickup_item(item_id, amount)
		var body := get_parent()
		if body:
			body.queue_free()
		else:
			queue_free()
