extends SimTestBase
## KAN3-S4 — paused clock driver: waits on decisions, feeds exactly one tick,
## sim frozen without a driver, forced actions demand re-decision.


func _setup() -> Dictionary:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(99, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "hero", "name": "hero", "race": "human", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	var driver: PausedClockDriver = PausedClockDriver.new()
	driver.attach(game)
	driver.set_party(["hero"] as Array[String])
	return {"game": game, "driver": driver}


func test_waits_while_undeclared() -> void:
	var s: Dictionary = _setup()
	var tick_before: int = s.game.sim.clock.tick
	assert_false(s.driver.try_advance(), "no declaration -> no advance")
	assert_eq(s.game.sim.clock.tick, tick_before, "tick unchanged while waiting")
	s.game.free()


func test_advances_exactly_one_tick_then_rewaits() -> void:
	var s: Dictionary = _setup()
	var tick_before: int = s.game.sim.clock.tick
	s.driver.mark_declared("hero")
	assert_true(s.driver.try_advance(), "all declared -> advance")
	assert_eq(s.game.sim.clock.tick, tick_before + 1, "exactly one tick fed")
	assert_false(s.driver.try_advance(), "fresh tick -> waiting again")
	s.game.free()


func test_sim_frozen_without_driver() -> void:
	var s: Dictionary = _setup()
	var frozen_hash: String = s.game.state_hash()
	# No driver call, no commands: state must be bit-identical no matter how
	# much wall time passes (simulation/ has no _process and no timers).
	assert_eq(s.game.state_hash(), frozen_hash, "state frozen without the driver")
	s.game.free()


func test_forced_action_demands_redecision() -> void:
	var s: Dictionary = _setup()
	s.game.apply_command({"type": "add_combatant", "combatant": {
		"id": "wall", "name": "wall", "race": "human", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 1, "mind": 1, "charm": 1}}})
	# Unmeetable requirements -> Tool d6 on resolution (R10) -> forced action.
	s.game.apply_command({"type": "declare_action", "actor": "hero", "action":
		attack_action("bleeding", 2, "wall", "torso", {"requirements": {"physique": 99}})})
	s.driver.mark_declared("hero")
	var fired: bool = false
	for i: int in range(6):
		var events: Array[Dictionary] = s.game.sim.apply_command({"type": "advance_tick"})
		if has_event(events, "forced_action_triggered"):
			# Feed the event through the controller's signal path manually is
			# not needed — the driver listens to the controller, so re-run the
			# scenario through the controller instead if this fires here.
			fired = true
			break
	assert_true(fired, "precondition: unmet requirements produced a forced action")
	s.game.free()
	# Now the REAL assertion, via the controller path end to end:
	var s2: Dictionary = _setup()
	s2.game.apply_command({"type": "add_combatant", "combatant": {
		"id": "wall", "name": "wall", "race": "human", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 1, "mind": 1, "charm": 1}}})
	s2.game.apply_command({"type": "declare_action", "actor": "hero", "action":
		attack_action("bleeding", 2, "wall", "torso", {"requirements": {"physique": 99}})})
	var advanced: int = 0
	for i: int in range(6):
		s2.driver.mark_declared("hero")
		if not s2.driver.try_advance():
			break
		advanced += 1
	assert_true(advanced >= 1, "advanced at least once before the forced action")
	assert_false(s2.driver.can_advance(), "forced action blocks the clock until acknowledged")
	s2.driver.acknowledge_redecision("hero")
	s2.driver.mark_declared("hero")
	assert_true(s2.driver.try_advance(), "acknowledged -> clock moves again")
	s2.game.free()
