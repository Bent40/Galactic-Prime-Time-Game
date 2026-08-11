class_name Arena
extends RefCounted
## Combat arena MODEL (KAN-5 wave 3d) — bounds, walls, environment objects.
## RefCounted, headless, deterministic; serialized on CombatSim under "arena"
## and hash-covered. STRICTLY OPT-IN: a CombatSim with no arena (the default,
## and every pre-arena save/harness) keeps today's unbounded behavior and a
## byte-identical to_dict() — the "arena" key is simply absent (the compat pin
## in tests/test_arena.gd; the CI harnesses stage no arena and byte-diff clean).
##
## WHERE ARENA DEFS LIVE (documented decision): an arena is authored per
## ENCOUNTER as an "arena" block on the encounter def in data/demo_run.json
## (RunState.staging() passes it through; GameController._stage_encounter
## issues the set_arena command BEFORE the add_combatant batch, so staging
## rejection applies to every spawn). data/enemies.json's `arena_hexes`
## ([41, 60] on the incinedile) stays the per-enemy DESIGN RECORD the den's
## encounter block mirrors — the engine reads the encounter block only.
##
## CONFIG SHAPE (the authored block; from_config parses it):
##   {"bounds": {"width": W, "height": H, "origin"?: [q0, r0]}   axial rect
##             | {"hexes": [[q, r], ...]},                        explicit set
##    "walls":   [[q, r], ...],                                   blocked hexes
##    "objects": [{"key": "trash_can", "position": [q, r], "burn"?: int}, ...]}
## The axial rect covers q0 <= q < q0+W, r0 <= r < r0+H (an axial
## parallelogram — PROVISIONAL room shape; the owner redesigns rooms with the
## front). Default origin centers it: [-floor(W/2), -floor(H/2)], so the
## incinedile's authored 41x60 covers q in [-20, 20], r in [-30, 29] around
## the staging origin.
##
## BLOCKING MODEL (who blocks what — the movement-honesty contract):
##   * bounds/walls block EVERY position-changing path (blocks_lane): free +
##     scheduled moves, AI steps, tactical rolls, repositions, sidesteps,
##     knock-asides, flings, summon placement, grab drags, staging — and they
##     END a dash lane (or REFLECT it, phase-3 upgrade — see bounced_lane).
##   * trash cans block their hex like an OCCUPIED hex until destroyed
##     (blocks_movement = blocks_lane + object) — same paths as above, EXCEPT
##     the dash lane: a charge smashes THROUGH a can (destroying it), so cans
##     never end a lane and NEVER cause a bounce (bounces are walls only).
##
## TRASH CANS (canon off the authored flamethrower note: "trash cans explode
## at Burn 5 (3 spaces, 2 Burn)"): a can in a resolved burn-cone's arc
## accumulates the cone's burn amount; at burn >= TRASH_CAN_EXPLODE_AT it
## EXPLODES — HexGeometry.blast radius TRASH_CAN_BLAST_RADIUS, burn
## TRASH_CAN_BLAST_BURN to every combatant in it through the normal damage
## paths, attacker NONE (environment — no killer, takedown-v2 honesty), can
## removed. The phase-3 "flamethrower pops trash cans instantly" upgrade
## explodes a swept can on the FIRST touch (no accumulation). Mechanics live
## in ActionResolver (_ignite_cans_in_cone/_explode_cans); the constants and
## the object state live here.
##
## DASH BOUNCE REFLECTION MODEL (phase-3 "dash bounces between walls up to 2
## bounces" — the geometry authority is bounced_lane below):
## The lane walks hex-by-hex along its current ray direction v (an INTEGER
## cube vector — through minus from). Consecutive lane hexes are always
## adjacent (HexGeometry line guarantee), so when the next hex W is a
## wall/out-of-bounds the incoming unit step n = W - P is one of the six
## axial directions and names the blocked EDGE. The ray REFLECTS across that
## edge's plane:
##     v' = v - (v . n) n        (cube coordinates; n . n = 2)
## which is the exact mirror — the component of v along the edge normal n
## reverses, the tangential component is preserved. Because every axial n has
## exactly two nonzero cube components (+1/-1), the reflection is simply a
## SWAP of the two cube coordinates n mixes (bounce off an E/W edge: swap
## cube x and y). Integer in, integer out, stays on the cube plane, hex norm
## preserved. A head-on hit (v parallel to n) reflects straight back — a
## ricochet lane may legally REVISIT hexes (the chosen-BEND no-hairpin rule
## does not apply to forced bounces). The walk continues from P along v';
## total lane length stays <= the dash's range ACROSS ALL SEGMENTS; a wall
## hit past the bounce budget ENDS the lane at the last free hex. Ties inside
## each segment are fixed by HexGeometry's LINE TIE RULE (epsilon
## translation) — the whole walk is deterministic and rng-free.
##
## ASCII example — single bounce, the (1,1)-diagonal ray (steps alternate
## E, SE) from O=(0,0) toward (3,3), wall W at (2,1), range 6:
##
##       q ->                          lane (in order):
##   r=0   O  1  .          O=(0,0)    (0,0) (1,0) (1,1)   incoming E,SE,...
##   r=1    4  2  W         1=(1,0)    -- step E into W=(2,1): BOUNCE at 2 --
##   r=2   .  5  .  .       2=(1,1)*   v=(3,-6,3) n=E=(1,-1,0) v.n=9
##   r=3    6  .  .         4=(0,1)    v'=v-9n=(-6,3,3)  (cube x<->y swap)
##                          5=(-1,2)   (0,1) (-1,2) (-2,2) (-3,3) outgoing
##                          6=(-2,2)   W,SW,... — the mirror image of the
##                          7=(-3,3)   incoming diagonal across the N-S edge
##
##   full lane: [(0,0),(1,0),(1,1),(0,1),(-1,2),(-2,2),(-3,3)], bounces=[(1,1)]
##
## A second wall on the outgoing corridor (e.g. at (-3,3)) reflects again the
## same way (up to MAX_DASH_BOUNCES); a third wall ends the lane. Pinned
## hand-verified in tests/test_arena.gd (single + double + head-on retrace).

