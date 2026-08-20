class_name Exploration
extends RefCounted
## R34 — FREE-FORM EXPLORATION + CONTACT DETECTION (owner rulings 2026-08-19;
## the ruling text lives in docs/rules-addendum.md R34 + the R29 amendment).
## Pure, static, stateless (MODEL — no Godot node deps, no rng, no state);
## CombatSim owns the phase field, every mutation and the per-command sweep.
## The split mirrors simulation/stealth.gd: pure queries here, policy there.
##
## THE RULED MODEL and exactly what ships of it:
##  * "Exploration is FREE-FORM, not turn-based. Out of combat there is no
##    Clock, no Moment order, and no turn to end — the party walks freely;
##    movement costs nothing; the clock starts on contact." -> the sim carries
##    an explicit PHASE ("combat" | "exploration"). DEFAULT = combat, and the
##    key serializes only while it is NOT combat, so every legacy save, hash
##    and CI harness is byte-identical to the pre-exploration engine.
##    FREE-FORM means "no Moment/Clock accounting", NOT "outside the command
##    stream": an exploration phase is still a sequence of LOGGED commands and
##    state stays a pure function of (seed, ordered command log).
##    *** R35 REVISION (owner, 2026-08-19): "I think time should just be
##    moving. We have moment-to-time conversion units already established."
##    R34's clause "there is no Clock" is AMENDED — exploration is now "the
##    clock RUNS, but there is no turn order and nothing costs Moments".
##    advance_tick is LEGAL out of combat and IS the exploration time step
##    (R1: one tick ~ 0.5 fictional seconds, a Clock ~ 5); it runs the ONE
##    real tick path, never a parallel clock. The sim still never reads a wall
##    clock — the driver decides the real-time cadence and every step is a
##    logged command, so determinism is untouched. PAUSE is simply the driver
##    not issuing time steps: it needs NO sim state and has none (deliberate —
##    a paused flag would be a second time system pretending to be one field).
##    What still rejects out of combat is the MOMENT-ORDER family
##    (declare_action / combined_action / reaction / ai_decide, plus the
##    flagged inventory / camera_call / bit carry-over) — see
##    CombatSim.CLOCK_BOUND_COMMANDS, which also carries the note that the
##    reason string "clock_stopped" is now a legacy NAME for "no turn order".
##  * "exploration-time actions (opening doors, picking locks, voicebox
##    throws, scouting) are free out of combat and only regain their Moment
##    costs once the clock is running" -> in exploration the move / door /
##    stealth commands charge NO free-action slot, NO Moments and advance no
##    tick of their own. R35 completed the ruled set: the voicebox throw and
##    the lockpick — resolver-SCHEDULED declares R34 had to leave out — now
##    take the same waiver through ActionResolver.declare_free_form, and the
##    owner's same-day INVENTORY addition ("Time can pause during inventory
##    and item use in exploration mode so players can heal their characters
##    and the likes") gives the `inventory` command the same waiver through
##    ActionResolver.inventory_free_form — which additionally leaves R3's
##    `inventory_uses` first-free ledger untouched, so an out-of-combat heal
##    never charges the next fight. Pausing for the menu is, again, purely the
##    driver declining to issue time steps: NO sim state, and the KAN-6 driver
##    contract is "stop the beat while an inventory UI is open".
##  * "CONTACT IS SIGHT OR HEARING. The clock starts the moment either sense
##    lands: an enemy sees a contestant (R20 sight, R30 front arc, concealment
##    respected) or hears one (R20 hearing/loudness)." -> first_contact()
##    below IS that predicate, composed entirely out of the R20/R30 substrates
##    (Stealth.sees / Stealth.derive_noises / Stealth.hears — nothing about
##    detection is re-implemented here) and rng-FREE (neither ruled sense
##    authors a roll, so none was invented).
##  * "The mockup's 'ENTER > <route>' remains the deliberate way in; contact is
##    the involuntary one." -> the phase command's combat side is the
##    deliberate entry: it emits combat_started {reason: "deliberate"} and NO
##    contact event.
##
## THE DIRECTION OF CONTACT (a documented reading, flagged not hidden). R34's
## own examples are both ENEMY-detects-contestant ("a contestant walking into
## a mob's cone and a mob hearing a smashed door are the same event"), so the
## DETECTOR is always the AI-controlled side and the DETECTED is always a
## player-controlled body. A contestant who SEES a mob does not start the
## fight — that is the stealth design space R20 pays for (you may watch a
## guard and walk around him). If the owner rules the mirror direction later,
## it is one loop in first_contact().
##
## WHY HEARING DOES NOT REUSE THE COMBAT NOISE FILTER (the one real seam
## decision). CombatSim._noise_checks consumes a noise row only while its
## source is still HIDDEN, because inside combat everyone is DEFAULT-DETECTED
## and a visible actor's noise is redundant with detection itself. Out of
## combat that premise is FALSE — detection is precisely the open question —
## and R34 names the case verbatim: "a door heard through a wall can pull a
## room onto you before you enter it" (nobody smashing a door in exploration
## is stealthed). So contact consumes EVERY derived row from a hostile
## player-side source, hidden or not. The alerted/investigate machinery is
## untouched: it keeps its own combat discipline and runs alongside.
##
## NUMBERS: none authored by the R34 half. Sight range, the front arc,
## conceal radius and the loudness table are all R20/R30 values (PLACEHOLDER,
## R14 family) read straight off simulation/stealth.gd. The R35 half at the
## bottom of this file DOES author numbers (the patrol leash + every
## exploration-spectacle magnitude) — each one PLACEHOLDER (R14) and named at
## its constant.
##
## R35 (owner, 2026-08-19) turns this from a movement mode into a living one,
## in three pieces that all live below — plus the same-day TIME revision
## folded into the R34 bullet above: the free-form DECLARE waiver (voicebox +
## lockpicking), the PATROL beat (mobs stop being statues, stepping once per
## exploration TIME STEP), and the WALK's spectacle (the crowd watches
## exploration). See the R35 banner.

