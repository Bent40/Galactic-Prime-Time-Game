extends SimTestBase
## Content pass batch B — "Guardians & Grapplers" (docs/design/skills-r19-ladders-FINAL.md
## #5/#7 + the G6 passover NEW_SKILLS): intercept + iron_stance (the NEW
## retarget_guard archetype — reaction form vs stance form), pressure_hold +
## death_grip_jaws (the NEW skill_grapple archetype — the R9 grapple as a skill,
## grip parameterized: bite substitutes for hands), counter_surge (the NEW
## interrupt_counter archetype — the windup cost cut + the Body-table collapse,
## F3). Pins: the interception composition rules (the original target's dodge
## never rolls; the guardian does not dodge a hit it chose to take; R26
## undodgable hits are still interceptable — interception is not a dodge; a
## merged R15 hit retargets WHOLE), the one-reaction-per-tick price vs the
## stance's no-cost cover, the persistent stance reduction stacking with brace,
## the dance-exit stance breaks, the full Gemstone forge chain (recipe → grant
## → usable stance), the both-Exposed / no-reposition grapple locks + the drag
## ladder, the handless bite grip, the cut arithmetic + reschedule + collapse,
## serialization round-trips and determinism. All magnitudes are the
## PLACEHOLDER (R14) numbers the SkillBook authors.


