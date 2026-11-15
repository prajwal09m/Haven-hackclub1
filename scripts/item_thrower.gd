extends Node
class_name ItemThrower
## Drop and throw the selected inventory item.
##   1 / 2   select the item in HUD slot 1 or 2
##   G       drop it at your feet
##   T       HOLD to bring it back (charging), RELEASE to throw. A quick tap cancels.
## Thrown and dropped items land as pickups you can collect again with E.

const DROP_ACTION := "drop_item"
const THROW_ACTION := "throw_item"
const MAX_CHARGE_TIME := 1.2
const MIN_CHARGE_TO_THROW := 0.12
const MIN_THROW_SPEED := 5.0
const MAX_THROW_SPEED := 17.0
const HELD_REST := Vector3(0.3, -0.25, -0.5)
const HELD_BACK := Vector3(0.42, -0.1, -0.02)
const FLASHLIGHT_MODEL: PackedScene = preload("res://prefabs/flashlight_model.tscn")

var selected_index := 0

var _player: PlayerController
var _inventory: Inventory
var _hud: Node
var _charging := false
var _charge := 0.0
var _held_prop: Node3D


func _ready() -> void:
	_player = get_parent() as PlayerController
	_inventory = _player.get_node_or_null("Inventory") as Inventory
	_hud = _player.get_node_or_null("PickupHud")
	_select(0)


func _slot_ids() -> Array:
	if _hud and "slot_item_ids" in _hud:
		return _hud.slot_item_ids
	return ["flashlight"]


func selected_item_id() -> String:
	var ids := _slot_ids()
	return str(ids[clampi(selected_index, 0, ids.size() - 1)])


func _select(index: int) -> void:
	if _charging:
		return
	selected_index = clampi(index, 0, maxi(_slot_ids().size() - 1, 0))
	if _hud and _hud.has_method("set_selected_slot"):
		_hud.set_selected_slot(selected_index)


func _unhandled_input(event: InputEvent) -> void:
	if _player.input_locked or get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_select(0)
		elif event.keycode == KEY_2:
			_select(1)
	if event.is_action_pressed(DROP_ACTION):
		drop_selected()
	elif event.is_action_pressed(THROW_ACTION):
		begin_charge()
	elif event.is_action_released(THROW_ACTION):
		release_throw()


func _process(delta: float) -> void:
	if not _charging:
		return
	if _player.input_locked or _inventory.get_item_count(selected_item_id()) <= 0:
		_end_charge_visuals()
		return
	_charge = minf(_charge + delta / MAX_CHARGE_TIME, 1.0)
	_held_prop.position = HELD_REST.lerp(HELD_BACK, _charge)
	_held_prop.rotation_degrees.x = 35.0 * _charge


# ------------------------------------------------------------------ drop

func drop_selected() -> void:
	if _charging:
		return
	var item_id := selected_item_id()
	if _inventory.get_item_count(item_id) <= 0:
		GameState.show_hint("You aren't carrying that.", 1.5)
		return
	_inventory.remove_item(item_id, 1)
	_spawn_item(item_id, 1.5)


# ------------------------------------------------------------------ throw

func begin_charge() -> void:
	var item_id := selected_item_id()
	if _inventory.get_item_count(item_id) <= 0:
		GameState.show_hint("You aren't carrying that.", 1.5)
		return
	_charging = true
	_charge = 0.0
	_held_prop = _make_visual(item_id)
	_held_prop.position = HELD_REST
	_player.camera.add_child(_held_prop)
	_set_flashlight_viewmodel_hidden(item_id == PlayerFlashlight.ITEM_ID)


func release_throw() -> void:
	if not _charging:
		return
	var item_id := selected_item_id()
	var charge := _charge
	_end_charge_visuals()
	if charge < MIN_CHARGE_TO_THROW:
		return
	_inventory.remove_item(item_id, 1)
	_spawn_item(item_id, lerpf(MIN_THROW_SPEED, MAX_THROW_SPEED, charge))


func _end_charge_visuals() -> void:
	_charging = false
	_charge = 0.0
	if is_instance_valid(_held_prop):
		_held_prop.queue_free()
	_held_prop = null
	_set_flashlight_viewmodel_hidden(false)


## The in-hand flashlight model is hidden while the held "prop" replaces it.
func _set_flashlight_viewmodel_hidden(hide_it: bool) -> void:
	var flashlight := _player.camera.get_node_or_null("Flashlight") as PlayerFlashlight
	if flashlight == null:
		return
	if hide_it:
		flashlight.viewmodel.visible = false
	else:
		flashlight.set_on(flashlight.is_on) # redraws from the real inventory state


# ------------------------------------------------------------------ world item

func _make_visual(item_id: String) -> Node3D:
	if item_id == PlayerFlashlight.ITEM_ID:
		return FLASHLIGHT_MODEL.instantiate() as Node3D
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.18, 0.18, 0.18)
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	match item_id:
		"key1":
			material.albedo_color = Color(0.9, 0.75, 0.2)
		"medkit":
			material.albedo_color = Color(0.8, 0.1, 0.1)
		_:
			material.albedo_color = Color.from_hsv(float(absi(item_id.hash()) % 360) / 360.0, 0.6, 0.8)
	mesh_instance.material_override = material
	return mesh_instance


func _spawn_item(item_id: String, speed: float) -> void:
	var camera := _player.camera
	var forward := -camera.global_transform.basis.z
	var body := RigidBody3D.new()
	body.collision_layer = 2 # the interact ray only sees the pickup area below, not this body
	body.collision_mask = 1
	body.mass = 0.5
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.body_entered.connect(func(other: Node) -> void:
		if other is MonsterAI and body.linear_velocity.length() > 3.0:
			other.stun(3.0)
			GameState.show_hint("Stunned it!", 1.5))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.12, 0.12, 0.3) if item_id == PlayerFlashlight.ITEM_ID else Vector3(0.2, 0.2, 0.2)
	shape.shape = box
	body.add_child(shape)
	body.add_child(_make_visual(item_id))

	var pickup := DroppedPickup.new()
	pickup.item_id = item_id
	pickup.display_name = item_id.capitalize()
	pickup.amount = 1
	var pickup_shape := CollisionShape3D.new()
	var pickup_box := BoxShape3D.new()
	pickup_box.size = Vector3(0.6, 0.6, 0.6)
	pickup_shape.shape = pickup_box
	pickup.add_child(pickup_shape)
	body.add_child(pickup)

	_player.get_parent().add_child(body)
	body.global_position = camera.global_position + forward * 0.7 + Vector3.DOWN * 0.35
	body.linear_velocity = forward * speed + Vector3.UP * speed * 0.12
	body.angular_velocity = Vector3(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
