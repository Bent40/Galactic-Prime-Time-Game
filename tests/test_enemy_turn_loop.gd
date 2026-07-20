extends SimTestBase
## KAN3 — enemy-turn loop (release-blocking bug: the boss never fought back).
##
## The fix wires the enemy side into EVERY driver tick: ClockDriver.try_advance()
## runs the enemy turn (one ai_decide per ready AI combatant) BEFORE feeding the
## advance, and the HUD's END TURN routes through GameController.advance_moment(),
## which drives the PausedClockDriver. These tests prove, end to end through the
## controller + driver, that the Incine-Dile now CHOOSES actions each Moment and
## acts against the party — no sim change, fixed seeds only.


const GC_SCRIPT := "res://controller/game_controller.gd"


func _make_controller() -> Node:
	return (load(GC_SCRIPT) as GDScript).new()


## Stands up a real GameController with a fixed seed, the Incine-Dile boss at the
## origin, and a lone contestant adjacent to it, then attaches a PausedClockDriver
## with that contestant in the party and registers it via set_clock_driver. Returns
## the game, the driver, and a live event sink connected to sim_event (so every
## event the command stream produces — ai_decision, damage_applied, … — is captured).
func _stage(sim_seed: int, contestant_pos: Array) -> Dictionary:
	var game: Node = _make_controller()
	var events: Array[Dictionary] = []
	game.sim_event.connect(func(e: Dictionary) -> void: events.append(e))
	game.start_combat(sim_seed, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "vic", "name": "Vic", "race": "human", "team": "party",
		"position": contestant_pos,
		"traits": {"physique": 3, "reflexes": 1, "mind": 1, "charm": 1}}})
	var driver: PausedClockDriver = PausedClockDriver.new()
	driver.attach(game)
	driver.set_party(["vic"] as Array[String])
	game.set_clock_driver(driver)
	return {"game": game, "driver": driver, "events": events}


func _boss_decisions(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in events:
		if String(e.get("type", "")) == "ai_decision" and String(e.get("actor", "")) == "boss":
			out.append(e)
	return out


func _damage_to(events: Array[Dictionary], victim: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in events:
		if String(e.get("type", "")) == "damage_applied" and String(e.get("combatant", "")) == victim:
			out.append(e)
	return out


# --------------------------------------------------------- acceptance: fights back

## THE acceptance proof (the release-blocking bug): drive several Moments through
## advance_moment() and show the boss both DECIDES and lands blows on the party.
func test_boss_fights_back_through_advance_moment() -> void:
	var s: Dictionary = _stage(14, [1, 0])
	var game: Node = s.game
	var events: Array[Dictionary] = s.events

	# Torso HP before the fight (a body part losing HP is the acceptance signal).
	var torso_before: int = int(game.sim.combatants["vic"].parts["torso"]["hp"])

	# Play out several Moments. The contestant declares nothing this run — the
	# driver marks the party done inside advance_moment — so any action on the
	# board is the ENEMY side coming to life. Fixed seed, no wall clock, no RNG here.
	for moment: int in range(8):
		game.advance_moment()

	var decisions: Array[Dictionary] = _boss_decisions(events)
	assert_true(decisions.size() >= 1, "the boss DECIDED at least once across the playout (%d)" % decisions.size())
	var attacked := false
	for d: Dictionary in decisions:
		if String(d.get("choice", "")) == "attack":
			attacked = true
	assert_true(attacked, "the boss chose to ATTACK the party, not just idle")

	# The boss actually acted AGAINST the party: damage landed on the contestant
	# and a body part lost HP. Either alone is the fix; assert both for weight.
	var hits: Array[Dictionary] = _damage_to(events, "vic")
	assert_true(hits.size() >= 1, "the contestant took boss damage (%d hit(s))" % hits.size())
	var torso_after: int = int(game.sim.combatants["vic"].parts["torso"]["hp"])
	assert_true(torso_after < torso_before,
		"a contestant body part lost HP (torso %d -> %d)" % [torso_before, torso_after])
	game.free()


## Determinism guard: the same seed + same driver calls replays bit-identically.
func test_playout_is_deterministic() -> void:
	var hash_a := _playout_hash()
	var hash_b := _playout_hash()
	assert_eq(hash_a, hash_b, "same seed + same advance_moment sequence -> identical state hash")


func _playout_hash() -> String:
	var s: Dictionary = _stage(14, [1, 0])
	var game: Node = s.game
	for moment: int in range(8):
		game.advance_moment()
	var h: String = game.state_hash()
	game.free()
	return h


# ------------------------------------------------------- focused: try_advance drive

## A single try_advance() on a driver with a READY AI enemy issues the boss's
## declaration (an ai_decision) AND advances exactly one tick — run_enemy_turn only
## declares, it never advances the clock.
func test_try_advance_runs_the_boss_declaration() -> void:
	var s: Dictionary = _stage(14, [1, 0])
	var game: Node = s.game
	var events: Array[Dictionary] = s.events
	var tick_before: int = game.sim.clock.tick

	s.driver.mark_declared("vic")  # party consent so the paused gate opens
	assert_true(s.driver.try_advance(), "party declared -> the driver advances")
	assert_eq(game.sim.clock.tick, tick_before + 1, "exactly one tick fed (run_enemy_turn never advances)")
	assert_true(_boss_decisions(events).size() >= 1, "the boss declared (ai_decision issued) during the tick")
	game.free()


## With NO AI enemies on the board, try_advance() still advances exactly one tick
## and issues no ai_decision — the enemy-turn hook is a no-op when nobody is ready.
func test_try_advance_no_ai_still_one_tick() -> void:
	var game: Node = _make_controller()
	var events: Array[Dictionary] = []
	game.sim_event.connect(func(e: Dictionary) -> void: events.append(e))
	game.start_combat(14, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "solo", "name": "Solo", "race": "human", "team": "party",
		"position": [0, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	var driver: PausedClockDriver = PausedClockDriver.new()
	driver.attach(game)
	driver.set_party(["solo"] as Array[String])

	var tick_before: int = game.sim.clock.tick
	driver.mark_declared("solo")
	assert_true(driver.try_advance(), "all declared -> advance")
	assert_eq(game.sim.clock.tick, tick_before + 1, "exactly one tick with no AI to run")
	var ai_events: int = 0
	for e: Dictionary in events:
		if String(e.get("type", "")) == "ai_decision":
			ai_events += 1
	assert_eq(ai_events, 0, "no AI enemy -> no ai_decision issued")
	game.free()


# --------------------------------------------------- advance_moment fallback path

## Without a driver, advance_moment() is the unchanged fallback: a bare advance_tick
## through the command funnel (keeps every headless test that advances directly).
func test_advance_moment_falls_back_without_driver() -> void:
	var game: Node = _make_controller()
	game.start_combat(14, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "solo", "name": "Solo", "race": "human", "team": "party",
		"position": [0, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	var tick_before: int = game.sim.clock.tick
	var out: Array[Dictionary] = game.advance_moment()
	assert_eq(game.sim.clock.tick, tick_before + 1, "no driver -> advance_moment is a plain advance_tick")
	assert_true(has_event(out, "clock_moment_changed"), "the fallback returns the advance events directly")
	game.free()
