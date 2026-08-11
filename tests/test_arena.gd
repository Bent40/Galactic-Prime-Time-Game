extends SimTestBase
## KAN-5 wave 3d — arenas: bounds, walls, environment objects (trash cans),
## and the last two phase upgrades un-inerted (rules-addendum R28 + R11 #20).
##
## Under test:
##  * the OPT-IN model: set_arena / staging rejection / no-arena = legacy
##    (the compat pin: a no-arena sim serializes with NO "arena" key — the
##    same top-level shape as the pre-arena engine; the CI harnesses stage no
##    arena and byte-diff clean against their pre-change output).
##  * movement honesty: bounds+walls (and can hexes) block every position-
##    changing path — free move, AI step, dash lane end, sidestep,
##    knock-aside, fling, tactical roll, summon placement, feint reposition,
##    grab drag — each pinned.
##  * dash wall bounces (phase 3 "dash bounces between walls up to 2
##    bounces"): the edge-mirror reflection model (Arena.bounced_lane —
##    hand-verified single/double/head-on lanes vs the ASCII example in
##    simulation/arena.gd), range cap across segments, the AI bank-shot
##    search, all lane rules on reflected segments, bounce+bend composition,
##    the phase gate, and the no-arena inert continuation.
##  * trash cans (phase 3 "flamethrower pops trash cans instantly"):
##    accumulate-to-5 explosion (radius 3 / burn 2 / environment attribution
##    pinned), the instant pop, can-blocks-hex, dash-through smash (no
##    bounce), cascade, mid-accumulation serialization.
##  * determinism + serialization round-trips throughout.

const WIDE_BOUNDS: Dictionary = {"width": 41, "height": 60}


func arena_cfg(walls: Array = [], objects: Array = [], bounds: Dictionary = WIDE_BOUNDS) -> Dictionary:
	return {"bounds": bounds, "walls": walls, "objects": objects}


