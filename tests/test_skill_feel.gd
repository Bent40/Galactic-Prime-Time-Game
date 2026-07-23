extends SimTestBase
## Skill-feel quick wins (owner complaint: "the skills don't feel like they do
## anything different from each other") — the SIM side of the three fixes:
##   1. Feint fallout is ATTRIBUTED: the collapse emits feint_fallout carrying
##      feinter, victim and what failed (feint_by state, serialized).
##   2. Slam knockdown MATTERS vs the boss: overhead_slam honestly knocks the
##      Incine-Dile prone; a prone boss cannot dodge (R22), cannot cone-sweep
##      (skill-feel gate), crawls at allowance 1, and standing back up consumes
##      its whole Moment (the ai "stand" choice -> the resolver's stand action).
##   3. (Part-pick is a HUD flow fix — no sim defaulting change; covered by
##      ui/hud/tools/smoke_ui.gd probes, not here.)
## Deterministic: fixed seeds, no wall-clock; rng notes per test.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold (same helper as
## tests/test_incinedile.gd) — knockdown tests stay pin-exact without consuming
## the AI dodge stream.
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


# ------------------------------------------------------------- 1. feint fallout attribution

func test_feint_fallout_attributes_feinter_victim_and_key() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"position": [0, 0]})
	add_human(sim, "mark", {"position": [1, 0]})
	declare(sim, "trick", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	advance(sim)
	var mark: CombatantState = sim.combatants["mark"]
	assert_true(mark.feint_forced, "the mark is feint-forced")
	assert_eq(mark.feint_by, "trick", "the feinter is remembered for attribution")
	# The mark's next resolved action collapses — the payoff event is attributed.
	declare(sim, "mark", {
		"kind": "skill", "key": "strong_strike", "level": 1, "attack_range": 1,
		"targets": [{"id": "trick", "part": "torso"}],
	})
	advance(sim, 2)
	var collapse: Array[Dictionary] = advance(sim)
	var fallout: Dictionary = assert_event(collapse, "feint_fallout", "the payoff emits its own event")
	assert_eq(String(fallout.get("actor", "")), "trick", "the FEINTER gets the credit")
	assert_eq(String(fallout.get("victim", "")), "mark", "the victim is named")
	assert_eq(String(fallout.get("kind", "")), "skill", "what failed: the action kind")
	assert_eq(String(fallout.get("key", "")), "strong_strike", "what failed: the action key")
	assert_event(collapse, "action_invalidated", "the existing collapse event still fires")
	assert_event(collapse, "forced_action_triggered", "the Forced Tool still rides the collapse")
	assert_false(mark.feint_forced, "the flag clears at the collapse")
	assert_eq(mark.feint_by, "", "the attribution clears with the flag")


func test_feint_attribution_serializes() -> void:
	var sim: CombatSim = make_sim(4242)
	add_human(sim, "trick", {"position": [0, 0]})
	add_human(sim, "mark", {"position": [1, 0]})
	declare(sim, "trick", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	advance(sim)
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "state hash survives the round-trip")
	var r_mark: CombatantState = restored.combatants["mark"]
	assert_true(r_mark.feint_forced, "feint_forced preserved")
	assert_eq(r_mark.feint_by, "trick", "feint_by preserved")
	# The restored sim still pays the fallout off with full attribution.
	restored.apply_command({"type": "declare_action", "actor": "mark", "action":
		attack_action("crushed", 1, "trick", "torso")})
	var collapse: Array[Dictionary] = restored.apply_command({"type": "advance_tick"})
	var fallout: Dictionary = assert_event(collapse, "feint_fallout", "fallout fires after resume")
	assert_eq(String(fallout.get("actor", "")), "trick", "attribution survives the save")


# ------------------------------------------------------------- 2. slam knockdown vs the boss

func test_overhead_slam_knocks_the_boss_prone() -> void:
	# Dodge stripped (same driver-side spec choice as tests/test_incinedile.gd)
	# so the landed hit is deterministic. Slam Lv1: Force 3 + floor(phys 5/2) = 5
	# vs boss Robustness floor(phys 6/2) = 3 — lands, no special boss immunity.
	var sim: CombatSim = make_sim()
	add_human(sim, "smasher", {"team": "party", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	declare(sim, "smasher", {
		"kind": "skill", "key": "overhead_slam", "level": 1, "attack_range": 1,
		"targets": [{"id": "boss", "part": "left_hand"}],
	})
	advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	var knocked: Dictionary = assert_event(ev, "knocked_prone", "the slam grounds the boss")
	assert_eq(String(knocked.get("combatant", "")), "boss", "the boss is the one flattened")
	assert_eq(String(knocked.get("source", "")), "smasher", "knockdown is attributed to the slammer")
	assert_eq(String(knocked.get("skill", "")), "overhead_slam", "the skill is named")
	var boss: CombatantState = sim.combatants["boss"]
	assert_true(bool(boss.statuses.get("prone", false)), "the boss is Prone")


func test_prone_boss_cannot_dodge_and_consumes_no_rng() -> void:
	# Dodge threshold KEPT (7): a standing boss would at least roll for an aimed
	# round (Reflexes 4 + 1d4 vs 7). Prone makes the dodge ineligible (R22) —
	# no attack_dodged, the hit lands, and the salted ai_rng is never touched.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_enemy(sim, "boss", "incinedile", {"position": [1, 1]})
	sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	var rng_before: int = sim.ai.ai_rng.state
	declare(sim, "h", attack_action("crushed", 5, "boss", "left_hand"))
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "attack_dodged", "a prone boss cannot dodge (R22 ineligibility)")
	var damage: Dictionary = assert_event(ev, "damage_applied", "the aimed round lands")
	assert_eq(int(damage.get("amount", -1)), 3, "Force 5+1=6 − Robustness 3 = 3, undodged")
	assert_eq(sim.ai.ai_rng.state, rng_before, "the ineligible dodge consumed no ai_rng")


func test_prone_boss_cone_locked_and_standing_costs_the_moment() -> void:
	# Two contestants inside cone reach — a STANDING boss's priority-1 pick is
	# the flamethrower cone. Prone locks the cone AND every other ability: the
	# boss's whole decision is "stand", a real cost-1 action for the Moment.
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [1, 0]})
	add_human(sim, "b", {"team": "party", "position": [0, 1]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "boss decided")
	assert_eq(String(decision.get("choice", "")), "stand", "a grounded croc rights itself first — no cone")
	var declared: Dictionary = assert_event(events, "action_declared", "standing is a REAL declared action")
	assert_eq(String(declared.get("kind", "")), "stand", "the stand action kind")
	assert_eq(int(declared.get("cost", 0)), 1, "standing costs the boss its Moment")
	# The Moment is spent: no second decision this tick.
	assert_rejected(ai_decide(sim, "boss"), "not_ready", "the stand consumed the boss's action")
	var resolved: Array[Dictionary] = advance(sim)
	var stood: Dictionary = assert_event(resolved, "stood_up", "the stand-up event is attributed")
	assert_eq(String(stood.get("combatant", "")), "boss", "the boss stood up")
	var boss: CombatantState = sim.combatants["boss"]
	assert_false(bool(boss.statuses.get("prone", false)), "prone clears when the stand resolves")
	# Back on its feet the NEXT Moment: the cone sweep is priority 1 again.
	var next_events: Array[Dictionary] = ai_decide(sim, "boss")
	var next_decision: Dictionary = assert_event(next_events, "ai_decision", "boss decided again")
	assert_eq(String(next_decision.get("choice", "")), "attack", "the boss fights again")
	assert_eq(String(next_decision.get("ability", "")), "flamethrower", "the cone is available once standing")


func test_prone_ai_crawls_at_allowance_one() -> void:
	# The _step_toward allowance-1 crawl, verified through a mob decision (the
	# boss now stands before it would ever crawl): a prone roach closes ONE hex
	# toward a distant target where a standing one closes three.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [6, 0]})
	add_enemy(sim, "roach", "roach_dog")
	sim.apply_command({"type": "set_status", "target": "roach", "status": "prone", "value": true})
	var ev_prone: Array[Dictionary] = ai_decide(sim, "roach")
	var decision: Dictionary = assert_event(ev_prone, "ai_decision", "prone mob decided")
	assert_eq(String(decision.get("choice", "")), "move", "out of reach -> close distance")
	var moved: Dictionary = assert_event(ev_prone, "moved", "the crawl is a real move")
	assert_eq(moved.get("to", []), [1, 0], "prone allowance 1: one hex, not three")
	# Control: the same layout standing covers the full free-move allowance.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"team": "party", "position": [6, 0]})
	add_enemy(sim2, "roach", "roach_dog")
	var ev_stand: Array[Dictionary] = ai_decide(sim2, "roach")
	var moved2: Dictionary = assert_event(ev_stand, "moved", "standing mob moves too")
	assert_eq(moved2.get("to", []), [3, 0], "standing allowance 3: three hexes")


func test_stand_state_serializes_mid_beat() -> void:
	# Save between the slam landing and the stand resolving: the restored sim
	# still owes the boss its stand-up (prone true) and pays it off identically.
	var sim: CombatSim = make_sim(777)
	add_human(sim, "a", {"team": "party", "position": [1, 0]})
	add_human(sim, "b", {"team": "party", "position": [0, 1]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	ai_decide(sim, "boss")  # declares the stand
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "hash survives mid-beat save")
	var resolved: Array[Dictionary] = restored.apply_command({"type": "advance_tick"})
	assert_event(resolved, "stood_up", "the restored sim resolves the pending stand")
	var boss: CombatantState = restored.combatants["boss"]
	assert_false(bool(boss.statuses.get("prone", false)), "prone cleared after resume")
