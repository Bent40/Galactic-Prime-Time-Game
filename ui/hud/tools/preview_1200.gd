extends SceneTree
## HUD v2 SCALE-CHECK DRIVER — renders combat_hud.tscn at 1200x750 (instead of
## the standard 1600x1000) to sanity-check that the new shell layout scales.
## Mirrors scripts/hud_preview.gd's fixture staging exactly (same roster, same
## frozen beat); DRIVER/CONSUMER ONLY — never touches simulation/, controller/,
## data/ or tests/. Lives under ui/hud/tools/ because the HUD rework owns it.
##
## Run:  HUD_OUT=/abs/out.png xvfb-run -s "-screen 0 1920x1200x24" -a \
##         godot --path . -s ui/hud/tools/preview_1200.gd

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")

const SEED := 14


func _initialize() -> void:
	var out := OS.get_environment("HUD_OUT")
	if out == "":
		out = "res://hud_render_1200.png"

	var root := get_root()
	DisplayServer.window_set_size(Vector2i(1200, 750))
	root.size = Vector2i(1200, 750)

	var gc = GameControllerScript.new()
	gc.name = "Preview1200Controller"
	root.add_child(gc)
	gc.start_combat(SEED)

	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}})
	_add_contestant(gc, "imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	_add_contestant(gc, "dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1])

	# Same frozen beat as scripts/hud_preview.gd (harness-only fixture pokes).
	gc.sim.clock.tick = 23  # Clock 3 · Moment 07
	var dario = gc.sim.combatants["dario"]
	dario.parts["right_arm"]["hp"] = 1
	dario.conditions["right_arm"] = {"bleeding": {"tier": 1, "delayed": false}}
	var h = gc.sim.hype
	h.meter = 68
	h.band = "hot"
	h.active_goal = {
		"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike",
		"payout": 45, "clocks_left": 2, "progress": 0, "params": {},
	}
	h.spotlight = {}

	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	hud.bind(gc)

	for i in 6:
		await process_frame

	var img := root.get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, out])
	print("HUD 1200x750 render saved -> %s  %s" % [out, str(img.get_size())])
	quit()


func _add_contestant(gc, id: String, cname: String, traits: Dictionary, pos: Array) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1,
	}})
