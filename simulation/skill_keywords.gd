class_name SkillKeywords
extends RefCounted
## The G3 keyword tree — Gemstone compatibility authority (MODEL — pure,
## stateless, data-driven; rules-addendum R27).
##
## G3 RULED (owner 2026-07-23): every skill carries 2–4 keywords from the book
## §4.5 hierarchy of BROAD groups and NARROW members. Skills sharing a NARROW
## keyword are compatible at the Skill Gemstone; sharing only a BROAD group is
## the "ask the GM with a fiction reason" tier — machine-READABLE here (basis
## "broad_only"), never machine-LEGAL; no overlap = incompatible.
##
## PLACEMENT (why not SkillBook): SkillBook is the zero-data static mechanics
## table — it never consumes data files. The keyword rule is data-driven like
## Creation: callers hand in the PARSED data/skill_keywords.json Dictionary
## (simulation/ does no file I/O), so this is its own small static util that
## SkillForge, tests, and future Gemstone UI all share.
##
## DOC SHAPE (data/skill_keywords.json): { "taxonomy": { <broad>: [<narrow>,
## ...] }, "skills": { <skill key>: [<keyword>, ...] } }. A skill key with no
## entry has no keywords (unimplemented/unruled content — e.g. reversion) and
## is therefore compatible with nothing. Keywords outside the taxonomy are
## ignored defensively here; scripts/validate_seeds.py rejects them in data.

const BASIS_NARROW_SHARED: String = "narrow_shared"
const BASIS_BROAD_ONLY: String = "broad_only"
const BASIS_NONE: String = "none"


## The ruled keyword list for a skill key ([] when unassigned). Fresh array.
static func keywords_for(skill_key: String, doc: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for kw: Variant in (doc.get("skills", {}) as Dictionary).get(skill_key, []) as Array:
		out.append(String(kw))
	return out


## True when the keyword is one of the book §4.5 BROAD group names.
static func is_broad(keyword: String, doc: Dictionary) -> bool:
	return (doc.get("taxonomy", {}) as Dictionary).has(keyword)


## True when the keyword is a NARROW member of any broad group.
static func is_narrow(keyword: String, doc: Dictionary) -> bool:
	for narrows: Variant in (doc.get("taxonomy", {}) as Dictionary).values():
		if (narrows as Array).has(keyword):
			return true
	return false


## The G3 compatibility ruling for a skill pair, deterministic + data-driven:
##   { "compatible": bool, "basis": "narrow_shared"|"broad_only"|"none",
##     "keywords": [the shared keywords that decided the basis, sorted] }
## - narrow_shared: >= 1 shared NARROW keyword -> compatible (auto-legal).
## - broad_only: shared BROAD group(s) only -> NOT compatible here; this is the
##   ruled GM-call tier, surfaced machine-readably for a human to adjudicate.
## - none: no shared taxonomy keyword (unknown skills/keywords land here).
## Symmetric in its arguments; same inputs -> identical dict, every call.
static func compatible(skill_a: String, skill_b: String, doc: Dictionary) -> Dictionary:
	var b_keywords: Array[String] = keywords_for(skill_b, doc)
	var shared_narrow: Array[String] = []
	var shared_broad: Array[String] = []
	for kw: String in keywords_for(skill_a, doc):
		if not b_keywords.has(kw):
			continue
		if is_narrow(kw, doc) and not shared_narrow.has(kw):
			shared_narrow.append(kw)
		elif is_broad(kw, doc) and not shared_broad.has(kw):
			shared_broad.append(kw)
	shared_narrow.sort()
	shared_broad.sort()
	if not shared_narrow.is_empty():
		return {"compatible": true, "basis": BASIS_NARROW_SHARED, "keywords": shared_narrow}
	if not shared_broad.is_empty():
		return {"compatible": false, "basis": BASIS_BROAD_ONLY, "keywords": shared_broad}
	return {"compatible": false, "basis": BASIS_NONE, "keywords": [] as Array[String]}
