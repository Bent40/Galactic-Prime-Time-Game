extends SceneTree
## HUD PREVIEW / VISUAL-REGRESSION DRIVER (KAN-6) — renders combat_hud.tscn against
## a frozen mid-fight sim state and saves a PNG for comparison with the approved
## mockup (docs/ux-designs/demo-slice-2026-07-19/renders/combat-hud.png).
##
## Run:  bash scripts/render_hud.sh          (xvfb gives a real GL renderer)
##  or:  xvfb-run -s "-screen 0 1920x1200x24" -a godot --path . -s scripts/hud_preview.gd
##
## The HUD is presentation-only and reads the sim ONLY through the GameController
## view API. This DRIVER is a fixture: it stands up a real GameController, drives
## the roster in through real add_combatant commands, then (harness-only, exactly
## like a unit test) pokes a few sim fields to freeze the exact beat the mockup
## shows. The HUD never sees any of that poking — it re-derives everything from
## view_clock / view_broadcast / view_combatants.

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")

const SEED := 14


func _initialize() -> void:
	var out := OS.get_environment("HUD_OUT")
	if out == "":
		out = "res://hud_render.png"

	var root := get_root()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	root.size = Vector2i(1600, 1000)

	var gc = GameControllerScript.new()
	gc.name = "PreviewController"
	root.add_child(gc)
	gc.start_combat(SEED)

	_add_boss(gc)
	_add_contestant(gc, "imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	# Dario carries his AUTHORED bit (decision log #25) verbatim from
	# demo_loadouts.json; Imani has none (canonical — zero camera interest).
	_add_contestant(gc, "dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}})

	# ---- PREVIEW STAGING (harness-only fixture; NOT how the HUD gets its data) ----
	# Freeze the approved-mockup beat by poking sim state directly, like a test.
	gc.sim.clock.tick = 23  # Clock 3 (tick/10 + 1) · Moment 07 (10 - tick % 10)
	var dario = gc.sim.combatants["dario"]
	dario.parts["right_arm"]["hp"] = 1                               # 1/2 -> danger ramp
	dario.conditions["right_arm"] = {"bleeding": {"tier": 1, "delayed": false}}
	var h = gc.sim.hype
	h.meter = 68
	h.band = "hot"                                                   # -> band_display ELECTRIC
	h.active_goal = {
		"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike",
		"payout": 45, "clocks_left": 2, "progress": 0, "params": {},
	}
	h.spotlight = {}   # Camera Call available (unspent) — the mockup's CTA state
	# --------------------------------------------------------------------------

	var hud := HUD_SCENE.instantiate()
	root.add_child(hud)
	hud.bind(gc)

	# let layout settle + the GL frame render before we grab the framebuffer
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var img := root.get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, out])
	print("HUD render saved -> %s  %s" % [out, str(img.get_size())])
	quit()


func _add_boss(gc) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}})


func _add_contestant(gc, id: String, cname: String, traits: Dictionary, pos: Array, extra: Dictionary = {}) -> void:
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1,
	}
	combatant.merge(extra, true)
	gc.apply_command({"type": "add_combatant", "combatant": combatant})
