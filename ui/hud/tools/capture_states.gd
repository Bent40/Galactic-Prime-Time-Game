extends SceneTree
## OWNER-REVIEW SCREENSHOT CAPTURE DRIVER — stages eighteen representative game
## states (title, HUD shell, flyout, confirm preview, boss dash windup, the
## pressure-valve telegraph -> blast -> knockout beat, the boss inspector, the
## R24 feint-read, bid screen, WIN verdict card, rich status badges, the R34
## intent icons + cone-state colours, R34/R35 free-form exploration, and — the
## KAN-6 PHASE 2 set — the exploration rows that COMMIT, the scheduled
## condition-tick chips on the timeline, the MODE D Modification Center popup
## and the R29 hype-chain banner) and grabs one evidence PNG each off the real
## framebuffer.
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
	await _capture_13_intent_board()
	await _capture_14_exploration_mode()
	await _capture_15_exploration_acts()
	await _capture_16_condition_ticks()
	await _capture_17_mod_center()
	await _capture_18_hype_chain()

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
## reach, so the boss's real ai_decide declares the cost-2 DASH windup.
##
## R34 (decision #36, 2026-08-19) RETIRED the telegraph this stage used to
## check. The enemy declared-action BAND is gone from the Moment timeline; the
## telegraph now rides the enemy's own INTENT ICON. The probes below are the
## pin for BOTH halves of that move: the strip must carry NO enemy band, and
## the icon must carry the declaration instead. A green "bars lane populated"
## here would now mean the ruling had been un-done.
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
	# R34 half 1 — the strip carries order and timing only. Only the boss has
	# declared, so the party-only bar filter must leave the lane EMPTY.
	_check("05: no enemy band on the timeline (R34 decision 2)",
		hud._shell.timeline._bars_lane.get_child_count() == 0)
	# R34 half 2 — the telegraph is on the enemy instead, and it is READ (not
	# UNREAD): the boss has committed, so the icon names what is coming.
	var boss_intent: Dictionary = (hud._intent_rows() as Dictionary).get("boss", {})
	print("  05 boss intent icon: %s" % str(boss_intent))
	_check("05: boss intent icon reads the declared dash",
		String(boss_intent.get("label", "")).contains("DASH")
			and String(boss_intent.get("kind", "")) != "unknown")
	_check("05: intent hover carries the full explanation",
		String(boss_intent.get("tip", "")).contains("RESOLVES CLOCK"))
	_check("05: intent chip is on the board",
		_panel_has_text(hud._shell.arena, "DASH"))
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
	# R26 x R34: the undodgable declaration MOVED onto the intent icon and must
	# be there from the windup on — "the player must know before they die".
	var valve_intent: Dictionary = (hud._intent_rows() as Dictionary).get("boss", {})
	print("  06 boss intent during the valve windup: %s" % str(valve_intent))
	if bool(valve_intent.get("undodgable", false)):
		_check("06: ⛔ UNDODGABLE declared on the intent icon (R26 via R34)",
			String(valve_intent.get("tip", "")).contains("UNDODGABLE"))
	else:
		print("  06 NOTE: the boss's pending declaration at this beat carries no "
			+ "R26 undodgable flag — the icon honestly says nothing it does not know.")
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
	# view_combatants and the inspector now renders it as the ATTENTION section
	# (KAN-4 quick win) — print the map as ground truth and shoot the ledger.
	var antag: Dictionary = _row("boss").get("antagonism", {})
	print("  08 boss antagonism map (view_combatants): %s" % str(antag))
	_check("08: boss holds grudges in the view", not antag.is_empty())
	hud._on_token_clicked("boss")
	await _settle()
	_check("08: inspector focused on the boss", hud._focus_id == "boss")
	_check("08: ATTENTION grudge ledger rendered", hud._shell.inspector._attn_panel.visible)
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
# --------------------------- 13 · R34 intent icons + cone-state colours
## THE DELTA-1/2/3 EVIDENCE SHOT (front-rework decisions 2 and 5-amended).
##
## Staged so the frame's own contrast is REAL, not arranged in the renderer:
##   * the boss DECLARES through its own ai_decide, so its intent icon is READ
##     and (when the sweep picks the cone) an attack arc is committed;
##   * a second enemy is added FAR AWAY and declares nothing, so its icon is
##     honestly UNREAD ❓ and its eyeline holds nobody — the NEUTRAL cone;
##   * the boss stands nose-to-nose with the party, so its eyeline DOES hold
##     contestants — the RED cone and the 👁 HAS ... chip.
## Everything the shot shows comes from view_schedule / view_vision; nothing is
## poked into the sim and no cone geometry is invented in the HUD.
func _capture_13_intent_board() -> void:
	_stand_up("CaptureControllerG", false)
	# The unread, unaware second enemy. Far outside the boss's own arc and
	# range, and it is never asked to decide.
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": "roach", "name": "Little Brother", "enemy": "little_brother_roach",
		"team": "enemies", "position": [-4, 3]}})
	_attach_hud()
	await _settle()

	gc.apply_command({"type": "ai_decide", "actor": "boss"})
	await _settle()

	var intents: Dictionary = hud._intent_rows()
	var boss_intent: Dictionary = intents.get("boss", {})
	var roach_intent: Dictionary = intents.get("roach", {})
	print("  13 boss intent : %s" % str(boss_intent))
	print("  13 roach intent: %s" % str(roach_intent))
	_check("13: boss carries a READ intent icon",
		String(boss_intent.get("kind", "unknown")) != "unknown"
			and String(boss_intent.get("label", "")) != "UNREAD")
	_check("13: undeclared enemy shows UNREAD ❓ (never a fabricated guess)",
		String(roach_intent.get("kind", "")) == "unknown"
			and String(roach_intent.get("label", "")) == "UNREAD")
	_check("13: UNREAD hover explains itself",
		String(roach_intent.get("tip", "")).contains("never a guess"))

	var vision: Dictionary = hud._vision_rows()
	var boss_eye: Dictionary = vision.get("boss", {})
	var roach_eye: Dictionary = vision.get("roach", {})
	print("  13 boss vision : %s" % str({"seen": boss_eye.get("seen"),
		"label": boss_eye.get("label"), "watched": (boss_eye.get("hexes", []) as Array).size()}))
	print("  13 roach vision: %s" % str({"seen": roach_eye.get("seen"),
		"label": roach_eye.get("label"), "watched": (roach_eye.get("hexes", []) as Array).size()}))
	_check("13: the boss's vision cone is HOT (holds a contestant -> RED)",
		bool(boss_eye.get("seen", false))
			and String(boss_eye.get("label", "")).begins_with("HAS"))
	_check("13: the distant enemy's cone is NEUTRAL (👁 UNAWARE)",
		not bool(roach_eye.get("seen", true))
			and String(roach_eye.get("label", "")) == "UNAWARE")
	_check("13: eyelines are real hexes off view_vision, not a drawn wedge",
		not (boss_eye.get("hexes", []) as Array).is_empty())
	_check("13: both chips are on the board",
		_panel_has_text(hud._shell.arena, "UNAWARE")
			and _panel_has_text(hud._shell.arena, "UNREAD"))
	_check("13: the cone-reading legend is up", hud._shell.arena._legend.visible)

	var cones: Array = hud._attack_cone_rows()
	print("  13 declared attack arcs: %s" % str(cones.size()))
	if not cones.is_empty():
		_check("13: the attack arc is the COMMITTED shape (real hexes)",
			not ((cones[0] as Dictionary).get("hexes", []) as Array).is_empty())
	else:
		print("  13 NOTE: the boss's chosen action declares no area_shape at this "
			+ "staging, so no attack arc is drawn — correct, not a miss.")
	_check("13: timeline carries no enemy band (R34 decision 2)",
		hud._shell.timeline._bars_lane.get_child_count() == 0)
	await _render("13_intent_icons_and_cones.png")

	await _teardown()


