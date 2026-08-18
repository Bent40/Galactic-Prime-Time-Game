extends SimTestBase
## R30 — the FACING primitive (decision #33, owner 2026-08-18: "facing
## primitive for sure is needed; it's part of the stealth engine too").
##
## Under test:
##   * the ARC MODEL, ASCII-pinned: front = {facing-1, facing, facing+1},
##     rear = the opposite 3, membership for all six directions + the six
##     exact-diagonal boundary hexes (direction_index's global tie rule);
##   * is_behind edge cases: same hex, adjacency, distance-independence, the
##     exact ±60° boundary rays;
##   * the STAGING default: face the nearest opponent at add time (tie =
##     earliest sorted id), else direction 0;
##   * the UPDATE TABLE, case by case: targeted declare (instant + windup
##     HOLD — no re-face at strike resolution, so a committed attacker can be
##     flanked), free move, scheduled move, tactical roll, dash charge (lane
##     direction at the final hex — a bent lane pins the difference from the
##     declare-time facing), grapple (both parties face each other, the held
##     victim included), AI actions through ai_decide (the table applies to
##     every combatant); involuntary displacement (knockback / sidestep)
##     never re-faces;
##   * R20 vision cones (sees): an observer misses a hider OUTSIDE its front
##     arc at equal range/LOS and catches one inside; staying out of the
##     front arc IS the new concealment; the observer turning (moving)
##     re-opens its cone — R20's "reacting turns it so you enter its cone",
##     now literal;
##   * herding respects cones: a herder whose quarry sits in its rear arc
##     falls back to the normal chase (position-pinned);
##   * serialization: the only-when-set pin ("facing" key present ONLY while
##     != 0; a facing-untouched fight serializes with NO facing key anywhere),
##     mid-fight round-trip + lockstep, determinism;
##   * the view carries facing additively (spectator contract).
##
## The legacy byte-compat re-pin (base-engine hashes reproduced, the facing
## key proven the ONLY delta) lives in tests/test_stealth.gd; the batch-A
## rear-arc retrofit pins (slip_through rear reposition + decapitate's
## not_behind_target gate) live in tests/test_skills_batch_a.gd.
##
## THE ARC ASCII (from simulation/stealth.gd — direction indices into
## HexGeometry.DIRECTIONS: 0=E, 1=NE, 2=NW, 3=W, 4=SW, 5=SE):
##
##      (0,-1) (1,-1)          NW  NE
##   (-1,0)  S  (1,0)    =    W    S    E
##      (-1,1) (0,1)           SW  SE
##
##   facing 0 (E):  FRONT = {SE, E, NE} (5, 0, 1) · REAR = {NW, W, SW} (2, 3, 4)


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func stealth(sim: CombatSim, actor: String, to_state: String = "hide") -> Array[Dictionary]:
	return sim.apply_command({"type": "stealth", "actor": actor, "set": to_state})


func facing_of(sim: CombatSim, id: String) -> int:
	return (sim.combatants[id] as CombatantState).facing


# ------------------------------------------------------------------ arc math

func test_front_and_rear_arcs_for_all_six_facings() -> void:
	# For every facing f: the six pure direction hexes split 3 front / 3 rear
	# exactly as {f-1, f, f+1} vs the rest — at distance 1 AND at distance 4
	# (the arcs are unbounded wedges; range is a separate gate).
	var origin := Vector2i.ZERO
	for f: int in range(6):
		for d: int in range(6):
			var offset: int = (d - f + 6) % 6
			var expect_front: bool = offset <= 1 or offset == 5
			for dist: int in [1, 4]:
				var hex: Vector2i = origin + HexGeometry.DIRECTIONS[d] * dist
				assert_eq(Stealth.front_arc_contains(origin, f, hex), expect_front,
					"facing %d, direction %d, distance %d" % [f, d, dist])