## A non-dodging Elite (Mind 0: feint-reads impossible; no dodge_threshold: no
## dodge stream). `extra` merges over the spec (size, parts, position, team).
func add_elite(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Elite", "size": "Large",
		"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
			{"key": "left_leg", "hp": 50, "lethal": false},
			{"key": "right_leg", "hp": 50, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


func add_party(sim: CombatSim, id: String, pos: Array, physique: int = 3) -> void:
	add_human(sim, id, {"team": "party", "position": pos,
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3}})


## A handless bite-capable layout (the death_grip_jaws unlock): head carries
## the data-driven `bite_capable` flag, NO arm/hand parts anywhere.
func add_croc(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "team": "party", "size": "Medium", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 2, "charm": 1},
		"body_parts": [
			{"key": "head", "hp": 4, "lethal": true, "bite_capable": true},
			{"key": "torso", "hp": 6, "lethal": true},
			{"key": "left_leg", "hp": 3, "lethal": false},
			{"key": "right_leg", "hp": 3, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func guard_declare(sim: CombatSim, guardian: String, ally: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, guardian, {"kind": "skill", "key": "intercept", "level": level,
		"targets": [{"id": ally}]})


func stance_declare(sim: CombatSim, actor: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "iron_stance", "level": level})


# ================================================================= intercept

func test_intercept_end_to_end_hit_lands_on_guardian() -> void:
	var sim: CombatSim = make_sim(4901)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [2, 0])
	# Both party members carry a dodge threshold that WOULD auto-fire (Reflexes
	# 3 >= 2) on any dodge-eligible hit — the composition pin: neither rolls.
	(sim.combatants["guardian"] as CombatantState).boss_traits = {"dodge_threshold": 2}
	(sim.combatants["ally"] as CombatantState).boss_traits = {"dodge_threshold": 2}
	var declared: Array[Dictionary] = guard_declare(sim, "guardian", "ally")
	assert_event(declared, "action_declared", "the guard declares (cost 0, free slot)")
	var armed: Array[Dictionary] = advance(sim)
	var set_event: Dictionary = assert_event(armed, "guard_set", "the guard arms at resolution")
	assert_eq(String(set_event.get("ally", "")), "ally", "guard names the ward")
	var guardian: CombatantState = sim.combatants["guardian"]
	assert_true(bool(guardian.armed_primes.get("intercept", false)), "the PREP substrate armed")
	assert_eq(String(guardian.guard.get("ally", "")), "ally", "guard record on the guardian")
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var icept: Dictionary = assert_event(ev, "hit_intercepted", "the aimed hit retargets")
	assert_eq(String(icept.get("guardian", "")), "guardian", "to the guardian")
	assert_eq(String(icept.get("ally", "")), "ally", "away from the ward")
	assert_eq(String(icept.get("mode", "")), "reaction", "the reaction form")
	# The guardian's OWN numbers: Force 3+1 = 4 vs Robustness 1 -> net 3.
	assert_eq(int(guardian.parts["torso"]["hp"]), 2, "guardian takes the hit at its own gate (5 -> 2)")
	assert_eq(guardian.condition_tier("torso", "crushed"), 1, "the condition lands on the GUARDIAN")
	var ally: CombatantState = sim.combatants["ally"]
	assert_eq(int(ally.parts["torso"]["hp"]), 5, "the ward is untouched")
	assert_eq(ally.condition_tier("torso", "crushed"), 0, "no condition on the ward")
	# Composition, both halves: the ORIGINAL target's dodge never rolled (the
	# hit was taken before it), and the GUARDIAN did not dodge a hit it chose
	# to take — no dodge-shaped event anywhere, zero dodge rng.
	assert_no_event(ev, "attack_dodged", "no dodge fired for either body")
	assert_no_event(ev, "dodge_failed", "no dodge was even rolled")
	# (The reaction-slot price is pinned behaviorally in the one-reaction test
	# below — the flag itself resets with the tick.)


func test_intercept_one_reaction_per_tick_and_guard_persistence() -> void:
	var sim: CombatSim = make_sim(4902)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe_a", [2, 0])
	add_elite(sim, "foe_b", [1, 1])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	declare(sim, "foe_a", attack_action("crushed", 1, "ally", "torso"))
	declare(sim, "foe_b", attack_action("crushed", 1, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(events_of(ev, "hit_intercepted").size(), 1,
		"ONE interception per tick — the reaction slot is the price")
	var guardian: CombatantState = sim.combatants["guardian"]
	var ally: CombatantState = sim.combatants["ally"]
	assert_eq(int(guardian.parts["torso"]["hp"]), 4, "first hit on the guardian (Force 2 - 1 = 1)")
	assert_eq(int(ally.parts["torso"]["hp"]), 4, "second hit same tick PASSES THROUGH to the ward")
	# Next tick: the slot resets and the guard is STILL armed (nothing consumed
	# the prep — the per-hit price is the reaction, not the prime).
	declare(sim, "foe_a", attack_action("crushed", 1, "ally", "torso"))
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "hit_intercepted", "the guard persists across ticks")
	assert_eq(int(guardian.parts["torso"]["hp"]), 3, "guardian takes the next tick's hit")
	assert_eq(int(ally.parts["torso"]["hp"]), 4, "ward untouched again")


func test_intercept_declare_gates() -> void:
	var sim: CombatSim = make_sim(4903)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_party(sim, "far_ally", [3, 0])
	add_elite(sim, "foe", [2, 0])
	assert_rejected(guard_declare(sim, "guardian", "guardian"), "cannot_guard_self",
		"a guard names someone else")
	assert_rejected(guard_declare(sim, "guardian", "foe"), "target_not_ally",
		"a guard names an ALLY (same team)")
	assert_rejected(guard_declare(sim, "guardian", "far_ally"), "ally_not_adjacent",
		"the guard declares on an ADJACENT ally")


func test_intercept_range_ladder_and_flat_reduction() -> void:
	# L1 guard range 1: the ward drifting to distance 2 is uncovered.
	var sim: CombatSim = make_sim(4904)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [3, 0])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	move(sim, "ally", [2, 0])
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "hit_intercepted", "distance 2 > L1 guard range 1 — no interception")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 2,
		"the ward takes its own hit (Force 4 - 1 = 3)")
	assert_false((sim.combatants["guardian"] as CombatantState).reaction_used,
		"an out-of-range guard pays nothing")
	# L2 (+1 guard range): the same geometry intercepts.
	var sim2: CombatSim = make_sim(4905)
	add_party(sim2, "guardian", [0, 0])
	add_party(sim2, "ally", [1, 0])
	add_elite(sim2, "foe", [3, 0])
	guard_declare(sim2, "guardian", "ally", 2)
	advance(sim2)
	move(sim2, "ally", [2, 0])
	declare(sim2, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev2: Array[Dictionary] = advance(sim2)
	assert_event(ev2, "hit_intercepted", "L2 guard range 2 covers the drifted ward")
	assert_eq(int((sim2.combatants["guardian"] as CombatantState).parts["torso"]["hp"]), 2,
		"guardian takes it whole at L2 (no reduction yet)")
	# L3 (-1 physical damage when intercepting): the zig-zag's other rail.
	var sim3: CombatSim = make_sim(4906)
	add_party(sim3, "guardian", [0, 0])
	add_party(sim3, "ally", [1, 0])
	add_elite(sim3, "foe", [2, 0])
	guard_declare(sim3, "guardian", "ally", 3)
	advance(sim3)
	declare(sim3, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev3: Array[Dictionary] = advance(sim3)
	var icept: Dictionary = assert_event(ev3, "hit_intercepted", "L3 intercepts")
	assert_eq(int(icept.get("reduction", -1)), 1, "the per-interception reduction rides the event")
	assert_eq(int((sim3.combatants["guardian"] as CombatantState).parts["torso"]["hp"]), 3,
		"net 3 - 1 intercept reduction = 2 (5 -> 3)")


func test_intercept_catches_undodgable_hits() -> void:
	# R26 composition: an undodgable hit skips every dodge-shaped ESCAPE — but
	# interception is NOT a dodge (taking the hit on another body escapes
	# nothing), so it still applies.
	var sim: CombatSim = make_sim(4907)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [2, 0])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso", {"undodgable": true}))
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "hit_intercepted", "undodgable is still interceptable (R26)")
	assert_eq(int((sim.combatants["guardian"] as CombatantState).parts["torso"]["hp"]), 2,
		"the guardian takes the undodgable hit")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 5, "ward clean")


