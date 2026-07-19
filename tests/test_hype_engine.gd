extends SimTestBase
## Hype engine v1 (simulation/hype_engine.gd) — determinism, scoring, decay,
## band events, serialization, crowd Goals, and Camera Call. Numeric
## expectations use the PLACEHOLDER weights; tests assert relations (>, <,
## band membership) wherever exact values depend on condition-application
## side effects. Goal tests pin the table to a single goal so the (seeded)
## goal draw is forced without depending on RNG internals.


## A lethal torso hit: 5 damage (torso hp 5) kills. One resolution batch gains
## damage(5*4=20) + died(60) = 80 spectacle points. (Head is not a legal
## target here — R7 head_not_targetable — so the kill goes through the torso.)
func _kill_setup(sim_seed: int = 1234) -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	var declared: Array[Dictionary] = declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	assert_no_event(declared, "command_rejected", "kill-setup declare must be accepted")
	return sim


func test_determinism_same_log_same_hype() -> void:
	var sim1: CombatSim = _kill_setup()
	var sim2: CombatSim = _kill_setup()
	advance(sim1, 3)
	advance(sim2, 3)
	assert_eq(sim1.hype.meter, sim2.hype.meter, "same command log -> same meter")
	assert_eq(sim1.hype.band, sim2.hype.band, "same command log -> same band")
	assert_eq(sim1.state_hash(), sim2.state_hash(), "state_hash covers hype and stays replay-stable")


func test_kill_raises_hype_and_spikes() -> void:
	var sim: CombatSim = _kill_setup()
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "combatant_died", "the setup kill happened")
	assert_true(sim.hype.meter >= 80, "kill batch is worth at least damage+death points, got %d" % sim.hype.meter)
	assert_event(events, "hype_spike", "an 80+ point batch clears the spike threshold (50)")
	var change: Dictionary = assert_event(events, "hype_band_changed", "meter left the cold band")
	assert_eq(String(change.get("from_band", "")), "cold", "band started cold")
	assert_true(["warm", "hot", "on_fire"].has(String(change.get("to_band", ""))), "band rose")
	assert_true(int(sim.hype.ledger.get("b", 0)) > 0, "the victim's drama is credited to their ledger")


func test_zero_damage_scores_nothing() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	declare(sim, "a", attack_action("bleeding", 0, "b", "torso"))
	advance(sim, 3)
	assert_eq(sim.hype.meter, 0, "a 0-damage poke is not entertainment")
	assert_eq(sim.hype.band, "cold", "band stays cold")


func test_decay_on_clock_reset() -> void:
	var sim: CombatSim = _kill_setup()
	advance(sim, 3)
	var before: int = sim.hype.meter
	assert_true(before > 0, "precondition: hype raised")
	# Idle out the rest of the Clock; the dead target's conditions never advance
	# (on_clock_reset guards on alive), so the only scored change is decay.
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(events, "clock_reset", "a full Clock completed while idle")
	assert_true(sim.hype.meter < before, "boredom decays the meter (%d -> %d)" % [before, sim.hype.meter])
	assert_true(sim.hype.meter >= 0, "meter never goes negative")


func test_meter_floors_at_zero() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK * 3)
	assert_true(events_of(events, "clock_reset").size() >= 2, "several idle Clocks passed")
	assert_eq(sim.hype.meter, 0, "decay from zero stays zero")


func test_serialization_roundtrip_mid_combat() -> void:
	var sim: CombatSim = _kill_setup()
	advance(sim, 2)
	var saved: Dictionary = sim.to_dict()
	var resumed: CombatSim = CombatSim.from_dict(saved)
	assert_eq(resumed.hype.meter, sim.hype.meter, "meter survives to_dict/from_dict")
	assert_eq(resumed.hype.band, sim.hype.band, "band survives to_dict/from_dict")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical after round-trip")
	# Resumed timeline must stay in lockstep with the uninterrupted one.
	advance(sim, Clock.TICKS_PER_CLOCK)
	advance(resumed, Clock.TICKS_PER_CLOCK)
	assert_eq(resumed.hype.meter, sim.hype.meter, "resumed run tracks the uninterrupted run")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after resume")


# ---------------------------------------------------------------- crowd goals

