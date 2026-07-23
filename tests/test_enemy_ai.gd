extends SimTestBase
## Enemy AI v1 (simulation/enemy_ai.gd, I-16) — ai_decide plumbing, mob/elite
## policy pins, summoning, determinism and serialization. The Incinedile boss
## (phase machine + dodge threshold) is covered in test_incinedile.gd.
##
## Policy expectations pin the R11 #15/#16 rules as amended by R23 (decision
## #29): targeting is the antagonism-weighted draw (one salted ai_rng randf per
## >= 2-candidate decision, zero for a single candidate), everything else stays
## rng-free rules over sorted state. Multi-candidate target pins therefore
## predict the draw with a twin RNG instead of hardcoding a name — still exact,
## still deterministic. The engine's own anchors (50/50, grudge, rng cost,
## decay, serialization) live in tests/test_antagonism.gd.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## Weak target: a torso-only 3 HP dummy so total-HP tie-breaks are unambiguous.
func weak_parts() -> Array:
	return [{"key": "torso", "name": "Torso", "hp": 3, "lethal": true}]


# ---------------------------------------------------------------- plumbing

func test_ai_decide_rejections() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "roach", "roach_dog")
	assert_rejected(ai_decide(sim, "ghost"), "unknown_actor", "unknown actor rejected")
	assert_rejected(ai_decide(sim, "h"), "not_ai_controlled", "contestants are never AI-driven")
	# Acting consumes the schedule: a second decide this tick is not_ready.
	var first: Array[Dictionary] = ai_decide(sim, "roach")
	assert_event(first, "ai_decision", "first decide acted")
	assert_rejected(ai_decide(sim, "roach"), "not_ready", "one scheduled action per tick")
	# Helpless gate (Shock T3 = Faint, R13): no decisions while out cold.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim2, "roach", "roach_dog")
	sim2.apply_command({"type": "apply_condition", "target": "roach", "part": "carapace", "condition": "shock", "tier": 3})
	assert_rejected(ai_decide(sim2, "roach"), "helpless", "a fainted mob makes no decisions")
	# Dead gate: a killed mob is rejected with the standard vocabulary.
	var sim3: CombatSim = make_sim()
	add_human(sim3, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim3, "roach", "roach_dog")
	declare(sim3, "h", attack_action("crushed", 1, "roach", "carapace"))
	advance(sim3, 1)
	assert_rejected(ai_decide(sim3, "roach"), "actor_dead", "dead mobs are rejected")


func test_ai_ready_ids_lists_only_ready_enemies() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "roach_a", "roach_dog")
	add_enemy(sim, "roach_b", "roach_dog", {"position": [0, 1]})
	assert_eq(sim.ai_ready_ids(), ["roach_a", "roach_b"], "both mobs ready, sorted; the human never listed")
	ai_decide(sim, "roach_a")
	assert_eq(sim.ai_ready_ids(), ["roach_b"], "an enemy that acted drops out until its next tick")
	advance(sim, 1)
	assert_eq(sim.ai_ready_ids(), ["roach_a", "roach_b"], "the next tick restores readiness")


# ---------------------------------------------------------------- mob policy

func test_mob_attacks_adjacent_target() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "roach", "roach_dog")
	var events: Array[Dictionary] = ai_decide(sim, "roach")
	var decision: Dictionary = assert_event(events, "ai_decision", "mob decided")
	assert_eq(String(decision.get("choice", "")), "attack", "adjacent target -> attack")
	assert_eq(String(decision.get("tier", "")), "mob", "mob tier")
	assert_eq(String(decision.get("ability", "")), "bite", "seeded ability used")
	assert_eq(String(decision.get("target", "")), "h", "target carried on the decision")
	assert_false(bool(decision.get("moves", true)), "no move needed in reach")
	assert_event(events, "action_declared", "the attack was declared through the resolver")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var damage: Dictionary = assert_event(resolved, "damage_applied", "bite landed")
	assert_eq(String(damage.get("combatant", "")), "h", "damage on the target")
	assert_eq(String(damage.get("part", "")), "torso", "mob part pick is torso-line")
	# R14 (decision-log #22): the roach-dog's bite Force = 1 + floor(physique 1 / 2)
	# = 1 fails to clear a fresh phys-3 human's Robustness (floor(3/2) = 1), so it
	# nets 0 and opens no wound — bleeding does NOT seed (D3). This is a placeholder
	# magnitude: a lone phys-1 mob no longer chips a phys-3 contestant (tuned later);
	# the AI-policy assertions above are the point of this test.
	assert_eq(int(damage.get("amount", -1)), 0, "R14: bite Force 1 ≤ Robustness 1 → blocked to 0")
	assert_event(resolved, "attack_no_wound", "a blocked bite seeds no bleeding (R14 D3)")
	assert_no_event(resolved, "condition_applied", "no wound → no bleeding on a blocked hit")


