class_name TagEngine
extends RefCounted
## Slice tag detection engine v1 (issue I-13) — the ~10 detectable "slice tags"
## and the audience/hype economy they feed (docs/design/slice-tags-proposal.md,
## RULED owner 2026-07-18).
##
## Contract (mirrors HypeEngine's consumer discipline exactly):
## - A pure consumer of the event stream apply_command produces. No wall-clock
##   reads; NO randomness at all (unlike HypeEngine there is no goal draw here —
##   tag state is a pure function of the ordered event log). Serialized in
##   CombatSim.to_dict() under "tags" and covered by state_hash.
## - Wired in CombatSim.apply_command IMMEDIATELY AFTER hype.ingest so it also
##   sees the hype outputs Scene Stealer keys off (hype_goal_completed,
##   hype_camera_call_started). Every event this engine emits is tag_* prefixed
##   and skipped on re-ingest — the same self-guard convention as hype_*.
## - Contestants only (RULED item 7): a combatant whose category is an AI
##   category (Mob/Elite/Boss/Super Boss) generates detectable beats but holds
##   NO tags. Every award is gated on _is_contestant.
## - Demo loadouts start with NO tags (RULED item 4): everything is earned on
##   camera. Lifecycle is binary held / not-held for the slice; the 0..3 weight
##   ladder is deferred.
##
## Detection is code (like HypeEngine's goal predicates and EnemyAI's policy);
## the data file data/tag_effects.json supplies thresholds, resonance selectors
## and the rider numbers (all PLACEHOLDER, R14). The 10 detectors:
##   reckless      action_resolved(attack,ok,rounds>0) while the actor is Exposed
##   gorefest      part_destroyed / bleeding condition_advanced>=T2 / bleed_out_started, batch-credited to the attacker
##   blooper_reel  forced_action_triggered (actor)
##   scene_stealer hype_goal_completed / hype_camera_call_started (holder)
##   the_bit       bit_performed — the mechanically-null signature action (actor)
##   fan_favorite  dramatic beats whose subject (victim) is the holder (v1 proxy for cumulative spectacle)
##   survivor      own jeopardy beats while remaining ALIVE (bleed-out, part loss, shock>=T3)
##   craft_services protective reaction / support inventory / attack_blocked
##   formation     combined_action_declared — every linked contestant member
##   3am_energy    moved-spaces streak accumulated between clock_reset boundaries

## Static effect table (NOT serialized — re-wired from static_data, like
## HypeEngine's goal_table); key -> effect dict.
var by_key: Dictionary = {}
## Live combatants ref for the contestant gate (NOT serialized — re-wired by
## CombatSim.from_dict, like ConditionEngine/EnemyAI).
var combatants: Dictionary = {}

## Serialized tag state.
var held: Dictionary = {}      # contestant id -> {tag_key: true}
var progress: Dictionary = {}  # contestant id -> {tag_key: int qualifying beats}
## Exposed-state mirror rebuilt from exposed_state_changed events (Reckless).
var exposed: Dictionary = {}   # id -> bool
## 3am Energy movement streak, reset at each clock_reset (within_clocks = 1).
var move_accum: Dictionary = {}       # id -> spaces accumulated this Clock
var move_streak_done: Dictionary = {} # id -> bool (streak already credited this Clock)


## Fresh-sim wiring: effect table + combatants ref.
func setup(effects: Variant, combatants_ref: Dictionary) -> void:
	set_effects(effects)
	wire(combatants_ref)


## Re-wire path for CombatSim.from_dict (table is static data, never saved).
func set_effects(effects: Variant) -> void:
	by_key = {}
	var rows: Array = []
	if effects is Dictionary:
		rows = (effects as Dictionary).get("tags", [])
	elif effects is Array:
		rows = effects
	for row: Variant in rows:
		if row is Dictionary:
			by_key[String((row as Dictionary).get("key", ""))] = row


func wire(combatants_ref: Dictionary) -> void:
	combatants = combatants_ref


