class_name CombatSim
extends RefCounted
## Headless combat simulation facade (KAN-2) — a pure command-stream reducer.
##
## Contract (docs/DIRECTION.md technical deltas + docs/rules-addendum.md):
## - The sim advances ONLY via apply_command(cmd) -> [events]. The caller owns
##   the command log; the sim is the reducer. State is a pure function of
##   (seed, ordered command log): no wall-clock reads, one seeded RNG consumed
##   only inside apply_command, every roll emitted in an event.
## - Clock drivers live OUTSIDE the sim: it never self-advances; the driver
##   feeds "advance_tick" commands (R0).
##
## Commands (Dictionary, "type" +):
##   {"type": "add_combatant", "combatant": {spec}}         (see CombatantState.from_spec)
##   {"type": "advance_tick"}                                completes the current tick (R1)
##   {"type": "declare_action", "actor", "action": {...}}    (see ActionResolver.declare)
##   {"type": "move", "actor", "to": [q, r]}                 hex movement (R3)
##   {"type": "inventory", "actor", "item"?, "interaction"?} inventory interaction (R3)
##   {"type": "reaction", "actor", "cost", "target"?, "part"?, "damage"?} (R2)
##   {"type": "combined_action", "members": [{"actor", "action": {..., "provides"?}}...]} (R15)
##   {"type": "treat", "target", "part", "condition", "mode": "delay"|"resolve"} (R4/R10)
##   {"type": "heal", "target", "part", "amount"}            explicit field healing only
##   {"type": "apply_condition", "target", "part", "condition", "tier"?, "poison_type"?,
##            "activation_delay"?}                           environment/GM source
##   {"type": "grant_level", "actor"} / {"type": "spend_level_point", "actor", "trait"} (R6)
##   {"type": "set_status", "target", "status": "overwhelmed"|"prone"|"slowed", "value"}
##   {"type": "set_stance", "actor", "stance"}                  0-cost stance for STANCE primes (R3)
##   {"type": "prime", "actor", "key"}                          arm a PREP-CHANNEL prime (R3)
##   {"type": "camera_call", "actor", "target"}                Charm spotlight (R6/R11 #13)
##   {"type": "ai_decide", "actor"}                            enemy AI turn (R11 #15)
##   {"type": "set_arena", "arena": {config}}                  OPT-IN arena (KAN-5 wave 3d)
##       Bounds/walls/objects/doors/terrain per simulation/arena.gd's config
##       shape (terrain + door locks: KAN-5 K2, rules-addendum R33).
##       Absent arena = today's unbounded behavior, with a byte-identical
##       to_dict() (the "arena" key is only present once set — the legacy
##       compat pin). Issued by GameController._stage_encounter BEFORE the
##       add_combatant batch when the encounter def carries an "arena" block;
##       rejected when an arena is already set, the config is invalid,
##       walls/objects/doors fall outside the bounds or on each other,
##       terrain hexes fall outside the bounds or on walls/objects
##       (arena_terrain_misplaced), or an already-staged combatant would be
##       left on a blocked/door hex. Spawning ON terrain is LEGAL, water
##       included (staging never prices movement; nothing ruled forbids a
##       mid-pool spawn — deliberately NOT invented).
##   {"type": "door", "actor", "key", "set": "open"|"closed"}  KAN-5 wave 4b (R29)
##       Flips an authored door. The actor must be alive/ready and ADJACENT
##       (distance exactly 1) to the door hex — standing ON an open door
##       cannot close it under itself. Costs the FREE-ACTION SLOT (R3, the
##       inventory-interaction family: one free action per combatant per
##       tick, shared with The Bit / the free move / first inventory use /
##       0-cost reactions; v1 deliberately grants NO Moment-cost fallback, so
##       one door interaction per tick is the cap). Closing onto a hex with a
##       live body in the doorway rejects (door_blocked_by_body). A LOCKED
##       door (K2 — an authored lock in state "locked") cannot be opened:
##       rejected door_locked naming the tier, slot untouched — the pick path
##       is the INTERNAL pick_lock API below, NOT a command (R33 documents
##       the downscope). Enemies never issue it in v1 — the AI never decides
##       doors (no enemy_ai code path exists for it; a closed door honestly
##       walls enemies off). Emits door_changed {actor, key, position, state}.
##   {"type": "stealth", "actor", "set"?: "hide"|"reveal"}    R20 (KAN-5 wave 4c)
##       The v1 binary stealth model (rules-addendum R20 — its own phasing
##       note authorizes this slice; the IMPLEMENTED marker there carries the
##       full mapping + every downscope). STRICTLY OPT-IN: default = everyone
##       detected; the "stealthed" key serializes only while true, so a
##       stealth-free fight is byte-identical to the pre-stealth engine.
##       HIDE (default): the actor must be alive/ready, un-grappled (physical
##       contact IS detection — R9 links reject in_grapple) and currently
##       UNSEEN by every living hostile that can act (Stealth.sees — 2× Mind
##       range + hex-line LOS through walls/closed doors; rejected
##       in_enemy_sight naming the observer). Costs the FREE-ACTION SLOT (R3,
##       the door/bit family — UNPRICED by R20, documented v1 choice; no
##       Moment-cost fallback). Emits stealth_entered.
##       REVEAL: voluntarily drops concealment — free (abandoning a state is
##       not an act), emits stealth_broken reason "revealed_self".
##       While stealthed: EnemyAI._opponents excludes the actor (the mob
##       honestly loses the TARGET — though a hider's NOISE can now leave an
##       AI hearer ALERTED and investigating the hex a sound happened on:
##       R20 hearing, round 3b — the _noise_checks sweep below); hostile
##       declares/reactions/grapples at it reject target_stealthed; an aimed
##       hostile windup collapses if it hides mid-windup (R2). Committed AREA
##       shapes (cones, charge lanes, blasts) still hit its BODY by hex —
##       physicality over information — and damage alone never breaks stealth,
##       but the Shock-T1 Shout it may trigger does (R13 noise seed).
##       Stealth BREAKS automatically (the per-command _stealth_checks sweep,
##       zero rng — R20 authors no roll): "seen" (any hostile gains range+LOS
##       — either side moving, a door opening...), "shout" (Shock T1), or
##       "downed" (death/removal). stealth_broken carries the reason (+
##       observer when seen).
##
## Rejected commands emit a single command_rejected event and mutate nothing.

var rng: RandomNumberGenerator
var rng_seed: int = 0
var static_data: Dictionary = {}
var clock: Clock
var combatants: Dictionary = {}  # id -> CombatantState (shared with helpers)
var cond: ConditionEngine
var resolver: ActionResolver
var hype: HypeEngine
var tags: TagEngine
var evidence: EvidenceEngine
var ai: EnemyAI
## OPT-IN arena (KAN-5 wave 3d): null = unbounded legacy (the overwhelming
## default — harnesses and pre-arena saves). Set via the set_arena command,
## serialized under "arena" ONLY when present (byte-identical legacy dicts).
var arena: Arena = null
## KAN-5 K1 — the zones/fields substrate (simulation/zones.gd carries the full
## model + every seam decision). null until the FIRST create_zone call: zones
## are STRICTLY OPT-IN runtime entities with NO command surface this story —
## the internal create_zone/remove_zone/damage_zone API below is what the
## future wall-skill resolvers call (tests drive it directly). Serialized
## under "zones" ONLY once a zone has ever been created (the compat pin).
var zones: Zones = null
## State snapshot taken at the START of the current tick — all resolutions at
## a tick compute against it (R2 simultaneity; simultaneous kills trade).
var tick_snapshot: Dictionary = {}


func _init(sim_seed: int = 0, data: Dictionary = {}) -> void:
	rng_seed = sim_seed
	rng = RandomNumberGenerator.new()
	rng.seed = sim_seed
	static_data = data.duplicate(true)
	clock = Clock.new()
	cond = ConditionEngine.new()
	cond.setup(static_data.get("conditions", []), combatants)
	ai = EnemyAI.new()
	ai.setup(combatants, clock, sim_seed)
	resolver = ActionResolver.new()
	resolver.setup(clock, combatants, cond, rng, ai)
	hype = HypeEngine.new()
	hype.setup(_goal_table(), sim_seed)
	hype.wire(combatants)  # R11 #14 v2 team-awareness (live ref, like tags/evidence)
	# Batch D (play_to_the_camera): the resolver reads the camera-call spend
	# ledger through this ref (remaining-stack prime) and opens the surge on it.
	resolver.wire_hype(hype)
	# Slice tags (I-13) — the second broadcast-plane consumer, wired after hype
	# so its detectors also see hype outputs (Scene Stealer). HypeEngine reads
	# held tags back through hype.tags for resonance.
	tags = TagEngine.new()
	tags.setup(static_data.get("tag_effects", {}), combatants)
	hype.tags = tags
	# Evidence ledger — the third broadcast-plane consumer, wired after tags so
	# it can also see tag_* outputs; the verdict quotes it.
	evidence = EvidenceEngine.new()
	evidence.wire(combatants, clock)
	_rebuild_snapshot()


## Crowd-goal table from static data; degrades to "no goals" when the key is
## absent or unparsed (nothing else in the sim depends on it).
func _goal_table() -> Array:
	var goals: Variant = static_data.get("crowd_goals", [])
	return goals if goals is Array else []


