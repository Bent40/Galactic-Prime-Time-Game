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
	# Dario carries his AUTHORED bit (decision log #25) verbatim from
	# demo_loadouts.json — the wounded bit below is HIS. Imani has NO bit
	# (canonical — zero camera interest); the sim rejects the_bit from her.
	_add_contestant(gc, "dario", "Dario \"Encore\"", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [2, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}})
	_add_grunt(gc)

	# ---- REAL DEEDS (through the command funnel, so the EVIDENCE block quotes a
	# genuine ledger — the record is never poked): a takedown, the breaching hit,
	# a bit done while bleeding (by DARIO — decision log #25: only he has an
	# authored bit; this step used to be Imani's and moved), a wounded camera
	# call, and an un-answered goal.
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 5},
		"attack_range": 1, "targets": [{"id": "grunt", "part": "torso"}]}})
	gc.apply_command({"type": "advance_tick"})
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "bleeding", "amount": 10},
		"attack_range": 1, "targets": [{"id": "boss", "part": "right_hand"}]}})
	gc.apply_command({"type": "advance_tick"})  # -> breach_opened (real slice win)
	gc.apply_command({"type": "apply_condition", "target": "dario", "part": "left_arm", "condition": "bleeding", "tier": 1})
	gc.apply_command({"type": "bit", "actor": "dario"})  # -> bit_under_fire (Dario, wounded)
	gc.apply_command({"type": "treat", "target": "dario", "part": "left_arm", "condition": "bleeding", "mode": "resolve"})
	gc.apply_command({"type": "apply_condition", "target": "imani", "part": "left_arm", "condition": "bleeding", "tier": 1})
	gc.apply_command({"type": "camera_call", "actor": "imani", "target": "imani"})  # -> spotlight_gamble (Imani, wounded)
	gc.apply_command({"type": "treat", "target": "imani", "part": "left_arm", "condition": "bleeding", "mode": "resolve"})
	for i in range(2 * 10):  # two Clock laps: a goal is offered, then dies un-met
		gc.apply_command({"type": "advance_tick"})

	# ---- PREVIEW STAGING (harness-only fixture; NOT how the card gets its data) ----
	# Freeze the approved-mockup end-of-run beat by poking the NON-evidence state.
	gc.sim.tags.held["imani"] = {"survivor": true, "fan_favorite": true}  # -> THE UNBROKEN + FAN FAVORITE
	gc.sim.hype.meter = 214                                               # -> HYPE EARNED 214
	gc.sim.hype.band = "on_fire"                                          # -> peak crowd ON FIRE, 5 stars
	# --------------------------------------------------------------------------

	# Log the real evidence the card will quote (proof the block is ledger-fed).
	# Dario's ledger is printed too: the wounded bit is HIS deed now (decision
	# log #25 — Imani has no authored bit), so it lives on his record.
	for e in gc.view_verdict("imani").get("evidence", []):
		print("EVIDENCE  " + String((e as Dictionary).get("line", "")))
	for e in gc.view_verdict("dario").get("evidence", []):
		print("EVIDENCE[dario]  " + String((e as Dictionary).get("line", "")))

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
	# dodge_threshold stripped (same trick as the tests/playtest) so the staged
	# breaching hit lands deterministically without consuming the AI d6 stream.
	var boss_traits := {}
	var enemies = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	for entry in enemies as Array:
		if String((entry as Dictionary).get("key", "")) == "incinedile":
			boss_traits = ((entry as Dictionary).get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})


func _add_grunt(gc) -> void:
	# A warm body for the staged takedown deed (real kill, real evidence).
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "grunt", "name": "Pit Grunt", "race": "human", "team": "enemies",
		"position": [2, 0], "traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}})


func _add_contestant(gc, id: String, cname: String, traits: Dictionary, pos: Array, extra: Dictionary = {}) -> void:
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1,
	}
	combatant.merge(extra, true)
	gc.apply_command({"type": "add_combatant", "combatant": combatant})
