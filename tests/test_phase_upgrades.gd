extends SimTestBase
## The Incine-Dile phase upgrades are REAL (wave 2d — rules-addendum R11 #20).
## The authored per-phase `behavior.upgrades` STRINGS are the source of truth,
## parsed by EnemyAI.UPGRADE_EFFECTS into effect keys; upgrades ACCUMULATE
## (union of every entered phase's list) and derive from current_phase — no new
## serialized state. Under test:
##  * "death spin grab range +1" (phase 3+) — the grab reaches 2 hexes and
##    DRAGS the victim adjacent first (blocked pull = honest failure).
##  * "death spin costs 2 moments" (phase 5) — chew+spin merge into ONE beat:
##    grab then chew+spin, 2 Moments total, one less counterplay Moment
##    (PROVISIONAL model, R11 #20).
##  * "dash can change direction mid-run" (phase 4+) — the ONE-bend charge
##    lane; all wave-2a/2b lane rules apply to the BENT lane; the R22 sidestep
##    steps off the dodger's SEGMENT, the knock-aside off the FULL bent lane.
##  * "network fully exposed" (phase 4+) — the phase-4 valve never re-hides
##    the network (the phase-2 valve still does).
##  * "flamethrower tracks closest target" (phase 5) — the cone AIMS at the
##    nearest opponent instead of the biggest crowd (toward selection only).
##  * "dash bounces between walls up to 2 bounces" / "flamethrower pops trash
##    cans instantly" — REAL since wave 3d (KAN-5 arenas), but ARENA-GATED:
##    they map to effects (dash_wall_bounce / cans_pop_instantly) yet stay
##    behaviorally inert WITHOUT an arena — no walls, no cans, byte-identical
##    fights (the flipped inert pin below; mechanics in tests/test_arena.gd).


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold (test_incinedile
## pattern) — staging hits stay pin-exact without consuming the AI stream.
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


func boss_state(sim: CombatSim, id: String = "boss") -> CombatantState:
	return sim.combatants.get(id)


## A boss at `phase` (state set directly, the test_death_spin pattern) + one
## victim at `victim_pos`. Single opponent = the cone can never preempt.
func stage_at_phase(phase: int, victim_pos: Array = [1, 0], victim_traits: Dictionary = {}) -> CombatSim:
	var sim: CombatSim = make_sim()
	var stat_block: Dictionary = {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}
	stat_block.merge(victim_traits, true)
	add_human(sim, "vic", {"team": "party", "position": victim_pos, "traits": stat_block})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	sim.ai.boss_phase["boss"] = phase
	return sim


func spin_state(sim: CombatSim) -> Dictionary:
	return sim.ai.death_spins.get("boss", {})


# ---------------------------------------------------------- the upgrade reader

func test_reader_maps_authored_strings_and_accumulates_by_phase() -> void:
	# The authored data is the source of truth — pin the exact strings first,
	# so a data edit surfaces here instead of silently unmapping an effect.
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	var phases: Array = []
	for entry: Variant in enemies:
		if String((entry as Dictionary).get("key", "")) == "incinedile":
			phases = (entry as Dictionary).get("phases", [])
	var authored: Dictionary = {}
	for phase_entry: Variant in phases:
		var pe: Dictionary = phase_entry
		authored[int(pe.get("phase_number", 0))] = (pe.get("behavior", {}) as Dictionary).get("upgrades", [])
	assert_eq(authored.get(3, []), ["flamethrower pops trash cans instantly",
		"dash bounces between walls up to 2 bounces", "death spin grab range +1"],
		"phase-3 authored upgrade strings pinned")
	assert_eq(authored.get(4, []), ["network fully exposed", "dash can change direction mid-run"],
		"phase-4 authored upgrade strings pinned")
	assert_eq(authored.get(5, []), ["flamethrower tracks closest target", "death spin costs 2 moments"],
		"phase-5 authored upgrade strings pinned")
	# The reader: effects activate AT their authored phase and ACCUMULATE.
	# Wave 3d: the phase-3 set now includes the two arena-gated effects — they
	# report ACTIVE here (the reader is arena-blind) and gate on the arena at
	# the mechanics layer (tests/test_arena.gd).
	var expected: Dictionary = {
		1: [], 2: [],
		3: ["grab_range_plus_1", "dash_wall_bounce", "cans_pop_instantly"],
		4: ["grab_range_plus_1", "dash_wall_bounce", "cans_pop_instantly",
			"network_stays_exposed", "dash_bend"],
		5: ["grab_range_plus_1", "dash_wall_bounce", "cans_pop_instantly",
			"network_stays_exposed", "dash_bend",
			"cone_track_closest", "spin_two_moments"],
	}
	for phase: int in [1, 2, 3, 4, 5]:
		var sim: CombatSim = stage_at_phase(phase)
		var active: Dictionary = sim.ai.upgrades_active(boss_state(sim))
		var keys: Array = active.keys()
		keys.sort()
		var want: Array = (expected[phase] as Array).duplicate()
		want.sort()
		assert_eq(keys, want, "phase %d active effect set" % phase)
		assert_eq(sim.ai.grab_range(boss_state(sim)), 2 if phase >= 3 else 1,
			"phase %d grab range" % phase)


func test_unknown_strings_stay_inert_and_arena_upgrades_gate_on_the_arena() -> void:
	# An arbitrary unknown string is still a DATA-ONLY no-op: visible in data,
	# never reported, nothing executes. The two formerly-inert strings now MAP
	# (wave 3d un-inerted them) — but WITHOUT an arena they stay behaviorally
	# inert: no walls -> no bounces (a bounce-marked declare rejects), no cans
	# -> nothing pops, and the sim serializes with the exact legacy shape (no
	# "arena" key), so a no-arena fight is byte-identical to pre-arena play.
	var sim: CombatSim = make_sim()
	add_human(sim, "vic", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge(), "phases": [
		{"phase_number": 1, "name": "Synthetic", "behavior": {
			"abilities": ["flamethrower", "dash", "death_spin"],
			"upgrades": ["totally unknown future upgrade", "death spin grab range +1",
				"dash bounces between walls up to 2 bounces"],
		}},
	]})
	var active: Dictionary = sim.ai.upgrades_active(boss_state(sim))
	var keys: Array = active.keys()
	keys.sort()
	assert_eq(keys, ["dash_wall_bounce", "grab_range_plus_1"],
		"unknown strings report nothing; mapped strings (bounce included) parse")
	assert_true(EnemyAI.UPGRADE_EFFECTS.has("dash bounces between walls up to 2 bounces"),
		"wall bounces are mapped now (KAN-5 arenas, wave 3d)")
	assert_true(EnemyAI.UPGRADE_EFFECTS.has("flamethrower pops trash cans instantly"),
		"the trash-can pop is mapped now (KAN-5 arenas, wave 3d)")
	# The ARENA gate is what keeps a no-arena fight identical to before: even
	# with dash_wall_bounce active, a bounce-marked lane rejects without walls.
	assert_rejected(declare(sim, "boss", {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 6,
		"targets": [{"id": "vic", "part": "torso"}],
		"area_shape": {"kind": "line", "lane": [[0, 0], [1, 0]], "bounces": [[1, 0]]},
	}), "bounce_not_available", "no arena = no walls = no bounces (the inert continuation)")
	assert_false(sim.to_dict().has("arena"),
		"and the no-arena sim keeps the legacy serialized shape")


