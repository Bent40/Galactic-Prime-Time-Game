class_name CombatantState
extends RefCounted
## Pure-state combatant record (MODEL — no Godot node deps).
##
## Built from a race/enemy seed shape (data/races.json, data/enemies.json) or an
## explicit spec. All mutation happens through CombatSim's command stream; this
## class only holds state plus cheap derived-stat queries (rules-addendum R6).

const SIZE_ORDER: Dictionary = {"Small": 0, "Medium": 1, "Large": 2, "Huge": 3}
const TRAIT_KEYS: Array[String] = ["physique", "reflexes", "mind", "charm"]
## R34 free-action budget (owner, 2026-08-19 — amends R3's single slot):
## how many free (0-Moment) actions one combatant may spend per reset window.
## PLACEHOLDER (R14) like every other authored number — the ruling's "2 per
## turn" shown as `FREE ACTIONS 1/2` on the HUD button.
##
## NAME/CADENCE NOTE (flagged, not silently resolved): R34 names the window a
## "Clock" ("per combatant per Clock, matching R3's existing reset cadence"),
## but R3's cadence as written AND as built is per TICK — reset_tick_flags()
## clears the budget at every tick advance (CombatSim._advance's sorted sweep),
## and the whole free-action family (free moves above all) is priced per tick.
## The constant keeps the ruling's vocabulary; the live window is the tick.
## See docs/rules-addendum.md R3 (2026-08-19 amendment) for the flag.
const FREE_ACTIONS_PER_CLOCK: int = 2

var id: String = ""
var display_name: String = ""
var team: String = ""
var category: String = "Contestant"  # Contestant / Mob / Elite / Boss
## The enemy-template key this combatant was built from (from_spec's "enemy"
## field); "" for race-built contestants and explicit no-template specs.
## Serialized so the view API's stable display token (view_combatants "token")
## survives save/load and replay identically.
var template_key: String = ""
var size: String = "Medium"
var position: Vector2i = Vector2i.ZERO
## FACING (decision #33 — the facing primitive; rules-addendum R30): an axial
## hex-direction index 0..5 into HexGeometry.DIRECTIONS / EnemyAI.HEX_NEIGHBORS
## (0=E, 1=NE, 2=NW, 3=W, 4=SW, 5=SE). Updated AUTOMATICALLY and
## deterministically by the R30 update table (targeted declares, resolved
## moves/repositions/leaps, dash charges, grapples — ActionResolver owns the
## seams; involuntary displacement never re-faces); there is NO facing command
## in v1 — a contestant cannot deliberately guard their back yet (documented
## R30 limitation). Staging default (CombatSim._add_combatant): face the
## nearest opponent at add time, else direction 0. Consumed by Stealth's R20
## front-arc vision cone (sees) and the is_behind rear-arc gates. Serialized
## ONLY while != 0 (the stealthed/last_action_target compat-pin pattern; the
## documented serialization default is 0) — see to_dict.
var facing: int = 0

## part_key -> {"name": String, "hp": int, "base_max_hp": int, "lethal": bool,
##              "disabled": bool, "destroyed": bool, "hidden": bool}
var parts: Dictionary = {}
## part_key -> {condition_id -> instance}; instance = {"tier": int, "delayed": bool,
##   "reapplied_this_clock": bool, "poison_type": String, "activation_delay": int,
##   "last_attack_advance_tick": int}
var conditions: Dictionary = {}
## Timers: {"kind": "suffocation"|"dissolution"|"death"|"bleed_out",
##   "condition": String, "part": String, "clocks_remaining": int, "delay": int,
##   "paused": bool}
var timers: Array[Dictionary] = []
## Shock high-water mark (R13): momentary-event model — no pool, no in-combat
## decay; reset fresh per combat (field default, like shock itself).
var shock: int = 0
## part_key -> true for every wound that has PRODUCED shock this combat. Re-abusing
## an already-shocked wound elevates the incoming source one tier (R13 per-organ).
var shocked_parts: Dictionary = {}
## Shock T2 (Stutter, R13): set when shock newly reaches T2 — the combatant's next
## resolved scheduled action simply FAILS (no Forced Action roll); cleared there.
var shock_stutter_pending: bool = false

## trait -> {"base": int, "bonus": int, "level_bonus": int}
var stats: Dictionary = {}
var level_points: int = 0
var camera_call_stacks_granted: int = 0  # granted by loadout/scenario (F1); adds to charm over-cap
## AUTHORED signature bit (decision log #25): {} for the many characters who have
## none, else {"key": String, "name": String, "line": String} straight off the
## loadout/spec. Not everyone has a bit — the sim REJECTS the_bit from an actor
## with an empty bit. Mechanically The Bit stays NULL (decision #15): this field
## is static identity data, never mutated by any command.
var bit: Dictionary = {}
## GRANTED loadout skills (same grant pattern as camera_call_stacks_granted /
## bit): normalized {"key": String, "level": int} rows straight off the spec's
## "skills", grant order preserved. Static grant data — never mutated by any
## command; skill_level() is the read. [] for enemies / skill-less specs.
var skills: Array[Dictionary] = []
var resistances: Dictionary = {"Physical": 0, "Affliction": 0, "Psychic": 0}
## Player-allocated Reflexes-derived physical resistance: condition_id -> int (R6).
var allocated_physical: Dictionary = {}
## R22 per-stat threshold dice (grant pattern like `skills`/`bit`): stat name ->
## die size, upgraded through progression (d4 -> d6 -> d8; KAN-7 prices it).
## Empty = the default d4 for every stat. Only "reflexes" is consumed today
## (dodge checks); the field is per-stat so future stat-threshold checks (Mind
## vs fear, Physique vs forced movement) inherit the mechanism.
var threshold_dice: Dictionary = {}

var boss_traits: Dictionary = {}
var breached: bool = false
## Enemy ability list (data/enemies.json shape) — consumed by EnemyAI (I-16).
var abilities: Array[Dictionary] = []
## Boss phase table (data/enemies.json "phases") — consumed by EnemyAI (I-16).
var boss_phases: Array[Dictionary] = []
## R23 antagonism (decision #29): opponent id -> grudge score (float >= 0).
## Lives on the AI actor doing the remembering, keyed by who earned it — net
## damage builds it 1:1 (PLACEHOLDER R14), a Feint builds it on a mock-sensitive
## personality, and it multiplies by the personality's decay each Clock reset.
## {} default (no history); EnemyAI's weighted targeting reads it.
var antagonism: Dictionary = {}
## R23 personality block (data/enemies.json "personality", spec-overridable —
## same source pattern as boss_traits): the targeting tuning surface. Raw
## authored dict; every read goes through a personality_*() accessor so absent
## keys fall back to the R23 defaults (mock_sensitive derives from Mind >= 3).
## The `spare_respect` field is a RESERVED hook (R23: sparing needs a detectable
## mercy event, none ships yet) — carried, validated, never read.
var personality: Dictionary = {}

