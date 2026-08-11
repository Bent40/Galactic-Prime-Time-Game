extends SimTestBase
## Wave 3b — the Gemstone mutation machinery (G6 owner ruling 2026-07-23 round
## 3; book §4.5; rules-addendum R27). Proves simulation/skill_forge.gd +
## data/skill_mutations.json:
##   * the Iron Stance recipe is canon: Intercept Lv5 + Brace Lv3 ->
##     iron_stance Lv1, no compatibility_override — and its parents REALLY
##     share the narrow keyword 'bracing' in the ported data (the loud
##     discrepancy assert the recipe's legality rests on);
##   * a valid roster mutates: both parents CONSUMED, result granted at the
##     recipe level, bystander rows untouched, order preserved;
##   * every violation surfaces (missing parent / underleveled /
##     already-owned / broad-only parents without an override / malformed
##     recipe), and ALL violations arrive at once (Creation-style);
##   * apply is PURE (input array + rows untouched), deterministic, and
##     returns [] (never a half-roster) on an invalid mutation;
##   * a mutated skills array round-trips through CombatantState.from_spec /
##     to_dict / from_dict and a REAL sim's state hash — unimplemented keys
##     (iron_stance) are legal grant DATA (from_spec has no KNOWN_KEYS gate).

var _keywords: Dictionary = {}
var _mutations: Dictionary = {}


func keywords() -> Dictionary:
	if _keywords.is_empty():
		_keywords = load_json("res://data/skill_keywords.json")
	return _keywords


func iron_stance_recipe() -> Dictionary:
	if _mutations.is_empty():
		_mutations = load_json("res://data/skill_mutations.json")
	return SkillForge.find_recipe(_mutations, "iron_stance")


## A mutation-ready roster: both parents at exactly the recipe minimums plus
## an implemented bystander grant (order matters: bystander sits between).
func ready_roster() -> Array:
	return [
		{"key": "intercept", "level": 5},
		{"key": "dance", "level": 2},
		{"key": "brace", "level": 3},
	]


