class_name EvidenceEngine
extends RefCounted
## Evidence ledger — the small set of REAL decisions the verdict can QUOTE
## ("the show called you X; here is what you actually did"). Public identity
## (tags/epithet) is what the crowd SAW; this ledger is what actually HAPPENED.
##
## Contract (mirrors TagEngine's consumer discipline exactly):
## - A pure consumer of the event stream apply_command produces. No wall-clock
##   reads; NO randomness — the ledger is a pure function of the ordered event
##   log. Serialized in CombatSim.to_dict() under "evidence" and covered by
##   state_hash.
## - Wired in CombatSim._post AFTER tags.ingest so it also sees hype_* AND tag_*
##   outputs in the same batch. Every event this engine emits is evidence_*
##   prefixed and skipped on re-ingest — the same self-guard convention.
## - The ledger is APPEND-ONLY and chronological. Each entry:
##     {"tick": int, "clock": int, "moment": int, "type": String,
##      "actor": String, "detail": {...}}
##   `clock` is the 1-based Clock lap (C1 = ticks 0..9); `moment` the displayed
##   Moment (10..1). actor "" marks PARTY-LEVEL evidence (no reliable individual
##   attribution in the source signal — never guessed).
## - HONESTY: every entry is triggered by a real event/state. When a signal
##   cannot name an individual (the treat command carries no treater; a breach
##   opened by a festering wound at Clock reset has no hitter in the batch), the
##   entry is party-level or DROPPED — never approximated.
##
## The 7 ledger evidence types (an 8th, "endured", is view-derived by
## GameController.view_verdict — survival state, not an event — so it is NOT
## recorded here):
##   breach_risk      breach_opened, batch-correlated to the contestant whose
##                    landed hit damaged the breached combatant (gorefest-style
##                    credited_actor attribution); detail.windup marks a hit
##                    committed through a windup (Exposed the whole way).
##   goal_answered    hype_goal_completed, credited to completed_by (HypeEngine
##                    _goal_completer — the same attribution Scene Stealer uses).
##   goal_unanswered  hype_goal_expired — the crowd's demand died un-met (party).
##   bit_under_fire   bit_performed while the performer is genuinely at risk AT
##                    THAT MOMENT (live state read: damaged/bleeding part, or a
##                    live hostile within 1 hex). A safe bit is NOT evidence.
##   spotlight_gamble hype_camera_call_started while the caller carries a
##                    damaged part (the spotlight doubles LOSSES too — calling
##                    it hurt is a real gamble; an unhurt call proves nothing).
##   stabilized       bleed_out_stabilized — someone was pulled back from
##                    bleeding out. The treat command names no treater, so this
##                    is party-level; detail.saved names who was saved.
##   takedown         combatant_died where the victim is team "enemies" and a
##                    credited contestant exists (I-13 credited_actor).

## Live refs (NOT serialized — re-wired by CombatSim.from_dict, like TagEngine).
var combatants: Dictionary = {}
var clock: Clock = null

## Serialized state.
var ledger: Array[Dictionary] = []
## Windup mirror rebuilt from action_declared/action_resolved/action_invalidated
## events (breach_risk's detail.windup) — a declared windup stays pending until
## its resolution/invalidation (or the actor's death) clears it.
var windup: Dictionary = {}  # actor id -> true


func wire(combatants_ref: Dictionary, clock_ref: Clock) -> void:
	combatants = combatants_ref
	clock = clock_ref


