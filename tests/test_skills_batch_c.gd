extends SimTestBase
## Content pass batch C — "Medics & Minds" (docs/design/skills-r19-ladders-FINAL.md
## #3/#6/#19/#29/#37 + the G6 passover field_triage): seal_the_wound +
## field_triage (the NEW ally_treatment archetype — delay ONLY, FINAL default
## #8's honesty pin, incl. the R5 bleed-out stabilization and the
## bandage_charge STACK economy), read_the_pattern + aura_reading (the NEW
## intel_reveal archetype — declared read vs the passive aura, both gated by
## Stealth.sees so the R30 facing cone is a real counter to intel),
## mind_burst (the psychic_strike strike VARIANT — Shock through the R13
## stated-tier + escalation model, bypass_head_gate), and acrobatic_save (the
## NEW forced_roll_save archetype — the G1 movement-forfeit arming, R25: NO
## prime, NO stance; extra dice from the action rng stream, lowest-severity
## choose rule, tie keeps the original, arming consumed per roll). Pins: the
## no-HP/no-cure structure, treatments compose with (are ignored by) the
## batch-B retarget_guard, R30 declare-facing, pattern-read expiry at the
## Clock reset, the contestant-facing view gating (broadcast omniscience
## unchanged), twin-RNG save consumption, serialization round-trips +
## only-when-set pins, determinism. All magnitudes PLACEHOLDER (R14).


func add_party(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = {"team": "party", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}
	spec.merge(overrides, true)
	add_human(sim, id, spec)


## A non-dodging Elite (no dodge_threshold: no dodge stream; Mind 0: it sees
## and reads nothing itself). `extra` merges over the spec.
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


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func apply_cond(sim: CombatSim, target: String, part: String, condition: String, tier: int) -> Array[Dictionary]:
	return sim.apply_command({"type": "apply_condition", "target": target,
		"part": part, "condition": condition, "tier": tier})


func treat_declare(sim: CombatSim, actor: String, key: String, target: String, part: String, condition: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": key, "level": level,
		"targets": [{"id": target, "part": part}], "condition": condition})


func pattern_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "read_the_pattern", "level": level,
		"targets": [{"id": target, "part": "torso"}]})


func burst_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "mind_burst", "level": level,
		"targets": [{"id": target, "part": "head"}]})


func save_declare(sim: CombatSim, actor: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "acrobatic_save", "level": level})


# ============================================================= seal_the_wound

func test_seal_delays_never_cures() -> void:
	var sim: CombatSim = make_sim(5101)
	add_party(sim, "medic", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [4, 0])
	apply_cond(sim, "ally", "torso", "bleeding", 2)
	var ally: CombatantState = sim.combatants["ally"]
	var hp_before: int = int(ally.parts["torso"]["hp"])
	var declared: Array[Dictionary] = treat_declare(sim, "medic", "seal_the_wound", "ally", "torso", "bleeding")
	assert_event(declared, "action_declared", "seal declares on the adjacent ally")
	var ev: Array[Dictionary] = advance(sim)
	var applied: Dictionary = assert_event(ev, "treatment_applied", "the treatment lands")
	assert_eq(String(applied.get("target", "")), "ally", "on the ally")
	assert_eq(int(applied.get("clocks", 0)), 1, "L1 = 1 Clock of delay")
	assert_event(ev, "condition_delayed", "the delay is the whole effect")
	# Default #8, behaviorally: nothing was cured, nothing was healed.
	assert_eq(ally.condition_tier("torso", "bleeding"), 2, "the condition is HELD, not resolved")
	assert_no_event(ev, "condition_resolved", "never a cure")
	assert_no_event(ev, "healed", "never HP")
	assert_eq(int(ally.parts["torso"]["hp"]), hp_before, "HP untouched")
	# The delayed condition skips exactly the next reset's advancement.
	var reset_ev: Array[Dictionary] = advance(sim, 9)
	assert_event(reset_ev, "condition_delay_consumed", "the reset consumes the delay")
	assert_eq(ally.condition_tier("torso", "bleeding"), 2, "no advancement this Clock")


