extends SimTestBase
## KAN-5 wave 4d — the war-hound MAZE FUNNEL: corner_the_prey is REAL
## (rules-addendum R11 #21; the compendium §4.6 signature — the pack corners
## the quarry and cuts off its escape). Personality-gated (`herder: true` +
## the shared `pack` family — data-driven, no hardcoded species), layered ON
## TOP of the unchanged strike-or-close flow. Full contract:
## simulation/enemy_ai.gd header, HERDING section.
##
## Under test:
##   * the ROLE SPLIT on a hand-built map (ASCII below): the closest herder
##     CHASES (normal strike flow), the second cuts off — it moves onto the
##     quarry's nearest OPEN door, exact positions pinned;
##   * the cut-off hex computation: nearest open door to the QUARRY (closed
##     doors never count; authored-order tie rule), unit-pinned via
##     nearest_open_door_hex; the no-open-door fallback = the normal chase
##     move, position-pinned;
##   * herding never skips a kill: a quarry in reach -> STRIKE, not
##     reposition (the strike branch runs before any herding check);
##   * the HOLD: a herder already ON the cut-off hex holds its post (wait,
##     reason "holding_cutoff", stance "hunting" — never thrashes back into
##     the chase);
##   * R20 honesty: a stealthed quarry never reaches herding (_opponents
##     excludes it — the pack honestly loses the target); a quarry OUTSIDE
##     sight 2 x Mind (the war hound's 2) is chased, never herded;
##   * a single herder just chases; a non-herder pack (roaches) is unchanged
##     in the same geometry;
##   * determinism + rng cost: zero ai_rng draws on single-candidate herding
##     decides, EXACTLY one draw with two candidates (twin-RNG), same seed +
##     same log -> identical hashes;
##   * the pack_herding event shape (herder / quarry / cutoff_hex), emitted
##     only once the cut-off step REALLY resolves;
##   * serialization: herding adds NO new AI state (exact to_dict key-set
##     pin) and round-trips mid-funnel;
##   * the authored kennel (data/demo_run.json): the wave-4d touch-up — the
##     kennel-run fence + the OPEN kennel_run_gate — exists, off every spawn
##     (the run drive still WINs in test_run_state/test_dungeon_flow).
##
## THE LADDER (the hand-built map — a 5x3 axial rect, origin [0,0], two wall
## posts making three rungs; D = the OPEN kennel_gate door, W = wall,
## P = prey (party human), A/B = war hounds):
##
##       q=0    q=1    q=2    q=3    q=4
##   r=0  .      P      A      B      .
##   r=1    .      W      .      W      .
##   r=2      .      .      D      .      .
##
## B stands 2 from P (sight 2 = 2 x Mind 1 — SEEN; bodies never block LOS)
## but cannot strike this Moment: A's body plugs (2,0) and the walls force
## the long way round (4+ steps to bite range > allowance 3). The chase would
## step B to (0,2) (the A* route (2,1),(1,2),(0,2) truncated); the FUNNEL
## instead posts B on the open door at (2,2) — (2,1), (2,2) — ON the quarry's
## escape in one Moment.

const LADDER_ARENA: Dictionary = {
	"bounds": {"width": 5, "height": 3, "origin": [0, 0]},
	"walls": [[1, 1], [3, 1]],
	"doors": [{"key": "kennel_gate", "position": [2, 2], "state": "open"}],
}


