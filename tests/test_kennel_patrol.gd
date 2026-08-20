extends SimTestBase
## R35 CONTENT HALF + THE RUN-LOOP WIRING (owner ruling 2026-08-20: "give the
## hounds patrol routes"). Two things ship together here on purpose:
##
##  (1) THE AUTHORED ROUTES — data/demo_run.json's kennel_gauntlet now gives
##      each war hound its OWN patrol route (per-INSTANCE data: a route is
##      position-specific and data/enemies.json cannot know the room, so the
##      war_hound TEMPLATE stays patrol-free — the "silently rewrite every
##      staged room" failure R35's opt-in design exists to prevent).
##  (2) THE RUN LOOP ENTERS ROOMS IN EXPLORATION — RunState.staging() carries
##      `opens_in` (default "exploration"), GameController issues the LOGGED
##      phase command after the add batch, and GameController.view_phase()
##      projects the mode for a driver/HUD. Without (2) the routes of (1)
##      could never execute: every room used to stage straight into combat.
##
## Pinned below: the authored routes load and normalize into
## CombatantState.patrol through the REAL staging path; each hound walks its
## OWN route across successive time steps; a patrolling hound acquires an
## approaching contestant and names SIGHT; a staged room really opens
## free-form and the fight starts on contact or the deliberate ENTER; the
## R29 hype chain carries across the new phase boundary; a combat-only room
## ("opens_in": "combat") is hash-identical to the pre-wiring engine; and the
## whole opening draws ZERO rng (twin-RNG state compare) and replays in
## lockstep.
##
## HONEST GAP, pinned rather than hidden (see the run_state.gd header and
## rules-addendum R35): the kennel's authored FIGHT staging puts a hound one
## hex from Imani inside its own cone, so the room's opening contact sweep
## fires on the SAME command that opens it. The exploration window is real but
## one command long, and the authored patrol therefore takes no beat in the
## seeded demo drive. Closing that needs an ENTRY staging distinct from the
## FIGHT staging — owner room-design work, not engine work.

const DEMO_RUN_PATH: String = "res://data/demo_run.json"

## The authored routes, verbatim — the pin that catches a silent data edit.
const HOUND_1_ROUTE: Array = [[2, 0], [-3, 0]]
const HOUND_2_ROUTE: Array = [[2, -2], [-2, -2], [-2, -4], [2, -4]]


# ---------------------------------------------------------------- plumbing

func _controller() -> Node:
	return (load("res://controller/game_controller.gd") as GDScript).new()


static func _demo_run() -> Dictionary:
	return (SimTestBase.load_json(DEMO_RUN_PATH) as Dictionary).get("run", {})


static func _room(key: String) -> Dictionary:
	for enc: Variant in _demo_run().get("encounters", []) as Array:
		if String((enc as Dictionary).get("key", "")) == key:
			return (enc as Dictionary).duplicate(true)
	return {}


## Stages ONE authored room through the real run path. The def's `exits` are
## dropped so the single-room list is a plain LINEAR run (the graph rules are
## test_dungeon_flow.gd's job); everything the story is about — enemies,
## overrides.patrol, party_positions, arena, opens_in — is verbatim.
func _stage_room(gc: Node, key: String, def_overrides: Dictionary = {}) -> Dictionary:
	var def: Dictionary = _room(key)
	def.erase("exits")
	def.merge(def_overrides, true)
	var run_def: Dictionary = _demo_run()
	gc.start_run(int(run_def.get("run_seed", 0)), run_def.get("party", []), [def],
		load_static_data())
	var events: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	return {"def": def, "events": events}


## A bare hound on an authored route, staged into a bare sim (no run layer).
func _add_hound(sim: CombatSim, id: String, pos: Array, route: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": "war_hound", "team": "enemies",
		"position": pos, "patrol": {"route": route.duplicate(true)}}})


## The kennel arena, verbatim off the authored def.
func _kennel_arena(sim: CombatSim) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": (_room("kennel_gauntlet").get("arena", {}) as Dictionary)})


func _positions(sim: CombatSim, ids: Array) -> Array:
	var out: Array = []
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[String(id)]
		out.append([c.position.x, c.position.y])
	return out


# ======================================================================
# (1) THE AUTHORED ROUTES LOAD
# ======================================================================