func test_seal_honesty_pin_no_hp_path_exists() -> void:
	# STRUCTURAL assert (default #8): the ally_treatment resolver contains no
	# resolve mode and no heal call — the delay-not-cure rule is not a code
	# path we chose not to take, it is a path that does not exist.
	var source: String = FileAccess.get_file_as_string("res://simulation/action_resolver.gd")
	var start: int = source.find("func _resolve_ally_treatment(")
	assert_true(start >= 0, "the ally_treatment resolver exists")
	var end: int = source.find("\nfunc ", start)
	var body: String = source.substr(start, (end - start) if end > start else -1)
	assert_true(body.find("cond.delay(") >= 0, "the resolver delays through ConditionEngine.delay")
	assert_eq(body.find("heal_part"), -1, "no heal call exists in the treatment resolver")
	assert_eq(body.find("cond.resolve("), -1, "no resolve call exists in the treatment resolver")
	assert_eq(body.find("cond.treat("), -1, "no treat-mode passthrough exists (delay is called directly)")
	# And the specs carry no mode switch to smuggle one in.
	for lv: int in range(1, 5):
		for key: String in ["seal_the_wound", "field_triage"]:
			var spec: Dictionary = SkillBook.mechanics(key, lv)
			assert_false(spec.has("mode"), "%s L%d spec has no mode field" % [key, lv])
			assert_false(spec.has("heal"), "%s L%d spec has no heal field" % [key, lv])


func test_seal_stabilizes_bleed_out() -> void:
	var sim: CombatSim = make_sim(5102)
	add_party(sim, "medic", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [4, 0])
	# Bleeding T3 on the torso: part death + lethal_if_vital -> bleed-out (R5).
	var down_ev: Array[Dictionary] = apply_cond(sim, "ally", "torso", "bleeding", 3)
	assert_event(down_ev, "bleed_out_started", "the ally is bleeding out")
	var ally: CombatantState = sim.combatants["ally"]
	assert_true(ally.is_helpless(sim.clock.tick), "bleeding out = helpless (R5)")
	treat_declare(sim, "medic", "seal_the_wound", "ally", "torso", "bleeding")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "treatment_applied", "the seal lands on the downed ally")
	assert_event(ev, "bleed_out_stabilized", "delaying the driving condition stabilizes (R5)")
	assert_true(ally.alive, "alive")
	assert_true(ally.bleed_out.is_empty(), "no longer bleeding out")
	# 0-HP-stabilized: the lethal state is HELD, never cured — no HP returns.
	assert_eq(int(ally.parts["torso"]["hp"]), 0, "0-HP-stabilized — no HP restored (default #8)")
	assert_eq(ally.condition_tier("torso", "bleeding"), 3, "the lethal condition is held, not cured")


func test_seal_declare_gates_and_delay_ladder() -> void:
	var sim: CombatSim = make_sim(5103)
	add_party(sim, "medic", [0, 0])
	add_party(sim, "ally", [1, 0])
	add_party(sim, "far_ally", [3, 0])
	add_elite(sim, "foe", [2, 1])
	assert_rejected(treat_declare(sim, "medic", "seal_the_wound", "ally", "torso", "bleeding"),
		"condition_not_active", "no wound = nothing to seal")
	apply_cond(sim, "ally", "torso", "chilled", 1)
	assert_rejected(treat_declare(sim, "medic", "seal_the_wound", "ally", "torso", "chilled"),
		"condition_not_treatable", "seal treats Bleeding OR Infection only (L1-4)")
	apply_cond(sim, "far_ally", "torso", "bleeding", 1)
	assert_rejected(treat_declare(sim, "medic", "seal_the_wound", "far_ally", "torso", "bleeding"),
		"out_of_range", "self or ADJACENT only at L1")
	apply_cond(sim, "foe", "torso", "bleeding", 1)
	assert_rejected(treat_declare(sim, "medic", "seal_the_wound", "foe", "torso", "bleeding"),
		"target_not_ally", "an enemy is not treated")
	# SELF-treatment is seal's privilege, and the L3 ladder banks 3 Clocks of
	# delay: the next three resets each consume one skip, the fourth advances.
	apply_cond(sim, "medic", "torso", "bleeding", 1)
	var declared: Array[Dictionary] = treat_declare(sim, "medic", "seal_the_wound", "medic", "torso", "bleeding", 3)
	assert_event(declared, "action_declared", "seal-self declares")
	var ev: Array[Dictionary] = advance(sim)
	var applied: Dictionary = assert_event(ev, "treatment_applied", "self-seal lands")
	assert_eq(int(applied.get("clocks", 0)), 3, "L3 = 3 Clocks of delay")
	var medic: CombatantState = sim.combatants["medic"]
	advance(sim, 9)   # reset 1
	assert_eq(medic.condition_tier("torso", "bleeding"), 1, "reset 1 skipped")
	advance(sim, 10)  # reset 2
	assert_eq(medic.condition_tier("torso", "bleeding"), 1, "reset 2 skipped")
	advance(sim, 10)  # reset 3
	assert_eq(medic.condition_tier("torso", "bleeding"), 1, "reset 3 skipped")
	advance(sim, 10)  # reset 4
	assert_eq(medic.condition_tier("torso", "bleeding"), 2, "the delay is spent — the clock resumes")


