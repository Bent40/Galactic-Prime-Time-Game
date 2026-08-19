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

## Content pass batch A: the encoded strike-shaped skill archetypes. They all
## deal damage (the dance-end trigger) and all carry declare-time validation
## (_validate_skill_declare) — the pre-batch archetypes keep their surfaces.
const BATCH_A_STRIKE_ARCHETYPES: Array[String] = [
	"leap_strike", "slip_reposition_strike", "head_finisher", "aoe_cone_strike",
	"downed_finisher", "multi_part_flurry", "adjacent_mob_sweep",
	"crossing_arc_strike", "pow_strike",
]

# Shared context, wired by CombatSim (no back-reference to the sim itself).
var clock: Clock
var combatants: Dictionary = {}
var cond: ConditionEngine
var rng: RandomNumberGenerator
var ai: EnemyAI
## Batch D (play_to_the_camera): the HypeEngine ref, wired by CombatSim via
## wire_hype (both construction paths) — the camera_call STACK resource reads
## the REMAINING stacks (derived total minus the spend ledger) through it, and
## the hype_surge resolver opens the window on it (the _camera_call command
## precedent: commands may drive the broadcast plane; it never reads back).
## Held untyped so the resolver keeps no compile-order dependency; null (an
## unwired unit-test resolver) degrades to the pre-batch derived-total read.
var hype = null
## KAN-5 (wave 3d): the sim's OPT-IN arena, wired by CombatSim at set_arena /
## from_dict (serialized on CombatSim, never here). null = unbounded legacy —
## every arena check in the movement/lane paths below is guarded on it.
var arena: Arena = null

## R15 merged-force groups for the CURRENT resolve_due batch ONLY (never across
## commands — built by _prescan_merge_groups, flushed + cleared before resolve_due
## returns, so serialization stays trivially correct: the field is always empty
## between commands). Key "combo_id|target_id|part" -> group Dictionary.
var _merge_groups: Dictionary = {}
## Tier-2 wave 2 (counterscript — the widened gate's same-tick half). Both
## fields live for the CURRENT resolve_due batch ONLY (the _merge_groups
## transience model — set/cleared inside resolve_due, never across commands,
## never serialized):
##   _due_batch    — the seq-ordered due entries take_due removed from the
##                   Clock queue this tick. A resolving counter scans it for
##                   the read target's STILL-PENDING same-tick entries (seq >
##                   the counter's own — anything with a lower seq already
##                   resolved, and countering after resolution is impossible).
##   _counter_cuts — victim_id -> {"seq": int, "by": String}: a counter that
##                   connected against a same-tick pending entry marks it
##                   here; when that exact entry (seq-matched) reaches its own
##                   slot in the SAME batch, _resolve_entry collapses it into
##                   Forced Action – BODY. The seq match means a later entry
##                   of the same actor is never collateral.
var _due_batch: Array[Dictionary] = []
var _counter_cuts: Dictionary = {}


func setup(clock_ref: Clock, combatants_ref: Dictionary, cond_ref: ConditionEngine, rng_ref: RandomNumberGenerator, ai_ref: EnemyAI) -> void:
	clock = clock_ref
	combatants = combatants_ref
	cond = cond_ref
	rng = rng_ref
	ai = ai_ref


## Batch D: the broadcast-plane ref for the camera-call spend ledger + the
## surge window (see the `hype` field note). Separate from setup so existing
## call sites and resolver-only unit contexts stay untouched.
func wire_hype(hype_ref) -> void:
	hype = hype_ref


static func _reject(reason: String, detail: Dictionary = {}) -> Array[Dictionary]:
	var event: Dictionary = {"type": "command_rejected", "reason": reason}
	event.merge(detail)
	var events: Array[Dictionary] = [event]
	return events


# ----------------------------------------------------- facing (R30, decision #33)

## R30 — face `c` along the from→to ray (the nearest axial direction,
## HexGeometry.direction_index's canonical tie rule). No-op for a zero-length
## ray. The VOLUNTARY-movement half of the update table: resolved moves,
## repositions, leaps, tactical rolls. Involuntary displacement (knockback /
## knock-aside / sidestep / fling / drag) deliberately never calls this.
static func _face_along(c: CombatantState, from: Vector2i, to: Vector2i) -> void:
	var idx: int = HexGeometry.direction_index(from, to)
	if idx >= 0:
		c.facing = idx


## R30 — the targeted-DECLARE half of the update table: face the (first)
## declared target. Reads "targets"[0].id (attack/skill rows) else the single
## "target" String (grapple kinds). Unknown/absent/same-hex targets change
## nothing (the kind validators already gated legality).
func _face_declared_target(actor: CombatantState, action: Dictionary) -> void:
	var target_id: String = ""
	var targets: Array = action.get("targets", [])
	if not targets.is_empty():
		target_id = String((targets[0] as Dictionary).get("id", ""))
	if target_id == "":
		target_id = String(action.get("target", ""))
	var target: CombatantState = combatants.get(target_id)
	if target != null:
		_face_along(actor, actor.position, target.position)


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

	# R20 (KAN-5 wave 4c) — AI honesty for hand-built commands too: aiming at a
	# STEALTHED hostile rejects at declare (the actor's fiction holds no target
	# — EnemyAI._opponents already excludes them; this is the same gate for the
	# player surface). Covers every target-carrying kind: attack/skill
	# ("targets" rows) and the grapple family ("target"). Ally targets are
	# exempt — the party coordinates with its own hidden scout (documented v1
	# reading; friendly fire on a stealthed teammate stays legal, Q69).
	var stealth_gate: Array[Dictionary] = _validate_targets_not_stealthed(actor, action)
	if not stealth_gate.is_empty():
		return stealth_gate

	# R3 priming gate (decision-log #20): "cooldowns do not exist" — a declared
	# action instead gates on its PRIME. Unsatisfied primes reject at declare.
	var prime_reason: String = _prime_unmet(actor, action)
	if prime_reason != "":
		return _reject("prime_unmet", {"actor": actor_id, "prime": prime_reason})

	# G1 Tactical Roll (rules-addendum R25): the declared_dodge archetype spends
	# the actor's MOVEMENT for the Moment — not a Moment, not the free-action
	# slot — and moves IMMEDIATELY at declare. Routed before the R3 slot caps
	# because its economy is the movement allowance, not the action slots.
	# Batch A: the encoded content-pass archetypes carry declare-time skill
	# validation (_validate_skill_declare) — targets, gates, and shape checks a
	# generic skill declare never had. Un-encoded keys (the `strike` fallback)
	# and the pre-batch archetypes keep their exact declare surface.
	if kind == "skill":
		var skill_spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
		if String(skill_spec.get("archetype", "")) == "declared_dodge":
			return _declare_tactical_roll(actor, action, skill_spec)
		# Batch C (acrobatic_save — G1/R25): the forced_roll_save arming shares
		# the tactical roll's economy — its cost is the MOVEMENT allowance, not
		# a Moment or the free slot — so it routes before the R3 slot caps too.
		if String(skill_spec.get("archetype", "")) == "forced_roll_save":
			return _declare_forced_roll_save(actor, action, skill_spec)
		# Tier-2 wave 1 (perfect_evasion — S5): the fused arming is BOTH R25
		# movement-forfeit declares in one — it routes before the slot caps
		# for the same reason its parents do (the economy is the movement
		# allowance, not a Moment or the free slot).
		if String(skill_spec.get("archetype", "")) == "fused_evasion":
			return _declare_fused_evasion(actor, action, skill_spec)
		# Batch D (telekinesis): a voluntary release is FREE and immediate —
		# abandoning a state is not an act (the stealth-reveal precedent), so
		# it touches neither the Moment economy nor the free-action slot.
		if String(skill_spec.get("archetype", "")) == "sustained_channel" \
				and bool(action.get("release", false)):
			if actor.channeling.is_empty():
				return _reject("not_channeling", {"actor": actor.id})
			return release_channel(actor, "released")
		var skill_gate: Array[Dictionary] = _validate_skill_declare(actor, action, skill_spec)
		if not skill_gate.is_empty():
			return skill_gate

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
	# Batch D (telekinesis): the sustain occupies the actor's SCHEDULED action
	# each Moment — committing to any OTHER scheduled action abandons the grip
	# first (free/0-cost actions coexist with the concentration; the movement
	# family rejects "channeling" instead of abandoning, so a grip is never
	# lost to a mis-click step). A sustained_channel declare that got this far
	# IS the sustain (a second grip already rejected already_channeling).
	var pre_events: Array[Dictionary] = []
	if eff_cost > 0 and not actor.channeling.is_empty() \
			and not _is_channel_sustain(kind, action):
		pre_events = release_channel(actor, "abandoned")
	if uses_strained:
		actor.strained_grip = false
	# R30 update table (decision #33): every TARGETED declare faces the (first)
	# target's direction at declare — windups included (face at declare, HOLD
	# through the windup: no re-face at strike resolution, so a committed boss
	# can honestly be flanked mid-windup). Reads "targets"[0] (attack/skill)
	# else the single "target" field (the grapple family). Target-less declares
	# (stand/wait/reload/brace/dance/shockwave's aimed arc) change nothing.
	_face_declared_target(actor, action)
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
	var events: Array[Dictionary] = pre_events
	events.append({
		"type": "action_declared",
		"actor": actor_id,
		"kind": kind,
		"cost": eff_cost,
		"resolve_tick": resolve_tick,
		"windup": window > 0,
	})
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
		if arch == "committed_strike" or arch == "conditional_followup" \
				or arch == "interrupt_counter" or arch == "psychic_strike" \
				or arch == "aoe_blast" \
				or BATCH_A_STRIKE_ARCHETYPES.has(arch):
			return true
		# Tier-2 wave 2 (counterscript): the counter mode is a strike; the
		# read mode is a knowledge play — only the former ends the dance.
		if arch == "fused_counter":
			return String(action.get("mode", "counter")) != "read"
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
##                  + optional "same_target": true (batch A) — the chained
##                  action's first target must equal the actor's
##                  last_action_target (the FINAL default #4 "same target" gate)
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
			if bool(prime.get("same_target", false)):
				var chain_target := ""
				var chain_targets: Array = action.get("targets", [])
				if not chain_targets.is_empty():
					chain_target = String((chain_targets[0] as Dictionary).get("id", ""))
				if chain_target == "" or chain_target != actor.last_action_target:
					return "chain_same_target:%s" % after
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
## `charges` fallback. Batch D: with the hype ref wired the camera-call read
## is the REMAINING stacks — derived total minus the camera_calls_used spend
## ledger (the honest "spend a stack" gate; spotlights and surges spend from
## the same pool). An unwired resolver keeps the pre-batch derived-total read.
func _stack_count(actor: CombatantState, resource: String) -> int:
	if resource == "camera_call":
		var total: int = int(actor.derived_stats().get("camera_call_stacks", 0))
		if hype != null:
			return maxi(0, total - int(hype.camera_calls_used.get(actor.id, 0)))
		return total
	return int(actor.charges.get(resource, 0))


## STATE-POSITION status read: "exposed"/"helpless" use the live caches the rest
## of the resolver reads; "winding_up" (batch B — counter_surge's gate) asks the
## Clock for a pending windup entry (the data row's "currently executing a 2+
## Moment cost action"); everything else is a plain statuses flag.
func _has_status(c: CombatantState, status: String) -> bool:
	if status == "exposed":
		return c.exposed_cache
	if status == "helpless":
		return c.is_helpless(clock.tick)
	if status == "winding_up":
		return clock.has_windup_for(c.id)
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
##                 dodge_outcome: "" | "ineligible" | "auto_dodge" | "roll_needed" | "impossible" | "undodgable",
##                 dodge_roll_needed: int (0 unless roll_needed),
##                 undodgable: bool — R26 (additive): the action's data-driven
##                 undodgable flag; when true the dodge uncertainty collapses
##                 honestly (dodge_possible false, outcome "undodgable"),
##                 target_stealthed: true — R20 (additive, wave 4c): present
##                 ONLY when the target is a stealthed hostile — declaring
##                 this would reject target_stealthed, and the preview says
##                 so instead of projecting an unaskable hit,
##                 read_possible: bool, read_threshold: int,
##                 read_mind: int, read_die: int,
##                 read_outcome: "" | "ineligible" | "auto_read" | "roll_needed" | "impossible",
##                 read_roll_needed: int (0 unless roll_needed)}]
##                The read_* keys are the R24 feint-read UNCERTAINTY (the Mind
##                counter): computed from the SAME fields check_feint_read reads
##                — the spec's read_threshold at the actor's level, the
##                DEFENDER's Mind and mind threshold die — never rolled. A
##                non-feint action (no read_threshold on its spec) carries
##                outcome "" / threshold 0. Stats, never category: any target
##                with a Mind previews honestly.
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
	# R26 (additive): an undodgable action's dodge uncertainty is NOT uncertain
	# — the flag is reported and dodge_possible collapses to false, exactly
	# matching _strike_round's skip (transparency is the rule's other half).
	var undodgable: bool = bool(action.get("undodgable", false))
	var dodge_eligible: bool = threshold > 0 and not undodgable \
		and target.alive and not target.removed_from_play \
		and not target.is_helpless(clock.tick) and not target.exposed_cache \
		and not bool(target.statuses.get("prone", false))
	var dodge_reflexes: int = target.trait_total("reflexes")
	var dodge_die: int = target.threshold_die("reflexes")
	var dodge_outcome: String = ""
	var dodge_roll_needed: int = 0
	if undodgable:
		dodge_outcome = "undodgable"
	elif threshold > 0:
		if not dodge_eligible:
			dodge_outcome = "ineligible"
		elif dodge_reflexes >= threshold:
			dodge_outcome = "auto_dodge"
		elif dodge_reflexes + dodge_die >= threshold:
			dodge_outcome = "roll_needed"
			dodge_roll_needed = threshold - dodge_reflexes
		else:
			dodge_outcome = "impossible"
	# Feint read UNCERTAINTY (R24) — the exact fields + ladder check_feint_read
	# evaluates at resolve (threshold from the SkillBook spec at the actor's
	# level; the DEFENDER's Mind + mind threshold die), NEVER rolled, no rng.
	# Additive keys only; the eligibility gate mirrors check_feint_read's own
	# (threshold > 0, target alive and in play — stats, never category).
	var read_threshold: int = 0
	if String(action.get("kind", "attack")) == "skill":
		read_threshold = int(SkillBook.mechanics(String(action.get("key", "")),
			int(action.get("level", 1))).get("read_threshold", 0))
	var read_eligible: bool = read_threshold > 0 and target.alive and not target.removed_from_play
	var read_mind: int = target.trait_total("mind")
	var read_die: int = target.threshold_die("mind")
	var read_outcome: String = ""
	var read_roll_needed: int = 0
	if read_threshold > 0:
		if not read_eligible:
			read_outcome = "ineligible"
		elif read_mind >= read_threshold:
			read_outcome = "auto_read"
		elif read_mind + read_die >= read_threshold:
			read_outcome = "roll_needed"
			read_roll_needed = read_threshold - read_mind
		else:
			read_outcome = "impossible"
	var row: Dictionary = {
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
		"undodgable": undodgable,
		"read_possible": read_eligible and read_outcome != "impossible",
		"read_threshold": read_threshold,
		"read_mind": read_mind,
		"read_die": read_die,
		"read_outcome": read_outcome,
		"read_roll_needed": read_roll_needed,
	}
	# R20 (ADDITIVE, wave 4c) — preview honesty: aiming at a stealthed HOSTILE
	# would reject at declare (target_stealthed), so the row says so instead of
	# projecting a hit that cannot be asked for. Key present only when true
	# (existing preview consumers keep their exact row shape).
	if target.stealthed and target.team != actor.team:
		row["target_stealthed"] = true
	return row


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


