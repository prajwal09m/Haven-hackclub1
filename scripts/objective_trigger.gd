extends Area3D
class_name ObjectiveTrigger
## Drop-in area: completes an objective when the player enters it.
## Add an Area3D with this script and a CollisionShape3D, then set objective_id in the inspector.

@export var objective_id: String = ""
@export var one_shot: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if objective_id.is_empty() or not body.is_in_group("player"):
		return
	ObjectiveManager.complete_objective(objective_id)
	if one_shot:
		set_deferred("monitoring", false)