func test_treatment_faces_the_target_and_ignores_retarget_guard() -> void:
	var sim: CombatSim = make_sim(5104)
	add_party(sim, "guardian", [0, 1])
	add_party(sim, "ally", [1, 0])
	add_party(sim, "medic", [2, 0])
	add_elite(sim, "foe", [3, 0])
	# The guardian intercept-guards the ally (batch B).
	declare(sim, "guardian", {"kind": "skill", "key": "intercept", "level": 1,
		"targets": [{"id": "ally"}]})
	advance(sim)
	var guardian: CombatantState = sim.combatants["guardian"]
	assert_true(bool(guardian.armed_primes.get("intercept", false)), "guard armed (batch B substrate)")
	apply_cond(sim, "ally", "torso", "bleeding", 1)
	# R30 update table: the treatment DECLARE faces the target — automatic,
	# no treatment special-case. Medic at [2,0] faces the ally at [1,0] = W (3).
	var medic: CombatantState = sim.combatants["medic"]
	treat_declare(sim, "medic", "seal_the_wound", "ally", "torso", "bleeding")
	assert_eq(medic.facing, 3, "the targeted declare faced the ward (R30, automatic)")
	var ev: Array[Dictionary] = advance(sim)
	# Interception composition: a treatment is NOT an attack — it never enters
	# _strike_round, so the armed guard has nothing to retarget.
	assert_no_event(ev, "hit_intercepted", "retarget_guard ignores non-attack declares")
	var delayed: Dictionary = assert_event(ev, "condition_delayed", "the delay landed")
	assert_eq(String(delayed.get("combatant", "")), "ally", "on the guarded ALLY, not the guardian")


# =============================================================== field_triage

func test_triage_charge_economy() -> void:
	var sim: CombatSim = make_sim(5111)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 1}})
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [4, 0])
	apply_cond(sim, "ally", "torso", "bleeding", 1)
	apply_cond(sim, "ally", "left_arm", "chilled", 1)
	var medic: CombatantState = sim.combatants["medic"]
	# Triage is NOT self-treatment and NOT condition-restricted.
	apply_cond(sim, "medic", "torso", "bleeding", 1)
	assert_rejected(treat_declare(sim, "medic", "field_triage", "medic", "torso", "bleeding"),
		"cannot_target_self", "triage treats an ALLY, never self")
	var declared: Array[Dictionary] = treat_declare(sim, "medic", "field_triage", "ally", "left_arm", "chilled")
	assert_event(declared, "action_declared", "any active condition is treatable (chilled included)")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "treatment_applied", "the triage lands")
	var consumed: Dictionary = assert_event(ev, "charge_consumed", "the bandage_charge is spent")
	assert_eq(String(consumed.get("resource", "")), "bandage_charge", "the STACK resource by name")
	assert_eq(int(consumed.get("remaining", -1)), 0, "1 -> 0")
	assert_eq(int(medic.charges.get("bandage_charge", -1)), 0, "the generic counter decremented")
	# STACK reject at zero: the prime gates the NEXT declare.
	advance(sim)
	assert_rejected(treat_declare(sim, "medic", "field_triage", "ally", "torso", "bleeding"),
		"prime_unmet", "no bandage = no triage (the STACK prime)")


func test_triage_range_ladder_and_stale_premise_keeps_charge() -> void:
	var sim: CombatSim = make_sim(5112)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 2}})
	add_party(sim, "ally", [2, 0])
	add_elite(sim, "foe", [4, 0])
	apply_cond(sim, "ally", "torso", "bleeding", 1)
	assert_rejected(treat_declare(sim, "medic", "field_triage", "ally", "torso", "bleeding", 1),
		"out_of_range", "L1 treats adjacent only")
	var declared: Array[Dictionary] = treat_declare(sim, "medic", "field_triage", "ally", "torso", "bleeding", 3)
	assert_event(declared, "action_declared", "L3 treats at 2 hexes (the range rung)")
	# The premise evaporates between declare and resolution (the wound is
	# field-resolved by the GM/treat command the same tick): the delay finds
	# nothing — and the bandage is NOT burned.
	sim.apply_command({"type": "treat", "target": "ally", "part": "torso",
		"condition": "bleeding", "mode": "resolve"})
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "treatment_applied", "nothing to treat at resolution")
	assert_no_event(ev, "charge_consumed", "a stale premise never burns the bandage")
	assert_event(ev, "condition_ignored", "the honest not_active outcome")
	var medic: CombatantState = sim.combatants["medic"]
	assert_eq(int(medic.charges.get("bandage_charge", -1)), 2, "both charges still held")


