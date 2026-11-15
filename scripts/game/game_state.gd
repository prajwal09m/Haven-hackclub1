extends Node
## Autoload: GameState. Story flags, chapter flow, scene transitions, hint text and the
## persistent ending state (user://haven_save.cfg).

signal email_delivered(email_id: String)
signal story_event(event_name: String)
signal invitation_accepted

const SAVE_PATH := "user://haven_save.cfg"
const SCENE_HOTEL := "res://scenes/chapters/hotel_room.tscn"
const SCENE_FOREST := "res://scenes/chapters/forest.tscn"
const SCENE_CAPTURE := "res://scenes/endings/capture_ending.tscn"
const SCENE_TRUE_ENDING := "res://scenes/endings/true_ending.tscn"

# ---- persistent (saved) ----
var captures := 0
var ending_transformed := false
var ending_deletion := false
var deletion_stage := "none" # none | pending | verified
var entities_removed := false
var registry_token := ""
var saved_chapter := 1
## Messages produced by the launch-time registry check (shown on the title screen).
var launch_log: Array[String] = []

# ---- session ----
var chapter := 1
var flags: Dictionary = {}
var delivered_emails: Array[String] = []
var read_emails: Dictionary = {}
var revolver_rounds := 4
## Tests set this so ending sequences do not close the editor/test runner.
var suppress_quit := false

var _fade_rect: ColorRect
var _hint_label: Label
var _hint_tween: Tween
var _transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_load_save()
	_verify_registry_on_launch()


# ------------------------------------------------------------------ overlay (fade + hints)

func _build_overlay() -> void:
	var hint_layer := CanvasLayer.new()
	hint_layer.layer = 60
	add_child(hint_layer)
	_hint_label = Label.new()
	_hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint_label.offset_bottom = -70
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	_hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint_label.add_theme_constant_override("outline_size", 6)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.modulate.a = 0.0
	hint_layer.add_child(_hint_label)

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	fade_layer.add_child(_fade_rect)


func show_hint(text: String, seconds: float = 4.5) -> void:
	if _hint_label == null:
		return
	_hint_label.text = text
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_label, "modulate:a", 1.0, 0.2)
	_hint_tween.tween_interval(seconds)
	_hint_tween.tween_property(_hint_label, "modulate:a", 0.0, 0.6)


func _fade(target_alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, seconds)
	await tween.finished


func fade_out(seconds: float = 0.6) -> void:
	await _fade(1.0, seconds)


func fade_in(seconds: float = 0.6) -> void:
	await _fade(0.0, seconds)


## Fades out, swaps the scene, fades back in. Simple and synchronous: no loading architecture.
func change_scene(path: String, fade_seconds: float = 0.6) -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade(1.0, fade_seconds)
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("[GameState] Could not load scene %s (error %d)" % [path, error])
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(0.0, fade_seconds)
	_transitioning = false


# ------------------------------------------------------------------ chapter flow

func new_game() -> void:
	_reset_session()
	saved_chapter = 1
	start_chapter(1)


func continue_game() -> void:
	_reset_session()
	start_chapter(clampi(saved_chapter, 1, 3))


func _reset_session() -> void:
	flags.clear()
	delivered_emails.clear()
	read_emails.clear()
	revolver_rounds = 4
	chapter = 1
	ObjectiveManager.clear_objectives()


## Starts chapter n (1-3): rebuilds objectives and inbox for it and loads its scene.
## Earlier chapters' objectives/emails are filled in as already done, so any chapter can be a start point.
func start_chapter(n: int, load_scene: bool = true) -> void:
	chapter = n
	saved_chapter = maxi(saved_chapter, n)
	save_game()
	_setup_objectives(n)
	_setup_emails(n)
	if n >= 2:
		flags["coords_found"] = true
	if n >= 3:
		flags["note_found"] = true
	if not load_scene:
		return
	if n == 3 and entities_removed:
		change_scene(SCENE_TRUE_ENDING)
	elif n == 2:
		change_scene(SCENE_FOREST)
	else:
		change_scene(SCENE_HOTEL)


func _setup_objectives(n: int) -> void:
	ObjectiveManager.clear_objectives()
	for objective in StoryData.OBJECTIVES:
		if objective["chapter"] < n:
			ObjectiveManager.register_objective(objective["id"], objective["title"], true)
		elif objective["chapter"] == n and objective["initial"]:
			ObjectiveManager.register_objective(objective["id"], objective["title"], false)


func _setup_emails(n: int) -> void:
	deliver_email("e1_welcome", false)
	if n >= 2:
		for id in ["e2_whitlow", "e3_coordinates"]:
			deliver_email(id, false)
		for id in delivered_emails:
			read_emails[id] = true
	if n >= 3 and not entities_removed:
		deliver_email("e4_invitation", false)


func _register_objective(objective_id: String) -> void:
	if ObjectiveManager.has_objective(objective_id):
		return
	for objective in StoryData.OBJECTIVES:
		if objective["id"] == objective_id:
			ObjectiveManager.register_objective(objective_id, objective["title"])


func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value


func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)


# ------------------------------------------------------------------ story events

func deliver_email(email_id: String, notify: bool = true) -> void:
	if delivered_emails.has(email_id):
		return
	delivered_emails.append(email_id)
	email_delivered.emit(email_id)
	if notify:
		show_hint("New message received.")
		ProcAudio.play(self, "chime", -6.0)