func set_arena(sim: CombatSim, cfg: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": cfg})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


## The seeded Incinedile trait block minus the dodge threshold (the
## test_incinedile pattern — staging hits stay pin-exact without rng).
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


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


## A dash-only synthetic boss (the inert-test phase-override pattern): no
## cone, no grab, no valve — the lane mechanics under test stay isolated.
func add_dash_boss(sim: CombatSim, upgrades: Array, pos: Array = [0, 0]) -> Array[Dictionary]:
	return add_boss(sim, "boss", {
		"position": pos,
		"boss_traits": traits_without_dodge(),
		"phases": [{
			"phase_number": 1, "name": "Synthetic",
			"behavior": {"abilities": ["dash"], "upgrades": upgrades},
		}],
	})


func boss_state(sim: CombatSim, id: String = "boss") -> CombatantState:
	return sim.combatants.get(id)


## The boss's pending scheduled action's area_shape (read-only Clock probe).
func _scheduled_shape(sim: CombatSim) -> Dictionary:
	for entry: Dictionary in sim.clock.scheduled_entries():
		if String(entry.get("actor", "")) == "boss":
			return (entry["action"] as Dictionary).get("area_shape", {})
	return {}


func lane_pairs(shape: Dictionary) -> Array:
	return shape.get("lane", [])


# ------------------------------------------------- the reflection model (authority)

func test_reflection_model_hand_verified_lanes() -> void:
	# Single bounce, angled (the arena.gd ASCII example): the (1,1)-diagonal
	# ray (steps E, SE, ...) hits wall (2,1) via an E step and mirrors across
	# the N-S edge (cube x<->y swap) into the W/SW diagonal.
	var arena: Arena = Arena.from_config(arena_cfg([[2, 1]]))
	var single: Dictionary = arena.bounced_lane(Vector2i(0, 0), Vector2i(3, 3), 6, 2)
	assert_eq(single["lane"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-2, 2), Vector2i(-3, 3)],
		"single-bounce lane matches the ASCII example exactly")
	assert_eq(single["bounces"], [Vector2i(1, 1)], "one bounce, at the pre-wall hex")
	# Double bounce: a second wall on the outgoing corridor reflects again
	# (SW step into (-3,3): swap the SW axes -> the NNE direction).
	var arena_b: Arena = Arena.from_config(arena_cfg([[2, 1], [-3, 3]]))
	var double: Dictionary = arena_b.bounced_lane(Vector2i(0, 0), Vector2i(3, 3), 6, 2)
	assert_eq(double["lane"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
		Vector2i(0, 1), Vector2i(-1, 2), Vector2i(-2, 2), Vector2i(-2, 1)],
		"double-bounce lane hand-verified")
	assert_eq(double["bounces"], [Vector2i(1, 1), Vector2i(-2, 2)], "both bounce points recorded")
	# Head-on: v parallel to the blocked step reflects straight back — the
	# ricochet legally RETRACES (revisits are allowed on bounced lanes).
	var arena_c: Arena = Arena.from_config(arena_cfg([[2, 0]]))
	var headon: Dictionary = arena_c.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 4, 2)
	assert_eq(headon["lane"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 0),
		Vector2i(-1, 0), Vector2i(-2, 0)], "head-on bounce retraces the incoming lane")
	assert_eq(headon["bounces"], [Vector2i(1, 0)], "bounced at the pre-wall hex")
	# Budget 0 (no upgrade): the lane ENDS at the wall — today's rule.
	var flat: Dictionary = arena_c.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 4, 0)
	assert_eq(flat["lane"], [Vector2i(0, 0), Vector2i(1, 0)], "budget 0: lane truncates before the wall")
	assert_eq((flat["bounces"] as Array).size(), 0, "and records no bounce")
	# Range cap ACROSS segments: reach 4 stops the single-bounce lane 4 steps in.
	var capped: Dictionary = arena.bounced_lane(Vector2i(0, 0), Vector2i(3, 3), 4, 2)
	assert_eq((capped["lane"] as Array).size(), 5, "reach 4 = origin + 4 hexes across both segments")
	assert_eq((capped["lane"] as Array).back(), Vector2i(-1, 2), "cut mid-reflected-segment")
	# A THIRD wall past the 2-bounce budget ends the lane at the last free hex.
	var arena_d: Arena = Arena.from_config(arena_cfg([[2, 1], [-3, 3], [-2, 1]]))
	var ended: Dictionary = arena_d.bounced_lane(Vector2i(0, 0), Vector2i(3, 3), 6, 2)
	assert_eq((ended["lane"] as Array).back(), Vector2i(-2, 2), "third wall: the lane ends, no third bounce")
	assert_eq((ended["bounces"] as Array).size(), 2, "the authored cap holds")
	# Out-of-bounds edges reflect/end exactly like walls.
	var room: Arena = Arena.from_config({"bounds": {"width": 3, "height": 3, "origin": [0, 0]}})
	var oob: Dictionary = room.bounced_lane(Vector2i(0, 0), Vector2i(5, 0), 6, 0)
	assert_eq(oob["lane"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		"budget 0: the bounds end the lane like a wall")


# ------------------------------------------------- opt-in staging + rejection

func test_set_arena_validation_and_staging_rejections() -> void:
	var sim: CombatSim = make_sim()
	# Invalid config / bad placements reject and mutate nothing.
	assert_rejected(set_arena(sim, {}), "invalid_arena", "no bounds = no arena")
	assert_rejected(set_arena(sim, {"bounds": {"width": 0, "height": 5}}), "invalid_arena", "degenerate rect")
	assert_rejected(set_arena(sim, arena_cfg([[99, 99]])), "arena_wall_out_of_bounds", "wall outside the room")
	assert_rejected(set_arena(sim, arena_cfg([[2, 0]], [{"key": "trash_can", "position": [2, 0]}])),
		"arena_object_misplaced", "a can on a wall")
	assert_rejected(set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [99, 99]}])),
		"arena_object_misplaced", "a can outside the room")
	assert_true(sim.arena == null, "every rejection left the sim arena-less")
	# A combatant already standing outside the proposed room blocks the set.
	add_human(sim, "out", {"team": "party", "position": [30, 0]})
	assert_rejected(set_arena(sim, arena_cfg()), "combatant_outside_arena",
		"an already-staged combatant outside the bounds rejects the arena")
	# A valid set emits the arena_set summary; a second set rejects.
	var sim2: CombatSim = make_sim()
	var events: Array[Dictionary] = set_arena(sim2, arena_cfg([[3, 0]], [{"key": "trash_can", "position": [4, 0]}]))
	var arena_event: Dictionary = assert_event(events, "arena_set", "the opt-in event")
	assert_eq(int((arena_event.get("bounds", {}) as Dictionary).get("width", 0)), 41, "bounds echoed")
	assert_eq(arena_event.get("walls", []), [[3, 0]], "walls echoed (sorted)")
	assert_eq((arena_event.get("objects", []) as Array).size(), 1, "objects echoed (the spawn record)")
	assert_rejected(set_arena(sim2, arena_cfg()), "arena_already_set", "one arena per combat")
	# Staging honesty: spawns must land on legal ground.
	assert_rejected(add_human(sim2, "oob", {"position": [30, 0]}), "staging_out_of_bounds",
		"a spawn outside the bounds rejects")
	assert_rejected(add_human(sim2, "walled", {"position": [3, 0]}), "staging_blocked_hex",
		"a spawn on a wall rejects")
	assert_rejected(add_human(sim2, "canned", {"position": [4, 0]}), "staging_blocked_hex",
		"a spawn on a trash can rejects")
	assert_event(add_human(sim2, "ok", {"position": [1, 0]}), "combatant_added", "legal ground stages fine")