func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	match String(cmd.get("type", "")):
		"add_combatant":
			events = _add_combatant(cmd.get("combatant", {}))
		"advance_tick":
			events = _advance_tick()
		"declare_action":
			events = resolver.declare(String(cmd.get("actor", "")), cmd.get("action", {}))
		"move":
			var to: Array = cmd.get("to", [0, 0])
			events = resolver.move(String(cmd.get("actor", "")), Vector2i(int(to[0]), int(to[1])))
		"inventory":
			events = resolver.inventory(String(cmd.get("actor", "")), cmd)
		"reaction":
			events = resolver.reaction(String(cmd.get("actor", "")), cmd)
		"combined_action":
			events = _combined_action(cmd.get("members", []), String(cmd.get("combo_id", "")))
		"treat":
			events = _treat(cmd)
		"heal":
			events = _heal(cmd)
		"apply_condition":
			events = _apply_condition(cmd)
		"grant_level":
			events = _grant_level(cmd)
		"spend_level_point":
			events = _spend_level_point(cmd)
		"set_status":
			events = _set_status(cmd)
		"set_stance":
			events = _set_stance(cmd)
		"prime":
			events = _prime(cmd)
		"camera_call":
			events = _camera_call(cmd)
		"bit":
			events = _bit(cmd)
		"ai_decide":
			events = _ai_decide(cmd)
		"set_arena":
			events = _set_arena(cmd)
		"door":
			events = _door(cmd)
		"stealth":
			events = _stealth(cmd)
		_:
			events = [{"type": "command_rejected", "reason": "unknown_command", "command": String(cmd.get("type", ""))}]
	_post(events)
	return events


## Housekeeping after every command: deaths cancel scheduled actions, breach
## checks run, exposure caches refresh, events get the tick stamp.
func _post(events: Array[Dictionary]) -> void:
	# KAN-5 K1 (zones) — the position sweep: on_pass off this batch's dash
	# corridors, on_enter off the post-command position diff (the ONE seam
	# every position mutation flows past — zones.gd documents the choice).
	# Runs FIRST so zone-authored deaths get the same housekeeping (cancel /
	# breach / broadcast) as any other batch event, and a zone-triggered Shock
	# shout reaches the stealth sweep below. No-op (no events, no rng, no
	# state) while no zone store exists — the legacy compat pin.
	if zones != null:
		events.append_array(zones.position_sweep(events, clock.tick))
	for event: Dictionary in events.duplicate():
		if String(event.get("type", "")) == "combatant_died":
			var dead_id := String(event.get("combatant", ""))
			clock.cancel_for(dead_id)
			ai.explosion_beats.erase(dead_id)  # a dead boss never runs beats (#27)
			var dead: CombatantState = combatants.get(dead_id)
			if dead != null:
				dead.windup_pending = false
	# Breach (incl. non-advance damage like reactions) + boss phase machine.
	events.append_array(_breach_and_phase_checks())
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		events.append_array(ExposureEngine.refresh(combatants[id], clock.tick))
	# R20 (wave 4c): the stealth sweep — every command re-checks every stealthed
	# combatant (sight / shout / downed) BEFORE the broadcast plane ingests, so
	# hype/tags/evidence see stealth_broken too. No-op (no events, no rng, no
	# state) while nobody is stealthed — the legacy compat pin.
	events.append_array(_stealth_checks(events))
	# Batch B (retarget_guard) — the guard sweep: every command re-checks every
	# held iron stance (moved off the anchor / Prone / downed breaks it — the
	# dance-exit pattern) and every armed intercept guard (guardian or guarded
	# ally down clears it). Runs BEFORE the broadcast plane ingests so
	# hype/tags/evidence see the break events too. No-op (no events, no rng,
	# no state) while nobody holds either — the legacy compat pin.
	events.append_array(_guard_checks())
	# Batch D (telekinesis) — the channel sweep: a sustainer damaged in THIS
	# command's batch (damage_applied events — resolutions, reactions, forced
	# fallout and condition drains alike), grappled, helpless or down — or
	# whose held target is gone — loses the grip (release_channel keeps the
	# held_by mirror in sync). BEFORE the broadcast plane so the release is
	# scored/seen too. No-op while nobody channels — the legacy compat pin.
	events.append_array(_channel_checks(events))
	# ---- R20 HEARING (round 3b) — the NOISE sweep: its own bounded region. --
	# Reads THIS command's event batch, derives its noise rows (the Stealth
	# loudness table) and alerts AI hearers of noises from sources still
	# HIDDEN at sweep time; also runs the alert decay. AFTER the state sweeps
	# above (stealth first — a shouter/seen hider is already revealed, i.e.
	# default-detected, before noise is consumed) and BEFORE the broadcast
	# plane, so hype/tags/evidence can see noise_heard / alerted /
	# alert_cleared too. No-op (no events, no rng, no state) while nobody is
	# hidden AND nobody is alerted — the legacy compat pin.
	events.append_array(_noise_checks(events))
	# ---- end hearing. -------------------------------------------------------
	# Batch D (play_to_the_camera): close an outlived surge window BEFORE this
	# batch is scored — expiry is tick-driven, scoring must never read a stale
	# window. No-op while none is live — the legacy compat pin.
	events.append_array(hype.expire_surge(clock.tick))
	events.append_array(hype.ingest(events))
	# Tag detection runs AFTER hype so Scene Stealer sees hype_goal_completed /
	# hype_camera_call_started. Its tag_* outputs are system events (no
	# spectacle_points), so a second hype pass is unneeded; The Bit's escalating
	# spectacle already rides the bit_performed event hype scored above.
	events.append_array(tags.ingest(events))
	# Evidence ledger runs LAST so it can see hype_* and tag_* outputs too. Its
	# evidence_* outputs carry no spectacle_points and no engine rescans them.
	events.append_array(evidence.ingest(events))
	for event: Dictionary in events:
		if not event.has("tick"):
			event["tick"] = clock.tick


## Breach hooks (Resistance.check_breach — single-hit burst per R15/NQ2, so a
## combined action's merged hit is the party's path to 7+) + the boss phase
## machine (R11 #18). Runs in _post after every command AND inside _advance_tick
## BEFORE the per-tick flags reset — single-hit/burst breach data must be
## evaluated on the tick it happened. Both flags latch (breached / boss_phase),
## so the double sweep never double-fires.
func _breach_and_phase_checks() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if Resistance.check_breach(c):
			c.breached = true
			var part_keys: Array = c.parts.keys()
			part_keys.sort()
			for part_key: Variant in part_keys:
				var part: Dictionary = c.parts[part_key]
				if bool(part.get("hidden", false)):
					part["hidden"] = false
			events.append({"type": "breach_opened", "combatant": c.id})
		events.append_array(ai.phase_events(c, cond))
	# Death-spin abort sweep (wave 2b) — AFTER the phase machine so an entry
	# into an explosion valve this very command aborts a live spin immediately
	# (the valve outranks, #27 precedent). Idempotent like the latching flags.
	events.append_array(ai.death_spin_checks())
	return events


# ------------------------------------------------------------------ commands

func _add_combatant(spec: Dictionary) -> Array[Dictionary]:
	var id := String(spec.get("id", ""))
	if id == "":
		return [{"type": "command_rejected", "reason": "missing_id"}]
	if combatants.has(id):
		return [{"type": "command_rejected", "reason": "duplicate_id", "combatant": id}]
	# KAN-5 staging honesty: with an arena set, a spawn must land inside the
	# bounds and off walls/objects (rejected at add time — GameController
	# stages the arena BEFORE the add batch so every spawn is checked).
	if arena != null:
		var pos_raw: Array = spec.get("position", [0, 0])
		var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
		if not arena.in_bounds(pos):
			return [{"type": "command_rejected", "reason": "staging_out_of_bounds", "combatant": id, "position": [pos.x, pos.y]}]
		# Wave 4b (R29): a doorway is never a spawn hex, open OR closed —
		# authored staging must keep doors workable (checked before the wall
		# gate so a closed door reports the door-specific reason too).
		if arena.door_index_at(pos) >= 0:
			return [{"type": "command_rejected", "reason": "staging_on_door_hex", "combatant": id, "position": [pos.x, pos.y]}]
		if arena.is_wall(pos) or arena.object_index_at(pos) >= 0:
			return [{"type": "command_rejected", "reason": "staging_blocked_hex", "combatant": id, "position": [pos.x, pos.y]}]
	var c := CombatantState.from_spec(spec, static_data)
	c.next_action_tick = clock.tick
	# R30 staging default (decision #33 — deterministic, documented): a fresh
	# combatant faces its NEAREST opponent at add time (hex distance; an exact
	# tie keeps the earliest sorted id), else direction 0 (E). Applies to every
	# add — staged rosters and mid-fight summons alike (a brood spawn faces the
	# fight it joins). The update table (ActionResolver) owns every later change.
	c.facing = _staging_facing(c)
	combatants[id] = c
	tick_snapshot[id] = _snapshot_entry(c)
	var events: Array[Dictionary] = [{"type": "combatant_added", "combatant": id}]
	return events


## The R30 staging default: the HexGeometry direction index toward the nearest
## living, in-play OPPONENT (the _opponents hostility predicate: a different
## team, where teamless-vs-teamless is not hostile), else 0. Sorted-id
## iteration + first-wins ties keep it deterministic; pure over current state.
func _staging_facing(c: CombatantState) -> int:
	var best: CombatantState = null
	var best_d: int = 0
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.team == c.team:
			continue  # covers teamless-vs-teamless ("" == "") too
		if not other.alive or other.removed_from_play:
			continue
		var d: int = CombatantState.hex_distance(c.position, other.position)
		if best == null or d < best_d:
			best = other
			best_d = d
	if best == null:
		return 0
	var idx: int = HexGeometry.direction_index(c.position, best.position)
	return idx if idx >= 0 else 0


