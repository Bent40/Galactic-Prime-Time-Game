extends SimTestBase
## KAN-2 acceptance tests — one test per criterion from docs/rules-addendum.md
## ("KAN-2 acceptance criteria", 1–21). Each test quotes its criterion.
## Criterion 19 has a smoke test here; the thorough version (100 mixed
## commands, snapshot/restore/replay) lives in tests/test_determinism.gd.


## 1. "Absolute ticks map to Moments 10→1 and Clock resets fire after
##    Moment 1 [R0/R1]."
func test_01_ticks_map_to_moments_and_clock_reset() -> void:
	var sim: CombatSim = make_sim()
	assert_eq(sim.clock.tick, 0, "sim starts at absolute tick 0")
	assert_eq(sim.clock.moment(), 10, "tick 0 displays Moment 10")
	for i: int in range(9):
		var events: Array[Dictionary] = advance(sim)
		assert_no_event(events, "clock_reset", "no reset before Moment 1 completes (tick %d)" % sim.clock.tick)
		assert_eq(sim.clock.moment(), 10 - sim.clock.tick % 10, "moment = 10 - tick %% 10")
	assert_eq(sim.clock.tick, 9, "after 9 advances the tick displaying Moment 1 is current")
	assert_eq(sim.clock.moment(), 1, "tick 9 displays Moment 1")
	var reset_events: Array[Dictionary] = advance(sim)
	var reset: Dictionary = assert_event(reset_events, "clock_reset", "reset fires when the Moment-1 tick completes")
	assert_eq(int(reset.get("tick", -1)), 9, "reset happens on tick 9")
	assert_eq(sim.clock.tick, 10, "next Clock starts at tick 10")
	assert_eq(sim.clock.moment(), 10, "tick 10 displays Moment 10 again")


## 2. "A 2-cost action declared at Moment 1 resolves at Moment 9 of the next
##    Clock [R1]." (No wrap ambiguity: next_action_tick = tick + cost.)
func test_02_two_cost_action_across_clock_boundary() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, 9)
	assert_eq(sim.clock.moment(), 1, "declaring on Moment 1 (tick 9)")
	var declared: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 3, "b", "torso", {"cost": 2}))
	var decl_event: Dictionary = assert_event(declared, "action_declared", "windup accepted")
	assert_eq(int(decl_event.get("resolve_tick", -1)), 11, "resolves at absolute tick 11")
	var tick10: Array[Dictionary] = advance(sim)
	assert_no_event(tick10, "action_resolved", "not resolved on Moment 10 of next Clock")
	var tick11: Array[Dictionary] = advance(sim)
	assert_no_event(tick11, "action_resolved", "not resolved before its tick completes")
	var resolved_events: Array[Dictionary] = advance(sim)
	var resolved: Dictionary = assert_event(resolved_events, "action_resolved", "resolves on tick 11")
	assert_eq(int(resolved.get("tick", -1)), 11, "resolution tick is 11")
	assert_eq(int(resolved.get("moment", -1)), 9, "tick 11 displays Moment 9 of the next Clock")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(int(b.parts["torso"]["hp"]), 2, "listed damage 3 landed on the torso (5 -> 2)")


## 3. "Two lethal same-tick attacks kill both combatants (snapshot
##    semantics) [R2]."
func test_03_simultaneous_lethal_attacks_trade() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	declare(sim, "a", attack_action("crushed", 5, "b", "torso"))
	declare(sim, "b", attack_action("crushed", 5, "a", "torso"))
	var events: Array[Dictionary] = advance(sim)
	assert_eq(events_of(events, "combatant_died").size(), 2, "both die — nobody gets tick-order priority")
	var a: CombatantState = sim.combatants["a"]
	var b: CombatantState = sim.combatants["b"]
	assert_false(a.alive, "a is dead")
	assert_false(b.alive, "b is dead")


## 4. "A combatant that moves out of a windup's range before its resolution
##    tick is unharmed; an instant attack cannot be dodged by later
##    movement [R2]." (Invalidated windup collapses into Forced Action – Tool.)
func test_04_windup_dodgeable_instant_not() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	declare(sim, "a", attack_action("crushed", 3, "b", "torso", {"cost": 2}))
	advance(sim)
	sim.apply_command({"type": "move", "actor": "b", "to": [4, 0]})  # free 3-space move at an earlier tick
	advance(sim)
	var events: Array[Dictionary] = advance(sim)
	var invalidated: Dictionary = assert_event(events, "action_invalidated", "windup re-checks range at resolution")
	assert_eq(String(invalidated.get("reason", "")), "out_of_range", "dodged by leaving range")
	var forced: Dictionary = assert_event(events, "forced_action_triggered", "invalidated windup collapses into Forced Action – Tool")
	assert_eq(String(forced.get("table", "")), "tool", "Tool table")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(int(b.parts["torso"]["hp"]), 5, "b is unharmed")

	# Instant: same-tick movement does not dodge a cost-1 attack.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "c", {"position": [0, 0]})
	add_human(sim2, "d", {"position": [1, 0]})
	declare(sim2, "c", attack_action("crushed", 2, "d", "torso"))
	sim2.apply_command({"type": "move", "actor": "d", "to": [4, 0]})
	var events2: Array[Dictionary] = advance(sim2)
	assert_no_event(events2, "action_invalidated", "instants resolve without re-check")
	var d: CombatantState = sim2.combatants["d"]
	assert_eq(int(d.parts["torso"]["hp"]), 3, "instant attack landed despite same-tick movement")