func test_the_authored_routes_reach_patrol_state_through_the_real_staging_path() -> void:
	var gc: Node = _controller()
	_stage_room(gc, "kennel_gauntlet")
	var h1: CombatantState = gc.sim.combatants["war_hound_1"]
	var h2: CombatantState = gc.sim.combatants["war_hound_2"]
	# The per-instance `overrides.patrol` really survives staging -> spec ->
	# Exploration.patrol_from_spec -> CombatantState.patrol.
	assert_eq(h1.patrol.get("route", []), HOUND_1_ROUTE,
		"hound 1 carries THE RUN route (post [2, 0] <-> the gate mouth [-3, 0])")
	assert_eq(h2.patrol.get("route", []), HOUND_2_ROUTE,
		"hound 2 carries THE NORTH PENS circuit")
	assert_eq(int(h1.patrol.get("index", -1)), 0, "the cycle cursor normalizes to the first post")
	assert_eq(int(h2.patrol.get("index", -1)), 0, "…on both hounds")
	assert_ne(h1.patrol.get("route", []), h2.patrol.get("route", []),
		"DIFFERENT routes — the pair reads as a pack with two jobs, not two clones")
	# The staged posts are unchanged by the row split (the KAN-4 hand-off pins
	# in test_run_state.gd / test_run_persistence.gd depend on them).
	assert_eq(h1.position, Vector2i(2, 0), "hound 1 still stages on its authored post")
	assert_eq(h2.position, Vector2i(2, -2), "hound 2 still stages on its authored post")
	# The party is untouched by the pass.
	for id: String in ["imani", "dario"]:
		assert_true((gc.sim.combatants[id] as CombatantState).patrol.is_empty(),
			"%s carries no patrol — contestants are never scenery" % id)
	# THE TEMPLATE STAYS CLEAN: no other authored room gets a pacing hound.
	var corridor: Node = _controller()
	_stage_room(corridor, "service_corridor")
	for id: Variant in corridor.sim.combatants.keys():
		assert_true((corridor.sim.combatants[id] as CombatantState).patrol.is_empty(),
			"%s: no seeded enemy outside the kennel patrols (opt-in per-INSTANCE data)" % String(id))
	gc.free()
	corridor.free()


# ======================================================================
# (2) EACH HOUND WALKS ITS OWN ROUTE
# ======================================================================

func test_each_hound_walks_its_own_authored_route_across_time_steps() -> void:
	# The authored kennel arena + the authored posts + the authored routes,
	# with NO contestant on the board — so nothing can make contact and the
	# patrol beat is the only thing happening. (The seeded demo's own drive
	# cannot show this: its fight staging is already nose-to-nose. See the
	# header's HONEST GAP.)
	var sim: CombatSim = make_sim()
	_kennel_arena(sim)
	_add_hound(sim, "war_hound_1", [2, 0], HOUND_1_ROUTE)
	_add_hound(sim, "war_hound_2", [2, -2], HOUND_2_ROUTE)
	sim.apply_command({"type": "phase", "set": "exploration"})
	var trail_1: Array = []
	var trail_2: Array = []
	for _i: int in range(6):
		sim.apply_command({"type": "advance_tick"})
		var pair: Array = _positions(sim, ["war_hound_1", "war_hound_2"])
		trail_1.append(pair[0])
		trail_2.append(pair[1])
	# HOUND 1 — the run: one hex per beat, west down the r = 0 lane, arriving
	# at the gate mouth on beat 5 and turning back east on beat 6 (the cycle
	# wraps: a two-point route IS pacing).
	assert_eq(trail_1, [[1, 0], [0, 0], [-1, 0], [-2, 0], [-3, 0], [-2, 0]],
		"hound 1 paces THE RUN one hex per exploration time step and turns at the gate mouth")
	# HOUND 2 — the north pens: west along r = -2, then NORTH at [-2, -2] onto
	# the second leg. A different lane and a different shape, same beat.
	assert_eq(trail_2, [[1, -2], [0, -2], [-1, -2], [-2, -2], [-2, -3], [-2, -4]],
		"hound 2 walks its own circuit — west along the pens, then north up the second leg")
	assert_ne(trail_1, trail_2, "the pack does not move as one body")
	# The cursors advanced on the state, not just on the board.
	assert_eq(int((sim.combatants["war_hound_1"] as CombatantState).patrol.get("index", -1)), 0,
		"hound 1's cursor wrapped back to post 0 after touching the gate mouth")
	assert_eq(int((sim.combatants["war_hound_2"] as CombatantState).patrol.get("index", -1)), 2,
		"hound 2 is walking to its THIRD post")
	# Facing follows every step — the whole point of the ruling (their
	# eyelines move with them).
	assert_eq((sim.combatants["war_hound_1"] as CombatantState).facing,
		HexGeometry.direction_index(Vector2i(-3, 0), Vector2i(-2, 0)),
		"hound 1 faces along its last step (back east up the run)")