func add_enemy(sim: CombatSim, id: String, enemy_key: String, pos: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": enemy_key, "team": "enemies", "position": pos}})


func add_hound(sim: CombatSim, id: String, pos: Array) -> Array[Dictionary]:
	return add_enemy(sim, id, "war_hound", pos)


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


## The ladder scenario (header ASCII): prey + two hounds, door as authored
## unless overridden. Returns the sim, staged and ready at tick 0.
func ladder_sim(sim_seed: int = 1234, door_state: String = "open") -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	var arena: Dictionary = LADDER_ARENA.duplicate(true)
	((arena["doors"] as Array)[0] as Dictionary)["state"] = door_state
	sim.apply_command({"type": "set_arena", "arena": arena})
	add_human(sim, "prey", {"team": "party", "position": [1, 0]})
	add_hound(sim, "hound_a", [2, 0])
	add_hound(sim, "hound_b", [3, 0])
	return sim


# ------------------------------------------------------------- the role split

func test_role_split_closest_chases_second_cuts_off() -> void:
	var sim: CombatSim = ladder_sim()
	var pre_rng: int = sim.ai.ai_rng.state
	# A (distance 1) is the CLOSEST herder — the chaser role: normal strike.
	var first: Array[Dictionary] = ai_decide(sim, "hound_a")
	var da: Dictionary = assert_event(first, "ai_decision", "the chaser decides")
	assert_eq(String(da.get("choice", "")), "attack", "closest herder CHASES — the normal strike flow")
	assert_eq(String(da.get("ability", "")), "rending_bite", "with its authored bite")
	assert_no_event(first, "pack_herding", "the chaser never herds")
	assert_eq(String(sim.ai.stances.get("hound_a", "")), "aggressive", "a biting chaser reads aggressive")
	# B (distance 2, SEEN — sight 2, LOS through A's body) cannot strike this
	# Moment (A plugs (2,0), the walls force the 4-step way round): the funnel
	# rewrites its chase into the cut-off move ONTO the open door.
	var second: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(second, "ai_decision", "the cut-off herder decides")
	assert_eq(String(db.get("choice", "")), "move", "the cut-off is a MOVE decision")
	assert_eq(String(db.get("target", "")), "prey", "the quarry rides the decision event")
	assert_true(bool(db.get("moves", false)), "the decision carries the step")
	var moved: Dictionary = assert_event(second, "moved", "the step really resolves")
	assert_eq(moved.get("to", []), [2, 2], "B posts ON the open door — (2,1), (2,2), pinned")
	assert_eq((sim.combatants["hound_b"] as CombatantState).position, Vector2i(2, 2),
		"B stands on the quarry's escape")
	assert_event(second, "pack_herding", "the funnel announces itself")
	assert_eq(String(sim.ai.stances.get("hound_b", "")), "hunting",
		"a cutting-off herder reads hunting (the move stance)")
	# Zero ai_rng draws anywhere: single candidate for both decides, and the
	# role split / cut-off hex are pure functions of sorted state.
	assert_eq(sim.ai.ai_rng.state, pre_rng, "the whole split consumed ZERO ai_rng draws")


func test_pack_herding_event_shape() -> void:
	var sim: CombatSim = ladder_sim()
	ai_decide(sim, "hound_a")
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var herd: Dictionary = assert_event(events, "pack_herding", "the cut-off move emits it")
	assert_eq(herd, {
		"type": "pack_herding", "herder": "hound_b",
		"quarry": "prey", "cutoff_hex": [2, 2],
		"tick": 0,  # the standard per-command tick stamp every event carries
	}, "the exact event shape: herder, quarry, cutoff_hex (+ tick stamp)")
	# Emitted AFTER the moved event (announced only once the step resolved).
	var saw_moved: bool = false
	for event: Dictionary in events:
		if String(event.get("type", "")) == "moved":
			saw_moved = true
		if String(event.get("type", "")) == "pack_herding":
			assert_true(saw_moved, "pack_herding follows the resolved step — the honesty order")


# ------------------------------------------------------------ the cut-off hex

func test_nearest_open_door_closed_skipped_and_authored_order_ties() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 5, "height": 3, "origin": [0, 0]},
		"doors": [
			{"key": "z_closed", "position": [1, 2], "state": "closed"},
			{"key": "gate_a", "position": [0, 0], "state": "open"},
			{"key": "gate_b", "position": [2, 0], "state": "open"},
		]}})
	# gate_a and gate_b are BOTH distance 1 from (1,0); z_closed never counts
	# (a closed door is a wall, not an escape). Tie -> the EARLIEST authored
	# open door (gate_a).
	assert_eq(sim.ai.nearest_open_door_hex(Vector2i(1, 0)), Vector2i(0, 0),
		"nearest OPEN door; authored order breaks the exact tie")
	# From (2,1): gate_b at distance 1 is strictly nearest.
	assert_eq(sim.ai.nearest_open_door_hex(Vector2i(2, 1)), Vector2i(2, 0),
		"strictly nearest open door wins")
	# All doors closed -> null (no escape to deny).
	var sim2: CombatSim = make_sim()
	sim2.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 5, "height": 3, "origin": [0, 0]},
		"doors": [{"key": "d", "position": [1, 2], "state": "closed"}]}})
	assert_eq(sim2.ai.nearest_open_door_hex(Vector2i(1, 0)), null, "closed-only arena has no escape")
	# No doors at all -> null; no arena -> null.
	var sim3: CombatSim = make_sim()
	sim3.apply_command({"type": "set_arena", "arena": {"bounds": {"width": 5, "height": 3}}})
	assert_eq(sim3.ai.nearest_open_door_hex(Vector2i.ZERO), null, "door-less arena has no escape")
	var sim4: CombatSim = make_sim()
	assert_eq(sim4.ai.nearest_open_door_hex(Vector2i.ZERO), null, "no arena, no escape")


