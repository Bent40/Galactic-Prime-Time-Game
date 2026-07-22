extends SimTestBase
## View-API widening (spectator contract — docs/design/view-api-spectator-contract.md):
## view_combatants carries game MEANING directly (team / category / is_boss /
## token / persona / patron) so no consumer ever reverse-engineers it from part
## names, and view_encounter is the encounter-level probe (status + boss beat +
## slice objective). Every view is a read-only projection of LIVE sim state:
## deterministic, plain primitives, zero mutation.


## The seeded Incinedile boss_traits minus the dodge threshold — exactly what
## tests/test_incinedile.gd traits_without_dodge() does, so the scripted breach
## stays deterministic without consuming the AI d6 stream.
func _traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


## The slice roster the HUD renders: demo contestant "imani" (loadout join
## target) vs the Incinedile boss. Fixed seed; adjacent so attacks are in range.
func _game_with_slice_roster() -> Node:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "imani", "name": "Imani", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile", "team": "enemies",
		"position": [0, 0], "boss_traits": _traits_without_dodge()}})
	return game


func _view_of(game: Node, id: String) -> Dictionary:
	for cd: Dictionary in game.view_combatants():
		if String(cd.get("id", "")) == id:
			return cd
	return {}


func test_view_combatants_carries_team_category_boss_and_token() -> void:
	var game: Node = _game_with_slice_roster()
	var boss: Dictionary = _view_of(game, "boss")
	assert_eq(String(boss.get("team", "")), "enemies", "boss team projected")
	assert_eq(String(boss.get("category", "")), "Boss", "boss category projected")
	assert_true(bool(boss.get("is_boss", false)), "is_boss flags the Boss category")
	assert_eq(String(boss.get("token", "")), "incinedile", "boss token = enemy template key")
	var imani: Dictionary = _view_of(game, "imani")
	assert_eq(String(imani.get("team", "")), "party", "contestant team projected")
	assert_eq(String(imani.get("category", "")), "Contestant", "contestant category projected")
	assert_false(bool(imani.get("is_boss", true)), "a contestant is not the boss")
	assert_eq(String(imani.get("token", "")), "imani", "contestant token = combatant id (race-built, no template)")
	game.free()


func test_view_combatants_joins_persona_and_patron_from_loadouts() -> void:
	var game: Node = _game_with_slice_roster()
	# A contestant with NO demo-loadout match must read empty — never guessed.
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "zed", "name": "Zed", "race": "human", "team": "party", "position": [2, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})

	# The demo contestant joins by the documented rule: loadout key's first
	# "_"-token ("imani_the_door" -> "imani") == combat id.
	var expected_persona: String = ""
	var loadouts: Dictionary = SimTestBase.load_json("res://data/demo_loadouts.json")
	for lo: Variant in loadouts.get("loadouts", []):
		if String((lo as Dictionary).get("key", "")) == "imani_the_door":
			expected_persona = String((lo as Dictionary).get("broadcast_persona", ""))
	assert_ne(expected_persona, "", "precondition: the demo loadout carries a persona")

	var imani: Dictionary = _view_of(game, "imani")
	assert_eq(String(imani.get("persona", "")), expected_persona,
		"persona joined verbatim from the loadout's broadcast_persona")
	assert_eq(String(imani.get("patron", "")), "hestia",
		"signed patron KEY joined via chosen_patron -> patron_gods")

	var boss: Dictionary = _view_of(game, "boss")
	assert_eq(String(boss.get("persona", "")), "", "enemies carry no persona")
	assert_eq(String(boss.get("patron", "")), "", "enemies carry no patron")

	var zed: Dictionary = _view_of(game, "zed")
	assert_eq(String(zed.get("persona", "")), "", "no loadout match -> empty persona, never guessed")
	assert_eq(String(zed.get("patron", "")), "", "no loadout match -> empty patron, never guessed")
	game.free()


func test_template_key_serializes_for_stable_tokens() -> void:
	# The token must survive save/load + replay: template_key rides to_dict/from_dict.
	var game: Node = _game_with_slice_roster()
	var d: Dictionary = game.sim.combatants["boss"].to_dict()
	assert_eq(String(d.get("template_key", "?")), "incinedile", "template_key serialized in to_dict")
	var restored: CombatantState = CombatantState.from_dict(d)
	assert_eq(restored.template_key, "incinedile", "template_key survives from_dict")
	var h: Dictionary = game.sim.combatants["imani"].to_dict()
	assert_eq(String(h.get("template_key", "?")), "", "race-built contestant serializes an empty template_key")
	game.free()


