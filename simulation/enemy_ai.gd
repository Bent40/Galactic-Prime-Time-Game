class_name EnemyAI
extends RefCounted
## Deterministic enemy decision policy v1 (I-16) — mob/elite tiers, the
## Incinedile Phase-1 machine, and the dodge-threshold boss ability.
##
## Contract (docs/rules-addendum.md R11 #15–#18):
## - The policy lives INSIDE the sim and is driven by the "ai_decide" command —
##   the driver/controller feeds one per ready enemy per tick (like
##   advance_tick), so every AI decision enters the command log and a replay
##   recomputes the identical decision from (sorted sim state, salted ai_rng).
##   The sim stays passive: it never self-advances and never self-decides.
## - decide() is rng-free: pure priority rules over SORTED state (no
##   unsorted-dict iteration feeds a decision). The ONLY ai_rng consumer is the
##   R22 dodge check's threshold die (mirror of hype_engine's salted goal_rng
##   pattern) — and only on the ROLLED fallback: an auto-dodge or an impossible
##   dodge consumes nothing — so dodge rolls never perturb the action RNG's
##   Forced-Action sequence.
## - All state (ai_rng.state, boss phases, summon counts, explosion beats) is
##   serialized in CombatSim.to_dict() under "ai" and covered by state_hash.
## - No to-hit rolls: proposed attacks auto-succeed like player attacks; the
##   Forced Action d6 remains the failure path. The dodge threshold is an
##   authored ENEMY ability (R2's explicit-miss pattern), not a universal rule.
##
## All numbers PLACEHOLDER (R14) pending the numbers rework, unless marked canon.

## Decouples the AI RNG stream from the action RNG seeded with the same value.
const AI_RNG_SALT: int = 0xD0D6E5
## Categories the policy controls; everything else is player/NPC-recruit driven.
const AI_CATEGORIES: Array[String] = ["Mob", "Elite", "Boss", "Super Boss"]
## Elite self-heal trigger: any lethal part below this fraction of max. PLACEHOLDER (R14).
const HEAL_LETHAL_PART_RATIO: float = 0.5
## Boss cone sweep wants at least this many targets in reach. PLACEHOLDER (R14).
const CONE_MIN_TARGETS: int = 2
## R3 free-move allowance the policy plans with (resolver enforces the real cap).
const FREE_MOVE_SPACES: int = 3
## Axial hex neighbors in fixed order — deterministic movement tie-break.
const HEX_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Wired refs (never serialized — re-wired by CombatSim, like ConditionEngine).
var combatants: Dictionary = {}
var clock: Clock
## Serialized AI state.
var ai_rng := RandomNumberGenerator.new()
var boss_phase: Dictionary = {}  # combatant id -> current phase_number (default 1)
var summons: Dictionary = {}     # combatant id -> total combatants summoned
## Live explosion beats (decision #27): combatant id -> {"phase": int,
## "telegraph_tick": int}. An entry exists only from the telegraph's execution
## until the blast resolves (the pre-telegraph "entered the phase" state is the
## phase number itself), so a mid-beat save restores the countdown exactly.
var explosion_beats: Dictionary = {}


## Fresh-sim wiring: refs + deterministic salted RNG seed. from_dict restores
## ai_rng.state afterwards on the resume path.
func setup(combatants_ref: Dictionary, clock_ref: Clock, sim_seed: int) -> void:
	wire(combatants_ref, clock_ref)
	ai_rng.seed = sim_seed + AI_RNG_SALT


## Re-wire path for CombatSim.from_dict (refs are live objects, never saved).
func wire(combatants_ref: Dictionary, clock_ref: Clock) -> void:
	combatants = combatants_ref
	clock = clock_ref


static func is_ai_controlled(c: CombatantState) -> bool:
	return AI_CATEGORIES.has(c.category)


# ------------------------------------------------------------------ decisions

## Computes the actor's decision for this tick. Pure function of sorted sim
## state (+ stored phase/summon memory) — consumes NO rng. Returned shape:
##   {"choice": "attack"|"heal"|"summon"|"move"|"wait", "tier": String,
##    "ability": String?, "target": String?, "move_to": Vector2i?,
##    "action": Dictionary? (resolver.declare payload),
##    "summon": Dictionary? ({enemy_key, count, ability, cost}),
##    "reason": String? (wait only)}
func decide(actor: CombatantState) -> Dictionary:
	match actor.category:
		"Boss", "Super Boss":
			return _decide_boss(actor)
		"Elite":
			return _decide_elite(actor)
		_:
			return _decide_mob(actor)