## 5. "Reaction resolves immediately and delays the reactor's next scheduled
##    action by its cost; a second reaction in the same tick is rejected [R2]."
func test_05_reaction_immediate_and_capped() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	var events: Array[Dictionary] = sim.apply_command({
		"type": "reaction", "actor": "a", "cost": 2,
		"target": "b", "part": "torso", "damage": {"type": "crushed", "amount": 1},
	})
	assert_event(events, "reaction_resolved", "reaction resolves immediately, out of schedule")
	assert_event(events, "damage_applied", "its effect lands in the same command")
	var a: CombatantState = sim.combatants["a"]
	assert_eq(a.next_action_tick, 2, "reactor pays by acting later (+2 ticks)")
	var blocked: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 1, "b", "torso"))
	assert_rejected(blocked, "not_ready", "scheduled action delayed by the reaction cost")
	var second: Array[Dictionary] = sim.apply_command({"type": "reaction", "actor": "a", "cost": 0})
	assert_rejected(second, "reaction_used", "max one reaction per combatant per tick")


## 6. "Second 0-cost action in one tick is rejected (free-slot consumed) [R3]."
func test_06_free_action_slot() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	var first: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 0, "key": "taunt"})
	assert_event(first, "action_declared", "0-cost skills are legal (F10)")
	var second: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 0, "key": "flex"})
	assert_rejected(second, "free_action_used", "one free (0-Moment) action per tick")
	var next_tick: Array[Dictionary] = advance(sim)
	assert_event(next_tick, "action_resolved", "the free action resolved on its tick")
	var again: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 0, "key": "taunt2"})
	assert_event(again, "action_declared", "slot refreshes next tick")


## 7. "Move of 3 spaces = free once per tick; second move same tick rejected;
##    7-space move costs 1 Moment [R3]." (cost = ceil((spaces - 3) / 4))
func test_07_movement_costs() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	var free_move: Array[Dictionary] = sim.apply_command({"type": "move", "actor": "a", "to": [3, 0]})
	var moved: Dictionary = assert_event(free_move, "moved", "1–3 spaces is free")
	assert_true(bool(moved.get("free", false)), "consumed the free slot, no Moments")
	var second: Array[Dictionary] = sim.apply_command({"type": "move", "actor": "a", "to": [4, 0]})
	assert_rejected(second, "already_moved", "you cannot move twice in one tick")
	advance(sim)
	var long_move: Array[Dictionary] = sim.apply_command({"type": "move", "actor": "a", "to": [10, 0]})
	var long_decl: Dictionary = assert_event(long_move, "action_declared", "7-space move is a scheduled action")
	assert_eq(int(long_decl.get("cost", -1)), 1, "ceil((7-3)/4) = 1 Moment")
	var resolve_events: Array[Dictionary] = advance(sim)
	assert_event(resolve_events, "moved", "scheduled move resolves")
	var a: CombatantState = sim.combatants["a"]
	assert_eq([a.position.x, a.position.y], [10, 0], "position updated at resolution")


## 8. "First inventory interaction free, second costs 1 Moment, no reset
##    exploit [R3]." (The book's reset-upon-other-action clause is deleted.)
func test_08_inventory_interaction_costs() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	var first: Array[Dictionary] = sim.apply_command({"type": "inventory", "actor": "a"})
	var used: Dictionary = assert_event(first, "inventory_used", "first interaction of the combat")
	assert_true(bool(used.get("free", false)), "first interaction is free")
	advance(sim)
	var second: Array[Dictionary] = sim.apply_command({"type": "inventory", "actor": "a"})
	var second_decl: Dictionary = assert_event(second, "action_declared", "second interaction is scheduled")
	assert_eq(int(second_decl.get("cost", -1)), 1, "second interaction costs 1 Moment")
	advance(sim)
	declare(sim, "a", attack_action("crushed", 1, "b", "torso"))  # a different action...
	advance(sim)
	var third: Array[Dictionary] = sim.apply_command({"type": "inventory", "actor": "a"})
	var third_decl: Dictionary = assert_event(third, "action_declared", "...does NOT reset the freebie")
	assert_eq(int(third_decl.get("cost", -1)), 1, "still 1 Moment — reset-loop exploit deleted")