func test_no_arena_serializes_with_the_legacy_shape() -> void:
	# The compat pin: a no-arena sim's to_dict carries NO "arena" key — the
	# exact pre-arena top-level shape, so its canonical serialization (and
	# state_hash) is byte-identical to the pre-change engine. The CI harnesses
	# stage no arena and byte-diff clean on the same principle.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	sim.ai.boss_phase["boss"] = 3  # both arena-gated upgrades ACTIVE — and inert
	ai_decide(sim, "boss")
	advance(sim, 2)
	var keys: Array = sim.to_dict().keys()
	keys.sort()
	assert_eq(keys, ["ai", "clock", "combatants", "evidence", "hype", "rng_seed",
		"rng_state", "static_data", "tags", "tick_snapshot"],
		"no-arena to_dict = the exact legacy key set (no 'arena')")
	# And an arena-carrying sim declares itself.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, arena_cfg())
	assert_true(sim2.to_dict().has("arena"), "an opted-in arena serializes under 'arena'")


func test_arena_state_roundtrips_and_replays_in_lockstep() -> void:
	var sim: CombatSim = make_sim(77)
	set_arena(sim, arena_cfg([[3, 0]], [{"key": "trash_can", "position": [2, 0], "burn": 2}]))
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical (arena covered)")
	assert_true(restored.arena != null, "the arena itself restored")
	assert_eq(restored.arena.objects[0].get("burn", -1), 2, "mid-accumulation burn preserved")
	assert_true(restored.ai.arena == restored.arena, "EnemyAI re-wired to the restored arena")
	assert_true(restored.resolver.arena == restored.arena, "resolver re-wired too")
	# Lockstep: both sims run the same tail commands to the same hash.
	for cmd: Dictionary in [{"type": "ai_decide", "actor": "boss"}, {"type": "advance_tick"}] as Array[Dictionary]:
		sim.apply_command(cmd)
		restored.apply_command(cmd)
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")


# ------------------------------------------------- movement honesty (each path pinned)

func test_free_move_rejects_bounds_walls_and_cans() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[1, 0]], [{"key": "trash_can", "position": [0, 1]}],
		{"width": 5, "height": 5, "origin": [-2, -2]}))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	assert_rejected(move(sim, "h", [3, 0]), "out_of_bounds", "a move outside the room rejects")
	assert_rejected(move(sim, "h", [1, 0]), "hex_blocked", "a move onto a wall rejects")
	assert_rejected(move(sim, "h", [0, 1]), "hex_blocked", "a move onto a trash can rejects")
	assert_event(move(sim, "h", [1, -1]), "moved", "legal ground still moves freely")


func test_ai_step_routes_around_walls() -> void:
	# A SLOWED mob (allowance 1) at (2,1) hunting (0,0): the greedy step's
	# first fixed-order improving candidate is NW (2,0) — walled, so the one
	# visible step lands on the next improving candidate W (1,1) instead. The
	# wall observably diverted the step (without it the mob stands on (2,0)).
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[2, 0]]))
	add_human(sim, "vic", {"team": "party", "position": [0, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [2, 1],
	}})
	sim.apply_command({"type": "set_status", "target": "mob", "status": "slowed", "value": true})
	var events: Array[Dictionary] = ai_decide(sim, "mob")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "move", "one slowed step cannot reach yet")
	assert_eq((sim.combatants["mob"] as CombatantState).position, Vector2i(1, 1),
		"the step DETOURS around the wall (the unwalled pick would be (2,0))")
	# A mob with no legal improving step just waits — it cannot phase through.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, arena_cfg([[1, 0]]))
	add_human(sim2, "vic", {"team": "party", "position": [0, 0]})
	sim2.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [2, 0],
	}})
	var stuck: Dictionary = first_event(ai_decide(sim2, "mob"), "ai_decision")
	assert_eq(String(stuck.get("choice", "")), "wait", "walled off: the mob waits")
	assert_eq((sim2.combatants["mob"] as CombatantState).position, Vector2i(2, 0), "and never moved")


