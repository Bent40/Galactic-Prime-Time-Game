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
##    "objects": [{"key": "trash_can", "position": [q, r], "burn"?: int}, ...],
##    "doors":   [{"key": String (unique), "position": [q, r],
##                 "state": "open"|"closed",                      KAN-5 wave 4b
##                 "lock"?: {"tier": "simple"|"moderate"|"complex"|"magical",
##                           "state": "locked"|"unlocked"}}, ...],  KAN-5 K2
##    "terrain": [{"type": "difficult"|"water"|"rough",
##                 "hexes": [[q, r], ...]}, ...]}                 KAN-5 K2
##
## TERRAIN LAYER (KAN-5 remainder K2 — the substrate for quick_step / swim /
## acrobatics next story): an authored PER-HEX terrain typing. Untyped hexes
## are "normal"; TERRAIN_TYPES is an extensible enum (the validator and
## from_config gate it — an unknown type is an authoring error, never a silent
## normal). Terrain never BLOCKS anything (walls/doors/objects own blocking);
## it prices movement: move_cost(hex) is the entry cost of stepping ONTO a
## hex (TERRAIN_MOVE_COST — PLACEHOLDER R14). The substrate is deliberately
## SKILL-AGNOSTIC: per-combatant modifiers (quick_step ignoring difficult
## terrain, swim's "water is not difficult terrain for you" L6, acrobatics'
## rough-terrain immunity) apply at the CONSUMER — the caller that walks a
## route bills terrain via move_cost and overlays its own modifier there
## (a callback/parameter on the consumer's seam, next story) — so this query
## never learns skills. Consumers this story: Pathing/EnemyAI._step_toward
## (the AI free-move budget). The resolver's player-move pricing is the NEXT
## story (documented asymmetry — rules-addendum R33). SPAWNING ON TERRAIN IS
## LEGAL, water included (a contestant can be staged mid-pool; nothing in the
## rules forbids it and staging never prices movement) — the Clock-reset
## in_water marker (CombatSim._advance_tick) is water's only substrate effect.
##
## DOOR LOCKS (KAN-5 K2 — the lockpicking substrate): a door may author
## "lock": {tier, state}; absent = no lock (an unlocked door key never
## serializes — wave-4b byte-compat). A LOCKED door only exists CLOSED
## (from_config rejects a locked-open door — an open door blocks nothing, so
## its lock would be fiction) and the `door` command cannot open it
## (door_locked rejection). LOCK_PICK_MOMENTS is the tier -> Moments-to-pick
## table (PLACEHOLDER R14; "magical" additionally needs the special
## capability — the lockpicking L9 rung — enforced by CombatSim.pick_lock's
## `special` flag). No re-lock path exists in v1 (pick is one-way; a lock
## command is future work, priced when it lands).
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
##   * DOORS (KAN-5 wave 4b, rules-addendum R29): a CLOSED door blocks EXACTLY
##     like a wall, and it does so THROUGH is_wall() — the one query every
##     consumer already reads (movement, dash lanes incl. the phase-3 bounce,
##     LOS when it exists, staging) — so doors need ZERO consumer edits. An
##     OPEN door blocks nothing (standing in a doorway is legal; SPAWNING on
##     one is not — CombatSim staging rejects any door hex). Doors flip via
##     the sim's `door` command (free-action slot, R3); enemies never issue
##     it in v1 (the AI never decides doors — a closed door honestly walls an
##     enemy off). Authored-WALL-only checks (set_arena placement validation,
##     view/serialization) read the `walls` dict directly, never is_wall.
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
## KAN-5 K2 — the terrain-type enum (extensible; from_config + the seed
## validator gate against it) and the per-hex movement ENTRY cost table.
## Costs are PLACEHOLDER (R14): normal 1 (untyped — never in the table),
## difficult/rough/water 2. Keep costs single-digit: Pathing's packed
## frontier key re-derives its field bounds off a max step cost of
## TERRAIN_COST_MAX (see pathing.gd — headroom to ~2^19 exists, but the
## documented contract is small integer costs).
const TERRAIN_TYPES: Array[String] = ["difficult", "water", "rough"]
const TERRAIN_MOVE_COST: Dictionary = {"difficult": 2, "water": 2, "rough": 2}
## The largest cost in TERRAIN_MOVE_COST — pathing's field-bound input.
const TERRAIN_COST_MAX: int = 2
## KAN-5 K2 — the lock-tier enum (the lockpicking ladder's Simple -> Magical
## scale) and the Moments-to-pick table (PLACEHOLDER R14: simple 1 /
## moderate 2 / complex 3 / magical 3 + the special capability — the L9
## "open magical/keycard analogues" rung; CombatSim.pick_lock enforces it).
const LOCK_TIERS: Array[String] = ["simple", "moderate", "complex", "magical"]
const LOCK_PICK_MOMENTS: Dictionary = {"simple": 1, "moderate": 2, "complex": 3, "magical": 3}