## R20 (wave 4c): [] when no declared target is a stealthed HOSTILE, else the
## target_stealthed rejection. Reads action "targets" rows (attack/skill) and
## the single "target" field (grapple kinds). Unknown ids fall through — the
## kind-specific validators own those rejections.
func _validate_targets_not_stealthed(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		if target != null and target.stealthed and target.team != actor.team:
			return _reject("target_stealthed", {"actor": actor.id, "target": target.id})
	var single: CombatantState = combatants.get(String(action.get("target", "")))
	if single != null and single.stealthed and single.team != actor.team:
		return _reject("target_stealthed", {"actor": actor.id, "target": single.id})
	return []


func _validate_kind(actor: CombatantState, kind: String, action: Dictionary) -> Array[Dictionary]:
	match kind:
		"attack":
			return _validate_attack(actor, action)
		"grapple":
			return _validate_grapple(actor, action)
		"grapple_escape":
			# Tier-2 wave 1 (phantom_grasp — S10-a, OQ1): a psychic HOLD is
			# escapable per R9's escape actions too; a plain telekinesis lift
			# (no grip value on the channel) keeps the legacy rejection.
			if actor.grappled_by == "" and _hold_holder_of(actor) == null:
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
	# Wave 2d — "dash can change direction mid-run" (phase 4+): a BENT charge
	# lane (area_shape carrying a bend point) is phase-gated at the command
	# surface too, so a hand-built bent dash below phase 4 rejects exactly like
	# the AI never deciding one. Phase gating derives from current_phase — no
	# duplicated state.
	var declared_shape: Dictionary = action.get("area_shape", {})
	if String(declared_shape.get("kind", "")) == "line" and declared_shape.has("bend") \
			and not ai.has_upgrade(actor, "dash_bend"):
		return _reject("bend_not_available", {"actor": actor.id})
	# Wave 3d (KAN-5) — the wall-bounce gates, mirroring the bend gate: a lane
	# carrying bounce markers needs an arena (no walls, no bounces) AND the
	# phase-3 "dash bounces between walls up to 2 bounces" upgrade; the marker
	# count is capped at the authored 2. With an arena set, every declared
	# lane hex must be legal ground (walls/bounds are never charged through —
	# bounces reflect BEFORE the wall, so an honest lane never contains one).
	if String(declared_shape.get("kind", "")) == "line":
		var bounce_marks: Array = declared_shape.get("bounces", [])
		if not bounce_marks.is_empty():
			if arena == null or not ai.has_upgrade(actor, "dash_wall_bounce"):
				return _reject("bounce_not_available", {"actor": actor.id})
			if bounce_marks.size() > Arena.MAX_DASH_BOUNCES:
				return _reject("too_many_bounces", {"actor": actor.id, "bounces": bounce_marks.size()})
		if arena != null:
			for lane_hex: Vector2i in _shape_lane(declared_shape):
				if arena.blocks_lane(lane_hex):
					return _reject("lane_blocked", {"actor": actor.id, "hex": [lane_hex.x, lane_hex.y]})
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
		# bypass_head_gate (batch A, the audit's one-line flag): an action whose
		# fiction created its own opening (decapitate via slip_through; the
		# mind_burst content pass later) declares against the Head regardless —
		# a data-driven action flag like R26's undodgable.
		if part_key.contains("head") and not bool(action.get("bypass_head_gate", false)) \
				and not _head_targetable_live(target):
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
	var grip_reason: String = _grip_unmet(actor, "hands")
	if grip_reason != "":
		return _reject(grip_reason, {"actor": actor.id})
	# Wave 2b: a death-spin grab names its grabbing hand (the boss's
	# non-flamethrower hand — EnemyAI.grab_hand_part). A disabled grab hand
	# blocks the grab OUTRIGHT, even when the R9 "any free hand" gate above
	# would pass on the other hand (the flamethrower arm cannot hold a victim).
	# Wave 2d: a death-spin grab's reach is EnemyAI.grab_range — base 1, +1
	# from phase 3 ("death spin grab range +1"); the plain R9 grapple stays 1.
	var reach: int = 1
	var is_death_spin: bool = bool(action.get("death_spin", false))
	if is_death_spin:
		var grab_part := String(action.get("grab_part", ""))
		if grab_part == "" or not actor.part_usable(grab_part, clock.tick):
			return _reject("grab_hand_disabled", {"actor": actor.id, "part": grab_part})
		reach = ai.grab_range(actor)
	# R9: target no more than one size larger.
	if target.size_rank() - actor.size_rank() > 1:
		return _reject("target_too_large", {"actor": actor.id, "target": target.id})
	var distance: int = CombatantState.hex_distance(actor.position, target.position)
	if distance > reach:
		return _reject("out_of_range", {"target": target.id, "range": reach})
	# Wave 2d: a beyond-adjacent grab must DRAG the victim adjacent first —
	# a living body on the pull hex blocks the drag, so the grab cannot land
	# (re-verified live at resolution; this declare gate mirrors it).
	if is_death_spin and distance > 1 \
			and _pull_hex_blocked(actor, target):
		return _reject("pull_blocked", {"actor": actor.id, "target": target.id})
	return []


## The R9 grip gate, PARAMETERIZED (batch B — death_grip_jaws): "" when the
## actor can hold with the named grip, else the rejection reason. "hands" is
## the unchanged R9 free-hand gate (the base grapple kind and pressure_hold);
## "bite" substitutes a usable bite-capable part (data-driven `bite_capable`
## on the part — carried additively by CombatantState.from_spec, only when the
## seed/spec declares it) — this is what unlocks grappling for HANDLESS
## layouts. Tier-2 wave 1 (vice_grip — S7-a, the M8 fusion): "any" accepts
## EITHER anatomy — a usable hand OR a bite-capable part satisfies the gate,
## one skill for every body plan (the grip-neutral ladder; both recipes'
## twin yields this one key). NOTE: the shipped races.json animal TEMPLATE
## keeps arm-keyed forelimbs (they already pass the hands gate) and is
## deliberately unstamped — static_data is hash-covered, so stamping the
## template would move every legacy fight hash (the test_stealth pins); an
## authored handless layout declares the flag on its own part plan.
func _grip_unmet(actor: CombatantState, grip: String) -> String:
	if grip == "bite":
		return "" if actor.bite_part(clock.tick) != "" else "no_bite_part"
	if grip == "any":
		if actor.usable_hands(clock.tick) >= 1 or actor.bite_part(clock.tick) != "":
			return ""
		return "no_grip"
	return "" if actor.usable_hands(clock.tick) >= 1 else "no_free_hand"


## Is the range-2 grab's drag destination (EnemyAI.grab_pull_hex) occupied by
## a living, in-play combatant other than the grabbing pair — or, with an
## arena set (KAN-5), a wall/out-of-bounds/trash-can hex? Live state.
func _pull_hex_blocked(actor: CombatantState, target: CombatantState) -> bool:
	var pull: Vector2i = EnemyAI.grab_pull_hex(actor.position, target.position)
	if arena != null and arena.blocks_movement(pull):
		return true
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or other.id == target.id:
			continue
		if other.alive and not other.removed_from_play and other.position == pull:
			return true
	return false


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
	# Tier-2 wave 1 (vice_grip — S7-d, [FROM row 12, audit reword]): "both
	# grappler hands / a FULL JAW GRIP and a coverable airway" — at Vice Grip
	# L4+ a usable bite-capable part substitutes for the both-hands gate (the
	# grip-neutral ladder's authored substitution; every other holder keeps
	# the unchanged R9 both-hands requirement — death_grip_jaws alone never
	# unlocked suffocation). R9's boss/size caps above stay uncut.
	if actor.usable_hands(clock.tick) < 2 \
			and not (actor.skill_level("vice_grip") >= 4 and actor.bite_part(clock.tick) != ""):
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


# --------------------------------------------- batch-A skill declare gates

## Declare-time validation for the encoded batch-A skill archetypes (content
## pass "Chains & Strikes"). Pre-batch archetypes and un-encoded fallback keys
## return [] untouched — their declare surface is unchanged. Validators may
## NORMALIZE the action in place (rebuild target rows, stamp rpm/area_shape)
## BEFORE declare() stores its deep copy, so the stored command is complete and
## serializes with everything its resolution needs. All reads are LIVE state
## (declares validate live, R2). Runs AFTER the prime gate, so chain rejects
## always surface as prime_unmet first.
func _validate_skill_declare(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	match String(spec.get("archetype", "")):
		"leap_strike":
			return _validate_leap_strike(actor, action, spec)
		"slip_reposition_strike":
			return _validate_slip_reposition_strike(actor, action, spec)
		"head_finisher":
			return _validate_head_finisher(actor, action, spec)
		"aoe_cone_strike":
			return _validate_aoe_cone_strike(actor, action, spec)
		"downed_finisher":
			return _validate_downed_finisher(actor, action, spec)
		"multi_part_flurry":
			return _validate_multi_part_flurry(actor, action, spec)
		"adjacent_mob_sweep":
			return _validate_adjacent_mob_sweep(actor, action, spec)
		"crossing_arc_strike":
			return _validate_crossing_arc_strike(actor, action, spec)
		"pow_strike":
			return _validate_pow_strike(actor, action, spec)
		"retarget_guard":
			return _validate_retarget_guard(actor, action, spec)
		"skill_grapple":
			return _validate_skill_grapple(actor, action, spec)
		"interrupt_counter":
			return _validate_interrupt_counter(actor, action, spec)
		"fused_counter":
			return _validate_fused_counter(actor, action, spec)
		"ally_treatment":
			return _validate_ally_treatment(actor, action, spec)
		"intel_reveal":
			return _validate_intel_reveal(actor, action, spec)
		"psychic_strike":
			return _validate_psychic_strike(actor, action, spec)
		"aoe_blast":
			return _validate_aoe_blast(actor, action, spec)
		"stealth_conceal":
			return _validate_stealth_conceal(actor, action, spec)
		"projection_control":
			return _validate_projection_control(actor, action, spec)
		"hype_surge":
			return _validate_hype_surge(actor, action, spec)
		"sustained_channel":
			return _validate_sustained_channel(actor, action, spec)
		"item_flow":
			return _validate_item_flow(actor, action, spec)
	return []


## Shared batch-A strike gate: the SAME target legality _validate_attack
## enforces for attacks (existence, alive, part, surface immunity, head gate
## incl. bypass_head_gate, reach) with the spec's reach/bypass injected — a
## skill declare must not aim at what an attack could not. reach_override > 0
## replaces the spec reach (the pounce leap's extended envelope).
func _batch_strike_gate(actor: CombatantState, action: Dictionary, spec: Dictionary, reach_override: int = 0) -> Array[Dictionary]:
	var probe: Dictionary = action.duplicate(true)
	if reach_override > 0:
		probe["attack_range"] = reach_override
	elif spec.has("attack_range") and not probe.has("attack_range"):
		probe["attack_range"] = int(spec["attack_range"])
	if bool(spec.get("bypass_head_gate", false)):
		probe["bypass_head_gate"] = true
	return _validate_attack(actor, probe)


## Movement legality for a skill-absorbed step (leap landing / knockback /
## far-side slip): arena bounds/walls/cans + living-body occupancy — the same
## gates move() and the tactical roll enforce. "" = free to enter.
func _movement_blocked_reason(mover: CombatantState, to: Vector2i) -> String:
	if arena != null:
		if not arena.in_bounds(to):
			return "out_of_bounds"
		if arena.is_wall(to) or arena.object_index_at(to) >= 0:
			return "hex_blocked"
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id != mover.id and other.alive and not other.removed_from_play and other.position == to:
			return "hex_occupied"
	return ""


## Batch A: is the combatant "downed" for the execution finisher — Prone OR
## Helpless (the ladder's L1 window; the L9 widening stays threshold data).
func _target_downed(c: CombatantState) -> bool:
	return bool(c.statuses.get("prone", false)) or c.is_helpless(clock.tick)


## leap_strike (pounce) declare gate: single torso row; landing declared as
## `leap_to` (validated within leap_range, adjacent to the target, and through
## the movement gates) — REQUIRED when the actor is not already adjacent
## (explicit command-stream movement; no auto-pathing, matching the
## _free_reposition convention).
func _validate_leap_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	# Batch D (telekinesis): the leap is a movement action — a held body
	# cannot pounce ("Held creatures cannot take movement actions").
	if actor.held_by != "":
		return _reject("held", {"actor": actor.id, "by": actor.held_by})
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var t: Dictionary = targets[0]
	if not String(t.get("part", "")).contains("torso"):
		return _reject("torso_only", {"actor": actor.id, "part": String(t.get("part", ""))})
	var leap_range: int = int(spec.get("leap_range", 3))
	var gate: Array[Dictionary] = _batch_strike_gate(actor, action, spec, leap_range + 1)
	if not gate.is_empty():
		return gate
	var target: CombatantState = combatants.get(String(t.get("id", "")))
	if action.has("leap_to"):
		var lt: Array = action["leap_to"]
		if lt.size() != 2:
			return _reject("invalid_leap_destination", {"actor": actor.id})
		var to := Vector2i(int(lt[0]), int(lt[1]))
		if to != actor.position:
			var spaces: int = CombatantState.hex_distance(actor.position, to)
			if spaces > leap_range:
				return _reject("leap_out_of_range", {"actor": actor.id, "range": leap_range, "spaces": spaces})
			if CombatantState.hex_distance(to, target.position) > 1:
				return _reject("landing_not_adjacent", {"actor": actor.id, "target": target.id})
			var blocked: String = _movement_blocked_reason(actor, to)
			if blocked != "":
				return _reject(blocked, {"actor": actor.id, "to": [to.x, to.y]})
	elif CombatantState.hex_distance(actor.position, target.position) > 1:
		return _reject("leap_required", {"actor": actor.id, "target": target.id})
	return []


## slip_reposition_strike (slip_through) declare gate: adjacency, the size gap
## (G8 rewording — size_rank, at least one size larger; never category), and
## the row REBUILD: the authored effect cuts "each of their legs", so the rows
## become every leg part of the chain target, sorted.
func _validate_slip_reposition_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.is_empty():
		return _reject("target_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target == null or not target.alive:
		return _reject("unknown_target", {"target": String((targets[0] as Dictionary).get("id", ""))})
	if target.size_rank() - actor.size_rank() < 1:
		return _reject("target_not_larger", {"actor": actor.id, "target": target.id})
	var legs: Array = []
	var part_keys: Array = target.parts.keys()
	part_keys.sort()
	for pk: Variant in part_keys:
		if String(pk).contains("leg"):
			legs.append({"id": target.id, "part": String(pk)})
	if legs.is_empty():
		return _reject("no_leg_parts", {"target": target.id})
	action["targets"] = legs
	action["rpm"] = legs.size()
	action["rounds"] = legs.size()
	return _batch_strike_gate(actor, action, spec)


## head_finisher (decapitate) declare gate: single Head row on an EXPOSED
## target that the actor stands BEHIND — the STATE half of the ladder's
## "CHAIN + STATE" gate plus the R30 rear-arc gate (decision #33: the ladder's
## "positioned behind" is REAL now — Stealth.is_behind against the target's
## live facing retires Batch A's interim Exposed-only approximation; the chain
## half already rejected in _prime_unmet). The head gate itself is bypassed
## (bypass_head_gate) — exposure + the rear arc are what keep that honest: no
## free head shots outside the carved opening.
func _validate_head_finisher(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var t: Dictionary = targets[0]
	if not String(t.get("part", "")).contains("head"):
		return _reject("head_only", {"actor": actor.id, "part": String(t.get("part", ""))})
	var target: CombatantState = combatants.get(String(t.get("id", "")))
	if target == null or not target.alive:
		return _reject("unknown_target", {"target": String(t.get("id", ""))})
	if not target.exposed_cache:
		return _reject("target_not_exposed", {"target": target.id})
	if not Stealth.is_behind(target, actor.position):
		return _reject("not_behind_target", {"actor": actor.id, "target": target.id})
	return _batch_strike_gate(actor, action, spec)


## aoe_cone_strike (shockwave) declare gate: a well-formed cone direction
## (area_shape.toward, RELATIVE to the actor — the _recheck_cone_targets
## convention); the stored shape is normalized to kind "cone" at the AUTHORED
## size (a hand-built oversized arc cannot out-range the spec). Membership is
## computed at resolution — the wave targets whoever is really in the arc.
func _validate_aoe_cone_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var shape: Dictionary = action.get("area_shape", {})
	var toward_raw: Array = shape.get("toward", [])
	if toward_raw.size() != 2:
		return _reject("cone_direction_required", {"actor": actor.id})
	var dir := Vector2i(int(toward_raw[0]), int(toward_raw[1]))
	if HexGeometry.direction_index(actor.position, actor.position + dir) < 0:
		return _reject("cone_direction_required", {"actor": actor.id})
	shape["kind"] = "cone"
	shape["size"] = int(spec.get("cone_size", 3))
	action["area_shape"] = shape
	return []


## downed_finisher (execution) declare gate: single Head-or-Torso row on an
## adjacent Prone/Helpless target (re-checked again at resolution — standing
## up mid-windup escapes the finisher). Prone/Helpless imply Exposed, so the
## normal head gate already passes for the Head variant — no bypass flag.
func _validate_downed_finisher(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var t: Dictionary = targets[0]
	var part := String(t.get("part", ""))
	if not (part.contains("head") or part.contains("torso")):
		return _reject("head_or_torso_only", {"actor": actor.id, "part": part})
	var target: CombatantState = combatants.get(String(t.get("id", "")))
	if target == null or not target.alive:
		return _reject("unknown_target", {"target": String(t.get("id", ""))})
	if not _target_downed(target):
		return _reject("target_not_downed", {"target": target.id})
	return _batch_strike_gate(actor, action, spec)


## multi_part_flurry (thousand_cuts) declare gate: exactly parts_required
## DISTINCT part rows, all on the chain target (targets[] carries part rows —
## the multi-part declare shape the audit mapped).
func _validate_multi_part_flurry(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	var need: int = int(spec.get("parts_required", 3))
	if targets.size() != need:
		return _reject("three_parts_required", {"actor": actor.id, "declared": targets.size(), "required": need})
	var first_id := String((targets[0] as Dictionary).get("id", ""))
	var seen: Dictionary = {}
	for row: Variant in targets:
		var t: Dictionary = row
		if String(t.get("id", "")) != first_id:
			return _reject("single_target_required", {"actor": actor.id})
		var part := String(t.get("part", ""))
		if seen.has(part):
			return _reject("distinct_parts_required", {"actor": actor.id, "part": part})
		seen[part] = true
	action["rpm"] = need
	action["rounds"] = need
	return _batch_strike_gate(actor, action, spec)


## adjacent_mob_sweep (controlled_sweep) declare gate. The ">= 2 Mobs adjacent"
## floor is DECLARE VALIDATION by design — not a STATE-prime extension (the
## canonical STATE predicate reads one subject's status; a counted-adjacency
## predicate would widen the R3 prime vocabulary mid-batch — revisit only if a
## second skill needs one). Every declared row must be a distinct, adjacent
## Mob; damage is inherited from the action/item ("a single target attack on
## each"); sweeps never merge (R15) — separate strikes by design.
func _validate_adjacent_mob_sweep(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if String(action.get("combo_id", "")) != "":
		return _reject("sweep_cannot_merge", {"actor": actor.id})
	var adjacent_mobs: int = 0
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or not other.alive or other.removed_from_play:
			continue
		if other.team == actor.team or other.category != "Mob":
			continue
		if CombatantState.hex_distance(actor.position, other.position) <= 1:
			adjacent_mobs += 1
	if adjacent_mobs < 2:
		return _reject("needs_two_adjacent_mobs", {"actor": actor.id, "adjacent_mobs": adjacent_mobs})
	var targets: Array = action.get("targets", [])
	if targets.is_empty():
		return _reject("target_required", {"actor": actor.id})
	var limit: int = int(spec.get("mob_limit", 3))
	if targets.size() > limit:
		return _reject("too_many_targets", {"actor": actor.id, "declared": targets.size(), "limit": limit})
	var seen: Dictionary = {}
	for row: Variant in targets:
		var t: Dictionary = row
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		if target == null:
			return _reject("unknown_target", {"target": String(t.get("id", ""))})
		if seen.has(target.id):
			return _reject("distinct_targets_required", {"target": target.id})
		seen[target.id] = true
		if target.category != "Mob":
			return _reject("target_not_mob", {"target": target.id})
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	if (action.get("damage", {}) as Dictionary).is_empty() and not item.has("damage_type"):
		return _reject("no_damage_source", {"actor": actor.id})
	action["rpm"] = targets.size()
	action["rounds"] = targets.size()
	return _batch_strike_gate(actor, action, spec)


## crossing_arc_strike (slice_n_dice) declare gate: the rows must form one of
## the four G8 modes; the classified mode is stamped onto the action so the
## resolver tunes the per-mode Bleed without re-deriving.
func _validate_crossing_arc_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	var mode: String = _crossing_arc_mode(targets)
	if mode == "":
		return _reject("invalid_arc_shape", {"actor": actor.id})
	action["slice_mode"] = mode
	action["rpm"] = targets.size()
	action["rounds"] = targets.size()
	return _batch_strike_gate(actor, action, spec)


## The G8 mode off the declared rows ("" = not a legal crossing-arc shape):
##   single_limbs — one target, two DISTINCT limb rows
##   single_torso — one target, one torso row
##   pair_limbs   — two targets, one limb row each
##   pair_torsos  — two targets, one torso row each
static func _crossing_arc_mode(targets: Array) -> String:
	if targets.size() == 1:
		return "single_torso" if String((targets[0] as Dictionary).get("part", "")).contains("torso") else ""
	if targets.size() != 2:
		return ""
	var a: Dictionary = targets[0]
	var b: Dictionary = targets[1]
	var a_part := String(a.get("part", ""))
	var b_part := String(b.get("part", ""))
	if String(a.get("id", "")) == String(b.get("id", "")):
		if _is_limb_part(a_part) and _is_limb_part(b_part) and a_part != b_part:
			return "single_limbs"
		return ""
	if _is_limb_part(a_part) and _is_limb_part(b_part):
		return "pair_limbs"
	if a_part.contains("torso") and b_part.contains("torso"):
		return "pair_torsos"
	return ""


## A "limb" for the crossing arc: arms/legs/hands (forepaws read as arms via
## the part plan's keys — the G8 forepaw note is a data concern, not an engine
## vocabulary).
static func _is_limb_part(part_key: String) -> bool:
	return part_key.contains("arm") or part_key.contains("leg") \
		or part_key.contains("hand") or part_key.contains("limb")


## pow_strike (heroic_punch) declare gate: one row through the shared gate —
## notably the UN-bypassed head gate (Exposed/Helpless/Overwhelmed open the
## Head as usual; the Shock rider then asks Exposed specifically at resolve).
func _validate_pow_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	return _batch_strike_gate(actor, action, spec)


# --------------------------------------------- batch-B skill declare gates

## retarget_guard declare gate (batch B). Reaction form (intercept): exactly one
## target row naming a living ALLY (same NON-EMPTY team — teamless combatants
## have no allies to guard, mirroring the _opponents hostility predicate) other
## than the actor, ADJACENT at declare ("declare a guard on one adjacent ally";
## guard_range then governs the interception distance per hit). Stance form
## (iron_stance): no target; declaring while Prone rejects — the stance would
## break the instant it started ("ends the instant you move or fall Prone").
func _validate_retarget_guard(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if String(spec.get("form", "")) == "stance":
		if bool(actor.statuses.get("prone", false)):
			return _reject("prone", {"actor": actor.id})
		return []
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var ally: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if ally == null or not ally.alive or ally.removed_from_play:
		return _reject("unknown_target", {"target": String((targets[0] as Dictionary).get("id", ""))})
	if ally.id == actor.id:
		return _reject("cannot_guard_self", {"actor": actor.id})
	if actor.team == "" or ally.team != actor.team:
		return _reject("target_not_ally", {"actor": actor.id, "target": ally.id})
	if CombatantState.hex_distance(actor.position, ally.position) > 1:
		return _reject("ally_not_adjacent", {"actor": actor.id, "target": ally.id})
	return []


## skill_grapple declare gate (batch B — pressure_hold / death_grip_jaws).
## HOLD mode (default): the R9 grapple gates with the grip PARAMETERIZED
## (spec "grip": "hands" = the unchanged free-hand gate, "bite" = a usable
## bite-capable part — death_grip_jaws' unlock for handless layouts), the R9
## size gate (<= 1 size larger) and the spec reach. DRAG mode (the action
## carries "drag_to" while ALREADY holding the target): the L2+ drag ladder —
## destination within the level's drag distance; the cost is NORMALIZED to 1
## (the data rows' "N spaces per Moment": one Moment moves the pair up to N
## hexes), stamped before declare() stores its deep copy.
func _validate_skill_grapple(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	if action.has("drag_to"):
		if target == null or not target.alive or actor.grappling != target.id:
			return _reject("not_holding_target", {"actor": actor.id})
		var limit: int = int(spec.get("drag", 0))
		if limit <= 0:
			return _reject("drag_not_available", {"actor": actor.id, "level": int(action.get("level", 1))})
		var dt: Array = action["drag_to"]
		if dt.size() != 2:
			return _reject("invalid_drag_destination", {"actor": actor.id})
		var to := Vector2i(int(dt[0]), int(dt[1]))
		var spaces: int = CombatantState.hex_distance(actor.position, to)
		if spaces < 1 or spaces > limit:
			return _reject("drag_out_of_range", {"actor": actor.id, "limit": limit, "spaces": spaces})
		action["cost"] = 1  # normalized: the drag is a 1-Moment action (data rows)
		return []
	if target == null or not target.alive:
		return _reject("invalid_grapple_target", {"actor": actor.id})
	if actor.grappling != "":
		return _reject("already_grappling", {"actor": actor.id})
	var grip_reason: String = _grip_unmet(actor, String(spec.get("grip", "hands")))
	if grip_reason != "":
		return _reject(grip_reason, {"actor": actor.id})
	# R9: target no more than one size larger (the base grapple's gate, kept).
	if target.size_rank() - actor.size_rank() > 1:
		return _reject("target_too_large", {"actor": actor.id, "target": target.id})
	if CombatantState.hex_distance(actor.position, target.position) > int(spec.get("attack_range", 1)):
		return _reject("out_of_range", {"target": target.id, "range": int(spec.get("attack_range", 1))})
	return []


## interrupt_counter declare gate (batch B — counter_surge): one target row
## through the shared strike gate (reach 1, part legality, head gate). The
## mid-windup STATE prime already rejected in _prime_unmet (runs first). The
## strike inherits the action/item damage; with neither supplied the basic
## unarmed strike (crushed 1 — the _dash_counter convention) is stamped at
## declare so the stored command is complete.
func _validate_interrupt_counter(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	if (action.get("damage", {}) as Dictionary).is_empty() and not item.has("damage_type"):
		action["damage"] = {"type": "crushed", "amount": 1}
	return _batch_strike_gate(actor, action, spec)


## fused_counter (counterscript, tier-2 wave 2) declare gate. Mode "read":
## the intel_reveal declared_read gates verbatim (one living ENEMY within
## read_range that the reader SEES — Stealth.sees, the R30 cone included);
## the read-cap replacement policy is a RESOLUTION concern, so a declare at
## the cap is legal. Default mode "counter": one target row through the
## shared strike gate — the target must be YOUR read target (a live
## pattern_reads record; any live read satisfies it — the merged character's
## own reads in practice, documented), and that read IS the whole prime: no
## winding_up STATE gate (the S1-a widening — the read target may have
## nothing scheduled yet; the resolution answers whatever is genuinely
## pending, or reports the miss honestly). The strike inherits action/item
## damage with the counter_surge basic-unarmed default stamped at declare.
func _validate_fused_counter(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var mode := String(action.get("mode", "counter"))
	if mode != "read" and mode != "counter":
		return _reject("unknown_counter_mode", {"actor": actor.id, "mode": mode})
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if mode == "read":
		if target == null or not target.alive or target.removed_from_play:
			return _reject("invalid_read_target", {"actor": actor.id})
		if actor.team == "" or target.team == "" or target.team == actor.team:
			return _reject("target_not_enemy", {"actor": actor.id, "target": target.id})
		var reach: int = int(spec.get("read_range", 3))
		if CombatantState.hex_distance(actor.position, target.position) > reach:
			return _reject("out_of_range", {"target": target.id, "range": reach})
		if not Stealth.sees(actor, target, arena, clock.tick):
			return _reject("target_not_visible", {"actor": actor.id, "target": target.id})
		return []
	if target == null or not actor.pattern_reads.has(target.id):
		return _reject("target_not_read", {"actor": actor.id,
			"target": "" if target == null else target.id})
	var item: Dictionary = actor.items.get(String(action.get("item", "")), {})
	if (action.get("damage", {}) as Dictionary).is_empty() and not item.has("damage_type"):
		action["damage"] = {"type": "crushed", "amount": 1}
	return _batch_strike_gate(actor, action, spec)


## ally_treatment (batch C) declare gate: one target row {id, part} + the
## action's "condition" naming what to treat. Self only where the spec allows
## it (seal_the_wound); otherwise a same-team ALLY within treat_range. The
## condition must be on the spec's treatable list (empty list = any) and
## ACTUALLY ACTIVE on the named part (instance or a live non-bleed_out timer)
## — a treatment never declares against a wound that is not there.
## Tier-2 wave 2 (combat_medic): a spec "ally_consumes" gates ALLY treatment
## on holding the named charge (Triage's economy fused in — self-treatment is
## exempt, Seal's lane had no charge; the reject mirrors the STACK prime's
## vocabulary since it IS that economy, made target-conditional). An action
## {"mode": "resolve"} (S6-d, [FROM row 6]) additionally requires: the spec's
## resolve_conditions list (L4+ — resolve_not_available below it), the named
## condition ON that list, the per-Clock gate open, and the condition NOT
## driving the target's bleed-out — a lethal state is held (delay/stabilize),
## never cured (default #8's boundary, enforced at declare and re-checked
## live at resolution).
func _validate_ally_treatment(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var t: Dictionary = targets[0]
	var target: CombatantState = combatants.get(String(t.get("id", "")))
	if target == null or not target.alive or target.removed_from_play:
		return _reject("invalid_treatment_target", {"actor": actor.id})
	if target.id == actor.id:
		if not bool(spec.get("self_allowed", false)):
			return _reject("cannot_target_self", {"actor": actor.id})
	elif target.team == "" or target.team != actor.team:
		return _reject("target_not_ally", {"actor": actor.id, "target": target.id})
	var ally_consumes := String(spec.get("ally_consumes", ""))
	if ally_consumes != "" and target.id != actor.id \
			and _stack_count(actor, ally_consumes) < 1:
		return _reject("prime_unmet", {"actor": actor.id, "prime": "stack:%s<1" % ally_consumes})
	var reach: int = int(spec.get("treat_range", 1))
	if CombatantState.hex_distance(actor.position, target.position) > reach:
		return _reject("out_of_range", {"target": target.id, "range": reach})
	var condition_id := ConditionEngine.normalize_condition_id(String(action.get("condition", "")))
	var treatable: Array = spec.get("treatable", [])
	if condition_id == "" or (not treatable.is_empty() and not treatable.has(condition_id)):
		return _reject("condition_not_treatable", {"actor": actor.id, "condition": condition_id})
	var mode := String(action.get("mode", "delay"))
	if mode != "delay" and mode != "resolve":
		return _reject("unknown_treat_mode", {"actor": actor.id, "mode": mode})
	if mode == "resolve":
		var resolvable: Array = spec.get("resolve_conditions", [])
		if resolvable.is_empty():
			return _reject("resolve_not_available", {"actor": actor.id, "level": int(action.get("level", 1))})
		if not resolvable.has(condition_id):
			return _reject("condition_not_resolvable", {"actor": actor.id, "condition": condition_id})
		if actor.treat_resolve_used_clock == clock.tick / Clock.TICKS_PER_CLOCK:
			return _reject("resolve_used_this_clock", {"actor": actor.id})
		if String(target.bleed_out.get("condition", "")) == condition_id:
			return _reject("lethal_state_held_not_cured", {"actor": actor.id, "target": target.id})
	var part_key := String(t.get("part", ""))
	if not target.parts.has(part_key):
		return _reject("no_such_part", {"target": target.id, "part": part_key})
	if not _condition_treat_active(target, part_key, condition_id):
		return _reject("condition_not_active", {"target": target.id, "part": part_key, "condition": condition_id})
	return []


## Is the condition live for a treatment: an instance on the named part, or a
## running timer for it (suffocation/dissolution/death timers — never the
## bleed_out grace, which delay() deliberately does not touch: stabilization
## goes through delaying the DRIVING condition instead).
func _condition_treat_active(target: CombatantState, part_key: String, condition_id: String) -> bool:
	if not target.condition_instance(part_key, condition_id).is_empty():
		return true
	for timer: Dictionary in target.timers:
		if String(timer.get("condition", "")) == condition_id and String(timer.get("kind", "")) != "bleed_out":
			return true
	return false


## intel_reveal (batch C) declare gate. The passive form (aura_reading) is
## never declarable — owning it IS the mechanic (the view layer reads the
## grant). The declared form (read_the_pattern) reads one living ENEMY within
## read_range that the reader can SEE — Stealth.sees, so the reader's R30
## facing cone, sight range and LOS all gate the read (an enemy over your
## shoulder cannot be pattern-read).
func _validate_intel_reveal(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if String(spec.get("form", "")) != "declared_read":
		return _reject("passive_skill", {"actor": actor.id, "key": String(action.get("key", ""))})
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target == null or not target.alive or target.removed_from_play:
		return _reject("invalid_read_target", {"actor": actor.id})
	if actor.team == "" or target.team == "" or target.team == actor.team:
		return _reject("target_not_enemy", {"actor": actor.id, "target": target.id})
	var reach: int = int(spec.get("read_range", 3))
	if CombatantState.hex_distance(actor.position, target.position) > reach:
		return _reject("out_of_range", {"target": target.id, "range": reach})
	if not Stealth.sees(actor, target, arena, clock.tick):
		return _reject("target_not_visible", {"actor": actor.id, "target": target.id})
	return []


## psychic_strike (mind_burst, batch C) declare gate: one target row aimed at
## the HEAD (the authored "Single (Head only)"), line of sight (the L8
## out-of-sight rung stays threshold data), then the shared attack-legality
## gate with the spec's range + bypass_head_gate injected (the bypass is the
## point: Exposure never gates this head declare).
func _validate_psychic_strike(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	if not String((targets[0] as Dictionary).get("part", "")).contains("head"):
		return _reject("head_part_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target != null and not Stealth.has_los(arena, actor.position, target.position):
		return _reject("no_line_of_sight", {"actor": actor.id, "target": target.id})
	return _batch_strike_gate(actor, action, spec)


# --------------------------------------------- batch-D skill declare gates

## aoe_blast (poison_ball / frost_ball / fire_ball) declare gate: the declare
## names a target HEX ("at": [q, r]) — not combatant rows (membership is
## resolved over whoever is really in the blast; area geometry is never
## "aimed", so the retarget guard and the stealth target-gate stay out by
## construction). Gates: well-formed hex, within the spec range, inside the
## arena bounds (a detonation in the void is no declare; a wall hex is legal —
## the orb bursts against it), and line of sight from the caster (the thrown
## projectile below the L8 remote-origin rung — the mind_burst precedent;
## re-checked at resolution, a door closing mid-windup breaks it). The spec's
## authored poison_type is stamped onto the action so the condition system's
## soup machinery reads it (fixed below the L6 choose-the-toxin rung — a
## caller-supplied type is overridden, never trusted).
func _validate_aoe_blast(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var at_raw: Array = action.get("at", [])
	if at_raw.size() != 2:
		return _reject("blast_target_required", {"actor": actor.id})
	var at := Vector2i(int(at_raw[0]), int(at_raw[1]))
	var reach: int = int(spec.get("attack_range", 20))
	if CombatantState.hex_distance(actor.position, at) > reach:
		return _reject("out_of_range", {"actor": actor.id, "range": reach, "at": [at.x, at.y]})
	if arena != null and not arena.in_bounds(at):
		return _reject("out_of_bounds", {"actor": actor.id, "at": [at.x, at.y]})
	if not Stealth.has_los(arena, actor.position, at):
		return _reject("no_line_of_sight", {"actor": actor.id, "at": [at.x, at.y]})
	if spec.has("poison_type"):
		action["poison_type"] = String(spec["poison_type"])
	return []


## stealth_conceal (camouflage) declare gate: no target (self). Rejects an
## already-stealthed actor (nothing to conceal twice) and any grapple contact
## (the stealth command's in_grapple rule — being held IS being found).
## Deliberately NO sight gate at declare: entering in a distant watcher's
## sight line is the skill's whole point — the RESOLUTION runs the entry
## check with the shrunk reveal radius already in place.
func _validate_stealth_conceal(actor: CombatantState, _action: Dictionary, _spec: Dictionary) -> Array[Dictionary]:
	if actor.stealthed:
		return _reject("already_stealthed", {"actor": actor.id})
	if actor.grappling != "" or actor.grappled_by != "":
		return _reject("in_grapple", {"actor": actor.id})
	return []


## projection_control (vibe_control) declare gate: a declared mode ("fear" |
## "charm"), one living HOSTILE target row within the spec range, and the
## PERCEPTION gate — the target must currently SEE the actor (Stealth.sees
## with the roles flipped: the TARGET's R30 facing cone, its 2×Mind sight
## range, LOS, and its ability to act all gate the projection — you cannot
## strike a pose at something that cannot perceive you; a Mind-0 creature or
## an enemy you stand behind is immune by blindness, not by will).
func _validate_projection_control(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var mode := String(action.get("mode", ""))
	if mode != "fear" and mode != "charm":
		return _reject("unknown_vibe_mode", {"actor": actor.id, "mode": mode})
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target == null or not target.alive or target.removed_from_play:
		return _reject("unknown_target", {"target": String((targets[0] as Dictionary).get("id", ""))})
	if actor.team == "" or target.team == "" or target.team == actor.team:
		return _reject("target_not_enemy", {"actor": actor.id, "target": target.id})
	var reach: int = int(spec.get("attack_range", 3))
	if CombatantState.hex_distance(actor.position, target.position) > reach:
		return _reject("out_of_range", {"target": target.id, "range": reach})
	if not Stealth.sees(target, actor, arena, clock.tick):
		return _reject("target_cannot_perceive", {"actor": actor.id, "target": target.id})
	return []


## hype_surge (play_to_the_camera) declare gate: no target (the party is the
## target). The STACK prime already gated the remaining Camera-Call stacks
## (_prime_unmet runs first); here: a teamless actor has no party to surge,
## and ONE surge at a time (the spotlight precedent) — a live window rejects
## rather than letting a Moment be spent on a guaranteed fizzle.
func _validate_hype_surge(actor: CombatantState, _action: Dictionary, _spec: Dictionary) -> Array[Dictionary]:
	if actor.team == "":
		return _reject("teamless", {"actor": actor.id})
	if hype != null and not (hype.surge as Dictionary).is_empty():
		return _reject("surge_active", {"actor": actor.id})
	return []


## Batch D (telekinesis): team-agnostic visibility — the R20 sight components
## (front arc + 2×Mind range + LOS) without the hostility predicate, so a
## grip on an ally is as legal as one on an enemy ("Single (object or
## creature)"; the data gates VISIBILITY, not allegiance). Stealthed HOSTILE
## targets are already rejected by the generic stealth gate; a stealthed
## ALLY stays grippable (the party coordinates with its own hidden scout —
## the documented stealth-gate exemption).
func _channel_can_see(actor: CombatantState, target: CombatantState) -> bool:
	if not Stealth.front_arc_contains(actor.position, actor.facing, target.position):
		return false
	if CombatantState.hex_distance(actor.position, target.position) > Stealth.sight_range(actor):
		return false
	return Stealth.has_los(arena, actor.position, target.position)


## sustained_channel (telekinesis) declare gate. GRIP (default): one living
## target row (never self), the actor free of grapples (R9 contact breaks the
## concentration before it starts) and not already channeling (one grip), the
## target not already held by anyone, within grip_range, and VISIBLE
## (_channel_can_see — "Target must be visible"). SUSTAIN ({"sustain": true}):
## the actor must be the live channel's owner; an optional "drag_to" must be
## exactly one hex from the TARGET's position and enterable (walls / bounds /
## cans / bodies — the movement gates; re-checked at resolution, where a
## blocked drag fizzles honestly while the sustain still holds).
func _validate_sustained_channel(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if bool(action.get("sustain", false)):
		if actor.channeling.is_empty():
			return _reject("not_channeling", {"actor": actor.id})
		var held: CombatantState = combatants.get(String(actor.channeling.get("target", "")))
		if held == null or not held.alive or held.removed_from_play:
			return _reject("target_gone", {"actor": actor.id})
		if action.has("drag_to"):
			var dt: Array = action["drag_to"]
			if dt.size() != 2:
				return _reject("invalid_drag_destination", {"actor": actor.id})
			var to := Vector2i(int(dt[0]), int(dt[1]))
			# Tier-2 wave 1 (phantom_grasp — S10-a): the drag limit is the
			# spec's `drag` (telekinesis keeps its authored 1 — behavior
			# unchanged; the phantom hold walks farther, the trained hold
			# replacing raw lifting). Resolution walks the hex line honestly.
			var limit: int = maxi(1, int(spec.get("drag", 1)))
			var spaces: int = CombatantState.hex_distance(held.position, to)
			if spaces < 1 or spaces > limit:
				return _reject("drag_out_of_range", {"actor": actor.id, "to": [to.x, to.y], "limit": limit})
			var blocked: String = _movement_blocked_reason(held, to)
			if blocked != "":
				return _reject(blocked, {"actor": actor.id, "to": [to.x, to.y]})
		return []
	var targets: Array = action.get("targets", [])
	if targets.size() != 1:
		return _reject("single_target_required", {"actor": actor.id})
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target == null or not target.alive or target.removed_from_play:
		return _reject("unknown_target", {"target": String((targets[0] as Dictionary).get("id", ""))})
	if target.id == actor.id:
		return _reject("cannot_target_self", {"actor": actor.id})
	if actor.grappling != "" or actor.grappled_by != "":
		return _reject("grappled", {"actor": actor.id})
	if not actor.channeling.is_empty():
		return _reject("already_channeling", {"actor": actor.id})
	if target.held_by != "":
		return _reject("already_held", {"target": target.id, "by": target.held_by})
	var reach: int = int(spec.get("grip_range", 10))
	if CombatantState.hex_distance(actor.position, target.position) > reach:
		return _reject("out_of_range", {"target": target.id, "range": reach})
	if not _channel_can_see(actor, target):
		return _reject("target_not_visible", {"actor": actor.id, "target": target.id})
	return []


## item_flow (juggling) declare gate: the flow moves ONE item between two
## DISTINCT combatants, the juggler always one end ("from"/"to", defaulting
## to the actor — both-other flows are the L6 mass-flow rung, data). The
## OTHER end must be alive, in play and within pass_range. Item legality:
## the source must actually hold it; the actor's own DROPPED item cannot be
## juggled (it is on the ground — the inventory pickup is that path); a
## HOSTILE source only yields DROPPED items (G8: disarm gated to unwielded/
## dropped; wielded disarm is the L7 payoff, threshold data) and never a
## stealthed one (you cannot snatch from what you cannot see); the
## destination cannot already carry the key (one dict per key — an honest
## reject, not a silent merge).
func _validate_item_flow(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var from_id := String(action.get("from", actor.id))
	var to_id := String(action.get("to", actor.id))
	if from_id == to_id:
		return _reject("flow_needs_two_ends", {"actor": actor.id})
	if from_id != actor.id and to_id != actor.id:
		return _reject("actor_not_in_flow", {"actor": actor.id})
	var other_id: String = from_id if from_id != actor.id else to_id
	var other: CombatantState = combatants.get(other_id)
	if other == null or not other.alive or other.removed_from_play:
		return _reject("unknown_target", {"target": other_id})
	var reach: int = int(spec.get("pass_range", 5))
	if CombatantState.hex_distance(actor.position, other.position) > reach:
		return _reject("out_of_range", {"target": other_id, "range": reach})
	var source: CombatantState = combatants.get(from_id)
	var item_key := String(action.get("item", ""))
	var item: Dictionary = source.items.get(item_key, {})
	if item.is_empty():
		return _reject("no_such_item", {"actor": actor.id, "item": item_key, "holder": from_id})
	if from_id == actor.id and bool(item.get("dropped", false)):
		return _reject("item_dropped", {"actor": actor.id, "item": item_key})
	if from_id != actor.id and other.team != actor.team:
		if other.stealthed:
			return _reject("target_stealthed", {"actor": actor.id, "target": other_id})
		if not bool(item.get("dropped", false)):
			return _reject("item_wielded", {"actor": actor.id, "item": item_key, "holder": from_id})
	var dest: CombatantState = combatants.get(to_id)
	if dest.items.has(item_key):
		return _reject("already_carrying", {"target": to_id, "item": item_key})
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
			# R9: 2 Moments automatic; 1 Moment if Physique >= the holder's
			# CONTEST stat — the grappler's Physique for a mundane grip, the
			# holder's MIND for a psychic hold (tier-2 wave 1, phantom_grasp
			# — OQ1 RULED: escape contest = target Physique vs holder Mind;
			# escape_holder_stat parameterizes the stat by grip type).
			var grappler: CombatantState = combatants.get(actor.grappled_by)
			var quick: bool = false
			if grappler != null:
				quick = actor.trait_total("physique") \
					>= grappler.trait_total(escape_holder_stat("hands"))
			else:
				var holder: CombatantState = _hold_holder_of(actor)
				if holder != null:
					quick = actor.trait_total("physique") \
						>= holder.trait_total(escape_holder_stat(String(holder.channeling.get("grip", ""))))
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
	# Batch D (telekinesis): a held target cannot take movement actions, and a
	# channeling sustainer is rooted — drop the grip first (the free release).
	if actor.held_by != "":
		return _reject("held", {"actor": actor_id, "by": actor.held_by})
	if not actor.channeling.is_empty():
		return _reject("channeling", {"actor": actor_id})
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor_id})
	if actor.moved_this_tick:
		return _reject("already_moved", {"actor": actor_id})  # R3: never twice per tick
	var spaces: int = CombatantState.hex_distance(actor.position, to)
	if spaces <= 0:
		return _reject("no_move", {"actor": actor_id})
	# KAN-5 movement honesty: with an arena set, a move's destination must be
	# inside the bounds and off walls/trash cans (a can blocks its hex like an
	# occupied body until destroyed). Combatant occupancy stays unchecked at
	# move — the pre-arena model, unchanged.
	if arena != null:
		if not arena.in_bounds(to):
			return _reject("out_of_bounds", {"actor": actor_id, "to": [to.x, to.y]})
		if arena.is_wall(to) or arena.object_index_at(to) >= 0:
			return _reject("hex_blocked", {"actor": actor_id, "to": [to.x, to.y]})
	var prone: bool = bool(actor.statuses.get("prone", false))
	var slowed: bool = bool(actor.statuses.get("slowed", false))
	var allowance: int = 1 if (prone or slowed) else 3
	if spaces <= allowance:
		if actor.free_action_used:
			return _reject("free_action_used", {"actor": actor_id})
		actor.free_action_used = true
		actor.moved_this_tick = true
		# R30: a resolved move faces the movement direction — the from→to ray's
		# nearest axial direction (the sim's move is a from→to hop, so the ray
		# IS the last step; documented in the addendum R30 entry).
		_face_along(actor, actor.position, to)
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


# ------------------------------------------------------------------ tactical roll (G1 / R25)

## G1 (owner 2026-07-23; rules-addendum R25): Tactical Roll is a declared-hex
## dodge — "you give up your movement for the Moment and declare the hex you
## roll to; the attack still resolves". Semantics:
##  * COST = exactly the movement allowance (design call, R25): the roll sets
##    moved_this_tick — a free move after a roll rejects "already_moved", a roll
##    after any move this tick rejects "movement_spent". It does NOT touch the
##    free-action slot ("give up your movement", nothing more): The Bit, the
##    first inventory use and 0-cost declares/reactions stay legal the same tick.
##  * The move happens IMMEDIATELY at declare (it is a dodge): windup re-checks
##    at later resolution ticks see the new hex through the R2 tick-start
##    snapshot — the existing cone-arc / dash-lane / plain-range re-checks ARE
##    the single/multi-target half of the G1 refinement, no new seam. Rolling on
##    an attack's own resolution tick dodges nothing (R2 snapshot semantics;
##    instants cost <= 1 are never dodged by movement).
##  * The rolled_this_window marker (set here, cleared at the actor's next tick
##    start) feeds the AoE-center rule: an AREA attack resolving this Moment
##    misses the roller unless the destination is the area's CENTER
##    (EnemyAI.resolve_explosion_blast).
##  * Movement gates mirror move(): no roll while grappled (R9), winding up
##    (R2 commit) or Prone (R3 prone-can-only-crawl + the R22 punish window).
##    Exposed does NOT block the roll — Exposed combatants may still move (R3),
##    and R22's Exposed gate governs the threshold dodge, not movement.
func _declare_tactical_roll(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if actor.grappled_by != "" or actor.grappling != "":
		return _reject("grappled", {"actor": actor.id})
	# Batch D (telekinesis): the roll is movement — held targets and rooted
	# sustainers have none to spend (the move() mirror).
	if actor.held_by != "":
		return _reject("held", {"actor": actor.id, "by": actor.held_by})
	if not actor.channeling.is_empty():
		return _reject("channeling", {"actor": actor.id})
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor.id})
	if bool(actor.statuses.get("prone", false)):
		return _reject("prone", {"actor": actor.id})
	if actor.moved_this_tick:
		return _reject("movement_spent", {"actor": actor.id})
	var to_raw: Array = action.get("to", [])
	if to_raw.size() != 2:
		return _reject("invalid_destination", {"actor": actor.id})
	var to := Vector2i(int(to_raw[0]), int(to_raw[1]))
	var spaces: int = CombatantState.hex_distance(actor.position, to)
	if spaces <= 0:
		return _reject("no_move", {"actor": actor.id})
	var roll_range: int = int(spec.get("roll_range", 2))
	if spaces > roll_range:
		return _reject("roll_out_of_range", {"actor": actor.id, "range": roll_range, "spaces": spaces})
	# KAN-5: a roll destination obeys the arena like any movement — in bounds,
	# off walls and off trash cans (the occupied-hex check below already ran
	# for bodies; walls/cans compose with it).
	if arena != null:
		if not arena.in_bounds(to):
			return _reject("out_of_bounds", {"actor": actor.id, "to": [to.x, to.y]})
		if arena.is_wall(to) or arena.object_index_at(to) >= 0:
			return _reject("hex_blocked", {"actor": actor.id, "to": [to.x, to.y]})
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id != actor.id and other.alive and not other.removed_from_play and other.position == to:
			return _reject("hex_occupied", {"actor": actor.id, "by": other.id})
	# --- all checks passed; mutate ---
	actor.moved_this_tick = true
	actor.rolled_this_window = true
	var from: Vector2i = actor.position
	actor.position = to
	# R30: the roll is VOLUNTARY movement — face the roll direction (yes, a
	# roll away turns your back; the table has no dodge exception, documented).
	_face_along(actor, from, to)
	var events: Array[Dictionary] = [{
		"type": "tactical_roll", "actor": actor.id,
		"from": [from.x, from.y], "to": [to.x, to.y],
		"spaces": spaces, "range": roll_range, "level": int(action.get("level", 1)),
	}]
	return events


## Batch C (acrobatic_save — G1, rules-addendum R25): the forced_roll_save
## ARMING. Same economy as the tactical roll ("Acrobatic Save gets the same
## movement-forfeit cost in place of its cooldown"): the declare consumes the
## actor's MOVEMENT for the Moment (moved_this_tick — a free move after
## arming rejects already_moved; arming after any move rejects
## movement_spent) and touches neither the free-action slot nor the Moment
## economy. NO prime, NO stance (the ladders doc's old prime note is
## superseded — see its 2026-08-18 tail annotation). Arming sets forced_save
## {"dice": N}; the owner's next Forced Action – BODY roll consumes it
## (_forced_body_roll). Nothing is scheduled — the arming IS the resolution.
## Gates mirror the movement family: no arming while grappled (R9), winding
## up (R2 commit) or Prone (the data's own requirement; Helpless is already
## rejected by declare()).
func _declare_forced_roll_save(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	# already_armed FIRST: an armed save makes the declare pointless whatever
	# the movement state — never charge (or confusingly report) movement for it.
	if not actor.forced_save.is_empty():
		return _reject("already_armed", {"actor": actor.id})
	if actor.grappled_by != "" or actor.grappling != "":
		return _reject("grappled", {"actor": actor.id})
	# Batch D (telekinesis): the arming spends movement — held targets and
	# rooted sustainers have none to forfeit (the movement-family mirror).
	if actor.held_by != "":
		return _reject("held", {"actor": actor.id, "by": actor.held_by})
	if not actor.channeling.is_empty():
		return _reject("channeling", {"actor": actor.id})
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor.id})
	if bool(actor.statuses.get("prone", false)):
		return _reject("prone", {"actor": actor.id})
	if actor.moved_this_tick:
		return _reject("movement_spent", {"actor": actor.id})
	# --- all checks passed; mutate ---
	actor.moved_this_tick = true
	actor.forced_save = {"dice": maxi(1, int(spec.get("extra_dice", 1)))}
	return [{
		"type": "acrobatic_save_armed", "actor": actor.id,
		"dice": int(actor.forced_save["dice"]), "level": int(action.get("level", 1)),
	}]


# ------------------------------------- perfect evasion (tier-2 wave 1, S5)

## The fused arming (perfect_evasion — M6, BLESSED 2026-08-18): ONE R25
## movement forfeit arms BOTH parents' defenses — the declared-hex roll
## (moves IMMEDIATELY at declare, rolled_this_window set: the AoE-center rule
## and the R2 snapshot dodge semantics apply exactly as for tactical_roll)
## AND the armed save (forced_save — consumed by the next Forced Action –
## BODY roll through _forced_body_roll; at L4+ the arming carries the S5-d
## negate flag, gated once per Clock by negate_used_clock). Gates are the
## UNION of both parents' declares (they were already identical). At L3+
## the declare records the `evasion` window record so the OQ2 second roll
## can prove distinctness. Zero rng — the arming is pure movement + state.
func _declare_fused_evasion(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	# S5-c (OQ2 RULED "2nd roll 2nd attack"): the second declared-hex roll —
	# a separate shape that never re-charges the forfeit.
	if bool(action.get("second_roll", false)):
		return _declare_evasion_second_roll(actor, action, spec)
	# already_armed FIRST (the acrobatic_save rule): an armed save makes the
	# declare pointless whatever the movement state.
	if not actor.forced_save.is_empty():
		return _reject("already_armed", {"actor": actor.id})
	if actor.grappled_by != "" or actor.grappling != "":
		return _reject("grappled", {"actor": actor.id})
	if actor.held_by != "":
		return _reject("held", {"actor": actor.id, "by": actor.held_by})
	if not actor.channeling.is_empty():
		return _reject("channeling", {"actor": actor.id})
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor.id})
	if bool(actor.statuses.get("prone", false)):
		return _reject("prone", {"actor": actor.id})
	if actor.moved_this_tick:
		return _reject("movement_spent", {"actor": actor.id})
	var roll_range: int = int(spec.get("roll_range", 2))
	var to_reason: String = _evasion_destination_unmet(actor, action, roll_range)
	if to_reason != "":
		return _reject(to_reason, {"actor": actor.id, "range": roll_range})
	var to_raw: Array = action.get("to", [])
	var to := Vector2i(int(to_raw[0]), int(to_raw[1]))
	# --- all checks passed; mutate (ONE forfeit, both armings) ---
	actor.moved_this_tick = true
	actor.rolled_this_window = true
	actor.forced_save = {"dice": maxi(1, int(spec.get("extra_dice", 1)))}
	if bool(spec.get("negate", false)):
		actor.forced_save["negate"] = true
	if bool(spec.get("second_roll", false)):
		actor.evasion = {"answered": _pending_attack_seqs_on(actor), "second_used": false}
	var from: Vector2i = actor.position
	var spaces: int = CombatantState.hex_distance(from, to)
	actor.position = to
	# R30: the roll is VOLUNTARY movement (the tactical_roll rule, unchanged).
	_face_along(actor, from, to)
	return [{
		"type": "perfect_evasion", "actor": actor.id,
		"from": [from.x, from.y], "to": [to.x, to.y], "spaces": spaces,
		"range": roll_range, "dice": int(actor.forced_save["dice"]),
		"negate_armed": bool(actor.forced_save.get("negate", false)),
		"second_roll_available": bool(spec.get("second_roll", false)),
		"level": int(action.get("level", 1)),
	}]


## S5-c per the OQ2 RULING (owner 2026-08-18: "2nd roll 2nd attack"): one
## movement forfeit covers a SECOND declared-hex roll when a second DISTINCT
## attack resolves against the roller in the same window. Mechanized against
## the Clock queue: the declare names the attacker ("against"); its pending
## entry aimed at the roller must exist and must NOT be in the window
## record's answered set (what the first roll already dodged) — a same-attack
## re-roll rejects. The forfeit is never waived and never re-charged:
## moved_this_tick stays spent, no new movement is charged, and the second
## roll is once per window (second_used). Zero rng — pure movement.
func _declare_evasion_second_roll(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	if not bool(spec.get("second_roll", false)):
		return _reject("second_roll_locked", {"actor": actor.id, "level": int(action.get("level", 1))})
	if actor.evasion.is_empty():
		return _reject("no_first_roll", {"actor": actor.id})
	if bool(actor.evasion.get("second_used", false)):
		return _reject("second_roll_used", {"actor": actor.id})
	if actor.grappled_by != "" or actor.grappling != "":
		return _reject("grappled", {"actor": actor.id})
	if actor.held_by != "":
		return _reject("held", {"actor": actor.id, "by": actor.held_by})
	if not actor.channeling.is_empty():
		return _reject("channeling", {"actor": actor.id})
	if actor.windup_pending:
		return _reject("winding_up", {"actor": actor.id})
	if bool(actor.statuses.get("prone", false)):
		return _reject("prone", {"actor": actor.id})
	var against := String(action.get("against", ""))
	if against == "":
		return _reject("against_required", {"actor": actor.id})
	var seq: int = _pending_attack_seq_from(actor, against)
	if seq < 0:
		return _reject("no_second_attack", {"actor": actor.id, "against": against})
	var answered: Array = actor.evasion.get("answered", [])
	if answered.has(seq):
		return _reject("same_attack", {"actor": actor.id, "against": against})
	var roll_range: int = int(spec.get("roll_range", 2))
	var to_reason: String = _evasion_destination_unmet(actor, action, roll_range)
	if to_reason != "":
		return _reject(to_reason, {"actor": actor.id, "range": roll_range})
	var to_raw: Array = action.get("to", [])
	var to := Vector2i(int(to_raw[0]), int(to_raw[1]))
	# --- all checks passed; mutate (no new forfeit — the first one pays) ---
	answered.append(seq)
	actor.evasion["answered"] = answered
	actor.evasion["second_used"] = true
	actor.rolled_this_window = true
	var from: Vector2i = actor.position
	var spaces: int = CombatantState.hex_distance(from, to)
	actor.position = to
	_face_along(actor, from, to)
	return [{
		"type": "perfect_evasion_second_roll", "actor": actor.id,
		"against": against, "from": [from.x, from.y], "to": [to.x, to.y],
		"spaces": spaces, "range": roll_range, "level": int(action.get("level", 1)),
	}]


## Shared destination legality for both evasion rolls — the tactical_roll
## gates verbatim (well-formed hex, real move, within range, arena-legal,
## unoccupied). "" = legal, else the rejection reason.
func _evasion_destination_unmet(actor: CombatantState, action: Dictionary, roll_range: int) -> String:
	var to_raw: Array = action.get("to", [])
	if to_raw.size() != 2:
		return "invalid_destination"
	var to := Vector2i(int(to_raw[0]), int(to_raw[1]))
	var spaces: int = CombatantState.hex_distance(actor.position, to)
	if spaces <= 0:
		return "no_move"
	if spaces > roll_range:
		return "roll_out_of_range"
	if arena != null:
		if not arena.in_bounds(to):
			return "out_of_bounds"
		if arena.is_wall(to) or arena.object_index_at(to) >= 0:
			return "hex_blocked"
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id != actor.id and other.alive and not other.removed_from_play and other.position == to:
			return "hex_occupied"
	return ""


## Every pending Clock-queue entry aimed at `victim` (attack/skill "targets"
## rows or the grapple family's "target"), as a sorted list of entry seqs —
## the attack identities a roll declared NOW is answering. Deterministic
## (seq order), zero mutation.
func _pending_attack_seqs_on(victim: CombatantState) -> Array:
	var seqs: Array = []
	for entry: Dictionary in clock.scheduled_entries():
		if String(entry.get("actor", "")) == victim.id:
			continue
		if _entry_targets(entry.get("action", {})).has(victim.id):
			seqs.append(int(entry.get("seq", -1)))
	return seqs


## The seq of `attacker`'s pending entry aimed at `victim`, -1 when none —
## the OQ2 second roll's "a second distinct attack resolving against you".
func _pending_attack_seq_from(victim: CombatantState, attacker: String) -> int:
	for entry: Dictionary in clock.scheduled_entries():
		if String(entry.get("actor", "")) != attacker:
			continue
		if _entry_targets(entry.get("action", {})).has(victim.id):
			return int(entry.get("seq", -1))
	return -1


## The combatant ids a stored action is aimed at ("targets" rows + the
## grapple family's single "target" field).
func _entry_targets(action: Dictionary) -> Array:
	var out: Array = []
	for t: Variant in action.get("targets", []) as Array:
		out.append(String((t as Dictionary).get("id", "")))
	var single := String(action.get("target", ""))
	if single != "":
		out.append(single)
	return out


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
	# R20 (wave 4c): a damaging reaction cannot aim at a stealthed hostile —
	# same honesty gate as declare, checked BEFORE the slot/readiness mutate.
	var aimed: CombatantState = combatants.get(String(payload.get("target", "")))
	if aimed != null and aimed.stealthed and aimed.team != actor.team:
		return _reject("target_stealthed", {"actor": actor_id, "target": aimed.id})
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
	# Tier-2 wave 2 (counterscript): stash the batch for the widened counter's
	# same-tick pending scan; clear any stale cut marks (both transient —
	# see the field notes).
	_due_batch = due
	_counter_cuts.clear()
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
	_due_batch = []
	_counter_cuts.clear()
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
	# retarget_guard stance (iron_stance, batch B): the merged hit is ONE wound
	# — a covered-type component lets the persistent (NON-consumed) stance
	# reduction apply once, exactly like the brace below. Applied before brace
	# (the solo-path order), while the stance genuinely holds.
	if reduced > 0 and _iron_stance_live(target):
		var stance_types: Array = target.iron_stance.get("types", [])
		var stance_covered: bool = false
		for m: Variant in connected:
			if stance_types.has(String((m as Dictionary)["condition"])):
				stance_covered = true
		var stance_red: int = int(target.iron_stance.get("reduction", 0))
		if stance_covered and stance_red > 0:
			var before_stance: int = reduced
			reduced = maxi(0, reduced - stance_red)
			events.append({
				"type": "iron_stance_reduced", "combatant": target.id, "part": part_key,
				"reduction": stance_red, "condition": String((connected[0] as Dictionary)["condition"]),
				"damage_before": before_stance, "damage_after": reduced,
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
	# intercept L3+ (batch B): the INTERCEPTED merged hit is ONE hit — the
	# per-interception flat reduction applies once (all merged members are
	# Physical by construction, matching the solo path's Physical-only rule).
	if reduced > 0 and int(group.get("intercept_reduction", 0)) > 0:
		reduced = maxi(0, reduced - int(group["intercept_reduction"]))
	# R11 #14 v2: the merged hit is ONE blow; its author is the LAST member whose
	# strike actually CONNECTED (the closing hit of the merged wound — a member
	# who missed never authored it). Single credit, matching the ruling's
	# singular "that killer" and the breach_risk closing-hitter convention.
	events.append_array(cond.damage_part(target, part_key, reduced, "weapon", String((connected[0] as Dictionary)["condition"]), clock.tick,
			String((connected[connected.size() - 1] as Dictionary)["actor"])))
	if target.dancing and reduced > 0:
		events.append_array(_end_dance(target, "hit"))
	# ONE recorded hit for the single-hit breach threshold (R15/NQ2).
	target.record_hit(String(group["combo_id"]), reduced)
	# Wave 2b: the merged hit is ONE hit for "release if hit for 5" too — the
	# party's combined-action seam works on the grab exactly like the breach.
	if reduced > 0:
		events.append_array(ai.check_death_spin_release(target, reduced))
	# R23: each connected member earns grudge for its OWN contribution — the one
	# merged net hit is attributed per member proportionally to the Force it
	# contributed (the same per-member Forces the merged gate was built from).
	if reduced > 0 and sum_force > 0:
		for m: Variant in connected:
			var member: Dictionary = m
			var share: float = float(reduced) * float(int(member["force"])) / float(sum_force)
			events.append_array(EnemyAI.add_antagonism(target, String(member["actor"]), share, "damage"))
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
				"attacker": String(md["actor"]),  # R11 #14 v2: each rider keeps its own author
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
	# Tier-2 wave 2 (counterscript S1-a — the widened gate's same-tick half): a
	# counter that resolved EARLIER this tick (lower seq) marked this actor's
	# still-pending declared action; at its own slot the countered action
	# COLLAPSES into Forced Action – BODY (the parameterized table — the
	# _collapse_batch_windup body path, kind-honest). Seq-matched: only the
	# exact countered entry dies. Checked before the stutter/feint so the
	# counter's collapse wins the slot — the stutter and the feint's pending
	# consequence are both preserved for the actor's NEXT action (the same
	# preservation discipline the stutter grants the feint).
	if _counter_cuts.has(actor.id) \
			and int((_counter_cuts[actor.id] as Dictionary).get("seq", -1)) == int(entry.get("seq", -2)):
		var cut_by := String((_counter_cuts[actor.id] as Dictionary).get("by", ""))
		_counter_cuts.erase(actor.id)
		var countered_targets: Array = action.get("targets", [])
		var countered_original: String = "" if countered_targets.is_empty() \
			else String((countered_targets[0] as Dictionary).get("id", ""))
		var countered_events: Array[Dictionary] = [{"type": "action_invalidated",
			"actor": actor.id, "kind": kind, "reason": "countered", "by": cut_by}]
		var countered_body: Dictionary = _forced_body_roll(actor, "countered")
		countered_events.append_array(countered_body["events"])
		# S5-d composition: a NEGATED Body roll queues no consequence — the
		# countered action still died (the same rule the windup collapse follows).
		if not bool(countered_body.get("negated", false)):
			forced_queue.append({"actor": actor.id, "rolled": countered_body["rolled"], "ctx": {
				"part": actor.acting_part(clock.tick), "target": countered_original,
			}})
		return countered_events
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
		return _collapse_feinted_action(actor, kind, String(action.get("key", String(action.get("item", "")))), forced_queue)
	var events: Array[Dictionary] = []
	match kind:
		"attack":
			events = _resolve_strike(actor, entry, snapshot, forced_queue)
		"skill":
			events = _resolve_skill(actor, entry, snapshot, forced_queue)
		"move":
			var to: Array = action.get("to", [actor.position.x, actor.position.y])
			var move_to := Vector2i(int(to[0]), int(to[1]))
			# R30: a resolved (scheduled) move faces the movement direction.
			_face_along(actor, actor.position, move_to)
			actor.position = move_to
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
			# Skill-feel pass: an attributed stood_up event alongside the generic
			# action_resolved, so the HUD can announce that getting back up cost
			# the combatant its action for the Moment (the cost is the declare's).
			events.append({"type": "stood_up", "combatant": actor.id,
				"cost": int(action.get("eff_cost", 1))})
			events.append({"type": "action_resolved", "actor": actor.id, "kind": "stand", "result": "ok"})
		_:
			events.append({"type": "action_resolved", "actor": actor.id, "kind": kind, "result": "ok"})
	# R3 priming bookkeeping (decision-log #20). Record the CHAIN key: this
	# action's identity becomes the actor's last_action_key (a different action's
	# key overwrites it, so a non-matching action "clears" a pending chain). A
	# PREP-CHANNEL prime is CONSUMED here — using the armed action spends it.
	# Batch A: the first target id is recorded alongside for the CHAIN
	# same-target gate ("" for target-less actions — which therefore also clear
	# a pending same-target chain, mirroring the key rule).
	actor.last_action_key = String(action.get("key", String(action.get("item", ""))))
	var resolved_targets: Array = action.get("targets", [])
	actor.last_action_target = "" if resolved_targets.is_empty() \
		else String((resolved_targets[0] as Dictionary).get("id", ""))
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
		"leap_strike":
			return _resolve_leap_strike(actor, entry, snapshot, forced_queue, spec)
		"slip_reposition_strike":
			return _resolve_slip_reposition_strike(actor, entry, snapshot, forced_queue, spec)
		"head_finisher":
			return _resolve_head_finisher(actor, entry, snapshot, forced_queue, spec)
		"aoe_cone_strike":
			return _resolve_aoe_cone_strike(actor, entry, snapshot, forced_queue, spec)
		"downed_finisher":
			return _resolve_downed_finisher(actor, entry, snapshot, forced_queue, spec)
		"multi_part_flurry":
			return _resolve_multi_part_flurry(actor, entry, snapshot, forced_queue, spec)
		"adjacent_mob_sweep":
			return _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
		"crossing_arc_strike":
			return _resolve_crossing_arc_strike(actor, entry, snapshot, forced_queue, spec)
		"pow_strike":
			return _resolve_pow_strike(actor, entry, snapshot, forced_queue, spec)
		"retarget_guard":
			return _resolve_retarget_guard(actor, action, spec)
		"skill_grapple":
			return _resolve_skill_grapple(actor, entry, snapshot, forced_queue, spec)
		"interrupt_counter":
			return _resolve_interrupt_counter(actor, entry, snapshot, forced_queue, spec)
		"fused_counter":
			return _resolve_fused_counter(actor, entry, snapshot, forced_queue, spec)
		"ally_treatment":
			return _resolve_ally_treatment(actor, entry, spec)
		"intel_reveal":
			return _resolve_intel_reveal(actor, entry, spec)
		"psychic_strike":
			return _resolve_psychic_strike(actor, entry, snapshot, forced_queue, spec)
		"aoe_blast":
			return _resolve_aoe_blast(actor, entry, snapshot, forced_queue, spec)
		"stealth_conceal":
			return _resolve_stealth_conceal(actor, entry, forced_queue, spec)
		"projection_control":
			return _resolve_projection_control(actor, entry, spec)
		"hype_surge":
			return _resolve_hype_surge(actor, entry, spec)
		"sustained_channel":
			return _resolve_sustained_channel(actor, entry, spec)
		"item_flow":
			return _resolve_item_flow(actor, entry, spec)
		"forced_roll_save", "fused_evasion":
			# Unreachable via declare (both armings route before scheduling);
			# defensive so a hand-built entry can never fall into the strike path.
			return [{"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "not_schedulable"}]
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
	# Batch A: a spec-carried head-gate bypass (decapitate) rides the action so
	# the windup/cone re-checks honor it exactly like the declare gate did.
	if bool(spec.get("bypass_head_gate", false)):
		action["bypass_head_gate"] = true
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
## R24: the spec's read_threshold first asks the DEFENDER's Mind through the R22
## threshold machinery (EnemyAI.check_feint_read). A READ feint is WASTED —
## nothing arms on the reader, the feinter's Moment is spent normally (the
## action resolves as a read, not a rejection) — and the reader adds mock-grudge
## (R23: passing the Mind gate IS getting the insult), replacing the
## mock_sensitive gate that still governs LANDED feints unchanged. A spec
## without read_threshold (non-feint setup skills) is never readable.
func _resolve_setup_debuff(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = _first_target(action)
	events.append_array(_free_reposition(actor, action, int(spec.get("reposition", 1)), "feint_reposition"))
	if target != null and target.alive:
		var read: Dictionary = ai.check_feint_read(target, int(spec.get("read_threshold", 0)))
		if bool(read.get("read", false)):
			events.append({
				"type": "feint_read", "reader": target.id, "feinter": actor.id,
				"threshold": int(read["threshold"]), "mind": int(read["mind"]),
				"die": int(read["die"]), "roll": int(read["roll"]), "auto": bool(read["auto"]),
			})
			events.append_array(EnemyAI.add_antagonism(
				target, actor.id, target.personality_mock_grudge(), "mockery"))
		else:
			target.feint_forced = true
			target.feint_by = actor.id  # attribution for the feint_fallout payoff event
			events.append({"type": "feint_applied", "actor": actor.id, "target": target.id})
			# R23: the Feint is the one taunt-shaped act — an AI target whose
			# personality is mock-SENSITIVE (authored, default Mind >= 3) takes the
			# insult personally and earns mock_grudge toward the mocker. A creature
			# too dim to parse the insult (incinedile, Mind 1) gains nothing.
			if target.personality_mock_sensitive():
				events.append_array(EnemyAI.add_antagonism(
					target, actor.id, target.personality_mock_grudge(), "mockery"))
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


# ---------------------------------------------------- batch-A skill resolvers

## Shared collapse for a windup premise that broke between declare and
## resolution — the standard invalidated-windup shape (event + Forced roll),
## with the escaped target excluded from Collateral exactly like the generic
## windup path does. F3 (batch B): the collapse TABLE is a parameter — the
## self-broken batch-A premises and the feint path keep the default Tool;
## counter_surge's inflicted windup cut rolls BODY (its spec's
## collapse_table), with the roll reason naming the cut. Never silently reuse
## Tool for a new collapse source — pass the authored table.
func _collapse_batch_windup(actor: CombatantState, reason: String, forced_queue: Array[Dictionary], original_target: String, table: String = ForcedAction.TABLE_TOOL, roll_reason: String = "invalidated_windup") -> Array[Dictionary]:
	var events: Array[Dictionary] = [{"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": reason}]
	var collapse: Dictionary
	if table == ForcedAction.TABLE_BODY:
		# Batch C: an inflicted BODY collapse (counter_surge's cut) goes through
		# the save chokepoint — an armed acrobatic_save betters this roll too.
		var body: Dictionary = _forced_body_roll(actor, roll_reason)
		collapse = body["rolled"]
		events.append_array(body["events"])
		# Tier-2 wave 1 (S5-d): a NEGATED Body roll queues no consequence —
		# the windup still collapsed; the Forced Action was vetoed outright.
		if bool(body.get("negated", false)):
			return events
	else:
		collapse = ForcedAction.roll(table, rng)
		events.append(ForcedAction.make_event(actor.id, collapse, roll_reason))
	forced_queue.append({"actor": actor.id, "rolled": collapse, "ctx": {
		"part": actor.acting_part(clock.tick), "target": original_target,
	}})
	return events


## Batch C (acrobatic_save): the ONE chokepoint every resolver-side Forced
## Action – BODY roll goes through. Unarmed: exactly the legacy shape — one
## roll off the action rng stream, one forced_action_triggered event, ZERO
## extra draws (the twin-RNG guarantee: an un-armed fight is byte-identical
## to the pre-batch engine). Armed (victim.forced_save): the arming is
## consumed FIRST (per roll — a same-batch second Body roll gets no save),
## `dice` EXTRA dice are drawn from the SAME stream, every die emitted inside
## the acrobatic_save event, and the LOWEST-severity consequence is kept
## (ForcedAction.save_severity — the documented deterministic choose rule; a
## severity tie keeps the EARLIEST roll, i.e. the original). The
## forced_action_triggered event then carries the CHOSEN roll — the one whose
## consequence actually applies. Returns {"rolled": chosen, "events": [...]}.
##
## Tier-2 wave 1 (perfect_evasion — S5-d, [FROM row 68]): an arming carrying
## the "negate" flag VETOES the Forced Action – Body outright, once per Clock
## (negate_used_clock — the Clock INDEX gate: open again after the reset, no
## sweep needed). The base die is still drawn first (stream discipline: the
## unarmed/armed/negated paths all consume the same base draw), the arming is
## consumed, the vetoed roll is emitted in forced_body_negated, and NO
## forced_action_triggered fires — callers skip queueing via "negated". A
## same-Clock second negate falls back to the dice-softening path (the save
## still softens; "second negate rejected until reset"). Scope honesty: this
## chokepoint covers every RESOLVER-side Body roll; condition-timer rolls
## outside the resolver are outside this story's footprint.
func _forced_body_roll(victim: CombatantState, reason: String) -> Dictionary:
	var events: Array[Dictionary] = []
	var rolled: Dictionary = ForcedAction.roll(ForcedAction.TABLE_BODY, rng)
	if not victim.forced_save.is_empty() and bool(victim.forced_save.get("negate", false)):
		var clock_index: int = clock.tick / Clock.TICKS_PER_CLOCK
		if victim.negate_used_clock != clock_index:
			victim.forced_save = {}  # consumed — the negate IS the save's use
			victim.negate_used_clock = clock_index
			events.append({
				"type": "forced_body_negated", "actor": victim.id, "reason": reason,
				"vetoed_roll": int(rolled["roll"]),
				"vetoed_consequence": String(rolled["consequence"]),
				"clock_index": clock_index,
			})
			return {"rolled": rolled, "events": events, "negated": true}
	if not victim.forced_save.is_empty():
		var dice: int = maxi(1, int(victim.forced_save.get("dice", 1)))
		victim.forced_save = {}  # consumed per roll — armed for THAT roll only
		var rolls: Array[Dictionary] = [rolled]
		for i: int in range(dice):
			rolls.append(ForcedAction.roll(ForcedAction.TABLE_BODY, rng))
		var best: int = 0
		for i: int in range(1, rolls.size()):
			if ForcedAction.save_severity(rolls[i]) < ForcedAction.save_severity(rolls[best]):
				best = i
		var roll_rows: Array = []
		for r: Dictionary in rolls:
			roll_rows.append({"roll": int(r["roll"]), "consequence": String(r["consequence"])})
		events.append({
			"type": "acrobatic_save", "actor": victim.id, "reason": reason,
			"rolls": roll_rows, "chosen_index": best, "kept_original": best == 0,
		})
		rolled = rolls[best]
	events.append(ForcedAction.make_event(victim.id, rolled, reason))
	return {"rolled": rolled, "events": events}


## leap_strike (pounce): the leap lands and the strike resolves in ONE action.
## The landing re-validates LIVE at resolution — a body/wall now on the hex
## collapses the windup ("leap_blocked"), and a target whose snapshot hex left
## the landing's reach dodged it ("target_left_landing") — both the standard
## invalidation. R20 holds: a target that slipped into stealth during the
## windup vanished from the pouncer's fiction. The leap consumes NO move
## allowance (absorbed into the action — R3 untouched). The strike then rides
## the normal path with window 0: this resolver's own checks REPLACE the
## generic windup re-check (the stored reach is the leap envelope, leap+1 —
## re-running the generic check would let a landing-adjacency miss through).
func _resolve_leap_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var targets: Array = action.get("targets", [])
	var target_id: String = "" if targets.is_empty() else String((targets[0] as Dictionary).get("id", ""))
	var target: CombatantState = combatants.get(target_id)
	var target_snap: Dictionary = snapshot.get(target_id, {})
	if target == null or not bool(target_snap.get("alive", false)):
		return _collapse_batch_windup(actor, "target_dead", forced_queue, target_id)
	if bool(target_snap.get("stealthed", false)) and target.team != actor.team:
		return _collapse_batch_windup(actor, "target_stealthed", forced_queue, target_id)
	var to: Vector2i = actor.position
	if action.has("leap_to"):
		var lt: Array = action["leap_to"]
		to = Vector2i(int(lt[0]), int(lt[1]))
	var target_pos_raw: Array = target_snap.get("position", [target.position.x, target.position.y])
	var target_pos := Vector2i(int(target_pos_raw[0]), int(target_pos_raw[1]))
	if CombatantState.hex_distance(to, target_pos) > 1:
		return _collapse_batch_windup(actor, "target_left_landing", forced_queue, target_id)
	var events: Array[Dictionary] = []
	if to != actor.position:
		if _movement_blocked_reason(actor, to) != "":
			return _collapse_batch_windup(actor, "leap_blocked", forced_queue, target_id)
		var from: Vector2i = actor.position
		actor.position = to
		# R30: the resolved leap faces its movement direction (the table's
		# leap rule; the strike's own declare already faced the prey from the
		# ORIGINAL hex — resolves never re-face toward targets).
		_face_along(actor, from, to)
		events.append({"type": "pounce_leap", "actor": actor.id,
			"from": [from.x, from.y], "to": [to.x, to.y],
			"spaces": CombatantState.hex_distance(from, to)})
	var synth: Dictionary = {"actor": actor.id, "action": action, "window": 0}
	events.append_array(_strike_via_spec(actor, synth, snapshot, forced_queue, spec))
	return events


## slip_reposition_strike (slip_through): the leg cuts (rows rebuilt at
## declare), then the REAR-ARC reposition, then the Exposed rider. Cost 1 =
## instant (R2): no windup re-checks. R30 retrofit (decision #33 — retires the
## F5 far-side approximation): "reposition behind" is REAL — the destination
## scans the target's REAR-arc adjacent hexes in a fixed, documented order
## (directly behind = facing+3 first, then facing+2, then facing+4; the
## target's LIVE facing at resolution), taking the first free one (the actor's
## own hex counts as free — already behind = stay put). No rear hex free =
## the pre-R30 far-side fallback (the hex directly across, then the first free
## neighbor in fixed order), documented: the slip still happens, just not
## cleanly behind. The reposition faces its movement direction (R30 table).
func _resolve_slip_reposition_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target != null and target.alive:
		var from: Vector2i = actor.position
		var to: Vector2i = from
		var found_rear: bool = false
		for rear_offset: int in [3, 2, 4]:
			var candidate: Vector2i = target.position \
				+ HexGeometry.DIRECTIONS[(target.facing + rear_offset) % 6]
			if candidate == from or _movement_blocked_reason(actor, candidate) == "":
				to = candidate
				found_rear = true
				break
		if not found_rear:
			# Far-side fallback (the pre-R30 rule, kept verbatim): directly
			# across the target from the actor; blocked, the first free
			# neighbor of the target (fixed order) that is not the actor's own
			# hex; nowhere free = hold position (the wall rule).
			var far: Vector2i = target.position + (target.position - from)
			if _movement_blocked_reason(actor, far) == "":
				to = far
			else:
				for neighbor: Vector2i in EnemyAI.HEX_NEIGHBORS:
					var candidate: Vector2i = target.position + neighbor
					if candidate == from:
						continue
					if _movement_blocked_reason(actor, candidate) == "":
						to = candidate
						break
		if to != from:
			_face_along(actor, from, to)  # R30: voluntary reposition
			actor.position = to
		events.append({"type": "slip_through_reposition", "actor": actor.id,
			"from": [from.x, from.y], "to": [to.x, to.y], "moved": to != from})
		var until: int = clock.tick + int(spec.get("exposed_ticks", 2))
		target.exposed_until_tick = maxi(target.exposed_until_tick, until)
		events.append({"type": "slip_through_exposed", "actor": actor.id,
			"target": target.id, "until_tick": until})
	return events


## head_finisher (decapitate): the bypass-gated Head strike, then — when the
## Head kill really happened (the normal lethal path emitted combatant_died off
## THIS strike) — the cinematic_kill beat: attributed to the killer and
## carrying the authored spectacle payout for the HypeEngine
## spectacle_points hook (PLACEHOLDER R14).
func _resolve_head_finisher(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target != null and not target.alive:
		for event: Dictionary in events:
			if String(event.get("type", "")) == "combatant_died" and String(event.get("combatant", "")) == target.id:
				events.append({
					"type": "cinematic_kill", "actor": actor.id, "target": target.id,
					"skill_key": String(action.get("key", "decapitate")),
					"spectacle_points": int(spec.get("cinematic_spectacle", 0)),
				})
				break
	return events


## aoe_cone_strike (shockwave): membership computed LIVE at resolution (cost 1
## = instant, R2 — no escape window): every living, in-play combatant on the
## OTHER team whose hex is in the declared cone — stealthed bodies included
## (the R20 physicality rule for area geometry) — EXCLUDING the actor's
## last_action_target (the Overhead Slam victim, the authored L1 core; read
## here BEFORE _resolve_entry overwrites the chain bookkeeping — load-bearing:
## shoving the downed victim would break Execution's adjacency). Per member in
## sorted-id order: one strike round to the first usable leg part (torso-line
## fallback), the 1-hex knockback away from the actor on a CONNECTED hit, and
## — Mob category only — Forced Action – Body off the existing rng stream.
func _resolve_aoe_cone_strike(actor: CombatantState, entry: Dictionary, _snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	var shape: Dictionary = action.get("area_shape", {})
	var toward_raw: Array = shape.get("toward", [])
	var size: int = int(shape.get("size", int(spec.get("cone_size", 3))))
	if toward_raw.size() != 2 or size <= 0:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "malformed_cone"})
		return events
	var dir := Vector2i(int(toward_raw[0]), int(toward_raw[1]))
	var arc: Dictionary = HexGeometry.to_set(HexGeometry.cone(actor.position, actor.position + dir, size))
	var excluded: String = actor.last_action_target
	# Membership FIRST (sorted ids, live positions), then the per-member rounds
	# — a member's knockback never re-shapes who the wave already caught.
	var members: Array[CombatantState] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or other.team == actor.team:
			continue
		if not other.alive or other.removed_from_play:
			continue
		if other.id == excluded or not arc.has(other.position):
			continue
		members.append(other)
	var amount: int = int(spec.get("amount", 1))
	var condition_id := ConditionEngine.normalize_condition_id(String(spec.get("damage_type", "crushed")))
	for member: CombatantState in members:
		var part_key: String = _first_leg_part(member)
		if part_key == "":
			continue  # nothing attackable on this body
		var member_events: Array[Dictionary] = _strike_round(member, part_key, condition_id, amount, action, actor)
		events.append_array(member_events)
		if not _hit_landed(member_events, member.id):
			continue
		events.append_array(_knockback_away(member, actor))
		if member.category == "Mob":
			var body: Dictionary = _forced_body_roll(member, "shockwave")
			events.append_array(body["events"])
			if not bool(body.get("negated", false)):  # S5-d veto queues nothing
				forced_queue.append({"actor": member.id, "rolled": body["rolled"], "ctx": {"part": member.acting_part(clock.tick)}})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "shockwave")), "result": "ok", "rounds": members.size()})
	return events


## downed_finisher (execution): re-checks the downed premise LIVE at
## resolution (standing up mid-windup escapes the finisher — the standard
## collapse), then the strike through the normal windup path; a landed Torso
## hit adds the authored Shock T3 (Faint); a Head kill is the normal lethal
## path (no cinematic beat — that is decapitate's).
func _resolve_downed_finisher(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var target_id: String = "" if target == null else target.id
	if target == null or not target.alive:
		return _collapse_batch_windup(actor, "target_dead", forced_queue, target_id)
	if not _target_downed(target):
		return _collapse_batch_windup(actor, "target_not_downed", forced_queue, target_id)
	var part := String(((action.get("targets", [])[0]) as Dictionary).get("part", ""))
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if part.contains("torso") and target.alive and _hit_landed(events, target.id):
		var tier: int = int(spec.get("torso_shock_tier", 3))
		events.append({"type": "execution_shock", "actor": actor.id, "target": target.id, "tier": tier})
		events.append_array(cond.apply_shock(target, tier, clock.tick, part))
	return events


## multi_part_flurry (thousand_cuts): capture which declared parts ALREADY
## bled (pre-strike, at resolution — "already had active Bleed" when the cuts
## land), run the flurry (each landed cut applies/reapplies Bleed through the
## normal R4 path), then — ALL parts pre-bleeding AND all cuts landed (net
## damage > 0, the Physical-path landed equivalence) — the authored payoff
## advances each part one MORE tier on top of the standard reapply advance
## (the SkillBook note of record), then the free reposition.
func _resolve_multi_part_flurry(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var rows: Array = action.get("targets", [])
	var pre_bleeding: bool = target != null and not rows.is_empty()
	if target != null:
		for row: Variant in rows:
			if target.condition_tier(String((row as Dictionary).get("part", "")), "bleeding") <= 0:
				pre_bleeding = false
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target != null and target.alive and pre_bleeding:
		var landed_count: int = 0
		for event: Dictionary in events:
			if String(event.get("type", "")) == "damage_applied" \
					and String(event.get("combatant", "")) == target.id \
					and int(event.get("amount", 0)) > 0:
				landed_count += 1
		if landed_count >= rows.size():
			var parts: Array = []
			for row: Variant in rows:
				parts.append(String((row as Dictionary).get("part", "")))
			events.append({"type": "thousand_cuts_tier_advance", "actor": actor.id,
				"target": target.id, "parts": parts})
			for pk: Variant in parts:
				events.append_array(cond.advance(target, String(pk), "bleeding", 1, clock.tick, "thousand_cuts_flurry"))
	events.append_array(_free_reposition(actor, action, int(spec.get("reposition", 2)), "thousand_cuts_reposition"))
	return events


## crossing_arc_strike (slice_n_dice): every G8 mode strikes ALL its rows at
## ONE amount (limbs share the limb value; each torso mode its own), so the
## mode — stamped at declare — just retunes the spec amount and the normal
## strike path (windup re-checks included) does the rest.
func _resolve_crossing_arc_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var mode := String(action.get("slice_mode", _crossing_arc_mode(action.get("targets", []))))
	var tuned: Dictionary = spec.duplicate(true)
	match mode:
		"single_torso":
			tuned["amount"] = int(spec.get("torso_bleed", 3))
		"pair_torsos":
			tuned["amount"] = int(spec.get("pair_torso_bleed", 1))
		_:
			tuned["amount"] = int(spec.get("limb_bleed", 2))
	return _strike_via_spec(actor, entry, snapshot, forced_queue, tuned)


## pow_strike (heroic_punch): capture the target's Exposed state BEFORE the
## strike, resolve the committed Crush normally, then the riders on a LANDED
## Head hit: the crowd POW beat (heroic_punch_pow, carrying the authored
## spectacle payout through the HypeEngine hook — PLACEHOLDER R14) and — when
## the target was EXPOSED specifically — the Shock rattle.
func _resolve_pow_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var was_exposed: bool = target != null and target.exposed_cache
	var rows: Array = action.get("targets", [])
	var part: String = "" if rows.is_empty() else String((rows[0] as Dictionary).get("part", ""))
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target != null and part.contains("head") and _hit_landed(events, target.id):
		events.append({
			"type": "heroic_punch_pow", "actor": actor.id, "target": target.id,
			"part": part, "spectacle_points": int(spec.get("pow_spectacle", 0)),
		})
		if was_exposed and target.alive:
			var tier: int = int(spec.get("head_shock_tier", 1))
			events.append({"type": "heroic_punch_shock", "actor": actor.id, "target": target.id, "tier": tier})
			events.append_array(cond.apply_shock(target, tier, clock.tick, part))
	return events


# ---------------------------------------------------- batch-B skill resolvers

## retarget_guard (batch B). Reaction form (intercept): the guard declare
## resolves by ARMING the guard — armed_primes["intercept"] (the PREP
## substrate) + the guard record {ally, range, reduction} on the guardian. The
## interception itself is never a declared action: nothing consumes the prime,
## so the guard persists across hits (the per-hit price is the reaction slot,
## paid in _strike_round) until replaced by a new guard declare or cleared by
## the CombatSim sweep (guardian or ally down). Re-declaring on another ally
## REPLACES the guard (one guarded ally below the L6 threshold). Stance form
## (iron_stance): enters the stance — anchor = the hex held; the CombatSim
## _guard_checks sweep breaks it on movement/Prone/down (the dance-exit
## pattern). Both are cost-0 instants; the premise is re-checked live at
## resolution (same-tick state can change between declare and resolve).
func _resolve_retarget_guard(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if String(spec.get("form", "")) == "stance":
		if bool(actor.statuses.get("prone", false)):
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "prone"})
			return events
		actor.iron_stance = {
			"anchor": [actor.position.x, actor.position.y],
			"radius": int(spec.get("guard_radius", 1)),
			"reduction": int(spec.get("stance_reduction", 1)),
			"types": (spec.get("stance_types", ["crushed", "burn"]) as Array).duplicate(),
		}
		events.append({"type": "iron_stance_started", "combatant": actor.id,
			"anchor": [actor.position.x, actor.position.y],
			"radius": int(actor.iron_stance["radius"]),
			"reduction": int(actor.iron_stance["reduction"]),
			"types": (actor.iron_stance["types"] as Array).duplicate()})
		events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "iron_stance")), "result": "ok", "rounds": 0})
		return events
	var ally: CombatantState = _first_target(action)
	if ally == null or not ally.alive or ally.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "ally_downed"})
		return events
	actor.guard = {
		"ally": ally.id,
		"range": int(spec.get("guard_range", 1)),
		"reduction": int(spec.get("intercept_reduction", 0)),
	}
	actor.armed_primes["intercept"] = true
	events.append({"type": "guard_set", "guardian": actor.id, "ally": ally.id,
		"range": int(actor.guard["range"]), "reduction": int(actor.guard["reduction"])})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "intercept")), "result": "ok", "rounds": 0})
	return events


## skill_grapple (batch B — pressure_hold / death_grip_jaws). HOLD mode: the
## R9 grapple through the skill surface — grappling/grappled_by set (neither
## repositions and BOTH are Exposed via the existing R9/ExposureEngine
## substrate, nothing re-authored), the R30 mutual facing, and the R9 Physique
## gate (grappler Physique < target's = Forced Action – Body off the action
## rng; the hold still lands). A windup hold (pressure_hold, cost 2) re-checks
## its premise at resolution — target alive/in-reach against the R2 snapshot,
## grip + not-already-holding LIVE (the reload re-verify family) — and
## collapses into the standard invalidation otherwise. The jaws variant then
## delivers the L2+ initial-bite Bleed rider through the HONEST R14 strike
## gate (_strike_round on the victim's torso-line part — deterministic locus,
## documented; R26 undodgable: the bite rides a hold that already landed, so
## no dodge-shaped escape and ZERO rng consumed by the skip). DRAG mode
## ("drag_to" while holding): the pair walks the hex line 1 hex at a time (the
## grab_pull idiom) — the holder steps into the next free hex, the victim is
## pulled into the hex just vacated (adjacency preserved by construction) —
## stopping early at walls/bounds/cans/bodies (the victim's own body blocks a
## drag straight through them, deterministically). R30: the holder's drag is
## voluntary movement (faces the step direction); the dragged victim's facing
## NEVER changes (drag is on the update table's involuntary exclusion list).
func _resolve_skill_grapple(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var key := String(action.get("key", "pressure_hold"))
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	var events: Array[Dictionary] = []
	if action.has("drag_to"):
		if target == null or not target.alive or target.removed_from_play \
				or actor.grappling != target.id or target.grappled_by != actor.id:
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "grip_lost"})
			return events
		var dt: Array = action["drag_to"]
		var to := Vector2i(int(dt[0]), int(dt[1]))
		var limit: int = int(spec.get("drag", 0))
		var actor_from: Vector2i = actor.position
		var victim_from: Vector2i = target.position
		var steps: int = 0
		while steps < limit and actor.position != to:
			var lane: Array[Vector2i] = HexGeometry.line(actor.position, to)
			if lane.size() < 2:
				break
			var next: Vector2i = lane[1]
			if _movement_blocked_reason(actor, next) != "":
				break  # walls/bounds/cans/bodies stop the drag honestly (victim included)
			var vacated: Vector2i = actor.position
			actor.position = next
			target.position = vacated
			_face_along(actor, vacated, next)  # R30: the holder's step is voluntary
			steps += 1
		events.append({"type": "grapple_dragged", "actor": actor.id, "target": target.id,
			"from": [actor_from.x, actor_from.y], "to": [actor.position.x, actor.position.y],
			"target_from": [victim_from.x, victim_from.y],
			"target_to": [target.position.x, target.position.y],
			"spaces": steps, "limit": limit})
		events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": key, "result": "ok", "rounds": 0})
		return events
	# --- HOLD mode ---
	var is_windup: bool = int(entry["window"]) > 0
	var target_id: String = String(action.get("target", ""))
	if target == null or not target.alive or target.removed_from_play:
		if is_windup:
			return _collapse_batch_windup(actor, "target_dead", forced_queue, target_id)
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "invalid_target"})
		return events
	if is_windup:
		# R2 snapshot re-checks: an escaped/stealthed target dodges the windup.
		var target_snap: Dictionary = snapshot.get(target.id, {})
		if not bool(target_snap.get("alive", false)):
			return _collapse_batch_windup(actor, "target_dead", forced_queue, target_id)
		if bool(target_snap.get("stealthed", false)) and target.team != actor.team:
			return _collapse_batch_windup(actor, "target_stealthed", forced_queue, target_id)
		var actor_snap: Dictionary = snapshot.get(actor.id, {})
		var a_pos: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
		var t_pos: Array = target_snap.get("position", [target.position.x, target.position.y])
		if CombatantState.hex_distance(Vector2i(int(a_pos[0]), int(a_pos[1])),
				Vector2i(int(t_pos[0]), int(t_pos[1]))) > int(spec.get("attack_range", 1)):
			return _collapse_batch_windup(actor, "out_of_range", forced_queue, target_id)
	# LIVE re-verifies (the reload needs-both-hands family).
	if actor.grappling != "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "already_grappling"})
		return events
	var grip := String(spec.get("grip", "hands"))
	var grip_reason: String = _grip_unmet(actor, grip)
	if grip_reason != "":
		if is_windup:
			return _collapse_batch_windup(actor, grip_reason, forced_queue, target_id)
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": grip_reason})
		return events
	actor.grappling = target.id
	target.grappled_by = actor.id
	# R30: a grapple faces BOTH parties toward each other (the table's one
	# involuntary facing) — same rule as the base grapple kind, verified there.
	_face_along(actor, actor.position, target.position)
	_face_along(target, target.position, actor.position)
	events.append({"type": "grapple_started", "grappler": actor.id, "target": target.id, "skill": key})
	# R9: automatic when grappler Physique >= target's; otherwise Forced
	# Action – Body — always allowed, consequences apply, hold lands.
	# Grip-neutral acting part (vice_grip's "any"): the hand when one is
	# usable, else the bite part — whichever anatomy actually holds.
	var acting: String = actor.acting_part(clock.tick)
	if grip == "bite":
		acting = actor.bite_part(clock.tick)
	elif grip == "any" and actor.usable_hands(clock.tick) < 1:
		acting = actor.bite_part(clock.tick)
	if actor.trait_total("physique") < target.trait_total("physique"):
		var body: Dictionary = _forced_body_roll(actor, "grapple_above_weight")
		events.append_array(body["events"])
		if not bool(body.get("negated", false)):  # S5-d veto queues nothing
			forced_queue.append({"actor": actor.id, "rolled": body["rolled"], "ctx": {"part": acting, "target": target.id}})
	# death_grip_jaws L2+: the initial-bite Bleed rider on close. Tier-2 wave
	# 1 (vice_grip — S7-b, [FROM row 86]): the grip-neutral sibling
	# `grip_bleed` rides the SAME honest strike gate — the grip closes with a
	# real Bleed wound on the held part (deterministic torso-line locus, the
	# bite-rider convention); the standing per-Clock condition advancement
	# then carries the wound forward. The literal while-held per-reset
	# re-application needs the Clock-reset rider (combat_sim's sweep — outside
	# this story's footprint; the rung content stays data-flagged).
	var bite: int = int(spec.get("grip_bleed", spec.get("bite_bleed", 0)))
	if bite > 0 and target.alive:
		var bite_part: String = ai.torso_line_part(target)
		if bite_part != "":
			var rider_type: String = "grip_bleed_rider" if spec.has("grip_bleed") else "bite_rider"
			events.append({"type": rider_type, "actor": actor.id, "target": target.id,
				"part": bite_part, "amount": bite})
			events.append_array(_strike_round(target, bite_part, "bleeding", bite,
				{"kind": "skill", "key": key, "undodgable": true}, actor))
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": key, "result": "ok", "rounds": 0})
	return events


## interrupt_counter (batch B — counter_surge): the cost-1 strike rides the
## normal path (the winding-up victim is Exposed through its windup, so the
## R22 dodge never fires — the punish window, no special casing); then a
## CONNECTED hit (damage_applied — the knock-aside convention: a robustness-
## blocked 0 still connected) CUTS the victim's remaining windup cost by the
## level's cost_cut. Cut < remaining: the entry is RESCHEDULED cut ticks
## earlier (Clock.reschedule_windup_for — "reducing their action's remaining
## cost" literally: the shortened windup also pulls next_action_tick in sync)
## and windup_cut reports the arithmetic. Cut >= remaining: the action
## COLLAPSES — the entry is cancelled (Clock.cancel_windup_for), the victim's
## windup_pending re-derives, and the victim rolls Forced Action – BODY
## through the PARAMETERIZED collapse helper (F3: the table is a parameter;
## the feint path keeps Tool) on the same action rng stream every Forced
## Action rides. A victim whose windup already left the queue (it resolves
## this very tick — R2 simultaneity: same-tick means already firing) takes
## the hit but no cut: windup_cut_missed says so.
func _resolve_interrupt_counter(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var target: CombatantState = _first_target(action)
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target == null or not _hit_landed(events, target.id):
		return events
	var windup: Dictionary = clock.windup_entry_for(target.id)
	if windup.is_empty():
		events.append({"type": "windup_cut_missed", "actor": actor.id, "target": target.id})
		return events
	var remaining: int = int(windup["tick"]) - clock.tick
	var cut: int = int(spec.get("cost_cut", 1))
	if cut >= remaining:
		var cancelled: Dictionary = clock.cancel_windup_for(target.id)
		target.windup_pending = clock.has_windup_for(target.id)
		var victim_action: Dictionary = cancelled.get("action", {})
		var victim_targets: Array = victim_action.get("targets", [])
		var victim_target: String = "" if victim_targets.is_empty() \
			else String((victim_targets[0] as Dictionary).get("id", ""))
		events.append({"type": "windup_collapsed", "actor": actor.id, "victim": target.id,
			"cut": cut, "remaining_before": remaining,
			"key": String(victim_action.get("key", String(victim_action.get("item", ""))))})
		events.append_array(_collapse_batch_windup(target, "windup_cut", forced_queue,
			victim_target, String(spec.get("collapse_table", ForcedAction.TABLE_BODY)), "windup_cut"))
	else:
		var new_tick: int = int(windup["tick"]) - cut
		clock.reschedule_windup_for(target.id, new_tick)
		target.next_action_tick = mini(target.next_action_tick, new_tick)
		events.append({"type": "windup_cut", "actor": actor.id, "victim": target.id,
			"cut": cut, "remaining_before": remaining, "remaining_after": remaining - cut,
			"resolve_tick": new_tick})
	return events


## fused_counter (counterscript, tier-2 wave 2 — S1). Mode "read" routes to
## _resolve_counter_read. Default mode "counter" (S1-a, the WIDENED gate):
## the strike resolves first (the counter_surge convention — a
## robustness-blocked 0 still connects), the read-target gate re-checks LIVE
## (a read expired at the Clock reset mid-flight is an honest miss). A
## connected hit answers the read target's ONE genuinely pending declared
## action:
##   * a FUTURE windup (the Clock queue — during resolution the queue holds
##     only future entries): cut remaining Moments, the counter_surge
##     arithmetic + events verbatim; cut >= remaining collapses it (Forced
##     BODY, the parameterized table). A cut that does NOT collapse arms the
##     S1-b per-source immunity window (L2+, [FROM row 8]): the source
##     cannot affect this counter-actor for immunity_moments Moments —
##     counter_immunities, enforced at the hit seams.
##   * a SAME-TICK still-pending scheduled instant (the due batch, seq >
##     this counter's — declared AFTER the counter, unresolved): its whole
##     remaining cost (the 1 Moment completing now) is cut, so it collapses
##     at its own slot (_counter_cuts -> _resolve_entry, Forced BODY). The
##     honest boundary, stated: a lower-seq entry already RESOLVED before
##     this counter — a same-tick instant can never be countered after
##     resolution (the batch-B "already firing" rule, seq-exact), so the
##     widened gate covers exactly the SCHEDULED remainder. Free 0-cost
##     entries carry no remaining cost and are never counterable.
##   * neither: counter_missed — the strike landed, nothing was left to
##     answer.
func _resolve_fused_counter(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	if String(action.get("mode", "counter")) == "read":
		return _resolve_counter_read(actor, action, spec)
	var target: CombatantState = _first_target(action)
	var events: Array[Dictionary] = _strike_via_spec(actor, entry, snapshot, forced_queue, spec)
	if target == null or not _hit_landed(events, target.id):
		return events
	if not actor.pattern_reads.has(target.id):
		events.append({"type": "counter_missed", "actor": actor.id, "target": target.id,
			"reason": "read_expired"})
		return events
	var cut: int = int(spec.get("cost_cut", 1))
	var windup: Dictionary = clock.windup_entry_for(target.id)
	if not windup.is_empty():
		var remaining: int = int(windup["tick"]) - clock.tick
		if cut >= remaining:
			var cancelled: Dictionary = clock.cancel_windup_for(target.id)
			target.windup_pending = clock.has_windup_for(target.id)
			var victim_action: Dictionary = cancelled.get("action", {})
			var victim_targets: Array = victim_action.get("targets", [])
			var victim_target: String = "" if victim_targets.is_empty() \
				else String((victim_targets[0] as Dictionary).get("id", ""))
			events.append({"type": "windup_collapsed", "actor": actor.id, "victim": target.id,
				"cut": cut, "remaining_before": remaining,
				"key": String(victim_action.get("key", String(victim_action.get("item", ""))))})
			events.append_array(_collapse_batch_windup(target, "windup_cut", forced_queue,
				victim_target, String(spec.get("collapse_table", ForcedAction.TABLE_BODY)), "windup_cut"))
		else:
			var new_tick: int = int(windup["tick"]) - cut
			clock.reschedule_windup_for(target.id, new_tick)
			target.next_action_tick = mini(target.next_action_tick, new_tick)
			events.append({"type": "windup_cut", "actor": actor.id, "victim": target.id,
				"cut": cut, "remaining_before": remaining, "remaining_after": remaining - cut,
				"resolve_tick": new_tick})
			# S1-b ([FROM row 8], L2+): countered but NOT collapsed — "you
			# already answered it". Window convention: immune while
			# clock.tick < until_tick; until = T + moments + 1 covers the
			# NEXT `moments` Moments (T+1..T+moments — the counter's own
			# tick T rides along vacuously, a cut windup never resolves
			# before T+1). A re-counter of the same source overwrites
			# (latest answer wins — deterministic).
			var moments: int = int(spec.get("immunity_moments", 0))
			if moments > 0:
				var until: int = clock.tick + moments + 1
				actor.counter_immunities[target.id] = until
				events.append({"type": "counter_immunity", "actor": actor.id,
					"source": target.id, "moments": moments, "until_tick": until})
		return events
	var my_seq: int = int(entry.get("seq", -1))
	for due_entry: Dictionary in _due_batch:
		if String(due_entry.get("actor", "")) != target.id:
			continue
		if int(due_entry.get("seq", -1)) <= my_seq:
			continue
		var due_action: Dictionary = due_entry.get("action", {})
		if int(due_action.get("eff_cost", 0)) < 1:
			continue
		_counter_cuts[target.id] = {"seq": int(due_entry["seq"]), "by": actor.id}
		events.append({"type": "action_countered", "actor": actor.id, "victim": target.id,
			"cut": cut, "remaining_before": 1,
			"key": String(due_action.get("key", String(due_action.get("item",
				String(due_action.get("kind", "attack"))))))})
		return events
	events.append({"type": "counter_missed", "actor": actor.id, "target": target.id,
		"reason": "nothing_pending"})
	return events


## The counterscript read (mode "read", S1-a/c): the intel_reveal
## declared_read resolution on the SAME substrate — live re-checks, the
## deterministic schedule projection, the pattern_reads record (the existing
## Clock-reset expiry sweep and GameController's owner-gated view projection
## carry it unchanged — the additive exposure idiom already shipped) — plus
## the S1 read CAP: read_targets concurrent reads (1 below L3; S1-c's second
## enemy at L3+). A read past the cap REPLACES the OLDEST read (insertion
## order — attention moves; deterministic, and the dropped target's counter
## gate closes with it). Zero rng.
func _resolve_counter_read(actor: CombatantState, action: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = _first_target(action)
	if target == null or not target.alive or target.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	if not Stealth.sees(actor, target, arena, clock.tick):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_not_visible"})
		return events
	var cap: int = maxi(1, int(spec.get("read_targets", 1)))
	if not actor.pattern_reads.has(target.id) and actor.pattern_reads.size() >= cap:
		var oldest := String((actor.pattern_reads.keys() as Array)[0])
		actor.pattern_reads.erase(oldest)
		events.append({"type": "counterscript_read_dropped", "actor": actor.id, "target": oldest})
	var actions_revealed: int = maxi(1, int(spec.get("actions_revealed", 1)))
	actor.pattern_reads[target.id] = {"actions": actions_revealed}
	events.append({
		"type": "counterscript_read", "actor": actor.id, "target": target.id,
		"actions": actions_revealed,
		"schedule": _pattern_schedule_rows(target.id, actions_revealed),
	})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "counterscript")), "result": "ok", "rounds": 0})
	return events


# ---------------------------------------------------- batch-C skill resolvers

## ally_treatment (batch C — seal_the_wound / field_triage; tier-2 wave 2 —
## combat_medic): DELAY is the base mode; S6-d's RESOLVE is the ONE ruled
## exception, and it clears a CONDITION INSTANCE only.
## HONESTY PIN (FINAL default #8, updated for the wave-2 shape): this
## resolver still has no heal_part call — HP restoration structurally cannot
## happen here (tests/test_skills_batch_c.gd asserts the structure, not just
## the behavior). The S6-d resolve path goes through ConditionEngine.treat's
## OWN removal gates (mode "resolve": R10's infection-prevents-resolution
## rule, timer handling, resolve's timer cancellation) — never a bespoke
## removal (no direct cond.resolve call), never while the condition drives a
## bleed-out (a lethal state is held, not cured — re-checked live here), and
## once per Clock (treat_resolve_used_clock, spent only when the resolve
## actually LANDS). Re-checks the live target (an instant can still lose it
## to a same-tick death earlier in the batch), then delays the named
## condition delay_clocks Clocks through ConditionEngine.delay — whose
## existing bleed-out hook STABILIZES a downed ally when the delayed
## condition drives the bleed-out (R5's 0-HP-stabilized: alive, held, no HP
## restored — not a special case here). field_triage's bandage_charge (and
## combat_medic's ally-only ally_consumes twin) is consumed ONLY when the
## treatment actually lands — a premise that evaporated between declare and
## resolve never burns the bandage, and a self-treatment never touches the
## ally-gated charge. A treatment is not an attack: it never enters
## _strike_round, so the batch-B retarget_guard ignores it by construction —
## a guarded ally receives their own bandage, never the guardian.
func _resolve_ally_treatment(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	var target: CombatantState = _first_target(action)
	if target == null or not target.alive or target.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	var rows: Array = action.get("targets", [])
	var part_key: String = "" if rows.is_empty() else String((rows[0] as Dictionary).get("part", ""))
	var condition_id := ConditionEngine.normalize_condition_id(String(action.get("condition", "")))
	var mode := String(action.get("mode", "delay"))
	var landed: bool = false
	if mode == "resolve":
		# S6-d gates, re-checked LIVE (declare validated them; a same-tick
		# earlier resolution can change every one of them).
		if not (spec.get("resolve_conditions", []) as Array).has(condition_id):
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "condition_not_resolvable"})
			return events
		var clock_index: int = clock.tick / Clock.TICKS_PER_CLOCK
		if actor.treat_resolve_used_clock == clock_index:
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "resolve_used_this_clock"})
			return events
		if String(target.bleed_out.get("condition", "")) == condition_id:
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "lethal_state_held_not_cured"})
			return events
		var treat_events: Array[Dictionary] = cond.treat(target, part_key, condition_id, "resolve")
		for ev: Dictionary in treat_events:
			var ev_type := String(ev.get("type", ""))
			if ev_type == "condition_resolved" or ev_type == "timer_cancelled":
				landed = true
		if landed:
			actor.treat_resolve_used_clock = clock_index
			events.append({
				"type": "treatment_resolved", "actor": actor.id, "target": target.id,
				"part": part_key, "condition": condition_id,
				"skill": String(action.get("key", "")),
			})
		events.append_array(treat_events)
	else:
		var clocks: int = maxi(1, int(spec.get("delay_clocks", 1)))
		var delay_events: Array[Dictionary] = cond.delay(target, part_key, condition_id, clocks)
		for ev: Dictionary in delay_events:
			var ev_type := String(ev.get("type", ""))
			if ev_type == "condition_delayed" or ev_type == "timer_delayed":
				landed = true
		if landed:
			events.append({
				"type": "treatment_applied", "actor": actor.id, "target": target.id,
				"part": part_key, "condition": condition_id, "clocks": clocks,
				"skill": String(action.get("key", "")),
			})
		events.append_array(delay_events)
	var consumes := String(spec.get("consumes", ""))
	if consumes == "" and target.id != actor.id:
		consumes = String(spec.get("ally_consumes", ""))
	if landed and consumes != "":
		var remaining: int = maxi(0, int(actor.charges.get(consumes, 0)) - 1)
		actor.charges[consumes] = remaining
		events.append({"type": "charge_consumed", "actor": actor.id, "resource": consumes, "remaining": remaining})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "")), "result": "ok", "rounds": 0})
	return events


