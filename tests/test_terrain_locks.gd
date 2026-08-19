extends SimTestBase
## KAN-5 remainder K2 — TERRAIN TYPING + DOOR LOCKS (rules-addendum R33): the
## substrate that unblocks quick_step / swim / acrobatics / lockpicking next
## story.
##
## Under test:
##  * the terrain layer: config shape gates (type enum, non-empty hexes, one
##    type per hex) + placement gates (arena_terrain_misplaced), terrain_at /
##    move_cost queries (untyped = "normal" cost 1; typed cost 2 PLACEHOLDER
##    R14), spawning ON terrain — water included — is LEGAL.
##  * terrain-weighted pathing: A* prefers the CHEAP route around a difficult
##    patch (hand-built maps, exact routes pinned, cost arithmetic in the
##    comments); the tie-break contract survives weighted g (equal-cost
##    routes -> the documented dive's pick, pinned + re-run identical); the
##    allowance is a movement BUDGET (an AI walker crosses 1 difficult + 1
##    normal hex on budget 3, pinned through the real sim; budget 1 cannot
##    afford an adjacent cost-2 hex and waits honestly); greedy keeps its
##    legacy distance-only CHOOSER and only BILLS costs; no-terrain arenas
##    ride the unchanged unit-cost walk (the legacy compat pin — the whole
##    pre-K2 suite, test_pathing's exact-route pins included, runs unchanged
##    beside this file).
##  * the water substrate marker: a combatant OCCUPYING water when the Clock
##    resets emits in_water (event-only — NO state, NO timers; suffocation
##    wiring is the swim story's), nothing off-reset, nothing on dry land,
##    nothing in terrain-less fights.
##  * door locks: config gates (tier enum, lock state, locked-implies-closed),
##    the door_locked rejection (slot untouched), a locked door blocks exactly
##    like any closed door, the INTERNAL pick_lock API (adjacency/lock gates,
##    the tier -> Moments table verbatim, magical's special flag, no slot or
##    Moments charged — the honest downscope: scheduling rides the lockpicking
##    skill's resolver action next story), and the picked door opening.
##  * serialization: lock state + terrain rows ride the arena block
##    (hash-covered, tamper-evident, round-trip + lockstep); lockless doors
##    carry NO "lock" key and terrain-less arenas NO "terrain" key (the
##    wave-4b/3d byte-compat pins); views mirror both.
##  * the authored demo data (kennel muck + the corridor supply cage) parses
##    and answers the queries as authored.
##  * determinism: identical command logs (pick_lock calls included) end on
##    identical hashes.


func set_arena(sim: CombatSim, cfg: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": cfg})


func door(sim: CombatSim, actor: String, key: String, to_state: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "door", "actor": actor, "key": key, "set": to_state})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


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


func locked_door(key: String, pos: Array, tier: String = "simple", lock_state: String = "locked") -> Dictionary:
	return {"key": key, "position": pos, "state": "closed",
		"lock": {"tier": tier, "state": lock_state}}


# ------------------------------------------------------------ the terrain layer