func test_view_encounter_tracks_breach_and_win() -> void:
	var game: Node = _game_with_slice_roster()

	# --- at the start: ONGOING, boss block present, nothing discovered ---
	var enc: Dictionary = game.view_encounter()
	assert_eq(String((enc.get("status", {}) as Dictionary).get("outcome", "")), "ONGOING", "fight starts ONGOING")
	assert_false(bool((enc.get("status", {}) as Dictionary).get("over", true)), "not over at the start")
	var boss: Dictionary = enc.get("boss", {})
	assert_false(boss.is_empty(), "boss block present with a boss on the table")
	assert_eq(String(boss.get("id", "")), "boss", "boss id projected")
	assert_eq(String(boss.get("name", "")), "Incinedile", "boss name projected")
	assert_false(bool(boss.get("breached", true)), "pre-breach: breached false")
	assert_false(bool(boss.get("network_exposed", true)), "pre-breach: network not exposed")
	assert_eq(int(boss.get("phase", 0)), 1, "pre-breach: phase 1")
	var objective: Dictionary = enc.get("objective", {})
	assert_eq(String(objective.get("kind", "")), "breach_network", "objective kind is the slice win condition")
	assert_false(bool(objective.get("discovered", true)), "objective not yet discovered")
	assert_ne(String(objective.get("text", "")), "", "objective carries a display line")

	# --- a REAL breach: one 7+ NET single hit (R14: raw 10 + floor(phys 5/2) =
	# Force 12, net 12 − Robustness 3 = 9 ≥ 7) — test_incinedile's burst path ---
	game.apply_command({"type": "declare_action", "actor": "imani",
		"action": attack_action("crushed", 10, "boss", "left_hand")})
	var breach_events: Array[Dictionary] = game.apply_command({"type": "advance_tick"})
	assert_event(breach_events, "breach_opened", "precondition: the hit really breached")
	var enc2: Dictionary = game.view_encounter()
	var boss2: Dictionary = enc2.get("boss", {})
	assert_true(bool(boss2.get("breached", false)), "post-breach: breached flips true")
	assert_true(bool(boss2.get("network_exposed", false)), "post-breach: network_exposed flips true")
	assert_eq(int(boss2.get("phase", 0)), 2, "post-breach: phase 2 (PLACEHOLDER F2 rule)")
	assert_true(bool((enc2.get("objective", {}) as Dictionary).get("discovered", false)),
		"objective reads discovered after the breach")
	assert_eq(String((enc2.get("status", {}) as Dictionary).get("outcome", "")), "ONGOING",
		"still ONGOING mid-fight")

	# --- kill: one huge hit into the exposed lethal network (crushed is
	# condition-immune on it, but Force/HP damage is never gated) ---
	game.apply_command({"type": "declare_action", "actor": "imani",
		"action": attack_action("crushed", 60, "boss", "network")})
	var kill_events: Array[Dictionary] = game.apply_command({"type": "advance_tick"})
	assert_event(kill_events, "combatant_died", "precondition: the network kill really landed")
	var enc3: Dictionary = game.view_encounter()
	assert_eq(String((enc3.get("status", {}) as Dictionary).get("outcome", "")), "WIN", "dead boss -> WIN")
	assert_true(bool((enc3.get("status", {}) as Dictionary).get("over", false)), "and the fight reads over")
	game.free()


func test_views_are_read_only() -> void:
	# Spectator-contract determinism: probing must never change the state. Call
	# every view twice; the full-state hash must be bit-identical before/after.
	var game: Node = _game_with_slice_roster()
	var before: String = game.state_hash()
	for i: int in range(2):
		game.view_combatants()
		game.view_encounter()
		game.view_clock()
		game.view_broadcast()
		game.view_turn_order()
		game.view_bid()
		game.view_verdict("imani")
	assert_eq(game.state_hash(), before, "calling every view twice mutates nothing")
	game.free()