## intel_reveal declared form (read_the_pattern, batch C): ZERO rng. The read
## deep-copies the target's pending Clock entries (seq order — the
## scheduled_entries spectator probe) into a deterministic pattern_read event
## and records the reveal on the actor (pattern_reads). LIFETIME: "until the
## next Clock reset" verbatim — CombatSim's reset sweep clears the map and
## emits pattern_read_expired. KNOWLEDGE SURFACE (documented choice): the
## event carries the rows revealed AT READ TIME; while the reveal lives,
## GameController.view_combatants projects the target's CURRENT entries onto
## the OWNER's row (additive "pattern_reads" key) — so reading an idle enemy
## pays off the moment they declare, and the broadcast/spectator surface
## (view_schedule — already omniscient) is untouched. Visibility re-checks
## LIVE at resolution: a same-tick earlier resolution can kill the target or
## break the reader's sight (Stealth.sees — cone included).
func _resolve_intel_reveal(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	if String(spec.get("form", "")) != "declared_read":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "passive_skill"})
		return events
	var target: CombatantState = _first_target(action)
	if target == null or not target.alive or target.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	if not Stealth.sees(actor, target, arena, clock.tick):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_not_visible"})
		return events
	var actions_revealed: int = maxi(1, int(spec.get("actions_revealed", 1)))
	actor.pattern_reads[target.id] = {"actions": actions_revealed}
	events.append({
		"type": "pattern_read", "actor": actor.id, "target": target.id,
		"actions": actions_revealed,
		"schedule": _pattern_schedule_rows(target.id, actions_revealed),
	})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "read_the_pattern")), "result": "ok", "rounds": 0})
	return events