# ---------------------------------------------------- grab range +1 (phase 3+)

func test_range_two_grab_drags_the_victim_adjacent_first() -> void:
	var sim: CombatSim = stage_at_phase(3, [2, 0])
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "grab", "phase 3: distance 2 is grab prey")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "grapple_started", "the hold lands")
	var grab: Dictionary = assert_event(resolved, "death_spin_grab", "the sequence opens")
	assert_true(bool(grab.get("dragged", false)), "the range-2 grab DRAGS")
	assert_eq(grab.get("dragged_from", []), [2, 0], "from the victim's hex")
	assert_eq(grab.get("dragged_to", []), [1, 0], "one hex along the line, adjacent to the boss")
	assert_eq((sim.combatants["vic"] as CombatantState).position, Vector2i(1, 0),
		"the victim was actually pulled")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "boss", "and held")
	assert_eq(int(spin_state(sim).get("beat", 0)), 1, "beat 1 armed — the sequence continues normally")
	# An adjacent grab still reports dragged=false (no pull needed).
	var sim2: CombatSim = stage_at_phase(3, [1, 0])
	ai_decide(sim2, "boss")
	var grab2: Dictionary = assert_event(advance(sim2, 1), "death_spin_grab", "adjacent grab")
	assert_false(bool(grab2.get("dragged", true)), "no drag on an already-adjacent victim")


