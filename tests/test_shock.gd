extends SimTestBase
## S2.2 / R13 Shock — the momentary-event model off a per-combat high-water mark
## (no pool, no in-combat decay, full reset per combat). Covers:
##   - escalation: max(current+1, source), a strong source not weakened
##   - per-organ elevation: re-abusing an already-shocked wound bumps the source
##   - tier effects fired as each tier is newly REACHED:
##       T1 Shout · T2 Stutter (next action fails) · T3 Faint · T4 Incapacitated
##   - serialization round-trip of shocked_parts + shock_stutter_pending.
## Deterministic (fixed seeds; direct engine calls use an explicit tick).
## NOTE: the Burn T1 -> Shock T1 cauterize path stays covered by
## test_kan2_acceptance.test_12_burn_t1_cauterizes_with_shock_cost (unchanged).

const SEED: int = 90210

## A weapon item so the T3/T4 item-drop can be observed.
func _knife() -> Dictionary:
	return {
		"key": "knife", "item_type": "weapon", "damage_type": "bleeding",
		"damage_amount": 1, "base_moment_cost": 1, "attack_range": 1,
	}


# ---------------------------------------------------------------- escalation

func test_escalation_high_water_mark() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a")
	add_human(sim, "b")
	var cond: ConditionEngine = sim.cond

	# A fresh source lands at its own tier; a second independent T1 source escalates
	# one above current: max(1+1, 1) = 2.
	var a: CombatantState = sim.combatants["a"]
	cond.apply_shock(a, 1, 0)
	assert_eq(a.shock, 1, "first T1 source -> T1")
	cond.apply_shock(a, 1, 0)
	assert_eq(a.shock, 2, "a second independent T1 source escalates to T2 (max(1+1,1))")

	# A strong T3 source onto a T1 mark is NOT weakened to T2: max(1+1, 3) = 3.
	var b: CombatantState = sim.combatants["b"]
	cond.apply_shock(b, 1, 0)
	assert_eq(b.shock, 1, "T1 established")
	cond.apply_shock(b, 3, 0)
	assert_eq(b.shock, 3, "a strong T3 source lands at T3, not one-above-current")


# ---------------------------------------------------------------- per-organ

func test_per_organ_reabused_wound_elevates() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "same")
	add_human(sim, "diff")
	add_human(sim, "lit")
	var cond: ConditionEngine = sim.cond

	# First torso hit records the wound but does NOT self-elevate (nothing prior).
	var same: CombatantState = sim.combatants["same"]
	cond.apply_shock(same, 1, 0, "torso")
	assert_eq(same.shock, 1, "first torso hit -> T1, no self-elevation")
	assert_true(same.shocked_parts.has("torso"), "torso recorded as a shocked wound")

	# Re-abuse the SAME wound with a T2 source: source bumped 2 -> 3 BEFORE escalation,
	# so max(1+1, 3) = 3. (A T1-source re-abuse would still read T2 because escalation
	# already adds +1 — the elevation is only OBSERVABLE when the bumped source beats
	# current+1, hence a T2 source here.)
	cond.apply_shock(same, 2, 0, "torso")
	assert_eq(same.shock, 3, "re-abusing the same wound elevates the source (-> T3)")

	# Same setup but the second T2 source hits a DIFFERENT, un-abused part: no bump,
	# so max(1+1, 2) = 2.
	var diff: CombatantState = sim.combatants["diff"]
	cond.apply_shock(diff, 1, 0, "torso")
	cond.apply_shock(diff, 2, 0, "left_arm")
	assert_eq(diff.shock, 2, "a fresh, un-abused part does not elevate the source")

	# The ruling's named example: torso T1 twice -> T2 (the source bump is masked by
	# escalation's +1 here, but the wound is still recorded and the mark reads T2).
	var lit: CombatantState = sim.combatants["lit"]
	cond.apply_shock(lit, 1, 0, "torso")
	cond.apply_shock(lit, 1, 0, "torso")
	assert_eq(lit.shock, 2, "same wound T1 twice -> T2")


# ---------------------------------------------------------------- T1 Shout

func test_t1_reaching_tier_one_shouts() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a")
	var a: CombatantState = sim.combatants["a"]
	var ev: Array[Dictionary] = sim.cond.apply_shock(a, 1, 0)
	var shout: Dictionary = assert_event(ev, "shock_shout", "reaching T1 emits Shout")
	assert_eq(String(shout.get("combatant", "")), "a", "Shout carries the combatant id")
	# Staying at T1 (no crossing) does not re-emit Shout.
	var ev2: Array[Dictionary] = sim.cond.apply_shock(a, 1, 0)
	assert_eq(a.shock, 2, "escalated to T2")
	assert_no_event(ev2, "shock_shout", "Shout fires only when T1 is newly crossed")


# ---------------------------------------------------------------- T2 Stutter