## The deterministic schedule projection a pattern read reveals: the target's
## pending Clock entries (seq order), up to `limit` rows, projected to the
## view_schedule vocabulary — kind / key / declared_tick / resolve_tick /
## windup. Deep-copied source (scheduled_entries), zero rng, zero mutation.
func _pattern_schedule_rows(target_id: String, limit: int) -> Array:
	var rows: Array = []
	for sched: Dictionary in clock.scheduled_entries():
		if rows.size() >= limit:
			break
		if String(sched.get("actor", "")) != target_id:
			continue
		var sched_action: Dictionary = sched.get("action", {})
		var window: int = int(sched.get("window", 0))
		var resolve_tick: int = int(sched.get("tick", 0))
		var key := String(sched_action.get("key", ""))
		if key == "":
			key = String(sched_action.get("item", ""))
		if key == "":
			key = String(sched_action.get("kind", "attack"))
		rows.append({
			"kind": String(sched_action.get("kind", "attack")),
			"key": key,
			"declared_tick": (resolve_tick - window) if window > 0 else resolve_tick,
			"resolve_tick": resolve_tick,
			"windup": window > 0,
		})
	return rows


## psychic_strike (mind_burst, batch C): the strike VARIANT — a windup that
## delivers Shock, not HP. Re-checks the premise against the R2 tick-start
## SNAPSHOT like every windup: a dead target, a hostile that slipped into
## stealth (vanished from the caster's fiction — the R20 rule plain aimed
## windups follow), a target out of the spec range, or broken line of sight
## collapses into the standard invalidated shape (Forced – Tool). Then ONE
## apply_shock at the spec tier: the R13 stated-tier + escalation model owns
## the already-Shocked case (old > 0 -> max(old + 1, tier)), and the struck
## head part rides along for the per-organ elevation. Deliberately no
## _strike_round: no Force/Robustness, no physical dodge (R22 is
## Reflexes-vs-physical), no damage_applied — psychic noise is not a wound.
func _resolve_psychic_strike(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	var rows: Array = action.get("targets", [])
	var part: String = "" if rows.is_empty() else String((rows[0] as Dictionary).get("part", ""))
	var target: CombatantState = _first_target(action)
	var original_first: String = "" if target == null else target.id
	if target == null or not target.alive or target.removed_from_play:
		return _collapse_batch_windup(actor, "target_gone", forced_queue, original_first)
	var snap: Dictionary = snapshot.get(target.id, {})
	if bool(snap.get("stealthed", false)) and target.team != actor.team:
		return _collapse_batch_windup(actor, "target_stealthed", forced_queue, original_first)
	var actor_snap: Dictionary = snapshot.get(actor.id, {})
	var actor_pos_raw: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
	var target_pos_raw: Array = snap.get("position", [target.position.x, target.position.y])
	var from := Vector2i(int(actor_pos_raw[0]), int(actor_pos_raw[1]))
	var to := Vector2i(int(target_pos_raw[0]), int(target_pos_raw[1]))
	if CombatantState.hex_distance(from, to) > int(spec.get("attack_range", 5)):
		return _collapse_batch_windup(actor, "target_left_range", forced_queue, original_first)
	if not Stealth.has_los(arena, from, to):
		return _collapse_batch_windup(actor, "lost_line_of_sight", forced_queue, original_first)
	# Tier-2 wave 2 (counterscript S1-b): the per-source counter immunity
	# covers the psychic seam too — this resolver deliberately never enters
	# _strike_round, so the exclusion is mirrored here: an immune target is
	# simply missed (no Shock, zero rng), the action still resolved.
	if clock.tick < int(target.counter_immunities.get(actor.id, 0)):
		events.append({"type": "attack_immune", "combatant": target.id, "part": part,
			"source": actor.id, "until_tick": int(target.counter_immunities[actor.id])})
		events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "mind_burst")), "result": "ok", "rounds": 0})
		return events
	var tier: int = int(spec.get("shock_tier", 2))
	events.append({"type": "mind_burst", "actor": actor.id, "target": target.id, "part": part, "tier": tier})
	events.append_array(cond.apply_shock(target, tier, clock.tick, part))
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "mind_burst")), "result": "ok", "rounds": 1})
	return events