func test_blocked_pull_hex_fails_the_grab_honestly() -> void:
	# A body on the pull hex: the AI never decides the grab, a hand-built
	# declare rejects, and a pull blocked BETWEEN declare and resolution
	# invalidates live (no hold, no sequence).
	var sim: CombatSim = stage_at_phase(3, [2, 0])
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "walldog", "name": "walldog", "enemy": "roach_dog",
		"team": "enemies", "position": [1, 0],
	}})
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_ne(String(decision.get("choice", "")), "grab",
		"the AI never decides a grab whose pull is blocked")
	# Command surface: the hand-built range-2 grab rejects at declare.
	assert_rejected(declare(sim, "boss", {
		"kind": "grapple", "target": "vic", "cost": 1,
		"death_spin": true, "grab_part": "right_hand",
	}), "pull_blocked", "a blocked drag hex cannot be grabbed through")
	# Live re-check: pull free at declare, blocked before resolution.
	var sim2: CombatSim = stage_at_phase(3, [2, 0])
	add_human(sim2, "runner", {"team": "party", "position": [0, 1]})
	assert_event(declare(sim2, "boss", {
		"kind": "grapple", "target": "vic", "cost": 1,
		"death_spin": true, "grab_part": "right_hand",
	}), "action_declared", "pull hex free at declare — the grab schedules")
	assert_event(sim2.apply_command({"type": "move", "actor": "runner", "to": [1, 0]}),
		"moved", "a runner blocks the pull hex mid-tick")
	var resolved: Array[Dictionary] = advance(sim2, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated", "the grab fails honestly")
	assert_eq(String(invalidated.get("reason", "")), "pull_blocked", "on the live pull re-check")
	assert_no_event(resolved, "grapple_started", "no hold lands")
	assert_no_event(resolved, "death_spin_grab", "no sequence arms")
	assert_eq((sim2.combatants["vic"] as CombatantState).grappled_by, "", "the victim stays free")
	assert_eq((sim2.combatants["vic"] as CombatantState).position, Vector2i(2, 0), "and unmoved")


func test_grab_range_stays_one_below_phase_three() -> void:
	var sim: CombatSim = stage_at_phase(1, [2, 0])
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_ne(String(decision.get("choice", "")), "grab", "phase 1: distance 2 is out of reach")
	assert_rejected(declare(sim, "boss", {
		"kind": "grapple", "target": "vic", "cost": 1,
		"death_spin": true, "grab_part": "right_hand",
	}), "out_of_range", "the hand-built range-2 grab rejects below phase 3")
	# The plain R9 grapple NEVER gains the upgrade range — boss at phase 3+,
	# non-death-spin grapple at distance 2 still rejects at range 1.
	var sim2: CombatSim = stage_at_phase(3, [2, 0])
	assert_rejected(declare(sim2, "boss", {"kind": "grapple", "target": "vic", "cost": 1}),
		"out_of_range", "the upgrade widens the DEATH-SPIN grab only, not generic R9")


# ------------------------------------------- death spin costs 2 moments (phase 5)

func test_phase_five_spin_is_two_moments_grab_then_merged_chew_spin() -> void:
	var sim: CombatSim = stage_at_phase(5, [1, 0], {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3})
	ai_decide(sim, "boss")
	var grab_tick: int = sim.clock.tick
	advance(sim, 1)
	assert_eq(int(spin_state(sim).get("beat", 0)), 1, "beat 1 armed at the grab")
	# The continuation is the MERGED beat — never a separate chew at phase 5.
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "spin", "phase 5: chew+spin merge into ONE beat")
	assert_ne(String(decision.get("choice", "")), "chew", "no separate chew Moment")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var chew: Dictionary = assert_event(resolved, "death_spin_chew", "the chew half still happens")
	assert_true(bool(chew.get("merged", false)), "flagged as the merged beat")
	assert_eq(chew.get("arms", []), ["left_arm", "right_arm"], "both arms chewed")
	var arm_hits: Dictionary = {}
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		arm_hits[String(hit.get("part", ""))] = int(hit.get("amount", -1))
	assert_eq(arm_hits.get("left_arm", -1), 4, "chew nets 4 on the left arm (same R14 math as 3-beat)")
	assert_eq(arm_hits.get("right_arm", -1), 4, "chew nets 4 on the right arm")
	assert_eq(arm_hits.get("torso", -1), 10, "the spin-kill nets 10 through the gate, same beat")
	var died: Dictionary = assert_event(resolved, "combatant_died", "the merged beat kills")
	assert_eq(String(died.get("combatant", "")), "vic", "the held victim")
	var kill: Dictionary = assert_event(resolved, "death_spin_kill", "the sequence closes")
	assert_eq(kill.get("flung_to", []), [4, 0], "the fling geometry is unchanged")
	assert_eq(int(kill.get("tick", -1)), grab_tick + 1,
		"TWO Moments total: grab on one tick, chew+spin on the very next")
	assert_true(spin_state(sim).is_empty(), "sequence over")
	assert_eq(boss_state(sim).grappling, "", "hold released by the finisher")