func test_terrain_config_shape_and_placement_gates() -> void:
	var sim: CombatSim = make_sim()
	var bounds: Dictionary = {"width": 9, "height": 9}
	# Shape gates (Arena.from_config): unknown type / empty hexes / bad pair /
	# two types on one hex each reject the whole config as invalid.
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"terrain": [{"type": "lava", "hexes": [[1, 0]]}]}),
		"invalid_arena", "an unknown terrain type is an authoring error, never a silent normal")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"terrain": [{"type": "difficult", "hexes": []}]}),
		"invalid_arena", "a terrain row needs a non-empty hexes list")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"terrain": [{"type": "difficult", "hexes": [[1]]}]}),
		"invalid_arena", "a terrain hex must be a pair")
	assert_rejected(set_arena(sim, {"bounds": bounds, "terrain": [
		{"type": "difficult", "hexes": [[1, 0]]},
		{"type": "water", "hexes": [[1, 0]]}]}),
		"invalid_arena", "one type per hex — a double-typed hex rejects")
	# Placement gates (_set_arena): out of bounds / on a wall / on an object.
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"terrain": [{"type": "rough", "hexes": [[99, 99]]}]}),
		"arena_terrain_misplaced", "terrain outside the room")
	assert_rejected(set_arena(sim, {"bounds": bounds, "walls": [[2, 0]],
		"terrain": [{"type": "difficult", "hexes": [[2, 0]]}]}),
		"arena_terrain_misplaced", "typed solid rock is an authoring error")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"objects": [{"key": "trash_can", "position": [2, 0]}],
		"terrain": [{"type": "water", "hexes": [[2, 0]]}]}),
		"arena_terrain_misplaced", "terrain under a can is an authoring error")
	assert_true(sim.arena == null, "every rejection left the sim arena-less")
	# A valid set: queries answer, the arena_set event carries the canonical
	# rows, and a DOORWAY may legally carry terrain (an open door is floor).
	var events: Array[Dictionary] = set_arena(sim, {"bounds": bounds,
		"doors": [{"key": "gate", "position": [3, 0], "state": "open"}],
		"terrain": [
			{"type": "water", "hexes": [[0, 2], [1, 2]]},
			{"type": "difficult", "hexes": [[1, 0], [3, 0]]},
		]})
	var arena_event: Dictionary = assert_event(events, "arena_set", "the opt-in event")
	assert_eq(arena_event.get("terrain", []), [
		{"type": "difficult", "hexes": [[1, 0], [3, 0]]},
		{"type": "water", "hexes": [[0, 2], [1, 2]]},
	], "canonical rows on the event: TERRAIN_TYPES order, hexes sorted")
	assert_eq(sim.arena.terrain_at(Vector2i(1, 0)), "difficult", "typed hex answers its type")
	assert_eq(sim.arena.terrain_at(Vector2i(0, 0)), "normal", "untyped hexes are normal")
	assert_eq(sim.arena.move_cost(Vector2i(1, 0)), 2, "difficult costs 2 (PLACEHOLDER R14)")
	assert_eq(sim.arena.move_cost(Vector2i(0, 2)), 2, "water costs 2 (PLACEHOLDER R14)")
	assert_eq(sim.arena.move_cost(Vector2i(0, 0)), 1, "normal costs 1")
	# Spawning ON terrain is legal — water included (staging never prices
	# movement; nothing ruled forbids a mid-pool spawn — deliberately not
	# invented). Terrain never blocks anything.
	assert_event(add_human(sim, "swimmer", {"team": "party", "position": [0, 2]}),
		"combatant_added", "spawning IN WATER is legal")
	assert_event(add_human(sim, "wader", {"team": "party", "position": [1, 0]}),
		"combatant_added", "spawning on difficult terrain is legal")
	assert_false(sim.arena.blocks_movement(Vector2i(1, 2)),
		"terrain never blocks (water is floor, just expensive floor)")


# ------------------------------------------------- terrain-weighted pathfinding
##
## THE DETOUR MAP (unique optimum — the cheap route around the patch). Axial
## q right, r down-right; bounds q in [-2, 6], r in [-2, 2]; # = wall,
## d = difficult (cost 2), M = walker (0,0), V = victim (4,0), o = the pinned
## optimal route, . = open floor:
##
##   r=-2   .  .  .  .  .  .  .  .  .
##   r=-1    .  .  o  o  o  o  .  .  .     o: (1,-1) (2,-1) (3,-1) (4,-1)
##   r= 0     .  .  M  d  d  d  V  .  .    d: (1,0) (2,0) (3,0)
##   r= 1      .  .  #  #  #  #  .  .  .   #: (0,1) (1,1) (2,1) (3,1)
##   r= 2       .  .  .  .  .  .  .  .  .
##
## Cost arithmetic (stop ring = dist 1 of V): straight through the patch =
## 2+2+2 = 6 ending on (3,0); the south lane is WALLED; the north detour
## (1,-1) (2,-1) (3,-1) (4,-1) = 1+1+1+1 = 4 — the unique minimum (any mixed
## route re-entering the patch pays >= 5). Greedy's distance-only chooser
## walks straight into the patch (E is the only distance-reducing step from
## M) and pays 6 — the contrast A* exists for.

