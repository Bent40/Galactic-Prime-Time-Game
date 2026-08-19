class_name Zones
extends RefCounted
## Zones/fields substrate (KAN-5 remainder K1) — the RUNTIME area-effect store
## the wall skills (poison_wall / frost_wall / fire_wall) and
## elemental_confluence will drive next story, and the shape DIRECTION.md's
## combat-fields sketch stays compatible with. RefCounted, headless,
## deterministic (ZERO rng anywhere in this file); serialized on CombatSim
## under a "zones" key and hash-covered. STRICTLY OPT-IN: no command creates a
## zone — CombatSim.create_zone/remove_zone/damage_zone are the INTERNAL API
## the future skill resolvers call — and a sim that never created one
## serializes byte-identically to the pre-zone engine (the CI-harness pin).
##
## ZONE MODEL (one entry in `zones`, plain JSON-safe types only):
##   {"id": int                deterministic creation sequence (1, 2, ... off
##                             the serialized next_id counter — save/restore
##                             replay-transparent),
##    "key": String            content identity ("fire_wall", ...),
##    "hexes": [[q, r], ...]   the zone's hex set, stored SORTED + deduped,
##    "owner": String          the combatant who authored the zone ("" =
##                             environment/GM). Attribution flows from here:
##                             every condition/damage the zone applies carries
##                             the owner as its wound source, so a burn death
##                             in your fire wall credits YOU (takedown-v2),
##    "created_tick": int      the tick the zone was created on,
##    "duration_clocks": int   REMAINING Clock resets: counts down 1 at each
##                             reset (after the occupancy bite) and the zone
##                             expires at 0; -1 = lasts the combat,
##    "effects": {"on_enter"?: {block}, "on_occupy_clock"?: {block},
##                "on_pass"?: {block}}   (vocabulary below),
##    "hp": int                frost walls are destructible: hp >= 1 can be
##                             worn down via damage_zone (expires reason
##                             "destroyed" at 0); -1 = indestructible.
##                             ATTACKABILITY IS DEFERRED (documented): making
##                             a zone a legal attack target needs resolver
##                             targeting, which is the next story's footprint —
##                             this story hp moves ONLY through the internal
##                             API (the Burn-x2-vs-frost rule rides the future
##                             attacker path, not this store),
##    "blocks_movement": bool  blocks EXACTLY like a wall (seam notes below),
##    "blocks_los": bool}      occludes the stealth/LOS sight line.
##
## EFFECT VOCABULARY (DATA-shaped — the skills feed it; nothing here is
## hardcoded per zone key). Each trigger block:
##   {"affects"?: "all" (default) | "non_owner" | "hostile",
##        all = any creature (fire wall burns its caster too); non_owner =
##        everyone but the author (confluence's "not you"); hostile = a
##        different team than the owner's (the L9 "ally-safe" rung; the
##        EnemyAI._opponents predicate — teamless-vs-teamless is not hostile,
##        and an owner absent from the fight matches nobody),
##    "damage"?: {"type": String, "amount": int, "part"?: String},
##        typed damage per R14 through the normal paths: the type normalizes
##        to its condition id, Resistance.reduce_damage applies the flat
##        physical reduction, ConditionEngine.damage_part is the central sink
##        (source_kind "environment", source_id = owner — kill attribution),
##    "conditions"?: [{"condition": String, "tier"?: int (default 1),
##                     "part"?: String (default "torso"),
##                     "poison_type"?: String,
##                     "source"?: "direct" (default) | "attack"}],
##        each routed through ConditionEngine.apply with attacker = owner —
##        the existing wound-source machinery carries the credit. "source"
##        lets a skill opt into attack semantics (poison entry gate, the
##        once-per-tick advance cap); "shock" is a legal condition here and
##        routes to apply_shock (fire_wall L6 "passers take tier 2 Shock" =
##        {"condition": "shock", "tier": 2} on on_pass; Shock is a momentary
##        event with no wound-source field — documented, unattributed),
##    "advance"?: [{"condition": String, "steps"?: int (default 1)}]}
##        advances every ACTIVE instance of the condition on the combatant
##        (sorted part order) — confluence's Toxic Surge ("advance all active
##        Poison conditions by 1 tier").
##   Validation is STRICT at create time (unknown trigger names, unknown ops,
##   malformed entries all reject) so a typo'd skill payload surfaces loudly
##   instead of silently doing nothing.
##
## LIFECYCLE SEAMS (all in existing sweeps — no new command surface):
##  * on_enter — fired by CombatSim._post's POSITION-DIFF sweep (this file's
##    position_sweep): the baseline map remembers every combatant's position
##    at the end of the previous command; any change that lands a living
##    combatant in a zone it was not in fires on_enter. CHOSEN SEAM
##    (documented): the resolver's ~18 position-mutation sites belong to a
##    sibling story's footprint, so the ONE post-command diff is the single
##    hook every path (free/scheduled moves, AI steps, tactical rolls, dashes,
##    slips, sidesteps, knock-asides, flings, pulls, grab drags, forced
##    movement) already flows past. A spawn (staging/summon) baselines
##    silently — materializing is not entering; the occupant is hit at the
##    next Clock via on_occupy_clock. Moving hex-to-hex WITHIN a zone never
##    re-enters.
##  * on_pass — fired for movement that CROSSES a zone without ending in it.
##    HONESTY NOTE (which paths expose traversal): dash lanes DO — the
##    dash_charged event carries from/to (+ committed bend/bounces), and the
##    corridor is reconstructed exactly from those waypoints (segments between
##    committed waypoints are straight hex lines by construction). 1-3-space
##    free moves and scheduled long moves are destination-only HOPS per the
##    standing wall contract (the resolver validates the destination hex
##    only), so no real traversal exists and on_pass honestly does not fire
##    for them — nor for leaps (an arc OVER the ground is not a crossing).
##    One on_pass per zone per dash, origin/destination zones excluded
##    (starting inside and running out is not passing through; ending inside
##    is on_enter's job). Known reconstruction edge (documented): a head-on
##    bounce that RETRACES its own corridor under-walks (the straight-back
##    segment collapses); no such lane can cross a zone this story.
##  * on_occupy_clock — fired at each Clock reset (clock_reset_sweep, called
##    from CombatSim._advance_tick's completes_clock block AFTER the universal
##    condition advancement) for every living, in-play combatant standing in
##    the zone. Runs BEFORE the duration countdown, so a 1-Clock wall bites
##    its occupants at the reset that also expires it.
##  * expiry — duration_clocks counts down at each reset; 0 = zone_expired
##    reason "duration". damage_zone to 0 = reason "destroyed"; remove_zone =
##    reason "removed" (confluence's redeploy = remove + create).
##    RESET-TICK RACE (documented, deliberate): a dash resolving on the exact
##    tick whose reset expires the zone misses its on_pass/on_enter (the
##    position sweep runs in _post, after the reset removed the zone); the
##    occupancy bite still lands first, so the wall's real menace survives.
##
## BLOCKING SEAM (the minimal composition — documented decision): a
## blocks_movement zone blocks EXACTLY like a wall because Arena.is_wall
## consults this store (the R29 closed-door precedent: ONE query, zero
## consumer edits) — free/scheduled moves, tactical rolls, dash lane ends AND
## phase-3 bounces, sidesteps, knock-asides, flings, pulls, summon placement,
## pathing, staging all inherit it. blocks_los composes into Arena.blocks_lane
## — the one channel Stealth.has_los walks. SHARED-CHOKE-POINT CAVEAT
## (documented, deliberate): blocks_lane also drives dash-lane geometry and
## both Stealth.has_los and the resolver are outside this story's footprint,
## so a blocks_los-ONLY zone (a future smoke curtain) is currently lane-solid
## too; no such zone is authored this story, and the skill story that wants
## sight-only smoke owns the query split. NO-ARENA FIGHTS (documented): the
## legacy unbounded room has no blocking queries at all, so both flags are
## INERT there — zone EFFECTS (enter/occupy/pass) still work; the wall skills
## fire inside arena'd encounters. A blocking zone may not be created on a
## living combatant's hex (zone_blocked_by_body — the door-close precedent;
## frost wall L8 "raise it under a target" lifts this in its own story).
##
## DETERMINISM: ids from the serialized next_id counter; every sweep iterates
## zones in id (store) order and combatants in sorted-id order; zero rng.
## Runtime caches (_hex_sets / blocking indexes / the position baseline) are
## derived state — rebuilt on wire/restore, never serialized.