func test_phase_five_release_on_five_still_works_in_the_shrunk_window() -> void:
	# The single counterplay Moment between grab and merged beat: an ally hit
	# netting 5 resolves before the same-tick merged beat (declaration order)
	# — the jaws close on air, the victim keeps both arms and their life.
	var sim: CombatSim = stage_at_phase(5, [1, 0])
	add_human(sim, "ally", {"team": "party", "position": [-3, 0]})
	ai_decide(sim, "boss")
	advance(sim, 1)  # grab landed
	declare(sim, "ally", attack_action("crushed", 7, "boss", "right_leg", {"attack_range": 3}))
	ai_decide(sim, "boss")  # the merged beat is declared — and will fizzle
	var resolved: Array[Dictionary] = advance(sim, 1)
	var released: Dictionary = assert_event(resolved, "death_spin_released", "net 5 forces the release")
	assert_eq(int(released.get("hit", 0)), 5, "the qualifying hit")
	assert_event(resolved, "action_invalidated", "the merged beat closes on air (grip_lost)")
	assert_no_event(resolved, "death_spin_kill", "no kill")
	assert_no_event(resolved, "death_spin_chew", "no chew half either — the whole beat fizzled")
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		assert_ne(String(hit.get("combatant", "")), "vic", "the victim took nothing")
	assert_true((sim.combatants["vic"] as CombatantState).alive, "alive")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "", "and free")
	assert_true(spin_state(sim).is_empty(), "sequence aborted")


func test_below_phase_five_the_three_beat_sequence_is_unchanged() -> void:
	var sim: CombatSim = stage_at_phase(3, [1, 0])
	ai_decide(sim, "boss")
	advance(sim, 1)  # grab
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "chew", "phase 3: the separate chew beat survives")
	var chewed: Array[Dictionary] = advance(sim, 1)
	var chew: Dictionary = assert_event(chewed, "death_spin_chew", "chew resolves alone")
	assert_false(bool(chew.get("merged", false)), "not merged")
	assert_no_event(chewed, "death_spin_kill", "no same-Moment kill below phase 5")
	assert_eq(int(spin_state(sim).get("beat", 0)), 2, "beat 2 pending — spin comes NEXT Moment")


# ------------------------------------------- dash bend mid-run (phase 4+)

## A hand-built BENT dash exactly as EnemyAI shapes one (manual declare so the
## staging controls the geometry): seg1 E to the bend, seg2 onward.
func bent_dash_action(target_id: String, lane_pairs: Array, bend: Array) -> Dictionary:
	return {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2},
		"attack_range": 6,
		"targets": [{"id": target_id, "part": "torso"}],
		"dodge": {"threshold": 7, "counter_at": 9},
		"knock_aside": true,
		"area_shape": {"kind": "line", "lane": lane_pairs, "bend": bend},
	}


