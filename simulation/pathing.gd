class_name Pathing
extends RefCounted
## Deterministic hex route planning (KAN-5 wave 4a) — the A* planner behind
## EnemyAI._step_toward, retiring R28's "greedy step strands on concave walls"
## limitation. STATIC + STATELESS: every function is a pure function of its
## arguments — nothing here is serialized, no instance is ever created, and
## CombatSim's to_dict()/state_hash are untouched (pinned in
## tests/test_pathing.gd). All rng-free.
##
## WHEN A* RUNS (the routing gate — next_steps applies it):
##  * arena is null, OR the arena has no walls and rect bounds -> the EXACT
##    legacy greedy walk (greedy_steps — the verbatim pre-wave-4a
##    EnemyAI._step_toward loop). Documented rationale:
##      - No arena = an INFINITE graph: A* toward an unreachable goal could
##        only burn the expansion cap; and in truly-open space the greedy walk
##        IS an optimal path (some neighbor always reduces the hex distance by
##        1, the metric's per-step maximum). Occupied-hex blocking keeps the
##        legacy greedy semantics BY CONTRACT (byte-compat with the pre-pathing
##        sim — the CI harnesses stage no arena and must byte-diff clean; a
##        bodies-only trap in open space stays greedy, a documented limitation).
##      - A wall-less RECT arena is provably greedy-safe: between any two
##        in-rect hexes a shortest path exists that stays in-rect (decompose
##        the difference vector over the two spanning adjacent directions —
##        every such decomposition changes q and r monotonically, so every
##        intermediate hex stays inside the axial parallelogram), hence a
##        strictly-improving in-rect step always exists and greedy never
##        strands on bounds. Greedy = optimal there, so A* would add nothing.
##  * The arena has any wall, OR explicit-hex-set bounds (bounds_kind
##    "hexes" — which may be CONCAVE, the same trap shape walls make) -> real
##    A* over the blocked-hex graph.
##
## TIE-BREAK CONTRACT (the determinism guarantee — documented exactly):
## Frontier pops are ordered by a single ascending packed-integer key
## (f, then G_MAX - g, then insertion sequence): lowest f = g + h first; among
## equal f the DEEPEST node (largest g) first; among equal (f, g) the
## earliest-inserted first. Neighbors are generated in the fixed
## HexGeometry.DIRECTIONS order (== EnemyAI.HEX_NEIGHBORS, pinned by test), so
## an earlier direction earns an earlier insertion sequence. A node's parent is
## set at FIRST discovery and re-pointed only by a STRICTLY better g (an
## equal-g rediscovery never re-points). No dictionary-iteration order is ever
## observed: the frontier is a keyed binary heap; closed/g/parent dictionaries
## are only ever probed by key. Identical inputs -> identical path.
##   Consequence (the greedy-compat property): deepest-first inside an f-tie
## makes the search DIVE — at each node the first f-preserving unblocked
## neighbor in fixed order is popped next, which is exactly the greedy walker's
## step choice wherever that step is unobstructed. Pathfinding therefore
## reproduces the greedy path wherever greedy was already optimal and diverges
## only where greedy would strand or detour suboptimally.
##
## HEURISTIC: h(n) = max(0, distance(n, goal) - stop_range) — admissible and
## consistent (the hex distance is a metric), so the first goal-ring pop is
## optimal and no closed node is ever reopened.
##
## EXPANSION CAP (the never-hangs bound): MAX_EXPANSIONS = 4096 closed-node
## expansions. Hitting the cap abandons the search and returns the greedy
## walker's steps HONESTLY (a real, legal — possibly stranding — walk; never a
## pretend path, never a hang). 4096 covers the largest authored arena (the
## den's 41x60 rect = 2460 hexes) with room to spare, so a cap hit means an
## unauthored-scale space where greedy is the honest budget answer.
##
## BLOCKED = occupied hexes (the caller's set — living combatants) + walls +
## out-of-bounds + trash cans, via Arena.blocks_movement — the arena's own
## movement-blocking query, TODAY's surface (the arena exposes no doors yet;
## when it grows them, blocks_movement is where they land).
##
## CALL-SITE AUDIT (wave 4a — every movement consumer, integrate only where
## the old behavior was dishonest):
##  * EnemyAI._step_toward (both _strike_or_close call sites: the pre-dash
##    step and the close-distance step) — INTEGRATED: the goal-seeking walker
##    is exactly what stranded on concave walls.
##  * EnemyAI._grab_decision pull-hex check — NOT integrated: the drag hex is
##    fixed geometry (lane index 1 on the boss->victim line), not a route
##    choice; wave 3d already refuses a blocked pull honestly. Nothing to
##    route.
##  * Dash lane planning (_dash_lane_for / bank shots / _bent_dash_lane) —
##    NOT integrated: a dash is a straight/reflected CHARGE lane, not a walk;
##    wave 3d's bounce/bend searches stay the lane authority.
##  * Resolver displacements (sidestep, knock-aside, fling, grab drag, summon
##    placement, tactical roll, free/scheduled moves) — NOT integrated: none
##    is a goal-seeking walker; wave 3d already made each arena-honest
##    (skip/stop/reject).

