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
## - decide() consumes rng ONLY for the antagonism draw (R23 amends the old
##   "decide() is rng-free" line): targeting is a weighted-random pick over
##   SORTED candidates — a decision with >= 2 candidates consumes EXACTLY ONE
##   ai_rng.randf() draw, a single-candidate (or no-target/summon/heal/beat)
##   decision consumes ZERO. Everything else stays pure rules over sorted
##   state. The only other ai_rng consumers are the R22 dodge check's threshold
##   die and the R24 feint-read's Mind die (mirrors of hype_engine's salted
##   goal_rng pattern) — and only on the ROLLED fallback: an auto or an
##   impossible check consumes nothing — so none of the draws ever perturb the
##   action RNG's Forced-Action sequence.
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
## Death Spin (wave 2b, decision #31 — the authored 3-beat sequence is REAL):
## BASE grab reach in hexes. Wave 2d: the authored "death spin grab range +1"
## phase upgrade is REAL — grab_range() adds 1 from its authored phase (3) on;
## this constant stays the flat pre-upgrade rule.
const GRAB_RANGE: int = 1
## Beat-2 CHEW damage: "chew: 2 crushed to both arms" — canon off the authored
## sequence line (data/enemies.json), delivered through the normal R14 gate.
const CHEW_CRUSHED: int = 2
## Beat-3 SPIN-KILL damage — PLACEHOLDER (R14). "spin and kill" is ruled an
## honest R14 hit, never a bypass: Force = 8 + floor(boss phys 6/2) = 11 vs a
## fresh contestant torso's Robustness ~1-2 fells a fresh 5-HP torso through
## the gate for any plausible contestant physique; an armored monster could
## genuinely survive it.
const SPIN_KILL_AMOUNT: int = 8
## Beat-3 fling distance in hexes (or until a body blocks). PLACEHOLDER (R14).
const SPIN_FLING_HEXES: int = 3
## "release if hit for 5" — canon off the authored sequence line: any SINGLE
## recorded hit (R15/NQ2 seam — a merged combined hit counts as ONE) netting
## this much on the boss mid-sequence forces the release and aborts the spin.
const RELEASE_HIT_THRESHOLD: int = 5
## R3 free-move allowance the policy plans with (resolver enforces the real cap).
const FREE_MOVE_SPACES: int = 3
## Axial hex neighbors in fixed order — deterministic movement tie-break.
const HEX_NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Wave 2d — the authored per-phase `behavior.upgrades` STRINGS are the source
## of truth; this map parses them into the effect keys the sim consumes. An
## authored string with NO entry here is a DATA-ONLY no-op by design: it stays
## visible in the data, upgrades_active() never reports it, nothing executes.
## The two deliberate data-only entries (and why — see rules-addendum R11 #20):
##  * "dash bounces between walls up to 2 bounces" — there are NO walls yet:
##    geometry is unbounded (hex_geometry.gd header); bounces arrive with the
##    KAN-5 arenas.
##  * "flamethrower pops trash cans instantly" — trash cans are not sim
##    entities; environment objects are KAN-5 scope.
const UPGRADE_EFFECTS: Dictionary = {
	"death spin grab range +1": "grab_range_plus_1",
	"death spin costs 2 moments": "spin_two_moments",
	"dash can change direction mid-run": "dash_bend",
	"network fully exposed": "network_stays_exposed",
	"flamethrower tracks closest target": "cone_track_closest",
}

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
## Live death-spin sequences (wave 2b — same serialization pattern as
## explosion_beats): combatant id -> {"beat": int (1 = grab landed, chew next;
## 2 = chew landed, spin next), "victim": String, "part": String (the grabbing
## hand), "started_tick": int}. An entry exists only from the grab's RESOLUTION
## until the spin resolves or the sequence aborts (release-on-5, R9 escape,
## valve entry, victim/boss down), so a mid-sequence save restores the exact
## continuation. Serialized + hash-covered under "ai".
var death_spins: Dictionary = {}


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
## state (+ stored phase/summon memory) — consumes rng ONLY for the R23
## antagonism draw (one randf per >= 2-candidate targeting decision, zero
## otherwise). Returned shape:
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


## MOB: bite the antagonism-weighted target (R23 — closer much likelier,
## grudge multiplies; torso-line part); close distance toward it when out of
## reach; wait otherwise.
func _decide_mob(actor: CombatantState) -> Dictionary:
	var strike: Dictionary = _first_strike_ability(actor, [])
	var opponents: Array[CombatantState] = _opponents(actor)
	if opponents.is_empty():
		return _wait("mob", "no_targets")
	if strike.is_empty():
		return _wait("mob", "no_usable_ability")
	return _strike_or_close(actor, "mob", strike, opponents, false)


## ELITE: summon the brood once, self-heal when a lethal part is below half,
## then whip the antagonism-weighted target (its authored low_hp_bias is the
## old "picks off the weak" persona, now a bias not a rule — R23; heads when
## exposed); close toward the pick otherwise.
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


