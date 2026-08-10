class_name HexGeometry
extends RefCounted
## Axial-hex geometry primitives (MODEL — pure, static, stateless; no Godot
## node deps, no rng, no state). Retires the R11 #16 "cone N / line resolve as
## plain reach" deferral: EnemyAI and ActionResolver target/re-check the REAL
## shapes through these functions (wave 2a, decision #31 engine mandate).
##
## COORDINATES — axial (q, r) in Vector2i, matching CombatantState.position and
## the cube mapping x = q, z = r, y = -q - r. `distance` is the cube hex norm,
## bit-identical to CombatantState.hex_distance (pinned by test).
##
## DIRECTIONS — the fixed six-neighbor order below IS EnemyAI.HEX_NEIGHBORS
## (pinned by test): E, NE, NW, W, SW, SE. Every "first direction wins" tie in
## this file breaks along that order.
##
## DETERMINISM & ORDERING (load-bearing — these feed targeting loops):
##  * line()/line_extended() are ordered ALONG the ray, origin first — the lane
##    order is the charge order and is semantically meaningful.
##  * cone()/blast() are sorted ascending by Vector2i's lexicographic order
##    (q, then r) — callers must never depend on insertion order.
##  * LINE TIE RULE: the hex line samples the from→to cube segment at unit
##    distances and cube-rounds each sample after a fixed epsilon TRANSLATION
##    (+1e-6, +2e-6, -3e-6 in cube x/y/z) — exact midpoints break toward the
##    +x/+y cube side, identically for every call. Because the nudge is a pure
##    translation, line(a, b) and line(b, a) contain the SAME hexes (reversed
##    order); consecutive line hexes are always adjacent.
##
## CONE MODEL (the flamethrower arc): a 120-degree wedge, boundary-inclusive.
## For the direction d nearest to origin→toward (cube dot product; ties take
## the earlier DIRECTIONS entry), the two adjacent directions d_a, d_b satisfy
## d_a + d_b = d, and
##     cone(origin, toward, size) = { origin + a*d_a + c*d_b :
##                                    a >= 0, c >= 0, 1 <= max(a, c) <= size }
## i.e. every hex whose angular offset from d is within +/-60 degrees
## (boundary rays included) and whose distance is at most `size`. Ring k of
## the cone holds exactly 2k+1 hexes (of the ring's 6k), so |cone| =
## size^2 + 2*size. Symmetric where the data is symmetric: the set is closed
## under reflection across the d axis. Origin is never part of its own cone.
##
##   size-2 cone, direction E = (1, 0), O = origin (axial labels right):
##
##         #            (2,-2)
##        # #           (1,-1) (2,-1)
##       O # #          (1,0)  (2,0)
##        # #           (0,1)  (1,1)
##         #            (0,2)
##
##   size-3 cone, direction E = (1, 0):
##
##          #           (3,-3)
##        # #           (2,-2) (3,-2)
##       # # #          (1,-1) (2,-1) (3,-1)
##      O # # #         (1,0)  (2,0)  (3,0)
##       # # #          (0,1)  (1,1)  (2,1)
##        # #           (0,2)  (1,2)
##          #           (0,3)
##
## BLAST MODEL: blast(center, radius) = every hex with distance <= radius,
## CENTER INCLUDED — the exact membership rule the explosion beat has always
## used (it excludes the boss by id, not by hex).
##
## ARENA BOUNDS: the sim has NO bounds concept yet — data/enemies.json's
## arena_hexes is authored data the engine does not read. All shapes here are
## deliberately unbounded; bounds arrive with the KAN-5 arena work.

## The canonical fixed neighbor order (E, NE, NW, W, SW, SE) — kept equal to
## EnemyAI.HEX_NEIGHBORS by test (the two constants must never drift).
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## The line tie-break translation (sums to zero: it stays on the cube plane).
const _EPS_X: float = 1e-6
const _EPS_Y: float = 2e-6
const _EPS_Z: float = -3e-6


## Cube hex distance — identical to CombatantState.hex_distance (pinned by test).
static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