## Sim whose crowd-goal table is pinned to exactly the given goals.
func make_goal_sim(goals: Array, sim_seed: int = 1234) -> CombatSim:
	var data: Dictionary = SimTestBase.load_static_data()
	data["crowd_goals"] = goals
	return CombatSim.new(sim_seed, data)


## A camera-ready contestant: charm 30 -> 1 Camera Call stack (R6 over-cap).
func add_star(sim: CombatSim, id: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 30}}
	spec.merge(overrides, true)
	return add_human(sim, id, spec)


func test_goal_offered_at_clock_reset() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	assert_true(sim.hype.active_goal.is_empty(), "no goal before the first Clock reset")
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(events, "clock_reset", "a Clock completed")
	var offered: Dictionary = assert_event(events, "hype_goal_offered", "first Clock reset offers a crowd goal")
	assert_false(sim.hype.active_goal.is_empty(), "a goal is now active")
	assert_eq(String(sim.hype.active_goal.get("id", "")), String(offered.get("goal", "")), "active goal matches the offer")
	assert_true(int(offered.get("deadline_clocks", 0)) >= 1, "the offer carries a deadline")


func test_goal_selection_is_deterministic() -> void:
	var sim1: CombatSim = make_sim(777)
	var sim2: CombatSim = make_sim(777)
	add_human(sim1, "a")
	add_human(sim2, "a")
	var offers1: Array[Dictionary] = events_of(advance(sim1, Clock.TICKS_PER_CLOCK * 7), "hype_goal_offered")
	var offers2: Array[Dictionary] = events_of(advance(sim2, Clock.TICKS_PER_CLOCK * 7), "hype_goal_offered")
	assert_true(offers1.size() >= 2, "several goals were offered over 7 idle Clocks, got %d" % offers1.size())
	assert_eq(offers1.size(), offers2.size(), "same command log -> same number of offers")
	for i: int in range(mini(offers1.size(), offers2.size())):
		assert_eq(String(offers1[i].get("goal", "")), String(offers2[i].get("goal", "")), "offer %d matches" % i)
	assert_eq(sim1.state_hash(), sim2.state_hash(), "goal RNG stream is part of deterministic state")


func test_goal_takedown_completion_pays_hype() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "finish_them", "pinned goal is active")
	var before: int = sim.hype.meter
	declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "combatant_died", "the kill landed")
	var done: Dictionary = assert_event(events, "hype_goal_completed", "a kill completes the takedown goal")
	assert_eq(int(done.get("spectacle_points", -1)), 80, "payout matches the goal table")
	assert_eq(String(done.get("combatant", "")), "b", "completion carries its attribution (Stage-2 broadcast)")
	assert_true(sim.hype.active_goal.is_empty(), "goal cleared after completion")
	assert_true(sim.hype.meter >= before + 80 + 80, "meter gained kill points AND the payout (got %d -> %d)" % [before, sim.hype.meter])
	var next_events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(next_events, "hype_goal_offered", "the next Clock reset offers a fresh goal")


func test_goal_overkill_requires_threshold() -> void:
	var goal: Dictionary = {"id": "overkill", "name": "OVERKILL!", "kind": "overkill", "params": {"threshold": 8}, "payout": 60, "deadline_clocks": 9}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "overkill", "pinned goal is active")
	declare(sim, "a", attack_action("bleeding", 4, "b", "torso"))
	var small: Array[Dictionary] = advance(sim, 2)
	assert_event(small, "damage_applied", "the small hit landed")
	assert_no_event(small, "hype_goal_completed", "a 4-damage hit is under the 8 threshold")
	assert_false(sim.hype.active_goal.is_empty(), "goal still active")
	declare(sim, "a", attack_action("bleeding", 8, "b", "torso"))
	var big: Array[Dictionary] = advance(sim, 2)
	var done: Dictionary = assert_event(big, "hype_goal_completed", "an 8-damage hit clears the threshold")
	assert_eq(int(done.get("spectacle_points", -1)), 60, "overkill payout matches the table")