func test_sidestep_respects_walls_and_negates_without_displacement() -> void:
	# Straight E dash at a Reflexes-7 dodger on (3,0). Its fixed-order
	# neighbors: (4,0)/(2,0) on-lane, (4,-1) walled -> the sidestep lands on
	# the next legal candidate (3,-1).
	var dash: Dictionary = {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
		"targets": [{"id": "vic", "part": "torso"}],
		"dodge": {"threshold": 7, "counter_at": 9},
		"area_shape": {"kind": "line",
			"lane": [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]},
	}
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[4, -1]]))
	add_human(sim, "vic", {"team": "party", "position": [3, 0], "traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_dash_boss(sim, [])
	declare(sim, "boss", dash)
	advance(sim, 2)
	var dodged: Array[Dictionary] = advance(sim, 1)
	assert_event(dodged, "attack_dodged", "Reflexes 7 auto-dodges")
	var side: Dictionary = assert_event(dodged, "dash_sidestepped", "the sidestep rides it")
	assert_eq(side.get("to", []), [3, -1], "the walled candidate was skipped")
	# Every candidate walled/on-lane: the dodge still negates, no displacement.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, arena_cfg([[4, -1], [3, -1], [2, 1], [3, 1]]))
	add_human(sim2, "vic", {"team": "party", "position": [3, 0], "traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_dash_boss(sim2, [])
	declare(sim2, "boss", dash)
	advance(sim2, 2)
	var pinned: Array[Dictionary] = advance(sim2, 1)
	assert_event(pinned, "attack_dodged", "the dodge still negates")
	assert_no_event(pinned, "dash_sidestepped", "but there is nowhere legal to step")
	assert_no_event(pinned, "damage_applied", "negated = no hit")
	assert_eq((sim2.combatants["vic"] as CombatantState).position, Vector2i(3, 0), "the dodger holds the hex")


func test_knock_aside_blocked_by_walls_still_lands_prone() -> void:
	var dash: Dictionary = {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
		"targets": [{"id": "vic", "part": "torso"}],
		"dodge": {"threshold": 7, "counter_at": 9}, "knock_aside": true,
		"area_shape": {"kind": "line",
			"lane": [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0], [5, 0], [6, 0]]},
	}
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[4, -1], [3, -1], [2, 1], [3, 1]]))
	add_human(sim, "vic", {"team": "party", "position": [3, 0], "traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_dash_boss(sim, [])
	declare(sim, "boss", dash)
	advance(sim, 2)
	var events: Array[Dictionary] = advance(sim, 1)
	assert_event(events, "damage_applied", "Reflexes 2 cannot dodge — the charge connects")
	var knocked: Dictionary = assert_event(events, "knocked_aside", "the shove still happens")
	assert_false(bool(knocked.get("displaced", true)), "every off-lane hex walled: no displacement")
	assert_eq((sim.combatants["vic"] as CombatantState).position, Vector2i(3, 0), "the target stays")
	assert_true(bool((sim.combatants["vic"] as CombatantState).statuses.get("prone", false)),
		"but is STILL knocked prone (the documented blocked-shove rule)")


func test_fling_stops_short_at_a_wall() -> void:
	# The real 3-beat death spin: the spin lane runs E through the victim; a
	# wall one hex down it shortens the flight — the victim drops on the last
	# free hex instead of flying the authored 3.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[3, 0]]))
	add_human(sim, "vic", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	ai_decide(sim, "boss")
	advance(sim, 1)  # grab
	ai_decide(sim, "boss")
	advance(sim, 1)  # chew
	ai_decide(sim, "boss")
	var events: Array[Dictionary] = advance(sim, 1)  # spin
	var kill: Dictionary = assert_event(events, "death_spin_kill", "the spin closes")
	assert_eq(kill.get("flung_to", []), [2, 0], "the wall stops the fling short")
	assert_eq(int(kill.get("hexes_flung", -1)), 1, "one hex instead of the authored 3")


func test_tactical_roll_rejects_blocked_destinations() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[1, 0]], [{"key": "trash_can", "position": [0, 1]}],
		{"width": 3, "height": 3, "origin": [-1, -1]}))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	assert_rejected(declare(sim, "h", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [2, 0]}),
		"out_of_bounds", "a roll outside the room rejects")
	assert_rejected(declare(sim, "h", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, 0]}),
		"hex_blocked", "a roll onto a wall rejects")
	assert_rejected(declare(sim, "h", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [0, 1]}),
		"hex_blocked", "a roll onto a can rejects")
	assert_event(declare(sim, "h", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, -1]}),
		"tactical_roll", "legal ground still rolls")


func test_summon_placement_skips_blocked_hexes() -> void:
	# The elite's brood spawns on the nearest FREE LEGAL hexes: ring-1 scan
	# order is (-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0) — walling the first
	# and third pushes the four spawns onto the remaining legal ones.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[-1, 0], [0, -1]]))
	add_human(sim, "far", {"team": "party", "position": [8, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "elite", "name": "elite", "enemy": "little_brother_roach",
		"team": "enemies", "position": [0, 0],
	}})
	var events: Array[Dictionary] = ai_decide(sim, "elite")
	var summoned: Dictionary = assert_event(events, "enemies_summoned", "the elite wakes the eggs")
	assert_eq(int(summoned.get("count", 0)), 4, "all four spawn")
	var got: Array = []
	for id: Variant in summoned.get("ids", []) as Array:
		var brood: CombatantState = sim.combatants.get(String(id))
		got.append([brood.position.x, brood.position.y])
	assert_eq(got, [[-1, 1], [0, 1], [1, -1], [1, 0]],
		"spawns skip the walled ring hexes, in the deterministic scan order")