## "trash cans explode at Burn 5 (3 spaces, 2 Burn)" — canon (flamethrower note).
const TRASH_CAN_EXPLODE_AT: int = 5
const TRASH_CAN_BLAST_RADIUS: int = 3
const TRASH_CAN_BLAST_BURN: int = 2
## "dash bounces between walls up to 2 bounces" — canon (phase-3 upgrade string).
const MAX_DASH_BOUNCES: int = 2

## Bounds: "rect" (axial parallelogram) or "hexes" (explicit set).
var bounds_kind: String = "rect"
var rect_origin: Vector2i = Vector2i.ZERO
var rect_size: Vector2i = Vector2i.ZERO
var hex_set: Dictionary = {}  # {Vector2i: true} when bounds_kind == "hexes"
## Blocked hexes (authored walls): {Vector2i: true}.
var walls: Dictionary = {}
## Environment objects, in authored order (deterministic iteration order —
## the array IS command-stream state): [{"key", "position": [q, r], "burn": int}].
var objects: Array[Dictionary] = []


## Parses the authored config block. Returns null when the shape is invalid
## (callers reject the set_arena command with "invalid_arena").
static func from_config(cfg_variant: Variant) -> Arena:
	var cfg: Dictionary = cfg_variant if cfg_variant is Dictionary else {}
	var bounds: Dictionary = cfg.get("bounds", {})
	if bounds.is_empty():
		return null
	var arena := Arena.new()
	if bounds.has("hexes"):
		arena.bounds_kind = "hexes"
		var raw_hexes: Variant = bounds.get("hexes", [])
		if not (raw_hexes is Array) or (raw_hexes as Array).is_empty():
			return null
		for pair: Variant in raw_hexes as Array:
			var hex: Variant = _parse_hex(pair)
			if hex == null:
				return null
			arena.hex_set[hex] = true
	else:
		arena.bounds_kind = "rect"
		var width: int = int(bounds.get("width", 0))
		var height: int = int(bounds.get("height", 0))
		if width < 1 or height < 1:
			return null
		arena.rect_size = Vector2i(width, height)
		if bounds.has("origin"):
			var origin: Variant = _parse_hex(bounds.get("origin"))
			if origin == null:
				return null
			arena.rect_origin = origin
		else:
			# Default origin centers the room on the staging origin (documented).
			arena.rect_origin = Vector2i(-(width / 2), -(height / 2))
	for pair: Variant in cfg.get("walls", []) as Array:
		var wall: Variant = _parse_hex(pair)
		if wall == null:
			return null
		arena.walls[wall] = true
	for entry: Variant in cfg.get("objects", []) as Array:
		if not (entry is Dictionary):
			return null
		var obj: Dictionary = entry
		var pos: Variant = _parse_hex(obj.get("position"))
		if pos == null or String(obj.get("key", "")) == "":
			return null
		arena.objects.append({
			"key": String(obj.get("key", "")),
			"position": [(pos as Vector2i).x, (pos as Vector2i).y],
			"burn": maxi(0, int(obj.get("burn", 0))),
		})
	return arena


