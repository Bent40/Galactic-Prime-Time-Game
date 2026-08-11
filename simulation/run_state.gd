class_name RunState
extends RefCounted
## Headless RUN model (KAN-4 core, decision-log #31 — engine only, no scenes).
##
## A run = an ordered list of encounters walked by one party (R17: a "run" is one
## dungeon deployment — leave Lounge -> return/extract/die; run TYPE decides the
## death rules, the engine here is type-agnostic). The run extends the Stage-0
## command-stream contract (docs/DIRECTION.md) one level up: RUN state is a pure
## function of (run seed, ordered run-command log) — this class is the reducer,
## the caller (GameController) owns the log. Every encounter is its OWN CombatSim
## with its own seed derived deterministically from the run seed + encounter
## index; party state crosses the gap ONLY as serialized dictionaries
## (to_dict/from_dict), never as live objects. No wall-clock reads, no RNG at the
## run level at all (encounter seeds are arithmetic, not draws).
##
## RUN-COMMAND SET (Dictionary, "type" +):
##   {"type": "start_run", "seed": int, "party": [add_combatant specs],
##    "encounters": [encounter defs]}                    idle -> between
##   {"type": "begin_encounter"}                         between -> combat
##       Starts encounter #completed. Rejected while a recruit offer is available
##       or open (the offer beat is unmissable — resolve it first). Emits
##       run_encounter_started {index, key, sim_seed, hype_start};
##       sim_seed = run_seed * 1000003 + (index + 1) * 7919 (documented
##       arithmetic — deterministic, no hash dependency); hype_start = the
##       chain-retained opening meter (decision #32 — see the persists table).
##   {"type": "end_encounter", "outcome": "WIN"|"LOSS",
##    "carried": {id: CombatantState.to_dict()}, "camera_calls_used": {id: int},
##    "tags_held": {id: {tag: true}}, "hype_meter": int}  combat -> between/finished
##       The CONTROLLER enriches this command from the live sim before logging it,
##       so the LOGGED command carries the full capture and a bare RunState can
##       replay the run log with no sims at all. A LOSS finishes the run on the
##       spot (party wipe — later encounters never start). A WIN with an eligible
##       recruit_offer on the def emits run_recruit_available and stages the
##       offer for the offer_recruit command.
##   {"type": "offer_recruit", "recruit_key": k}         between -> offer
##       Opens the offer beat for the recruit the last encounter made available.
##   {"type": "accept_recruit"}                          offer -> between
##       PROVISIONAL (#31): the recruit joins AS-IS, carrying whatever damage
##       they took fighting that encounter as a staged ally.
##   {"type": "decline_recruit"}                         offer -> between
##       STORY-DRIVEN (decision #32, supersedes #31's global decline-final): the
##       recruit's own data decides. The offer spec's "on_decline" is honored:
##       "gone_for_run" (the default when the spec is silent — #31's behavior)
##       bars any re-offer for the rest of the run; "may_reoffer" leaves the
##       recruit offerable again by a LATER encounter's recruit_offer (same run
##       — a fresh offer beat; declining the re-offer re-honors the data). The
##       run_recruit_declined event reports the policy HONORED.
##   {"type": "choose_exit", "key": k}                   exploration -> between
##       KAN-5 wave 4b (rules-addendum R29): resolves the EXPLORATION beat by
##       picking one of the cleared room's authored exits; begin_encounter then
##       starts the chosen room. Rejected mid-combat (encounter_active),
##       mid-offer (offer_pending), outside the beat (no_exploration_beat —
##       single-exit rooms auto-advance, so no beat ever opens for them), for
##       an unknown exit key (unknown_exit), an exit to a non-existent room
##       (unknown_encounter — the validator gates authored data) and an exit
##       into an already-visited room not authored "revisitable": true
##       (room_not_revisitable — impossible in validator-clean v1 DAG data,
##       kept as the honest runtime guard). Emits run_exit_chosen {key, to,
##       auto: false}.
##   {"type": "end_run"}                                 between -> finished
##       Outcome WIN when every encounter cleared (LINEAR runs only — a GRAPH
##       run wins by clearing a terminal room, which auto-finishes, so end_run
##       there is always early extraction), else ABANDONED (PROVISIONAL —
##       extraction before clearing the route; R17 run types will refine).
##       Rejected mid-combat, while an offer is unresolved and mid-exploration
##       (the beat is unmissable, like the offer beat). A LOSS never needs it
##       (the wipe auto-finishes).
## Rejections emit one {"type": "run_command_rejected", "reason": ...} and mutate
## nothing. Phases: idle / between / combat / offer / exploration / finished.
##
## ROOM GRAPH (KAN-5 wave 4b, R29 — the encounter list generalized): an
## encounter def may author `exits: [{key, to: encounter_key, label}]`. Any def
## carrying an "exits" key flips the run into GRAPH mode; with none the list is
## the exact pre-graph LINEAR run — same behavior, same serialization (the
## compat pin: graph fields serialize only in graph mode). Graph rules:
##   * the ENTRY room is encounters[0] (documented; begin_encounter starts it).
##   * after a room's combat WINs (and any recruit beat resolves — the offer
##     outranks), the cleared room's exits decide (_room_disposition):
##     0 exits = a TERMINAL room -> the run auto-finishes WIN on the spot;
##     1 exit  = auto-advance (run_exit_chosen {auto: true} — corridor feel,
##               exactly the old linear cadence, no beat);
##     2+      = the EXPLORATION beat (run_exploration_beat {exits}; the view
##               exposes the exits; choose_exit resolves it).
##   * the graph is a DAG in v1 (documented; loops are future work): rooms
##     default `revisitable: false` and the seed validator rejects cycles /
##     unreachable rooms / dangling exits. VISITED tracking is DERIVED from
##     logged state (records + active_index), never stored — replay-safe.
##   * CHAIN SEMANTICS: choosing an exit is still back-to-back for the hype
##     chain — the chain (hype_chain_index + the retention ladder) persists
##     through exploration beats untouched; a future REST beat stays the one
##     chain-breaker (unchanged data hook).
##   * sim seeds stay encounter_seed(room INDEX) — path-independent arithmetic.
##
## ENCOUNTER DEF (data — data/demo_run.json is the canonical authored example):
##   {"key": String, "kind": "combat",
##    "exits"?: [{"key": String, "to": encounter key, "label": String}] — the
##                room-graph edges (wave 4b; absent = linear list / terminal
##                room in graph mode), "revisitable"?: bool (default false —
##                DAG v1),
##    "enemies": [{"enemy_key", "id"?, "name"?, "count"?, "position"?,
##                 "positions"? (per-instance, aligned with count),
##                 "overrides"? (merged into the add_combatant spec last)}],
##    "allies":  [{"spec": {full add_combatant spec, team "party"}}]  (staged
##                party-side NPCs that are NOT roster members — the recruit
##                fights here before the offer; a recruit spec may carry
##                "on_decline": "gone_for_run" | "may_reoffer", copied verbatim
##                from its recruit_loadouts.json row — decision #32),
##    "recruit_offer"?: recruit loadout key — maps to the staged ally whose
##                combat id is the key's first "_"-separated token (the
##                documented loadout-id rule, same join view_bid uses),
##    "party_positions"?: {id: [q, r]} — restage positions for roster members,
##    "arena"?: {bounds/walls/objects — simulation/arena.gd's config shape,
##                KAN-5 wave 3d}. Passed through staging() verbatim; the
##                controller issues set_arena BEFORE the add batch. Absent =
##                the unbounded legacy combat, unchanged.}
##
## WHAT PERSISTS vs RESETS BETWEEN ENCOUNTERS (_sanitize_carry — the policy):
## The party's post-combat CombatantState.to_dict() is captured at end_encounter
## and re-seeded into the next encounter's staging. PERSISTS (carried verbatim):
##   - parts (HP damage, disabled, destroyed, armor): wounds persist between
##     fights (R11 canon, decision #27 "wounds persist"; B11/Q29: no field HP
##     regeneration — healing items treat conditions only).
##   - conditions (tier, delayed, poison_type, activation_delay): B11 — in the
##     field conditions can only be Delayed/Resolved per their treatments; an
##     untreated wound rides into the next fight. Per-instance bookkeeping is
##     sanitized: reapplied_this_clock -> false (fresh Clock lap — a
##     resolves-if-not-reapplied condition resolves at the new fight's first
##     reset per its own rule), last_attack_advance_tick -> -1 (no attack has
##     advanced it this combat).
##   - timers (suffocation/death/bleed_out countdowns): Clock-relative
##     (clocks_remaining), and the condition driving them persists.
##   - bleed_out: R5 — bleeding out until stabilized (the harsh healing economy
##     is deliberate, B11).
##   - stats, level_points: R6 progression is durable.
##   - camera_call_stacks_granted + the SPENT ledger (HypeEngine.camera_calls_used,
##     spliced by the controller at staging): B9 RULED — session = one dungeon
##     deployment, so stacks spent stay spent for the whole RUN and refresh only
##     at the Lounge.
##   - skills, bit, threshold_dice, resistances, allocated_physical, personality,
##     abilities, boss_phases, boss_traits, items: static grants / identity;
##     consumed item uses & magazines stay consumed (B11 economy).
##   - alive / removed_from_play: R17 — death is permanent within the run
##     (recruited NPCs permanently losable in every mode); R5 — mind collapse is
##     permanent. Dead/removed members stay on the roster RECORD but are never
##     staged into a later encounter.
##   - statuses.incapacitated: condition-justified (incapacitated_if_head rides a
##     persisting head condition; the ConditionEngine clears it when the
##     condition resolves).
##   - held tags (TagEngine.held, spliced by the controller at staging):
##     PROVISIONAL — tags are earned-on-camera durable labels (they gate unlocks,
##     owner ruling 2026-07-17); per-fight tag PROGRESS counters reset.
## RESETS (fresh-combat values):
##   - position: re-staged by the encounter def (new room).
##   - shock, shocked_parts, shock_stutter_pending: R13 RULED — Shock resets
##     fully at combat end (combat-end reset is the ONLY recovery).
##   - breached: per-combat discovery (#27 — the valve reset re-hides the
##     network; a new fight starts surface-immune).
##   - antagonism: R23 — grudges live on the enemy doing the remembering, and the
##     encounter's enemies die with the encounter.
##   - next_action_tick, windup_pending: the encounter's Clock (and its
##     scheduled-action queue) does not outlive its CombatSim.
##   - per-tick/per-Clock flags: free_action_used, reaction_used, moved_this_tick,
##     inventory_uses, took_scheduled_action_this_clock, damage_taken_this_tick,
##     largest_single_hit_this_tick, combo_hits_this_tick.
##   - prime substrate: last_action_key, stance, armed_primes, charges — R3
##     primes are in-combat flow state (decision #20).
##   - tick-anchored windows: exposed_until_tick, helpless_until_tick,
##     unarmed_until_tick, part_locked_until — anchored to the dead Clock's
##     absolute ticks; shock-T4's rest-of-combat Helpless/Exposed resets WITH
##     shock (R13).
##   - strained_grip: Forced-Action fallout ("+1 Moment next tool action") —
##     momentary combat flow, not a wound (PROVISIONAL).
##   - statuses overwhelmed / prone / slowed: per-combat posture/staging — you
##     stand back up between fights (PROVISIONAL).
##   - combat buffs/debuffs: brace_guard, feint_forced, feint_by, dancing,
##     dance_charm; grapple links (grappling/grappled_by — the partner did not
##     follow you out); exposed_cache (recomputed).
##   - stealthed (R20, wave 4c): in-encounter concealment — the next room
##     re-stages (and re-sees) you; the compat-conditional key is erased.
##   - broadcast plane, EXCEPT the chained hype meter: the HypeEngine
##     goal/spotlight and the EvidenceEngine ledger are per-encounter (each
##     fight is its own broadcast segment; the run keeps each segment's outcome
##     + final hype in `records`). The METER is CHAIN-RETAINED (decision #32,
##     supersedes the per-encounter hype reset): back-to-back encounters retain
##     hype — the next encounter of a chain OPENS at floor(retention% x the
##     previous segment's ending meter), retention laddered 40% / 60% / 80%
##     then 100% for every further link (CHAIN_RETENTION_PCT, floor rounding —
##     chaining encounters is rewarded with hype). Today EVERY encounter
##     chains (no rest beats exist yet); a future rest/lounge beat RESETS
##     hype_chain_index to 0 (data hook only — no such encounter kind is
##     authored). Applied at staging via staging().hype_start, derived purely
##     from logged state (records + hype_chain_index), so a bare-RunState
##     replay of the run log reproduces it.