## Bounds: "rect" (axial parallelogram) or "hexes" (explicit set).
var bounds_kind: String = "rect"
var rect_origin: Vector2i = Vector2i.ZERO
var rect_size: Vector2i = Vector2i.ZERO
var hex_set: Dictionary = {}  # {Vector2i: true} when bounds_kind == "hexes"
## Blocked hexes (authored walls): {Vector2i: true}.
var walls: Dictionary = {}
## KAN-5 K1 (zones substrate): the sim's RUNTIME zone store, wired by
## CombatSim whenever zones exist (create_zone / set_arena / from_dict) and
## NEVER serialized here — zones serialize on CombatSim under "zones", and
## this arena's to_dict/view stay byte-identical whatever zones exist.
## Composing here puts zone blocking behind the SAME queries every consumer
## already reads (the R29 closed-door precedent — zero consumer edits):
##   * a blocks_movement zone enters is_wall -> full wall parity (moves,
##     tactical rolls, dash lane ends AND phase-3 bounces, sidesteps,
##     knock-asides, flings, pulls, summon placement, pathing, staging — and
##     LOS, since Stealth.has_los walks blocks_lane);
##   * a blocks_los zone enters blocks_lane — the one channel the LOS walk
##     consults. Shared-choke-point caveat (deliberate, documented in
##     zones.gd): blocks_lane also drives dash-lane geometry, so a
##     blocks_los-ONLY zone is lane-solid too; no such zone is authored this
##     story, and the story that wants sight-only smoke owns the query split.
## Authored-solid-only checks (set_arena placement validation, zone placement,
## view/serialization) keep reading the `walls` dict directly, never is_wall.
var zones: Zones = null
## Environment objects, in authored order (deterministic iteration order —
## the array IS command-stream state): [{"key", "position": [q, r], "burn": int}].
var objects: Array[Dictionary] = []
## Doors (KAN-5 wave 4b), in authored order (the array IS command-stream
## state — `state` is a mutable field, flipped by the door command; K2 adds
## the optional "lock" sub-dict whose own `state` CombatSim.pick_lock flips):
## [{"key": String, "position": [q, r], "state": "open"|"closed",
##   "lock"?: {"tier": String, "state": "locked"|"unlocked"}}].
var doors: Array[Dictionary] = []
## KAN-5 K2 — the terrain layer: {Vector2i: String type}. Untyped hexes are
## absent (= "normal"); ONE type per hex (from_config gates duplicates).
## Never blocks; prices movement via move_cost. Serialized with the arena
## (canonical rows — terrain_rows) ONLY when authored: a terrain-less arena's
## to_dict/view stay byte-identical to the pre-terrain engine.
var terrain: Dictionary = {}


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
	# Doors (wave 4b): shape gates here (key non-empty + unique, position a
	# hex pair, state one of the two authored values); PLACEMENT gates
	# (bounds/walls/objects/duplicate hexes) live in CombatSim._set_arena.
	var door_keys: Dictionary = {}
	for entry: Variant in cfg.get("doors", []) as Array:
		if not (entry is Dictionary):
			return null
		var door: Dictionary = entry
		var door_pos: Variant = _parse_hex(door.get("position"))
		var door_key := String(door.get("key", ""))
		var state := String(door.get("state", ""))
		if door_pos == null or door_key == "" or door_keys.has(door_key) \
				or (state != "open" and state != "closed"):
			return null
		door_keys[door_key] = true
		var door_row: Dictionary = {
			"key": door_key,
			"position": [(door_pos as Vector2i).x, (door_pos as Vector2i).y],
			"state": state,
		}
		# K2 locks: optional; tier in the enum, state locked|unlocked, and a
		# LOCKED lock only exists on a CLOSED door (a locked-open door is a
		# contradiction — an open door blocks nothing). The "lock" key rides
		# the row ONLY when authored (wave-4b byte-compat for lockless doors).
		if door.has("lock"):
			var lock: Variant = door.get("lock")
			if not (lock is Dictionary):
				return null
			var tier := String((lock as Dictionary).get("tier", ""))
			var lock_state := String((lock as Dictionary).get("state", ""))
			if not LOCK_TIERS.has(tier) \
					or (lock_state != "locked" and lock_state != "unlocked") \
					or (lock_state == "locked" and state != "closed"):
				return null
			door_row["lock"] = {"tier": tier, "state": lock_state}
		arena.doors.append(door_row)
	# Terrain (K2): shape gates here (known type, non-empty hex-pair list, ONE
	# type per hex); PLACEMENT gates (bounds/walls/objects) in _set_arena.
	for entry: Variant in cfg.get("terrain", []) as Array:
		if not (entry is Dictionary):
			return null
		var patch: Dictionary = entry
		var terrain_type := String(patch.get("type", ""))
		var raw_patch: Variant = patch.get("hexes", [])
		if not TERRAIN_TYPES.has(terrain_type) \
				or not (raw_patch is Array) or (raw_patch as Array).is_empty():
			return null
		for pair: Variant in raw_patch as Array:
			var hex: Variant = _parse_hex(pair)
			if hex == null or arena.terrain.has(hex):
				return null
			arena.terrain[hex] = terrain_type
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