static func _parse_hex(pair: Variant) -> Variant:
	if not (pair is Array) or (pair as Array).size() != 2:
		return null
	return Vector2i(int((pair as Array)[0]), int((pair as Array)[1]))


# ------------------------------------------------------------------ queries

func in_bounds(hex: Vector2i) -> bool:
	if bounds_kind == "hexes":
		return hex_set.has(hex)
	return hex.x >= rect_origin.x and hex.x < rect_origin.x + rect_size.x \
		and hex.y >= rect_origin.y and hex.y < rect_origin.y + rect_size.y


func is_wall(hex: Vector2i) -> bool:
	return walls.has(hex)


## LANE blocking (dash geometry): walls + out-of-bounds only — a charge
## smashes THROUGH trash cans, so cans never end (or bounce) a lane.
func blocks_lane(hex: Vector2i) -> bool:
	return is_wall(hex) or not in_bounds(hex)


## MOVEMENT blocking (every non-lane position change): walls + out-of-bounds
## + trash cans (a can blocks its hex like an occupied hex until destroyed).
func blocks_movement(hex: Vector2i) -> bool:
	return blocks_lane(hex) or object_index_at(hex) >= 0


## Index into `objects` of the (first) object on `hex`, -1 when free.
func object_index_at(hex: Vector2i) -> int:
	for i: int in range(objects.size()):
		var pos: Array = objects[i].get("position", [])
		if pos.size() == 2 and Vector2i(int(pos[0]), int(pos[1])) == hex:
			return i
	return -1


## Sorted wall list (deterministic view/serialization order).
func sorted_walls() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for hex: Variant in walls:
		out.append(hex)
	out.sort()
	return out


# ------------------------------------------------------------------ bounce walk

## The bounced dash-lane walk — the reflection-model authority (header ASCII).
## Walks up to `max_len` steps from `from` along the from->through ray,
## reflecting off walls/bounds up to `max_bounces` times (0 = today's
## lane-ENDS-at-a-wall rule); a wall hit past the budget ends the lane at the
## last free hex. Trash cans never interact here (charges smash through).
## Returns {"lane": Array[Vector2i] (from first), "bounces": Array[Vector2i]
## (the hex the lane reflected AT, in order)}. Pure, deterministic, rng-free.
func bounced_lane(from: Vector2i, through: Vector2i, max_len: int, max_bounces: int) -> Dictionary:
	var lane: Array[Vector2i] = [from]
	var bounces: Array[Vector2i] = []
	if from == through or max_len <= 0:
		return {"lane": lane, "bounces": bounces}
	var v: Vector3i = _cube(through) - _cube(from)
	var pos: Vector2i = from
	var steps_left: int = max_len
	var guard: int = max_len + max_bounces + 2  # belt-and-braces loop bound
	while steps_left > 0 and guard > 0:
		guard -= 1
		var seg: Array[Vector2i] = HexGeometry.line_extended(pos, _axial(_cube(pos) + v), steps_left)
		if seg.size() < 2:
			break  # degenerate direction — nothing to walk
		var bounced: bool = false
		for k: int in range(1, seg.size()):
			var nxt: Vector2i = seg[k]
			if blocks_lane(nxt):
				if bounces.size() >= max_bounces:
					return {"lane": lane, "bounces": bounces}  # lane ENDS at the wall
				var n: Vector3i = _cube(nxt) - _cube(pos)  # unit axial step (adjacent)
				var dot: int = v.x * n.x + v.y * n.y + v.z * n.z
				v = v - n * dot  # the edge mirror: swaps the two cube axes n mixes
				bounces.append(pos)
				bounced = true
				if v == Vector3i.ZERO:
					return {"lane": lane, "bounces": bounces}  # degenerate — end honestly
				break
			lane.append(nxt)
			pos = nxt
			steps_left -= 1
			if steps_left <= 0:
				break
		if not bounced and steps_left > 0:
			break  # segment exhausted without a wall (only possible when degenerate)
	return {"lane": lane, "bounces": bounces}