func test_intercept_merged_force_retargets_whole() -> void:
	# R15 composition: the merged hit retargets WHOLE — one decision, one
	# reaction slot, ONE merged gate against the guardian.
	var sim: CombatSim = make_sim(4908)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe_a", [2, 0])
	add_elite(sim, "foe_b", [1, 1])
	add_elite(sim, "foe_c", [0, 1])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	sim.apply_command({"type": "combined_action", "combo_id": "pair", "members": [
		{"actor": "foe_a", "action": attack_action("crushed", 1, "ally", "torso")},
		{"actor": "foe_b", "action": attack_action("crushed", 1, "ally", "torso")},
	]})
	# A third, SOLO aimed hit the same tick: the merged interception must have
	# spent the one reaction, so this one passes through to the ward.
	declare(sim, "foe_c", attack_action("crushed", 1, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(events_of(ev, "hit_intercepted").size(), 1, "one interception for the whole merged hit")
	var cf: Dictionary = assert_event(ev, "combined_force", "the merged gate still fires")
	assert_eq(String(cf.get("combatant", "")), "guardian", "the ONE merged gate evaluates vs the GUARDIAN")
	assert_eq(int(cf.get("force", -1)), 4, "merged Force (1+1)+(1+1) = 4")
	assert_eq(int(cf.get("net", -1)), 3, "net = 4 - the guardian's Robustness 1")
	var guardian: CombatantState = sim.combatants["guardian"]
	assert_eq(int(guardian.parts["torso"]["hp"]), 2, "the guardian eats the merged net 3")
	assert_eq(guardian.condition_tier("torso", "crushed"), 1, "the merged riders land on the guardian")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 4,
		"the same-tick solo hit passes through — ONE reaction paid for the whole merged hit")


func test_intercept_guard_sweep_clears_on_downed() -> void:
	# Guardian down mid-batch: the second aimed hit passes through (live
	# eligibility), and the sweep clears the guard + the armed prime.
	var sim: CombatSim = make_sim(4909)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe_a", [2, 0])
	add_elite(sim, "foe_b", [1, 1])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	declare(sim, "foe_a", attack_action("crushed", 20, "ally", "torso"))
	declare(sim, "foe_b", attack_action("crushed", 20, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var guardian: CombatantState = sim.combatants["guardian"]
	assert_event(ev, "hit_intercepted", "the first killer blow is taken")
	assert_false(guardian.alive, "the guardian died for the ward (torso 5 vs net 20)")
	assert_false((sim.combatants["ally"] as CombatantState).alive,
		"the second blow passed through a dead guardian")
	var ended: Dictionary = assert_event(ev, "guard_ended", "the sweep clears the guard")
	assert_eq(String(ended.get("reason", "")), "downed", "reason: the guardian went down")
	assert_true(guardian.guard.is_empty(), "guard record cleared")
	assert_false(bool(guardian.armed_primes.get("intercept", false)), "prep substrate cleared with it")


func test_intercept_does_not_reface_the_guardian() -> void:
	# R30: the interception is involuntary-adjacent — the guardian's facing
	# never changes (reactions / out-of-schedule strikes are off the table).
	var sim: CombatSim = make_sim(4910)
	add_party(sim, "guardian", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [1, 1])
	guard_declare(sim, "guardian", "ally")
	advance(sim)
	var guardian: CombatantState = sim.combatants["guardian"]
	var facing_before: int = guardian.facing
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "hit_intercepted", "the hit was intercepted")
	assert_eq(guardian.facing, facing_before, "taking the hit never re-faces the guardian")


# ================================================================ iron stance

func test_iron_stance_covers_all_adjacent_allies_with_no_reaction_cost() -> void:
	var sim: CombatSim = make_sim(4920)
	add_party(sim, "stancer", [1, 0])
	add_party(sim, "a1", [0, 0])
	add_party(sim, "a2", [2, 0])
	add_party(sim, "a_far", [3, 0])  # distance 2 from the stancer — uncovered at L1
	add_elite(sim, "foe_a", [-1, 1])
	add_elite(sim, "foe_b", [2, 1])
	add_elite(sim, "foe_c", [4, 0])
	var declared: Array[Dictionary] = stance_declare(sim, "stancer")
	assert_event(declared, "action_declared", "the stance declares (cost 0)")
	var started: Array[Dictionary] = advance(sim)
	assert_event(started, "iron_stance_started", "the stance is held")
	declare(sim, "foe_a", attack_action("crushed", 3, "a1", "torso"))
	declare(sim, "foe_b", attack_action("crushed", 3, "a2", "torso"))
	declare(sim, "foe_c", attack_action("crushed", 3, "a_far", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var intercepts: Array[Dictionary] = events_of(ev, "hit_intercepted")
	assert_eq(intercepts.size(), 2, "BOTH adjacent allies covered the same tick — no reaction cost")
	for icept: Dictionary in intercepts:
		assert_eq(String(icept.get("mode", "")), "stance", "the stance form")
	var stancer: CombatantState = sim.combatants["stancer"]
	assert_false(stancer.reaction_used, "the stance never touches the reaction slot (its value)")
	# Each hit: Force 4 - Robustness 1 = 3, then the persistent -1 -> 2. Twice.
	assert_eq(int(stancer.parts["torso"]["hp"]), 1, "5 - 2 - 2 = 1 (persistent -1 on each)")
	assert_eq(events_of(ev, "iron_stance_reduced").size(), 2, "the reduction is NON-consumed")
	assert_eq(int((sim.combatants["a1"] as CombatantState).parts["torso"]["hp"]), 5, "a1 clean")
	assert_eq(int((sim.combatants["a2"] as CombatantState).parts["torso"]["hp"]), 5, "a2 clean")
	assert_eq(int((sim.combatants["a_far"] as CombatantState).parts["torso"]["hp"]), 2,
		"distance 2 > L1 radius 1: the far ally takes its own hit")


func test_iron_stance_reduction_stacks_with_brace_and_persists() -> void:
	var sim: CombatSim = make_sim(4921)
	add_party(sim, "stancer", [0, 0])
	add_elite(sim, "foe", [1, 0])
	stance_declare(sim, "stancer", 2)  # L2: reduction -2 (Crush/Burn)
	advance(sim)
	declare(sim, "stancer", {"kind": "skill", "key": "brace", "level": 1})  # guard 1
	advance(sim)
	declare(sim, "foe", attack_action("crushed", 5, "stancer", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var stance_red: Dictionary = assert_event(ev, "iron_stance_reduced", "the stance reduces first")
	assert_eq(int(stance_red.get("damage_before", -1)), 5, "net 6 - 1 = 5 before the stance")
	assert_eq(int(stance_red.get("damage_after", -1)), 3, "-2 stance (posture)")
	var braced: Dictionary = assert_event(ev, "brace_absorbed", "the brace stacks on top (flinch)")
	assert_eq(int(braced.get("damage_after", -1)), 2, "-1 brace -> 2")
	var stancer: CombatantState = sim.combatants["stancer"]
	assert_eq(int(stancer.parts["torso"]["hp"]), 3, "5 - 2 = 3")
	# Next hit: the brace was CONSUMED, the stance was NOT.
	declare(sim, "foe", attack_action("crushed", 2, "stancer", "torso"))
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "iron_stance_reduced", "the stance reduction persists (non-consumed)")
	assert_no_event(ev2, "brace_absorbed", "the brace is gone")
	assert_eq(int(stancer.parts["torso"]["hp"]), 3, "Force 3 - 1 = 2, stance -2 -> 0 damage")


func test_iron_stance_type_coverage_l1_vs_l4() -> void:
	# L1 covers Crush/Burn only — a Bleed hit passes the reduction untouched.
	var sim: CombatSim = make_sim(4922)
	add_party(sim, "stancer", [0, 0])
	add_elite(sim, "foe", [1, 0])
	stance_declare(sim, "stancer")
	advance(sim)
	declare(sim, "foe", attack_action("bleeding", 3, "stancer", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "iron_stance_reduced", "L1 types are Crush/Burn — Bleed passes")
	assert_eq(int((sim.combatants["stancer"] as CombatantState).parts["torso"]["hp"]), 2,
		"full net 3 lands")
	# L4: the reduction extends to Bleed and Chill.
	var sim2: CombatSim = make_sim(4923)
	add_party(sim2, "stancer", [0, 0])
	add_elite(sim2, "foe", [1, 0])
	stance_declare(sim2, "stancer", 4)  # L4: reduction 2, types + bleeding/chilled
	advance(sim2)
	declare(sim2, "foe", attack_action("bleeding", 3, "stancer", "torso"))
	var ev2: Array[Dictionary] = advance(sim2)
	assert_event(ev2, "iron_stance_reduced", "L4 covers Bleed")
	assert_eq(int((sim2.combatants["stancer"] as CombatantState).parts["torso"]["hp"]), 4,
		"net 3 - 2 = 1")


func test_iron_stance_breaks_on_move_and_prone() -> void:
	# The dance-exit pattern: movement ends the stance the moment it happens.
	var sim: CombatSim = make_sim(4924)
	add_party(sim, "stancer", [1, 0])
	add_party(sim, "ally", [0, 0])
	add_elite(sim, "foe", [-1, 1])
	stance_declare(sim, "stancer")
	advance(sim)
	var moved: Array[Dictionary] = move(sim, "stancer", [2, 0])
	var ended: Dictionary = assert_event(moved, "iron_stance_ended", "the step breaks the stance")
	assert_eq(String(ended.get("reason", "")), "moved", "reason: moved off the anchor")
	assert_true((sim.combatants["stancer"] as CombatantState).iron_stance.is_empty(), "state cleared")
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "hit_intercepted", "a broken stance covers nobody")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 2,
		"the ally takes its own hit")
	# Prone breaks it too.
	var sim2: CombatSim = make_sim(4925)
	add_party(sim2, "stancer", [1, 0])
	stance_declare(sim2, "stancer")
	advance(sim2)
	var downed: Array[Dictionary] = sim2.apply_command({"type": "set_status",
		"target": "stancer", "status": "prone", "value": true})
	var ended2: Dictionary = assert_event(downed, "iron_stance_ended", "prone breaks the stance")
	assert_eq(String(ended2.get("reason", "")), "prone", "reason: prone")
	# And declaring it WHILE prone rejects outright.
	assert_rejected(stance_declare(sim2, "stancer"), "prone",
		"a prone stancer cannot hold ground")


func test_iron_stance_radius_widens_at_l3() -> void:
	var sim: CombatSim = make_sim(4926)
	add_party(sim, "stancer", [0, 0])
	add_party(sim, "ally", [2, 0])  # distance 2
	add_elite(sim, "foe", [3, 0])
	stance_declare(sim, "stancer", 3)  # L3: +1 protected radius -> 2
	advance(sim)
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "hit_intercepted", "L3 radius 2 covers the distance-2 ally")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 5, "ally clean")


func test_forge_chain_iron_stance_granted_and_usable() -> void:
	# The FULL Gemstone chain: the shipped recipe (Intercept Lv5 + Brace Lv3,
	# both parents consumed) -> apply_mutation -> the grant row -> a staged
	# combatant -> the stance DECLARES at the granted level and really guards.
	var mutations: Dictionary = load_json("res://data/skill_mutations.json")
	var keywords: Dictionary = load_json("res://data/skill_keywords.json")
	var recipe: Dictionary = SkillForge.find_recipe(mutations, "iron_stance")
	assert_false(recipe.is_empty(), "the shipped recipe exists")
	var roster: Array = [{"key": "intercept", "level": 5}, {"key": "brace", "level": 3}]
	var mutated: Array[Dictionary] = SkillForge.apply_mutation(roster, recipe, keywords)
	assert_eq(mutated.size(), 1, "both parents consumed")
	assert_eq(String(mutated[0].get("key", "")), "iron_stance", "the result arrives")
	var sim: CombatSim = make_sim(4927)
	add_human(sim, "tank", {"team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"skills": mutated})
	add_party(sim, "ally", [0, 0])
	add_elite(sim, "foe", [-1, 1])
	var tank: CombatantState = sim.combatants["tank"]
	assert_eq(tank.skill_level("iron_stance"), 1, "granted at the recipe level")
	assert_eq(tank.skill_level("intercept"), 0, "parent consumed")
	stance_declare(sim, "tank", tank.skill_level("iron_stance"))
	var started: Array[Dictionary] = advance(sim)
	assert_event(started, "iron_stance_started", "the forged skill declares and holds")
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var icept: Dictionary = assert_event(ev, "hit_intercepted", "the forge result REALLY guards")
	assert_eq(String(icept.get("guardian", "")), "tank", "the tank takes the hit")
	assert_eq(int(tank.parts["torso"]["hp"]), 3, "net 3, stance -1 -> 2 (5 -> 3)")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]), 5, "ally clean")


# ============================================================== pressure_hold

func test_pressure_hold_locks_both_and_faces_the_pair() -> void:
	var sim: CombatSim = make_sim(4930)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0], {"size": "Medium"})
	var declared: Array[Dictionary] = declare(sim, "holder", {
		"kind": "skill", "key": "pressure_hold", "level": 1, "target": "victim"})
	var decl: Dictionary = assert_event(declared, "action_declared", "the clinch declares")
	assert_true(bool(decl.get("windup", false)), "cost 2 — a committed windup")
	var ev: Array[Dictionary] = advance(sim, 3)
	var started: Dictionary = assert_event(ev, "grapple_started", "the hold lands at resolution")
	assert_eq(String(started.get("skill", "")), "pressure_hold", "attributed to the skill")
	var holder: CombatantState = sim.combatants["holder"]
	var victim: CombatantState = sim.combatants["victim"]
	assert_eq(holder.grappling, "victim", "R9 link set")
	assert_eq(victim.grappled_by, "holder", "R9 link set")
	assert_true(holder.exposed_cache, "BOTH are Exposed while held (R9)")
	assert_true(victim.exposed_cache, "BOTH are Exposed while held (R9)")
	assert_rejected(move(sim, "holder", [0, 1]), "grappled", "neither repositions (R9)")
	assert_rejected(move(sim, "victim", [2, 0]), "grappled", "neither repositions (R9)")
	# R30: the grapple faces both parties toward each other (already automatic).
	assert_eq(holder.facing, 0, "holder faces E toward the victim")
	assert_eq(victim.facing, 3, "the held victim is turned W toward the holder")
	assert_no_event(ev, "forced_action_triggered", "equal Physique: the hold is automatic (R9)")


