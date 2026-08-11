extends SimTestBase
## KAN-5 wave 4a — real AI pathfinding (simulation/pathing.gd + the
## EnemyAI._step_toward integration), retiring R28's "greedy step strands on
## concave walls" limitation.
##
## Under test:
##  * A* optimality on hand-built wall maps — exact step sequences pinned
##    (each map drawn in ASCII), including multi-decide navigation through
##    the AI and the honest strand-proof control (greedy alone gets nowhere).
##  * the documented tie-break contract — two equal routes -> the fixed-order
##    one, pinned; identical inputs -> identical path.
##  * unreachable goals -> empty route + the AI WAITS honestly (no thrash).
##  * the 4096 node-expansion cap -> the honest greedy fallback, pinned.
##  * open-space equivalence (the byte-compat mandate): with no arena,
##    next_steps == greedy_steps == the verbatim legacy _step_toward loop,
##    property-style over a seeded batch; wall-less arenas ride the same
##    fast path; a walls-arena open corridor reproduces greedy exactly
##    (the deepest-first dive property).
##  * allowance/prone/slowed/occupied honored through the real AI.
##  * pathing is STATELESS — the sim serializes the same keys as wave 3d,
##    and a walls-arena hunt stays hash-deterministic across save/restore.


func arena_from(walls: Array, bounds: Dictionary) -> Arena:
	return Arena.from_config({"bounds": bounds, "walls": walls})


func set_arena(sim: CombatSim, walls: Array, bounds: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": {"bounds": bounds, "walls": walls}})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func add_mob(sim: CombatSim, id: String, pos: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": "roach_dog", "team": "enemies", "position": pos,
	}})


func hexes(pairs: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for pair: Variant in pairs:
		out.append(Vector2i(int((pair as Array)[0]), int((pair as Array)[1])))
	return out


## The verbatim PRE-wave-4a EnemyAI._step_toward inner loop (the legacy greedy
## walker), kept here as the equivalence anchor: final position or null.
func legacy_greedy_final(from: Vector2i, goal: Vector2i, allowance: int, stop_range: int, occupied: Dictionary) -> Variant:
	var pos: Vector2i = from
	for step: int in range(allowance):
		var current_d: int = CombatantState.hex_distance(pos, goal)
		if current_d <= stop_range:
			break
		var best: Variant = null
		var best_d: int = current_d
		for neighbor: Vector2i in EnemyAI.HEX_NEIGHBORS:
			var candidate: Vector2i = pos + neighbor
			if occupied.has(candidate):
				continue
			var d: int = CombatantState.hex_distance(candidate, goal)
			if d < best_d:
				best = candidate
				best_d = d
		if best == null:
			break
		pos = best
	if pos == from:
		return null
	return pos


# ------------------------------------------------------------- the U-trap map
##
## The shared concave map (axial q right, r down-right; bounds q in [-2, 6],
## r in [-3, 3]; # = wall, M = mob (0,0), V = victim (3,0), o = the pinned
## optimal route, . = open floor):
##
##   r=-3   .  .  .  .  .  .  .  .  .
##   r=-2    .  .  .  o  o  o  .  .  .      o: (1,-2) (2,-2) (3,-2)
##   r=-1     .  .  o  #  .  o  .  .  .     o: (0,-1)        (3,-1)
##   r= 0      .  .  M  #  .  V  .  .  .    walls: (1,-1) (1,0)
##   r= 1       .  .  .  #  .  .  .  .  .          (1,1)
##   r= 2        .  .  .  #  .  .  .  .  .         (1,2)
##   r= 3         .  .  .  .  .  .  .  .  .
##
## The q=1 wall column (r -1..2) severs every straight route; the only
## crossings are (1,-2) north and (1,3) south. Optimality arithmetic (stop
## ring = dist 1 of V): the north route costs dist(M,(1,-2)) +
## (dist((1,-2),V) - 1) = 2 + (4 - 1) = 5; the south route costs
## dist(M,(1,3)) + (dist((1,3),V) - 1) = 4 + (3 - 1) = 6 — so 5 is minimal
## and every 5-step route crosses at (1,-2). Every pin below was hand-audited
## against exactly this arithmetic.

const U_WALLS: Array = [[1, -1], [1, 0], [1, 1], [1, 2]]
const U_BOUNDS: Dictionary = {"width": 9, "height": 7, "origin": [-2, -3]}


func test_u_trap_optimal_path_found_and_pinned() -> void:
	var arena: Arena = arena_from(U_WALLS, U_BOUNDS)
	var occupied: Dictionary = {Vector2i(3, 0): true}
	# The full optimal route: 5 steps, crossing north at (1,-2), ending on the
	# stop ring at (3,-1) (dist 1 from V). Exact sequence pinned.
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 10, 1, occupied, arena),
		hexes([[0, -1], [1, -2], [2, -2], [3, -2], [3, -1]]),
		"the 5-step optimal route around the wall column, exact hexes")
	# Allowance truncation: the first 3 steps of the SAME route.
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 3, 1, occupied, arena),
		hexes([[0, -1], [1, -2], [2, -2]]), "allowance 3 = the route's first 3 steps")
	# Replanning from the truncation point finishes the same route.
	assert_eq(Pathing.next_steps(Vector2i(2, -2), Vector2i(3, 0), 3, 1, occupied, arena),
		hexes([[3, -2], [3, -1]]), "the next decide's replan completes the route")
	# Strand-proof control: the legacy greedy walker cannot leave the trap at
	# all (no strictly-improving unblocked neighbor exists at M) — this is
	# exactly the R28 limitation this wave retires.
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(3, 0), 10, 1, occupied, arena),
		hexes([]), "greedy strands in the trap (the retired behavior)")
	# Already inside the stop ring: empty, no busywork.
	assert_eq(Pathing.next_steps(Vector2i(2, 0), Vector2i(3, 0), 3, 1, occupied, arena),
		hexes([]), "inside stop_range -> no steps")