## BOSS (Incinedile) — DECIDE ORDER (wave 2b, documented policy):
##   valve > stand (prone) > active death-spin continuation > cone sweep >
##   death-spin GRAB > dash > close.
## Rationale, top down: the explosion valve is canon-outranking (#27 precedent
## — the telegraph -> blast beat is never delayed; entering it ABORTS a live
## spin via death_spin_checks). A knocked-down boss rights itself. A boss with
## its jaws already full FINISHES the sequence it started (committed — only the
## valve outranks it). The cone stays the marquee crowd opener (>= 2 in arc).
## The death-spin GRAB is the boss's PUNISH on a target that stays ADJACENT
## while it is free to act — a grab-and-kill threat scarier than the dash, so
## it sits above it; it fires only when a valid in-reach grab target exists AND
## the grabbing hand is functional (no step-then-grab: reach is grab_range —
## base 1, +1 from phase 3 per the authored "grab range +1" upgrade, wave 2d).
## The dash remains the reach tool, then close distance. The ability
## set is filtered to the current phase's behavior list (which gates STARTING
## a sequence; an in-flight one continues on its own state).
func _decide_boss(actor: CombatantState) -> Dictionary:
	var phase: int = current_phase(actor.id)
	var behavior: Dictionary = _phase_entry(actor, phase).get("behavior", {})
	if behavior.has("explosion"):
		return _decide_explosion_beat(actor, phase, behavior.get("explosion", {}))
	# Skill-feel pass (builds on R22's prone rules): a knocked-down boss RIGHTS
	# ITSELF before it fights — the "stand" choice declares the resolver's stand
	# action (cost 1), so getting back up consumes the boss's whole Moment.
	# Prone never clears for free: until this resolves the boss cannot dodge
	# (check_dodge), crawls at allowance 1 (_step_toward) and cannot cone-sweep
	# (_first_cone_ability). The explosion valve above deliberately outranks it —
	# the canon telegraph -> blast beat (decision #27) is never delayed by prone.
	# Boss-only on purpose: mobs/elites keep their pre-existing prone behavior.
	# (A live spin never reaches the prone branch: knocking the boss prone
	# aborts the sequence in the death_spin_checks sweep before any decide.)
	if bool(actor.statuses.get("prone", false)):
		return {"choice": "stand", "tier": "boss"}
	# Active death-spin sequence: the committed continuation (chew, then spin).
	var spin_state: Dictionary = death_spins.get(actor.id, {})
	if not spin_state.is_empty():
		return _decide_spin_beat(actor, spin_state)
	var allowed: Array = behavior.get("abilities", [])
	var opponents: Array[CombatantState] = _opponents(actor)
	if opponents.is_empty():
		return _wait("boss", "no_targets")
	# Priority 1: cone sweep when enough targets stand inside the REAL arc
	# (decision #31 — retires the R11 #16 range-only deferral): the aim is the
	# fixed-order direction whose 120-degree HexGeometry.cone catches the most
	# opponents; a cone "reaches" an opponent iff that best arc contains it.
	# Wave 2d "flamethrower tracks closest target" (phase 5): the AIM hunts the
	# NEAREST opponent instead — only the toward selection shifts; the shape,
	# size and the >= CONE_MIN_TARGETS gate below are unchanged.
	var cone: Dictionary = _first_cone_ability(actor, allowed)
	if not cone.is_empty():
		var sweep: Dictionary
		if has_upgrade(actor, "cone_track_closest"):
			sweep = _tracking_cone_sweep(actor, cone, opponents)
		else:
			sweep = _best_cone_sweep(actor, cone, opponents)
		var in_cone: Array[CombatantState] = sweep["targets"]
		if in_cone.size() >= CONE_MIN_TARGETS:
			return _cone_decision(actor, cone, in_cone, sweep["toward"])
	# Priority 2: death-spin GRAB — the adjacency punish (wave 2b). R23 pick
	# over the ADJACENT candidates only (one ai_rng draw for >= 2 candidates,
	# zero for a single one — the standard targeting RNG-cost rule).
	var grab: Dictionary = _grab_decision(actor, allowed, opponents)
	if not grab.is_empty():
		return grab
	# Priority 3: single-target strike (dash), torso bias; else close distance.
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
	# R26: the authored undodgable flag rides both beat choices so the telegraph
	# can announce it and the blast can honor it — data-driven, never hardcoded.
	var undodgable: bool = bool(explosion.get("undodgable", false))
	var beat: Dictionary = explosion_beats.get(actor.id, {})
	if beat.is_empty():
		return {
			"choice": "telegraph", "tier": "boss", "phase": phase,
			"radius": radius, "moments_until_blast": escape + 1,
			"undodgable": undodgable,
		}
	if clock.tick <= int(beat.get("telegraph_tick", 0)) + escape:
		return _wait("boss", "explosion_building")
	return {"choice": "blast", "tier": "boss", "phase": phase, "radius": radius,
			"undodgable": undodgable}


# ------------------------------------------------------------ death spin (wave 2b)

## The GRAB opener, or {} when it does not apply. PACING MODEL (documented
## decision): grab cost 1 -> chew cost 1 -> spin cost 1 — the honest read of
## the authored "3-beat, moment_cost 3": the cost spans the SEQUENCE, one
## Moment per beat, each beat a REAL scheduled action declared through the
## resolver (so feints, shock stutter and the R9 grapple machinery all apply
## normally). Fires only when: death_spin is in the phase's behavior list, the
## boss is not already holding anyone, the grabbing hand is functional, and an
## in-reach (grab_range — base 1, +1 at phase 3+, wave 2d) R9-legal target
## exists. A range-2 candidate must also have a FREE drag hex (the pull would
## fail on a blocked one, so the AI never decides it — the resolver still fails
## a hand-built command honestly). The victim pick is the R23 antagonism draw
## over the in-reach candidates.
func _grab_decision(actor: CombatantState, allowed: Array, opponents: Array[CombatantState]) -> Dictionary:
	var ability: Dictionary = _first_sequence_ability(actor, allowed)
	if ability.is_empty() or actor.grappling != "":
		return {}
	var grab_hand: String = grab_hand_part(actor)
	if grab_hand == "":
		return {}
	var reach: int = grab_range(actor)
	var occupied: Dictionary = _occupied_hexes(actor)
	var adjacent: Array[CombatantState] = []
	for opponent: CombatantState in opponents:
		var distance: int = CombatantState.hex_distance(actor.position, opponent.position)
		if distance > reach:
			continue
		if opponent.size_rank() - actor.size_rank() > 1:
			continue  # R9: target no more than one size larger
		if distance > 1 and occupied.has(grab_pull_hex(actor.position, opponent.position)):
			continue  # wave 2d: a blocked drag hex means the grab cannot land
		adjacent.append(opponent)
	if adjacent.is_empty():
		return {}
	var victim: CombatantState = pick_weighted_target(actor, adjacent)
	return {
		"choice": "grab", "tier": "boss",
		"ability": String(ability.get("key", "")),
		"target": victim.id,
		"action": {
			"kind": "grapple", "target": victim.id, "cost": 1,
			"key": String(ability.get("key", "")),
			"death_spin": true, "grab_part": grab_hand,
		},
	}


