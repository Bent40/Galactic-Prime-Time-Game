extends SceneTree
## HUD v2 UI SMOKE DRIVER — exercises the NEW interactive structure that the
## frozen v1 drivers don't touch: launcher categories -> flyouts, the Phase-2
## CONFIRM STEP (armed -> part pick -> ActionPreview -> CONFIRM/BACK), the
## END TURN confirmation (Area 12), the declared-action timeline bars, THE BIT
## gating fallback, focus switching, the event-log overlay, plus the
## status-prominence pass (party-card / inspector badge rows, arena status
## pips, hidden-part masking), the smooth-motion pass (persistent tokens,
## eased position tween on a real move), the skill-feel quick wins
## (FEINTED badge + loud feint_fallout, boss PRONE badge + stand-up beat,
## and the combined-strike part-pick that replaced the left_hand default),
## plus the R24 feint-read announce (a staged high-Mind reader auto-reads —
## loud broadcast line, nothing armed, no badge), and the KAN-4 quick wins:
## the inspector ATTENTION grudge ledger (R23 antagonism -> UI), the R24
## READ-RISK lines in the ActionPreview confirm panel (all three outcome
## classes, preview-only), and the pressure-valve broadcast announces
## (telegraph / blast / per-victim knockout / breach reset) staged on a fresh
## dodge-stripped controller driven through the REAL PausedClockDriver so the
## beat events land DURING END TURN — the priority-over-generic path.
## Renders evidence PNGs. DRIVER/CONSUMER ONLY — never touches simulation/,
## controller/, data/ or tests/. Lives under ui/hud/tools/ (HUD-rework-owned).
##
## Run:  HUD_DIR=/abs/out/ xvfb-run -a godot --path . -s ui/hud/tools/smoke_ui.gd
## Exit 0 = every probe held; 2 = a probe failed (printed).

const GameControllerScript := preload("res://controller/game_controller.gd")
const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")

const SEED := 14