func test_boundary_diagonals_follow_the_direction_index_tie_rule() -> void:
	# The six exact-diagonal hexes tie between two adjacent directions and
	# snap to the EARLIER HexGeometry.DIRECTIONS entry (global index order) —
	# pinned here so the arc boundary can never drift silently.
	var diagonal_reads: Dictionary = {
		Vector2i(2, -1): 0,   # E+NE  -> E
		Vector2i(1, -2): 1,   # NE+NW -> NE
		Vector2i(-1, -1): 2,  # NW+W  -> NW
		Vector2i(-2, 1): 3,   # W+SW  -> W
		Vector2i(-1, 2): 4,   # SW+SE -> SW
		Vector2i(1, 1): 0,    # SE+E  -> E (the wrap: index 0 beats index 5)
	}
	for hex: Vector2i in diagonal_reads:
		assert_eq(HexGeometry.direction_index(Vector2i.ZERO, hex), int(diagonal_reads[hex]),
			"diagonal %s reads direction %d" % [str(hex), int(diagonal_reads[hex])])
	# Membership consequences for facing 0 (front {5,0,1} / rear {2,3,4}):
	assert_true(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(2, -1)), "E+NE diagonal is front")
	assert_true(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(1, 1)), "SE+E diagonal is front")
	assert_true(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(1, -2)), "NE+NW diagonal is front (reads NE)")
	assert_false(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(-1, -1)), "NW+W diagonal is rear")
	assert_false(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(-2, 1)), "W+SW diagonal is rear")
	assert_false(Stealth.front_arc_contains(Vector2i.ZERO, 0, Vector2i(-1, 2)), "SW+SE diagonal is rear (reads SW)")


func test_is_behind_edge_cases() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "s", {"team": "party", "position": [0, 0]})
	var s: CombatantState = sim.combatants["s"]
	s.facing = 0  # E (it already is — explicit for the pin)
	assert_false(Stealth.is_behind(s, Vector2i(0, 0)), "your own hex is never behind you (distance 0)")
	assert_true(Stealth.is_behind(s, Vector2i(-1, 0)), "adjacent W is behind (adjacent included)")
	assert_true(Stealth.is_behind(s, Vector2i(-5, 0)), "distance never fronts a rear hex (unbounded wedge)")
	assert_false(Stealth.is_behind(s, Vector2i(1, 0)), "adjacent E is in front")
	assert_false(Stealth.is_behind(s, Vector2i(4, -4)), "the pure facing+1 boundary ray (NE) is FRONT, at any range")
	assert_false(Stealth.is_behind(s, Vector2i(0, 4)), "the pure facing-1 boundary ray (SE) is FRONT")
	assert_true(Stealth.is_behind(s, Vector2i(0, -4)), "one step past the boundary (NW) is REAR")
	assert_true(Stealth.is_behind(s, Vector2i(-4, 4)), "the SW ray is REAR")
	s.facing = 3  # W — the mirrored read
	assert_true(Stealth.is_behind(s, Vector2i(1, 0)), "facing W: adjacent E is behind")
	assert_false(Stealth.is_behind(s, Vector2i(-1, 0)), "facing W: adjacent W is in front")


# ------------------------------------------------------------ staging default

func test_staging_faces_nearest_opponent_else_direction_zero() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	assert_eq(facing_of(sim, "a"), 0, "no opponents at add time -> direction 0")
	add_human(sim, "e1", {"team": "enemies", "position": [3, 3]})
	assert_eq(facing_of(sim, "e1"), 2, "e1 faces its nearest opponent a: (-3,-3) ties NW/W -> NW (earlier index)")
	assert_eq(facing_of(sim, "a"), 0, "an arriving opponent never re-faces an existing combatant")
	add_human(sim, "e2", {"team": "enemies", "position": [0, 3]})
	assert_eq(facing_of(sim, "e2"), 2, "e2 faces a at pure NW, distance 3")
	# Tie: two opponents exactly equidistant -> the earliest sorted id wins.
	add_human(sim, "b", {"team": "party", "position": [3, 0]})
	# b's opponents: e1 at (0,3) rel = distance 3, e2 at (-3,3) rel = distance 3
	# -> sorted-id tie keeps e1 -> direction (0,3) = SE.
	assert_eq(facing_of(sim, "b"), 5, "equidistant opponents: the earliest sorted id (e1) sets the direction")


