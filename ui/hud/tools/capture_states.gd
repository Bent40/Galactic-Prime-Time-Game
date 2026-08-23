extends SceneTree
## OWNER-REVIEW SCREENSHOT CAPTURE DRIVER — stages fourteen representative game
## states (title, HUD shell, flyout, confirm preview, boss dash windup, the
## pressure-valve telegraph -> blast -> knockout beat, the boss inspector, the
## R24 feint-read, bid screen, WIN verdict card, rich status badges, the R34
## intent icons + cone-state colours, and R34/R35 free-form exploration) and grabs
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
	await _capture_13_intent_board()
	await _capture_14_exploration_mode()

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
	for ch in node.get_children():
		if _shown_text(ch, needle):
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
