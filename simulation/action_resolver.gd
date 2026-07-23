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
var ai: EnemyAI

## R15 merged-force groups for the CURRENT resolve_due batch ONLY (never across
## commands — built by _prescan_merge_groups, flushed + cleared before resolve_due
## returns, so serialization stays trivially correct: the field is always empty
## between commands). Key "combo_id|target_id|part" -> group Dictionary.
var _merge_groups: Dictionary = {}


func setup(clock_ref: Clock, combatants_ref: Dictionary, cond_ref: ConditionEngine, rng_ref: RandomNumberGenerator, ai_ref: EnemyAI) -> void:
	clock = clock_ref
	combatants = combatants_ref
	cond = cond_ref
	rng = rng_ref
	ai = ai_ref


static func _reject(reason: String, detail: Dictionary = {}) -> Array[Dictionary]:
	var event: Dictionary = {"type": "command_rejected", "reason": reason}
	event.merge(detail)
	var events: Array[Dictionary] = [event]
	return events


# ------------------------------------------------------------------ declare

## Declares a scheduled or free (0-Moment) action. Action dict keys:
## kind ("attack"|"skill"|"grapple"|"grapple_escape"|"grapple_suffocate"|
## "reload"|"stand"|"wait"), cost, key (action identity), prime (R3 priming
## gate — a requirement-shaped Dictionary; see _prime_unmet),
## item (key on the actor), damage {"type","amount"},
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

	# R3 priming gate (decision-log #20): "cooldowns do not exist" — a declared
	# action instead gates on its PRIME. Unsatisfied primes reject at declare.
	var prime_reason: String = _prime_unmet(actor, action)
	if prime_reason != "":
		return _reject("prime_unmet", {"actor": actor_id, "prime": prime_reason})

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
	events.append_array(_apply_declare_riders(actor, kind, action, resolve_tick))
	return events