func test_ai_walks_around_u_wall_across_decides() -> void:
	# The same map through the REAL sim: the mob navigates the trap across two
	# decides (allowance 3 per tick) and bites on arrival — the stranded-
	# forever wait of wave 3d is gone.
	var sim: CombatSim = make_sim()
	set_arena(sim, U_WALLS, U_BOUNDS)
	add_human(sim, "vic", {"team": "party", "position": [3, 0]})
	add_mob(sim, "mob", [0, 0])
	var first: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(String(first_event(first, "ai_decision").get("choice", "")), "move",
		"decide 1: still out of reach — the mob closes along the route")
	assert_eq(first_event(first, "moved").get("to", []), [2, -2],
		"decide 1 lands on the route's 3rd hex (allowance 3)")
	advance(sim, 1)
	var second: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(String(first_event(second, "ai_decision").get("choice", "")), "attack",
		"decide 2: the replanned 2 steps reach the stop ring — bite declared")
	assert_eq(first_event(second, "moved").get("to", []), [3, -1],
		"decide 2 finishes the route on (3,-1), adjacent to the victim")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "damage_applied", "the around-the-wall bite really lands")


func test_tie_break_prefers_fixed_order_route() -> void:
	# Two EQUAL 2-step routes around a single wall (M=(0,0), V=(2,0), wall
	# # = (1,0); stop ring dist 1 of V):
	#
	#   r=-1    .  o  o  .        north: (1,-1) (2,-1)  — first step NE (idx 1)
	#   r= 0     M  #  V  .       south: (0,1)  (1,1)   — first step SE (idx 5)
	#   r= 1      .  .  .  .
	#
	# Both cost 2. The documented tie-break (f asc, deepest-first, insertion
	# order asc over fixed-order neighbor generation) dives NE first — the
	# EARLIER HEX_NEIGHBORS entry — so the north route wins. Pinned.
	var arena: Arena = arena_from([[1, 0]], {"width": 7, "height": 7, "origin": [-3, -3]})
	var occupied: Dictionary = {Vector2i(2, 0): true}
	var route: Array[Vector2i] = Pathing.next_steps(Vector2i(0, 0), Vector2i(2, 0), 5, 1, occupied, arena)
	assert_eq(route, hexes([[1, -1], [2, -1]]), "the fixed-order (NE-first) route wins the tie")
	# Identical inputs -> identical path (no hidden state, no dict-order luck).
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(2, 0), 5, 1, occupied, arena), route,
		"re-running the identical query returns the identical route")