func test_feint_reposition_blocked_by_wall_holds_position() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[0, 1]]))
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	add_human(sim, "foe", {"team": "enemies", "position": [1, 0]})
	declare(sim, "h", {"kind": "skill", "key": "feint", "level": 1,
		"targets": [{"id": "foe", "part": "torso"}], "reposition_to": [0, 1]})
	advance(sim, 1)
	assert_eq((sim.combatants["h"] as CombatantState).position, Vector2i(0, 0),
		"a reposition into a wall is no reposition — the actor holds position")


func test_grab_drag_blocked_by_a_wall_on_the_pull_hex() -> void:
	# Phase-3 range-2 grab: the drag destination (the boss-adjacent line hex)
	# is WALLED — the AI never decides the grab, a hand-built one rejects.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[1, 0]]))
	add_human(sim, "vic", {"team": "party", "position": [2, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	sim.ai.boss_phase["boss"] = 3
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_ne(String(decision.get("choice", "")), "grab", "the AI never grabs through a walled pull hex")
	assert_rejected(declare(sim, "boss", {
		"kind": "grapple", "target": "vic", "cost": 1,
		"death_spin": true, "grab_part": "right_hand",
	}), "pull_blocked", "the hand-built range-2 grab rejects on the walled drag hex")


# ------------------------------------------------- dash wall bounces (phase 3)

func test_real_boss_phase_gate_no_bounces_below_three() -> void:
	# The real Incinedile, victim reachable ONLY by carom (walls kill both
	# the straight lane and every improving step). Phase 1: no bounce — the
	# boss can only wait. Phase 3: the authored upgrade banks the dash off
	# the wall and the charge lands.
	var stage: Callable = func(phase: int) -> CombatSim:
		var s: CombatSim = make_sim()
		set_arena(s, arena_cfg([[-1, 1], [2, 1]]))
		add_human(s, "vic", {"team": "party", "position": [-3, 3],
			"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
		add_boss(s, "boss", {"boss_traits": traits_without_dodge()})
		s.ai.boss_phase["boss"] = phase
		return s
	var low: CombatSim = stage.call(1)
	var low_decision: Dictionary = first_event(ai_decide(low, "boss"), "ai_decision")
	assert_eq(String(low_decision.get("choice", "")), "wait",
		"phase 1: no lane through the wall, no bounce, no step — the boss waits")
	var sim: CombatSim = stage.call(3)
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "phase 3: the bank shot reaches")
	assert_eq(String(decision.get("ability", "")), "dash", "as a dash")
	var shape: Dictionary = _scheduled_shape(sim)
	assert_eq(lane_pairs(shape), [[0, 0], [1, 0], [1, 1], [0, 1], [-1, 2], [-2, 2], [-3, 3]],
		"the committed lane IS the hand-verified single-bounce lane (ASCII model)")
	assert_eq(shape.get("bounces", []), [[1, 1]], "the bounce point rides the shape")
	# Determinism: the same staging picks the same lane.
	var twin: CombatSim = stage.call(3)
	ai_decide(twin, "boss")
	assert_eq(_scheduled_shape(twin), shape, "same staging, same committed lane")
	# The charge genuinely runs the reflected corridor.
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(resolved, "dash_charged", "the ricochet charge runs")
	assert_eq(charged.get("bounces", []), [[1, 1]], "the charge event surfaces the bounce")
	assert_eq(boss_state(sim).position, Vector2i(-2, 2), "the boss stops adjacent-before the target")
	assert_event(resolved, "damage_applied", "and the strike lands (Reflexes 2 cannot dodge)")
	var knocked: Dictionary = assert_event(resolved, "knocked_aside", "the dash's knock-aside still rides")
	assert_eq(knocked.get("to", []), [-2, 3], "shoved off the reflected lane")


func test_ai_double_bounce_bank_shot() -> void:
	# Synthetic dash-only boss; the target sits at the end of the
	# hand-verified DOUBLE-bounce corridor; a third wall kills the direct ray.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[2, 1], [-3, 3], [-1, 0]]))
	add_human(sim, "vic", {"team": "party", "position": [-2, 1],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces"])
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "the double bank reaches")
	var shape: Dictionary = _scheduled_shape(sim)
	assert_eq(lane_pairs(shape), [[0, 0], [1, 0], [1, 1], [0, 1], [-1, 2], [-2, 2], [-2, 1]],
		"the committed lane IS the hand-verified double-bounce lane")
	assert_eq(shape.get("bounces", []), [[1, 1], [-2, 2]], "both bounce points ride the shape")
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "dash_charged", "the double ricochet runs")
	assert_eq(boss_state(sim).position, Vector2i(-2, 2), "adjacent-before along the lane order")
	assert_event(resolved, "damage_applied", "and connects")


func test_bounced_lane_rules_left_lane_and_occupation_stop() -> void:
	# Leaving the bounced corridor mid-windup dodges the charge (left_lane).
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[-1, 1], [2, 1]]))
	add_human(sim, "vic", {"team": "party", "position": [-3, 3]})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces"])
	ai_decide(sim, "boss")
	advance(sim, 1)
	assert_event(move(sim, "vic", [-4, 3]), "moved", "the target steps off the corridor")
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated", "the windup collapses")
	assert_eq(String(invalidated.get("reason", "")), "left_lane", "the standard lane re-check, bounced or not")
	assert_no_event(resolved, "dash_charged", "no charge down an abandoned corridor")
	# A body arriving on the REFLECTED segment stops the charge short.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, arena_cfg([[-1, 1], [2, 1]]))
	add_human(sim2, "vic", {"team": "party", "position": [-3, 3]})
	sim2.apply_command({"type": "add_combatant", "combatant": {
		"id": "runner", "name": "runner", "enemy": "roach_dog",
		"team": "enemies", "position": [0, 3],
	}})
	add_dash_boss(sim2, ["dash bounces between walls up to 2 bounces"])
	ai_decide(sim2, "boss")
	advance(sim2, 1)
	assert_event(move(sim2, "runner", [-1, 2]), "moved", "a body steps onto the reflected segment")
	advance(sim2, 1)
	var stopped: Array[Dictionary] = advance(sim2, 1)
	assert_event(stopped, "dash_stopped_short", "the occupation stop applies past the bounce")
	assert_no_event(stopped, "damage_applied", "out of reach = honest miss")
	assert_eq(boss_state(sim2).position, Vector2i(0, 1), "stopped before the body, mid-reflected-segment")


func test_sidestep_leaves_the_reflected_lane() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[-1, 1], [2, 1]]))
	add_human(sim, "vic", {"team": "party", "position": [-3, 3],
		"traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces"])
	ai_decide(sim, "boss")
	advance(sim, 2)
	var events: Array[Dictionary] = advance(sim, 1)
	assert_event(events, "attack_dodged", "Reflexes 7 auto-dodges the ricochet")
	var side: Dictionary = assert_event(events, "dash_sidestepped", "and sidesteps")
	assert_eq(side.get("to", []), [-2, 3],
		"off the FULL bounced lane (bounces never split the exclusion — only a chosen bend does)")
	assert_no_event(events, "damage_applied", "nothing lands")