## MOB: bite the priority target (nearest → lowest HP → id, torso-line);
## close distance with the free move when out of reach; wait otherwise.
func _decide_mob(actor: CombatantState) -> Dictionary:
	var strike: Dictionary = _first_strike_ability(actor, [])
	var opponents: Array[CombatantState] = _opponents(actor)
	if opponents.is_empty():
		return _wait("mob", "no_targets")
	if strike.is_empty():
		return _wait("mob", "no_usable_ability")
	return _strike_or_close(actor, "mob", strike, opponents, false)


## ELITE: summon the brood once, self-heal when a lethal part is below half,
## then whip the weakest target in reach (heads when exposed); close otherwise.
func _decide_elite(actor: CombatantState) -> Dictionary:
	var summon_ability: Dictionary = _first_ability_with(actor, "summon")
	if not summon_ability.is_empty() and int(summons.get(actor.id, 0)) == 0:
		var summon_spec: Dictionary = summon_ability.get("summon", {})
		return {
			"choice": "summon", "tier": "elite",
			"ability": String(summon_ability.get("key", "")),
			"summon": {
				"enemy_key": String(summon_spec.get("enemy_key", "")),
				"count": maxi(1, int(summon_spec.get("count", 1))),
				"ability": String(summon_ability.get("key", "")),
				"cost": maxi(1, int(summon_ability.get("moment_cost", 1))),
			},
		}
	var heal_ability: Dictionary = _first_ability_with(actor, "heal")
	if not heal_ability.is_empty() and _wants_heal(actor):
		return {
			"choice": "heal", "tier": "elite",
			"ability": String(heal_ability.get("key", "")),
			"action": {
				"kind": "skill",
				"key": String(heal_ability.get("key", "")),
				"cost": maxi(1, int(heal_ability.get("moment_cost", 1))),
				"heal": (heal_ability.get("heal", {}) as Dictionary).duplicate(true),
			},
		}
	var strike: Dictionary = _first_strike_ability(actor, [])
	var opponents: Array[CombatantState] = _opponents(actor)
	if opponents.is_empty():
		return _wait("elite", "no_targets")
	if strike.is_empty():
		return _wait("elite", "no_usable_ability")
	return _strike_or_close(actor, "elite", strike, opponents, true)


## BOSS (Incinedile): cone sweep when the crowd is in reach, else the line
## charge at the priority target (torso bias), else close distance. The ability
## set is filtered to the current phase's behavior list. In an explosion phase
## the beat machine takes over (decision #27): telegraph -> escape window ->
## blast, then the machine advances and the boss fights the next Threshold.
func _decide_boss(actor: CombatantState) -> Dictionary:
	var phase: int = current_phase(actor.id)
	var behavior: Dictionary = _phase_entry(actor, phase).get("behavior", {})
	if behavior.has("explosion"):
		return _decide_explosion_beat(actor, phase, behavior.get("explosion", {}))
	var allowed: Array = behavior.get("abilities", [])
	var opponents: Array[CombatantState] = _opponents(actor)
	if opponents.is_empty():
		return _wait("boss", "no_targets")
	# Priority 1: cone sweep when enough targets stand inside it.
	var cone: Dictionary = _first_cone_ability(actor, allowed)
	if not cone.is_empty():
		var cone_range: int = _ability_range(cone)
		var in_cone: Array[CombatantState] = []
		for opponent: CombatantState in opponents:
			if CombatantState.hex_distance(actor.position, opponent.position) <= cone_range:
				in_cone.append(opponent)
		if in_cone.size() >= CONE_MIN_TARGETS:
			return _cone_decision(actor, cone, in_cone)
	# Priority 2: single-target strike (dash), torso bias; else close distance.
	var strike: Dictionary = _first_strike_ability(actor, allowed)
	if strike.is_empty():
		return _wait("boss", "no_usable_ability")
	return _strike_or_close(actor, "boss", strike, opponents, false)