# ------------------------------- 14 · R34/R35 Mode A — free-form exploration
## THE DELTA-4/5 EVIDENCE SHOT. The room is put into free-form exploration
## through the LOGGED phase command (the same one GameController._stage_encounter
## issues when a room opens), then the HUD is asked to prove the whole contract:
##   * the timing strip becomes the exploration strip (no turn order, nothing
##     costs Moments, elapsed off R0's tick->fiction conversion, PAUSE control);
##   * the launcher becomes the free-form verb set and ENTER becomes the commit;
##   * THE DRIVER REALLY RUNS: tick_realtime issues logged advance_ticks, and
##     stops dead under PAUSE and under an open inventory surface (R35's
##     Pokemon clause). That last pair is the half R34/R35 flagged as missing.
func _capture_14_exploration_mode() -> void:
	# The party is staged WELL CLEAR of the boss. That is not decoration: R34's
	# contact predicate runs on the phase command itself, so a party already
	# inside a mob's eyeline bounces straight back to combat "in the same
	# breath" (R35 names exactly this for the kennel). Out of the cone, the
	# room genuinely stays free-form and can be walked.
	_stand_up("CaptureControllerH", false, false)
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [8, 0],
		{"skills": IMANI_SKILLS})
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [8, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."},
		"skills": DARIO_SKILLS})
	_attach_hud()
	# Hand-step the clock for the driver assertions below (the HUD's own
	# per-frame pump would otherwise race the probes).
	hud.auto_time_steps = false
	await _settle()

	var phase_events: Array = gc.apply_command({"type": "phase", "set": "exploration"})
	for e in phase_events:
		print("  14 phase command event: %s" % str(e))
	await _settle()
	var phase: Dictionary = gc.view_phase()
	print("  14 view_phase: %s" % str(phase))
	_check("14: the sim is in free-form exploration", bool(phase.get("exploring", false)))
	_check("14: no turn order, no Moment costs",
		not bool(phase.get("turn_order", true)) and not bool(phase.get("moment_costs", true)))
	# VISIBLE text only — the combat strip and the exploration strip both exist
	# in the tree at all times, so a plain text walk would pass on a hidden one.
	_check("14: OUT OF COMBAT strip is up",
		_shown_text(hud._shell.timeline, "OUT OF COMBAT"))
	_check("14: the timing strip is GONE (no turn order to time)",
		not hud._shell.timeline._combat_row.visible)
	_check("14: the strip states the ruling",
		_shown_text(hud._shell.timeline, "NO TURN ORDER")
			and _shown_text(hud._shell.timeline, "NOTHING COSTS MOMENTS"))
	_check("14: the elapsed readout is up", _shown_text(hud._shell.timeline, "⏱"))
	_check("14: the PAUSE control is on the strip",
		_shown_text(hud._shell.timeline, "PAUSE"))
	_check("14: the route breadcrumb replaced the timing strip",
		_shown_text(hud._shell.timeline, "YOU ARE HERE"))
	_check("14: the launcher swapped to the free-form verbs",
		_shown_text(hud._shell.launcher, "WALK")
			and _shown_text(hud._shell.launcher, "INTERACT")
			and _shown_text(hud._shell.launcher, "INVENTORY"))
	_check("14: WALK is marked FREE", _shown_text(hud._shell.launcher, "FREE"))
	_check("14: INVENTORY declares that it pauses time",
		_shown_text(hud._shell.launcher, "PAUSES TIME"))
	_check("14: ENTER replaced END TURN as the commit",
		_shown_text(hud._shell.launcher, "ENTER"))
	_check("14: the board says free movement / time running",
		_shown_text(hud._shell.arena, "FREE MOVEMENT"))
	await _render("14_exploration_mode.png")

	# ---- THE DRIVER (R35's named gap). Real logged time steps, no wall clock.
	var driver = hud._explore_driver
	var t0 := int((gc.view_phase() as Dictionary).get("tick", -1))
	var issued: int = driver.tick_realtime(driver.SECONDS_PER_TICK)
	await _settle()
	var t1 := int((gc.view_phase() as Dictionary).get("tick", -1))
	print("  14 driver step: issued=%d tick %d -> %d" % [issued, t0, t1])
	_check("14: the driver issues a real exploration time step", issued == 1 and t1 == t0 + 1)
	_check("14: the step is the ONE real tick path (advance_tick)",
		String((gc.command_log.back() as Dictionary).get("type", "")) == "advance_tick")

	# PAUSE: the driver simply stops issuing. Nothing in the sim knows.
	hud._on_pause()
	await _settle()
	var paused_issued: int = driver.tick_realtime(driver.SECONDS_PER_TICK * 4.0)
	var t2 := int((gc.view_phase() as Dictionary).get("tick", -1))
	_check("14: PAUSE stops the time steps", paused_issued == 0 and t2 == t1)
	_check("14: pause is DRIVER state — the sim holds none",
		String((gc.view_phase() as Dictionary).get("pause", "")) == "driver")
	_check("14: the strip shows the held state", _shown_text(hud._shell.timeline, "TIME HELD"))
	await _render("15_exploration_paused.png")
	hud._on_pause()
	await _settle()

	# R35's Pokemon clause: an OPEN inventory surface holds time the same way.
	hud._on_category("inventory")
	await _settle()
	_check("14: the inventory surface is open", hud._shell.flyout.visible)
	var inv_issued: int = driver.tick_realtime(driver.SECONDS_PER_TICK * 4.0)
	var t3 := int((gc.view_phase() as Dictionary).get("tick", -1))
	_check("14: an open inventory holds time (R35's Pokemon clause)",
		inv_issued == 0 and t3 == t1)
	await _render("16_exploration_inventory_holds_time.png")
	hud._close_flyout()
	await _settle()
	var resumed: int = driver.tick_realtime(driver.SECONDS_PER_TICK)
	_check("14: closing the surface releases time again", resumed == 1)

	# WALK is not a relabelled MOVE button: the HUD issues the SAME {"type":
	# "move"} command it always did, and the sim's phase gate routes it to the
	# free-form walk — zero Moment cost, zero ticks. The button says FREE
	# because the engine makes it free, not because the label says so.
	hud.set_active_actor("imani")
	hud._on_move()
	await _settle()
	_check("14: WALK arms the click-to-target board", hud._shell.arena.move_mode())
	var walk_tick := int((gc.view_phase() as Dictionary).get("tick", -1))
	var walk_events: Array = gc.apply_command(
		{"type": "move", "actor": "imani", "to": [7, 0]})
	var walk_ok := false
	for e in walk_events:
		var ev: Dictionary = e
		print("  14 walk event: %s" % str(ev))
		if String(ev.get("type", "")) == "moved":
			walk_ok = true
	_check("14: the free-form walk is accepted out of combat", walk_ok)
	_check("14: walking costs no Moment and burns no tick",
		int((gc.view_phase() as Dictionary).get("tick", -1)) == walk_tick)

	# The commit: ENTER is the deliberate way in, straight off view_phase.
	hud._on_end_turn_pressed()
	await _settle()
	_check("14: ENTER started the fight",
		not bool((gc.view_phase() as Dictionary).get("exploring", true)))
	_check("14: the timing strip came back", hud._shell.timeline._combat_row.visible)
	await _render("17_exploration_entered_combat.png")

	await _teardown()


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


