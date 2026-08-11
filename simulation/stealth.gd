class_name Stealth
extends RefCounted
## R20 stealth & detection — the v1 BINARY SIGHT queries (KAN-5 wave 4c).
## Pure, static, stateless (MODEL — no Godot node deps, no rng, no state);
## CombatSim owns every mutation (the `stealth` command + the per-command
## `_stealth_checks` sweep read these).
##
## THE RULED MODEL (rules-addendum R20, owner 2026-07-18) and what v1 ships of
## it — R20's own phasing note authorizes exactly this slice ("v1 can ship the
## binary sight/hearing model on the existing hex positions"):
##  * SIGHT: "An entity sees out to roughly 2× its Mind stat in range" —
##    sight_range() resolves "roughly" to EXACTLY 2 × Mind (PROVISIONAL number,
##    R14 family — flagged in the addendum). "If you are seen, you are not
##    stealthed (binary: within cone + in range + line-of-sight + Mind
##    sufficient → revealed)": the Mind gate IS the range (Mind 0 = sight 0 —
##    a roach_dog never sees anyone, even adjacent); LOS walks the hex line;
##    vision CONES/facing are DOWNSCOPED (no positional facing exists — R20
##    itself defers true cones), so v1 sight is 360°.
##  * COVER: "Cover blocks line-of-sight/vision-cone per its geometry" — with
##    heights/sized gaps unmodeled (R20 defers them too), v1 cover is the
##    full-height solid set the R29 door work already promised LOS would read:
##    walls + CLOSED doors block sight through Arena.blocks_lane (is_wall +
##    out-of-bounds — the void beyond the room is not see-through); an OPEN
##    door blocks nothing. Objects (trash cans) deliberately do NOT block
##    sight: they are not in is_wall and no height model says they should
##    (flagged downscope, not an oversight).
##  * WHO OBSERVES: hostiles only — you hide WITH your allies FROM the enemy;
##    same-team (and self) observation never breaks stealth, mirroring
##    EnemyAI._opponents' hostility predicate (teams are explicit; a teamless
##    observer watches no one, a teamless target hides from any teamed
##    observer). An observer that cannot act (dead / removed / helpless —
##    fainted keeps no watch) sees nothing.
## Hearing (the Shock-T1 Shout wire), entry/exit, AI honesty and the sweep
## live in CombatSim/ConditionEngine/EnemyAI — see the R20 IMPLEMENTED marker
## in docs/rules-addendum.md for the full map + every downscope.


## R20 sight range: EXACTLY 2 × the observer's Mind trait total ("roughly 2×"
## resolved — PROVISIONAL, R14 numbers family). Mind 0 sees 0 hexes.
static func sight_range(observer: CombatantState) -> int:
	return 2 * observer.trait_total("mind")


## Line-of-sight between two hexes: the HexGeometry.line walk with every
## INTERMEDIATE hex tested against the arena's wall-like solids (walls +
## closed doors + out-of-bounds, via blocks_lane — the one R29 query).
## Endpoints never block (standing in a doorway is legal, and the observer/
## target occupy their own hexes). No arena = the unbounded legacy room:
## nothing blocks, exactly as before walls existed.
static func has_los(arena: Arena, from: Vector2i, to: Vector2i) -> bool:
	if arena == null:
		return true
	var line: Array[Vector2i] = HexGeometry.line(from, to)
	for i: int in range(1, line.size() - 1):
		if arena.blocks_lane(line[i]):
			return false
	return true


## The R20 binary sight check: does `observer` see `target` right now?
## Hostile + able to act + in range + LOS — no rng, no facing (v1 360°).
static func sees(observer: CombatantState, target: CombatantState, arena: Arena, tick: int) -> bool:
	if observer.id == target.id or observer.team == "" or observer.team == target.team:
		return false
	if not observer.can_act(tick):
		return false  # dead/removed/helpless (fainted) keeps no watch
	if CombatantState.hex_distance(observer.position, target.position) > sight_range(observer):
		return false
	return has_los(arena, observer.position, target.position)


## The first (sorted-id) living hostile observer that sees `target`, "" when
## nobody does. Deterministic — the sweep and the entry gate both report the
## same observer for the same state.
static func first_observer_seeing(combatants: Dictionary, target: CombatantState, arena: Arena, tick: int) -> String:
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		if sees(combatants[id], target, arena, tick):
			return String(id)
	return ""