func test_a_patrolling_hound_acquires_an_approaching_contestant_and_names_sight() -> void:
	# The hounds are added FIRST, so their staging facing is the no-opponent
	# default (east) — they are looking up the pens, away from the gate. A
	# contestant then stands still in the run lane, WEST of hound 1: behind
	# its eyeline, so the room opens with no contact at all.
	var sim: CombatSim = make_sim()
	_kennel_arena(sim)
	_add_hound(sim, "war_hound_1", [2, 0], HOUND_1_ROUTE)
	add_human(sim, "imani", {"team": "party", "position": [-2, 0]})
	var opened: Array[Dictionary] = sim.apply_command({"type": "phase", "set": "exploration"})
	assert_event(opened, "exploration_started", "the room opens free-form")
	assert_no_event(opened, "contact", "nobody has been seen yet — the cone points the other way")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "still walking")
	# The contestant NEVER MOVES. The room comes to her: hound 1 walks its
	# authored route west down the run, its cone swinging with it, and finds
	# her. (R35's ruled case — "standing still never freezes the room".)
	var found: Dictionary = {}
	var beats: int = 0
	for _i: int in range(6):
		if sim.phase == Exploration.PHASE_COMBAT:
			break
		beats += 1
		var events: Array[Dictionary] = sim.apply_command({"type": "advance_tick"})
		if has_event(events, "contact"):
			found = first_event(events, "contact")
			assert_eq(String(first_event(events, "combat_started").get("reason", "")), "contact",
				"the clock starts on the involuntary way in")
	assert_false(found.is_empty(), "the patrolling hound made contact inside its own route")
	assert_eq(String(found.get("by", "")), "war_hound_1", "the PATROLLER is the detector")
	assert_eq(String(found.get("target", "")), "imani", "…and the standing contestant is who it found")
	assert_eq(String(found.get("sense", "")), "sight", "SIGHT — a moving cone acquired her (R20/R30)")
	assert_eq(beats, 2, "two beats: hound Mind 1 = sight range 2, so [0, 0] is where she enters the cone")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "the kennel gauntlet is on")
	assert_eq((sim.combatants["imani"] as CombatantState).position, Vector2i(-2, 0),
		"she never took a step — the patrol is what closed the distance")
	# CONTRAST: the identical board with the route stripped never finds her.
	var control: CombatSim = make_sim()
	_kennel_arena(control)
	control.apply_command({"type": "add_combatant", "combatant": {
		"id": "war_hound_1", "name": "war_hound_1", "enemy": "war_hound",
		"team": "enemies", "position": [2, 0]}})
	add_human(control, "imani", {"team": "party", "position": [-2, 0]})
	control.apply_command({"type": "phase", "set": "exploration"})
	advance(control, 6)
	assert_eq(control.phase, Exploration.PHASE_EXPLORATION,
		"a statue hound never finds her — the ROUTE is what made contact happen")


# ======================================================================
# (3) THE RUN LOOP ENTERS ROOMS IN EXPLORATION
# ======================================================================

