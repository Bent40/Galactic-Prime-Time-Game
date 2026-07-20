extends SimTestBase
## KAN3-S3 — the controller's read-only view API + the renderer's pure math
## (both headless-testable; drawing itself is proven by the xvfb screenshot).


func _game() -> Node:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "Hero", "race": "human", "position": [2, 3],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	return game


func test_view_reflects_sim_state() -> void:
	var game: Node = _game()
	var views: Array[Dictionary] = game.view_combatants()
	assert_eq(views.size(), 1, "one combatant in view")
	var v: Dictionary = views[0]
	assert_eq(String(v.get("name", "")), "Hero", "display name projected")
	assert_eq(v.get("position", []), [2, 3], "position projected")
	assert_eq((v.get("parts", []) as Array).size(), 6, "six human parts")
	game.apply_command({"type": "apply_condition", "target": "a", "part": "torso", "condition": "bleeding"})
	game.apply_command({"type": "heal", "target": "a", "part": "torso", "amount": 0})
	var torso: Dictionary = {}
	for part: Dictionary in game.view_combatants()[0]["parts"]:
		if part["key"] == "torso":
			torso = part
	assert_eq(int((torso.get("conditions", {}) as Dictionary).get("bleeding", 0)), 1, "condition tier projected")
	game.free()


func test_view_is_plain_data() -> void:
	var game: Node = _game()
	# The view must be safe to serialize (no object references leaking out).
	var text: String = JSON.stringify(game.view_combatants())
	assert_true(text.length() > 0 and not text.contains("RefCounted"), "pure primitives")
	var clock: Dictionary = game.view_clock()
	assert_true(clock.has("tick") and clock.has("moment"), "clock view shape")
	game.free()


func test_renderer_math_pure() -> void:
	var script: GDScript = load("res://scenes/field/field_renderer.gd")
	var origin: Vector2 = script.axial_to_pixel(0, 0, 30.0)
	assert_eq(origin, Vector2.ZERO, "origin maps to zero")
	var right: Vector2 = script.axial_to_pixel(1, 0, 30.0)
	var down: Vector2 = script.axial_to_pixel(0, 1, 30.0)
	assert_true(right.x > 0.0 and is_equal_approx(right.y, 0.0), "q advances x only")
	assert_true(down.x > 0.0 and down.y > 0.0, "r advances diagonally (pointy-top)")
	var pts: PackedVector2Array = script.hex_points(Vector2(100, 100), 30.0)
	assert_eq(pts.size(), 6, "six hex vertices")
	for p: Vector2 in pts:
		assert_true(is_equal_approx(p.distance_to(Vector2(100, 100)), 30.0), "vertices on the radius")


func test_pixel_to_axial_round_trips() -> void:
	# pixel_to_axial is the inverse the HUD uses to turn a click back into a hex;
	# it must recover every axial coord axial_to_pixel produces, at any hex size.
	var script: GDScript = load("res://scenes/field/field_renderer.gd")
	var coords: Array = [
		Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
		Vector2i(0, -1), Vector2i(2, -1), Vector2i(-2, 3), Vector2i(3, 3),
		Vector2i(-3, -2), Vector2i(4, -5),
	]
	for size: float in [18.0, 30.0, 44.0]:
		for c: Vector2i in coords:
			var px: Vector2 = script.axial_to_pixel(c.x, c.y, size)
			var back: Vector2i = script.pixel_to_axial(px, size)
			assert_eq(back, c, "round-trip %s @ size %s" % [str(c), str(size)])
	# A click landing anywhere inside a hex still rounds to that hex's centre.
	var jitter: Vector2 = script.axial_to_pixel(2, -1, 30.0) + Vector2(6.0, -4.0)
	assert_eq(script.pixel_to_axial(jitter, 30.0), Vector2i(2, -1), "off-centre click snaps to the hex")


func test_verdict_view_projects_outcome_epithet_and_breach() -> void:
	# Stand up a FINISHED state: Imani alive holding two slice-tags, the Incine-Dile
	# breached to Phase 2, hype banked. Pokes sim fields directly (harness-only,
	# exactly like the other sim tests) — view_verdict re-derives everything.
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "imani", "name": "Imani \"The Door\"", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile", "team": "enemies",
		"position": [0, 0]}})
	game.sim.tags.held["imani"] = {"survivor": true, "fan_favorite": true}
	game.sim.combatants["boss"].breached = true
	game.sim.hype.meter = 214
	game.sim.hype.band = "on_fire"

	var v: Dictionary = game.view_verdict("imani")
	assert_eq(String(v.get("outcome", "")), "SURVIVED", "alive contestant SURVIVED")
	assert_eq(int(v.get("hype_earned", 0)), 214, "hype meter projected")
	assert_eq(String(v.get("peak_band", "")), "ON FIRE", "band_display projected")
	assert_eq(String((v.get("epithet", {}) as Dictionary).get("name", "")), "THE UNBROKEN",
		"epithet derived from the survivor tag")
	assert_eq(String((v.get("crowd_verdict", {}) as Dictionary).get("name", "")), "FAN FAVORITE",
		"crowd verdict derived from the fan_favorite tag")
	assert_true(int((v.get("crowd_verdict", {}) as Dictionary).get("stars", 0)) >= 1,
		"stars derived from the peak band")
	assert_true(bool((v.get("boss", {}) as Dictionary).get("breached", false)), "boss reads breached")
	assert_eq(int((v.get("boss", {}) as Dictionary).get("phase", 0)), 2, "breach = Phase 2 reached")
	assert_true(bool(v.get("slice_win", false)), "a breach is a slice win")

	# A DIED contestant flips the outcome (and only the outcome-derived fields).
	game.sim.combatants["imani"].alive = false
	assert_eq(String(game.view_verdict("imani").get("outcome", "")), "DIED",
		"a dead contestant reads DIED")
	game.free()


func test_turn_order_projects_and_reflects_windup() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "A", "race": "human", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "b", "name": "B", "race": "human", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	var order: Array = game.view_turn_order()
	assert_eq(order.size(), 2, "both live combatants in turn order")
	assert_true(bool(order[0].get("is_contestant", false)), "humans flagged as contestants")
	assert_true(bool(order[0].get("ready", false)), "everyone is ready at tick 0")
	# a commits a 2-Moment windup -> next_action_tick advances, winding up, not ready, sorts last.
	game.apply_command({"type": "declare_action", "actor": "a", "action": {
		"kind": "attack", "cost": 2, "attack_range": 3,
		"damage": {"type": "bleeding", "amount": 1}, "targets": [{"id": "b", "part": "torso"}]}})
	var order2: Array = game.view_turn_order()
	var a_entry: Dictionary = {}
	for e: Dictionary in order2:
		if String(e.get("id", "")) == "a":
			a_entry = e
	assert_true(bool(a_entry.get("windup_pending", false)), "a is winding up")
	assert_false(bool(a_entry.get("ready", true)), "a is not ready mid-windup")
	assert_true(int(a_entry.get("next_action_tick", 0)) > 0, "a's next action is scheduled later")
	assert_eq(String((order2[order2.size() - 1] as Dictionary).get("id", "")), "a", "the winding-up actor sorts to the back")
	game.free()
