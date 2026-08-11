class_name Creation
extends RefCounted
## Character-creation ENGINE (KAN-4 S4.1, decision-log #31 — engine only; the
## owner drafts the creation front later). A creation spec -> validated
## add_combatant spec assembler, pure + stateless like SkillBook: validate()
## returns EVERY violation at once; assemble() emits the exact combatant dict
## CombatSim's add_combatant / CombatantState.from_spec consumes.
##
## TRAIT-SOURCING AGNOSTIC (decision #31): the input carries FINAL trait
## numbers. Whether the front derived them from a background/epithet track
## (R16: "the background is the single creation surface") or direct allocation
## is presentation — not creation's business. Creation checks the RESULT
## against the ruled creation budget, nothing else.
##
## INPUT SHAPE (the creation spec — designed here):
##   {
##     "name": String (required, non-empty) — display name.
##     "id": String (optional) — combat id override; defaults to a
##         deterministic slug of name (lowercase, non-alphanumeric runs
##         collapsed to "_"). The derived id must be non-empty.
##     "body_plan": String (required) — a data/races.json key. Must be
##         unlocked in the data (Earth-life availability, R16) and not
##         variable-morphology: animal layouts need an authored per-character
##         parts sitting, deferred by owner ruling Q61 / R21 — humans are the
##         creatable plan today. Validated against the DATA, never a
##         hardcoded race list.
##     "traits": {"physique": int, "reflexes": int, "mind": int, "charm": int}
##         — final trait numbers (see above).
##     "skills": [{"key": String, "level": int, "cap": int?}, ...] — the R16
##         background picks. "cap" is the R16 trade annotation: a raised cap
##         over skills.json default_cap (see the trade rule below).
##     "bit": {"key": String, "name": String, "line": String} (optional) —
##         the AUTHORED signature bit (decision #25). ABSENT for the many
##         characters who have none — no bit is VALID.
##     "persona": (optional) broadcast persona — passthrough (see OUTPUT).
##     "patron": (optional) chosen patron — passthrough (see OUTPUT).
##     "camera_call_stacks": int (optional, default 0) — granted stacks
##         (the demo-loadout grant pattern, F1).
##   }
##   Unknown top-level keys are ignored by validate() and NOT copied by
##   assemble() (deterministic output; "cap" on a skill row is the one
##   annotation carried through).
##
## VALIDATION RULES (each cited at its check below):
##   - body_plan: exists in races.json; unlocked == 1 (Earth-life only, R16);
##     not variable_morphology (animal sitting deferred, Q61 / R21).
##   - traits: each in 1..5 (the "rated 1-5" creation-only scale, R6); the
##     RULED budget is a 7/7 SPLIT — physique+reflexes == 7 (Body) and
##     mind+charm == 7 (Core) (R6: "7 points across Body traits + 7 across
##     Core traits", reaffirmed by R16's NPC note and pinned by
##     tests/test_party_of_three.gd on the demo/recruit data).
##   - skills: only SkillBook-IMPLEMENTED keys (the recruit-premades
##     precedent: "skills draw ONLY from ... KNOWN_KEYS — nothing
##     aspirational"); granted levels 1..cap (R19 level 0 = untrained is not
##     a background grant; scripts/validate_seeds.py check_loadouts
##     precedent); no duplicates; at least one pick (loadout precedent:
##     "skills must be a non-empty list").
##   - R16 pick count + cap trade: the background gives 4 picks; "any of them
##     may be given up for +1 cap on another" — so kept picks + total cap
##     raises <= 4. A "cap" annotation must exceed the skill's
##     skills.json default_cap and stay <= 10 (schema CHECK 0..10). Fewer
##     picks than the max is LEGAL (the recruits ship with 3, 4th slot open).
##     INTERPRETATION NOTE: the R16 text prices each give-up at +1 cap "on
##     another"; stacking several +1s on the same kept skill is read as legal
##     (the text does not forbid it) — each raise still costs one pick.
##   - bit: optional; when present must be exactly {key, name, line}, all
##     non-empty (decision #25 authored shape; validate_seeds precedent).
##   - camera_call_stacks: 0..1. PROVISIONAL: no ruled upper bound exists —
##     every shipped loadout grants exactly 1 (a system-testing override,
##     slice-contestants §RULED item 5) and the validator floor is 0, so the
##     engine pins the observed range until the owner prices grants.
##
## OUTPUT (assemble): {id, name, race, traits, skills, camera_call_stacks,
##   bit?, persona?, patron?} — EXACTLY a valid CombatantState.from_spec
##   input. team / position are left to the caller (merge them onto the dict
##   before add_combatant). threshold_dice is deliberately absent: R22's
##   per-stat default d4 applies by omission. persona / patron ride the dict
##   untouched for the caller's presentation plumbing — from_spec ignores
##   unknown keys, and add_combatant stores none of the spec itself, so the
##   passthrough never reaches sim state or the state hash. The R16 "cap"
##   annotation is validated here, carried on the row, and dropped by
##   from_spec's normalization exactly like the demo/recruit loadout path;
##   no runtime consumer exists yet (KAN-7 progression will own caps).
##   Same spec in -> identical dict out (fixed build order; hashing goes
##   through CombatSim.canonical_serialize, which key-sorts anyway).

