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
## can own an unimplemented skill as data. (Batch B: intercept AND iron_stance
## are now IMPLEMENTED — the retarget_guard archetype — so the shipped recipe
## yields a REAL result; the keys-and-levels-only contract stays, unchanged,
## for future recipes whose results land before their content pass.) NOTE the
## seed-data files (recruit_loadouts _meta) restrict THEIR rows to implemented
## keys — an authoring policy, not an engine constraint. Duplicate keys are
## already illegal upstream (Creation / validate_seeds); the first row with a
## key is the grant read, mirroring CombatantState.skill_level().
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
##
## TIER-2 ENABLEMENT (decisions #34 + #35, owner 2026-08-18) adds two more
## pure operations beside the merge:
##
## ABSORB (data/skill_absorptions.json; #35 Q2): consume ONE narrow-compatible
## FODDER skill to FLAT-unlock the SURVIVOR's L6-8 band — the survivor keeps
## its identity. Gates (validate_absorption, all-violations-at-once): survivor
## owned at its authored min_level (5 — the past-5 moment), fodder owned at
## its authored PER-PAIR min_fodder_level (the #35 fairness rationale: higher
## where the fodder is stat-cheap), fodder among the entry's authored
## candidates, pair narrow-compatible (STRICT — absorbs have NO override
## tier; broad-only pairs are Mod-Center offer scope), survivor not already
## absorbed (one absorb per survivor, ever). apply_absorption removes the
## fodder row and stamps the survivor row {absorbed: fodder_key, cap: 8}.
## HONESTY NOTE on the annotations: those are ROSTER-layer bookkeeping (the
## recruit_loadouts cap/cap_note precedent) — CombatantState.from_spec
## normalizes combat rows to {key, level} and DROPS them by design; combat
## consumes only the grant, progression data carries the absorb record.
## Leveling the unlocked band is KAN-7 pricing scope.
##
## MOD-CENTER OFFERS (data/mod_center_offers.json; #35 Q1 route a): authored
## special offers on BROAD-ONLY pairs — an offer row is structurally a
## mutation recipe carrying compatibility_override: true (the recorded GM
## call), so a roster-gated redemption validates through the ordinary
## validate_mutation override path, no new machinery. validate_offer is the
## AUTHORING gate: an offer whose parents share a NARROW keyword is an
## authoring error (that pair is a normal recipe), and a no-share pair is not
## offerable at all — mirrored data-side by validate_seeds.
##
## Q3 OPENNESS (tier-3): nothing here restricts a recipe PARENT to tier-1
## keys — a tier-2 result key (e.g. iron_stance) is a legal future parent;
## validation is keys + levels against the roster, whatever the key's tier.

const CODE_RECIPE_INVALID: String = "recipe_invalid"
const CODE_PARENT_MISSING: String = "parent_missing"
const CODE_PARENT_UNDERLEVELED: String = "parent_underleveled"
const CODE_PARENTS_INCOMPATIBLE: String = "parents_incompatible"
const CODE_RESULT_ALREADY_OWNED: String = "result_already_owned"

const CODE_ABSORPTION_INVALID: String = "absorption_invalid"
const CODE_FODDER_NOT_CANDIDATE: String = "fodder_not_candidate"
const CODE_SURVIVOR_MISSING: String = "survivor_missing"
const CODE_SURVIVOR_UNDERLEVELED: String = "survivor_underleveled"
const CODE_FODDER_MISSING: String = "fodder_missing"
const CODE_FODDER_UNDERLEVELED: String = "fodder_underleveled"
const CODE_PAIR_INCOMPATIBLE: String = "pair_incompatible"
const CODE_SURVIVOR_ALREADY_ABSORBED: String = "survivor_already_absorbed"

const CODE_OFFER_INVALID: String = "offer_invalid"
const CODE_OFFER_NOT_BROAD_ONLY: String = "offer_not_broad_only"

## The ruled flat absorb band: an absorbed survivor's cap (L6-8 — #35 Q2).
const ABSORB_CAP: int = 8


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


# ------------------------------------------------------------------- absorbs

## Convenience: the absorption entry for the given survivor key from a parsed
## data/skill_absorptions.json doc; {} when absent.
static func find_absorption(absorptions_doc: Dictionary, survivor_key: String) -> Dictionary:
	for row: Variant in absorptions_doc.get("absorptions", []) as Array:
		if row is Dictionary and String((row as Dictionary).get("key", "")) == survivor_key:
			return row
	return {}