func codes_of(violations: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for v: Dictionary in violations:
		out.append(String(v.get("code", "")))
	return out


func canon(value: Variant) -> String:
	return CombatSim.canonical_serialize(value)


# ------------------------------------------------------------ recipe is canon

func test_iron_stance_recipe_is_the_ruled_canon() -> void:
	var recipe: Dictionary = iron_stance_recipe()
	assert_false(recipe.is_empty(), "the iron_stance recipe ships in data/skill_mutations.json")
	var parents: Array = recipe.get("parents", [])
	assert_eq(parents.size(), 2, "two parents (G6: Intercept + Brace)")
	assert_eq(String((parents[0] as Dictionary).get("key", "")), "intercept", "parent 1 intercept")
	assert_eq(int((parents[0] as Dictionary).get("min_level", 0)), 5, "Intercept Lv5 (G6)")
	assert_eq(String((parents[1] as Dictionary).get("key", "")), "brace", "parent 2 brace")
	assert_eq(int((parents[1] as Dictionary).get("min_level", 0)), 3, "Brace Lv3 (G6)")
	assert_eq(String((recipe.get("result", {}) as Dictionary).get("key", "")), "iron_stance",
		"result iron_stance")
	assert_eq(int((recipe.get("result", {}) as Dictionary).get("level", 0)), 1,
		"the mutation arrives at level 1 (book §4.5)")
	# The G3 legality this recipe rests on, asserted against the PORTED data:
	# Intercept x Brace share the NARROW keyword 'bracing' — so the recipe
	# carries NO compatibility_override. If this ever fails, the port drifted
	# from the ruling ("compatible through bracing", book §4.5).
	assert_false(recipe.has("compatibility_override"),
		"no authored override — the pair is narrow-compatible in the ruled data")
	var verdict: Dictionary = SkillKeywords.compatible("intercept", "brace", keywords())
	assert_eq(String(verdict["basis"]), "narrow_shared",
		"intercept x brace: narrow-shared in the ported KEYWORDS data")
	assert_eq(verdict["keywords"], ["bracing"] as Array[String],
		"…through 'bracing', exactly as ruled")


# ------------------------------------------------------------- the happy path

func test_valid_roster_mutates_parents_consumed() -> void:
	var roster: Array = ready_roster()
	assert_eq(codes_of(SkillForge.validate_mutation(roster, iron_stance_recipe(), keywords())),
		[] as Array[String], "a mutation-ready roster validates clean")
	var mutated: Array[Dictionary] = SkillForge.apply_mutation(
		roster, iron_stance_recipe(), keywords())
	assert_eq(mutated.size(), 2, "3 rows -> 2: two parents consumed, one result granted")
	assert_eq(String(mutated[0].get("key", "")), "dance", "bystander survives, order preserved")
	assert_eq(int(mutated[0].get("level", 0)), 2, "bystander level untouched")
	assert_eq(String(mutated[1].get("key", "")), "iron_stance", "result appended last")
	assert_eq(int(mutated[1].get("level", 0)), 1, "granted at the recipe level (Lv1)")
	assert_eq(SkillForge._granted_level(mutated, "intercept"), 0, "intercept CONSUMED")
	assert_eq(SkillForge._granted_level(mutated, "brace"), 0, "brace CONSUMED")


func test_overleveled_parents_still_mutate() -> void:
	# min_level is a floor, not an exact ask.
	var roster: Array = [{"key": "brace", "level": 5}, {"key": "intercept", "level": 6}]
	var mutated: Array[Dictionary] = SkillForge.apply_mutation(
		roster, iron_stance_recipe(), keywords())
	assert_eq(mutated.size(), 1, "both parents consumed even above the minimums")
	assert_eq(String(mutated[0].get("key", "")), "iron_stance", "only the result remains")


# ------------------------------------------------------------------ violations

func test_missing_parent_surfaces() -> void:
	var roster: Array = [{"key": "brace", "level": 3}, {"key": "dance", "level": 2}]
	var codes: Array[String] = codes_of(
		SkillForge.validate_mutation(roster, iron_stance_recipe(), keywords()))
	assert_true(codes.has("parent_missing"), "no intercept -> parent_missing, got %s" % str(codes))
	assert_false(codes.has("parent_underleveled"), "missing is missing, not underleveled")


func test_underleveled_parent_surfaces() -> void:
	var roster: Array = [{"key": "intercept", "level": 4}, {"key": "brace", "level": 3}]
	var codes: Array[String] = codes_of(
		SkillForge.validate_mutation(roster, iron_stance_recipe(), keywords()))
	assert_eq(codes, ["parent_underleveled"] as Array[String],
		"intercept Lv4 < recipe Lv5 -> exactly parent_underleveled")


func test_already_owned_result_surfaces() -> void:
	var roster: Array = ready_roster()
	roster.append({"key": "iron_stance", "level": 1})
	var codes: Array[String] = codes_of(
		SkillForge.validate_mutation(roster, iron_stance_recipe(), keywords()))
	assert_eq(codes, ["result_already_owned"] as Array[String],
		"owning the result already blocks the merge")


func test_all_violations_at_once() -> void:
	# Missing intercept + underleveled brace + result already owned: every
	# violation in ONE pass (the Creation idiom — never fail-fast).
	var roster: Array = [{"key": "brace", "level": 2}, {"key": "iron_stance", "level": 1}]
	var violations: Array[Dictionary] = SkillForge.validate_mutation(
		roster, iron_stance_recipe(), keywords())
	var codes: Array[String] = codes_of(violations)
	assert_eq(codes, ["parent_missing", "parent_underleveled", "result_already_owned"] as Array[String],
		"all three violations at once, deterministic order")
	for v: Dictionary in violations:
		assert_true(v.has("field") and v.has("message"), "each violation carries {code, field, message}")


func test_broad_only_parents_need_the_authored_override() -> void:
	# A synthetic recipe on the book's own GM-call pair: fire_ball x
	# frost_ball share only the broad 'magic' group — NOT auto-legal (G3).
	var recipe: Dictionary = {
		"key": "frostfire", "name": "Frostfire Ball",
		"parents": [{"key": "fire_ball", "min_level": 2}, {"key": "frost_ball", "min_level": 2}],
		"result": {"key": "frostfire_ball", "level": 1},
	}
	var roster: Array = [{"key": "fire_ball", "level": 3}, {"key": "frost_ball", "level": 3}]
	var codes: Array[String] = codes_of(SkillForge.validate_mutation(roster, recipe, keywords()))
	assert_eq(codes, ["parents_incompatible"] as Array[String],
		"broad-only parents are the GM-call tier, rejected by the engine")
	# The explicit authored override IS the recorded GM call — then it merges.
	recipe["compatibility_override"] = true
	assert_eq(codes_of(SkillForge.validate_mutation(roster, recipe, keywords())),
		[] as Array[String], "the authored compatibility_override clears the pair")


func test_malformed_recipe_is_rejected_loudly() -> void:
	var roster: Array = ready_roster()
	var one_parent: Dictionary = {"key": "x", "name": "X",
		"parents": [{"key": "brace", "min_level": 3}], "result": {"key": "y", "level": 1}}
	assert_eq(codes_of(SkillForge.validate_mutation(roster, one_parent, keywords())),
		["recipe_invalid"] as Array[String], "one parent is not a merge")
	var self_fuel: Dictionary = {"key": "x", "name": "X",
		"parents": [{"key": "intercept", "min_level": 5}, {"key": "brace", "min_level": 3}],
		"result": {"key": "brace", "level": 1}}
	assert_eq(codes_of(SkillForge.validate_mutation(roster, self_fuel, keywords())),
		["recipe_invalid"] as Array[String], "a result that is also a parent is malformed")
	assert_eq(codes_of(SkillForge.validate_mutation(roster, {}, keywords())).count("recipe_invalid"),
		2, "an empty recipe fails both parents and result shape")


# ----------------------------------------------------- purity + determinism

func test_apply_is_pure_and_deterministic() -> void:
	var roster: Array = ready_roster()
	var before: String = canon(roster)
	var first: Array[Dictionary] = SkillForge.apply_mutation(roster, iron_stance_recipe(), keywords())
	assert_eq(canon(roster), before, "apply never mutates the input array or its rows")
	# Mutating the OUTPUT never reaches back into the input (deep rows).
	first[0]["level"] = 99
	assert_eq(canon(roster), before, "output rows are fresh, not aliases")
	var second: Array[Dictionary] = SkillForge.apply_mutation(roster, iron_stance_recipe(), keywords())
	var third: Array[Dictionary] = SkillForge.apply_mutation(roster, iron_stance_recipe(), keywords())
	assert_eq(canon(second), canon(third), "same input -> identical output, every call")
	# Invalid mutation: [] and never a half-roster (Creation.assemble idiom).
	var invalid: Array[Dictionary] = SkillForge.apply_mutation(
		[{"key": "brace", "level": 3}], iron_stance_recipe(), keywords())
	assert_eq(invalid.size(), 0, "invalid apply returns [] (push_error), not a partial merge")


# ------------------------------------------------------- round-trip + the sim

func test_mutated_roster_round_trips_from_spec_and_hash() -> void:
	# The mutated array IS a from_spec "skills" grant list — including the
	# UNIMPLEMENTED iron_stance key: from_spec normalizes any {key, level} row
	# with no KNOWN_KEYS gate (simulation/combatant.gd; the mystery_move
	# precedent in test_loadout_skills). That is what makes owning a mutation
	# result legal as data before its content pass (R27).
	var mutated: Array[Dictionary] = SkillForge.apply_mutation(
		ready_roster(), iron_stance_recipe(), keywords())
	var sim: CombatSim = make_sim(77)
	var events: Array[Dictionary] = add_human(sim, "tank", {"team": "party", "skills": mutated})
	assert_no_event(events, "command_rejected", "a mutated roster is a legal combatant spec")
	var c: CombatantState = sim.combatants["tank"]
	assert_eq(c.skill_level("iron_stance"), 1, "iron_stance granted at Lv1 (state)")
	assert_eq(c.skill_level("dance"), 2, "bystander grant intact")
	assert_eq(c.skill_level("intercept"), 0, "consumed parent reads 0 = not known")
	assert_eq(c.skill_level("brace"), 0, "consumed parent reads 0 = not known")
	# State rows normalized to exactly {key, level} and serialization-stable.
	for row: Dictionary in c.skills:
		var row_keys: Array = row.keys()
		row_keys.sort()
		assert_eq(row_keys, ["key", "level"], "state rows normalized to {key, level}")
	var restored: CombatantState = CombatantState.from_dict(c.to_dict())
	assert_eq(restored.skill_level("iron_stance"), 1, "iron_stance survives to_dict/from_dict")
	assert_eq(canon(restored.to_dict().get("skills")), canon(c.to_dict().get("skills")),
		"grants re-serialize identically")
	var rsim: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(rsim.state_hash(), sim.state_hash(), "state hash stable across the full round-trip")


func test_mutation_then_spec_is_deterministic_end_to_end() -> void:
	# Same roster + recipe -> same mutated grants -> same sim hash, twice.
	var hashes: Array[String] = []
	for i: int in range(2):
		var mutated: Array[Dictionary] = SkillForge.apply_mutation(
			ready_roster(), iron_stance_recipe(), keywords())
		var sim: CombatSim = make_sim(4242)
		add_human(sim, "tank", {"team": "party", "skills": mutated})
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "mutation -> spec -> sim is deterministic")