## Explosion-phase choreography (decision #27): the boss's first decide in the
## phase telegraphs (visible steam, 1 Moment), it holds through the escape
## window (`escape_moments`, canon 2 — the counterplay is moving out of radius),
## then the decide after the window resolves the blast. Pure over stored beat
## state + the clock — no rng; the beat advances only when CombatSim executes
## the returned choice (begin_explosion_telegraph / resolve_explosion_blast).
func _decide_explosion_beat(actor: CombatantState, phase: int, explosion: Dictionary) -> Dictionary:
	var radius: int = int(explosion.get("radius", 0))
	var escape: int = maxi(0, int(explosion.get("escape_moments", 0)))
	var beat: Dictionary = explosion_beats.get(actor.id, {})
	if beat.is_empty():
		return {
			"choice": "telegraph", "tier": "boss", "phase": phase,
			"radius": radius, "moments_until_blast": escape + 1,
		}
	if clock.tick <= int(beat.get("telegraph_tick", 0)) + escape:
		return _wait("boss", "explosion_building")
	return {"choice": "blast", "tier": "boss", "phase": phase, "radius": radius}


## Shared strike/close flow: pick a target in reach (optionally after the free
## move) and return the attack decision; move-only or wait when out of reach.
func _strike_or_close(actor: CombatantState, tier: String, strike: Dictionary, opponents: Array[CombatantState], elite_pick: bool) -> Dictionary:
	var reach: int = _ability_range(strike)
	var from: Vector2i = actor.position
	var target: CombatantState = _pick_target(actor, opponents, from, reach, elite_pick)
	var move_to: Variant = null
	if target == null:
		var nearest: CombatantState = _pick_target(actor, opponents, from, -1, false)
		if nearest != null:
			move_to = _step_toward(actor, nearest.position, reach)
		if move_to != null:
			from = move_to
			target = _pick_target(actor, opponents, from, reach, elite_pick)
	if target == null:
		if move_to != null:
			return {"choice": "move", "tier": tier, "move_to": move_to}
		return _wait(tier, "no_reachable_action")
	var part_key: String = _pick_part(target, strike, elite_pick)
	if part_key == "":
		return _wait(tier, "no_reachable_action")
	var decision: Dictionary = {
		"choice": "attack", "tier": tier,
		"ability": String(strike.get("key", "")),
		"target": target.id,
		"action": _attack_action(strike, [{"id": target.id, "part": part_key}]),
	}
	if move_to != null:
		decision["move_to"] = move_to
	return decision


func _cone_decision(actor: CombatantState, cone: Dictionary, in_cone: Array[CombatantState]) -> Dictionary:
	var targets: Array[Dictionary] = []
	for opponent: CombatantState in in_cone:
		var part_key: String = _pick_part(opponent, cone, false)
		if part_key != "":
			targets.append({"id": opponent.id, "part": part_key})
	if targets.is_empty():
		return _wait("boss", "no_reachable_action")
	var action: Dictionary = _attack_action(cone, targets)
	action["rpm"] = targets.size()  # one round per swept target (v1 cone model)
	action["rounds"] = targets.size()
	return {
		"choice": "attack", "tier": "boss",
		"ability": String(cone.get("key", "")),
		"target": String((targets[0] as Dictionary).get("id", "")),
		"action": action,
	}


static func _wait(tier: String, reason: String) -> Dictionary:
	return {"choice": "wait", "tier": tier, "reason": reason}


# ------------------------------------------------------------------ targeting

## Living, in-play combatants whose team differs from the actor's. An actor
## with an EMPTY team sees no targets (teams are explicit — R11 #15); a
## teamless combatant IS hostile to any teamed enemy. A grappled actor is
## locked onto its living grappler. Targets without an attackable part are
## skipped. Sorted-id iteration keeps this deterministic.
func _opponents(actor: CombatantState) -> Array[CombatantState]:
	var out: Array[CombatantState] = []
	if actor.team == "":
		return out
	if actor.grappled_by != "":
		var grappler: CombatantState = combatants.get(actor.grappled_by)
		if grappler != null and grappler.alive and not grappler.removed_from_play \
				and grappler.team != actor.team and not _attackable_parts(grappler).is_empty():
			out.append(grappler)
			return out
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or other.team == actor.team:
			continue
		if not other.alive or other.removed_from_play:
			continue
		if _attackable_parts(other).is_empty():
			continue
		out.append(other)
	return out


