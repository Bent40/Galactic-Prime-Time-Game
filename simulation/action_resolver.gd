class_name ActionResolver
extends RefCounted
## Declare/resolve semantics (rules-addendum R2/R3), attack + condition
## delivery (R4), movement & inventory costs (R3), RPM/magazine/reload (R8),
## grapple (R9), reactions (R2) and the requirements gate (R10).
##
## Declarations validate against LIVE state. Resolutions happen in CombatSim's
## advance_tick batch: instants (cost <= 1) resolve without re-checks (they
## cannot be dodged, R2); windups (cost >= 2) re-check range/validity against
## the snapshot taken at the START of the resolution tick — leaving a windup's
## range before its resolution tick dodges it; an invalidated action collapses
## into Forced Action – Tool (book rule).

const STAT_REQUIREMENT_KEYS: Array[String] = ["physique", "reflexes", "mind", "charm"]

# Shared context, wired by CombatSim (no back-reference to the sim itself).
var clock: Clock
var combatants: Dictionary = {}
var cond: ConditionEngine
var rng: RandomNumberGenerator


func setup(clock_ref: Clock, combatants_ref: Dictionary, cond_ref: ConditionEngine, rng_ref: RandomNumberGenerator) -> void:
	clock = clock_ref
	combatants = combatants_ref
	cond = cond_ref
	rng = rng_ref


static func _reject(reason: String, detail: Dictionary = {}) -> Array[Dictionary]:
	var event: Dictionary = {"type": "command_rejected", "reason": reason}
	event.merge(detail)
	var events: Array[Dictionary] = [event]
	return events


# ------------------------------------------------------------------ declare