func test_goal_expiry_penalty_and_reoffer() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 1}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	# Kill BEFORE any offer: the goal must not complete retroactively, and the
	# corpse leaves no advancing conditions to muddy the decay arithmetic.
	declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	var kill_events: Array[Dictionary] = advance(sim, 3)
	assert_event(kill_events, "combatant_died", "setup kill happened")
	assert_no_event(kill_events, "hype_goal_completed", "no goal was active yet — nothing completes")
	var first_reset: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(first_reset, "hype_goal_offered", "goal offered at the first reset")
	var before: int = sim.hype.meter
	var second_reset: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(second_reset, "hype_goal_expired", "deadline_clocks=1 expires at the next reset")
	assert_event(second_reset, "hype_goal_offered", "the crowd immediately wants something new")
	assert_eq(sim.hype.meter, maxi(0, before - HypeEngine.DECAY_PER_CLOCK - HypeEngine.GOAL_EXPIRY_PENALTY),
		"expiry costs the penalty on top of normal decay")


# ---------------------------------------------------------------- camera call

func test_camera_call_requires_stacks() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_star(sim, "s", {"position": [2, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "zz", "target": "b"}), "unknown_actor", "unknown caller")
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "a", "target": "zz"}), "unknown_target", "unknown target")
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "a", "target": "b"}), "no_camera_call_stacks", "charm 3 -> zero stacks (R6)")
	var started: Array[Dictionary] = sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	var ack: Dictionary = assert_event(started, "hype_camera_call_started", "charm 30 -> 1 stack, call accepted")
	assert_eq(int(ack.get("stacks_remaining", -1)), 0, "the only stack is now spent")
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "s", "target": "a"}), "spotlight_active", "one spotlight at a time")


func test_camera_call_doubles_spotlit_gains() -> void:
	var sim_plain: CombatSim = make_sim(42)
	var sim_called: CombatSim = make_sim(42)
	for sim: CombatSim in [sim_plain, sim_called]:
		add_human(sim, "a")
		add_human(sim, "b", {"position": [1, 0]})
		add_star(sim, "s", {"position": [2, 0]})
	assert_event(sim_called.apply_command({"type": "camera_call", "actor": "s", "target": "b"}),
		"hype_camera_call_started", "spotlight on the victim-to-be")
	for sim: CombatSim in [sim_plain, sim_called]:
		declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	advance(sim_plain, 3)
	var events: Array[Dictionary] = advance(sim_called, 3)
	assert_event(events, "combatant_died", "the kill landed on camera")
	assert_true(sim_plain.hype.meter > 0, "precondition: the plain kill scored")
	assert_eq(sim_called.hype.meter, sim_plain.hype.meter * HypeEngine.CAMERA_CALL_MULTIPLIER,
		"every point of the spotlit kill batch is doubled")
	assert_eq(int(sim_called.hype.ledger.get("b", 0)), int(sim_plain.hype.ledger.get("b", 0)) * HypeEngine.CAMERA_CALL_MULTIPLIER,
		"the spotlit combatant's ledger credit is doubled")
	var ended: Dictionary = assert_event(events, "hype_spotlight_ended", "spotlight ends with its target")
	assert_eq(String(ended.get("reason", "")), "target_died", "ended because the target died")
	assert_true(sim_called.hype.spotlight.is_empty(), "spotlight cleared")


func test_camera_call_ends_when_target_acts() -> void:
	var sim: CombatSim = make_sim()
	add_star(sim, "s")
	add_human(sim, "b", {"position": [1, 0]})
	assert_event(sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"}),
		"hype_camera_call_started", "spotlight up")
	declare(sim, "b", attack_action("bleeding", 0, "s", "torso"))
	var events: Array[Dictionary] = advance(sim, 2)
	assert_event(events, "action_resolved", "the target's action resolved")
	var ended: Dictionary = assert_event(events, "hype_spotlight_ended", "spotlight ends at end of the target's action")
	assert_eq(String(ended.get("reason", "")), "action_ended", "reason is the action ending")
	assert_true(sim.hype.spotlight.is_empty(), "spotlight cleared")


func test_camera_call_fades_after_clock_limit() -> void:
	var sim: CombatSim = make_sim()
	add_star(sim, "s")
	add_human(sim, "b", {"position": [1, 0]})
	sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK * HypeEngine.CAMERA_CALL_CLOCK_LIMIT)
	var ended: Dictionary = assert_event(events, "hype_spotlight_ended", "an idle spotlight fades on the Clock fallback")
	assert_eq(String(ended.get("reason", "")), "faded", "fallback reason")
	assert_true(sim.hype.spotlight.is_empty(), "spotlight cleared")
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"}),
		"no_camera_call_stacks", "the spent stack does not come back")