## item_key -> item dict (normalized; ranged items carry "magazine_loaded").
var items: Dictionary = {}

var alive: bool = true
var removed_from_play: bool = false  # dissolution mind-collapse (R5) — never "died"

# Scheduling / per-tick bookkeeping
var next_action_tick: int = 0
var windup_pending: bool = false
## R3/R34 free-action budget — how many free (0-Moment) actions this combatant
## has spent in the current window (0..FREE_ACTIONS_PER_CLOCK). Spent by the
## whole free-action family: 0-cost declares, the free 1-3 space move, the
## first inventory interaction, 0-cost reactions, the bit, the door/voicebox
## family and the stealth entry. Cleared with the other per-tick flags
## (reset_tick_flags) — the cadence R3 has always run on, so no new sweep and
## no Clock stamp: the existing per-tick reset already owns the window (the
## treat_resolve_used_clock/negate_used_clock stamp idiom exists precisely
## because those gates have NO sweep; this one does). Serialized ONLY while
## > 0 (the negate_used_clock compat pin) so a fight that spends no free
## action hashes byte-identically to the pre-R34 engine.
var free_actions_used: int = 0
## COMPAT VIEW of the budget, kept because the whole engine (CombatSim's bit /
## door / voicebox paths, EnemyAI's free-move gate, the view API, the HUD, the
## harnesses) reads and writes this boolean: true = the budget is EXHAUSTED,
## `= true` SPENDS one entry, `= false` refunds the whole window. The
## rejection reason string stays "free_action_used" byte-identically.
var free_action_used: bool:
	get:
		return free_actions_used >= FREE_ACTIONS_PER_CLOCK
	set(value):
		if value:
			spend_free_action()
		else:
			free_actions_used = 0
var reaction_used: bool = false
var moved_this_tick: bool = false
## G1 Tactical Roll marker (rules-addendum R25): set when the combatant
## tactical-rolls, cleared with the other per-tick flags at the next tick start —
## the dodge window IS the roll's Moment ("you give up your movement for the
## Moment"). Consumed by the AoE-center rule: an AREA attack (the explosion
## blast) resolving this Moment MISSES a roller entirely unless the roller's
## hex is the area's CENTER. Single/multi-target windups need no marker — the
## roll's immediate position update flows through the R2 snapshot re-checks.
var rolled_this_window: bool = false
var inventory_uses: int = 0
var took_scheduled_action_this_clock: bool = false
var damage_taken_this_tick: int = 0
## R15/NQ2 single-hit breach tracking (reset each tick): the largest single hit
## landed this tick, where a combined action's linked strikes (shared combo_id)
## merge into one hit.
var largest_single_hit_this_tick: int = 0
var combo_hits_this_tick: Dictionary = {}  # combo_id -> accumulated damage this tick

# Priming substrate (rules-addendum R3, decision-log #20 — "cooldowns do not
# exist"). Skills gate on a PRIME (one of 5 canonical types) evaluated at declare
# by ActionResolver._prime_unmet; the state those predicates read lives here.
## CHAIN: the key of this actor's LAST resolved action ("" = none / cleared by a
## non-matching action). A chain prime {"after": k} is met when this equals k.
var last_action_key: String = ""
## CHAIN same-target gate (content pass batch A): the first target id of this
## actor's LAST resolved action ("" = none / a target-less action clears it).
## A chain prime {"after": k, "same_target": true} additionally requires the
## chained action's first target to equal this. Serialized ONLY while non-empty
## (the stealthed compat-pin pattern) so a fight that never resolves a targeted
## action hashes byte-identically to the pre-batch engine.
var last_action_target: String = ""
## CHAIN open marker (tier-2 wave 3 — predators_arc S2-b, [FROM row 40]): the
## key of a just-resolved action that OPENED its chain to ANY legal target —
## while set (and still the last resolved action), the SAME-TARGET half of a
## chain gate this actor's last action satisfies is WAIVED, so the chained
## skill may declare against a different (adjacent — its own reach gate)
## target ("the takedown feeds the next takedown"). Set by the opening
## resolver (predators_arc L2+); cleared by ActionResolver's chain bookkeeping
## the moment any OTHER action resolves (the last_action_key overwrite rule's
## mirror). Serialized ONLY while non-empty (the stealthed compat-pin
## pattern) so a fusion-free fight hashes byte-identically to the pre-wave
## engine.
var chain_open_key: String = ""
## STANCE: the stance the actor currently holds ("" = none). Set/cleared by the
## sim's set_stance command; a stance prime {"stance": s} is met when this == s.
var stance: String = ""
## PREP-CHANNEL: armed prep primes (key -> true). The sim's `prime` command arms
## one; using a prep-gated action consumes it (ActionResolver clears it at resolve).
var armed_primes: Dictionary = {}
## STACK: generic named-resource counter fallback (resource -> count) for stack
## primes whose resource is not the camera-call stack (that one reads derived_stats).
## Batch C: grantable via the combatant spec's `charges` field (from_spec) —
## field_triage's bandage_charge economy rides this counter.
var charges: Dictionary = {}

# Status effects / forced-action fallout
## R20 stealth (KAN-5 wave 4c): true while this combatant is STEALTHED —
## concealed from the opposing team's information surface (EnemyAI._opponents
## excludes it; hostile declares/reactions/grapples reject target_stealthed).
## Default false = detected (the opt-in compat pin). Entered via the sim's
## `stealth` command; broken by sight (Stealth.sees, swept every command), the
## Shock-T1 Shout (R13 noise seed), going down, or a voluntary reveal.
## Serialized ONLY while true, so a stealth-free fight's to_dict() — and every
## hash over it — stays byte-identical to the pre-stealth engine.
var stealthed: bool = false
var exposed_until_tick: int = 0
var helpless_until_tick: int = 0
var unarmed_until_tick: int = 0
var strained_grip: bool = false
var part_locked_until: Dictionary = {}  # part_key -> tick
var statuses: Dictionary = {}  # "overwhelmed"/"prone"/"slowed"/"incapacitated" -> true
var exposed_cache: bool = false