# ------------------------------------------------------------ the update table

func test_targeted_declare_faces_the_first_target() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "t", {"team": "enemies", "position": [0, 2]})
	assert_eq(facing_of(sim, "a"), 0, "staged before any opponent existed")
	declare(sim, "a", attack_action("crushed", 1, "t", "torso", {"attack_range": 6}))
	assert_eq(facing_of(sim, "a"), 5, "the declare itself faces the target (SE), before any resolution")


func test_windup_holds_facing_and_a_flanker_gets_behind_the_committed_boss() -> void:
	# The AI-honesty consequence (decision #33): a windup faces at declare and
	# HOLDS through the windup — no re-face until (and at) the strike's
	# resolution — so a second contestant CAN now get behind a committed boss.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "boss", "category": "Boss", "team": "enemies",
		"position": [0, 0], "traits": {"physique": 4, "reflexes": 2, "mind": 2, "charm": 1},
		"body_parts": [{"key": "torso", "hp": 30, "lethal": true}]}})
	add_human(sim, "c1", {"team": "party", "position": [0, 2]})
	add_human(sim, "c2", {"team": "party", "position": [1, 1]})
	assert_eq(facing_of(sim, "boss"), 0, "staged before any opponent existed")
	declare(sim, "boss", attack_action("crushed", 2, "c1", "torso", {"cost": 2, "attack_range": 6}))
	assert_eq(facing_of(sim, "boss"), 5, "the windup faces its target (SE) at declare")
	assert_true((sim.combatants["boss"] as CombatantState).windup_pending, "committed")
	# c2 circles behind (facing 5's rear arc = {NE, NW, W}) while committed.
	move(sim, "c2", [-1, 0])
	assert_eq(facing_of(sim, "boss"), 5, "no re-face on someone else's move")
	assert_true(Stealth.is_behind(sim.combatants["boss"], Vector2i(-1, 0)),
		"the flanker IS behind the committed boss — the windup holds its facing")
	var resolution: Array[Dictionary] = advance(sim, 3)
	assert_event(resolution, "damage_applied", "the committed strike still lands on c1")
	assert_eq(facing_of(sim, "boss"), 5, "a strike RESOLUTION never re-faces (only the table's movement rules do)")
	assert_true(Stealth.is_behind(sim.combatants["boss"], Vector2i(-1, 0)), "c2 is still behind post-resolution")


func test_moves_rolls_and_repositions_face_their_direction() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	# Free move: the from->to ray's nearest direction.
	move(sim, "a", [0, 2])
	assert_eq(facing_of(sim, "a"), 5, "free move SE faces SE")
	advance(sim, 1)
	# Scheduled move (distance > 3): faces at RESOLUTION.
	move(sim, "a", [0, -4])
	assert_eq(facing_of(sim, "a"), 5, "the scheduled move has not resolved yet — facing holds")
	advance(sim, 1)
	assert_eq(facing_of(sim, "a"), 2, "the resolved move faces NW")
	assert_eq((sim.combatants["a"] as CombatantState).position, Vector2i(0, -4), "and really moved")
	# Tactical roll: voluntary movement at declare — faces the roll direction.
	declare(sim, "a", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, -5]})
	assert_eq(facing_of(sim, "a"), 1, "the roll faces its direction (NE) immediately at declare")