## Validates an absorption (#35 Q2) against a roster skills array: the named
## fodder candidate is consumed to flat-unlock the survivor's L6-8 band.
## Returns [] when legal, else one {code, field, message} per violation — ALL
## violations at once, deterministic order (entry shape first; then fodder
## candidacy; then survivor / fodder presence + levels in that order; then
## narrow compatibility; then the one-absorb-ever gate). A malformed entry
## short-circuits to its shape violations alone (the validate_mutation
## idiom). Never mutates its inputs.
static func validate_absorption(roster_skills: Array, absorption: Dictionary,
		fodder_key: String, keywords_doc: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# --- entry shape (authored data — validate_seeds checks it too) ---------
	var survivor: Variant = absorption.get("survivor")
	var survivor_key := String((survivor as Dictionary).get("key", "")) if survivor is Dictionary else ""
	var survivor_min: Variant = _as_int((survivor as Dictionary).get("min_level")) if survivor is Dictionary else null
	if survivor_key == "" or survivor_min == null or int(survivor_min) < 1:
		out.append(_violation(CODE_ABSORPTION_INVALID, "survivor",
			"absorption survivor must be {key: non-empty String, min_level: int >= 1}"))
	var candidates: Variant = absorption.get("fodder")
	var candidate_keys: Array[String] = []
	var fodder_min: Variant = null
	if not (candidates is Array) or (candidates as Array).is_empty():
		out.append(_violation(CODE_ABSORPTION_INVALID, "fodder",
			"absorption fodder must be a list of >= 1 {key, min_fodder_level} rows"))
	else:
		for i: int in range((candidates as Array).size()):
			var row_v: Variant = (candidates as Array)[i]
			var key := String((row_v as Dictionary).get("key", "")) if row_v is Dictionary else ""
			var min_level: Variant = _as_int((row_v as Dictionary).get("min_fodder_level")) if row_v is Dictionary else null
			if key == "" or min_level == null or int(min_level) < 1:
				out.append(_violation(CODE_ABSORPTION_INVALID, "fodder[%d]" % i,
					"fodder rows must be {key: non-empty String, min_fodder_level: int >= 1}"))
			elif key == survivor_key:
				out.append(_violation(CODE_ABSORPTION_INVALID, "fodder[%d]" % i,
					"a skill cannot absorb itself ('%s')" % key))
			elif candidate_keys.has(key):
				out.append(_violation(CODE_ABSORPTION_INVALID, "fodder[%d]" % i,
					"duplicate fodder candidate '%s'" % key))
			else:
				candidate_keys.append(key)
				if key == fodder_key:
					fodder_min = min_level
	if not out.is_empty():
		return out

	# --- the chosen fodder must be an AUTHORED candidate (per-pair minimums
	# exist only for authored pairs — #35 Q2) --------------------------------
	if fodder_min == null:
		out.append(_violation(CODE_FODDER_NOT_CANDIDATE, "fodder",
			"'%s' is not an authored fodder candidate for '%s' (authored: %s)" % [
				fodder_key, survivor_key, str(candidate_keys)]))
		return out

	# --- survivor at its past-5 moment; fodder at its per-pair minimum ------
	var survivor_owned: int = _granted_level(roster_skills, survivor_key)
	if survivor_owned == 0:
		out.append(_violation(CODE_SURVIVOR_MISSING, "survivor",
			"survivor '%s' is not on the roster" % survivor_key))
	elif survivor_owned < int(survivor_min):
		out.append(_violation(CODE_SURVIVOR_UNDERLEVELED, "survivor",
			"survivor '%s' owned at Lv%d, absorption needs >= Lv%d (the past-5 moment)" % [
				survivor_key, survivor_owned, int(survivor_min)]))
	var fodder_owned: int = _granted_level(roster_skills, fodder_key)
	if fodder_owned == 0:
		out.append(_violation(CODE_FODDER_MISSING, "fodder",
			"fodder '%s' is not on the roster" % fodder_key))
	elif fodder_owned < int(fodder_min):
		out.append(_violation(CODE_FODDER_UNDERLEVELED, "fodder",
			"fodder '%s' owned at Lv%d, this pair's authored minimum is Lv%d (#35 Q2 fairness gate)" % [
				fodder_key, fodder_owned, int(fodder_min)]))

	# --- STRICT narrow compatibility — absorbs have no override tier --------
	var verdict: Dictionary = SkillKeywords.compatible(survivor_key, fodder_key, keywords_doc)
	if not bool(verdict["compatible"]):
		out.append(_violation(CODE_PAIR_INCOMPATIBLE, "fodder",
			"'%s' x '%s' share no NARROW keyword (basis: %s) — absorb legality is strictly narrow (G3); broad-only pairs are Mod-Center offer scope, never absorbs" % [
				survivor_key, fodder_key, String(verdict["basis"])]))

	# --- one absorb per survivor, ever (the flat band unlocks once) ---------
	var survivor_row: Dictionary = _row_for(roster_skills, survivor_key)
	if survivor_row.has("absorbed"):
		out.append(_violation(CODE_SURVIVOR_ALREADY_ABSORBED, "survivor",
			"survivor '%s' already absorbed '%s' — the L6-8 band unlocks once (#35 Q2)" % [
				survivor_key, String(survivor_row["absorbed"])]))

	return out


## Applies a VALID absorption: a NEW skills array with the fodder row removed
## (consumed) and the survivor row stamped {absorbed: fodder_key, cap:
## ABSORB_CAP} — level untouched, other rows deep-duplicated, order
## preserved. PURE: inputs never touched; same inputs -> identical output.
## The stamps are ROSTER-layer annotations (recruit_loadouts cap/cap_note
## precedent): CombatantState.from_spec drops them by design — see the class
## doc. On an invalid absorption: push_error + [] — never a half-roster.
static func apply_absorption(roster_skills: Array, absorption: Dictionary,
		fodder_key: String, keywords_doc: Dictionary) -> Array[Dictionary]:
	var violations: Array[Dictionary] = validate_absorption(
		roster_skills, absorption, fodder_key, keywords_doc)
	if not violations.is_empty():
		var codes: Array[String] = []
		for v: Dictionary in violations:
			codes.append(String(v["code"]))
		push_error("SkillForge.apply_absorption: invalid absorption (%s)" % ", ".join(codes))
		return []
	var survivor_key := String((absorption["survivor"] as Dictionary)["key"])
	var out: Array[Dictionary] = []
	for row_v: Variant in roster_skills:
		var row: Dictionary = row_v
		var key := String(row.get("key", ""))
		if key == fodder_key:
			continue
		var copy: Dictionary = row.duplicate(true)
		if key == survivor_key:
			copy["absorbed"] = fodder_key
			copy["cap"] = ABSORB_CAP
		out.append(copy)
	return out


# -------------------------------------------------------- Mod-Center offers

## Convenience: the offer with the given key from a parsed
## data/mod_center_offers.json doc; {} when absent.
static func find_offer(offers_doc: Dictionary, offer_key: String) -> Dictionary:
	for row: Variant in offers_doc.get("offers", []) as Array:
		if row is Dictionary and String((row as Dictionary).get("key", "")) == offer_key:
			return row
	return {}


## The AUTHORING gate for a Mod-Center offer (#35 Q1 route a): an offer is
## structurally a mutation recipe carrying compatibility_override: true, and
## its parents must share a BROAD group and NO narrow keyword. Returns [] for
## a well-authored offer, else one {code, field, message} per violation —
## a narrow-shared pair is an authoring ERROR (it belongs in
## data/skill_mutations.json as a normal recipe) and a no-share pair is not
## offerable at all. Roster gating is NOT checked here — redeem an offer
## through the ordinary validate_mutation / apply_mutation override path.
## Never mutates its inputs; mirrored data-side by validate_seeds.
static func validate_offer(offer: Dictionary, keywords_doc: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# Structural recipe shape first (reusing the mutation shape checks against
	# an empty roster would drag in roster codes — check shape directly).
	var shape: Array[Dictionary] = validate_mutation([], offer, keywords_doc)
	for v: Dictionary in shape:
		if String(v["code"]) == CODE_RECIPE_INVALID:
			out.append(_violation(CODE_OFFER_INVALID, String(v["field"]), String(v["message"])))
	if not out.is_empty():
		return out
	if not bool(offer.get("compatibility_override", false)):
		out.append(_violation(CODE_OFFER_INVALID, "compatibility_override",
			"an offer must carry compatibility_override: true — the offer IS the recorded GM call past the narrow rule (#35 Q1)"))
	var parent_keys: Array[String] = []
	for parent: Variant in offer.get("parents", []) as Array:
		parent_keys.append(String((parent as Dictionary)["key"]))
	for i: int in range(parent_keys.size()):
		for j: int in range(i + 1, parent_keys.size()):
			var verdict: Dictionary = SkillKeywords.compatible(
				parent_keys[i], parent_keys[j], keywords_doc)
			var basis := String(verdict["basis"])
			if basis == SkillKeywords.BASIS_NARROW_SHARED:
				out.append(_violation(CODE_OFFER_NOT_BROAD_ONLY, "parents",
					"'%s' x '%s' share the NARROW keyword(s) %s — authoring error: a narrow-shared pair is a NORMAL recipe (data/skill_mutations.json), not a Mod-Center offer" % [
						parent_keys[i], parent_keys[j], str(verdict["keywords"])]))
			elif basis == SkillKeywords.BASIS_NONE:
				out.append(_violation(CODE_OFFER_NOT_BROAD_ONLY, "parents",
					"'%s' x '%s' share no taxonomy keyword at all — not offerable (#35 Q1 covers broad-only pairs)" % [
						parent_keys[i], parent_keys[j]]))
	return out


static func _violation(code: String, field: String, message: String) -> Dictionary:
	return {"code": code, "field": field, "message": message}


## The first roster row carrying a key ({} = not owned) — first row wins,
## mirroring _granted_level.
static func _row_for(roster_skills: Array, key: String) -> Dictionary:
	for row_v: Variant in roster_skills:
		if row_v is Dictionary and String((row_v as Dictionary).get("key", "")) == key:
			return row_v
	return {}


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