## 9. "Cooldown '1 Clock' = exactly 10 ticks regardless of Clock boundary [R3]."
func test_09_cooldown_absolute_ticks() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	advance(sim, 5)
	var declared: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 1, "key": "zap", "cooldown_clocks": 1})
	assert_event(declared, "action_declared", "skill accepted at tick 5")
	advance(sim)  # resolves at tick 5 -> available again at tick 15
	advance(sim, 8)
	assert_eq(sim.clock.tick, 14, "one tick before cooldown expiry (crossed a Clock reset)")
	var too_early: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 1, "key": "zap"})
	assert_rejected(too_early, "cooldown", "still cooling at tick 14")
	advance(sim)
	var ready: Array[Dictionary] = declare(sim, "a", {"kind": "skill", "cost": 1, "key": "zap"})
	assert_event(ready, "action_declared", "available at exactly resolution + 10 ticks")


## 10. "Damage = listed − flat resistance, floor 0; applies condition T1;
##     re-application same tick does not double-advance; next-tick
##     re-application advances to T2 [R4]."
func test_10_damage_resistance_and_condition_application() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "a2", {"position": [1, 1]})
	add_human(sim, "b", {"position": [1, 0], "resistances": {"Physical": 1}})
	declare(sim, "a", attack_action("bleeding", 2, "b", "torso"))
	declare(sim, "a2", attack_action("bleeding", 2, "b", "torso"))
	var events: Array[Dictionary] = advance(sim)
	var dmg: Dictionary = assert_event(events, "damage_applied", "damage lands")
	assert_eq(int(dmg.get("amount", -1)), 1, "listed 2 − flat resistance 1 = 1")
	assert_event(events, "condition_applied", "first application puts Bleeding at Tier 1")
	assert_no_event(events, "condition_advanced", "same-tick re-application does not double-advance")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(b.condition_tier("torso", "bleeding"), 1, "Bleeding T1 after the simultaneous hits")
	declare(sim, "a", attack_action("bleeding", 2, "b", "torso"))
	var tick2: Array[Dictionary] = advance(sim)
	var advanced: Dictionary = assert_event(tick2, "condition_advanced", "next-tick re-application advances")
	assert_eq(int(advanced.get("to_tier", -1)), 2, "Bleeding advances to Tier 2")
	declare(sim, "a", attack_action("bleeding", 1, "b", "torso"))
	var tick3: Array[Dictionary] = advance(sim)
	var floored: Dictionary = assert_event(tick3, "damage_applied", "attack still resolves")
	assert_eq(int(floored.get("amount", -1)), 0, "1 − resistance 1 = 0 (floor 0)")


## 11. "At Clock reset every active condition advances one tier; a Delayed
##     condition skips exactly one advancement [R4]."
func test_11_universal_clock_reset_advancement_and_delay() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "b", {"position": [0, 0]})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "left_arm", "condition": "bleeding", "tier": 1})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "right_arm", "condition": "crushed", "tier": 1})
	var delayed: Array[Dictionary] = sim.apply_command({"type": "treat", "target": "b", "part": "right_arm", "condition": "crushed", "mode": "delay"})
	assert_event(delayed, "condition_delayed", "Crushed is Delayed")
	var reset1: Array[Dictionary] = advance(sim, 10)
	assert_event(reset1, "clock_reset", "a full Clock elapsed")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(b.condition_tier("left_arm", "bleeding"), 2, "active condition advanced one tier at reset")
	assert_event(reset1, "condition_delay_consumed", "the Delayed condition skipped this advancement")
	assert_eq(b.condition_tier("right_arm", "crushed"), 1, "Crushed did not advance")
	advance(sim, 10)
	assert_eq(b.condition_tier("right_arm", "crushed"), 2, "delay skips EXACTLY one advancement")