const PHASES: Array[String] = ["idle", "between", "combat", "offer", "exploration", "finished"]

## Hype-chain retention ladder (decision #32): link N of a chain opens at
## floor(CHAIN_RETENTION_PCT[min(N, 4)]% x the previous ending meter). Index 0
## = a chain-opening encounter (fresh meter); 100% holds for all further links.
const CHAIN_RETENTION_PCT: Array[int] = [0, 40, 60, 80, 100]

var run_seed: int = 0
var phase: String = "idle"
## Encounter defs, verbatim from start_run (data — see the header shape).
var encounters: Array[Dictionary] = []
## Roster rows: {"id", "name", "loadout_key", "spec" (add_combatant spec),
## "carried" ({} until the member survives an end_encounter capture),
## "camera_calls_used": int, "tags_held": {tag: true}, "alive", "removed",
## "joined_encounter" (-1 for founders, else the encounter index they were met)}.
var roster: Array[Dictionary] = []
## Index of the encounter currently in combat; -1 outside the combat phase.
var active_index: int = -1
## Encounters completed (LINEAR runs: == the index begin_encounter starts next).
var completed: int = 0
## GRAPH mode (wave 4b): the room index begin_encounter starts next — set by
## choose_exit / the single-exit auto-advance; entry room 0. Linear runs never
## read it (begin uses `completed`) and never serialize it (the compat pin).
var next_index: int = 0
## Offer staged by the last end_encounter, awaiting the offer_recruit command:
## {"recruit_key", "id", "spec", "carried", "camera_calls_used", "tags_held"}.
var available_offer: Dictionary = {}
## The open offer beat (same shape) — accept_recruit / decline_recruit resolve it.
var pending_offer: Dictionary = {}
## recruit_key -> true for every recruit declined GONE-FOR-RUN (re-offer
## impossible). Decision #32: only a decline whose honored on_decline is
## gone_for_run lands here — a may_reoffer decline leaves no mark, so a later
## encounter's recruit_offer finds the recruit eligible again.
var declined: Dictionary = {}
## Consecutive back-to-back encounters completed in the current hype chain
## (decision #32). Today EVERY encounter is chained (no rest beats exist); a
## future rest/lounge beat RESETS this to 0 (data hook only — no such
## encounter kind is authored yet). Serialized: chain retention must survive
## save/restore between encounters.
var hype_chain_index: int = 0
## One record per completed encounter: {"index", "key", "sim_seed", "outcome",
## "hype_meter", "survivors": [ids]}.
var records: Array[Dictionary] = []
## "" while live; "WIN" / "LOSS" / "ABANDONED" once finished.
var outcome: String = ""