const DETOUR_BOUNDS: Dictionary = {"width": 9, "height": 5, "origin": [-2, -2]}
const DETOUR_WALLS: Array = [[0, 1], [1, 1], [2, 1], [3, 1]]
const DETOUR_TERRAIN: Array = [{"type": "difficult", "hexes": [[1, 0], [2, 0], [3, 0]]}]


func detour_arena() -> Arena:
	return Arena.from_config({"bounds": DETOUR_BOUNDS, "walls": DETOUR_WALLS,
		"terrain": DETOUR_TERRAIN})


func test_astar_prefers_cheap_route_around_difficult_terrain() -> void:
	var arena: Arena = detour_arena()
	var occupied: Dictionary = {Vector2i(4, 0): true}
	# The full optimal route: cost 4 around the patch, exact hexes pinned.
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, arena),
		hexes([[1, -1], [2, -1], [3, -1], [4, -1]]),
		"the cost-4 detour beats the cost-6 straight line, exact hexes")
	# BUDGET truncation (allowance is a budget, all-normal prefix here).
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 3, 1, occupied, arena),
		hexes([[1, -1], [2, -1], [3, -1]]), "budget 3 = the route's first 3 normal steps")
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 2, 1, occupied, arena),
		hexes([[1, -1], [2, -1]]), "budget 2 truncates the same route")
	# Greedy control: the distance-only chooser dives straight into the patch
	# (billing honestly — 3 difficult steps = budget 6), proving the K2 rule
	# that greedy BILLS terrain but never plans around it (A*'s job).
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 6, 1, occupied, arena),
		hexes([[1, 0], [2, 0], [3, 0]]), "greedy pays 6 straight through (the control)")
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 4, 1, occupied, arena),
		hexes([[1, 0], [2, 0]]), "greedy budget 4 affords only two difficult steps")


func test_tie_break_survives_weighted_costs() -> void:
	# THE TIE MAP — the detour map WITHOUT walls: the south lane opens, so two
	# all-normal cost-4 routes exist around the patch (north via (1,-1)..(4,-1),
	# south via (0,1)..(3,1)). Hand-audited dive: from M the frontier holds
	# f=4 entries (1,0) g2 / (1,-1) g1 / (0,1) g1 — deepest-first pops the
	# difficult (1,0) first (a dead end at f=4: its onward g is beaten), then
	# the g-tie between (1,-1) (seq 2) and (0,1) (seq 6) resolves by insertion
	# order to NE, and the dive rides the north lane to the ring. The packed
	# key (f, G_MAX - g, seq) never cared how g accrued — the contract
	# survives weighted g verbatim.
	var arena: Arena = Arena.from_config({"bounds": DETOUR_BOUNDS, "terrain": DETOUR_TERRAIN})
	var occupied: Dictionary = {Vector2i(4, 0): true}
	var route: Array[Vector2i] = Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, arena)
	assert_eq(route, hexes([[1, -1], [2, -1], [3, -1], [4, -1]]),
		"the NE-first dive wins the weighted-cost tie (north route, pinned)")
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, arena), route,
		"re-running the identical query returns the identical route")