## 12. "Burn T1 stops Bleeding, removes Chill, applies Shock T1, deals its HP
##     damage [R4]."
func test_12_burn_t1_cauterizes_with_shock_cost() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "left_arm", "condition": "bleeding", "tier": 1})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "left_arm", "condition": "chilled", "tier": 1})
	declare(sim, "a", attack_action("burn", 1, "b", "left_arm"))
	var events: Array[Dictionary] = advance(sim)
	var dmg: Dictionary = assert_event(events, "damage_applied", "Burn deals its HP damage")
	assert_eq(int(dmg.get("amount", -1)), 1, "1 Burn damage")
	assert_event(events, "condition_applied", "Burn T1 applied")
	assert_eq(events_of(events, "condition_resolved").size(), 2, "Bleeding stopped AND Chill removed")
	var shock: Dictionary = assert_event(events, "shock_changed", "cauterizing costs Shock (addendum)")
	assert_eq(int(shock.get("to_tier", -1)), 1, "Shock Tier 1")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(b.condition_tier("left_arm", "bleeding"), 0, "no more Bleeding")
	assert_eq(b.condition_tier("left_arm", "chilled"), 0, "no more Chill")
	assert_eq(b.condition_tier("left_arm", "burn"), 1, "Burn T1 active")
	assert_eq(b.shock, 1, "Shock T1 on the target")


## 13. "Infected T2 makes other conditions advance twice per Clock reset [R4]."
func test_13_infected_t2_accelerates_other_conditions() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "b", {"position": [0, 0]})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "torso", "condition": "infected", "tier": 2})
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "left_arm", "condition": "bleeding", "tier": 1})
	var reset: Array[Dictionary] = advance(sim, 10)
	assert_event(reset, "clock_reset", "a full Clock elapsed")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(b.condition_tier("left_arm", "bleeding"), 3, "Bleeding advanced 1 + 1 extra tier (1 -> 3)")
	assert_eq(b.condition_tier("torso", "infected"), 3, "Infected itself advances only once (2 -> 3)")


## 14. "Torso to 0 by Bleeding ⇒ 1-Clock bleed-out (Helpless), delay of
##     Bleeding stabilizes; torso to 0 by weapon damage ⇒ immediate death;
##     Exhausted never kills [R5]."
func test_14_bleed_out_vs_immediate_death_vs_exhausted() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "b1", {"position": [0, 0]})
	sim.apply_command({"type": "apply_condition", "target": "b1", "part": "torso", "condition": "bleeding", "tier": 1})
	advance(sim, 10)  # reset 1: Bleeding T2
	var reset2: Array[Dictionary] = advance(sim, 10)  # reset 2: Bleeding T3 = part death
	assert_event(reset2, "bleed_out_started", "torso lost to a delayable condition starts bleed-out")
	assert_no_event(reset2, "combatant_died", "bleed-out is not death")
	var b1: CombatantState = sim.combatants["b1"]
	assert_true(b1.alive, "still alive")
	assert_true(b1.is_helpless(sim.clock.tick), "Helpless during bleed-out")
	assert_eq(int(b1.parts["torso"]["hp"]), 0, "torso at 0")
	var treat_events: Array[Dictionary] = sim.apply_command({"type": "treat", "target": "b1", "part": "torso", "condition": "bleeding", "mode": "delay"})
	assert_event(treat_events, "bleed_out_stabilized", "delaying the causing condition stabilizes")
	assert_true(b1.alive, "returned at 0-HP-stabilized")
	assert_false(b1.is_helpless(sim.clock.tick), "no longer Helpless")

	var sim2: CombatSim = make_sim()
	add_human(sim2, "a", {"position": [0, 0]})
	add_human(sim2, "b2", {"position": [1, 0]})
	declare(sim2, "a", attack_action("crushed", 5, "b2", "torso"))
	var weapon_events: Array[Dictionary] = advance(sim2)
	assert_event(weapon_events, "combatant_died", "direct weapon damage to 0 = immediate death")
	assert_no_event(weapon_events, "bleed_out_started", "no bleed-out for weapon kills")

	var sim3: CombatSim = make_sim()
	add_human(sim3, "b3", {"position": [0, 0]})
	sim3.apply_command({"type": "apply_condition", "target": "b3", "part": "torso", "condition": "exhausted", "tier": 3})
	var long_run: Array[Dictionary] = advance(sim3, 30)
	assert_no_event(long_run, "combatant_died", "Exhausted has no death mechanism (A1)")
	var b3: CombatantState = sim3.combatants["b3"]
	assert_true(b3.alive, "Exhausted never kills")


