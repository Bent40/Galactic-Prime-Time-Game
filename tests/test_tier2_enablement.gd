extends SimTestBase
## Tier-2 enablement (decisions #34 + #35, owner 2026-08-18; tier proposal
## RULED — docs/design/skill-tiers-proposal.md). Proves the ruled tier
## machinery as data + forge operations:
##   * all 9 authored merge recipes (M1 regression + M2-M8 + M8's mirrored
##     animal-side twin) validate structurally, and each rejects under-leveled
##     parents per ITS OWN authored min-levels (Q5 — per-recipe, no global
##     convention);
##   * a full merge applies end-to-end for a new recipe (parents consumed,
##     result granted at L1, roster serializes through from_spec + sim hash);
##   * ABSORB (#35 Q2): validate + apply for each of the 4 ruled absorptions
##     and every authored fodder candidate — fodder consumed, survivor row
##     stamped {absorbed, cap: 8}, min-fodder rejection per pair, one absorb
##     ever, strictly-narrow compatibility, authored-candidate gate;
##   * Mod-Center offers (#35 Q1 route a): the_unseen validates through the
##     ordinary compatibility_override path; a narrow-shared pair authored as
##     an offer FAILS validate_offer (the authoring-error gate);
##   * Q3 structural openness: a hypothetical recipe with a tier-2 result
##     (iron_stance) as PARENT validates — nothing forbids tier-3;
##   * purity/determinism: inputs untouched, same inputs -> same outputs, and
##     the HONEST from_spec contract (roster-layer absorb annotations are
##     DROPPED at combat-spec time, the recruit_loadouts cap/cap_note
##     precedent — combat consumes only the grant).

var _keywords: Dictionary = {}
var _mutations: Dictionary = {}
var _absorptions: Dictionary = {}
var _offers: Dictionary = {}

## The 8 ruled tier-2 result keys (M1..M8 — the twin shares vice_grip).
const RESULT_KEYS: Array[String] = [
	"iron_stance", "counterscript", "predators_arc", "earthbreaker",
	"vivisection", "perfect_evasion", "combat_medic", "vice_grip",
]


func keywords() -> Dictionary:
	if _keywords.is_empty():
		_keywords = load_json("res://data/skill_keywords.json")
	return _keywords


func mutations() -> Dictionary:
	if _mutations.is_empty():
		_mutations = load_json("res://data/skill_mutations.json")
	return _mutations


func absorptions() -> Dictionary:
	if _absorptions.is_empty():
		_absorptions = load_json("res://data/skill_absorptions.json")
	return _absorptions


func offers() -> Dictionary:
	if _offers.is_empty():
		_offers = load_json("res://data/mod_center_offers.json")
	return _offers


func recipe_rows() -> Array:
	return mutations().get("mutations", []) as Array


func absorption_rows() -> Array:
	return absorptions().get("absorptions", []) as Array


