extends SimTestBase
## Hype engine v1 (simulation/hype_engine.gd) — determinism, scoring, decay,
## band events, serialization. Numeric expectations use the PLACEHOLDER
## weights; tests assert relations (>, <, band membership) wherever exact
## values depend on condition-application side effects.


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


func test_hype_events_are_not_rescored() -> void:
	var sim: CombatSim = _kill_setup()
	advance(sim, 3)
	var meter_after: int = sim.hype.meter
	# Feeding the engine its own output must be a no-op (re-entry safety).
	var echo: Array[Dictionary] = sim.hype.ingest([
		{"type": "hype_spike", "gain": 999, "meter": meter_after},
		{"type": "hype_band_changed", "from_band": "cold", "to_band": "hot", "meter": meter_after},
	])
	assert_eq(sim.hype.meter, meter_after, "hype_* events score nothing")
	assert_true(echo.is_empty(), "no cascading hype events")