## Loadout skill grants — verbatim (normalized key+level) from
## data/demo_loadouts.json (per-loadout skills are combatant STATE now; the
## SKILLS flyout probes below assert the list comes from the VIEW, not a fixture).
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
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0],
		{"skills": IMANI_SKILLS})
	# Dario carries his AUTHORED bit (decision-log #25, mirrors demo_loadouts) so
	# the bit-gating probes exercise the real integrated behavior. Both carry
	# their loadout SKILL grants (keys + levels), read back through the view.
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."},
		"skills": DARIO_SKILLS})

	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)
	await _settle()

	# 0a) SKILLS flyout is VIEW-DRIVEN (fixture ACTOR_SKILLS deleted): the active
	#     actor's (Dario's) entries mirror his granted `skills` rows straight off
	#     view_combatants — 3 entries, FEINT labeled with its honest cost.
	var view_ids: Array = []
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "dario":
			for srd in (cd as Dictionary).get("skills", []):
				view_ids.append("skill:" + String((srd as Dictionary).get("key", "")))
	var fly: Dictionary = hud._flyout_data("skills")
	var fly_ids: Array = []
	var feint_label := ""
	var feint_sub := ""
	for ed in fly.get("entries", []):
		fly_ids.append(String((ed as Dictionary).get("id", "")))
		if String((ed as Dictionary).get("id", "")) == "skill:feint":
			feint_label = String((ed as Dictionary).get("label", ""))
			feint_sub = String((ed as Dictionary).get("sub", ""))
	_check("skills flyout: Dario's 3 granted entries", fly_ids.size() == 3)
	_check("skills flyout entries mirror the VIEW rows", fly_ids == view_ids)
	_check("FEINT entry labeled with its honest cost",
		feint_label.contains("FEINT") and feint_sub.contains("COST 1"))

	# 0b) A combatant with NO granted skills gets ONE honest disabled entry —
	#     never a fixture fallback (the boss's view row carries skills: []).
	hud.set_active_actor("boss")
	var none_entries: Array = (hud._flyout_data("skills") as Dictionary).get("entries", [])
	_check("no-skills flyout: one honest disabled entry",
		none_entries.size() == 1
		and not bool((none_entries[0] as Dictionary).get("enabled", true))
		and String((none_entries[0] as Dictionary).get("label", "")).contains("NO SKILLS"))
	hud.set_active_actor("dario")

	# 0c) ActionPreview previews the GRANTED level's numbers: Dario's dance is
	#     granted Lv2, so the honest self-effect line reads +2 Charm (not Lv1's +1).
	hud._open_self_preview("dance")
	await _settle()
	_check("self preview open (dance)", hud._shell.action_preview.visible)
	_check("preview shows granted-level numbers (+2 Charm)",
		_panel_has_text(hud._shell.action_preview, "+2 Charm effect"))
	hud._shell.action_preview.back_requested.emit()
	await _settle()
	_check("dance preview closed after BACK", not hud._shell.action_preview.visible)

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

	# 9b) FREE-ACTION ECONOMY (anti-spam ruling): performing the bit consumes
	#     the R3 one-free-action-per-tick slot — the entry dims for the rest of
	#     the Moment, off the view's free_action_used field.
	hud.set_active_actor("dario")
	hud._on_bit()
	await _settle()
	hud.set_active_actor("dario")  # _issue's refresh re-derives the on-the-clock actor; pin Dario back
	var used_entry: Dictionary = hud._bit_entry()
	_check("bit dims when free action used",
		not bool(used_entry.get("enabled", true))
		and String(used_entry.get("sub", "")).contains("free action already used"))

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

	# 13) Full-HUD evidence shot with the VIEW-DRIVEN skills flyout open for
	#     Dario (his 3 granted entries with LV + cost lines on screen). Saved
	#     OUTSIDE the repo, next to HUD_DIR's parent, as skills_hud.png.
	hud.set_active_actor("dario")
	if hud._open_cat != "":
		hud._on_category(hud._open_cat)  # toggle whatever is open closed first
	hud._on_category("skills")
	await _settle()
	_check("skills flyout open for the final shot", hud._shell.flyout.visible)
	_check("final shot flyout lists FEINT from the view",
		_panel_has_text(hud._shell.flyout, "FEINT"))
	await _render("../skills_hud.png")
	hud._on_category("skills")  # toggle closed for the status/motion probes below
	await _settle()

	# ---- STATUS PROMINENCE + SMOOTH MOTION (owner directive 2026-07-23) --------

	# 14) View widening: every view_combatants row carries the ADDITIVE
	#     helpless/prone status keys (booleans, read by the badge rows).
	var status_keys_ok := true
	for cd in gc.view_combatants():
		if not (cd as Dictionary).has("helpless") or not (cd as Dictionary).has("prone"):
			status_keys_ok = false
	_check("view rows carry helpless + prone keys", status_keys_ok)

	# 15) Party-card badge row: stage a wounded beat (harness-only pokes, exactly
	#     like hud_preview.gd) — bleeding T2 + burn T1, shock T3, knocked prone —
	#     then refresh and read the RENDERED rail.
	var imani_state = gc.sim.combatants["imani"]
	imani_state.conditions["torso"] = {"bleeding": {"tier": 2, "delayed": false}}
	imani_state.conditions["left_arm"] = {"burn": {"tier": 1, "delayed": false}}
	imani_state.shock = 3
	imani_state.statuses["prone"] = true
	hud.refresh()
	await _settle()
	_check("party card badge BLD 2", _panel_has_text(hud._shell.party_rail, "BLD 2"))
	_check("party card badge BRN 1", _panel_has_text(hud._shell.party_rail, "BRN 1"))
	_check("party card badge SHK 3", _panel_has_text(hud._shell.party_rail, "SHK 3"))
	_check("party card badge PRONE", _panel_has_text(hud._shell.party_rail, "PRONE"))

	# 16) Inspector ACTIVE STATUS section: focusing Imani fronts the same
	#     condition tiers + state flags in the set-off badge block.
	hud._on_card_clicked("imani")
	await _settle()
	_check("inspector ACTIVE STATUS section present",
		_panel_has_text(hud._shell.inspector, "ACTIVE STATUS"))
	_check("inspector badge BLD 2", _panel_has_text(hud._shell.inspector, "BLD 2"))
	_check("inspector badge SHK 3", _panel_has_text(hud._shell.inspector, "SHK 3"))
	_check("inspector badge PRONE", _panel_has_text(hud._shell.inspector, "PRONE"))
	await _render("smoke_status_badges.png")

	# 17) Known-anatomy masking holds for badges: a condition living ONLY on the
	#     boss's HIDDEN network part must not surface anywhere while unbreached
	#     (chilled is used because nothing else in this run applies it).
	gc.sim.combatants["boss"].conditions["network"] = {"chilled": {"tier": 2, "delayed": false}}
	hud._on_token_clicked("boss")
	await _settle()
	_check("hidden-part condition stays masked", not _panel_has_text(hud._shell.inspector, "CHL"))
	_check("arena boss-cond line masked too", not _panel_has_text(hud._shell.arena, "CHILLED"))

	# 18) Arena pips: Imani's token carries one coloured dot PER BADGE (her
	#     bleeding + burn + shock + prone, plus any live state flag such as the
	#     windup EXPOSED) — the board itself shows who is hurt or locked.
	var imani_row: Dictionary = {}
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "imani":
			imani_row = cd
	var expected_pips: int = mini((hud._status_badges(imani_row) as Array).size(), 6)
	var imani_token: Control = hud._shell.arena._tokens.get("imani")
	var pip_dots := 0
	if imani_token != null:
		for ch in imani_token.get_children():
			if ch is HBoxContainer:
				for dot in ch.get_children():
					if dot is Panel:
						pip_dots += 1
	_check("imani token pips mirror her badges", pip_dots == expected_pips and pip_dots >= 4)

	# 19) Persistent tokens: the same wrapper NODE survives a refresh (content
	#     rebuilt in place, identity stable — the substrate the tween rides on).
	hud.refresh()
	await _settle()
	_check("token node persists across refresh",
		hud._shell.arena._tokens.get("imani") == imani_token)

	# 20) SMOOTH MOVE: a real move command GLIDES the token to its new screen
	#     point (eased tween) instead of snapping. END TURN first so the fresh
	#     Moment resets the per-tick action economy for the free move.
	hud._on_end_turn()
	await _settle()
	var mover: Control = hud._shell.arena._tokens.get("dario")
	var start_pos: Vector2 = mover.position
	gc.apply_command({"type": "move", "actor": "dario", "to": [0, 2]})
	# Ground truth first: the sim actually accepted the move.
	var dario_pos: Array = []
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "dario":
			dario_pos = (cd as Dictionary).get("position", [])
	_check("move accepted by the sim", dario_pos == [0, 2])
	var glide_target: Vector2 = mover.get_meta("target_px", start_pos)
	_check("token retargeted by the move", glide_target.distance_to(start_pos) > 8.0)
	# No process frame has run since the retarget: a SNAP would already sit on
	# the target; the tween has not stepped yet, so the token must not have.
	_check("no snap on refresh (tween pending)", mover.position.distance_to(start_pos) < 0.5)
	var t0 := Time.get_ticks_msec()
	while mover.position.distance_to(glide_target) > 0.5 and Time.get_ticks_msec() - t0 < 2000:
		await process_frame
	_check("token settled on the new hex point", mover.position.distance_to(glide_target) <= 0.5)
	await _render("smoke_status_motion.png")

	# ---- SKILL-FEEL QUICK WINS (owner fix menu, story/skill-feel) --------------

	# 21) FEINTED badge: Dario feints the boss for real; once the feint resolves
	#     the boss's view row carries the ADDITIVE feint_forced flag and the
	#     inspector badge row shows FEINTED (anatomy masking does not hide it —
	#     the flag is top-level state, not a part condition).
	gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
		"kind": "skill", "key": "feint", "level": 3, "attack_range": 2,
		"targets": [{"id": "boss", "part": "head"}]}})
	hud._on_end_turn()  # the instant feint resolves on this Moment's advance
	await _settle()
	var boss_row: Dictionary = {}
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "boss":
			boss_row = cd
	_check("view row carries feint_forced (additive)", bool(boss_row.get("feint_forced", false)))
	hud._on_token_clicked("boss")
	await _settle()
	_check("inspector shows the FEINTED badge", _panel_has_text(hud._shell.inspector, "FEINTED"))
	await _render("smoke_feint_badge.png")

	# 21b) FEINT FALLOUT is loud: the boss's pending cone windup collapses under
	#      the armed feint — the attributed feint_fallout event lands in the log
	#      with the broadcast payoff line, and the Momus ticker keeps it (the
	#      generic END TURN line must NOT clobber the payoff).
	var fallout_seen := false
	for i in 3:
		hud._on_end_turn()
		await _settle()
		for ed in hud._event_log:
			if String((ed as Dictionary).get("type", "")) == "feint_fallout":
				fallout_seen = true
		if fallout_seen:
			break
	_check("feint_fallout event reached the log", fallout_seen)
	var fallout_line := ""
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == "feint_fallout":
			fallout_line = String((ed as Dictionary).get("line", ""))
	_check("fallout line is attributed broadcast copy",
		fallout_line.contains("DARIO") and fallout_line.contains("feint pays off"))
	_check("ticker keeps the payoff over the END TURN line",
		String(hud._shell.ticker._line.text).contains("feint pays off"))
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "boss":
			boss_row = cd
	_check("feint flag cleared after the fallout", not bool(boss_row.get("feint_forced", true)))
	hud._open_log()
	await _settle()
	await _render("smoke_feint_payoff.png")
	hud._close_log()

	# 22) Boss PRONE badge + stand-up costs the Moment: knock the boss prone via
	#     the real set_status command; the inspector badge row shows PRONE for
	#     the boss too; the boss's whole next decision is "stand", and once the
	#     stand resolves the flag clears with an attributed stood_up event.
	gc.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	hud._on_token_clicked("boss")
	await _settle()
	_check("inspector shows PRONE on the boss", _panel_has_text(hud._shell.inspector, "PRONE"))
	await _render("smoke_boss_prone.png")
	var stand_events: Array = gc.apply_command({"type": "ai_decide", "actor": "boss"})
	var stand_choice := ""
	for e in stand_events:
		if String((e as Dictionary).get("type", "")) == "ai_decision":
			stand_choice = String((e as Dictionary).get("choice", ""))
	_check("prone boss decision is stand (cone locked)", stand_choice == "stand")
	hud._on_end_turn()
	await _settle()
	var stood_seen := false
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == "stood_up":
			stood_seen = true
	_check("stood_up event reached the log", stood_seen)
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "boss":
			boss_row = cd
	_check("boss no longer prone after standing", not bool(boss_row.get("prone", true)))

	# 23) PART-PICK, not left_hand default (owner fix #3): the interactive
	#     COMBINED STRIKE routes through the part-pick step — picking it ARMS
	#     part-targeting (no instant preview), the part click opens the merged
	#     preview AT the picked part, and CONFIRM declares a combined_action
	#     whose members carry the PICKED part, not the old silent default.
	for i in 4:
		if hud._combo_ready():
			break
		hud._on_end_turn()
		await _settle()
	_check("both combo members ready", hud._combo_ready())
	hud._on_category("attack")
	await _settle()
	hud._on_flyout_entry("combined")
	await _settle()
	_check("combined pick arms part-targeting",
		String(hud._armed.get("kind", "")) == "combined")
	_check("no preview before a part is picked", not hud._shell.action_preview.visible)
	_check("boss auto-focused for the pick", hud._focus_id == "boss")
	hud._on_inspector_part_clicked("right_leg")
	await _settle()
	_check("part pick opens the combo preview", hud._shell.action_preview.visible)
	_check("preview routes to the PICKED part", _panel_has_text(hud._shell.action_preview, "R-LEG"))
	await _render("smoke_combo_partpick.png")
	hud._shell.action_preview.confirmed.emit()
	await _settle()
	_check("disarmed after combo CONFIRM", hud._armed.is_empty())
	var combo_cmd: Dictionary = {}
	for cmd in gc.command_log:
		if String((cmd as Dictionary).get("type", "")) == "combined_action":
			combo_cmd = cmd
	var parts_picked: Array = []
	for md in combo_cmd.get("members", []):
		for td in ((md as Dictionary).get("action", {}) as Dictionary).get("targets", []):
			parts_picked.append(String((td as Dictionary).get("part", "")))
	_check("declared combo carries the picked part", parts_picked == ["right_leg", "right_leg"])
	var combo_last: Dictionary = hud._event_log.back()
	_check("combo declare accepted", String(combo_last.get("type", "")) != "command_rejected")

	# 24) R24 FEINT-READ goes loud: stage a high-Mind reader via raw commands —
	#     Mind 7 >= threshold 7 (an L3 feint) forces an AUTO-read, no rng — on a
	#     free hex next to Dario, feint it, and the read must land in the log +
	#     Momus ticker with the broadcast copy while NOTHING arms on the reader
	#     (no feint_forced flag -> no FEINTED badge; a read is a beat, not a badge).
	var dario_hex: Array = []
	var taken: Array = []
	for cd in gc.view_combatants():
		var row: Dictionary = cd
		if bool(row.get("alive", true)):
			taken.append(row.get("position", []))
		if String(row.get("id", "")) == "dario":
			dario_hex = row.get("position", [])
	var sage_hex: Array = []
	for nd in [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]]:
		var cand: Array = [int(dario_hex[0]) + int((nd as Array)[0]), int(dario_hex[1]) + int((nd as Array)[1])]
		if not taken.has(cand):
			sage_hex = cand
			break
	_check("free hex found beside Dario for the reader", not sage_hex.is_empty())
	_add_contestant("sage", "Sage", {"physique": 3, "reflexes": 3, "mind": 7, "charm": 3}, sage_hex)
	for i in 5:
		if _actor_ready("dario"):
			break
		hud._on_end_turn()
		await _settle()
	_check("dario ready to feint the reader", _actor_ready("dario"))
	gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
		"kind": "skill", "key": "feint", "level": 3, "attack_range": 2,
		"targets": [{"id": "sage", "part": "torso"}]}})
	var read_declare: Dictionary = hud._event_log.back()
	_check("read-path feint declare accepted", String(read_declare.get("type", "")) != "command_rejected")
	hud._on_end_turn()  # the instant feint resolves on this Moment's advance
	await _settle()
	var read_line := ""
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == "feint_read":
			read_line = String((ed as Dictionary).get("line", ""))
	_check("feint_read event reached the log", read_line != "")
	_check("read line is attributed broadcast copy",
		read_line.contains("SAGE READS the feint") and read_line.contains("DARIO"))
	_check("ticker keeps the read over the END TURN line",
		String(hud._shell.ticker._line.text).contains("READS the feint"))
	var sage_row: Dictionary = {}
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == "sage":
			sage_row = cd
	_check("nothing armed on the reader (no feint_forced)",
		not bool(sage_row.get("feint_forced", true)))
	hud._on_token_clicked("sage")
	await _settle()
	_check("no FEINTED badge on the reader", not _panel_has_text(hud._shell.inspector, "FEINTED"))
	await _render("smoke_feint_read.png")

	# ---- KAN-4 QUICK WINS (grudge ledger / read-risk / valve announces) --------

	# 25) ATTENTION grudge ledger (R23 -> UI): damage writes the boss's
	#     antagonism ledger; this session's landed hits usually earned grudges
	#     already — if the seed's dodges swallowed every hit, stage one honest
	#     poke through the funnel (bounded retry; the boss CAN dodge it).
	for i in 6:
		if not (_row("boss").get("antagonism", {}) as Dictionary).is_empty():
			break
		if _actor_ready("imani"):
			gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
				"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 6},
				"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}})
		hud._on_end_turn()
		await _settle()
	var boss_antag: Dictionary = _row("boss").get("antagonism", {})
	_check("boss holds grudges in the view", not boss_antag.is_empty())
	hud._on_token_clicked("boss")
	await _settle()
	_check("inspector shows the ATTENTION section", hud._shell.inspector._attn_panel.visible)
	var top_id := ""
	var top_score := -1.0
	var antag_ids: Array = boss_antag.keys()
	antag_ids.sort()
	for oid in antag_ids:
		if float(boss_antag[oid]) > top_score:
			top_score = float(boss_antag[oid])
			top_id = String(oid)
	_check("ledger names the loudest grudge",
		_panel_has_text(hud._shell.inspector, hud._display_name_for(top_id)))
	var attn_rows: Array = hud._attention_rows(_row("boss"))
	_check("one ATTENTION row per ledger entry", attn_rows.size() == boss_antag.size())
	var attn_sorted := true
	for i in range(1, attn_rows.size()):
		if float((attn_rows[i - 1] as Dictionary).get("share", 0.0)) \
				< float((attn_rows[i] as Dictionary).get("share", 0.0)):
			attn_sorted = false
	_check("ATTENTION rows sorted descending", attn_sorted)
	_check("top ATTENTION share normalized to 1.0",
		not attn_rows.is_empty()
		and absf(float((attn_rows[0] as Dictionary).get("share", 0.0)) - 1.0) < 0.0001)
	await _render("smoke_grudge_ledger.png")
	hud._on_card_clicked("imani")
	await _settle()
	_check("empty ledger omits the ATTENTION section", not hud._shell.inspector._attn_panel.visible)

	# 26) R24 READ-RISK in the confirm panel — fresh controller so the on-the-
	#     clock derivation is deterministic (fresh tick 0, id sort -> Dario, feint
	#     granted Lv3 -> threshold 7). The armed feint's part pick must show the
	#     Mind counter honestly for all three classes, preview-only: the dim boss
	#     (Mind 1, max 5 < 7 — impossible), Sage (Mind 7 — auto-read), Imani
	#     (Mind 4 — reads on 3+ on d4). The read asks the DEFENDER, so ally and
	#     contestant targets preview too.
	await _teardown_hud()
	_stand_up_fresh("SmokeControllerReadRisk", false, false)
	_add_contestant("sage", "Sage", {"physique": 3, "reflexes": 3, "mind": 7, "charm": 3}, [1, -1])
	await _settle()
	_check("read-risk: dario on the clock (fresh tick)", hud._active_actor == "dario")
	hud._on_category("skills")
	await _settle()
	hud._on_flyout_entry("skill:feint")
	await _settle()
	_check("read-risk: feint armed + boss auto-focused",
		String(hud._armed.get("key", "")) == "feint" and hud._focus_id == "boss")
	hud._on_inspector_part_clicked("left_hand")
	await _settle()
	_check("read-risk: boss too dim to read (impossible)",
		_panel_has_text(hud._shell.action_preview, "too dim to read it"))
	hud._shell.action_preview.back_requested.emit()
	await _settle()
	hud._on_token_clicked("sage")
	await _settle()
	hud._on_inspector_part_clicked("torso")
	await _settle()
	_check("read-risk: Sage WILL read it (auto)",
		_panel_has_text(hud._shell.action_preview, "WILL read this — Mind 7"))
	await _render("smoke_feint_read_risk.png")
	hud._shell.action_preview.back_requested.emit()
	await _settle()
	hud._on_token_clicked("imani")
	await _settle()
	hud._on_inspector_part_clicked("torso")
	await _settle()
	_check("read-risk: Imani reads on 3+ on d4 (roll_needed)",
		_panel_has_text(hud._shell.action_preview, "reads on 3+ on d4"))
	_check("read-risk previews declared nothing", not _schedule_has("dario", "feint"))
	var esc := InputEventKey.new()
	esc.pressed = true
	esc.keycode = KEY_ESCAPE
	hud._unhandled_input(esc)  # closes the preview (BACK, one step)
	await _settle()
	hud._unhandled_input(esc)  # cancels the armed feint
	await _settle()
	_check("read-risk: esc cleared the armed feint", hud._armed.is_empty())

	# 27) PRESSURE-VALVE ANNOUNCES (decision #27 -> broadcast): fresh controller
	#     with the dodge STRIPPED (capture_states' documented driver-side spec
	#     choice — deterministic scripted hits) and the REAL PausedClockDriver
	#     attached, so END TURN runs the boss's decide inside advance_moment and
	#     the beat events land DURING _on_end_turn — proving the loud lines
	#     outrank the generic END TURN flavor exactly like the feint payoff.
	await _teardown_hud()
	_stand_up_fresh("SmokeControllerValve", true, true)
	await _settle()
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "bleeding", "amount": 10},
		"attack_range": 1, "targets": [{"id": "boss", "part": "right_hand"}]}})
	hud._on_end_turn()
	await _settle()
	_check("valve: boss breached", bool(_row("boss").get("breached", false)))
	gc.apply_command({"type": "declare_action", "actor": "imani", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
		"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
	gc.apply_command({"type": "declare_action", "actor": "dario", "action": {
		"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 9},
		"attack_range": 1, "targets": [{"id": "boss", "part": "network"}]}})
	hud._on_end_turn()
	await _settle()
	var vnet := -1
	for pd in _row("boss").get("parts", []):
		if String((pd as Dictionary).get("key", "")) == "network":
			vnet = int((pd as Dictionary).get("hp", -1))
	_check("valve: network at the valve threshold (<= 35)", vnet >= 0 and vnet <= 35)
	var telegraph_seen := false
	for i in 5:
		hud._on_end_turn()
		await _settle()
		if _log_has("explosion_telegraph"):
			telegraph_seen = true
			break
	_check("valve: explosion_telegraph reached the log", telegraph_seen)
	var tele_line := _log_line("explosion_telegraph")
	_check("valve: telegraph line is the broadcast copy",
		tele_line.contains("STEAM SCREAMS") and tele_line.contains("RUN."))
	_check("valve: ticker keeps the telegraph over the END TURN line",
		String(hud._shell.ticker._line.text).contains("STEAM SCREAMS"))
	await _render("smoke_valve_telegraph.png")
	var blast_seen := false
	for i in 5:
		hud._on_end_turn()
		await _settle()
		if _log_has("explosion_blast"):
			blast_seen = true
			break
	_check("valve: explosion_blast reached the log", blast_seen)
	_check("valve: blast line is the broadcast copy",
		_log_line("explosion_blast").contains("THE VALVE BLOWS"))
	var ko_lines: Array = []
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == "explosion_knockout":
			ko_lines.append(String((ed as Dictionary).get("line", "")))
	var ko_ok := not ko_lines.is_empty()
	for kl in ko_lines:
		if not (String(kl).contains("OUT COLD") and String(kl).contains("2 Clocks")):
			ko_ok = false
	_check("valve: per-victim knockout copy (OUT COLD / 2 Clocks)", ko_ok)
	var ko_all := " | ".join(PackedStringArray(ko_lines))
	_check("valve: both victims named", ko_all.contains("IMANI") and ko_all.contains("DARIO"))
	_check("valve: breach reset announce (RETREATS deeper)",
		_log_line("breach_reset").contains("RETREATS deeper"))
	_check("valve: ticker holds a valve line over the generic flavor",
		String(hud._shell.ticker._line.text).contains("RETREATS deeper"))
	await _render("smoke_valve_blast.png")

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


## Ground truth for "can declare this Moment" — mirrors the balance driver's
## readiness gate (alive, not helpless, not winding up, cost paid off).
func _actor_ready(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	if c == null:
		return false
	return c.alive and not c.removed_from_play and not c.is_helpless(gc.sim.clock.tick) \
		and gc.sim.clock.tick >= c.next_action_tick and not c.windup_pending


## True when the pending schedule holds a row for (actor, key) — windup-flagged
## when require_windup is set. Ground truth straight off the view probe.
func _schedule_has(actor: String, key: String, require_windup := false) -> bool:
	for rd in gc.view_schedule():
		var r: Dictionary = rd
		if String(r.get("actor", "")) == actor and String(r.get("key", "")) == key:
			if not require_windup or bool(r.get("windup", false)):
				return true
	return false


## One combatant's view row off the CURRENT controller (ground truth, read-only).
func _row(id: String) -> Dictionary:
	for cd in gc.view_combatants():
		if String((cd as Dictionary).get("id", "")) == id:
			return cd
	return {}


func _log_has(event_type: String) -> bool:
	return _log_line(event_type) != ""


## The LATEST logged line for an event type ("" when none reached the log).
func _log_line(event_type: String) -> String:
	var line := ""
	for ed in hud._event_log:
		if String((ed as Dictionary).get("type", "")) == event_type:
			line = String((ed as Dictionary).get("line", ""))
	return line


## Fresh controller + HUD for the quick-win sections (capture_states' per-stage
## idiom). strip_dodge is the documented driver-side spec choice (deterministic
## scripted hits — never an engine edit); attach_driver wires the REAL
## PausedClockDriver exactly like scenes/main.gd, so END TURN runs the boss's
## decide inside advance_moment.
func _stand_up_fresh(cname: String, strip_dodge: bool, attach_driver: bool) -> void:
	gc = GameControllerScript.new()
	gc.name = cname
	root_node.add_child(gc)
	gc.start_combat(SEED)
	var combatant: Dictionary = {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}
	if strip_dodge:
		var boss_traits: Dictionary = {}
		var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
		for entry in enemies as Array:
			if String((entry as Dictionary).get("key", "")) == "incinedile":
				boss_traits = ((entry as Dictionary).get("traits", {}) as Dictionary).duplicate(true)
		boss_traits.erase("dodge_threshold")
		boss_traits.erase("dodge_threshold_note")
		combatant["boss_traits"] = boss_traits
	gc.apply_command({"type": "add_combatant", "combatant": combatant})
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0],
		{"skills": IMANI_SKILLS})
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
		{"skills": DARIO_SKILLS})
	if attach_driver:
		var driver := PausedClockDriver.new()
		driver.attach(gc)
		driver.set_party(["imani", "dario"] as Array[String])
		gc.set_clock_driver(driver)
	hud = HUD_SCENE.instantiate()
	root_node.add_child(hud)
	hud.bind(gc)


func _teardown_hud() -> void:
	root_node.remove_child(hud)
	hud.queue_free()
	hud = null
	root_node.remove_child(gc)
	gc.queue_free()
	gc = null
	await process_frame
	await process_frame


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