## Round 3a (frost_wall — the R32 attackability deferral CLOSED): a declared
## attack may target a destructible zone by id (ActionResolver
## _validate_zone_attack / _resolve_zone_attack route the damage here through
## CombatSim.damage_zone). The R14 gate applies verbatim — Force (action/item
## amount + the attacker's Physique push) vs THIS robustness, net = the
## damage; burn-typed net doubles vs a frost_wall zone (the authored "Burn
## damage deals twice as much"). One flat robustness for every zone this
## story (PLACEHOLDER R14 — per-zone robustness waits for the numbers pass).
const WALL_ROBUSTNESS: int = 1

## Trigger names + per-block op names the validator accepts (strict).
const TRIGGERS: Array[String] = ["on_enter", "on_occupy_clock", "on_pass"]
const BLOCK_KEYS: Array[String] = ["affects", "damage", "conditions", "advance"]
const AFFECTS_VALUES: Array[String] = ["all", "non_owner", "hostile"]

## Serialized state.
var next_id: int = 0
## Live zones in creation (= id) order — the array IS command-stream state.
var zones: Array[Dictionary] = []

## Runtime refs (wired by CombatSim, like ConditionEngine/TagEngine).
var combatants: Dictionary = {}
var cond: ConditionEngine = null

## Runtime derived caches — NEVER serialized (rebuilt on wire/restore).
var _hex_sets: Dictionary = {}  # zone id -> {Vector2i: true}
var _block_move: Dictionary = {}  # {Vector2i: true} across blocks_movement zones
var _block_los: Dictionary = {}  # {Vector2i: true} across blocks_los zones
## The position-diff baseline: combatant id -> Vector2i at the end of the last
## sweep. Rebuilt from live positions on wire/restore/create (the sweep always
## leaves it synced at a command boundary, so restoring from current positions
## is exact).
var _last_positions: Dictionary = {}


