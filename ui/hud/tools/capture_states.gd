extends SceneTree
## OWNER-REVIEW SCREENSHOT CAPTURE DRIVER — stages twelve representative game
## states (title, HUD shell, flyout, confirm preview, boss dash windup, the
## pressure-valve telegraph -> blast -> knockout beat, the boss inspector, the
## R24 feint-read, bid screen, WIN verdict card, rich status badges) and grabs
## one evidence PNG each off the real framebuffer.
##
## DRIVER/CONSUMER ONLY — never touches simulation/, controller/, data/ or
## tests/. Every state is staged through the real command funnel
## (GameController.apply_command / run_enemy_turn) and the HUD facade's own
## handlers, exactly like ui/hud/tools/smoke_ui.gd and scripts/hud_interact.gd.
## No sim internals are poked; conditions/shock/prone ride the real
## apply_condition / set_status commands.
##
## Documented DRIVER-SIDE SPEC CHOICES (not engine edits — the same tricks
## scripts/slice_playtest.gd, scripts/verdict_preview.gd and the engine's own
## tests already use, each flagged where applied):
##   * Stages C (valve beat) and F (win drive) add the boss with dodge_threshold
##     STRIPPED so the scripted breach/kill arithmetic is deterministic.
##   * Stage F runs the boss on a CONTROLLED cadence (no ai_decide) while the
##     party pounds the exposed network — slice_playtest's documented pacing
##     choice; every hit is a player-shaped declare through the funnel.
##
## Run:  CAP_DIR=/abs/out/ xvfb-run -a godot --path . -s ui/hud/tools/capture_states.gd
##   (NOT --headless — a real GL renderer is needed to capture the framebuffer;
##    ALSA "audio driver failed" lines in the log are harmless)
## Exit 0 = every staging probe held; 2 = a probe failed (printed).

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const BID_SCENE := preload("res://ui/screens/bid_screen.tscn")
const VERDICT_SCENE := preload("res://ui/screens/verdict_card.tscn")

const SEED := 14

## Loadout skill grants — verbatim (normalized key+level) from
## data/demo_loadouts.json (per-loadout skills are combatant STATE; the HUD
## reads them back through view_combatants — same staging as the other drivers).
const IMANI_SKILLS := [
	{"key": "strong_strike", "level": 2},
	{"key": "overhead_slam", "level": 1},
	{"key": "brace", "level": 2},
]
const DARIO_SKILLS := [
	{"key": "feint", "level": 3},
	{"key": "pressure_strike", "level": 1},
	{"key": "dance", "level": 2},
]

var gc
var hud
var root_node
var out_dir := ""
var failures: Array = []


func _initialize() -> void:
	out_dir = OS.get_environment("CAP_DIR")
	if out_dir == "":
		out_dir = "res://"
	if not out_dir.ends_with("/"):
		out_dir += "/"

	root_node = get_root()
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	root_node.size = Vector2i(1600, 1000)

	await _capture_01_title()
	await _capture_02_04_slice()
	await _capture_05_dash_windup()
	await _capture_06_08_valve_beat()
	await _capture_09_feint_read()
	await _capture_10_bid_screen()
	await _capture_11_verdict_win()
	await _capture_12_status_badges()

	print("")
	if failures.is_empty():
		print("CAPTURE PASS: all staging probes held")
		quit(0)
	else:
		print("CAPTURE FAILURES: %s" % ", ".join(PackedStringArray(failures)))
		quit(2)


# ------------------------------------------------------------------ 01 · title
## The project's main scene IS the title screen (run/main_scene =
## res://scenes/title.tscn) — instantiate it directly and shoot.
func _capture_01_title() -> void:
	var title: Control = TITLE_SCENE.instantiate()
	root_node.add_child(title)
	await _settle()
	await _render("01_title.png")
	root_node.remove_child(title)
	title.queue_free()
	await process_frame