func test_goal_payout_doubled_under_spotlight() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	add_star(sim, "s", {"position": [2, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	var events: Array[Dictionary] = advance(sim, 3)
	var done: Dictionary = assert_event(events, "hype_goal_completed", "spotlit kill completes the goal")
	assert_eq(int(done.get("spectacle_points", -1)), 80 * HypeEngine.CAMERA_CALL_MULTIPLIER,
		"payout is doubled when the completing event is the spotlit combatant's")


func test_spectacle_serialization_roundtrip() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	add_star(sim, "s", {"position": [2, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical with live goal + spotlight + spent stack")
	assert_eq(resumed.hype.active_goal, sim.hype.active_goal, "active goal survives the round-trip")
	assert_eq(resumed.hype.spotlight, sim.hype.spotlight, "spotlight survives the round-trip")
	assert_eq(resumed.hype.camera_calls_used, sim.hype.camera_calls_used, "spent stacks survive the round-trip")
	# Both timelines finish the fight identically: doubled payout on both.
	for s: CombatSim in [sim, resumed]:
		declare(s, "a", attack_action("bleeding", 5, "b", "torso"))
		advance(s, 3)
		advance(s, Clock.TICKS_PER_CLOCK * 2)
	assert_eq(resumed.hype.meter, sim.hype.meter, "resumed run tracks the uninterrupted run")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after resume (goal RNG included)")


func test_hype_events_are_not_rescored() -> void:
	var sim: CombatSim = _kill_setup()
	var recorded: Array[Dictionary] = advance(sim, 3)
	var meter_after: int = sim.hype.meter
	# A recorded broadcast batch contains the engine's own outputs; re-feeding
	# JUST those must not move the meter. This has teeth: hype_spike carries its
	# point value in "spectacle_points", so an engine without the prefix guard
	# would double-count it here.
	var own: Array[Dictionary] = []
	for event: Dictionary in recorded:
		if String(event.get("type", "")).begins_with("hype_"):
			own.append(event)
	var spike: Dictionary = first_event(own, "hype_spike")
	assert_true(int(spike.get("spectacle_points", 0)) > 0,
		"the recorded spike self-describes a nonzero point value (guard hazard is real)")
	var echo: Array[Dictionary] = sim.hype.ingest(own)
	assert_eq(sim.hype.meter, meter_after, "re-ingesting the engine's own events scores nothing")
	assert_true(echo.is_empty(), "no cascading hype events")


## The generic scoring hook the guard protects: any non-hype event carrying
## "spectacle_points" scores that value directly (authored-content injection).
func test_spectacle_points_hook_scores_directly() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var echo: Array[Dictionary] = sim.hype.ingest([
		{"type": "scripted_flourish", "combatant": "a", "spectacle_points": 25},
	])
	assert_eq(sim.hype.meter, 25, "injected spectacle scores at face value")
	assert_eq(int(sim.hype.ledger.get("a", 0)), 25, "and is credited to the attributed combatant")
	assert_true(events_of(echo, "hype_spike").is_empty(), "25 points is below the spike threshold")


func test_goal_part_break_completion() -> void:
	var goal: Dictionary = {"id": "break_something", "name": "Break Something!", "kind": "part_break", "params": {}, "payout": 50, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "break_something", "pinned goal is active")
	# Bleeding T3 ("Part Death") destroys a non-lethal part outright.
	var events: Array[Dictionary] = sim.apply_command({
		"type": "apply_condition", "target": "b", "part": "left_arm",
		"condition": "bleeding", "tier": 3,
	})
	assert_event(events, "part_destroyed", "the arm is gone")
	var done: Dictionary = assert_event(events, "hype_goal_completed", "a destroyed part completes the goal")
	assert_eq(int(done.get("spectacle_points", -1)), 50, "part_break payout matches the table")
	assert_eq(String(done.get("combatant", "")), "b", "attribution is the maimed combatant")
	assert_true(sim.hype.active_goal.is_empty(), "goal cleared after completion")


func test_goal_exposed_strike_completion() -> void:
	var goal: Dictionary = {"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike", "params": {}, "payout": 45, "deadline_clocks": 2}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "show_off", "pinned goal is active")
	# A 2-Moment windup makes the attacker genuinely Exposed (R2 channeling) —
	# the engine's exposed mirror must be populated by real exposure events.
	var declared: Array[Dictionary] = declare(sim, "a", attack_action("bleeding", 2, "b", "torso", {"cost": 2}))
	assert_event(declared, "exposed_state_changed", "declaring the windup exposes the attacker")
	assert_true(bool(sim.hype.exposed.get("a", false)), "the exposed mirror tracks the attacker")
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "action_resolved", "the windup landed")
	var done: Dictionary = assert_event(events, "hype_goal_completed", "landing a hit while Exposed completes the goal")
	assert_eq(int(done.get("spectacle_points", -1)), 45, "exposed_strike payout matches the table")
	assert_eq(String(done.get("combatant", "")), "a", "attribution falls back to the acting combatant")
	assert_false(bool(sim.hype.exposed.get("a", false)), "the mirror un-exposes once the windup resolves")


func test_exposed_mirror_serialization_roundtrip() -> void:
	var goal: Dictionary = {"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike", "params": {}, "payout": 45, "deadline_clocks": 2}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	declare(sim, "a", attack_action("bleeding", 2, "b", "torso", {"cost": 2}))
	assert_true(bool(sim.hype.exposed.get("a", false)), "precondition: mirror is NON-empty mid-windup")
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.hype.exposed, sim.hype.exposed, "exposed mirror survives the round-trip")
	assert_true(bool(resumed.hype.exposed.get("a", false)), "restored mirror still marks the attacker Exposed")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical mid-windup")
	# Both timelines complete the exposed_strike goal identically post-restore.
	var events_live: Array[Dictionary] = advance(sim, 3)
	var events_resumed: Array[Dictionary] = advance(resumed, 3)
	assert_event(events_live, "hype_goal_completed", "live timeline completes the goal")
	assert_event(events_resumed, "hype_goal_completed", "resumed timeline completes it too")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after resume")


## Teeth for the goal-RNG stream: different sim seeds must produce different
## offer sequences (fails if the seed is ignored OR the draw is constant), and
## a draw must consume the dedicated RNG (fails if the RNG is never advanced).
func test_goal_rng_stream_has_teeth() -> void:
	var sim1: CombatSim = make_sim(101)
	var sim2: CombatSim = make_sim(202)
	add_human(sim1, "a")
	add_human(sim2, "a")
	var seq1: Array[String] = []
	for offer: Dictionary in events_of(advance(sim1, Clock.TICKS_PER_CLOCK * 20), "hype_goal_offered"):
		seq1.append(String(offer.get("goal", "")))
	var seq2: Array[String] = []
	for offer: Dictionary in events_of(advance(sim2, Clock.TICKS_PER_CLOCK * 20), "hype_goal_offered"):
		seq2.append(String(offer.get("goal", "")))
	assert_true(seq1.size() >= 5, "enough offers to compare, got %d" % seq1.size())
	assert_ne(",".join(seq1), ",".join(seq2), "different seeds -> different goal-offer sequences")
	var sim3: CombatSim = make_sim(303)
	add_human(sim3, "a")
	var state_before: int = sim3.hype.goal_rng.state
	var events: Array[Dictionary] = advance(sim3, Clock.TICKS_PER_CLOCK)
	assert_event(events, "hype_goal_offered", "a goal draw happened")
	assert_ne(sim3.hype.goal_rng.state, state_before, "a goal draw consumes the dedicated RNG")


func test_camera_call_actor_gates() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_star(sim, "s", {"position": [0, 1]})
	add_human(sim, "b", {"position": [1, 0]})
	# Shock T3 -> Helpless for a Clock: same actor gate as declared actions.
	sim.apply_command({"type": "apply_condition", "target": "s", "condition": "shock", "tier": 3})
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"}),
		"helpless", "a Helpless caller cannot call the camera (R11 #13)")
	advance(sim, Clock.TICKS_PER_CLOCK + 1)
	# Kill the would-be target: rejection flips to target_dead (helpless expired).
	declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	advance(sim, 3)
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"}),
		"target_dead", "no spotlight on a corpse")
	# Kill the caller: a dead caller is rejected before any stack accounting.
	declare(sim, "a", attack_action("bleeding", 5, "s", "torso"))
	advance(sim, 3)
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "s", "target": "a"}),
		"actor_dead", "a dead caller cannot call the camera")