# Skill-effect state (SkillBook archetypes; ActionResolver owns the transitions).
## self_guard (brace): the next incoming Crush/Burn hit is reduced by this, then
## the guard is consumed (cleared to 0).
var brace_guard: int = 0
## setup_debuff (feint): set on the TARGET; its next resolved scheduled action
## collapses into a Forced Action – Tool, and the flag clears at that resolution.
var feint_forced: bool = false
## Who armed the pending feint (skill-feel pass): the feinter's id, kept so the
## collapse can emit an ATTRIBUTED feint_fallout event ("DARIO's feint pays
## off"). Set with feint_forced, cleared with it; a second feint before the
## first collapses overwrites (last feinter takes the credit — deterministic).
var feint_by: String = ""
## self_stance (dance): the actor is in the dance stance. Ends when hit, knocked
## Prone, or the actor commits to an attack / damaging skill.
var dancing: bool = false
## The Charm-effect bonus granted while dancing (per the dance level table).
var dance_charm: int = 0
## retarget_guard reaction form (intercept, batch B): the ARMED guard —
## {"ally": String, "range": int, "reduction": int}, recorded when the guard
## declare resolves (alongside armed_primes["intercept"], the PREP substrate).
## {} = no guard. While armed, a hit AIMED at the guarded ally within `range`
## retargets to this combatant at the top of _strike_round, costing the
## reaction slot per hit. Serialized ONLY while non-empty (the stealthed
## compat-pin pattern) so a guard-free fight hashes byte-identically.
var guard: Dictionary = {}
## retarget_guard stance form (iron_stance, batch B): the held stance —
## {"anchor": [q, r], "radius": int, "reduction": int, "types": [condition ids]}.
## {} = not held. While held (position == anchor, not Prone — the CombatSim
## _guard_checks sweep enforces the dance-exit pattern), hits AIMED at ANY
## adjacent ally retarget to this combatant (no reaction cost — the stance's
## value) and the NON-consumed flat reduction applies to covered-type damage
## this combatant takes. Serialized ONLY while non-empty (same compat pin).
var iron_stance: Dictionary = {}
## forced_roll_save (acrobatic_save, batch C): the ARMED save — {"dice": int}
## while armed via the G1 movement-forfeit declare (R25: NO prime, NO stance),
## {} = unarmed. The owner's next Forced Action – BODY roll consumes it
## (ActionResolver._forced_body_roll draws the extra dice and keeps the
## lowest-severity result). Serialized ONLY while non-empty (the stealthed
## compat-pin pattern) so a save-free fight hashes byte-identically.
var forced_save: Dictionary = {}
## intel_reveal declared form (read_the_pattern, batch C): live reveals —
## target_id -> {"actions": int}. A reveal lasts until the Clock reset
## (CombatSim's reset sweep clears the map and emits pattern_read_expired);
## while live, GameController projects the target's CURRENT scheduled entries
## onto this owner's view row (the knowledge stays fresh — reading an idle
## enemy pays off when they declare). Serialized ONLY while non-empty (same
## compat pin).
var pattern_reads: Dictionary = {}
## stealth_conceal (camouflage, batch D): the live concealment modifier —
## {"radius": int, "anchor": [q, r]} while camouflaged, {} otherwise. The
## radius CAPS every observer's effective sight range against THIS combatant
## (Stealth.sees reads it via conceal_radius() — "revealed only within N
## spaces"); the anchor is the hex the camouflage was woven on — ANY
## displacement off it (voluntary or involuntary, the iron_stance rule)
## breaks the camouflage AND the stealth it rides (the CombatSim
## _stealth_checks sweep). Cleared whenever stealth breaks/reveals for any
## reason — the modifier never outlives the stealth state it modifies.
## Serialized ONLY while non-empty (the stealthed compat-pin pattern).
var conceal: Dictionary = {}
## R20 hearing (round 3b) — the ALERTED state: set by CombatSim's noise sweep
## on an AI combatant that HEARD a noise from a source it cannot see. Shape:
## {"tick": int (when heard), "sound": [q, r] (the hex the SOUND happened
## on)}. Deliberately NO source id — R20's ruled wording: "becomes ALERTED —
## it does NOT know where you are": the state records a sound, never a who,
## so an investigator walks to where the sound WAS, not to the hider (the
## scapegoat/illusion/decoy design space rides exactly this gap). Refreshed
## by each newly heard noise; cleared by decay (a full quiet Clock) or going
## down — both in the noise sweep. AI-only in practice (the sweep's hearer
## gate), so it never rides the encounter carry: enemies are per-room and the
## RunState sanitizer never sees one (documented there-by-omission; the gate
## is the guarantee). Serialized ONLY while non-empty (same compat pin).
var alerted: Dictionary = {}
## sustained_channel (telekinesis, batch D): the live channel on the ACTOR —
## {"key": String, "target": String, "range": int, "sustained_tick": int}
## while gripping, {} otherwise. sustained_tick = the last tick a grip or
## sustain RESOLVED; a completing tick beyond it lapses the grip (the
## per-Moment upkeep — CombatSim's _advance_tick lapse check). While set:
## the actor is Exposed (ExposureEngine reads it, the R9-grapple mirror) and
## rooted (move/tactical roll reject "channeling"); any OTHER scheduled
## declare abandons the grip first (the sustain occupies the scheduled
## action). Serialized ONLY while non-empty (same compat pin).
var channeling: Dictionary = {}
## fused_evasion (perfect_evasion, tier-2 wave 1 — S5-c, OQ2 RULED): the live
## evasion-window record — {"answered": [entry seqs], "second_used": bool}
## while a L3+ fused arming is live this window, {} otherwise. "answered" =
## the Clock-queue seqs of every pending attack aimed at this combatant when
## a roll was declared (what that roll already dodged); the OQ2 second roll
## must name a pending attack NOT in the set — a same-attack re-roll rejects.
## Cleared with the other window markers at the tick advance
## (reset_tick_flags — the rolled_this_window lifetime). Serialized ONLY
## while non-empty (the stealthed compat-pin pattern).
var evasion: Dictionary = {}
## fused_evasion (perfect_evasion — S5-d, [FROM row 68]): the per-Clock
## negate gate — the Clock INDEX (tick / Clock.TICKS_PER_CLOCK) in which the
## armed save last negated a Forced Action – Body outright; -1 = never. The
## negate fires only while the current Clock index differs — a second negate
## in the same Clock falls back to the dice-softening path until the reset.
## Serialized ONLY while >= 0 (same compat pin).
var negate_used_clock: int = -1
## sustained_channel: the mirror on the TARGET — the id of the combatant
## telekinetically holding this one ("" = free). While set the target cannot
## take movement actions (move / tactical roll / the pounce leap reject
## "held"; "may still use arms" — attacks and other declares stay legal;
## involuntary displacement still moves the body and the grip's range
## re-check governs). Serialized ONLY while non-empty (same compat pin).
var held_by: String = ""
## fused_counter (counterscript, tier-2 wave 2 — S1-b, [FROM row 8]): the
## per-source counter-immunity windows — source_id -> until_tick. Armed when
## this combatant's counter CUT a source's windup without collapsing it ("you
## already answered it"); while clock.tick < until_tick, ANY strike-shaped
## effect FROM that source aimed at this combatant simply misses
## (ActionResolver._strike_round's top-of-round exclusion + the psychic seam
## — the immune actor is excluded from the effect against THEM only, others
## are still affected). Records persist past expiry and gate by comparison
## (the exposed_until_tick precedent — no sweep needed). Serialized ONLY
## while non-empty (the stealthed compat-pin pattern).
var counter_immunities: Dictionary = {}
## terrain_stride (quick_step, Round 3a): the live stride window — while
## clock.tick < this, difficult/rough hexes price as normal ground for this
## combatant in the R33 cost overlay (ActionResolver._move_cost_for). Set by
## the immediate quick_step declare (tick + stride_moments); 0 = never
## declared. Gates by comparison, no sweep (the exposed_until_tick
## precedent). Serialized ONLY while > 0 (the negate_used_clock compat-pin
## pattern) so a stride-free fight hashes byte-identically.
var quick_step_until_tick: int = 0
## ally_treatment resolve mode (combat_medic, tier-2 wave 2 — S6-d, [FROM
## row 6]): the per-Clock resolve gate — the Clock INDEX (tick /
## Clock.TICKS_PER_CLOCK) in which this medic last fully RESOLVED a
## condition through the S6-d path; -1 = never (the negate_used_clock
## precedent). A second resolve in the same Clock rejects at declare (and
## re-checks at resolution); the gate re-opens at the reset, no sweep
## needed. Serialized ONLY while >= 0 (same compat pin).
var treat_resolve_used_clock: int = -1
## sustained_con (the_long_con, tier-2 wave 4 — S9-a): the live con on the
## HOLDER — {"targets": {target_id -> "tool"|"body"}, "dice": int,
## "hype": int} while the con holds, {} otherwise. Each entry is one mark
## whose NEXT resolved action AGAINST this holder collapses into a Forced
## Action on the stored table (Tool default; Body only via the S9-c L3+
## choice), firing once per mark (the entry is consumed at the collapse).
## "dice" = the S9-b die-manipulation extras stamped at resolve; "hype" =
## the S9-d per-Clock performance base (0 below L4). Sanctioned ends
## (AUTHORED this wave, PLACEHOLDER family R14): the holder STRIKES
## (declaring a damaging action — the dance-end seam), a mark stops
## PERCEIVING the holder (the CombatSim _con_checks sweep reads
## Stealth.sees mark->holder), a party goes down, or the encounter ends
## (never carried — the RunState sanitizer). Serialized ONLY while
## non-empty (the stealthed compat-pin pattern).
var con: Dictionary = {}
## sustained_con: the mirror on the MARK — the id of the combatant whose con
## this one is under ("" = free). One con per mark (a second holder rejects
## at declare, the held_by precedent). Serialized ONLY while non-empty.
var conned_by: String = ""
## sustained_con (S9-a): banked free 1-hex repositions — each con firing
## grants the holder one ("each time it fires you may reposition 1 space at
## no cost" [PH]). Spent through the move command OUTSIDE the R3 movement
## economy (no slot, no allowance, no moved_this_tick); persists until spent
## or the encounter ends (AUTHORED lifetime, PLACEHOLDER R14 — deliberately
## surviving the con's own end so the last firing's step is never stillborn).
## Serialized ONLY while > 0 (the quick_step_until_tick compat-pin pattern).
var con_steps: int = 0