func test_bent_declare_gates_on_phase_four() -> void:
	var lane: Array = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]]
	var sim: CombatSim = stage_at_phase(3, [2, 2])
	assert_rejected(declare(sim, "boss", bent_dash_action("vic", lane, [2, 0])),
		"bend_not_available", "phase 3: no mid-run direction change yet")
	var sim2: CombatSim = stage_at_phase(4, [2, 2])
	assert_event(declare(sim2, "boss", bent_dash_action("vic", lane, [2, 0])),
		"action_declared", "phase 4: the bent lane declares")


func test_ai_bends_the_dash_around_a_blocker_at_phase_four_plus() -> void:
	# Straight lane (0,0)->(4,0) is blocked at (2,0) (an enemy-team body, so
	# the opponent list is untouched). Below phase 4 the boss can only step;
	# at phase 5 it finds a ONE-bend lane and charges to adjacent-before.
	var stage_bent: Callable = func(phase: int) -> CombatSim:
		var s: CombatSim = make_sim()
		add_human(s, "vic", {"team": "party", "position": [4, 0],
			"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
		s.apply_command({"type": "add_combatant", "combatant": {
			"id": "walldog", "name": "walldog", "enemy": "roach_dog",
			"team": "enemies", "position": [2, 0],
		}})
		add_boss(s, "boss", {"boss_traits": traits_without_dodge()})
		s.ai.boss_phase["boss"] = phase
		return s
	var low: CombatSim = stage_bent.call(3)
	var low_decision: Dictionary = first_event(ai_decide(low, "boss"), "ai_decision")
	assert_eq(String(low_decision.get("choice", "")), "move",
		"phase 3: no straight lane -> the boss can only close")
	var sim: CombatSim = stage_bent.call(5)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "attack", "phase 5: the bend reaches")
	assert_eq(String(decision.get("ability", "")), "dash", "as a dash")
	var declared_shape: Dictionary = _scheduled_shape(sim)
	assert_true(declared_shape.has("bend"), "the declare carries the bend point")
	var lane: Array = declared_shape.get("lane", [])
	assert_true(lane.size() >= 3 and lane.size() <= 7, "lane length within the dash's range")
	assert_eq(lane[0], [0, 0], "lane starts at the boss")
	assert_true(lane.has([4, 0]), "and reaches the target's hex")
	assert_false(lane.has([2, 0]), "routing AROUND the blocker, never through it")
	# Determinism: the same staging picks the same bend (fixed-order search).
	var twin: CombatSim = stage_bent.call(5)
	ai_decide(twin, "boss")
	assert_eq(_scheduled_shape(twin).get("bend", []), declared_shape.get("bend", []),
		"same bend both runs")
	# And the AI-built bent charge genuinely lands: run the windup out.
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(resolved, "dash_charged", "the bent charge runs")
	assert_eq(charged.get("bend", []), declared_shape.get("bend", []),
		"the dash event payload carries the bend")
	assert_eq(CombatantState.hex_distance(boss_state(sim).position, Vector2i(4, 0)), 1,
		"the boss charged to adjacent-before the target")
	assert_event(resolved, "damage_applied", "and the strike lands (Reflexes 2 cannot dodge)")


## The boss's pending scheduled action's area_shape (read-only Clock probe).
func _scheduled_shape(sim: CombatSim) -> Dictionary:
	for entry: Dictionary in sim.clock.scheduled_entries():
		if String(entry.get("actor", "")) == "boss":
			return (entry["action"] as Dictionary).get("area_shape", {})
	return {}


func test_bent_charge_stops_at_occupation_on_either_segment() -> void:
	var lane: Array = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]]
	# Segment 1 blocked at (1,0): the charge never leaves the gate.
	var sim: CombatSim = stage_at_phase(5, [2, 2])
	add_human(sim, "seg1_block", {"team": "party", "position": [1, 0]})
	declare(sim, "boss", bent_dash_action("vic", lane, [2, 0]))
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "dash_stopped_short", "a body on segment 1 stops the charge")
	assert_no_event(resolved, "dash_charged", "no ground gained")
	assert_no_event(resolved, "damage_applied", "an honest miss — no strike")
	assert_eq(boss_state(sim).position, Vector2i(0, 0), "the boss never moved")
	# Segment 2 blocked at (2,1): the charge takes the bend then stops short.
	var sim2: CombatSim = stage_at_phase(5, [2, 2])
	add_human(sim2, "seg2_block", {"team": "party", "position": [2, 1]})
	declare(sim2, "boss", bent_dash_action("vic", lane, [2, 0]))
	advance(sim2, 2)
	var resolved2: Array[Dictionary] = advance(sim2, 1)
	var charged: Dictionary = assert_event(resolved2, "dash_charged", "the charge runs segment 1")
	assert_eq(charged.get("to", []), [2, 0], "to the bend hex")
	assert_eq(charged.get("bend", []), [2, 0], "the dash event payload carries the bend")
	assert_event(resolved2, "dash_stopped_short", "then a segment-2 body stops it")
	assert_no_event(resolved2, "damage_applied", "out of reach = honest miss")
	assert_eq(boss_state(sim2).position, Vector2i(2, 0), "stopped before the segment-2 body")