func setup(combatants_ref: Dictionary, cond_ref: ConditionEngine) -> void:
	combatants = combatants_ref
	cond = cond_ref
	_rebuild_index()
	_sync_positions()


func is_empty() -> bool:
	return zones.is_empty()


# ------------------------------------------------------------------ blocking

## True when a blocks_movement zone covers `hex` (consulted by Arena.is_wall).
func blocks_movement_at(hex: Vector2i) -> bool:
	return _block_move.has(hex)


## True when a blocks_los zone covers `hex` (consulted by Arena.blocks_lane —
## the channel Stealth.has_los walks; see the shared-choke-point caveat above).
func blocks_los_at(hex: Vector2i) -> bool:
	return _block_los.has(hex)


# ------------------------------------------------------------------ internal API

## Creates a zone from `spec` (the ZONE MODEL keys minus id/created_tick).
## Validates strictly; a rejection emits one zone_rejected event and mutates
## nothing. `arena` (may be null) gates placement: in bounds, off authored
## walls/closed doors (zones may overlap zones, trash cans and — for
## non-blocking zones — bodies).
func create(spec: Dictionary, tick: int, arena: Arena) -> Array[Dictionary]:
	var key := String(spec.get("key", ""))
	if key == "":
		return _rejected("zone_missing_key")
	var hexes: Array[Vector2i] = []
	var seen: Dictionary = {}
	var raw_hexes: Variant = spec.get("hexes", [])
	if not (raw_hexes is Array) or (raw_hexes as Array).is_empty():
		return _rejected("zone_invalid_hexes", {"key": key})
	for pair: Variant in raw_hexes as Array:
		if not (pair is Array) or (pair as Array).size() != 2:
			return _rejected("zone_invalid_hexes", {"key": key})
		var hex := Vector2i(int((pair as Array)[0]), int((pair as Array)[1]))
		if not seen.has(hex):
			seen[hex] = true
			hexes.append(hex)
	hexes.sort()
	var duration: int = int(spec.get("duration_clocks", -1))
	if duration != -1 and duration < 1:
		return _rejected("zone_invalid_duration", {"key": key})
	var hp: int = int(spec.get("hp", -1))
	if hp != -1 and hp < 1:
		return _rejected("zone_invalid_hp", {"key": key})
	var effects_variant: Variant = spec.get("effects", {})
	if not (effects_variant is Dictionary):
		return _rejected("zone_invalid_effects", {"key": key})
	var effects: Dictionary = effects_variant
	var effect_reason: String = _validate_effects(effects)
	if effect_reason != "":
		return _rejected(effect_reason, {"key": key})
	var blocks_movement: bool = bool(spec.get("blocks_movement", false))
	var blocks_los: bool = bool(spec.get("blocks_los", false))
	if arena != null:
		for hex: Vector2i in hexes:
			if not arena.in_bounds(hex):
				return _rejected("zone_out_of_bounds", {"key": key, "hex": [hex.x, hex.y]})
			# Authored solids only (walls dict + closed doors — never is_wall,
			# which would see other zones and forbid legal overlaps).
			if arena.walls.has(hex) or arena.is_closed_door(hex):
				return _rejected("zone_on_wall", {"key": key, "hex": [hex.x, hex.y]})
	if blocks_movement:
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			var c: CombatantState = combatants[id]
			if c.alive and not c.removed_from_play and seen.has(c.position):
				return _rejected("zone_blocked_by_body", {"key": key, "by": c.id})
	# The baseline must be honest BEFORE the zone exists: whoever stands in it
	# now was never "entering" it (standing there at creation is occupancy —
	# the next Clock's on_occupy_clock bites, not on_enter).
	_sync_positions()
	next_id += 1
	var hex_rows: Array = []
	for hex: Vector2i in hexes:
		hex_rows.append([hex.x, hex.y])
	var zone: Dictionary = {
		"id": next_id,
		"key": key,
		"hexes": hex_rows,
		"owner": String(spec.get("owner", "")),
		"created_tick": tick,
		"duration_clocks": duration,
		"effects": effects.duplicate(true),
		"hp": hp,
		"blocks_movement": blocks_movement,
		"blocks_los": blocks_los,
	}
	zones.append(zone)
	_rebuild_index()
	return [{
		"type": "zone_created",
		"zone": int(zone["id"]),
		"key": key,
		"owner": String(zone["owner"]),
		"hexes": hex_rows.duplicate(true),
		"duration_clocks": duration,
		"hp": hp,
		"blocks_movement": blocks_movement,
		"blocks_los": blocks_los,
	}]