static func _cube(hex: Vector2i) -> Vector3i:
	return Vector3i(hex.x, -hex.x - hex.y, hex.y)


static func _axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.z)


# ------------------------------------------------------------------ view

## Read-only plain-Dictionary projection (GameController.view_arena).
func view() -> Dictionary:
	var wall_rows: Array = []
	for hex: Vector2i in sorted_walls():
		wall_rows.append([hex.x, hex.y])
	var object_rows: Array = []
	for obj: Dictionary in objects:
		object_rows.append({
			"key": String(obj.get("key", "")),
			"position": (obj.get("position", []) as Array).duplicate(),
			"burn": int(obj.get("burn", 0)),
		})
	var bounds: Dictionary
	if bounds_kind == "hexes":
		var hex_rows: Array = []
		for hex: Vector2i in _sorted_bound_hexes():
			hex_rows.append([hex.x, hex.y])
		bounds = {"kind": "hexes", "hexes": hex_rows}
	else:
		bounds = {
			"kind": "rect",
			"origin": [rect_origin.x, rect_origin.y],
			"width": rect_size.x, "height": rect_size.y,
		}
	return {"bounds": bounds, "walls": wall_rows, "objects": object_rows}


func _sorted_bound_hexes() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for hex: Variant in hex_set:
		out.append(hex)
	out.sort()
	return out


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	var out: Dictionary = {"bounds_kind": bounds_kind}
	if bounds_kind == "hexes":
		var hex_rows: Array = []
		for hex: Vector2i in _sorted_bound_hexes():
			hex_rows.append([hex.x, hex.y])
		out["hexes"] = hex_rows
	else:
		out["origin"] = [rect_origin.x, rect_origin.y]
		out["size"] = [rect_size.x, rect_size.y]
	var wall_rows: Array = []
	for hex: Vector2i in sorted_walls():
		wall_rows.append([hex.x, hex.y])
	out["walls"] = wall_rows
	out["objects"] = objects.duplicate(true)
	return out


static func from_dict(data: Dictionary) -> Arena:
	var arena := Arena.new()
	arena.bounds_kind = String(data.get("bounds_kind", "rect"))
	if arena.bounds_kind == "hexes":
		for pair: Variant in data.get("hexes", []) as Array:
			var hex: Variant = _parse_hex(pair)
			if hex != null:
				arena.hex_set[hex] = true
	else:
		var origin: Variant = _parse_hex(data.get("origin", [0, 0]))
		var size: Variant = _parse_hex(data.get("size", [0, 0]))
		arena.rect_origin = origin if origin != null else Vector2i.ZERO
		arena.rect_size = size if size != null else Vector2i.ZERO
	for pair: Variant in data.get("walls", []) as Array:
		var wall: Variant = _parse_hex(pair)
		if wall != null:
			arena.walls[wall] = true
	for entry: Variant in data.get("objects", []) as Array:
		arena.objects.append((entry as Dictionary).duplicate(true))
	return arena
