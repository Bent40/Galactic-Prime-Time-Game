extends SimTestBase
## KAN-7 run loop — GameController fight-over detection (the headless hinge of
## TITLE → BID → COMBAT → VERDICT → TITLE). The scene transitions themselves are
## not headless-testable, so these tests exercise the controller contract they hang
## on: combat_status() reports ONGOING / WIN / LOSS from live team membership, and
## combat_ended fires EXACTLY ONCE the first time the fight resolves.
##
## Deterministic defeat: a lethal suffocation on a combatant's torso (a human's
## torso is lethal + exposed) kills it within a few Clocks — the same mechanism
## test_condition_death.gd relies on. Fixed seeds; no RNG, no AI (a bare
## advance_tick never acts the enemy, so only the suffocated combatant changes).

const SEED := 14
const TICKS_PER_CLOCK := 10
const MAX_TICKS := 150  # ~15 Clocks — comfortably past the suffocation death timer


func _make_controller() -> Node:
	var script: GDScript = load("res://controller/game_controller.gd")
	return script.new()


## Stages a fresh controller with one party human + one enemy human, both alive.
func _stage(game: Node) -> void:
	game.start_combat(SEED, load_static_data())
	_add(game, "hero", "party")
	_add(game, "goon", "enemies")


func _add(game: Node, id: String, team: String) -> void:
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "race": "human", "team": team, "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}})


## Suffocates a combatant's torso (a deterministic lethal condition).
func _suffocate(game: Node, id: String) -> void:
	game.apply_command({"type": "apply_condition", "target": id, "part": "torso", "condition": "suffocation"})


## Advances one tick through the CONTROLLER (not the sim directly) so the fight-over
## check on the controller runs. Returns once the fight is over or MAX_TICKS elapse.
func _advance_until_over(game: Node) -> void:
	for _i: int in range(MAX_TICKS):
		if bool(game.combat_status().get("over", false)):
			return
		game.apply_command({"type": "advance_tick"})


func _advance_ticks(game: Node, ticks: int) -> void:
	for _i: int in range(ticks):
		game.apply_command({"type": "advance_tick"})


# ---------------------------------------------------------------- status detection

func test_status_ongoing_at_fight_start() -> void:
	var game: Node = _make_controller()
	_stage(game)
	var status: Dictionary = game.combat_status()
	assert_false(bool(status.get("over", true)), "fight is not over while both sides stand")
	assert_eq(String(status.get("outcome", "")), "ONGOING", "outcome is ONGOING at fight start")
	game.free()


func test_status_win_when_all_enemies_dead() -> void:
	var game: Node = _make_controller()
	_stage(game)
	_suffocate(game, "goon")
	_advance_until_over(game)
	assert_false(game.sim.combatants["goon"].alive, "precondition: the enemy suffocated to death")
	assert_true(game.sim.combatants["hero"].alive, "the party contestant is untouched and still live")
	var status: Dictionary = game.combat_status()
	assert_true(bool(status.get("over", false)), "fight is over once the last enemy falls")
	assert_eq(String(status.get("outcome", "")), "WIN", "no live enemy + live party = WIN")
	game.free()


func test_status_loss_when_all_party_dead() -> void:
	var game: Node = _make_controller()
	_stage(game)
	_suffocate(game, "hero")
	_advance_until_over(game)
	assert_false(game.sim.combatants["hero"].alive, "precondition: the party contestant suffocated to death")
	assert_true(game.sim.combatants["goon"].alive, "the enemy is untouched and still live")
	var status: Dictionary = game.combat_status()
	assert_true(bool(status.get("over", false)), "fight is over once the last party member falls")
	assert_eq(String(status.get("outcome", "")), "LOSS", "no live party = LOSS (even with a live enemy)")
	game.free()


# ---------------------------------------------------------------- one-shot signal

func test_combat_ended_fires_exactly_once() -> void:
	var game: Node = _make_controller()
	var count: Array[int] = [0]
	var last_outcome: Array[String] = [""]
	game.combat_ended.connect(func(e: Dictionary) -> void:
		count[0] += 1
		last_outcome[0] = String(e.get("outcome", "")))
	_stage(game)
	# Nothing fired before the fight is decided.
	_suffocate(game, "goon")
	_advance_until_over(game)
	assert_eq(count[0], 1, "combat_ended fired once when the fight resolved")
	assert_eq(last_outcome[0], "WIN", "the fired event carried the WIN outcome")
	# Keep advancing well past the resolution — the corpse stays down, and the latch
	# must NOT re-fire the signal on every subsequent tick.
	_advance_ticks(game, 30)
	assert_eq(count[0], 1, "combat_ended stays latched — exactly one fire across continued advancement")
	game.free()


## The generic sim_event carries combat_ended too (single emit path), so a listener
## on either signal sees the resolution — the pattern the scenes rely on.
func test_combat_ended_also_flows_on_sim_event() -> void:
	var game: Node = _make_controller()
	var saw: Array[bool] = [false]
	game.sim_event.connect(func(e: Dictionary) -> void:
		if String(e.get("type", "")) == "combat_ended":
			saw[0] = true)
	_stage(game)
	_suffocate(game, "goon")
	_advance_until_over(game)
	assert_true(saw[0], "combat_ended also surfaces on the generic sim_event stream")
	game.free()
