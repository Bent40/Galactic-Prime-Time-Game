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


func test_view_broadcast_projects_the_audience_economy() -> void:
	# Slice-playtest finding F3: the HUD needs hype/goal/spotlight/tags and the
	# boss's hidden-part state, none of which lived in a view before.
	var game: Node = _make_controller()
	game.start_combat(14, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "A", "race": "human", "position": [0, 1],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		# a performs a bit below — the sim now rejects the_bit from an actor with
		# no authored bit (decision log #25), so the spec grants one.
		"bit": {"key": "bow", "name": "The Bow", "line": "a bow, mid-combat"},
	}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "enemy": "incinedile", "position": [0, 0],
	}})

	# --- view_broadcast: the audience economy ---
	var b: Dictionary = game.view_broadcast()
	assert_true(b.has("hype") and b.has("goal") and b.has("spotlight") and b.has("tags"),
		"broadcast projection carries hype / goal / spotlight / tags")
	var band := String((b["hype"] as Dictionary).get("band", ""))
	var disp := String((b["hype"] as Dictionary).get("band_display", ""))
	var expected: Dictionary = {"cold": "COLD OPEN", "warm": "WARMING UP", "hot": "ELECTRIC", "on_fire": "ON FIRE"}
	assert_eq(disp, String(expected.get(band, "")), "band_display maps the sim band to the owner-blessed name")
	assert_false(disp.is_empty(), "band_display is populated")
	# A bit generates in-progress tag state that must surface in the projection.
	game.apply_command({"type": "bit", "actor": "a"})
	var b2: Dictionary = game.view_broadcast()
	var atags: Dictionary = (b2["tags"] as Dictionary).get("a", {})
	assert_eq(int((atags.get("progress", {}) as Dictionary).get("the_bit", 0)), 1,
		"the contestant's in-progress tag surfaces in view_broadcast")
	assert_true(int((b2["hype"] as Dictionary).get("meter", 0)) > 0, "the bit's spectacle moved the meter")

	# --- view_combatants: the hidden network stays hidden until breach ---
	var boss_view: Dictionary = {}
	for cv: Dictionary in game.view_combatants():
		if String(cv.get("id", "")) == "boss":
			boss_view = cv
	assert_false(bool(boss_view.get("breached", true)), "boss starts un-breached")
	var network_present := false
	var network_hidden := false
	for p: Dictionary in boss_view.get("parts", []):
		if String(p.get("key", "")) == "network":
			network_present = true
			network_hidden = bool(p.get("hidden", false))
	assert_true(network_present, "the network part is in the view")
	assert_true(network_hidden, "the network reads hidden while un-breached — the HUD keeps it off-screen")
	game.free()