func test_a_staged_room_opens_free_form_and_the_phase_command_is_logged() -> void:
	var gc: Node = _controller()
	var staged: Dictionary = _stage_room(gc, "brood_landing")
	# The entry room opens OUT OF COMBAT: nobody's staged eyeline is on a
	# contestant, so the exploration window survives the opening sweep.
	assert_eq(gc.sim.phase, Exploration.PHASE_EXPLORATION, "the room is WALKED, not dropped into")
	assert_eq(String(gc.run.staging().get("opens_in", "")), "exploration",
		"staging() carries the decision (default — no authored room sets the key)")
	# It is a real, LOGGED sim command — the encounter log's first entry — not
	# a state poke, so a replay from the staged checkpoint reproduces it.
	assert_eq(gc.command_log.size(), 1, "exactly one command logged at staging")
	assert_eq(String((gc.command_log[0] as Dictionary).get("type", "")), "phase",
		"…and it is the phase command")
	assert_eq(String((gc.command_log[0] as Dictionary).get("set", "")), "exploration", "set to exploration")
	# Clock-BOUND commands reject as a family while the room is walked...
	assert_rejected(gc.apply_command({"type": "declare_action", "actor": "imani",
		"action": attack_action("crushed", 3, "roach_dog_1", "carapace")}),
		"clock_stopped", "no turn order exists until the fight starts (R34's legacy reason name)")
	# THE DELIBERATE ENTRY (the mockup's "ENTER > <route>" commit), taken on
	# the freshly opened room so nothing else can have started the fight.
	var entered: Array[Dictionary] = gc.apply_command({"type": "phase", "set": "combat"})
	assert_eq(String(assert_event(entered, "combat_started", "the ENTER commit").get("reason", "")),
		"deliberate", "walking in on purpose is never reported as contact")
	assert_no_event(entered, "contact", "…and emits no contact event")
	assert_eq(gc.sim.phase, Exploration.PHASE_COMBAT, "the clock is running")
	# Staging is untouched by the wiring: the room's own content is all there.
	assert_true(gc.sim.combatants.has("roach_dog_1") and gc.sim.combatants.has("imani"),
		"the add batch ran exactly as before the wiring")
	gc.free()

	# ...and on a fresh copy of the same room, the FREE-FORM WALK really works
	# instead of the R3 movement economy: no slot, no Moments, no tick.
	var walker: Node = _controller()
	_stage_room(walker, "brood_landing")
	var before_tick: int = walker.sim.clock.tick
	var walked: Array[Dictionary] = walker.apply_command({
		"type": "move", "actor": "dario", "to": [0, 2]})
	var moved: Dictionary = assert_event(walked, "moved", "the party walks freely")
	assert_true(bool(moved.get("free", false)), "the exploration walk costs nothing")
	assert_true(bool(moved.get("exploration", false)), "…and is flagged as the free-form walk")
	assert_eq(walker.sim.clock.tick, before_tick, "a walk advances no tick of its own")
	assert_eq((walker.sim.combatants["dario"] as CombatantState).free_actions_used, 0,
		"…and spends no free-action budget entry")
	walker.free()


func test_the_kennels_own_staging_makes_contact_on_the_opening_sweep() -> void:
	# THE HONEST PIN (the header's gap). The kennel's FIGHT staging puts
	# war_hound_1 one hex from Imani, inside its own cone, so the contact
	# sweep that runs at the end of the phase command finds her immediately:
	# the room opens free-form and is caught in the same breath. That is R34
	# working as ruled — and it is exactly why the authored patrol takes no
	# beat in the seeded demo until the room authors an ENTRY staging.
	var gc: Node = _controller()
	var staged: Dictionary = _stage_room(gc, "kennel_gauntlet")
	assert_eq(String(gc.run.staging().get("opens_in", "")), "exploration",
		"the kennel opens free-form like every other room")
	var log_events: Array[Dictionary] = gc.apply_command({"type": "phase", "set": "combat"})
	assert_rejected(log_events, "already_in_phase",
		"…and the opening sweep already closed the window: the fight is on")
	assert_eq(gc.sim.phase, Exploration.PHASE_COMBAT, "contact, not a walk")
	# The routes are LOADED all the same — content and wiring are independent.
	assert_eq((gc.sim.combatants["war_hound_1"] as CombatantState).patrol.get("route", []),
		HOUND_1_ROUTE, "the authored route is on the state whether or not it gets a beat")
	gc.free()