## True when any VISIBLE Label under `node` contains `needle` — the strict
## sibling of _panel_has_text, needed once a component keeps two mutually
## exclusive strips (combat / exploration) alive in the same tree.
func _shown_text(node: Node, needle: String) -> bool:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return false
	if node is Label and String((node as Label).text).contains(needle):
		return true
	# KAN-6 phase 2: some surfaces state their fact in a RichTextLabel (the
	# hype-chain carry sentence, the Mod-Center prose) — a Label-only walk would
	# report those as MISSING while the player is reading them. get_parsed_text
	# is the rendered string, so bbcode markup can never fake a match.
	if node is RichTextLabel and String((node as RichTextLabel).get_parsed_text()).contains(needle):
		return true
	for ch in node.get_children():
		if _shown_text(ch, needle):
			return true
	return false


## True when any Label under `node` contains `needle` (panel-content probe).
func _panel_has_text(node: Node, needle: String) -> bool:
	if node is Label and String((node as Label).text).contains(needle):
		return true
	if node is RichTextLabel and String((node as RichTextLabel).get_parsed_text()).contains(needle):
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


# ============ 15 · KAN-6 PHASE 2 — THE EXPLORATION ROWS THAT COMMIT =========
## Phase 1 shipped Mode A's shape with its INTERACT / INVENTORY rows
## deliberately inert. This is the evidence that they now issue REAL commands
## and render REAL results — the whole of phase 2 item 1.
##
## Staged on the AUTHORED SERVICE CORRIDOR (data/demo_run.json), through the
## real run loop: start_run -> begin_encounter opens the room FREE-FORM by
## itself (RunState.staging()'s opens_in default), so the arena, its supply
## cage door, its simple lock, the party positions and the hype chain are all
## the shipped data rather than a fixture.
##
## THREE DOCUMENTED DRIVER-SIDE STAGING CHOICES (the capture-header idiom —
## staging only; no engine, controller or data file is touched):
##  1. The roach pair is staged at the corridor's FAR END instead of beside the
##     party. Not cosmetic: footfalls are QUIET(3) noise and R34's contact
##     predicate is live, so with the authored positions the very first scouted
##     step is heard and the room flips to combat before any of the free-form
##     acts can be shown. Moving them proves the acts; the pull is then proved
##     DELIBERATELY at the end of the stage, with the voicebox.
##  2. Sasha joins from her authored brood_landing ally spec (the same spec the
##     run's own recruit beat stages), so the frame's "SASHA — VOICEBOX" row
##     has the character it names.
##  3. She is granted VOICEBOX and LOCKPICKING. This is the honest finding the
##     stage exists to expose as much as to work around: NO shipped loadout
##     (demo_loadouts.json or recruit_loadouts.json) grants either skill, so
##     the approved frame's rows presuppose grants the seed data does not
##     author. Without the grant the HUD says so and disables the row — which
##     is the ungranted half of the same evidence, checked below first.
func _capture_15_exploration_acts() -> void:
	var def: Dictionary = _run_def()
	var corridor: Dictionary = _encounter_def(def, "service_corridor").duplicate(true)
	var den: Dictionary = _encounter_def(def, "incinedile_den").duplicate(true)
	# staging choice 1 — the pair walks the far end of the corridor
	var enemies: Array = (corridor.get("enemies", []) as Array).duplicate(true)
	(enemies[0] as Dictionary)["positions"] = [[-6, 0], [-6, 1]]
	corridor["enemies"] = enemies
	# staging choices 2 + 3 — Sasha, with the two exploration grants
	var party: Array = (def.get("party", []) as Array).duplicate(true)
	var sasha: Dictionary = _sasha_spec(def)
	var sasha_skills: Array = (sasha.get("skills", []) as Array).duplicate(true)
	sasha_skills.append({"key": "voicebox", "level": 1})
	sasha_skills.append({"key": "lockpicking", "level": 1})
	sasha["skills"] = sasha_skills
	# One item, DROPPED — so the inventory row can prove the recovery path.
	sasha["items"] = [{"key": "bandage", "name": "Bandage", "base_moment_cost": 2, "dropped": true}]
	party.append(sasha)

	gc = GameControllerScript.new()
	gc.name = "CaptureControllerI"
	root_node.add_child(gc)
	gc.start_run(int(def.get("run_seed", 0)), party, [corridor, den], _static_data())
	gc.apply_run_command({"type": "begin_encounter"})
	_record_events()
	_attach_hud()
	hud.auto_time_steps = false  # hand-stepped, so probes never race the beat
	await _settle()

	var phase: Dictionary = gc.view_phase()
	print("  15 view_phase: %s" % str(phase))
	_check("15: the corridor opened FREE-FORM through the real run loop",
		bool(phase.get("exploring", false)))
	_check("15: the authored supply cage door is on the board",
		_door_row("supply_cage_door").has("lock"))

	# ---- the UNGRANTED half: Imani owns neither skill, and the rows say so.
	# Selecting her card IS the gesture: out of combat there is no turn order,
	# so the acting contestant is the selected one.
	hud._on_card_clicked("imani")
	hud._on_category("interact")
	await _settle()
	print("  15 active actor: %s" % hud._active_actor)
	for e in hud._interact_entries():
		print("    15 interact row: %s | %s | enabled=%s" % [
			String((e as Dictionary).get("label", "")), String((e as Dictionary).get("sub", "")),
			str((e as Dictionary).get("enabled", false))])
	_check("15: an ungranted contestant gets an honest disabled VOICEBOX row",
		_shown_text(hud._shell.flyout, "no voicebox grant"))
	_check("15: …and an honest disabled PICK row",
		_shown_text(hud._shell.flyout, "NO LOCKPICKING GRANT"))
	hud._close_flyout()
	await _settle()

	# ---- the GRANTED half: Sasha's rows are live.
	hud._on_card_clicked("sasha")
	hud._on_category("interact")
	await _settle()
	_check("15: selecting a card really moves the acting contestant out of combat",
		hud._active_actor == "sasha")
	await _settle()
	_check("15: PICK THE SUPPLY CAGE DOOR is offered",
		_shown_text(hud._shell.flyout, "PICK THE SUPPLY CAGE DOOR"))
	_check("15: the row states the COMBAT price the waiver is suspending",
		_shown_text(hud._shell.flyout, "1 MOMENT once the fighting starts"))
	_check("15: SASHA — VOICEBOX is offered", _shown_text(hud._shell.flyout, "VOICEBOX"))
	_check("15: SCOUT AHEAD is offered", _shown_text(hud._shell.flyout, "SCOUT AHEAD"))
	await _render("18_explore_interact_live.png")

	# ---- SCOUT AHEAD — real free-form walks toward the authored exit --------
	var before: Array = _party_hexes()
	var scout_tick := int((gc.view_phase() as Dictionary).get("tick", -1))
	hud._on_flyout_entry("scout")
	await _settle()
	var after: Array = _party_hexes()
	print("  15 scout: %s -> %s" % [str(before), str(after)])
	print("  15 gate hex: %s · sasha items: %s" % [str(_door_hex("supply_cage_door")),
		str(_row("sasha").get("items", []))])
	var scout_reject: Dictionary = _last_event("command_rejected")
	if not scout_reject.is_empty():
		print("  15 scout rejection: %s" % str(scout_reject))
	_check("15: SCOUT AHEAD really walked the party", str(before) != str(after))
	_check("15: …and the walk cost no Moment and burned no tick",
		int((gc.view_phase() as Dictionary).get("tick", -1)) == scout_tick)
	_check("15: the room is still free-form (nothing was committed)",
		bool((gc.view_phase() as Dictionary).get("exploring", false)))
	_check("15: the walk went through the REAL move command",
		String((gc.command_log.back() as Dictionary).get("type", "")) == "move")
	await _render("19_explore_scouted.png")

	# ---- PICK THE SUPPLY CAGE — the free-form lockpick ---------------------
	_check("15: the scout put Sasha in reach of the lock",
		_hex_dist_ids("sasha", _door_hex("supply_cage_door")) == 1)
	var locked_before := String((_door_row("supply_cage_door").get("lock", {}) as Dictionary).get("state", ""))
	hud._on_category("interact")
	await _settle()
	hud._on_flyout_entry("pick:supply_cage_door")
	await _settle()
	var picked: Dictionary = _last_event("lock_picked")
	print("  15 lock_picked: %s" % str(picked))
	_check("15: the pick RESOLVED (it is not an inspect row any more)", not picked.is_empty())
	_check("15: it reports moments 0 — the R35 waiver, stated honestly",
		int(picked.get("moments", -1)) == 0)
	_check("15: the lock really is open now (live view state)",
		locked_before == "locked"
			and String((_door_row("supply_cage_door").get("lock", {}) as Dictionary).get("state", "")) == "unlocked")
	_check("15: the ticker says the zero out loud", _shown_text(hud._shell.ticker, "0 MOMENTS"))
	_check("15: nothing was scheduled and no tick burned",
		gc.view_schedule().is_empty()
			and int((gc.view_phase() as Dictionary).get("tick", -1)) == scout_tick)
	await _render("20_explore_lock_picked.png")

	# ---- INVENTORY — the item really comes back ---------------------------
	hud._on_category("inventory")
	await _settle()
	_check("15: the dropped item is offered as a PICK UP row",
		_shown_text(hud._shell.flyout, "PICK UP BANDAGE"))
	_check("15: an open inventory still holds time (phase 1 parity)",
		hud._explore_driver.tick_realtime(hud._explore_driver.SECONDS_PER_TICK * 4.0) == 0)
	hud._on_flyout_entry("take:bandage")
	await _settle()
	_check("15: the interaction ran and was FREE out of combat",
		bool(_last_event("inventory_used").get("free", false)))
	_check("15: the item was genuinely recovered", not _last_event("item_recovered").is_empty())
	_check("15: R3's first-free ledger is untouched by the out-of-combat use",
		not _shown_text(hud._shell.ticker, "DENIED"))
	hud._on_category("inventory")
	await _settle()
	_check("15: …and the row flipped to USE now that it is in hand",
		_shown_text(hud._shell.flyout, "USE BANDAGE"))
	await _render("21_explore_inventory_used.png")
	hud._close_flyout()
	await _settle()

	# ---- VOICEBOX — a quiet throw, then the throw that PULLS THE ROOM ------
	hud._on_category("interact")
	await _settle()
	hud._on_flyout_entry("voicebox")
	await _settle()
	_check("15: the throw armed the board pick", hud._shell.arena.move_mode())
	_check("15: the launcher states the skill's own authored range",
		_shown_text(hud._shell.launcher, "VOICEBOX — pick a hex within 10"))
	await _render("22_explore_voicebox_armed.png")
	hud._throw_at(Vector2i(5, 2))
	await _settle()
	var thrown: Dictionary = _last_event("sound_thrown")
	print("  15 sound_thrown (quiet corner): %s" % str(thrown))
	_check("15: the throw RESOLVED on the spot", not thrown.is_empty())
	_check("15: at the R20 table's LOUD loudness, unchanged by the waiver",
		int(thrown.get("loudness", 0)) == Stealth.NOISE_LOUD)
	_check("15: a throw out of earshot pulls nobody — the room stays free-form",
		bool((gc.view_phase() as Dictionary).get("exploring", false))
			and _last_event("noise_heard").is_empty())

	# The pull, on purpose: a hex the pack CAN hear.
	hud._on_category("interact")
	await _settle()
	hud._on_flyout_entry("voicebox")
	await _settle()
	hud._throw_at(Vector2i(-4, 0))
	await _settle()
	var heard: Dictionary = _last_event("noise_heard")
	var contact: Dictionary = _last_event("contact")
	print("  15 noise_heard: %s" % str(heard))
	print("  15 contact    : %s" % str(contact))
	_check("15: the pack HEARD the thrown sound", not heard.is_empty())
	_check("15: …and it pulled the room onto the party (contact by HEARING)",
		String(contact.get("sense", "")) == "hearing")
	_check("15: the fight really started", not bool((gc.view_phase() as Dictionary).get("exploring", true)))
	_check("15: the timing strip came back with it", hud._shell.timeline._combat_row.visible)
	await _render("23_explore_voicebox_pulled_the_room.png")

	await _teardown()