# ---------------------------------------------------- batch-D skill resolvers

## aoe_blast (poison_ball / frost_ball / fire_ball, batch D): the ranged
## detonation at a declared HEX. Windup re-check (R2): line of sight from the
## caster to the center must still hold (a door closing mid-windup collapses
## the throw — the psychic_strike precedent; the hex itself cannot move, and
## a winding-up caster cannot). MEMBERSHIP is computed at resolution over
## SNAPSHOT positions (R2's tick-start authority: leaving the blast before
## its resolution tick escapes it; same-tick movement neither dodges nor
## blocks) — every living, in-play combatant EXCEPT THE CASTER (the valve's
## exclude-the-source precedent; friendly fire is otherwise ON — "all
## targets", chaos is content — and stealthed bodies are caught by hex,
## physicality over information). R25 (G1 refinement): a member whose
## rolled_this_window marker is live is MISSED entirely — unless the roll's
## destination hex IS the blast's center (and unlike the boss valve, a
## declared center hex can genuinely be rolled onto — the exception is live
## here). The blast is NOT undodgable (R26: only valve blasts carry that
## flag), so a boss dodge_threshold may roll against its row; ordinary
## targets have no blast dodge — the per-target row consumes ZERO rng.
## Each caught member takes one _strike_round row on its torso-line part
## (the can-blast locus — deterministic; the G8 "one exposed part (torso if
## none)" rewording): force-vs-robustness, resistances, brace, conditions
## and the per-target POISON ENTRY GATE all inside the normal machinery.
## frost_ball's authored Chilled T1 rides as a separate rider on every
## caught, un-escaped member (not dodged, not surface-blocked — Chilled is
## not wound-gated, matching the normal path); fire_ball then washes the
## blast over the arena's trash cans (_ignite_cans_in_blast — the
## can-ignition family's blast-shaped sibling). An EMPTY blast still
## resolves (the ground is washed, cans still catch): rounds 0, no collapse.
func _resolve_aoe_blast(actor: CombatantState, entry: Dictionary, snapshot: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var at_raw: Array = action.get("at", [])
	if at_raw.size() != 2:
		return [{"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "malformed_blast"}]
	var center := Vector2i(int(at_raw[0]), int(at_raw[1]))
	if not Stealth.has_los(arena, actor.position, center):
		return _collapse_batch_windup(actor, "lost_line_of_sight", forced_queue, "")
	var radius: int = int(spec.get("blast_radius", 1))
	var area: Dictionary = HexGeometry.to_set(HexGeometry.blast(center, radius))
	var condition_id := ConditionEngine.normalize_condition_id(String(spec.get("damage_type", "")))
	var amount: int = int(spec.get("amount", 0))
	var events: Array[Dictionary] = []
	# Membership first (sorted ids, snapshot hexes) — a member's own round
	# never re-shapes who the detonation already caught.
	var members: Array[CombatantState] = []
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id:
			continue
		var snap: Dictionary = snapshot.get(other.id, {})
		if not bool(snap.get("alive", false)):
			continue
		if not other.alive or other.removed_from_play:
			continue  # died earlier this batch — no rounds against a corpse
		var pos_raw: Array = snap.get("position", [other.position.x, other.position.y])
		if not area.has(Vector2i(int(pos_raw[0]), int(pos_raw[1]))):
			continue
		members.append(other)
	var caught: Array = []
	for member: CombatantState in members:
		caught.append(member.id)
	events.append({
		"type": "aoe_blast", "actor": actor.id,
		"key": String(action.get("key", "")),
		"center": [center.x, center.y], "radius": radius,
		"caught": caught,
	})
	var struck: int = 0
	for member: CombatantState in members:
		# R25: the AoE-center rule — a live roller is missed unless standing
		# on the center itself (live position: the roll already happened).
		if member.rolled_this_window and member.position != center:
			events.append({
				"type": "blast_missed_roller",
				"combatant": member.id, "by": actor.id,
				"at": [member.position.x, member.position.y],
				"center": [center.x, center.y],
			})
			continue
		var part_key: String = ai.torso_line_part(member)
		if part_key == "":
			continue  # nothing attackable on this body
		var member_events: Array[Dictionary] = _strike_round(member, part_key, condition_id, amount, action, actor)
		events.append_array(member_events)
		struck += 1
		# frost_ball's authored rider: Chilled T1 on a caught, un-escaped
		# member — a dodged or surface-blocked round escaped the frost too.
		if spec.has("rider_condition") and member.alive:
			var escaped: bool = false
			for ev: Dictionary in member_events:
				var ev_type := String(ev.get("type", ""))
				if (ev_type == "attack_dodged" or ev_type == "attack_blocked") \
						and String(ev.get("combatant", "")) == member.id:
					escaped = true
			if not escaped:
				events.append_array(cond.apply(member, part_key, String(spec["rider_condition"]), clock.tick, {
					"source": "attack",
					"attacker": actor.id,
				}))
	if bool(spec.get("ignites_flammables", false)):
		events.append_array(_ignite_cans_in_blast(actor, center, radius, amount))
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "")), "result": "ok", "rounds": struck})
	return events