# ------------------------------------- 02-04 · fresh slice / flyout / preview
## The demo-slice roster exactly as scenes/main.gd stages it: plain Incine-Dile
## (template traits intact — the dodge uncertainty is real) + Imani/Dario with
## their loadout skills and Dario's authored bit, FRESH at Clock 1 Moment 10.
func _capture_02_04_slice() -> void:
	_stand_up("CaptureControllerA", false)
	_attach_hud()
	await _settle()

	# 02 — full HUD shell, fresh fight.
	var ck: Dictionary = gc.view_clock()
	_check("02: fresh fight (tick 0 = Clock 1 Moment 10)",
		int(ck.get("tick", -1)) == 0 and int(ck.get("moment", -1)) == 10)
	await _render("02_hud_fight_start.png")

	# 03 — SKILLS flyout open for Dario (first ready contestant on a fresh tick).
	_check("03: Dario on the clock", hud._active_actor == "dario")
	hud._on_category("skills")
	await _settle()
	_check("03: skills flyout visible", hud._shell.flyout.visible)
	_check("03: flyout lists FEINT / PRESSURE STRIKE / DANCE",
		_panel_has_text(hud._shell.flyout, "FEINT")
		and _panel_has_text(hud._shell.flyout, "PRESSURE STRIKE")
		and _panel_has_text(hud._shell.flyout, "DANCE"))
	await _render("03_skills_flyout.png")
	hud._on_category("skills")  # toggle closed
	await _settle()

	# 04 — the Phase-2 confirm step: Dario really spends his Moment on a feint at
	# the boss (player-shaped declare), the clock rotates to Imani, whose
	# strong_strike part-pick opens the ActionPreview with the honest numbers
	# (NET damage / WINDUP commitment / dodge uncertainty) — smoke_ui probe 3.
	hud._on_skill_for("dario", "feint")
	await _settle()
	_check("04: active rotated to imani", hud._active_actor == "imani")
	hud._on_category("skills")
	await _settle()
	hud._on_flyout_entry("skill:strong_strike")
	await _settle()
	_check("04: armed + boss auto-focused",
		not hud._armed.is_empty() and hud._focus_id == "boss")
	hud._on_inspector_part_clicked("left_hand")
	await _settle()
	_check("04: action preview visible", hud._shell.action_preview.visible)
	_check("04: honest NET damage line", _panel_has_text(hud._shell.action_preview, "NET 5 DAMAGE"))
	_check("04: windup commitment line", _panel_has_text(hud._shell.action_preview, "WINDUP"))
	_check("04: dodge uncertainty line", _panel_has_text(hud._shell.action_preview, "may dodge"))
	await _render("04_action_preview.png")
	hud._shell.action_preview.back_requested.emit()
	await _settle()

	await _teardown()


# ------------------------------------------------------- 05 · boss dash windup
## A LONE contestant inside dash range: the cone sweep needs 2+ targets in
## reach, so the boss's real ai_decide declares the cost-2 DASH windup — the
## telegraph rides the Moment timeline's declared-action bars.
func _capture_05_dash_windup() -> void:
	_stand_up("CaptureControllerB", false, false)
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [2, 0],
		{"skills": IMANI_SKILLS})
	_attach_hud()
	await _settle()

	var events: Array = gc.apply_command({"type": "ai_decide", "actor": "boss"})
	var choice := ""
	var ability := ""
	for e in events:
		if String((e as Dictionary).get("type", "")) == "ai_decision":
			choice = String((e as Dictionary).get("choice", ""))
			ability = String((e as Dictionary).get("ability", ""))
	_check("05: boss decision is the dash", choice == "attack" and ability == "dash")
	var windup_row := false
	for rd in gc.view_schedule():
		var r: Dictionary = rd
		if String(r.get("actor", "")) == "boss" and bool(r.get("windup", false)):
			windup_row = true
			print("  05 schedule row: %s declared_tick=%d resolve_tick=%d windup=%s" % [
				String(r.get("key", "")), int(r.get("declared_tick", -1)),
				int(r.get("resolve_tick", -1)), str(bool(r.get("windup", false)))])
	_check("05: dash windup on the schedule", windup_row)
	await _settle()
	_check("05: timeline bars lane populated", hud._shell.timeline._bars_lane.get_child_count() > 0)
	await _render("05_dash_windup.png")

	await _teardown()