## Node-expansion cap (documented above): closed pops before the honest
## greedy fallback. Covers the largest authored arena several times over.
const MAX_EXPANSIONS: int = 4096
## Packed-key field width (f / inverted-g / seq each fit 21 bits; see _key).
const _FIELD_BITS: int = 21
const _FIELD_MAX: int = (1 << _FIELD_BITS) - 1
## Defensive ceiling on the start heuristic so f always fits its key field
## (f <= h0 + 2 * (MAX_EXPANSIONS + 1) < 2^21 when h0 < 2^19). No authored
## arena comes within orders of magnitude; past it, greedy is the honest
## fallback (same contract as the expansion cap).
const _MAX_START_H: int = 1 << 19


## The first `allowance` steps (excluding `from`) of the deterministic optimal
## route from `from` to within `stop_range` of `goal` — [] when already inside
## stop_range, when allowance <= 0, or when the goal ring is unreachable
## (walls-arena A* proves it by exhausting the reachable component; the caller
## waits honestly instead of thrashing). Routing gate, tie-breaks, cap and
## fallback: the class header. `occupied` is a {Vector2i: true} set of hexes
## living combatants hold; `arena` may be null (unbounded legacy space).
static func next_steps(from: Vector2i, goal: Vector2i, allowance: int, stop_range: int, occupied: Dictionary, arena: Arena) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if allowance <= 0 or HexGeometry.distance(from, goal) <= stop_range:
		return empty
	if arena == null or (arena.walls.is_empty() and arena.bounds_kind != "hexes"):
		return greedy_steps(from, goal, allowance, stop_range, occupied, arena)
	return _astar_steps(from, goal, allowance, stop_range, occupied, arena)


## The legacy greedy walk (the verbatim pre-wave-4a EnemyAI._step_toward inner
## loop, returning the step sequence instead of the final hex): up to
## `allowance` steps, each the fixed-order neighbor that most reduces the hex
## distance, strictly-improving only, blocked hexes skipped, stopping inside
## `stop_range` or when no improving step exists. Byte-compat is the contract:
## HexGeometry.DIRECTIONS == EnemyAI.HEX_NEIGHBORS and HexGeometry.distance ==
## CombatantState.hex_distance (both pinned by test), so this IS the old walk.
static func greedy_steps(from: Vector2i, goal: Vector2i, allowance: int, stop_range: int, occupied: Dictionary, arena: Arena) -> Array[Vector2i]:
	var steps: Array[Vector2i] = []
	var pos: Vector2i = from
	for step: int in range(allowance):
		var current_d: int = HexGeometry.distance(pos, goal)
		if current_d <= stop_range:
			break
		var best: Variant = null
		var best_d: int = current_d
		for neighbor: Vector2i in HexGeometry.DIRECTIONS:
			var candidate: Vector2i = pos + neighbor
			if occupied.has(candidate):
				continue
			if arena != null and arena.blocks_movement(candidate):
				continue
			var d: int = HexGeometry.distance(candidate, goal)
			if d < best_d:
				best = candidate
				best_d = d
		if best == null:
			break
		pos = best
		steps.append(pos)
	return steps


# ------------------------------------------------------------------ A* core