# ------------------------------------------------------------------ reducer

func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	match String(cmd.get("type", "")):
		"start_run":
			return _start_run(cmd)
		"begin_encounter":
			return _begin_encounter()
		"end_encounter":
			return _end_encounter(cmd)
		"offer_recruit":
			return _offer_recruit(String(cmd.get("recruit_key", "")))
		"accept_recruit":
			return _accept_recruit()
		"decline_recruit":
			return _decline_recruit()
		"choose_exit":
			return _choose_exit(String(cmd.get("key", "")))
		"end_run":
			return _end_run()
	return _reject("unknown_run_command", {"command": String(cmd.get("type", ""))})


func _reject(reason: String, extra: Dictionary = {}) -> Array[Dictionary]:
	var event: Dictionary = {"type": "run_command_rejected", "reason": reason}
	event.merge(extra)
	var events: Array[Dictionary] = [event]
	return events


func _start_run(cmd: Dictionary) -> Array[Dictionary]:
	if phase != "idle":
		return _reject("run_already_started")
	var party: Array = cmd.get("party", [])
	var defs: Array = cmd.get("encounters", [])
	if party.is_empty():
		return _reject("empty_party")
	if defs.is_empty():
		return _reject("no_encounters")
	var seen: Dictionary = {}
	for entry: Variant in party:
		var spec: Dictionary = (entry as Dictionary).duplicate(true)
		var id := String(spec.get("id", ""))
		if id == "":
			return _reject("party_spec_missing_id")
		if seen.has(id):
			return _reject("duplicate_party_id", {"id": id})
		seen[id] = true
	for entry: Variant in defs:
		var def: Dictionary = entry
		if String(def.get("kind", "combat")) != "combat":
			return _reject("unknown_encounter_kind", {"kind": String(def.get("kind", ""))})
	run_seed = int(cmd.get("seed", 0))
	for entry: Variant in party:
		var spec: Dictionary = (entry as Dictionary).duplicate(true)
		spec["team"] = "party"  # the roster IS the party — enforced, never guessed
		roster.append({
			"id": String(spec.get("id", "")),
			"name": String(spec.get("name", String(spec.get("id", "")))),
			"loadout_key": String(spec.get("loadout_key", "")),
			"spec": spec,
			"carried": {},
			"camera_calls_used": 0,
			"tags_held": {},
			"alive": true,
			"removed": false,
			"joined_encounter": -1,
		})
	for entry: Variant in defs:
		encounters.append((entry as Dictionary).duplicate(true))
	phase = "between"
	var ids: Array[String] = []
	for row: Dictionary in roster:
		ids.append(String(row["id"]))
	var keys: Array[String] = []
	for def: Dictionary in encounters:
		keys.append(String(def.get("key", "")))
	var events: Array[Dictionary] = [{
		"type": "run_started", "run_seed": run_seed, "party": ids, "encounters": keys,
	}]
	return events