## stealth_conceal (camouflage, batch D): the 3-Moment concealment windup
## resolves into STEALTH with the shrunken reveal radius. Premise re-checks
## LIVE (the batch collapse — Forced Tool, the book's invalidated-windup
## rule): already stealthed (entered via the command mid-windup) or grappled
## (contact IS detection). Then the modifier is set FIRST and the R20 entry
## gate runs WITH it — a watcher inside the shrunk radius still catches you
## (collapse, "in_enemy_sight" + the observer named); a watcher beyond it no
## longer matters, which is the skill: hiding in plain sight of the distant.
## Entry emits the substrate's own stealth_entered (additive via/reveal_radius
## keys) — every existing consumer of the stealth state sees a normal entry.
func _resolve_stealth_conceal(actor: CombatantState, entry: Dictionary, forced_queue: Array[Dictionary], spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	if actor.stealthed:
		return _collapse_batch_windup(actor, "already_stealthed", forced_queue, "")
	if actor.grappling != "" or actor.grappled_by != "":
		return _collapse_batch_windup(actor, "in_grapple", forced_queue, "")
	var radius: int = maxi(1, int(spec.get("reveal_radius", 6)))
	actor.conceal = {
		"radius": radius,
		"anchor": [actor.position.x, actor.position.y],
	}
	var observer: String = Stealth.first_observer_seeing(combatants, actor, arena, clock.tick)
	if observer != "":
		actor.conceal = {}
		var events: Array[Dictionary] = _collapse_batch_windup(actor, "in_enemy_sight", forced_queue, "")
		events[0]["observer"] = observer
		return events
	actor.stealthed = true
	return [
		{"type": "stealth_entered", "actor": actor.id, "via": "camouflage",
			"reveal_radius": radius},
		{"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "camouflage")), "result": "ok", "rounds": 0},
	]


## projection_control (vibe_control, batch D): the two projected modes.
## Instant (cost 1) — live premise re-checks in the batch-C style: the target
## must still be there and still PERCEIVE the actor (a same-tick earlier
## resolution can kill it or spin its cone away). FEAR: the 1-hex push
## directly away (the batch-A knockback helper — wall/bounds/can/body-honest,
## involuntary: no facing change) + the grudge REDUCTION toward the actor
## (EnemyAI.reduce_antagonism — floor 0; "less likely to prioritize you",
## fed straight into the R23 weighted targeting). CHARM: fixation — the
## grudge INCREASE (add_antagonism), the actor's 1-hex reposition while
## they're fixed (_free_reposition, reposition_to), then the target FACES
## the actor's final hex ("can't look away" — the second RULED involuntary
## facing after the grapple's, an authored addition to the R30 table,
## documented here as its seam) and is EXPOSED for exposed_ticks: the
## ladder's "Exposed-from-behind", whose "behind" half is the REAL R30
## is_behind gate — with the facing locked onto the actor, the rear arc is
## exactly the fixation's blind side (decapitate's own declare gate reads
## it). No persistent charm state is stored below the L9 survives-a-hit
## rung: the fixation is the facing snap + grudge + the bounded Exposed
## window (PROVISIONAL honest-minimal reading; the data's "ends when hit"
## has nothing stored to end — revisit if a later rung needs the state).
func _resolve_projection_control(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var mode := String(action.get("mode", ""))
	var target: CombatantState = _first_target(action)
	var events: Array[Dictionary] = []
	if target == null or not target.alive or target.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	if not Stealth.sees(target, actor, arena, clock.tick):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_cannot_perceive"})
		return events
	events.append({"type": "vibe_projected", "actor": actor.id, "target": target.id,
		"mode": mode, "level": int(action.get("level", 1))})
	if mode == "fear":
		events.append_array(_knockback_away(target, actor))
		events.append_array(EnemyAI.reduce_antagonism(
			target, actor.id, float(spec.get("fear_calm", 0.0)), "fear"))
	else:
		events.append_array(EnemyAI.add_antagonism(
			target, actor.id, float(spec.get("charm_fixate", 0.0)), "fixation"))
		events.append_array(_free_reposition(actor, action,
			int(spec.get("charm_reposition", 1)), "vibe_reposition"))
		_face_along(target, target.position, actor.position)
		events.append({"type": "vibe_fixated", "actor": actor.id, "target": target.id,
			"facing": target.facing})
		var until: int = clock.tick + int(spec.get("exposed_ticks", 2))
		target.exposed_until_tick = maxi(target.exposed_until_tick, until)
		events.append({"type": "vibe_exposed", "actor": actor.id, "target": target.id,
			"until_tick": until})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "vibe_control")), "result": "ok", "rounds": 0})
	return events


## hype_surge (play_to_the_camera, batch D): spends ONE Camera-Call stack and
## opens the party-wide surge window. The spend + window live in HypeEngine
## (open_surge — the same camera_calls_used ledger the spotlight spends); the
## resolver re-checks the live premise (stacks can be spent and a window can
## open between declare and resolution — same-tick simultaneity) and reports
## a fizzle as the honest invalidation: the Moment was spent either way.
## until_tick = this tick + 1 + the L2-4 duration rows — the window covers
## event batches through the actor's next Moment at L1 (CombatSim's
## expire_surge owns the boundary).
func _resolve_hype_surge(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	if hype == null:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "no_hype_engine"})
		return events
	if actor.team == "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "teamless"})
		return events
	var until_tick: int = clock.tick + 1 + int(spec.get("surge_bonus_moments", 0))
	var stacks_total: int = int(actor.derived_stats().get("camera_call_stacks", 0))
	var opened: Array = hype.open_surge(actor.id, actor.team, until_tick,
		int(spec.get("surge_multiplier", 2)), stacks_total)
	var started: bool = false
	for ev: Variant in opened:
		var event: Dictionary = ev
		events.append(event)
		if String(event.get("type", "")) == "hype_surge_started":
			started = true
	if started:
		events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": String(action.get("key", "play_to_the_camera")), "result": "ok", "rounds": 0})
	else:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill",
			"reason": String((events[0] as Dictionary).get("reason", "surge_wasted"))})
	return events


## sustained_channel (telekinesis, batch D). GRIP: the channel opens — the
## actor's channeling record + the target's held_by mirror; the actor is now
## Exposed (ExposureEngine reads the channel) and rooted, the target
## movement-locked. SUSTAIN: the per-Moment upkeep — re-checks the premise
## LIVE (target there, within the GRIP's stored range, LOS — a target yanked
## out of range or a door closing snaps the grip: release + invalidation),
## stamps sustained_tick (the lapse authority CombatSim reads at tick end),
## and optionally DRAGS the target one hex (forced movement: wall/bounds/
## can/body-honest, re-checked live — a blocked drag fizzles while the
## sustain holds; the dragged body's facing never changes, R30 involuntary).
## Ending: release declare (free), abandoning via another scheduled declare,
## the upkeep lapse, or the CombatSim sweep (actor damaged / grappled /
## helpless / either side down) — every path funnels through
## release_channel, so the mirror can never dangle.
func _resolve_sustained_channel(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var key := String(action.get("key", "telekinesis"))
	var events: Array[Dictionary] = []
	if bool(action.get("sustain", false)):
		if actor.channeling.is_empty():
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "not_channeling"})
			return events
		var held: CombatantState = combatants.get(String(actor.channeling.get("target", "")))
		if held == null or not held.alive or held.removed_from_play:
			events.append_array(release_channel(actor, "target_gone"))
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
			return events
		var grip_reach: int = int(actor.channeling.get("range", int(spec.get("grip_range", 10))))
		if CombatantState.hex_distance(actor.position, held.position) > grip_reach:
			events.append_array(release_channel(actor, "target_left_range"))
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_left_range"})
			return events
		if not Stealth.has_los(arena, actor.position, held.position):
			events.append_array(release_channel(actor, "lost_line_of_sight"))
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "lost_line_of_sight"})
			return events
		actor.channeling["sustained_tick"] = clock.tick
		events.append({"type": "telekinesis_sustained", "actor": actor.id, "target": held.id})
		if action.has("drag_to"):
			var dt: Array = action["drag_to"]
			var to := Vector2i(int(dt[0]), int(dt[1]))
			var from: Vector2i = held.position
			# Tier-2 wave 1 (phantom_grasp): the drag walks the hex line one
			# hex at a time up to the spec limit, stopping early at walls/
			# bounds/cans/bodies (the grapple-drag walk); telekinesis' limit
			# is 1, so its single-step behavior is byte-identical. R30:
			# forced movement — the dragged body's facing never changes.
			var limit: int = maxi(1, int(spec.get("drag", 1)))
			var steps: int = 0
			while steps < limit and held.position != to:
				var lane: Array[Vector2i] = HexGeometry.line(held.position, to)
				if lane.size() < 2:
					break
				var next: Vector2i = lane[1]
				if _movement_blocked_reason(held, next) != "":
					break
				held.position = next
				steps += 1
			if steps > 0:
				events.append({"type": "telekinesis_dragged", "actor": actor.id,
					"target": held.id, "from": [from.x, from.y],
					"to": [held.position.x, held.position.y]})
			else:
				events.append({"type": "telekinesis_drag_blocked", "actor": actor.id,
					"target": held.id, "to": [to.x, to.y]})
		events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
			"key": key, "result": "ok", "rounds": 0})
		return events
	# --- GRIP (instant, cost 1) — live premise re-checks in the batch-C style.
	var target: CombatantState = _first_target(action)
	if target == null or not target.alive or target.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	if not actor.channeling.is_empty():
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "already_channeling"})
		return events
	if target.held_by != "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "already_held"})
		return events
	if actor.grappling != "" or actor.grappled_by != "":
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "grappled"})
		return events
	var reach: int = int(spec.get("grip_range", 10))
	if CombatantState.hex_distance(actor.position, target.position) > reach:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_left_range"})
		return events
	if not _channel_can_see(actor, target):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_not_visible"})
		return events
	actor.channeling = {
		"key": key,
		"target": target.id,
		"range": reach,
		"sustained_tick": clock.tick,
	}
	# Tier-2 wave 1 (phantom_grasp — S10-a, OQ1 RULED): a spec-declared grip
	# type marks the channel as a trained HOLD on the R9 gate set — the
	# "psychic" value routes the escape contest to the holder's MIND
	# (escape_holder_stat). Only-when-set: telekinesis' channel record (and
	# every legacy hash over it) is byte-identical without the key.
	if spec.has("grip"):
		actor.channeling["grip"] = String(spec["grip"])
	target.held_by = actor.id
	events.append({"type": "telekinesis_grip", "actor": actor.id, "target": target.id,
		"range": reach})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": key, "result": "ok", "rounds": 0})
	return events


## Batch D (telekinesis): the ONE release seam — clears the channel and the
## held-by mirror together and says why. [] when no channel is live, so every
## caller (voluntary release, abandon-on-declare, the upkeep lapse, the
## CombatSim break sweep) can call it unconditionally.
func release_channel(actor: CombatantState, reason: String) -> Array[Dictionary]:
	if actor.channeling.is_empty():
		return []
	var target_id := String(actor.channeling.get("target", ""))
	var target: CombatantState = combatants.get(target_id)
	if target != null and target.held_by == actor.id:
		target.held_by = ""
	actor.channeling = {}
	return [{"type": "telekinesis_released", "actor": actor.id, "target": target_id,
		"reason": reason}]


## True for a sustained_channel skill declare — the one scheduled shape that
## does NOT abandon a live channel (a second grip already rejected at the
## validator, so anything reaching the declare mutate IS the sustain).
func _is_channel_sustain(kind: String, action: Dictionary) -> bool:
	if kind != "skill":
		return false
	var spec: Dictionary = SkillBook.mechanics(String(action.get("key", "")), int(action.get("level", 1)))
	return String(spec.get("archetype", "")) == "sustained_channel"


## item_flow (juggling, batch D): the transfer itself. Free-slot instant —
## live premise re-checks mirror the declare gate (both ends alive, the item
## still where it was, the G8 disarm gate still true — a same-tick pickup or
## death makes the flow fizzle honestly). The item DICT moves whole (magazine
## state and all — it is the same object, re-keyed to the new holder) and
## lands un-dropped: a caught item is in hand, whatever the floor said.
func _resolve_item_flow(actor: CombatantState, entry: Dictionary, spec: Dictionary) -> Array[Dictionary]:
	var action: Dictionary = entry["action"]
	var events: Array[Dictionary] = []
	var from_id := String(action.get("from", actor.id))
	var to_id := String(action.get("to", actor.id))
	var source: CombatantState = combatants.get(from_id)
	var dest: CombatantState = combatants.get(to_id)
	var other: CombatantState = source if from_id != actor.id else dest
	if source == null or dest == null or not source.alive or source.removed_from_play \
			or not dest.alive or dest.removed_from_play:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "target_gone"})
		return events
	var item_key := String(action.get("item", ""))
	var item: Dictionary = source.items.get(item_key, {})
	if item.is_empty():
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "no_such_item"})
		return events
	if from_id == actor.id and bool(item.get("dropped", false)):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "item_dropped"})
		return events
	var disarm: bool = from_id != actor.id and other != null and other.team != actor.team
	if disarm and not bool(item.get("dropped", false)):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "item_wielded"})
		return events
	if dest.items.has(item_key):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "skill", "reason": "already_carrying"})
		return events
	source.items.erase(item_key)
	if bool(item.get("dropped", false)):
		item["dropped"] = false
	dest.items[item_key] = item
	events.append({"type": "item_passed", "actor": actor.id, "item": item_key,
		"from": from_id, "to": to_id, "disarm": disarm,
		"range": int(spec.get("pass_range", 5))})
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "skill",
		"key": String(action.get("key", "juggling")), "result": "ok", "rounds": 0})
	return events


## Batch-A knockback (generalized from _dash_knock_aside): shove `target` ONE
## hex directly AWAY from `from_actor` (the origin→target ray's nearest fixed
## direction; ties break along the canonical order). Wall / bounds / trash-can
## / living-body blocked = no displacement (the shove stops honestly) — and NO
## prone is implied: unlike the dash's knock-aside, a plain knockback only
## displaces unless a ladder explicitly says otherwise. R30: INVOLUNTARY
## displacement — the victim's facing never changes (getting shoved does not
## spin you around; the update table's explicit exclusion).
func _knockback_away(target: CombatantState, from_actor: CombatantState) -> Array[Dictionary]:
	if not target.alive or target.removed_from_play:
		return []
	var idx: int = HexGeometry.direction_index(from_actor.position, target.position)
	if idx < 0:
		return []  # same hex — no direction to push along
	var from: Vector2i = target.position
	var to: Vector2i = from + HexGeometry.DIRECTIONS[idx]
	var displaced: bool = _movement_blocked_reason(target, to) == ""
	if displaced:
		target.position = to
	return [{
		"type": "knocked_back", "combatant": target.id, "by": from_actor.id,
		"from": [from.x, from.y],
		"to": [to.x, to.y] if displaced else [from.x, from.y],
		"displaced": displaced,
	}]


## The deterministic "legs" part for the shockwave's low sweep: first
## non-destroyed part key (sorted) containing "leg"; a legless body takes the
## wave on its torso line.
func _first_leg_part(c: CombatantState) -> String:
	var keys: Array = c.parts.keys()
	keys.sort()
	for pk: Variant in keys:
		if String(pk).contains("leg") and not bool((c.parts[pk] as Dictionary).get("destroyed", false)):
			return String(pk)
	return ai.torso_line_part(c)