## Priority pick among opponents within reach of `from` (reach < 0 = anywhere).
## Mob rule: nearest → lowest total HP → id. Elite rule ("picks off the weak"):
## lowest total HP → nearest → id. Returns null when nobody is in reach.
func _pick_target(actor: CombatantState, opponents: Array[CombatantState], from: Vector2i, reach: int, elite_pick: bool) -> CombatantState:
	var best: CombatantState = null
	var best_distance: int = 0
	var best_hp: int = 0
	for opponent: CombatantState in opponents:
		var d: int = CombatantState.hex_distance(from, opponent.position)
		if reach >= 0 and d > reach:
			continue
		var hp: int = _total_hp(opponent)
		var better: bool = false
		if best == null:
			better = true
		elif elite_pick:
			better = hp < best_hp or (hp == best_hp and d < best_distance)
		else:
			better = d < best_distance or (d == best_distance and hp < best_hp)
		if better:
			best = opponent
			best_distance = d
			best_hp = hp
	return best


static func _total_hp(c: CombatantState) -> int:
	var total: int = 0
	var keys: Array = c.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		total += int((c.parts[part_key] as Dictionary).get("hp", 0))
	return total


## Parts an attack can meaningfully hit: hp > 0, not destroyed, not hidden
## behind surface immunity; heads only when the book's gate allows (R7).
func _attackable_parts(target: CombatantState) -> Array[String]:
	var out: Array[String] = []
	var keys: Array = target.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		var part: Dictionary = target.parts[key]
		if int(part.get("hp", 0)) <= 0 or bool(part.get("destroyed", false)):
			continue
		if Resistance.part_blocked_by_surface_immunity(target, key):
			continue
		if key.contains("head") and not _head_targetable(target):
			continue
		out.append(key)
	return out


func _head_targetable(target: CombatantState) -> bool:
	return target.exposed_cache \
		or target.is_helpless(clock.tick) \
		or bool(target.statuses.get("overwhelmed", false))


## Mob/boss part pick: torso-line (torso → first non-head lethal → first);
## a "part_bias" on the ability's damage entry is honored first. Elite pick
## punishes exposure: head when targetable, else the lowest-HP part.
func _pick_part(target: CombatantState, ability: Dictionary, elite_pick: bool) -> String:
	var candidates: Array[String] = _attackable_parts(target)
	if candidates.is_empty():
		return ""
	if elite_pick:
		for key: String in candidates:
			if key.contains("head"):
				return key
		var best: String = candidates[0]
		for key: String in candidates:
			if int((target.parts[key] as Dictionary).get("hp", 0)) < int((target.parts[best] as Dictionary).get("hp", 0)):
				best = key
		return best
	var bias: String = String(_first_damage(ability).get("part_bias", ""))
	if bias != "" and candidates.has(bias):
		return bias
	if candidates.has("torso"):
		return "torso"
	for key: String in candidates:
		if bool((target.parts[key] as Dictionary).get("lethal", false)) and not key.contains("head"):
			return key
	return candidates[0]


# ------------------------------------------------------------------ abilities

## First ability carrying the given effect key ("summon", "heal"), in authored
## order. Unsupported shapes (sequence/effect-only) are skipped by the strike
## lookup, so death_spin/drag_back defer cleanly (R11 #16).
func _first_ability_with(actor: CombatantState, effect_key: String) -> Dictionary:
	for ability: Dictionary in actor.abilities:
		if ability.has(effect_key):
			return ability
	return {}


## First plain strike ability (damage list, no sequence, not a cone), filtered
## to `allowed` keys when non-empty (the boss phase's behavior list).
func _first_strike_ability(actor: CombatantState, allowed: Array) -> Dictionary:
	for ability: Dictionary in actor.abilities:
		if not allowed.is_empty() and not allowed.has(String(ability.get("key", ""))):
			continue
		if ability.has("sequence") or _is_cone(ability):
			continue
		if (ability.get("damage", []) as Array).is_empty():
			continue
		return ability
	return {}


func _first_cone_ability(actor: CombatantState, allowed: Array) -> Dictionary:
	for ability: Dictionary in actor.abilities:
		if not allowed.is_empty() and not allowed.has(String(ability.get("key", ""))):
			continue
		if _is_cone(ability) and not (ability.get("damage", []) as Array).is_empty():
			return ability
	return {}


static func _is_cone(ability: Dictionary) -> bool:
	return String(ability.get("area", "")).begins_with("cone")