func test_leaving_the_bent_lane_mid_windup_dodges_the_charge() -> void:
	var lane: Array = [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2]]
	var sim: CombatSim = stage_at_phase(5, [2, 2])
	declare(sim, "boss", bent_dash_action("vic", lane, [2, 0]))
	advance(sim, 1)
	assert_event(sim.apply_command({"type": "move", "actor": "vic", "to": [4, 0]}),
		"moved", "the target steps off the bent corridor mid-windup")
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated", "the windup collapses")
	assert_eq(String(invalidated.get("reason", "")), "left_lane", "the standard lane re-check, bent or not")
	assert_no_event(resolved, "dash_charged", "no charge down an abandoned lane")
	assert_no_event(resolved, "damage_applied", "nothing lands")


func test_sidestep_leaves_the_dodgers_segment_knock_aside_the_whole_lane() -> void:
	# Hairpin lane [(0,0),(1,0),(2,0),(1,1)], bend (2,0): the target at (1,1)
	# stands on SEGMENT 2. Its fixed-order neighbors: (2,1) staged occupied,
	# (2,0) on segment 2, (1,0) on SEGMENT 1, (0,1) off-lane entirely.
	#  * R22 sidestep (voluntary): excludes only the dodger's segment — the
	#    first legal hex is (1,0), a segment-ONE hex.
	#  * knock-aside (involuntary): excludes the FULL bent lane — (1,0) is
	#    skipped and the shove lands on (0,1).
	var lane: Array = [[0, 0], [1, 0], [2, 0], [1, 1]]
	var dodger: CombatSim = stage_at_phase(5, [1, 1], {"reflexes": 7})
	sink_blocker(dodger, [2, 1])
	declare(dodger, "boss", bent_dash_action("vic", lane, [2, 0]))
	advance(dodger, 2)
	var dodged: Array[Dictionary] = advance(dodger, 1)
	assert_event(dodged, "attack_dodged", "Reflexes 7 auto-dodges the charge")
	var side: Dictionary = assert_event(dodged, "dash_sidestepped", "the R22 sidestep rides it")
	assert_eq(side.get("to", []), [1, 0],
		"the sidestep leaves the dodger's SEGMENT — a segment-1 hex is legal ground")
	assert_no_event(dodged, "knocked_aside", "a dodged dash never knocks aside")
	var victim: CombatSim = stage_at_phase(5, [1, 1], {"reflexes": 2})
	sink_blocker(victim, [2, 1])
	declare(victim, "boss", bent_dash_action("vic", lane, [2, 0]))
	advance(victim, 2)
	var knocked_events: Array[Dictionary] = advance(victim, 1)
	assert_event(knocked_events, "damage_applied", "Reflexes 2 cannot dodge — the charge connects")
	var knocked: Dictionary = assert_event(knocked_events, "knocked_aside", "and knocks aside")
	assert_eq(knocked.get("to", []), [0, 1],
		"the shove skips segment-1 hexes too — off the WHOLE bent lane")
	assert_true(bool((victim.combatants["vic"] as CombatantState).statuses.get("prone", false)),
		"and prone (the 'aside' cost)")


