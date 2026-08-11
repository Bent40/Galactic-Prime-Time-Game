extends SimTestBase
## KAN-4 S4.1 — the character-creation ENGINE (decision-log #31: engine only,
## the owner drafts the front later). Proves simulation/creation.gd:
##   * a valid creation spec assembles into the EXACT add_combatant spec —
##     from_spec round-trips field-by-field (parts/HP/lethal from races.json,
##     traits, skills, bit, R22 default threshold dice);
##   * validate() returns EVERY violation at once (never fail-fast), each
##     ruled check surfaces its own {code, field, message}, deterministically;
##   * the R16 cap-trade rule both ways (picks + raises <= 4; raised caps buy
##     real level headroom; over-budget and non-raise caps rejected);
##   * no bit is VALID (decision #25 — not everyone has one);
##   * a non-human plan is rejected TODAY, data-driven (Q61/R21 morphology
##     deferral + the unlocked gate — never a hardcoded race list);
##   * assembled specs are accepted by a REAL sim (add_combatant, zero
##     rejections, stable hash) and a 3-party fight staged from three
##     assembled specs runs mixed ticks clean.

## Creation specs mirroring the demo/recruit loadouts (numbers verbatim from
## data/demo_loadouts.json / data/recruit_loadouts.json — the creation-legal
## precedent data; explicit ids match the loadout first-token mapping).
const DARIO_BIT: Dictionary = {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}

var _data: Dictionary = {}


## Static data for creation: the sim's table plus skills.json (creation reads
## "races" and "skills"; the sim itself never needs the skills table).
func creation_data() -> Dictionary:
	if _data.is_empty():
		_data = SimTestBase.load_static_data()
		_data["skills"] = load_json("res://data/skills.json")
	return _data


func imani_spec() -> Dictionary:
	return {
		"name": "Imani \"The Door\" Brandt",
		"id": "imani",
		"body_plan": "human",
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3},
		"skills": [
			{"key": "strong_strike", "level": 2},
			{"key": "overhead_slam", "level": 1, "cap": 6},
			{"key": "brace", "level": 2},
		],
		"persona": "The immovable veteran.",
		"patron": 3,
		"camera_call_stacks": 1,
	}


func dario_spec() -> Dictionary:
	return {
		"name": "Dario \"Encore\" Vekić",
		"id": "dario",
		"body_plan": "human",
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5},
		"skills": [
			{"key": "feint", "level": 3, "cap": 6},
			{"key": "pressure_strike", "level": 1},
			{"key": "dance", "level": 2},
		],
		"bit": DARIO_BIT.duplicate(true),
		"persona": "The heel you pay to boo.",
		"patron": 2,
		"camera_call_stacks": 1,
	}


func sasha_spec() -> Dictionary:
	return {
		"name": "Sasha \"The Tell\" Marchenko",
		"id": "sasha",
		"body_plan": "human",
		"traits": {"physique": 3, "reflexes": 4, "mind": 5, "charm": 2},
		"skills": [
			{"key": "feint", "level": 2},
			{"key": "brace", "level": 2},
			{"key": "strong_strike", "level": 1},
		],
		"persona": "The oddsmaker's nightmare.",
		"patron": 5,
		"camera_call_stacks": 1,
	}


