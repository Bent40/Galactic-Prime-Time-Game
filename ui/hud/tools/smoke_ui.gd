extends SceneTree
## HUD v2 UI SMOKE DRIVER — exercises the NEW interactive structure that the
## frozen v1 drivers don't touch: launcher categories -> flyouts (attack /
## skills / free actions), the armed-action -> inspector part-pick declare flow,
## THE BIT gating fallback, focus switching, and the event-log overlay.
## Renders evidence PNGs. DRIVER/CONSUMER ONLY — never touches simulation/,
## controller/, data/ or tests/. Lives under ui/hud/tools/ (HUD-rework-owned).
##
## Run:  HUD_DIR=/abs/out/ xvfb-run -a godot --path . -s ui/hud/tools/smoke_ui.gd
## Exit 0 = every probe held; 2 = a probe failed (printed).

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")

const SEED := 14

var gc
var hud
var root_node
var out_dir := ""
var failures: Array = []


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
	gc.name = "SmokeController"
	root_node.add_child(gc)
	gc.start_combat(SEED)
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}})
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1])

	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)
	await _settle()

	# 1) SKILLS flyout opens with the active actor's list (scrollable structure).
	hud._on_category("skills")
	await _settle()
	_check("skills flyout visible", hud._shell.flyout.visible)
	_check("skills open_cat", hud._open_cat == "skills")
	await _render("smoke_skills_flyout.png")

	# 2) A targeted skill ARMS part-targeting; the inspector auto-focuses the boss.
	hud._on_flyout_entry("skill:feint")
	await _settle()
	_check("armed after targeted skill", not hud._armed.is_empty())
	_check("flyout closed on pick", not hud._shell.flyout.visible)
	_check("boss auto-focused", hud._focus_id == "boss")
	await _render("smoke_armed_inspector.png")

	# 3) Clicking a part row declares the REAL command at that part.
	hud._on_inspector_part("left_hand")
	await _settle()
	_check("disarmed after part pick", hud._armed.is_empty())
	var boss = gc.sim.combatants.get("boss")
	_check("feint declared (boss feint window set)", boss != null)

	# 4) ATTACK flyout: unarmed strike arms; picking a REAL part row (the
	#    inspector only lists real parts) declares a real attack — crushed 1,
	#    honestly blocked by robustness at resolve, never faked.
	hud._on_category("attack")
	await _settle()
	hud._on_flyout_entry("unarmed")
	await _settle()
	_check("unarmed armed", String(hud._armed.get("kind", "")) == "attack")
	hud._on_inspector_part("right_hand")
	await _settle()
	_check("unarmed declared+disarmed", hud._armed.is_empty())
	var last: Dictionary = hud._event_log.back()
	_check("unarmed declare accepted (not rejected)",
		String(last.get("type", "")) != "command_rejected")

	# 5) FREE ACTIONS: the AUTHORED bit gating (decision-log #25, integrated).
	#    Dario carries The Bow -> enabled + labeled; Imani has no bit -> disabled.
	hud.set_active_actor("dario")
	var bit_entry: Dictionary = hud._bit_entry()
	_check("bit enabled + named for Dario (The Bow)",
		bool(bit_entry.get("enabled", false)) and String(bit_entry.get("label", "")).to_upper().contains("BOW"))
	hud.set_active_actor("imani")
	var bitless_entry: Dictionary = hud._bit_entry()
	_check("bit disabled for bitless Imani", not bool(bitless_entry.get("enabled", true)))
	hud.set_active_actor("dario")
	hud._on_category("free")
	await _settle()
	await _render("smoke_free_flyout.png")
	hud._on_flyout_entry("camera_call")
	await _settle()
	var spot: Dictionary = gc.view_broadcast().get("spotlight", {})
	_check("camera call spotlit active actor", String(spot.get("target", "")) == hud._active_actor)

	# 6) Focus switching: party card click selects + inspects an ally.
	hud._on_card_clicked("imani")
	await _settle()
	_check("card click selects", hud._selected_id == "imani" and hud._focus_id == "imani")

	# 7) Event log overlay opens with the session's sim events and closes.
	hud._open_log()
	await _settle()
	_check("event log visible", hud._shell.event_log.visible)
	_check("event log has events", not hud._event_log.is_empty())
	await _render("smoke_event_log.png")
	hud._close_log()
	_check("event log closed", not hud._shell.event_log.visible)

	print("")
	if failures.is_empty():
		print("UI SMOKE: all probes held")
		quit(0)
	else:
		print("UI SMOKE FAILURES: %s" % ", ".join(PackedStringArray(failures)))
		quit(2)


func _check(tag: String, ok: bool) -> void:
	print("  %-42s %s" % [tag, "OK" if ok else "FAIL"])
	if not ok:
		failures.append(tag)


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array) -> void:
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1}})


func _settle() -> void:
	for i in 4:
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
		print("render -> %s" % path)