func test_dash_charge_faces_the_lane_direction_at_its_final_hex() -> void:
	# A STOPPED-SHORT charge pins the difference between the declare-time
	# facing (toward the target: [1,2] reads SE) and the resolution facing
	# (the lane direction AT the final hex): an interloper on [1,1] stops the
	# run at [0,1], where the committed lane's next step points E.
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "t", {"team": "enemies", "position": [1, 2]})
	add_human(sim, "wall", {"team": "enemies", "position": [1, 1]})  # the lane interloper
	declare(sim, "a", {"kind": "attack", "cost": 2, "attack_range": 6,
		"damage": {"type": "crushed", "amount": 2},
		"targets": [{"id": "t", "part": "torso"}],
		"area_shape": {"kind": "line",
			"lane": [[0, 0], [0, 1], [1, 1], [1, 2]]}})
	assert_eq(facing_of(sim, "a"), 5, "declare faces the target: (1,2) reads SE")
	var resolution: Array[Dictionary] = advance(sim, 3)
	var charged: Dictionary = assert_event(resolution, "dash_charged", "the charge ran the lane")
	assert_eq(charged.get("to", []), [0, 1], "the interloper stops the run one hex in")
	assert_event(resolution, "dash_stopped_short", "an honest miss — the Moment was spent charging")
	assert_eq(facing_of(sim, "a"), 0,
		"the charge faces the LANE direction at its final hex (the next lane step points E) — not the target")


func test_grapple_faces_both_parties_toward_each_other() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "g", {"team": "party", "position": [0, 0]})
	add_human(sim, "v", {"team": "enemies", "position": [1, 0]})
	# Point the victim AWAY first (state poke, the stealthed-test idiom).
	(sim.combatants["v"] as CombatantState).facing = 0  # E — back turned to g
	(sim.combatants["g"] as CombatantState).facing = 3  # W — looking away too
	declare(sim, "g", {"kind": "grapple", "cost": 1, "target": "v"})
	assert_eq(facing_of(sim, "g"), 0, "the grapple DECLARE already faces the target")
	var resolution: Array[Dictionary] = advance(sim, 1)
	assert_event(resolution, "grapple_started", "the hold lands")
	assert_eq(facing_of(sim, "g"), 0, "grappler faces the victim (E)")
	assert_eq(facing_of(sim, "v"), 3, "the HELD victim is turned to face the grappler (W) — the one involuntary facing, ruled")


func test_ai_actions_update_facing_through_the_same_table() -> void:
	# The table applies to every combatant: the mob's own ai_decide declare
	# re-faces it exactly like a player command would.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [1, 0]}})
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	# The mob staged first (no opponents -> 0); walk h1 around and let the
	# mob's own attack declares re-face it through the shared seam.
	assert_eq(facing_of(sim, "mob"), 0, "mob staged before any opponent existed")
	move(sim, "h1", [2, 0])  # east of the mob
	(sim.combatants["mob"] as CombatantState).facing = 3  # point away — the declare must re-face
	var decided: Array[Dictionary] = ai_decide(sim, "mob")
	assert_eq(String(first_event(decided, "ai_decision").get("choice", "")), "attack", "adjacent bite")
	assert_eq(facing_of(sim, "mob"), 0, "the bite declare faces E — the mob's own action ran the table")
	advance(sim, 1)
	move(sim, "h1", [0, 0])  # west of the mob
	ai_decide(sim, "mob")
	assert_eq(facing_of(sim, "mob"), 3, "next Moment's bite re-faces W — AI facing is live, not staged-only")


func test_involuntary_displacement_never_re_faces() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "t", {"team": "enemies", "position": [1, 0]})
	var t: CombatantState = sim.combatants["t"]
	t.facing = 2  # NW — an arbitrary non-default posture
	# Knockback (the batch-A shove): displaced 1 hex E, facing untouched.
	var events: Array[Dictionary] = sim.resolver._knockback_away(t, sim.combatants["a"])
	assert_true(bool((events[0] as Dictionary).get("displaced", false)), "the shove displaced")
	assert_eq(t.position, Vector2i(2, 0), "pushed directly away (E)")
	assert_eq(t.facing, 2, "knockback NEVER re-faces (involuntary)")
	# Sidestep (the R22 dodge rider): displaced off the lane, facing untouched.
	var lane_set: Dictionary = HexGeometry.to_set([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i])
	var side: Array[Dictionary] = sim.resolver._dash_sidestep(t, sim.combatants["a"], lane_set)
	assert_eq(side.size(), 1, "the sidestep fired")
	assert_ne(t.position, Vector2i(2, 0), "stepped off the lane")
	assert_eq(t.facing, 2, "sidestep NEVER re-faces (reflex, not a chosen move)")