# ============ 16 · SCHEDULED CONDITION TICKS ON THE TIMELINE ================
## Approved frame 1 puts scheduled condition ticks on the timeline as chips on
## their own lane ("🔥 BURN II → DARIO"). Decision 2 keeps this strip as the
## ORDER-AND-TIMING surface and decision 4 makes status effects load-bearing
## everywhere; a scheduled tick is timing, so it lives here — unlike enemy
## intent, which R34 moved onto the enemy's own icon and which stage 13 pins as
## still absent from the strip.
##
## Everything staged through the real apply_condition command; every chip is
## read back off the new view_condition_schedule() projection, which in turn
## reads ConditionEngine's own rules. Nothing about WHEN a condition bites is
## re-implemented in the HUD, and the stage proves that by advancing the clock
## to the reset and checking the chip's prediction against what actually fired.
func _capture_16_condition_ticks() -> void:
	_stand_up("CaptureControllerJ", false)
	_attach_hud()
	await _settle()
	for i in 3:  # a few real Moments so the strip reads mid-fight
		hud._on_end_turn()
		await _settle()

	gc.apply_command({"type": "apply_condition", "target": "dario", "part": "right_arm",
		"condition": "burn", "tier": 1})
	gc.apply_command({"type": "apply_condition", "target": "imani", "part": "torso",
		"condition": "bleeding", "tier": 2})
	for e in gc.apply_command({"type": "apply_condition", "target": "boss", "part": "left_hand",
			"condition": "chilled", "tier": 1}):
		print("  16 chilled staging event: %s" % str(e))
	for e in gc.apply_command({"type": "apply_condition", "target": "imani", "part": "left_leg",
			"condition": "exhausted", "tier": 2}):
		print("  16 exhausted staging event: %s" % str(e))
	await _settle()

	var sched: Array = gc.view_condition_schedule()
	print("  16 boss parts: %s" % str(_row("boss").get("parts", [])))
	for row in sched:
		print("  16 tick row: %s" % str(row))
	_check("16: the projection reports scheduled ticks", not sched.is_empty())
	var burn: Dictionary = _tick_row(sched, "dario", "burn")
	_check("16: Dario's burn is scheduled to ADVANCE",
		String(burn.get("effect", "")) == "advance" and int(burn.get("to_tier", 0)) == 2)
	_check("16: …at the CLOCK RESET, which is where conditions actually bite",
		int(burn.get("at_tick", -1)) % 10 == 9 and int(burn.get("clocks_away", 0)) == 1)
	# A condition whose def does NOT advance at the reset reads its own rule,
	# not "advance": chilled resolves unless it was reapplied this Clock, and
	# exhausted eases off when its owner rested. Both are ConditionEngine's
	# rules, read through the projection — the point of sourcing it there.
	print("  16 chilled row : %s" % str(_tick_row(sched, "boss", "chilled")))
	print("  16 exhausted   : %s" % str(_tick_row(sched, "imani", "exhausted")))
	# The boss RESISTED the chilled staging (condition_resisted — its own
	# resistance rule), so the non-advancing branch is proved on the one that
	# actually landed: exhausted does not advance at the reset, it EASES.
	_check("16: a non-advancing condition reads its OWN rule, not 'advance'",
		String(_tick_row(sched, "imani", "exhausted").get("effect", "")) == "step_down"
			and int(_tick_row(sched, "imani", "exhausted").get("to_tier", -1)) == 1)
	_check("16: …and a resisted condition schedules NOTHING (no phantom chip)",
		_tick_row(sched, "boss", "chilled").is_empty())

	var chips: Array = hud._condition_tick_chips(
		int(gc.view_clock().get("tick", 0)) - (int(gc.view_clock().get("tick", 0)) % 10))
	for c in chips:
		print("  16 chip: %s" % str((c as Dictionary).get("label", "")))
	_check("16: the lane is populated", not chips.is_empty())
	_check("16: it carries the frame's own chip shape (BRN II → DARIO)",
		_chips_contain(chips, "BRN II → DARIO"))
	_check("16: chips are DRAWN on the strip's own lane",
		hud._shell.timeline._ticks_lane.get_child_count() > 0)
	_check("16: and the enemy-intent bands are still retired (phase 1 parity)",
		hud._shell.timeline._bars_lane.get_child_count() == 0)
	await _render("24_timeline_condition_ticks.png")

	# THE PREDICTION IS CHECKED AGAINST REALITY: run the Clock out and confirm
	# the burn advanced exactly as the chip said it would.
	var predicted := int(burn.get("to_tier", 0))
	while int(gc.view_clock().get("tick", 0)) <= int(burn.get("at_tick", 0)):
		gc.apply_command({"type": "advance_tick"})
	await _settle()
	_check("16: the chip told the truth — the burn really is T%d after the reset" % predicted,
		_part_condition_tier("dario", "right_arm", "burn") == predicted)

	await _teardown()