# =========================================================== read_the_pattern

func test_pattern_read_reveals_the_schedule_row() -> void:
	var sim: CombatSim = make_sim(5121)
	add_party(sim, "reader", [0, 0])
	add_elite(sim, "foe", [2, 0])
	# The foe commits to a windup — the Clock now holds its scheduled entry.
	var foe_declared: Array[Dictionary] = declare(sim, "foe", {"kind": "skill", "key": "strong_strike",
		"level": 1, "targets": [{"id": "reader", "part": "torso"}]})
	var foe_row: Dictionary = assert_event(foe_declared, "action_declared", "the foe winds up")
	var resolve_tick: int = int(foe_row.get("resolve_tick", -1))
	var declared: Array[Dictionary] = pattern_declare(sim, "reader", "foe")
	assert_event(declared, "action_declared", "the read declares (visible, in range, in the cone)")
	var ev: Array[Dictionary] = advance(sim)
	var read: Dictionary = assert_event(ev, "pattern_read", "the deterministic reveal event")
	assert_eq(String(read.get("actor", "")), "reader", "reader attributed")
	assert_eq(String(read.get("target", "")), "foe", "target attributed")
	var schedule: Array = read.get("schedule", [])
	assert_eq(schedule.size(), 1, "exactly the foe's one pending entry")
	if schedule.size() == 1:
		var row: Dictionary = schedule[0]
		assert_eq(String(row.get("kind", "")), "skill", "row kind exact")
		assert_eq(String(row.get("key", "")), "strong_strike", "row key exact")
		assert_eq(int(row.get("resolve_tick", -1)), resolve_tick, "row resolve_tick exact")
		assert_eq(int(row.get("declared_tick", -1)), resolve_tick - 2, "row declared_tick exact (cost-2 windup)")
		assert_true(bool(row.get("windup", false)), "row windup exact")
	var reader: CombatantState = sim.combatants["reader"]
	assert_true(reader.pattern_reads.has("foe"), "the reveal is recorded on the reader")


func test_pattern_read_gates_cone_range_and_zero_rng() -> void:
	var sim: CombatSim = make_sim(5122)
	add_party(sim, "reader", [0, 0])
	add_elite(sim, "foe", [2, 0])
	add_elite(sim, "far_foe", [4, 0])
	# Beyond the authored 3-hex read range (L1-4).
	assert_rejected(pattern_declare(sim, "reader", "far_foe"), "out_of_range",
		"the read reaches 3 hexes")
	# R30: face AWAY (a free move west turns the reader's back) — the foe is
	# now in the rear arc, and an observer sees NOTHING over its shoulder.
	move(sim, "reader", [-1, 0])
	assert_rejected(pattern_declare(sim, "reader", "foe"), "target_not_visible",
		"the facing cone gates intel — an unseen enemy cannot be read")
	# Zero rng: the whole read path never touches the action stream. Twin sims,
	# one with a read, one without — the NEXT forced roll draws identically.
	var twin_a: CombatSim = make_sim(5123)
	var twin_b: CombatSim = make_sim(5123)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "reader", [0, 0])
		add_elite(twin, "foe", [1, 0])
		apply_cond(twin, "reader", "torso", "bleeding", 2)
	pattern_declare(twin_b, "reader", "foe")
	advance(twin_b)
	advance(twin_a)
	declare(twin_a, "reader", attack_action("crushed", 1, "foe", "torso"))
	declare(twin_b, "reader", attack_action("crushed", 1, "foe", "torso"))
	var roll_a: Dictionary = assert_event(advance(twin_a), "forced_action_triggered", "twin A rolls")
	var roll_b: Dictionary = assert_event(advance(twin_b), "forced_action_triggered", "twin B rolls")
	assert_eq(int(roll_b.get("roll", -1)), int(roll_a.get("roll", -2)),
		"the read consumed ZERO rng — the streams stay aligned")