## R23 (decision #29) REWRITE — the nearest → lowest-HP → id cascade this test
## used to pin is SUPERSEDED by the antagonism-weighted draw. The kept INTENT:
## a closer target is much likelier (inverse-square weight, pinned EXACTLY),
## and the decision IS the weighted draw at the live ai_rng state (predicted
## with a twin RNG, never hardcoded). The deep engine pins (50/50 anchor,
## grudge, rng cost) live in tests/test_antagonism.gd.
func test_mob_targeting_is_the_weighted_draw() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h_far", {"team": "party", "position": [4, 0]})
	add_human(sim, "h_near", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "roach", "roach_dog")
	var roach: CombatantState = sim.combatants["roach"]
	var candidates: Array[CombatantState] = [sim.combatants["h_far"] as CombatantState, sim.combatants["h_near"] as CombatantState]
	var rows: Array[Dictionary] = sim.ai.targeting_weights(roach, candidates, roach.position)
	# No history, default personality (proximity_bias 2.0): distance 4 vs 1 is
	# EXACTLY inverse-square — 1/16 vs 1 (the "closer = much higher" canon).
	assert_eq(float((rows[0] as Dictionary)["weight"]), 1.0 / 16.0, "far weight = 1/4^2 exactly")
	assert_eq(float((rows[1] as Dictionary)["weight"]), 1.0, "adjacent weight = 1 exactly")
	var expected: String = _predicted_pick(sim, "roach")
	var decision: Dictionary = first_event(ai_decide(sim, "roach"), "ai_decision")
	assert_eq(String(decision.get("target", "")), expected,
		"the decision IS the weighted draw at the live ai_rng state (16:1 toward the near)")


## Twin-RNG prediction of the R23 weighted pick the actor's next decide will
## make (from the CURRENT ai_rng state), replaying pick_weighted_target's walk
## over targeting_weights in sorted-id order. "" when it would not draw.
func _predicted_pick(sim: CombatSim, actor_id: String) -> String:
	var actor: CombatantState = sim.combatants[actor_id]
	var opponents: Array[CombatantState] = sim.ai._opponents(actor)
	if opponents.size() < 2:
		return "" if opponents.is_empty() else opponents[0].id
	var rows: Array[Dictionary] = sim.ai.targeting_weights(actor, opponents, actor.position)
	var twin := RandomNumberGenerator.new()
	twin.state = sim.ai.ai_rng.state
	var total: float = 0.0
	for row: Dictionary in rows:
		total += float(row["weight"])
	var draw: float = twin.randf() * total
	var cumulative: float = 0.0
	for i: int in range(rows.size()):
		cumulative += float((rows[i] as Dictionary)["weight"])
		if draw < cumulative:
			return String((rows[i] as Dictionary)["id"])
	return String((rows[rows.size() - 1] as Dictionary)["id"])


