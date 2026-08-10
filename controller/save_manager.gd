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


# ------------------------------------------------------------------ run saves
# KAN-4 wave 2e — closes the run engine's flagged gap ("SaveManager was not
# extended; run persistence to disk is future work"). Same discipline as the
# combat envelope, one level up (DIRECTION delta 5): {run_snapshot,
# run_command_log, run_offset} — the run snapshot is the convenience, the run
# log alone rebuilds a bare RunState — plus the in-flight encounter's own
# {sim_snapshot, sim_command_log, sim_offset} when one is live
# (between-encounters saves carry an empty sim block). Same file format
# (var_to_str — the sim's 64-bit RNG state survives), same directory, same
# soft-fail idiom. NO wall-clock metadata anywhere: the combat envelope stamps
# none, so run envelopes stamp none either — the whole file is deterministic
# state, and save -> load -> save round-trips byte-identical.

## Bumped when the run-envelope shape changes; load_run gates on it. The combat
## loader predates versioned loads and only shape-checks its envelope — run
## saves add the minimal explicit version gate (noted divergence).
const RUN_SAVE_VERSION: int = 1


## Saves the live run. `sim` is the in-flight encounter's CombatSim, or null
## between encounters (the caller decides live-ness — run-phase knowledge stays
## with the controller); `sim_command_log` is that encounter's log tail since
## staging (the run log carries everything before it).
func save_run(save_name: String, run: RunState, run_command_log: Array, sim: CombatSim, sim_command_log: Array) -> bool:
	last_error = ""
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var envelope: Dictionary = {
		"version": RUN_SAVE_VERSION,
		"kind": "run",
		"seed": run.run_seed,
		"run_snapshot": run.to_dict(),
		"run_command_log": run_command_log.duplicate(true),
		"run_offset": run_command_log.size(),
		"sim_snapshot": sim.to_dict() if sim != null else {},
		"sim_command_log": sim_command_log.duplicate(true) if sim != null else [],
		"sim_offset": sim_command_log.size() if sim != null else 0,
	}
	var file: FileAccess = FileAccess.open(_path(save_name), FileAccess.WRITE)
	if file == null:
		last_error = "cannot open save file for writing"
		return false
	file.store_string(var_to_str(envelope))
	file.close()
	return true


## Returns the run envelope, or {} with last_error set (soft fail — the file on
## disk and the caller's live state are never touched by a failed load). Typed
## errors: "no such save" / "corrupt run-save envelope" (unparseable) /
## "not a run save" (a combat save or foreign envelope) / "unsupported
## run-save version" (the explicit version gate).
func load_run(save_name: String) -> Dictionary:
	last_error = ""
	var path: String = _path(save_name)
	if not FileAccess.file_exists(path):
		last_error = "no such save"
		return {}
	var parsed: Variant = str_to_var(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		last_error = "corrupt run-save envelope"
		return {}
	var envelope: Dictionary = parsed
	if String(envelope.get("kind", "")) != "run" or not envelope.has("run_snapshot"):
		last_error = "not a run save"
		return {}
	if int(envelope.get("version", -1)) != RUN_SAVE_VERSION:
		last_error = "unsupported run-save version"
		return {}
	return envelope


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