func test_terrain_free_gates_and_billing_unchanged() -> void:
	# The legacy compat pins: a terrain-less wall-less rect arena still rides
	# the greedy fast path (the routing gate grew ONLY the terrain clause),
	# and unit costs bill exactly like the pre-K2 step count.
	var plain: Arena = Arena.from_config({"bounds": {"width": 9, "height": 9}})
	var occupied: Dictionary = {Vector2i(4, 0): true}
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 3, 1, occupied, plain),
		Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 3, 1, occupied, plain),
		"no terrain, no walls, rect bounds -> the greedy fast path, unchanged")
	assert_eq(plain.move_cost(Vector2i(1, 0)), 1, "every hex costs 1 without terrain")
	# A terrain-carrying arena routes via A* even wall-less — and on all-normal
	# ground it reproduces greedy exactly (the greedy-compat dive property):
	# the patch sits far off the M->V corridor, so the pinned steps match.
	var far: Arena = Arena.from_config({"bounds": {"width": 21, "height": 21},
		"terrain": [{"type": "rough", "hexes": [[-8, -8]]}]})
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, far),
		hexes([[1, 0], [2, 0], [3, 0]]),
		"terrain flips the gate to A*; an untouched corridor stays the greedy line")
	assert_eq(Pathing.next_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, far),
		Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 10, 1, occupied, far),
		"...and equals greedy_steps hex for hex")


func test_ai_walker_budget_consumes_move_cost() -> void:
	# THE CORRIDOR (1 hex tall — the only route is straight): M mob (0,0),
	# d = difficult (1,0), V victim (4,0). The story's own example pinned: a
	# 3-budget walker crosses 1 difficult + 1 normal hex (2+1=3), NOT 3 hexes.
	#
	#   r=0   .  M  d  .  .  V  .  .  .  .  .    q in [-1, 9]
	#
	var sim: CombatSim = make_sim()
	set_arena(sim, {"bounds": {"width": 11, "height": 1, "origin": [-1, 0]},
		"terrain": [{"type": "difficult", "hexes": [[1, 0]]}]})
	add_human(sim, "vic", {"team": "party", "position": [4, 0]})
	add_mob(sim, "mob", [0, 0])
	var first: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(String(first_event(first, "ai_decision").get("choice", "")), "move",
		"decide 1: out of reach — the mob closes")
	assert_eq(first_event(first, "moved").get("to", []), [2, 0],
		"budget 3 buys the difficult hex (2) + one normal (1) — two hexes, not three")
	advance(sim, 1)
	var second: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(first_event(second, "moved").get("to", []), [3, 0],
		"decide 2: one normal step onto the stop ring")
	assert_eq(String(first_event(second, "ai_decision").get("choice", "")), "attack",
		"...and the bite declares on arrival")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "damage_applied", "the terrain-priced approach really lands")


func test_slowed_walker_cannot_afford_adjacent_difficult_hex() -> void:
	# Budget 1 (slowed) vs an adjacent cost-2 hex: the step is unaffordable —
	# the walker waits honestly (no thrash, no free discount).
	var sim: CombatSim = make_sim()
	set_arena(sim, {"bounds": {"width": 11, "height": 1, "origin": [-1, 0]},
		"terrain": [{"type": "difficult", "hexes": [[3, 0]]}]})
	add_human(sim, "vic", {"team": "party", "position": [4, 0]})
	add_mob(sim, "mob", [2, 0])
	sim.apply_command({"type": "set_status", "target": "mob", "status": "slowed", "value": true})
	var events: Array[Dictionary] = ai_decide(sim, "mob")
	assert_no_event(events, "moved", "budget 1 cannot buy a cost-2 entry")
	assert_ne(String(first_event(events, "ai_decision").get("choice", "")), "attack",
		"and no reach, so no bite either")
	assert_eq((sim.combatants["mob"] as CombatantState).position, Vector2i(2, 0), "never moved")
	# Greedy billing pins (the direct API — the chooser is unchanged, the
	# budget is real): allowance 3 buys d(2)+normal(1); allowance 1 buys nothing.
	var arena: Arena = Arena.from_config({"bounds": {"width": 11, "height": 1, "origin": [-1, 0]},
		"terrain": [{"type": "difficult", "hexes": [[1, 0]]}]})
	var occupied: Dictionary = {Vector2i(4, 0): true}
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 3, 1, occupied, arena),
		hexes([[1, 0], [2, 0]]), "greedy bills 2+1 on budget 3")
	assert_eq(Pathing.greedy_steps(Vector2i(0, 0), Vector2i(4, 0), 1, 1, occupied, arena),
		hexes([]), "greedy budget 1 cannot afford the cost-2 first step")