# ------------------------------------------------------ R20 vision cones (sees)

func test_observer_misses_outside_its_front_arc_at_equal_range_and_los() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "watcher", {"team": "enemies", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})  # facing 0 (E), sight 6
	add_human(sim, "h1", {"team": "party", "position": [-4, 0]})  # W: REAR arc, distance 4, clear LOS
	add_human(sim, "h2", {"team": "party", "position": [4, 0]})   # E: FRONT arc, same distance, same LOS
	var watcher: CombatantState = sim.combatants["watcher"]
	assert_false(Stealth.sees(watcher, sim.combatants["h1"], null, 0),
		"equal range, equal LOS — the rear-arc contestant is UNSEEN (the cone gate)")
	assert_true(Stealth.sees(watcher, sim.combatants["h2"], null, 0),
		"the front-arc contestant at the same range IS seen")
	# The feature: hiding works behind the observer's back.
	assert_event(stealth(sim, "h1"), "stealth_entered", "staying out of the front arc IS concealment now")
	assert_rejected(stealth(sim, "h2"), "in_enemy_sight", "in the cone the old binary stands")
	# Closing distance INSIDE the rear arc reveals nothing.
	advance(sim, 1)
	var step: Array[Dictionary] = move(sim, "h1", [-3, 0])
	assert_no_event(step, "stealth_broken", "closer, still over the shoulder — still hidden")
	# The observer TURNS (moves — the move re-faces it SW, fronting the W ray):
	# R20's "reacting turns/moves it so you enter its cone", literal now.
	var turn: Array[Dictionary] = move(sim, "watcher", [-1, 1])
	var broken: Dictionary = assert_event(turn, "stealth_broken", "the turned cone finds the hider")
	assert_eq(String(broken.get("reason", "")), "seen", "seen — the cone re-opened, nothing else changed")
	assert_eq(String(broken.get("observer", "")), "watcher", "by the watcher")


func test_herding_respects_the_cone() -> void:
	# The wave-4d ladder geometry (tests/test_herding.gd) with the cut-off
	# hound's facing poked EAST: the quarry (W) sits in its rear arc, so
	# Stealth.sees fails and the funnel honestly falls back to the normal
	# chase — the exact pre-herding route, position-pinned.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 5, "height": 3, "origin": [0, 0]},
		"walls": [[1, 1], [3, 1]],
		"doors": [{"key": "kennel_gate", "position": [2, 2], "state": "open"}]}})
	add_human(sim, "prey", {"team": "party", "position": [1, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "hound_a", "name": "hound_a", "enemy": "war_hound", "team": "enemies", "position": [2, 0]}})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "hound_b", "name": "hound_b", "enemy": "war_hound", "team": "enemies", "position": [3, 0]}})
	(sim.combatants["hound_b"] as CombatantState).facing = 0  # E — back to the prey
	ai_decide(sim, "hound_a")
	var events: Array[Dictionary] = ai_decide(sim, "hound_b")
	var db: Dictionary = assert_event(events, "ai_decision", "the blind-side herder decides")
	assert_eq(String(db.get("choice", "")), "move", "still a move — the chase")
	var moved: Dictionary = assert_event(events, "moved", "the chase step resolves")
	assert_eq(moved.get("to", []), [0, 2], "the NORMAL chase route — a rear-arc quarry is chased, never herded")
	assert_no_event(events, "pack_herding", "no funnel without eyes on the quarry (the cone gate)")


# --------------------------------------- serialization / determinism / view