func codes_of(violations: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for v: Dictionary in violations:
		out.append(String(v.get("code", "")))
	return out


## Asserts validate(spec) surfaces the expected code (message names the case).
func assert_code(spec: Dictionary, code: String, message: String) -> void:
	var codes: Array[String] = codes_of(Creation.validate(spec, creation_data()))
	assert_true(codes.has(code), "%s — expected code '%s', got %s" % [message, code, str(codes)])


## Canonical text form (the hashing-relevant form — CombatSim key-sorts).
func canon(value: Variant) -> String:
	return CombatSim.canonical_serialize(value)


# ---------------------------------------------------------------- validity

func test_valid_specs_validate_empty() -> void:
	for spec: Dictionary in [imani_spec(), dario_spec(), sasha_spec()]:
		var violations: Array[Dictionary] = Creation.validate(spec, creation_data())
		assert_eq(violations.size(), 0, "%s: creation-legal spec has zero violations: %s" % [String(spec["id"]), str(violations)])


func test_validate_is_deterministic_and_nonmutating() -> void:
	# A many-violation spec: same input -> the identical violation list, same
	# order, twice — and validate/assemble never mutate the spec they read.
	var broken: Dictionary = {
		"name": "",
		"body_plan": "animal",
		"traits": {"physique": 6, "reflexes": 2, "mind": 5, "charm": 3},
		"skills": [{"key": "fireball", "level": 1}, {"key": "brace", "level": 0}],
		"bit": {"key": "x"},
		"camera_call_stacks": 2,
	}
	var before: String = canon(broken)
	var first: Array[Dictionary] = Creation.validate(broken, creation_data())
	var second: Array[Dictionary] = Creation.validate(broken, creation_data())
	assert_eq(canon(first), canon(second), "validate is deterministic: identical list, identical order")
	assert_eq(canon(broken), before, "validate never mutates the spec")
	var good: Dictionary = imani_spec()
	var good_before: String = canon(good)
	Creation.validate(good, creation_data())
	Creation.assemble(good, creation_data())
	assert_eq(canon(good), good_before, "assemble never mutates the spec")


# ---------------------------------------------------------------- round-trip

func test_assemble_round_trips_through_from_spec() -> void:
	# Dario (bit + R16 cap trade): assemble -> from_spec -> every field the
	# creation spec governs, checked against races.json + the input finals.
	var data: Dictionary = creation_data()
	var assembled: Dictionary = Creation.assemble(dario_spec(), data)
	assert_false(assembled.is_empty(), "a valid spec assembles")
	assert_eq(String(assembled["id"]), "dario", "explicit id override carried")
	assert_eq(String(assembled["race"]), "human", "body_plan maps to the races.json key (the recruit-spec path)")
	assert_eq(assembled["persona"], "The heel you pay to boo.", "persona passthrough")
	assert_eq(int(assembled["patron"]), 2, "patron passthrough")
	assert_false(assembled.has("threshold_dice"), "no dice grant emitted — R22 default d4 applies by omission")
	var c: CombatantState = CombatantState.from_spec(assembled, data)
	assert_eq(c.id, "dario", "combat id")
	assert_eq(c.display_name, "Dario \"Encore\" Vekić", "display name")
	assert_eq(c.category, "Contestant", "race-built specs default Contestant")
	assert_eq(c.template_key, "", "no enemy template")
	assert_eq(c.size, "Medium", "size from the human plan")
	assert_eq(c.team, "", "team left to the caller")
	# Parts: exactly the human plan, HP/lethal verbatim (hp_bonus 0 at
	# creation traits — Physique <= 5 is far under the over-10 ladder, R6).
	var plan_parts: Array = []
	for race: Variant in data["races"] as Array:
		if String((race as Dictionary).get("key", "")) == "human":
			plan_parts = (race as Dictionary).get("body_parts", [])
	assert_eq(c.parts.size(), plan_parts.size(), "every plan part landed (and nothing else)")
	assert_eq(c.hp_bonus_per_part(), 0, "no over-10 HP bonus at creation traits")
	for part_spec: Variant in plan_parts:
		var p: Dictionary = part_spec
		var key := String(p["key"])
		assert_true(c.parts.has(key), "part %s present" % key)
		var part: Dictionary = c.parts.get(key, {})
		assert_eq(String(part.get("name", "")), String(p["name"]), "%s: name" % key)
		assert_eq(int(part.get("hp", -1)), int(p["hp"]), "%s: hp = plan base" % key)
		assert_eq(int(part.get("base_max_hp", -1)), int(p["hp"]), "%s: base_max_hp" % key)
		assert_eq(bool(part.get("lethal", not bool(p["lethal"]))), bool(p["lethal"]), "%s: lethal flag" % key)
		assert_false(bool(part.get("destroyed", true)), "%s: starts intact" % key)
	# Traits: the FINAL numbers, base-only (bonus/level_bonus zero).
	for trait_key: String in CombatantState.TRAIT_KEYS:
		var expected: int = int((dario_spec()["traits"] as Dictionary)[trait_key])
		assert_eq(c.trait_total(trait_key), expected, "trait_total(%s) matches the spec final" % trait_key)
		assert_eq(int((c.stats[trait_key] as Dictionary)["base"]), expected, "%s base" % trait_key)
		assert_eq(int((c.stats[trait_key] as Dictionary)["bonus"]), 0, "%s bonus 0" % trait_key)
		assert_eq(int((c.stats[trait_key] as Dictionary)["level_bonus"]), 0, "%s level_bonus 0" % trait_key)
	# Skills: grant order preserved, levels via skill_level(), the R16 cap
	# annotation validated then dropped by from_spec's normalization (the
	# demo/recruit loadout path).
	assert_eq(c.skills.size(), 3, "three granted skills")
	assert_eq(c.skill_level("feint"), 3, "feint at the granted level")
	assert_eq(c.skill_level("pressure_strike"), 1, "pressure_strike granted")
	assert_eq(c.skill_level("dance"), 2, "dance granted")
	assert_eq(c.skills[0], {"key": "feint", "level": 3}, "from_spec normalized the cap annotation away")
	# Bit + camera stacks + R22 dice defaults.
	assert_eq(c.bit, DARIO_BIT, "authored bit carried verbatim (decision #25)")
	assert_eq(c.camera_call_stacks_granted, 1, "granted camera stacks")
	assert_eq(int(c.derived_stats()["camera_call_stacks"]), 1, "derived stacks = granted + over-cap 0")
	for trait_key: String in CombatantState.TRAIT_KEYS:
		assert_eq(c.threshold_die(trait_key), 4, "%s threshold die defaults d4 (R22)" % trait_key)


func test_assemble_is_deterministic_and_slugs_a_default_id() -> void:
	var data: Dictionary = creation_data()
	var a: Dictionary = Creation.assemble(imani_spec(), data)
	var b: Dictionary = Creation.assemble(imani_spec(), data)
	assert_eq(canon(a), canon(b), "same spec in -> identical dict out (canonical form)")
	assert_true(a == b, "deep-equal dicts")
	# Default id: deterministic slug of name when no override is given.
	var spec: Dictionary = imani_spec()
	spec.erase("id")
	var slugged: Dictionary = Creation.assemble(spec, data)
	assert_eq(String(slugged["id"]), "imani_the_door_brandt", "id defaults to the name slug")
	assert_eq(canon(slugged), canon(Creation.assemble(spec, data)), "slugged assembly is deterministic too")


# ---------------------------------------------------------------- violations

func test_each_validation_rule_surfaces_its_code() -> void:
	# name / id
	var s: Dictionary = imani_spec()
	s["name"] = ""
	assert_code(s, "name_required", "empty name")
	s = imani_spec()
	s["id"] = ""
	assert_code(s, "id_invalid", "empty explicit id")
	s = imani_spec()
	s.erase("id")
	s["name"] = "!!!"
	assert_code(s, "id_invalid", "name that slugs to nothing needs an explicit id")
	# body plan (data-driven: unknown key / R16 removed race / unlocked gate)
	s = imani_spec()
	s["body_plan"] = "robot"
	assert_code(s, "unknown_body_plan", "robot was REMOVED by R16 — not a races.json key")
	s = imani_spec()
	s.erase("body_plan")
	assert_code(s, "unknown_body_plan", "missing body_plan")
	# unlocked gate: proven against injected data (no shipped race is locked).
	var locked_data: Dictionary = creation_data().duplicate(true)
	for race: Variant in locked_data["races"] as Array:
		if String((race as Dictionary).get("key", "")) == "human":
			(race as Dictionary)["unlocked"] = 0
	var locked_codes: Array[String] = codes_of(Creation.validate(imani_spec(), locked_data))
	assert_true(locked_codes.has("body_plan_locked"), "a locked plan is data-rejected, got %s" % str(locked_codes))
	# traits
	s = imani_spec()
	s.erase("traits")
	assert_code(s, "traits_invalid", "traits must be an object")
	s = imani_spec()
	(s["traits"] as Dictionary).erase("mind")
	assert_code(s, "trait_invalid", "missing trait")
	s = imani_spec()
	(s["traits"] as Dictionary)["physique"] = 6
	(s["traits"] as Dictionary)["reflexes"] = 1
	assert_code(s, "trait_out_of_range", "trait over the creation cap of 5 (R6)")
	s = imani_spec()
	s["traits"] = {"physique": 4, "reflexes": 2, "mind": 4, "charm": 3}
	assert_code(s, "body_budget_violation", "Body pillar must sum to exactly 7 (R6)")
	s = imani_spec()
	s["traits"] = {"physique": 5, "reflexes": 2, "mind": 5, "charm": 3}
	assert_code(s, "core_budget_violation", "Core pillar must sum to exactly 7 (R6)")
	# skills
	s = imani_spec()
	s["skills"] = []
	assert_code(s, "skills_required", "empty skills list")
	s = imani_spec()
	s.erase("skills")
	assert_code(s, "skills_required", "missing skills list")
	s = imani_spec()
	s["skills"] = [{"level": 2}]
	assert_code(s, "skill_row_invalid", "row without a key")
	s = imani_spec()
	s["skills"] = [{"key": "fireball", "level": 1}]
	assert_code(s, "unknown_skill", "fireball is seed content, not SkillBook-implemented")
	s = imani_spec()
	s["skills"] = [{"key": "brace", "level": 2}, {"key": "brace", "level": 1}]
	assert_code(s, "duplicate_skill", "the same skill granted twice")
	s = imani_spec()
	s["skills"] = [{"key": "brace", "level": 0}]
	assert_code(s, "skill_level_invalid", "level 0 is untrained (R19), not a background grant")
	s = imani_spec()
	s["skills"] = [{"key": "brace", "level": 6}]
	assert_code(s, "skill_level_invalid", "level above the untraded default_cap 5")
	# bit (decision #25 authored shape)
	s = sasha_spec()
	s["bit"] = {"key": "x"}
	assert_code(s, "bit_invalid", "bit missing name/line")
	s = sasha_spec()
	s["bit"] = {"key": "x", "name": "X", "line": ""}
	assert_code(s, "bit_invalid", "bit with an empty line")
	s = sasha_spec()
	s["bit"] = {"key": "x", "name": "X", "line": "does X.", "mood": "smug"}
	assert_code(s, "bit_invalid", "bit with extra keys is not the authored shape")
	# camera stacks (demo precedent bound, PROVISIONAL)
	s = imani_spec()
	s["camera_call_stacks"] = -1
	assert_code(s, "camera_call_stacks_invalid", "negative stacks")
	s = imani_spec()
	s["camera_call_stacks"] = 2
	assert_code(s, "camera_call_stacks_invalid", "above the demo-precedent grant of 1")


func test_multi_violation_returns_all_at_once() -> void:
	# One pass, many broken rules: every code present in the ONE returned
	# list — never fail-fast — and every entry carries {code, field, message}.
	var spec: Dictionary = {
		"name": "",
		"body_plan": "animal",
		"traits": {"physique": 6, "reflexes": 2, "mind": 5, "charm": 3},
		"skills": [{"key": "fireball", "level": 1}, {"key": "brace", "level": 0}],
		"bit": {"key": "x"},
		"camera_call_stacks": 7,
	}
	var violations: Array[Dictionary] = Creation.validate(spec, creation_data())
	var codes: Array[String] = codes_of(violations)
	for expected: String in ["name_required", "body_plan_deferred", "trait_out_of_range",
			"body_budget_violation", "core_budget_violation", "unknown_skill",
			"skill_level_invalid", "bit_invalid", "camera_call_stacks_invalid"]:
		assert_true(codes.has(expected), "one call surfaces '%s' alongside the rest: %s" % [expected, str(codes)])
	for v: Dictionary in violations:
		assert_true(String(v.get("code", "")) != "" and String(v.get("field", "")) != ""
			and String(v.get("message", "")) != "", "entry carries code+field+message: %s" % str(v))


# ---------------------------------------------------------------- R16 trade

func test_cap_trade_r16_both_ways() -> void:
	var data: Dictionary = creation_data()
	# LEGAL: 3 picks + one +1 cap = 4 (the demo Imani/Dario pattern).
	assert_eq(Creation.validate(imani_spec(), data).size(), 0, "3 picks + one raise = the full 4-pick budget")
	# LEGAL: all 4 picks kept, no trade.
	var four: Dictionary = imani_spec()
	four["skills"] = [
		{"key": "strong_strike", "level": 1}, {"key": "overhead_slam", "level": 1},
		{"key": "brace", "level": 1}, {"key": "feint", "level": 1},
	]
	assert_eq(Creation.validate(four, data).size(), 0, "4 picks, no raises")
	# LEGAL: fewer picks than the max (the recruits ship with 3, no trade).
	assert_eq(Creation.validate(sasha_spec(), data).size(), 0, "3 picks and an open 4th slot is legal")
	# LEGAL boundary: 2 picks + a +2 raise on one of them = 4; the raised cap
	# buys REAL level headroom (level 7 <= cap 7).
	var stacked: Dictionary = imani_spec()
	stacked["skills"] = [{"key": "strong_strike", "level": 7, "cap": 7}, {"key": "brace", "level": 1}]
	assert_eq(Creation.validate(stacked, data).size(), 0,
		"2 picks + 2 raises stacked on one skill = 4 (R16 reading: each raise costs a pick)")
	# ILLEGAL: 4 picks AND a raise = 5 > 4.
	var over: Dictionary = four.duplicate(true)
	((over["skills"] as Array)[0] as Dictionary)["cap"] = 6
	assert_code(over, "background_picks_exceeded", "4 kept picks leave nothing to trade")
	# ILLEGAL: 3 picks + a +4 raise = 7 > 4.
	var greedy: Dictionary = imani_spec()
	((greedy["skills"] as Array)[1] as Dictionary)["cap"] = 9
	assert_code(greedy, "background_picks_exceeded", "a +4 raise costs more picks than remain")
	# ILLEGAL cap values: not a raise / over the schema ceiling.
	var flat: Dictionary = imani_spec()
	((flat["skills"] as Array)[1] as Dictionary)["cap"] = 5
	assert_code(flat, "cap_trade_invalid", "cap equal to default_cap is not a trade")
	var eleven: Dictionary = imani_spec()
	((eleven["skills"] as Array)[1] as Dictionary)["cap"] = 11
	assert_code(eleven, "cap_trade_invalid", "cap above the schema CHECK ceiling of 10")
	# Level must respect the RAISED cap, not just the default.
	var high: Dictionary = imani_spec()
	((high["skills"] as Array)[1] as Dictionary)["level"] = 6
	assert_eq(Creation.validate(high, data).size(), 0, "level 6 is legal under the traded cap 6")
	((high["skills"] as Array)[1] as Dictionary)["level"] = 7
	assert_code(high, "skill_level_invalid", "level 7 exceeds the traded cap 6")


# ---------------------------------------------------------------- bit / plan

func test_no_bit_is_valid() -> void:
	# Decision #25: not everyone has a bit — Sasha's whole act is that she
	# never performs. A bitless spec validates, assembles, and lands bit {}.
	var data: Dictionary = creation_data()
	var spec: Dictionary = sasha_spec()
	assert_false(spec.has("bit"), "precondition: the spec carries no bit")
	assert_eq(Creation.validate(spec, data).size(), 0, "no bit is VALID")
	var assembled: Dictionary = Creation.assemble(spec, data)
	assert_false(assembled.has("bit"), "assemble emits no bit key for a bitless character")
	var c: CombatantState = CombatantState.from_spec(assembled, data)
	assert_eq(c.bit, {}, "from_spec lands the empty bit (the sim rejects the_bit for her)")


func test_non_human_plan_rejected_today() -> void:
	# Animal is Earth-life (R16) and unlocked in the data, but its layout is
	# an authored per-character sitting — deferred (owner ruling Q61 / R21).
	# The gate reads the DATA (racial_traits.variable_morphology), never a
	# hardcoded race list.
	var spec: Dictionary = imani_spec()
	spec["body_plan"] = "animal"
	assert_code(spec, "body_plan_deferred", "animal creation waits on the parts sitting")
	var assembled: Dictionary = Creation.assemble(spec, creation_data())
	assert_true(assembled.is_empty(), "assemble refuses the deferred plan")


func test_assemble_invalid_spec_returns_empty_never_half() -> void:
	# Contract: push_error + {} — never a half-spec. (The push_error prints an
	# ERROR line in the headless log; that is the contract, not a failure.)
	var spec: Dictionary = imani_spec()
	spec["skills"] = [{"key": "brace", "level": 9}]
	var assembled: Dictionary = Creation.assemble(spec, creation_data())
	assert_true(assembled.is_empty(), "invalid spec assembles to exactly {}")


# ---------------------------------------------------------------- real sim

## Stages a sim with the three creation-assembled contestants (team/position
## merged by the caller, as documented) and asserts clean acceptance.
func _staged_sim(sim_seed: int, with_boss: bool) -> CombatSim:
	var data: Dictionary = creation_data()
	var sim: CombatSim = make_sim(sim_seed)
	if with_boss:
		sim.apply_command({"type": "add_combatant", "combatant": {
			"id": "boss", "name": "Incinedile", "enemy": "incinedile",
			"team": "enemies", "position": [0, 0],
		}})
	var staging: Array = [
		[imani_spec(), [1, 0]], [dario_spec(), [0, 1]], [sasha_spec(), [1, -1]],
	]
	for row: Variant in staging:
		var combatant: Dictionary = Creation.assemble((row as Array)[0], data)
		assert_false(combatant.is_empty(), "spec assembles")
		combatant["team"] = "party"
		combatant["position"] = (row as Array)[1]
		var events: Array[Dictionary] = sim.apply_command({"type": "add_combatant", "combatant": combatant})
		assert_event(events, "combatant_added", "the REAL sim accepts the assembled spec")
		assert_no_event(events, "command_rejected", "zero rejections on add")
	return sim


func test_assembled_specs_accepted_by_real_sim_hash_stable() -> void:
	var sim: CombatSim = _staged_sim(777, false)
	assert_eq(sim.combatants.size(), 3, "all three assembled contestants on the table")
	var h: String = sim.state_hash()
	assert_eq(h.length(), 64, "full sha256 hex digest")
	assert_true(h.is_valid_hex_number(false), "valid hex")
	assert_eq(_staged_sim(777, false).state_hash(), h,
		"same seed + same assembled specs = the identical state hash (persona/patron passthrough never leaks into state)")


## Scripted mixed-command trio fight from three ASSEMBLED specs vs the real
## seeded Incinedile (the test_party_of_three staging idiom): guarded skill
## rotations off each granted kit, a free brace, Dario's authored bit, boss
## ai_decides — every emitted command legal.
func _assembled_trio_fight(sim_seed: int) -> Dictionary:
	var sim: CombatSim = _staged_sim(sim_seed, true)
	var rotations: Dictionary = {
		"imani": [
			{"kind": "skill", "key": "strong_strike", "level": 2, "attack_range": 3, "targets": [{"id": "boss", "part": "left_hand"}]},
			{"kind": "skill", "key": "overhead_slam", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "left_hand"}]},
		],
		"dario": [
			{"kind": "skill", "key": "feint", "level": 3, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
			{"kind": "skill", "key": "pressure_strike", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
		],
		"sasha": [
			{"kind": "skill", "key": "feint", "level": 2, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
			{"kind": "skill", "key": "strong_strike", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
		],
	}
	var next_idx: Dictionary = {"imani": 0, "dario": 0, "sasha": 0}
	var events: Array[Dictionary] = []
	for t: int in range(14):
		for id: String in ["imani", "dario", "sasha"]:
			var c: CombatantState = sim.combatants[id]
			var boss: CombatantState = sim.combatants["boss"]
			if not c.can_act(sim.clock.tick) or sim.clock.tick < c.next_action_tick or c.windup_pending:
				continue
			if not boss.alive or CombatantState.hex_distance(c.position, boss.position) > 3:
				continue
			var rot: Array = rotations[id]
			var action: Dictionary = (rot[int(next_idx[id]) % rot.size()] as Dictionary).duplicate(true)
			next_idx[id] = int(next_idx[id]) + 1
			events.append_array(declare(sim, id, action))
		if t == 1:
			var sasha: CombatantState = sim.combatants["sasha"]
			if sasha.can_act(sim.clock.tick) and not sasha.free_action_used:
				events.append_array(declare(sim, "sasha", {"kind": "skill", "key": "brace", "level": 2}))
		if t == 2:
			var dario: CombatantState = sim.combatants["dario"]
			if dario.can_act(sim.clock.tick) and not dario.free_action_used:
				events.append_array(sim.apply_command({"type": "bit", "actor": "dario"}))
		for aid: String in sim.ai_ready_ids():
			events.append_array(sim.apply_command({"type": "ai_decide", "actor": aid}))
		events.append_array(advance(sim, 1))
	return {
		"hash": sim.state_hash(),
		"rejections": events_of(events, "command_rejected"),
		"damage": events_of(events, "damage_applied").size(),
		"decisions": events_of(events, "ai_decision").size(),
		"bits": events_of(events, "bit_performed").size(),
	}


func test_three_party_fight_from_assembled_specs_runs_mixed_ticks_clean() -> void:
	var run: Dictionary = _assembled_trio_fight(4321)
	assert_eq((run["rejections"] as Array).size(), 0,
		"14 mixed ticks of assembled trio + boss produce ZERO rejections: %s" % str(run["rejections"]))
	assert_true(int(run["damage"]) > 0, "the fight is real — damage landed (%d hits)" % int(run["damage"]))
	assert_true(int(run["decisions"]) > 0, "the boss actually fought (%d ai decisions)" % int(run["decisions"]))
	assert_eq(int(run["bits"]), 1, "Dario's creation-carried authored bit performed on camera")
	assert_eq(String(_assembled_trio_fight(4321)["hash"]), String(run["hash"]),
		"same seed + same script from assembled specs = same final hash")