func test_mob_closes_distance_then_attacks() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [5, 0]})
	add_enemy(sim, "roach", "roach_dog")
	# Tick 0: 5 hexes out — free-move 3, still out of reach, no attack.
	var events: Array[Dictionary] = ai_decide(sim, "roach")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "move", "out of reach -> close distance")
	var moved: Dictionary = assert_event(events, "moved", "the free move executed")
	assert_eq(moved.get("to", []), [3, 0], "greedy steps straight toward the target")
	assert_true(bool(moved.get("free", false)), "1–3 spaces ride the free slot (R3)")
	assert_no_event(events, "action_declared", "no attack from out of reach")
	# Same tick again: cannot move twice — the mob has nothing left to do.
	var again: Dictionary = first_event(ai_decide(sim, "roach"), "ai_decision")
	assert_eq(String(again.get("choice", "")), "wait", "no second move in one tick")
	assert_eq(String(again.get("reason", "")), "no_reachable_action", "wait reason recorded")
	advance(sim, 1)
	# Tick 1: step adjacent AND bite in the same tick (free move + scheduled action, R3).
	var events2: Array[Dictionary] = ai_decide(sim, "roach")
	var decision2: Dictionary = first_event(events2, "ai_decision")
	assert_eq(String(decision2.get("choice", "")), "attack", "in reach after the step")
	assert_true(bool(decision2.get("moves", false)), "the closing step is part of the decision")
	assert_event(events2, "action_declared", "bite declared after moving")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "damage_applied", "move-then-attack landed")


func test_team_rules_and_wait_mutates_nothing() -> void:
	# No opponents at all: wait, and the state hash is untouched.
	var sim: CombatSim = make_sim()
	add_enemy(sim, "roach", "roach_dog")
	var before: String = sim.state_hash()
	var decision: Dictionary = first_event(ai_decide(sim, "roach"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "wait", "nobody to fight")
	assert_eq(String(decision.get("reason", "")), "no_targets", "wait reason recorded")
	assert_eq(sim.state_hash(), before, "a wait decision mutates nothing")
	# Same team is never a target.
	var sim2: CombatSim = make_sim()
	add_enemy(sim2, "roach_a", "roach_dog")
	add_enemy(sim2, "roach_b", "roach_dog", {"position": [1, 0]})
	assert_eq(String(first_event(ai_decide(sim2, "roach_a"), "ai_decision").get("choice", "")), "wait",
		"same-team combatants are not targets")
	# A TEAMLESS enemy sees nothing (teams are explicit, R11 #15)...
	var sim3: CombatSim = make_sim()
	add_human(sim3, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim3, "roach", "roach_dog", {"team": ""})
	assert_eq(String(first_event(ai_decide(sim3, "roach"), "ai_decision").get("choice", "")), "wait",
		"an enemy with an empty team waits")
	# ...but a teamless TARGET is hostile to a teamed enemy.
	var sim4: CombatSim = make_sim()
	add_human(sim4, "h", {"position": [1, 0]})
	add_enemy(sim4, "roach", "roach_dog")
	assert_eq(String(first_event(ai_decide(sim4, "roach"), "ai_decision").get("choice", "")), "attack",
		"a teamless combatant is a valid target")


func test_grappled_mob_bites_its_grappler() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h_grappler", {"team": "party", "position": [1, 0], "traits": {"physique": 9, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "h_weak", {"team": "party", "position": [0, 1], "body_parts": weak_parts()})
	add_enemy(sim, "roach", "roach_dog")
	declare(sim, "h_grappler", {"kind": "grapple", "target": "roach"})
	var grabbed: Array[Dictionary] = advance(sim, 1)
	assert_event(grabbed, "grapple_started", "the hold landed")
	var decision: Dictionary = first_event(ai_decide(sim, "roach"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "grappled mob still fights")
	assert_eq(String(decision.get("target", "")), "h_grappler",
		"the grapple locks targeting onto the grappler (weaker target ignored)")
	assert_false(bool(decision.get("moves", true)), "no repositioning while held (R9)")


# ---------------------------------------------------------------- elite policy

func test_elite_summons_brood_once() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [2, 0]})
	add_enemy(sim, "elite", "little_brother_roach")
	var events: Array[Dictionary] = ai_decide(sim, "elite")
	var decision: Dictionary = assert_event(events, "ai_decision", "elite decided")
	assert_eq(String(decision.get("choice", "")), "summon", "the brood-tender wakes its eggs first")
	assert_eq(String(decision.get("ability", "")), "awaken_eggs", "seeded summon ability")
	var summoned: Dictionary = assert_event(events, "enemies_summoned", "summon event emitted")
	assert_eq(int(summoned.get("count", 0)), 4, "seeded count: 4 roach-dogs")
	assert_eq(events_of(events, "combatant_added").size(), 4, "each brood member added")
	assert_eq(summoned.get("ids", []), ["elite_brood_1", "elite_brood_2", "elite_brood_3", "elite_brood_4"],
		"deterministic brood ids")
	var seen_positions: Dictionary = {}
	for brood_id: String in ["elite_brood_1", "elite_brood_2", "elite_brood_3", "elite_brood_4"]:
		var brood: CombatantState = sim.combatants.get(brood_id)
		assert_true(brood != null, "brood %s exists" % brood_id)
		assert_eq(brood.team, "enemies", "brood inherits the summoner's team")
		assert_eq(brood.next_action_tick, 1, "summons act from the NEXT tick (R11 #16)")
		assert_false(seen_positions.has(brood.position), "brood members never stack on one hex")
		seen_positions[brood.position] = true
		assert_true(CombatantState.hex_distance(brood.position, Vector2i(0, 0)) <= 2, "brood spawns close to the summoner")
	assert_rejected(ai_decide(sim, "elite"), "not_ready", "the summon consumed the elite's action")
	assert_eq(sim.ai_ready_ids(), [], "nobody ready until the next tick")
	advance(sim, 1)
	assert_eq(sim.ai_ready_ids().size(), 5, "elite + 4 brood ready next tick")
	var second: Dictionary = first_event(ai_decide(sim, "elite"), "ai_decision")
	assert_eq(String(second.get("choice", "")), "attack", "summon happens ONCE per combat")
	assert_eq(String(second.get("ability", "")), "whip", "elite falls through to its strike")