# ------------------------------------------------------- the water marker

func test_water_occupancy_marker_at_clock_reset() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, {"bounds": {"width": 9, "height": 9},
		"terrain": [{"type": "water", "hexes": [[2, 0], [2, 1]]}]})
	add_human(sim, "swimmer", {"team": "party", "position": [2, 0]})
	add_human(sim, "lander", {"team": "party", "position": [0, 0]})
	# Nothing off-reset: ticks 0..8 complete without a marker.
	var pre_reset: Array[Dictionary] = advance(sim, 9)
	assert_no_event(pre_reset, "in_water", "the marker is a Clock-BOUNDARY sweep, not per-tick")
	# The reset tick: exactly ONE marker — the water occupant, position stamped.
	var reset: Array[Dictionary] = advance(sim, 1)
	assert_event(reset, "clock_reset", "precondition: tick 9 completes the Clock")
	var markers: Array[Dictionary] = events_of(reset, "in_water")
	assert_eq(markers.size(), 1, "one occupant in water = one marker (dry land emits nothing)")
	assert_eq(String((markers[0] as Dictionary).get("combatant", "")), "swimmer", "who")
	assert_eq((markers[0] as Dictionary).get("position", []), [2, 0], "where")
	assert_eq(int((markers[0] as Dictionary).get("tick", -1)), 9, "stamped on the completing tick")
	# The marker is EVENT-ONLY — no state, no timers (the honest boundary:
	# suffocation wiring is the swim story's, condition/resolver scope).
	var swimmer_dict: Dictionary = sim.to_dict()["combatants"]["swimmer"]
	assert_false(swimmer_dict.has("in_water"), "no in_water state serializes")
	assert_false(swimmer_dict.has("submerged"), "no submersion state serializes")
	# Wading OUT before the next reset: no marker for the ex-swimmer.
	move(sim, "swimmer", [4, 0])
	var second_reset: Array[Dictionary] = advance(sim, 10)
	assert_no_event(second_reset, "in_water", "off the water at the reset = no marker")
	# And a terrain-less fight never enters the sweep at all.
	var dry: CombatSim = make_sim()
	set_arena(dry, {"bounds": {"width": 9, "height": 9}})
	add_human(dry, "h", {"team": "party", "position": [0, 0]})
	assert_no_event(advance(dry, 10), "in_water", "no terrain = the legacy no-op")


# ------------------------------------------------------------------ door locks

func test_lock_config_gates() -> void:
	var sim: CombatSim = make_sim()
	var bounds: Dictionary = {"width": 9, "height": 9}
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"doors": [locked_door("d", [2, 0], "rusty")]}),
		"invalid_arena", "a lock tier must be in the ruled enum")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"doors": [locked_door("d", [2, 0], "simple", "ajar")]}),
		"invalid_arena", "a lock state must be locked|unlocked")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"doors": [{"key": "d", "position": [2, 0], "state": "open",
			"lock": {"tier": "simple", "state": "locked"}}]}),
		"invalid_arena", "a locked-OPEN door is a contradiction (open blocks nothing)")
	assert_rejected(set_arena(sim, {"bounds": bounds,
		"doors": [{"key": "d", "position": [2, 0], "state": "closed", "lock": "simple"}]}),
		"invalid_arena", "a lock must be an object")
	# Legal shapes: locked-closed, unlocked-closed, unlocked-open.
	assert_event(set_arena(sim, {"bounds": bounds, "doors": [
		locked_door("a", [2, 0]),
		locked_door("b", [3, 0], "magical", "unlocked"),
		{"key": "c", "position": [4, 0], "state": "open",
			"lock": {"tier": "moderate", "state": "unlocked"}},
	]}), "arena_set", "every legal lock shape stages")
	# The tier table verbatim (PLACEHOLDER R14 — the pick prices next story).
	assert_eq(Arena.LOCK_PICK_MOMENTS, {"simple": 1, "moderate": 2, "complex": 3, "magical": 3},
		"the tier -> Moments-to-pick table, verbatim")


