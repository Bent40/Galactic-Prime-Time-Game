extends SimTestBase
## Wave 3b — the G3 keyword tree (owner 2026-07-23; book §4.5; rules-addendum
## R27). Proves data/skill_keywords.json + simulation/skill_keywords.gd:
##   * the committed taxonomy IS the book §4.5 table (9 broad groups, exact
##     narrow member lists — a drift from ruled canon is a real failure);
##   * data integrity: every IMPLEMENTED skill (SkillBook.KNOWN_KEYS) has an
##     entry; every entry carries 2–4 keywords (§4.5), all from the taxonomy,
##     no duplicates; broad/narrow namespaces stay disjoint;
##   * compatible() lands all three ruled tiers on REAL ruled pairs:
##     narrow_shared (intercept x brace via 'bracing' — the G6/§4.5 canonical
##     example; frost_ball x frost_wall via 'cold'), broad_only (fire_ball x
##     frost_ball — the book's own "two magic skills of different elements"
##     GM-call case; machine-readable, NOT auto-legal), none (fire_ball x
##     lockpicking; unknown keys);
##   * symmetric, deterministic, non-mutating.

var _doc: Dictionary = {}


func doc() -> Dictionary:
	if _doc.is_empty():
		_doc = load_json("res://data/skill_keywords.json")
	return _doc


func canon(value: Variant) -> String:
	return CombatSim.canonical_serialize(value)


# ------------------------------------------------------------- taxonomy canon

func test_taxonomy_is_the_book_table() -> void:
	# The §4.5 table, verbatim (RULED canon — pinned on purpose).
	var book: Dictionary = {
		"magic": ["fire", "cold", "toxin", "psychic", "force"],
		"strikes": ["blade", "blunt", "unarmed", "flurry", "precision", "power"],
		"movement": ["leaping", "tumbling", "rushing"],
		"performance": ["deception", "presence", "sound", "projection"],
		"survival": ["treatment", "bracing", "aquatic"],
		"control": ["grapple", "throw"],
		"perception": ["empathy", "patterning", "awareness"],
		"infiltration": ["stealth", "locks", "squeezing"],
		"craft": ["repair", "improvisation"],
	}
	var taxonomy: Dictionary = doc().get("taxonomy", {})
	var broad_keys: Array = taxonomy.keys()
	broad_keys.sort()
	var book_keys: Array = book.keys()
	book_keys.sort()
	assert_eq(broad_keys, book_keys, "exactly the 9 broad groups of book §4.5")
	for b: String in book:
		assert_eq(taxonomy.get(b), book[b], "narrow members of '%s' match the §4.5 table" % b)


func test_taxonomy_classes_are_unambiguous() -> void:
	var taxonomy: Dictionary = doc().get("taxonomy", {})
	var seen_narrow: Dictionary = {}
	for b: Variant in taxonomy:
		assert_true(SkillKeywords.is_broad(String(b), doc()), "'%s' classifies broad" % b)
		assert_false(SkillKeywords.is_narrow(String(b), doc()),
			"broad '%s' is never also narrow (disjoint namespaces)" % b)
		for n: Variant in taxonomy[b] as Array:
			assert_true(SkillKeywords.is_narrow(String(n), doc()), "'%s' classifies narrow" % n)
			assert_false(SkillKeywords.is_broad(String(n), doc()),
				"narrow '%s' is never also broad" % n)
			assert_false(seen_narrow.has(n), "narrow '%s' lives in exactly one group" % n)
			seen_narrow[n] = true
	assert_false(SkillKeywords.is_broad("bogus", doc()), "unknown keyword is not broad")
	assert_false(SkillKeywords.is_narrow("bogus", doc()), "unknown keyword is not narrow")


# --------------------------------------------------------------- entry hygiene

func test_every_implemented_skill_has_an_entry() -> void:
	# The validator mirrors this in Python; here it runs against the REAL
	# SkillBook constant, no parsing.
	var skills: Dictionary = doc().get("skills", {})
	for key: String in SkillBook.KNOWN_KEYS:
		assert_true(skills.has(key),
			"implemented skill '%s' carries its ruled keywords (G3 — data canon)" % key)
	# The G6 mutation pair + result are DATA canon even though unimplemented.
	for key: String in ["intercept", "brace", "iron_stance"]:
		assert_true(skills.has(key), "'%s' present (mutation machinery depends on it)" % key)


