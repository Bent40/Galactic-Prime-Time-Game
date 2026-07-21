extends SimTestBase
## Owner ruling 2026-07-20: a `condition_destruction_immune` part (the mycelium
## network) cannot be DESTROYED by a condition reaching a terminal tier — it must
## be worn down by HP damage instead (so its 50 HP + pressure valves pace the
## fight; crushed T3 no longer one-shots it). EXCEPTION: NEURAL POISON still
## destroys it (mycelium is a neural network). HP-depletion death is unaffected.


## A combatant with a single lethal, EXPOSED core; `immune` toggles the flag.
func _boss_with_core(immune: bool) -> CombatSim:
	var sim: CombatSim = make_sim()
	var part: Dictionary = {"key": "core", "name": "Core", "hp": 10, "lethal": true}
	if immune:
		part["condition_destruction_immune"] = true
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Boss", "team": "enemies", "position": [0, 0],
		"body_parts": [part], "traits": {"physique": 3}}})
	return sim


func test_crushed_terminal_does_not_destroy_immune_core() -> void:
	var sim: CombatSim = _boss_with_core(true)
	var c: CombatantState = sim.combatants["boss"]
	# Crushed T3 = [part_destroyed, lethal_if_vital] — both are destruction effects.
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "crushed", sim.clock.tick, {"tier": 3})
	assert_true(c.alive, "immune core: crushed's terminal tier does NOT kill the boss")
	assert_false(bool(c.parts["core"].get("destroyed", false)), "core is not destroyed by the condition tier")
	assert_true(has_event(events, "condition_destruction_immune"), "the immunity is reported")


func test_control_non_immune_core_IS_destroyed_by_crushed_terminal() -> void:
	var sim: CombatSim = _boss_with_core(false)
	var c: CombatantState = sim.combatants["boss"]
	sim.cond.apply(c, "core", "crushed", sim.clock.tick, {"tier": 3})
	assert_false(c.alive, "control: a NON-immune lethal core IS destroyed by the crushed terminal")


func test_immune_core_still_dies_by_hp_depletion() -> void:
	var sim: CombatSim = _boss_with_core(true)
	var c: CombatantState = sim.combatants["boss"]
	# HP damage still grinds it to 0 -> death (the intended grind-down kill; this
	# path is separate from the condition-tier terminals and is NOT gated).
	sim.cond.damage_part(c, "core", 10, "weapon", "crushed", sim.clock.tick)
	assert_false(c.alive, "immune core still dies when its HP is ground to 0")


func test_neural_poison_destroys_immune_core() -> void:
	var sim: CombatSim = _boss_with_core(true)
	var c: CombatantState = sim.combatants["boss"]
	# Poison T3 = [death_timer_clocks:2] (a destruction effect). Neural poison
	# bypasses the immunity, so the death timer STARTS (timer_started).
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "poison", sim.clock.tick,
		{"tier": 3, "poison_type": "neural"})
	assert_true(has_event(events, "timer_started"), "neural poison's death timer starts (immunity bypassed)")
	assert_false(has_event(events, "condition_destruction_immune"), "neural poison is NOT blocked")


func test_normal_poison_cannot_destroy_immune_core() -> void:
	var sim: CombatSim = _boss_with_core(true)
	var c: CombatantState = sim.combatants["boss"]
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "poison", sim.clock.tick,
		{"tier": 3, "poison_type": "acid"})
	assert_true(has_event(events, "condition_destruction_immune"), "normal poison's death timer is blocked")
	assert_false(has_event(events, "timer_started"), "no death timer starts for normal poison on the immune core")
	assert_true(c.alive, "normal poison cannot tier-destroy the immune network")