func test_locked_door_blocks_and_rejects_the_door_command() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, {"bounds": {"width": 9, "height": 9}, "doors": [
		locked_door("cage", [1, 0]),
		{"key": "plain", "position": [0, 1], "state": "closed"},
	]})
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	# A locked door IS a closed door: same one-query blocking, no special case.
	assert_rejected(move(sim, "h", [1, 0]), "hex_blocked",
		"a locked door blocks movement exactly like any closed door")
	# The door command cannot open it — door_locked names the tier, and the
	# rejection never wastes the free slot (checked BEFORE the slot).
	var refused: Array[Dictionary] = door(sim, "h", "cage", "open")
	assert_rejected(refused, "door_locked", "a locked door refuses the door command")
	assert_eq(String(first_event(refused, "command_rejected").get("tier", "")), "simple",
		"the rejection names the lock tier")
	assert_false((sim.combatants["h"] as CombatantState).free_action_used,
		"rattling a locked handle never spends the slot")
	# The same-state gate still outranks: asking a locked door to CLOSE reads
	# door_already_closed (a locked door only exists closed).
	assert_rejected(door(sim, "h", "cage", "closed"), "door_already_closed",
		"locked implies closed — the no-op close rejects first")
	# An UNLOCKED lock is inert: the plain closed door still flips normally.
	assert_event(door(sim, "h", "plain", "open"), "door_changed",
		"a lockless door is untouched by the lock machinery")
	# AI wall parity — the EXACT test_doors geometry with the lock added: a
	# locked door reads as a closed door through the one is_wall query, so the
	# mob's pinned walled-off wait is untouched (enemies never open doors in
	# v1 — and could not pick this one anyway).
	var sim2: CombatSim = make_sim()
	set_arena(sim2, {"bounds": {"width": 41, "height": 60},
		"doors": [locked_door("cage", [1, 0])]})
	add_human(sim2, "vic", {"team": "party", "position": [0, 0]})
	add_mob(sim2, "mob", [2, 0])
	var stuck: Dictionary = first_event(ai_decide(sim2, "mob"), "ai_decision")
	assert_eq(String(stuck.get("choice", "")), "wait", "a locked door walls the mob off")
	assert_eq((sim2.combatants["mob"] as CombatantState).position, Vector2i(2, 0), "and never moved")


func test_pick_lock_gates_and_flow() -> void:
	var sim: CombatSim = make_sim()
	assert_rejected(sim.pick_lock("ghost", "cage"), "unknown_actor", "unknown actor")
	set_arena(sim, {"bounds": {"width": 11, "height": 11}, "doors": [
		locked_door("cage", [1, 0]),
		locked_door("vault", [0, 1], "magical"),
		locked_door("far", [4, 0], "moderate"),
		{"key": "plain", "position": [-1, 0], "state": "closed"},
	]})
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	# A no-arena sim has no locks at all.
	var bare: CombatSim = make_sim()
	add_human(bare, "h", {"team": "party", "position": [0, 0]})
	assert_rejected(bare.pick_lock("h", "cage"), "no_arena", "no arena = no locks")
	# Ask gates: unknown door / adjacency / no lock on the door.
	assert_rejected(sim.pick_lock("h", "nope"), "unknown_door", "unknown door key")
	assert_rejected(sim.pick_lock("h", "far"), "door_not_adjacent",
		"distance 4: the picker must be ADJACENT (the door-command gate)")
	assert_rejected(sim.pick_lock("h", "plain"), "no_lock", "a lockless door has nothing to pick")
	# MAGICAL needs the special capability (the L9 rung) — the flag, not the
	# grantor, is the substrate's business.
	assert_rejected(sim.pick_lock("h", "vault"), "magical_lock_needs_special",
		"a magical lock refuses a mundane pick")
	# The pick: lock_picked reports the tier price (nothing is CHARGED here —
	# the lockpicking skill's resolver action schedules and pays next story).
	var picked: Array[Dictionary] = sim.pick_lock("h", "cage")
	var event: Dictionary = assert_event(picked, "lock_picked", "the pick resolution")
	assert_eq(String(event.get("tier", "")), "simple", "which tier")
	assert_eq(int(event.get("moments", 0)), 1, "simple = 1 Moment (the table, reported not charged)")
	assert_eq(event.get("position", []), [1, 0], "where")
	assert_false((sim.combatants["h"] as CombatantState).free_action_used,
		"the INTERNAL API charges nothing — pricing rides the future resolver action")
	# One-way: a second pick finds nothing left to pick.
	assert_rejected(sim.pick_lock("h", "cage"), "lock_already_unlocked", "picking is one-way")
	# The picked door now works like any closed door — open it, walk through,
	# close it again (the lock stays unlocked; no re-lock path exists in v1).
	assert_event(door(sim, "h", "cage", "open"), "door_changed", "the picked door opens")
	advance(sim, 1)
	assert_event(move(sim, "h", [1, 0]), "moved", "and the doorway is floor again")
	# The magical pick with the special flag works.
	var special: Array[Dictionary] = sim.pick_lock("h", "vault", true)
	assert_eq(int(assert_event(special, "lock_picked", "special pick").get("moments", 0)), 3,
		"magical = 3 Moments + the special flag (the table)")


