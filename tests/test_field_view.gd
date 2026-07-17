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
