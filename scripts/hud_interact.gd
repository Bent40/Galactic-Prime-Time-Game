extends SceneTree
## HUD INTERACTION DRIVER (KAN-6) — proves the combat HUD is PLAYABLE: it drives a
## scripted CLICK SEQUENCE through the SAME handler methods the HUD's buttons call
## (hud._on_camera_call / _declare_skill_attack / _on_bit / _on_end_turn), rendering
## a PNG after each step so the live loop can be verified by eye. Each command goes
## through GameController.apply_command; the HUD re-binds off the resulting sim_event.
##
## Run:  xvfb-run -a godot --path . -s scripts/hud_interact.gd
##   (NOT --headless — a real GL renderer is needed to capture the framebuffer;
##    ALSA "audio driver failed" lines in the log are harmless)
## Output PNGs: $HUD_DIR (default <project>/) / hud_step0..4.png
##
## HARD LINE: DRIVER/CONSUMER ONLY — it never touches simulation/, controller/,
## data/ or tests/. Two documented DRIVER-SIDE spec choices (not engine edits, and
## exactly what scripts/slice_playtest.gd and the engine's own tests already do):
##   * The boss is added with dodge_threshold STRIPPED so the scripted breach is
##     deterministic (the dodge d6 would otherwise negate ~half of aimed rounds
##     while the boss is not Exposed).
##   * Dario is given Charm 30 so the R6 over-cap formula (Charm-10)/20 grants
##     exactly 1 Camera Call stack (stacks derive ONLY from Charm).

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")

const SEED := 14
const IMANI := "imani"
const DARIO := "dario"
const BOSS := "boss"

var gc
var hud
var root_node
var out_dir := ""


func _initialize() -> void:
	out_dir = OS.get_environment("HUD_DIR")
	if out_dir == "":
		out_dir = "res://"
	if not out_dir.ends_with("/"):
		out_dir += "/"

	root_node = get_root()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	root_node.size = Vector2i(1600, 1000)

	gc = GameControllerScript.new()
	gc.name = "InteractController"
	root_node.add_child(gc)
	gc.start_combat(SEED)

	_add_boss()
	_add_contestant(IMANI, "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	_add_contestant(DARIO, "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1])

	# Freeze the approved-mockup beat (harness-only poke, like a unit test / hud_preview).
	gc.sim.clock.tick = 23  # Clock 3 · Moment 07
	var h = gc.sim.hype
	h.meter = 68
	h.band = "warm"  # consistent with the meter; it climbs to hot/on_fire on air
	h.active_goal = {
		"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike",
		"payout": 45, "clocks_left": 2, "progress": 0, "params": {},
	}
	h.spotlight = {}

	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)
	hud.set_active_actor(DARIO)

	# ---- STEP 0: initial state -------------------------------------------------
	await _render("hud_step0.png")
	_probe("step0 (initial)")

	# ---- STEP 1: CAMERA CALL, then THE BIT under the hot lens -------------------
	# Camera Call sets a spotlight on Dario; the immediate Bit is attributed to
	# Dario, so it is DOUBLED — the hype meter jumps. (Camera Call alone scores 0;
	# its whole point is the doubling, which the Bit realizes.)
	hud._on_camera_call()
	hud._on_bit()
	await _render("hud_step1.png")
	_probe("step1 (camera call + bit)")

	# ---- STEP 2: attack the flamethrower arm + END TURN ------------------------
	# FEINT declares a real bleeding attack on left_hand; END TURN resolves it.
	hud._declare_skill_attack(DARIO, "feint")
	hud._on_end_turn()
	await _render("hud_step2.png")
	_probe("step2 (one feint resolved — arm bleeds, no breach yet)")

	# ---- STEP 3: keep attacking until the BREACH -------------------------------
	# The next bleeding hit advances bleeding T1 -> T2 (one attack-advance per tick),
	# which is the boss's condition_tier breach — the network unmasks.
	var safety := 0
	while not _boss_breached() and safety < 6:
		safety += 1
		hud._declare_skill_attack(DARIO, "feint")
		hud._on_end_turn()
	await _render("hud_step3.png")
	_probe("step3 (BREACH — network exposed)")

	# ---- STEP 4: THE BIT (escalating spectacle) --------------------------------
	hud._on_bit()
	await _render("hud_step4.png")
	_probe("step4 (second bit — spectacle up)")

	print("")
	print("BREACHED = %s   (0 = clean run)" % str(_boss_breached()))
	quit(0 if _boss_breached() else 2)


# --------------------------------------------------------------------- helpers
func _add_boss() -> void:
	# Strip dodge_threshold from the seeded traits so the scripted breach is
	# deterministic (driver-side spec choice; see the header + slice_playtest.gd).
	var boss_traits: Dictionary = {}
	var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	for entry: Variant in enemies as Array:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": BOSS, "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1,
	}})


func _boss_breached() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.breached)


## Read a few ground-truth numbers straight off the sim (NOT the HUD) so the log
## corroborates what the PNG should show.
func _probe(tag: String) -> void:
	var h = gc.sim.hype
	var b = gc.sim.combatants.get(BOSS)
	var arm: Dictionary = b.parts.get("left_hand", {})
	var bleed: int = b.condition_tier("left_hand", "bleeding")
	var spot: String = String((h.spotlight as Dictionary).get("target", "")) if not (h.spotlight as Dictionary).is_empty() else "-"
	print("  %-46s hype=%3d band=%-7s arm_hp=%2d/%d bleed=T%d breached=%s spotlight=%s" % [
		tag, int(h.meter), String(h.band), int(arm.get("hp", 0)),
		int(arm.get("base_max_hp", 0)), bleed, str(bool(b.breached)), spot])


func _render(fname: String) -> void:
	# Let layout settle + the GL frame render before grabbing the framebuffer.
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root_node.get_texture().get_image()
	var path: String = out_dir + fname
	var err: int = img.save_png(path)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, path])
	else:
		print("render -> %s  %s" % [path, str(img.get_size())])