const PHASE_COMBAT: String = "combat"
const PHASE_EXPLORATION: String = "exploration"

## The free-form walk's routing budget (see CombatSim._explore_move). R34
## prices exploration movement at NOTHING, so the only job left for a budget
## is to bound the planner: Pathing's own expansion cap is the honest ceiling
## — past it the planner falls back to the greedy walk and an unreachable ask
## is rejected honestly rather than hanging. Not a game number.
const WALK_BUDGET: int = Pathing.MAX_EXPANSIONS


## THE CONTACT PREDICATE (R34). Returns {} when nobody has made contact, else
## {"by": detector_id, "target": detected_id, "sense": "sight"|"hearing"}.
##
## Verbatim: for each AI-controlled combatant D in sorted-id order that can
## act (dead / removed / helpless makes no contact — the Stealth.sees gate,
## mirrored for hearing so a fainted guard neither watches nor listens):
##   SIGHT   — the first non-AI combatant T in sorted-id order with
##             Stealth.sees(D, T, arena, tick): hostility, the R30 FRONT ARC,
##             2 x Mind range, the R20/S8 conceal radius cap and hex-line LOS
##             through walls + CLOSED doors are all that query's own gates.
##   HEARING — else the first noise row N of THIS command's batch (batch
##             order — the freshest sound loses to the earliest here on
##             purpose: contact is a threshold, not a tracked sound, and the
##             earliest audible row is the one that actually landed first)
##             whose source is a non-AI combatant hostile to D, with
##             Stealth.hears(D.position, N.position, N.loudness).
## Sight is tested before hearing for the same detector because sight is the
## stronger sense (it LOCATES the contestant; hearing only places a sound).
## Deterministic — sorted ids throughout, first match wins. ZERO rng.
static func first_contact(combatants: Dictionary, arena: Arena, tick: int, noises: Array[Dictionary]) -> Dictionary:
	var ids: Array = combatants.keys()
	ids.sort()
	for detector_id: Variant in ids:
		var detector: CombatantState = combatants[detector_id]
		if not EnemyAI.is_ai_controlled(detector):
			continue
		if not detector.can_act(tick):
			continue
		for target_id: Variant in ids:
			var target: CombatantState = combatants[target_id]
			if EnemyAI.is_ai_controlled(target):
				continue
			if Stealth.sees(detector, target, arena, tick):
				return {"by": detector.id, "target": target.id, "sense": "sight"}
		for noise: Dictionary in noises:
			var source: CombatantState = combatants.get(String(noise.get("source", "")))
			if source == null or EnemyAI.is_ai_controlled(source):
				continue
			if detector.team == "" or detector.team == source.team:
				continue  # hostile sources only (the Stealth.sees team predicate)
			if Stealth.hears(detector.position, noise.get("position", Vector2i.ZERO), int(noise.get("loudness", 0))):
				return {"by": detector.id, "target": source.id, "sense": "hearing"}
	return {}


