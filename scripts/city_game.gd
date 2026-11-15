extends Node3D
## Game logic for CityLevel:
##  1. bakes a navigation mesh around the player's start (the monster needs one to move)
##  2. spawns the monster
##  3. when the monster catches the player: fake "program crashed" window, then quits.

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")

@export var monster_spawn_offset := Vector3(0, 0.5, 30)
@export var bake_size := Vector3(260, 12, 260)
@export var quit_on_crash := true

var player: PlayerController
var monster: MonsterAI
var crashed := false


func _ready() -> void:
	player = get_node_or_null("Player") as PlayerController
	if player == null:
		push_error("CityGame: no Player node.")
		return
	player.died.connect(_on_player_died)
	await get_tree().physics_frame
	_bake_navigation()
	await get_tree().physics_frame
	_spawn_monster()
	_setup_bounce_hud()


func _bake_navigation() -> void:
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.cell_size = 0.5
	nav_mesh.cell_height = 0.25
	var centre := player.global_position
	nav_mesh.filter_baking_aabb = AABB(centre - bake_size * 0.5, bake_size)
	var source := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, source, self)
	NavigationServer3D.bake_from_source_geometry_data(nav_mesh, source)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav_mesh
	add_child(region)


## Hounds start at BASE_CHASE_SPEED and speed up over the run (up to END_CHASE_SPEED).
## Player: walk 5, sprint 8 (but sprinting drains stamina). The hound never loses you.
const BASE_CHASE_SPEED := 5.6
const END_CHASE_SPEED := 8.6
const SECOND_HOUND_AT := 40.0 # seconds into the run

var hounds: Array[MonsterAI] = []
var _second_hound_spawned := false


func _spawn_monster() -> void:
	monster = _make_hound(monster_spawn_offset)


func _make_hound(offset: Vector3) -> MonsterAI:
	var hound := ENEMY_SCENE.instantiate() as MonsterAI
	hound.attack_damage = 100.0 # one catch = caught
	hound.speed = 4.0
	hound.chase_speed = BASE_CHASE_SPEED
	hound.sight_detection_range = 60.0
	hound.lose_range = 400.0
	hound.always_hunt = true # never loses you
	add_child(hound)
	hound.global_position = player.global_position + offset
	hounds.append(hound)
	return hound


func _on_player_died() -> void:
	if crashed or _won:
		return
	if lives > 0:
		_bounce_back()
		return
	crashed = true
	print("[CityGame] Player caught - triggering fake crash.")
	_show_fake_crash()


func _show_fake_crash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)

	# CenterContainer keeps the box centred at any window size.
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(centre)
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.93, 0.93)
	style.border_color = Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	box.add_theme_stylebox_override("panel", style)
	centre.add_child(box)

	var v := VBoxContainer.new()
	box.add_child(v)
	var title := Label.new()
	title.text = "horror.exe"
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	v.add_child(title)
	var message := Label.new()
	message.text = "\nhorror.exe has stopped working.\n\nSomething found you.\n"
	message.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	v.add_child(message)
	var button := Button.new()
	button.text = "Close program"
	button.pressed.connect(_quit_now)
	v.add_child(button)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if quit_on_crash:
		get_tree().create_timer(4.0, true, false, true).timeout.connect(_quit_now)


func _quit_now() -> void:
	if quit_on_crash:
		get_tree().quit()


# ---------------------------------------------------------------- BOUNCE BACK + survive 90 s
@export var lives := 1            # extra lives: caught once = you bounce back
@export var survive_seconds := 120.0

var _start_pos: Vector3
var _time_left := 0.0
var _won := false
var _hud: Label
var _banner: Label
var _stamina_bar: ProgressBar


func _enter_tree() -> void:
	_time_left = survive_seconds


func _setup_bounce_hud() -> void:
	_start_pos = player.global_position
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	# Full-screen root: every child below is anchored to it, so the layout scales with the window.
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# Top strip: timer text, then the stamina bar, both centred.
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 14
	top.offset_bottom = 70
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	_hud = Label.new()
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_theme_font_size_override("font_size", 18)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	top.add_child(_hud)

	var bar_row := CenterContainer.new()
	bar_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(bar_row)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.max_value = player.max_stamina
	_stamina_bar.show_percentage = false
	_stamina_bar.custom_minimum_size = Vector2(240, 14)
	bar_row.add_child(_stamina_bar)

	# Message banner: full width, centred text, wraps if long.
	_banner = Label.new()
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.18
	_banner.anchor_bottom = 0.18
	_banner.offset_left = 40
	_banner.offset_right = -40
	_banner.offset_top = 0
	_banner.offset_bottom = 120
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_theme_font_size_override("font_size", 26)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_banner)
	_say("SURVIVE %d seconds. The hound never stops. Sprint (SHIFT) is limited. Throw things (T) to stun it." % int(survive_seconds), 6.0)


func _say(text: String, seconds: float) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func _process(delta: float) -> void:
	if _hud == null or crashed or _won:
		return
	_time_left -= delta
	var elapsed := survive_seconds - _time_left
	var chase_speed := lerpf(BASE_CHASE_SPEED, END_CHASE_SPEED, clampf(elapsed / survive_seconds, 0.0, 1.0))
	for hound in hounds:
		if is_instance_valid(hound):
			hound.chase_speed = chase_speed
	if not _second_hound_spawned and elapsed >= SECOND_HOUND_AT:
		_second_hound_spawned = true
		_make_hound(Vector3(-35, 0.5, -35))
		_say("A SECOND HOUND HAS JOINED THE HUNT.", 4.0)
	if _stamina_bar:
		_stamina_bar.value = player.stamina
	_hud.text = "HAVEN IN: %d s   |   BOUNCE-BACKS LEFT: %d   |   HOUNDS: %d" % [maxi(ceili(_time_left), 0), lives, hounds.size()]
	if _time_left <= 0.0:
		_win()


func _bounce_back() -> void:
	lives -= 1
	player.is_dead = false
	player.health = player.max_health
	player.set_input_locked(false)
	player.global_position = _start_pos
	var i := 0
	for hound in hounds:
		if is_instance_valid(hound):
			hound.stunned_until = 0.0
			hound.global_position = _start_pos + monster_spawn_offset + Vector3(i * 25.0, 0, 0)
			i += 1
	_say("YOU BOUNCED BACK.\nDon't get caught again.", 3.5)


func _win() -> void:
	_won = true
	player.set_input_locked(true)
	if is_instance_valid(monster):
		monster.set_physics_process(false)
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0.85)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(black)
	var text := Label.new()
	text.text = "YOU REACHED THE HAVEN.\n\nYou bounced back.\n\nThanks for playing."
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 32)
	layer.add_child(text)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