## R15 — multi-character combined action: a set of LINKED declarations resolving
## on the same tick (R2 simultaneity is the substrate; each actor pays its own
## Moment cost). Assist `provides` stats satisfy partners' requirements; linked
## strikes on the same target+part MERGE FORCE into one gate + one net hit
## (ActionResolver merged-force pre-scan), and linked hits merge for breach
## thresholds (CombatantState.record_hit). A Forced Action on one member degrades
## only that member — the rest still resolve. Members must share ONE nominal
## Moment cost (instants OR equal-cost windups like two cost-2 skills) so they
## resolve on the same tick; a per-actor cost penalty (Exhausted) can still
## desync them, in which case the strikes resolve separately and simply don't
## merge — the resolve-tick pre-scan is the authority, this gate is the courtesy.
## members: [{"actor", "action": {..., "provides"?}}...]. An explicit_combo_id
## ("" = auto) lets a caller name the link (e.g. the HUD's "party_combo").
func _combined_action(members: Array, explicit_combo_id: String = "") -> Array[Dictionary]:
	if members.size() < 2:
		return [{"type": "command_rejected", "reason": "combo_needs_two_members"}]
	var provides: Dictionary = {}
	var seen: Dictionary = {}
	var member_ids: Array[String] = []
	var shared_cost: int = -1
	for member: Variant in members:
		var md: Dictionary = member
		var aid := String(md.get("actor", ""))
		if aid == "" or not combatants.has(aid):
			return [{"type": "command_rejected", "reason": "combo_unknown_actor", "actor": aid}]
		if seen.has(aid):
			return [{"type": "command_rejected", "reason": "combo_duplicate_actor", "actor": aid}]
		seen[aid] = true
		member_ids.append(aid)
		var act: Dictionary = md.get("action", {})
		var cost: int = _member_nominal_cost(act)
		if shared_cost < 0:
			shared_cost = cost
		elif cost != shared_cost:
			return [{"type": "command_rejected", "reason": "combo_requires_same_tick", "actor": aid}]
		var member_provides: Dictionary = act.get("provides", {})
		for key: Variant in member_provides:
			provides[String(key)] = maxi(int(provides.get(String(key), 0)), int(member_provides[key]))
	var combo_id := explicit_combo_id
	if combo_id == "":
		combo_id = "combo:%d:%d" % [clock.tick, clock.next_seq]
	var events: Array[Dictionary] = [{
		"type": "combined_action_declared", "combo_id": combo_id, "members": member_ids,
	}]
	for member: Variant in members:
		var md: Dictionary = member
		var act: Dictionary = (md.get("action", {}) as Dictionary).duplicate(true)
		act["combo_id"] = combo_id
		act["combo_provides"] = provides.duplicate(true)
		events.append_array(resolver.declare(String(md.get("actor", "")), act))
	return events


## A combo member's nominal Moment cost, mirroring ActionResolver._base_cost's
## defaults: an explicit action.cost wins; a skill falls back to its SkillBook
## spec cost; everything else defaults to 1 (the members are strikes).
func _member_nominal_cost(act: Dictionary) -> int:
	if act.has("cost"):
		return int(act["cost"])
	if String(act.get("kind", "")) == "skill":
		var spec: Dictionary = SkillBook.mechanics(String(act.get("key", "")), int(act.get("level", 1)))
		return int(spec.get("cost", 1))
	return 1


## R1 order of operations for the CURRENT tick:
## 1. resolve all actions due this tick (against the tick-start snapshot),
## 2. apply Forced-Action consequences queued by step 1,
## 3. if this tick completes a Clock: universal condition advancement (R4),
## 4. advance to the next tick and re-snapshot.
func _advance_tick() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var result: Dictionary = resolver.resolve_due(tick_snapshot)
	events.append_array(result["events"])
	for queued: Variant in result["forced"] as Array:
		var forced: Dictionary = queued
		var actor: CombatantState = combatants.get(String(forced.get("actor", "")))
		if actor == null:
			continue
		events.append_array(ForcedAction.apply_consequence(
			forced["rolled"], actor, forced.get("ctx", {}), cond, combatants, clock.tick))
	# Batch D (telekinesis) — the per-Moment upkeep lapse: a live channel whose
	# grip/sustain did NOT resolve on this completing tick (nothing declared,
	# or the sustain was feinted/stuttered/invalidated away) lapses at the END
	# of the unpaid Moment — the target was genuinely held through it (nobody
	# knew the upkeep would fail until the Moment closed), then the
	# concentration runs out with the tick. Sorted-id order, zero rng; a
	# channel-free fight never enters the loop (the legacy compat pin).
	var channel_ids: Array = combatants.keys()
	channel_ids.sort()
	for channel_id: Variant in channel_ids:
		var holder: CombatantState = combatants[channel_id]
		if holder.channeling.is_empty():
			continue
		if int(holder.channeling.get("sustained_tick", -1)) < clock.tick:
			events.append_array(resolver.release_channel(holder, "sustain_lapsed"))
	if clock.completes_clock():
		events.append({"type": "clock_reset", "tick": clock.tick})
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			events.append_array(cond.on_clock_reset(combatants[id], clock.tick))
		events.append_array(_antagonism_decay())
		events.append_array(_pattern_read_expiry())
		# KAN-5 K1 (zones) — the Clock-boundary sweep: on_occupy_clock for
		# every occupant (AFTER the universal condition advancement above, so
		# a fresh zone application advances at the NEXT reset, not its own),
		# then the duration countdown/expiry (zones.gd documents the order —
		# a 1-Clock wall bites its occupants at the reset that kills it).
		# No-op while no zone store exists — the legacy compat pin.
		if zones != null:
			events.append_array(zones.clock_reset_sweep(clock.tick))
		# K2 (R33) — the WATER substrate marker: a living, in-play combatant
		# OCCUPYING a water hex when the Clock resets is submersion-exposed —
		# the sim EMITS in_water and mutates NOTHING (no state, no timer, no
		# rng). The honest boundary: the R9-family suffocation interaction is
		# condition/resolver scope — the swim story reads this marker and
		# wires the timers; inventing them here would price a system the
		# ladder owns. No-op without authored water (the legacy compat pin —
		# terrain-less fights never enter the loop).
		if arena != null and not arena.terrain.is_empty():
			var water_ids: Array = combatants.keys()
			water_ids.sort()
			for water_id: Variant in water_ids:
				var swimmer: CombatantState = combatants[water_id]
				if swimmer.alive and not swimmer.removed_from_play \
						and arena.terrain_at(swimmer.position) == "water":
					events.append({"type": "in_water", "combatant": swimmer.id,
						"position": [swimmer.position.x, swimmer.position.y]})
	# Breach/phase state must be read BEFORE the per-tick flag reset below:
	# single-hit/burst breaches (R15/NQ2) and reset-driven condition tiers
	# belong to the completing tick (I-16; _post re-runs this harmlessly).
	events.append_array(_breach_and_phase_checks())
	# Everything above happened ON the completing tick — stamp before advancing.
	for event: Dictionary in events:
		if not event.has("tick"):
			event["tick"] = clock.tick
			event["moment"] = clock.moment()
	clock.advance()
	var all_ids: Array = combatants.keys()
	all_ids.sort()
	for id: Variant in all_ids:
		var c: CombatantState = combatants[id]
		c.reset_tick_flags()
		c.windup_pending = clock.has_windup_for(c.id)
	events.append({"type": "clock_moment_changed", "tick": clock.tick, "moment": clock.moment()})
	_rebuild_snapshot()
	return events


## R23 grudge decay at the Clock boundary: every AI combatant's antagonism
## scores multiply by its personality decay (default 1.0 = no decay —
## incinedile keeps 1.0, it remembers pain). Event policy (documented choice):
## ONE summary antagonism_changed per actor whose map actually changed —
## {"actor", "source": "decay", "factor", "scores": the full new map} — no
## per-target delta rows; decay 1.0 or an empty map emits nothing. Sorted-id
## iteration + sorted score keys keep it deterministic.
func _antagonism_decay() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not EnemyAI.is_ai_controlled(c) or c.antagonism.is_empty():
			continue
		var decay: float = c.personality_decay()
		if is_equal_approx(decay, 1.0):
			continue
		var keys: Array = c.antagonism.keys()
		keys.sort()
		for key: Variant in keys:
			c.antagonism[key] = float(c.antagonism[key]) * decay
		events.append({
			"type": "antagonism_changed", "actor": c.id, "source": "decay",
			"factor": decay, "scores": c.antagonism.duplicate(true),
		})
	return events


## Batch C (read_the_pattern): the reveal lives "until the next Clock reset"
## verbatim — this reset sweep clears every live reveal and says so (one
## pattern_read_expired per actor->target pair, sorted both ways —
## deterministic). No-op (no events, no state) while nobody holds a reveal —
## the legacy compat pin, mirroring the stealth/guard sweeps.
func _pattern_read_expiry() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if c.pattern_reads.is_empty():
			continue
		var targets: Array = c.pattern_reads.keys()
		targets.sort()
		for target_id: Variant in targets:
			events.append({"type": "pattern_read_expired", "actor": c.id, "target": String(target_id)})
		c.pattern_reads = {}
	return events