## The committed continuation of a live sequence: beat 1 done -> CHEW ("2
## crushed to both arms", one R14-gated round per arm part), beat 2 done ->
## SPIN-KILL (one massive R14-gated hit at the victim's torso-line part; the
## resolver's beat hook then flings the victim down the spin lane). Both are
## cost-1 attack declares carrying the death_spin_beat marker — the resolver
## re-verifies the grip at resolution (a same-tick release/escape makes the
## beat close on air) and only a REALLY-resolved beat advances the state, so a
## feinted/stuttered beat is retried, never skipped. The stale guard is
## belt-and-braces: death_spin_checks aborts broken sequences after every
## command, before any decide can see one.
##
## Wave 2d — "death spin costs 2 moments" (phase 5, PROVISIONAL model): the
## sequence ACCELERATES by merging chew and spin into ONE beat — grab (1
## Moment) then chew+spin (1 Moment), total 2. The merged declare is the SPIN
## action carrying the chew's arm rounds as riders (chew_targets) + the
## death_spin_merged marker; the resolver fires the chew rounds first, then
## the kill, then closes the sequence from beat 1. The counterplay window
## shrinks by exactly one Moment: release-on-5 / R9 escape must land in the
## single Moment between the grab and the merged beat's resolution (a
## same-tick release still makes the merged jaws close on air). Derived from
## current_phase at decide time — no new state; the markers ride the declared
## action only.
func _decide_spin_beat(actor: CombatantState, spin: Dictionary) -> Dictionary:
	var victim: CombatantState = combatants.get(String(spin.get("victim", "")))
	if victim == null or not victim.alive or victim.removed_from_play \
			or victim.grappled_by != actor.id or actor.grappling != victim.id:
		return _wait("boss", "death_spin_stale")
	if int(spin.get("beat", 1)) == 1 and not has_upgrade(actor, "spin_two_moments"):
		var arm_targets: Array[Dictionary] = _arm_targets(victim)
		return {
			"choice": "chew", "tier": "boss", "ability": "death_spin",
			"target": victim.id,
			"action": {
				"kind": "attack", "key": "death_spin_chew", "cost": 1,
				"damage": {"type": "crushed", "amount": CHEW_CRUSHED},
				"attack_range": GRAB_RANGE,
				"targets": arm_targets,
				"rpm": maxi(1, arm_targets.size()),
				"rounds": maxi(1, arm_targets.size()),
				"death_spin_beat": "chew",
			},
		}
	var part_key: String = torso_line_part(victim)
	var targets: Array[Dictionary] = []
	if part_key != "":
		targets.append({"id": victim.id, "part": part_key})
	var action: Dictionary = {
		"kind": "attack", "key": "death_spin_kill", "cost": 1,
		"damage": {"type": "crushed", "amount": SPIN_KILL_AMOUNT},
		"attack_range": GRAB_RANGE,
		"targets": targets,
		"death_spin_beat": "spin",
	}
	if int(spin.get("beat", 1)) == 1:
		# Phase-5 merged beat: the chew rides the spin declare (wave 2d).
		action["death_spin_merged"] = true
		action["chew_targets"] = _arm_targets(victim)
	return {
		"choice": "spin", "tier": "boss", "ability": "death_spin",
		"target": victim.id,
		"action": action,
	}