func test_no_open_door_falls_back_to_the_normal_chase() -> void:
	# The ladder with the door CLOSED: same geometry, no escape to deny — B's
	# decide IS the normal chase move (the A* route toward bite range,
	# truncated at allowance 3), pinned exactly.
	var sim: CombatSim = ladder_sim(1234, "closed")
	ai_decide(sim, "hound_a")
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "B decides")
	assert_eq(String(db.get("choice", "")), "move", "still a move — the chase")
	var moved: Dictionary = assert_event(events, "moved", "the chase step resolves")
	assert_eq(moved.get("to", []), [0, 2], "the NORMAL chase step — (2,1),(1,2),(0,2) truncated, pinned")
	assert_no_event(events, "pack_herding", "no open door -> no funnel")


# --------------------------------------------- herding never skips a kill

func test_quarry_in_reach_strikes_instead_of_repositioning() -> void:
	# B posts on the door (the role-split flow), then the prey blunders into
	# reach: B's next decide is the STRIKE — herding is positioning, never
	# pacifism (the strike branch runs before any herding check).
	var sim: CombatSim = ladder_sim()
	ai_decide(sim, "hound_a")
	ai_decide(sim, "hound_b")
	assert_eq((sim.combatants["hound_b"] as CombatantState).position, Vector2i(2, 2), "B on its post")
	advance(sim, 1)
	move(sim, "prey", [2, 1])  # the prey runs FOR the gate — into B's jaws
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "B decides with prey adjacent")
	assert_eq(String(db.get("choice", "")), "attack", "in reach -> STRIKE, never a reposition")
	assert_eq(String(db.get("ability", "")), "rending_bite", "the bite")
	assert_no_event(events, "pack_herding", "no herding on a strikeable quarry")
	assert_eq(String(sim.ai.stances.get("hound_b", "")), "aggressive", "the killer stance")


# ------------------------------------------------------------------- the hold

func test_herder_on_the_cutoff_hex_holds_its_post() -> void:
	# B already ON the open door, quarry SEEN (distance 2, LOS through the
	# chaser's body) but not strikeable (A plugs the only short approach):
	# B HOLDS — wait, reason holding_cutoff, stance hunting, no thrash.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": LADDER_ARENA.duplicate(true)})
	add_human(sim, "prey", {"team": "party", "position": [2, 0]})
	add_hound(sim, "hound_a", [2, 1])
	add_hound(sim, "hound_b", [3, 2])
	move(sim, "hound_b", [2, 2])  # standing in the open doorway is legal
	advance(sim, 1)
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "the posted herder decides")
	assert_eq(String(db.get("choice", "")), "wait", "the hold is a wait")
	assert_eq(String(db.get("reason", "")), "holding_cutoff", "with the documented reason")
	assert_eq(String(db.get("target", "")), "prey", "the quarry rides the hold too")
	assert_false(bool(db.get("moves", false)), "no step — the post is kept")
	assert_no_event(events, "pack_herding", "the hold emits nothing new (the post was announced)")
	assert_eq((sim.combatants["hound_b"] as CombatantState).position, Vector2i(2, 2), "B stays put")
	assert_eq(String(sim.ai.stances.get("hound_b", "")), "hunting",
		"holding the post reads hunting (the documented stance exception)")


# ---------------------------------------------------- R20 honesty (visibility)

func test_stealthed_quarry_is_never_herded() -> void:
	# A stealthed quarry does not EXIST to the policy (R20): no targeting, no
	# draw, no herding — the pack honestly loses the target and waits.
	var sim: CombatSim = ladder_sim()
	(sim.combatants["prey"] as CombatantState).stealthed = true
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "B decides blind")
	assert_eq(String(db.get("choice", "")), "wait", "no visible prey -> wait")
	assert_eq(String(db.get("reason", "")), "no_targets", "the honest reason")
	assert_no_event(events, "pack_herding", "nothing to herd")