## THE CONTENT FACT, pinned so a re-authored staging announces itself: which
## of the four seeded rooms actually SURVIVE their opening contact sweep. Every
## room opens free-form; whether the window lasts longer than one command is a
## property of the room's own FIGHT staging, not of the wiring. Two of four
## survive today — and the two that do not are exactly the two whose staging
## puts a mob's eyeline on a contestant at range 0-2.
func test_which_authored_rooms_survive_their_opening_contact_sweep() -> void:
	var expected: Dictionary = {
		"brood_landing": Exploration.PHASE_EXPLORATION,
		"kennel_gauntlet": Exploration.PHASE_COMBAT,
		"service_corridor": Exploration.PHASE_EXPLORATION,
		"incinedile_den": Exploration.PHASE_COMBAT,
	}
	for enc: Variant in _demo_run().get("encounters", []) as Array:
		var key := String((enc as Dictionary).get("key", ""))
		var gc: Node = _controller()
		_stage_room(gc, key)
		assert_eq(String(gc.run.staging().get("opens_in", "")), "exploration",
			"%s opens free-form like every room (no def authors the opt-out)" % key)
		assert_eq(gc.sim.phase, String(expected[key]),
			("%s: the opening sweep %s" % [key,
				"left the window open — the party really walks this room"
				if String(expected[key]) == Exploration.PHASE_EXPLORATION
				else "caught them on the spot (a staged eyeline is already on a contestant)"]))
		gc.free()


func test_a_scripted_ambush_room_still_opens_in_combat_byte_identically() -> void:
	# The opt-out: a def authoring "opens_in": "combat" gets the pre-wiring
	# engine verbatim — NO phase command is issued at all, so the sim never
	# leaves its default combat phase and the `phase` key never serializes.
	var ambush: Node = _controller()
	_stage_room(ambush, "brood_landing", {"opens_in": "combat"})
	assert_eq(ambush.sim.phase, Exploration.PHASE_COMBAT, "the ambush room drops you into the fight")
	assert_eq(ambush.command_log.size(), 0, "no phase command was issued (a provable no-op)")
	assert_false((ambush.sim.to_dict() as Dictionary).has("phase"),
		"…so the phase key never appears — legacy saves and hashes untouched")
	var ambush_hash: String = ambush.sim.state_hash()

	# THE BAR: the default (exploration) room, entered deliberately with no
	# other command in between, is HASH-IDENTICAL to the ambush room. The
	# whole opening phase round-trip therefore costs the fight nothing.
	var walked_in: Node = _controller()
	_stage_room(walked_in, "brood_landing")
	assert_eq(walked_in.sim.phase, Exploration.PHASE_EXPLORATION, "precondition: it opened free-form")
	walked_in.apply_command({"type": "phase", "set": "combat"})
	assert_eq(walked_in.sim.state_hash(), ambush_hash,
		"a combat-only fight is byte-identical whichever way the room opened")
	assert_false((walked_in.sim.to_dict() as Dictionary).has("phase"),
		"the phase key is gone again the moment combat starts (the only-when-set pin)")
	ambush.free()
	walked_in.free()


func test_view_phase_projects_the_mode_for_the_driver() -> void:
	var gc: Node = _controller()
	assert_true(gc.view_phase().is_empty(), "{} before a fight is staged")
	_stage_room(gc, "kennel_gauntlet", {"opens_in": "combat"})
	var in_combat: Dictionary = gc.view_phase()
	assert_eq(String(in_combat.get("phase", "")), "combat", "the combat readout")
	assert_false(bool(in_combat.get("exploring", true)), "not exploring")
	assert_eq(String(in_combat.get("label", "")), "IN COMBAT", "the HUD copy")
	assert_true(bool(in_combat.get("turn_order", false)), "combat has turn order")
	assert_true(bool(in_combat.get("moment_costs", false)), "…and Moment costs")
	assert_true((in_combat.get("enter_command", {}) as Dictionary).is_empty(),
		"no ENTER button while already in the fight")
	assert_eq((in_combat.get("patrolling", []) as Array).size(), 0, "no patrol beat exists in combat")

	# The exploration readout — the mockups' "OUT OF COMBAT / time runs /
	# PAUSE" strip, plus the ENTER command and the living-room roster.
	var walking: Node = _controller()
	var sim: CombatSim = make_sim()
	_kennel_arena(sim)
	_add_hound(sim, "war_hound_1", [2, 0], HOUND_1_ROUTE)
	_add_hound(sim, "war_hound_2", [2, -2], HOUND_2_ROUTE)
	walking.sim = sim
	sim.apply_command({"type": "phase", "set": "exploration"})
	var out: Dictionary = walking.view_phase()
	assert_eq(String(out.get("phase", "")), "exploration", "the exploration readout")
	assert_true(bool(out.get("exploring", false)), "exploring")
	assert_eq(String(out.get("label", "")), "OUT OF COMBAT", "the mockup's own copy")
	assert_true(bool(out.get("time_runs", false)),
		"TIME RUNS in both phases (R34's TIME AMENDMENT — never a frozen clock)")
	assert_false(bool(out.get("turn_order", true)), "no turn order out of combat")
	assert_false(bool(out.get("moment_costs", true)), "nothing costs Moments out of combat")
	assert_eq(String((out.get("time_step", {}) as Dictionary).get("type", "")), "advance_tick",
		"the driver's beat is the ONE real tick path — and out of combat it IS the patrol beat")
	assert_eq(String(out.get("pause", "")), "driver",
		"PAUSE IS NOT SIM STATE: the driver pauses by not issuing the time step")
	assert_eq((out.get("enter_command", {}) as Dictionary),
		{"type": "phase", "set": "combat"}, "the ENTER > <route> commit, ready to issue")
	assert_eq(out.get("patrolling", []), ["war_hound_1", "war_hound_2"],
		"both hounds are live scenery this room — sorted ids")
	assert_eq(int(out.get("tick", -1)), sim.clock.tick, "one clock readout, shared by both phases")
	# A downed patroller drops off the living-room roster.
	(sim.combatants["war_hound_2"] as CombatantState).alive = false
	assert_eq(walking.view_phase().get("patrolling", []), ["war_hound_1"], "a dead hound is not patrolling")
	gc.free()
	walking.free()


