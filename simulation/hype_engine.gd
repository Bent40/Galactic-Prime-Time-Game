class_name HypeEngine
extends RefCounted
## Broadcast spectacle/hype engine v1 (deterministic) — the audience's excitement
## as derived sim state (DIRECTION.md: the slice ships a visible hype meter, one
## active crowd Goal, and Camera Call — review-4 §5 item 3).
##
## Contract: a consumer of the event stream apply_command produces. No wall-clock
## reads; the ONLY randomness is goal selection, drawn from a dedicated RNG
## seeded from the sim seed (separate stream so goal draws never perturb the
## action RNG's Forced-Action rolls) — hype stays a pure function of
## (seed, command log), serialized in CombatSim.to_dict() and covered by
## state_hash. EVERY event this engine emits is hype_* prefixed and re-enters
## the same stream, so replays and Stage-2 broadcasts narrate the crowd for
## free; the prefix is also the re-entry guard. The guard is load-bearing:
## point-carrying hype events (hype_spike / hype_goal_completed) self-describe
## their value in "spectacle_points" — the same generic field authored content
## may use to inject spectacle — so re-ingesting a recorded stream would
## double-count them if the guard ever went missing.
##
## Three subsystems:
## - METER: flat spectacle points per event type + damage/shock scaling, decay
##   each Clock reset, banded cold/warm/hot/on_fire, spike events on big beats.
## - CROWD GOAL (director v1, DIRECTION delta 4): ONE active goal at a time,
##   data-driven from static_data["crowd_goals"], offered at Clock resets (the
##   book's reorganization beat), completion pays hype, expiry costs a little.
## - CAMERA CALL (compendium §2.2/§11, R6 stacks): a Charm-driven spotlight on
##   one combatant; spectacle points attributed to the spotlit combatant are
##   DOUBLED (canon: "gains AND losses are doubled") until the end of that
##   combatant's current-or-next action, their death, or a Clock-count fallback.
##
## Scoring lives on the BROADCAST information plane: contestants never "see"
## hype directly; presentation surfaces it only through announcer/crowd channels.
## All numbers PLACEHOLDER (R14) unless marked canon, pending tuning — including
## every payout/threshold/deadline in data/crowd_goals.json. Attribution v1
## credits the combatant the event is about (or its actor) — cross-referencing
## attackers is a v2 concern (PROVISIONAL, R11 #14).

## PLACEHOLDER flat spectacle points per event type (R14).
const EVENT_WEIGHTS: Dictionary = {
	"combatant_died": 60,
	"mind_collapsed": 50,
	"breach_opened": 45,
	"bleed_out_started": 40,
	"bleed_out_stabilized": 35,  # the clutch save rates almost like the fall
	"part_destroyed": 30,
	"part_disabled": 18,
	"collateral_hit": 15,        # chaos is content
	"forced_action_triggered": 12,  # comedy beat
	"condition_advanced": 10,
	"grapple_started": 10,
	"reaction_resolved": 8,
}
const DAMAGE_POINTS_PER_HP: int = 4    # PLACEHOLDER (R14)
const SHOCK_POINTS_PER_TIER: int = 8   # PLACEHOLDER (R14)
const DECAY_PER_CLOCK: int = 15        # PLACEHOLDER (R14) — boredom between beats
const SPIKE_THRESHOLD: int = 50        # PLACEHOLDER (R14) — one-ingest gain that reads as a "moment"
## Band floors, checked highest-first (PLACEHOLDER, R14).
const BANDS := [["on_fire", 180], ["hot", 100], ["warm", 40], ["cold", 0]]
## Crowd disappointment when a Goal expires uncompleted. PLACEHOLDER (R14).
const GOAL_EXPIRY_PENALTY: int = 10
## Camera Call doubles the spotlit combatant's spectacle swings — canon
## (compendium §11: "doubles ... gains AND losses"), not a placeholder.
const CAMERA_CALL_MULTIPLIER: int = 2
## Fallback spotlight lifetime in Clock resets when the spotlit combatant never
## finishes an action. PLACEHOLDER (R14, PROVISIONAL interpretation R11 #13).
const CAMERA_CALL_CLOCK_LIMIT: int = 2
## Decouples the goal RNG stream from the action RNG seeded with the same value.
const GOAL_RNG_SALT: int = 0x5EC7AC1E