# ------------------------------------------- serialization + determinism

func test_terrain_and_locks_serialize_hash_covered_and_lockstep() -> void:
	var sim: CombatSim = make_sim(99)
	set_arena(sim, {"bounds": {"width": 9, "height": 9},
		"walls": [[3, 3]],
		"doors": [locked_door("cage", [1, 0]), {"key": "plain", "position": [0, 1], "state": "closed"}],
		"terrain": [{"type": "difficult", "hexes": [[2, 0]]}, {"type": "water", "hexes": [[2, 1]]}]})
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	sim.pick_lock("h", "cage")  # a MID-PICK state must serialize
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	var doors: Array = (snapshot["arena"] as Dictionary)["doors"]
	assert_eq(String(((doors[0] as Dictionary).get("lock", {}) as Dictionary).get("state", "")),
		"unlocked", "the PICKED lock state is what serializes")
	assert_false((doors[1] as Dictionary).has("lock"),
		"a lockless door row carries NO lock key (wave-4b byte-compat)")
	assert_eq((snapshot["arena"] as Dictionary).get("terrain", []), [
		{"type": "difficult", "hexes": [[2, 0]]},
		{"type": "water", "hexes": [[2, 1]]},
	], "terrain serializes as the canonical rows")
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical (lock + terrain covered)")
	assert_eq(restored.arena.terrain_at(Vector2i(2, 1)), "water", "terrain restored per hex")
	assert_false(Arena.door_locked(restored.arena.doors[1]), "plain door restored lockless")
	# Hash teeth: a tampered lock state and a tampered terrain type must both
	# change the run hash.
	var tampered: Dictionary = sim.to_dict()
	((((tampered["arena"] as Dictionary)["doors"] as Array)[0] as Dictionary)["lock"] as Dictionary)["state"] = "locked"
	assert_ne(CombatSim.from_dict(tampered).state_hash(), mid_hash,
		"lock state is hash-covered — a silent re-lock cannot hide")
	var tampered2: Dictionary = sim.to_dict()
	(((tampered2["arena"] as Dictionary)["terrain"] as Array)[0] as Dictionary)["type"] = "water"
	assert_ne(CombatSim.from_dict(tampered2).state_hash(), mid_hash,
		"terrain typing is hash-covered — silent re-terraforming cannot hide")
	# Lockstep: identical tails from the restored snapshot (a terrain-priced
	# AI decide included).
	add_mob(sim, "mob", [4, 0])
	restored.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [4, 0]}})
	for s: CombatSim in ([sim, restored] as Array):
		s.apply_command({"type": "ai_decide", "actor": "mob"})
		s.apply_command({"type": "advance_tick"})
		s.apply_command({"type": "door", "actor": "h", "key": "cage", "set": "open"})
		s.apply_command({"type": "advance_tick"})
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")
	# The wave-3d/4b byte-compat pin: a terrain-less, lockless arena serializes
	# with NO terrain key and NO lock keys — pre-K2 saves keep their shape.
	var plain: CombatSim = make_sim()
	set_arena(plain, {"bounds": {"width": 9, "height": 9},
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]})
	var plain_arena: Dictionary = plain.to_dict()["arena"]
	assert_false(plain_arena.has("terrain"), "no terrain authored = no terrain key")
	assert_false(((plain_arena["doors"] as Array)[0] as Dictionary).has("lock"),
		"no lock authored = no lock key")
	assert_false(plain.arena.view().has("terrain"), "view_arena mirrors the terrain pin")
	assert_false(((plain.arena.view()["doors"] as Array)[0] as Dictionary).has("lock"),
		"view_arena mirrors the lock pin")


