extends Node3D
## Quick testing zone for the existing MonsterAI (scenes/enemy.tscn).
## Builds a floor with pillars, bakes a navigation mesh at start-up (the monster needs one to
## move), spawns the player and the monster, and shows a small debug UI.
## R resets the test. When the monster catches you, a placeholder message appears
## (this is where the game "crash" will be hooked in later).

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

var monster: MonsterAI
var player: PlayerController
var _region: NavigationRegion3D
var _status_label: Label
var _caught_overlay: Control
var _caught := false


func _ready() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.03, 0.04, 0.05)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.28, 0.33)
	environment.ambient_light_energy = 0.6
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.6
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)

	_build_arena()
	player = load("res://scenes/player.tscn").instantiate() as PlayerController
	add_child(player)
	player.global_position = Vector3(0, 1.1, 22)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	_build_ui()
	_spawn_monster_after_bake()


func _build_arena() -> void:
	_region = NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	_region.navigation_mesh = nav_mesh
	add_child(_region)
	# Everything the monster should walk on / around is a child of the region.
	add_box(_region, Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color(0.12, 0.13, 0.12))
	for wall in [[Vector3(0, 2, -30.5), Vector3(61, 4, 1)], [Vector3(0, 2, 30.5), Vector3(61, 4, 1)],
			[Vector3(-30.5, 2, 0), Vector3(1, 4, 61)], [Vector3(30.5, 2, 0), Vector3(1, 4, 61)]]:
		add_box(_region, wall[0], wall[1], Color(0.2, 0.18, 0.16))
	var pillars := [Vector3(-8, 0, 8), Vector3(8, 0, 8), Vector3(-8, 0, -6), Vector3(8, 0, -6), Vector3(0, 0, 0), Vector3(-16, 0, 0), Vector3(16, 0, 0)]
	for pillar in pillars:
		add_box(_region, pillar + Vector3(0, 2, 0), Vector3(2.5, 4, 2.5), Color(0.25, 0.22, 0.2))
	_region.bake_navigation_mesh(false)


func _spawn_monster_after_bake() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	monster = ENEMY_SCENE.instantiate() as MonsterAI
	monster.attack_damage = 100.0 # one catch = dead, so the "caught" event is easy to test
	monster.scale = Vector3.ONE * 0.35 # the stock monster is city-sized
	monster.sight_detection_range = 30.0
	monster.head_start_time = 5.0 # stock value is 30 s of grace before it hunts
	add_child(monster)
	monster.global_position = Vector3(0, 0.5, -20)


# ------------------------------------------------------------------ debug UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_status_label = Label.new()
	_status_label.position = Vector2(24, 120)
	_status_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_status_label.add_theme_constant_override("outline_size", 5)
	layer.add_child(_status_label)

	_caught_overlay = ColorRect.new()
	(_caught_overlay as ColorRect).color = Color(0.4, 0.0, 0.0, 0.7)
	_caught_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caught_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caught_overlay.visible = false
	layer.add_child(_caught_overlay)
	var message := Label.new()
	message.text = "CAUGHT\n\n(the game crash will be triggered here later)\n\nPress R to try again"
	message.set_anchors_preset(Control.PRESET_FULL_RECT)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 26)
	_caught_overlay.add_child(message)


func _process(_delta: float) -> void:
	if _status_label == null or player == null:
		return
	var state_name := "spawning..."
	var distance_text := "-"
	if is_instance_valid(monster):
		state_name = MonsterAI.State.keys()[monster.state]
		distance_text = "%.1f m" % monster.global_position.distance_to(player.global_position)
	_status_label.text = "HEALTH: %d / %d\nMONSTER: %s\nDISTANCE: %s\n[R] reset" % [player.health, player.max_health, state_name, distance_text]


func _on_player_damaged(_amount: float, _health_left: float) -> void:
	GameState.show_hint("The monster got you.", 2.0)


func _on_player_died() -> void:
	_caught = true
	_caught_overlay.visible = true
	# Placeholder: later this is where the fake crash / ending hook goes.
	print("[MonsterTest] Player caught by the monster.")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()


## Solid coloured box with collision (child of `parent`).
func add_box(parent: Node, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	parent.add_child(body)