func test_pressure_hold_above_weight_rolls_forced_body_but_lands() -> void:
	var sim: CombatSim = make_sim(4931)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0], {"size": "Medium",
		"traits": {"physique": 4, "reflexes": 3, "mind": 0, "charm": 3}})
	declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 1, "target": "victim"})
	var ev: Array[Dictionary] = advance(sim, 3)
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "above weight: Forced Body")
	assert_eq(String(forced.get("table", "")), "body", "the R9 Body table")
	assert_eq(String(forced.get("reason", "")), "grapple_above_weight", "attributed")
	assert_eq((sim.combatants["holder"] as CombatantState).grappling, "victim",
		"always allowed — the hold still lands")


func test_pressure_hold_windup_escape_collapses() -> void:
	var sim: CombatSim = make_sim(4932)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0], {"size": "Medium"})
	declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 1, "target": "victim"})
	advance(sim)
	move(sim, "victim", [4, 0])  # slips the clinch during the windup
	var ev: Array[Dictionary] = advance(sim, 2)
	var invalidated: Dictionary = assert_event(ev, "action_invalidated", "the premise broke")
	assert_eq(String(invalidated.get("reason", "")), "out_of_range", "target left the clinch (R2)")
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the standard windup collapse")
	assert_eq(String(forced.get("table", "")), "tool", "a SELF-broken windup keeps Tool (F3's other half)")
	assert_eq((sim.combatants["holder"] as CombatantState).grappling, "", "no hold")