func test_hand_built_bounce_gates() -> void:
	var lane: Array = [[0, 0], [1, 0], [1, 1], [0, 1], [-1, 2]]
	var bounce_dash: Callable = func(bounces: Array) -> Dictionary:
		return {
			"kind": "attack", "key": "dash", "cost": 2,
			"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
			"targets": [{"id": "vic", "part": "torso"}],
			"area_shape": {"kind": "line", "lane": lane, "bounces": bounces},
		}
	# No arena: bounce markers are meaningless — the inert-pin continuation.
	var bare: CombatSim = make_sim()
	add_human(bare, "vic", {"team": "party", "position": [-1, 2]})
	add_dash_boss(bare, ["dash bounces between walls up to 2 bounces"])
	assert_rejected(declare(bare, "boss", bounce_dash.call([[1, 1]])), "bounce_not_available",
		"no arena = no walls = no bounces, even with the upgrade authored")
	# Arena but no upgrade: same gate.
	var plain: CombatSim = make_sim()
	set_arena(plain, arena_cfg([[2, 1]]))
	add_human(plain, "vic", {"team": "party", "position": [-1, 2]})
	add_dash_boss(plain, [])
	assert_rejected(declare(plain, "boss", bounce_dash.call([[1, 1]])), "bounce_not_available",
		"below the phase-3 upgrade the ricochet does not exist")
	# Upgrade + arena: the marker cap and the wall-free-lane rule hold.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[2, 1]]))
	add_human(sim, "vic", {"team": "party", "position": [-1, 2]})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces"])
	assert_rejected(declare(sim, "boss", bounce_dash.call([[1, 1], [0, 1], [-1, 2]])), "too_many_bounces",
		"the authored cap is 2")
	var walled: Dictionary = bounce_dash.call([[1, 1]])
	walled["area_shape"] = {"kind": "line", "lane": [[0, 0], [1, 0], [2, 1]], "bounces": [[1, 0]]}
	walled["targets"] = [{"id": "vic", "part": "torso"}]
	assert_rejected(declare(sim, "boss", walled), "lane_blocked",
		"a committed lane never contains a wall hex (bounces reflect BEFORE it)")
	assert_event(declare(sim, "boss", bounce_dash.call([[1, 1]])), "action_declared",
		"the legal single-bounce lane declares")


