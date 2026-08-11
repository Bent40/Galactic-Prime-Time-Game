class_name SkillForge
extends RefCounted
## The Skill Gemstone mutation ENGINE (G6 owner ruling 2026-07-23 round 3;
## book §4.5; rules-addendum R27). Recipes are authored data
## (data/skill_mutations.json); this is the pure machinery: validate_mutation()
## returns EVERY violation at once (Creation-style, never fail-fast) and
## apply_mutation() is a pure function on a skills array — parents CONSUMED,
## result granted at the recipe level.
##
## ROSTER SHAPE: the CombatantState.from_spec grant rows — [{"key": String,
## "level": int, ...}]. Validation is against KEYS + LEVELS ONLY; SkillBook
## implementation is deliberately NOT required: from_spec normalizes any
## {key, level} row with no KNOWN_KEYS gate (simulation/combatant.gd — proven
## by test_loadout_skills' un-catalogued "mystery_move" grant), so a roster
## can own an unimplemented skill as data. That is load-bearing here: neither
## intercept (G6-approved, content pass pending) nor iron_stance (the mutation
## result) is implemented today. NOTE the seed-data files (recruit_loadouts
## _meta) restrict THEIR rows to implemented keys — an authoring policy, not
## an engine constraint. Duplicate keys are already illegal upstream
## (Creation / validate_seeds); the first row with a key is the grant read,
## mirroring CombatantState.skill_level().
##
## RECIPE SHAPE (data/skill_mutations.json "mutations" rows):
##   { "key": String, "name": String,
##     "parents": [{"key": String, "min_level": int}] (>= 2, distinct),
##     "result": {"key": String, "level": int} (not a parent key),
##     "note": String, "compatibility_override": bool (optional) }
## Parents must pairwise share a NARROW keyword (the G3 rule via
## SkillKeywords.compatible); a recipe whose parents overlap only BROADLY is
## the GM-call tier and needs the explicit authored compatibility_override —
## broad_only is machine-readable, never auto-legal. No shipped recipe needs
## it: Intercept x Brace share the narrow keyword 'bracing' (book §4.5
## canonical example).
##
## ECONOMY: the Gemstone COST (compendium Modification Center: 1 Bronze) is
## KAN-7 scope — recorded in the data note, deliberately unpriced here.
## Usable by future progression AND creation-time validation; creation.gd is
## deliberately untouched (no creation surface consumes mutations yet).

const CODE_RECIPE_INVALID: String = "recipe_invalid"
const CODE_PARENT_MISSING: String = "parent_missing"
const CODE_PARENT_UNDERLEVELED: String = "parent_underleveled"
const CODE_PARENTS_INCOMPATIBLE: String = "parents_incompatible"
const CODE_RESULT_ALREADY_OWNED: String = "result_already_owned"


## Convenience: the recipe with the given key from a parsed
## data/skill_mutations.json doc; {} when absent.
static func find_recipe(mutations_doc: Dictionary, recipe_key: String) -> Dictionary:
	for row: Variant in mutations_doc.get("mutations", []) as Array:
		if row is Dictionary and String((row as Dictionary).get("key", "")) == recipe_key:
			return row
	return {}