# ======================================================================
# (4) THE R29 HYPE CHAIN ACROSS THE NEW PHASE BOUNDARY
# ======================================================================

func test_the_hype_chain_carries_across_the_exploration_boundary() -> void:
	# decision #32: a chained room opens at floor(retention% x the previous
	# room's ending meter). Rooms now open in EXPLORATION, so the retained
	# meter has to survive the phase command, the free-form walk and the entry
	# into combat — R29 calls the chain "back-to-back glue, not a rest", and
	# the new boundary must not eat it.
	# The first room is won on a BARE RunState (the controller's end_encounter
	# funnel insists on a real resolved fight; the chain math is what is under
	# test here, not the fight), then restore_run hands the live controller the
	# chained checkpoint — the same public path a resumed save takes.
	var run_def: Dictionary = _demo_run()
	var room_a: Dictionary = _room("brood_landing")
	room_a.erase("exits")
	room_a.erase("recruit_offer")
	room_a.erase("allies")
	var room_b: Dictionary = room_a.duplicate(true)
	room_b["key"] = "brood_landing_b"
	var bare: RunState = RunState.new()
	bare.apply_command({"type": "start_run", "seed": int(run_def.get("run_seed", 0)),
		"party": run_def.get("party", []), "encounters": [room_a, room_b]})
	bare.apply_command({"type": "begin_encounter"})
	bare.apply_command({"type": "end_encounter", "outcome": "WIN", "carried": {}, "hype_meter": 137})
	var want: int = bare.chain_hype_start()
	assert_true(want > 0, "precondition: the chain really retained a meter (got %d)" % want)

	var gc: Node = _controller()
	gc.restore_run(bare.to_dict(), {}, load_static_data())
	var started: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(started, "run_encounter_started", "the next link starts")
		.get("hype_start", -1)), want, "the run event still announces the retained meter")
	assert_eq(gc.sim.phase, Exploration.PHASE_EXPLORATION,
		"precondition: the chained room really opened free-form")
	assert_eq(gc.sim.hype.meter, want,
		"the retained meter is on the live engine the moment the room OPENS — the phase "
		+ "command did not reset it")
	var want_band: String = "cold"
	for entry: Variant in HypeEngine.BANDS:
		if want >= int((entry as Array)[1]):
			want_band = String((entry as Array)[0])
			break
	assert_eq(String(gc.sim.hype.band), want_band,
		"…with its band re-derived exactly as the pre-wiring staging did")
	# It survives the exploration commands themselves...
	gc.apply_command({"type": "move", "actor": "dario", "to": [0, 2]})
	assert_true(gc.sim.hype.meter >= want,
		"a free-form walk can only ADD to the chained meter (R35 spectacle), never reset it")
	var carried_in: int = gc.sim.hype.meter
	# ...and rides into the fight across the deliberate ENTER.
	deliberate_enter(gc)
	assert_eq(gc.sim.phase, Exploration.PHASE_COMBAT, "the fight is on")
	assert_eq(gc.sim.hype.meter, carried_in,
		"the chain arrives at the fight intact — the phase boundary is glue, not a rest")
	gc.free()