func test_bounce_and_bend_compose_on_one_lane() -> void:
	# A hand-built lane carrying BOTH markers: chosen bend at (2,0) (turn SE),
	# then a head-on bounce off the wall at (2,2) (retrace NW). Segment cap is
	# honest: 1 bend + <= 2 bounces. Requires BOTH upgrades.
	var lane: Array = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 0], [2, -1]]
	var composed: Dictionary = {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
		"targets": [{"id": "vic", "part": "torso"}],
		"area_shape": {"kind": "line", "lane": lane, "bend": [2, 0], "bounces": [[2, 1]]},
	}
	var no_bend: CombatSim = make_sim()
	set_arena(no_bend, arena_cfg([[2, 2]]))
	add_human(no_bend, "vic", {"team": "party", "position": [2, -1]})
	add_dash_boss(no_bend, ["dash bounces between walls up to 2 bounces"])
	assert_rejected(declare(no_bend, "boss", composed), "bend_not_available",
		"the bend half still needs its own (phase-4) upgrade")
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([[2, 2]]))
	add_human(sim, "vic", {"team": "party", "position": [2, -1],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces", "dash can change direction mid-run"])
	assert_event(declare(sim, "boss", composed), "action_declared", "bend + bounce compose")
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(resolved, "dash_charged", "the composite charge runs")
	assert_eq(charged.get("bend", []), [2, 0], "the bend rides the event")
	assert_eq(charged.get("bounces", []), [[2, 1]], "so does the bounce")
	assert_eq(boss_state(sim).position, Vector2i(2, 0),
		"the walk honors the revisit (the retrace ends adjacent-before the target)")
	assert_event(resolved, "damage_applied", "and the strike lands")


# ------------------------------------------------- trash cans (phase 3)

func cone_sweep(target_id: String = "vic") -> Dictionary:
	return {
		"kind": "attack", "key": "flamethrower", "cost": 1,
		"damage": {"type": "burn", "amount": 1}, "attack_range": 10,
		"targets": [{"id": target_id, "part": "torso"}],
		"area_shape": {"kind": "cone", "toward": [1, 0], "size": 10},
	}


func test_can_accumulates_to_five_then_explodes() -> void:
	# Five burn-1 sweeps over the can at (3,0). The 5th detonates it: blast
	# radius 3, burn 2 through the NORMAL damage path with NO attacker —
	# environment damage (no killer, no grudge). The tanky target (phys 8,
	# robustness 4) shrugs both flame and blast; the 1-HP roach witness dies
	# with killer "" (the takedown-v2 unauthored-death pin); the fire-healing
	# boss is HEALED by its own arena's exploding prop.
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [3, 0]}]))
	add_human(sim, "vic", {"team": "party", "position": [1, 0],
		"traits": {"physique": 8, "reflexes": 2, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "witness", "name": "witness", "enemy": "roach_dog",
		"team": "enemies", "position": [5, 0],
	}})
	add_boss(sim, "boss")  # full real traits — the undodgable blast must consume ZERO rng
	for i: int in range(4):
		declare(sim, "boss", cone_sweep())
		var burned: Array[Dictionary] = advance(sim, 1)
		var touch: Dictionary = assert_event(burned, "trash_can_burned", "sweep %d touches the can" % (i + 1))
		assert_eq(int(touch.get("burn", -1)), i + 1, "burn accumulates 1 per sweep")
		assert_no_event(burned, "trash_can_exploded", "below 5 nothing pops")
	var rng_before: int = sim.ai.ai_rng.state
	declare(sim, "boss", cone_sweep())
	var events: Array[Dictionary] = advance(sim, 1)
	var boom: Dictionary = assert_event(events, "trash_can_exploded", "burn 5: the can explodes")
	assert_eq(boom.get("position", []), [3, 0], "at its hex")
	assert_eq(int(boom.get("radius", 0)), 3, "canon radius 3")
	assert_eq(int(boom.get("damage", 0)), 2, "canon burn 2")
	assert_false(bool(boom.get("instant", true)), "an accumulation pop, not the upgrade")
	assert_eq(sim.ai.ai_rng.state, rng_before,
		"the environment blast consumes ZERO ai_rng (undodgable collateral, R22/R26)")
	var died: Dictionary = assert_event(events, "combatant_died", "the 1-HP witness dies in the blast")
	assert_eq(String(died.get("combatant", "")), "witness", "the roach in radius")
	assert_eq(String(died.get("killer", "")), "", "environment kill: NO killer (takedown-v2 honesty)")
	assert_no_event(events, "antagonism_changed", "environment damage earns no grudge")
	var healed: Dictionary = assert_event(events, "healed", "the fire-healing boss is HEALED by the blast")
	assert_eq(String(healed.get("source", "")), "fire_heals", "through the normal boss hook")
	assert_true(sim.arena.objects.is_empty(), "the can is gone")
	assert_event(move(sim, "vic", [3, 0]), "moved", "its hex unblocks once destroyed")