func test_quarry_outside_sight_two_is_chased_not_herded() -> void:
	# B staged at (4,2): distance 5 from the prey — far outside the war
	# hound's sight 2 (2 x Mind 1). The prey is not stealthed, so the CHASE
	# proceeds as ever (R20: sight gates herding INFORMATION, not targeting) —
	# but the funnel needs eyes on the quarry: normal chase move, pinned.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": LADDER_ARENA.duplicate(true)})
	add_human(sim, "prey", {"team": "party", "position": [1, 0]})
	add_hound(sim, "hound_a", [2, 0])
	add_hound(sim, "hound_b", [4, 2])
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "the far hound decides")
	assert_eq(String(db.get("choice", "")), "move", "a plain chase move")
	var moved: Dictionary = assert_event(events, "moved", "the chase step resolves")
	assert_eq(moved.get("to", []), [1, 2],
		"the NORMAL chase route — (3,2),(2,2),(1,2) truncated, pinned — not the door post")
	assert_no_event(events, "pack_herding", "unseen quarry -> no funnel")


# ------------------------------------------- lone herders and non-herder packs

func test_single_herder_chases_normally() -> void:
	# The ladder with a trash can plugging (2,0) instead of the chaser's body:
	# ONE hound, same unreachable-quarry geometry, door open — but a pack of
	# one never splits roles: the normal chase move, pinned.
	var sim: CombatSim = make_sim()
	var arena: Dictionary = LADDER_ARENA.duplicate(true)
	arena["objects"] = [{"key": "trash_can", "position": [2, 0]}]
	sim.apply_command({"type": "set_arena", "arena": arena})
	add_human(sim, "prey", {"team": "party", "position": [1, 0]})
	add_hound(sim, "hound_b", [3, 0])
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "the lone hound decides")
	assert_eq(String(db.get("choice", "")), "move", "a plain chase move")
	var moved: Dictionary = assert_event(events, "moved", "the chase step resolves")
	assert_eq(moved.get("to", []), [0, 2], "the normal chase route — no cut-off for a lone herder")
	assert_no_event(events, "pack_herding", "a pack of one never funnels")


func test_non_herder_pack_is_unchanged() -> void:
	# Roaches in the exact role-split geometry (pack_hunters, but NOT
	# herders): the second roach chases — same route the chase always took —
	# and nothing herds. The open door means nothing to a non-herder.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": LADDER_ARENA.duplicate(true)})
	add_human(sim, "prey", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "roach_a", "roach_dog", [2, 0])
	add_enemy(sim, "roach_b", "roach_dog", [3, 0])
	var events: Array[Dictionary] = ai_decide(sim, "roach_b")
	var db: Dictionary = assert_event(events, "ai_decision", "the second roach decides")
	assert_eq(String(db.get("choice", "")), "move", "a plain chase move")
	var moved: Dictionary = assert_event(events, "moved", "the chase step resolves")
	assert_eq(moved.get("to", []), [0, 2], "byte-identical to the pre-herding chase")
	assert_no_event(events, "pack_herding", "non-herders never funnel")


func test_closest_herder_tie_keeps_the_earliest_sorted_id() -> void:
	# The role-split tie rule, unit-pinned: two herders EXACTLY equidistant
	# from the quarry — the earliest sorted id is the chaser.
	var sim: CombatSim = make_sim()
	add_human(sim, "prey", {"team": "party", "position": [1, 1]})
	add_hound(sim, "hound_a", [2, 0])
	add_hound(sim, "hound_b", [0, 2])
	var pack: Array[CombatantState] = sim.ai._herder_pack(sim.combatants["hound_a"], "war_hound")
	assert_eq(pack.size(), 2, "both hounds are pack herders")
	assert_eq(EnemyAI._closest_herder_id(pack, Vector2i(1, 1)), "hound_a",
		"distance 1 vs distance 1: the sorted-id tie keeps hound_a")


# ------------------------------------------------ determinism + rng cost

func test_determinism_same_seed_same_log_identical() -> void:
	var a: CombatSim = _drive_funnel(777)
	var b: CombatSim = _drive_funnel(777)
	assert_eq(a.state_hash(), b.state_hash(), "same seed + same log -> identical hash")
	assert_eq(a.ai.ai_rng.state, b.ai.ai_rng.state, "identical rng stream position")
	assert_ne(_drive_funnel(778).state_hash(), a.state_hash(), "a different seed diverges")


func test_two_candidate_herding_decide_still_costs_exactly_one_draw() -> void:
	# The R23 rng-cost rule survives herding: >= 2 candidates -> EXACTLY one
	# ai_rng draw (the antagonism pick), twin-proven; the role split and the
	# cut-off hex consume nothing on top.
	var sim: CombatSim = ladder_sim()
	add_human(sim, "prey2", {"team": "party", "position": [0, 1]})
	var pre: int = sim.ai.ai_rng.state
	ai_decide(sim, "hound_b")
	var twin := RandomNumberGenerator.new()
	twin.state = pre
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state,
		"two candidates -> exactly ONE draw, herding or not")