## R23 (decision #29) REWRITE — the elite's old lowest-HP-first RULE is now its
## authored low_hp_bias PERSONALITY (data/enemies.json): a wounded target
## weighs heavier, it does not auto-win. Kept INTENT: the "picks off the weak"
## persona is real and pinned exactly; the decision is the weighted draw.
func test_elite_low_hp_bias_prefers_the_wounded() -> void:
	var sim: CombatSim = make_sim()
	# Equidistant so proximity cancels; hw wounded to half its total HP.
	add_human(sim, "ha", {"team": "party", "position": [1, 0]})
	add_human(sim, "hw", {"team": "party", "position": [0, 1]})
	add_enemy(sim, "elite", "little_brother_roach", {"abilities": [
		{"key": "whip", "name": "Whip", "moment_cost": 1, "range": 7,
			"damage": [{"type": "bleeding", "amount": 2}]},
	]})
	var elite: CombatantState = sim.combatants["elite"]
	assert_eq(elite.personality_low_hp_bias(), 3.0, "seeded elite personality carries low_hp_bias 3.0")
	assert_false(elite.personality_mock_sensitive(), "Mind 1 brood-tender is authored mock-insensitive")
	# Wound hw to exactly half of its 17 total HP (2+5+2+2+3+3): 17 -> 8.5 is not
	# integral, so halve the torso instead and compute the exact expected factor.
	var hw: CombatantState = sim.combatants["hw"]
	var torso: Dictionary = hw.parts["torso"]
	torso["hp"] = 1  # torso 5 -> 1: total 17 -> 13
	var candidates: Array[CombatantState] = [sim.combatants["ha"] as CombatantState, hw]
	var rows: Array[Dictionary] = sim.ai.targeting_weights(elite, candidates, elite.position)
	assert_eq(float((rows[0] as Dictionary)["weight"]), 1.0, "fresh equidistant target weighs 1")
	var expected_hw: float = 1.0 + 3.0 * (1.0 - 13.0 / 17.0)
	assert_eq(float((rows[1] as Dictionary)["weight"]), expected_hw,
		"wounded target's weight = 1 + low_hp_bias * missing-HP fraction, exactly")
	assert_true(expected_hw > 1.5, "the persona is a real preference, not a nudge")
	var expected: String = _predicted_pick(sim, "elite")
	var decision: Dictionary = first_event(ai_decide(sim, "elite"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "whip reaches both")
	assert_eq(String(decision.get("target", "")), expected,
		"the elite's pick IS the biased weighted draw at the live ai_rng state")


func test_elite_punishes_exposure_with_head_shots() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0]})
	add_enemy(sim, "elite", "little_brother_roach", {"abilities": [
		{"key": "whip", "name": "Whip", "moment_cost": 1, "range": 7,
			"damage": [{"type": "bleeding", "amount": 2}]},
	]})
	sim.apply_command({"type": "set_status", "target": "h", "status": "prone", "value": true})
	var events: Array[Dictionary] = ai_decide(sim, "elite")
	assert_eq(String(first_event(events, "ai_decision").get("choice", "")), "attack", "whip declared")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var damage: Dictionary = assert_event(resolved, "damage_applied", "whip landed")
	assert_eq(String(damage.get("part", "")), "head", "an Exposed target gets whipped at the head")


