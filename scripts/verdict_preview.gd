extends SceneTree
## VERDICT-CARD PREVIEW / VISUAL-REGRESSION DRIVER (KAN-7) — renders
## ui/screens/verdict_card.tscn against a frozen FINISHED sim state and saves a
## PNG for comparison with the approved mockup
## (docs/ux-designs/demo-slice-2026-07-19/renders/verdict-card.png).
##
## Run:  bash scripts/render_verdict.sh   (xvfb gives a real GL renderer)
##  or:  xvfb-run -s "-screen 0 1920x1200x24" -a godot --path . -s scripts/verdict_preview.gd
##
## The card is presentation-only and reads the sim ONLY through the GameController
## view API (view_verdict). This DRIVER is a fixture: it stands up a real
## GameController, drives the roster in through real add_combatant commands, then
## (harness-only, exactly like a unit test) pokes a few sim fields to freeze the
## end-of-run beat the mockup shows — Imani alive holding two slice-tags, the
## Incine-Dile breached to Phase 2, hype banked. The card never sees any of that
## poking — it re-derives everything from view_verdict().

const GameControllerScript := preload("res://controller/game_controller.gd")
const VERDICT_SCENE := preload("res://ui/screens/verdict_card.tscn")

const SEED := 14


func _initialize() -> void:
	var out := OS.get_environment("VERDICT_OUT")
	if out == "":
		out = "res://verdict_render.png"

	var root := get_root()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	root.size = Vector2i(1600, 1000)

	var gc = GameControllerScript.new()
	gc.name = "PreviewController"
	root.add_child(gc)
	gc.start_combat(SEED)

	_add_boss(gc)
	_add_contestant(gc, "imani", "Imani \"The Door\"", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	_add_contestant(gc, "dario", "Dario \"Encore\"", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 30}, [2, 1])

	# ---- PREVIEW STAGING (harness-only fixture; NOT how the card gets its data) ----
	# Freeze the approved-mockup end-of-run beat by poking sim state directly.
	gc.sim.tags.held["imani"] = {"survivor": true, "fan_favorite": true}  # -> THE UNBROKEN + FAN FAVORITE
	gc.sim.combatants["boss"].breached = true                             # -> boss BREACHED, Phase 2, slice win
	gc.sim.hype.meter = 214                                               # -> HYPE EARNED 214
	gc.sim.hype.band = "on_fire"                                          # -> peak crowd ON FIRE, 5 stars
	# --------------------------------------------------------------------------

	var card := VERDICT_SCENE.instantiate()
	root.add_child(card)
	card.bind(gc, "imani")

	# let layout settle + the GL frame render before we grab the framebuffer
	await process_frame
	await process_frame
	await process_frame
	await process_frame

	var img := root.get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, out])
	print("Verdict render saved -> %s  %s" % [out, str(img.get_size())])
	quit()


func _add_boss(gc) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}})


func _add_contestant(gc, id: String, cname: String, traits: Dictionary, pos: Array) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits,
	}})