## The full funnel drive used by the determinism pins: role split at tick 0,
## the prey runs for the gate at tick 1, B strikes at tick 2 — chase, funnel,
## kill, all through real commands.
func _drive_funnel(sim_seed: int) -> CombatSim:
	var sim: CombatSim = ladder_sim(sim_seed)
	ai_decide(sim, "hound_a")
	ai_decide(sim, "hound_b")
	advance(sim, 1)
	move(sim, "prey", [2, 1])
	ai_decide(sim, "hound_b")
	advance(sim, 2)
	return sim


# ---------------------------------------------------------------- serialization

func test_herding_adds_no_ai_state_and_round_trips() -> void:
	# Mid-funnel state: A's bite pending, B posted on the door. The AI block
	# serializes the EXACT pre-herding key set — the role split and cut-off
	# hex re-derive from sorted state, nothing new is stored.
	var sim: CombatSim = ladder_sim()
	ai_decide(sim, "hound_a")
	ai_decide(sim, "hound_b")
	var ai_keys: Array = (sim.to_dict().get("ai", {}) as Dictionary).keys()
	ai_keys.sort()
	assert_eq(ai_keys,
		["ai_rng_state", "boss_phase", "death_spins", "explosion_beats", "stances", "summons"],
		"the exact wave-3a AI key set — herding stores NOTHING new")
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "mid-funnel roundtrip hash identical")
	# The continuation is command-identical on both: the prey closes, B kills.
	advance(sim, 1)
	advance(restored, 1)
	move(sim, "prey", [2, 1])
	move(restored, "prey", [2, 1])
	var live: Array[Dictionary] = ai_decide(sim, "hound_b")
	var replayed: Array[Dictionary] = ai_decide(restored, "hound_b")
	assert_eq(String(first_event(replayed, "ai_decision").get("choice", "")),
		String(first_event(live, "ai_decision").get("choice", "")),
		"identical post-restore decide (the strike)")
	assert_eq(restored.state_hash(), sim.state_hash(), "post-continuation hashes identical")


# ------------------------------------------------- the authored kennel (data)

func test_kennel_arena_authors_the_gate_the_funnel_denies() -> void:
	# The wave-4d touch-up (PROVISIONAL): the kennel-run fence + the OPEN
	# kennel_run_gate — the escape the second hound's cut-off posts on. Fence
	# and gate sit clear of every staged spawn (the run drive is untouched —
	# the WIN pins live in test_run_state/test_dungeon_flow).
	var run_def: Dictionary = (SimTestBase.load_json("res://data/demo_run.json") as Dictionary).get("run", {})
	var kennel: Dictionary = (run_def.get("encounters", []) as Array)[1]
	assert_eq(String(kennel.get("key", "")), "kennel_gauntlet", "the mid room is the kennel")
	var arena: Dictionary = kennel.get("arena", {})
	var doors: Array = arena.get("doors", [])
	assert_eq(doors.size(), 1, "one kennel door")
	var gate: Dictionary = doors[0]
	assert_eq(String(gate.get("key", "")), "kennel_run_gate", "the kennel-run gate")
	assert_eq(String(gate.get("state", "")), "open", "authored OPEN — the obvious escape")
	var gate_pos: Array = gate.get("position", [])
	assert_eq(int(gate_pos[0]), -4, "in the fence gap, west side (q)")
	assert_eq(int(gate_pos[1]), 0, "in the fence gap, west side (r)")
	var walls: Array = arena.get("walls", [])
	assert_eq(walls.size(), 4, "the fence: four wall hexes flanking the gate")
	for wall: Variant in walls:
		assert_eq(int((wall as Array)[0]), -4, "the fence runs the q = -4 line")
		assert_true(int((wall as Array)[1]) != 0, "the gap at r = 0 is the gate's hex")
	# Every staged spawn sits at q >= 0 — fence and gate never touch staging.
	for pos: Variant in (kennel.get("party_positions", {}) as Dictionary).values():
		assert_true(int((pos as Array)[0]) >= 0, "party staging clear of the fence")
	for row: Variant in kennel.get("enemies", []) as Array:
		for pos: Variant in (row as Dictionary).get("positions", []) as Array:
			assert_true(int((pos as Array)[0]) >= 0, "hound staging clear of the fence")