func test_phase_three_pops_cans_instantly() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [3, 0]}]))
	add_human(sim, "vic", {"team": "party", "position": [1, 0],
		"traits": {"physique": 8, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	sim.ai.boss_phase["boss"] = 3  # "flamethrower pops trash cans instantly"
	declare(sim, "boss", cone_sweep())
	var events: Array[Dictionary] = advance(sim, 1)
	var boom: Dictionary = assert_event(events, "trash_can_exploded", "the FIRST touch pops it")
	assert_true(bool(boom.get("instant", false)), "flagged as the phase-3 instant pop")
	assert_no_event(events, "trash_can_burned", "no accumulation on the popped can")
	assert_true(sim.arena.objects.is_empty(), "gone")


func test_can_explosion_cascades_to_nearby_cans() -> void:
	# Two pre-heated cans 1 hex apart: the sweep tips both to 5; the first
	# explosion's blast is a burn TOUCH (+2) on anything still standing, and
	# the queue detonates the second exactly once (no double-pop).
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [
		{"key": "trash_can", "position": [3, 0], "burn": 4},
		{"key": "trash_can", "position": [4, 0], "burn": 4},
	]))
	add_human(sim, "vic", {"team": "party", "position": [1, 0],
		"traits": {"physique": 8, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	declare(sim, "boss", cone_sweep())
	var events: Array[Dictionary] = advance(sim, 1)
	assert_eq(events_of(events, "trash_can_exploded").size(), 2, "both cans detonate, once each")
	assert_true(sim.arena.objects.is_empty(), "both gone")


func test_dash_smashes_through_cans_without_bouncing() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, arena_cfg([], [{"key": "trash_can", "position": [2, 0]}]))
	add_human(sim, "vic", {"team": "party", "position": [4, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_dash_boss(sim, ["dash bounces between walls up to 2 bounces"])
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "the can does not block the lane")
	var shape: Dictionary = _scheduled_shape(sim)
	assert_false(shape.has("bounces"), "and does NOT bounce the charge — cans are not walls")
	advance(sim, 2)
	var events: Array[Dictionary] = advance(sim, 1)
	var smashed: Dictionary = assert_event(events, "trash_can_smashed", "the charge smashes through it")
	assert_eq(smashed.get("position", []), [2, 0], "the can on the corridor")
	assert_no_event(events, "trash_can_exploded", "a smash is not a burn touch — no explosion")
	assert_event(events, "dash_charged", "the charge itself is unbroken")
	assert_eq(boss_state(sim).position, Vector2i(3, 0), "adjacent-before the target, straight through")
	assert_true(sim.arena.objects.is_empty(), "the can is destroyed")


# ------------------------------------------------- run staging + determinism

func test_demo_run_stages_the_authored_arenas() -> void:
	var gc: Node = load("res://controller/game_controller.gd").new()
	var def: Dictionary = (SimTestBase.load_json("res://data/demo_run.json") as Dictionary).get("run", {})
	gc.start_run(int(def.get("run_seed", 0)), def.get("party", []), def.get("encounters", []),
		load_static_data())
	gc.apply_run_command({"type": "begin_encounter"})
	assert_true(gc.sim.arena != null, "encounter 1 staged its authored arena")
	var arena_view: Dictionary = gc.view_arena()
	assert_eq(int((arena_view.get("bounds", {}) as Dictionary).get("width", 0)), 13,
		"the tutorial floor's authored 13x13 bounds")
	assert_eq((arena_view.get("walls", []) as Array).size(), 0, "no walls on the tutorial floor")
	# The staging plan carries the block verbatim (where arena defs LIVE).
	assert_eq(int(((gc.run.staging().get("arena", {}) as Dictionary).get("bounds", {}) as Dictionary).get("width", 0)),
		13, "RunState.staging() passes the encounter's arena block through")
	# The den def authors the incinedile's 41x60 design record + props.
	var den: Dictionary = (def.get("encounters", []) as Array)[2]
	var den_arena: Dictionary = den.get("arena", {})
	assert_eq([int((den_arena.get("bounds", {}) as Dictionary).get("width", 0)),
		int((den_arena.get("bounds", {}) as Dictionary).get("height", 0))], [41, 60],
		"the den mirrors traits.arena_hexes [41, 60]")
	assert_eq((den_arena.get("objects", []) as Array).size(), 3, "2-3 authored trash cans (PLACEHOLDER)")
	assert_true((den_arena.get("walls", []) as Array).size() >= 3, "a handful of authored walls")
	gc.free()


func test_same_seed_same_log_same_hash_through_an_arena_fight() -> void:
	# Determinism through the full new surface: staging + bounce dash + can
	# accumulation + explosion, twice, identical hashes.
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(4242)
		set_arena(sim, arena_cfg([[-1, 1], [2, 1]], [
			{"key": "trash_can", "position": [3, 0], "burn": 4},
		]))
		add_human(sim, "vic", {"team": "party", "position": [-3, 3],
			"traits": {"physique": 8, "reflexes": 2, "mind": 3, "charm": 3}})
		add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
		sim.ai.boss_phase["boss"] = 3
		declare(sim, "boss", cone_sweep())  # instant-pops the pre-heated can (phase 3)
		advance(sim, 1)
		ai_decide(sim, "boss")  # the single-bounce bank shot
		advance(sim, 2)
		advance(sim, 1)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through the arena kit")