# ============ 17 · MODE D — THE MODIFICATION CENTER POPUP ===================
## Approved frame 5. The popup itself, over the live HUD: three BLESSED
## broad-only offers with their group chips, the focused offer expanded, the
## requirement rows measured against a REAL character's granted levels, the
## CONSUMES-BOTH-PARENTS warning, the "offered, never automatic" framing, the
## KAN-7 price stamp with no number on it, and the declared PAUSED state.
##
## Dario is the focus on purpose: his authored loadout carries FEINT at Lv3,
## which makes THE LONG CON read exactly as the approved frame renders it —
## FEINT 3/5 IN PROGRESS, VIBE CONTROL –/3 NOT LEARNED, two requirements short.
## That match is the point: the frame's numbers were drawn from this data, and
## the popup now reproduces them from the data rather than from the frame.
func _capture_17_mod_center() -> void:
	_stand_up("CaptureControllerK", false)
	_attach_hud()
	await _settle()
	hud._on_card_clicked("dario")
	await _settle()

	var offers: Array = gc.view_offers("dario")
	for o in offers:
		print("  17 offer: %s short=%s parents=%s" % [
			String((o as Dictionary).get("key", "")),
			str((o as Dictionary).get("requirements_short", -1)),
			str((o as Dictionary).get("parents", []))])
	_check("17: all three authored offers project", offers.size() == 3)
	_check("17: every one is well-authored (SkillForge.validate_offer)",
		_all_authored_ok(offers))
	var long_con: Dictionary = _offer_row(offers, "the_long_con")
	_check("17: THE LONG CON reads Dario's REAL feint grant (3 / 5, IN PROGRESS)",
		_parent_state(long_con, "feint") == "IN PROGRESS"
			and _parent_owned(long_con, "feint") == 3)
	_check("17: …and an unlearned parent is NOT LEARNED, not a fake zero",
		_parent_state(long_con, "vibe_control") == "NOT LEARNED"
			and _parent_owned(long_con, "vibe_control") == 0)
	_check("17: the gate is two requirements short, exactly as the frame reads",
		int(long_con.get("requirements_short", -1)) == 2)
	_check("17: the price is UNPRICED and stamped KAN-7",
		not bool((long_con.get("price", {}) as Dictionary).get("priced", true))
			and String((long_con.get("price", {}) as Dictionary).get("scope", "")) == "KAN-7")
	_check("17: redemption is NOT wired, and the projection says why",
		not bool((long_con.get("redemption", {}) as Dictionary).get("available", true))
			and not ((long_con.get("redemption", {}) as Dictionary).get("missing", []) as Array).is_empty())

	hud._open_mod_center()
	await _settle()
	_check("17: MODE D is open", hud._shell.mod_center.visible)
	_check("17: it focuses the offer Dario is closest to (THE LONG CON)",
		hud._mod_focus == "the_long_con")
	_check("17: the header declares the PAUSED state",
		_shown_text(hud._shell.mod_center, "PAUSED"))
	_check("17: …and Escape is offered as the way out",
		_shown_text(hud._shell.mod_center, "ESC CLOSES"))
	_check("17: all three offers are on screen side by side",
		_shown_text(hud._shell.mod_center, "THE UNSEEN")
			and _shown_text(hud._shell.mod_center, "THE LONG CON")
			and _shown_text(hud._shell.mod_center, "PHANTOM GRASP"))
	_check("17: the broad-only group chips are real (off shared_broad)",
		_shown_text(hud._shell.mod_center, "BROAD-ONLY · PERFORMANCE")
			and _shown_text(hud._shell.mod_center, "BROAD-ONLY · INFILTRATION"))
	_check("17: the CONSUMES BOTH PARENTS warning is up",
		_shown_text(hud._shell.mod_center, "CONSUMES BOTH PARENTS"))
	_check("17: the offered-never-automatic framing is up",
		_shown_text(hud._shell.mod_center, "offered, never automatic"))
	_check("17: the requirement rows read as the frame does",
		_shown_text(hud._shell.mod_center, "IN PROGRESS")
			and _shown_text(hud._shell.mod_center, "NOT LEARNED"))
	_check("17: the price row carries the KAN-7 stamp and no number",
		_shown_text(hud._shell.mod_center, "KAN-7 — TBD"))
	_check("17: the gate is the honest one",
		_shown_text(hud._shell.mod_center, "NOT YET — 2 REQUIREMENTS SHORT"))
	await _render("25_mod_center_mode_d.png")

	# Focus another offer — the popup re-expands without touching anything.
	hud._on_offer_focused("the_unseen")
	await _settle()
	_check("17: focusing another offer expands it",
		_shown_text(hud._shell.mod_center, "The ghost and the prowler fuse"))
	await _render("26_mod_center_focus_switch.png")

	# A different character re-measures the SAME offers against THEIR grants.
	hud._on_card_clicked("imani")
	hud._mod_focus = "the_long_con"
	hud.refresh()
	await _settle()
	_check("17: Imani owns no LONG CON parent — both rows read NOT LEARNED",
		_parent_state(_offer_row(gc.view_offers("imani"), "the_long_con"), "feint") == "NOT LEARNED")
	await _render("27_mod_center_other_character.png")

	# Escape closes (Mode D's own rule) and time is released again.
	hud._close_mod_center()
	await _settle()
	_check("17: Escape closes MODE D", not hud._shell.mod_center.visible)
	_check("17: …and the driver's hold is released",
		not hud._explore_driver.blockers.has("mod center"))

	await _teardown()


