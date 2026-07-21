extends SimTestBase
## Owner ruling 2026-07-20: the mycelium network is a BODY PART with its own
## per-part condition resistances — not a special "destruction gate". It is immune
## to most conditions (they never apply, so they never build tiers or destroy it),
## has NO resistance to force (full HP damage grinds its 50 HP), is HARMED by fire
## (not healed by it), and neural poison bypasses its poison immunity (mycelium is
## a neural network). This tests that per-part model on a network-like `core` part.


## A combatant with an EXPOSED, lethal `core` carrying the network's immunity profile.
func _boss_with_core() -> CombatSim:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Boss", "team": "enemies", "position": [0, 0],
		"traits": {"physique": 1},
		"body_parts": [{
			"key": "core", "name": "Core", "hp": 10, "lethal": true,
			"bleed_immune": true, "fire_harms": true,
			"condition_immunities": ["crushed", "chilled", "exhausted", "infected",
				"suffocation", "dissolution", "poison"],
		}]}})
	return sim


# ---- immune conditions never apply (so they never build tiers / destroy it) ----

func test_crushed_condition_never_applies_to_the_network() -> void:
	var sim: CombatSim = _boss_with_core()
	var c: CombatantState = sim.combatants["boss"]
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "crushed", sim.clock.tick, {"tier": 3})
	assert_true(has_event(events, "condition_resisted"), "the crushed CONDITION is resisted (part_immune)")
	assert_true(c.alive, "crushed never destroys the network via its condition tier")
	assert_false(c.conditions.get("core", {}).has("crushed"), "no crushed tier is stored on the core")

func test_normal_poison_and_bleeding_never_apply() -> void:
	var sim: CombatSim = _boss_with_core()
	var c: CombatantState = sim.combatants["boss"]
	assert_true(has_event(sim.cond.apply(c, "core", "poison", sim.clock.tick, {"tier": 3, "poison_type": "acid"}), "condition_resisted"),
		"non-neural poison is resisted")
	assert_true(has_event(sim.cond.apply(c, "core", "bleeding", sim.clock.tick, {"tier": 2}), "condition_resisted"),
		"bleeding is resisted (bleed_immune)")
	assert_true(c.alive, "immune conditions leave the network alive")


# ---- the vulnerabilities: force (HP), fire (burn), neural poison ----

func test_force_hp_damage_still_grinds_the_network_down() -> void:
	var sim: CombatSim = _boss_with_core()
	var c: CombatantState = sim.combatants["boss"]
	sim.cond.damage_part(c, "core", 10, "weapon", "crushed", sim.clock.tick)
	assert_false(c.alive, "force/HP damage is never gated — grinding the core to 0 kills it")

func test_burn_condition_DOES_apply_to_the_network() -> void:
	var sim: CombatSim = _boss_with_core()
	var c: CombatantState = sim.combatants["boss"]
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "burn", sim.clock.tick, {"tier": 2})
	assert_false(has_event(events, "condition_resisted"), "burn is NOT immune — fire harms the network")
	assert_true(c.conditions.get("core", {}).has("burn"), "the burn condition is stored on the core")

func test_neural_poison_bypasses_the_poison_immunity() -> void:
	var sim: CombatSim = _boss_with_core()
	var c: CombatantState = sim.combatants["boss"]
	var events: Array[Dictionary] = sim.cond.apply(c, "core", "poison", sim.clock.tick, {"tier": 3, "poison_type": "neural"})
	assert_false(has_event(events, "condition_resisted"), "neural poison is NOT resisted")
	assert_true(has_event(events, "timer_started"), "neural poison's death timer starts on the network")


# ---- fire HARMS (does not heal) a fire_harms part, even on a fire_heals boss ----

func test_fire_harms_the_network_instead_of_healing_it() -> void:
	var sim: CombatSim = make_sim()
	# A fire-healing boss (its flesh regenerates from fire) whose `core` is fire_harms.
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Flame Boss", "team": "enemies", "position": [0, 0],
		"traits": {"physique": 1}, "boss_traits": {"fire_heals": true},
		"body_parts": [
			{"key": "flesh", "name": "Flesh", "hp": 10, "lethal": false},
			{"key": "core", "name": "Core", "hp": 10, "lethal": true, "fire_harms": true},
		]}})
	add_human(sim, "a", {"position": [1, 0], "traits": {"physique": 3}})
	# Burn the fire_harms core: it must take DAMAGE, not heal.
	declare(sim, "a", attack_action("burn", 3, "boss", "core"))
	advance(sim)
	assert_true(int(sim.combatants["boss"].parts["core"]["hp"]) < 10, "fire HARMS the core (took burn damage)")
	# Burn the ordinary flesh: the fire-heal hook fires (no damage / healed).
	declare(sim, "a", attack_action("burn", 3, "boss", "flesh"))
	advance(sim)
	assert_eq(int(sim.combatants["boss"].parts["flesh"]["hp"]), 10, "fire HEALS the flesh (no net damage)")