## Reach: explicit "range", else the cone's size ("cone 10"), else 1. The v1
## cone model is range-only (true cone/line geometry is KAN-5 scope, R11 #16).
static func _ability_range(ability: Dictionary) -> int:
	if ability.has("range"):
		return maxi(1, int(ability.get("range", 1)))
	var area := String(ability.get("area", ""))
	if area.begins_with("cone"):
		return maxi(1, int(area.get_slice(" ", 1)))
	return 1


## v1 uses the FIRST damage entry of a multi-damage ability (deferral, R11 #16).
static func _first_damage(ability: Dictionary) -> Dictionary:
	var damage: Array = ability.get("damage", [])
	if damage.is_empty():
		return {}
	return damage[0]


func _attack_action(ability: Dictionary, targets: Array[Dictionary]) -> Dictionary:
	var damage: Dictionary = _first_damage(ability)
	var action: Dictionary = {
		"kind": "attack",
		"key": String(ability.get("key", "")),
		"cost": maxi(1, int(ability.get("moment_cost", 1))),
		"damage": {"type": String(damage.get("type", "")), "amount": int(damage.get("amount", 0))},
		"attack_range": _ability_range(ability),
		"targets": targets,
	}
	# R22: an ability-authored dodge block (the Dash counters ladder) rides the
	# action so the resolver can run the target-side dodge at the strike round.
	if ability.has("dodge"):
		action["dodge"] = (ability.get("dodge", {}) as Dictionary).duplicate(true)
	return action


func _wants_heal(actor: CombatantState) -> bool:
	var keys: Array = actor.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var part: Dictionary = actor.parts[part_key]
		if not bool(part.get("lethal", false)):
			continue
		if float(part.get("hp", 0)) < actor.max_hp(String(part_key)) * HEAL_LETHAL_PART_RATIO:
			return true
	return false


# ------------------------------------------------------------------ movement

## Greedy free-move plan toward `goal`: up to the allowance, each step the
## fixed-order neighbor that strictly reduces hex distance and is not occupied
## by a living combatant. Stops inside `stop_range`. Returns null when no legal
## improving step exists or the actor cannot move this tick.
func _step_toward(actor: CombatantState, goal: Vector2i, stop_range: int) -> Variant:
	if actor.grappled_by != "" or actor.grappling != "" or actor.windup_pending:
		return null
	if actor.moved_this_tick or actor.free_action_used:
		return null
	var prone: bool = bool(actor.statuses.get("prone", false))
	var slowed: bool = bool(actor.statuses.get("slowed", false))
	var allowance: int = 1 if (prone or slowed) else FREE_MOVE_SPACES
	var occupied: Dictionary = _occupied_hexes(actor)
	var pos: Vector2i = actor.position
	for step: int in range(allowance):
		var current_d: int = CombatantState.hex_distance(pos, goal)
		if current_d <= stop_range:
			break
		var best: Variant = null
		var best_d: int = current_d
		for neighbor: Vector2i in HEX_NEIGHBORS:
			var candidate: Vector2i = pos + neighbor
			if occupied.has(candidate):
				continue
			var d: int = CombatantState.hex_distance(candidate, goal)
			if d < best_d:
				best = candidate
				best_d = d
		if best == null:
			break
		pos = best
	if pos == actor.position:
		return null
	return pos


func _occupied_hexes(actor: CombatantState) -> Dictionary:
	var occupied: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or not other.alive or other.removed_from_play:
			continue
		occupied[other.position] = true
	return occupied


# ------------------------------------------------------------------ dodge (R22)

## R22 unified dodge check — the threshold asks the DODGER's Reflexes (SUPERSEDES
## the flat d6 of R11 #17). One check, both directions (boss dodging an aimed
## round; a contestant dodging the Dash):
##   Reflexes >= threshold           -> auto-dodge, NO rng consumed.
##   Reflexes + threshold die >= t   -> roll the stat's die (default 1d4) from
##                                      the salted ai_rng and add it.
##   Reflexes + die max < threshold  -> the dodge is IMPOSSIBLE: no rng, no
##                                      event ({} — preview reports the class).
## No dodge while Helpless, Exposed or Prone (windups, grapples and the slam
## punish window). Consumes the salted ai_rng ONLY. Returns {} when no attempt
## happens; else {"dodged", "roll" (0 when auto), "die", "reflexes",
## "threshold", "auto"}.
func check_dodge(target: CombatantState, tick: int, threshold: int) -> Dictionary:
	if threshold <= 0:
		return {}
	if not target.alive or target.removed_from_play:
		return {}
	if target.is_helpless(tick) or target.exposed_cache or bool(target.statuses.get("prone", false)):
		return {}
	var reflexes: int = target.trait_total("reflexes")
	var die: int = target.threshold_die("reflexes")
	if reflexes >= threshold:
		return {"dodged": true, "roll": 0, "die": die, "reflexes": reflexes, "threshold": threshold, "auto": true}
	if reflexes + die < threshold:
		return {}  # impossible — intended texture (R22: Imani vs the Dash), no rng
	var roll: int = ai_rng.randi_range(1, die)
	return {"dodged": reflexes + roll >= threshold, "roll": roll, "die": die, "reflexes": reflexes, "threshold": threshold, "auto": false}