## The chew's per-arm target rows on the victim, in sorted part-key order.
static func _arm_targets(victim: CombatantState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var keys: Array = victim.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		if String(part_key).contains("arm"):
			out.append({"id": victim.id, "part": String(part_key)})
	return out


## The hand the boss grabs with — DATA-HONEST ruling (documented decision):
## the flamethrower is authored on the LEFT hand ("Left Hand (Flamethrower
## Arm)"; trait left_hand_disable_removes_flamethrower), so the grab uses the
## first USABLE hand/arm part in sorted key order that is NOT the flamethrower
## hand (for the seeded Incinedile: right_hand). A boss without the authored
## flamethrower trait may grab with any usable hand. "" = no functional grab
## hand = no grab (the AI never decides it; the resolver rejects a hand-built
## command the same way).
func grab_hand_part(actor: CombatantState) -> String:
	var flame_hand: String = ""
	if bool(actor.boss_traits.get("left_hand_disable_removes_flamethrower", false)):
		flame_hand = "left_hand"
	var keys: Array = actor.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if not (key.contains("arm") or key.contains("hand")):
			continue
		if key == flame_hand:
			continue
		if actor.part_usable(key, clock.tick):
			return key
	return ""


## Wave 2d — the range-2 grab's DRAG destination: the hex adjacent to the boss
## on the boss→victim HexGeometry line (lane index 1; the line's fixed tie rule
## makes it deterministic). The grab drags the victim there FIRST — a 1-hex
## pull along the line — so the hold always closes adjacent; a living body on
## this hex blocks the pull and the grab fails honestly (resolver).
static func grab_pull_hex(boss_pos: Vector2i, victim_pos: Vector2i) -> Vector2i:
	var lane: Array[Vector2i] = HexGeometry.line(boss_pos, victim_pos)
	if lane.size() < 2:
		return victim_pos
	return lane[1]


## First sequence-carrying ability (death_spin), filtered to the phase's
## behavior list — the lookup the strike scan deliberately skips (sequences
## are not plain strikes; wave 2b gives them their own decide path).
func _first_sequence_ability(actor: CombatantState, allowed: Array) -> Dictionary:
	for ability: Dictionary in actor.abilities:
		if not allowed.is_empty() and not allowed.has(String(ability.get("key", ""))):
			continue
		if ability.has("sequence"):
			return ability
	return {}


## Post-command sweep (run from CombatSim's breach/phase housekeeping, so it
## fires after EVERY command): aborts any live death-spin whose preconditions
## broke. Deterministic check order per sequence, first hit wins:
##   boss dead/removed        -> "boss_out"
##   boss prone or helpless   -> "boss_downed"
##   boss in an explosion valve phase -> "explosion_valve" (the valve OUTRANKS
##                               the spin, #27 precedent — venting opens the jaws)
##   victim dead/removed      -> "victim_out" (covers death mid-chew)
##   grapple no longer intact -> "grapple_ended" (R9 escape, forced release)
## Aborting releases a still-intact hold (grapple_ended reason
## "death_spin_aborted") and clears the sequence. Idempotent — a second sweep
## in the same batch finds nothing to do.
func death_spin_checks() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var ids: Array = death_spins.keys()
	ids.sort()
	for id: Variant in ids:
		var boss_id := String(id)
		var spin: Dictionary = death_spins[boss_id]
		var boss: CombatantState = combatants.get(boss_id)
		var reason: String = ""
		if boss == null or not boss.alive or boss.removed_from_play:
			reason = "boss_out"
		elif boss.is_helpless(clock.tick) or bool(boss.statuses.get("prone", false)):
			reason = "boss_downed"
		elif (_phase_entry(boss, current_phase(boss_id)).get("behavior", {}) as Dictionary).has("explosion"):
			reason = "explosion_valve"
		else:
			var victim: CombatantState = combatants.get(String(spin.get("victim", "")))
			if victim == null or not victim.alive or victim.removed_from_play:
				reason = "victim_out"
			elif victim.grappled_by != boss_id or boss.grappling != victim.id:
				reason = "grapple_ended"
		if reason == "":
			continue
		events.append_array(_abort_death_spin(boss_id, spin, reason))
	return events


## Clears a sequence, releasing the hold when it is still intact. The
## death_spin_aborted event carries the beat the sequence died on.
func _abort_death_spin(boss_id: String, spin: Dictionary, reason: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	death_spins.erase(boss_id)
	var victim_id := String(spin.get("victim", ""))
	var boss: CombatantState = combatants.get(boss_id)
	var victim: CombatantState = combatants.get(victim_id)
	if boss != null and victim != null \
			and boss.grappling == victim_id and victim.grappled_by == boss_id:
		boss.grappling = ""
		victim.grappled_by = ""
		events.append({
			"type": "grapple_ended", "grappler": boss_id, "target": victim_id,
			"reason": "death_spin_aborted",
		})
	events.append({
		"type": "death_spin_aborted", "combatant": boss_id, "victim": victim_id,
		"beat": int(spin.get("beat", 1)), "reason": reason,
	})
	return events


## The authored "release if hit for 5": called from the damage path at the
## R15/NQ2 single-hit seam (after record_hit, so a merged combined hit counts
## as ONE hit at its merged net). A qualifying hit on a boss mid-sequence
## forces the release — the hold ends, the sequence clears, the spin never
## comes. Rng-free, idempotent (the first qualifying hit erases the state).
func check_death_spin_release(boss: CombatantState, hit: int) -> Array[Dictionary]:
	if hit < RELEASE_HIT_THRESHOLD:
		return []
	var spin: Dictionary = death_spins.get(boss.id, {})
	if spin.is_empty():
		return []
	var events: Array[Dictionary] = []
	death_spins.erase(boss.id)
	var victim_id := String(spin.get("victim", ""))
	var victim: CombatantState = combatants.get(victim_id)
	if victim != null and boss.grappling == victim_id and victim.grappled_by == boss.id:
		boss.grappling = ""
		victim.grappled_by = ""
		events.append({
			"type": "grapple_ended", "grappler": boss.id, "target": victim_id,
			"reason": "forced_release",
		})
	events.append({
		"type": "death_spin_released", "combatant": boss.id, "victim": victim_id,
		"hit": hit, "threshold": RELEASE_HIT_THRESHOLD,
		"beat": int(spin.get("beat", 1)),
	})
	return events


## Shared strike/close flow (R23): ONE antagonism-weighted pick over ALL
## opponents decides who this actor wants — then it strikes that target if in
## reach, else free-moves toward it (striking when the step closes the gap).
## The old "nearest fallback" is gone on purpose: the mob moves toward whoever
## it is antagonized by. Exactly one ai_rng draw when >= 2 candidates, zero
## for a single candidate (grapple lock included) — see pick_weighted_target.
##
## LINE abilities (the dash — decision #31, retiring the R11 #16 deferral):
## "reach" is a LEGAL CHARGE LANE, not plain range — the target must sit on the
## HexGeometry lane from the acting hex within the ability's range with every
## lane hex before it unoccupied (the charge stops before the first occupied
## hex, so a blocked lane could never connect). Wave 2d "dash can change
## direction mid-run" (phase 4+): when no STRAIGHT lane exists the AI may bend
## the lane ONCE (_bent_dash_lane — the bend reaches a lane-valid target
## otherwise unreachable; fixed-order candidate search, no rng). No lane at
## all from here: plan the free step toward the pick (allowance rules
## unchanged) and dash only if the post-step hex has one; else just move (or
## wait when no step exists) — the picked target must be genuinely
## lane-reachable or the AI does not dash. The declared action carries the
## committed lane (area_shape, + the bend point when bent) for the resolver's
## windup re-check + charge. All pure and rng-free.
func _strike_or_close(actor: CombatantState, tier: String, strike: Dictionary, opponents: Array[CombatantState], elite_pick: bool) -> Dictionary:
	var reach: int = _ability_range(strike)
	var is_line: bool = String(strike.get("area", "")) == "line"
	var target: CombatantState = pick_weighted_target(actor, opponents)
	if target == null:
		return _wait(tier, "no_reachable_action")
	var move_to: Variant = null
	var lane_info: Dictionary = {}
	if is_line:
		lane_info = _dash_lane_for(actor, actor.position, target, reach)
		if lane_info.is_empty():
			move_to = _step_toward(actor, target.position, 1)
			if move_to == null:
				return _wait(tier, "no_reachable_action")
			lane_info = _dash_lane_for(actor, move_to, target, reach)
			if lane_info.is_empty():
				return {"choice": "move", "tier": tier, "move_to": move_to}
	elif CombatantState.hex_distance(actor.position, target.position) > reach:
		move_to = _step_toward(actor, target.position, reach)
		if move_to == null:
			return _wait(tier, "no_reachable_action")
		if CombatantState.hex_distance(move_to, target.position) > reach:
			return {"choice": "move", "tier": tier, "move_to": move_to}
	var part_key: String = _pick_part(target, strike, elite_pick)
	if part_key == "":
		return _wait(tier, "no_reachable_action")
	var action: Dictionary = _attack_action(strike, [{"id": target.id, "part": part_key}])
	if is_line:
		# The committed charge corridor (straight or bent), from the hex the
		# actor will act from (the free step resolves before the declare in
		# _ai_decide) — _dash_lane_for already built it from that hex.
		var lane: Array = []
		for hex: Vector2i in lane_info.get("lane", []) as Array:
			lane.append([(hex as Vector2i).x, (hex as Vector2i).y])
		action["area_shape"] = {"kind": "line", "lane": lane}
		if lane_info.has("bend"):
			var bend: Vector2i = lane_info["bend"]
			action["area_shape"]["bend"] = [bend.x, bend.y]
	var decision: Dictionary = {
		"choice": "attack", "tier": tier,
		"ability": String(strike.get("key", "")),
		"target": target.id,
		"action": action,
	}
	if move_to != null:
		decision["move_to"] = move_to
	return decision


## The committed dash lane from `from` to the target, or {} when none exists:
## {"lane": Array[Vector2i]} for a straight lane; {"lane", "bend": Vector2i}
## for a bent one (wave 2d, phase 4+ only). Straight is always preferred — the
## bend exists to reach a lane-valid target OTHERWISE unreachable.
func _dash_lane_for(actor: CombatantState, from: Vector2i, target: CombatantState, reach: int) -> Dictionary:
	if _dash_lane_exists(actor, from, target, reach):
		return {"lane": HexGeometry.line_extended(from, target.position, reach)}
	if has_upgrade(actor, "dash_bend"):
		return _bent_dash_lane(actor, from, target, reach)
	return {}


## Wave 2d — "dash can change direction mid-run" (phase 4+): a ONE-bend charge
## lane. Geometry: two chained HexGeometry segments — line(from, bend) then
## line_extended(bend, target) — total length still <= the dash's range. The
## candidate search is deterministic and rng-free (documented order): segment-1
## length d1 ascending (the earliest bend first), then candidate bend hexes at
## exactly d1 in HexGeometry.blast's sorted (q, then r) order; the FIRST
## candidate producing a legal lane wins. Legal means: both segment lengths
## >= 1, d1 + d2 <= reach, the composite never revisits a hex (no hairpins
## through the origin), the target sits ON it exactly once, and every hex
## strictly between origin and target is unoccupied (the same rule the
## straight lane obeys — the charge must genuinely reach adjacent-before the
## target). Returns {} when no bend reaches the target.
func _bent_dash_lane(actor: CombatantState, from: Vector2i, target: CombatantState, reach: int) -> Dictionary:
	if from == target.position:
		return {}
	var occupied: Dictionary = _occupied_hexes(actor)
	occupied.erase(target.position)  # the charge stops BEFORE the target anyway
	for d1: int in range(1, reach):
		for bend: Vector2i in HexGeometry.blast(from, d1):
			if HexGeometry.distance(from, bend) != d1 or bend == target.position:
				continue
			var d2: int = HexGeometry.distance(bend, target.position)
			if d2 < 1 or d1 + d2 > reach:
				continue
			var lane: Array[Vector2i] = _compose_bent_lane(from, bend, target.position, reach - d1)
			if lane.is_empty():
				continue
			var t_idx: int = lane.find(target.position)
			if t_idx < 1:
				continue
			var blocked: bool = false
			for k: int in range(1, t_idx):
				if occupied.has(lane[k]):
					blocked = true
					break
			if not blocked:
				return {"lane": lane, "bend": bend}
	return {}


## Chains line(from, bend) + line_extended(bend, target, tail_len) into one
## lane, rejecting self-intersections ([] — a lane that revisits a hex is not
## a chargeable corridor). Pure, static, rng-free.
static func _compose_bent_lane(from: Vector2i, bend: Vector2i, target_pos: Vector2i, tail_len: int) -> Array[Vector2i]:
	var lane: Array[Vector2i] = HexGeometry.line(from, bend)
	var seen: Dictionary = HexGeometry.to_set(lane)
	var tail: Array[Vector2i] = HexGeometry.line_extended(bend, target_pos, tail_len)
	for k: int in range(1, tail.size()):
		if seen.has(tail[k]):
			var empty: Array[Vector2i] = []
			return empty
		seen[tail[k]] = true
		lane.append(tail[k])
	return lane


## True when a legal dash lane exists from `from` to the target: the target
## within `reach` (so it sits ON the from→target lane by construction) and
## every lane hex strictly between unoccupied — the charge would genuinely
## reach the hex adjacent-before the target. Pure, rng-free.
func _dash_lane_exists(actor: CombatantState, from: Vector2i, target: CombatantState, reach: int) -> bool:
	if from == target.position:
		return false
	if CombatantState.hex_distance(from, target.position) > reach:
		return false
	var occupied: Dictionary = _occupied_hexes(actor)
	var lane: Array[Vector2i] = HexGeometry.line_extended(from, target.position, reach)
	for k: int in range(1, lane.size()):
		if lane[k] == target.position:
			return true
		if occupied.has(lane[k]):
			return false
	return false


## The best cone aim (decision #31): try all six fixed-order directions and
## keep the one whose HexGeometry.cone arc contains the most opponents —
## strictly-more wins, so an exact tie keeps the EARLIER neighbor order entry.
## Returns {"toward": Vector2i direction, "targets": in-arc opponents in the
## candidates' given (sorted-id) order}. Pure and rng-free.
func _best_cone_sweep(actor: CombatantState, cone: Dictionary, opponents: Array[CombatantState]) -> Dictionary:
	var size: int = _ability_range(cone)
	var best_dir: Vector2i = HEX_NEIGHBORS[0]
	var best_targets: Array[CombatantState] = []
	for dir: Vector2i in HEX_NEIGHBORS:
		var arc: Dictionary = HexGeometry.to_set(HexGeometry.cone(actor.position, actor.position + dir, size))
		var hit: Array[CombatantState] = []
		for opponent: CombatantState in opponents:
			if arc.has(opponent.position):
				hit.append(opponent)
		if hit.size() > best_targets.size():
			best_dir = dir
			best_targets = hit
	return {"toward": best_dir, "targets": best_targets}


## Wave 2d — "flamethrower tracks closest target" (phase 5): the cone AIMS at
## the NEAREST opponent instead of the biggest crowd — the authored text says
## the sweep TRACKS, i.e. it hunts its closest quarry (a behavior shift, not a
## shape change). Selection (documented, PROVISIONAL like the rest of the
## upgrade models): nearest = minimal hex distance, an exact tie keeps the
## EARLIER candidate in the given (sorted-id) order; among the fixed-order
## directions whose arc CONTAINS the nearest, the most swept targets wins
## (exact ties keep the earlier direction) — the sweep stays maximal SUBJECT TO
## tracking its quarry. A nearest outside cone range leaves every arc check
## false and the decide gate falls through. Pure and rng-free.
func _tracking_cone_sweep(actor: CombatantState, cone: Dictionary, opponents: Array[CombatantState]) -> Dictionary:
	var size: int = _ability_range(cone)
	var nearest: CombatantState = opponents[0]
	var nearest_d: int = CombatantState.hex_distance(actor.position, nearest.position)
	for opponent: CombatantState in opponents:
		var d: int = CombatantState.hex_distance(actor.position, opponent.position)
		if d < nearest_d:
			nearest = opponent
			nearest_d = d
	var best_dir: Vector2i = HEX_NEIGHBORS[0]
	var best_targets: Array[CombatantState] = []
	var found: bool = false
	for dir: Vector2i in HEX_NEIGHBORS:
		var arc: Dictionary = HexGeometry.to_set(HexGeometry.cone(actor.position, actor.position + dir, size))
		if not arc.has(nearest.position):
			continue
		var hit: Array[CombatantState] = []
		for opponent: CombatantState in opponents:
			if arc.has(opponent.position):
				hit.append(opponent)
		if not found or hit.size() > best_targets.size():
			found = true
			best_dir = dir
			best_targets = hit
	return {"toward": best_dir, "targets": best_targets}


## Builds the cone sweep declare: one round per swept target (v1 multi-target
## model, unchanged) + the committed arc (area_shape) so the resolver's windup
## re-check re-evaluates the CONE shape, not plain range (R2: leaving the arc
## before resolution dodges it).
func _cone_decision(actor: CombatantState, cone: Dictionary, in_cone: Array[CombatantState], toward: Vector2i) -> Dictionary:
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
	action["area_shape"] = {"kind": "cone", "toward": [toward.x, toward.y], "size": _ability_range(cone)}
	return {
		"choice": "attack", "tier": "boss",
		"ability": String(cone.get("key", "")),
		"target": String((targets[0] as Dictionary).get("id", "")),
		# The chosen arc direction, surfaced on the ai_decision event (wave 2d:
		# the phase-5 tracking aim is visible, not just buried in the shape).
		"aim": [toward.x, toward.y],
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


## R23 targeting weights (the Antagonism engine, decision #29 — SUPERSEDES the
## nearest → lowest-HP → id cascade of R11 #16, for ALL AI tiers). One row per
## candidate, in the candidates' given order (sorted-id from _opponents), each
## {"id", "distance", "weight"} where
##   weight = proximity_factor * grudge_factor * hp_factor
##   proximity_factor = 1 / maxi(1, distance)^proximity_bias   (2.0 = inverse-square)
##   grudge_factor    = 1 + grudge_weight * antagonism[id]     (no history -> 1)
##   hp_factor        = 1 + low_hp_bias * (1 - hp/max_hp)      (bias 0 -> 1)
## Equal distances with no history and no bias give EXACTLY equal weights (the
## canon 50/50 anchor). Pure and rng-free — the draw lives in
## pick_weighted_target; exposed so tests can assert exactness directly.
func targeting_weights(actor: CombatantState, candidates: Array[CombatantState], from: Vector2i) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var proximity_bias: float = actor.personality_proximity_bias()
	var grudge_weight: float = actor.personality_grudge_weight()
	var low_hp_bias: float = actor.personality_low_hp_bias()
	for candidate: CombatantState in candidates:
		var distance: int = CombatantState.hex_distance(from, candidate.position)
		var proximity_factor: float = 1.0 / pow(float(maxi(1, distance)), proximity_bias)
		var grudge_factor: float = 1.0 + grudge_weight * float(actor.antagonism.get(candidate.id, 0.0))
		var hp_ratio: float = float(_total_hp(candidate)) / float(maxi(1, _total_max_hp(candidate)))
		var hp_factor: float = 1.0 + low_hp_bias * (1.0 - hp_ratio)
		rows.append({
			"id": candidate.id,
			"distance": distance,
			"weight": maxf(0.0, proximity_factor * grudge_factor * hp_factor),
		})
	return rows


## R23 selection: ONE ai_rng.randf() draw walked over the candidates' weights
## in their sorted-id order. RNG-cost rule (documented + tested): a targeting
## decision with >= 2 candidates consumes EXACTLY one draw; a single-candidate
## decision (e.g. the grapple lock) consumes ZERO; no candidates consume none.
## Deterministic given the rng state; two equal weights split exactly 50/50.
func pick_weighted_target(actor: CombatantState, candidates: Array[CombatantState]) -> CombatantState:
	if candidates.is_empty():
		return null
	if candidates.size() == 1:
		return candidates[0]
	var rows: Array[Dictionary] = targeting_weights(actor, candidates, actor.position)
	var total: float = 0.0
	for row: Dictionary in rows:
		total += float(row["weight"])
	var draw: float = ai_rng.randf() * total  # the ONE draw, consumed unconditionally
	if total <= 0.0:
		return candidates[0]  # degenerate authored weights — deterministic fallback
	var cumulative: float = 0.0
	for i: int in range(candidates.size()):
		cumulative += float((rows[i] as Dictionary)["weight"])
		if draw < cumulative:
			return candidates[i]
	return candidates[candidates.size() - 1]  # randf() can return exactly 1.0


static func _total_hp(c: CombatantState) -> int:
	var total: int = 0
	var keys: Array = c.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		total += int((c.parts[part_key] as Dictionary).get("hp", 0))
	return total


static func _total_max_hp(c: CombatantState) -> int:
	var total: int = 0
	var keys: Array = c.parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		total += c.max_hp(String(part_key))
	return total


## R23 grudge write: `holder` (the AI actor remembering) earns `delta` toward
## `earner_id`. No-op — [] — for a non-AI holder, a non-positive delta, or a
## self-hit, so callers can wire it unconditionally at the damage/feint seams.
## Emits the antagonism_changed event ("actor" = the rememberer, "target" =
## who earned the attention, "source" = "damage" | "mockery").
static func add_antagonism(holder: CombatantState, earner_id: String, delta: float, source: String) -> Array[Dictionary]:
	if delta <= 0.0 or earner_id == "" or earner_id == holder.id or not is_ai_controlled(holder):
		return []
	var score: float = float(holder.antagonism.get(earner_id, 0.0)) + delta
	holder.antagonism[earner_id] = score
	return [{
		"type": "antagonism_changed",
		"actor": holder.id, "target": earner_id,
		"delta": delta, "score": score, "source": source,
	}]


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
	# Skill-feel pass: a grounded croc can't sweep the room — the cone is
	# unavailable while prone. (Belt-and-braces with _decide_boss's stand-first
	# short-circuit, so the gate holds even if a future path skips standing.)
	if bool(actor.statuses.get("prone", false)):
		return {}
	for ability: Dictionary in actor.abilities:
		if not allowed.is_empty() and not allowed.has(String(ability.get("key", ""))):
			continue
		if _is_cone(ability) and not (ability.get("damage", []) as Array).is_empty():
			return ability
	return {}


static func _is_cone(ability: Dictionary) -> bool:
	return String(ability.get("area", "")).begins_with("cone")


## Reach MAGNITUDE: explicit "range", else the cone's size ("cone 10"), else 1.
## For cone/line abilities this is the SHAPE SIZE fed to HexGeometry (the arc
## size / lane length) — whether a target is actually reachable is decided by
## the real shape (_best_cone_sweep / _dash_lane_exists, decision #31), no
## longer by plain distance (the retired R11 #16 deferral).
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
	# R26: an ability-authored undodgable flag rides the action — the resolver
	# skips every dodge-shaped escape for it (data-driven, never a boss special).
	if bool(ability.get("undodgable", false)):
		action["undodgable"] = true
	# Wave 2b: the dash's authored "knock aside" effect rides the action — the
	# resolver applies it to a CONNECTED (not dodged, not stopped-short) target
	# after the charge's strike round.
	if String(ability.get("effect", "")) == "knock aside":
		action["knock_aside"] = true
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


# ------------------------------------------------------------------ feint read (R24)

## R24 feint-read — the Mind counter to feints, through the R22 threshold
## machinery unchanged. The feint's read threshold asks the DEFENDER's Mind:
##   Mind >= threshold           -> auto-read, NO rng consumed.
##   Mind + threshold die >= t   -> roll the stat's die (default 1d4) from
##                                  the salted ai_rng and add it.
##   Mind + die max < threshold  -> the read is IMPOSSIBLE: no rng, no event
##                                  ({} — the dim boss stays feintable by design:
##                                  Incinedile Mind 1 vs an L3 feint's 7).
## Gates on stats, never on category — any target with a Mind can read (in
## practice only AI gets feinted today). Consumes the salted ai_rng ONLY.
## Returns {} when no attempt happens; else {"read", "roll" (0 when auto),
## "die", "mind", "threshold", "auto"}.
func check_feint_read(target: CombatantState, threshold: int) -> Dictionary:
	if threshold <= 0:
		return {}
	if not target.alive or target.removed_from_play:
		return {}
	var mind: int = target.trait_total("mind")
	var die: int = target.threshold_die("mind")
	if mind >= threshold:
		return {"read": true, "roll": 0, "die": die, "mind": mind, "threshold": threshold, "auto": true}
	if mind + die < threshold:
		return {}  # impossible — intended texture (R24), no rng
	var roll: int = ai_rng.randi_range(1, die)
	return {"read": mind + roll >= threshold, "roll": roll, "die": die, "mind": mind, "threshold": threshold, "auto": false}


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


# ------------------------------------------------------- phase upgrades (wave 2d)

## The actor's ACTIVE upgrade effects: {effect_key: true}. Upgrades ACCUMULATE —
## the union of every phase entry's authored `behavior.upgrades` strings with
## phase_number <= the actor's current phase, parsed through UPGRADE_EFFECTS
## (unknown strings are data-only no-ops and never reported). Pure function of
## (authored boss_phases data, the serialized boss_phase number) — upgrades are
## DERIVED, never stored, so there is no new state to serialize or drift.
func upgrades_active(actor: CombatantState) -> Dictionary:
	var out: Dictionary = {}
	var phase: int = current_phase(actor.id)
	for entry: Dictionary in actor.boss_phases:
		if int(entry.get("phase_number", 0)) > phase:
			continue
		for authored: Variant in (entry.get("behavior", {}) as Dictionary).get("upgrades", []) as Array:
			var effect := String(UPGRADE_EFFECTS.get(String(authored), ""))
			if effect != "":
				out[effect] = true
	return out


func has_upgrade(actor: CombatantState, effect_key: String) -> bool:
	return bool(upgrades_active(actor).get(effect_key, false))


## The grab's live reach: base 1, +1 from the authored phase-3 upgrade on.
func grab_range(actor: CombatantState) -> int:
	return GRAB_RANGE + (1 if has_upgrade(actor, "grab_range_plus_1") else 0)


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
		# R26 transparency (additive): an undodgable blast is declared on the
		# windup so nobody dies to a misunderstanding — the flag rides the
		# telegraph loudly, straight off the authored explosion block.
		"undodgable": bool(decision.get("undodgable", false)),
	}]
	return events


## Executes the "blast" choice: every OTHER living, in-play combatant within
## the hex radius is knocked out — Helpless for 2 Clocks (owner ruling,
## decision #27), no damage, no death. Friendly fire is ON (other enemies in
## radius are caught; the boss itself is not) and the blast is never
## threshold-dodged (collateral/environment, R22); an already-Helpless victim
## just has the window extended (maxi). ONE exception — the G1 AoE-center rule
## (rules-addendum R25): the blast is an AREA attack, so it MISSES a combatant
## whose rolled_this_window marker is live (a Tactical Roll this Moment)
## entirely, UNLESS the roller's hex is the area's CENTER. The blast centers on
## the boss's own hex, and rolling onto an occupied hex is impossible — so in
## practice a well-timed roller ALWAYS escapes the valve KO (flagged for the
## owner in R25; the center check stays live for future area attacks with
## unoccupied centers). R26 (owner 2026-07-25, decision #32) SUPERSEDES that
## consequence for the VALVE: the authored explosion block carries
## "undodgable": true, and an undodgable AREA attack skips the roller-escape
## check entirely — a blast-Moment Tactical Roll no longer escapes the KO;
## leaving the radius during the escape window (movement, not a dodge) remains
## the counterplay. The center machinery stays live for authored DODGABLE
## areas. Then the canonical retreat applies when this valve resets the
## breach, and the machine advances into the next phase — the boss resumes
## normal fight behavior next Moment.
func resolve_explosion_blast(actor: CombatantState, decision: Dictionary, cond: ConditionEngine) -> Array[Dictionary]:
	var phase: int = int(decision.get("phase", current_phase(actor.id)))
	var radius: int = int(decision.get("radius", 0))
	var undodgable: bool = bool(decision.get("undodgable", false))
	var events: Array[Dictionary] = [{
		"type": "explosion_blast",
		"combatant": actor.id, "phase": phase, "radius": radius,
		"position": [actor.position.x, actor.position.y],
		"undodgable": undodgable,
	}]
	# The blast shape is the shared HexGeometry primitive (decision #31);
	# membership is identical to the old direct distance <= radius check.
	var area: Dictionary = HexGeometry.to_set(HexGeometry.blast(actor.position, radius))
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if other.id == actor.id or not other.alive or other.removed_from_play:
			continue
		if not area.has(other.position):
			continue
		# G1 AoE-center rule (R25): a rolling target is missed by an AREA attack
		# entirely — unless the destination hex IS the area's center. R26: an
		# UNDODGABLE area skips the roller escape outright (the roll is a
		# dodge-shaped escape; movement out of the radius already happened or
		# didn't) — no rng lives on this path either way.
		if not undodgable and other.rolled_this_window and other.position != actor.position:
			events.append({
				"type": "blast_missed_roller",
				"combatant": other.id, "by": actor.id,
				"at": [other.position.x, other.position.y],
				"center": [actor.position.x, actor.position.y],
			})
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
	# Wave 2d — "network fully exposed" (phase 4+): from the phase-4 valve on
	# the network NEVER re-hides. For the seeded Incinedile this was already
	# emergent (breach_resets_after_phase: 2 gates the retreat to the phase-2
	# valve only — the phase-4/6 blasts never retreated); the upgrade guard
	# makes the authored string the CANON rather than a data coincidence: even
	# a boss whose data retreats at a later valve stays exposed once the
	# upgrade is active.
	if health_part != "" and actor.parts.has(health_part) \
			and int(immunity.get("breach_resets_after_phase", 0)) == phase \
			and not has_upgrade(actor, "network_stays_exposed"):
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
		"death_spins": death_spins.duplicate(true),
	}


static func from_dict(data: Dictionary) -> EnemyAI:
	var ai := EnemyAI.new()
	ai.ai_rng.state = int(data.get("ai_rng_state", 0))
	ai.boss_phase = (data.get("boss_phase", {}) as Dictionary).duplicate(true)
	ai.summons = (data.get("summons", {}) as Dictionary).duplicate(true)
	ai.explosion_beats = (data.get("explosion_beats", {}) as Dictionary).duplicate(true)
	# Pre-wave-2b saves lack "death_spins": no live sequence, matching a fresh sim.
	ai.death_spins = (data.get("death_spins", {}) as Dictionary).duplicate(true)
	return ai