## Declare-time skill riders. Committed strikes commit the actor: they are Exposed
## through the windup (the existing exposure system reports it). And the dance
## stance ends the moment its owner commits to an attack or a damaging skill.
func _apply_declare_riders(actor: CombatantState, kind: String, action: Dictionary, resolve_tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if actor.dancing and _action_is_damaging(kind, action):
		events.append_array(_end_dance(actor, "declared_attack"))
	if kind == "skill":
		var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
		if String(spec.get("archetype", "")) == "committed_strike":
			# Exposed for the whole windup and the beat it lands on (R2 channeling).
			actor.exposed_until_tick = maxi(actor.exposed_until_tick, resolve_tick + 1)
	return events


## True when an action deals damage for the dance-end trigger: any attack, an
## encoded damaging skill archetype, or a generic-fallback skill with a target.
func _action_is_damaging(kind: String, action: Dictionary) -> bool:
	if kind == "attack":
		return true
	if kind == "skill":
		var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
		var arch := String(spec.get("archetype", ""))
		if arch == "committed_strike" or arch == "conditional_followup":
			return true
		if arch == "strike":
			return not (action.get("targets", []) as Array).is_empty()
	return false


# ------------------------------------------------------------------ priming (R3)

## The prime a declared action gates on: action["prime"] wins; for a skill it
## falls back to the SkillBook spec's "prime" when the action does not override.
## Returns {} when the action carries no prime.
func _effective_prime(action: Dictionary) -> Dictionary:
	var prime: Dictionary = action.get("prime", {})
	if prime.is_empty() and String(action.get("kind", "")) == "skill":
		var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
		prime = spec.get("prime", {})
	return prime


## R3 priming gate (rules-addendum R3, decision-log #20 — "cooldowns do not
## exist"). A declared action may gate on ONE of five canonical, requirement-
## shaped primes. Returns "" when satisfied (or the action carries no prime),
## else a short unmet reason. Evaluated at DECLARE against live state.
##   CHAIN          {"type":"chain","after":k}                — actor's last resolved key == k
##   STANCE         {"type":"stance","stance":s}              — actor holds stance s
##   STACK          {"type":"stack","resource":r,"count":n}   — actor has >= n of r
##   STATE-POSITION {"type":"state","who":"self|target","status":s} — subject has status s
##   PREP-CHANNEL   {"type":"prep","key":k}                   — actor has armed prime k
func _prime_unmet(actor: CombatantState, action: Dictionary) -> String:
	var prime: Dictionary = _effective_prime(action)
	if prime.is_empty():
		return ""
	match String(prime.get("type", "")):
		"chain":
			var after := String(prime.get("after", ""))
			if actor.last_action_key != after:
				return "chain_after:%s" % after
		"stance":
			var want := String(prime.get("stance", ""))
			if actor.stance != want:
				return "stance:%s" % want
		"stack":
			var resource := String(prime.get("resource", ""))
			var need: int = int(prime.get("count", 1))
			if _stack_count(actor, resource) < need:
				return "stack:%s<%d" % [resource, need]
		"state":
			var who := String(prime.get("who", "self"))
			var status := String(prime.get("status", ""))
			var subject: CombatantState = actor if who == "self" else _first_target(action)
			if subject == null or not _has_status(subject, status):
				return "state:%s:%s" % [who, status]
		"prep":
			var key := String(prime.get("key", ""))
			if not bool(actor.armed_primes.get(key, false)):
				return "prep:%s" % key
		_:
			return "unknown_prime:%s" % String(prime.get("type", ""))
	return ""


## STACK resource count: the camera-call resource reuses the actor's Charm
## over-cap camera-call stacks (R6, derived); any other name reads the generic
## `charges` fallback.
func _stack_count(actor: CombatantState, resource: String) -> int:
	if resource == "camera_call":
		return int(actor.derived_stats().get("camera_call_stacks", 0))
	return int(actor.charges.get(resource, 0))


## STATE-POSITION status read: "exposed"/"helpless" use the live caches the rest
## of the resolver reads; everything else is a plain statuses flag.
func _has_status(c: CombatantState, status: String) -> bool:
	if status == "exposed":
		return c.exposed_cache
	if status == "helpless":
		return c.is_helpless(clock.tick)
	return bool(c.statuses.get(status, false))


# ------------------------------------------------------- read-only preview (HUD v2)

## READ-ONLY action preview (spectator contract — ADDITIVE, HUD v2 Phase 2).
## Predicts what declaring `action` would cost and what its strike would do,
## WITHOUT mutating any state and WITHOUT touching either rng stream: a dodge
## (either direction — boss aimed-round OR the Dash ladder, R22) is reported as
## UNCERTAINTY (threshold, dodger Reflexes, die size, outcome class — read off
## the same fields EnemyAI.check_dodge reads) — never rolled. Reuses the live authorities
## (_effective_cost / _prime_unmet / the exact _strike_round Force formula +
## Resistance helpers + the part condition_immunities / bleed_immune / D3 gates)
## so the preview never lies. Returns a plain Dictionary:
##   cost: int              — effective Moment cost (Exhausted/Strained included)
##   windup: bool           — cost >= 2 commits through a windup (R2)
##   prime_unmet: String    — "" ok, else the same reason declare would reject on
##   per_target: [{id, part, force, robustness, net, landed,
##                 blocked_reason ("" | "surface_immunity" | "robustness" | "fire_heals"),
##                 conditions: [ids that would ride the hit],
##                 dodge_possible: bool, dodge_threshold: int,
##                 dodge_reflexes: int, dodge_die: int,
##                 dodge_outcome: "" | "ineligible" | "auto_dodge" | "roll_needed" | "impossible",
##                 dodge_roll_needed: int (0 unless roll_needed)}]
##   merged: {force, robustness, net} — only when the action carries a
##           "combo_members" combined-preview request (see below).
##
## COMBINED preview: action["combo_members"] = [{"actor_id", "action"}...] asks
## for the R15 merged-force projection — per_target then carries one row per
## member (its own Force / dodge read) and `merged` sums the CONNECTED members'
## Forces against the one merged Robustness gate, mirroring _merge_apply
## (lowest flat reduction among the component types; dodge stays uncertainty —
## an eligible dodge can still shrink the real merged hit).
func preview_action(actor: CombatantState, action: Dictionary) -> Dictionary:
	if action.has("combo_members"):
		return _preview_combined(action)
	if actor == null:
		return {}
	var kind := String(action.get("kind", "attack"))
	var uses_strained: bool = actor.strained_grip and (kind == "attack" or kind == "reload")
	var out: Dictionary = {
		"cost": _effective_cost(actor, kind, action, uses_strained),
		"windup": _effective_cost(actor, kind, action, uses_strained) >= 2,
		"prime_unmet": _prime_unmet(actor, action),
		"per_target": [],
	}
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var row: Dictionary = _preview_target_row(actor, action, String(t.get("id", "")), String(t.get("part", "")))
		if not row.is_empty():
			(out["per_target"] as Array).append(row)
	return out


## One per_target preview row — the read-only twin of _strike_round's math.
## {} when the target/part does not exist (declare would reject those anyway).
func _preview_target_row(actor: CombatantState, action: Dictionary, target_id: String, part_key: String) -> Dictionary:
	var target: CombatantState = combatants.get(target_id)
	if target == null or not target.parts.has(part_key):
		return {}
	var damage: Dictionary = _preview_damage(actor, action)
	var condition_id := ConditionEngine.normalize_condition_id(String(damage.get("type", "")))
	var amount: int = int(damage.get("amount", 0))
	# R10 requirements gate: unmet halves the amount (deterministic; the Tool d6
	# rider stays run-time uncertainty and is NOT modelled here).
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	var requirements: Dictionary = action.get("requirements", item.get("stat_requirements", {}))
	if _requirements_unmet(actor, requirements, action.get("combo_provides", {})):
		amount = floori(amount / 2.0)
	var cond_def: Dictionary = cond.def_for(condition_id)
	var is_physical: bool = String(cond_def.get("resistance_type", "")) == "Physical"
	# The EXACT _strike_round formulas (R14):
	var atk_physique: int = actor.trait_total("physique")
	var force: int = amount + floori(atk_physique / 2.0)
	var part_armor: int = int((target.parts[part_key] as Dictionary).get("armor", 0))
	var flat_res: int = Resistance.flat_physical_reduction(target, condition_id)
	var robustness: int = floori(target.trait_total("physique") / 2.0) + part_armor + flat_res
	var landed: bool = force > robustness
	var blocked_reason: String = ""
	var net: int = 0
	if condition_id == "burn" and Resistance.fire_heals(target) \
			and not bool(target.parts.get(part_key, {}).get("fire_harms", false)):
		blocked_reason = "fire_heals"  # the hit would HEAL the target (boss hook)
		landed = false
	elif Resistance.part_blocked_by_surface_immunity(target, part_key):
		blocked_reason = "surface_immunity"
		landed = false
	else:
		if is_physical:
			net = maxi(0, force - robustness)
		else:
			net = Resistance.reduce_damage(amount, target, cond_def, condition_id)
			landed = true  # non-Physical paths are not force-gated (R14)
		# self_guard (brace): the buffered Crush/Burn guard is deterministic state.
		if target.brace_guard > 0 and (condition_id == "crushed" or condition_id == "burn"):
			net = maxi(0, net - target.brace_guard)
		if is_physical and not landed:
			blocked_reason = "robustness"
	# Dodge UNCERTAINTY (R22) — the same threshold + eligibility check_dodge
	# reads, NEVER rolled. Boss direction: the target's boss_traits threshold;
	# dash direction: the ability's authored "dodge" block (non-boss dodgers).
	# Additive keys only; dodge_possible stays accurate (false when the dodge is
	# ineligible OR impossible — Reflexes + die max < threshold).
	var threshold: int = int(target.boss_traits.get("dodge_threshold", 0))
	if threshold <= 0:
		threshold = int((action.get("dodge", {}) as Dictionary).get("threshold", 0))
	var dodge_eligible: bool = threshold > 0 and target.alive and not target.removed_from_play \
		and not target.is_helpless(clock.tick) and not target.exposed_cache \
		and not bool(target.statuses.get("prone", false))
	var dodge_reflexes: int = target.trait_total("reflexes")
	var dodge_die: int = target.threshold_die("reflexes")
	var dodge_outcome: String = ""
	var dodge_roll_needed: int = 0
	if threshold > 0:
		if not dodge_eligible:
			dodge_outcome = "ineligible"
		elif dodge_reflexes >= threshold:
			dodge_outcome = "auto_dodge"
		elif dodge_reflexes + dodge_die >= threshold:
			dodge_outcome = "roll_needed"
			dodge_roll_needed = threshold - dodge_reflexes
		else:
			dodge_outcome = "impossible"
	return {
		"id": target_id,
		"part": part_key,
		"force": force,
		"robustness": robustness,
		"net": net,
		"landed": landed,
		"blocked_reason": blocked_reason,
		"conditions": _preview_riding_conditions(target, part_key, condition_id, cond_def, landed, action),
		"dodge_possible": dodge_eligible and dodge_outcome != "impossible",
		"dodge_threshold": threshold,
		"dodge_reflexes": dodge_reflexes,
		"dodge_die": dodge_die,
		"dodge_outcome": dodge_outcome,
		"dodge_roll_needed": dodge_roll_needed,
	}


## The damage dict the strike would actually use, mirroring _strike_via_spec /
## _resolve_strike: a known skill's SkillBook spec is the authority; otherwise
## the action's own damage, then the item's listed damage.
func _preview_damage(actor: CombatantState, action: Dictionary) -> Dictionary:
	var kind := String(action.get("kind", "attack"))
	if kind == "skill":
		var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
		if spec.has("damage_type") and (SkillBook.is_known(String(action.get("key", ""))) or not action.has("damage")):
			return {"type": String(spec["damage_type"]), "amount": int(spec.get("amount", 1))}
	var damage: Dictionary = action.get("damage", {})
	if damage.is_empty():
		var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
		if item.has("damage_type"):
			damage = {"type": String(item.get("damage_type", "")), "amount": int(item.get("damage_amount", 0))}
	return damage


## Condition ids that would RIDE the hit, mirroring the resolve-time gates:
## D3 (a damaging condition needs a landed wound), the part's bleed_immune +
## condition_immunities (with the neural-poison bypass), and surface hiding.
func _preview_riding_conditions(target: CombatantState, part_key: String, condition_id: String, cond_def: Dictionary, landed: bool, action: Dictionary) -> Array:
	if condition_id == "" or cond_def.is_empty():
		return []
	if _condition_needs_wound(condition_id, cond_def) and not landed:
		return []  # R14 D3: blocked to no wound -> no bleed/burn/poison seeds
	var part: Dictionary = target.parts.get(part_key, {})
	if condition_id == "bleeding" and bool(part.get("bleed_immune", false)):
		return []
	var immunities: Array = part.get("condition_immunities", [])
	if immunities.has(condition_id):
		var neural_bypass: bool = condition_id == "poison" and String(action.get("poison_type", "")) == "neural"
		if not neural_bypass:
			return []
	if bool(part.get("hidden", false)) and not target.breached:
		return []
	return [condition_id]


## Combined-strike preview (R15 merged force, read-only): per-member rows +
## the ONE merged gate _merge_apply would evaluate. A member CONNECTS for the
## merged sum when its row is not blocked (surface/fire) and its damage path is
## Physical — dodge remains per-member uncertainty, exactly as at resolve.
func _preview_combined(action: Dictionary) -> Dictionary:
	var rows: Array = []
	var sum_force: int = 0
	var merged_target: CombatantState = null
	var merged_part: String = ""
	var flat_min: int = -1
	var cost: int = 0
	var windup: bool = false
	var prime_unmet: String = ""
	for member: Variant in action.get("combo_members", []) as Array:
		var md: Dictionary = member
		var m_actor: CombatantState = combatants.get(String(md.get("actor_id", md.get("actor", ""))))
		var m_action: Dictionary = md.get("action", {})
		if m_actor == null:
			continue
		var m_kind := String(m_action.get("kind", "attack"))
		var m_strained: bool = m_actor.strained_grip and (m_kind == "attack" or m_kind == "reload")
		cost = maxi(cost, _effective_cost(m_actor, m_kind, m_action, m_strained))
		windup = windup or _effective_cost(m_actor, m_kind, m_action, m_strained) >= 2
		if prime_unmet == "":
			prime_unmet = _prime_unmet(m_actor, m_action)
		var targets: Array = m_action.get("targets", [])
		if targets.is_empty():
			continue
		var t: Dictionary = targets[0]
		var row: Dictionary = _preview_target_row(m_actor, m_action, String(t.get("id", "")), String(t.get("part", "")))
		if row.is_empty():
			continue
		row["actor"] = m_actor.id
		rows.append(row)
		# Mirror _merge_group_for/_merge_connect: only an unblocked Physical
		# member contributes Force to the merged gate.
		var m_damage: Dictionary = _preview_damage(m_actor, m_action)
		var m_cond := ConditionEngine.normalize_condition_id(String(m_damage.get("type", "")))
		var m_physical: bool = String(cond.def_for(m_cond).get("resistance_type", "")) == "Physical"
		if String(row.get("blocked_reason", "")) in ["surface_immunity", "fire_heals"] or not m_physical:
			continue
		sum_force += int(row.get("force", 0))
		merged_target = combatants.get(String(t.get("id", "")))
		merged_part = String(t.get("part", ""))
		var fr: int = Resistance.flat_physical_reduction(merged_target, m_cond)
		flat_min = fr if flat_min < 0 else mini(flat_min, fr)
	var merged: Dictionary = {"force": sum_force, "robustness": 0, "net": 0}
	if merged_target != null and merged_target.parts.has(merged_part):
		var part_armor: int = int((merged_target.parts[merged_part] as Dictionary).get("armor", 0))
		var robustness: int = floori(merged_target.trait_total("physique") / 2.0) + part_armor + maxi(0, flat_min)
		merged["robustness"] = robustness
		merged["net"] = maxi(0, sum_force - robustness)
	return {
		"cost": cost,
		"windup": windup,
		"prime_unmet": prime_unmet,
		"per_target": rows,
		"merged": merged,
	}


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
		"skill":
			# Cost/windup come from the SkillBook spec (brace/dance 0 = free;
			# feint 1 = instant; committed strikes 2 = windup). An explicit
			# action.cost still wins so a future chain discount can override.
			var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
			return int(action.get("cost", int(spec.get("cost", 1))))
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
		# R14: the reactor is the attacker for this out-of-schedule strike.
		events.append_array(_strike_round(target, String(payload.get("part", "torso")), condition_id, int(damage.get("amount", 0)), payload, actor))
	return events


# ------------------------------------------------------------------ resolution

## Resolves everything due this tick against the tick-start snapshot (R2).
## Returns {"events": Array[Dictionary], "forced": Array[Dictionary]} — forced
## consequences are applied by CombatSim AFTER all resolutions (R1 step 2).
func resolve_due(snapshot: Dictionary) -> Dictionary:
	var events: Array[Dictionary] = []
	var forced_queue: Array[Dictionary] = []
	var due: Array[Dictionary] = clock.take_due(clock.tick)
	_prescan_merge_groups(due)
	for entry: Dictionary in due:
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
	# R15: any merged group whose expected members did not all reach _strike_round
	# (whiff, invalidated windup, feint collapse, shock stutter, death mid-tick)
	# still lands what DID connect — flushed before forced consequences apply.
	events.append_array(_flush_merge_groups())
	return {"events": events, "forced": forced_queue}


# ------------------------------------------------------- merged force (R15)

## R15 merged force (rules-addendum R15 — "combined attacks merge force"; closes
## the R14 TODO): linked strikes (shared combo_id) that resolve on the SAME tick
## against the SAME target+part merge their Force values BEFORE the robustness
## gate — one merged gate, one merged net-damage hit. The pre-scan establishes
## GROUP MEMBERSHIP only (who is expected to strike); each member's ACTUAL Force
## is contributed at its own _strike_round — after requirement-halving is known
## and after its own dodge/surface checks — so the merged hit is always built
## from real, resolved contributions and the AI d6 stream is consumed in exactly
## the same order as un-merged play. Solo strikes (no combo_id, or a group of
## one) are completely unchanged.
func _prescan_merge_groups(due: Array[Dictionary]) -> void:
	_merge_groups.clear()
	for entry: Dictionary in due:
		var action: Dictionary = entry["action"]
		var combo_id := String(action.get("combo_id", ""))
		if combo_id == "":
			continue
		var kind := String(action.get("kind", ""))
		if kind != "attack" and kind != "skill":
			continue
		var targets: Array = action.get("targets", [])
		if targets.is_empty():
			continue
		var t: Dictionary = targets[0]
		var key := "%s|%s|%s" % [combo_id, String(t.get("id", "")), String(t.get("part", ""))]
		if not _merge_groups.has(key):
			_merge_groups[key] = {
				"combo_id": combo_id,
				"target_id": String(t.get("id", "")),
				"part": String(t.get("part", "")),
				"pending": 0,      # expected _strike_round check-ins still outstanding
				"connected": [],   # [{actor, force, condition, injection, poison_type}] in check-in order
				"applied": false,
			}
		var group: Dictionary = _merge_groups[key]
		group["pending"] = int(group["pending"]) + 1
	# A lone linked strike (no partner due on this tick+target+part) is a solo
	# strike — drop its group so the un-merged path handles it unchanged. (Its
	# recorded hit still accumulates per combo_id for the breach threshold.)
	for key: Variant in _merge_groups.keys():
		if int((_merge_groups[key] as Dictionary)["pending"]) < 2:
			_merge_groups.erase(key)


## The merged group this strike round belongs to, or {} for the solo path.
## Only Physical-path strikes merge force (R14: the force-vs-robustness model
## governs the Physical HP number; Affliction/Psychic keep reduce_damage and are
## not force-gated) — a non-Physical member drops out and resolves solo.
func _merge_group_for(action: Dictionary, target: CombatantState, part_key: String) -> Dictionary:
	var combo_id := String(action.get("combo_id", ""))
	if combo_id == "" or _merge_groups.is_empty():
		return {}
	var group: Dictionary = _merge_groups.get("%s|%s|%s" % [combo_id, target.id, part_key], {})
	if group.is_empty() or bool(group.get("applied", false)):
		return {}  # post-application rounds (rpm > 1 edge) fall back to solo
	return group


## A member that cannot contribute (dodged, surface-blocked, fire-healed, or
## non-Physical) drops out: its Force leaves the sum. Closing the group (last
## expected member accounted for) applies the merged hit NOW.
func _merge_drop(group: Dictionary, target: CombatantState) -> Array[Dictionary]:
	group["pending"] = int(group["pending"]) - 1
	if int(group["pending"]) <= 0:
		return _merge_apply(group, target)
	return []


## A member that connected contributes its ACTUAL Force (halving already applied
## to `force`'s amount component) + its condition rider. The LAST member to be
## accounted for applies the one merged hit.
func _merge_connect(group: Dictionary, target: CombatantState, condition_id: String, force: int, action: Dictionary, attacker: CombatantState) -> Array[Dictionary]:
	(group["connected"] as Array).append({
		"actor": attacker.id if attacker != null else "",
		"force": force,
		"condition": condition_id,
		"injection": bool(action.get("injection", false)),
		"poison_type": String(action.get("poison_type", "")),
	})
	return _merge_drop(group, target)


## Applies the ONE merged hit: net = max(0, sum(connected Forces) − Robustness).
## One damage application, one combined_force event, one recorded hit for the
## breach threshold. The merged hit is ONE wound: when it LANDS every connected
## member's condition rides it (a crushing + a bleeding component both apply);
## blocked to 0, the D3 rule holds (no bleed/burn/poison — non-wound conditions
## keep today's behavior).
func _merge_apply(group: Dictionary, target: CombatantState) -> Array[Dictionary]:
	group["applied"] = true
	var events: Array[Dictionary] = []
	var connected: Array = group["connected"]
	if connected.is_empty():
		return events  # every member missed — nothing lands
	var part_key := String(group["part"])
	var sum_force: int = 0
	var actors: Array = []
	for m: Variant in connected:
		sum_force += int((m as Dictionary)["force"])
		actors.append(String((m as Dictionary)["actor"]))
	# Robustness (R14): one merged gate. The flat physical reduction uses the
	# LOWEST value among the component damage types — the merged wound opens
	# along the least-resisted vector (all zero for the slice roster).
	var part_armor: int = int((target.parts[part_key] as Dictionary).get("armor", 0))
	var flat_res: int = -1
	for m: Variant in connected:
		var fr: int = Resistance.flat_physical_reduction(target, String((m as Dictionary)["condition"]))
		flat_res = fr if flat_res < 0 else mini(flat_res, fr)
	var robustness: int = floori(target.trait_total("physique") / 2.0) + part_armor + maxi(0, flat_res)
	var landed: bool = sum_force > robustness
	var reduced: int = maxi(0, sum_force - robustness)
	events.append({
		"type": "combined_force", "combo_id": String(group["combo_id"]),
		"combatant": target.id, "part": part_key,
		"actors": actors, "force": sum_force, "robustness": robustness, "net": reduced,
	})
	# self_guard (brace): the merged hit is ONE wound — a Crush/Burn component
	# lets the buffered guard absorb it once, exactly like a solo hit.
	var crush_or_burn: bool = false
	for m: Variant in connected:
		var cid := String((m as Dictionary)["condition"])
		if cid == "crushed" or cid == "burn":
			crush_or_burn = true
	if target.brace_guard > 0 and crush_or_burn:
		var before_guard: int = reduced
		reduced = maxi(0, reduced - target.brace_guard)
		events.append({
			"type": "brace_absorbed", "combatant": target.id, "part": part_key,
			"guard": target.brace_guard, "condition": String((connected[0] as Dictionary)["condition"]),
			"damage_before": before_guard, "damage_after": reduced,
		})
		target.brace_guard = 0
	events.append_array(cond.damage_part(target, part_key, reduced, "weapon", String((connected[0] as Dictionary)["condition"]), clock.tick))
	if target.dancing and reduced > 0:
		events.append_array(_end_dance(target, "hit"))
	# ONE recorded hit for the single-hit breach threshold (R15/NQ2).
	target.record_hit(String(group["combo_id"]), reduced)
	for m: Variant in connected:
		var md: Dictionary = m
		var cid := String(md["condition"])
		if not target.alive or cid == "":
			continue
		var cdef: Dictionary = cond.def_for(cid)
		if _condition_needs_wound(cid, cdef) and not landed:
			events.append({
				"type": "attack_no_wound", "combatant": target.id, "part": part_key,
				"condition": cid, "force": sum_force, "robustness": robustness,
			})
		else:
			events.append_array(cond.apply(target, part_key, cid, clock.tick, {
				"source": "attack",
				"injection": bool(md["injection"]),
				"poison_type": String(md["poison_type"]),
			}))
	return events


## End-of-batch safety net (see resolve_due): applies every un-applied group
## (sorted key order — deterministic), then clears the transient table.
func _flush_merge_groups() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var keys: Array = _merge_groups.keys()
	keys.sort()
	for key: Variant in keys:
		var group: Dictionary = _merge_groups[key]
		if bool(group["applied"]):
			continue
		var target: CombatantState = combatants.get(String(group["target_id"]))
		if target == null or not target.parts.has(String(group["part"])):
			continue
		events.append_array(_merge_apply(group, target))
	_merge_groups.clear()
	return events


func _resolve_entry(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var kind := String(action.get("kind", "attack"))
	# Shock T2 (Stutter, R13): the combatant's next resolved scheduled action simply
	# FAILS — check-and-clear at the same choke point feint uses, but with NO Forced
	# Action roll (feint collapses into a Tool roll; a stutter just fails). A stutter
	# is checked first: it invalidates the action outright, so the feint's pending
	# consequence is preserved and lands on the following action instead.
	if actor.shock_stutter_pending:
		actor.shock_stutter_pending = false
		return [{"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": "shock_stutter"}]
	# Feint (setup_debuff): the target's NEXT resolved scheduled action collapses
	# into a Forced Action – Tool — the same collapse an invalidated windup takes.
	# Check-and-clear at the START of the target's next resolution (any kind).
	if actor.feint_forced:
		return _collapse_feinted_action(actor, kind, forced_queue)
	var events: Array[Dictionary] = []
	match kind:
		"attack":
			events = _resolve_strike(actor, entry, snapshot, forced_queue)
		"skill":
			events = _resolve_skill(actor, entry, snapshot, forced_queue)
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
	# R3 priming bookkeeping (decision-log #20). Record the CHAIN key: this
	# action's identity becomes the actor's last_action_key (a different action's
	# key overwrites it, so a non-matching action "clears" a pending chain). A
	# PREP-CHANNEL prime is CONSUMED here — using the armed action spends it.
	actor.last_action_key = String(action.get("key", String(action.get("item", ""))))
	var eff_prime: Dictionary = _effective_prime(action)
	if String(eff_prime.get("type", "")) == "prep":
		actor.armed_primes.erase(String(eff_prime.get("key", "")))
	return events


# ------------------------------------------------------------------ skills (SkillBook)

## Resolves a kind=="skill" entry: the SkillBook spec supplies the archetype and
## its numbers; each archetype composes existing primitives (damage/resistance/
## dodge via _strike_round, Forced Actions, Exposed/Shock) rather than duplicating
## them. Unknown keys fall through the `strike` fallback so they still resolve.
func _resolve_skill(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
	match String(spec.get("archetype", "strike")):
		"committed_strike":
			return _resolve_committed_strike(actor, entry, snapshot, forced_queue, spec)
		"self_guard":
			return _resolve_self_guard(actor, action, spec)
		"setup_debuff":
			return _resolve_setup_debuff(actor, action, spec)
		"conditional_followup":
			return _resolve_conditional_followup(actor, entry, snapshot, forced_queue, spec)
		"self_stance":
			return _resolve_self_stance(actor, action, spec)
		_:
			return _strike_via_spec(actor, entry, snapshot, forced_queue, spec)


## Injects the spec's typed damage/reach into the action, then runs the SAME
## strike path attacks use (windup re-check, Forced Actions, resistance, dodge,
## RPM, breach). For known skills the spec is the damage authority; the generic
## fallback honours a caller-supplied damage before its own placeholder.
func _strike_via_spec(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = (entry["action"] as Dictionary).duplicate(true)
	if spec.has("damage_type") and (SkillBook.is_known(String(action.get("key", ""))) or not action.has("damage")):
		action["damage"] = {"type": String(spec["damage_type"]), "amount": int(spec.get("amount", 1))}
	if spec.has("attack_range") and not action.has("attack_range"):
		action["attack_range"] = int(spec["attack_range"])
	var synth_entry: Dictionary = {"actor": actor.id, "action": action, "window": entry["window"]}
	return _resolve_strike(actor, synth_entry, snapshot, forced_queue)


## committed_strike (strong_strike, overhead_slam): a windup single strike. The
## Exposed rider is set at declare; here overhead_slam's knockdown lands Prone on
## any standing target that actually took the hit. R15 note: in a MERGED group
## the one damage_applied is emitted by the group's closing member, so a
## non-closing overhead_slam member's knockdown does not fire — the demo combo
## (strong_strike, knockdown=false) is unaffected; revisit if a knockdown skill
## joins a combo.
func _resolve_committed_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if bool(spec.get("knockdown", false)):
		var action: Dictionary = entry["action"]
		for target_entry: Variant in action.get("targets", []) as Array:
			var t: Dictionary = target_entry
			var target: CombatantState = combatants.get(String(t.get("id", "")))
			if target == null or not target.alive:
				continue
			if not _hit_landed(events, target.id):
				continue
			if bool(target.statuses.get("prone", false)):
				continue
			target.statuses["prone"] = true
			events.append({
				"type": "knocked_prone", "combatant": target.id,
				"source": actor.id, "skill": String(action.get("key", "")),
			})
			# Knocked Prone ends the dance stance (a trigger distinct from "hit").
			events.append_array(_end_dance(target, "knocked_prone"))
	return events


## self_guard (brace): no target, no damage. Buffers the next Crush/Burn hit.
func _resolve_self_guard(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	actor.brace_guard = int(spec.get("guard_amount", 1))
	return [
		{"type": "brace_set", "combatant": actor.id, "amount": actor.brace_guard},
		{"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "brace")), "result": "ok", "rounds": 0},
	]


## setup_debuff (feint): no damage. Flags the target so its next resolved action
## collapses into a Forced Action – Tool; the actor repositions up to 1 free.
func _resolve_setup_debuff(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = _first_target(action)
	events.append_array(_free_reposition(actor, action, int(spec.get("reposition", 1)), "feint_reposition"))
	if target != null and target.alive:
		target.feint_forced = true
		events.append({"type": "feint_applied", "actor": actor.id, "target": target.id})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "feint")), "result": "ok", "rounds": 0})
	return events


## conditional_followup (pressure_strike): a Bleed strike; if the target is still
## under Feint's pending consequence it also takes Shock T1. Actor moves up to 2 free.
func _resolve_conditional_followup(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	# Which targets are still feint-forced at resolution (captured before the strike;
	# the strike itself never clears a target's feint flag). Value = the struck part,
	# so the bonus Shock lands per-organ (R13): repeated abuse of the same wound elevates.
	var feinted: Dictionary = {}
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var tgt: CombatantState = combatants.get(String(t.get("id", "")))
		if tgt != null and tgt.feint_forced:
			feinted[tgt.id] = String(t.get("part", ""))
	var events: Array[Dictionary] = _free_reposition(actor, action, int(spec.get("reposition", 2)), "pressure_reposition")
	events.append_array(_strike_via_spec(actor, entry, snapshot, forced_queue, spec))
	var bonus_tier: int = int(spec.get("bonus_shock_tier", 1))
	for tid: Variant in feinted:
		var tgt: CombatantState = combatants.get(String(tid))
		if tgt == null or not tgt.alive:
			continue
		events.append({"type": "pressure_bonus_shock", "actor": actor.id, "target": tgt.id, "tier": bonus_tier})
		events.append_array(cond.apply_shock(tgt, bonus_tier, clock.tick, String(feinted[tid])))
	return events


## self_stance (dance): no target, no damage. Enters the dance stance (+Charm).
func _resolve_self_stance(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	actor.dancing = true
	actor.dance_charm = int(spec.get("charm_bonus", 1))
	# TODO: wire dance_charm_bonus() into the camera-call / hype Charm read
	# (CombatSim._camera_call → derived_stats camera_call_stacks, and HypeEngine's
	# spectacle scoring) — both live outside this story's file set, so the accessor
	# + lifecycle are shipped here and the consumer wiring is deferred.
	return [
		{"type": "dance_started", "combatant": actor.id, "charm_bonus": actor.dance_charm},
		{"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "dance")), "result": "ok", "rounds": 0},
	]


## The feinted actor's next scheduled action collapses: it is invalidated and
## replaced by a Forced Action – Tool (rolled, emitted, queued), exactly like an
## invalidated windup. Clears the flag so only the NEXT action is affected.
func _collapse_feinted_action(actor: CombatantState, kind: String, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	actor.feint_forced = false
	var events: Array[Dictionary] = [{
		"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": "feinted",
	}]
	var collapse: Dictionary = ForcedAction.roll(ForcedAction.TABLE_TOOL, rng)
	events.append(ForcedAction.make_event(actor.id, collapse, "feinted"))
	forced_queue.append({"actor": actor.id, "rolled": collapse, "ctx": {"part": actor.acting_part(clock.tick)}})
	return events


## First target combatant of an action (or null when there is none).
func _first_target(action: Dictionary) -> CombatantState:
	var targets: Array = action.get("targets", [])
	if targets.is_empty():
		return null
	return combatants.get(String((targets[0] as Dictionary).get("id", "")))


## Free reposition (no Moment cost) up to `max_spaces`. Honours an explicit
## `reposition_to` when the caller supplies one; otherwise emits the reposition
## event without auto-pathing (deterministic hex pathing toward the target is the
## content-pass follow-up — see TODO). Never repositions while grappled.
func _free_reposition(actor: CombatantState, action: Dictionary, max_spaces: int, event_type: String) -> Array[Dictionary]:
	if action.has("reposition_to") and actor.grappled_by == "" and actor.grappling == "":
		var rt: Array = action["reposition_to"]
		var to := Vector2i(int(rt[0]), int(rt[1]))
		var dist: int = CombatantState.hex_distance(actor.position, to)
		if dist >= 1 and dist <= max_spaces:
			actor.position = to
			return [{"type": event_type, "actor": actor.id, "to": [to.x, to.y], "spaces": dist, "free": true}]
	# TODO: deterministic free step toward/around the target when no reposition_to
	# is supplied; for now the reposition is surfaced but the actor holds position.
	return [{"type": event_type, "actor": actor.id, "moved": false, "max_spaces": max_spaces}]


## Did a strike land a hit on this combatant (a damage_applied event for it)? A
## dodge / block / whiff produces no damage_applied, so knockdown/riders skip it.
static func _hit_landed(events: Array[Dictionary], target_id: String) -> bool:
	for event: Dictionary in events:
		if String(event.get("type", "")) == "damage_applied" and String(event.get("combatant", "")) == target_id:
			return true
	return false


## Ends the dance stance (self_stance) and emits dance_ended; no-op when not dancing.
static func _end_dance(c: CombatantState, reason: String) -> Array[Dictionary]:
	if not c.dancing:
		return []
	c.dancing = false
	c.dance_charm = 0
	return [{"type": "dance_ended", "combatant": c.id, "reason": reason}]


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
	var combo_provides: Dictionary = action.get("combo_provides", {})
	var unmet: bool = _requirements_unmet(actor, requirements, combo_provides)
	# R15 spectacle: surface the moment a combo assist covers a partner's shortfall.
	if not unmet and not combo_provides.is_empty() and _requirements_unmet(actor, requirements):
		events.append({"type": "combo_assist_applied", "actor": actor.id, "combo_id": String(action.get("combo_id", ""))})
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

	# Self-heal payload (enemy abilities like Seal Wound, I-16): applied at
	# resolution — a multi-Moment heal is interruptible like any windup — to
	# the actor's most-damaged part at that time. Halved when requirements
	# were unmet (R10); negated by Whiff like every other effect.
	var heal: Dictionary = action.get("heal", {})
	if not heal.is_empty() and not whiffed:
		var heal_amount: int = maxi(0, int(heal.get("amount", 0)))
		if unmet:
			heal_amount = floori(heal_amount / 2.0)
		var heal_part: String = _most_damaged_part(actor)
		if heal_part != "" and heal_amount > 0:
			events.append_array(cond.heal_part(actor, heal_part, heal_amount))

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
		# R14: `actor` is the attacker — its Physique feeds Force.
		events.append_array(_strike_round(target, String(t.get("part", "")), condition_id, amount, action, actor))
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


## Deterministic self-heal location: the not-destroyed part with the largest
## HP deficit (tie: first in sorted key order). "" when nothing is wounded.
static func _most_damaged_part(c: CombatantState) -> String:
	var best: String = ""
	var best_deficit: int = 0
	var keys: Array = c.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		var part: Dictionary = c.parts[key]
		if bool(part.get("destroyed", false)):
			continue
		var deficit: int = c.max_hp(key) - int(part.get("hp", 0))
		if deficit > best_deficit:
			best = key
			best_deficit = deficit
	return best


## R10 requirements gate. R15: a combined action's assists may `provides` stats
## (a brace supplies "steady ground", a boost supplies the height for a jump
## attack) that satisfy a partner's otherwise-unmet requirement — teamwork's
## primary power is unlocking, not just adding numbers.
func _requirements_unmet(actor: CombatantState, requirements: Dictionary, provides: Dictionary = {}) -> bool:
	for stat_key: String in STAT_REQUIREMENT_KEYS:
		if requirements.has(stat_key):
			var need: int = int(requirements[stat_key])
			if actor.trait_total(stat_key) < need and int(provides.get(stat_key, 0)) < need:
				return true
	if requirements.has("hands"):
		var need_hands: int = int(requirements["hands"])
		if actor.usable_hands(clock.tick) < need_hands and int(provides.get("hands", 0)) < need_hands:
			return true
	return false


## One round of typed damage + condition delivery with boss hooks (R6).
## R14 (rules-addendum R14, decision-log #22): the force-vs-robustness gate IS the
## damage — `damage = max(0, Force − Robustness)` on the Physical path. `attacker`
## may be null (environment / no source), in which case its Physique Force
## contribution is 0 (Force = amount).
func _strike_round(target: CombatantState, part_key: String, condition_id: String, amount: int, action: Dictionary, attacker: CombatantState = null) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not target.parts.has(part_key):
		return events
	# R15 merged force: is this strike a member of a same-tick merged group?
	# ({} on the solo path — the overwhelming default — and outside resolve_due.)
	var group: Dictionary = _merge_group_for(action, target, part_key)
	var cond_def: Dictionary = cond.def_for(condition_id)
	var is_physical: bool = String(cond_def.get("resistance_type", "")) == "Physical"
	# Boss hook: fire heals (Incinedile) — Burn damage restores the part. EXCEPT a
	# `fire_harms` part (the mycelium network): fire HARMS it like the fungus it is
	# (owner ruling 2026-07-20), so it takes the burn damage + condition normally.
	if condition_id == "burn" and Resistance.fire_heals(target) \
			and not bool(target.parts.get(part_key, {}).get("fire_harms", false)):
		var part: Dictionary = target.parts[part_key]
		part["hp"] = mini(target.max_hp(part_key), int(part["hp"]) + amount)
		events.append({"type": "healed", "combatant": target.id, "part": part_key, "amount": amount, "source": "fire_heals"})
		if not group.is_empty():
			events.append_array(_merge_drop(group, target))  # a healed member adds no Force
		return events
	# R22 dodge — one check, both directions (SUPERSEDES the flat d6 of R11 #17):
	# the threshold asks the DODGER's Reflexes; Reflexes >= threshold auto-dodges
	# (no rng), else the stat's threshold die (default 1d4) rolls off the salted
	# ai_rng; an impossible dodge (Reflexes + die max < threshold) consumes
	# nothing and emits nothing. Boss direction: boss_traits.dodge_threshold.
	# Dash direction: the ability's authored "dodge" block against a non-boss
	# dodger — a successful dash dodge also rides the counters ladder (sidestep;
	# counterattack at counter_at). Never fires while the dodger is Exposed/
	# Helpless/Prone (punish windows); every ROLLED attempt is emitted (no
	# unlogged randomness). A counter strike (action.counter) is itself the
	# dodge's rider and cannot be dodged in v1 (deterministic, rng-free). R15:
	# EACH merged member runs its own dodge here, at the same point in the AI
	# stream as un-merged play; a dodged member's Force drops out of the merged
	# sum.
	if not bool(action.get("counter", false)):
		var boss_threshold: int = int(target.boss_traits.get("dodge_threshold", 0))
		var ability_dodge: Dictionary = action.get("dodge", {})
		var dodge: Dictionary = {}
		var is_dash_dodge: bool = false
		if boss_threshold > 0:
			dodge = ai.try_dodge(target, clock.tick)
		elif not ability_dodge.is_empty():
			dodge = ai.check_dodge(target, clock.tick, int(ability_dodge.get("threshold", 0)))
			is_dash_dodge = true
		if not dodge.is_empty():
			var dodge_detail: Dictionary = {
				"roll": int(dodge.get("roll", 0)), "die": int(dodge.get("die", 0)),
				"reflexes": int(dodge.get("reflexes", 0)),
				"threshold": int(dodge.get("threshold", 0)), "auto": bool(dodge.get("auto", false)),
			}
			if bool(dodge.get("dodged", false)):
				var dodged_event: Dictionary = {"type": "attack_dodged", "combatant": target.id, "part": part_key}
				dodged_event.merge(dodge_detail)
				events.append(dodged_event)
				if is_dash_dodge:
					events.append_array(_dash_dodge_riders(target, attacker, ability_dodge))
				if not group.is_empty():
					events.append_array(_merge_drop(group, target))
				return events
			var failed_event: Dictionary = {"type": "dodge_failed", "combatant": target.id}
			failed_event.merge(dodge_detail)
			events.append(failed_event)
	if Resistance.part_blocked_by_surface_immunity(target, part_key):
		events.append({"type": "attack_blocked", "combatant": target.id, "part": part_key, "reason": "surface_immunity"})
		if not group.is_empty():
			events.append_array(_merge_drop(group, target))
		return events
	# R14 (rules-addendum R14, decision-log #22): the force-vs-robustness gate IS
	# the damage on the Physical path. Force = the weapon/skill force + the
	# attacker's Physique push; Robustness = the target's Physique-derived base +
	# per-part armor + flat physical resistance. A hit LANDS (opens a real wound)
	# only when Force > Robustness. This equals max(0, (amount − flat_res) +
	# floor(atk_phys/2) − floor(tgt_phys/2) − part_armor), so for equal physique +
	# no armor it reduces to the old (amount − flat resistance) model.
	var atk_physique: int = attacker.trait_total("physique") if attacker != null else 0
	var force: int = amount + floori(atk_physique / 2.0)
	# R15 (rules-addendum R15; the R14 TODO, now closed): a linked Physical strike
	# CONTRIBUTES its Force to the group instead of resolving alone — the group's
	# last accounted-for member applies the ONE merged gate + merged net hit (see
	# _merge_apply). A non-Physical member is not force-gated (R14) and falls back
	# to the solo path below, its Force leaving the merged sum.
	if not group.is_empty():
		if is_physical:
			events.append_array(_merge_connect(group, target, condition_id, force, action, attacker))
			return events
		events.append_array(_merge_drop(group, target))
	var part_armor: int = int((target.parts[part_key] as Dictionary).get("armor", 0))
	var flat_res: int = Resistance.flat_physical_reduction(target, condition_id)
	var robustness: int = floori(target.trait_total("physique") / 2.0) + part_armor + flat_res
	var landed: bool = force > robustness
	# The force-vs-robustness model governs the PHYSICAL HP number; Affliction/
	# Psychic keep today's reduce_damage (flat/tier-immunity handled elsewhere) and
	# are NOT force-gated.
	var reduced: int
	if is_physical:
		reduced = maxi(0, force - robustness)
	else:
		reduced = Resistance.reduce_damage(amount, target, cond_def, condition_id)
	# self_guard (brace): the buffered next Crush/Burn hit is reduced by the guard
	# (floor 0), AFTER normal resistance, then the guard is consumed regardless of
	# whether damage remained. Only Crush/Burn consume it; other types pass through.
	if target.brace_guard > 0 and (condition_id == "crushed" or condition_id == "burn"):
		var before_guard: int = reduced
		reduced = maxi(0, reduced - target.brace_guard)
		events.append({
			"type": "brace_absorbed", "combatant": target.id, "part": part_key,
			"guard": target.brace_guard, "condition": condition_id,
			"damage_before": before_guard, "damage_after": reduced,
		})
		target.brace_guard = 0
	events.append_array(cond.damage_part(target, part_key, reduced, "weapon", condition_id, clock.tick))
	# self_stance (dance): the stance ends when its owner is hit (takes damage).
	if target.dancing and reduced > 0:
		events.append_array(_end_dance(target, "hit"))
	# R15/NQ2: record the landed hit for single-hit breach; a combined action's
	# linked strikes (shared combo_id) merge into one hit for the threshold.
	target.record_hit(String(action.get("combo_id", "")), reduced)
	# R14 D3 (decision-log #22): a DAMAGING condition (bleeding/burn/poison + any
	# Physical-typed condition) seeds a wound only when the hit LANDED
	# (Force > Robustness). A hit blocked to 0 by robustness opens no wound, so
	# bleed/burn/poison do NOT land — Shock (applied elsewhere) still may. A landed
	# condition applies at its tier regardless of the exact HP number, so tier
	# immunity (not flat reduction) is what blocks it (R6). Non-damaging conditions
	# (suffocation/chilled/infected/exhausted/dissolution) keep today's behavior.
	if target.alive and condition_id != "":
		if _condition_needs_wound(condition_id, cond_def) and not landed:
			events.append({
				"type": "attack_no_wound", "combatant": target.id, "part": part_key,
				"condition": condition_id, "force": force, "robustness": robustness,
			})
		else:
			events.append_array(cond.apply(target, part_key, condition_id, clock.tick, {
				"source": "attack",
				"injection": bool(action.get("injection", false)),
				"poison_type": String(action.get("poison_type", "")),
			}))
	return events


## R22 dash counters ladder riders on a SUCCESSFUL dash dodge: the sidestep
## rides ANY successful dodge (auto or rolled); the counterattack rides only a
## Reflexes >= counter_at auto-dodge. Both deterministic, both rng-free.
func _dash_dodge_riders(dodger: CombatantState, dasher: CombatantState, ability_dodge: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if dasher == null:
		return events
	events.append_array(_dash_sidestep(dodger, dasher))
	var counter_at: int = int(ability_dodge.get("counter_at", 0))
	if counter_at > 0 and dodger.trait_total("reflexes") >= counter_at:
		events.append_array(_dash_counter(dodger, dasher))
	return events


## R22 1-hex sidestep: the first unoccupied hex in the fixed HEX_NEIGHBORS order
## that strictly INCREASES distance from the dasher. No free improving hex ->
## the dodge still negates, no displacement.
func _dash_sidestep(dodger: CombatantState, dasher: CombatantState) -> Array[Dictionary]:
	var occupied: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == dodger.id or not other.alive or other.removed_from_play:
			continue
		occupied[other.position] = true
	var from: Vector2i = dodger.position
	var from_d: int = CombatantState.hex_distance(from, dasher.position)
	for neighbor: Vector2i in EnemyAI.HEX_NEIGHBORS:
		var candidate: Vector2i = from + neighbor
		if occupied.has(candidate):
			continue
		if CombatantState.hex_distance(candidate, dasher.position) <= from_d:
			continue
		dodger.position = candidate
		return [{
			"type": "dash_sidestepped", "combatant": dodger.id, "by": dasher.id,
			"from": [from.x, from.y], "to": [candidate.x, candidate.y],
		}]
	return []


## R22 counterattack (Reflexes >= counter_at): the dodger lands ONE free basic
## strike back at the dasher's torso-line part — the dodger's first plain
## damage-dealing ability, else the basic unarmed strike (crushed 1, so Force =
## 1 + floor(physique/2)). Resolved through _strike_round (R14 force gate,
## conditions, breach recording all apply) with the counter flag: the counter is
## the dodge's own rider — it cannot be dodged in v1, keeping it rng-free.
func _dash_counter(dodger: CombatantState, dasher: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var part_key: String = ai.torso_line_part(dasher)
	if part_key == "":
		return events  # nothing attackable on the dasher — no counter lands
	var damage: Dictionary = {"type": "crushed", "amount": 1}  # basic unarmed strike
	var ability: Dictionary = ai._first_strike_ability(dodger, [])
	if not ability.is_empty():
		var first: Dictionary = _first_ability_damage(ability)
		damage = {"type": String(first.get("type", "crushed")), "amount": int(first.get("amount", 1))}
	var condition_id := ConditionEngine.normalize_condition_id(String(damage.get("type", "")))
	events.append({
		"type": "dash_countered", "combatant": dodger.id, "target": dasher.id,
		"part": part_key, "damage_type": condition_id, "amount": int(damage.get("amount", 0)),
	})
	events.append_array(_strike_round(dasher, part_key, condition_id, int(damage.get("amount", 0)),
		{"kind": "attack", "key": "dash_counter", "counter": true}, dodger))
	return events


## First damage entry of an ability (the v1 multi-damage deferral, R11 #16).
static func _first_ability_damage(ability: Dictionary) -> Dictionary:
	var damage: Array = ability.get("damage", [])
	if damage.is_empty():
		return {}
	return damage[0]


## R14 D3: damaging conditions that must seed on a real wound (Force > Robustness) —
## bleeding/burn/poison and every Physical-typed condition (crushed). A blocked
## hit (Force ≤ Robustness) opens no wound, so these do not apply.
func _condition_needs_wound(condition_id: String, cond_def: Dictionary) -> bool:
	if condition_id == "bleeding" or condition_id == "burn" or condition_id == "poison":
		return true
	return String(cond_def.get("resistance_type", "")) == "Physical"


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
