extends SimTestBase
## KAN3-S1 — GameController wiring: command funnel, event re-emit (generic +
## typed), constructor-friendliness (no scene tree needed).


func _make_controller() -> Node:
	var script: GDScript = load("res://controller/game_controller.gd")
	return script.new()


func test_controller_funnels_and_reemits() -> void:
	var game: Node = _make_controller()
	var generic: Array[Dictionary] = []
	var typed_added: Array[Dictionary] = []
	game.sim_event.connect(func(e: Dictionary) -> void: generic.append(e))
	game.combatant_added.connect(func(e: Dictionary) -> void: typed_added.append(e))
	game.start_combat(1234, load_static_data())
	var returned: Array[Dictionary] = game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "a", "race": "human", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}})
	returned.append_array(game.apply_command({"type": "advance_tick"}))
	assert_eq(generic.size(), returned.size(), "every returned event re-emitted on sim_event")
	assert_eq(typed_added.size(), 1, "typed combatant_added fired exactly once")
	assert_event(returned, "clock_moment_changed", "advance produced clock movement")
	assert_true(game.state_hash() != "", "state hash exposed through the controller")
	game.free()


func test_rejected_commands_emit_typed_rejection() -> void:
	var game: Node = _make_controller()
	var rejections: Array[Dictionary] = []
	game.command_rejected.connect(func(e: Dictionary) -> void: rejections.append(e))
	game.start_combat(1, load_static_data())
	game.apply_command({"type": "definitely_not_a_command"})
	assert_eq(rejections.size(), 1, "rejection surfaced as its typed signal")
	game.free()


func test_apply_before_start_is_safe() -> void:
	var game: Node = _make_controller()
	var events: Array[Dictionary] = game.apply_command({"type": "advance_tick"})
	assert_true(events.is_empty(), "no sim -> empty result, no crash")
	game.free()