func test_pressure_hold_drag_ladder() -> void:
	var sim: CombatSim = make_sim(4933)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0], {"size": "Medium"})
	declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 1, "target": "victim"})
	advance(sim, 3)
	# Gates: no drag at L1; range-capped at L2; only while holding.
	assert_rejected(declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 1,
		"target": "victim", "drag_to": [-1, 0]}), "drag_not_available", "L1 has no drag")
	assert_rejected(declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 2,
		"target": "victim", "drag_to": [-2, 0]}), "drag_out_of_range", "L2 drags 1 space per Moment")
	assert_rejected(declare(sim, "victim", {"kind": "skill", "key": "pressure_hold", "level": 2,
		"target": "holder", "drag_to": [2, 0]}), "not_holding_target", "only the holder drags")
	# The real drag: holder steps, victim is pulled into the vacated hex.
	var declared: Array[Dictionary] = declare(sim, "holder", {"kind": "skill", "key": "pressure_hold",
		"level": 2, "target": "victim", "drag_to": [-1, 0]})
	var decl: Dictionary = assert_event(declared, "action_declared", "the drag declares")
	assert_eq(int(decl.get("cost", -1)), 1, "the drag is a 1-Moment action (normalized)")
	var ev: Array[Dictionary] = advance(sim)
	var dragged: Dictionary = assert_event(ev, "grapple_dragged", "the drag resolves")
	assert_eq(int(dragged.get("spaces", -1)), 1, "one deterministic 1-hex step")
	var holder: CombatantState = sim.combatants["holder"]
	var victim: CombatantState = sim.combatants["victim"]
	assert_eq(holder.position, Vector2i(-1, 0), "holder stepped to the drag hex")
	assert_eq(victim.position, Vector2i(0, 0), "victim pulled into the vacated hex (grab_pull idiom)")
	assert_eq(holder.grappling, "victim", "the hold survives the drag")
	# R30: the holder's step is voluntary (faces W); the DRAGGED victim's
	# facing never changes (drag is on the involuntary exclusion list).
	assert_eq(holder.facing, 3, "holder faces the drag direction")
	assert_eq(victim.facing, 3, "the victim's facing is untouched (still W from the hold)")
	# Dragging INTO the held body stops honestly (spaces 0, nobody moves).
	declare(sim, "holder", {"kind": "skill", "key": "pressure_hold",
		"level": 2, "target": "victim", "drag_to": [0, 0]})
	var ev2: Array[Dictionary] = advance(sim)
	var stuck: Dictionary = assert_event(ev2, "grapple_dragged", "the blocked drag still resolves")
	assert_eq(int(stuck.get("spaces", -1)), 0, "the victim's own body blocks the lane — no step")
	assert_eq(holder.position, Vector2i(-1, 0), "holder held position")