## 15. "Head targeting rejected unless target Exposed/Helpless/Overwhelmed
##     [book, kept]."
func test_15_head_targeting_gate() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	add_human(sim, "c", {"position": [0, 1]})
	add_human(sim, "d", {"position": [-1, 0]})
	var blocked: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 1, "b", "head"))
	assert_rejected(blocked, "head_not_targetable", "fresh target's head is off limits")
	declare(sim, "b", {"kind": "wait", "cost": 2})  # multi-Moment windup -> Exposed (R2)
	var vs_exposed: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 1, "b", "head"))
	assert_event(vs_exposed, "action_declared", "Exposed target: head is targetable")
	advance(sim)
	sim.apply_command({"type": "set_status", "target": "c", "status": "overwhelmed", "value": true})
	var vs_overwhelmed: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 1, "c", "head"))
	assert_event(vs_overwhelmed, "action_declared", "Overwhelmed target: head is targetable")
	advance(sim)
	sim.apply_command({"type": "apply_condition", "target": "d", "part": "torso", "condition": "shock", "tier": 3})
	var d: CombatantState = sim.combatants["d"]
	assert_true(d.is_helpless(sim.clock.tick), "Shock T3 (Faint) = Helpless")
	var vs_helpless: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 1, "d", "head"))
	assert_event(vs_helpless, "action_declared", "Helpless target: any part including the head")