## Scores one command's event batch for tag detection; returns tag_* events to
## append to the same batch. Never rescans tag_* events, so re-entry is safe.
func ingest(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in range(events.size()):
		var event: Dictionary = events[i]
		var etype := String(event.get("type", ""))
		if etype.begins_with("tag_"):
			continue
		if etype == "exposed_state_changed":
			exposed[String(event.get("combatant", ""))] = bool(event.get("exposed", false))
			continue
		if etype == "clock_reset":
			# within_clocks = 1: the movement streak window is one Clock.
			move_accum.clear()
			move_streak_done.clear()
			continue
		_detect(events, i, event, etype, out)
	return out


## Escalating spectacle for the NEXT bit by `actor` (base + bonus * prior
## performances this deployment). Read by CombatSim._bit BEFORE this bit is
## counted, so the first bit pays base. The bit is mechanically null; this is
## pure spectacle, the tag's single pattern-5 rider (RULED item 8).
func bit_spectacle(actor_id: String) -> int:
	var rider: Dictionary = by_key.get("the_bit", {}).get("rider", {})
	var base: int = int(rider.get("base_spectacle", 0))
	var bonus: int = int(rider.get("bonus_per_prior", 0))
	var prior: int = int((progress.get(actor_id, {}) as Dictionary).get("the_bit", 0))
	return maxi(0, base + bonus * prior)


## Resonance multiplier for HypeEngine: scale `points` by the product of the
## contestant's HELD tags whose resonance selectors include `token` (an event
## type, or "goal_completed" for crowd-goal payouts, matched by "*" too).
## Integer round-half-up — no floats reach serialized state. Held-empty (the
## start-of-slice default) is the identity, so untagged play is unchanged.
func apply_resonance(id: String, token: String, points: int) -> int:
	if points <= 0 or not _is_contestant(id):
		return points
	var hk: Dictionary = held.get(id, {})
	if hk.is_empty():
		return points
	var keys: Array = hk.keys()
	keys.sort()
	var result: int = points
	for key: Variant in keys:
		var res: Dictionary = by_key.get(String(key), {}).get("resonance", {})
		var selectors: Array = res.get("selectors", [])
		if selectors.has(token) or selectors.has("*"):
			var pct: int = int(res.get("resonance_pct", 100))
			result = int((result * pct + 50) / 100)
	return result


func holds(id: String, tag_key: String) -> bool:
	return bool((held.get(id, {}) as Dictionary).get(tag_key, false))


# ------------------------------------------------------------------ detection

func _detect(events: Array[Dictionary], i: int, event: Dictionary, etype: String, out: Array[Dictionary]) -> void:
	match etype:
		"action_resolved":
			# Reckless — land an attack while Exposed (verbatim exposed_strike predicate).
			if String(event.get("kind", "")) == "attack" \
					and String(event.get("result", "")) == "ok" \
					and int(event.get("rounds", 0)) > 0 \
					and bool(exposed.get(String(event.get("actor", "")), false)):
				_award(String(event.get("actor", "")), "reckless", out)
		"bit_performed":
			_award(String(event.get("actor", "")), "the_bit", out)
		"forced_action_triggered":
			_award(String(event.get("actor", "")), "blooper_reel", out)
		"hype_goal_completed":
			_award(String(event.get("combatant", "")), "scene_stealer", out)
		"hype_camera_call_started":
			_award(String(event.get("actor", "")), "scene_stealer", out)
		"combined_action_declared":
			for member: Variant in event.get("members", []):
				_award(String(member), "formation", out)
		"part_destroyed":
			_award(HypeEngine.credited_actor(events, i), "gorefest", out)
			_award_fan_favorite(event, out)
			_award_survivor(String(event.get("combatant", "")), out)
		"bleed_out_started":
			_award(HypeEngine.credited_actor(events, i), "gorefest", out)
			_award_fan_favorite(event, out)
			_award_survivor(String(event.get("combatant", "")), out)
		"condition_advanced":
			if String(event.get("condition", "")) == "bleeding" and int(event.get("to_tier", 0)) >= 2:
				_award(HypeEngine.credited_actor(events, i), "gorefest", out)
		"bleed_out_stabilized":
			_award_fan_favorite(event, out)
			_award_survivor(String(event.get("combatant", "")), out)
		"part_disabled":
			_award_fan_favorite(event, out)
			_award_survivor(String(event.get("combatant", "")), out)
		"combatant_died":
			_award_fan_favorite(event, out)
		"shock_changed":
			if int(event.get("to_tier", 0)) >= 3:
				_award_survivor(String(event.get("combatant", "")), out)
		"reaction_resolved":
			var pk: Array = by_key.get("craft_services", {}).get("detector", {}).get("protective_keys", [])
			if pk.has(String(event.get("key", ""))):
				_award(String(event.get("actor", "")), "craft_services", out)
		"inventory_used":
			var si: Array = by_key.get("craft_services", {}).get("detector", {}).get("support_interactions", [])
			if si.has(String(event.get("interaction", ""))):
				_award(String(event.get("actor", "")), "craft_services", out)
		"attack_blocked":
			_award(String(event.get("combatant", "")), "craft_services", out)
		"moved":
			_award_movement_streak(event, out)


## Fan Favorite (v1 proxy): a dramatic beat whose subject (victim) is a
## contestant. beat_events come from the data file so the set stays declarative.
func _award_fan_favorite(event: Dictionary, out: Array[Dictionary]) -> void:
	var beats: Array = by_key.get("fan_favorite", {}).get("detector", {}).get("events", [])
	if beats.has(String(event.get("type", ""))):
		_award(String(event.get("combatant", "")), "fan_favorite", out)


## Survivor — a jeopardy beat on SELF, credited only while the combatant is
## still alive (a fatal beat kills them; the dead don't survive). Ingest runs in
## _post AFTER the death is applied, so combatants[id].alive is authoritative.
func _award_survivor(id: String, out: Array[Dictionary]) -> void:
	if id == "":
		return
	var c: CombatantState = combatants.get(id)
	if c == null or not c.alive or c.removed_from_play:
		return
	_award(id, "survivor", out)


## 3am Energy — accumulate the mover's spaces this Clock; the first Clock in
## which the accumulation reaches streak_spaces counts once toward the unlock.
func _award_movement_streak(event: Dictionary, out: Array[Dictionary]) -> void:
	var id := String(event.get("actor", ""))
	if id == "" or not _is_contestant(id):
		return
	var total: int = int(move_accum.get(id, 0)) + maxi(0, int(event.get("spaces", 0)))
	move_accum[id] = total
	var need: int = int(by_key.get("3am_energy", {}).get("detector", {}).get("streak_spaces", 1))
	if total >= need and not bool(move_streak_done.get(id, false)):
		move_streak_done[id] = true
		_award(id, "3am_energy", out)


## Records one qualifying beat toward `tag_key` for contestant `id`, emitting the
## broadcast event (tag_progressed → tag_acquired at the threshold →
## tag_reinforced after). Non-contestants and the empty id are silently ignored.
func _award(id: String, tag_key: String, out: Array[Dictionary]) -> void:
	if id == "" or not by_key.has(tag_key) or not _is_contestant(id):
		return
	var threshold: int = maxi(1, int(by_key[tag_key].get("unlock", {}).get("count", 1)))
	var pk: Dictionary = progress.get(id, {})
	var count: int = int(pk.get(tag_key, 0)) + 1
	pk[tag_key] = count
	progress[id] = pk
	if count < threshold:
		out.append({"type": "tag_progressed", "combatant": id, "tag": tag_key, "count": count, "threshold": threshold})
	elif count == threshold:
		var hk: Dictionary = held.get(id, {})
		hk[tag_key] = true
		held[id] = hk
		out.append({"type": "tag_acquired", "combatant": id, "tag": tag_key})
	else:
		out.append({"type": "tag_reinforced", "combatant": id, "tag": tag_key, "count": count})


func _is_contestant(id: String) -> bool:
	var c: CombatantState = combatants.get(id)
	if c == null:
		return false
	return not EnemyAI.AI_CATEGORIES.has(c.category)


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	return {
		"held": held.duplicate(true),
		"progress": progress.duplicate(true),
		"exposed": exposed.duplicate(true),
		"move_accum": move_accum.duplicate(true),
		"move_streak_done": move_streak_done.duplicate(true),
	}


static func from_dict(data: Dictionary) -> TagEngine:
	var engine := TagEngine.new()
	engine.held = (data.get("held", {}) as Dictionary).duplicate(true)
	engine.progress = (data.get("progress", {}) as Dictionary).duplicate(true)
	engine.exposed = (data.get("exposed", {}) as Dictionary).duplicate(true)
	engine.move_accum = (data.get("move_accum", {}) as Dictionary).duplicate(true)
	engine.move_streak_done = (data.get("move_streak_done", {}) as Dictionary).duplicate(true)
	return engine