## Wall-like solid blocking: authored walls + CLOSED doors (KAN-5 wave 4b).
## A closed door blocks EXACTLY like a wall through this ONE query, so every
## existing consumer — movement, dash lanes (a phase-3+ dash BOUNCES off a
## closed door like any wall), staging, LOS when it exists — inherits doors
## with zero edits; an OPEN door blocks nothing. Authored-wall-only checks
## (set_arena placement validation, view/serialization) read `walls` directly.
func is_wall(hex: Vector2i) -> bool:
	return walls.has(hex) or is_closed_door(hex) \
		or (zones != null and zones.blocks_movement_at(hex))


## True when `hex` carries a door whose state is "closed".
func is_closed_door(hex: Vector2i) -> bool:
	var idx: int = door_index_at(hex)
	return idx >= 0 and String(doors[idx].get("state", "")) == "closed"


## Index into `doors` of the door on `hex` (any state), -1 when none.
func door_index_at(hex: Vector2i) -> int:
	for i: int in range(doors.size()):
		var pos: Array = doors[i].get("position", [])
		if pos.size() == 2 and Vector2i(int(pos[0]), int(pos[1])) == hex:
			return i
	return -1


## Index into `doors` of the door named `key`, -1 when unknown.
func door_index_for(key: String) -> int:
	for i: int in range(doors.size()):
		if String(doors[i].get("key", "")) == key:
			return i
	return -1


## K2 — true when a door row carries a lock whose state is "locked".
static func door_locked(door: Dictionary) -> bool:
	return String((door.get("lock", {}) as Dictionary).get("state", "")) == "locked"


## K2 — the terrain type of `hex`: an authored TERRAIN_TYPES entry, else
## "normal" (untyped). Never blocks — pure typing; costs ride move_cost.
func terrain_at(hex: Vector2i) -> String:
	return String(terrain.get(hex, "normal"))


## K2 — the movement ENTRY cost of stepping ONTO `hex` (normal 1; typed hexes
## per TERRAIN_MOVE_COST — PLACEHOLDER R14). SKILL-AGNOSTIC by contract:
## per-combatant modifiers (quick_step/swim/acrobatics) overlay this at the
## CONSUMER (the route walker's seam), never here — see the class header.
func move_cost(hex: Vector2i) -> int:
	return int(TERRAIN_MOVE_COST.get(terrain.get(hex, ""), 1))