# ------------------------- 06-08 · valve telegraph / blast knockout / inspector
## The decision-#27 pressure-valve beat, driven end to end through commands:
## breach (single hit >= 7 net), pound the exposed network to <= 35 with
## player-shaped strikes, then the boss's own ai_decide telegraphs, holds the
## 2-Moment escape window, and blasts — both contestants parked inside radius 5.
## Boss added with dodge_threshold STRIPPED (driver-side spec choice, see header).
func _capture_06_08_valve_beat() -> void:
	_stand_up("CaptureControllerC", true)
	_attach_hud()
	await _settle()

	# Breach: bleeding 10 at the visible right hand — force 10 + floor(5/2) = 12
	# − robustness 3 = net 9 >= 7, the single-hit breach threshold (the exact
	# staging scripts/verdict_preview.gd uses).
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "bleeding", "amount": 10},
		"attack_range": 1, "targets": [{"id": "boss", "part": "right_hand"}]}})
	hud._on_end_turn()
	await _settle()
	_check("06: boss breached (network exposed)", bool(_row("boss").get("breached", false)))

	# Pound the network to the Pressure Valve I threshold (<= 35): one round of
	# player-shaped crushed-9 strikes (net 8 + 7 = 15; 50 -> 35).
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
		"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
	gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
		"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
	hud._on_end_turn()
	await _settle()
	var net_hp := _network_hp()
	print("  06 network hp after the pound: %d" % net_hp)
	_check("06: network at the valve threshold (<= 35)", net_hp >= 0 and net_hp <= 35)

	# The boss's own turn: the beat machine telegraphs (visible steam).
	gc.run_enemy_turn()
	await _settle()
	_check("06: explosion_telegraph reached the log", _log_has("explosion_telegraph"))
	_check("06: phase change reached the log", _log_has("boss_phase_changed"))
	hud._open_log()
	await _settle()
	await _render("06_explosion_telegraph.png")
	hud._close_log()
	await _settle()

	# Escape window (2 Moments) with both contestants parked inside radius 5,
	# then the blast: Helpless for 2 Clocks, no damage — the canon knockout.
	for i in 3:
		hud._on_end_turn()
		await _settle()
		gc.run_enemy_turn()
		await _settle()
		if _log_has("explosion_blast"):
			break
	_check("07: explosion_blast reached the log", _log_has("explosion_blast"))
	_check("07: explosion_knockout reached the log", _log_has("explosion_knockout"))
	_check("07: imani HELPLESS in the view", bool(_row("imani").get("helpless", false)))
	_check("07: HELPLESS badge on the party rail", _panel_has_text(hud._shell.party_rail, "HELPLESS"))
	hud._open_log()
	await _settle()
	await _render("07_post_blast_knockout.png")
	hud._close_log()
	await _settle()

	# 08 — the boss inspector. The R23 antagonism (grudge) map rides
	# view_combatants; the inspector does not render it yet (view-API-only) —
	# print it as ground truth and shoot the inspector as it stands today.
	var antag: Dictionary = _row("boss").get("antagonism", {})
	print("  08 boss antagonism map (view_combatants, not yet in UI): %s" % str(antag))
	_check("08: boss holds grudges in the view", not antag.is_empty())
	hud._on_token_clicked("boss")
	await _settle()
	_check("08: inspector focused on the boss", hud._focus_id == "boss")
	await _render("08_grudge_ledger.png")

	await _teardown()