# ============================================================ death_grip_jaws

func test_death_grip_jaws_unlocks_grappling_for_handless_layouts() -> void:
	var sim: CombatSim = make_sim(4940)
	add_croc(sim, "croc", [0, 0])
	add_elite(sim, "victim", [1, 0], {"size": "Medium"})
	var croc: CombatantState = sim.combatants["croc"]
	assert_eq(croc.usable_hands(sim.clock.tick), 0, "precondition: genuinely handless")
	assert_eq(croc.bite_part(sim.clock.tick), "head", "the bite-capable head is the grip")
	# The hands-gated hold rejects; the jaws hold does not (G6: no prime).
	assert_rejected(declare(sim, "croc", {"kind": "skill", "key": "pressure_hold", "level": 1,
		"target": "victim"}), "no_free_hand", "pressure_hold still asks for hands")
	var declared: Array[Dictionary] = declare(sim, "croc", {
		"kind": "skill", "key": "death_grip_jaws", "level": 1, "target": "victim"})
	assert_event(declared, "action_declared", "the bite-grapple declares (cost 1, no prime)")
	var ev: Array[Dictionary] = advance(sim)
	var started: Dictionary = assert_event(ev, "grapple_started", "the jaws close")
	assert_eq(String(started.get("skill", "")), "death_grip_jaws", "attributed")
	assert_eq(croc.grappling, "victim", "the hold is a REAL R9 link")
	assert_true((sim.combatants["victim"] as CombatantState).exposed_cache, "both Exposed (R9)")
	assert_no_event(ev, "bite_rider", "no Bleed rider at L1")