# Grapple (R9)
var grappling: String = ""
var grappled_by: String = ""

## Bleed-out state (R5): {} or {"condition": String, "part": String}
var bleed_out: Dictionary = {}


static func from_spec(spec: Dictionary, static_data: Dictionary) -> CombatantState:
	var c := CombatantState.new()
	c.id = String(spec.get("id", ""))
	c.display_name = String(spec.get("name", c.id))
	c.team = String(spec.get("team", ""))
	var template: Dictionary = {}
	if spec.has("race"):
		template = _find_template(static_data.get("races", []), String(spec["race"]))
	elif spec.has("enemy"):
		template = _find_template(static_data.get("enemies", []), String(spec["enemy"]))
		c.template_key = String(spec["enemy"])
		c.category = String(template.get("category", "Mob"))
	c.category = String(spec.get("category", c.category))
	c.size = String(spec.get("size", template.get("size", "Medium")))
	var pos: Array = spec.get("position", [0, 0])
	c.position = Vector2i(int(pos[0]), int(pos[1]))

	var trait_spec: Dictionary = spec.get("traits", template.get("stat_block", {}))
	for key: String in TRAIT_KEYS:
		var value: Variant = trait_spec.get(key, 1)
		if value is Dictionary:
			var d: Dictionary = value
			c.stats[key] = {
				"base": int(d.get("base", 1)),
				"bonus": int(d.get("bonus", 0)),
				"level_bonus": int(d.get("level_bonus", 0)),
			}
		else:
			c.stats[key] = {"base": int(value), "bonus": 0, "level_bonus": 0}
	c.level_points = int(spec.get("level_points", 0))
	# Granted Camera Call stacks (F1 fix): a loadout/scenario may GRANT stacks
	# directly (demo_loadouts.json `camera_call_stacks`) instead of manufacturing
	# them by inflating Charm over-cap (the old Charm-30 hack). Derived stacks =
	# granted + over-cap, so both sources compose.
	c.camera_call_stacks_granted = int(spec.get("camera_call_stacks", 0))
	# Authored bit (decision log #25): carried only when the spec declares one.
	c.bit = (spec.get("bit", {}) as Dictionary).duplicate(true)
	# Granted loadout skills (view-API grant pattern, like camera_call_stacks /
	# bit): each spec row is normalized to {key, level} — loadout annotations
	# (id / cap / cap_note / ...) are dropped; unkeyed rows are skipped. Fresh
	# dicts (deep-copied by construction); [] default.
	for skill_spec: Variant in spec.get("skills", []) as Array:
		var s: Dictionary = skill_spec
		var skill_key := String(s.get("key", ""))
		if skill_key == "":
			continue
		c.skills.append({"key": skill_key, "level": int(s.get("level", 1))})

	var res_spec: Dictionary = spec.get("resistances", template.get("resistances", {}))
	for res_key: String in ["Physical", "Affliction", "Psychic"]:
		c.resistances[res_key] = int(res_spec.get(res_key, 0))
	var racial: Dictionary = template.get("racial_traits", {})
	if racial.has("physical_resistance"):
		c.resistances["Physical"] += int(racial["physical_resistance"])
	var alloc: Dictionary = spec.get("allocated_physical_resistance", {})
	for alloc_key: Variant in alloc:
		c.allocated_physical[String(alloc_key)] = int(alloc[alloc_key])
	# R22 threshold dice (grant pattern like skills/bit): normalized stat -> die
	# size rows straight off the spec; absent = {} = d4 everywhere.
	var dice_spec: Dictionary = spec.get("threshold_dice", {})
	for die_key: Variant in dice_spec:
		c.threshold_dice[String(die_key)] = int(dice_spec[die_key])
	# Batch C: grantable STACK charges (the generic counter _stack_count reads —
	# field_triage's bandage_charge economy). Same grant pattern as
	# threshold_dice; absent = {} = no charges, byte-identical legacy specs.
	var charges_spec: Dictionary = spec.get("charges", {})
	for charge_key: Variant in charges_spec:
		c.charges[String(charge_key)] = int(charges_spec[charge_key])

	c.boss_traits = (spec.get("boss_traits", template.get("traits", {})) as Dictionary).duplicate(true)
	# R23 personality (decision #29): spec override wins, else the enemy
	# template's authored block, else {} (accessor defaults apply).
	c.personality = (spec.get("personality", template.get("personality", {})) as Dictionary).duplicate(true)
	for ability_spec: Variant in spec.get("abilities", template.get("abilities", [])) as Array:
		c.abilities.append((ability_spec as Dictionary).duplicate(true))
	for phase_spec: Variant in spec.get("phases", template.get("phases", [])) as Array:
		c.boss_phases.append((phase_spec as Dictionary).duplicate(true))

	var hp_bonus: int = c.hp_bonus_per_part()
	var part_specs: Array = spec.get("body_parts", template.get("body_parts", []))
	for part_spec: Variant in part_specs:
		var p: Dictionary = part_spec
		var key := String(p.get("key", ""))
		var base_max := int(p.get("hp", 1))
		c.parts[key] = {
			"name": String(p.get("name", key)),
			"hp": base_max + hp_bonus,
			"base_max_hp": base_max,
			"lethal": bool(p.get("lethal", false)),
			"disabled": bool(p.get("disabled", false)),
			"destroyed": bool(p.get("destroyed", false)),
			"hidden": bool(p.get("hidden_until_breach", false)),
			# F2 rework: a bleed_immune part has no blood — bleeding never applies
			# and the systemic bleed-out drain skips it (the mycelium network).
			"bleed_immune": bool(p.get("bleed_immune", false)),
			# Owner ruling 2026-07-20: per-part condition resistances. A condition in
			# `condition_immunities` never applies to this part (so it never builds
			# tiers or destroys it) — the mycelium network is immune to most
			# conditions. `fire_harms` exempts the part from the boss fire-heal, so
			# fire damages it instead of healing it. Force/HP damage is never gated.
			"condition_immunities": (p.get("condition_immunities", []) as Array).duplicate(),
			"fire_harms": bool(p.get("fire_harms", false)),
		}
		# R14 (decision-log #22): optional per-part armor feeds Robustness. Added
		# only when the seed specifies it — an absent field means 0 (see
		# ActionResolver._strike_round's parts[...].get("armor", 0)), so existing
		# part dicts and their serialized hashes are unchanged. It round-trips
		# automatically through parts.duplicate(true) in to_dict/from_dict.
		if p.has("armor"):
			c.parts[key]["armor"] = int(p["armor"])
		# Batch B (death_grip_jaws — the R9 grip gate parameterized): a
		# bite-capable part substitutes for hands in the skill-grapple grip
		# check (data-driven, seed/race layout). Added only when the seed
		# specifies it (the `armor` only-when-present idiom), so existing part
		# dicts and their serialized hashes are unchanged; round-trips through
		# parts.duplicate(true) automatically.
		if p.has("bite_capable"):
			c.parts[key]["bite_capable"] = bool(p["bite_capable"])

	for item_spec: Variant in spec.get("items", []) as Array:
		var item: Dictionary = {}
		if item_spec is String:
			item = _find_template(static_data.get("items", []), String(item_spec)).duplicate(true)
		else:
			item = (item_spec as Dictionary).duplicate(true)
		var item_key := String(item.get("key", ""))
		if item_key == "":
			continue
		if item.has("magazine") and not item.has("magazine_loaded"):
			item["magazine_loaded"] = int(item["magazine"])
		c.items[item_key] = item

	for status_key: String in ["overwhelmed", "prone", "slowed"]:
		if bool(spec.get(status_key, false)):
			c.statuses[status_key] = true
	return c