## 16. "Level point → +1 levelBonus; over-10 formulas produce app-identical
##     derived stats for the five live characters' sheets (fixture test
##     against real campaign data) [R6]."
## Fixtures derived by hand with the R6 formulas (floor((total-10)/divisor),
## divisors 5/12/15/20); the (3,6,6,4) line is live-character-shaped (all of
## the campaign's level-6 sheets sit below every over-10 threshold -> zeros).
func test_16_stat_economy_and_derived_stats() -> void:
	var fixtures: Array[Dictionary] = [
		{"id": "c1", "stats": [17, 23, 26, 21], "hp": 1, "alloc": 1, "psy": 1, "cam": 0},
		{"id": "c2", "stats": [3, 6, 6, 4], "hp": 0, "alloc": 0, "psy": 0, "cam": 0},
		{"id": "c3", "stats": [5, 7, 4, 6], "hp": 0, "alloc": 0, "psy": 0, "cam": 0},
		{"id": "c4", "stats": [11, 13, 12, 10], "hp": 0, "alloc": 0, "psy": 0, "cam": 0},
		{"id": "c5", "stats": [16, 24, 30, 41], "hp": 1, "alloc": 1, "psy": 1, "cam": 1},
	]
	var sim: CombatSim = make_sim()
	for fixture: Dictionary in fixtures:
		var stats: Array = fixture["stats"]
		add_human(sim, String(fixture["id"]), {"traits": {
			"physique": int(stats[0]), "reflexes": int(stats[1]),
			"mind": int(stats[2]), "charm": int(stats[3]),
		}})
		var c: CombatantState = sim.combatants[String(fixture["id"])]
		var derived: Dictionary = c.derived_stats()
		assert_eq(derived["hp_bonus_per_part"], fixture["hp"], "%s: Physique over-10 /5" % fixture["id"])
		assert_eq(derived["physical_resistance_allocatable"], fixture["alloc"], "%s: Reflexes over-10 /12" % fixture["id"])
		assert_eq(derived["psychic_resistance"], fixture["psy"], "%s: Mind over-10 /15" % fixture["id"])
		assert_eq(derived["camera_call_stacks"], fixture["cam"], "%s: Charm over-10 /20" % fixture["id"])
		assert_eq(int(c.parts["torso"]["hp"]), 5 + int(fixture["hp"]), "%s: torso HP includes the bonus" % fixture["id"])

	# Level point -> +1 levelBonus on any one trait (single unified pool).
	add_human(sim, "lv", {"traits": {"physique": 14, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "grant_level", "actor": "lv"})
	var lv: CombatantState = sim.combatants["lv"]
	assert_eq(lv.level_points, 1, "level grant fills the pool")
	var spent: Array[Dictionary] = sim.apply_command({"type": "spend_level_point", "actor": "lv", "trait": "physique"})
	assert_event(spent, "level_point_spent", "point spent")
	assert_eq(lv.trait_total("physique"), 15, "+1 levelBonus on the chosen trait")
	assert_eq(lv.level_points, 0, "pool decremented")
	assert_event(spent, "max_hp_increased", "crossing Physique 15 grants +1 max HP per part")
	assert_eq(int(lv.parts["torso"]["hp"]), 6, "torso HP followed the threshold")
	var broke: Array[Dictionary] = sim.apply_command({"type": "spend_level_point", "actor": "lv", "trait": "mind"})
	assert_rejected(broke, "no_level_points", "empty pool spends are rejected")


## 17. "Grapple: Physique-gated initiate; 2-Moment escape; Suffocation-by-
##     grapple rejected vs a boss [R9]."
func test_17_grapple_rules() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "g", {"position": [0, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "t", {"position": [1, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "w", {"position": [10, 0], "traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "s", {"position": [11, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "g2", {"position": [20, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "m", "name": "Mini-Boss", "category": "Boss", "size": "Medium",
		"position": [21, 0],
		"traits": {"physique": 6, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 5, "lethal": true},
			{"key": "torso", "hp": 12, "lethal": true},
			{"key": "left_arm", "hp": 5, "lethal": false},
			{"key": "right_arm", "hp": 5, "lethal": false},
		],
	}})
	declare(sim, "g", {"kind": "grapple", "target": "t"})
	declare(sim, "w", {"kind": "grapple", "target": "s"})
	declare(sim, "g2", {"kind": "grapple", "target": "m"})
	var events: Array[Dictionary] = advance(sim)
	assert_eq(events_of(events, "grapple_started").size(), 3, "all three holds land (always allowed)")
	var g_forced: bool = false
	var w_forced: bool = false
	for forced: Dictionary in events_of(events, "forced_action_triggered"):
		if String(forced.get("actor", "")) == "g":
			g_forced = true
		if String(forced.get("actor", "")) == "w" and String(forced.get("table", "")) == "body":
			w_forced = true
	assert_false(g_forced, "Physique 5 vs 3: automatic, no Forced Action")
	assert_true(w_forced, "Physique 2 vs 5: Forced Action – Body")
	var t: CombatantState = sim.combatants["t"]
	assert_true(t.exposed_cache, "both grappler and target are Exposed")
	assert_true(sim.combatants["g"].exposed_cache, "both grappler and target are Exposed")

	var escape: Array[Dictionary] = declare(sim, "t", {"kind": "grapple_escape"})
	var escape_decl: Dictionary = assert_event(escape, "action_declared", "escape accepted")
	assert_eq(int(escape_decl.get("cost", -1)), 2, "2-Moment escape (Physique 3 < grappler's 5)")
	var suffocate: Array[Dictionary] = declare(sim, "g2", {"kind": "grapple_suffocate", "target": "m"})
	assert_rejected(suffocate, "boss_immune_to_grapple_suffocation", "boss win conditions are discovered, not choked out")
	var escape_window: Array[Dictionary] = advance(sim, 3)
	assert_event(escape_window, "grapple_ended", "escape resolved after its 2-Moment windup")
	assert_eq(t.grappled_by, "", "hold broken")


## 18. "RPM 3 weapon fires 3 rounds in one 1-Moment action, magazine
##     decrements, empty ⇒ reload required (2 Moments, 2 hands) [R8]."
func test_18_rpm_magazine_reload() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0], "items": [{
		"key": "spark_volver", "item_type": "weapon",
		"damage_type": "burn", "damage_amount": 2,
		"base_moment_cost": 1, "rpm": 3, "magazine": 6, "attack_range": 5,
	}]})
	add_human(sim, "b", {"position": [1, 0], "body_parts": [
		{"key": "head", "hp": 2, "lethal": true},
		{"key": "torso", "hp": 40, "lethal": true},
		{"key": "left_arm", "hp": 20, "lethal": false},
		{"key": "right_arm", "hp": 20, "lethal": false},
	]})
	var volley: Dictionary = {"kind": "attack", "item": "spark_volver", "rounds": 3, "targets": [{"id": "b", "part": "torso"}]}
	declare(sim, "a", volley.duplicate(true))
	var events: Array[Dictionary] = advance(sim)
	var resolved: Dictionary = assert_event(events, "action_resolved", "one 1-Moment firing action")
	assert_eq(int(resolved.get("rounds", -1)), 3, "delivers up to RPM = 3 rounds")
	assert_eq(events_of(events, "damage_applied").size(), 3, "listed damage is PER ROUND")
	var mag: Dictionary = assert_event(events, "magazine_changed", "magazine decrements")
	assert_eq(int(mag.get("loaded", -1)), 3, "6 - 3 = 3 rounds left")
	declare(sim, "a", volley.duplicate(true))
	advance(sim)
	var a: CombatantState = sim.combatants["a"]
	assert_eq(int(a.items["spark_volver"]["magazine_loaded"]), 0, "magazine empty after the second volley")
	var dry: Array[Dictionary] = declare(sim, "a", volley.duplicate(true))
	assert_rejected(dry, "reload_required", "empty magazine cannot fire")
	var reload: Array[Dictionary] = declare(sim, "a", {"kind": "reload", "item": "spark_volver"})
	var reload_decl: Dictionary = assert_event(reload, "action_declared", "reload accepted (2 usable hands)")
	assert_eq(int(reload_decl.get("cost", -1)), 2, "reload costs 2 Moments")
	var reload_events: Array[Dictionary] = advance(sim, 3)
	assert_event(reload_events, "reloaded", "reload resolved after its windup")
	assert_eq(int(a.items["spark_volver"]["magazine_loaded"]), 6, "magazine refilled")