func on_email_opened(email_id: String) -> void:
	read_emails[email_id] = true
	if email_id == "e1_welcome" and ObjectiveManager.complete_objective("read_first_email"):
		_register_objective("investigate_woman")
		show_hint("Someone knows which room I'm in. Check the drawer and the room.")
		get_tree().create_timer(3.0).timeout.connect(func() -> void: deliver_email("e2_whitlow"))


func on_attachment_opened(_email_id: String, attachment_name: String) -> void:
	match attachment_name:
		"whitlow_report.txt":
			add_clue("report")
		"harrow_survey.dat":
			set_flag("coords_found")
			if ObjectiveManager.complete_objective("find_coordinates"):
				show_hint("Harrow Forest. The hotel door will take me to the old logging road.", 6.0)
				story_event.emit("coords_found")


func add_clue(clue: String) -> void:
	if has_flag("clue_" + clue):
		return
	set_flag("clue_" + clue)
	story_event.emit("clue_" + clue)
	if chapter == 1:
		if has_flag("clue_diary") and has_flag("clue_clipping") and has_flag("clue_report"):
			if ObjectiveManager.complete_objective("investigate_woman"):
				_register_objective("find_coordinates")
				show_hint("They were all written to by the same sender. Another message is coming.", 5.0)
				get_tree().create_timer(3.5).timeout.connect(func() -> void: deliver_email("e3_coordinates"))
	elif chapter == 2:
		if has_flag("clue_symbol") and has_flag("clue_robe") and has_flag("clue_ledger"):
			if ObjectiveManager.complete_objective("investigate_cult"):
				set_flag("cult_investigated")
				story_event.emit("cult_investigated")


func on_note_found() -> void:
	if has_flag("note_found"):
		return
	set_flag("note_found")
	if ObjectiveManager.complete_objective("find_note"):
		_register_objective("return_hotel")
		show_hint("Back to the car. Back to the hotel.", 5.0)


func on_program_opened() -> void:
	if ObjectiveManager.complete_objective("open_attachment"):
		_register_objective("reach_ritual")


func accept_invitation() -> void:
	if has_flag("accepted"):
		return
	set_flag("accepted")
	invitation_accepted.emit()


# ------------------------------------------------------------------ endings

## Ending A. Saves the capture state first, then plays the capture sequence scene.
func begin_capture_ending() -> void:
	captures += 1
	ending_transformed = true
	save_game()
	change_scene(SCENE_CAPTURE, 1.0)


## Ending A epilogue: cleanly close the game (the scripted fourth-wall moment).
func finish_capture_ending_and_quit() -> void:
	save_game()
	if suppress_quit:
		return
	get_tree().quit()


func quit_game() -> void:
	save_game()
	if not suppress_quit:
		get_tree().quit()


func start_true_ending() -> void:
	change_scene(SCENE_TRUE_ENDING, 1.0)


func complete_true_ending() -> void:
	ending_deletion = true
	save_game()


## Ending B, step 1: write the registry files into user://entity_records and arm the check.
func write_registry_files() -> bool:
	if registry_token == "":
		registry_token = _make_token()
	if not EntityRecords.create_files(registry_token):
		return false
	if deletion_stage != "verified":
		deletion_stage = "pending"
	save_game()
	return true


func _make_token() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x" % rng.randi()


## Ending B, step 2: run at every launch. Only a fully valid edit unlocks the true ending.
func _verify_registry_on_launch() -> void:
	if deletion_stage != "pending":
		return
	var check := EntityRecords.verify(registry_token)
	match check["result"]:
		EntityRecords.Result.VALID:
			deletion_stage = "verified"
			entities_removed = true
			launch_log.append("[REGISTRY] Verified. 0 entity records found. The entities have been removed.")
		EntityRecords.Result.UNCHANGED:
			launch_log.append("[REGISTRY] No change detected. The entities are still bound.")
		EntityRecords.Result.PARTIAL:
			launch_log.append("[REGISTRY] Incomplete edit: %s Nothing was changed." % check["message"])
		EntityRecords.Result.MISSING:
			EntityRecords.create_files(registry_token)
			launch_log.append("[REGISTRY] The registry was deleted. A fresh copy has been written.")
		_:
			EntityRecords.create_files(registry_token)
			launch_log.append("[REGISTRY] Rejected: %s The registry was rebuilt." % check["message"])
	save_game()


# ------------------------------------------------------------------ save / load

func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("haven", "captures", captures)
	config.set_value("haven", "ending_transformed", ending_transformed)
	config.set_value("haven", "ending_deletion", ending_deletion)
	config.set_value("haven", "deletion_stage", deletion_stage)
	config.set_value("haven", "entities_removed", entities_removed)
	config.set_value("haven", "registry_token", registry_token)
	config.set_value("haven", "saved_chapter", saved_chapter)
	config.save(SAVE_PATH)


func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	captures = int(config.get_value("haven", "captures", 0))
	ending_transformed = bool(config.get_value("haven", "ending_transformed", false))
	ending_deletion = bool(config.get_value("haven", "ending_deletion", false))
	deletion_stage = str(config.get_value("haven", "deletion_stage", "none"))
	entities_removed = bool(config.get_value("haven", "entities_removed", false))
	registry_token = str(config.get_value("haven", "registry_token", ""))
	saved_chapter = int(config.get_value("haven", "saved_chapter", 1))


## Debug/test: wipe saved progress and Haven's own registry files (nothing else).
func reset_save() -> void:
	captures = 0
	ending_transformed = false
	ending_deletion = false
	deletion_stage = "none"
	entities_removed = false
	registry_token = ""
	saved_chapter = 1
	launch_log.clear()
	for path in [EntityRecords.REGISTRY_PATH, EntityRecords.README_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_game()