## The boss's own aimed-round dodge (authored via boss_traits.dodge_threshold,
## R2's explicit-miss pattern) — the R22 check against the boss's Reflexes.
func try_dodge(target: CombatantState, tick: int) -> Dictionary:
	return check_dodge(target, tick, int(target.boss_traits.get("dodge_threshold", 0)))


## Torso-line part pick on `target` for the R22 dash counterattack (mirrors the
## non-elite _pick_part path without an ability bias): torso when attackable,
## else the first non-head lethal candidate, else the first non-head candidate
## (the counter aims at the body line even when a windup exposes the head —
## head-hunting stays the elite persona, not a free rider). "" when nothing is
## attackable.
func torso_line_part(target: CombatantState) -> String:
	var candidates: Array[String] = _attackable_parts(target)
	if candidates.is_empty():
		return ""
	if candidates.has("torso"):
		return "torso"
	for key: String in candidates:
		if bool((target.parts[key] as Dictionary).get("lethal", false)) and not key.contains("head"):
			return key
	for key: String in candidates:
		if not key.contains("head"):
			return key
	return candidates[0]


# ------------------------------------------------------------------ phases (R11 #18)

func current_phase(combatant_id: String) -> int:
	return int(boss_phase.get(combatant_id, 1))


func _phase_entry(actor: CombatantState, phase_number: int) -> Dictionary:
	for entry: Dictionary in actor.boss_phases:
		if int(entry.get("phase_number", 0)) == phase_number:
			return entry
	return {}


## Phase-machine check, run by CombatSim._post after every command: while in a
## fight phase, the health part dropping to an explosion phase's hp_at_or_below
## fires boss_phase_changed — the boss enters the valve, and the explosion beat
## (decision #27: telegraph -> escape window -> blast) plays out over its next
## ai_decides. While an explosion phase is live the hp gate stays quiet: only
## the blast leaves the phase (resolve_explosion_blast applies the canonical
## retreat and advances into the next Threshold). Wounds PERSIST throughout.
func phase_events(c: CombatantState, _cond: ConditionEngine) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if c.boss_phases.is_empty() or not c.alive:
		return events
	var immunity: Dictionary = c.boss_traits.get("surface_immunity", {})
	var health_part := String(immunity.get("health_part", ""))
	if health_part == "" or not c.parts.has(health_part):
		return events
	var phase: int = current_phase(c.id)
	var current_behavior: Dictionary = _phase_entry(c, phase).get("behavior", {})
	if current_behavior.has("explosion"):
		return events  # the beat machine owns leaving an explosion phase (#27)
	var hp: int = int((c.parts[health_part] as Dictionary).get("hp", 0))
	for entry: Dictionary in c.boss_phases:
		var num: int = int(entry.get("phase_number", 0))
		if num <= phase or not entry.has("hp_at_or_below"):
			continue
		if hp > int(entry.get("hp_at_or_below", 0)):
			break  # explosion thresholds are ordered downward; nothing fires yet
		boss_phase[c.id] = num
		events.append({
			"type": "boss_phase_changed",
			"combatant": c.id, "from_phase": phase, "to_phase": num,
			"name": String(entry.get("name", "")),
		})
		break
	return events