func _begin_encounter() -> Array[Dictionary]:
	if phase == "combat":
		return _reject("encounter_active")
	if phase == "offer":
		return _reject("offer_pending")
	if phase == "exploration":
		return _reject("exit_unchosen")  # wave 4b: the beat is unmissable
	if phase == "finished":
		return _reject("run_finished")
	if phase != "between":
		return _reject("run_not_started")
	if not available_offer.is_empty():
		return _reject("offer_unresolved", {"recruit_key": String(available_offer.get("recruit_key", ""))})
	# Wave 4b: graph runs start the CHOSEN room (entry room 0; choose_exit /
	# auto-advance set it); linear runs keep the exact pre-graph index walk.
	var start_index: int = next_index if _graph_mode() else completed
	if start_index < 0 or start_index >= encounters.size():
		return _reject("no_encounters_left")
	active_index = start_index
	phase = "combat"
	var events: Array[Dictionary] = [{
		"type": "run_encounter_started",
		"index": active_index,
		"key": String(encounters[active_index].get("key", "")),
		"sim_seed": encounter_seed(active_index),
		"hype_start": chain_hype_start(),
	}]
	return events


func _end_encounter(cmd: Dictionary) -> Array[Dictionary]:
	if phase != "combat":
		return _reject("no_active_encounter")
	var fight_outcome := String(cmd.get("outcome", ""))
	if fight_outcome != "WIN" and fight_outcome != "LOSS":
		return _reject("unknown_encounter_outcome", {"outcome": fight_outcome})
	var def: Dictionary = encounters[active_index]
	var carried: Dictionary = cmd.get("carried", {})
	var camera_used: Dictionary = cmd.get("camera_calls_used", {})
	var tags_held: Dictionary = cmd.get("tags_held", {})
	# Ingest the capture into the roster (sanitized — the persists/resets policy).
	var survivors: Array[String] = []
	for row: Dictionary in roster:
		var id := String(row["id"])
		if not carried.has(id):
			continue  # not staged this encounter (dead earlier / joined later)
		var clean: Dictionary = _sanitize_carry(carried[id])
		row["carried"] = clean
		row["alive"] = bool(clean.get("alive", true))
		row["removed"] = bool(clean.get("removed_from_play", false))
		if camera_used.has(id):
			row["camera_calls_used"] = int(camera_used[id])
		if tags_held.has(id):
			row["tags_held"] = (tags_held[id] as Dictionary).duplicate(true)
		if bool(row["alive"]) and not bool(row["removed"]):
			survivors.append(id)
	var record_index: int = active_index
	records.append({
		"index": record_index,
		"key": String(def.get("key", "")),
		"sim_seed": encounter_seed(record_index),
		"outcome": fight_outcome,
		"hype_meter": int(cmd.get("hype_meter", 0)),
		"survivors": survivors,
	})
	completed += 1
	active_index = -1
	# One more link on the hype chain (decision #32): every encounter today is
	# back-to-back — a future rest/lounge beat resets this instead (data hook).
	hype_chain_index += 1
	var events: Array[Dictionary] = [{
		"type": "run_encounter_ended",
		"index": record_index,
		"key": String(def.get("key", "")),
		"outcome": fight_outcome,
		"survivors": survivors,
	}]
	if fight_outcome == "LOSS":
		# Party wipe: the run is over on the spot — later encounters never start,
		# and there is no offer beat (nobody left to make it to).
		outcome = "LOSS"
		phase = "finished"
		events.append({"type": "run_ended", "outcome": outcome, "encounters_cleared": completed - 1})
		return events
	phase = "between"
	# Recruit offer beat (decision #31): the def names a recruit met this
	# encounter; the capture must hold them alive (a dead recruit is not
	# offerable — R17: recruited NPCs are permanently losable), un-declined and
	# not already on the roster. offer_recruit opens the beat explicitly.
	var recruit_key := String(def.get("recruit_offer", ""))
	if recruit_key != "":
		var recruit_id: String = recruit_key.get_slice("_", 0)
		var recruit_carry: Dictionary = _sanitize_carry(carried.get(recruit_id, {})) if carried.has(recruit_id) else {}
		var eligible: bool = not recruit_carry.is_empty() \
			and bool(recruit_carry.get("alive", false)) \
			and not bool(recruit_carry.get("removed_from_play", false)) \
			and not declined.has(recruit_key) \
			and _roster_row(recruit_id).is_empty()
		if eligible:
			available_offer = {
				"recruit_key": recruit_key,
				"id": recruit_id,
				"spec": _ally_spec(def, recruit_id),
				"carried": recruit_carry,
				"camera_calls_used": int(camera_used.get(recruit_id, 0)),
				"tags_held": (tags_held.get(recruit_id, {}) as Dictionary).duplicate(true),
			}
			events.append({"type": "run_recruit_available", "recruit_key": recruit_key, "id": recruit_id})
	# Wave 4b (R29): the cleared room's exits decide what happens next — the
	# recruit beat outranks (disposition defers to accept/decline while an
	# offer is available; the offer_unresolved gate keeps it unmissable).
	if _graph_mode() and available_offer.is_empty():
		events.append_array(_room_disposition())
	return events


func _offer_recruit(recruit_key: String) -> Array[Dictionary]:
	if phase != "between":
		return _reject("no_offer_beat_here")
	if declined.has(recruit_key):
		return _reject("recruit_declined_for_run", {"recruit_key": recruit_key})
	if String(available_offer.get("recruit_key", "")) != recruit_key:
		return _reject("no_such_offer", {"recruit_key": recruit_key})
	pending_offer = available_offer
	available_offer = {}
	phase = "offer"
	var events: Array[Dictionary] = [{
		"type": "run_recruit_offered",
		"recruit_key": String(pending_offer["recruit_key"]),
		"id": String(pending_offer["id"]),
	}]
	return events