func test_only_when_set_serialization_and_untouched_fight_has_no_key() -> void:
	# The compat pin: "facing" exists ONLY while != 0 (documented default 0).
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "b", {"team": "enemies", "position": [3, 0]})
	var dict: Dictionary = sim.to_dict()
	assert_false((dict["combatants"]["a"] as Dictionary).has("facing"),
		"facing 0 serializes NO key (the only-when-set pin)")
	assert_eq(int((dict["combatants"]["b"] as Dictionary).get("facing", -1)), 3,
		"a staged non-zero facing serializes (b faces its opponent W)")
	# A genuinely facing-untouched fight: same-team roster (no staging
	# opponents), eastward moves only (E = the direction-0 default), advances —
	# the serialized state contains no facing key ANYWHERE, byte-identical to
	# the pre-facing engine (the base-engine byte proof rides the re-pinned
	# legacy hashes in test_stealth.gd).
	var sim2: CombatSim = make_sim(41)
	add_human(sim2, "a", {"team": "party", "position": [0, 0]})
	add_human(sim2, "b", {"team": "party", "position": [0, 1]})
	move(sim2, "a", [2, 0])
	advance(sim2, 1)
	move(sim2, "b", [3, 1])
	advance(sim2, 2)
	var dict2: Dictionary = sim2.to_dict()
	for id: Variant in dict2.get("combatants", {}) as Dictionary:
		assert_false((dict2["combatants"][id] as Dictionary).has("facing"),
			"no facing key on a facing-untouched combatant (%s)" % id)
	for id: Variant in dict2.get("tick_snapshot", {}) as Dictionary:
		assert_false((dict2["tick_snapshot"][id] as Dictionary).has("facing"),
			"the tick snapshot never carries facing at all (%s)" % id)


func test_roundtrip_mid_fight_and_lockstep() -> void:
	var sim: CombatSim = make_sim(7)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "t", {"team": "enemies", "position": [0, 2]})
	declare(sim, "a", attack_action("crushed", 2, "t", "torso", {"cost": 2, "attack_range": 6}))
	# Mid-windup: a faces SE (5), t staged facing NW (2) — both non-default.
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "round-trip hash identical mid-windup (facing covered)")
	assert_eq(restored.combatants["a"].facing, 5, "the declared facing survived the trip")
	assert_eq(restored.combatants["t"].facing, 2, "the staged facing survived the trip")
	# Lockstep tail: the same facing-changing command on both sims.
	for target: CombatSim in [sim, restored] as Array[CombatSim]:
		target.apply_command({"type": "move", "actor": "t", "to": [1, 2]})
		target.apply_command({"type": "advance_tick"})
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")
	assert_eq(restored.combatants["t"].facing, sim.combatants["t"].facing, "identical facing on both timelines")


func test_determinism_facing_heavy_log_twice_same_hash() -> void:
	var hashes: Array[String] = []
	for _round: int in range(2):
		var sim: CombatSim = make_sim(4242)
		sim.apply_command({"type": "add_combatant", "combatant": {
			"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [3, 0]}})
		add_human(sim, "h1", {"team": "party", "position": [0, 0]})
		add_human(sim, "h2", {"team": "party", "position": [0, 1]})
		move(sim, "h1", [2, 0])
		ai_decide(sim, "mob")
		advance(sim, 1)
		declare(sim, "h1", {"kind": "grapple", "cost": 1, "target": "mob"})
		declare(sim, "h2", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, 1]})
		advance(sim, 1)
		ai_decide(sim, "mob")
		advance(sim, 2)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through the facing kit")


func test_view_combatants_carries_facing_additively() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, SimTestBase.load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "h1", "name": "h1", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [3, 0]}})
	var seen: Dictionary = {}
	for cd: Dictionary in game.view_combatants():
		seen[String(cd.get("id", ""))] = int(cd.get("facing", -1))
	assert_eq(int(seen.get("h1", -1)), 0, "the view carries the default facing")
	assert_eq(int(seen.get("mob", -1)), 3, "the view carries the staged facing (mob faces its opponent W)")
	game.free()
