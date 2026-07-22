extends SimTestBase
## Per-loadout SKILLS as combatant STATE + view projection (the last fixture
## holdover removed). CombatantState ingests the spec's "skills" grants
## (normalized {key, level} — loadout annotations dropped), serializes them,
## answers skill_level(), and view_combatants exposes {key, level, name, cost,
## self} rows so the HUD's SKILLS flyout + declares run on granted state, never
## a fixture table. The end-to-end test proves the GRANTED level flows through
## a kind:"skill" declare into both the read-only preview and the resolved hit.

## Imani-style grant spec, VERBATIM demo_loadouts.json rows — including the
## annotations (id / cap / cap_note) that normalization must drop.
const IMANI_SKILLS := [
	{"id": 4, "key": "strong_strike", "level": 2},
	{"id": 23, "key": "overhead_slam", "level": 1, "cap": 6, "cap_note": "R16 skill-trade"},
	{"id": 8, "key": "brace", "level": 2},
]


func _game() -> Node:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(11, load_static_data())
	return game


func _add(game: Node, spec: Dictionary) -> void:
	game.apply_command({"type": "add_combatant", "combatant": spec})


func _imani_spec() -> Dictionary:
	return {
		"id": "imani", "name": "Imani", "race": "human", "team": "party",
		"position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3},
		"skills": IMANI_SKILLS.duplicate(true),
	}


## The large-HP, non-dodging Elite target from test_skill_mechanics, staged
## through the controller so exact typed-damage numbers can be asserted.
func _dummy_spec() -> Dictionary:
	return {
		"id": "foe", "name": "foe", "category": "Elite", "size": "Medium",
		"team": "enemies", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
		],
	}


func _view_of(game: Node, id: String) -> Dictionary:
	for cd: Dictionary in game.view_combatants():
		if String(cd.get("id", "")) == id:
			return cd
	return {}


# ------------------------------------------------------------- (a) projection

func test_granted_skills_project_key_level_name_cost_self() -> void:
	var game: Node = _game()
	_add(game, _imani_spec())
	var rows: Array = _view_of(game, "imani").get("skills", [])
	assert_eq(rows.size(), 3, "all three granted skills project")
	var r0: Dictionary = rows[0]
	assert_eq(String(r0.get("key", "")), "strong_strike", "grant order preserved")
	assert_eq(int(r0.get("level", 0)), 2, "GRANTED level from state, not a hardcoded 1")
	assert_eq(String(r0.get("name", "")), "Strong Strike", "display name joined from skills.json")
	assert_eq(int(r0.get("cost", 0)), 2, "honest Moment cost from SkillBook")
	assert_false(bool(r0.get("self", true)), "strong_strike is targeted")
	var brace_row: Dictionary = rows[2]
	assert_eq(String(brace_row.get("key", "")), "brace", "brace row present (third grant)")
	assert_eq(int(brace_row.get("level", 0)), 2, "brace granted at Lv2")
	assert_eq(int(brace_row.get("cost", 1)), 0, "brace is free (cost 0)")
	assert_true(bool(brace_row.get("self", false)), "brace is a self skill")
	# Normalization: loadout annotations (id / cap / cap_note) are DROPPED — the
	# state rows carry exactly {key, level}.
	for sr: Dictionary in (game.sim.combatants["imani"] as CombatantState).skills:
		var state_keys: Array = sr.keys()
		state_keys.sort()
		assert_eq(state_keys, ["key", "level"], "state rows normalized to {key, level}")
	game.free()


func test_unknown_skill_name_falls_back_to_titlecase() -> void:
	var game: Node = _game()
	_add(game, {
		"id": "odd", "name": "Odd", "race": "human", "team": "party",
		"position": [0, 1], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"skills": [{"key": "mystery_move", "level": 2}],
	})
	var rows: Array = _view_of(game, "odd").get("skills", [])
	assert_eq(rows.size(), 1, "the un-catalogued grant still projects")
	var row: Dictionary = rows[0]
	assert_eq(String(row.get("name", "")), "Mystery Move", "title-cased key fallback, never guessed")
	assert_eq(int(row.get("cost", 0)), 1, "SkillBook generic-strike fallback cost")
	assert_false(bool(row.get("self", true)), "the fallback strike is targeted")
	game.free()


# ---------------------------------------------- (b) [] for enemies + ungranted