## LANE blocking (dash geometry + the Stealth.has_los sight walk): walls +
## out-of-bounds — a charge smashes THROUGH trash cans, so cans never end (or
## bounce) a lane. KAN-5 K1: blocks_los zones compose here (the zones var's
## header carries the seam rationale + the shared-choke-point caveat);
## blocks_movement zones already arrive through is_wall.
func blocks_lane(hex: Vector2i) -> bool:
	return is_wall(hex) or not in_bounds(hex) \
		or (zones != null and zones.blocks_los_at(hex))


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


## K2 — sorted typed-hex list (deterministic placement-validation order).
func sorted_terrain_hexes() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for hex: Variant in terrain:
		out.append(hex)
	out.sort()
	return out


## K2 — the CANONICAL terrain rows (view + serialization): one row per type
## present, in TERRAIN_TYPES order, hexes sorted — the per-hex dict never
## leaks its iteration order, so identical terrain always prints identically.
func terrain_rows() -> Array:
	var rows: Array = []
	for terrain_type: String in TERRAIN_TYPES:
		var typed: Array[Vector2i] = []
		for hex: Variant in terrain:
			if String(terrain[hex]) == terrain_type:
				typed.append(hex)
		if typed.is_empty():
			continue
		typed.sort()
		var hex_rows: Array = []
		for hex: Vector2i in typed:
			hex_rows.append([hex.x, hex.y])
		rows.append({"type": terrain_type, "hexes": hex_rows})
	return rows


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
	var out: Dictionary = {"bounds": bounds, "walls": wall_rows, "objects": object_rows}
	# Wave 4b compat pin: the "doors" key appears ONLY on a door-carrying
	# arena — pre-door arena views keep their exact shape.
	if not doors.is_empty():
		var door_rows: Array = []
		for door: Dictionary in doors:
			var row: Dictionary = {
				"key": String(door.get("key", "")),
				"position": (door.get("position", []) as Array).duplicate(),
				"state": String(door.get("state", "")),
			}
			# K2 compat pin: "lock" rides the row ONLY when authored — the
			# live lock state included (a picked lock shows "unlocked").
			if door.has("lock"):
				row["lock"] = (door.get("lock", {}) as Dictionary).duplicate(true)
			door_rows.append(row)
		out["doors"] = door_rows
	# K2 compat pin: the "terrain" key appears ONLY on a terrain-carrying
	# arena (canonical rows) — pre-terrain arena views keep their exact shape.
	if not terrain.is_empty():
		out["terrain"] = terrain_rows()
	return out


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
	# Wave 4b compat pin: "doors" serializes ONLY when authored — a door-less
	# arena's to_dict (and every hash over it) is byte-identical to wave 3d.
	# K2: an authored "lock" sub-dict rides each row for free (deep duplicate),
	# live state included — lock state is hash-covered.
	if not doors.is_empty():
		out["doors"] = doors.duplicate(true)
	# K2 compat pin: "terrain" serializes ONLY when authored (canonical rows —
	# the per-hex dict's iteration order never leaks); a terrain-less arena's
	# to_dict is byte-identical to the pre-terrain engine.
	if not terrain.is_empty():
		out["terrain"] = terrain_rows()
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
	for entry: Variant in data.get("doors", []) as Array:
		arena.doors.append((entry as Dictionary).duplicate(true))
	# K2 terrain rows (the terrain_rows canonical shape; lenient like walls —
	# malformed entries are skipped, a valid save never contains any).
	for entry: Variant in data.get("terrain", []) as Array:
		if not (entry is Dictionary):
			continue
		var terrain_type := String((entry as Dictionary).get("type", ""))
		for pair: Variant in (entry as Dictionary).get("hexes", []) as Array:
			var hex: Variant = _parse_hex(pair)
			if hex != null and terrain_type != "":
				arena.terrain[hex] = terrain_type
	return arena