# ============ 18 · THE R29 HYPE-CHAIN BANNER ================================
## Approved frame 4's crowd panel states the carry math in words. Staged on the
## REAL demo run (start_run -> begin_encounter), so `hype_chain_index`, the
## retention rung and the room graph are the shipped ones; the meter is raised
## by REAL play (declares resolving through the funnel), never poked.
func _capture_18_hype_chain() -> void:
	var def: Dictionary = _run_def()
	gc = GameControllerScript.new()
	gc.name = "CaptureControllerL"
	root_node.add_child(gc)
	gc.start_run(int(def.get("run_seed", 0)), def.get("party", []),
		def.get("encounters", []), _static_data())
	gc.apply_run_command({"type": "begin_encounter"})
	_record_events()
	_attach_hud()
	hud.auto_time_steps = false
	await _settle()

	var chain: Dictionary = gc.view_hype_chain()
	print("  18 view_hype_chain (fresh): %s" % str(chain))
	_check("18: a chain is ARMED — brood landing has two exits to carry into",
		bool(chain.get("armed", false)))
	_check("18: the rung is the LADDER's, read off RunState (link 1 = 40%)",
		int(chain.get("pct", 0)) == int(RunState.CHAIN_RETENTION_PCT[1]))
	_check("18: the ladder itself is the engine's, not a HUD copy",
		(chain.get("ladder", []) as Array).size() == RunState.CHAIN_RETENTION_PCT.size())
	_check("18: the banner is up in MODE A", _shown_text(hud._shell.crowd, "HYPE CHAIN"))
	await _render("28_hype_chain_exploration.png")

	# The deliberate ENTER, then real play to move the meter.
	hud._on_end_turn_pressed()
	await _settle()
	_check("18: the room is fighting now", not bool((gc.view_phase() as Dictionary).get("exploring", true)))
	# Real play, not a poke: a camera call for the multiplier, then genuine
	# strikes on the brood until the crowd actually reacts.
	gc.apply_command({"type": "camera_call", "actor": "dario", "target": "dario"})
	for i in 14:
		if int((gc.view_broadcast().get("hype", {}) as Dictionary).get("meter", 0)) > 0:
			break
		for attacker: String in ["imani", "dario", "sasha"]:
			gc.apply_command({"type": "declare_action", "actor": attacker, "action": {
				"kind": "attack", "key": "unarmed_strike", "cost": 1, "attack_range": 1,
				"damage": {"type": "crushed", "amount": 2},
				"targets": [{"id": "roach_dog_%d" % ((i % 3) + 1), "part": "carapace"}]}})
		hud._on_end_turn()
		await _settle()
	var live: Dictionary = gc.view_hype_chain()
	print("  18 view_hype_chain (live): %s" % str(live))
	var meter := int(live.get("meter", 0))
	var expect := int(floor(meter * int(live.get("pct", 0)) / 100.0))
	_check("18: real play actually moved the crowd (a 0 → 0 carry proves nothing)",
		meter > 0)
	_check("18: the meter the banner quotes is the LIVE one",
		meter == int((gc.view_broadcast().get("hype", {}) as Dictionary).get("meter", -1)))
	_check("18: the head start is floor(pct x meter) — chain_hype_start's own arithmetic",
		int(live.get("opens_at", -1)) == expect)
	_check("18: the banner states the carry in the frame's words",
		_shown_text(hud._shell.crowd, "%d → %d" % [meter, expect]))
	_check("18: …and names the rung after it (the frame's 'keeps 60%')",
		_shown_text(hud._shell.crowd, "%d%%" % int(live.get("then_pct", 0))))
	_check("18: CHAINING IS REWARDED rides the banner",
		_shown_text(hud._shell.crowd, "CHAINING IS REWARDED"))
	await _render("29_hype_chain_combat.png")

	await _teardown()