# -------------------------------------------------------- 09 · R24 feint read
## A high-Mind reader staged via a raw add_combatant spec (smoke_ui probe 24
## idiom): Mind 7 >= the L3 feint's threshold 7 forces an AUTO-read — Dario's
## real feint collapses into the loud READS broadcast line, nothing armed.
func _capture_09_feint_read() -> void:
	_stand_up("CaptureControllerD", false)
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "sage", "name": "Sage", "race": "human", "team": "enemies",
		"position": [0, 2], "traits": {"physique": 3, "reflexes": 3, "mind": 7, "charm": 3}}})
	_attach_hud()
	await _settle()

	var declare: Array = gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
		"kind": "skill", "key": "feint", "level": 3, "attack_range": 2,
		"targets": [{"id": "sage", "part": "torso"}]}})
	var rejected := false
	for e in declare:
		if String((e as Dictionary).get("type", "")) == "command_rejected":
			rejected = true
	_check("09: feint declare accepted", not rejected)
	hud._on_end_turn()  # the instant feint resolves on this Moment's advance
	await _settle()
	_check("09: feint_read reached the log", _log_has("feint_read"))
	_check("09: ticker carries the READ broadcast line",
		String(hud._shell.ticker._line.text).contains("READS the feint"))
	_check("09: nothing armed on the reader", not bool(_row("sage").get("feint_forced", true)))
	await _render("09_feint_read.png")

	await _teardown()


# ---------------------------------------------------------- 10 · bid screen
## The patron bid screen reads STATIC pre-run data through view_bid — no live
## combat; bind straight off a fresh controller (scripts/bid_preview.gd idiom).
func _capture_10_bid_screen() -> void:
	gc = GameControllerScript.new()
	gc.name = "CaptureControllerE"
	root_node.add_child(gc)
	var bid: Control = BID_SCENE.instantiate()
	root_node.add_child(bid)
	bid.bind(gc)
	await _settle()
	await _render("10_bid_screen.png")
	root_node.remove_child(bid)
	bid.queue_free()
	await _teardown()


# ------------------------------------------------------- 11 · WIN verdict card
## The honest fastest win: breach, then pound the exposed network to 0 with
## player-shaped strikes (slice_playtest's NET_HIT-9 command, its documented
## controlled-cadence pacing choice) — the network is lethal, the boss dies,
## combat_status reads WIN, and the verdict card binds to the REAL final state.
func _capture_11_verdict_win() -> void:
	_stand_up("CaptureControllerF", true)

	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "bleeding", "amount": 10},
		"attack_range": 1, "targets": [{"id": "boss", "part": "right_hand"}]}})
	gc.apply_command({"type": "advance_tick"})
	_check("11: boss breached for the win drive", bool(_row("boss").get("breached", false)))

	var safety := 0
	while bool(_row("boss").get("alive", false)) and safety < 8:
		safety += 1
		gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
			"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
			"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
		gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
			"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
			"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
		gc.apply_command({"type": "advance_tick"})
	var status: Dictionary = gc.combat_status()
	print("  11 combat_status after the drive: %s" % str(status))
	_check("11: boss dead, outcome WIN",
		not bool(_row("boss").get("alive", true)) and String(status.get("outcome", "")) == "WIN")

	var card: Control = VERDICT_SCENE.instantiate()
	root_node.add_child(card)
	card.bind(gc, "imani")
	await _settle()
	await _render("11_verdict_card.png")
	root_node.remove_child(card)
	card.queue_free()
	await _teardown()