## Removes a zone outright (the confluence redeploy path = remove + create).
func remove(zone_id: int, reason: String = "removed") -> Array[Dictionary]:
	var idx: int = _zone_index(zone_id)
	if idx < 0:
		return _rejected("zone_unknown", {"zone": zone_id})
	return _expire(idx, reason)


## Decrements a destructible zone's hp (frost walls). THE ONLY hp path this
## story — attackability (resolver targeting, the Burn-x2 rule) is the next
## story's footprint. Removal at 0 (zone_expired reason "destroyed").
func damage(zone_id: int, amount: int) -> Array[Dictionary]:
	var idx: int = _zone_index(zone_id)
	if idx < 0:
		return _rejected("zone_unknown", {"zone": zone_id})
	var zone: Dictionary = zones[idx]
	if int(zone.get("hp", -1)) < 0:
		return _rejected("zone_indestructible", {"zone": zone_id})
	if amount <= 0:
		return _rejected("zone_invalid_damage_amount", {"zone": zone_id})
	zone["hp"] = maxi(0, int(zone["hp"]) - amount)
	var events: Array[Dictionary] = [{
		"type": "zone_damaged",
		"zone": zone_id,
		"key": String(zone.get("key", "")),
		"amount": amount,
		"hp": int(zone["hp"]),
	}]
	if int(zone["hp"]) == 0:
		events.append_array(_expire(idx, "destroyed"))
	return events