## 19. "Determinism: identical (seed, command log) ⇒ identical state hash
##     after 100 mixed commands; snapshot → restore → replay tail ⇒ same hash
##     [DIRECTION contract]." — smoke test here; the thorough 100-command +
##     snapshot/restore version lives in tests/test_determinism.gd.
func test_19_determinism_smoke() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(777)
		add_human(sim, "a", {"position": [0, 0], "traits": {"physique": 1, "reflexes": 3, "mind": 3, "charm": 3}})
		add_human(sim, "b", {"position": [1, 0]})
		for i: int in range(6):
			declare(sim, "a", attack_action("chilled", 2, "b", "left_arm", {"requirements": {"physique": 5}}))
			advance(sim)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same seed + same command log = same state hash")


## 20. "Forced Action: unmet requirements halve effect and roll the correct
##     d6 table; 'always allowed' preserved [R10/book]."
func test_20_forced_action_requirements_gate() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0], "traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "b", {"position": [1, 0], "body_parts": [
		{"key": "head", "hp": 2, "lethal": true},
		{"key": "torso", "hp": 40, "lethal": true},
		{"key": "left_arm", "hp": 20, "lethal": false},
		{"key": "right_arm", "hp": 20, "lethal": false},
	]})
	var declared: Array[Dictionary] = declare(sim, "a", attack_action("crushed", 4, "b", "torso", {"requirements": {"physique": 5}}))
	assert_event(declared, "action_declared", "Forced Actions are ALWAYS allowed")
	var events: Array[Dictionary] = advance(sim)
	var forced: Dictionary = assert_event(events, "forced_action_triggered", "unmet stat requirement rolls the d6")
	assert_eq(String(forced.get("table", "")), "tool", "stat shortfall on a weapon action = Tool table")
	var roll: int = int(forced.get("roll", 0))
	assert_true(roll >= 1 and roll <= 6, "d6 roll logged in the event (got %d)" % roll)
	var resolved: Dictionary = assert_event(events, "action_resolved", "the action still resolves")
	assert_true(bool(resolved.get("halved", false)), "effect magnitude halved (round down)")
	if String(forced.get("consequence", "")) == "whiff":
		assert_eq(String(resolved.get("result", "")), "whiff", "Whiff is the one consequence that negates the action")
		assert_no_event(events, "damage_applied", "whiffed action has no effect")
	else:
		var dmg: Dictionary = assert_event(events, "damage_applied", "halved damage lands")
		assert_eq(int(dmg.get("amount", -1)), 2, "4 halved (round down) = 2")

	# A condition demanding Forced Action – Body rolls the BODY table.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "c", {"position": [0, 0]})
	add_human(sim2, "b2", {"position": [1, 0], "body_parts": [
		{"key": "head", "hp": 2, "lethal": true},
		{"key": "torso", "hp": 40, "lethal": true},
	]})
	sim2.apply_command({"type": "apply_condition", "target": "c", "part": "torso", "condition": "exhausted", "tier": 3})
	declare(sim2, "c", attack_action("crushed", 1, "b2", "torso"))
	var body_events: Array[Dictionary] = advance(sim2)
	var body_forced: Dictionary = assert_event(body_events, "forced_action_triggered", "Exhausted T3: every action is Forced – Body")
	assert_eq(String(body_forced.get("table", "")), "body", "Body table")


