class_name Dal
extends RefCounted
## Data Access Layer — the SINGLE owner of static data (KAN3-S2, ADR 3).
##
## JSON-backed now, SQLite-shaped API: typed collection getters + by-key lookups;
## no caller ever sees a file path. When content volume triggers the SQLite
## re-entry (architecture OPEN item), only this file changes.

const _PATHS: Dictionary = {
	"conditions": "res://data/conditions.json",
	"races": "res://data/races.json",
	"enemies": "res://data/enemies.json",
	"items": "res://data/items.json",
	"skills": "res://data/skills.json",
	"skill_thresholds": "res://data/skill_thresholds.json",
	"tags": "res://data/tags.json",
	"modifiers": "res://data/modifiers.json",
	"patron_gods": "res://data/patron_gods.json",
	"crowd_goals": "res://data/crowd_goals.json",
}

var _cache: Dictionary = {}


func _collection(name: String) -> Array:
	if not _cache.has(name):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_PATHS[name]))
		_cache[name] = parsed if parsed is Array else []
	return _cache[name]


func conditions() -> Array: return _collection("conditions")
func races() -> Array: return _collection("races")
func enemies() -> Array: return _collection("enemies")
func items() -> Array: return _collection("items")
func skills() -> Array: return _collection("skills")
func skill_thresholds() -> Array: return _collection("skill_thresholds")
func tags() -> Array: return _collection("tags")
func modifiers() -> Array: return _collection("modifiers")
func patron_gods() -> Array: return _collection("patron_gods")
func crowd_goals() -> Array: return _collection("crowd_goals")


## By-key lookup (rows are keyed by "key" across all collections; "" -> {}).
func by_key(collection: String, key: String) -> Dictionary:
	for row: Variant in _collection(collection):
		if String((row as Dictionary).get("key", "")) == key:
			return row
	return {}


func race(key: String) -> Dictionary: return by_key("races", key)
func enemy(key: String) -> Dictionary: return by_key("enemies", key)
func item(key: String) -> Dictionary: return by_key("items", key)
func skill(key: String) -> Dictionary: return by_key("skills", key)
func patron_god(key: String) -> Dictionary: return by_key("patron_gods", key)


## The bundle CombatSim.new() consumes.
func static_data_for_sim() -> Dictionary:
	return {
		"conditions": conditions(),
		"races": races(),
		"enemies": enemies(),
		"items": items(),
		"crowd_goals": crowd_goals(),
	}