var meter: int = 0
var band: String = "cold"
var ledger: Dictionary = {}  # combatant id -> lifetime spectacle points credited
## Active crowd goal ({} = none): {id, name, kind, params, payout, clocks_left}.
var active_goal: Dictionary = {}
## Active Camera Call spotlight ({} = none): {caller, target, clocks_left}.
var spotlight: Dictionary = {}
var camera_calls_used: Dictionary = {}  # combatant id -> stacks spent this session
## Exposed-state mirror rebuilt from exposed_state_changed events, so the
## engine stays a pure event consumer (needed by the exposed_strike goal).
var exposed: Dictionary = {}  # combatant id -> bool
## Static goal table (NOT serialized — re-wired from static_data, like
## ConditionEngine's condition list) + its dedicated RNG (state IS serialized).
var goal_table: Array = []
var goal_rng := RandomNumberGenerator.new()
## Slice-tag engine ref (I-13, NOT serialized — re-wired by CombatSim, held
## untyped so HypeEngine keeps no compile-time dependency on TagEngine). Held
## tags amplify the spectacle points of matching events attributed to (or
## batch-credited to) the holder; null (no tags wired) leaves scoring untouched.
var tags = null


## Fresh-sim wiring: goal table + deterministic goal-RNG seed. from_dict
## restores goal_rng.state afterwards on the resume path.
func setup(goals: Array, sim_seed: int) -> void:
	set_goal_table(goals)
	goal_rng.seed = sim_seed + GOAL_RNG_SALT


## Re-wire path for CombatSim.from_dict (table is static data, never saved).
func set_goal_table(goals: Array) -> void:
	goal_table = goals.duplicate(true)