func test_two_runs_same_log_identical_hashes() -> void:
	# Determinism over the full K2 surface: identical logs (a terrain arena,
	# a locked door, a pick, AI decides across the patch) -> identical hashes.
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(4242)
		set_arena(sim, {"bounds": {"width": 11, "height": 5, "origin": [-1, -2]},
			"doors": [locked_door("cage", [7, 0])],
			"terrain": [{"type": "difficult", "hexes": [[1, 0], [2, 0]]},
				{"type": "water", "hexes": [[1, 1]]}]})
		add_human(sim, "vic", {"team": "party", "position": [4, 0]})
		add_mob(sim, "mob", [0, 0])
		door(sim, "vic", "cage", "open")  # rejected door_not_adjacent — logged all the same
		ai_decide(sim, "mob")
		advance(sim, 1)
		sim.pick_lock("vic", "cage")  # rejected door_not_adjacent — deterministic too
		ai_decide(sim, "mob")
		advance(sim, 10)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "identical (seed, command log) -> identical hash")


# ------------------------------------------------------------ the authored data

func test_authored_demo_terrain_and_lock_parse_and_answer() -> void:
	var run_data: Dictionary = SimTestBase.load_json("res://data/demo_run.json")
	var encounters: Array = (run_data.get("run", {}) as Dictionary).get("encounters", [])
	var kennel: Dictionary = {}
	var corridor: Dictionary = {}
	for enc: Variant in encounters:
		match String((enc as Dictionary).get("key", "")):
			"kennel_gauntlet":
				kennel = enc
			"service_corridor":
				corridor = enc
	# The kennel muck (PROVISIONAL, PLACEHOLDER positions): a difficult row
	# along the south pens, clear of spawns / fence / gate.
	var kennel_arena: Arena = Arena.from_config(kennel.get("arena", {}))
	assert_true(kennel_arena != null, "the kennel arena parses")
	assert_eq(kennel_arena.terrain_at(Vector2i(0, 3)), "difficult", "the muck row is typed")
	assert_eq(kennel_arena.move_cost(Vector2i(0, 3)), 2, "and bills 2 (PLACEHOLDER R14)")
	assert_eq(kennel_arena.terrain_at(Vector2i(0, 0)), "normal", "the fight floor stays normal")
	# The corridor supply cage (PROVISIONAL): the first authored LOCKED door.
	var corridor_arena: Arena = Arena.from_config(corridor.get("arena", {}))
	assert_true(corridor_arena != null, "the corridor arena parses")
	var idx: int = corridor_arena.door_index_for("supply_cage_door")
	assert_true(idx >= 0, "the supply cage door exists")
	assert_true(Arena.door_locked(corridor_arena.doors[idx]), "and it is LOCKED")
	assert_eq(String((corridor_arena.doors[idx].get("lock", {}) as Dictionary).get("tier", "")),
		"simple", "tier simple (the lockpicking skill's first practice target)")
	assert_true(corridor_arena.is_closed_door(Vector2i(5, -2)), "locked implies closed")