## 21. "Combined action: two linked same-tick attacks merge into a single hit
##     for breach checks (7+); an assist satisfies a partner's requirement; a
##     Forced Action on one partner degrades but does not cancel the others'
##     contributions [R15]."
func test_21_combined_action() -> void:
	# A boss whose surface immunity breaches only on a SINGLE hit >= 7 (NQ2 ruling).
	var boss_spec: Dictionary = {
		"id": "boss", "name": "Puppet", "category": "Boss", "size": "Large",
		"position": [1, 0],
		"traits": {"physique": 6, "reflexes": 3, "mind": 3, "charm": 3},
		"resistances": {"Physical": 0},
		"body_parts": [
			{"key": "hide", "hp": 60, "lethal": false},
			{"key": "network", "hp": 8, "lethal": true, "hidden_until_breach": true},
		],
		"boss_traits": {"surface_immunity": {"breach_conditions": [
			{"type": "burst_damage", "amount": 7, "window": "single_hit"},
		]}},
	}

	# (a1) a lone 4-damage hit is below the single-hit threshold — no breach.
	var sim: CombatSim = make_sim()
	add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": boss_spec})
	declare(sim, "p1", attack_action("crushed", 4, "boss", "hide"))
	var lone: Array[Dictionary] = advance(sim)
	assert_no_event(lone, "breach_opened", "a lone 4-damage hit (<7) does not breach single-hit immunity")
	assert_false(sim.combatants["boss"].breached, "boss stays armored after one small hit")
	assert_true(bool(sim.combatants["boss"].parts["network"].get("hidden", false)), "the network stays hidden")

	# (a2) a combined action merges two 4-damage linked hits into one 8-damage hit.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "p1", {"position": [0, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim2, "p2", {"position": [2, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	sim2.apply_command({"type": "add_combatant", "combatant": boss_spec})
	var combo: Array[Dictionary] = sim2.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("crushed", 4, "boss", "hide")},
		{"actor": "p2", "action": attack_action("crushed", 4, "boss", "hide")},
	]})
	assert_event(combo, "combined_action_declared", "the combo is one linked declaration set")
	assert_eq(events_of(combo, "action_declared").size(), 2, "each partner pays its own Moment cost")
	var merged: Array[Dictionary] = advance(sim2)
	assert_eq(events_of(merged, "damage_applied").size(), 2, "both partners' hits land this tick")
	assert_event(merged, "breach_opened", "4+4 merged into one 8-damage hit clears the 7+ breach")
	assert_true(sim2.combatants["boss"].breached, "surface immunity broken by the combined hit")
	assert_false(bool(sim2.combatants["boss"].parts["network"].get("hidden", false)), "the network is now exposed")

	# (b) an assist supplies a partner's otherwise-unmet requirement.
	var sim3: CombatSim = make_sim()
	add_human(sim3, "strong", {"position": [0, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim3, "weak", {"position": [2, 0], "traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim3, "t", {"position": [1, 0], "body_parts": [
		{"key": "head", "hp": 2, "lethal": true},
		{"key": "torso", "hp": 40, "lethal": true},
		{"key": "left_arm", "hp": 20, "lethal": false},
		{"key": "right_arm", "hp": 20, "lethal": false},
	]})
	var strong_attack: Dictionary = attack_action("crushed", 4, "t", "torso")
	strong_attack["provides"] = {"physique": 5}  # a brace supplies "steady ground"
	var combo_b: Array[Dictionary] = sim3.apply_command({"type": "combined_action", "members": [
		{"actor": "strong", "action": strong_attack},
		{"actor": "weak", "action": attack_action("crushed", 4, "t", "torso", {"requirements": {"physique": 5}})},
	]})
	assert_event(combo_b, "combined_action_declared", "combo declared")
	var res_b: Array[Dictionary] = advance(sim3)
	assert_event(res_b, "combo_assist_applied", "the brace supplies weak's Physique requirement")
	assert_no_event(res_b, "forced_action_triggered", "a satisfied requirement rolls no d6")
	var full_hits: int = 0
	for dmg: Dictionary in events_of(res_b, "damage_applied"):
		if int(dmg.get("amount", -1)) == 4:
			full_hits += 1
	assert_eq(full_hits, 2, "both partners deal full, unhalved 4 damage")

	# (c) a Forced Action on one partner degrades ONLY that partner.
	var sim4: CombatSim = make_sim()
	add_human(sim4, "ok", {"position": [0, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim4, "fail", {"position": [2, 0], "traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim4, "t", {"position": [1, 0], "body_parts": [
		{"key": "head", "hp": 2, "lethal": true},
		{"key": "torso", "hp": 40, "lethal": true},
		{"key": "left_arm", "hp": 20, "lethal": false},
		{"key": "right_arm", "hp": 20, "lethal": false},
	]})
	var combo_c: Array[Dictionary] = sim4.apply_command({"type": "combined_action", "members": [
		{"actor": "ok", "action": attack_action("crushed", 4, "t", "torso")},
		{"actor": "fail", "action": attack_action("crushed", 4, "t", "torso", {"requirements": {"physique": 5}})},
	]})
	assert_event(combo_c, "combined_action_declared", "combo declared")
	var res_c: Array[Dictionary] = advance(sim4)
	var forced: Dictionary = assert_event(res_c, "forced_action_triggered", "the unmet partner rolls the Tool d6")
	assert_eq(String(forced.get("actor", "")), "fail", "only the failing partner is forced")
	var ok_undegraded: bool = false
	for resolved: Dictionary in events_of(res_c, "action_resolved"):
		if String(resolved.get("actor", "")) == "ok":
			ok_undegraded = not bool(resolved.get("halved", true))
	assert_true(ok_undegraded, "the healthy partner resolves un-degraded — the combo is not cancelled")
	var ok_full_damage: bool = false
	for dmg: Dictionary in events_of(res_c, "damage_applied"):
		if int(dmg.get("amount", -1)) == 4:
			ok_full_damage = true
	assert_true(ok_full_damage, "ok's full 4 damage lands despite fail's Forced Action")