func test_elite_heals_when_a_lethal_part_drops_below_half() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "elite", "little_brother_roach", {"abilities": [
		{"key": "seal_wound", "name": "Seal Wound", "moment_cost": 2, "heal": {"amount": 1, "target": "self"}},
		{"key": "whip", "name": "Whip", "moment_cost": 1, "range": 7,
			"damage": [{"type": "bleeding", "amount": 2}]},
	]})
	# Healthy: no heal — the strike wins.
	var healthy: Dictionary = first_event(ai_decide(sim, "elite"), "ai_decision")
	assert_eq(String(healthy.get("choice", "")), "attack", "no self-care while healthy")
	advance(sim, 1)
	# Torso 15 -> 7 (below half): the elite seals the wound. R14: the elite's
	# Robustness = floor(physique 4 / 2) = 2, so to still net 8 the raw force is
	# bumped 8 → 9: Force = 9 + floor(3/2) = 10, net = 10 − 2 = 8, torso 15 → 7.
	declare(sim, "h", attack_action("bleeding", 9, "elite", "torso"))
	advance(sim, 1)
	var events: Array[Dictionary] = ai_decide(sim, "elite")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "heal", "wounded below half -> heal (R11 #16)")
	assert_eq(String(decision.get("ability", "")), "seal_wound", "seeded heal ability")
	var declared: Dictionary = assert_event(events, "action_declared", "heal is a scheduled action")
	assert_eq(int(declared.get("cost", 0)), 2, "seeded 2-Moment cost")
	assert_true(bool(declared.get("windup", false)), "a 2-Moment heal is an interruptible windup (R2)")
	var hp_before: int = int((sim.combatants["elite"] as CombatantState).parts["torso"]["hp"])
	var resolved: Array[Dictionary] = advance(sim, 3)
	var healed: Dictionary = assert_event(resolved, "healed", "the heal resolved on schedule")
	assert_eq(String(healed.get("part", "")), "torso", "heals the most-damaged part")
	assert_eq(int(healed.get("amount", 0)), 1, "seeded amount")
	assert_eq(int((sim.combatants["elite"] as CombatantState).parts["torso"]["hp"]), hp_before + 1, "HP actually restored")


# ---------------------------------------------------------------- determinism

## Memoryless deterministic driver: one ai_decide per ready enemy, then one
## tick — exactly what GameController.run_enemy_turn + a clock driver do.
func _drive(sim: CombatSim, ticks: int) -> Array[String]:
	var fingerprints: Array[String] = []
	for t: int in range(ticks):
		for id: String in sim.ai_ready_ids():
			var decision: Dictionary = first_event(ai_decide(sim, id), "ai_decision")
			fingerprints.append("%s|%s|%s|%s" % [
				id, String(decision.get("choice", "")),
				String(decision.get("ability", "")), String(decision.get("target", "")),
			])
		advance(sim, 1)
	return fingerprints


func _skirmish(sim: CombatSim) -> void:
	add_human(sim, "h_close", {"team": "party", "position": [2, 0]})
	add_human(sim, "h_far", {"team": "party", "position": [6, 0]})
	add_enemy(sim, "elite", "little_brother_roach")
	add_enemy(sim, "roach", "roach_dog", {"position": [4, 0]})


func test_same_seed_same_decisions_same_hash() -> void:
	var sim1: CombatSim = make_sim(9090)
	var sim2: CombatSim = make_sim(9090)
	_skirmish(sim1)
	_skirmish(sim2)
	var trail1: Array[String] = _drive(sim1, 25)
	var trail2: Array[String] = _drive(sim2, 25)
	assert_true(trail1.size() >= 25, "the skirmish produced a real decision trail (%d)" % trail1.size())
	assert_eq(trail2, trail1, "identical state -> identical decision sequence")
	assert_eq(sim2.state_hash(), sim1.state_hash(), "identical (seed, command log) -> identical hash with AI in play")