## Scores one command's event batch; returns evidence_* events to append to the
## same batch. Never rescans evidence_* events, so re-entry is safe.
func ingest(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# A windup resolving in THIS batch clears the mirror at its action_resolved —
	# which sits BEFORE the breach_opened it may have caused. Snapshot the
	# batch-start mirror so the breach still sees the commitment honestly.
	var windup_at_start: Dictionary = windup.duplicate()
	var seen: Dictionary = {}  # per-batch duplicate guard (cap ledger growth)
	for i: int in range(events.size()):
		var event: Dictionary = events[i]
		var etype := String(event.get("type", ""))
		if etype.begins_with("evidence_"):
			continue
		match etype:
			"action_declared":
				if bool(event.get("windup", false)):
					windup[String(event.get("actor", ""))] = true
			"action_resolved", "action_invalidated":
				windup.erase(String(event.get("actor", "")))
			"breach_opened":
				_breach_risk(events, i, event, windup_at_start, out, seen)
			"hype_goal_completed":
				_goal_answered(event, out, seen)
			"hype_goal_expired":
				_record("goal_unanswered", "", {"goal": String(event.get("goal", ""))}, event, out, seen)
			"bit_performed":
				_bit_under_fire(event, out, seen)
			"hype_camera_call_started":
				_spotlight_gamble(event, out, seen)
			"bleed_out_stabilized":
				# The treat command carries NO actor — party-level, honestly.
				_record("stabilized", "", {"saved": String(event.get("combatant", ""))}, event, out, seen)
			"combatant_died":
				windup.erase(String(event.get("combatant", "")))
				_takedown(events, i, event, out, seen)
	return out


# ------------------------------------------------------------------ detectors

## The contestant whose landed hit opened the breach. breach_opened names only
## the breached combatant and is appended by _post/_advance_tick AFTER the
## strike's closer, so the gorefest-style forward scan cannot start from the
## breach itself: find the LAST damage_applied on the breached combatant earlier
## in the batch and credit ITS batch actor (HypeEngine.credited_actor — forward
## to the closing action_resolved, or back to the opening reaction_resolved).
## A breach with no damaging hit in the batch (a wound festering to T2 at Clock
## reset) credits nobody and records NOTHING — nobody's hit opened it.
## A merged combined-action hit credits the closing hitter (v1, same convention
## as gorefest's batch credit).
func _breach_risk(events: Array[Dictionary], i: int, event: Dictionary, windup_at_start: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var breached_id := String(event.get("combatant", ""))
	var dmg_index: int = -1
	for j: int in range(i - 1, -1, -1):
		if String(events[j].get("type", "")) == "damage_applied" \
				and String(events[j].get("combatant", "")) == breached_id:
			dmg_index = j
			break
	if dmg_index < 0:
		return
	var attacker: String = HypeEngine.credited_actor(events, dmg_index)
	if attacker == "" or not _is_contestant(attacker):
		return
	var detail: Dictionary = {"boss": breached_id}
	if bool(windup_at_start.get(attacker, false)):
		detail["windup"] = true  # committed through the windup, Exposed the whole way
	_record("breach_risk", attacker, detail, event, out, seen)


## Credited to the goal COMPLETER (completed_by, HypeEngine._goal_completer —
## the same attribution Scene Stealer rides), falling back to the legacy
## `combatant` field. A goal completed by a non-contestant (the boss killing a
## contestant completes a takedown goal too) is NOT contestant evidence — drop.
func _goal_answered(event: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var completer := String(event.get("completed_by", ""))
	if completer == "":
		completer = String(event.get("combatant", ""))
	if not _is_contestant(completer):
		return
	_record("goal_answered", completer, {
		"goal": String(event.get("goal", "")),
		"payout": int(event.get("spectacle_points", 0)),
	}, event, out, seen)


## The bit is only evidence when performed AT RISK — live combatant state read
## when the batch is scored (_post runs after all state mutation, so the read is
## authoritative): any damaged/bleeding part, or a live hostile within 1 hex.
func _bit_under_fire(event: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var actor_id := String(event.get("actor", ""))
	var c: CombatantState = combatants.get(actor_id)
	if c == null or not _is_contestant(actor_id):
		return
	var detail: Dictionary = {}
	var wounded: String = _first_wounded_part(c)
	if wounded != "":
		detail["wounded_part"] = wounded
		detail["bleeding"] = c.condition_tier(wounded, "bleeding") > 0
	var foe: String = _adjacent_hostile(c)
	if foe != "":
		detail["enemy_adjacent"] = foe
	if detail.is_empty():
		return  # an unhurt, unthreatened bit is not evidence of anything
	_record("bit_under_fire", actor_id, detail, event, out, seen)


## Calling the spotlight while carrying a damaged part: the multiplier doubles
## losses too, so a wounded call is a real gamble. An unhurt call records nothing.
func _spotlight_gamble(event: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var caller := String(event.get("actor", ""))
	var c: CombatantState = combatants.get(caller)
	if c == null or not _is_contestant(caller):
		return
	var wounded: String = _first_wounded_part(c)
	if wounded == "":
		return
	_record("spotlight_gamble", caller, {
		"wounded_part": wounded,
		"target": String(event.get("target", "")),
	}, event, out, seen)


## An enemy-team death with a credited contestant (I-13 credited_actor: forward
## to the strike's closer, back to an opening reaction). A clock-driven death
## (bleed-out drain) has no closer in its batch — uncredited, so no entry.
func _takedown(events: Array[Dictionary], i: int, event: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var victim := String(event.get("combatant", ""))
	var vc: CombatantState = combatants.get(victim)
	if vc == null or vc.team != "enemies":
		return
	var credited: String = HypeEngine.credited_actor(events, i)
	if credited == "" or not _is_contestant(credited):
		return
	_record("takedown", credited, {"victim": victim}, event, out, seen)


# ------------------------------------------------------------------ helpers

## First (sorted) part that is destroyed, disabled, below max HP, or bleeding.
func _first_wounded_part(c: CombatantState) -> String:
	var keys: Array = c.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		var part: Dictionary = c.parts[key]
		if bool(part.get("destroyed", false)) or bool(part.get("disabled", false)) \
				or int(part.get("hp", 0)) < c.max_hp(key) \
				or c.condition_tier(key, "bleeding") > 0:
			return key
	return ""


## First (sorted) live, on-field combatant of an OPPOSING team within 1 hex.
## Team is the hostility ground truth (combat_status); team-less fixtures have
## no hostiles, so they never fake this signal.
func _adjacent_hostile(c: CombatantState) -> String:
	if c.team == "":
		return ""
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other == c or other.team == "" or other.team == c.team:
			continue
		if not other.alive or other.removed_from_play:
			continue
		if CombatantState.hex_distance(other.position, c.position) <= 1:
			return String(id)
	return ""


## Appends one ledger entry (chronological, append-only) + its broadcast event.
## Time comes from the source event's stamp when present (advance_tick batches
## stamp tick+moment before _post), else the live clock — deterministic either
## way. `seen` drops exact same-batch duplicates (the sanity cap).
func _record(evidence_type: String, actor_id: String, detail: Dictionary, source: Dictionary, out: Array[Dictionary], seen: Dictionary) -> void:
	var tick: int = int(source.get("tick", clock.tick if clock != null else 0))
	var entry: Dictionary = {
		"tick": tick,
		"clock": tick / Clock.TICKS_PER_CLOCK + 1,
		"moment": int(source.get("moment", Clock.TICKS_PER_CLOCK - (tick % Clock.TICKS_PER_CLOCK))),
		"type": evidence_type,
		"actor": actor_id,
		"detail": detail.duplicate(true),
	}
	var key: String = "%s|%s|%d|%s" % [evidence_type, actor_id, tick, JSON.stringify(detail, "", true)]
	if seen.has(key):
		return
	seen[key] = true
	ledger.append(entry)
	var event: Dictionary = entry.duplicate(true)
	event["type"] = "evidence_recorded"
	event["evidence"] = evidence_type
	out.append(event)


func _is_contestant(id: String) -> bool:
	var c: CombatantState = combatants.get(id)
	if c == null:
		return false
	return not EnemyAI.AI_CATEGORIES.has(c.category)


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	return {
		"ledger": ledger.duplicate(true),
		"windup": windup.duplicate(true),
	}


static func from_dict(data: Dictionary) -> EvidenceEngine:
	var engine := EvidenceEngine.new()
	for entry: Variant in data.get("ledger", []) as Array:
		engine.ledger.append((entry as Dictionary).duplicate(true))
	engine.windup = (data.get("windup", {}) as Dictionary).duplicate(true)
	return engine