static func _find_template(entries: Variant, key: String) -> Dictionary:
	for entry: Variant in entries as Array:
		var d: Dictionary = entry
		if String(d.get("key", "")) == key:
			return d
	return {}


## The granted level for a loadout skill — 0 when the skill is NOT granted
## (callers treat 0 as "not known"; a declare may still run any key at an
## explicit level, exactly as before — the grant is state, not a gate).
func skill_level(key: String) -> int:
	for s: Dictionary in skills:
		if String(s.get("key", "")) == key:
			return int(s.get("level", 1))
	return 0


func trait_total(trait_key: String) -> int:
	var t: Dictionary = stats.get(trait_key, {})
	return int(t.get("base", 0)) + int(t.get("bonus", 0)) + int(t.get("level_bonus", 0))


## R22: the stat's threshold die size — default d4 when no upgrade was granted.
func threshold_die(trait_key: String) -> int:
	return maxi(1, int(threshold_dice.get(trait_key, 4)))


# ------------------------------------------------- personality reads (R23)
# The Antagonism engine's tuning surface (decision #29). All numbers
# PLACEHOLDER (R14). Absent keys fall back to the R23 defaults here, so an
# enemy template without a "personality" block behaves as the baseline mob.

## How steeply proximity dominates the targeting weight — 2.0 = inverse-square.
func personality_proximity_bias() -> float:
	return float(personality.get("proximity_bias", 2.0))


## Grudge multiplier in the targeting weight: 1.0 + grudge_weight * score.
func personality_grudge_weight() -> float:
	return float(personality.get("grudge_weight", 1.0))


## Can this creature even parse an insult? Default derives from Mind >= 3
## (the intelligence gate the owner ruled — incinedile's Mind 1 authors false).
func personality_mock_sensitive() -> bool:
	return bool(personality.get("mock_sensitive", trait_total("mind") >= 3))


## Grudge a single mockery (Feint) is worth to a mock-sensitive personality.
func personality_mock_grudge() -> float:
	return float(personality.get("mock_grudge", 2.0))


## Preference for wounded targets: 1.0 + low_hp_bias * (1 - hp/max_hp). The
## elite "picks off the weak" persona is now this bias, not a rule (R23).
func personality_low_hp_bias() -> float:
	return float(personality.get("low_hp_bias", 0.0))


## Per-Clock grudge multiplier at the reset (1.0 = never forgets — incinedile).
func personality_decay() -> float:
	return float(personality.get("decay", 1.0))


## R15 pack synergy gate (wave 3a): does this creature hunt as a pack? Authored
## on mob templates only (roach_dog); elites/bosses fight alone — default false.
func personality_pack_hunter() -> bool:
	return bool(personality.get("pack_hunter", false))


## R15 pack FAMILY (wave 3a, documented choice: the explicit personality key,
## not an id/enemy_key prefix): two pack hunters link only when both carry the
## same non-empty pack name ("roach"). "" = no family = never links.
func personality_pack() -> String:
	return String(personality.get("pack", ""))


## KAN-5 wave 4d herding gate (the war_hound's corner_the_prey signature —
## R11 #21): a pack of >= 2 herders sharing a `pack` family splits chase /
## cut-off roles (EnemyAI._herd_cutoff). Data-driven — the personality key is
## what the engine reads, never a species check; the corner_the_prey ability
## entry stays the authored flavor record. Default false.
func personality_herder() -> bool:
	return bool(personality.get("herder", false))