func test_death_grip_jaws_bite_gate_and_bleed_rider() -> void:
	# A disabled head is no grip.
	var sim: CombatSim = make_sim(4941)
	add_croc(sim, "croc", [0, 0], {"body_parts": [
		{"key": "head", "hp": 4, "lethal": true, "bite_capable": true, "disabled": true},
		{"key": "torso", "hp": 6, "lethal": true},
		{"key": "left_leg", "hp": 3, "lethal": false},
	]})
	add_elite(sim, "victim", [1, 0], {"size": "Medium"})
	assert_rejected(declare(sim, "croc", {"kind": "skill", "key": "death_grip_jaws", "level": 1,
		"target": "victim"}), "no_bite_part", "a disabled jaw cannot hold")
	# L2: the initial bite deals 1 Bleed on close, through the honest R14 gate.
	var sim2: CombatSim = make_sim(4942)
	add_croc(sim2, "croc", [0, 0])
	add_elite(sim2, "victim", [1, 0], {"size": "Medium"})
	declare(sim2, "croc", {"kind": "skill", "key": "death_grip_jaws", "level": 2, "target": "victim"})
	var ev: Array[Dictionary] = advance(sim2)
	var bite: Dictionary = assert_event(ev, "bite_rider", "the L2 bite rider fires on close")
	assert_eq(int(bite.get("amount", -1)), 1, "1 Bleed (PLACEHOLDER R14)")
	assert_eq(String(bite.get("part", "")), "torso", "deterministic torso-line locus")
	var victim: CombatantState = sim2.combatants["victim"]
	assert_eq(int(victim.parts["torso"]["hp"]), 49, "Force 1+1 - Robustness 1 = 1 (50 -> 49)")
	assert_eq(victim.condition_tier("torso", "bleeding"), 1, "the Bleed rides the landed bite")
	# The bite_capable flag round-trips inside the parts dict.
	var restored: CombatantState = CombatantState.from_dict((sim2.combatants["croc"] as CombatantState).to_dict())
	assert_eq(restored.bite_part(0), "head", "bite_capable survives serialization")


# ============================================================== counter_surge

func test_counter_surge_rejects_without_a_windup() -> void:
	var sim: CombatSim = make_sim(4950)
	add_party(sim, "surger", [0, 0])
	add_elite(sim, "idle", [1, 0])
	assert_rejected(declare(sim, "surger", {"kind": "skill", "key": "counter_surge", "level": 1,
		"targets": [{"id": "idle", "part": "torso"}]}), "prime_unmet",
		"the STATE prime asks for a target mid-windup (Clock.has_windup_for)")


## Stages the interrupt geometry: the winder (elite) winds up strong_strike at
## a dummy elite; the surger stands adjacent to the winder.
func _windup_sim(sim_seed: int) -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	add_party(sim, "surger", [0, 0])
	add_elite(sim, "winder", [1, 0])
	add_elite(sim, "dummy", [2, 0])
	declare(sim, "winder", {"kind": "skill", "key": "strong_strike", "level": 1,
		"targets": [{"id": "dummy", "part": "torso"}]})
	return sim


func test_counter_surge_cut_reschedules_the_windup() -> void:
	var sim: CombatSim = _windup_sim(4951)
	var declared: Array[Dictionary] = declare(sim, "surger", {"kind": "skill", "key": "counter_surge",
		"level": 1, "targets": [{"id": "winder", "part": "torso"}]})
	assert_event(declared, "action_declared", "the interrupt declares (cost 1)")
	var ev: Array[Dictionary] = advance(sim)
	# The strike connected (basic unarmed default: Force 1+1 - Robustness 1 = 1).
	var winder: CombatantState = sim.combatants["winder"]
	assert_eq(int(winder.parts["torso"]["hp"]), 49, "the interrupt strike lands (50 -> 49)")
	var cut: Dictionary = assert_event(ev, "windup_cut", "the connected hit cuts the remaining cost")
	assert_eq(int(cut.get("remaining_before", -1)), 2, "2 Moments remained")
	assert_eq(int(cut.get("cut", -1)), 1, "L1 cuts 1")
	assert_eq(int(cut.get("remaining_after", -1)), 1, "1 remains")
	assert_eq(int(cut.get("resolve_tick", -1)), 1, "rescheduled a tick earlier (Clock reschedule)")
	assert_eq(winder.next_action_tick, 1, "the shortened cost pulls readiness in sync")
	# The rescheduled entry is plain command-stream state — a mid-cut
	# round-trip resumes on the SAME shortened timeline (serialized-consistent).
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "the rescheduled queue entry round-trips")
	# The shortened windup fires a tick EARLY, exactly once — on both timelines.
	var ev2: Array[Dictionary] = advance(sim)
	var dummy: CombatantState = sim.combatants["dummy"]
	assert_eq(int(dummy.parts["torso"]["hp"]), 44, "strong_strike resolved at tick 1 (Force 7 - 1 = 6)")
	var ev3: Array[Dictionary] = advance(sim)
	assert_no_event(ev3, "damage_applied", "nothing left at the original tick 2")
	assert_true(has_event(ev2, "action_resolved"), "the cut action still resolved (honestly, early)")
	advance(restored, 2)
	assert_eq(restored.state_hash(), sim.state_hash(), "restore -> replay tail = same hash")