func _accept_recruit() -> Array[Dictionary]:
	if phase != "offer":
		return _reject("no_open_offer")
	# PROVISIONAL default (#31): the recruit joins AS-IS — the carried capture
	# includes every wound they took fighting the offer encounter as an ally.
	var spec: Dictionary = (pending_offer.get("spec", {}) as Dictionary).duplicate(true)
	spec["team"] = "party"
	roster.append({
		"id": String(pending_offer["id"]),
		"name": String(spec.get("name", String(pending_offer["id"]))),
		"loadout_key": String(pending_offer["recruit_key"]),
		"spec": spec,
		"carried": (pending_offer.get("carried", {}) as Dictionary).duplicate(true),
		"camera_calls_used": int(pending_offer.get("camera_calls_used", 0)),
		"tags_held": (pending_offer.get("tags_held", {}) as Dictionary).duplicate(true),
		"alive": true,
		"removed": false,
		"joined_encounter": completed - 1,
	})
	var events: Array[Dictionary] = [{
		"type": "run_recruit_joined",
		"recruit_key": String(pending_offer["recruit_key"]),
		"id": String(pending_offer["id"]),
	}]
	pending_offer = {}
	phase = "between"
	# Wave 4b: the recruit beat resolved — now the cleared room's exits decide.
	if _graph_mode():
		events.append_array(_room_disposition())
	return events


func _decline_recruit() -> Array[Dictionary]:
	if phase != "offer":
		return _reject("no_open_offer")
	# Story-driven decline (decision #32, supersedes #31's global decline-final):
	# the recruit's own loadout data decides. Anything other than an explicit
	# "may_reoffer" honors as gone_for_run (#31's behavior, kept as the safe
	# default for silent/unknown values — the seed validator gates the enum).
	var recruit_key := String(pending_offer["recruit_key"])
	var may_reoffer: bool = \
		String((pending_offer.get("spec", {}) as Dictionary).get("on_decline", "gone_for_run")) == "may_reoffer"
	if not may_reoffer:
		declined[recruit_key] = true
	var events: Array[Dictionary] = [{
		"type": "run_recruit_declined",
		"recruit_key": recruit_key,
		"id": String(pending_offer["id"]),
		"on_decline": "may_reoffer" if may_reoffer else "gone_for_run",  # the policy HONORED
	}]
	pending_offer = {}
	phase = "between"
	# Wave 4b: the recruit beat resolved — now the cleared room's exits decide.
	if _graph_mode():
		events.append_array(_room_disposition())
	return events


func _end_run() -> Array[Dictionary]:
	if phase == "combat":
		return _reject("encounter_active")
	if phase == "offer":
		return _reject("offer_pending")
	if phase == "exploration":
		return _reject("exit_unchosen")  # wave 4b: the beat is unmissable
	if phase == "finished":
		return _reject("run_already_ended")
	if phase != "between":
		return _reject("run_not_started")
	if not available_offer.is_empty():
		return _reject("offer_unresolved", {"recruit_key": String(available_offer.get("recruit_key", ""))})
	# Wave 4b: a GRAPH run wins by clearing a terminal room (auto-finished in
	# _room_disposition), so an explicit end_run there is always extraction.
	outcome = "WIN" if (not _graph_mode() and completed >= encounters.size()) else "ABANDONED"
	phase = "finished"
	var events: Array[Dictionary] = [{
		"type": "run_ended", "outcome": outcome, "encounters_cleared": completed,
	}]
	return events


## KAN-5 wave 4b (R29): resolves the EXPLORATION beat — the run-level door
## choice (§4.6's maze funnel is this, authored as data). Gating mirrors the
## offer beat's; the revisit guard keeps the v1 DAG honest even against
## unvalidated data (the seed validator is the authority for authored maps).
func _choose_exit(key: String) -> Array[Dictionary]:
	if phase == "combat":
		return _reject("encounter_active")
	if phase == "offer":
		return _reject("offer_pending")
	if phase != "exploration":
		return _reject("no_exploration_beat")
	var def: Dictionary = encounters[int((records.back() as Dictionary).get("index", -1))]
	var chosen: Dictionary = {}
	for entry: Variant in def.get("exits", []) as Array:
		if String((entry as Dictionary).get("key", "")) == key:
			chosen = entry
	if chosen.is_empty():
		return _reject("unknown_exit", {"key": key})
	var to_key := String(chosen.get("to", ""))
	var to_index: int = _encounter_index(to_key)
	if to_index < 0:
		return _reject("unknown_encounter", {"key": to_key})
	if _visited(to_index) and not bool(encounters[to_index].get("revisitable", false)):
		return _reject("room_not_revisitable", {"key": to_key})
	next_index = to_index
	phase = "between"
	var events: Array[Dictionary] = [{
		"type": "run_exit_chosen", "key": key, "to": to_key, "auto": false,
	}]
	return events


# ------------------------------------------------------------------ room graph

## True when any encounter def authors an "exits" list — the GRAPH-mode switch
## (wave 4b). A def set with none is the exact pre-graph linear run: same
## behavior, same serialization (no graph key ever appears — the compat pin).
func _graph_mode() -> bool:
	for def: Dictionary in encounters:
		if def.has("exits"):
			return true
	return false