## The feinted actor's next scheduled action collapses: it is invalidated and
## replaced by a Forced Action – Tool (rolled, emitted, queued), exactly like an
## invalidated windup. Clears the flag so only the NEXT action is affected.
## F3 (batch B): the collapse TABLE is parameterized at the shared helper —
## this feint path DELIBERATELY keeps Tool (the fumbled-response fiction);
## counter_surge's windup cut is the Body-table collapse.
## Skill-feel pass: the payoff moment also emits an ATTRIBUTED feint_fallout
## event ("actor" = the feinter who set it up, "victim" = whose action just
## crumbled, "kind"/"key" = what failed) so the HUD can announce the payoff
## loudly instead of burying it in the collapse plumbing.
func _collapse_feinted_action(actor: CombatantState, kind: String, key: String, forced_queue: Array[Dictionary]) -> Array[Dictionary]:
	var feinter: String = actor.feint_by
	actor.feint_forced = false
	actor.feint_by = ""
	var events: Array[Dictionary] = [{
		"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": "feinted",
	}]
	events.append({
		"type": "feint_fallout",
		"actor": feinter, "victim": actor.id, "kind": kind, "key": key,
	})
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
## content-pass follow-up — see TODO). Never repositions while grappled — or,
## batch D, while telekinetically held (movement actions are locked).
func _free_reposition(actor: CombatantState, action: Dictionary, max_spaces: int, event_type: String) -> Array[Dictionary]:
	if action.has("reposition_to") and actor.grappled_by == "" and actor.grappling == "" \
			and actor.held_by == "":
		var rt: Array = action["reposition_to"]
		var to := Vector2i(int(rt[0]), int(rt[1]))
		var dist: int = CombatantState.hex_distance(actor.position, to)
		# KAN-5: a reposition into a wall/bounds/can is no reposition — the
		# actor holds position (the unmoved event below), the skill still lands.
		if dist >= 1 and dist <= max_spaces \
				and (arena == null or not arena.blocks_movement(to)):
			# R30: a resolved reposition is voluntary movement — face it.
			_face_along(actor, actor.position, to)
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

	# Wave 2b death-spin beat gate: a chew/spin beat resolves only while the
	# HOLD is still live (the LIVE grip re-check _resolve_grapple_suffocate
	# uses — a same-tick release-on-5 or R9 escape that resolved earlier in the
	# batch makes the jaws close on air: invalidated, no strike, no Tool roll).
	if String(action.get("death_spin_beat", "")) != "" \
			and _death_spin_beat_stale(actor, action):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": "grip_lost"})
		return events

	# Windups re-check range & validity against the tick-start snapshot (R2).
	# Decision #31: an area action re-checks its REAL SHAPE instead of plain
	# range — the cone re-evaluates its committed arc per target (leaving the
	# arc dodges the sweep for THAT target; an emptied sweep collapses), and
	# the dash re-validates + walks its committed charge lane.
	if is_windup:
		var shape: Dictionary = action.get("area_shape", {})
		var shape_kind := String(shape.get("kind", ""))
		var original_first: String = ""
		if not targets.is_empty():
			original_first = String((targets[0] as Dictionary).get("id", ""))
		var invalid_reason: String = _windup_invalid_reason(actor, action, item, snapshot, shape_kind)
		if invalid_reason == "" and shape_kind == "cone":
			events.append_array(_recheck_cone_targets(actor, action, snapshot, shape))
			targets = action.get("targets", [])
			if targets.is_empty():
				invalid_reason = "left_area"  # every target escaped the arc
		if invalid_reason == "" and shape_kind == "line":
			var charge: Dictionary = _resolve_dash_charge(actor, action, snapshot, shape)
			var charge_events: Array[Dictionary] = charge["events"]
			events.append_array(charge_events)
			invalid_reason = String(charge["invalid"])
			if invalid_reason == "" and bool(charge["stopped_short"]):
				# An honest MISS, not a collapse: the boss spent the Moment
				# charging and was stopped out of reach — no strike, no Tool roll.
				events.append({
					"type": "action_resolved", "actor": actor.id, "kind": kind,
					"key": String(action.get("key", String(action.get("item", "")))),
					"result": "stopped_short", "halved": false, "rounds": 0,
				})
				return events
		if invalid_reason != "":
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": kind, "reason": invalid_reason})
			var collapse: Dictionary = ForcedAction.roll(ForcedAction.TABLE_TOOL, rng)
			events.append(ForcedAction.make_event(actor.id, collapse, "invalidated_windup"))
			# The original target escaped the effect entirely — a Collateral
			# consequence must not hit them (they dodged), so exclude them.
			forced_queue.append({"actor": actor.id, "rolled": collapse, "ctx": {
				"part": acting_part, "target": original_first,
			}})
			return events

	# Condition-driven Forced Action – Body (bleeding T2+, crushed T1, exhausted T3...).
	if cond.forced_body_required(actor, acting_part):
		var body: Dictionary = _forced_body_roll(actor, "condition_forced_body")
		events.append_array(body["events"])
		if not bool(body.get("negated", false)):  # S5-d veto queues nothing
			forced_queue.append({"actor": actor.id, "rolled": body["rolled"], "ctx": {"part": acting_part}})

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

	# Wave 2d — the phase-5 MERGED death-spin beat ("death spin costs 2
	# Moments"): the CHEW's arm rounds ride the SAME declare as the spin-kill
	# and fire FIRST (grab -> chew+spin in one Moment), each through the normal
	# R14 gate exactly like the 3-beat chew. Negated by Whiff with the rest of
	# the action; a stale grip never reaches here (the beat gate above). Fired
	# before the empty-targets exit so an armless/torso-less victim still gets
	# whichever half applies.
	if not whiffed and bool(action.get("death_spin_merged", false)):
		var chew_arms: Array = []
		for chew_entry: Variant in action.get("chew_targets", []) as Array:
			var ct: Dictionary = chew_entry
			var chew_target: CombatantState = combatants.get(String(ct.get("id", "")))
			if chew_target == null:
				continue
			chew_arms.append(String(ct.get("part", "")))
		events.append({
			"type": "death_spin_chew", "combatant": actor.id,
			"victim": String((ai.death_spins.get(actor.id, {}) as Dictionary).get("victim", "")),
			"arms": chew_arms, "merged": true,
		})
		for chew_entry: Variant in action.get("chew_targets", []) as Array:
			var ct: Dictionary = chew_entry
			var chew_target: CombatantState = combatants.get(String(ct.get("id", "")))
			if chew_target == null:
				continue
			events.append_array(_strike_round(chew_target, String(ct.get("part", "")),
				"crushed", EnemyAI.CHEW_CRUSHED, {"kind": "attack", "key": "death_spin_chew"}, actor))

	if whiffed or targets.is_empty() or damage.is_empty():
		# Wave 2b: an armless victim still gets chewed ON (no arm rounds to
		# fire) and a spin with nothing attackable still flings — the beat
		# advances/finishes off the empty-targets exit too.
		if not whiffed:
			events.append_array(_apply_death_spin_beat(actor, action))
			# Wave 3d: a really-resolved burn cone washes its arc even with no
			# combatant targets — trash cans in it still catch (a Whiff negates).
			events.append_array(_ignite_cans_in_cone(actor, action, snapshot, damage, amount))
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
	# Wave 2b: the dash's authored "knock aside" becomes real — a CONNECTED
	# target (its strike round produced a damage_applied: not dodged, not
	# surface-blocked, not fire-healed; a robustness-blocked 0 still connected
	# — the charge's mass hit, even if no wound opened) is shoved off the lane
	# and knocked prone. A dodged dash sidesteps instead (mutually exclusive:
	# the dodge returns before damage_applied). Stopped-short never gets here.
	if bool(action.get("knock_aside", false)) and not targets.is_empty():
		var shape: Dictionary = action.get("area_shape", {})
		if String(shape.get("kind", "")) == "line":
			var knock_target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
			if knock_target != null and _hit_landed(events, knock_target.id):
				events.append_array(_dash_knock_aside(knock_target, actor, HexGeometry.to_set(_shape_lane(shape))))
	# Wave 3d (KAN-5): a resolved burn cone's flame also washes over the arc's
	# trash cans — after the combatant rounds (people first, environment
	# second), through the accumulate-or-pop model (_ignite_cans_in_cone).
	events.append_array(_ignite_cans_in_cone(actor, action, snapshot, damage, amount))
	# Wave 2b: a really-resolved chew/spin beat advances/finishes the sequence.
	events.append_array(_apply_death_spin_beat(actor, action))
	events.append({
		"type": "action_resolved", "actor": actor.id, "kind": kind,
		"key": String(action.get("key", String(action.get("item", "")))),
		"result": "ok", "halved": unmet, "rounds": rounds,
	})
	return events


## Whole-action windup re-check (R2). Decision #31 splits area actions off:
## `shape_kind` "cone" skips everything but the disarmed gate (the per-target
## arc re-check in _recheck_cone_targets replaces the whole-action gate);
## "line" keeps the target/head gates but skips the plain range check (the
## committed lane in _resolve_dash_charge is the real geometry). "" (the
## overwhelming default) is today's behavior, unchanged.
func _windup_invalid_reason(actor: CombatantState, action: Dictionary, item: Dictionary, snapshot: Dictionary, shape_kind: String = "") -> String:
	if not item.is_empty() and (bool(item.get("dropped", false)) or actor.unarmed_until_tick > clock.tick):
		return "disarmed"
	if shape_kind == "cone":
		return ""
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
		# R20 (wave 4c): a hostile target that slipped into stealth during the
		# windup VANISHED from the attacker's fiction — the aimed windup
		# collapses exactly like the R2 out-of-range escape. Plain aimed
		# actions only: a committed charge LANE is physical geometry (bodies on
		# it get hit by hex, stealthed or not — physicality over information),
		# and cones re-check per target in _recheck_cone_targets, which keeps
		# stealthed bodies in the arc for the same reason.
		if shape_kind == "" and bool(snap.get("stealthed", false)) and target.team != actor.team:
			return "target_stealthed"
		if shape_kind != "line":
			var target_pos: Array = snap.get("position", [target.position.x, target.position.y])
			var a := Vector2i(int(actor_pos[0]), int(actor_pos[1]))
			var b := Vector2i(int(target_pos[0]), int(target_pos[1]))
			if CombatantState.hex_distance(a, b) > reach:
				return "out_of_range"
		var part_key := String(t.get("part", ""))
		if part_key.contains("head") and not bool(action.get("bypass_head_gate", false)):
			var targetable: bool = bool(snap.get("exposed", false)) \
				or bool(snap.get("helpless", false)) \
				or bool(snap.get("overwhelmed", false))
			if not targetable:
				return "head_not_targetable"
	return ""


## Decision #31 cone windup re-check (R2: leaving the AREA before resolution
## dodges it — per target, since a sweep is multi-target): recompute the
## committed arc from the actor's SNAPSHOT hex + the declared aim direction and
## EXCLUDE every target whose snapshot hex is outside it (or who died, or whose
## head-gate closed) — each exclusion is exactly the out-of-range windup dodge,
## applied per head. rounds/rpm shrink with the list (one round per swept
## target, the v1 multi-target model); survivors still get burned. The caller
## collapses the whole windup only when EVERY target escaped.
func _recheck_cone_targets(actor: CombatantState, action: Dictionary, snapshot: Dictionary, shape: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var toward_raw: Array = shape.get("toward", [])
	var size: int = int(shape.get("size", 0))
	if toward_raw.size() != 2 or size <= 0:
		return events  # malformed shape — nothing to re-check against
	var actor_snap: Dictionary = snapshot.get(actor.id, {})
	var actor_pos: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
	var origin := Vector2i(int(actor_pos[0]), int(actor_pos[1]))
	var dir := Vector2i(int(toward_raw[0]), int(toward_raw[1]))
	var arc: Dictionary = HexGeometry.to_set(HexGeometry.cone(origin, origin + dir, size))
	var remaining: Array = []
	for target_entry: Variant in action.get("targets", []) as Array:
		var t: Dictionary = target_entry
		var target: CombatantState = combatants.get(String(t.get("id", "")))
		var reason: String = ""
		if target == null:
			reason = "target_missing"
		else:
			var snap: Dictionary = snapshot.get(target.id, {})
			var target_pos: Array = snap.get("position", [target.position.x, target.position.y])
			if not bool(snap.get("alive", false)):
				reason = "target_dead"
			elif not arc.has(Vector2i(int(target_pos[0]), int(target_pos[1]))):
				reason = "left_area"
			elif String(t.get("part", "")).contains("head") \
					and not bool(action.get("bypass_head_gate", false)) \
					and not (bool(snap.get("exposed", false))
					or bool(snap.get("helpless", false)) or bool(snap.get("overwhelmed", false))):
				reason = "head_not_targetable"
		if reason == "":
			remaining.append(t)
		else:
			events.append({
				"type": "windup_target_escaped", "actor": actor.id,
				"target": String(t.get("id", "")), "reason": reason,
			})
	action["targets"] = remaining
	action["rounds"] = mini(int(action.get("rounds", remaining.size())), remaining.size())
	action["rpm"] = maxi(1, mini(int(action.get("rpm", maxi(1, remaining.size()))), maxi(1, remaining.size())))
	return events


## Decision #31 dash charge (retires "line resolves as plain reach"): the dash
## is an honest CHARGE along its committed lane (the declared area_shape, built
## by EnemyAI from HexGeometry.line_extended). All geometry evaluates against
## the tick-start SNAPSHOT (R2 simultaneity — same-tick movement neither dodges
## nor blocks); only the dasher's position mutation is live. Steps:
##  1. lane validity: the dasher must still stand on lane[0] (lane_lost
##     otherwise — no mechanic moves a winding-up dasher today, so this is a
##     safety) and the target's snapshot hex must still be ON the lane beyond
##     index 0 — a target that left the committed corridor dodged the windup
##     (left_lane -> the standard invalidation collapse, like out_of_range).
##  2. charge: the dasher advances along the lane toward the hex
##     adjacent-before the target, stopping BEFORE the first hex occupied by a
##     living, in-play combatant (snapshot hexes) — a charge is a run, not a
##     teleport: bodies block it, and an interloper on the lane SHIELDS the
##     declared target (v1: only declared targets are ever hit).
##  3. contact: stopped short of adjacency = an honest MISS (dash_stopped_short;
##     the Moment was spent charging, no strike, no Tool collapse); reaching
##     adjacency lets the strike resolve through the normal round (R22 dodge
##     ladder unchanged).
## Wave 2d — a BENT lane ("dash can change direction mid-run", phase 4+) walks
## through this function UNCHANGED: the committed lane list IS the geometry, so
## the occupation stop applies on either segment, leaving the bent corridor
## dodges the windup (left_lane), and the adjacent-before rule reads the lane
## order. The dash_charged event surfaces the bend point when one was declared.
## Returns {"invalid": String ("" = ok), "stopped_short": bool, "events": [...]}.
func _resolve_dash_charge(actor: CombatantState, action: Dictionary, snapshot: Dictionary, shape: Dictionary) -> Dictionary:
	var out_events: Array[Dictionary] = []
	var lane: Array[Vector2i] = _shape_lane(shape)
	var actor_snap: Dictionary = snapshot.get(actor.id, {})
	var actor_pos: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
	var origin := Vector2i(int(actor_pos[0]), int(actor_pos[1]))
	if lane.size() < 2 or origin != lane[0]:
		return {"invalid": "lane_lost", "stopped_short": false, "events": out_events}
	var targets: Array = action.get("targets", [])
	if targets.is_empty():
		return {"invalid": "target_missing", "stopped_short": false, "events": out_events}
	var target: CombatantState = combatants.get(String((targets[0] as Dictionary).get("id", "")))
	if target == null:
		return {"invalid": "target_missing", "stopped_short": false, "events": out_events}
	var target_snap: Dictionary = snapshot.get(target.id, {})
	var target_pos_raw: Array = target_snap.get("position", [target.position.x, target.position.y])
	var target_pos := Vector2i(int(target_pos_raw[0]), int(target_pos_raw[1]))
	var t_idx: int = lane.find(target_pos)
	if t_idx < 1:
		return {"invalid": "left_lane", "stopped_short": false, "events": out_events}
	# Snapshot occupancy: everyone alive and in play except the dasher and the
	# declared target (the charge stops before the target via stop_idx anyway).
	var occupied: Dictionary = {}
	var ids: Array = snapshot.keys()
	ids.sort()
	for id: Variant in ids:
		if String(id) == actor.id or String(id) == target.id:
			continue
		var snap: Dictionary = snapshot[id]
		if not bool(snap.get("alive", false)):
			continue
		var pos_raw: Array = snap.get("position", [])
		if pos_raw.size() == 2:
			occupied[Vector2i(int(pos_raw[0]), int(pos_raw[1]))] = true
	var stop_idx: int = t_idx - 1
	var final_idx: int = 0
	for k: int in range(1, stop_idx + 1):
		if occupied.has(lane[k]):
			break
		final_idx = k
	# R30: the dash charge faces the LANE direction at the dasher's final hex —
	# toward the next lane hex (for a bent/bounced corridor: the direction of
	# the segment the charge ended on). Applies on a stopped-short charge too
	# (the Moment was spent charging down that lane); an INVALIDATED lane
	# (lane_lost / left_lane) returned above and keeps the declare-time facing.
	if final_idx + 1 < lane.size():
		_face_along(actor, lane[final_idx], lane[final_idx + 1])
	if final_idx > 0:
		var from: Vector2i = actor.position
		actor.position = lane[final_idx]
		var charged: Dictionary = {
			"type": "dash_charged", "actor": actor.id,
			"from": [from.x, from.y], "to": [lane[final_idx].x, lane[final_idx].y],
			"hexes": final_idx,
		}
		if shape.has("bend"):
			charged["bend"] = (shape.get("bend", []) as Array).duplicate()
		# Wave 3d: the committed wall-bounce points ride the charge event
		# (like the bend) — the ricochet is spectator-visible.
		if shape.has("bounces"):
			charged["bounces"] = (shape.get("bounces", []) as Array).duplicate(true)
		out_events.append(charged)
		# Wave 3d: a charge SMASHES straight through trash cans — every can on
		# the corridor the dasher actually traversed is destroyed (no bounce
		# off cans, no explosion: a smash is not a burn touch). Re-queried per
		# hex because each removal reindexes the object store.
		if arena != null:
			for k: int in range(1, final_idx + 1):
				var can_idx: int = arena.object_index_at(lane[k])
				if can_idx >= 0:
					var can: Dictionary = arena.objects[can_idx]
					arena.objects.remove_at(can_idx)
					out_events.append({
						"type": "trash_can_smashed",
						"key": String(can.get("key", "")),
						"position": (can.get("position", []) as Array).duplicate(),
						"by": actor.id,
					})
	if final_idx < stop_idx:
		out_events.append({
			"type": "dash_stopped_short", "actor": actor.id, "target": target.id,
			"at": [lane[final_idx].x, lane[final_idx].y],
			"distance": HexGeometry.distance(lane[final_idx], target_pos),
		})
		return {"invalid": "", "stopped_short": true, "events": out_events}
	return {"invalid": "", "stopped_short": false, "events": out_events}


## The committed lane hexes off an area_shape (serialization-safe int pairs).
static func _shape_lane(shape: Dictionary) -> Array[Vector2i]:
	var lane: Array[Vector2i] = []
	for pair: Variant in shape.get("lane", []) as Array:
		var p: Array = pair
		if p.size() == 2:
			lane.append(Vector2i(int(p[0]), int(p[1])))
	return lane


## Wave 2d — the R22 sidestep's exclusion set against a possibly-BENT lane:
## "the sidestep steps off whichever segment the dodger stood on". A straight
## lane (no bend) is one segment — today's behavior unchanged. A bent lane
## splits at the bend hex (which belongs to BOTH segments; the second-segment
## check runs first, deterministically): the dodger standing on segment 2 need
## only leave segment 2 (a segment-1 hex is a legal sidestep), and vice versa.
## A dodger on neither segment (moved off-lane already) keeps the full lane.
static func _sidestep_lane(shape: Dictionary, dodger_pos: Vector2i) -> Array[Vector2i]:
	var lane: Array[Vector2i] = _shape_lane(shape)
	var bend_raw: Array = shape.get("bend", [])
	if bend_raw.size() != 2:
		return lane
	var bend := Vector2i(int(bend_raw[0]), int(bend_raw[1]))
	var bend_idx: int = lane.find(bend)
	if bend_idx < 0:
		return lane
	var segment_one: Array[Vector2i] = []
	var segment_two: Array[Vector2i] = []
	for k: int in range(lane.size()):
		if k <= bend_idx:
			segment_one.append(lane[k])
		if k >= bend_idx:
			segment_two.append(lane[k])
	if segment_two.has(dodger_pos):
		return segment_two
	if segment_one.has(dodger_pos):
		return segment_one
	return lane


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


# ------------------------------------------------ retarget guard (batch B)

## Does the action AIM at this combatant — i.e. name it in its declared target
## rows ("targets" for attack/skill shapes, the single "target" field for the
## grapple/reaction shapes)? Area geometry (cones, charge lanes, blasts),
## death-spin chew rounds and environment hits carry no row naming the victim
## — physicality over information: you are hit where you stand, and a
## bodyguard answers AIMED strikes only (documented v1 line).
static func _action_aims_at(action: Dictionary, combatant_id: String) -> bool:
	for row: Variant in action.get("targets", []) as Array:
		if String((row as Dictionary).get("id", "")) == combatant_id:
			return true
	return String(action.get("target", "")) == combatant_id


## Is the iron stance GENUINELY held right now — anchored on the declared hex
## and not Prone? The CombatSim _guard_checks sweep breaks a moved/prone/downed
## stance after every command; this live re-check keeps mid-resolution honesty
## (a knockback earlier in the same resolve batch already broke the ground
## hold, even before the sweep runs).
static func _iron_stance_live(c: CombatantState) -> bool:
	if c.iron_stance.is_empty():
		return false
	if bool(c.statuses.get("prone", false)):
		return false
	var anchor_raw: Array = c.iron_stance.get("anchor", [])
	return anchor_raw.size() == 2 \
		and c.position == Vector2i(int(anchor_raw[0]), int(anchor_raw[1]))


## The FIRST eligible guardian for a hit aimed at `ally` (sorted-id scan —
## deterministic; within one candidate the stance form is checked before the
## reaction form). {} when nobody qualifies. Eligibility, both forms: alive,
## in play, not Helpless (R7: cannot react), on the ally's NON-EMPTY team, not
## the ally, not the attacker, with an attackable torso line. Stance form
## (iron_stance): the stance live (anchored, not Prone) + the ally within its
## radius — NO reaction cost (the stance's value). Reaction form (intercept):
## the guard armed on THIS ally (armed_primes + the guard record), the ally
## within guard range, and the guardian's reaction slot FREE — the existing
## one-reaction-per-tick rule prices every interception.
func _find_guardian(ally: CombatantState, attacker: CombatantState) -> Dictionary:
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		if c.id == ally.id or c.id == attacker.id:
			continue
		if not c.alive or c.removed_from_play or c.is_helpless(clock.tick):
			continue
		if c.team == "" or c.team != ally.team:
			continue
		if ai.torso_line_part(c) == "":
			continue  # nothing attackable — no body to put in the way
		if _iron_stance_live(c) \
				and CombatantState.hex_distance(c.position, ally.position) <= int(c.iron_stance.get("radius", 1)):
			return {"guardian": c, "mode": "stance"}
		if not c.guard.is_empty() and String(c.guard.get("ally", "")) == ally.id \
				and bool(c.armed_primes.get("intercept", false)) \
				and not c.reaction_used \
				and CombatantState.hex_distance(c.position, ally.position) <= int(c.guard.get("range", 1)):
			return {"guardian": c, "mode": "reaction"}
	return {}


## The interception decision for one strike round ({} = the hit proceeds
## unmoved). Solo rounds decide fresh per hit; a MERGED (R15) group decides
## ONCE — the first member's check-in stores the verdict on the group
## (intercept_decided / intercept_to / intercept_part / intercept_reduction,
## plus the retargeted target_id/part for _merge_apply and the flush path) and
## later members follow it without paying again. The intercepted hit lands on
## the guardian's TORSO-LINE part (deterministic locus — the body thrown in
## the way; never the guardian's Head, so the interception can never bypass
## the guardian's own head gate). The reaction form pays the guardian's
## reaction slot AT the decision; the stance form pays nothing.
func _intercept_hit(group: Dictionary, target: CombatantState, part_key: String, action: Dictionary, attacker: CombatantState) -> Dictionary:
	if attacker == null or attacker.id == target.id:
		return {}
	if not group.is_empty() and bool(group.get("intercept_decided", false)):
		var stored_id := String(group.get("intercept_to", ""))
		if stored_id == "":
			return {}
		var stored: CombatantState = combatants.get(stored_id)
		if stored == null:
			return {}
		return {"guardian": stored, "part": String(group.get("intercept_part", "")),
			"reduction": int(group.get("intercept_reduction", 0)), "event": {}}
	if not _action_aims_at(action, target.id):
		return {}
	var pick: Dictionary = _find_guardian(target, attacker)
	if not group.is_empty():
		group["intercept_decided"] = true
		group["intercept_to"] = "" if pick.is_empty() else (pick["guardian"] as CombatantState).id
	if pick.is_empty():
		return {}
	var guardian: CombatantState = pick["guardian"]
	var mode := String(pick["mode"])
	var landing_part: String = ai.torso_line_part(guardian)
	var reduction: int = 0
	if mode == "reaction":
		guardian.reaction_used = true  # the per-hit price (one reaction per tick)
		reduction = int(guardian.guard.get("reduction", 0))
	var event: Dictionary = {
		"type": "hit_intercepted", "guardian": guardian.id, "ally": target.id,
		"attacker": attacker.id, "mode": mode,
		"part": landing_part, "original_part": part_key, "reduction": reduction,
	}
	if not group.is_empty():
		group["intercept_part"] = landing_part
		group["intercept_reduction"] = reduction
		group["target_id"] = guardian.id
		group["part"] = landing_part
	return {"guardian": guardian, "part": landing_part, "reduction": reduction, "event": event}


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
	# Looked up by the ORIGINAL declared target/part — an interception below
	# never changes the group's key, only where the merged hit lands.
	var group: Dictionary = _merge_group_for(action, target, part_key)
	# Batch B (retarget_guard — intercept / iron_stance): a hit AIMED at a
	# guarded ally (the action names them in its declared target rows — area
	# geometry, chews and environment hits are never "aimed") retargets to the
	# guardian HERE, at the TOP of the round. COMPOSITION (the batch's ruled
	# lines, documented verbatim):
	#  * the ORIGINAL target's dodge never rolls — the hit was taken before it;
	#  * the GUARDIAN does not dodge a hit it chose to take — the intercepted
	#    round skips every dodge-shaped escape, consuming ZERO rng (the R26
	#    skip discipline: the ai_rng stream is byte-identical to a fight where
	#    the check never existed);
	#  * an R26 UNDODGABLE hit may still be intercepted — interception is not
	#    a dodge (R26 forbids dodge-shaped ESCAPES; taking the hit on another
	#    body escapes nothing);
	#  * a MERGED (R15) hit retargets WHOLE — the group decides once at its
	#    first member's check-in (one reaction slot, one hit_intercepted
	#    event), later members follow the stored decision, and the ONE merged
	#    gate evaluates against the guardian.
	# The guardian's own robustness/resistances/immunities then apply and any
	# conditions land on the guardian — the round simply continues against the
	# new body. R30: the interception is involuntary-adjacent — the guardian's
	# facing NEVER changes (reactions/out-of-schedule strikes are off the
	# update table).
	# Tier-2 wave 2 (counterscript S1-b, [FROM row 8]): the per-source counter
	# immunity — while clock.tick < until_tick, a hit FROM the countered
	# source aimed at the counter-actor simply MISSES ("you already answered
	# it"). Composition, documented: checked at the TOP of the round, BEFORE
	# interception and every dodge — the hit never connects, so there is
	# nothing to retarget and nothing to dodge; ZERO rng is consumed (the R26
	# skip discipline — the ai_rng stream is byte-identical to a fight where
	# the check never existed); a merged member drops out like a dodged one;
	# the exclusion protects the AIMED counter-actor only — an interception
	# ONTO an immune guardian still lands (the guardian chose to take that
	# hit, the same override interception applies to dodges and R26).
	if attacker != null and clock.tick < int(target.counter_immunities.get(attacker.id, 0)):
		events.append({"type": "attack_immune", "combatant": target.id, "part": part_key,
			"source": attacker.id, "until_tick": int(target.counter_immunities[attacker.id])})
		if not group.is_empty():
			events.append_array(_merge_drop(group, target))
		return events
	var intercepted: bool = false
	var intercept_reduction: int = 0
	var interception: Dictionary = _intercept_hit(group, target, part_key, action, attacker)
	if not interception.is_empty():
		var intercept_event: Dictionary = interception.get("event", {})
		if not intercept_event.is_empty():
			events.append(intercept_event)
		target = interception["guardian"]
		part_key = String(interception["part"])
		intercepted = true
		intercept_reduction = int(interception.get("reduction", 0))
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
	# sum. R26 (owner 2026-07-25, decision #32): an action carrying the
	# data-driven "undodgable" flag skips EVERY dodge-shaped escape — the boss
	# threshold dodge AND the authored dodge/counters ladder — consuming ZERO
	# rng (a skipped check never touches the salted stream, so the ai_rng state
	# is byte-identical to a fight where the check never existed). Movement/
	# windup re-checks (leaving the arc/lane/radius) are elsewhere and stay the
	# honest counterplay.
	# Batch B: an INTERCEPTED round skips the whole dodge ladder — the guardian
	# chose to take this hit (composition rules at the interception seam above);
	# like the R26 skip, ZERO rng is consumed.
	if not intercepted and not bool(action.get("counter", false)) and not bool(action.get("undodgable", false)):
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
					events.append_array(_dash_dodge_riders(target, attacker, ability_dodge, action))
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
	# retarget_guard stance (iron_stance, batch B): the PERSISTENT, NON-consumed
	# flat reduction on covered-type damage the stancer takes — intercepted or
	# aimed at the stancer directly. Applied while the stance genuinely holds
	# (live anchor/prone re-check — mid-batch displacement is honest before the
	# CombatSim sweep runs), BEFORE brace so both stack: the stance is the
	# posture, the brace the flinch on top (order affects event numbers only —
	# both are flat).
	if reduced > 0 and _iron_stance_live(target) \
			and (target.iron_stance.get("types", []) as Array).has(condition_id):
		var stance_red: int = int(target.iron_stance.get("reduction", 0))
		if stance_red > 0:
			var before_stance: int = reduced
			reduced = maxi(0, reduced - stance_red)
			events.append({
				"type": "iron_stance_reduced", "combatant": target.id, "part": part_key,
				"reduction": stance_red, "condition": condition_id,
				"damage_before": before_stance, "damage_after": reduced,
			})
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
	# intercept L3+ (batch B): the per-interception flat reduction — "-N
	# PHYSICAL damage taken when intercepting" (Physical path only; the number
	# already rode the hit_intercepted event).
	if intercepted and intercept_reduction > 0 and is_physical and reduced > 0:
		reduced = maxi(0, reduced - intercept_reduction)
	events.append_array(cond.damage_part(target, part_key, reduced, "weapon", condition_id, clock.tick,
			attacker.id if attacker != null else ""))
	# self_stance (dance): the stance ends when its owner is hit (takes damage).
	if target.dancing and reduced > 0:
		events.append_array(_end_dance(target, "hit"))
	# R15/NQ2: record the landed hit for single-hit breach; a combined action's
	# linked strikes (shared combo_id) merge into one hit for the threshold.
	target.record_hit(String(action.get("combo_id", "")), reduced)
	# Wave 2b: "release if hit for 5" listens at this same single-hit seam — a
	# net hit (post-record, so a combo reads its merged running total) >= 5 on
	# a boss mid-death-spin forces the release and aborts the sequence.
	if reduced > 0:
		var hit_total: int = reduced
		var release_combo := String(action.get("combo_id", ""))
		if release_combo != "":
			hit_total = int(target.combo_hits_this_tick.get(release_combo, reduced))
		events.append_array(ai.check_death_spin_release(target, hit_total))
	# R23: net damage dealt to an AI-controlled combatant builds grudge on it,
	# keyed by the attacker (1:1 net-damage scale, PLACEHOLDER R14) — a hit
	# blocked to 0 builds nothing. EnemyAI's weighted targeting reads the score.
	if attacker != null and reduced > 0:
		events.append_array(EnemyAI.add_antagonism(target, attacker.id, float(reduced), "damage"))
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
				"attacker": attacker.id if attacker != null else "",  # R11 #14 v2 wound source
			}))
	return events


