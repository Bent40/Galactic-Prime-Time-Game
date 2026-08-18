class_name Stealth
extends RefCounted
## R20 stealth & detection — the binary sight queries (KAN-5 wave 4c) plus the
## R30 FACING arcs (decision #33 — "the facing primitive... is part of the
## stealth engine too"). Pure, static, stateless (MODEL — no Godot node deps,
## no rng, no state); CombatSim owns every mutation (the `stealth` command +
## the per-command `_stealth_checks` sweep read these).
##
## THE RULED MODEL (rules-addendum R20, owner 2026-07-18) and what ships of it:
##  * SIGHT: "An entity sees out to roughly 2× its Mind stat in range" —
##    sight_range() resolves "roughly" to EXACTLY 2 × Mind (PROVISIONAL number,
##    R14 family — flagged in the addendum). "If you are seen, you are not
##    stealthed (binary: within cone + in range + line-of-sight + Mind
##    sufficient → revealed)": the Mind gate IS the range (Mind 0 = sight 0 —
##    a roach_dog never sees anyone, even adjacent); LOS walks the hex line;
##    vision CONES are REAL as of the facing primitive (decision #33 /
##    addendum R30 — retiring the wave-4c "no positional facing exists"
##    downscope): sees() is gated to the observer's FRONT ARC, the hex
##    resolution of R20's ±60° cone (see the ARC MODEL below). An observer
##    sees NOTHING in its rear arc — keeping out of the front arc is now a
##    real way to stay hidden.
##  * COVER: "Cover blocks line-of-sight/vision-cone per its geometry" — with
##    heights/sized gaps unmodeled (R20 defers them), v1 cover is the
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
## in docs/rules-addendum.md for the full map + every remaining downscope.
##
## ARC MODEL (R30 — the facing arcs). A combatant's `facing` is a direction
## index 0..5 into HexGeometry.DIRECTIONS (0=E, 1=NE, 2=NW, 3=W, 4=SW, 5=SE):
##
##      (0,-1) (1,-1)          NW  NE
##   (-1,0)  S  (1,0)    =    W    S    E     (S = the subject's hex)
##      (-1,1) (0,1)           SW  SE
##
## FRONT arc = the 3 directions {facing-1, facing, facing+1} (mod 6) — the hex
## resolution of R20's ±60° cone language (the same 120-degree wedge
## HexGeometry.cone sweeps). REAR arc = the opposite 3, {facing+2, facing+3,
## facing+4}. For facing 0 (E):
##
##        rear | front
##      NW  NE          FRONT = {SE, E, NE}   (indices 5, 0, 1)
##     W   S-->  E      REAR  = {NW, W, SW}   (indices 2, 3, 4)
##      SW  SE
##        rear | front
##
## A hex at ANY distance belongs to the arc of its DIRECTION from the subject
## (HexGeometry.direction_index — the canonical nearest-direction read), so
## the arcs are unbounded wedges; range is a separate gate (sight_range for
## vision, distance >= 1 for is_behind). BOUNDARY RULE (inherited from
## direction_index, documented): a hex exactly BETWEEN two adjacent directions
## (the "diagonal", e.g. E+NE = (2,-1)) ties toward the EARLIER
## HexGeometry.DIRECTIONS entry — (2,-1) reads E, (1,-2) reads NE, (-1,-1)
## reads NW, (-2,1) reads W, (-1,2) reads SW, and (1,1) (SE+E) reads E. The
## tie is global index order, deterministic, and pinned in tests/test_facing.


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


## R30 front-arc membership (the ARC MODEL in the header): is `other_pos`
## within the ±60° front wedge of a subject at `subject_pos` holding `facing`?
## True for the subject's own hex (no direction — a body you overlap is not
## behind you; unreachable for distinct combatants under occupancy anyway).
## Pure geometry, rng-free.
static func front_arc_contains(subject_pos: Vector2i, facing: int, other_pos: Vector2i) -> bool:
	var idx: int = HexGeometry.direction_index(subject_pos, other_pos)
	if idx < 0:
		return true  # same hex — never "outside the cone"
	var offset: int = (idx - facing + 6) % 6
	return offset <= 1 or offset == 5


## R30 rear-arc check — the "positioned behind" gate (decision #33: decapitate
## / slip_through / the intel family read this instead of Batch A's interim
## Exposed approximation): true when `other_pos` sits in the REAR arc of
## `subject` at ANY distance >= 1 (adjacent included). False for the subject's
## own hex (distance 0 has no direction).
static func is_behind(subject: CombatantState, other_pos: Vector2i) -> bool:
	if other_pos == subject.position:
		return false
	return not front_arc_contains(subject.position, subject.facing, other_pos)


## The R20 binary sight check: does `observer` see `target` right now?
## Hostile + able to act + FRONT ARC (R30 vision cone — decision #33 retires
## the v1 360° downscope) + in range + LOS — no rng. Consulted ONLY on the
## stealth-reveal sweep/entry, herding, and the intel paths — base
## targeting/detection stays default-EVERYONE-DETECTED (the R20 slice
## discipline: cones gate INFORMATION plays, never the base fight).
## Batch D (camouflage — the stealth MODIFIER): a target holding a live
## concealment (CombatantState.conceal, set by the stealth_conceal resolver)
## carries an override radius that CAPS the observer's effective sight range
## against THAT target — "revealed only within N spaces" (the authored core;
## L2-4 shrink N). Every other gate (hostility, can-act, front arc, LOS) is
## UNCHANGED — camouflage narrows how CLOSE a watcher must be, it never
## grants sight through walls or over shoulders. Composition is one min():
## the modifier can only ever shrink the reveal distance, never extend it
## past the observer's own 2×Mind range.
static func sees(observer: CombatantState, target: CombatantState, arena: Arena, tick: int) -> bool:
	if observer.id == target.id or observer.team == "" or observer.team == target.team:
		return false
	if not observer.can_act(tick):
		return false  # dead/removed/helpless (fainted) keeps no watch
	if not front_arc_contains(observer.position, observer.facing, target.position):
		return false  # R30: an observer sees nothing over its shoulder
	var reveal_range: int = sight_range(observer)
	if target.conceal_radius() > 0:
		reveal_range = mini(reveal_range, target.conceal_radius())
	if CombatantState.hex_distance(observer.position, target.position) > reveal_range:
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