## The room-graph advance policy (wave 4b, R29), run after a WIN's recruit
## beat fully resolves (directly at end_encounter when no offer was staged;
## at accept/decline otherwise). Reads the CLEARED room's authored exits:
##   0 exits  -> TERMINAL room: the run auto-finishes WIN on the spot (the
##               graph counterpart of "every encounter cleared"; mirrors the
##               LOSS auto-finish — no end_run needed).
##   1 exit   -> auto-advance (run_exit_chosen {auto: true}): a corridor
##               needs no beat — exactly the old linear cadence.
##   2+ exits -> the EXPLORATION beat: phase "exploration", the exits surface
##               on the view, choose_exit resolves it. The hype chain is
##               UNTOUCHED by the beat (back-to-back glue, not a rest).
func _room_disposition() -> Array[Dictionary]:
	var cleared_index: int = int((records.back() as Dictionary).get("index", -1))
	var def: Dictionary = encounters[cleared_index]
	var exits: Array = def.get("exits", []) as Array
	var events: Array[Dictionary] = []
	if exits.is_empty():
		outcome = "WIN"
		phase = "finished"
		events.append({"type": "run_ended", "outcome": outcome, "encounters_cleared": completed})
	elif exits.size() == 1:
		var exit_def: Dictionary = exits[0]
		var to_key := String(exit_def.get("to", ""))
		next_index = _encounter_index(to_key)  # -1 (dangling data) rejects at begin
		events.append({
			"type": "run_exit_chosen", "key": String(exit_def.get("key", "")),
			"to": to_key, "auto": true,
		})
	else:
		phase = "exploration"
		events.append({
			"type": "run_exploration_beat", "index": cleared_index,
			"key": String(def.get("key", "")), "exits": _exit_rows(def),
		})
	return events


## Index of the encounter def keyed `key`, -1 when unknown.
func _encounter_index(key: String) -> int:
	for i: int in range(encounters.size()):
		if String(encounters[i].get("key", "")) == key:
			return i
	return -1


## True when room `index` was already STARTED this run — DERIVED off logged
## state (records + the live active_index), never stored, so a bare-reducer
## replay tracks visits for free (wave 4b visited tracking).
func _visited(index: int) -> bool:
	if index == active_index:
		return true
	for record: Dictionary in records:
		if int(record.get("index", -1)) == index:
			return true
	return false