func test_pattern_read_expires_at_clock_reset() -> void:
	var sim: CombatSim = make_sim(5124)
	add_party(sim, "reader", [0, 0])
	add_elite(sim, "foe", [2, 0])
	pattern_declare(sim, "reader", "foe")
	advance(sim)
	var reader: CombatantState = sim.combatants["reader"]
	assert_true(reader.pattern_reads.has("foe"), "the reveal is live")
	var ev: Array[Dictionary] = advance(sim, 9)  # through the Clock reset
	var expired: Dictionary = assert_event(ev, "pattern_read_expired", "the reset expires the reveal")
	assert_eq(String(expired.get("target", "")), "foe", "naming the read target")
	assert_true(reader.pattern_reads.is_empty(), "knowledge gone — read again next Clock")


# =============================================================== aura_reading

func test_aura_passive_gates_the_contestant_surface() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(5131, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "reader", "name": "Reader", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"skills": [{"key": "aura_reading", "level": 1}]}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "blind", "name": "Blind", "race": "human", "team": "party", "position": [0, 1],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "foe", "name": "Foe", "category": "Elite", "team": "enemies", "position": [2, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1},
		"body_parts": [{"key": "torso", "hp": 20, "lethal": true}]}})
	var reader_row: Dictionary = _view_of(game, "reader")
	var blind_row: Dictionary = _view_of(game, "blind")
	var foe_row: Dictionary = _view_of(game, "foe")
	# Passive: no declare, no cost — OWNING the grant exposes the feeling.
	var aura: Dictionary = reader_row.get("aura_reads", {})
	assert_true(aura.has("foe"), "the owner reads the visible enemy")
	assert_eq(String(aura.get("foe", "")), String(foe_row.get("ai_stance", "?")),
		"the read IS the substrate string (unknown before the first decide)")
	assert_false(blind_row.has("aura_reads"), "a non-owner gets NO aura surface")
	# Broadcast omniscience unchanged: every consumer still sees ai_stance.
	assert_eq(String(foe_row.get("ai_stance", "")), "unknown", "the broadcast field is untouched")
	# After the enemy decides, the owner's read carries the live stance.
	game.apply_command({"type": "ai_decide", "actor": "foe"})
	var after: Dictionary = _view_of(game, "reader").get("aura_reads", {})
	assert_ne(String(after.get("foe", "")), "unknown", "the stance substrate paid off")
	assert_eq(String(after.get("foe", "")), String(_view_of(game, "foe").get("ai_stance", "?")),
		"feeling only — exactly the stance string, never intent/actions")
	# R30: turning the owner's back hides the enemy from the OWNER (the
	# broadcast still sees everything) — the aura key drops off the row.
	game.apply_command({"type": "move", "actor": "reader", "to": [-1, 0]})
	var turned: Dictionary = _view_of(game, "reader")
	assert_false(turned.has("aura_reads"), "cone-blocked: the owner senses nothing behind them")
	assert_ne(String(_view_of(game, "foe").get("ai_stance", "")), "", "broadcast stance still on the enemy row")
	game.free()


func test_aura_never_declares() -> void:
	var sim: CombatSim = make_sim(5132)
	add_party(sim, "reader", [0, 0])
	add_elite(sim, "foe", [2, 0])
	assert_rejected(declare(sim, "reader", {"kind": "skill", "key": "aura_reading", "level": 1,
		"targets": [{"id": "foe", "part": "torso"}]}), "passive_skill",
		"the passive form has no declare — owning it is the mechanic")


func _view_of(game: Node, id: String) -> Dictionary:
	for cd: Dictionary in game.view_combatants():
		if String(cd.get("id", "")) == id:
			return cd
	return {}


# ================================================================= mind_burst

func test_mind_burst_head_bypass_and_stated_tier() -> void:
	var sim: CombatSim = make_sim(5141)
	add_party(sim, "psychic", [0, 0])
	add_elite(sim, "foe", [3, 0])
	var foe: CombatantState = sim.combatants["foe"]
	# Control: a plain attack cannot declare at the un-Exposed head...
	assert_rejected(declare(sim, "psychic", attack_action("crushed", 1, "foe", "head", {"attack_range": 5})),
		"head_not_targetable", "the head gate holds for ordinary attacks")
	# ...but mind_burst declares regardless of Exposure (bypass_head_gate).
	var declared: Array[Dictionary] = burst_declare(sim, "psychic", "foe")
	assert_event(declared, "action_declared", "the burst declares at the un-Exposed head")
	var ev: Array[Dictionary] = advance(sim, 3)  # cost-2 windup: declare T, resolve T+2
	var burst: Dictionary = assert_event(ev, "mind_burst", "the psychic hit lands")
	assert_eq(int(burst.get("tier", 0)), 2, "stated tier 2")
	assert_eq(foe.shock, 2, "fresh Shock lands AT the source tier (R13)")
	assert_true(foe.shock_stutter_pending, "T2 Stutter armed — their current action fails")
	# No wound: psychic noise deals no HP damage and no condition ticks.
	assert_no_event(ev, "damage_applied", "not a wound")
	assert_eq(int(foe.parts["head"]["hp"]), 50, "head HP untouched")