func test_view_skills_empty_for_enemies_and_ungranted() -> void:
	var game: Node = _game()
	_add(game, _imani_spec())
	_add(game, {"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]})
	_add(game, {"id": "zed", "name": "Zed", "race": "human", "team": "party",
		"position": [2, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	var boss_view: Dictionary = _view_of(game, "boss")
	assert_true(boss_view.has("skills"), "the field is present on every row, never missing")
	assert_eq((boss_view.get("skills", [0]) as Array).size(), 0, "enemies project skills: []")
	assert_eq((_view_of(game, "zed").get("skills", [0]) as Array).size(), 0,
		"a contestant with no grants projects [] — never a fixture fallback")
	game.free()


# ----------------------------------------------- (c) serialization round-trip

func test_serialization_roundtrip_preserves_grants_and_hash() -> void:
	var game: Node = _game()
	_add(game, _imani_spec())
	var d: Dictionary = (game.sim.combatants["imani"] as CombatantState).to_dict()
	assert_eq((d.get("skills", []) as Array).size(), 3, "skills serialized in to_dict")
	var restored: CombatantState = CombatantState.from_dict(d)
	assert_eq(restored.skill_level("strong_strike"), 2, "strong_strike Lv2 survives from_dict")
	assert_eq(restored.skill_level("overhead_slam"), 1, "overhead_slam Lv1 survives from_dict")
	assert_eq(restored.skill_level("brace"), 2, "brace Lv2 survives from_dict")
	assert_eq(restored.to_dict().get("skills"), d.get("skills"), "grants re-serialize identically")
	# Full-sim round trip: the state hash (which now covers the grants) is stable.
	var rsim: CombatSim = CombatSim.from_dict(game.sim.to_dict())
	assert_eq(rsim.state_hash(), game.sim.state_hash(), "state_hash consistent across the round-trip")
	game.free()


# ------------------------------------------------------------- (d) skill_level

func test_skill_level_reports_granted_level_or_zero() -> void:
	var game: Node = _game()
	_add(game, _imani_spec())
	var c: CombatantState = game.sim.combatants["imani"]
	assert_eq(c.skill_level("strong_strike"), 2, "granted level (Lv2)")
	assert_eq(c.skill_level("overhead_slam"), 1, "granted level (Lv1)")
	assert_eq(c.skill_level("brace"), 2, "granted level (Lv2)")
	assert_eq(c.skill_level("dance"), 0, "not granted -> 0")
	assert_eq(c.skill_level(""), 0, "empty key -> 0")
	game.free()


# ------------------------------------- (e) the granted level flows END TO END

func test_granted_level_flows_into_declare_preview_and_resolve() -> void:
	# overhead_slam scales amount = 2 + level. Grant Lv3, then declare THROUGH
	# kind:"skill" with the actor's GRANTED level (exactly what the HUD now
	# does): the read-only preview and the resolved hit BOTH read 5 (2+3), where
	# a Lv1 declare reads 3 — the delta IS the level, end to end.
	var game: Node = _game()
	_add(game, {
		"id": "slam", "name": "Slam", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"skills": [{"key": "overhead_slam", "level": 3}, {"key": "brace", "level": 2}],
	})
	_add(game, _dummy_spec())

	# The granted level comes off the VIEW row (the HUD's source).
	var granted: int = 0
	for rd: Variant in _view_of(game, "slam").get("skills", []):
		if String((rd as Dictionary).get("key", "")) == "overhead_slam":
			granted = int((rd as Dictionary).get("level", 0))
	assert_eq(granted, 3, "the view row carries the granted level (Lv3)")

	var action: Dictionary = {"kind": "skill", "key": "overhead_slam", "level": granted,
		"attack_range": 1, "targets": [{"id": "foe", "part": "torso"}]}

	# PREVIEW at the granted level: force 5+1=6 vs robustness 1 -> net 5.
	var probe: Dictionary = game.preview_action("slam", action)
	var row: Dictionary = (probe.get("per_target", []) as Array)[0]
	assert_eq(int(row.get("net", 0)), 5, "preview nets the Lv3 amount (2+3=5)")
	var lv1_probe: Dictionary = game.preview_action("slam", {"kind": "skill",
		"key": "overhead_slam", "level": 1, "attack_range": 1,
		"targets": [{"id": "foe", "part": "torso"}]})
	assert_eq(int(((lv1_probe.get("per_target", []) as Array)[0] as Dictionary).get("net", 0)), 3,
		"the Lv1 preview stays 3 — the +2 delta is the granted level")

	# RESOLVE: the cost-2 windup lands the Lv3 hit (50 -> 45, not Lv1's 47).
	var declared: Array[Dictionary] = game.apply_command(
		{"type": "declare_action", "actor": "slam", "action": action})
	assert_event(declared, "action_declared", "the Lv3 slam declares cleanly")
	game.apply_command({"type": "advance_tick"})
	game.apply_command({"type": "advance_tick"})
	var events: Array[Dictionary] = game.apply_command({"type": "advance_tick"})
	var hit: Dictionary = assert_event(events, "damage_applied", "the slam resolves")
	assert_eq(int(hit.get("amount", 0)), 5, "resolved amount = 2+3 = 5")
	assert_eq(int((game.sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]), 45,
		"torso 50 -> 45 at the granted Lv3 (a Lv1 slam leaves 47)")

	# And a level-scaled SELF skill: brace at its granted Lv2 buffers 2, not 1.
	var braced: Array[Dictionary] = game.apply_command({"type": "declare_action",
		"actor": "slam", "action": {"kind": "skill", "key": "brace",
			"level": (game.sim.combatants["slam"] as CombatantState).skill_level("brace")}})
	assert_event(braced, "action_declared", "the brace declares cleanly")
	game.apply_command({"type": "advance_tick"})
	assert_eq((game.sim.combatants["slam"] as CombatantState).brace_guard, 2,
		"brace at its granted Lv2 sets guard 2 (Lv1 would set 1)")
	game.free()