## Plain exit rows for events/views: [{key, to, label}] verbatim off the def.
static func _exit_rows(def: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for entry: Variant in def.get("exits", []) as Array:
		var e: Dictionary = entry
		rows.append({
			"key": String(e.get("key", "")),
			"to": String(e.get("to", "")),
			"label": String(e.get("label", "")),
		})
	return rows


# ------------------------------------------------------------------ staging

## Deterministic per-encounter sim seed — documented arithmetic on the run seed
## (no hash dependency, so the derivation is stable across platforms/versions).
func encounter_seed(index: int) -> int:
	return run_seed * 1000003 + (index + 1) * 7919


## The meter the NEXT encounter of the chain opens with (decision #32,
## supersedes the per-encounter hype reset): floor(retention% x the previous
## encounter's ending meter), retention laddered 40/60/80 then 100 for all
## further links; 0 on a chain-opening encounter. Pure read off logged state
## (records carry the enriched end_encounter's hype_meter; hype_chain_index
## advances only in the reducer), so a bare-RunState replay reproduces it.
func chain_hype_start() -> int:
	if hype_chain_index <= 0 or records.is_empty():
		return 0
	var pct: int = CHAIN_RETENTION_PCT[mini(hype_chain_index, CHAIN_RETENTION_PCT.size() - 1)]
	var prev_meter: int = int((records.back() as Dictionary).get("hype_meter", 0))
	return int(floor(prev_meter * pct / 100.0))


## Read-only staging plan for the ACTIVE encounter — the controller executes it
## through the EXISTING start_combat/apply_command path. Deterministic: same run
## state, same plan. {} outside the combat phase.
##   sim_seed:          the derived encounter seed
##   adds:              add_combatant specs in fixed order — roster (roster
##                      order), then def allies, then def enemies
##   carried:           id -> sanitized CombatantState dict to splice over the
##                      freshly-added base spec (serialized-state hand-off)
##   camera_calls_used: id -> stacks already spent this run (B9 splice)
##   tags_held:         id -> held tags to splice (PROVISIONAL carry)
##   hype_start:        the chain-retained opening meter (decision #32 — the
##                      controller seeds the HypeEngine with it at staging)
func staging() -> Dictionary:
	if phase != "combat":
		return {}
	var def: Dictionary = encounters[active_index]
	var party_positions: Dictionary = def.get("party_positions", {})
	var adds: Array[Dictionary] = []
	var carried: Dictionary = {}
	var camera_used: Dictionary = {}
	var tags_held: Dictionary = {}
	for row: Dictionary in roster:
		if not bool(row["alive"]) or bool(row["removed"]):
			continue  # the dead stay on the record, never in the arena (R17)
		var id := String(row["id"])
		var spec: Dictionary = (row["spec"] as Dictionary).duplicate(true)
		if party_positions.has(id):
			spec["position"] = (party_positions[id] as Array).duplicate()
		adds.append(spec)
		if not (row["carried"] as Dictionary).is_empty():
			carried[id] = (row["carried"] as Dictionary).duplicate(true)
		if int(row["camera_calls_used"]) > 0:
			camera_used[id] = int(row["camera_calls_used"])
		if not (row["tags_held"] as Dictionary).is_empty():
			tags_held[id] = (row["tags_held"] as Dictionary).duplicate(true)
	for entry: Variant in def.get("allies", []) as Array:
		var ally_spec: Dictionary = ((entry as Dictionary).get("spec", {}) as Dictionary).duplicate(true)
		if ally_spec.is_empty() or not _roster_row(String(ally_spec.get("id", ""))).is_empty():
			continue  # an accepted recruit stages from the roster, never twice
		ally_spec["team"] = "party"
		adds.append(ally_spec)
	for entry: Variant in def.get("enemies", []) as Array:
		var row: Dictionary = entry
		var enemy_key := String(row.get("enemy_key", ""))
		var count: int = maxi(1, int(row.get("count", 1)))
		var base_id := String(row.get("id", enemy_key))
		var base_name := String(row.get("name", enemy_key))
		var positions: Array = row.get("positions", [])
		for i: int in range(count):
			var spec: Dictionary = {
				"id": base_id if count == 1 else "%s_%d" % [base_id, i + 1],
				"name": base_name if count == 1 else "%s %d" % [base_name, i + 1],
				"enemy": enemy_key,
				"team": "enemies",
				"position": (positions[i] as Array).duplicate() if i < positions.size() \
					else (row.get("position", [0, 0]) as Array).duplicate(),
			}
			spec.merge((row.get("overrides", {}) as Dictionary).duplicate(true), true)
			adds.append(spec)
	return {
		"index": active_index,
		"key": String(def.get("key", "")),
		"sim_seed": encounter_seed(active_index),
		"adds": adds,
		"carried": carried,
		"camera_calls_used": camera_used,
		"tags_held": tags_held,
		"hype_start": chain_hype_start(),
		# KAN-5 (wave 3d): the encounter's authored arena block, verbatim ({} =
		# no arena — the unbounded legacy combat). The controller stages it
		# via set_arena BEFORE the add batch.
		"arena": (def.get("arena", {}) as Dictionary).duplicate(true),
	}


func _roster_row(id: String) -> Dictionary:
	for row: Dictionary in roster:
		if String(row["id"]) == id:
			return row
	return {}


## The staged ally spec for `recruit_id` in `def` (the recruit fought this
## encounter as a party-side NPC — decision #31's staging default). {} if the
## def never staged them (the eligibility check then fails the offer).
func _ally_spec(def: Dictionary, recruit_id: String) -> Dictionary:
	for entry: Variant in def.get("allies", []) as Array:
		var spec: Dictionary = (entry as Dictionary).get("spec", {})
		if String(spec.get("id", "")) == recruit_id:
			return spec.duplicate(true)
	return {}


# ------------------------------------------------------------------ carry policy

## The persists/resets policy (full rule-cited table in the class header): takes
## a raw post-combat CombatantState.to_dict() and returns what honestly crosses
## the encounter gap. Pure and deterministic — the same capture always sanitizes
## to the same carry.
static func _sanitize_carry(raw_variant: Variant) -> Dictionary:
	var raw: Dictionary = raw_variant if raw_variant is Dictionary else {}
	if raw.is_empty():
		return {}
	var carry: Dictionary = raw.duplicate(true)
	# Re-staged by the encounter def (new room).
	carry["position"] = [0, 0]
	# R13: Shock resets fully at combat end (the only recovery).
	carry["shock"] = 0
	carry["shocked_parts"] = {}
	carry["shock_stutter_pending"] = false
	# Per-combat discovery / enemy-side memory.
	carry["breached"] = false
	carry["antagonism"] = {}
	# The encounter's Clock died — scheduling, per-tick/per-Clock flags,
	# tick-anchored windows.
	carry["next_action_tick"] = 0
	carry["windup_pending"] = false
	carry["free_action_used"] = false
	carry["reaction_used"] = false
	carry["moved_this_tick"] = false
	carry["inventory_uses"] = 0
	carry["took_scheduled_action_this_clock"] = false
	carry["damage_taken_this_tick"] = 0
	carry["largest_single_hit_this_tick"] = 0
	carry["combo_hits_this_tick"] = {}
	carry["exposed_until_tick"] = 0
	carry["helpless_until_tick"] = 0
	carry["unarmed_until_tick"] = 0
	carry["part_locked_until"] = {}
	carry["exposed_cache"] = false
	# Prime substrate (R3/#20) — in-combat flow state.
	carry["last_action_key"] = ""
	carry["stance"] = ""
	carry["armed_primes"] = {}
	carry["charges"] = {}
	# Combat buffs/debuffs, grapple links, momentary fallout.
	carry["brace_guard"] = 0
	carry["feint_forced"] = false
	carry["feint_by"] = ""
	carry["dancing"] = false
	carry["dance_charm"] = 0
	carry["grappling"] = ""
	carry["grappled_by"] = ""
	carry["strained_grip"] = false
	# R20 (wave 4c): stealth is in-encounter concealment — you are re-staged
	# (and re-seen) in the next room. The key is compat-conditional (present
	# only while true), so ERASE it rather than write false.
	carry.erase("stealthed")
	# Statuses: only the condition-justified incapacitated persists (its head
	# condition carried too); overwhelmed/prone/slowed are per-combat posture.
	var statuses: Dictionary = {}
	if bool((raw.get("statuses", {}) as Dictionary).get("incapacitated", false)):
		statuses["incapacitated"] = true
	carry["statuses"] = statuses
	# Condition-instance bookkeeping: fresh Clock lap, no attacks yet.
	for part_key: Variant in carry.get("conditions", {}) as Dictionary:
		var on_part: Dictionary = carry["conditions"][part_key]
		for cond_id: Variant in on_part:
			var instance: Dictionary = on_part[cond_id]
			instance["reapplied_this_clock"] = false
			instance["last_attack_advance_tick"] = -1
	return carry


# ------------------------------------------------------------------ view

## Read-only plain-Dictionary projection (the view_run surface): run seed, phase,
## outcome, encounter list state, roster with a carried-damage summary, the
## offer beats, and the per-encounter records. Sorted/primitive — safe to poll.
func view() -> Dictionary:
	# Per-index record lookup (wave 4b): graph runs clear rooms out of list
	# order, so "done" is a record-index match, not a list prefix. Linear runs
	# read identically (their records ARE the index-ordered prefix).
	var record_by_index: Dictionary = {}
	for record: Dictionary in records:
		record_by_index[int(record.get("index", -1))] = record
	var encounter_rows: Array[Dictionary] = []
	for i: int in range(encounters.size()):
		var def: Dictionary = encounters[i]
		var state := "pending"
		var enc_outcome := ""
		if record_by_index.has(i):
			state = "done"
			enc_outcome = String((record_by_index[i] as Dictionary).get("outcome", ""))
		elif i == active_index:
			state = "active"
		encounter_rows.append({
			"index": i,
			"key": String(def.get("key", "")),
			"kind": String(def.get("kind", "combat")),
			"recruit_offer": String(def.get("recruit_offer", "")),
			"state": state,
			"outcome": enc_outcome,
		})
	var roster_rows: Array[Dictionary] = []
	for row: Dictionary in roster:
		roster_rows.append({
			"id": String(row["id"]),
			"name": String(row["name"]),
			"loadout_key": String(row["loadout_key"]),
			"alive": bool(row["alive"]),
			"removed": bool(row["removed"]),
			"joined_encounter": int(row["joined_encounter"]),
			"camera_calls_used": int(row["camera_calls_used"]),
			"tags_held": _sorted_keys(row["tags_held"]),
			"damage": _damage_summary(row["carried"]),
		})
	return {
		"run_seed": run_seed,
		"phase": phase,
		"outcome": outcome,
		"encounter": {"active_index": active_index, "completed": completed, "total": encounters.size()},
		# Decision #32: the chain link count + the meter the next encounter to
		# start opens with (== the active one's opening meter while live).
		"hype_chain": {"index": hype_chain_index, "hype_start": chain_hype_start()},
		"encounters": encounter_rows,
		"roster": roster_rows,
		"available_offer": _offer_view(available_offer),
		"pending_offer": _offer_view(pending_offer),
		# Wave 4b: the EXPLORATION beat's exits ([{key, to, label}] verbatim
		# off the cleared room's def) — [] outside the beat (the offer-view
		# idiom: the key is always present, empty when no beat is open).
		"exits": (_exit_rows(encounters[int((records.back() as Dictionary).get("index", -1))])
			if phase == "exploration" else ([] as Array[Dictionary])),
		"records": records.duplicate(true),
	}


static func _offer_view(offer: Dictionary) -> Dictionary:
	if offer.is_empty():
		return {}
	return {
		"recruit_key": String(offer.get("recruit_key", "")),
		"id": String(offer.get("id", "")),
		"name": String((offer.get("spec", {}) as Dictionary).get("name", String(offer.get("id", "")))),
	}


static func _sorted_keys(d_variant: Variant) -> Array:
	var keys: Array = (d_variant as Dictionary).keys()
	keys.sort()
	return keys


## Carried-damage summary off the sanitized carry: per-part hp vs max (max =
## base_max_hp + the R6 Physique-over-10 bonus, computed from the carried
## stats), plus every live condition. {} for a fresh member (no capture yet).
static func _damage_summary(carried_variant: Variant) -> Dictionary:
	var carried: Dictionary = carried_variant if carried_variant is Dictionary else {}
	if carried.is_empty():
		return {}
	var stats: Dictionary = carried.get("stats", {})
	var phys: Dictionary = stats.get("physique", {})
	var phys_total: int = int(phys.get("base", 0)) + int(phys.get("bonus", 0)) + int(phys.get("level_bonus", 0))
	var hp_bonus: int = CombatantState.over_cap(phys_total, 5)
	var parts: Dictionary = {}
	var part_keys: Array = (carried.get("parts", {}) as Dictionary).keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		var part: Dictionary = carried["parts"][part_key]
		parts[String(part_key)] = {
			"hp": int(part.get("hp", 0)),
			"max_hp": int(part.get("base_max_hp", 0)) + hp_bonus,
			"disabled": bool(part.get("disabled", false)),
			"destroyed": bool(part.get("destroyed", false)),
		}
	var conditions: Array[Dictionary] = []
	var cond_parts: Array = (carried.get("conditions", {}) as Dictionary).keys()
	cond_parts.sort()
	for part_key: Variant in cond_parts:
		var on_part: Dictionary = carried["conditions"][part_key]
		var cond_ids: Array = on_part.keys()
		cond_ids.sort()
		for cond_id: Variant in cond_ids:
			conditions.append({
				"part": String(part_key),
				"condition": String(cond_id),
				"tier": int((on_part[cond_id] as Dictionary).get("tier", 1)),
			})
	return {"parts": parts, "conditions": conditions}


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	var out: Dictionary = {
		"run_seed": run_seed,
		"phase": phase,
		"encounters": encounters.duplicate(true),
		"roster": roster.duplicate(true),
		"active_index": active_index,
		"completed": completed,
		"available_offer": available_offer.duplicate(true),
		"pending_offer": pending_offer.duplicate(true),
		"declined": declined.duplicate(true),
		"hype_chain_index": hype_chain_index,
		"records": records.duplicate(true),
		"outcome": outcome,
	}
	# Wave 4b compat pin: graph state serializes ONLY in graph mode — a linear
	# run's to_dict (and its state hash) is byte-identical to the pre-graph
	# engine (the arena/doors idiom, one level up). Hash-covered when present.
	if _graph_mode():
		out["next_index"] = next_index
	return out


static func from_dict(data: Dictionary) -> RunState:
	var run := RunState.new()
	run.run_seed = int(data.get("run_seed", 0))
	run.phase = String(data.get("phase", "idle"))
	for entry: Variant in data.get("encounters", []) as Array:
		run.encounters.append((entry as Dictionary).duplicate(true))
	for entry: Variant in data.get("roster", []) as Array:
		run.roster.append((entry as Dictionary).duplicate(true))
	run.active_index = int(data.get("active_index", -1))
	run.completed = int(data.get("completed", 0))
	# Wave 4b: pre-graph saves lack "next_index" — the linear invariant
	# (next room = completed) is the honest default.
	run.next_index = int(data.get("next_index", run.completed))
	run.available_offer = (data.get("available_offer", {}) as Dictionary).duplicate(true)
	run.pending_offer = (data.get("pending_offer", {}) as Dictionary).duplicate(true)
	run.declined = (data.get("declined", {}) as Dictionary).duplicate(true)
	run.hype_chain_index = int(data.get("hype_chain_index", 0))
	for entry: Variant in data.get("records", []) as Array:
		run.records.append((entry as Dictionary).duplicate(true))
	run.outcome = String(data.get("outcome", ""))
	return run


## Hash over the canonically-serialized run state (the DIRECTION determinism
## contract, one level up): identical (run seed, ordered run-command log) must
## always produce an identical run hash.
func state_hash() -> String:
	return CombatSim.canonical_serialize(to_dict()).sha256_text()