## Over-10 stat-cap formulas — adopted verbatim from the char-sheet app (R6).
static func over_cap(total: int, divisor: int) -> int:
	return int(floor(maxi(0, total - 10) / float(divisor)))


func hp_bonus_per_part() -> int:
	return over_cap(trait_total("physique"), 5)


func derived_stats() -> Dictionary:
	return {
		"hp_bonus_per_part": hp_bonus_per_part(),
		"physical_resistance_allocatable": over_cap(trait_total("reflexes"), 12),
		"psychic_resistance": over_cap(trait_total("mind"), 15),
		"camera_call_stacks": camera_call_stacks_granted + over_cap(trait_total("charm"), 20),
	}


func max_hp(part_key: String) -> int:
	var part: Dictionary = parts.get(part_key, {})
	return int(part.get("base_max_hp", 0)) + hp_bonus_per_part()


func condition_instance(part_key: String, condition_id: String) -> Dictionary:
	var on_part: Dictionary = conditions.get(part_key, {})
	return on_part.get(condition_id, {})


func condition_tier(part_key: String, condition_id: String) -> int:
	return int(condition_instance(part_key, condition_id).get("tier", 0))


func highest_tier_anywhere(condition_id: String) -> int:
	var highest: int = 0
	for part_key: Variant in conditions:
		highest = maxi(highest, condition_tier(String(part_key), condition_id))
	return highest


func part_usable(part_key: String, tick: int) -> bool:
	var part: Dictionary = parts.get(part_key, {})
	if part.is_empty() or bool(part["disabled"]) or bool(part["destroyed"]) or int(part["hp"]) <= 0:
		return false
	if int(part_locked_until.get(part_key, 0)) > tick:
		return false
	return true


## Hands = parts whose key contains "arm" or "hand" (human arms, enemy hands).
func usable_hands(tick: int) -> int:
	var count: int = 0
	var keys: Array = parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if (key.contains("arm") or key.contains("hand")) and part_usable(key, tick):
			count += 1
	return count


## Batch B (death_grip_jaws): the first usable bite-capable part in sorted key
## order, "" when none. The jaws-variant grip gate reads this instead of
## usable_hands — a bite-capable head substitutes for hands (R9 parameterized).
func bite_part(tick: int) -> String:
	var keys: Array = parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if bool((parts[key] as Dictionary).get("bite_capable", false)) and part_usable(key, tick):
			return key
	return ""


## Deterministic "acting part" for an action: first usable hand, else first part.
func acting_part(tick: int) -> String:
	var keys: Array = parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if (key.contains("arm") or key.contains("hand")) and part_usable(key, tick):
			return key
	if keys.is_empty():
		return ""
	return String(keys[0])


func is_helpless(tick: int) -> bool:
	return not bleed_out.is_empty() \
		or helpless_until_tick > tick \
		or statuses.get("incapacitated", false)


func can_act(tick: int) -> bool:
	return alive and not removed_from_play and not is_helpless(tick)


func size_rank() -> int:
	return int(SIZE_ORDER.get(size, 1))


## The Charm-effect bonus from the dance stance (self_stance) — 0 when not
## dancing. Charm-gated / spectacle consumers add this to the Charm read.
func dance_charm_bonus() -> int:
	return dance_charm if dancing else 0


## Batch D (camouflage): the live concealment's reveal radius — 0 when no
## camouflage is held. Stealth.sees caps the observer's effective sight range
## at this value when > 0 ("revealed only within N spaces").
func conceal_radius() -> int:
	return int(conceal.get("radius", 0))


## Axial hex distance — 1 space = 1 hex (R10/B8).
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


## R3/R34 free-action budget accessors — the counter's public surface. The
## engine asks has_free_action() before a 0-cost path and spend_free_action()
## when it takes one; free_actions_left() is what a HUD budget readout
## ("FREE ACTIONS 1/2") is derived from.
func free_actions_left() -> int:
	return maxi(0, FREE_ACTIONS_PER_CLOCK - free_actions_used)


func has_free_action() -> bool:
	return free_actions_used < FREE_ACTIONS_PER_CLOCK


func spend_free_action() -> void:
	free_actions_used = mini(free_actions_used + 1, FREE_ACTIONS_PER_CLOCK)


func reset_tick_flags() -> void:
	free_actions_used = 0
	reaction_used = false
	moved_this_tick = false
	rolled_this_window = false
	evasion = {}  # the fused-evasion window record shares the roll marker's lifetime
	damage_taken_this_tick = 0
	largest_single_hit_this_tick = 0
	combo_hits_this_tick.clear()