## Executes the "telegraph" choice: records the beat start and vents the steam.
## The event is the counterplay cue — radius + moments_until_blast tell the
## party exactly what to outrun (telegraph Moment + escape window).
func begin_explosion_telegraph(actor: CombatantState, decision: Dictionary) -> Array[Dictionary]:
	explosion_beats[actor.id] = {
		"phase": int(decision.get("phase", current_phase(actor.id))),
		"telegraph_tick": clock.tick,
	}
	var events: Array[Dictionary] = [{
		"type": "explosion_telegraph",
		"combatant": actor.id,
		"phase": int(decision.get("phase", 0)),
		"radius": int(decision.get("radius", 0)),
		"moments_until_blast": int(decision.get("moments_until_blast", 0)),
	}]
	return events


## Executes the "blast" choice: every OTHER living, in-play combatant within
## the hex radius is knocked out — Helpless for 2 Clocks (owner ruling,
## decision #27), no damage, no death. Friendly fire is ON (other enemies in
## radius are caught; the boss itself is not) and the blast is never dodged
## (collateral/environment, R22); an already-Helpless victim just has the
## window extended (maxi). Then the canonical retreat applies when this valve
## resets the breach, and the machine advances into the next phase — the boss
## resumes normal fight behavior next Moment.
func resolve_explosion_blast(actor: CombatantState, decision: Dictionary, cond: ConditionEngine) -> Array[Dictionary]:
	var phase: int = int(decision.get("phase", current_phase(actor.id)))
	var radius: int = int(decision.get("radius", 0))
	var events: Array[Dictionary] = [{
		"type": "explosion_blast",
		"combatant": actor.id, "phase": phase, "radius": radius,
		"position": [actor.position.x, actor.position.y],
	}]
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or not other.alive or other.removed_from_play:
			continue
		if CombatantState.hex_distance(actor.position, other.position) > radius:
			continue
		other.helpless_until_tick = maxi(other.helpless_until_tick, clock.tick + 2 * Clock.TICKS_PER_CLOCK)
		events.append({
			"type": "explosion_knockout",
			"combatant": other.id, "by": actor.id,
			"helpless_until_tick": other.helpless_until_tick,
		})
	explosion_beats.erase(actor.id)
	var immunity: Dictionary = actor.boss_traits.get("surface_immunity", {})
	var health_part := String(immunity.get("health_part", ""))
	if health_part != "" and actor.parts.has(health_part) \
			and int(immunity.get("breach_resets_after_phase", 0)) == phase:
		events.append_array(_retreat(actor, health_part, cond))
	for entry: Dictionary in actor.boss_phases:
		var num: int = int(entry.get("phase_number", 0))
		if num <= phase:
			continue
		boss_phase[actor.id] = num
		events.append({
			"type": "boss_phase_changed",
			"combatant": actor.id, "from_phase": phase, "to_phase": num,
			"name": String(entry.get("name", "")),
		})
		break
	return events


## The pressure-valve reset ("network retreats deeper — breach threshold
## resets", canon). Wounds PERSIST across the valve (owner-ruled, R11 #18).
func _retreat(c: CombatantState, health_part: String, _cond: ConditionEngine) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	c.breached = false
	var part: Dictionary = c.parts[health_part]
	part["hidden"] = true
	c.damage_taken_this_tick = 0
	c.largest_single_hit_this_tick = 0
	c.combo_hits_this_tick.clear()
	# Wounds PERSIST across the retreat (owner-ruled 2026-07-18): active
	# conditions and part damage carry over the pressure valve — only the breach
	# threshold resets (network re-hides + burst counter clears), never the
	# accumulated harm. Clearing the burst counters still blocks a same-tick
	# re-breach (the retreat now rides the blast mid-tick, #27, so the tick-flag
	# reset no longer covers it); the Bleeding-T2 path re-fires only on a fresh
	# advancement.
	events.append({"type": "breach_reset", "combatant": c.id, "part": health_part})
	return events


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	return {
		"ai_rng_state": ai_rng.state,
		"boss_phase": boss_phase.duplicate(true),
		"summons": summons.duplicate(true),
		"explosion_beats": explosion_beats.duplicate(true),
	}


static func from_dict(data: Dictionary) -> EnemyAI:
	var ai := EnemyAI.new()
	ai.ai_rng.state = int(data.get("ai_rng_state", 0))
	ai.boss_phase = (data.get("boss_phase", {}) as Dictionary).duplicate(true)
	ai.summons = (data.get("summons", {}) as Dictionary).duplicate(true)
	ai.explosion_beats = (data.get("explosion_beats", {}) as Dictionary).duplicate(true)
	return ai