# ------------------------------------------------------------------ sweeps

## The _post position sweep (CombatSim calls it FIRST, before the death-cancel
## scan, so zone-authored deaths get the same housekeeping as any batch
## event): on_pass off this batch's dash corridors, then on_enter off the
## position diff, then the baseline sync. Deterministic — batch order for
## dashes, sorted-id order for movers, id order for zones; zero rng. No-op
## (no events, no state) while no zone exists — the legacy compat pin.
func position_sweep(batch: Array[Dictionary], tick: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if zones.is_empty():
		_sync_positions()
		return out
	# 1. on_pass — dash corridors (the one traversal the machinery exposes).
	for event: Dictionary in batch:
		if String(event.get("type", "")) != "dash_charged":
			continue
		var mover: CombatantState = combatants.get(String(event.get("actor", "")))
		if mover == null:
			continue
		var corridor: Array[Vector2i] = _corridor_from_event(event)
		if corridor.size() < 3:
			continue  # no interior hexes — nothing was passed through
		var from_hex: Vector2i = corridor[0]
		var to_hex: Vector2i = corridor[corridor.size() - 1]
		for zone: Dictionary in zones:
			if not mover.alive or mover.removed_from_play:
				break  # died in an earlier wall this very crossing
			var hexes: Dictionary = _hex_sets.get(int(zone["id"]), {})
			if hexes.has(from_hex) or hexes.has(to_hex):
				continue  # started inside / ended inside — not a pass-through
			for k: int in range(1, corridor.size() - 1):
				if hexes.has(corridor[k]):
					out.append_array(_apply_effects(zone, "on_pass", mover, tick))
					break  # one on_pass per zone per dash
	# 2. on_enter — the position diff against the baseline.
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = combatants[id]
		var prev_variant: Variant = _last_positions.get(String(id))
		_last_positions[String(id)] = c.position
		if prev_variant == null:
			continue  # newcomer (staging/summon) — baseline silently
		var prev: Vector2i = prev_variant
		if prev == c.position or not c.alive or c.removed_from_play:
			continue
		for zone: Dictionary in zones:
			if not c.alive or c.removed_from_play:
				break
			var hexes: Dictionary = _hex_sets.get(int(zone["id"]), {})
			if hexes.has(c.position) and not hexes.has(prev):
				out.append_array(_apply_effects(zone, "on_enter", c, tick))
	_prune_positions()
	return out


## The Clock-reset sweep (CombatSim's completes_clock block, AFTER the
## universal condition advancement): the occupancy bite first, then the
## duration countdown — a 1-Clock wall menaces through the reset that kills
## it. Deterministic; zero rng; no-op while no zone exists.
func clock_reset_sweep(tick: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if zones.is_empty():
		return out
	for zone: Dictionary in zones:
		var block: Dictionary = (zone.get("effects", {}) as Dictionary).get("on_occupy_clock", {})
		if block.is_empty():
			continue
		var hexes: Dictionary = _hex_sets.get(int(zone["id"]), {})
		var ids: Array = combatants.keys()
		ids.sort()
		for id: Variant in ids:
			var c: CombatantState = combatants[id]
			if c.alive and not c.removed_from_play and hexes.has(c.position):
				out.append_array(_apply_effects(zone, "on_occupy_clock", c, tick))
	# Duration countdown — collect first, expire in id order (indexes shift).
	var expired_ids: Array[int] = []
	for zone: Dictionary in zones:
		if int(zone.get("duration_clocks", -1)) > 0:
			zone["duration_clocks"] = int(zone["duration_clocks"]) - 1
			if int(zone["duration_clocks"]) == 0:
				expired_ids.append(int(zone["id"]))
	for zone_id: int in expired_ids:
		out.append_array(_expire(_zone_index(zone_id), "duration"))
	return out


# ------------------------------------------------------------------ effects

## Applies one trigger block of `zone` to combatant `c`: the affects selector,
## then damage (R14-typed through the normal paths), conditions (via
## ConditionEngine.apply, attacker = the zone's owner — attribution), and
## advances. Emits zone_effect_applied ahead of the downstream events.
func _apply_effects(zone: Dictionary, trigger: String, c: CombatantState, tick: int) -> Array[Dictionary]:
	var block: Dictionary = (zone.get("effects", {}) as Dictionary).get(trigger, {})
	if block.is_empty():
		return []
	var owner := String(zone.get("owner", ""))
	match String(block.get("affects", "all")):
		"non_owner":
			if c.id == owner:
				return []
		"hostile":
			var owner_c: CombatantState = combatants.get(owner)
			# Absent owner = no team to be hostile to; same team (incl. the
			# teamless-vs-teamless "" == "") is never hostile (_opponents rule).
			if owner_c == null or owner_c.team == c.team:
				return []
	var out: Array[Dictionary] = [{
		"type": "zone_effect_applied",
		"zone": int(zone["id"]),
		"key": String(zone.get("key", "")),
		"trigger": trigger,
		"combatant": c.id,
		"owner": owner,
	}]
	if block.has("damage"):
		var dmg: Dictionary = block["damage"]
		var condition_id: String = ConditionEngine.normalize_condition_id(String(dmg.get("type", "")))
		var part: String = _part_for(c, String(dmg.get("part", "torso")))
		if part != "":
			var reduced: int = Resistance.reduce_damage(
				int(dmg.get("amount", 0)), c, cond.def_for(condition_id), condition_id)
			out.append_array(cond.damage_part(
				c, part, reduced, "environment", condition_id, tick, owner))
	for entry: Variant in block.get("conditions", []) as Array:
		var row: Dictionary = entry
		var ctx: Dictionary = {
			"source": String(row.get("source", "direct")),
			"tier": maxi(1, int(row.get("tier", 1))),
			"attacker": owner,
		}
		if row.has("poison_type"):
			ctx["poison_type"] = String(row["poison_type"])
		out.append_array(cond.apply(
			c, String(row.get("part", "torso")), String(row.get("condition", "")), tick, ctx))
	for entry: Variant in block.get("advance", []) as Array:
		var row: Dictionary = entry
		var condition_id := String(row.get("condition", ""))
		var steps: int = maxi(1, int(row.get("steps", 1)))
		var part_keys: Array = c.conditions.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			if (c.conditions[part_key] as Dictionary).has(condition_id):
				out.append_array(cond.advance(c, String(part_key), condition_id, steps, tick, "zone"))
	return out


## Deterministic damage-part fallback (mirrors the ConditionEngine S2.6
## chain): the asked-for part if the combatant has it, else torso, else the
## first sorted lethal part, else the first sorted part, else "" (no target).
func _part_for(c: CombatantState, asked: String) -> String:
	if c.parts.has(asked):
		return asked
	if c.parts.has("torso"):
		return "torso"
	var keys: Array = c.parts.keys()
	keys.sort()
	for key: Variant in keys:
		if bool((c.parts[key] as Dictionary).get("lethal", false)):
			return String(key)
	if not keys.is_empty():
		return String(keys[0])
	return ""


# ------------------------------------------------------------------ helpers

static func _rejected(reason: String, detail: Dictionary = {}) -> Array[Dictionary]:
	var event: Dictionary = {"type": "zone_rejected", "reason": reason}
	event.merge(detail)
	return [event]


## Round 3a — the live zone row by id ({} when unknown). Read-side query for
## the zone-attack path (validation reads hp/key/hexes; mutation still flows
## ONLY through create/remove/damage). Returns the LIVE dict, not a copy —
## callers must not mutate it (the combatants-dict discipline).
func zone_by_id(zone_id: int) -> Dictionary:
	var idx: int = _zone_index(zone_id)
	return zones[idx] if idx >= 0 else {}


func _zone_index(zone_id: int) -> int:
	for i: int in range(zones.size()):
		if int(zones[i].get("id", 0)) == zone_id:
			return i
	return -1


func _expire(idx: int, reason: String) -> Array[Dictionary]:
	if idx < 0:
		return []
	var zone: Dictionary = zones[idx]
	zones.remove_at(idx)
	_rebuild_index()
	return [{
		"type": "zone_expired",
		"zone": int(zone.get("id", 0)),
		"key": String(zone.get("key", "")),
		"reason": reason,
	}]


## Strict effects validation — "" = ok, else the rejection reason.
func _validate_effects(effects: Dictionary) -> String:
	for trigger: Variant in effects:
		if not TRIGGERS.has(String(trigger)):
			return "zone_unknown_trigger"
		var block_variant: Variant = effects[trigger]
		if not (block_variant is Dictionary):
			return "zone_invalid_effect_block"
		var block: Dictionary = block_variant
		for op: Variant in block:
			if not BLOCK_KEYS.has(String(op)):
				return "zone_unknown_effect_op"
		if block.has("affects") and not AFFECTS_VALUES.has(String(block["affects"])):
			return "zone_invalid_affects"
		if block.has("damage"):
			if not (block["damage"] is Dictionary):
				return "zone_invalid_damage"
			var dmg: Dictionary = block["damage"]
			for sub: Variant in dmg:
				if not ["type", "amount", "part"].has(String(sub)):
					return "zone_invalid_damage"
			if String(dmg.get("type", "")) == "" or int(dmg.get("amount", 0)) < 1:
				return "zone_invalid_damage"
		if block.has("conditions"):
			if not (block["conditions"] is Array):
				return "zone_invalid_conditions"
			for entry: Variant in block["conditions"] as Array:
				if not (entry is Dictionary):
					return "zone_invalid_conditions"
				var row: Dictionary = entry
				for sub: Variant in row:
					if not ["condition", "tier", "part", "poison_type", "source"].has(String(sub)):
						return "zone_invalid_conditions"
				if String(row.get("condition", "")) == "":
					return "zone_invalid_conditions"
				if row.has("source") and not ["direct", "attack"].has(String(row["source"])):
					return "zone_invalid_conditions"
		if block.has("advance"):
			if not (block["advance"] is Array):
				return "zone_invalid_advance"
			for entry: Variant in block["advance"] as Array:
				if not (entry is Dictionary):
					return "zone_invalid_advance"
				var row: Dictionary = entry
				for sub: Variant in row:
					if not ["condition", "steps"].has(String(sub)):
						return "zone_invalid_advance"
				if String(row.get("condition", "")) == "":
					return "zone_invalid_advance"
	return ""


## Reconstructs the hexes a dash_charged event's corridor actually traversed,
## in walk order (from first, final hex last). Segments between committed
## waypoints (bounces in walk order, or the single declared bend) are straight
## hex lines BY CONSTRUCTION (bounced_lane / _compose_bent_lane build them
## from line/line_extended), so chaining HexGeometry.line over the waypoints
## is exact; a waypoint past the corridor's real end (stopped short) is
## detected by the destination appearing on an earlier segment. Today's lane
## builders never author bend AND bounces on one lane — a hand-built composite
## falls back to the straight from->to line (documented degenerate). The
## head-on retrace under-walk is documented in the header.
static func _corridor_from_event(event: Dictionary) -> Array[Vector2i]:
	var from_raw: Array = event.get("from", [])
	var to_raw: Array = event.get("to", [])
	if from_raw.size() != 2 or to_raw.size() != 2:
		return []
	var from := Vector2i(int(from_raw[0]), int(from_raw[1]))
	var to := Vector2i(int(to_raw[0]), int(to_raw[1]))
	var waypoints: Array[Vector2i] = []
	if event.has("bounces") and not event.has("bend"):
		for pair: Variant in event.get("bounces", []) as Array:
			if pair is Array and (pair as Array).size() == 2:
				waypoints.append(Vector2i(int((pair as Array)[0]), int((pair as Array)[1])))
	elif event.has("bend") and not event.has("bounces"):
		var bend_raw: Array = event.get("bend", [])
		if bend_raw.size() == 2:
			waypoints.append(Vector2i(int(bend_raw[0]), int(bend_raw[1])))
	var corridor: Array[Vector2i] = [from]
	var cur: Vector2i = from
	for waypoint: Vector2i in waypoints:
		if cur == to:
			return corridor
		var seg: Array[Vector2i] = HexGeometry.line(cur, waypoint)
		var end_idx: int = seg.find(to, 1)
		if end_idx >= 1:
			for k: int in range(1, end_idx + 1):
				corridor.append(seg[k])
			return corridor  # the dash stopped on this segment
		for k: int in range(1, seg.size()):
			corridor.append(seg[k])
		cur = waypoint
	if cur != to:
		var tail: Array[Vector2i] = HexGeometry.line(cur, to)
		for k: int in range(1, tail.size()):
			corridor.append(tail[k])
	return corridor


func _rebuild_index() -> void:
	_hex_sets = {}
	_block_move = {}
	_block_los = {}
	for zone: Dictionary in zones:
		var hexes: Dictionary = {}
		for pair: Variant in zone.get("hexes", []) as Array:
			var hex := Vector2i(int((pair as Array)[0]), int((pair as Array)[1]))
			hexes[hex] = true
			if bool(zone.get("blocks_movement", false)):
				_block_move[hex] = true
			if bool(zone.get("blocks_los", false)):
				_block_los[hex] = true
		_hex_sets[int(zone.get("id", 0))] = hexes


func _sync_positions() -> void:
	_last_positions = {}
	var ids: Array = combatants.keys()
	ids.sort()
	for id: Variant in ids:
		_last_positions[String(id)] = (combatants[id] as CombatantState).position


func _prune_positions() -> void:
	for id: Variant in _last_positions.keys():
		if not combatants.has(String(id)):
			_last_positions.erase(id)


# ------------------------------------------------------------------ view

## Read-only plain-Dictionary projection (GameController.view_zones): one row
## per live zone in id order, deep-copied — a renderer draws the fields
## without touching simulation classes.
func view() -> Array:
	var out: Array = []
	for zone: Dictionary in zones:
		out.append({
			"id": int(zone.get("id", 0)),
			"key": String(zone.get("key", "")),
			"owner": String(zone.get("owner", "")),
			"hexes": (zone.get("hexes", []) as Array).duplicate(true),
			"created_tick": int(zone.get("created_tick", 0)),
			"duration_clocks": int(zone.get("duration_clocks", -1)),
			"hp": int(zone.get("hp", -1)),
			"blocks_movement": bool(zone.get("blocks_movement", false)),
			"blocks_los": bool(zone.get("blocks_los", false)),
			"effects": (zone.get("effects", {}) as Dictionary).duplicate(true),
		})
	return out


# ------------------------------------------------------------------ serialization

func to_dict() -> Dictionary:
	return {
		"next_id": next_id,
		"zones": zones.duplicate(true),
	}


static func from_dict(data: Dictionary) -> Zones:
	var store := Zones.new()
	store.next_id = int(data.get("next_id", 0))
	for entry: Variant in data.get("zones", []) as Array:
		store.zones.append((entry as Dictionary).duplicate(true))
	return store
