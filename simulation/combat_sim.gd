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
##   {"type": "camera_call", "actor", "target"}                Charm spotlight (R6/R11 #13)
##   {"type": "ai_decide", "actor"}                            enemy AI turn (R11 #15)
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
var ai: EnemyAI
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
	# Slice tags (I-13) — the second broadcast-plane consumer, wired after hype
	# so its detectors also see hype outputs (Scene Stealer). HypeEngine reads
	# held tags back through hype.tags for resonance.
	tags = TagEngine.new()
	tags.setup(static_data.get("tag_effects", {}), combatants)
	hype.tags = tags
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
			events = _combined_action(cmd.get("members", []))
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
		"camera_call":
			events = _camera_call(cmd)
		"bit":
			events = _bit(cmd)
		"ai_decide":
			events = _ai_decide(cmd)
		_:
			events = [{"type": "command_rejected", "reason": "unknown_command", "command": String(cmd.get("type", ""))}]
	_post(events)
	return events


## Housekeeping after every command: deaths cancel scheduled actions, breach
## checks run, exposure caches refresh, events get the tick stamp.
func _post(events: Array[Dictionary]) -> void:
	for event: Dictionary in events.duplicate():
		if String(event.get("type", "")) == "combatant_died":
			var dead_id := String(event.get("combatant", ""))
			clock.cancel_for(dead_id)
			var dead: CombatantState = combatants.get(dead_id)
			if dead != null:
				dead.windup_pending = false
	# Breach (incl. non-advance damage like reactions) + boss phase machine.
	events.append_array(_breach_and_phase_checks())
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		events.append_array(ExposureEngine.refresh(combatants[id], clock.tick))
	events.append_array(hype.ingest(events))
	# Tag detection runs AFTER hype so Scene Stealer sees hype_goal_completed /
	# hype_camera_call_started. Its tag_* outputs are system events (no
	# spectacle_points), so a second hype pass is unneeded; The Bit's escalating
	# spectacle already rides the bit_performed event hype scored above.
	events.append_array(tags.ingest(events))
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
	return events


# ------------------------------------------------------------------ commands

func _add_combatant(spec: Dictionary) -> Array[Dictionary]:
	var id := String(spec.get("id", ""))
	if id == "":
		return [{"type": "command_rejected", "reason": "missing_id"}]
	if combatants.has(id):
		return [{"type": "command_rejected", "reason": "duplicate_id", "combatant": id}]
	var c := CombatantState.from_spec(spec, static_data)
	c.next_action_tick = clock.tick
	combatants[id] = c
	tick_snapshot[id] = _snapshot_entry(c)
	var events: Array[Dictionary] = [{"type": "combatant_added", "combatant": id}]
	return events


## R15 — multi-character combined action: a set of LINKED declarations resolving
## on the same tick (R2 simultaneity is the substrate; each actor pays its own
## Moment cost). Assist `provides` stats satisfy partners' requirements; linked
## attacks merge into one hit for breach thresholds (see CombatantState.record_hit).
## A Forced Action on one member degrades only that member — the rest still
## resolve. v1 scope: members must be instants (cost <= 1) so same-tick resolution
## is guaranteed. members: [{"actor", "action": {..., "provides"?}}...].
func _combined_action(members: Array) -> Array[Dictionary]:
	if members.size() < 2:
		return [{"type": "command_rejected", "reason": "combo_needs_two_members"}]
	var provides: Dictionary = {}
	var seen: Dictionary = {}
	var member_ids: Array[String] = []
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
		if int(act.get("cost", 1)) > 1:
			return [{"type": "command_rejected", "reason": "combo_requires_instants", "actor": aid}]
		var member_provides: Dictionary = act.get("provides", {})
		for key: Variant in member_provides:
			provides[String(key)] = maxi(int(provides.get(String(key), 0)), int(member_provides[key]))
	var combo_id := "combo:%d:%d" % [clock.tick, clock.next_seq]
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
	if clock.completes_clock():
		events.append({"type": "clock_reset", "tick": clock.tick})
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			events.append_array(cond.on_clock_reset(combatants[id], clock.tick))
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
## by construction. It is NOT a normal action: it touches NO combatant state, the
## clock, the action RNG, scheduling, cost, or conditions. Its ONLY effect is one
## self-describing bit_performed event carrying escalating spectacle_points (base
## + bonus per prior bit this deployment, from the TagEngine rider) — scored by
## HypeEngine's generic spectacle hook, detected by TagEngine for the_bit. The
## character does the bit despite zero mechanical benefit; spectacle is the only
## payout. Read-only actor gates (rejections mutate nothing); contestants only.
func _bit(cmd: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(String(cmd.get("actor", "")))
	if actor == null:
		return [{"type": "command_rejected", "reason": "unknown_actor", "actor": String(cmd.get("actor", ""))}]
	if EnemyAI.AI_CATEGORIES.has(actor.category):
		return [{"type": "command_rejected", "reason": "not_a_contestant", "actor": actor.id}]
	if not actor.alive or actor.removed_from_play:
		return [{"type": "command_rejected", "reason": "actor_dead", "actor": actor.id}]
	return [{
		"type": "bit_performed",
		"actor": actor.id,
		"key": String(cmd.get("key", "bit")),
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
	var events: Array[Dictionary] = [{
		"type": "ai_decision",
		"actor": actor.id,
		"tier": String(decision.get("tier", "")),
		"choice": String(decision.get("choice", "wait")),
		"ability": String(decision.get("ability", "")),
		"target": String(decision.get("target", "")),
		"moves": decision.has("move_to"),
		"reason": String(decision.get("reason", "")),
	}]
	if decision.has("move_to"):
		var to: Vector2i = decision["move_to"]
		events.append_array(resolver.move(actor.id, to))
	match String(decision.get("choice", "wait")):
		"attack", "heal":
			events.append_array(resolver.declare(actor.id, decision.get("action", {})))
		"summon":
			events.append_array(_ai_summon(actor, decision.get("summon", {})))
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
				if not occupied.has(candidate):
					return candidate
	return center  # arena saturated — stack on the summoner rather than crash


# ------------------------------------------------------------------ snapshot

func _snapshot_entry(c: CombatantState) -> Dictionary:
	return {
		"position": [c.position.x, c.position.y],
		"alive": c.alive and not c.removed_from_play,
		"exposed": c.exposed_cache,
		"helpless": c.is_helpless(clock.tick),
		"overwhelmed": bool(c.statuses.get("overwhelmed", false)),
	}


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
	return {
		"rng_seed": rng_seed,
		"rng_state": rng.state,
		"clock": clock.to_dict(),
		"combatants": combatant_dicts,
		"tick_snapshot": tick_snapshot.duplicate(true),
		"static_data": static_data.duplicate(true),
		"hype": hype.to_dict(),
		"tags": tags.to_dict(),
		"ai": ai.to_dict(),
	}


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
	# Re-wire the tag engine (effect table is static data, never saved; the
	# combatants ref is a live object) and reconnect hype's resonance lookup.
	sim.tags.set_effects(sim.static_data.get("tag_effects", {}))
	sim.tags.wire(sim.combatants)
	sim.hype.tags = sim.tags
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