func test_mind_burst_escalates_the_already_shocked() -> void:
	var sim: CombatSim = make_sim(5142)
	add_party(sim, "psychic", [0, 0])
	add_elite(sim, "foe", [3, 0])
	var foe: CombatantState = sim.combatants["foe"]
	burst_declare(sim, "psychic", "foe")
	advance(sim, 3)
	assert_eq(foe.shock, 2, "first burst: T2")
	burst_declare(sim, "psychic", "foe")
	var ev: Array[Dictionary] = advance(sim, 3)
	# Escalation model + R13 per-organ: re-abusing the shocked head elevates
	# the source to 3; already-Shocked escalates to max(old+1, source) = 3.
	assert_eq(foe.shock, 3, "second burst escalates T2 -> T3 (Faint)")
	assert_true(foe.is_helpless(sim.clock.tick), "T3 = Helpless for a Clock")
	assert_event(ev, "shock_changed", "the escalation is an event, not a side-channel")


func test_mind_burst_windup_escape_collapses() -> void:
	var sim: CombatSim = make_sim(5143)
	add_party(sim, "psychic", [0, 0])
	add_elite(sim, "foe", [5, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	burst_declare(sim, "psychic", "foe")  # L1 range 5, exactly in reach
	advance(sim)
	move(sim, "foe", [7, 0])  # the foe leaves the burst's envelope mid-windup
	var ev: Array[Dictionary] = advance(sim, 2)  # through the resolve tick
	var invalid: Dictionary = assert_event(ev, "action_invalidated", "the windup collapses (R2)")
	assert_eq(String(invalid.get("reason", "")), "target_left_range", "the honest reason")
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the standard collapse roll")
	assert_eq(String(forced.get("table", "")), "tool", "invalidated windups roll Tool")
	assert_eq((sim.combatants["foe"] as CombatantState).shock, 0, "no Shock landed")


# ============================================================= acrobatic_save

func test_save_arming_is_the_movement_forfeit() -> void:
	var sim: CombatSim = make_sim(5151)
	add_party(sim, "acrobat", [0, 0])
	add_party(sim, "runner", [0, 1])
	add_elite(sim, "foe", [3, 0])
	# Arming consumes the Moment's movement (G1/R25) — and nothing else.
	var armed: Array[Dictionary] = save_declare(sim, "acrobat")
	var armed_event: Dictionary = assert_event(armed, "acrobatic_save_armed", "the arming event")
	assert_eq(int(armed_event.get("dice", 0)), 1, "L1 = one extra die")
	var acrobat: CombatantState = sim.combatants["acrobat"]
	assert_eq(int(acrobat.forced_save.get("dice", 0)), 1, "the armed state")
	assert_false(acrobat.free_action_used, "the free-action slot is NOT touched (movement only)")
	assert_rejected(move(sim, "acrobat", [1, 0]), "already_moved",
		"the movement is genuinely forfeit")
	assert_rejected(save_declare(sim, "acrobat"), "already_armed", "no double-arming")
	# And the mirror: movement first means no arming this Moment.
	move(sim, "runner", [1, 1])
	assert_rejected(save_declare(sim, "runner"), "movement_spent",
		"movement spent = the cost cannot be paid")
	# NO prime, NO stance (G1 supersedes the ladders doc's old prime note).
	var spec: Dictionary = SkillBook.mechanics("acrobatic_save", 1)
	assert_false(spec.has("prime"), "no prime encoded (R25)")
	assert_eq(String(spec.get("archetype", "")), "forced_roll_save", "the arming archetype")


func test_save_betters_a_bad_roll_pinned_seed() -> void:
	# Pinned seed 5000: draw 1 = 1 (tear_something, severity 6), draw 2 = 2
	# (lock_up, severity 3) — the save chooses the milder lock_up.
	var sim: CombatSim = make_sim(5000)
	add_party(sim, "acrobat", [0, 0])
	add_elite(sim, "foe", [1, 0])
	apply_cond(sim, "acrobat", "torso", "bleeding", 2)  # Forced Body on every action
	save_declare(sim, "acrobat")
	declare(sim, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var save: Dictionary = assert_event(ev, "acrobatic_save", "the save fires on the Body roll")
	var rolls: Array = save.get("rolls", [])
	assert_eq(rolls.size(), 2, "original + one extra die, every die emitted")
	if rolls.size() == 2:
		assert_eq(int((rolls[0] as Dictionary).get("roll", 0)), 1, "pinned original die")
		assert_eq(String((rolls[0] as Dictionary).get("consequence", "")), "tear_something", "pinned original consequence")
		assert_eq(int((rolls[1] as Dictionary).get("roll", 0)), 2, "pinned extra die")
		assert_eq(String((rolls[1] as Dictionary).get("consequence", "")), "lock_up", "pinned extra consequence")
	assert_eq(int(save.get("chosen_index", -1)), 1, "the milder consequence wins")
	assert_false(bool(save.get("kept_original", true)), "the save bettered the roll")
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the canonical roll event")
	assert_eq(String(forced.get("consequence", "")), "lock_up", "the CHOSEN consequence is what applies")
	var acrobat: CombatantState = sim.combatants["acrobat"]
	assert_true(acrobat.forced_save.is_empty(), "the arming is consumed by the roll")
	assert_event(ev, "part_locked", "lock_up applied — not tear_something's damage")
	for dmg: Dictionary in events_of(ev, "damage_applied"):
		assert_ne(String(dmg.get("combatant", "")), "acrobat",
			"tear_something never happened — no self-damage anywhere")


func test_save_tie_keeps_the_original_pinned_seed() -> void:
	# Pinned seed 5004: both dice roll 1 (tear_something = tear_something) —
	# equal severity keeps the ORIGINAL (earliest) die.
	var sim: CombatSim = make_sim(5004)
	add_party(sim, "acrobat", [0, 0])
	add_elite(sim, "foe", [1, 0])
	apply_cond(sim, "acrobat", "torso", "bleeding", 2)
	save_declare(sim, "acrobat")
	declare(sim, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var save: Dictionary = assert_event(ev, "acrobatic_save", "the save fires")
	var rolls: Array = save.get("rolls", [])
	assert_eq(rolls.size(), 2, "both dice emitted")
	if rolls.size() == 2:
		assert_eq(String((rolls[0] as Dictionary).get("consequence", "")), "tear_something", "pinned die 1")
		assert_eq(String((rolls[1] as Dictionary).get("consequence", "")), "tear_something", "pinned die 2")
	assert_eq(int(save.get("chosen_index", -1)), 0, "a tie keeps the original")
	assert_true(bool(save.get("kept_original", false)), "kept_original says so")


func test_save_twin_rng_unarmed_draws_zero_extra() -> void:
	# Twin sims, same seed (5000), same command log EXCEPT twin B arms the
	# save. Unarmed twin A: zero extra draws — its SECOND Body roll consumes
	# the stream value the armed twin spent as its extra die.
	var twin_a: CombatSim = make_sim(5000)
	var twin_b: CombatSim = make_sim(5000)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "acrobat", [0, 0])
		add_elite(twin, "foe", [1, 0])
		apply_cond(twin, "acrobat", "torso", "bleeding", 2)
	save_declare(twin_b, "acrobat")
	declare(twin_a, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	declare(twin_b, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	var ev_a1: Array[Dictionary] = advance(twin_a)
	var ev_b1: Array[Dictionary] = advance(twin_b)
	assert_no_event(ev_a1, "acrobatic_save", "unarmed: no save event")
	assert_eq(int(assert_event(ev_a1, "forced_action_triggered", "A tick 1").get("roll", 0)), 1,
		"A draw 1 (seed-pinned)")
	var save_b: Dictionary = assert_event(ev_b1, "acrobatic_save", "armed: the save event")
	var save_b_rolls: Array = save_b.get("rolls", [])
	assert_eq(save_b_rolls.size(), 2, "armed: original + one extra die")
	if save_b_rolls.size() == 2:
		assert_eq(int((save_b_rolls[1] as Dictionary).get("roll", 0)), 2,
			"B's extra die is stream draw 2")
	# Tick 2: both declare again — A's roll is draw 2 (proof it never drew an
	# extra), B's is draw 3 AND fires with no save (arming consumed per roll).
	declare(twin_a, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	declare(twin_b, "acrobat", attack_action("crushed", 1, "foe", "torso"))
	var ev_a2: Array[Dictionary] = advance(twin_a)
	var ev_b2: Array[Dictionary] = advance(twin_b)
	assert_eq(int(assert_event(ev_a2, "forced_action_triggered", "A tick 2").get("roll", 0)), 2,
		"unarmed A's second roll IS stream draw 2 — zero extra draws happened")
	assert_eq(int(assert_event(ev_b2, "forced_action_triggered", "B tick 2").get("roll", 0)), 6,
		"armed B's second roll is stream draw 3 — exactly one extra die was spent")
	assert_no_event(ev_b2, "acrobatic_save", "the arming was consumed by roll 1 — per roll, not per Clock")


# ==================================================== serialization & honesty

func test_batch_c_state_round_trips_mid_everything() -> void:
	# Armed save + live pattern read + charges + a banked multi-Clock delay —
	# the full batch-C state surface — must survive to_dict/from_dict and
	# continue identically on both timelines.
	var live: CombatSim = make_sim(5161)
	add_party(live, "medic", [0, 0], {"charges": {"bandage_charge": 2}})
	add_party(live, "acrobat", [0, 1])
	add_party(live, "reader", [1, -1])
	add_elite(live, "foe", [2, 0])
	apply_cond(live, "acrobat", "torso", "bleeding", 1)
	treat_declare(live, "medic", "field_triage", "acrobat", "torso", "bleeding", 4)  # 3-Clock delay
	save_declare(live, "acrobat")
	declare(live, "foe", {"kind": "skill", "key": "strong_strike", "level": 1,
		"targets": [{"id": "medic", "part": "torso"}]})
	pattern_declare(live, "reader", "foe")
	advance(live)
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the round-trip")
	var r_acrobat: CombatantState = restored.combatants["acrobat"]
	assert_eq(int(r_acrobat.forced_save.get("dice", 0)), 1, "the armed save round-trips")
	assert_true((restored.combatants["reader"] as CombatantState).pattern_reads.has("foe"),
		"the live reveal round-trips")
	assert_eq(int((restored.combatants["medic"] as CombatantState).charges.get("bandage_charge", -1)), 1,
		"the spent charge round-trips")
	assert_eq(int(r_acrobat.condition_instance("torso", "bleeding").get("delay_clocks", 0)), 2,
		"the banked multi-Clock delay round-trips")
	var live_tail: Array[Dictionary] = advance(live, 9)
	var rest_tail: Array[Dictionary] = advance(restored, 9)
	assert_event(live_tail, "pattern_read_expired", "live: the reveal expires at the reset")
	assert_event(rest_tail, "pattern_read_expired", "restored: identically")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_batch_c_fields_serialize_only_when_set() -> void:
	# The compat pin: a batch-C-free fight carries none of the new keys.
	var sim: CombatSim = make_sim(5162)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	apply_cond(sim, "e", "torso", "bleeding", 1)
	# A plain single-Clock delay (the legacy treat command) must not grow the
	# instance either — delay_clocks is only-when-set.
	sim.apply_command({"type": "treat", "target": "e", "part": "torso",
		"condition": "bleeding", "mode": "delay"})
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("forced_save"), "no 'forced_save' key on a save-free combatant (%s)" % id)
		assert_false(c.has("pattern_reads"), "no 'pattern_reads' key on a read-free combatant (%s)" % id)
	var e_conditions: Dictionary = (dict["combatants"]["e"] as Dictionary).get("conditions", {})
	var bleeding_instance: Dictionary = (e_conditions.get("torso", {}) as Dictionary).get("bleeding", {})
	assert_false(bleeding_instance.has("delay_clocks"),
		"a single-Clock delay never grows the instance (legacy hash pin)")


func test_batch_c_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(5163)
		add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 1}})
		add_party(sim, "acrobat", [0, 1])
		add_party(sim, "reader", [1, -1])
		add_party(sim, "psychic", [-1, 1])
		add_elite(sim, "foe", [1, 1])
		apply_cond(sim, "acrobat", "torso", "bleeding", 2)
		treat_declare(sim, "medic", "field_triage", "acrobat", "torso", "bleeding")
		save_declare(sim, "acrobat")
		declare(sim, "acrobat", attack_action("crushed", 1, "foe", "torso"))
		pattern_declare(sim, "reader", "foe")
		burst_declare(sim, "psychic", "foe")
		advance(sim, 12)  # instants + the burst windup + the Clock-reset expiry sweep
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole batch")
