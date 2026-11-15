extends Node
## Global objective tracker (Autoload name: ObjectiveManager).
## Knows nothing about the UI; the UI and gameplay scripts talk to it via the API and signals.
##
## Usage from any script:
##     ObjectiveManager.complete_objective("inspect_computer")

## Emitted when a new objective is registered.
signal objective_registered(objective_id: String)
## Emitted whenever the objective list or any completion state changes (UI refresh hook).
signal objectives_changed
## Emitted exactly once per objective, the moment it becomes completed.
signal objective_completed(objective_id: String, objective_title: String)

## Initial objectives. Edit this list to add / rename / reorder objectives.
## Each entry: { "id": unique String, "title": display String }
## Haven's story objectives are registered per chapter by GameState (see StoryData.OBJECTIVES),
## so this list is empty. Put any always-present objectives here.
const DEFAULT_OBJECTIVES: Array[Dictionary] = []

## Enables the F9 dev shortcut (completes the next unfinished objective). Debug builds only.
@export var enable_debug_shortcut: bool = true

var _objective_order: Array[String] = []
var _objective_titles: Dictionary = {}      # id -> String
var _objective_completed: Dictionary = {}   # id -> bool


func _ready() -> void:
	# Keep working while the tree is paused (e.g. inventory open).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for entry in DEFAULT_OBJECTIVES:
		register_objective(entry["id"], entry["title"])


func _unhandled_input(event: InputEvent) -> void:
	if not (enable_debug_shortcut and OS.is_debug_build()):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		debug_complete_next_objective()


# ---------------------------------------------------------------- Public API

## Registers an objective. Returns false (and keeps the existing one) if the ID is already used.
func register_objective(objective_id: String, objective_title: String, already_completed: bool = false) -> bool:
	if objective_id.is_empty():
		push_warning("[ObjectiveManager] Cannot register an objective with an empty ID.")
		return false
	if _objective_titles.has(objective_id):
		push_warning("[ObjectiveManager] Objective '%s' is already registered." % objective_id)
		return false
	_objective_order.append(objective_id)
	_objective_titles[objective_id] = objective_title
	_objective_completed[objective_id] = already_completed # silently pre-completed: no signal
	objective_registered.emit(objective_id)
	objectives_changed.emit()
	return true


## Removes every objective (used when a new game / chapter list is built). Emits objectives_changed.
func clear_objectives() -> void:
	_objective_order.clear()
	_objective_titles.clear()
	_objective_completed.clear()
	objectives_changed.emit()


## Completes an objective. Returns true only if this call completed it;
## unknown IDs and repeat calls return false and emit nothing.
func complete_objective(objective_id: String) -> bool:
	if not _objective_titles.has(objective_id):
		push_warning("[ObjectiveManager] Unknown objective ID '%s'." % objective_id)
		return false
	if _objective_completed[objective_id]:
		return false
	_objective_completed[objective_id] = true
	objective_completed.emit(objective_id, _objective_titles[objective_id])
	objectives_changed.emit()
	return true


func has_objective(objective_id: String) -> bool:
	return _objective_titles.has(objective_id)


func is_objective_completed(objective_id: String) -> bool:
	return _objective_completed.get(objective_id, false)


func get_objective_title(objective_id: String) -> String:
	return _objective_titles.get(objective_id, "")


## Returns all objectives in registration order as [{ "id", "title", "completed" }, ...].
func get_objectives() -> Array[Dictionary]:
	var objectives: Array[Dictionary] = []
	for objective_id in _objective_order:
		objectives.append({
			"id": objective_id,
			"title": _objective_titles[objective_id],
			"completed": _objective_completed[objective_id],
		})
	return objectives


func are_all_objectives_completed() -> bool:
	return not _objective_order.is_empty() and not _objective_completed.values().has(false)


# ---------------------------------------------------------------- Dev helper

## Development-only: completes the first unfinished objective. Also bound to F9 in debug builds.
func debug_complete_next_objective() -> void:
	for objective_id in _objective_order:
		if not _objective_completed[objective_id]:
			complete_objective(objective_id)
			return