func test_unreachable_returns_empty_and_ai_waits() -> void:
	var bounds: Dictionary = {"width": 9, "height": 9, "origin": [-4, -4]}
	var ring: Array = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]
	# Sealed WALKER: all six neighbors walled — no route out.
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 3, 1, {Vector2i(3, 0): true}, arena_from(ring, bounds)),
		hexes([]), "a sealed-in walker has no route")
	# Sealed TARGET: the goal's whole stop ring is walled — proven unreachable
	# by exhausting the bounded component, not by a cap.
	var target_ring: Array = [[4, 0], [4, -1], [3, -1], [2, 0], [2, 1], [3, 1]]
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 3, 1, {Vector2i(3, 0): true}, arena_from(target_ring, bounds)),
		hexes([]), "a sealed-off target has no route either")
	# Through the AI: the sealed-in mob WAITS honestly — no thrash, no drift —
	# and keeps waiting on later ticks (deterministically identical decides).
	var sim: CombatSim = make_sim()
	set_arena(sim, ring, bounds)
	add_human(sim, "vic", {"team": "party", "position": [3, 0]})
	add_mob(sim, "mob", [0, 0])
	for tick: int in range(2):
		var events: Array[Dictionary] = ai_decide(sim, "mob")
		var decision: Dictionary = first_event(events, "ai_decision")
		assert_eq(String(decision.get("choice", "")), "wait", "sealed in: the mob waits (tick %d)" % tick)
		assert_eq(String(decision.get("reason", "")), "no_reachable_action", "the honest wait reason")
		assert_no_event(events, "moved", "no thrash step")
		assert_eq((sim.combatants["mob"] as CombatantState).position, Vector2i(0, 0), "never moved")
		advance(sim, 1)


func test_expansion_cap_falls_back_to_greedy() -> void:
	# The documented never-hangs bound: MAX_EXPANSIONS closed pops, then the
	# honest greedy fallback. A 120x120 room (14400 hexes — far over the cap)
	# with the goal sealed inside a wall ring: A* would need the whole
	# component to prove unreachability, hits the cap first, and returns the
	# legal greedy walk instead (which strides straight at the distant goal).
	assert_eq(Pathing.MAX_EXPANSIONS, 4096, "the documented cap value")
	var arena: Arena = arena_from(
		[[51, 0], [51, -1], [50, -1], [49, 0], [49, 1], [50, 1]],
		{"width": 120, "height": 120, "origin": [-60, -60]})
	var occupied: Dictionary = {Vector2i(50, 0): true}
	var fallback: Array[Vector2i] = Pathing.next_steps(Vector2i(0, 0), Vector2i(50, 0), 3, 1, occupied, arena)
	assert_eq(fallback, hexes([[1, 0], [2, 0], [3, 0]]),
		"cap hit -> the greedy walk's exact steps (straight at the goal)")
	assert_eq(fallback, Pathing.greedy_steps(Vector2i(0, 0), Vector2i(50, 0), 3, 1, occupied, arena),
		"the fallback IS greedy_steps, not a truncated search result")