## R22 dash counters ladder riders on a SUCCESSFUL dash dodge: the sidestep
## rides ANY successful dodge (auto or rolled); the counterattack rides only a
## Reflexes >= counter_at auto-dodge. Both deterministic, both rng-free.
## Decision #31: the action's committed lane feeds the sidestep — dodging a
## charge means getting OFF ITS LANE.
func _dash_dodge_riders(dodger: CombatantState, dasher: CombatantState, ability_dodge: Dictionary, action: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if dasher == null:
		return events
	# Wave 2d: against a BENT lane the sidestep steps off whichever SEGMENT the
	# dodger stood on (_sidestep_lane) — the involuntary knock-aside keeps the
	# FULL bent lane as its exclusion (see _dash_knock_aside's caller).
	var lane_set: Dictionary = HexGeometry.to_set(_sidestep_lane(action.get("area_shape", {}) as Dictionary, dodger.position))
	events.append_array(_dash_sidestep(dodger, dasher, lane_set))
	var counter_at: int = int(ability_dodge.get("counter_at", 0))
	if counter_at > 0 and dodger.trait_total("reflexes") >= counter_at:
		events.append_array(_dash_counter(dodger, dasher))
	return events


## R22 1-hex sidestep, upgraded by decision #31: dodging a charge moves the
## dodger OFF THE LANE specifically — the first unoccupied hex in the fixed
## HEX_NEIGHBORS order that is NOT on the committed charge lane (the same
## deterministic first-fit rule as before, aimed at the real geometry). When
## the action carries no lane (an authored dodge block on a non-line action)
## the pre-#31 rule stands: the first free hex strictly INCREASING distance
## from the attacker. No qualifying free hex -> the dodge still negates, no
## displacement. R30: the sidestep is REFLEX displacement, not a chosen move —
## facing never changes (the update table's explicit exclusion).
func _dash_sidestep(dodger: CombatantState, dasher: CombatantState, lane_set: Dictionary) -> Array[Dictionary]:
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
		# KAN-5: a sidestep never lands on a wall/out-of-bounds/can hex; with
		# every candidate blocked the dodge still negates, no displacement
		# (the same no-qualifying-hex rule as before).
		if arena != null and arena.blocks_movement(candidate):
			continue
		if lane_set.is_empty():
			if CombatantState.hex_distance(candidate, dasher.position) <= from_d:
				continue
		elif lane_set.has(candidate):
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


## Wave 2b — the dash's authored "knock aside", now real: a target the charge
## CONNECTED with is displaced to the first free fixed-order neighbor OFF the
## committed lane (the involuntary sibling of the R22 sidestep's first-fit
## rule, decision #31 geometry) and knocked PRONE (the "aside" cost). No free
## off-lane neighbor: no displacement, still prone. A victim FELLED by the
## dash is down already (dead, not prone) — no knock-aside on a corpse. The
## charge rule itself is unchanged (wave 2a): the dasher stopped
## adjacent-before the target's SNAPSHOT hex, so after the shove it may
## legally stand adjacent to a now-empty hex — that is the documented
## interaction, not a bug.
func _dash_knock_aside(target: CombatantState, dasher: CombatantState, lane_set: Dictionary) -> Array[Dictionary]:
	if not target.alive or target.removed_from_play:
		return []
	var events: Array[Dictionary] = []
	var occupied: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == target.id or not other.alive or other.removed_from_play:
			continue
		occupied[other.position] = true
	var from: Vector2i = target.position
	var to: Vector2i = from
	var displaced: bool = false
	for neighbor: Vector2i in EnemyAI.HEX_NEIGHBORS:
		var candidate: Vector2i = from + neighbor
		if occupied.has(candidate) or lane_set.has(candidate):
			continue
		# KAN-5: a shove into a wall/bounds/can stops short — with no legal
		# off-lane neighbor the target stays put and is STILL knocked prone
		# (the pre-arena no-free-neighbor rule, walls composed in).
		if arena != null and arena.blocks_movement(candidate):
			continue
		to = candidate
		displaced = true
		break
	if displaced:
		target.position = to
	events.append({
		"type": "knocked_aside", "combatant": target.id, "by": dasher.id,
		"from": [from.x, from.y], "to": [to.x, to.y], "displaced": displaced,
	})
	if not bool(target.statuses.get("prone", false)):
		target.statuses["prone"] = true
		events.append({"type": "knocked_prone", "combatant": target.id,
			"source": dasher.id, "skill": "dash"})
		events.append_array(_end_dance(target, "knocked_prone"))
	return events


# ------------------------------------------------------ trash cans (wave 3d, KAN-5)

## A resolved BURN cone washes its committed arc over the arena's trash cans
## (canon off the authored flamethrower note: "trash cans explode at Burn 5
## (3 spaces, 2 Burn)"). Model (documented):
##  * arc = the declared area_shape (toward + size) from the actor's SNAPSHOT
##    hex — the same authority the windup re-check uses.
##  * each can in the arc ACCUMULATES the cone's per-round burn amount (post
##    R10 halving — the weakened flame is the weakened flame); at burn >=
##    Arena.TRASH_CAN_EXPLODE_AT it explodes. Accumulation is independent of
##    whether the combatant rounds landed — the flame washes the ground
##    regardless; only a Whiff negates the sweep (callers gate).
##  * phase-3 "flamethrower pops trash cans instantly" (cans_pop_instantly,
##    the ATTACKER's upgrade): a swept can explodes on the FIRST touch, no
##    accumulation — even a halved-to-0 flame still pops it (a touch is a
##    touch).
## Store-order iteration (the object array is command-stream state) keeps it
## deterministic; consumes ZERO rng on every path.
func _ignite_cans_in_cone(actor: CombatantState, action: Dictionary, snapshot: Dictionary, damage: Dictionary, amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if arena == null or arena.objects.is_empty():
		return events
	var shape: Dictionary = action.get("area_shape", {})
	if String(shape.get("kind", "")) != "cone":
		return events
	if ConditionEngine.normalize_condition_id(String(damage.get("type", ""))) != "burn":
		return events
	var toward_raw: Array = shape.get("toward", [])
	var size: int = int(shape.get("size", 0))
	if toward_raw.size() != 2 or size <= 0:
		return events
	var actor_snap: Dictionary = snapshot.get(actor.id, {})
	var actor_pos: Array = actor_snap.get("position", [actor.position.x, actor.position.y])
	var origin := Vector2i(int(actor_pos[0]), int(actor_pos[1]))
	var dir := Vector2i(int(toward_raw[0]), int(toward_raw[1]))
	var arc: Dictionary = HexGeometry.to_set(HexGeometry.cone(origin, origin + dir, size))
	var instant: bool = ai.has_upgrade(actor, "cans_pop_instantly")
	var explode_queue: Array[Dictionary] = []
	for obj: Dictionary in arena.objects:
		var pos_raw: Array = obj.get("position", [])
		var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
		if not arc.has(pos):
			continue
		if instant:
			explode_queue.append({"position": pos, "instant": true})
			continue
		if amount <= 0:
			continue  # a 0-burn wash accumulates nothing (and pops nothing)
		obj["burn"] = int(obj.get("burn", 0)) + amount
		events.append({
			"type": "trash_can_burned",
			"key": String(obj.get("key", "")),
			"position": [pos.x, pos.y],
			"added": amount, "burn": int(obj["burn"]),
			"by": actor.id,
		})
		if int(obj["burn"]) >= Arena.TRASH_CAN_EXPLODE_AT:
			explode_queue.append({"position": pos, "instant": false})
	events.append_array(_explode_cans(explode_queue, actor.id))
	return events


## Batch D (fire_ball) — the can-ignition family's BLAST-SHAPED sibling: a
## resolved burn BLAST washes its area over the arena's trash cans exactly
## like the cone wash (_ignite_cans_in_cone), swapping only the geometry —
## HexGeometry.blast(center, radius) for the committed arc. Same
## accumulate-or-pop model (each swept can accumulates the per-round burn
## amount; >= Arena.TRASH_CAN_EXPLODE_AT explodes through _explode_cans,
## cascades included), same instant-pop upgrade hook (a contestant never has
## it — carried for symmetry), same store-order determinism, ZERO rng, and
## ZERO arena behavior change — the arena still only holds the object state.
func _ignite_cans_in_blast(actor: CombatantState, center: Vector2i, radius: int, amount: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if arena == null or arena.objects.is_empty() or radius < 0:
		return events
	var area: Dictionary = HexGeometry.to_set(HexGeometry.blast(center, radius))
	var instant: bool = ai.has_upgrade(actor, "cans_pop_instantly")
	var explode_queue: Array[Dictionary] = []
	for obj: Dictionary in arena.objects:
		var pos_raw: Array = obj.get("position", [])
		var pos := Vector2i(int(pos_raw[0]), int(pos_raw[1]))
		if not area.has(pos):
			continue
		if instant:
			explode_queue.append({"position": pos, "instant": true})
			continue
		if amount <= 0:
			continue  # a 0-burn wash accumulates nothing (and pops nothing)
		obj["burn"] = int(obj.get("burn", 0)) + amount
		events.append({
			"type": "trash_can_burned",
			"key": String(obj.get("key", "")),
			"position": [pos.x, pos.y],
			"added": amount, "burn": int(obj["burn"]),
			"by": actor.id,
		})
		if int(obj["burn"]) >= Arena.TRASH_CAN_EXPLODE_AT:
			explode_queue.append({"position": pos, "instant": false})
	events.append_array(_explode_cans(explode_queue, actor.id))
	return events


## Explodes queued trash cans, cascades included, deterministically (queue
## order = ignition order; chained cans append in store order). Per canon
## ("3 spaces, 2 Burn"): blast = HexGeometry.blast(can, 3), burn 2 to every
## living combatant in it through the NORMAL damage path (_strike_round) with
## attacker NONE — environment damage, no killer (takedown-v2 unauthored-death
## honesty). Collateral is never threshold-dodged (R22 valve precedent): the
## synthetic action carries the R26 undodgable flag, so every dodge-shaped
## escape is skipped with ZERO rng; the R25 AoE-center rule still applies (a
## live roller is missed unless standing on the can's own hex — the center).
## The boss's fire-heal hook applies normally (a can blast HEALS the
## Incinedile's flesh — mycelium parts with fire_harms still burn). The blast
## is also a burn TOUCH on other cans in radius (+2, chaining at 5; the
## instant-pop upgrade never chains — it belongs to the flamethrower). An
## exploded can is REMOVED: its hex unblocks and further queue hits no-op.
func _explode_cans(queue: Array[Dictionary], by: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var pending: Array[Dictionary] = queue.duplicate()
	while not pending.is_empty():
		var entry: Dictionary = pending.pop_front()
		var pos: Vector2i = entry["position"]
		var idx: int = arena.object_index_at(pos)
		if idx < 0:
			continue  # already destroyed (double-queued / chained twice)
		var can: Dictionary = arena.objects[idx]
		arena.objects.remove_at(idx)
		events.append({
			"type": "trash_can_exploded",
			"key": String(can.get("key", "")),
			"position": [pos.x, pos.y],
			"radius": Arena.TRASH_CAN_BLAST_RADIUS,
			"damage": Arena.TRASH_CAN_BLAST_BURN,
			"burn": int(can.get("burn", 0)),
			"instant": bool(entry.get("instant", false)),
			"by": by,
		})
		var area: Dictionary = HexGeometry.to_set(HexGeometry.blast(pos, Arena.TRASH_CAN_BLAST_RADIUS))
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			var other: CombatantState = combatants[id]
			if not other.alive or other.removed_from_play or not area.has(other.position):
				continue
			if other.rolled_this_window and other.position != pos:
				events.append({
					"type": "blast_missed_roller",
					"combatant": other.id, "by": "environment",
					"at": [other.position.x, other.position.y],
					"center": [pos.x, pos.y],
				})
				continue
			var part_key: String = ai.torso_line_part(other)
			if part_key == "":
				continue
			events.append_array(_strike_round(other, part_key, "burn",
				Arena.TRASH_CAN_BLAST_BURN,
				{"kind": "attack", "key": "trash_can_explosion", "undodgable": true}, null))
		for obj: Dictionary in arena.objects:
			var opos_raw: Array = obj.get("position", [])
			var opos := Vector2i(int(opos_raw[0]), int(opos_raw[1]))
			if not area.has(opos):
				continue
			obj["burn"] = int(obj.get("burn", 0)) + Arena.TRASH_CAN_BLAST_BURN
			events.append({
				"type": "trash_can_burned",
				"key": String(obj.get("key", "")),
				"position": [opos.x, opos.y],
				"added": Arena.TRASH_CAN_BLAST_BURN, "burn": int(obj["burn"]),
				"by": "environment",
			})
			if int(obj["burn"]) >= Arena.TRASH_CAN_EXPLODE_AT:
				pending.append({"position": opos, "instant": false})
	return events


# ------------------------------------------------------ death spin beats (wave 2b)

## True when a chew/spin beat's preconditions broke between decide and
## resolution: no live sequence, wrong beat, or the hold is gone (victim
## dead/removed, released, escaped). LIVE state, mirroring
## _resolve_grapple_suffocate's grip check.
func _death_spin_beat_stale(actor: CombatantState, action: Dictionary) -> bool:
	var spin: Dictionary = ai.death_spins.get(actor.id, {})
	if spin.is_empty():
		return true
	# Wave 2d: the phase-5 MERGED beat (chew+spin in one Moment) closes the
	# sequence straight from beat 1; the 3-beat spin still expects beat 2.
	var expected_beat: int = 1 if String(action.get("death_spin_beat", "")) == "chew" \
			or bool(action.get("death_spin_merged", false)) else 2
	if int(spin.get("beat", 0)) != expected_beat:
		return true
	var victim: CombatantState = combatants.get(String(spin.get("victim", "")))
	return victim == null or not victim.alive or victim.removed_from_play \
			or actor.grappling != victim.id or victim.grappled_by != actor.id


## Advances/finishes a REALLY-resolved death-spin beat (the marker hook after
## the strike rounds — a feinted/stuttered beat never reaches this, so the
## sequence retries instead of skipping). CHEW: beat 1 -> 2, event. SPIN: the
## victim is FLUNG down the spin lane (prone on landing when it survives), the
## hold ends, the sequence clears, death_spin_kill closes the show. The strike
## itself already ran the honest R14 gate; a kill in it auto-released via
## _release_grapples, which is why the release here is conditional.
func _apply_death_spin_beat(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var beat_kind := String(action.get("death_spin_beat", ""))
	if beat_kind == "":
		return []
	var spin: Dictionary = ai.death_spins.get(actor.id, {})
	if spin.is_empty():
		return []
	var events: Array[Dictionary] = []
	var victim_id := String(spin.get("victim", ""))
	var victim: CombatantState = combatants.get(victim_id)
	if beat_kind == "chew" and int(spin.get("beat", 0)) == 1:
		spin["beat"] = 2
		var arms: Array = []
		for t: Variant in action.get("targets", []) as Array:
			arms.append(String((t as Dictionary).get("part", "")))
		events.append({
			"type": "death_spin_chew", "combatant": actor.id, "victim": victim_id,
			"arms": arms,
		})
	elif beat_kind == "spin" and (int(spin.get("beat", 0)) == 2
			or (bool(action.get("death_spin_merged", false)) and int(spin.get("beat", 0)) == 1)):
		# Wave 2d: the phase-5 merged beat closes straight from beat 1 — its
		# chew half already fired inside _resolve_strike (event + arm rounds).
		ai.death_spins.erase(actor.id)
		var flung_from: Vector2i = victim.position if victim != null else Vector2i.ZERO
		var fling: Dictionary = {"to": flung_from, "hexes": 0}
		var prone: bool = false
		if victim != null:
			fling = _death_spin_fling_target(actor, victim)
			victim.position = fling["to"]
			if victim.alive and not victim.removed_from_play \
					and not bool(victim.statuses.get("prone", false)):
				victim.statuses["prone"] = true
				prone = true
				events.append({"type": "knocked_prone", "combatant": victim.id,
					"source": actor.id, "skill": "death_spin"})
				events.append_array(_end_dance(victim, "knocked_prone"))
			if actor.grappling == victim_id and victim.grappled_by == actor.id:
				actor.grappling = ""
				victim.grappled_by = ""
				events.append({"type": "grapple_ended", "grappler": actor.id,
					"target": victim_id, "reason": "death_spin_finished"})
		var to: Vector2i = fling["to"]
		events.append({
			"type": "death_spin_kill", "combatant": actor.id, "victim": victim_id,
			"flung_from": [flung_from.x, flung_from.y], "flung_to": [to.x, to.y],
			"hexes_flung": int(fling["hexes"]), "prone": prone,
		})
	return events


## The beat-3 fling geometry: the spin lane is the HexGeometry ray from the
## boss THROUGH the victim; the victim flies SPIN_FLING_HEXES hexes down it,
## stopping before the first hex occupied by another living, in-play
## combatant. Deterministic, rng-free. {"to": Vector2i, "hexes": int} —
## hexes 0 means nowhere to fly (the victim drops on the spot). R30: the
## fling is INVOLUNTARY — the flung victim's facing never changes.
func _death_spin_fling_target(boss: CombatantState, victim: CombatantState) -> Dictionary:
	var start: Vector2i = victim.position
	var span: int = HexGeometry.distance(boss.position, start)
	var lane: Array[Vector2i] = HexGeometry.line_extended(boss.position, start, span + EnemyAI.SPIN_FLING_HEXES)
	var start_idx: int = lane.find(start)
	if start_idx < 0:
		return {"to": start, "hexes": 0}
	var occupied: Dictionary = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == victim.id or not other.alive or other.removed_from_play:
			continue
		occupied[other.position] = true
	var final_idx: int = start_idx
	for k: int in range(start_idx + 1, mini(lane.size(), start_idx + 1 + EnemyAI.SPIN_FLING_HEXES)):
		if occupied.has(lane[k]):
			break
		# KAN-5: a fling into a wall/bounds/can stops short — the victim drops
		# on the last free hex of the spin lane (still prone where the spin
		# rule says prone; the wall just shortens the flight).
		if arena != null and arena.blocks_movement(lane[k]):
			break
		final_idx = k
	return {"to": lane[final_idx], "hexes": final_idx - start_idx}


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
	# Wave 2b: re-verify the death-spin grabbing hand at resolution (it may have
	# been disabled between declare and resolve — same live re-check family as
	# reload's needs_both_hands). No hold lands on a dead hand.
	var is_death_spin: bool = bool(action.get("death_spin", false))
	var grab_part := String(action.get("grab_part", ""))
	if is_death_spin and (grab_part == "" or not actor.part_usable(grab_part, clock.tick)):
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple", "reason": "grab_hand_disabled"})
		return events
	# Wave 2d — the beyond-adjacent grab ("grab range +1", phase 3+) DRAGS the
	# victim adjacent FIRST: a 1-hex pull to the boss-adjacent hex of the
	# boss→victim line (EnemyAI.grab_pull_hex), re-checked LIVE at resolution
	# (same family as the grab-hand re-verify above) — a living body standing
	# on the pull hex blocks the drag and the grab fails honestly: no pull, no
	# hold, no sequence.
	var drag: Dictionary = {}
	if is_death_spin and CombatantState.hex_distance(actor.position, target.position) > 1:
		if _pull_hex_blocked(actor, target):
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple", "reason": "pull_blocked"})
			return events
		var pull: Vector2i = EnemyAI.grab_pull_hex(actor.position, target.position)
		drag = {"from": [target.position.x, target.position.y], "to": [pull.x, pull.y]}
		target.position = pull
	actor.grappling = target.id
	target.grappled_by = actor.id
	# R30: a grapple faces BOTH parties toward each other (physical contact
	# turns the held victim too — the one involuntary facing in the table,
	# ruled explicitly). Positions read post-drag, so the hold faces true.
	_face_along(actor, actor.position, target.position)
	_face_along(target, target.position, actor.position)
	events.append({"type": "grapple_started", "grappler": actor.id, "target": target.id})
	# Wave 2b: a death-spin grab ARMS the 3-beat sequence at the moment the hold
	# actually lands (beat 1 done — chew next). The dodge model does NOT apply
	# to the grab (an adjacent cost-1 instant, R2); the counterplay is the
	# authored release-on-5 / R9 escape chain, not a dodge roll.
	if is_death_spin:
		ai.death_spins[actor.id] = {
			"beat": 1, "victim": target.id, "part": grab_part,
			"started_tick": clock.tick,
		}
		var grab_event: Dictionary = {
			"type": "death_spin_grab", "combatant": actor.id, "victim": target.id,
			"part": grab_part, "release_threshold": EnemyAI.RELEASE_HIT_THRESHOLD,
			# Wave 2d: the drag is part of the grab's story — emitted on it.
			"dragged": not drag.is_empty(),
		}
		if not drag.is_empty():
			grab_event["dragged_from"] = drag["from"]
			grab_event["dragged_to"] = drag["to"]
		events.append(grab_event)
	# R9: automatic when grappler Physique >= target's; otherwise the attempt
	# is Forced Action – Body — always allowed, consequences apply, hold lands.
	if actor.trait_total("physique") < target.trait_total("physique"):
		var body: Dictionary = _forced_body_roll(actor, "grapple_above_weight")
		events.append_array(body["events"])
		if not bool(body.get("negated", false)):  # S5-d veto queues nothing
			forced_queue.append({"actor": actor.id, "rolled": body["rolled"], "ctx": {"part": actor.acting_part(clock.tick), "target": target.id}})
	return events


func _resolve_grapple_escape(actor: CombatantState) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if actor.grappled_by == "":
		# Tier-2 wave 1 (phantom_grasp — S10-a): the R9 escape action also
		# breaks a psychic HOLD — the paid escape releases the holder's
		# channel through the one release seam (the held_by mirror clears
		# with it). A hold that lapsed/broke mid-windup invalidates honestly.
		var holder: CombatantState = _hold_holder_of(actor)
		if holder == null:
			events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple_escape", "reason": "not_grappled"})
			return events
		events.append({"type": "hold_escaped", "holder": holder.id, "target": actor.id})
		events.append_array(release_channel(holder, "escaped"))
		return events
	var grappler: CombatantState = combatants.get(actor.grappled_by)
	if grappler != null:
		grappler.grappling = ""
	events.append({"type": "grapple_ended", "grappler": actor.grappled_by, "target": actor.id, "reason": "escaped"})
	actor.grappled_by = ""
	return events


## Tier-2 wave 1 (phantom_grasp — S10-a): the combatant HOLDING `victim`
## through a channel whose grip value marks a trained hold ("psychic" — the
## R9 gate set's third grip), or null when the victim is not hold-held. A
## plain telekinesis lift (no grip on the channel) is NOT a hold — its
## counterplay stays break-on-damage/lapse, never the R9 escape.
func _hold_holder_of(victim: CombatantState) -> CombatantState:
	if victim.held_by == "":
		return null
	var holder: CombatantState = combatants.get(victim.held_by)
	if holder == null or String(holder.channeling.get("target", "")) != victim.id:
		return null
	if String(holder.channeling.get("grip", "")) == "psychic":
		return holder
	return null


## The R9 escape contest's HOLDER stat, parameterized by grip type (OQ1
## RULED, owner 2026-08-18): a mundane grip (hands/bite/any) contests
## Physique-vs-Physique; the psychic grip contests target Physique vs the
## holder's MIND — mundane-psionic, no magic reading, no is_magic anywhere.
static func escape_holder_stat(grip: String) -> String:
	return "mind" if grip == "psychic" else "physique"


func _resolve_grapple_suffocate(actor: CombatantState, action: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var target: CombatantState = combatants.get(String(action.get("target", "")))
	if target == null or not target.alive or actor.grappling != target.id:
		events.append({"type": "action_invalidated", "actor": actor.id, "kind": "grapple_suffocate", "reason": "grip_lost"})
		return events
	events.append({"type": "action_resolved", "actor": actor.id, "kind": "grapple_suffocate", "result": "ok"})
	events.append_array(cond.apply(target, "torso", "suffocation", clock.tick, {"source": "attack", "attacker": actor.id}))
	return events


func to_dict() -> Dictionary:
	return {}  # stateless — all state lives on Clock/CombatantState, rewired by CombatSim


static func from_dict(_data: Dictionary) -> ActionResolver:
	return ActionResolver.new()