# =====================================================================
# R35 — THE EXPLORATION LAYER (owner rulings 2026-08-19; ruling text in
# docs/rules-addendum.md R35). Three features, all still pure/static/rng-free
# here: the FREE-FORM DECLARE waiver, the PATROL beat, and the WALK's
# spectacle. CombatSim owns every mutation, exactly as above.
# =====================================================================

## R35 #1 — "Voicebox and lockpicking WORK in exploration." Both are
## ActionResolver-SCHEDULED declares (the resolver owns their Moment cost), so
## R34 shipped them on the `clock_stopped` reject list. The owner's waiver is
## theirs alone: **no Moment cost, no free-action budget, no scheduling**
## while the clock is stopped — and full R3 costs the instant combat starts.
## The waiver is keyed on the ARCHETYPE, not the skill key, so the two ruled
## SKILLS are named exactly once (a future exploration-shaped archetype joins
## this list and nothing else changes). Every OTHER declare keeps rejecting
## `clock_stopped`, byte-identically. The owner's third waived act, the
## `inventory` command, is not a declare at all and is routed by CombatSim
## straight to ActionResolver.inventory_free_form.
const FREE_FORM_ARCHETYPES: Array[String] = ["thrown_sound", "scheduled_pick"]

## R35 #2 — the DERIVED patrol's leash: how far a pacing sentry wanders from
## its anchor before turning around. PLACEHOLDER (R14) — authored here, not
## ruled. An authored `route` ignores it entirely.
const PATROL_PACE_REACH: int = 3

## R35 #3 — THE CROWD WATCHES EXPLORATION. Every magnitude below is
## PLACEHOLDER (R14), authored by this story and documented in the addendum:
##  * DANGER — "proximity to a live hostile". Scored off the NEAREST live
##    hostile's distance to the hex walked to: nothing past the radius, then
##    a linear ramp inward (STEP x (RADIUS + 1 - d)) — 2 at the edge, 12 in
##    its face. A cleared room has no hostile and therefore pays NOTHING,
##    which is the ruling's whole point ("the crowd is bored by safety").
##  * UNSEEN — "good stealth": moving with danger nearby and NOT currently
##    seen by any live hostile (Stealth.first_observer_seeing, the same query
##    the stealth sweep uses — hidden by a skill or by a wall, both count).
##  * IN-CONE — "the money shot": unseen while standing INSIDE a live
##    hostile's vision cone (the R30 front arc within its 2 x Mind sight
##    range). Composes ON TOP of UNSEEN — creeping through the eyeline is
##    strictly better television than creeping behind a wall.
##  * BOSS — "approaching a large boss": per hex CLOSED on the nearest live
##    Huge/Boss-category enemy this walk. Backing away pays nothing (the
##    crowd wants the approach, not the retreat).
const SPECTACLE_DANGER_RADIUS: int = 6
const SPECTACLE_DANGER_STEP: int = 2
const SPECTACLE_UNSEEN_BONUS: int = 4
const SPECTACLE_IN_CONE_BONUS: int = 8
const SPECTACLE_BOSS_STEP: int = 6
## The "large" half of "approaching a large boss" (R35): the boss CATEGORIES
## plus the Huge size band — a Huge elite closes the same distance drama.
const SPECTACLE_BOSS_CATEGORIES: Array[String] = ["Boss", "Super Boss"]
const SPECTACLE_BOSS_SIZE: String = "Huge"


# ------------------------------------------------- R35 #1: the free-form declare

## Is THIS declare one of R35's two waived acts? Pure lookup through the
## SkillBook (the archetype is the identity — see FREE_FORM_ARCHETYPES).
## Non-skill kinds and unknown keys are never waived.
static func is_free_form_declare(action: Dictionary) -> bool:
	if String(action.get("kind", "attack")) != "skill":
		return false
	var spec: Dictionary = SkillBook.mechanics(
		String(action.get("key", "")), int(action.get("level", 1)))
	return FREE_FORM_ARCHETYPES.has(String(spec.get("archetype", "")))


# ------------------------------------------------------- R35 #2: the patrol beat

