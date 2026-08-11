extends SimTestBase
## Real hex geometry (decision #31 — retires the R11 #16 "cone N / line resolve
## as plain reach" deferral): HexGeometry primitives pinned against the header's
## hand-drawn shapes, the boss's arc-aimed flamethrower, the dash charge lane,
## the shape-honest windup re-checks, and full determinism with the new shapes
## in the log. The ASCII diagrams in simulation/hex_geometry.gd are the source
## of truth for the exact hex sets asserted here.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold (the
## test_incinedile spec choice) — geometry pins never consume the AI stream.
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


func hexes(pairs: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for pair: Variant in pairs:
		out.append(Vector2i(int((pair as Array)[0]), int((pair as Array)[1])))
	return out


# ---------------------------------------------------------------- primitives

func test_directions_match_enemy_ai_fixed_order() -> void:
	# The two fixed-order constants must never drift — every tie-break in the
	# geometry and every movement plan in the AI walk the same six directions.
	assert_eq(HexGeometry.DIRECTIONS, EnemyAI.HEX_NEIGHBORS,
		"HexGeometry.DIRECTIONS is EnemyAI.HEX_NEIGHBORS, entry for entry")


func test_distance_matches_combatant_hex_distance() -> void:
	# HexGeometry.distance is documented bit-identical to the sim's norm.
	var mismatches: int = 0
	for q: int in range(-6, 7):
		for r: int in range(-6, 7):
			var a := Vector2i(q, r)
			var b := Vector2i(-r, q - 2)
			if HexGeometry.distance(a, b) != CombatantState.hex_distance(a, b):
				mismatches += 1
	assert_eq(mismatches, 0, "distance agrees with CombatantState.hex_distance everywhere probed")


func test_line_straight_and_tie_cases() -> void:
	assert_eq(HexGeometry.line(Vector2i(0, 0), Vector2i(3, 0)),
		hexes([[0, 0], [1, 0], [2, 0], [3, 0]]), "straight E line, origin first")
	assert_eq(HexGeometry.line(Vector2i(2, 2), Vector2i(2, 2)), hexes([[2, 2]]),
		"degenerate line is just the hex")
	# TIE CASE (the documented rule): the midpoint of (0,0)->(2,-1) falls exactly
	# between (1,0) and (1,-1); the +y epsilon translation breaks it to (1,-1).
	var tie: Array[Vector2i] = HexGeometry.line(Vector2i(0, 0), Vector2i(2, -1))
	assert_eq(tie, hexes([[0, 0], [1, -1], [2, -1]]), "tie breaks to (1,-1), deterministically")
	assert_eq(HexGeometry.line(Vector2i(0, 0), Vector2i(2, -1)), tie,
		"the same call always draws the same line")
	# The nudge is a pure translation, so the reversed line holds the SAME hexes.
	var reversed_line: Array[Vector2i] = HexGeometry.line(Vector2i(2, -1), Vector2i(0, 0))
	reversed_line.reverse()
	assert_eq(reversed_line, tie, "line(b,a) is line(a,b) reversed — same hexes")
	# Consecutive line hexes are always adjacent (the lane-walk invariant).
	var long_line: Array[Vector2i] = HexGeometry.line(Vector2i(-3, 5), Vector2i(4, -2))
	for i: int in range(1, long_line.size()):
		assert_eq(HexGeometry.distance(long_line[i - 1], long_line[i]), 1,
			"line step %d is one hex" % i)


func test_line_extended_is_the_lane() -> void:
	assert_eq(HexGeometry.line_extended(Vector2i(0, 0), Vector2i(1, 0), 6),
		hexes([[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]),
		"the E lane runs origin -> 6 hexes out")
	# Continuing a tie-case direction: same samples, same tie rule, extended.
	assert_eq(HexGeometry.line_extended(Vector2i(0, 0), Vector2i(2, -1), 4),
		hexes([[0, 0], [1, -1], [2, -1], [3, -2], [4, -2]]),
		"the lane continues the from->through direction")
	# line(from, to) is exactly the lane truncated at the target's distance.
	var full: Array[Vector2i] = HexGeometry.line_extended(Vector2i(1, 1), Vector2i(4, -1), 6)
	var prefix: Array[Vector2i] = HexGeometry.line(Vector2i(1, 1), Vector2i(4, -1))
	assert_eq(full.slice(0, prefix.size()), prefix, "line() is the lane's prefix")
	assert_eq(HexGeometry.line_extended(Vector2i(2, 2), Vector2i(2, 2), 6), hexes([[2, 2]]),
		"degenerate lane (no direction) is just the origin")
	# Lane hexes are distinct and consecutive-adjacent (charge-walk invariants).
	var seen: Dictionary = {}
	for i: int in range(full.size()):
		assert_false(seen.has(full[i]), "lane hex %d not repeated" % i)
		seen[full[i]] = true
		if i > 0:
			assert_eq(HexGeometry.distance(full[i - 1], full[i]), 1, "lane step %d is one hex" % i)


func test_cone_size_two_exact_set() -> void:
	# The size-2 ASCII diagram in the header, verbatim (E direction, sorted).
	assert_eq(HexGeometry.cone(Vector2i(0, 0), Vector2i(1, 0), 2),
		hexes([[0, 1], [0, 2], [1, -1], [1, 0], [1, 1], [2, -2], [2, -1], [2, 0]]),
		"size-2 E cone is exactly the 8 diagrammed hexes")


func test_cone_size_three_exact_set() -> void:
	# The size-3 ASCII diagram in the header, verbatim (E direction, sorted).
	assert_eq(HexGeometry.cone(Vector2i(0, 0), Vector2i(1, 0), 3),
		hexes([
			[0, 1], [0, 2], [0, 3],
			[1, -1], [1, 0], [1, 1], [1, 2],
			[2, -2], [2, -1], [2, 0], [2, 1],
			[3, -3], [3, -2], [3, -1], [3, 0],
		]),
		"size-3 E cone is exactly the 15 diagrammed hexes")


func test_cone_counts_symmetry_and_translation() -> void:
	# |cone| = size^2 + 2*size (2k+1 hexes per ring); origin never included;
	# everything within `size` distance of the origin.
	for size: int in range(1, 5):
		var arc: Array[Vector2i] = HexGeometry.cone(Vector2i(0, 0), Vector2i(1, 0), size)
		assert_eq(arc.size(), size * size + 2 * size, "size-%d cone hex count" % size)
		var members: Dictionary = HexGeometry.to_set(arc)
		assert_false(members.has(Vector2i(0, 0)), "origin is never in its own cone")
		for hex: Vector2i in arc:
			assert_true(HexGeometry.distance(Vector2i(0, 0), hex) <= size,
				"cone hex %s within size" % str(hex))
	# Symmetric where the data is symmetric: the E cone is closed under
	# reflection across its own axis ((q, r) -> (q + r, -r)).
	var e_cone: Dictionary = HexGeometry.to_set(HexGeometry.cone(Vector2i(0, 0), Vector2i(1, 0), 3))
	for hex: Variant in e_cone:
		var v: Vector2i = hex
		assert_true(e_cone.has(Vector2i(v.x + v.y, -v.y)), "mirror of %s in the cone" % str(v))
	# Translation invariance: the cone moves rigidly with its origin.
	var moved: Array[Vector2i] = HexGeometry.cone(Vector2i(3, -2), Vector2i(4, -2), 2)
	var base: Array[Vector2i] = HexGeometry.cone(Vector2i(0, 0), Vector2i(1, 0), 2)
	for i: int in range(base.size()):
		assert_eq(moved[i], base[i] + Vector2i(3, -2), "translated cone hex %d" % i)


func test_direction_index_snapping_and_ties() -> void:
	for idx: int in range(6):
		assert_eq(HexGeometry.direction_index(Vector2i.ZERO, HexGeometry.DIRECTIONS[idx]), idx,
			"each neighbor snaps to its own direction (%d)" % idx)
	assert_eq(HexGeometry.direction_index(Vector2i.ZERO, Vector2i(4, 0)), 0, "far E hex snaps E")
	assert_eq(HexGeometry.direction_index(Vector2i.ZERO, Vector2i(-3, 0)), 3, "far W hex snaps W")
	# (1,1) sits exactly between E (index 0) and SE (index 5): the earlier
	# fixed-order entry wins the documented tie.
	assert_eq(HexGeometry.direction_index(Vector2i.ZERO, Vector2i(1, 1)), 0,
		"exact between-directions tie takes the earlier DIRECTIONS entry")
	assert_eq(HexGeometry.direction_index(Vector2i(2, 2), Vector2i(2, 2)), -1, "no direction to itself")


func test_blast_matches_distance_semantics() -> void:
	# The regression bar: blast membership IS the beat code's old direct
	# distance <= radius check, center included.
	var area: Dictionary = HexGeometry.to_set(HexGeometry.blast(Vector2i(1, -1), 3))
	for q: int in range(-4, 6):
		for r: int in range(-6, 5):
			var hex := Vector2i(q, r)
			assert_eq(area.has(hex), HexGeometry.distance(Vector2i(1, -1), hex) <= 3,
				"blast membership == distance rule at %s" % str(hex))
	assert_eq(HexGeometry.blast(Vector2i(5, 5), 0), hexes([[5, 5]]), "radius 0 is the center alone")
	var sorted_area: Array[Vector2i] = HexGeometry.blast(Vector2i(0, 0), 2)
	for i: int in range(1, sorted_area.size()):
		assert_true(sorted_area[i - 1] < sorted_area[i], "blast output strictly sorted")


# ---------------------------------------------------------------- cone aiming (AI)

func test_cone_aim_maximizes_targets_with_fixed_order_ties() -> void:
	# Direct _best_cone_sweep pins: the aim is the direction catching the MOST
	# opponents; an exact tie keeps the earlier HEX_NEIGHBORS entry.
	var sim: CombatSim = make_sim()
	add_human(sim, "wa", {"team": "party", "position": [-2, 0]})
	add_human(sim, "wb", {"team": "party", "position": [-1, 1]})
	add_human(sim, "eg", {"team": "party", "position": [3, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var boss: CombatantState = sim.combatants["boss"]
	var cone_ability: Dictionary = sim.ai._first_cone_ability(boss, [])
	assert_eq(String(cone_ability.get("key", "")), "flamethrower", "the seeded cone ability")
	var sweep: Dictionary = sim.ai._best_cone_sweep(boss, cone_ability, sim.ai._opponents(boss))
	assert_eq(sweep["toward"], Vector2i(-1, 0), "the W arc catches two, E only one")
	var caught: Array[String] = []
	for c: CombatantState in sweep["targets"]:
		caught.append(c.id)
	assert_eq(caught, ["wa", "wb"], "exactly the in-arc pair, sorted-id order")
	# Tie case: one target each on the E and W axes — equal counts everywhere
	# they land, so the FIRST fixed-order direction with the max count wins.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "east", {"team": "party", "position": [2, 0]})
	add_human(sim2, "west", {"team": "party", "position": [-2, 0]})
	add_enemy(sim2, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var boss2: CombatantState = sim2.combatants["boss"]
	var sweep2: Dictionary = sim2.ai._best_cone_sweep(boss2, sim2.ai._first_cone_ability(boss2, []),
		sim2.ai._opponents(boss2))
	assert_eq(sweep2["toward"], Vector2i(1, 0),
		"1-vs-1 tie: the earliest fixed-order direction (E) wins")


func test_boss_aims_the_arc_that_catches_the_crowd() -> void:
	# Sim-level honesty: a target inside plain range-10 but OUTSIDE the chosen
	# arc is NOT swept (the retired deferral would have burned all three).
	var sim: CombatSim = make_sim()
	add_human(sim, "wa", {"team": "party", "position": [-2, 0]})
	add_human(sim, "wb", {"team": "party", "position": [-1, 1]})
	add_human(sim, "eg", {"team": "party", "position": [2, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "boss decided")
	assert_eq(String(decision.get("ability", "")), "flamethrower", "two in the W arc -> sweep")
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var burned: Dictionary = {}
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		burned[String(hit.get("combatant", ""))] = true
	assert_true(burned.has("wa") and burned.has("wb"), "both in-arc targets burned")
	assert_false(burned.has("eg"), "in range-10 but OUTSIDE the arc: not swept (decision #31)")


func test_cone_windup_recheck_excludes_arc_leavers() -> void:
	# R2 through the REAL shape: leaving the ARC before resolution dodges the
	# sweep for that target; a target that moves but STAYS inside is still hit.
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "flamethrower",
		"both in the E arc -> sweep declared")
	advance(sim, 1)
	# During the windup (an EARLIER tick than resolution — R11 #2): hb steps out
	# of the arc but stays within plain range; ha shifts WITHIN the arc.
	sim.apply_command({"type": "move", "actor": "hb", "to": [-1, 2]})
	sim.apply_command({"type": "move", "actor": "ha", "to": [1, 1]})
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var escaped: Dictionary = assert_event(resolved, "windup_target_escaped",
		"the arc-leaver dodged the sweep")
	assert_eq(String(escaped.get("target", "")), "hb", "hb left the arc")
	assert_eq(String(escaped.get("reason", "")), "left_area", "the area reason is recorded")
	var burned: Dictionary = {}
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		burned[String(hit.get("combatant", ""))] = true
	assert_true(burned.has("ha"), "moving WITHIN the arc does not dodge — ha still burned")
	assert_false(burned.has("hb"), "the arc-leaver takes nothing")
	var done: Dictionary = assert_event(resolved, "action_resolved", "the shrunk sweep still resolves")
	assert_eq(int(done.get("rounds", -1)), 1, "one round per REMAINING swept target")


func test_cone_windup_collapses_when_every_target_escapes() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	ai_decide(sim, "boss")
	advance(sim, 1)
	# (2,-3) and (-1,2) are both still within plain range 10 but OUTSIDE the
	# declared E arc ((2,-2) would NOT do — it sits ON the arc's boundary ray).
	sim.apply_command({"type": "move", "actor": "ha", "to": [2, -3]})
	sim.apply_command({"type": "move", "actor": "hb", "to": [-1, 2]})
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated",
		"an emptied sweep collapses like an out-of-range windup")
	assert_eq(String(invalidated.get("reason", "")), "left_area", "every target escaped the arc")
	assert_event(resolved, "forced_action_triggered", "the collapse rolls Forced Action – Tool")
	assert_no_event(resolved, "damage_applied", "nobody is burned")
	assert_eq(events_of(resolved, "windup_target_escaped").size(), 2, "both escapes recorded")


# ---------------------------------------------------------------- dash lane

## Reflexes-2 target spec: the dash's threshold-7 dodge is IMPOSSIBLE (2 + d4
## max = 6 < 7) so charge outcomes are deterministic and consume no rng.
func cannot_dodge_traits() -> Dictionary:
	return {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}


func test_dash_charges_the_lane_and_ends_adjacent_before_target() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [5, 0], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "boss decided")
	assert_eq(String(decision.get("ability", "")), "dash", "lone target on a clear lane -> dash")
	assert_false(bool(decision.get("moves", true)), "distance 5 <= lane 6: no pre-step needed")
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(resolved, "dash_charged", "the boss runs its lane")
	assert_eq(charged.get("from", []), [0, 0], "from the declare hex")
	assert_eq(charged.get("to", []), [4, 0], "to the hex adjacent-before the target")
	assert_eq(int(charged.get("hexes", 0)), 4, "four lane hexes covered")
	assert_eq((sim.combatants["boss"] as CombatantState).position, Vector2i(4, 0),
		"the charge is a real position change")
	var damage: Dictionary = assert_event(resolved, "damage_applied", "contact: the strike lands")
	assert_eq(String(damage.get("combatant", "")), "h", "on the lane target")
	assert_no_event(resolved, "dash_stopped_short", "nothing blocked the lane")


func test_dash_blocked_lane_makes_the_ai_close_instead() -> void:
	# A body on every charge lane to the pick: the AI must NOT dash (the picked
	# target is not lane-reachable) — it falls back to closing distance.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	# Same-team blocker parked mid-lane (never an opponent, never fed a decide).
	add_enemy(sim, "wall", "roach_dog", {"position": [2, 0]})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "boss decided")
	assert_eq(String(decision.get("choice", "")), "move", "no legal lane -> close, don't dash")
	assert_no_event(events, "action_declared", "no dash was declared at an unreachable pick")
	var moved: Dictionary = assert_event(events, "moved", "the fallback step executed")
	assert_eq(moved.get("to", []), [1, 0], "one honest step toward the pick")


func test_dash_charge_stopped_short_is_an_honest_miss() -> void:
	# An interloper steps ONTO the lane during the windup: the charge stops
	# BEFORE the occupied hex, out of reach — an honest miss, no Tool collapse,
	# and the interloper is NOT hit (v1: only declared targets are ever hit).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [4, 0], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	add_enemy(sim, "walker", "roach_dog", {"position": [2, 1]})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "dash",
		"clear lane at declare -> dash")
	advance(sim, 1)
	sim.apply_command({"type": "move", "actor": "walker", "to": [2, 0]})  # onto the lane
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(resolved, "dash_charged", "the boss still charges")
	assert_eq(charged.get("to", []), [1, 0], "stopped BEFORE the first occupied lane hex")
	var short: Dictionary = assert_event(resolved, "dash_stopped_short", "out of reach: honest miss")
	assert_eq(String(short.get("target", "")), "h", "the declared target escaped")
	assert_eq(int(short.get("distance", 0)), 3, "three hexes short of the target")
	var done: Dictionary = assert_event(resolved, "action_resolved", "the Moment was spent charging")
	assert_eq(String(done.get("result", "")), "stopped_short", "reported as the miss it is")
	assert_no_event(resolved, "damage_applied", "no hit lands on anyone")
	assert_no_event(resolved, "forced_action_triggered", "a miss is not a collapse — no Tool roll")
	assert_eq((sim.combatants["boss"] as CombatantState).position, Vector2i(1, 0),
		"the boss holds where the body stopped it")


func test_dash_windup_dodged_by_leaving_the_lane() -> void:
	# R2 through the REAL lane: stepping OFF the charge corridor before the
	# resolution tick dodges the dash entirely (the standard windup collapse).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	ai_decide(sim, "boss")
	advance(sim, 1)
	sim.apply_command({"type": "move", "actor": "h", "to": [2, 1]})  # off the r=0 lane
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated", "the lane-leaver dodged")
	assert_eq(String(invalidated.get("reason", "")), "left_lane", "the lane reason is recorded")
	assert_event(resolved, "forced_action_triggered", "the collapse rolls Forced Action – Tool")
	assert_no_event(resolved, "damage_applied", "nothing lands")
	assert_no_event(resolved, "dash_charged", "no charge down an abandoned lane")
	assert_eq((sim.combatants["boss"] as CombatantState).position, Vector2i(0, 0),
		"the boss never moved")


func test_dash_sidestep_leaves_the_lane() -> void:
	# Decision #31 sidestep rule: the dodger's displacement is OFF the committed
	# lane specifically — first free fixed-order neighbor not on it.
	var sim: CombatSim = make_sim()
	add_human(sim, "dodger", {"team": "party", "position": [2, 0],
		"traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 3)
	assert_event(resolved, "attack_dodged", "Reflexes 7 auto-dodges the dash")
	var sidestep: Dictionary = assert_event(resolved, "dash_sidestepped", "the sidestep rides the dodge")
	# Lane (0,0)..(6,0); dodger at (2,0): (3,0) is ON the lane, so the first
	# free off-lane neighbor is (3,-1) ((2,0)+(1,-1)).
	assert_eq(sidestep.get("to", []), [3, -1], "first fixed-order neighbor OFF the lane")
	var lane_set: Dictionary = HexGeometry.to_set(
		HexGeometry.line_extended(Vector2i(0, 0), Vector2i(2, 0), 6))
	assert_false(lane_set.has((sim.combatants["dodger"] as CombatantState).position),
		"the dodger is genuinely off the charge lane")
	assert_no_event(resolved, "damage_applied", "the dodge negates the dash")


# ---------------------------------------------------------------- determinism

## Deterministic mixed-shape driver: ha pounds an aimed part every ready tick;
## hb oscillates across the E-arc boundary, so the boss's sweeps alternate
## between catching two (cone windup, sometimes dodged mid-windup by hb's
## step-out) and one (dash + charge + the R22 ladder) — cone, dash, exclusion
## and charge geometry all enter the log.
func _drive_shapes(sim: CombatSim, ticks: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for t: int in range(ticks):
		var ha: CombatantState = sim.combatants.get("ha")
		if ha != null and ha.can_act(sim.clock.tick) \
				and sim.clock.tick >= ha.next_action_tick and not ha.windup_pending:
			events.append_array(declare(sim, "ha", attack_action("crushed", 2, "boss", "right_hand")))
		var hb: CombatantState = sim.combatants.get("hb")
		if hb != null and hb.can_act(sim.clock.tick) and not hb.moved_this_tick \
				and not hb.free_action_used and not hb.windup_pending:
			var to: Vector2i = Vector2i(-1, 2) if hb.position == Vector2i(0, 2) else Vector2i(0, 2)
			events.append_array(sim.apply_command({"type": "move", "actor": "hb",
				"to": [to.x, to.y]}))
		for id: String in sim.ai_ready_ids():
			events.append_array(ai_decide(sim, id))
		events.append_array(advance(sim, 1))
	return events


func _staged_shape_fight(sim_seed: int) -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "ha", {"team": "party", "position": [2, 0], "traits": cannot_dodge_traits()})
	add_human(sim, "hb", {"team": "party", "position": [0, 2], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile")
	return sim


func test_full_determinism_with_real_shapes_in_the_log() -> void:
	var full_a: CombatSim = _staged_shape_fight(4242)
	var full_b: CombatSim = _staged_shape_fight(4242)
	var log_a: Array[Dictionary] = _drive_shapes(full_a, 16)
	_drive_shapes(full_b, 16)
	assert_eq(full_a.state_hash(), full_b.state_hash(),
		"same (seed, command log) -> same hash with cones + dashes on the new shapes")
	# The script genuinely exercised the new geometry.
	var abilities: Dictionary = {}
	for event: Dictionary in events_of(log_a, "ai_decision"):
		abilities[String(event.get("ability", ""))] = true
	assert_true(abilities.has("flamethrower"), "the fight declared cone sweeps")
	assert_true(abilities.has("dash"), "the fight declared dashes")
	assert_true(events_of(log_a, "windup_target_escaped").size() >= 1,
		"the arc re-check actually excluded a leaver")
	assert_true(events_of(log_a, "dash_charged").size() >= 1, "the charge actually moved the boss")
	# Save/restore MID-FIGHT (committed shapes in the scheduled queue): the
	# restored sim replays the identical tail to the identical hash.
	var head: CombatSim = _staged_shape_fight(4242)
	_drive_shapes(head, 8)
	var restored: CombatSim = CombatSim.from_dict(head.to_dict())
	assert_eq(restored.state_hash(), head.state_hash(), "roundtrip hash identical mid-fight")
	_drive_shapes(head, 8)
	_drive_shapes(restored, 8)
	assert_eq(head.state_hash(), full_a.state_hash(), "continued head run matches the full run")
	assert_eq(restored.state_hash(), full_a.state_hash(), "snapshot -> restore -> tail = identical hash")