func _treat(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var mode := String(cmd.get("mode", "delay"))
	if mode != "delay" and mode != "resolve":
		return [{"type": "command_rejected", "reason": "unknown_treat_mode", "mode": mode}]
	return cond.treat(target, String(cmd.get("part", "")), String(cmd.get("condition", "")), mode)


func _heal(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	return cond.heal_part(target, String(cmd.get("part", "")), int(cmd.get("amount", 0)))


func _apply_condition(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var ctx: Dictionary = {"source": "direct"}
	if cmd.has("tier"):
		ctx["tier"] = int(cmd["tier"])
	if cmd.has("poison_type"):
		ctx["poison_type"] = String(cmd["poison_type"])
	if cmd.has("activation_delay"):
		ctx["activation_delay"] = int(cmd["activation_delay"])
	return cond.apply(target, String(cmd.get("part", "")), String(cmd.get("condition", "")), clock.tick, ctx)


func _grant_level(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor"}]
	actor.level_points += 1
	var events: Array[Dictionary] = [{"type": "level_granted", "combatant": actor.id, "pool": actor.level_points}]
	return events


## R6: a level point buys +1 levelBonus on any one trait; a Physique threshold
## crossing also raises every part's max (and current) HP.
func _spend_level_point(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor"}]
	var trait_key := String(cmd.get("trait", ""))
	if not CombatantState.TRAIT_KEYS.has(trait_key):
		return [{"type": "command_rejected", "reason": "unknown_trait", "trait": trait_key}]
	if actor.level_points <= 0:
		return [{"type": "command_rejected", "reason": "no_level_points"}]
	var hp_bonus_before: int = actor.hp_bonus_per_part()
	actor.level_points -= 1
	var stat: Dictionary = actor.stats[trait_key]
	stat["level_bonus"] = int(stat.get("level_bonus", 0)) + 1
	var events: Array[Dictionary] = [{
		"type": "level_point_spent", "combatant": actor.id, "trait": trait_key,
		"total": actor.trait_total(trait_key), "pool": actor.level_points,
	}]
	var hp_gain: int = actor.hp_bonus_per_part() - hp_bonus_before
	if hp_gain > 0:
		var part_keys: Array = actor.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			var part: Dictionary = actor.parts[part_key]
			part["hp"] = int(part["hp"]) + hp_gain
		events.append({"type": "max_hp_increased", "combatant": actor.id, "per_part": hp_gain})
	return events


## Camera Call (compendium §2.2/§11; stacks per R6's Charm over-cap formula).
## The sim validates the participants — same actor gates and rejection
## vocabulary as ActionResolver.declare (alive → removed → helpless, R11 #13);
## stack accounting + the spotlight effect live in the HypeEngine (broadcast
## plane).
func _camera_call(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target", "target": String(cmd.get("target", ""))}]
	if not actor.alive:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "removed_from_play", "actor": actor.id}]
	if actor.is_helpless(clock.tick):
		return [{"type": "command_rejected", "reason": "helpless", "actor": actor.id}]
	if not target.alive:
		return [{"type": "command_rejected", "reason": "target_dead", "target": target.id}]
	if target.removed_from_play:
		return [{"type": "command_rejected", "reason": "target_removed_from_play", "target": target.id}]
	var stacks: int = int(actor.derived_stats().get("camera_call_stacks", 0))
	return hype.camera_call(actor.id, target.id, stacks)


## The Bit (I-13, RULED item 8) — the signature action that is MECHANICALLY NULL
## by construction, with ONE deliberate, ruled exception (owner, anti-spam
## ruling): it is a FREE ACTION and pays R3's free-action economy — one free
## (0-Moment) action per combatant per tick, the same slot 0-cost declares,
## free moves, first inventory uses and 0-cost reactions consume. The slot IS
## the cost: a second bit the same tick rejects "free_action_used", and doing
## the bit forfeits the tick's free move / inventory / reaction (and vice
## versa). Beyond that slot flag it still touches NO combatant state, the
## clock, the action RNG, scheduling, Moment cost, or conditions. Its ONLY
## other effect is one self-describing bit_performed event carrying escalating
## spectacle_points (base + bonus per prior bit this deployment, from the
## TagEngine rider) — scored by HypeEngine's generic spectacle hook, detected
## by TagEngine for the_bit. The escalation survives across ticks (progress is
## tag state), so the running joke still builds — one beat per Moment.
## Rejections mutate nothing; contestants only.
##
## AUTHORED bit (decision log #25): a bit is per-character authored content —
## not everyone has one. An actor whose spec carried no bit is rejected
## ("no_bit"); on success the event names WHICH bit was performed ("bit" =
## authored key, "bit_name" = display name) alongside the pre-existing
## "key"/"spectacle_points" fields, kept verbatim for compatibility.
func _bit(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	if EnemyAI.AI_CATEGORIES.has(actor.category):
		return [{"type": "command_rejected", "reason": "not_a_contestant", "actor": actor.id}]
	if not actor.alive or actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.bit.is_empty():
		return [{"type": "command_rejected", "reason": "no_bit", "actor": actor.id}]
	# R3 free-action economy (anti-spam ruling): one free action per tick — the
	# bit consumes the slot, so it competes with the free move / inventory /
	# 0-cost reactions and can never be spammed within a Moment.
	if actor.free_action_used:
		return [{"type": "command_rejected", "reason": "free_action_used", "actor": actor.id}]
	actor.free_action_used = true
	return [{
		"type": "bit_performed",
		"actor": actor.id,
		"key": String(cmd.get("key", "bit")),
		"bit": String(actor.bit.get("key", "")),
		"bit_name": String(actor.bit.get("name", "")),
		"spectacle_points": tags.bit_spectacle(actor.id),
	}]


func _set_status(cmd: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(cmd.get("target", "")))
	if target == null:
		return [{"type": "command_rejected", "reason": "unknown_target"}]
	var status := String(cmd.get("status", ""))
	if not ["overwhelmed", "prone", "slowed"].has(status):
		return [{"type": "command_rejected", "reason": "unknown_status", "status": status}]
	var value: bool = bool(cmd.get("value", true))
	if value:
		target.statuses[status] = true
	else:
		target.statuses.erase(status)
	var events: Array[Dictionary] = [{"type": "status_changed", "combatant": target.id, "status": status, "value": value}]
	return events


## Prime substrate (rules-addendum R3, decision-log #20 — "cooldowns do not
## exist"). A 0-cost STANCE declaration: sets actor.stance ("" clears). Outside
## the action economy (no Moment cost, no free-slot); the STANCE prime predicate
## in ActionResolver reads actor.stance.
func _set_stance(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	var stance := String(cmd.get("stance", ""))
	actor.stance = stance
	return [{"type": "stance_changed", "actor": actor.id, "stance": stance}]


## Prime substrate (R3, PREP-CHANNEL): arms actor.armed_primes[key]. Using a
## prep-gated action consumes it (ActionResolver clears it at resolve).
func _prime(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	var key := String(cmd.get("key", ""))
	if key == "":
		return [{"type": "command_rejected", "reason": "missing_prime_key", "actor": actor.id}]
	actor.armed_primes[key] = true
	return [{"type": "prime_armed", "actor": actor.id, "key": key}]


## KAN-5 (wave 3d; doors wave 4b) — the OPT-IN arena command. Validates the
## authored config (simulation/arena.gd shape), then that walls/objects/doors
## sit inside the bounds and off each other, then that every ALREADY-STAGED
## combatant remains on a legal non-door hex (staging order puts set_arena
## before the add batch, so this guard matters only for late/manual sets). On
## success the arena is wired into the EnemyAI + ActionResolver movement/lane
## paths and serialized under "arena" (hash-covered). Rejections mutate nothing.
func _set_arena(cmd: Dictionary) -> Array[Dictionary]:
	if arena != null:
		return [{"type": "command_rejected", "reason": "arena_already_set"}]
	var parsed: Arena = Arena.from_config(cmd.get("arena", {}))
	if parsed == null:
		return [{"type": "command_rejected", "reason": "invalid_arena"}]
	for wall: Vector2i in parsed.sorted_walls():
		if not parsed.in_bounds(wall):
			return [{"type": "command_rejected", "reason": "arena_wall_out_of_bounds", "hex": [wall.x, wall.y]}]
	var object_hexes: Dictionary = {}
	for obj: Dictionary in parsed.objects:
		var pos_raw: Array = obj.get("position", [])
		var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
		if not parsed.in_bounds(pos) or parsed.is_wall(pos) or object_hexes.has(pos):
			return [{"type": "command_rejected", "reason": "arena_object_misplaced", "hex": [pos.x, pos.y]}]
		object_hexes[pos] = true
	# Wave 4b (R29) door placement: in bounds, off authored walls (the walls
	# dict directly — is_wall would see the door's own closed state), off
	# objects, one door per hex. Key shape/uniqueness gated by from_config.
	var door_hexes: Dictionary = {}
	for door: Dictionary in parsed.doors:
		var door_pos_raw: Array = door.get("position", [])
		var door_pos := Vector2i(int(door_pos_raw[0]), int(door_pos_raw[1]))
		if not parsed.in_bounds(door_pos) or parsed.walls.has(door_pos) \
				or object_hexes.has(door_pos) or door_hexes.has(door_pos):
			return [{"type": "command_rejected", "reason": "arena_door_misplaced", "hex": [door_pos.x, door_pos.y]}]
		door_hexes[door_pos] = true
	# K2 (R33) terrain placement: typed hexes in bounds and off walls/objects
	# (typing solid rock or a can's hex is an authoring error; a DOORWAY may
	# legally carry terrain — an open door is floor). One-type-per-hex and the
	# type enum are shape gates in from_config; the validator mirrors all of it.
	for terrain_hex: Vector2i in parsed.sorted_terrain_hexes():
		if not parsed.in_bounds(terrain_hex) or parsed.walls.has(terrain_hex) \
				or object_hexes.has(terrain_hex):
			return [{"type": "command_rejected", "reason": "arena_terrain_misplaced", "hex": [terrain_hex.x, terrain_hex.y]}]
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not parsed.in_bounds(c.position) or parsed.is_wall(c.position) \
				or parsed.object_index_at(c.position) >= 0 \
				or parsed.door_index_at(c.position) >= 0:
			return [{"type": "command_rejected", "reason": "combatant_outside_arena",
				"combatant": c.id, "position": [c.position.x, c.position.y]}]
	arena = parsed
	ai.arena = arena
	resolver.arena = arena
	# KAN-5 K1: a late-set arena inherits any existing zone store (the normal
	# staging order puts set_arena before any zone exists; zone placement is
	# validated against the arena present at CREATION time — documented).
	arena.zones = zones
	var summary: Dictionary = arena.view()
	var arena_event: Dictionary = {
		"type": "arena_set",
		"bounds": summary["bounds"],
		"walls": summary["walls"],
		"objects": summary["objects"],
	}
	# Wave 4b compat pin: "doors" rides the event only when authored.
	if summary.has("doors"):
		arena_event["doors"] = summary["doors"]
	# K2 compat pin: "terrain" rides the event only when authored.
	if summary.has("terrain"):
		arena_event["terrain"] = summary["terrain"]
	return [arena_event]


## KAN-5 wave 4b (rules-addendum R29) — the door command: an adjacent, alive/
## ready combatant flips an authored door for its FREE-ACTION SLOT (R3, the
## inventory-interaction family — the slot IS the cost; v1 grants no
## Moment-cost fallback, so a second door interaction the same tick rejects
## free_action_used like any second free action). The state flip is the ONLY
## mutation: a closed door then blocks through Arena.is_wall (movement, dash
## lanes, bounces — one code path), an open one blocks nothing. Closing needs
## the doorway clear of live bodies. Enemies never issue it in v1 (the AI
## never decides doors — documented, no enemy_ai path). Rejections mutate
## nothing; door_changed carries the flip.
func _door(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	if not actor.alive:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "removed_from_play", "actor": actor.id}]
	if actor.is_helpless(clock.tick):
		return [{"type": "command_rejected", "reason": "helpless", "actor": actor.id}]
	if arena == null:
		return [{"type": "command_rejected", "reason": "no_arena", "actor": actor.id}]
	var key := String(cmd.get("key", ""))
	var idx: int = arena.door_index_for(key)
	if idx < 0:
		return [{"type": "command_rejected", "reason": "unknown_door", "actor": actor.id, "key": key}]
	var to_state := String(cmd.get("set", ""))
	if to_state != "open" and to_state != "closed":
		return [{"type": "command_rejected", "reason": "unknown_door_state", "actor": actor.id, "set": to_state}]
	var door: Dictionary = arena.doors[idx]
	var pos_raw: Array = door.get("position", [])
	var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
	if CombatantState.hex_distance(actor.position, pos) != 1:
		return [{"type": "command_rejected", "reason": "door_not_adjacent", "actor": actor.id, "key": key}]
	if String(door.get("state", "")) == to_state:
		return [{"type": "command_rejected", "reason": "door_already_" + to_state, "actor": actor.id, "key": key}]
	# K2 (R33): a LOCKED door cannot be worked — the ask this gate really
	# meets is "open" (a locked door only exists closed, so "closed" already
	# rejected door_already_closed above). Checked BEFORE the free slot so a
	# rattled locked handle never wastes the actor's tick; the pick path is
	# the internal pick_lock API (no command this story — documented there).
	if Arena.door_locked(door):
		return [{"type": "command_rejected", "reason": "door_locked", "actor": actor.id,
			"key": key, "tier": String((door.get("lock", {}) as Dictionary).get("tier", ""))}]
	if to_state == "closed":
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			var body: CombatantState = combatants[id]
			if body.alive and not body.removed_from_play and body.position == pos:
				return [{"type": "command_rejected", "reason": "door_blocked_by_body",
					"actor": actor.id, "key": key, "by": body.id}]
	# R3 free-action economy: one free action per tick — checked LAST so a
	# rejection for a bad ask never wastes the slot; the flip consumes it.
	if actor.free_action_used:
		return [{"type": "command_rejected", "reason": "free_action_used", "actor": actor.id}]
	actor.free_action_used = true
	door["state"] = to_state
	return [{
		"type": "door_changed",
		"actor": actor.id,
		"key": key,
		"position": [pos.x, pos.y],
		"state": to_state,
	}]


## K2 (rules-addendum R33) — the INTERNAL lock-pick resolution, deliberately
## NOT a command this story (the honest downscope, mirroring create_zone):
## picking costs MOMENTS by tier (Arena.LOCK_PICK_MOMENTS — the lockpicking
## ladder's "2 Moments per attempt" scale), and a Moments-costed act is a
## SCHEDULED action — declare/resolve, feint-able, Forced-Action-on-failure —
## which is ActionResolver territory. Scheduling it from a raw sim command
## would either bypass that machinery (dishonest) or re-implement it here
## (worse). So the substrate ships the lock MODEL + the door_locked rejection
## + THIS resolution API; the lockpicking SKILL (next story, resolver-side)
## declares the pick, pays the Moments through the normal schedule, and calls
## this at resolve. Tests/GM drivers may call it directly between commands
## (the create_zone precedent: direct-call events carry no tick stamp and
## skip the broadcast plane — no engine scores lock_picked today, so the two
## call shapes stay behaviorally identical). Gates mirror the door command
## (actor alive/ready + ADJACENT); `special` is the capability flag a MAGICAL
## lock additionally requires (the L9 rung — the substrate only enforces that
## the flag exists; what grants it is the skill's business). The state flip
## is the ONLY mutation — no slot, no Moments are charged HERE (the `moments`
## field on lock_picked REPORTS the tier price for the future scheduler; a
## direct call is a GM fiat until the skill lands). Rejections mutate nothing.
func pick_lock(actor_id: String, key: String, special: bool = false) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(actor_id)
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": actor_id}]
	if not actor.alive:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "removed_from_play", "actor": actor.id}]
	if actor.is_helpless(clock.tick):
		return [{"type": "command_rejected", "reason": "helpless", "actor": actor.id}]
	if arena == null:
		return [{"type": "command_rejected", "reason": "no_arena", "actor": actor.id}]
	var idx: int = arena.door_index_for(key)
	if idx < 0:
		return [{"type": "command_rejected", "reason": "unknown_door", "actor": actor.id, "key": key}]
	var door: Dictionary = arena.doors[idx]
	var pos_raw: Array = door.get("position", [])
	var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
	if CombatantState.hex_distance(actor.position, pos) != 1:
		return [{"type": "command_rejected", "reason": "door_not_adjacent", "actor": actor.id, "key": key}]
	if not door.has("lock"):
		return [{"type": "command_rejected", "reason": "no_lock", "actor": actor.id, "key": key}]
	var lock: Dictionary = door.get("lock", {})
	if String(lock.get("state", "")) != "locked":
		return [{"type": "command_rejected", "reason": "lock_already_unlocked", "actor": actor.id, "key": key}]
	var tier := String(lock.get("tier", ""))
	if tier == "magical" and not special:
		return [{"type": "command_rejected", "reason": "magical_lock_needs_special", "actor": actor.id, "key": key}]
	lock["state"] = "unlocked"
	return [{
		"type": "lock_picked",
		"actor": actor.id,
		"key": key,
		"position": [pos.x, pos.y],
		"tier": tier,
		"moments": int(Arena.LOCK_PICK_MOMENTS.get(tier, 0)),
	}]


## R20 (KAN-5 wave 4c) — the stealth command (contract in the class header;
## design + downscopes in the rules-addendum R20 IMPLEMENTED marker). HIDE
## gates in rejection-priority order (actor gates → state gates → the sight
## gate → the free-action slot LAST, so a rejected ask never wastes the slot —
## the door precedent); REVEAL is free. Rejections mutate nothing.
func _stealth(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	if not actor.alive:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "removed_from_play", "actor": actor.id}]
	if actor.is_helpless(clock.tick):
		return [{"type": "command_rejected", "reason": "helpless", "actor": actor.id}]
	var to_state := String(cmd.get("set", "hide"))
	if to_state != "hide" and to_state != "reveal":
		return [{"type": "command_rejected", "reason": "unknown_stealth_state", "actor": actor.id, "set": to_state}]
	if to_state == "reveal":
		if not actor.stealthed:
			return [{"type": "command_rejected", "reason": "not_stealthed", "actor": actor.id}]
		actor.stealthed = false
		actor.conceal = {}  # batch D: the camouflage modifier dies with the stealth
		return [{"type": "stealth_broken", "combatant": actor.id, "reason": "revealed_self"}]
	if actor.stealthed:
		return [{"type": "command_rejected", "reason": "already_stealthed", "actor": actor.id}]
	# R9 links are physical contact — the R20 binary ("if you are seen, you are
	# not stealthed") cannot be entered while an enemy literally holds you (and
	# holding someone means they know exactly where you are).
	if actor.grappling != "" or actor.grappled_by != "":
		return [{"type": "command_rejected", "reason": "in_grapple", "actor": actor.id}]
	var observer: String = Stealth.first_observer_seeing(combatants, actor, arena, clock.tick)
	if observer != "":
		return [{"type": "command_rejected", "reason": "in_enemy_sight", "actor": actor.id, "observer": observer}]
	# R3 free-action economy: checked LAST so a rejected ask never wastes the
	# slot; the hide consumes it (one free action per tick — the door family).
	if actor.free_action_used:
		return [{"type": "command_rejected", "reason": "free_action_used", "actor": actor.id}]
	actor.free_action_used = true
	actor.stealthed = true
	return [{"type": "stealth_entered", "actor": actor.id}]


# ------------------------------------------------------------------ zones (KAN-5 K1)

## The INTERNAL zone API — deliberately NO player/GM command surface this
## story: the future wall-skill resolvers call these from inside their own
## command (whose _post then folds the zone events into the batch); tests and
## drivers may call them directly between commands (direct-call events carry
## no tick stamp and skip the broadcast plane — none of today's engines score
## zone_* events, so the two call shapes stay behaviorally identical).
## simulation/zones.gd owns the model, the validation, the effect vocabulary
## and every seam decision; this facade owns the store lifecycle + wiring.
func create_zone(spec: Dictionary) -> Array[Dictionary]:
	if zones == null:
		zones = Zones.new()
		zones.setup(combatants, cond)
	var events: Array[Dictionary] = zones.create(spec, clock.tick, arena)
	# Wire the arena's blocking composition once zones exist (idempotent).
	if arena != null:
		arena.zones = zones
	return events


func remove_zone(zone_id: int, reason: String = "removed") -> Array[Dictionary]:
	if zones == null:
		return [{"type": "zone_rejected", "reason": "zone_unknown", "zone": zone_id}]
	return zones.remove(zone_id, reason)


## Frost-wall HP wear — the ONLY hp path this story (attackability needs
## resolver targeting: next story). Removal at 0 (zone_expired "destroyed").
func damage_zone(zone_id: int, amount: int) -> Array[Dictionary]:
	if zones == null:
		return [{"type": "zone_rejected", "reason": "zone_unknown", "zone": zone_id}]
	return zones.damage(zone_id, amount)


## R20 (wave 4c) — the per-command stealth sweep (called from _post): breaks
## every stealthed combatant that is now DOWNED (death/removal — a body is not
## hidden), SHOUTED (Shock T1, the R13 "breaks stealth" noise seed — the
## shock_shout events of THIS command's batch), or SEEN (the binary sight
## check — any living hostile that can act with range + LOS; both sides'
## movement, door flips, an observer recovering... all funnel through here
## because _post runs after every command). Deterministic and rng-FREE — R20
## authors no detection roll, so the sweep never touches either rng stream;
## with nobody stealthed it is a pure no-op (the legacy byte-compat pin).
## Breaking one stealth never changes another's visibility (a stealthed body
## blocks no sight line), so a single pass is complete.
func _stealth_checks(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var shouters: Dictionary = {}
	for event: Dictionary in events:
		if String(event.get("type", "")) == "shock_shout":
			shouters[String(event.get("combatant", ""))] = true
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not c.stealthed:
			# Batch D (camouflage) invariant: the modifier never outlives the
			# stealth it rides — a dangling conceal is cleared silently.
			if not c.conceal.is_empty():
				c.conceal = {}
			continue
		if not c.alive or c.removed_from_play:
			c.stealthed = false
			c.conceal = {}
			out.append({"type": "stealth_broken", "combatant": c.id, "reason": "downed"})
			continue
		# Batch D (camouflage): the MOVEMENT break — any displacement off the
		# woven anchor hex (voluntary or involuntary, the iron_stance rule)
		# breaks the camouflage AND the stealth it rides ("Breaks if character
		# moves"; the L6 move-one-hex rung stays threshold data). Checked
		# before the sight sweep: the mover is revealed by the movement
		# itself, whoever is watching.
		if not c.conceal.is_empty():
			var anchor_raw: Array = c.conceal.get("anchor", [])
			if anchor_raw.size() != 2 \
					or c.position != Vector2i(int(anchor_raw[0]), int(anchor_raw[1])):
				c.stealthed = false
				c.conceal = {}
				out.append({"type": "stealth_broken", "combatant": c.id, "reason": "moved"})
				continue
		if shouters.has(c.id):
			c.stealthed = false
			c.conceal = {}
			out.append({"type": "stealth_broken", "combatant": c.id, "reason": "shout"})
			continue
		var observer: String = Stealth.first_observer_seeing(combatants, c, arena, clock.tick)
		if observer != "":
			c.stealthed = false
			c.conceal = {}
			out.append({"type": "stealth_broken", "combatant": c.id, "reason": "seen", "observer": observer})
	return out


## Batch B (retarget_guard) — the per-command guard sweep. IRON STANCE breaks
## the moment its holder is off the anchor hex (ANY displacement — a voluntary
## step and an involuntary knockback both end "holding your ground"), Prone,
## or down: iron_stance_ended carries the reason (moved / prone / downed).
## The INTERCEPT guard clears when the guardian or the guarded ally goes down
## (guard_ended, reason downed / ally_downed) — the armed_primes entry clears
## with it, keeping the PREP substrate in sync. Deterministic sorted-id order;
## zero rng; a single pass is complete (breaking one guard never changes
## another's premise).
func _guard_checks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not c.iron_stance.is_empty():
			var reason: String = ""
			if not c.alive or c.removed_from_play:
				reason = "downed"
			elif bool(c.statuses.get("prone", false)):
				reason = "prone"
			else:
				var anchor_raw: Array = c.iron_stance.get("anchor", [])
				if anchor_raw.size() != 2 \
						or c.position != Vector2i(int(anchor_raw[0]), int(anchor_raw[1])):
					reason = "moved"
			if reason != "":
				c.iron_stance = {}
				out.append({"type": "iron_stance_ended", "combatant": c.id, "reason": reason})
		if not c.guard.is_empty():
			var guard_reason: String = ""
			if not c.alive or c.removed_from_play:
				guard_reason = "downed"
			else:
				var ally: CombatantState = combatants.get(String(c.guard.get("ally", "")))
				if ally == null or not ally.alive or ally.removed_from_play:
					guard_reason = "ally_downed"
			if guard_reason != "":
				c.guard = {}
				c.armed_primes.erase("intercept")
				out.append({"type": "guard_ended", "guardian": c.id, "reason": guard_reason})
	return out


## Batch D (telekinesis) — the per-command channel sweep: the grip ENDS when
## the sustainer takes damage ("ends on actor damage" — read off THIS batch's
## damage_applied events with a real amount, so resolutions, reactions,
## forced-action fallout and condition drains all count, independent of the
## per-tick flag reset), is grappled (R9 contact breaks concentration), goes
## helpless, or goes down — or when the held target is gone. Every break
## funnels through release_channel (the held_by mirror can never dangle); a
## stray held_by whose named holder no longer channels it is cleared silently
## (defensive invariant, same spirit as the conceal clear). Deterministic
## sorted-id order; zero rng; a channel-free fight is a pure no-op (the
## compat pin).
func _channel_checks(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var damaged: Dictionary = {}
	for event: Dictionary in events:
		if String(event.get("type", "")) == "damage_applied" and int(event.get("amount", 0)) > 0:
			damaged[String(event.get("combatant", ""))] = true
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not c.channeling.is_empty():
			var reason: String = ""
			if not c.alive or c.removed_from_play:
				reason = "downed"
			elif c.is_helpless(clock.tick):
				reason = "helpless"
			elif c.grappling != "" or c.grappled_by != "":
				reason = "grappled"
			elif damaged.has(c.id):
				reason = "damaged"
			else:
				var held: CombatantState = combatants.get(String(c.channeling.get("target", "")))
				if held == null or not held.alive or held.removed_from_play:
					reason = "target_gone"
			if reason != "":
				out.append_array(resolver.release_channel(c, reason))
		if c.held_by != "":
			var holder: CombatantState = combatants.get(c.held_by)
			if holder == null or String(holder.channeling.get("target", "")) != c.id:
				c.held_by = ""
	return out


# ------------------------------------------------------ hearing (R20 round 3b)

## R20 hearing — the per-command NOISE sweep (called from _post; the model +
## loudness table live in Stealth, the addendum R20 "SHIPPED — hearing/alert"
## marker carries the full contract). Deterministic and rng-FREE — R20's
## hearing text authors a personality reaction, never a roll.
##
## DERIVE, then CONSUME (the honest split): Stealth.derive_noises maps the
## batch to noise rows for EVERY mapped event, visible or hidden source alike
## — but a noise is CONSUMED (can alert) only while its source is still
## STEALTHED at sweep time, because everyone else is DEFAULT-DETECTED (the
## R20 slice discipline): the AI already knows a visible actor is there, so
## its noise is redundant with detection itself — filtering it is honesty
## about information, not a shortcut (the redundant-with-sight pin in
## tests/test_hearing.gd). Documented consequence: a SHOUT never alerts in
## v1 — the R13 wire (the stealth sweep above, which runs first) breaks the
## shouter's own stealth, fully revealing it: strictly MORE information than
## an alert. The LOUD table row stays real for authored noises with no
## visible source (voicebox's thrown sounds are exactly that substrate).
##
## PER SORTED HEARER, the eligibility gates: AI-controlled (alerts are an AI
## reaction substrate — a contestant's ears are the player's), able to act
## (a fainted guard hears nothing it will remember — sight's can-act rule),
## not the source itself, HOSTILE to the source (your own pack's noise
## alarms nobody — the sees() team predicate: a teamless hearer alerts to
## no one, a teamless source is hostile to any teamed hearer), and within
## the noise's loudness of the hex the sound HAPPENED on (Stealth.hears —
## boundary inclusive; LOS deliberately unchecked, no wall-acoustics model
## exists). Among several audible noises the LAST in batch order wins (the
## most recent sound overwrites — event batches are ordered, deterministic).
## Hearing never REVEALS: sees()/stealthed are untouched — the hearer
## records that a sound happened, not where its maker is now.
##
## STATE + EVENTS: the winning noise writes hearer.alerted = {"tick",
## "sound": [q, r]} (no source id — R20: "does not know where you are") and
## emits noise_heard {combatant, source, position, loudness}; the
## unalerted->alerted TRANSITION additionally emits alerted {combatant,
## position} (refreshes ride noise_heard — the state change is the tick +
## sound update it carries). DECAY, after consumption so a same-batch
## refresh wins the boundary: a full Clock's worth of ticks
## (Clock.TICKS_PER_CLOCK) since the last heard noise clears the alert
## ("a quiet Clock" — deterministic, no sweep-order dependence), and a
## downed hearer loses it too (the stealth "downed" mirror) — both emit
## alert_cleared {combatant, reason: "decayed"|"downed"}.
func _noise_checks(events: Array[Dictionary]) -> Array[Dictionary]:
	# The legacy compat pin, provably complete: alerts only ORIGINATE from
	# hidden sources and only an EXISTING alert can decay — with nobody
	# stealthed and nobody alerted the sweep can do nothing, so it does
	# nothing (no events, no rng, no state; stealth-free fights byte-match
	# the pre-hearing engine — the pinned hashes + both CI harnesses).
	var any_hidden: bool = false
	var any_alerted: bool = false
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if c.stealthed:
			any_hidden = true
		if not c.alerted.is_empty():
			any_alerted = true
	if not any_hidden and not any_alerted:
		return []
	var out: Array[Dictionary] = []
	# 1) DERIVE this batch's noise rows — the full honest table (only worth
	#    computing while a hidden source exists to be heard).
	var noises: Array[Dictionary] = []
	if any_hidden:
		noises = Stealth.derive_noises(events, combatants)
	# 2) CONSUME per sorted hearer (the eligibility gates in the header).
	for id: Variant in ids:
		var hearer: CombatantState = combatants[id]
		if not EnemyAI.is_ai_controlled(hearer) or not hearer.can_act(clock.tick):
			continue
		var winning: Dictionary = {}
		for noise: Dictionary in noises:
			var source_id := String(noise["source"])
			if source_id == hearer.id:
				continue
			var source: CombatantState = combatants.get(source_id)
			if source == null or not source.stealthed:
				continue  # default-detected: a visible actor's noise is redundant
			if hearer.team == "" or hearer.team == source.team:
				continue  # hostile sources only (the sees() team predicate)
			if not Stealth.hears(hearer.position, noise["position"], int(noise["loudness"])):
				continue
			winning = noise  # last audible in batch order wins (the freshest sound)
		if winning.is_empty():
			continue
		var was_alerted: bool = not hearer.alerted.is_empty()
		var pos: Vector2i = winning["position"]
		hearer.alerted = {"tick": clock.tick, "sound": [pos.x, pos.y]}
		out.append({"type": "noise_heard", "combatant": hearer.id,
			"source": String(winning["source"]),
			"position": [pos.x, pos.y], "loudness": int(winning["loudness"])})
		if not was_alerted:
			# The broadcast is omniscient (noise_heard above names the source);
			# what the MOB knows is only its alerted dict — no source, no target.
			out.append({"type": "alerted", "combatant": hearer.id,
				"position": [pos.x, pos.y]})
	# 3) DECAY (after consumption — a same-batch refresh already moved the
	#    anchor tick, so it wins the boundary).
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if c.alerted.is_empty():
			continue
		if not c.alive or c.removed_from_play:
			c.alerted = {}
			out.append({"type": "alert_cleared", "combatant": c.id, "reason": "downed"})
		elif clock.tick >= int(c.alerted.get("tick", 0)) + Clock.TICKS_PER_CLOCK:
			c.alerted = {}
			out.append({"type": "alert_cleared", "combatant": c.id, "reason": "decayed"})
	return out


# ------------------------------------------------------------------ enemy AI (R11 #15)

## AI-controlled combatants ready for an ai_decide this tick (sorted) — the
## driver-side query; the driver feeds one ai_decide per id, like advance_tick.
func ai_ready_ids() -> Array[String]:
	var out: Array[String] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if not EnemyAI.is_ai_controlled(c):
			continue
		if not c.can_act(clock.tick):
			continue
		if clock.tick < c.next_action_tick or c.windup_pending:
			continue
		out.append(String(id))
	return out


## One enemy's turn: the EnemyAI policy decides (rng-free, from sorted state),
## the sim executes the intents through the SAME primitives player commands
## use. Actor gates and rejection vocabulary mirror declare_action.
func _ai_decide(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	if not EnemyAI.is_ai_controlled(actor):
		return [{"type": "command_rejected", "reason": "not_ai_controlled", "actor": actor.id}]
	if not actor.alive:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	if actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "removed_from_play", "actor": actor.id}]
	if actor.is_helpless(clock.tick):
		return [{"type": "command_rejected", "reason": "helpless", "actor": actor.id}]
	if clock.tick < actor.next_action_tick:
		return [{"type": "command_rejected", "reason": "not_ready", "actor": actor.id, "ready_at_tick": actor.next_action_tick}]
	if actor.windup_pending:
		return [{"type": "command_rejected", "reason": "winding_up", "actor": actor.id}]
	var decision: Dictionary = ai.decide(actor)
	var decision_event: Dictionary = {
		"type": "ai_decision",
		"actor": actor.id,
		"tier": String(decision.get("tier", "")),
		"choice": String(decision.get("choice", "wait")),
		"ability": String(decision.get("ability", "")),
		"target": String(decision.get("target", "")),
		"moves": decision.has("move_to"),
		"reason": String(decision.get("reason", "")),
	}
	# Additive (wave 2d): a cone decision surfaces its chosen arc direction —
	# the phase-5 tracking aim is spectator-visible, not buried in the shape.
	if decision.has("aim"):
		decision_event["aim"] = decision["aim"]
	var events: Array[Dictionary] = [decision_event]
	if decision.has("move_to"):
		var to: Vector2i = decision["move_to"]
		var move_events: Array[Dictionary] = resolver.move(actor.id, to)
		events.append_array(move_events)
		# KAN-5 wave 4d herding: a cut-off reposition announces the funnel only
		# once the step REALLY resolved (the pack_synergy honesty pattern — a
		# rejected move emits nothing and the decision leaves no residue).
		if decision.has("herding"):
			for event: Dictionary in move_events:
				if String(event.get("type", "")) == "moved":
					var herd: Dictionary = decision["herding"]
					events.append({
						"type": "pack_herding", "herder": actor.id,
						"quarry": String(herd.get("quarry", "")),
						"cutoff_hex": (herd.get("cutoff", []) as Array).duplicate(),
					})
					break
	match String(decision.get("choice", "wait")):
		# grab/chew/spin are the death-spin beats (wave 2b) — each a REAL
		# cost-1 declare through the resolver (grab = the R9 grapple kind;
		# chew/spin = marker-carrying attacks), so validation, feints, shock
		# and the Forced-Action machinery all apply like any other action.
		"attack", "heal", "grab", "chew", "spin":
			var declared: Array[Dictionary] = resolver.declare(actor.id, decision.get("action", {}))
			events.append_array(declared)
			# R15 pack synergy (wave 3a): the linked pair announces itself only
			# once the second strike is REALLY scheduled — a rejected declare
			# emits nothing (the partner's residual combo_id resolves solo,
			# byte-identical to an unlinked strike).
			if decision.has("pack_link"):
				var scheduled: bool = false
				for event: Dictionary in declared:
					if String(event.get("type", "")) == "action_declared":
						scheduled = true
				if scheduled:
					var link: Dictionary = decision["pack_link"]
					events.append({
						"type": "pack_synergy",
						"combo_id": String(link.get("combo_id", "")),
						"members": [String(link.get("partner", "")), actor.id],
						"target": String(link.get("target", "")),
						"part": String(link.get("part", "")),
					})
		"stand":
			# Skill-feel pass: a prone boss spends its Moment standing back up —
			# the SAME cost-1 stand action players use (declared through the
			# resolver, resolved at the tick, emits stood_up + clears prone).
			events.append_array(resolver.declare(actor.id, {"kind": "stand", "cost": 1}))
		"summon":
			events.append_array(_ai_summon(actor, decision.get("summon", {})))
		"telegraph", "blast":
			# Explosion beat steps (decision #27): each is the boss's act for the
			# Moment — cost-1 instant pacing, like the summon above — so the beat
			# advances one step per tick and the fight resumes next Moment post-blast.
			actor.next_action_tick = clock.tick + 1
			actor.took_scheduled_action_this_clock = true
			if String(decision.get("choice", "")) == "telegraph":
				events.append_array(ai.begin_explosion_telegraph(actor, decision))
			else:
				events.append_array(ai.resolve_explosion_blast(actor, decision, cond))
	return events


## Executes a summon intent: cost-1 instant (declare+resolve same tick, R2),
## brood spawns on the nearest free hexes and acts from the NEXT tick (R11 #16).
func _ai_summon(actor: CombatantState, summon: Dictionary) -> Array[Dictionary]:
	var enemy_key := String(summon.get("enemy_key", ""))
	var template: Dictionary = CombatantState._find_template(static_data.get("enemies", []), enemy_key)
	if template.is_empty():
		return [{"type": "summon_failed", "actor": actor.id, "reason": "unknown_enemy_key", "enemy_key": enemy_key}]
	actor.next_action_tick = clock.tick + maxi(1, int(summon.get("cost", 1)))
	actor.took_scheduled_action_this_clock = true
	var events: Array[Dictionary] = []
	var spawned: Array[String] = []
	var claimed: Dictionary = {}
	var count: int = maxi(1, int(summon.get("count", 1)))
	var serial: int = int(ai.summons.get(actor.id, 0))
	for i: int in range(count):
		serial += 1
		var id: String = "%s_brood_%d" % [actor.id, serial]
		while combatants.has(id):
			serial += 1
			id = "%s_brood_%d" % [actor.id, serial]
		var pos: Vector2i = _free_hex_near(actor.position, claimed)
		claimed[pos] = true
		events.append_array(_add_combatant({
			"id": id,
			"name": String(template.get("name", enemy_key)),
			"enemy": enemy_key,
			"team": actor.team,
			"position": [pos.x, pos.y],
		}))
		var brood: CombatantState = combatants.get(id)
		if brood != null:
			brood.next_action_tick = clock.tick + 1  # summons act from the next tick
			spawned.append(id)
	ai.summons[actor.id] = serial
	events.append({
		"type": "enemies_summoned",
		"actor": actor.id, "ability": String(summon.get("ability", "")),
		"enemy_key": enemy_key, "count": spawned.size(), "ids": spawned,
	})
	return events


## Nearest unoccupied hex around `center`, deterministic: growing rings, fixed
## axial scan order inside each ring. `claimed` holds hexes taken this batch.
## KAN-5: with an arena set, blocked hexes (out-of-bounds/walls/trash cans)
## are never candidates — summons place on legal ground only.
func _free_hex_near(center: Vector2i, claimed: Dictionary) -> Vector2i:
	var occupied: Dictionary = claimed.duplicate()
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if c.alive and not c.removed_from_play:
			occupied[c.position] = true
	for radius: int in range(1, 9):
		for dq: int in range(-radius, radius + 1):
			for dr: int in range(-radius, radius + 1):
				var candidate := center + Vector2i(dq, dr)
				if CombatantState.hex_distance(center, candidate) != radius:
					continue
				if arena != null and arena.blocks_movement(candidate):
					continue
				if not occupied.has(candidate):
					return candidate
	return center  # arena saturated — stack on the summoner rather than crash


# ------------------------------------------------------------------ snapshot

func _snapshot_entry(c: CombatantState) -> Dictionary:
	var entry: Dictionary = {
		"position": [c.position.x, c.position.y],
		"alive": c.alive and not c.removed_from_play,
		"exposed": c.exposed_cache,
		"helpless": c.is_helpless(clock.tick),
		"overwhelmed": bool(c.statuses.get("overwhelmed", false)),
	}
	# R20 compat pin (wave 4c, the combatant-dict pattern): the key exists ONLY
	# while stealthed — legacy snapshots (serialized under "tick_snapshot")
	# stay byte-identical. Windup re-checks read it (target_stealthed, R2).
	if c.stealthed:
		entry["stealthed"] = true
	return entry


func _rebuild_snapshot() -> void:
	tick_snapshot = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		tick_snapshot[String(id)] = _snapshot_entry(combatants[id])


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	var combatant_dicts: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		combatant_dicts[String(id)] = (combatants[id] as CombatantState).to_dict()
	var out: Dictionary = {
		"rng_seed": rng_seed,
		"rng_state": rng.state,
		"clock": clock.to_dict(),
		"combatants": combatant_dicts,
		"tick_snapshot": tick_snapshot.duplicate(true),
		"static_data": static_data.duplicate(true),
		"hype": hype.to_dict(),
		"tags": tags.to_dict(),
		"evidence": evidence.to_dict(),
		"ai": ai.to_dict(),
	}
	# KAN-5 compat pin: the "arena" key exists ONLY once an arena is set — a
	# no-arena sim serializes byte-identically to the pre-arena engine.
	if arena != null:
		out["arena"] = arena.to_dict()
	# KAN-5 K1 compat pin: the "zones" key exists ONLY once a zone has EVER
	# been created (next_id > 0) — a zone-free fight serializes byte-
	# identically to the pre-zone engine (the CI-harness gate). The key
	# PERSISTS after every zone expired: the serialized id counter keeps a
	# save/restore mid-fight replay-transparent (a restored sim hands out the
	# same next zone id a straight-through run would).
	if zones != null and zones.next_id > 0:
		out["zones"] = zones.to_dict()
	return out


static func from_dict(data: Dictionary) -> CombatSim:
	var sim := CombatSim.new(int(data.get("rng_seed", 0)), data.get("static_data", {}))
	sim.rng.state = int(data.get("rng_state", sim.rng.state))
	sim.clock = Clock.from_dict(data.get("clock", {}))
	var combatant_dicts: Dictionary = data.get("combatants", {})
	for id: Variant in combatant_dicts:
		sim.combatants[String(id)] = CombatantState.from_dict(combatant_dicts[id])
	sim.tick_snapshot = (data.get("tick_snapshot", {}) as Dictionary).duplicate(true)
	sim.hype = HypeEngine.from_dict(data.get("hype", {}))
	# Pre-I13 saves lack "tags": a fresh TagEngine (empty state) matches a new
	# sim's tagless start, so the resume path stays sound. Refs (effect table,
	# combatants, hype.tags) are re-wired below.
	sim.tags = TagEngine.from_dict(data.get("tags", {}))
	# Pre-evidence saves lack "evidence": an empty ledger matches a fresh sim's
	# start, so the resume path stays sound (refs re-wired below).
	sim.evidence = EvidenceEngine.from_dict(data.get("evidence", {}))
	# Pre-I16 saves lack "ai": keep the fresh salted engine (matches a new sim
	# on the same seed) instead of resuming on state 0 (R11 #15).
	if data.has("ai"):
		sim.ai = EnemyAI.from_dict(data.get("ai", {}))
	# Re-wire helper references (clock instance was replaced above). The goal
	# table is static data, never serialized; goal_rng/ai_rng states were
	# restored above.
	sim.ai.wire(sim.combatants, sim.clock)
	sim.resolver.setup(sim.clock, sim.combatants, sim.cond, sim.rng, sim.ai)
	sim.cond.setup(sim.static_data.get("conditions", []), sim.combatants)
	sim.hype.set_goal_table(sim._goal_table())
	sim.hype.wire(sim.combatants)  # R11 #14 v2 team-awareness ref
	sim.resolver.wire_hype(sim.hype)  # batch D: camera-call ledger + surge
	# Re-wire the tag engine (effect table is static data, never saved; the
	# combatants ref is a live object) and reconnect hype's resonance lookup.
	sim.tags.set_effects(sim.static_data.get("tag_effects", {}))
	sim.tags.wire(sim.combatants)
	sim.hype.tags = sim.tags
	# Re-wire the evidence ledger's live refs (the clock instance was replaced).
	sim.evidence.wire(sim.combatants, sim.clock)
	# KAN-5: pre-arena saves lack "arena" — null keeps the unbounded legacy
	# behavior, matching a fresh sim. Wired AFTER ai/resolver were replaced.
	if data.has("arena"):
		sim.arena = Arena.from_dict(data.get("arena", {}))
		sim.ai.arena = sim.arena
		sim.resolver.arena = sim.arena
	# KAN-5 K1: pre-zone saves lack "zones" — null keeps the legacy no-op
	# sweeps, matching a fresh sim. Wired AFTER the arena so the blocking
	# composition (arena.zones) lands on the restored instance; setup rebuilds
	# the derived hex indexes and the position baseline (the sweep always
	# leaves the baseline synced at a command boundary, so rebuilding it from
	# the restored positions is exact).
	if data.has("zones"):
		sim.zones = Zones.from_dict(data.get("zones", {}))
		sim.zones.setup(sim.combatants, sim.cond)
		if sim.arena != null:
			sim.arena.zones = sim.zones
	return sim


## Hash over the canonically-serialized state. Identical (seed, command log)
## must always produce an identical hash (DIRECTION contract; criterion 19).
func state_hash() -> String:
	return canonical_serialize(to_dict()).sha256_text()


## Canonical, key-sorted, type-stable text form of a Variant tree.
static func canonical_serialize(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_INT:
			return str(value)
		TYPE_FLOAT:
			# JSON-parsed numbers arrive as floats; whole floats print as ints.
			var f: float = value
			if f == floorf(f) and absf(f) < 9007199254740992.0:
				return str(int(f))
			return str(f)
		TYPE_STRING, TYPE_STRING_NAME:
			return "\"" + String(value).c_escape() + "\""
		TYPE_ARRAY:
			var items: Array[String] = []
			for item: Variant in value as Array:
				items.append(canonical_serialize(item))
			return "[" + ",".join(items) + "]"
		TYPE_DICTIONARY:
			var dict: Dictionary = value
			var keys: Array = dict.keys()
			keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			var pairs: Array[String] = []
			for key: Variant in keys:
				pairs.append("\"" + str(key).c_escape() + "\":" + canonical_serialize(dict[key]))
			return "{" + ",".join(pairs) + "}"
	return "\"" + str(value).c_escape() + "\""