## An enemy-team body at `pos` (never an opponent — the decide is untouched).
func sink_blocker(sim: CombatSim, pos: Array) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "blocker_%d_%d" % [int(pos[0]), int(pos[1])], "name": "blocker",
		"enemy": "roach_dog", "team": "enemies", "position": pos,
	}})


# ------------------------------------- flamethrower tracks closest (phase 5)

func test_phase_five_cone_aims_at_the_nearest_not_the_biggest_crowd() -> void:
	# Five opponents: a pair E-ish (nearest at distance 2) and a trio W-ish at
	# distance 3. Below phase 5 the sweep maximizes (W arc, 3 targets); at
	# phase 5 it TRACKS the nearest — the E arc (2 targets) despite the bigger
	# crowd behind it. Only the toward selection shifts (R11 #20).
	var stage_cone: Callable = func(phase: int) -> CombatSim:
		var s: CombatSim = make_sim()
		add_human(s, "near", {"team": "party", "position": [2, 0]})
		add_human(s, "nearb", {"team": "party", "position": [3, -1]})
		add_human(s, "wa", {"team": "party", "position": [-3, 0]})
		add_human(s, "wb", {"team": "party", "position": [-3, 1]})
		add_human(s, "wc", {"team": "party", "position": [-2, -1]})
		add_boss(s, "boss", {"boss_traits": traits_without_dodge()})
		s.ai.boss_phase["boss"] = phase
		return s
	var low: CombatSim = stage_cone.call(3)
	var low_decision: Dictionary = first_event(ai_decide(low, "boss"), "ai_decision")
	assert_eq(String(low_decision.get("ability", "")), "flamethrower", "phase 3: sweep declared")
	assert_eq(low_decision.get("aim", []), [-1, 0], "phase 3 aims at the BIGGEST crowd (W, 3 targets)")
	var sim: CombatSim = stage_cone.call(5)
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("ability", "")), "flamethrower", "phase 5: sweep declared")
	assert_eq(decision.get("aim", []), [1, 0], "phase 5 aims at the NEAREST (E arc, only 2 targets)")
	assert_eq(String(decision.get("target", "")), "near", "the nearest quarry leads the target list")


func test_phase_five_tracking_keeps_the_min_targets_gate() -> void:
	# The nearest stands ALONE in its arcs; a pair clusters far behind. Below
	# phase 5 the sweep takes the pair; at phase 5 tracking finds only 1 target
	# in the quarry's arc — the >= 2 gate holds, the cone is NOT fired, and the
	# decide falls through to the grab (the nearest is in upgraded grab reach):
	# at phase 5 the boss hunts YOU, with its jaws if the crowd is elsewhere.
	var stage_lone: Callable = func(phase: int) -> CombatSim:
		var s: CombatSim = make_sim()
		add_human(s, "near", {"team": "party", "position": [2, 0]})
		add_human(s, "fa", {"team": "party", "position": [-4, 0]})
		add_human(s, "fb", {"team": "party", "position": [-4, 1]})
		add_boss(s, "boss", {"boss_traits": traits_without_dodge()})
		s.ai.boss_phase["boss"] = phase
		return s
	var low: CombatSim = stage_lone.call(3)
	var low_decision: Dictionary = first_event(ai_decide(low, "boss"), "ai_decision")
	assert_eq(String(low_decision.get("ability", "")), "flamethrower",
		"phase 3: the far pair is still a sweepable crowd")
	assert_eq(low_decision.get("aim", []), [-1, 0], "aimed away at the crowd")
	var sim: CombatSim = stage_lone.call(5)
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_ne(String(decision.get("ability", "")), "flamethrower",
		"phase 5: a lone quarry is not a crowd — the sweep gate holds")
	assert_eq(String(decision.get("choice", "")), "grab",
		"the boss hunts the nearest with the upgraded-range grab instead")


# ------------------------------------- network fully exposed (phase 4+)

