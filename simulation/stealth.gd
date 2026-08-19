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
## HEARING (round 3b — the second sense) lives at the bottom of this file:
## the loudness table + the pure noise derivation/`hears` queries; the
## Shock-T1 Shout self-break wire, entry/exit, AI honesty and both sweeps
## (stealth + noise) live in CombatSim/ConditionEngine/EnemyAI — see the R20
## IMPLEMENTED marker in docs/rules-addendum.md for the full map + every
## remaining downscope.
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


# --------------------------------------------------- hearing (R20 round 3b)
## THE NOISE MODEL — hearing is R20's SECOND SENSE (closing the wave-4c
## "hearing beyond the Shout" downscope; contract in the rules-addendum R20
## "SHIPPED — hearing/alert" marker). Pure DERIVATION: a command's event
## batch maps to noise rows through the loudness table below — no new
## emission points anywhere in the resolver, the events the sim already
## emits ARE the sounds. Deterministic and rng-FREE: R20's hearing text
## authors a personality REACTION ("may, per its personality/AI,
## investigate, ignore, or otherwise react"), never a detection roll, so
## hearing touches neither rng stream. CONSUMPTION (who hears what, the
## ALERTED state) lives in CombatSim._noise_checks — this file stays the
## pure-query authority, mirroring the sight split.
##
## THE LOUDNESS TABLE (every value PLACEHOLDER, R14 family). Loudness IS the
## hearing range in hexes — R20 authors no per-creature hearing acuity and
## none is invented; sound is omnidirectional and deliberately ignores LOS
## (no wall-acoustics model exists — a shout carries through a closed door;
## muffling is future numbers work, not silently assumed):
##   shout (shock_shout — the R13/R20 noise seed)      -> LOUD     (10)
##   attack resolutions / explosions / door flips      -> MODERATE (6)
##   movement (moved — free and scheduled alike)       -> QUIET    (3)
## v1 SOURCE MAP (exhaustive): shock_shout, action_resolved kind "attack",
## explosion_blast, door_changed, moved. Everything else that plausibly makes
## sound (reactions, grapples, zone effects, trash cans, treatment...) is
## DOWNSCOPED loudly in the addendum — no ruled loudness row yet; extend the
## table there first, then here.
const NOISE_LOUD: int = 10
const NOISE_MODERATE: int = 6
const NOISE_QUIET: int = 3


## Derives THIS batch's noise rows: [{"source": id, "position": Vector2i,
## "loudness": int}], in batch (event) order — deterministic. The derivation
## is HONEST AND COMPLETE per the table: every mapped event yields its row
## whether the source is hidden or seen — redundancy filtering is the
## CONSUMER's job (CombatSim._noise_checks documents the default-detected
## discipline). Position rule: the hex where the sound HAPPENED — the event's
## own position when it carries one (explosion_blast / door_changed; moved
## uses its destination "to" — the footfalls end there), else the source's
## sweep-time position (batch events do not all carry positions; documented
## v1 simplification). A sourceless/unknown-source row is skipped (nothing
## ruled hears the environment itself yet — trash cans ride the downscope).
static func derive_noises(events: Array[Dictionary], combatants: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events:
		match String(event.get("type", "")):
			"shock_shout":
				_append_noise(out, combatants, String(event.get("combatant", "")), [], NOISE_LOUD)
			"action_resolved":
				if String(event.get("kind", "")) == "attack":
					_append_noise(out, combatants, String(event.get("actor", "")), [], NOISE_MODERATE)
			"explosion_blast":
				_append_noise(out, combatants, String(event.get("combatant", "")), event.get("position", []), NOISE_MODERATE)
			"door_changed":
				_append_noise(out, combatants, String(event.get("actor", "")), event.get("position", []), NOISE_MODERATE)
			"moved":
				_append_noise(out, combatants, String(event.get("actor", "")), event.get("to", []), NOISE_QUIET)
	return out


## Appends one noise row; `position` is the event-carried [q, r] pair when it
## has one, else the source combatant's current hex (see derive_noises).
static func _append_noise(out: Array[Dictionary], combatants: Dictionary, source_id: String, position: Variant, loudness: int) -> void:
	if source_id == "":
		return
	var pair: Array = position if position is Array else []
	var pos: Vector2i
	if pair.size() == 2:
		pos = Vector2i(int(pair[0]), int(pair[1]))
	else:
		var source: CombatantState = combatants.get(source_id)
		if source == null:
			return
		pos = source.position
	out.append({"source": source_id, "position": pos, "loudness": loudness})


## The R20 binary hearing check — the range half of the sense: does a hearer
## at `hearer_pos` hear a noise of `loudness` made at `noise_position`? Plain
## hex distance, boundary INCLUSIVE (the sight-range convention), measured
## from where the sound HAPPENED — never from the source's current hex (the
## source may have moved on; hearing locates sounds, not makers). No LOS, no
## Mind gate, no rng (see the table header). Who is ELIGIBLE to hear (AI,
## able to act, hostile source, source undetected) is consumption policy —
## CombatSim._noise_checks.
static func hears(hearer_pos: Vector2i, noise_position: Vector2i, loudness: int) -> bool:
	return CombatantState.hex_distance(hearer_pos, noise_position) <= loudness