func test_entries_are_2_to_4_taxonomy_keywords() -> void:
	var skills: Dictionary = doc().get("skills", {})
	assert_true(skills.size() >= 49,
		"the full ruled port: 44 KEYWORDS-map skills + 5 G6 seeds (got %d)" % skills.size())
	for key: Variant in skills:
		var kws: Array = skills[key]
		assert_true(kws.size() >= 2 and kws.size() <= 4,
			"'%s': every skill carries 2-4 keywords (book §4.5), got %d" % [key, kws.size()])
		var seen: Dictionary = {}
		for kw: Variant in kws:
			assert_true(String(kw) != "", "'%s': no empty keywords" % key)
			assert_true(SkillKeywords.is_broad(String(kw), doc())
				or SkillKeywords.is_narrow(String(kw), doc()),
				"'%s': keyword '%s' comes from the §4.5 taxonomy" % [key, kw])
			assert_false(seen.has(kw), "'%s': keyword '%s' listed once" % [key, kw])
			seen[kw] = true


# ---------------------------------------------------- the three ruled tiers

func test_narrow_shared_pairs_are_compatible() -> void:
	# THE canonical pair (G6 / book §4.5 worked example): Intercept x Brace,
	# "compatible through 'bracing'".
	var v: Dictionary = SkillKeywords.compatible("intercept", "brace", doc())
	assert_true(bool(v["compatible"]), "intercept x brace compatible (§4.5 canonical example)")
	assert_eq(String(v["basis"]), "narrow_shared", "basis narrow_shared")
	assert_eq(v["keywords"], ["bracing"] as Array[String],
		"the deciding keyword is the shared NARROW 'bracing'")
	# A same-element magic pair: frost_ball x frost_wall share narrow 'cold'
	# (and broad 'magic' — the narrow wins the basis).
	var frost: Dictionary = SkillKeywords.compatible("frost_ball", "frost_wall", doc())
	assert_eq(String(frost["basis"]), "narrow_shared", "frost_ball x frost_wall: narrow 'cold' wins")
	assert_eq(frost["keywords"], ["cold"] as Array[String], "shared narrow keywords only")
	# Two shared narrows report BOTH, sorted: thousand_cuts x slice_n_dice
	# share 'blade' + 'flurry' (ruled assignments, KEYWORDS map).
	var flurry: Dictionary = SkillKeywords.compatible("thousand_cuts", "slice_n_dice", doc())
	assert_eq(flurry["keywords"], ["blade", "flurry"] as Array[String],
		"all shared narrows, deterministically sorted")


func test_broad_only_is_the_gm_call_tier() -> void:
	# The book's own GM-call case: "two magic skills of different elements".
	var v: Dictionary = SkillKeywords.compatible("fire_ball", "frost_ball", doc())
	assert_false(bool(v["compatible"]),
		"broad-only overlap is NOT machine-legal (G3: GM call with a fiction reason)")
	assert_eq(String(v["basis"]), "broad_only", "…but it IS machine-readable")
	assert_eq(v["keywords"], ["magic"] as Array[String], "the shared broad group is surfaced")
	# brace x swim share only the broad 'survival' group.
	var swim: Dictionary = SkillKeywords.compatible("brace", "swim", doc())
	assert_eq(String(swim["basis"]), "broad_only", "brace x swim: 'survival' broad only")


func test_no_overlap_and_unknown_keys_are_none() -> void:
	var v: Dictionary = SkillKeywords.compatible("fire_ball", "lockpicking", doc())
	assert_false(bool(v["compatible"]), "no shared keyword -> incompatible")
	assert_eq(String(v["basis"]), "none", "basis none")
	assert_eq((v["keywords"] as Array).size(), 0, "no deciding keywords")
	var unknown: Dictionary = SkillKeywords.compatible("reversion", "brace", doc())
	assert_eq(String(unknown["basis"]), "none",
		"a skill with no ruled entry (reversion) is compatible with nothing")
	assert_eq((SkillKeywords.keywords_for("reversion", doc()) as Array).size(), 0,
		"keywords_for an unassigned skill is []")


# ------------------------------------------------- determinism + no mutation

func test_compatible_is_symmetric_deterministic_nonmutating() -> void:
	var before: String = canon(doc())
	for pair: Array in [["intercept", "brace"], ["fire_ball", "frost_ball"],
			["fire_ball", "lockpicking"], ["thousand_cuts", "slice_n_dice"]]:
		var ab: Dictionary = SkillKeywords.compatible(pair[0], pair[1], doc())
		var ba: Dictionary = SkillKeywords.compatible(pair[1], pair[0], doc())
		assert_eq(canon(ab), canon(ba), "%s x %s symmetric" % [pair[0], pair[1]])
		var again: Dictionary = SkillKeywords.compatible(pair[0], pair[1], doc())
		assert_eq(canon(ab), canon(again), "%s x %s deterministic across calls" % [pair[0], pair[1]])
	assert_eq(canon(doc()), before, "compatible() never mutates the data doc")