func test_t2_stutter_fails_next_action_then_clears() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "s", {"position": [0, 0]})
	add_human(sim, "d", {"position": [1, 0]})
	var s: CombatantState = sim.combatants["s"]

	# Reaching T2 sets the stutter flag (and emits the event).
	var applied: Array[Dictionary] = sim.apply_command({
		"type": "apply_condition", "target": "s", "part": "torso",
		"condition": "shock", "tier": 2,
	})
	assert_event(applied, "shock_stutter", "reaching T2 emits Stutter")
	assert_true(s.shock_stutter_pending, "T2 arms the stutter flag")

	# The next resolved scheduled action is INVALIDATED (fails) — no Forced Action.
	declare(sim, "s", attack_action("crushed", 1, "d", "torso"))
	var stuttered: Array[Dictionary] = advance(sim)
	var inval: Dictionary = assert_event(stuttered, "action_invalidated", "the stuttered action fails")
	assert_eq(String(inval.get("reason", "")), "shock_stutter", "reason is shock_stutter")
	assert_no_event(stuttered, "forced_action_triggered", "a stutter rolls no Forced Action")
	assert_no_event(stuttered, "damage_applied", "the failed action deals no damage")
	assert_false(s.shock_stutter_pending, "the flag clears after firing")

	# A FOLLOWING action resolves normally (only the one action was consumed).
	declare(sim, "s", attack_action("crushed", 1, "d", "torso"))
	var followup: Array[Dictionary] = advance(sim)
	assert_no_event(followup, "action_invalidated", "the following action is not invalidated")
	assert_event(followup, "damage_applied", "the following action lands normally")


# ---------------------------------------------------------------- T3 Faint

func test_t3_faint_helpless_one_clock_and_drops_items() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "f", {"position": [0, 0], "items": [_knife()]})
	var f: CombatantState = sim.combatants["f"]

	var ev: Array[Dictionary] = sim.cond.apply_shock(f, 3, 0)
	assert_eq(f.shock, 3, "T3 reached")
	assert_true(f.is_helpless(0), "T3 Faint = Helpless")
	assert_eq(f.helpless_until_tick, Clock.TICKS_PER_CLOCK, "Helpless for ~1 Clock (tick 0 + 1 Clock)")
	assert_false(f.is_helpless(Clock.TICKS_PER_CLOCK + 5), "T3 Helpless is only ~1 Clock, not rest-of-combat")
	var drop: Dictionary = assert_event(ev, "item_dropped", "T3 drops held items")
	assert_eq(String(drop.get("item", "")), "knife", "the knife is dropped")
	assert_true(bool(f.items["knife"].get("dropped", false)), "the item is flagged dropped")
	assert_no_event(ev, "shock_incapacitated", "T3 is a Faint, not the rest-of-combat Incapacitation")


# ---------------------------------------------------------------- T4 Incapacitated

func test_t4_incapacitated_helpless_and_exposed_rest_of_combat() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "x", {"position": [0, 0], "items": [_knife()]})
	var x: CombatantState = sim.combatants["x"]

	# A direct jump 0 -> T4: rest-of-combat Helpless AND Exposed (not the 1-Clock T3).
	var ev: Array[Dictionary] = sim.cond.apply_shock(x, 4, 0)
	assert_eq(x.shock, 4, "T4 reached")
	assert_event(ev, "shock_incapacitated", "T4 emits Incapacitated")
	assert_event(ev, "item_dropped", "items still drop at T4")

	var far: int = Clock.TICKS_PER_CLOCK * 5000  # far beyond any real fight, below the sentinel
	assert_true(x.is_helpless(far), "Helpless for the rest of combat")
	assert_true(x.exposed_until_tick > far, "Exposed for the rest of combat")
	# Distinctly longer than a T3 Faint's single Clock.
	assert_true(x.helpless_until_tick > Clock.TICKS_PER_CLOCK, "T4 Helpless outlasts a T3 Faint")


# ---------------------------------------------------------------- serialization

func test_serialization_roundtrip_preserves_shock_state() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "t")
	var t: CombatantState = sim.combatants["t"]
	# Reach T2 on the torso: sets shock=2, records "torso", arms the stutter flag.
	sim.cond.apply_shock(t, 2, 0, "torso")
	assert_eq(t.shock, 2, "T2 established")
	assert_true(t.shocked_parts.has("torso"), "torso recorded")
	assert_true(t.shock_stutter_pending, "stutter armed")

	var hash_before: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), hash_before, "to_dict -> from_dict preserves the state hash")
	var rt: CombatantState = restored.combatants["t"]
	assert_eq(rt.shock, 2, "shock survived the round-trip")
	assert_true(rt.shocked_parts.has("torso"), "shocked_parts survived the round-trip")
	assert_true(rt.shock_stutter_pending, "shock_stutter_pending survived the round-trip")