const BODY_TRAITS: Array[String] = ["physique", "reflexes"]
const CORE_TRAITS: Array[String] = ["mind", "charm"]
## R6: the "rated 1-5" scale is creation-only; 7 points per pillar.
const TRAIT_MIN: int = 1
const TRAIT_MAX: int = 5
const PILLAR_BUDGET: int = 7
## R16: the background gives 4 skills (picks + cap raises share the budget).
const BACKGROUND_PICKS: int = 4
## Schema CHECK (001_initial_schema.sql): default_cap / level ceiling.
const CAP_CEILING: int = 10
## skills.json default_cap fallback when static_data carries no skills table
## (the entire current catalog authors 5).
const DEFAULT_SKILL_CAP: int = 5
## PROVISIONAL bound (see header): the demo/recruit precedent grants exactly 1.
const CAMERA_STACKS_MAX: int = 1


## Validates a creation spec against static_data (the same dict CombatSim
## consumes; "races" and "skills" are read). Returns [] when valid, else one
## {code, field, message} entry per violation — ALL violations at once, never
## fail-fast, in a deterministic order (fixed check sequence; skill rows in
## input order). Never mutates the spec.
static func validate(spec: Dictionary, static_data: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# --- name / id ---------------------------------------------------------
	var name_ok: bool = spec.get("name") is String and String(spec["name"]) != ""
	if not name_ok:
		out.append(_violation("name_required", "name", "name must be a non-empty String"))
	if spec.has("id"):
		if not (spec["id"] is String) or String(spec["id"]) == "":
			out.append(_violation("id_invalid", "id", "optional id override must be a non-empty String"))
	elif name_ok and _slug(String(spec["name"])) == "":
		out.append(_violation("id_invalid", "name",
			"name yields an empty id slug — provide an explicit id"))

	# --- body plan (R16 Earth-life via the data; Q61/R21 morphology gate) ---
	var plan_key := String(spec.get("body_plan", ""))
	var plan: Dictionary = _find_by_key(static_data.get("races", []), plan_key)
	if plan.is_empty():
		out.append(_violation("unknown_body_plan", "body_plan",
			"body_plan %s is not a races.json key" % [str(spec.get("body_plan", ""))]))
	else:
		if int(plan.get("unlocked", 0)) != 1:
			out.append(_violation("body_plan_locked", "body_plan",
				"body_plan '%s' is not unlocked in races.json (Earth-life availability, R16)" % plan_key))
		if bool((plan.get("racial_traits", {}) as Dictionary).get("variable_morphology", false)):
			out.append(_violation("body_plan_deferred", "body_plan",
				"body_plan '%s' needs an authored per-character part layout — deferred (owner ruling Q61 / R21); humans are creatable today" % plan_key))

	# --- traits (R6: 1..5 creation scale; 7 Body / 7 Core split) ------------
	var parsed_traits: Dictionary = {}
	if not (spec.get("traits") is Dictionary):
		out.append(_violation("traits_invalid", "traits", "traits must be an object"))
	else:
		var traits: Dictionary = spec["traits"]
		for trait_key: String in CombatantState.TRAIT_KEYS:
			var value: Variant = _as_int(traits.get(trait_key))
			if value == null:
				out.append(_violation("trait_invalid", "traits.%s" % trait_key,
					"trait %s must be an int" % trait_key))
				continue
			parsed_traits[trait_key] = value
			if int(value) < TRAIT_MIN or int(value) > TRAIT_MAX:
				out.append(_violation("trait_out_of_range", "traits.%s" % trait_key,
					"trait %s = %d outside %d..%d (the rated 1-5 creation-only scale, R6)" % [trait_key, int(value), TRAIT_MIN, TRAIT_MAX]))
	# Pillar budgets only when both members parsed — a missing trait already
	# has its own violation; a garbage sum would just echo that root cause.
	if parsed_traits.has("physique") and parsed_traits.has("reflexes"):
		var body: int = int(parsed_traits["physique"]) + int(parsed_traits["reflexes"])
		if body != PILLAR_BUDGET:
			out.append(_violation("body_budget_violation", "traits",
				"physique + reflexes = %d, RULED budget is %d (R6: 7 across Body traits)" % [body, PILLAR_BUDGET]))
	if parsed_traits.has("mind") and parsed_traits.has("charm"):
		var core: int = int(parsed_traits["mind"]) + int(parsed_traits["charm"])
		if core != PILLAR_BUDGET:
			out.append(_violation("core_budget_violation", "traits",
				"mind + charm = %d, RULED budget is %d (R6: 7 across Core traits)" % [core, PILLAR_BUDGET]))

	# --- skills (R16 background picks + cap trade) --------------------------
	var rows: Variant = spec.get("skills")
	if not (rows is Array) or (rows as Array).is_empty():
		out.append(_violation("skills_required", "skills",
			"skills must be a non-empty list of background picks (R16; validate_seeds loadout precedent)"))
	else:
		var seen: Dictionary = {}
		var raises: int = 0
		var picks: int = (rows as Array).size()
		for i: int in range((rows as Array).size()):
			var field := "skills[%d]" % i
			var row_v: Variant = (rows as Array)[i]
			if not (row_v is Dictionary) or not ((row_v as Dictionary).get("key") is String) \
					or String((row_v as Dictionary)["key"]) == "":
				out.append(_violation("skill_row_invalid", field,
					"each skill row must be an object with a non-empty 'key'"))
				continue
			var row: Dictionary = row_v
			var key := String(row["key"])
			if not SkillBook.is_known(key):
				out.append(_violation("unknown_skill", field,
					"'%s' is not an IMPLEMENTED skill (SkillBook.KNOWN_KEYS — nothing aspirational, recruit-premades precedent)" % key))
				continue
			if seen.has(key):
				out.append(_violation("duplicate_skill", field, "skill '%s' granted twice" % key))
				continue
			seen[key] = true
			var cap: int = _default_cap(static_data, key)
			if row.has("cap"):
				var cap_v: Variant = _as_int(row["cap"])
				if cap_v == null or int(cap_v) <= _default_cap(static_data, key) or int(cap_v) > CAP_CEILING:
					out.append(_violation("cap_trade_invalid", field,
						"'%s' cap %s must be an int in %d..%d (R16 trade raises over skills.json default_cap; schema CHECK <= 10)" % [key, str(row["cap"]), _default_cap(static_data, key) + 1, CAP_CEILING]))
				else:
					raises += int(cap_v) - cap
					cap = int(cap_v)
			var level_v: Variant = _as_int(row.get("level"))
			if level_v == null or int(level_v) < 1 or int(level_v) > cap:
				out.append(_violation("skill_level_invalid", field,
					"'%s' level %s outside 1..%d (granted levels 1..cap — R19 level 0 is untrained, not a background grant; validate_seeds precedent)" % [key, str(row.get("level")), cap]))
		if picks + raises > BACKGROUND_PICKS:
			out.append(_violation("background_picks_exceeded", "skills",
				"%d picks + %d cap raise(s) exceed the %d background picks (R16: the background gives 4 skills; each +1 cap costs a given-up pick)" % [picks, raises, BACKGROUND_PICKS]))

	# --- bit (decision #25 authored shape) ----------------------------------
	if spec.has("bit"):
		var bit_v: Variant = spec["bit"]
		var bit_ok: bool = bit_v is Dictionary and (bit_v as Dictionary).size() == 3
		if bit_ok:
			for bf: String in ["key", "name", "line"]:
				if not ((bit_v as Dictionary).get(bf) is String) or String((bit_v as Dictionary)[bf]) == "":
					bit_ok = false
		if not bit_ok:
			out.append(_violation("bit_invalid", "bit",
				"bit must be exactly {key, name, line}, all non-empty Strings (decision #25 authored shape); omit it entirely for a character with no bit"))

	# --- camera_call_stacks (demo precedent; PROVISIONAL bound) -------------
	if spec.has("camera_call_stacks"):
		var stacks_v: Variant = _as_int(spec["camera_call_stacks"])
		if stacks_v == null or int(stacks_v) < 0 or int(stacks_v) > CAMERA_STACKS_MAX:
			out.append(_violation("camera_call_stacks_invalid", "camera_call_stacks",
				"camera_call_stacks %s outside 0..%d (every shipped loadout grants exactly 1; floor 0 per validate_seeds — PROVISIONAL bound, see header)" % [str(spec["camera_call_stacks"]), CAMERA_STACKS_MAX]))

	return out


## Assembles a VALID creation spec into the exact add_combatant combatant dict
## (see OUTPUT in the header). On an invalid spec: push_error + {} — never a
## half-spec. Deterministic: same spec in -> identical dict out.
static func assemble(spec: Dictionary, static_data: Dictionary) -> Dictionary:
	var violations: Array[Dictionary] = validate(spec, static_data)
	if not violations.is_empty():
		var codes: Array[String] = []
		for v: Dictionary in violations:
			codes.append(String(v["code"]))
		push_error("Creation.assemble: invalid spec (%s)" % ", ".join(codes))
		return {}
	var traits: Dictionary = spec["traits"]
	var out_traits: Dictionary = {}
	for trait_key: String in CombatantState.TRAIT_KEYS:
		out_traits[trait_key] = int(_as_int(traits[trait_key]))
	var out_skills: Array[Dictionary] = []
	for row_v: Variant in spec["skills"] as Array:
		var row: Dictionary = row_v
		var normalized: Dictionary = {
			"key": String(row["key"]),
			"level": int(_as_int(row["level"])),
		}
		if row.has("cap"):
			normalized["cap"] = int(_as_int(row["cap"]))
		out_skills.append(normalized)
	var out: Dictionary = {
		"id": String(spec["id"]) if spec.has("id") else _slug(String(spec["name"])),
		"name": String(spec["name"]),
		"race": String(spec["body_plan"]),
		"traits": out_traits,
		"skills": out_skills,
		"camera_call_stacks": int(_as_int(spec.get("camera_call_stacks", 0))),
	}
	if spec.has("bit"):
		out["bit"] = (spec["bit"] as Dictionary).duplicate(true)
	if spec.has("persona"):
		out["persona"] = spec["persona"]
	if spec.has("patron"):
		out["patron"] = spec["patron"]
	return out


static func _violation(code: String, field: String, message: String) -> Dictionary:
	return {"code": code, "field": field, "message": message}


## int when the value is an int (or a whole float — JSON numbers parse as
## floats), null otherwise. Mirrors from_spec's int() pragmatism without
## silently truncating a fractional number.
static func _as_int(value: Variant) -> Variant:
	if value is int:
		return value
	if value is float and float(value) == floorf(float(value)):
		return int(value)
	return null


static func _find_by_key(entries: Variant, key: String) -> Dictionary:
	if key == "" or not (entries is Array):
		return {}
	for entry: Variant in entries as Array:
		if entry is Dictionary and String((entry as Dictionary).get("key", "")) == key:
			return entry
	return {}


static func _default_cap(static_data: Dictionary, skill_key: String) -> int:
	var row: Dictionary = _find_by_key(static_data.get("skills", []), skill_key)
	if row.is_empty():
		return DEFAULT_SKILL_CAP
	return int(row.get("default_cap", DEFAULT_SKILL_CAP))


## Deterministic combat-id slug: lowercase, alphanumeric runs kept, everything
## else collapsed into single "_" separators, edges stripped.
static func _slug(text: String) -> String:
	var lower := text.to_lower()
	var out := ""
	var pending: bool = false
	for i: int in range(lower.length()):
		var ch: String = lower[i]
		var alnum: bool = (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")
		if alnum:
			if pending and out != "":
				out += "_"
			pending = false
			out += ch
		else:
			pending = true
	return out