## Normalizes a spec/template `patrol` value into the serialized state dict
## CombatantState carries. TWO authored shapes, one storage:
##   true / {}                 -> the DERIVED PACE: {"anchor": [q, r],
##                                "reach": PATROL_PACE_REACH} — the sentry
##                                walks its own facing axis out to `reach`
##                                hexes from where it was staged, then turns
##                                around. Zero authoring, zero rng.
##   {"route": [[q, r], ...]}  -> the AUTHORED CYCLE: the mob walks waypoint
##                                to waypoint and wraps at the end (a
##                                two-point route IS "pacing between staged
##                                points"; a longer one is a circuit).
##                                "reach"/"anchor" are ignored.
## Anything else (false, a malformed row) -> {} = no patrol = the pre-R35
## statue. Returns a fresh dict; never mutates the spec.
static func patrol_from_spec(value: Variant, staged: Vector2i) -> Dictionary:
	if value is bool:
		if not bool(value):
			return {}
		return {"anchor": [staged.x, staged.y], "reach": PATROL_PACE_REACH}
	if not (value is Dictionary):
		return {}
	var spec: Dictionary = value
	var route: Array = spec.get("route", [])
	if not route.is_empty():
		var clean: Array = []
		for row: Variant in route:
			var pair: Array = row if row is Array else []
			if pair.size() == 2:
				clean.append([int(pair[0]), int(pair[1])])
		if not clean.is_empty():
			return {"route": clean, "index": int(spec.get("index", 0))}
	var anchor_raw: Array = spec.get("anchor", [staged.x, staged.y])
	var anchor: Array = anchor_raw if anchor_raw.size() == 2 else [staged.x, staged.y]
	return {
		"anchor": [int(anchor[0]), int(anchor[1])],
		"reach": maxi(0, int(spec.get("reach", PATROL_PACE_REACH))),
	}


## THE PATROL STEP (R35 #2) — what this mob does with the one beat the
## exploration TIME STEP just granted it. PURE and rng-FREE: a function of the
## mob's own stored patrol record, its position/facing, the arena and the
## occupancy set. The beat is CombatSim._advance_tick while phase ==
## exploration (owner, 2026-08-19: "time should just be moving"); this
## function is the deterministic half that rests on — same command log, same
## steps, forever.
##
## Returns an instruction dict, any subset of:
##   {"index": int}  — the authored cycle's cursor advanced (store it even
##                     when no step follows: the mob really did ARRIVE).
##   {"to": Vector2i} — take this step (CombatSim faces the mover along it).
##   {"facing": int}  — about-face instead of stepping (the derived pace's
##                     turn; the beat is spent turning, the eyeline moves).
## {} = hold this beat (blocked route, degenerate waypoints).
static func patrol_step(mob: CombatantState, arena: Arena, occupied: Dictionary) -> Dictionary:
	if mob.patrol.is_empty():
		return {}
	var route: Array = mob.patrol.get("route", [])
	if not route.is_empty():
		return _patrol_route_step(mob, route, arena, occupied)
	return _patrol_pace_step(mob, arena, occupied)


## The AUTHORED CYCLE. Standing ON the current waypoint advances the cursor
## (wrapping at the end — a route is a loop, so a two-point route paces), then
## ONE step of the deterministic optimal route toward the new waypoint is
## taken. A blocked or unreachable waypoint HOLDS (a body in the corridor is
## temporary; thrashing to a different goal is not) and is retried next beat.
static func _patrol_route_step(mob: CombatantState, route: Array, arena: Arena, occupied: Dictionary) -> Dictionary:
	var index: int = int(mob.patrol.get("index", 0)) % route.size()
	var goal: Vector2i = _patrol_hex(route[index])
	var out: Dictionary = {}
	if mob.position == goal:
		index = (index + 1) % route.size()
		goal = _patrol_hex(route[index])
		out["index"] = index
	if mob.position == goal:
		return out  # a one-point (or duplicated) route: the post IS the goal
	var steps: Array[Vector2i] = Pathing.next_steps(
		mob.position, goal, WALK_BUDGET, 0, occupied, arena)
	if steps.is_empty():
		return out
	out["to"] = steps[0]  # ONE hex per beat, whatever the terrain costs
	return out


## The DERIVED PACE (no authored route): step forward along the mob's own
## FACING while the hex ahead is walkable, unoccupied and still within
## `reach` of the anchor; otherwise spend the beat turning 180 degrees. The
## sentry therefore sweeps a fixed line and its cone sweeps with it — which is
## the whole point of the ruling ("their eyelines move with them").
static func _patrol_pace_step(mob: CombatantState, arena: Arena, occupied: Dictionary) -> Dictionary:
	var anchor: Vector2i = _patrol_hex(mob.patrol.get("anchor", []))
	var reach: int = int(mob.patrol.get("reach", PATROL_PACE_REACH))
	var ahead: Vector2i = mob.position + HexGeometry.DIRECTIONS[posmod(mob.facing, 6)]
	if CombatantState.hex_distance(ahead, anchor) <= reach and not occupied.has(ahead) \
			and (arena == null or (arena.in_bounds(ahead) and not arena.blocks_movement(ahead))):
		return {"to": ahead}
	return {"facing": posmod(mob.facing + 3, 6)}