func test_open_space_equivalence_property() -> void:
	# The byte-compat mandate: with NO arena, next_steps must reproduce the
	# legacy greedy walker exactly — property-style over a seeded batch of
	# from/goal/occupied layouts (fixed seed, deterministic forever), checked
	# against BOTH greedy_steps and the verbatim legacy loop kept above.
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x4A7E51  # fixed — the batch is a constant
	for i: int in range(60):
		var from := Vector2i(rng.randi_range(-15, 15), rng.randi_range(-15, 15))
		var goal := Vector2i(rng.randi_range(-15, 15), rng.randi_range(-15, 15))
		var occupied: Dictionary = {}
		for k: int in range(8):
			occupied[Vector2i(rng.randi_range(-15, 15), rng.randi_range(-15, 15))] = true
		occupied.erase(from)
		var allowance: int = 1 + (i % 3)
		var stop_range: int = i % 3
		var steps: Array[Vector2i] = Pathing.next_steps(from, goal, allowance, stop_range, occupied, null)
		assert_eq(steps, Pathing.greedy_steps(from, goal, allowance, stop_range, occupied, null),
			"open space rides the greedy fast path (case %d)" % i)
		var legacy: Variant = legacy_greedy_final(from, goal, allowance, stop_range, occupied)
		if steps.is_empty():
			assert_true(legacy == null, "no steps == the legacy null (case %d)" % i)
		else:
			assert_eq(steps[steps.size() - 1], legacy,
				"the final hex matches the verbatim legacy walker (case %d)" % i)


func test_wall_less_and_open_corridor_fast_paths() -> void:
	# A wall-less RECT arena rides the greedy fast path (provably optimal
	# there — see the pathing.gd header: rects are hex-convex, so bounds
	# never strand OR divert a greedy walk toward an in-rect goal). Pinned
	# equal from a bounds-edge start: M=(0,-2) on the top edge (r >= -2),
	# goal (-3, 1) — A* is never engaged (walls empty, rect bounds).
	var bounds: Dictionary = {"width": 9, "height": 5, "origin": [-4, -2]}
	var arena: Arena = arena_from([], bounds)
	var occupied: Dictionary = {Vector2i(-3, 1): true}
	var steps: Array[Vector2i] = Pathing.next_steps(Vector2i(0, -2), Vector2i(-3, 1), 3, 1, occupied, arena)
	assert_eq(steps, Pathing.greedy_steps(Vector2i(0, -2), Vector2i(-3, 1), 3, 1, occupied, arena),
		"wall-less rect arena == the exact greedy walk (fast path)")
	# A walls-arena OPEN corridor: the deepest-first dive reproduces greedy
	# exactly where greedy is already optimal (the documented greedy-compat
	# property) — a far-off irrelevant wall flips the gate to A*, the steps
	# stay identical.
	var far: Arena = arena_from([[10, -10]], {"width": 21, "height": 21, "origin": [-10, -10]})
	var corridor: Dictionary = {Vector2i(6, 0): true}
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(6, 0), 10, 1, corridor, far),
		hexes([[1, 0], [2, 0], [3, 0], [4, 0], [5, 0]]),
		"A* in an unobstructed corridor == the greedy straight line, pinned")
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(6, 0), 10, 1, corridor, far),
		Pathing.greedy_steps(Vector2i(0, 0), Vector2i(6, 0), 10, 1, corridor, far),
		"...and equals greedy_steps hex for hex")


func test_concave_hex_bounds_route() -> void:
	# Explicit-hex-set bounds can be CONCAVE without a single wall — the same
	# trap shape walls make, so the routing gate treats "hexes" bounds as
	# pathfinding terrain. The C-shaped floor (only these hexes exist):
	#
	#   r=0    M  x  V      M=(0,0)  V=(2,0)  x=(1,0) NOT in bounds
	#   r=1     o  o        floor: (0,1) (1,1) — the only way around
	#
	var arena: Arena = Arena.from_config({"bounds": {"hexes": [[0, 0], [0, 1], [1, 1], [2, 0]]}})
	var occupied: Dictionary = {Vector2i(2, 0): true}
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(2, 0), 5, 1, occupied, arena),
		hexes([[0, 1], [1, 1]]), "the concave-bounds detour is found")
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(2, 0), 5, 1, occupied, arena),
		hexes([]), "greedy would strand on the missing floor (the control)")