# ======================================================================
# (5) DETERMINISM
# ======================================================================

func test_the_opening_phase_and_the_patrol_beat_draw_zero_rng() -> void:
	# TWIN-RNG STATE COMPARE: two identically-seeded sims, one of which opens
	# free-form and runs the authored kennel patrol to CONTACT, inside one
	# Clock (so no Clock-reset goal draw fires). Every stream must be level.
	var quiet := CombatSim.new(4711, SimTestBase.load_static_data())
	var busy := CombatSim.new(4711, SimTestBase.load_static_data())
	for sim: CombatSim in [quiet, busy]:
		sim.apply_command({"type": "set_arena", "arena": (_room("kennel_gauntlet").get("arena", {}) as Dictionary)})
		_add_hound(sim, "war_hound_1", [2, 0], HOUND_1_ROUTE)
		add_human(sim, "imani", {"team": "party", "position": [-2, 0]})
	assert_eq(busy.rng.state, quiet.rng.state, "twins start level (action rng)")

	_run_authored_patrol(busy)
	assert_true(busy.clock.tick < Clock.TICKS_PER_CLOCK, "the scenario stayed inside one Clock")
	assert_eq(busy.phase, Exploration.PHASE_COMBAT, "the scenario really ended in contact")
	assert_eq(busy.rng.state, quiet.rng.state, "action RNG untouched by the opening + the patrol")
	assert_eq(busy.ai.ai_rng.state, quiet.ai.ai_rng.state, "AI RNG untouched")
	assert_eq(busy.hype.goal_rng.state, quiet.hype.goal_rng.state, "crowd-goal RNG untouched")

	# LOCKSTEP: same seed + same command log = same hash.
	var replay := CombatSim.new(4711, SimTestBase.load_static_data())
	replay.apply_command({"type": "set_arena", "arena": (_room("kennel_gauntlet").get("arena", {}) as Dictionary)})
	_add_hound(replay, "war_hound_1", [2, 0], HOUND_1_ROUTE)
	add_human(replay, "imani", {"team": "party", "position": [-2, 0]})
	_run_authored_patrol(replay)
	assert_eq(replay.state_hash(), busy.state_hash(), "identical command logs replay identically")

	# ...and a mid-patrol save resumes the identical walk (the route cursor
	# and the anchor are serialized state, not derived from the log tail).
	var mid := CombatSim.new(4711, SimTestBase.load_static_data())
	mid.apply_command({"type": "set_arena", "arena": (_room("kennel_gauntlet").get("arena", {}) as Dictionary)})
	_add_hound(mid, "war_hound_1", [2, 0], HOUND_1_ROUTE)
	add_human(mid, "imani", {"team": "party", "position": [-2, 0]})
	mid.apply_command({"type": "phase", "set": "exploration"})
	mid.apply_command({"type": "advance_tick"})
	var resumed: CombatSim = CombatSim.from_dict(mid.to_dict())
	assert_eq(resumed.phase, Exploration.PHASE_EXPLORATION, "the phase round-trips")
	assert_eq((resumed.combatants["war_hound_1"] as CombatantState).patrol,
		(mid.combatants["war_hound_1"] as CombatantState).patrol, "the route + cursor round-trip")
	mid.apply_command({"type": "advance_tick"})
	resumed.apply_command({"type": "advance_tick"})
	assert_eq(resumed.state_hash(), mid.state_hash(), "the resumed walk lands on the same hex")


## The scenario the twin-RNG pin runs on `busy`/`replay`: open free-form, then
## time-step the authored route until the hound's own cone finds the standing
## contestant. Command-identical every call.
func _run_authored_patrol(sim: CombatSim) -> void:
	sim.apply_command({"type": "phase", "set": "exploration"})
	for _i: int in range(4):
		if sim.phase == Exploration.PHASE_COMBAT:
			return
		sim.apply_command({"type": "advance_tick"})