## [q, r] -> Vector2i (a malformed/absent pair reads as the origin — the
## patrol_from_spec normalizer never stores one).
static func _patrol_hex(pair_raw: Variant) -> Vector2i:
	var pair: Array = pair_raw if pair_raw is Array else []
	if pair.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(pair[0]), int(pair[1]))


# --------------------------------------------- R35 #3: the crowd watches the walk

## THE EXPLORATION SPECTACLE (R35 #3) — what the crowd paid to see in a
## free-form walk from `from` to `to`. PURE and rng-FREE; the magnitudes are
## the PLACEHOLDER constants above. Returns {} when the walk earns NOTHING
## (the cleared-room case), else
##   {"points": int, "danger": int, "stealth": int, "boss": int}
## and CombatSim stamps `points` onto the walk's own `moved` event as the
## GENERIC "spectacle_points" field — the ingest hook HypeEngine has carried
## since v1 for exactly this ("authored/boss/environment content"). No new
## hype plumbing exists and none was needed: exploration hype lands in the
## same meter, in the same ledger, under the same Camera-Call/surge
## multipliers, and therefore rides the R29 chain carry unchanged.
##
## Only a PLAYER-side walk is scored (a patrolling mob's step is scenery, not
## a performance) — CombatSim's caller enforces it.
## "Cross-party meetings", R35's fourth ruled source, is DEFERRED and NOT
## implemented: no shared-world stage exists to meet a second party in
## (DIRECTION Stage 1+). Recorded in the addendum, not silently dropped.
static func walk_spectacle(mover: CombatantState, combatants: Dictionary, arena: Arena, tick: int, from: Vector2i, to: Vector2i) -> Dictionary:
	var ids: Array = combatants.keys()
	ids.sort()
	var nearest: int = -1
	var in_cone: bool = false
	var boss_from: int = -1
	var boss_to: int = -1
	for id: Variant in ids:
		var other: CombatantState = combatants[id]
		if not EnemyAI.is_ai_controlled(other) or not other.can_act(tick):
			continue
		if other.team == "" or other.team == mover.team:
			continue  # hostiles only (the Stealth.sees team predicate)
		var d: int = CombatantState.hex_distance(other.position, to)
		if nearest < 0 or d < nearest:
			nearest = d
		# The money shot's geometry: inside the R30 front arc AND inside the
		# R20 sight range. Whether the mob ACTUALLY sees the mover is the
		# separate `unseen` gate below — being in the cone and not seen is
		# precisely what earns the bonus.
		if not in_cone and d <= Stealth.sight_range(other) \
				and Stealth.front_arc_contains(other.position, other.facing, to):
			in_cone = true
		if _spectacle_is_large(other):
			var df: int = CombatantState.hex_distance(other.position, from)
			var dt: int = d
			if boss_to < 0 or dt < boss_to:
				boss_from = df
				boss_to = dt
	if nearest < 0 and boss_to < 0:
		return {}  # a cleared room pays nothing — the ruling, verbatim
	var danger: int = 0
	if nearest >= 0 and nearest <= SPECTACLE_DANGER_RADIUS:
		danger = SPECTACLE_DANGER_STEP * (SPECTACLE_DANGER_RADIUS + 1 - nearest)
	var stealth: int = 0
	var unseen: bool = Stealth.first_observer_seeing(combatants, mover, arena, tick) == ""
	if unseen and nearest >= 0 and nearest <= SPECTACLE_DANGER_RADIUS:
		stealth = SPECTACLE_UNSEEN_BONUS
	if unseen and in_cone:
		stealth += SPECTACLE_IN_CONE_BONUS
	var boss: int = 0
	if boss_to >= 0 and boss_from > boss_to:
		boss = SPECTACLE_BOSS_STEP * (boss_from - boss_to)
	var points: int = danger + stealth + boss
	if points <= 0:
		return {}
	return {"points": points, "danger": danger, "stealth": stealth, "boss": boss}


## "a large boss" (R35): a Boss-category enemy, or anything in the Huge size
## band (a Huge elite closes the same distance drama).
static func _spectacle_is_large(c: CombatantState) -> bool:
	return SPECTACLE_BOSS_CATEGORIES.has(c.category) or c.size == SPECTACLE_BOSS_SIZE