## The A* search (walls-arena path of next_steps — gate, tie-breaks, cap and
## heuristic per the class header). Returns the allowance-truncated optimal
## step sequence, [] when unreachable, or the greedy fallback on a cap hit.
static func _astar_steps(from: Vector2i, goal: Vector2i, allowance: int, stop_range: int, occupied: Dictionary, arena: Arena) -> Array[Vector2i]:
	var start_h: int = HexGeometry.distance(from, goal) - stop_range
	if start_h >= _MAX_START_H:
		return greedy_steps(from, goal, allowance, stop_range, occupied, arena)
	var heap: Array[int] = []
	var hex_for_seq: Dictionary = {}  # seq -> Vector2i (frontier entries)
	var g_score: Dictionary = {from: 0}
	var parent: Dictionary = {}
	var closed: Dictionary = {}
	var seq: int = 0
	hex_for_seq[0] = from
	_heap_push(heap, _key(start_h, 0, 0))
	var expansions: int = 0
	while not heap.is_empty():
		var popped: int = _heap_pop(heap)
		var hex: Vector2i = hex_for_seq[popped & _FIELD_MAX]
		if closed.has(hex):
			continue  # stale duplicate — a strictly better g was pushed later
		closed[hex] = true
		var g: int = int(g_score[hex])
		if HexGeometry.distance(hex, goal) <= stop_range:
			return _reconstruct(parent, from, hex, allowance)
		expansions += 1
		if expansions >= MAX_EXPANSIONS:
			return greedy_steps(from, goal, allowance, stop_range, occupied, arena)
		for neighbor: Vector2i in HexGeometry.DIRECTIONS:
			var candidate: Vector2i = hex + neighbor
			if closed.has(candidate):
				continue
			if occupied.has(candidate) or arena.blocks_movement(candidate):
				continue
			var tentative: int = g + 1
			if g_score.has(candidate) and int(g_score[candidate]) <= tentative:
				continue  # first discovery wins an equal-g tie (never re-point)
			g_score[candidate] = tentative
			parent[candidate] = hex
			seq += 1
			hex_for_seq[seq] = candidate
			var h: int = maxi(0, HexGeometry.distance(candidate, goal) - stop_range)
			_heap_push(heap, _key(tentative + h, tentative, seq))
	var unreachable: Array[Vector2i] = []
	return unreachable


## The parent-chain walk back from the popped goal-ring hex, allowance-truncated.
static func _reconstruct(parent: Dictionary, from: Vector2i, goal_hex: Vector2i, allowance: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var cursor: Vector2i = goal_hex
	while cursor != from:
		path.append(cursor)
		cursor = parent[cursor]
	path.reverse()
	if path.size() > allowance:
		path.resize(allowance)
	return path


## The packed frontier key — one ascending int comparison realizes the full
## tie-break contract: f ascending, then g DESCENDING (deepest first, stored
## inverted), then insertion sequence ascending. Field bounds hold by
## construction: g <= MAX_EXPANSIONS + 1, seq <= 6 * (MAX_EXPANSIONS + 1) + 1,
## f <= start_h + 2 * (MAX_EXPANSIONS + 1) < 2^21 (the _MAX_START_H guard).
static func _key(f: int, g: int, entry_seq: int) -> int:
	return (f << (2 * _FIELD_BITS)) | ((_FIELD_MAX - g) << _FIELD_BITS) | entry_seq


# ------------------------------------------------------------ binary min-heap

static func _heap_push(heap: Array[int], value: int) -> void:
	heap.append(value)
	var i: int = heap.size() - 1
	while i > 0:
		var p: int = (i - 1) >> 1
		if heap[p] <= heap[i]:
			break
		var tmp: int = heap[p]
		heap[p] = heap[i]
		heap[i] = tmp
		i = p


static func _heap_pop(heap: Array[int]) -> int:
	var top: int = heap[0]
	var last: int = heap[-1]
	heap.remove_at(heap.size() - 1)
	if heap.is_empty():
		return top
	heap[0] = last
	var i: int = 0
	var size: int = heap.size()
	while true:
		var left: int = 2 * i + 1
		var right: int = left + 1
		var smallest: int = i
		if left < size and heap[left] < heap[smallest]:
			smallest = left
		if right < size and heap[right] < heap[smallest]:
			smallest = right
		if smallest == i:
			break
		var tmp: int = heap[smallest]
		heap[smallest] = heap[i]
		heap[i] = tmp
		i = smallest
	return top