func test_network_stays_exposed_after_the_phase_four_valve() -> void:
	# Full honest drive: breach -> valve I (which DOES re-hide — the contrast)
	# -> re-breach -> drive to 18 -> valve II blast -> the network stays
	# exposed and attackable straight through phase 5. `far` does the phase-3+
	# work from outside both blast radii, so no knockout stalls the drive.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_human(sim, "far", {"team": "party", "position": [12, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	declare(sim, "h", attack_action("crushed", 10, "boss", "right_hand"))
	advance(sim, 1)  # net 8 single hit >= 7 — breach opens
	assert_true(boss_state(sim).breached, "staging: breached")
	declare(sim, "h", attack_action("crushed", 17, "boss", "network"))
	advance(sim, 1)  # net 15: network 50 -> 35 — Valve I
	assert_eq(sim.ai.current_phase("boss"), 2, "staging: Valve I entered")
	for _i: int in range(3):
		ai_decide(sim, "boss")
		advance(sim, 1)
	var valve_one: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(valve_one, "explosion_blast", "Valve I blows")
	assert_event(valve_one, "breach_reset", "the PHASE-2 valve still re-hides (upgrade inactive)")
	assert_true(bool(boss_state(sim).parts["network"]["hidden"]), "network re-hid at phase 2")
	assert_eq(sim.ai.current_phase("boss"), 3, "into Threshold 2")
	# Re-breach + drive to the Valve-II threshold from far outside the radius.
	declare(sim, "far", attack_action("crushed", 10, "boss", "right_leg", {"attack_range": 15}))
	advance(sim, 1)
	assert_true(boss_state(sim).breached, "re-breached in phase 3")
	declare(sim, "far", attack_action("crushed", 19, "boss", "network", {"attack_range": 15}))
	advance(sim, 1)  # net 17: network 35 -> 18 — Valve II
	assert_eq(sim.ai.current_phase("boss"), 4, "staging: Valve II entered")
	for _i: int in range(3):
		ai_decide(sim, "boss")
		advance(sim, 1)
	var valve_two: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(valve_two, "explosion_blast", "Valve II blows")
	assert_no_event(valve_two, "breach_reset", "NO retreat — the network is fully exposed (wave 2d)")
	assert_false(bool(boss_state(sim).parts["network"]["hidden"]), "the network never re-hides")
	assert_true(boss_state(sim).breached, "the breach stays open")
	assert_eq(sim.ai.current_phase("boss"), 5, "into Threshold 3")
	assert_true(sim.ai.has_upgrade(boss_state(sim), "network_stays_exposed"),
		"the reader reports the authored upgrade active")
	advance(sim, 1)
	assert_event(declare(sim, "far", attack_action("crushed", 6, "boss", "network", {"attack_range": 15})),
		"action_declared", "the network stays attackable straight into phase 5")


# ------------------------------------- determinism + serialization

func test_mid_phase_five_sequence_save_restores_the_merged_continuation() -> void:
	var sim: CombatSim = stage_at_phase(5, [2, 0])
	ai_decide(sim, "boss")
	advance(sim, 1)  # range-2 grab + drag landed — save at beat 1, phase 5
	assert_eq(int(spin_state(sim).get("beat", 0)), 1, "precondition: mid-sequence")
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical mid-sequence")
	assert_eq(int((restored.ai.boss_phase as Dictionary).get("boss", 0)), 5,
		"the phase (the ONLY upgrade state) survives the roundtrip")
	# Lockstep: both sims play the merged beat — the upgrade re-derives from
	# phase on the restored side with no extra state.
	var tail: Array[Dictionary] = [
		{"type": "ai_decide", "actor": "boss"}, {"type": "advance_tick"},
	]
	var tail_original: Array[Dictionary] = []
	var tail_restored: Array[Dictionary] = []
	for cmd: Dictionary in tail:
		tail_original.append_array(sim.apply_command(cmd))
		tail_restored.append_array(restored.apply_command(cmd))
	assert_event(tail_original, "death_spin_kill", "the original tail ran the merged beat")
	assert_event(tail_restored, "death_spin_kill", "the restored tail ran it identically")
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")


func test_same_seed_same_log_through_upgraded_fight_is_the_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = stage_at_phase(5, [2, 0])
		add_human(sim, "ally", {"team": "party", "position": [-3, 0]})
		ai_decide(sim, "boss")
		advance(sim, 1)  # drag + grab
		declare(sim, "ally", attack_action("crushed", 6, "boss", "right_leg", {"attack_range": 3}))
		ai_decide(sim, "boss")
		advance(sim, 1)  # merged chew+spin through the net-4 chip
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through the phase-5 kit")
