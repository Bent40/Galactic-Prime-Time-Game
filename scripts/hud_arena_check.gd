extends SceneTree
## ARENA / TURN-ORDER LIVENESS DRIVER (KAN-6) — proves the combat HUD's arena and
## tick-order rail reflect LIVE sim state (not fixtures) and that MOVE is real
## click-to-target. It stands up a real GameController, freezes the approved-mockup
## beat (harness-only pokes, exactly like a unit test / hud_preview.gd), then:
##
##   arena0.png — mockup state: tokens at their real hexes, rail from
##                view_turn_order(), on-the-clock highlight on the first ready
##                contestant (Dario).
##   arena1.png — after a real click-to-target MOVE of the active contestant to an
##                adjacent empty hex: the token has RELOCATED vs arena0.
##   arena2.png — after the active contestant commits a 2-Moment windup + END TURN:
##                the rail shows the WINDUP badge / reorders and the on-the-clock
##                highlight has ROTATED to the other contestant.
##
## The MOVE is driven through the SAME gui_input handler the click catcher uses
## (hud._on_arena_input with a synthesized left-click at the target hex's pixel),
## so the whole screen-pixel -> axial -> move path is exercised, not a shortcut.
##
## Run:  xvfb-run -a godot --path . -s scripts/hud_arena_check.gd
##   (NOT --headless — a real GL renderer is needed to capture the framebuffer;
##    ALSA "audio driver failed" lines in the log are harmless)
## Output PNGs: $HUD_DIR (default <project>/) / arena0..2.png
##
## HARD LINE: DRIVER/CONSUMER ONLY — never touches simulation/, controller/, data/
## or tests/. Same two documented driver-side spec choices as hud_interact.gd:
##   * the boss is added with dodge_threshold STRIPPED (deterministic breach path);
##   * Dario is given Charm 30 (R6 over-cap grants exactly 1 Camera Call stack).

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")
# field_renderer.gd is LOADED AT RUNTIME (its _ready references the `Game` autoload,
# which is not resolvable at this script's compile time). Set in _initialize().
var fr: GDScript

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

	fr = load("res://scenes/field/field_renderer.gd") as GDScript
	gc = GameControllerScript.new()
	gc.name = "ArenaController"
	root_node.add_child(gc)
	gc.start_combat(SEED)

	_add_boss()
	_add_contestant(IMANI, "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	_add_contestant(DARIO, "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1])

	# Freeze the approved-mockup beat (harness-only poke, like a unit test).
	gc.sim.clock.tick = 23  # Clock 3 · Moment 07
	var h = gc.sim.hype
	h.meter = 68
	h.band = "hot"
	h.active_goal = {
		"id": "show_off", "name": "Show-Off!", "kind": "exposed_strike",
		"payout": 45, "clocks_left": 2, "progress": 0, "params": {},
	}
	h.spotlight = {}

	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)

	# ---- arena0: mockup state -------------------------------------------------
	await _settle()
	_probe("arena0 (mockup)")
	await _render("arena0.png")

	# ---- arena1: real click-to-target MOVE of the active contestant -----------
	# Active is Dario at [0,1]; step him to adjacent empty hex [1,1] by ARMING MOVE
	# and feeding a left-click at that hex's on-screen pixel through the gui_input
	# handler (screen pixel -> pixel_to_axial -> move command).
	var mover: String = hud._active_actor
	var before: Vector2 = _token_screen(mover)
	hud._on_move()                                   # arm MOVE targeting
	await _settle()
	_probe("arena_move (targeting armed)")
	await _render("arena_move.png")                  # cyan reachable-hex highlight
	_click_hex(Vector2i(1, 1))                        # click the target hex
	await _settle()
	var after: Vector2 = _token_screen(mover)
	print("  MOVE %s: axial=%s  screen %s -> %s  (Δ=%.1fpx)" % [
		mover, str(_axial(mover)), str(before.round()), str(after.round()), before.distance_to(after)])
	_probe("arena1 (after MOVE)")
	await _render("arena1.png")

	# ---- arena2: 2-Moment windup + END TURN — rail badge + rotation -----------
	# Dario (still active) commits a real cost-2 attack on the boss's flamethrower
	# arm -> windup_pending; the rail shows WINDUP and the on-the-clock highlight
	# rotates to Imani. END TURN advances the Moment; the windup persists (resolves
	# at tick+2), so arena2 still shows the badge + the rotated highlight.
	gc.apply_command({"type": "declare_action", "actor": DARIO, "action": {
		"kind": "attack", "key": "pressure_strike", "cost": 2, "attack_range": 3,
		"damage": {"type": "crushed", "amount": 6},
		"targets": [{"id": BOSS, "part": "left_hand"}]}})
	hud._on_end_turn()
	await _settle()
	print("  after windup+END TURN: active=%s  dario_windup=%s" % [
		hud._active_actor, str(_windup_pending(DARIO))])
	_probe("arena2 (windup + rotation)")
	await _render("arena2.png")

	print("")
	print("moved_ok=%s  rotated_ok=%s  windup_ok=%s" % [
		str(before.distance_to(after) > 8.0),
		str(hud._active_actor == IMANI),
		str(_windup_pending(DARIO))])
	quit(0)


# --------------------------------------------------------------------- helpers
func _add_boss() -> void:
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


## The active actor's on-screen token point, via the HUD's live board transform.
func _token_screen(id: String) -> Vector2:
	var a: Vector2i = _axial(id)
	return fr.axial_to_pixel(a.x, a.y, hud._arena_eff) + hud._arena_off


func _axial(id: String) -> Vector2i:
	var c = gc.sim.combatants.get(id)
	return Vector2i(int(c.position.x), int(c.position.y)) if c != null else Vector2i.ZERO


func _windup_pending(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	return c != null and bool(c.windup_pending)


## Synthesize a left-click at a hex's on-screen pixel and feed it through the real
## gui_input handler (proves the screen-pixel -> axial -> move path end to end).
func _click_hex(hex: Vector2i) -> void:
	var px: Vector2 = fr.axial_to_pixel(hex.x, hex.y, hud._arena_eff) + hud._arena_off
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = px
	hud._on_arena_input(ev)


## Read a few ground-truth numbers straight off the sim so the log corroborates
## what each PNG should show.
func _probe(tag: String) -> void:
	var order: Array = gc.view_turn_order()
	var rail: Array = []
	for e: Dictionary in order:
		var mark := ""
		if bool(e.get("windup_pending", false)):
			mark = "*WINDUP"
		elif String(e.get("id", "")) == hud._active_actor:
			mark = "<NOW"
		rail.append("%s(nat%d)%s" % [String(e.get("id", "")), int(e.get("next_action_tick", 0)), mark])
	print("  %-26s active=%-6s rail=[%s]" % [tag, hud._active_actor, ", ".join(rail)])


func _settle() -> void:
	for i in 6:
		await process_frame


func _render(fname: String) -> void:
	await process_frame
	await process_frame
	var img: Image = root_node.get_texture().get_image()
	var path: String = out_dir + fname
	var err: int = img.save_png(path)
	if err != OK:
		push_error("save_png failed (%d) -> %s" % [err, path])
	else:
		print("render -> %s  %s" % [path, str(img.get_size())])
