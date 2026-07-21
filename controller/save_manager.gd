class_name SaveManager
extends RefCounted
## The SINGLE owner of save files (KAN3-S2). Envelope per DIRECTION delta 5:
## {seed, snapshot, command_log, offset} — the snapshot is a convenience; the
## log makes every save re-derivable from (seed, command_log) alone.
## Corrupt files fail SOFT: load returns {} and last_error explains; the file
## on disk is never touched by a failed load.

const SAVE_DIR: String = "user://saves"
## Envelope is serialized with var_to_str, NOT JSON: JSON doubles corrupt 64-bit
## ints (the sim's RNG state exceeds the 53-bit mantissa) and break hash equality.
const SAVE_EXT: String = ".save"

var last_error: String = ""


## Save names are normalized to a safe charset before touching the filesystem
## (review hardening): anything outside [A-Za-z0-9_-] becomes "_", so path
## separators / ".." / weird glyphs can never escape SAVE_DIR or produce invalid
## filenames. An empty result falls back to "save".
static func sanitize_name(save_name: String) -> String:
	var out := ""
	for i in range(save_name.length()):
		var ch := save_name[i]
		var code := ch.unicode_at(0)
		var safe := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) \
			or (code >= 97 and code <= 122) or ch == "_" or ch == "-"
		out += ch if safe else "_"
	return out if out != "" else "save"


func _path(save_name: String) -> String:
	return SAVE_DIR + "/" + sanitize_name(save_name) + SAVE_EXT


func save_game(save_name: String, sim: CombatSim, command_log: Array) -> bool:
	last_error = ""
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var envelope: Dictionary = {
		"version": 1,
		"seed": sim.rng_seed,
		"snapshot": sim.to_dict(),
		"command_log": command_log.duplicate(true),
		"offset": command_log.size(),
	}
	var file: FileAccess = FileAccess.open(_path(save_name), FileAccess.WRITE)
	if file == null:
		last_error = "cannot open save file for writing"
		return false
	file.store_string(var_to_str(envelope))
	file.close()
	return true


## Returns the envelope, or {} with last_error set (soft fail).
func load_game(save_name: String) -> Dictionary:
	last_error = ""
	var path: String = _path(save_name)
	if not FileAccess.file_exists(path):
		last_error = "no such save"
		return {}
	var parsed: Variant = str_to_var(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("snapshot"):
		last_error = "corrupt save envelope"
		return {}
	return parsed


func list_saves() -> Array[String]:
	var names: Array[String] = []
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(SAVE_EXT):
			names.append(file_name.trim_suffix(SAVE_EXT))
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	return names