# ------------------------------------------------------ 12 · rich status badges
## Mid-fight badge richness staged ENTIRELY through real commands (no sim
## pokes): apply_condition (bleeding T2 / burn T1 / shock T3) + set_status
## prone through the funnel — party-card badge rows, inspector ACTIVE STATUS
## block and arena token pips all read the same view.
func _capture_12_status_badges() -> void:
	_stand_up("CaptureControllerG", false)
	_attach_hud()
	await _settle()

	for i in 3:  # a few real Moments so the clock reads mid-fight
		hud._on_end_turn()
		await _settle()

	gc.apply_command({"type": "apply_condition", "target": "imani", "part": "torso",
		"condition": "bleeding", "tier": 2})
	gc.apply_command({"type": "apply_condition", "target": "imani", "part": "left_arm",
		"condition": "burn", "tier": 1})
	gc.apply_command({"type": "apply_condition", "target": "imani", "part": "torso",
		"condition": "shock", "tier": 3})
	gc.apply_command({"type": "set_status", "target": "imani", "status": "prone", "value": true})
	gc.apply_command({"type": "apply_condition", "target": "dario", "part": "right_arm",
		"condition": "burn", "tier": 1})
	hud._on_card_clicked("imani")
	await _settle()

	_check("12: party card badge BLD 2", _panel_has_text(hud._shell.party_rail, "BLD 2"))
	_check("12: party card badge BRN 1", _panel_has_text(hud._shell.party_rail, "BRN 1"))
	_check("12: party card badge SHK 3", _panel_has_text(hud._shell.party_rail, "SHK 3"))
	_check("12: party card badge PRONE", _panel_has_text(hud._shell.party_rail, "PRONE"))
	_check("12: inspector ACTIVE STATUS block", _panel_has_text(hud._shell.inspector, "ACTIVE STATUS"))
	await _render("12_status_badges.png")

	await _teardown()


# --------------------------------------------------------------------- helpers
## Fresh controller + the demo-slice roster. strip_dodge follows the
## hud_interact/verdict_preview/slice_playtest driver-side spec choice; the
## duo flag drops the standard Imani/Dario pair for stages that stage their own.
func _stand_up(cname: String, strip_dodge: bool, duo := true) -> void:
	gc = GameControllerScript.new()
	gc.name = cname
	root_node.add_child(gc)
	gc.start_combat(SEED)
	_add_boss(strip_dodge)
	if duo:
		_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0],
			{"skills": IMANI_SKILLS})
		_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
			{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."},
			"skills": DARIO_SKILLS})


func _attach_hud() -> void:
	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)


func _teardown() -> void:
	if hud != null:
		root_node.remove_child(hud)
		hud.queue_free()
		hud = null
	if gc != null:
		root_node.remove_child(gc)
		gc.queue_free()
		gc = null
	await process_frame
	await process_frame


func _add_boss(strip_dodge: bool) -> void:
	var combatant: Dictionary = {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}
	if strip_dodge:
		# Driver-side spec choice (see header): deterministic scripted hits.
		var boss_traits: Dictionary = {}
		var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
		for entry: Variant in enemies as Array:
			var e: Dictionary = entry
			if String(e.get("key", "")) == "incinedile":
				boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
		boss_traits.erase("dodge_threshold")
		boss_traits.erase("dodge_threshold_note")
		combatant["boss_traits"] = boss_traits
	gc.apply_command({"type": "add_combatant", "combatant": combatant})


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array, extra: Dictionary = {}) -> void:
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1}
	combatant.merge(extra, true)
	gc.apply_command({"type": "add_combatant", "combatant": combatant})


## One combatant's view row (ground truth for probes — read-only, never poked).
func _row(id: String) -> Dictionary:
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == id:
			return cd
	return {}


func _network_hp() -> int:
	for pd in _row("boss").get("parts", []):
		if String((pd as Dictionary).get("key", "")) == "network":
			return int((pd as Dictionary).get("hp", -1))
	return -1


func _log_has(event_type: String) -> bool:
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == event_type:
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


func _check(tag: String, ok: bool) -> void:
	print("  %-52s %s" % [tag, "OK" if ok else "FAIL"])
	if not ok:
		failures.append(tag)


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
		print("render -> %s  %s" % [path, str(img.get_size())])