func codes_of(violations: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for v: Dictionary in violations:
		out.append(String(v.get("code", "")))
	return out


func canon(value: Variant) -> String:
	return CombatSim.canonical_serialize(value)


## A roster owning every parent of a recipe at exactly its authored minimum.
func roster_for_recipe(recipe: Dictionary) -> Array:
	var out: Array = []
	for parent: Variant in recipe.get("parents", []) as Array:
		var p: Dictionary = parent
		out.append({"key": String(p["key"]), "level": int(p["min_level"])})
	return out


## A roster ready for an absorption: survivor at its minimum, a bystander,
## then the named fodder candidate at its authored minimum.
func roster_for_absorption(absorption: Dictionary, fodder_key: String) -> Array:
	var survivor: Dictionary = absorption["survivor"]
	var out: Array = [
		{"key": String(survivor["key"]), "level": int(survivor["min_level"])},
		{"key": "dance", "level": 2},
	]
	for cand: Variant in absorption.get("fodder", []) as Array:
		var c: Dictionary = cand
		if String(c["key"]) == fodder_key:
			out.append({"key": fodder_key, "level": int(c["min_fodder_level"])})
	return out


# ------------------------------------------------------- the 9 authored recipes

func test_all_authored_recipes_validate_structurally() -> void:
	# M1 regression + M2-M8 + the twin: 9 entries, and a roster at each
	# recipe's own exact minimums validates clean.
	var rows: Array = recipe_rows()
	assert_eq(rows.size(), 9, "9 authored recipes: M1 + the seven ruled tier-2 merges + M8's twin")
	for row: Variant in rows:
		var recipe: Dictionary = row
		var key := String(recipe.get("key", "?"))
		assert_eq(codes_of(SkillForge.validate_mutation(
			roster_for_recipe(recipe), recipe, keywords())), [] as Array[String],
			"recipe '%s' validates at its own authored minimums" % key)


func test_result_keys_are_the_ruled_tier2_set() -> void:
	var seen: Array[String] = []
	for row: Variant in recipe_rows():
		var result_key := String(((row as Dictionary).get("result", {}) as Dictionary).get("key", ""))
		if not seen.has(result_key):
			seen.append(result_key)
	seen.sort()
	var expected: Array[String] = RESULT_KEYS.duplicate()
	expected.sort()
	assert_eq(seen, expected, "distinct result keys = the 8 ruled tier-2 keys (twin shares vice_grip)")
	# The twin is the ONE sanctioned result-key duplication, and says so.
	var twin: Dictionary = SkillForge.find_recipe(mutations(), "vice_grip_animal")
	assert_false(twin.is_empty(), "M8's mirrored animal-side twin ships as its own recipe")
	assert_eq(String(twin.get("twin_of", "")), "vice_grip", "the twin declares twin_of vice_grip")
	assert_eq(String((twin.get("parents", []) as Array)[0].get("key", "")), "death_grip_jaws",
		"twin primary = jaws Lv5 (the mirrored roles)")
	assert_eq(int((twin.get("parents", []) as Array)[0].get("min_level", 0)), 5, "jaws Lv5")
	assert_eq(int((twin.get("parents", []) as Array)[1].get("min_level", 0)), 3, "hold Lv3")


func test_each_recipe_rejects_underleveled_parents_per_its_own_minimums() -> void:
	# Q5: min-levels are per-recipe authored values — each recipe enforces
	# ITS OWN numbers. Drop each parent to (min - 1) in turn.
	for row: Variant in recipe_rows():
		var recipe: Dictionary = row
		var key := String(recipe.get("key", "?"))
		var parents: Array = recipe.get("parents", [])
		for i: int in range(parents.size()):
			var roster: Array = roster_for_recipe(recipe)
			roster[i] = {"key": String((parents[i] as Dictionary)["key"]),
				"level": int((parents[i] as Dictionary)["min_level"]) - 1}
			var codes: Array[String] = codes_of(
				SkillForge.validate_mutation(roster, recipe, keywords()))
			assert_eq(codes, ["parent_underleveled"] as Array[String],
				"'%s' parent %d at min-1 -> exactly parent_underleveled" % [key, i])


func test_new_recipe_full_merge_end_to_end() -> void:
	# M5 Vivisection: parents consumed, result granted at L1, the mutated
	# roster is a legal from_spec grant list (the result key has NO
	# skills.json row yet — DATA-declared only, the proven interim pattern),
	# and the sim round-trips hash-stable.
	var recipe: Dictionary = SkillForge.find_recipe(mutations(), "vivisection")
	assert_false(recipe.is_empty(), "the vivisection recipe ships")
	var roster: Array = [
		{"key": "slice_n_dice", "level": 5},
		{"key": "dance", "level": 2},
		{"key": "thousand_cuts", "level": 3},
	]
	var mutated: Array[Dictionary] = SkillForge.apply_mutation(roster, recipe, keywords())
	assert_eq(mutated.size(), 2, "3 rows -> 2: both parents consumed, result granted")
	assert_eq(String(mutated[0].get("key", "")), "dance", "bystander survives, order preserved")
	assert_eq(String(mutated[1].get("key", "")), "vivisection", "result appended last")
	assert_eq(int(mutated[1].get("level", 0)), 1, "the merge arrives at L1")
	var sim: CombatSim = make_sim(88)
	var events: Array[Dictionary] = add_human(sim, "shredder", {"team": "party", "skills": mutated})
	assert_no_event(events, "command_rejected", "an unimplemented tier-2 key is legal grant data")
	assert_eq((sim.combatants["shredder"] as CombatantState).skill_level("vivisection"), 1,
		"vivisection granted at Lv1 in state")
	var rsim: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(rsim.state_hash(), sim.state_hash(), "hash stable across the round-trip")


func test_tier3_structural_openness() -> void:
	# Q3: tier-3 merges WILL exist — NOTHING in the engine may forbid a
	# tier-2 result key as a future recipe PARENT. A hypothetical recipe
	# with iron_stance (the shipped tier-2 result) as primary parent
	# validates structurally today.
	var hypothetical: Dictionary = {
		"key": "t3_hypothetical", "name": "T3 Hypothetical",
		"parents": [
			{"key": "iron_stance", "min_level": 5},
			{"key": "brace", "min_level": 3},
		],
		"result": {"key": "t3_result", "level": 1},
	}
	var roster: Array = [{"key": "iron_stance", "level": 5}, {"key": "brace", "level": 3}]
	assert_eq(codes_of(SkillForge.validate_mutation(roster, hypothetical, keywords())),
		[] as Array[String],
		"a tier-2 result key is a legal recipe parent — the schema stays tier-3-open (Q3)")
	var merged: Array[Dictionary] = SkillForge.apply_mutation(roster, hypothetical, keywords())
	assert_eq(merged.size(), 1, "the hypothetical t3 merge applies")
	assert_eq(String(merged[0].get("key", "")), "t3_result", "t3 result granted")


# ------------------------------------------------------------------ absorptions

func test_absorb_validate_and_apply_all_four() -> void:
	# Every ruled absorption x every authored fodder candidate: validates at
	# the authored minimums, applies pure — fodder consumed, survivor row
	# stamped {absorbed: fodder, cap: 8}, level and bystander untouched.
	var rows: Array = absorption_rows()
	assert_eq(rows.size(), 4, "the 4 ruled absorptions ship")
	for row: Variant in rows:
		var absorption: Dictionary = row
		var survivor_key := String((absorption["survivor"] as Dictionary)["key"])
		for cand: Variant in absorption.get("fodder", []) as Array:
			var fodder_key := String((cand as Dictionary)["key"])
			var roster: Array = roster_for_absorption(absorption, fodder_key)
			assert_eq(codes_of(SkillForge.validate_absorption(
				roster, absorption, fodder_key, keywords())), [] as Array[String],
				"%s absorbing %s validates at the authored minimums" % [survivor_key, fodder_key])
			var absorbed: Array[Dictionary] = SkillForge.apply_absorption(
				roster, absorption, fodder_key, keywords())
			assert_eq(absorbed.size(), 2, "%s: fodder row consumed" % survivor_key)
			assert_eq(String(absorbed[0].get("key", "")), survivor_key,
				"survivor survives in place, order preserved")
			assert_eq(int(absorbed[0].get("level", 0)),
				int((absorption["survivor"] as Dictionary)["min_level"]),
				"survivor LEVEL untouched — the unlock is the band, not free levels (Q2 flat)")
			assert_eq(String(absorbed[0].get("absorbed", "")), fodder_key,
				"survivor row records what it absorbed")
			assert_eq(int(absorbed[0].get("cap", 0)), 8, "cap raised to 8 — the flat L6-8 band")
			assert_eq(String(absorbed[1].get("key", "")), "dance", "bystander untouched")
			assert_eq(SkillForge._granted_level(absorbed, fodder_key), 0, "fodder gone")


func test_absorb_min_fodder_and_survivor_level_rejections() -> void:
	# The per-pair authored minimum is the #35 Q2 fairness gate — each pair
	# enforces ITS OWN number; the survivor gate is the past-5 moment.
	for row: Variant in absorption_rows():
		var absorption: Dictionary = row
		var survivor_key := String((absorption["survivor"] as Dictionary)["key"])
		for cand: Variant in absorption.get("fodder", []) as Array:
			var fodder_key := String((cand as Dictionary)["key"])
			var roster: Array = roster_for_absorption(absorption, fodder_key)
			roster[2] = {"key": fodder_key, "level": int((cand as Dictionary)["min_fodder_level"]) - 1}
			assert_eq(codes_of(SkillForge.validate_absorption(
				roster, absorption, fodder_key, keywords())),
				["fodder_underleveled"] as Array[String],
				"%s x %s at min-1 -> exactly fodder_underleveled (its own minimum)" % [
					survivor_key, fodder_key])
		var first_fodder := String((absorption["fodder"] as Array)[0].get("key", ""))
		var r2: Array = roster_for_absorption(absorption, first_fodder)
		r2[0] = {"key": survivor_key, "level": int((absorption["survivor"] as Dictionary)["min_level"]) - 1}
		assert_eq(codes_of(SkillForge.validate_absorption(r2, absorption, first_fodder, keywords())),
			["survivor_underleveled"] as Array[String],
			"%s below its past-5 moment -> survivor_underleveled" % survivor_key)


func test_absorb_is_once_ever() -> void:
	# One absorb per survivor: after absorbing candidate A, candidate B is
	# rejected — the flat band unlocks once (#35 Q2).
	var absorption: Dictionary = SkillForge.find_absorption(absorptions(), "controlled_sweep")
	assert_false(absorption.is_empty(), "the controlled_sweep absorption ships")
	var cands: Array = absorption["fodder"]
	assert_eq(cands.size(), 2, "controlled_sweep has two authored candidates")
	var key_a := String((cands[0] as Dictionary)["key"])
	var key_b := String((cands[1] as Dictionary)["key"])
	var roster: Array = [
		{"key": "controlled_sweep", "level": 5},
		{"key": key_a, "level": int((cands[0] as Dictionary)["min_fodder_level"])},
		{"key": key_b, "level": int((cands[1] as Dictionary)["min_fodder_level"])},
	]
	var once: Array[Dictionary] = SkillForge.apply_absorption(roster, absorption, key_a, keywords())
	assert_eq(once.size(), 2, "first absorb consumed candidate A")
	var codes: Array[String] = codes_of(
		SkillForge.validate_absorption(once, absorption, key_b, keywords()))
	assert_eq(codes, ["survivor_already_absorbed"] as Array[String],
		"a second absorb is rejected — the band unlocks once")


func test_absorb_narrow_compat_and_candidate_gates() -> void:
	# Strictly narrow: a synthetic broad-only pair is rejected with NO
	# override tier (broad-only is Mod-Center offer scope) — and a
	# narrow-compatible skill that is NOT an authored candidate is rejected
	# by the authoring gate, which is a different violation.
	var broad_only: Dictionary = {
		"key": "shockwave",
		"survivor": {"key": "shockwave", "min_level": 5},
		"fodder": [{"key": "strong_strike", "min_fodder_level": 3}],
		"unlock": {"cap": 8},
	}
	var roster: Array = [{"key": "shockwave", "level": 5}, {"key": "strong_strike", "level": 3}]
	assert_eq(codes_of(SkillForge.validate_absorption(roster, broad_only, "strong_strike", keywords())),
		["pair_incompatible"] as Array[String],
		"shockwave x strong_strike share only the broad 'strikes' — absorbs have no override tier")
	# decapitate IS narrow-compatible with controlled_sweep (blade) but is
	# not an authored candidate — the authored-candidate gate fires instead.
	var real: Dictionary = SkillForge.find_absorption(absorptions(), "controlled_sweep")
	var verdict: Dictionary = SkillKeywords.compatible("controlled_sweep", "decapitate", keywords())
	assert_true(bool(verdict["compatible"]), "precondition: the pair IS narrow-compatible")
	var r2: Array = [{"key": "controlled_sweep", "level": 5}, {"key": "decapitate", "level": 5}]
	assert_eq(codes_of(SkillForge.validate_absorption(r2, real, "decapitate", keywords())),
		["fodder_not_candidate"] as Array[String],
		"compatibility alone is not enough — absorb pairs are AUTHORED (per-pair minimums)")


func test_absorbed_roster_serializes_and_from_spec_is_honest() -> void:
	# The absorbed roster is plain JSON data (round-trips canonically), and
	# the from_spec contract is pinned HONESTLY: combat-spec normalization
	# DROPS the roster-layer annotations (absorbed/cap — the loadout
	# cap/cap_note precedent) while the grant itself survives.
	var absorption: Dictionary = SkillForge.find_absorption(absorptions(), "slip_through")
	var roster: Array = roster_for_absorption(absorption, "tactical_roll")
	var absorbed: Array[Dictionary] = SkillForge.apply_absorption(
		roster, absorption, "tactical_roll", keywords())
	var parsed: Variant = JSON.parse_string(JSON.stringify(absorbed))
	assert_eq(canon(parsed), canon(absorbed), "the absorbed roster round-trips through JSON")
	var sim: CombatSim = make_sim(99)
	var events: Array[Dictionary] = add_human(sim, "dasher", {"team": "party", "skills": absorbed})
	assert_no_event(events, "command_rejected", "an absorbed roster is a legal combatant spec")
	var c: CombatantState = sim.combatants["dasher"]
	assert_eq(c.skill_level("slip_through"), 5, "survivor grant survives at its level")
	assert_eq(c.skill_level("tactical_roll"), 0, "consumed fodder reads 0 = not known")
	for state_row: Dictionary in c.skills:
		var row_keys: Array = state_row.keys()
		row_keys.sort()
		assert_eq(row_keys, ["key", "level"],
			"combat rows normalized to {key, level} — absorbed/cap are ROSTER-layer data, dropped by design")
	var rsim: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(rsim.state_hash(), sim.state_hash(), "hash stable across the round-trip")


func test_absorb_apply_is_pure_and_deterministic() -> void:
	var absorption: Dictionary = SkillForge.find_absorption(absorptions(), "pressure_strike")
	var roster: Array = roster_for_absorption(absorption, "counter_surge")
	var before: String = canon(roster)
	var first: Array[Dictionary] = SkillForge.apply_absorption(
		roster, absorption, "counter_surge", keywords())
	assert_eq(canon(roster), before, "apply never mutates the input array or its rows")
	first[0]["level"] = 99
	assert_eq(canon(roster), before, "output rows are fresh, not aliases")
	var second: Array[Dictionary] = SkillForge.apply_absorption(
		roster, absorption, "counter_surge", keywords())
	var third: Array[Dictionary] = SkillForge.apply_absorption(
		roster, absorption, "counter_surge", keywords())
	assert_eq(canon(second), canon(third), "same inputs -> identical output, every call")
	var invalid: Array[Dictionary] = SkillForge.apply_absorption(
		[{"key": "pressure_strike", "level": 5}], absorption, "counter_surge", keywords())
	assert_eq(invalid.size(), 0, "invalid apply returns [] (push_error), never a half-roster")


# ------------------------------------------------------------ Mod-Center offers

func test_offer_the_unseen_validates_via_the_override_path() -> void:
	# Q1 route (a): an offer is structurally a mutation recipe carrying the
	# authored compatibility_override — the EXISTING override machinery is
	# the redemption path, engine-deep (no offer-specific merge code).
	var offer: Dictionary = SkillForge.find_offer(offers(), "the_unseen")
	assert_false(offer.is_empty(), "the_unseen ships in data/mod_center_offers.json")
	assert_true(bool(offer.get("provisional", false)), "the_unseen is PROVISIONAL (awaiting blessing)")
	assert_eq(codes_of(SkillForge.validate_offer(offer, keywords())), [] as Array[String],
		"the_unseen passes the authoring gate (broad-only pair + override)")
	var roster: Array = [{"key": "camouflage", "level": 5}, {"key": "nightlurking", "level": 3}]
	assert_eq(codes_of(SkillForge.validate_mutation(roster, offer, keywords())),
		[] as Array[String], "the offer validates against a ready roster via the override path")
	var merged: Array[Dictionary] = SkillForge.apply_mutation(roster, offer, keywords())
	assert_eq(merged.size(), 1, "both parents consumed")
	assert_eq(String(merged[0].get("key", "")), "the_unseen", "the_unseen granted")
	assert_eq(int(merged[0].get("level", 0)), 1, "…at L1")
	# The override is load-bearing: the same offer WITHOUT it is rejected.
	var stripped: Dictionary = offer.duplicate(true)
	stripped.erase("compatibility_override")
	assert_eq(codes_of(SkillForge.validate_mutation(roster, stripped, keywords())),
		["parents_incompatible"] as Array[String],
		"without the authored override the broad-only pair is illegal (G3)")


func test_all_shipped_offers_are_broad_only_and_provisional() -> void:
	var rows: Array = offers().get("offers", [])
	assert_eq(rows.size(), 3, "the three data-supported candidates ship (#35 Q1)")
	for row: Variant in rows:
		var offer: Dictionary = row
		var key := String(offer.get("key", "?"))
		assert_eq(codes_of(SkillForge.validate_offer(offer, keywords())), [] as Array[String],
			"offer '%s' passes the authoring gate" % key)
		assert_true(bool(offer.get("provisional", false)),
			"offer '%s' is flagged PROVISIONAL — result names await the owner" % key)
		var parents: Array = offer.get("parents", [])
		var verdict: Dictionary = SkillKeywords.compatible(
			String((parents[0] as Dictionary)["key"]),
			String((parents[1] as Dictionary)["key"]), keywords())
		assert_eq(String(verdict["basis"]), "broad_only",
			"offer '%s' pair is genuinely broad-only in the ruled data" % key)


func test_narrow_shared_pair_as_offer_fails_the_authoring_gate() -> void:
	# An offer on a narrow-shared pair is an authoring ERROR — that pair is a
	# normal recipe. The gate rejects it even WITH the override flag set.
	var bad: Dictionary = {
		"key": "bad_offer", "name": "Bad Offer",
		"parents": [{"key": "intercept", "min_level": 5}, {"key": "brace", "min_level": 3}],
		"shared_broad": ["survival"],
		"compatibility_override": true,
		"result": {"key": "bad_result", "level": 1},
	}
	assert_eq(codes_of(SkillForge.validate_offer(bad, keywords())),
		["offer_not_broad_only"] as Array[String],
		"intercept x brace share the narrow 'bracing' — a normal recipe, not an offer")
	# A pair sharing NOTHING is not offerable either.
	var none: Dictionary = bad.duplicate(true)
	(none["parents"] as Array)[1] = {"key": "fire_ball", "min_level": 3}
	assert_eq(codes_of(SkillForge.validate_offer(none, keywords())),
		["offer_not_broad_only"] as Array[String],
		"intercept x fire_ball share no taxonomy keyword — not offerable")
	# And a missing override is an authoring error too.
	var no_override: Dictionary = SkillForge.find_offer(offers(), "phantom_grasp").duplicate(true)
	no_override.erase("compatibility_override")
	assert_eq(codes_of(SkillForge.validate_offer(no_override, keywords())),
		["offer_invalid"] as Array[String],
		"an offer must carry compatibility_override: true — it IS the recorded GM call")