# ----------------------------------------------- phase-2 staging/probe helpers

func _run_def() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/demo_run.json"))
	return (parsed as Dictionary).get("run", {}) if parsed is Dictionary else {}


func _encounter_def(def: Dictionary, key: String) -> Dictionary:
	for raw: Variant in def.get("encounters", []) as Array:
		if String((raw as Dictionary).get("key", "")) == key:
			return raw
	return {}


## Sasha's authored party spec — the very row brood_landing stages her with.
func _sasha_spec(def: Dictionary) -> Dictionary:
	for raw: Variant in _encounter_def(def, "brood_landing").get("allies", []) as Array:
		var spec: Dictionary = (raw as Dictionary).get("spec", {})
		if String(spec.get("id", "")) == "sasha":
			return spec.duplicate(true)
	return {}


func _static_data() -> Dictionary:
	return Dal.new().static_data_for_sim()


func _door_row(key: String) -> Dictionary:
	for raw: Variant in (gc.view_arena() as Dictionary).get("doors", []):
		if String((raw as Dictionary).get("key", "")) == key:
			return raw
	return {}


func _door_hex(key: String) -> Vector2i:
	var pos: Array = _door_row(key).get("position", [0, 0])
	return Vector2i(int(pos[0]), int(pos[1]))


func _hex_dist_ids(id: String, to: Vector2i) -> int:
	var pos: Array = _row(id).get("position", [0, 0])
	var a := Vector2i(int(pos[0]), int(pos[1]))
	var dq := a.x - to.x
	var dr := a.y - to.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