func test_counter_surge_full_cut_collapses_into_forced_body() -> void:
	var sim: CombatSim = _windup_sim(4952)
	declare(sim, "surger", {"kind": "skill", "key": "counter_surge",
		"level": 2, "targets": [{"id": "winder", "part": "torso"}]})
	var ev: Array[Dictionary] = advance(sim)
	var collapsed: Dictionary = assert_event(ev, "windup_collapsed", "cut 2 >= remaining 2: collapse")
	assert_eq(String(collapsed.get("victim", "")), "winder", "attributed to the victim")
	assert_eq(String(collapsed.get("key", "")), "strong_strike", "names what died")
	var invalidated: Dictionary = assert_event(ev, "action_invalidated", "the action is gone")
	assert_eq(String(invalidated.get("actor", "")), "winder", "the winder's action")
	assert_eq(String(invalidated.get("reason", "")), "windup_cut", "reason: the cut")
	# F3: the collapse table is a PARAMETER — this path rolls BODY, never a
	# silently-reused Tool.
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the victim rolls")
	assert_eq(String(forced.get("actor", "")), "winder", "the victim rolls it")
	assert_eq(String(forced.get("table", "")), "body", "Forced Action - BODY (F3)")
	assert_eq(String(forced.get("reason", "")), "windup_cut", "attributed to the cut")
	# The collapsed strike never fires.
	advance(sim, 2)
	assert_eq(int((sim.combatants["dummy"] as CombatantState).parts["torso"]["hp"]), 50,
		"the dummy is never hit — the windup died")
	assert_false((sim.combatants["winder"] as CombatantState).windup_pending,
		"the victim's windup state cleared")


func test_counter_surge_same_tick_resolution_misses_the_cut() -> void:
	# R2 simultaneity: a windup due THIS tick is already firing — the interrupt
	# still lands its strike but there is nothing left to cut.
	var sim: CombatSim = _windup_sim(4953)
	advance(sim, 2)  # the windup resolves at tick 2's advance
	declare(sim, "surger", {"kind": "skill", "key": "counter_surge",
		"level": 1, "targets": [{"id": "winder", "part": "torso"}]})
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "windup_cut_missed", "same-tick means already firing — no cut")
	assert_no_event(ev, "windup_cut", "nothing was rescheduled")
	assert_eq(int((sim.combatants["dummy"] as CombatantState).parts["torso"]["hp"]), 44,
		"the windup fired normally this very tick")
	assert_eq(int((sim.combatants["winder"] as CombatantState).parts["torso"]["hp"]), 49,
		"the interrupt strike still landed")


# ==================================== serialization, determinism, compat pins

func test_batch_b_state_round_trips_mid_everything() -> void:
	# Guard armed + stance held + hold live + a rescheduled windup — the full
	# batch-B state surface — must survive to_dict/from_dict and continue
	# identically on both timelines.
	var live: CombatSim = make_sim(4960)
	add_party(live, "guardian", [0, 0])
	add_party(live, "ally", [1, 0])
	add_party(live, "stancer", [0, 1])
	add_party(live, "holder", [3, 0])
	add_elite(live, "victim", [4, 0], {"size": "Medium"})
	add_elite(live, "foe", [2, 0])
	guard_declare(live, "guardian", "ally")
	stance_declare(live, "stancer")
	declare(live, "holder", {"kind": "skill", "key": "pressure_hold", "level": 2, "target": "victim"})
	advance(live)
	declare(live, "foe", {"kind": "skill", "key": "strong_strike", "level": 1,
		"targets": [{"id": "ally", "part": "torso"}]})
	advance(live)
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the round-trip")
	var r_guardian: CombatantState = restored.combatants["guardian"]
	assert_eq(String(r_guardian.guard.get("ally", "")), "ally", "the guard record round-trips")
	assert_false((restored.combatants["stancer"] as CombatantState).iron_stance.is_empty(),
		"the stance round-trips")
	# Both timelines continue identically — the foe's windup resolves, aimed at
	# the guarded ally, and BOTH intercept it.
	var live_ev: Array[Dictionary] = advance(live, 2)
	var rest_ev: Array[Dictionary] = advance(restored, 2)
	assert_event(live_ev, "hit_intercepted", "live: the guard fires")
	assert_event(rest_ev, "hit_intercepted", "restored: the guard fires identically")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_batch_b_fields_serialize_only_when_set() -> void:
	# The compat pin: a batch-B-free fight carries neither key on any combatant.
	var sim: CombatSim = make_sim(4961)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("guard"), "no 'guard' key on a guard-free combatant (%s)" % id)
		assert_false(c.has("iron_stance"), "no 'iron_stance' key on a stance-free combatant (%s)" % id)


func test_batch_b_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(4962)
		add_party(sim, "guardian", [0, 0])
		add_party(sim, "ally", [1, 0])
		add_party(sim, "holder", [3, 1], 2)  # phys 2 < elite 3: the hold rolls Forced Body
		add_elite(sim, "victim", [4, 1], {"size": "Medium"})
		add_elite(sim, "foe", [2, 0])
		guard_declare(sim, "guardian", "ally")
		declare(sim, "holder", {"kind": "skill", "key": "pressure_hold", "level": 1, "target": "victim"})
		advance(sim)
		declare(sim, "foe", {"kind": "skill", "key": "strong_strike", "level": 1,
			"targets": [{"id": "ally", "part": "torso"}]})
		advance(sim, 2)
		declare(sim, "ally", {"kind": "skill", "key": "counter_surge", "level": 2,
			"targets": [{"id": "foe", "part": "torso"}]})
		advance(sim, 3)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole batch")