## Scores one command's event batch; returns hype events to append to the same
## batch. Never rescores hype_* events, so re-entry is safe.
func ingest(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gain: int = 0
	for i: int in range(events.size()):
		var event: Dictionary = events[i]
		var etype := String(event.get("type", ""))
		if etype.begins_with("hype_"):
			continue
		if etype == "exposed_state_changed":
			exposed[String(event.get("combatant", ""))] = bool(event.get("exposed", false))
			continue
		if etype == "clock_reset":
			meter = maxi(0, meter - DECAY_PER_CLOCK)
			out.append_array(_on_clock_reset())
			continue
		var points: int = _points_for(event)
		if points > 0:
			points = _spotlit(event, points)
			points = _resonate(events, i, event, points, false)
			gain += points
			_credit(event, points)
		if _goal_completed_by(event):
			var payout: int = _spotlit(event, int(active_goal.get("payout", 0)))
			payout = _resonate(events, i, event, payout, true)
			gain += payout
			_credit(event, payout)
			out.append({
				"type": "hype_goal_completed",
				"goal": String(active_goal.get("id", "")),
				"combatant": _attribution(event),
				"spectacle_points": payout,
			})
			active_goal = {}
		out.append_array(_check_spotlight_end(event))
	if gain > 0:
		meter += gain
		if gain >= SPIKE_THRESHOLD:
			out.append({"type": "hype_spike", "spectacle_points": gain, "meter": meter})
	var new_band: String = _band_for(meter)
	if new_band != band:
		out.append({"type": "hype_band_changed", "from_band": band, "to_band": new_band, "meter": meter})
		band = new_band
	return out


## Camera Call activation (command "camera_call", validated by CombatSim).
## stacks_total comes from the caller's Charm over-cap formula (R6). One
## spotlight at a time (PROVISIONAL, R11 #13); each use spends a stack for the
## session — session reset (B9: one dungeon deployment) is controller scope.
func camera_call(caller_id: String, target_id: String, stacks_total: int) -> Array[Dictionary]:
	if not spotlight.is_empty():
		return [{"type": "command_rejected", "reason": "spotlight_active", "target": String(spotlight.get("target", ""))}]
	var used: int = int(camera_calls_used.get(caller_id, 0))
	if used >= stacks_total:
		return [{"type": "command_rejected", "reason": "no_camera_call_stacks", "combatant": caller_id}]
	camera_calls_used[caller_id] = used + 1
	spotlight = {"caller": caller_id, "target": target_id, "clocks_left": CAMERA_CALL_CLOCK_LIMIT}
	return [{
		"type": "hype_camera_call_started",
		"actor": caller_id, "target": target_id,
		"stacks_remaining": stacks_total - used - 1,
	}]


func _points_for(event: Dictionary) -> int:
	# Generic injection hook: any event carrying "spectacle_points" scores that
	# value directly (authored/boss/environment content, review-2 §2 "style"
	# scoring). The engine's own hype_* events carry it too — which is exactly
	# why ingest's prefix guard must skip them (double-count otherwise).
	if event.has("spectacle_points"):
		return maxi(0, int(event.get("spectacle_points", 0)))
	match String(event.get("type", "")):
		"damage_applied":
			return maxi(0, int(event.get("amount", 0))) * DAMAGE_POINTS_PER_HP
		"shock_changed":
			return maxi(0, int(event.get("to_tier", 0)) - int(event.get("from_tier", 0))) * SHOCK_POINTS_PER_TIER
	return int(EVENT_WEIGHTS.get(String(event.get("type", "")), 0))


## Doubles points for events attributed to the spotlit combatant (canon).
func _spotlit(event: Dictionary, points: int) -> int:
	if not spotlight.is_empty() and _attribution(event) == String(spotlight.get("target", "")):
		return points * CAMERA_CALL_MULTIPLIER
	return points


## Slice-tag resonance (I-13): amplify `points` for events attributed to a
## tag-holder. Two responsible parties may hold a matching tag — the event's own
## subject (_attribution: victim/actor) and, for offensive beats, the batch
## attacker (credited_actor). Applying both covers offense tags (Gorefest, on
## the attacker) and defense/self tags (Reckless/Survivor, on the victim) with
## one mechanism. is_goal selects the "goal_completed" token for payout
## resonance (Scene Stealer / Fan Favorite). Audience-side only — never touches
## combat state. A null tags ref (untagged play) is the identity.
func _resonate(events: Array[Dictionary], index: int, event: Dictionary, points: int, is_goal: bool) -> int:
	if tags == null or points <= 0:
		return points
	var token: String = "goal_completed" if is_goal else String(event.get("type", ""))
	var seen: Dictionary = {}
	var victim := _attribution(event)
	if victim != "":
		seen[victim] = true
	var attacker := credited_actor(events, index)
	if attacker != "":
		seen[attacker] = true
	var ids: Array = seen.keys()
	ids.sort()
	var result: int = points
	for id: Variant in ids:
		result = int(tags.apply_resonance(String(id), token, result))
	return result


## Same-batch attacker attribution (RULED item 6, PROVISIONAL extends R11 #14):
## a victim-attributed offensive event is credited to the actor of the NEXT
## action_resolved/reaction_resolved in the same batch — the resolver emits
## strike events BEFORE their closing resolution, so the forward pairing is
## deterministic and replay-stable. No closer ahead (e.g. clock-driven condition
## advancement) → uncredited, which is correct: nobody performed it.
static func credited_actor(events: Array[Dictionary], index: int) -> String:
	for j: int in range(index, events.size()):
		var etype := String(events[j].get("type", ""))
		if etype == "action_resolved" or etype == "reaction_resolved":
			return String(events[j].get("actor", ""))
	return ""


## The spotlight ends when the spotlit combatant's action finishes (resolved or
## invalidated — "until end of that target's current or next action"), or when
## they die; the ending event itself still scored doubled above.
func _check_spotlight_end(event: Dictionary) -> Array[Dictionary]:
	if spotlight.is_empty():
		return []
	var target := String(spotlight.get("target", ""))
	var etype := String(event.get("type", ""))
	var reason: String = ""
	if etype in ["action_resolved", "action_invalidated"] and String(event.get("actor", "")) == target:
		reason = "action_ended"
	elif etype == "combatant_died" and String(event.get("combatant", "")) == target:
		reason = "target_died"
	if reason == "":
		return []
	spotlight = {}
	return [{"type": "hype_spotlight_ended", "target": target, "reason": reason}]


## Clock-reset beats: goal deadline countdown/expiry, then a fresh offer when
## the stage is empty (the crowd always wants something), and the spotlight
## lifetime fallback.
func _on_clock_reset() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not active_goal.is_empty():
		active_goal["clocks_left"] = int(active_goal.get("clocks_left", 0)) - 1
		if int(active_goal["clocks_left"]) <= 0:
			meter = maxi(0, meter - GOAL_EXPIRY_PENALTY)
			out.append({"type": "hype_goal_expired", "goal": String(active_goal.get("id", ""))})
			active_goal = {}
	if active_goal.is_empty() and not goal_table.is_empty():
		var roll: int = goal_rng.randi_range(0, goal_table.size() - 1)
		var chosen: Dictionary = (goal_table[roll] as Dictionary).duplicate(true)
		active_goal = {
			"id": String(chosen.get("id", "")),
			"name": String(chosen.get("name", "")),
			"kind": String(chosen.get("kind", "")),
			"params": chosen.get("params", {}),
			"payout": int(chosen.get("payout", 0)),
			"clocks_left": maxi(1, int(chosen.get("deadline_clocks", 1))),
		}
		out.append({
			"type": "hype_goal_offered",
			"goal": String(active_goal["id"]), "name": String(active_goal["name"]),
			"kind": String(active_goal["kind"]), "payout": int(active_goal["payout"]),
			"deadline_clocks": int(active_goal["clocks_left"]), "roll": roll,
		})
	if not spotlight.is_empty():
		spotlight["clocks_left"] = int(spotlight.get("clocks_left", 0)) - 1
		if int(spotlight["clocks_left"]) <= 0:
			out.append({"type": "hype_spotlight_ended", "target": String(spotlight.get("target", "")), "reason": "faded"})
			spotlight = {}
	return out


## Goal predicates — every kind must be machine-evaluable from the event
## stream alone (review-2 §2: "template goals ... already parameterizable").
func _goal_completed_by(event: Dictionary) -> bool:
	if active_goal.is_empty():
		return false
	var etype := String(event.get("type", ""))
	var params: Dictionary = active_goal.get("params", {})
	match String(active_goal.get("kind", "")):
		"takedown":       # compendium "Finish Fast" — a kill before the deadline
			return etype == "combatant_died"
		"overkill":       # a single hit at/over the threshold
			return etype == "damage_applied" and int(event.get("amount", 0)) >= int(params.get("threshold", 0))
		"part_break":     # compendium Spectacle — break a body part
			return etype == "part_destroyed"
		"exposed_strike": # compendium Risk "While Exposed" — land an attack while Exposed
			return etype == "action_resolved" \
				and String(event.get("kind", "")) == "attack" \
				and String(event.get("result", "")) == "ok" \
				and int(event.get("rounds", 0)) > 0 \
				and bool(exposed.get(String(event.get("actor", "")), false))
		"forced_action": # I-13 "Pratfall!" — any d6 Forced Action fires (comedy beat)
			if etype != "forced_action_triggered":
				return false
			if params.has("table") and String(params["table"]) != String(event.get("table", "")):
				return false
			if params.has("consequence") and String(params["consequence"]) != String(event.get("consequence", "")):
				return false
			return true
		"body_block": # I-13 "Body Block!" — a block or a protective reaction (Craft Services' plate)
			if etype == "attack_blocked":
				return true
			return etype == "reaction_resolved" \
				and (params.get("reaction_keys", []) as Array).has(String(event.get("key", "")))
		"move_spaces": # I-13 "Zoomies!" — moved-spaces accumulated within the goal's window
			if etype != "moved":
				return false
			var moved_total: int = int(active_goal.get("progress", 0)) + maxi(0, int(event.get("spaces", 0)))
			active_goal["progress"] = moved_total
			return moved_total >= int(params.get("spaces", 1))
	return false


func _credit(event: Dictionary, points: int) -> void:
	var id: String = _attribution(event)
	if id == "":
		return
	ledger[id] = int(ledger.get(id, 0)) + points


static func _attribution(event: Dictionary) -> String:
	return String(event.get("combatant", String(event.get("actor", ""))))


func _band_for(value: int) -> String:
	for entry: Array in BANDS:
		if value >= int(entry[1]):
			return String(entry[0])
	return "cold"


func to_dict() -> Dictionary:
	return {
		"meter": meter,
		"band": band,
		"ledger": ledger.duplicate(true),
		"active_goal": active_goal.duplicate(true),
		"spotlight": spotlight.duplicate(true),
		"camera_calls_used": camera_calls_used.duplicate(true),
		"exposed": exposed.duplicate(true),
		"goal_rng_state": goal_rng.state,
	}


static func from_dict(data: Dictionary) -> HypeEngine:
	var engine := HypeEngine.new()
	engine.meter = int(data.get("meter", 0))
	engine.band = String(data.get("band", "cold"))
	engine.ledger = (data.get("ledger", {}) as Dictionary).duplicate(true)
	engine.active_goal = (data.get("active_goal", {}) as Dictionary).duplicate(true)
	engine.spotlight = (data.get("spotlight", {}) as Dictionary).duplicate(true)
	engine.camera_calls_used = (data.get("camera_calls_used", {}) as Dictionary).duplicate(true)
	engine.exposed = (data.get("exposed", {}) as Dictionary).duplicate(true)
	# Pre-I9 saves lack goal_rng_state; the 0 fallback resumes on a stream that
	# DIVERGES from a log replay — pre-release saves are disposable (R11 #14).
	engine.goal_rng.state = int(data.get("goal_rng_state", 0))
	return engine