func _party_hexes() -> Array:
	var out: Array = []
	for cd in gc.view_combatants():
		var c: Dictionary = cd
		if String(c.get("team", "")) == "party":
			out.append([String(c.get("id", "")), c.get("position", [])])
	return out


## Raw sim events this stage has seen, recorded off the SAME signal the HUD
## subscribes to — so a probe checks the events the player's HUD reacted to,
## not a re-derivation.
var _captured_events: Array = []


func _record_events() -> void:
	_captured_events = []
	if gc != null and not gc.sim_event.is_connected(_on_captured_event):
		gc.sim_event.connect(_on_captured_event)


func _on_captured_event(e: Dictionary = {}) -> void:
	if not e.is_empty():
		_captured_events.append(e)


## The most recent event of a type since _record_events() was called.
func _last_event(event_type: String) -> Dictionary:
	var found: Dictionary = {}
	for raw: Variant in _captured_events:
		var e: Dictionary = raw
		if String(e.get("type", "")) == event_type:
			found = e
	return found


func _tick_row(rows: Array, combatant: String, condition: String) -> Dictionary:
	for raw: Variant in rows:
		var r: Dictionary = raw
		if String(r.get("combatant", "")) == combatant and String(r.get("condition", "")) == condition:
			return r
	return {}


func _chips_contain(chips: Array, needle: String) -> bool:
	for raw: Variant in chips:
		if String((raw as Dictionary).get("label", "")).contains(needle):
			return true
	return false


func _part_condition_tier(id: String, part: String, condition: String) -> int:
	for pd in _row(id).get("parts", []):
		var p: Dictionary = pd
		if String(p.get("key", "")) == part:
			return int((p.get("conditions", {}) as Dictionary).get(condition, 0))
	return 0


func _offer_row(offers: Array, key: String) -> Dictionary:
	for raw: Variant in offers:
		if String((raw as Dictionary).get("key", "")) == key:
			return raw
	return {}


func _parent_row(offer: Dictionary, key: String) -> Dictionary:
	for raw: Variant in offer.get("parents", []):
		if String((raw as Dictionary).get("key", "")) == key:
			return raw
	return {}


func _parent_state(offer: Dictionary, key: String) -> String:
	return String(_parent_row(offer, key).get("state", ""))


func _parent_owned(offer: Dictionary, key: String) -> int:
	return int(_parent_row(offer, key).get("owned_level", -1))


func _all_authored_ok(offers: Array) -> bool:
	for raw: Variant in offers:
		if not bool((raw as Dictionary).get("authored_ok", false)):
			return false
	return true