## Declares a scheduled or free (0-Moment) action. Action dict keys:
## kind ("attack"|"skill"|"grapple"|"grapple_escape"|"grapple_suffocate"|
## "reload"|"stand"|"wait"), cost, key (cooldown identity), cooldown /
## cooldown_clocks, item (key on the actor), damage {"type","amount"},
## attack_range, targets [{"id","part"}], rounds, requirements, injection,
## poison_type, target (grapple kinds).
func declare(actor_id: String, action: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(actor_id)
	if actor == null:
		return _reject("unknown_actor", {"actor": actor_id})
	if not actor.alive:
		return _reject("actor_dead", {"actor": actor_id})
	if actor.removed_from_play:
		return _reject("removed_from_play", {"actor": actor_id})
	if actor.is_helpless(clock.tick):
		return _reject("helpless", {"actor": actor_id})

	var kind := String(action.get("kind", "attack"))
	var validation: Array[Dictionary] = _validate_kind(actor, kind, action)
	if not validation.is_empty():
		return validation

	var cd_key := String(action.get("key", String(action.get("item", ""))))
	if cd_key != "" and int(actor.cooldowns.get(cd_key, 0)) > clock.tick:
		return _reject("cooldown", {"actor": actor_id, "key": cd_key, "ready_at_tick": int(actor.cooldowns[cd_key])})

	var uses_strained: bool = actor.strained_grip and (kind == "attack" or kind == "reload")
	var eff_cost: int = _effective_cost(actor, kind, action, uses_strained)

	# R3 caps: one scheduled action + one free (0-Moment) action per tick.
	if eff_cost <= 0:
		if actor.free_action_used:
			return _reject("free_action_used", {"actor": actor_id})
	else:
		if clock.tick < actor.next_action_tick:
			return _reject("not_ready", {"actor": actor_id, "ready_at_tick": actor.next_action_tick})

	# --- all checks passed; mutate ---
	if uses_strained:
		actor.strained_grip = false
	var window: int = 0
	var resolve_tick: int = clock.tick
	if eff_cost <= 0:
		actor.free_action_used = true
	else:
		actor.next_action_tick = clock.tick + eff_cost
		actor.took_scheduled_action_this_clock = true
		if eff_cost >= 2:
			window = eff_cost  # multi-Moment windup: declare T, resolve T+cost (R2)
			resolve_tick = clock.tick + eff_cost
			actor.windup_pending = true
	var stored: Dictionary = action.duplicate(true)
	stored["eff_cost"] = eff_cost
	stored["declared_tick"] = clock.tick
	clock.schedule(actor_id, stored, resolve_tick, window)
	var events: Array[Dictionary] = [{
		"type": "action_declared",
		"actor": actor_id,
		"kind": kind,
		"cost": eff_cost,
		"resolve_tick": resolve_tick,
		"windup": window > 0,
	}]
	return events


func _validate_kind(actor: CombatantState, kind: String, action: Dictionary) -> Array[Dictionary]:
	match kind:
		"attack":
			return _validate_attack(actor, action)
		"grapple":
			return _validate_grapple(actor, action)
		"grapple_escape":
			if actor.grappled_by == "":
				return _reject("not_grappled", {"actor": actor.id})
		"grapple_suffocate":
			return _validate_grapple_suffocate(actor, action)
		"reload":
			return _validate_reload(actor, action)
		"stand":
			if not bool(actor.statuses.get("prone", false)):
				return _reject("not_prone", {"actor": actor.id})
	return []


func _validate_attack(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var item: Dictionary = {}
	var item_key := String(action.get("item", ""))
	if item_key != "":
		item = actor.items.get(item_key, {})
		if item.is_empty():
			return _reject("no_such_item", {"actor": actor.id, "item": item_key})
		if bool(item.get("dropped", false)):
			return _reject("item_dropped", {"actor": actor.id, "item": item_key})
		if actor.unarmed_until_tick > clock.tick:
			return _reject("unarmed", {"actor": actor.id})
		if item.has("magazine") and int(item.get("magazine_loaded", 0)) <= 0:
			return _reject("reload_required", {"actor": actor.id, "item": item_key})
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		if target == null:
			return _reject("unknown_target", {"target": String(t.get("id", ""))})
		if not target.alive:
			return _reject("target_dead", {"target": target.id})
		var part_key := String(t.get("part", ""))
		if not target.parts.has(part_key):
			return _reject("no_such_part", {"target": target.id, "part": part_key})
		if Resistance.part_blocked_by_surface_immunity(target, part_key):
			return _reject("part_hidden", {"target": target.id, "part": part_key})
		# Head targeting gate (book rule, kept — acceptance criterion 15).
		if part_key.contains("head") and not _head_targetable_live(target):
			return _reject("head_not_targetable", {"target": target.id})
		var reach: int = _attack_range(action, item)
		if CombatantState.hex_distance(actor.position, target.position) > reach:
			return _reject("out_of_range", {"target": target.id, "range": reach})
	return []


func _head_targetable_live(target: CombatantState) -> bool:
	return target.exposed_cache \
		or target.is_helpless(clock.tick) \
		or bool(target.statuses.get("overwhelmed", false))


func _validate_grapple(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	if target == null or not target.alive:
		return _reject("invalid_grapple_target", {"actor": actor.id})
	if actor.grappling != "":
		return _reject("already_grappling", {"actor": actor.id})
	if actor.usable_hands(clock.tick) < 1:
		return _reject("no_free_hand", {"actor": actor.id})
	# R9: target no more than one size larger.
	if target.size_rank() - actor.size_rank() > 1:
		return _reject("target_too_large", {"actor": actor.id, "target": target.id})
	if CombatantState.hex_distance(actor.position, target.position) > 1:
		return _reject("out_of_range", {"target": target.id, "range": 1})
	return []


func _validate_grapple_suffocate(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var target_id := String(action.get("target", ""))
	if actor.grappling != target_id or target_id == "":
		return _reject("not_grappling_target", {"actor": actor.id, "target": target_id})
	var target: CombatantState = combatants.get(target_id)
	if target == null or not target.alive:
		return _reject("invalid_grapple_target", {"actor": actor.id})
	# R9: bosses and anything >= 2 sizes larger are immune to grapple-Suffocation.
	if target.category == "Boss":
		return _reject("boss_immune_to_grapple_suffocation", {"target": target_id})
	if target.size_rank() - actor.size_rank() >= 2:
		return _reject("too_large_for_suffocation", {"target": target_id})
	if actor.usable_hands(clock.tick) < 2:
		return _reject("needs_both_hands", {"actor": actor.id})
	if bool(target.boss_traits.get("no_airway", false)) or not _has_head(target):
		return _reject("no_coverable_airway", {"target": target_id})
	return []


func _has_head(c: CombatantState) -> bool:
	for part_key: Variant in c.parts:
		if String(part_key).contains("head"):
			return true
	return false


func _validate_reload(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	if item.is_empty() or not item.has("magazine"):
		return _reject("nothing_to_reload", {"actor": actor.id})
	if bool(item.get("dropped", false)):
		return _reject("item_dropped", {"actor": actor.id})
	if actor.usable_hands(clock.tick) < 2:
		return _reject("needs_both_hands", {"actor": actor.id})  # R8: 2 Moments, both hands
	return []


func _effective_cost(actor: CombatantState, kind: String, action: Dictionary, uses_strained: bool) -> int:
	var base: int = _base_cost(actor, kind, action)
	var eff: int = base
	if base >= 2:
		eff += cond.effect_value(actor, "moment_cost_penalty_heavy_actions")  # Exhausted T1
	eff += cond.effect_value(actor, "moment_cost_penalty_all")  # Exhausted T2
	if uses_strained:
		eff += 1  # Forced Tool 5: Strained Grip
	return eff


func _base_cost(actor: CombatantState, kind: String, action: Dictionary) -> int:
	match kind:
		"grapple", "grapple_suffocate", "stand":
			return int(action.get("cost", 1))
		"grapple_escape":
			# R9: 2 Moments automatic; 1 Moment if Physique >= grappler's.
			var grappler: CombatantState = combatants.get(actor.grappled_by)
			var quick: bool = grappler != null and actor.trait_total("physique") >= grappler.trait_total("physique")
			return int(action.get("cost", 1 if quick else 2))
		"reload":
			return int(action.get("cost", 2))  # R8
		"attack":
			var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
			return int(action.get("cost", int(item.get("base_moment_cost", 1))))
	return int(action.get("cost", 1))


func _attack_range(action: Dictionary, item: Dictionary) -> int:
	if action.has("attack_range"):
		return int(action["attack_range"])
	if item.has("attack_range"):
		return int(item["attack_range"])
	var pattern := String(item.get("range_pattern", ""))
	if pattern.begins_with("range_"):
		return maxi(1, int(pattern.get_slice("_", 1)))
	return 1


# ------------------------------------------------------------------ movement

## R3: 1–3 spaces free (consumes the free slot), once per tick; longer moves
## cost ceil((spaces - 3) / 4) Moments as a scheduled action. Slowed (R7):
## allowance 1, Moment costs double. Prone (R7): crawl 1 space only.
func move(actor_id: String, to: Vector2i) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(actor_id)
	if actor == null:
		return _reject("unknown_actor", {"actor": actor_id})
	if not actor.alive or actor.removed_from_play:
		return _reject("actor_dead", {"actor": actor_id})
	if actor.is_helpless(clock.tick):
		return _reject("helpless", {"actor": actor_id})
	if actor.grappled_by != "" or actor.grappling != "":
		return _reject("grappled", {"actor": actor_id})  # R9: no repositioning
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor_id})
	if actor.moved_this_tick:
		return _reject("already_moved", {"actor": actor_id})  # R3: never twice per tick
	var spaces: int = CombatantState.hex_distance(actor.position, to)
	if spaces <= 0:
		return _reject("no_move", {"actor": actor_id})
	var prone: bool = bool(actor.statuses.get("prone", false))
	var slowed: bool = bool(actor.statuses.get("slowed", false))
	var allowance: int = 1 if (prone or slowed) else 3
	if spaces <= allowance:
		if actor.free_action_used:
			return _reject("free_action_used", {"actor": actor_id})
		actor.free_action_used = true
		actor.moved_this_tick = true
		actor.position = to
		var events: Array[Dictionary] = [{
			"type": "moved", "actor": actor_id, "to": [to.x, to.y], "spaces": spaces, "free": true,
		}]
		return events
	if prone:
		return _reject("prone_can_only_crawl", {"actor": actor_id})
	var cost: int = maxi(1, ceili((spaces - 3) / 4.0))
	if slowed:
		cost *= 2
	if clock.tick < actor.next_action_tick:
		return _reject("not_ready", {"actor": actor_id, "ready_at_tick": actor.next_action_tick})
	actor.moved_this_tick = true
	actor.next_action_tick = clock.tick + cost
	actor.took_scheduled_action_this_clock = true
	var window: int = cost if cost >= 2 else 0
	if window > 0:
		actor.windup_pending = true
	var action: Dictionary = {"kind": "move", "to": [to.x, to.y], "spaces": spaces, "eff_cost": cost}
	clock.schedule(actor_id, action, clock.tick + (cost if cost >= 2 else 0), window)
	var events: Array[Dictionary] = [{
		"type": "action_declared", "actor": actor_id, "kind": "move", "cost": cost,
		"resolve_tick": clock.tick + (cost if cost >= 2 else 0), "windup": window > 0,
	}]
	return events


# ------------------------------------------------------------------ inventory

## R3: the FIRST inventory interaction of a combat is free (consumes the free
## slot); every later one costs 1 Moment (never resets — exploit deleted). An
## item's own listed Moment cost replaces the interaction cost when higher.
func inventory(actor_id: String, payload: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(actor_id)
	if actor == null:
		return _reject("unknown_actor", {"actor": actor_id})
	if not actor.alive or actor.removed_from_play:
		return _reject("actor_dead", {"actor": actor_id})
	if actor.is_helpless(clock.tick):
		return _reject("helpless", {"actor": actor_id})
	var first: bool = actor.inventory_uses == 0
	if first and not actor.free_action_used:
		actor.inventory_uses += 1
		actor.free_action_used = true
		var events: Array[Dictionary] = [{
			"type": "inventory_used", "actor": actor_id, "free": true,
			"interaction": String(payload.get("interaction", "use")),
		}]
		events.append_array(_apply_inventory_effect(actor, payload))
		return events
	var item: Dictionary = actor.items.get(String(payload.get("item", "")), {})
	var cost: int = maxi(1, int(item.get("base_moment_cost", 1)))
	cost += cond.effect_value(actor, "moment_cost_penalty_all")
	if cost >= 2:
		cost += cond.effect_value(actor, "moment_cost_penalty_heavy_actions")
	if clock.tick < actor.next_action_tick:
		return _reject("not_ready", {"actor": actor_id, "ready_at_tick": actor.next_action_tick})
	actor.inventory_uses += 1
	actor.next_action_tick = clock.tick + cost
	actor.took_scheduled_action_this_clock = true
	var window: int = cost if cost >= 2 else 0
	if window > 0:
		actor.windup_pending = true
	var action: Dictionary = payload.duplicate(true)
	action["kind"] = "inventory"
	action["eff_cost"] = cost
	clock.schedule(actor_id, action, clock.tick + (cost if cost >= 2 else 0), window)
	var events: Array[Dictionary] = [{
		"type": "action_declared", "actor": actor_id, "kind": "inventory", "cost": cost,
		"resolve_tick": clock.tick + (cost if cost >= 2 else 0), "windup": window > 0,
	}]
	return events


func _apply_inventory_effect(actor: CombatantState, payload: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if String(payload.get("interaction", "")) == "pickup":
		var item: Dictionary = actor.items.get(String(payload.get("item", "")), {})
		if not item.is_empty() and bool(item.get("dropped", false)):
			item["dropped"] = false
			events.append({"type": "item_recovered", "actor": actor.id, "item": String(payload.get("item", ""))})
	return events


# ------------------------------------------------------------------ reactions

## R2: a triggered reaction resolves immediately, out of schedule; its Moment
## cost is added to the reactor's next_action_tick. Max one reaction per
## combatant per tick; 0-cost reactions also consume the free-action slot.
func reaction(actor_id: String, payload: Dictionary) -> Array[Dictionary]:
	var actor: CombatantState = combatants.get(actor_id)
	if actor == null:
		return _reject("unknown_actor", {"actor": actor_id})
	if not actor.alive or actor.removed_from_play:
		return _reject("actor_dead", {"actor": actor_id})
	if actor.is_helpless(clock.tick):
		return _reject("helpless", {"actor": actor_id})  # R7: cannot react
	if actor.reaction_used:
		return _reject("reaction_used", {"actor": actor_id})
	var cost: int = int(payload.get("cost", 0))
	if cost <= 0 and actor.free_action_used:
		return _reject("free_action_used", {"actor": actor_id})
	actor.reaction_used = true
	if cost <= 0:
		actor.free_action_used = true
	actor.next_action_tick = maxi(actor.next_action_tick, clock.tick) + cost
	var events: Array[Dictionary] = [{
		"type": "reaction_resolved", "actor": actor_id, "cost": cost,
		"key": String(payload.get("key", "")),
		"next_action_tick": actor.next_action_tick,
	}]
	# Optional immediate effect (live state — reactions are out of schedule).
	var damage: Dictionary = payload.get("damage", {})
	var target: CombatantState = combatants.get(String(payload.get("target", "")))
	if not damage.is_empty() and target != null and target.alive:
		var condition_id := ConditionEngine.normalize_condition_id(String(damage.get("type", "")))
		events.append_array(_strike_round(target, String(payload.get("part", "torso")), condition_id, int(damage.get("amount", 0)), payload))
	return events


# ------------------------------------------------------------------ resolution

## Resolves everything due this tick against the tick-start snapshot (R2).
## Returns {"events": Array[Dictionary], "forced": Array[Dictionary]} — forced
## consequences are applied by CombatSim AFTER all resolutions (R1 step 2).
func resolve_due(snapshot: Dictionary) -> Dictionary:
	var events: Array[Dictionary] = []
	var forced_queue: Array[Dictionary] = []
	for entry: Dictionary in clock.take_due(clock.tick):
		var actor: CombatantState = combatants.get(String(entry["actor"]))
		if actor == null:
			continue
		var snap: Dictionary = snapshot.get(actor.id, {})
		if not bool(snap.get("alive", actor.alive)):
			events.append({"type": "action_invalidated", "actor": actor.id, "reason": "actor_dead"})
			continue
		if int(entry["window"]) > 0 and bool(snap.get("helpless", false)):
			events.append({"type": "action_invalidated", "actor": actor.id, "reason": "actor_helpless"})
			continue
		events.append_array(_resolve_entry(actor, entry, snapshot, forced_queue))
	return {"events": events, "forced": forced_queue}


func _resolve_entry(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var kind := String(action.get("kind", "attack"))
	var events: Array[Dictionary] = []
	match kind:
		"attack", "skill":
			events = _resolve_strike(actor, entry, snapshot, forced_queue)
		"move":
			var to: Array = action.get("to", [actor.position.x, actor.position.y])
			actor.position = Vector2i(int(to[0]), int(to[1]))
			events.append({"type": "moved", "actor": actor.id, "to": to, "spaces": int(action.get("spaces", 0)), "free": false})
		"inventory":
			events.append({"type": "inventory_used", "actor": actor.id, "free": false, "interaction": String(action.get("interaction", "use"))})
			events.append_array(_apply_inventory_effect(actor, action))
		"reload":
			events = _resolve_reload(actor, action, forced_queue)
		"grapple":
			events = _resolve_grapple(actor, action, forced_queue)
		"grapple_escape":
			events = _resolve_grapple_escape(actor)
		"grapple_suffocate":
			events = _resolve_grapple_suffocate(actor, action)
		"stand":
			actor.statuses.erase("prone")
			events.append({"type": "action_resolved", "actor": actor.id, "kind": "stand", "result": "ok"})
		_:
			events.append({"type": "action_resolved", "actor": actor.id, "kind": kind, "result": "ok"})
	var cd_key := String(action.get("key", String(action.get("item", ""))))
	var cd_ticks: int = _cooldown_ticks(action)
	if cd_key != "" and cd_ticks > 0:
		actor.cooldowns[cd_key] = clock.tick + cd_ticks  # R3: absolute-timeline ticks
	return events


func _cooldown_ticks(action: Dictionary) -> int:
	if action.has("cooldown_clocks"):
		return int(action["cooldown_clocks"]) * Clock.TICKS_PER_CLOCK  # "1 Clock" = 10 ticks
	return int(action.get("cooldown", 0))


func _resolve_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var action: Dictionary = entry["action"]
	var kind := String(action.get("kind", "attack"))
	var is_windup: bool = int(entry["window"]) > 0
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	var acting_part: String = actor.acting_part(clock.tick)
	var targets: Array = action.get("targets", [])

	# Windups re-check range & validity against the tick-start snapshot (R2).
	if is_windup:
		var invalid_reason: String = _windup_invalid_reason(actor, action, item, snapshot)
		if invalid_reason != "":
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": invalid_reason})
			var collapse: Dictionary = ForcedAction.roll(ForcedAction.TABLE_TOOL, rng)
			events.append(ForcedAction.make_event(actor.id, collapse, "invalidated_windup"))
			var missed_target: String = ""
			if not targets.is_empty():
				missed_target = String((targets[0] as Dictionary).get("id", ""))
			# The original target escaped the effect entirely — a Collateral
			# consequence must not hit them (they dodged), so exclude them.
			forced_queue.append({"actor": actor.id, "rolled": collapse, "ctx": {
				"part": acting_part, "target": missed_target,
			}})
			return events

	# Condition-driven Forced Action – Body (bleeding T2+, crushed T1, exhausted T3...).
	if cond.forced_body_required(actor, acting_part):
		var body_roll: Dictionary = ForcedAction.roll(ForcedAction.TABLE_BODY, rng)
		events.append(ForcedAction.make_event(actor.id, body_roll, "condition_forced_body"))
		forced_queue.append({"actor": actor.id, "rolled": body_roll, "ctx": {"part": acting_part}})

	# Requirements gate (R10): unmet -> still allowed, but effect magnitude is
	# halved (round down) AND the Tool d6 table triggers.
	var requirements: Dictionary = action.get("requirements", item.get("stat_requirements", {}))
	var unmet: bool = _requirements_unmet(actor, requirements)
	var whiffed: bool = false
	var damage: Dictionary = action.get("damage", {})
	if damage.is_empty() and item.has("damage_type"):
		damage = {"type": String(item.get("damage_type", "")), "amount": int(item.get("damage_amount", 0))}
	var amount: int = int(damage.get("amount", 0))
	if unmet:
		amount = floori(amount / 2.0)
		var tool_roll: Dictionary = ForcedAction.roll(ForcedAction.TABLE_TOOL, rng)
		events.append(ForcedAction.make_event(actor.id, tool_roll, "unmet_requirements"))
		if String(tool_roll["consequence"]) == "whiff":
			whiffed = true  # the only consequence that negates the action (D6)
		else:
			var first_target: String = ""
			if not targets.is_empty():
				first_target = String((targets[0] as Dictionary).get("id", ""))
			forced_queue.append({"actor": actor.id, "rolled": tool_roll, "ctx": {
				"part": acting_part, "damage": maxi(1, amount), "target": first_target,
			}})

	if whiffed or targets.is_empty() or damage.is_empty():
		events.append({
			"type": "action_resolved", "actor": actor.id, "kind": kind,
			"key": String(action.get("key", String(action.get("item", "")))),
			"result": "whiff" if whiffed else "ok", "halved": unmet, "rounds": 0,
		})
		return events

	# RPM firing (R8): a 1-Moment action delivers up to RPM rounds; listed
	# damage is per round; magazine decrements per round.
	var rpm: int = maxi(1, int(action.get("rpm", int(item.get("rpm", 1)))))
	var rounds: int = mini(maxi(1, int(action.get("rounds", targets.size()))), rpm)
	if item.has("magazine"):
		rounds = mini(rounds, int(item.get("magazine_loaded", 0)))
		item["magazine_loaded"] = int(item.get("magazine_loaded", 0)) - rounds
		events.append({"type": "magazine_changed", "actor": actor.id, "item": String(action.get("item", "")), "loaded": int(item["magazine_loaded"])})
	var condition_id := ConditionEngine.normalize_condition_id(String(damage.get("type", "")))
	for i: int in range(rounds):
		var t: Dictionary = targets[mini(i, targets.size() - 1)]
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		if target == null:
			continue
		events.append_array(_strike_round(target, String(t.get("part", "")), condition_id, amount, action))
	events.append({
		"type": "action_resolved", "actor": actor.id, "kind": kind,
		"key": String(action.get("key", String(action.get("item", "")))),
		"result": "ok", "halved": unmet, "rounds": rounds,
	})
	return events


func _windup_invalid_reason(actor: CombatantState, action: Dictionary, item: Dictionary, snapshot: Dictionary) -> String:
	if not item.is_empty() and (bool(item.get("dropped", false)) or actor.unarmed_until_tick > clock.tick):
		return "disarmed"
	var actor_snap: Dictionary = snapshot.get(actor.id, {})
	var actor_pos: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
	var reach: int = _attack_range(action, item)
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		if target == null:
			return "target_missing"
		var snap: Dictionary = snapshot.get(target.id, {})
		if not bool(snap.get("alive", false)):
			return "target_dead"
		var target_pos: Array = snap.get("position", [target.position.x, target.position.y])
		var a := Vector2i(int(actor_pos[0]), int(actor_pos[1]))
		var b := Vector2i(int(target_pos[0]), int(target_pos[1]))
		if CombatantState.hex_distance(a, b) > reach:
			return "out_of_range"
		var part_key := String(t.get("part", ""))
		if part_key.contains("head"):
			var targetable: bool = bool(snap.get("exposed", false)) \
				or bool(snap.get("helpless", false)) \
				or bool(snap.get("overwhelmed", false))
			if not targetable:
				return "head_not_targetable"
	return ""


func _requirements_unmet(actor: CombatantState, requirements: Dictionary) -> bool:
	for stat_key: String in STAT_REQUIREMENT_KEYS:
		if requirements.has(stat_key) and actor.trait_total(stat_key) < int(requirements[stat_key]):
			return true
	if requirements.has("hands") and actor.usable_hands(clock.tick) < int(requirements["hands"]):
		return true
	return false


## One round of typed damage + condition delivery (R4) with boss hooks (R6).
func _strike_round(target: CombatantState, part_key: String, condition_id: String, amount: int, action: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not target.parts.has(part_key):
		return events
	# Boss hook: fire heals (Incinedile) — Burn damage restores the part.
	if condition_id == "burn" and Resistance.fire_heals(target):
		var part: Dictionary = target.parts[part_key]
		part["hp"] = mini(target.max_hp(part_key), int(part["hp"]) + amount)
		events.append({"type": "healed", "combatant": target.id, "part": part_key, "amount": amount, "source": "fire_heals"})
		return events
	if Resistance.part_blocked_by_surface_immunity(target, part_key):
		events.append({"type": "attack_blocked", "combatant": target.id, "part": part_key, "reason": "surface_immunity"})
		return events
	# Damage = listed − flat resistance, floor 0 (R4).
	var reduced: int = Resistance.reduce_damage(amount, target, cond.def_for(condition_id), condition_id)
	events.append_array(cond.damage_part(target, part_key, reduced, "weapon", condition_id, clock.tick))
	# Typed damage applies/advances its condition regardless of the post-
	# resistance HP number (tier immunity, not flat reduction, blocks it — R6).
	if target.alive and condition_id != "":
		events.append_array(cond.apply(target, part_key, condition_id, clock.tick, {
			"source": "attack",
			"injection": bool(action.get("injection", false)),
			"poison_type": String(action.get("poison_type", "")),
		}))
	return events


func _resolve_reload(actor: CombatantState, action: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	# Re-verify both hands at resolution (an arm may have failed mid-windup).
	if item.is_empty() or actor.usable_hands(clock.tick) < 2 or bool(item.get("dropped", false)):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "reload", "reason": "needs_both_hands"})
		var collapse: Dictionary = ForcedAction.roll(ForcedAction.TABLE_TOOL, rng)
		events.append(ForcedAction.make_event(actor.id, collapse, "invalidated_windup"))
		forced_queue.append({"actor": actor.id, "rolled": collapse, "ctx": {"part": actor.acting_part(clock.tick)}})
		return events
	item["magazine_loaded"] = int(item.get("magazine", 0))
	events.append({"type": "reloaded", "actor": actor.id, "item": String(action.get("item", "")), "loaded": int(item["magazine_loaded"])})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "reload", "result": "ok"})
	return events


func _resolve_grapple(actor: CombatantState, action: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	if target == null or not target.alive or actor.grappling != "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple", "reason": "invalid_target"})
		return events
	actor.grappling = target.id
	target.grappled_by = actor.id
	events.append({"type": "grapple_started", "grappler": actor.id, "target": target.id})
	# R9: automatic when grappler Physique >= target's; otherwise the attempt
	# is Forced Action – Body — always allowed, consequences apply, hold lands.
	if actor.trait_total("physique") < target.trait_total("physique"):
		var body_roll: Dictionary = ForcedAction.roll(ForcedAction.TABLE_BODY, rng)
		events.append(ForcedAction.make_event(actor.id, body_roll, "grapple_above_weight"))
		forced_queue.append({"actor": actor.id, "rolled": body_roll, "ctx": {"part": actor.acting_part(clock.tick), "target": target.id}})
	return events


func _resolve_grapple_escape(actor: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if actor.grappled_by == "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple_escape", "reason": "not_grappled"})
		return events
	var grappler: CombatantState = combatants.get(actor.grappled_by)
	if grappler != null:
		grappler.grappling = ""
	events.append({"type": "grapple_ended", "grappler": actor.grappled_by, "target": actor.id, "reason": "escaped"})
	actor.grappled_by = ""
	return events


func _resolve_grapple_suffocate(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	if target == null or not target.alive or actor.grappling != target.id:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple_suffocate", "reason": "grip_lost"})
		return events
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "grapple_suffocate", "result": "ok"})
	events.append_array(cond.apply(target, "torso", "suffocation", clock.tick, {"source": "attack"}))
	return events


func to_dict() -> Dictionary:
	return {}  # stateless — all state lives on Clock/CombatantState, rewired by CombatSim


static func from_dict(_data: Dictionary) -> ActionResolver:
	return ActionResolver.new()
