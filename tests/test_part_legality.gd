extends SimTestBase
## S2.6 — condition part-legality on non-human part plans (regression for the
## silent-relocation bug: conditions aimed at parts outside the human template
## used to remap to template keys the combatant may not even have).


## A custom-bodied combatant: one lethal carapace + a tail (roach_dog shape).
func add_bug(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "position": [2, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 1},
		"body_parts": [
			{"key": "carapace", "name": "Carapace", "hp": 5, "lethal": true},
			{"key": "tail", "name": "Tail", "hp": 3, "lethal": false},
		],
	}})


func test_any_part_condition_stays_on_custom_part() -> void:
	var sim: CombatSim = make_sim()
	add_bug(sim, "bug")
	var events: Array[Dictionary] = sim.apply_command(
		{"type": "apply_condition", "target": "bug", "part": "carapace", "condition": "bleeding"})
	var applied: Dictionary = assert_event(events, "condition_applied", "bleeding lands on a custom part")
	assert_eq(String(applied.get("part", "")), "carapace", "no relocation off an existing part")


func test_restricted_condition_routes_to_equivalent() -> void:
	var sim: CombatSim = make_sim()
	add_bug(sim, "bug")
	# Infected is torso-only (tier condition, part-attached); the bug has no torso —
	# closest equivalent is its (sorted-first) lethal part: the carapace.
	var events: Array[Dictionary] = sim.apply_command(
		{"type": "apply_condition", "target": "bug", "part": "tail", "condition": "infected"})
	var applied: Dictionary = assert_event(events, "condition_applied", "infected still applies")
	assert_eq(String(applied.get("part", "")), "carapace", "torso-equivalent = lethal part")


func test_restricted_remap_preserved_for_humans() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var events: Array[Dictionary] = sim.apply_command(
		{"type": "apply_condition", "target": "a", "part": "left_arm", "condition": "infected"})
	var applied: Dictionary = assert_event(events, "condition_applied", "infected applies")
	assert_eq(String(applied.get("part", "")), "torso", "torso-only remap still works for humans")


func test_nonexistent_part_falls_back() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var events: Array[Dictionary] = sim.apply_command(
		{"type": "apply_condition", "target": "a", "part": "wings", "condition": "bleeding"})
	var applied: Dictionary = assert_event(events, "condition_applied", "bad part name still applies somewhere sane")
	assert_eq(String(applied.get("part", "")), "torso", "fallback chain prefers the torso")


func test_custom_parts_stay_deterministic() -> void:
	var sim1: CombatSim = make_sim(77)
	var sim2: CombatSim = make_sim(77)
	for sim: CombatSim in [sim1, sim2]:
		add_bug(sim, "bug")
		sim.apply_command({"type": "apply_condition", "target": "bug", "part": "carapace", "condition": "bleeding"})
		advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(sim1.state_hash(), sim2.state_hash(), "custom part plans replay identically")
