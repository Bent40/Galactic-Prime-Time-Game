extends SceneTree
## HUD v2 UI SMOKE DRIVER — exercises the NEW interactive structure that the
## frozen v1 drivers don't touch: launcher categories -> flyouts, the Phase-2
## CONFIRM STEP (armed -> part pick -> ActionPreview -> CONFIRM/BACK), the
## END TURN confirmation (Area 12), the declared-action timeline bars, THE BIT
## gating fallback, focus switching, and the event-log overlay.
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
	# Dario carries his AUTHORED bit (decision-log #25, mirrors demo_loadouts) so
	# the bit-gating probes exercise the real integrated behavior.
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}})

	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)
	await _settle()

	# 0) Dario (first ready contestant) spends his Moment on a real feint so the
	#    on-the-clock rotates to Imani, whose strong_strike gives the confirm
	#    panel an honest NET-damage line (Dario's bleed poke is robustness-
	#    blocked — also true, but the probe wants a positive line).
	hud._on_skill_for("dario", "feint")
	await _settle()
	_check("active rotated to imani", hud._active_actor == "imani")

	# 1) SKILLS flyout opens with the active actor's list (scrollable structure).
	hud._on_category("skills")
	await _settle()
	_check("skills flyout visible", hud._shell.flyout.visible)
	_check("skills open_cat", hud._open_cat == "skills")
	await _render("smoke_skills_flyout.png")

	# 2) A targeted skill ARMS part-targeting; the inspector auto-focuses the boss.
	hud._on_flyout_entry("skill:strong_strike")
	await _settle()
	_check("armed after targeted skill", not hud._armed.is_empty())
	_check("flyout closed on pick", not hud._shell.flyout.visible)
	_check("boss auto-focused", hud._focus_id == "boss")
	await _render("smoke_armed_inspector.png")

	# 3) CONFIRM STEP (Phase 2, Area 10): the INTERACTIVE part pick opens the
	#    ActionPreview panel (probe-fed) instead of declaring immediately.
	hud._on_inspector_part_clicked("left_hand")
	await _settle()
	_check("action preview visible on part pick", hud._shell.action_preview.visible)
	_check("armed state kept while confirming", not hud._armed.is_empty())
	_check("no strong_strike declared yet", not _schedule_has("imani", "strong_strike"))
	_check("panel shows a NET damage line", _panel_has_text(hud._shell.action_preview, "NET 5 DAMAGE"))
	_check("panel shows the windup commitment", _panel_has_text(hud._shell.action_preview, "WINDUP"))
	_check("panel shows the dodge uncertainty", _panel_has_text(hud._shell.action_preview, "may dodge"))
	await _render("smoke_confirm_panel.png")

	# 4) BACK returns to the armed state — nothing declared.
	hud._shell.action_preview.back_requested.emit()
	await _settle()
	_check("preview hidden after BACK", not hud._shell.action_preview.visible)
	_check("still armed after BACK", not hud._armed.is_empty())
	_check("still no strong_strike after BACK", not _schedule_has("imani", "strong_strike"))

	# 5) Re-pick + CONFIRM issues the REAL declare through the direct method.
	hud._on_inspector_part_clicked("left_hand")
	await _settle()
	hud._shell.action_preview.confirmed.emit()
	await _settle()
	_check("disarmed after CONFIRM", hud._armed.is_empty())
	_check("preview hidden after CONFIRM", not hud._shell.action_preview.visible)
	_check("CONFIRM declared the windup (schedule row)", _schedule_has("imani", "strong_strike", true))

	# 6) END TURN CONFIRMATION (Area 12): the button opens the panel; CONFIRM
	#    advances the tick; CANCEL leaves it untouched.
	var tick0 := int(gc.view_clock().get("tick", -1))
	hud._on_end_turn_pressed()
	await _settle()
	_check("end-turn confirmation visible", hud._shell.end_turn_confirm.visible)
	_check("end-turn shows next actor", _panel_has_text(hud._shell.end_turn_confirm, "NEXT TO ACT"))
	hud._shell.end_turn_confirm.confirmed.emit()
	await _settle()
	_check("CONFIRM advanced the tick", int(gc.view_clock().get("tick", -1)) == tick0 + 1)
	# Second press: Imani's windup now resolves NEXT tick — the telegraph line.
	hud._on_end_turn_pressed()
	await _settle()
	_check("resolves-next telegraph line shown", _panel_has_text(hud._shell.end_turn_confirm, "STRONG STRIKE"))
	await _render("smoke_end_turn_confirm.png")
	var tick1 := int(gc.view_clock().get("tick", -1))
	hud._shell.end_turn_confirm.cancelled.emit()
	await _settle()
	_check("CANCEL left the tick unchanged", int(gc.view_clock().get("tick", -1)) == tick1)
	_check("confirmation hidden after CANCEL", not hud._shell.end_turn_confirm.visible)

	# 7) Timeline bars MID-WINDUP: the strong_strike bar spans declared->resolve.
	_check("timeline bars lane populated", hud._shell.timeline._bars_lane.get_child_count() > 0)
	await _render("smoke_timeline_bars.png")

	# 8) confirm_enabled toggle: the interactive path collapses onto the direct
	#    declare (no panel) — the driver-facing escape hatch.
	hud.confirm_enabled = false
	hud._on_category("attack")
	await _settle()
	hud._on_flyout_entry("unarmed")
	await _settle()
	hud._on_inspector_part_clicked("right_hand")
	await _settle()
	_check("toggle off: no panel", not hud._shell.action_preview.visible)
	_check("toggle off: declared+disarmed directly", hud._armed.is_empty())
	var last: Dictionary = hud._event_log.back()
	_check("toggle off: declare accepted", String(last.get("type", "")) != "command_rejected")
	hud.confirm_enabled = true

	# 9) FREE ACTIONS: the AUTHORED bit gating (decision-log #25, integrated).
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

	# 10) Focus switching: party card click selects + inspects an ally.
	hud._on_card_clicked("imani")
	await _settle()
	_check("card click selects", hud._selected_id == "imani" and hud._focus_id == "imani")

	# 11) Event log overlay opens with the session's sim events and closes.
	hud._open_log()
	await _settle()
	_check("event log visible", hud._shell.event_log.visible)
	_check("event log has events", not hud._event_log.is_empty())
	await _render("smoke_event_log.png")
	hud._close_log()
	_check("event log closed", not hud._shell.event_log.visible)

	# 12) Full-HUD evidence shot MID-WINDUP with the enemy telegraph: a real
	#     ai_decide makes the boss declare; Imani's strong_strike is still
	#     pending — both declared-action bars ride the strip. Saved OUTSIDE the
	#     repo next to HUD_DIR's parent as preview_hud.png.
	gc.apply_command({"type": "ai_decide", "actor": "boss"})
	await _settle()
	_check("schedule pending for the full-HUD shot", not (gc.view_schedule() as Array).is_empty())
	_check("bars lane populated for the full-HUD shot", hud._shell.timeline._bars_lane.get_child_count() > 0)
	await _render("../preview_hud.png")

	print("")
	if failures.is_empty():
		print("UI SMOKE: all probes held")
		quit(0)
	else:
		print("UI SMOKE FAILURES: %s" % ", ".join(PackedStringArray(failures)))
		quit(2)


func _check(tag: String, ok: bool) -> void:
	print("  %-46s %s" % [tag, "OK" if ok else "FAIL"])
	if not ok:
		failures.append(tag)


## True when the pending schedule holds a row for (actor, key) — windup-flagged
## when require_windup is set. Ground truth straight off the view probe.
func _schedule_has(actor: String, key: String, require_windup := false) -> bool:
	for rd in gc.view_schedule():
		var r: Dictionary = rd
		if String(r.get("actor", "")) == actor and String(r.get("key", "")) == key:
			if not require_windup or bool(r.get("windup", false)):
				return true
	return false


## True when any Label under `node` contains `needle` (panel-content probe).
func _panel_has_text(node: Node, needle: String) -> bool:
	if node is Label and String((node as Label).text).contains(needle):
		return true
	for ch in node.get_children():
		if _panel_has_text(ch, needle):
			return true
	return false


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array, extra: Dictionary = {}) -> void:
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1}
	combatant.merge(extra, true)
	gc.apply_command({"type": "add_combatant", "combatant": combatant})


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