## Validates a mutation against a roster skills array. Returns [] when legal,
## else one {code, field, message} per violation — ALL violations at once, in
## a deterministic order (recipe shape first; then per-parent in recipe order;
## then compatibility; then result). A malformed recipe short-circuits to its
## shape violations alone: roster checks against a garbage recipe would only
## echo the root cause. Never mutates its inputs.
static func validate_mutation(roster_skills: Array, recipe: Dictionary,
		keywords_doc: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# --- recipe shape (authored data — validate_seeds checks it too; this
	# keeps the engine honest against a hand-built recipe) ------------------
	var parents: Variant = recipe.get("parents")
	var parent_keys: Array[String] = []
	if not (parents is Array) or (parents as Array).size() < 2:
		out.append(_violation(CODE_RECIPE_INVALID, "parents",
			"recipe parents must be a list of >= 2 {key, min_level} rows"))
	else:
		for i: int in range((parents as Array).size()):
			var row_v: Variant = (parents as Array)[i]
			var key := String((row_v as Dictionary).get("key", "")) if row_v is Dictionary else ""
			var min_level: Variant = _as_int((row_v as Dictionary).get("min_level")) if row_v is Dictionary else null
			if key == "" or min_level == null or int(min_level) < 1:
				out.append(_violation(CODE_RECIPE_INVALID, "parents[%d]" % i,
					"parent rows must be {key: non-empty String, min_level: int >= 1}"))
			elif parent_keys.has(key):
				out.append(_violation(CODE_RECIPE_INVALID, "parents[%d]" % i,
					"duplicate parent key '%s'" % key))
			else:
				parent_keys.append(key)
	var result: Variant = recipe.get("result")
	var result_key := String((result as Dictionary).get("key", "")) if result is Dictionary else ""
	var result_level: Variant = _as_int((result as Dictionary).get("level")) if result is Dictionary else null
	if result_key == "" or result_level == null or int(result_level) < 1:
		out.append(_violation(CODE_RECIPE_INVALID, "result",
			"recipe result must be {key: non-empty String, level: int >= 1}"))
	elif parent_keys.has(result_key):
		out.append(_violation(CODE_RECIPE_INVALID, "result",
			"result key '%s' is also a parent — a mutation may not yield its own fuel" % result_key))
	if not out.is_empty():
		return out

	# --- parents present at >= min_level (G6: Intercept Lv5 + Brace Lv3) ----
	for i: int in range((parents as Array).size()):
		var parent: Dictionary = (parents as Array)[i]
		var key := String(parent["key"])
		var min_level: int = int(_as_int(parent["min_level"]))
		var owned: int = _granted_level(roster_skills, key)
		if owned == 0:
			out.append(_violation(CODE_PARENT_MISSING, "parents[%d]" % i,
				"parent '%s' is not on the roster (both parents must be owned — G6, book §4.5)" % key))
		elif owned < min_level:
			out.append(_violation(CODE_PARENT_UNDERLEVELED, "parents[%d]" % i,
				"parent '%s' owned at Lv%d, recipe needs >= Lv%d (G6)" % [key, owned, min_level]))

	# --- G3 compatibility: parents pairwise share a NARROW keyword ----------
	if not bool(recipe.get("compatibility_override", false)):
		for i: int in range(parent_keys.size()):
			for j: int in range(i + 1, parent_keys.size()):
				var verdict: Dictionary = SkillKeywords.compatible(
					parent_keys[i], parent_keys[j], keywords_doc)
				if not bool(verdict["compatible"]):
					out.append(_violation(CODE_PARENTS_INCOMPATIBLE, "parents",
						"'%s' x '%s' share no NARROW keyword (basis: %s, shared: %s) — G3: broad-only overlap is the GM-call tier, legal only with an authored compatibility_override" % [
							parent_keys[i], parent_keys[j], String(verdict["basis"]),
							str(verdict["keywords"])]))

	# --- result not already owned -------------------------------------------
	if _granted_level(roster_skills, result_key) > 0:
		out.append(_violation(CODE_RESULT_ALREADY_OWNED, "result",
			"result '%s' is already on the roster" % result_key))

	return out


## Applies a VALID mutation: a NEW skills array with both parent rows removed
## (consumed — G6/book §4.5: "both parents are consumed") and the result
## appended as {key, level} at the recipe level. PURE: the input array and its
## rows are never touched (non-parent rows are deep-duplicated, order
## preserved). On an invalid mutation: push_error + [] — never a half-roster
## (Creation.assemble precedent; a valid apply always yields >= 1 row, so []
## is unambiguous). Same inputs -> identical output, every call.
static func apply_mutation(roster_skills: Array, recipe: Dictionary,
		keywords_doc: Dictionary) -> Array[Dictionary]:
	var violations: Array[Dictionary] = validate_mutation(roster_skills, recipe, keywords_doc)
	if not violations.is_empty():
		var codes: Array[String] = []
		for v: Dictionary in violations:
			codes.append(String(v["code"]))
		push_error("SkillForge.apply_mutation: invalid mutation (%s)" % ", ".join(codes))
		return []
	var consumed: Array[String] = []
	for parent: Variant in recipe["parents"] as Array:
		consumed.append(String((parent as Dictionary)["key"]))
	var out: Array[Dictionary] = []
	for row_v: Variant in roster_skills:
		var row: Dictionary = row_v
		if consumed.has(String(row.get("key", ""))):
			continue
		out.append(row.duplicate(true))
	var result: Dictionary = recipe["result"]
	out.append({"key": String(result["key"]), "level": int(_as_int(result["level"]))})
	return out


static func _violation(code: String, field: String, message: String) -> Dictionary:
	return {"code": code, "field": field, "message": message}


## The granted level for a key on a roster skills array — first row wins
## (mirrors CombatantState.skill_level); 0 = not owned.
static func _granted_level(roster_skills: Array, key: String) -> int:
	for row_v: Variant in roster_skills:
		if row_v is Dictionary and String((row_v as Dictionary).get("key", "")) == key:
			return int((row_v as Dictionary).get("level", 1))
	return 0


## int for ints and whole floats (JSON numbers parse as floats), null
## otherwise — the Creation._as_int idiom.
static func _as_int(value: Variant) -> Variant:
	if value is int:
		return value
	if value is float and float(value) == floorf(float(value)):
		return int(value)
	return null