## Records a landed hit for single-hit breach checks (R15/NQ2). A combined
## action's linked strikes (same combo_id) accumulate into ONE merged hit — the
## party's designed path to a 7+ single-hit breach no lone attacker can clear.
func record_hit(combo_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var hit: int = amount
	if combo_id != "":
		hit = int(combo_hits_this_tick.get(combo_id, 0)) + amount
		combo_hits_this_tick[combo_id] = hit
	largest_single_hit_this_tick = maxi(largest_single_hit_this_tick, hit)


func to_dict() -> Dictionary:
	var out: Dictionary = {
		"id": id,
		"display_name": display_name,
		"team": team,
		"category": category,
		"template_key": template_key,
		"size": size,
		"position": [position.x, position.y],
		"parts": parts.duplicate(true),
		"conditions": conditions.duplicate(true),
		"timers": timers.duplicate(true),
		"shock": shock,
		"shocked_parts": shocked_parts.duplicate(true),
		"shock_stutter_pending": shock_stutter_pending,
		"stats": stats.duplicate(true),
		"level_points": level_points,
		"camera_call_stacks_granted": camera_call_stacks_granted,
		"bit": bit.duplicate(true),
		"skills": skills.duplicate(true),
		"resistances": resistances.duplicate(true),
		"allocated_physical": allocated_physical.duplicate(true),
		"threshold_dice": threshold_dice.duplicate(true),
		"boss_traits": boss_traits.duplicate(true),
		"breached": breached,
		"abilities": abilities.duplicate(true),
		"boss_phases": boss_phases.duplicate(true),
		"antagonism": antagonism.duplicate(true),
		"personality": personality.duplicate(true),
		"items": items.duplicate(true),
		"alive": alive,
		"removed_from_play": removed_from_play,
		"next_action_tick": next_action_tick,
		"windup_pending": windup_pending,
		"free_action_used": free_action_used,  # DERIVED: budget exhausted (R34)
		"reaction_used": reaction_used,
		"moved_this_tick": moved_this_tick,
		"rolled_this_window": rolled_this_window,
		"inventory_uses": inventory_uses,
		"took_scheduled_action_this_clock": took_scheduled_action_this_clock,
		"damage_taken_this_tick": damage_taken_this_tick,
		"largest_single_hit_this_tick": largest_single_hit_this_tick,
		"combo_hits_this_tick": combo_hits_this_tick.duplicate(true),
		"last_action_key": last_action_key,
		"stance": stance,
		"armed_primes": armed_primes.duplicate(true),
		"charges": charges.duplicate(true),
		"exposed_until_tick": exposed_until_tick,
		"helpless_until_tick": helpless_until_tick,
		"unarmed_until_tick": unarmed_until_tick,
		"strained_grip": strained_grip,
		"part_locked_until": part_locked_until.duplicate(true),
		"statuses": statuses.duplicate(true),
		"exposed_cache": exposed_cache,
		"brace_guard": brace_guard,
		"feint_forced": feint_forced,
		"feint_by": feint_by,
		"dancing": dancing,
		"dance_charm": dance_charm,
		"grappling": grappling,
		"grappled_by": grappled_by,
		"bleed_out": bleed_out.duplicate(true),
	}
	# R20 compat pin (wave 4c, the arena-key pattern): "stealthed" exists ONLY
	# while true — a stealth-free combatant serializes byte-identically to the
	# pre-stealth engine (state_hash covered either way).
	if stealthed:
		out["stealthed"] = true
	# Batch-A compat pin (same pattern): the chain same-target key exists ONLY
	# while a targeted action has resolved — hash-covered whenever it matters.
	if last_action_target != "":
		out["last_action_target"] = last_action_target
	# Batch-B compat pins (the same only-when-set pattern): the intercept guard
	# and the iron stance exist ONLY while armed/held — a fight that never uses
	# the retarget_guard family serializes byte-identically to the pre-batch
	# engine (hash-covered whenever either is live).
	if not guard.is_empty():
		out["guard"] = guard.duplicate(true)
	if not iron_stance.is_empty():
		out["iron_stance"] = iron_stance.duplicate(true)
	# Batch-C compat pins (the same only-when-set pattern): the armed save and
	# any live pattern reveals exist ONLY while set — a fight that never uses
	# the medics-&-minds batch serializes byte-identically to the pre-batch
	# engine (hash-covered whenever either is live).
	if not forced_save.is_empty():
		out["forced_save"] = forced_save.duplicate(true)
	if not pattern_reads.is_empty():
		out["pattern_reads"] = pattern_reads.duplicate(true)
	# Batch-D compat pins (the same only-when-set pattern): the camouflage
	# modifier, the telekinetic channel and the held-by mirror exist ONLY
	# while live — a fight that never uses the casters-&-showfolk batch
	# serializes byte-identically to the pre-batch engine (hash-covered
	# whenever any is live).
	if not conceal.is_empty():
		out["conceal"] = conceal.duplicate(true)
	# R20 hearing compat pin (round 3b, the same only-when-set pattern): the
	# ALERTED state exists ONLY while a heard-but-unseen noise is live — a
	# fight in which nothing alerting was ever heard serializes byte-
	# identically to the pre-hearing engine (hash-covered while live).
	if not alerted.is_empty():
		out["alerted"] = alerted.duplicate(true)
	if not channeling.is_empty():
		out["channeling"] = channeling.duplicate(true)
	if held_by != "":
		out["held_by"] = held_by
	# Tier-2 wave 1 compat pins (the same only-when-set pattern): the fused-
	# evasion window record and the per-Clock negate marker exist ONLY while
	# live/used — a fight that never uses perfect_evasion serializes
	# byte-identically to the pre-wave engine (hash-covered when either is).
	if not evasion.is_empty():
		out["evasion"] = evasion.duplicate(true)
	if negate_used_clock >= 0:
		out["negate_used_clock"] = negate_used_clock
	# Tier-2 wave 2 compat pins (the same only-when-set pattern): the
	# counter-immunity windows and the medic's per-Clock resolve marker exist
	# ONLY while armed/used — a fight that never uses counterscript or the
	# combat_medic resolve serializes byte-identically to the pre-wave engine
	# (hash-covered when either is live).
	if not counter_immunities.is_empty():
		out["counter_immunities"] = counter_immunities.duplicate(true)
	if treat_resolve_used_clock >= 0:
		out["treat_resolve_used_clock"] = treat_resolve_used_clock
	# R34 compat pin (the same only-when-set pattern): the free-action COUNTER
	# exists only once an entry has been spent this window — a fight in which
	# nobody spends a free action serializes byte-identically to the pre-R34
	# engine (the derived "free_action_used" bool above carries the legacy
	# shape, and reads false for both 0 and 1 spent).
	if free_actions_used > 0:
		out["free_actions_used"] = free_actions_used
	# Round 3a compat pin (the same only-when-set pattern): the quick_step
	# stride window exists ONLY once declared — a fight that never strides
	# serializes byte-identically to the pre-round engine.
	if quick_step_until_tick > 0:
		out["quick_step_until_tick"] = quick_step_until_tick
	# Tier-2 wave 3 compat pin (the same only-when-set pattern): the chain-open
	# marker exists ONLY between the opening resolution and the next resolved
	# action — a fight that never resolves a chain-opening fusion serializes
	# byte-identically to the pre-wave engine (hash-covered while live).
	if chain_open_key != "":
		out["chain_open_key"] = chain_open_key
	# Tier-2 wave 4 compat pins (the same only-when-set pattern): the con
	# record, its mark-side mirror and the banked con steps exist ONLY while
	# a con is live / a step is banked — a fight that never uses the_long_con
	# serializes byte-identically to the pre-wave engine (hash-covered
	# whenever any is live).
	if not con.is_empty():
		out["con"] = con.duplicate(true)
	if conned_by != "":
		out["conned_by"] = conned_by
	if con_steps > 0:
		out["con_steps"] = con_steps
	# R30 compat pin (decision #33, the same only-when-set pattern): "facing"
	# exists ONLY while != 0 — the documented serialization default is
	# direction 0 (E), so a combatant that never faced away from 0 serializes
	# byte-identically to the pre-facing engine. (A fight where the staging
	# default or the update table lands a non-zero facing legitimately grows
	# the key — hash-covered whenever it matters.)
	if facing != 0:
		out["facing"] = facing
	return out


static func from_dict(data: Dictionary) -> CombatantState:
	var c := CombatantState.new()
	c.id = String(data.get("id", ""))
	c.display_name = String(data.get("display_name", ""))
	c.team = String(data.get("team", ""))
	c.category = String(data.get("category", "Contestant"))
	c.template_key = String(data.get("template_key", ""))
	c.size = String(data.get("size", "Medium"))
	var pos: Array = data.get("position", [0, 0])
	c.position = Vector2i(int(pos[0]), int(pos[1]))
	c.parts = (data.get("parts", {}) as Dictionary).duplicate(true)
	c.conditions = (data.get("conditions", {}) as Dictionary).duplicate(true)
	for timer: Variant in data.get("timers", []) as Array:
		c.timers.append((timer as Dictionary).duplicate(true))
	c.shock = int(data.get("shock", 0))
	c.shocked_parts = (data.get("shocked_parts", {}) as Dictionary).duplicate(true)
	c.shock_stutter_pending = bool(data.get("shock_stutter_pending", false))
	c.stats = (data.get("stats", {}) as Dictionary).duplicate(true)
	c.level_points = int(data.get("level_points", 0))
	c.camera_call_stacks_granted = int(data.get("camera_call_stacks_granted", 0))
	c.bit = (data.get("bit", {}) as Dictionary).duplicate(true)
	for skill: Variant in data.get("skills", []) as Array:
		c.skills.append((skill as Dictionary).duplicate(true))
	c.resistances = (data.get("resistances", {}) as Dictionary).duplicate(true)
	c.allocated_physical = (data.get("allocated_physical", {}) as Dictionary).duplicate(true)
	c.threshold_dice = (data.get("threshold_dice", {}) as Dictionary).duplicate(true)
	c.boss_traits = (data.get("boss_traits", {}) as Dictionary).duplicate(true)
	c.breached = bool(data.get("breached", false))
	for ability: Variant in data.get("abilities", []) as Array:
		c.abilities.append((ability as Dictionary).duplicate(true))
	for phase: Variant in data.get("boss_phases", []) as Array:
		c.boss_phases.append((phase as Dictionary).duplicate(true))
	c.antagonism = (data.get("antagonism", {}) as Dictionary).duplicate(true)
	c.personality = (data.get("personality", {}) as Dictionary).duplicate(true)
	c.items = (data.get("items", {}) as Dictionary).duplicate(true)
	c.alive = bool(data.get("alive", true))
	c.removed_from_play = bool(data.get("removed_from_play", false))
	c.next_action_tick = int(data.get("next_action_tick", 0))
	c.windup_pending = bool(data.get("windup_pending", false))
	# R34: the counter wins when present; pre-R34 saves carry only the boolean,
	# where true = the (then single) slot was spent = the budget is exhausted.
	if data.has("free_actions_used"):
		c.free_actions_used = clampi(int(data["free_actions_used"]), 0, FREE_ACTIONS_PER_CLOCK)
	else:
		c.free_actions_used = FREE_ACTIONS_PER_CLOCK if bool(data.get("free_action_used", false)) else 0
	c.reaction_used = bool(data.get("reaction_used", false))
	c.moved_this_tick = bool(data.get("moved_this_tick", false))
	# Pre-R25 saves lack the marker: false matches a fresh tick (no live roll).
	c.rolled_this_window = bool(data.get("rolled_this_window", false))
	c.inventory_uses = int(data.get("inventory_uses", 0))
	c.took_scheduled_action_this_clock = bool(data.get("took_scheduled_action_this_clock", false))
	c.damage_taken_this_tick = int(data.get("damage_taken_this_tick", 0))
	c.largest_single_hit_this_tick = int(data.get("largest_single_hit_this_tick", 0))
	c.combo_hits_this_tick = (data.get("combo_hits_this_tick", {}) as Dictionary).duplicate(true)
	c.last_action_key = String(data.get("last_action_key", ""))
	# Pre-batch-A saves lack the key: "" = no targeted action resolved yet.
	c.last_action_target = String(data.get("last_action_target", ""))
	c.stance = String(data.get("stance", ""))
	c.armed_primes = (data.get("armed_primes", {}) as Dictionary).duplicate(true)
	c.charges = (data.get("charges", {}) as Dictionary).duplicate(true)
	c.exposed_until_tick = int(data.get("exposed_until_tick", 0))
	c.helpless_until_tick = int(data.get("helpless_until_tick", 0))
	c.unarmed_until_tick = int(data.get("unarmed_until_tick", 0))
	c.strained_grip = bool(data.get("strained_grip", false))
	c.part_locked_until = (data.get("part_locked_until", {}) as Dictionary).duplicate(true)
	c.statuses = (data.get("statuses", {}) as Dictionary).duplicate(true)
	c.exposed_cache = bool(data.get("exposed_cache", false))
	c.brace_guard = int(data.get("brace_guard", 0))
	c.feint_forced = bool(data.get("feint_forced", false))
	c.feint_by = String(data.get("feint_by", ""))
	c.dancing = bool(data.get("dancing", false))
	c.dance_charm = int(data.get("dance_charm", 0))
	c.grappling = String(data.get("grappling", ""))
	c.grappled_by = String(data.get("grappled_by", ""))
	c.bleed_out = (data.get("bleed_out", {}) as Dictionary).duplicate(true)
	# Pre-stealth saves lack the key: false = detected, the legacy default.
	c.stealthed = bool(data.get("stealthed", false))
	# Pre-facing saves lack the key: 0 (E) is the documented R30 default.
	c.facing = int(data.get("facing", 0))
	# Pre-batch-B saves lack both keys: {} = no guard armed / no stance held.
	c.guard = (data.get("guard", {}) as Dictionary).duplicate(true)
	c.iron_stance = (data.get("iron_stance", {}) as Dictionary).duplicate(true)
	# Pre-batch-C saves lack both keys: {} = no save armed / no live reveals.
	c.forced_save = (data.get("forced_save", {}) as Dictionary).duplicate(true)
	c.pattern_reads = (data.get("pattern_reads", {}) as Dictionary).duplicate(true)
	# Pre-batch-D saves lack all three: no camouflage, no channel, not held.
	c.conceal = (data.get("conceal", {}) as Dictionary).duplicate(true)
	# Pre-hearing saves lack the key: {} = nothing heard, the legacy default.
	c.alerted = (data.get("alerted", {}) as Dictionary).duplicate(true)
	c.channeling = (data.get("channeling", {}) as Dictionary).duplicate(true)
	c.held_by = String(data.get("held_by", ""))
	# Pre-tier-2-wave-1 saves lack both: no live evasion window, never negated.
	c.evasion = (data.get("evasion", {}) as Dictionary).duplicate(true)
	c.negate_used_clock = int(data.get("negate_used_clock", -1))
	# Pre-tier-2-wave-2 saves lack both: no immunity windows, never resolved.
	c.counter_immunities = (data.get("counter_immunities", {}) as Dictionary).duplicate(true)
	c.treat_resolve_used_clock = int(data.get("treat_resolve_used_clock", -1))
	# Pre-Round-3a saves lack the key: 0 = no stride window ever opened.
	c.quick_step_until_tick = int(data.get("quick_step_until_tick", 0))
	# Pre-tier-2-wave-3 saves lack the key: "" = no chain currently open.
	c.chain_open_key = String(data.get("chain_open_key", ""))
	# Pre-tier-2-wave-4 saves lack all three: no con, no mark, no banked step.
	c.con = (data.get("con", {}) as Dictionary).duplicate(true)
	c.conned_by = String(data.get("conned_by", ""))
	c.con_steps = int(data.get("con_steps", 0))
	return c