func test_serialization_roundtrip_mid_skirmish() -> void:
	# Uninterrupted reference run.
	var sim_full: CombatSim = make_sim(9090)
	_skirmish(sim_full)
	_drive(sim_full, 16)
	var hash_full: String = sim_full.state_hash()
	# Head run, snapshotted mid-skirmish (after the summon, mid decisions).
	var sim_head: CombatSim = make_sim(9090)
	_skirmish(sim_head)
	_drive(sim_head, 8)
	var snapshot: Dictionary = sim_head.to_dict()
	assert_true(int((snapshot.get("ai", {}) as Dictionary).get("summons", {}).get("elite", 0)) >= 4,
		"snapshot carries the elite's summon memory")
	var sim_restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(sim_restored.state_hash(), sim_head.state_hash(), "restore is a faithful roundtrip (incl. AI state)")
	_drive(sim_head, 8)
	_drive(sim_restored, 8)
	assert_eq(sim_head.state_hash(), hash_full, "continued head run matches the uninterrupted run")
	assert_eq(sim_restored.state_hash(), hash_full, "snapshot -> restore -> drive tail => identical final hash")
	assert_eq(sim_restored.combatants.size(), sim_head.combatants.size(), "no double-summon after restore")


func test_pre_i16_save_resumes_with_fresh_salted_ai() -> void:
	var sim: CombatSim = make_sim(777)
	_skirmish(sim)
	_drive(sim, 3)
	var envelope: Dictionary = sim.to_dict()
	envelope.erase("ai")  # a save written before I-16
	var restored: CombatSim = CombatSim.from_dict(envelope)
	var fresh: CombatSim = make_sim(777)
	assert_eq(restored.ai.ai_rng.state, fresh.ai.ai_rng.state,
		"missing ai block -> fresh salted stream (not state 0)")
	assert_true(restored.ai.summons.is_empty(), "no phantom summon memory")
	assert_true(restored.ai.boss_phase.is_empty(), "no phantom phase memory")


func test_controller_run_enemy_turn() -> void:
	var script: GDScript = load("res://controller/game_controller.gd")
	var game: Node = script.new()
	var decisions: Array[Dictionary] = []
	game.ai_decision.connect(func(e: Dictionary) -> void: decisions.append(e))
	game.start_combat(1234, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "h", "name": "h", "race": "human", "team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "roach", "name": "roach", "enemy": "roach_dog", "team": "enemies", "position": [0, 0],
	}})
	var events: Array[Dictionary] = game.run_enemy_turn()
	assert_eq(decisions.size(), 1, "one decision signal per ready enemy")
	assert_event(events, "ai_decision", "events returned to the caller")
	assert_eq(game.command_log.back().get("type", ""), "ai_decide", "ai_decide entered the command log")
	assert_true(game.run_enemy_turn().is_empty(), "no ready enemies -> second call is a no-op")
	game.free()


func test_dodge_salt_diverges_from_the_action_stream() -> void:
	# The salt's PURPOSE is statistical independence from the action RNG, which
	# CombatSim seeds at the bare sim_seed (combat_sim.gd: rng.seed = sim_seed).
	# If AI_RNG_SALT were 0 the two streams would be identical. This pins the
	# salt VALUE, not just its isolation — gate-2 mutation M3 (salt -> 0).
	var EnemyAI: GDScript = load("res://simulation/enemy_ai.gd")
	var ai: RefCounted = EnemyAI.new()
	ai.setup({}, null, 4242)
	var action_rng := RandomNumberGenerator.new()
	action_rng.seed = 4242
	var ai_draws: Array[int] = []
	var action_draws: Array[int] = []
	for i: int in range(12):
		ai_draws.append(ai.ai_rng.randi_range(1, 6))
		action_draws.append(action_rng.randi_range(1, 6))
	assert_true(ai_draws != action_draws,
		"salted AI stream must diverge from the same-seed action stream (AI_RNG_SALT != 0)")