## The DIRECTIONS index nearest to the origin→toward ray: maximal cube-space
## dot product with (toward - origin); an exact tie takes the EARLIER entry.
## -1 when toward == origin (no direction).
static func direction_index(origin: Vector2i, toward: Vector2i) -> int:
	if origin == toward:
		return -1
	var v: Vector2i = toward - origin
	var vx: int = v.x
	var vz: int = v.y
	var vy: int = -vx - vz
	var best: int = -1
	var best_dot: int = 0
	for idx: int in range(DIRECTIONS.size()):
		var d: Vector2i = DIRECTIONS[idx]
		var dy: int = -d.x - d.y
		var dot: int = vx * d.x + vy * dy + vz * d.y
		if best == -1 or dot > best_dot:
			best = idx
			best_dot = dot
	return best


## The hex line from `from` to `to`, inclusive, ordered from→to (the standard
## cube-lerp-and-round algorithm; tie rule in the header). [from] when equal.
static func line(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return _walk(from, to, distance(from, to))


## The dash lane: continue the from→through direction out to `max_len` hexes
## from `from`, inclusive of `from` (index 0). Contains line(from, through) as
## its prefix (same samples, same tie rule). [from] when degenerate (equal
## hexes or max_len <= 0) — a charge needs a direction; callers guard.
static func line_extended(from: Vector2i, through: Vector2i, max_len: int) -> Array[Vector2i]:
	if from == through or max_len <= 0:
		var degenerate: Array[Vector2i] = [from]
		return degenerate
	return _walk(from, through, max_len)


## Shared sampler for line/line_extended: `count` unit-distance steps along the
## from→through ray, each cube-rounded after the fixed epsilon translation.
static func _walk(from: Vector2i, through: Vector2i, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = [from]
	if count <= 0 or from == through:
		return out
	var n: float = float(distance(from, through))
	var fx: float = float(from.x)
	var fz: float = float(from.y)
	var fy: float = -fx - fz
	var tx: float = float(through.x)
	var tz: float = float(through.y)
	var ty: float = -tx - tz
	var step_x: float = (tx - fx) / n
	var step_y: float = (ty - fy) / n
	var step_z: float = (tz - fz) / n
	for k: int in range(1, count + 1):
		out.append(_cube_round(
			fx + _EPS_X + step_x * k,
			fy + _EPS_Y + step_y * k,
			fz + _EPS_Z + step_z * k))
	return out


## Standard cube rounding: round each coordinate, then recompute the one with
## the largest rounding error so x + y + z == 0 holds.
static func _cube_round(x: float, y: float, z: float) -> Vector2i:
	var rx: float = roundf(x)
	var ry: float = roundf(y)
	var rz: float = roundf(z)
	var dx: float = absf(rx - x)
	var dy: float = absf(ry - y)
	var dz: float = absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


## The 120-degree cone arc (model + ASCII in the header). Sorted ascending by
## Vector2i order (q, then r). Empty when size <= 0 or toward == origin.
static func cone(origin: Vector2i, toward: Vector2i, size: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var idx: int = direction_index(origin, toward)
	if idx < 0 or size <= 0:
		return out
	var da: Vector2i = DIRECTIONS[(idx + 1) % 6]
	var db: Vector2i = DIRECTIONS[(idx + 5) % 6]
	for a: int in range(size + 1):
		for c: int in range(size + 1):
			if a == 0 and c == 0:
				continue
			out.append(origin + da * a + db * c)
	out.sort()
	return out


## Every hex with distance <= radius from `center`, CENTER INCLUDED (the
## explosion shape — the beat code's membership rule, unchanged). Sorted
## ascending by Vector2i order (q, then r). Empty when radius < 0.
static func blast(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if radius < 0:
		return out
	for q: int in range(-radius, radius + 1):
		for r: int in range(maxi(-radius, -q - radius), mini(radius, -q + radius) + 1):
			out.append(center + Vector2i(q, r))
	out.sort()
	return out


## Membership set for a hex list: {Vector2i: true}. Targeting loops test
## containment through this instead of scanning arrays.
static func to_set(hexes: Array[Vector2i]) -> Dictionary:
	var out: Dictionary = {}
	for hex: Vector2i in hexes:
		out[hex] = true
	return out