func test_allowance_prone_slowed_occupied_honored() -> void:
	# SLOWED: allowance 1 — exactly the route's first step per decide.
	var sim: CombatSim = make_sim()
	set_arena(sim, U_WALLS, U_BOUNDS)
	add_human(sim, "vic", {"team": "party", "position": [3, 0]})
	add_mob(sim, "mob", [0, 0])
	sim.apply_command({"type": "set_status", "target": "mob", "status": "slowed", "value": true})
	var events: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(first_event(events, "moved").get("to", []), [0, -1],
		"slowed allowance 1: only the route's first hex")
	# PRONE: the crawl is also allowance 1, same route prefix.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, U_WALLS, U_BOUNDS)
	add_human(sim2, "vic", {"team": "party", "position": [3, 0]})
	add_mob(sim2, "mob", [0, 0])
	sim2.apply_command({"type": "set_status", "target": "mob", "status": "prone", "value": true})
	assert_eq(first_event(ai_decide(sim2, "mob"), "moved").get("to", []), [0, -1],
		"prone crawl: one hex along the same route")
	# OCCUPIED: a body on the north crossing (1,-2) blocks it like a wall —
	# the route swings around the SOUTH end of the column (6 steps via the
	# (1,3) crossing; first 3 pinned). Hand-audited: north is severed, south
	# costs dist(M,(1,3)) + dist((1,3),V) - 1 = 4 + 2 = 6.
	var arena: Arena = arena_from(U_WALLS, U_BOUNDS)
	var occupied: Dictionary = {Vector2i(3, 0): true, Vector2i(1, -2): true}
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 10, 1, occupied, arena),
		hexes([[0, 1], [0, 2], [0, 3], [1, 3], [2, 2], [3, 1]]),
		"a body on the crossing reroutes the whole path south, exact hexes")
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(3, 0), 3, 1, occupied, arena),
		hexes([[0, 1], [0, 2], [0, 3]]), "allowance still truncates the rerouted path")


func test_pathing_is_stateless_and_serialization_unchanged() -> void:
	# Pathfinding adds NO sim state: after a walls-arena pathing decide the
	# serialized shape still carries exactly the wave-3d keys (nothing new
	# under "ai", no "pathing" key anywhere), and the whole hunt is
	# hash-deterministic across a mid-hunt save/restore.
	var sim: CombatSim = make_sim(4242)
	set_arena(sim, U_WALLS, U_BOUNDS)
	add_human(sim, "vic", {"team": "party", "position": [3, 0]})
	add_mob(sim, "mob", [0, 0])
	ai_decide(sim, "mob")  # a real pathfound move
	var snapshot: Dictionary = sim.to_dict()
	var ai_keys: Array = (snapshot["ai"] as Dictionary).keys()
	ai_keys.sort()
	assert_eq(ai_keys, ["ai_rng_state", "boss_phase", "death_spins", "explosion_beats", "stances", "summons"],
		"the ai block still serializes exactly the wave-3d keys")
	assert_false(snapshot.has("pathing"), "no pathing key at the top level")
	# Mid-hunt save/restore: the restored sim finishes the hunt identically.
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "mid-hunt hash roundtrips")
	for cmd: Dictionary in [{"type": "advance_tick"}, {"type": "ai_decide", "actor": "mob"}, {"type": "advance_tick"}] as Array[Dictionary]:
		sim.apply_command(cmd)
		restored.apply_command(cmd)
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails, identical hashes")
	assert_eq((restored.combatants["mob"] as CombatantState).position, Vector2i(3, -1),
		"both walkers finished the pathfound route")
