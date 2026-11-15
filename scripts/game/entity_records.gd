class_name EntityRecords
extends RefCounted
## Ending B puzzle: a registry file Haven writes into its own user:// folder.
## The player must delete the three "E-" (entity) lines while leaving the sealed "R-" (human)
## lines untouched. Haven only reads the file back when the game launches.
## Only files inside user://entity_records are ever created, read or rewritten.

const DIR := "user://entity_records"
const REGISTRY_PATH := "user://entity_records/registry.txt"
const README_PATH := "user://entity_records/README.txt"
const HEADER := "# HAVEN ENTITY REGISTRY v1"

enum Result { MISSING, UNCHANGED, PARTIAL, VALID, INVALID }

const HUMANS: Array[Dictionary] = [
	{"id": "R-01", "name": "Detective M", "status": "LIVING"},
	{"id": "R-02", "name": "Clara Whitlow", "status": "DECEASED"},
	{"id": "R-03", "name": "The Eleven", "status": "UNACCOUNTED"},
]
const ENTITIES: Array[Dictionary] = [
	{"id": "E-01", "name": "The Caller", "status": "BOUND"},
	{"id": "E-02", "name": "The Hollow One", "status": "BOUND"},
	{"id": "E-03", "name": "The Congregation", "status": "BOUND"},
]


static func registry_global_path() -> String:
	return ProjectSettings.globalize_path(REGISTRY_PATH)


static func folder_global_path() -> String:
	return ProjectSettings.globalize_path(DIR)


static func _seal(token: String, core: String) -> String:
	return (token + "#" + core).sha256_text().substr(0, 10)


static func _human_line(token: String, human: Dictionary) -> String:
	var core := "%s|HUMAN|%s|status=%s" % [human["id"], human["name"], human["status"]]
	return "%s|seal=%s" % [core, _seal(token, core)]


static func _entity_line(entity: Dictionary) -> String:
	return "%s|ENTITY|%s|status=%s" % [entity["id"], entity["name"], entity["status"]]


static func build_registry_text(token: String) -> String:
	var lines: PackedStringArray = [HEADER, "# SESSION: " + token, "[RECORDS]"]
	for human in HUMANS:
		lines.append(_human_line(token, human))
	for entity in ENTITIES:
		lines.append(_entity_line(entity))
	lines.append("[END]")
	return "\n".join(lines) + "\n"


## Creates (or rebuilds) registry.txt and README.txt. Returns true on success.
static func create_files(token: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR)) != OK:
		return false
	var registry := FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
	if registry == null:
		return false
	registry.store_string(build_registry_text(token))
	registry.close()
	var readme := FileAccess.open(README_PATH, FileAccess.WRITE)
	if readme == null:
		return false
	readme.store_string(
		"HAVEN - ENTITY RECORDS\n\n"
		+ "This folder belongs to the game Haven. Nothing outside it is ever touched.\n\n"
		+ "To unbind the entities:\n"
		+ "  1. Close Haven.\n"
		+ "  2. Open registry.txt in any text editor.\n"
		+ "  3. Delete the three lines that begin with E-  (ENTITY records).\n"
		+ "  4. Leave every R- line exactly as it is. They are sealed.\n"
		+ "  5. Save the file and start Haven again.\n\n"
		+ "Haven checks the file when it starts. A half-finished edit is ignored.\n"
		+ "A damaged file is rebuilt, and nothing is unlocked.\n")
	readme.close()
	return true


## Reads registry.txt and classifies it. Returns { "result": Result, "message": String }.
static func verify(token: String) -> Dictionary:
	if not FileAccess.file_exists(REGISTRY_PATH):
		return {"result": Result.MISSING, "message": "registry.txt is missing."}
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.READ)
	if file == null:
		return {"result": Result.MISSING, "message": "registry.txt could not be opened."}
	var text := file.get_as_text().trim_prefix("﻿")
	file.close()
	return classify_text(text, token)


static func classify_text(text: String, token: String) -> Dictionary:
	var lines := text.replace("\r", "").split("\n")
	var cleaned: Array[String] = []
	for raw_line in lines:
		cleaned.append(raw_line.strip_edges())
	while not cleaned.is_empty() and cleaned[0] == "":
		cleaned.pop_front()
	if cleaned.is_empty() or cleaned[0] != HEADER:
		return _invalid("the registry header was altered.")
	if not cleaned.has("# SESSION: " + token):
		return _invalid("the registry does not belong to this session.")
	var start := cleaned.find("[RECORDS]")
	var end := cleaned.find("[END]")
	if start == -1 or end == -1 or end < start:
		return _invalid("the [RECORDS] / [END] markers were damaged.")

	var human_found := {}
	var entity_found := {}
	for i in range(start + 1, end):
		var line := cleaned[i]
		if line == "" or line.begins_with("#"):
			continue
		var id := line.get_slice("|", 0)
		if id.begins_with("R-"):
			var expected := ""
			for human in HUMANS:
				if human["id"] == id:
					expected = _human_line(token, human)
			if expected == "" or line != expected or human_found.has(id):
				return _invalid("a human record (%s) was modified." % id)
			human_found[id] = true
		elif id.begins_with("E-"):
			var known := false
			for entity in ENTITIES:
				if entity["id"] == id:
					known = true
			if not known:
				return _invalid("an unknown entity record was added.")
			entity_found[id] = true
		else:
			return _invalid("an unknown line was added.")
	if human_found.size() != HUMANS.size():
		return _invalid("a human record is missing.")

	var remaining := entity_found.size()
	if remaining == 0:
		return {"result": Result.VALID, "message": "all entity records removed."}
	if remaining == ENTITIES.size():
		return {"result": Result.UNCHANGED, "message": "entity records are still present."}
	return {"result": Result.PARTIAL, "message": "%d of %d entity records remain." % [remaining, ENTITIES.size()]}


static func _invalid(reason: String) -> Dictionary:
	return {"result": Result.INVALID, "message": reason}


## Debug / test helper: rewrites registry.txt as a player would. modes: valid, partial, tamper, delete_file
static func debug_simulate_edit(mode: String, token: String) -> void:
	var kept: PackedStringArray = []
	for line in build_registry_text(token).split("\n"):
		match mode:
			"valid":
				if line.begins_with("E-"):
					continue
			"partial":
				if line.begins_with("E-01"):
					continue
			"tamper":
				if line.begins_with("E-"):
					continue
				if line.begins_with("R-02"):
					continue
		kept.append(line)
	if mode == "delete_file":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REGISTRY_PATH))
		return
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(kept))
		file.close()
