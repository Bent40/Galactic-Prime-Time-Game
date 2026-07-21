extends SimTestBase
## Review-hardening regressions: (1) granted Camera Call stacks replace the
## Charm-30 over-cap hack (F1) — a loadout grants stacks directly via the spec's
## `camera_call_stacks`, composing with the over-cap rule; (2) SaveManager
## normalizes save names to a safe charset so a hostile/typo name can never
## escape the save dir or produce an invalid filename.


func test_granted_camera_call_stack_without_overcap_charm() -> void:
	var sim: CombatSim = make_sim()
	# Dario per demo_loadouts.json: charm 5 (NOT 30) + a granted stack.
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "dario", "name": "Dario", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5},
		"camera_call_stacks": 1}})
	var c: CombatantState = sim.combatants["dario"]
	assert_eq(int(c.derived_stats()["camera_call_stacks"]), 1, "granted stack shows with charm 5 (no over-cap)")
	# Grant + over-cap compose: charm 30 => 1 over-cap stack, + 2 granted = 3.
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "star", "name": "Star", "race": "human", "team": "party", "position": [1, 0],
		"traits": {"physique": 1, "reflexes": 1, "mind": 1, "charm": 30},
		"camera_call_stacks": 2}})
	assert_eq(int(sim.combatants["star"].derived_stats()["camera_call_stacks"]), 3, "granted + over-cap compose")


func test_granted_stacks_survive_serialization() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "d", "name": "D", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"charm": 5}, "camera_call_stacks": 1}})
	var restored: CombatantState = CombatantState.from_dict(sim.combatants["d"].to_dict())
	assert_eq(restored.camera_call_stacks_granted, 1, "granted stacks round-trip to_dict/from_dict")
	assert_eq(int(restored.derived_stats()["camera_call_stacks"]), 1, "derived stacks intact after restore")


func test_save_name_sanitization() -> void:
	assert_eq(SaveManager.sanitize_name("slot_1-B"), "slot_1-B", "safe names pass through unchanged")
	assert_eq(SaveManager.sanitize_name("../../etc/passwd"), "______etc_passwd", "path traversal neutralized")
	assert_eq(SaveManager.sanitize_name("my save!.zip"), "my_save__zip", "spaces/punctuation become underscores")
	assert_eq(SaveManager.sanitize_name(""), "save", "empty name falls back to 'save'")
