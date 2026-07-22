extends Control
## CombatHud — HUD v2 THIN FACADE (front-rework Phase 1: STRUCTURE, per
## docs/ux-designs/hud-v2/ARCHITECTURE.md + ADOPTION.md).
##
## PRESENTATION ONLY. Never imports simulation/ classes; reads sim state
## exclusively through the GameController VIEW API (view_combatants /
## view_clock / view_broadcast / view_turn_order / view_encounter), subscribes
## to sim_event so it re-renders as the command stream resolves, and drives
## input the other way through GameController.apply_command — the one command
## funnel. It authors NO sim state.
##
## v2 STRUCTURE: this script is now a FACADE over the component scenes in
## ui/hud/components/ (HudShell + PartyRail/PartyCard, SelectedActorSummary,
## MomentTimeline, CrowdPanel, EntityInspector, ActionLauncher/ActionFlyout,
## MomusTicker, EventLogOverlay, ArenaView). The facade owns ALL state and
## meaning joins — active actor, focus/selection, armed action, event log,
## emoji/boss identity — maps view data into plain display dicts for the dumb
## components, and routes their signals back into sim commands.
##
## COMPATIBILITY BAR (drivers scripts/hud_preview.gd, scripts/hud_interact.gd,
## scripts/hud_arena_check.gd are UNCHANGED): bind / refresh / set_active_actor /
## _on_skill / _on_skill_for / _on_end_turn / _on_combined_strike /
## _on_camera_call / _on_bit / _on_move / _on_arena_input plus the readable
## _active_actor / _arena_eff / _arena_off keep their v1 semantics exactly.
##
## PHASE 2 — CONFIRM STEP (spec Areas 10 + 12): the confirm panels
## (ActionPreview / EndTurnConfirmation) are inserted ONLY on the INTERACTIVE
## path — the inspector part-click, the flyout self-skill / combined picks and
## the END TURN button route through _on_inspector_part_clicked /
## _on_end_turn_pressed, whose CONFIRM buttons then call the existing direct
## methods above. Drivers that call the direct methods bypass the panels by
## construction; `confirm_enabled = false` collapses the interactive path onto
## the direct one too. Panel contents come from the READ-ONLY probes
## (GameController.preview_action / view_schedule) — never invented numbers.
##
## VOCABULARY (ADOPTION.md — owner question OPEN, engine terms KEPT): CLOCK =
## the 10-tick lap, MOMENT = the tick position ("CLOCK 3 · MOMENT 07").
## Every NUMBER on screen is PLACEHOLDER (R14) — the watermark says so.

const HudShellScene := preload("res://ui/hud/components/hud_shell.tscn")
const UI := preload("res://ui/hud/components/hud_theme.gd")

var _gc = null  # GameController (untyped: it is the `Game` autoload script, no class_name)
var _shell     # HudShell instance (untyped: component methods are script-defined)

# ---- input wiring ----------------------------------------------------------
## The "ON THE CLOCK" contestant — the launcher / The Bit / Camera Call / MOVE
## act as this id. DERIVED every refresh() from view_turn_order() as the first
## `ready && is_contestant` entry (fallback: keep the current one), so END TURN
## rotates it automatically. set_active_actor() can force it as an override, but
## the next refresh re-derives from live turn order. (v1 semantics, unchanged.)
var _active_actor := "dario"

var _selected_id := ""        # party-rail selection (summary panel); defaults to active
var _focus_id := ""           # inspector focus (card / token / boss click)
var _armed: Dictionary = {}   # armed action awaiting a target part ({} = none)
var _open_cat := ""           # open flyout category ("" = closed)
var _move_mode := false       # MOVE click-to-target armed?

## Phase 2 confirm flow. confirm_enabled is a plain toggle drivers may flip to
## collapse the interactive path onto the direct methods (drivers calling the
## direct methods bypass the panels anyway). _pending_confirm remembers what
## the open ActionPreview would declare: {kind: "part"|"self"|"combo", ...}.
var confirm_enabled := true
var _pending_confirm: Dictionary = {}

# ---- identity / caches (facade-owned meaning joins) ------------------------
var _last_combatants: Array = []
var _emoji_map := {}          # id -> token emoji (keyed by the view's `token`)
var _boss_id_cache := ""
var _event_log: Array = []    # [{type, line}] — every sim_event this session
var _latest_tag_line := ""    # most recent tag-ish event, for the crowd panel

## The board transform lives in ArenaView; these getters keep the v1-readable
## surface (scripts/hud_arena_check.gd reads hud._arena_eff / hud._arena_off).
var _arena_eff: float:
	get:
		return float(_shell.arena.eff) if _shell != null else 40.0
var _arena_off: Vector2:
	get:
		return (_shell.arena.off as Vector2) if _shell != null else Vector2.ZERO

## Per-skill MECHANICS live in the MODEL (simulation/skill_book.gd, a global
## class the HUD may query — same rule as v1); the HUD sends NO damage numbers
## for skills. Targeted skills default to the boss's flamethrower arm — the
## designed path in — unless the player picks a part via the inspector.
const BOSS_DEFAULT_PART := "left_hand"
const SKILL_ATTACK_RANGE := 2

## COMBINED STRIKE (R15 merged force) — v1 command shape, unchanged.
const COMBO_ID := "party_combo"
const COMBO_MEMBERS := [
	["imani", "strong_strike"],
	["dario", "pressure_strike"],
]

## Per-loadout SKILLS are combatant STATE now (the last fixture holdover is
## gone): the SKILLS flyout and every skill declare read the active actor's
## `skills` rows off view_combatants ({key, level, name, cost, self}) — see
## _flyout_data / _skill_level_of. No fixture list, no hardcoded level 1.

## Purely-visual display-art table: view `token` -> emoji (v1, unchanged).
const TOKEN_EMOJI := {
	"incinedile": "🐊",
	"imani": "🛡️",
	"dario": "🎭",
	"roach_dog": "🪳",
	"little_brother_roach": "🪳",
}
const TOKEN_EMOJI_DEFAULT := "🎪"

const PART_LABEL := {
	"head": "HEAD", "torso": "TORSO", "left_arm": "L-ARM", "right_arm": "R-ARM",
	"left_leg": "L-LEG", "right_leg": "R-LEG", "left_hand": "L-HAND",
	"right_hand": "R-HAND", "network": "NETWORK",
}

## Purely-visual patron accent colours (patron KEY -> colour; v1, unchanged).
const PATRON_COLORS := {"hestia": UI.GOLD, "enyo": UI.MYTHIC}
const PATRON_COLOR_DEFAULT := UI.PURPLE

var _built := false


func _ready() -> void:
	_ensure_built()


## Build once, on whichever call comes first (bind() can arrive before _ready()
## in the SceneTree drivers — v1 lazy-build rule, kept).
func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shell = HudShellScene.instantiate()
	_shell._ensure_built()  # component refs must exist before we wire signals
	add_child(_shell)
	_shell.party_rail.card_clicked.connect(_on_card_clicked)
	_shell.arena.click_input.connect(_on_arena_input)
	_shell.arena.token_clicked.connect(_on_token_clicked)
	# INTERACTIVE paths route through the Phase 2 confirm panels; the direct
	# methods (_on_inspector_part / _on_end_turn) keep their v1 semantics for
	# drivers and are what the panels' CONFIRM buttons call.
	_shell.inspector.part_clicked.connect(_on_inspector_part_clicked)
	_shell.launcher.category_pressed.connect(_on_category)
	_shell.launcher.end_turn_pressed.connect(_on_end_turn_pressed)
	_shell.flyout.entry_pressed.connect(_on_flyout_entry)
	_shell.ticker.clicked.connect(_open_log)
	_shell.event_log.close_requested.connect(_close_log)
	_shell.action_preview.confirmed.connect(_on_preview_confirmed)
	_shell.action_preview.back_requested.connect(_on_preview_back)
	_shell.end_turn_confirm.confirmed.connect(_on_end_turn_confirmed)
	_shell.end_turn_confirm.cancelled.connect(_on_end_turn_cancelled)
	_momus("—and Dario bows mid-combat, the absolute professional!")


# ------------------------------------------------------------------ public API
## Bind the HUD to a live GameController and do a first render. Subscribes to
## the generic sim_event plus two typed signals (wiring proof) — v1 contract.
func bind(game) -> void:
	_ensure_built()
	_gc = game
	if _gc != null and not _gc.sim_event.is_connected(_on_sim_event):
		_gc.sim_event.connect(_on_sim_event)
		_gc.clock_moment_changed.connect(_on_event)  # typed-signal wiring proof
		_gc.hype_band_changed.connect(_on_event)
	refresh()


## Every sim event: append to the session event log (MomusTicker / overlay),
## then re-render. Typed signals go through _on_event (refresh only) so the
## log never double-counts an event.
func _on_sim_event(e: Dictionary = {}) -> void:
	if not e.is_empty():
		var t := String(e.get("type", ""))
		_event_log.append({"type": t, "line": _event_line(e)})
		if _event_log.size() > 300:
			_event_log = _event_log.slice(_event_log.size() - 300)
		if t.contains("tag"):
			_latest_tag_line = "🏷 %s" % _event_line(e)
	refresh()


func _on_event(_e: Dictionary = {}) -> void:
	refresh()


## Forces the on-the-clock contestant (override) — v1 semantics: holds only
## until the next refresh re-derives from live turn order.
func set_active_actor(id: String) -> void:
	_active_actor = id
	if _shell != null:
		_shell.launcher.set_who(_display_name_for(id))


# ------------------------------------------------------------------ input -> command
## Skill by key, acting as the on-the-clock contestant (v1 surface).
func _on_skill(skill_key: String) -> void:
	_declare_skill_attack(_active_actor, skill_key)


## Skill by key, acting as a specific contestant (v1 surface).
func _on_skill_for(actor_id: String, skill_key: String) -> void:
	_declare_skill_attack(actor_id, skill_key)


## Declares a kind=="skill" action; the sim (SkillBook + ActionResolver) owns
## the mechanics. Self skills declare with no target; every other skill targets
## `part` on the boss (default: the flamethrower arm — the designed path in).
func _declare_skill_attack(actor_id: String, skill_key: String, part := BOSS_DEFAULT_PART) -> void:
	# The REAL granted level from the view row (loadout state); 1 when not granted.
	var level := _skill_level_of(actor_id, skill_key)
	var label := skill_key.replace("_", " ").to_upper()
	if SkillBook.is_self_skill(skill_key):
		_issue({
			"type": "declare_action",
			"actor": actor_id,
			"action": {"kind": "skill", "key": skill_key, "level": level},
		}, "%s uses %s" % [_display_name_for(actor_id), label])
		return
	var boss := _boss_id()
	if boss == "":
		_momus("No boss on the board.")
		return
	_issue({
		"type": "declare_action",
		"actor": actor_id,
		"action": {
			"kind": "skill",
			"key": skill_key,
			"level": level,
			"attack_range": SKILL_ATTACK_RANGE,
			"targets": [{"id": boss, "part": part}],
		},
	}, "%s winds up %s on the %s" % [_display_name_for(actor_id), label, _part_label(part)])


## COMBINED STRIKE — v1 command shape unchanged: the sim merges the linked
## Forces before the robustness gate; each member pays its own cost-2 windup.
func _on_combined_strike() -> void:
	if _gc == null:
		return
	var boss := _boss_id()
	if boss == "":
		_momus("No boss on the board.")
		return
	if not _combo_ready():
		_momus("DENIED · COMBINED STRIKE NEEDS BOTH CONTESTANTS READY")
		return
	var members: Array = []
	for m in COMBO_MEMBERS:
		members.append({"actor": String(m[0]), "action": {
			"kind": "skill",
			"key": String(m[1]),
			"level": _skill_level_of(String(m[0]), String(m[1])),
			"attack_range": SKILL_ATTACK_RANGE,
			"targets": [{"id": boss, "part": BOSS_DEFAULT_PART}],
		}})
	_issue({"type": "combined_action", "combo_id": COMBO_ID, "members": members},
		"IMANI and DARIO strike as one — linked force on the flamethrower arm")


## Both combo members alive and ready this tick, from view_turn_order() (v1).
func _combo_ready() -> bool:
	if _gc == null:
		return false
	var ready := {}
	for e in _gc.view_turn_order():
		var ed: Dictionary = e
		ready[String(ed.get("id", ""))] = bool(ed.get("ready", false))
	for m in COMBO_MEMBERS:
		if not bool(ready.get(String(m[0]), false)):
			return false
	return true


func _on_camera_call() -> void:
	_issue({"type": "camera_call", "actor": _active_actor, "target": _active_actor},
		"%s calls the camera onto themselves — swings now doubled" % _display_name_for(_active_actor))


## THE BIT. Defensive on the widened view field a parallel story is adding:
## uses the active actor's authored `bit.key` when the view carries one, and
## falls back to the v1 fixed key when the field is absent (old behavior).
func _on_bit() -> void:
	var mine := _bit_of(_active_actor)
	var key := String(mine.get("key", "encore_bow"))
	if key == "":
		key = "encore_bow"
	_issue({"type": "bit", "actor": _active_actor, "key": key},
		"%s drops the Bit — pure spectacle for the crowd" % _display_name_for(_active_actor))


## MOVE arms click-to-target (v1 semantics): the arena highlights reachable
## hexes and the next click issues a real move. Toggling MOVE off disarms.
func _on_move() -> void:
	_move_mode = not _move_mode
	if _shell != null:
		_shell.arena.set_move_mode(_move_mode)
	if _move_mode:
		_momus("MOVE — pick a highlighted hex for %s" % _display_name_for(_active_actor))
	_update_launcher()


## gui_input from the arena click catcher (and callable directly by drivers —
## v1 surface). event.position is local to the arena panel, which shares the
## board transform's coordinate space.
func _on_arena_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_arena_click_local(event.position)


## Local pixel -> axial hex -> real move command. Rejections surface in the
## Momus ticker via _issue — never a crash. (v1 semantics.)
func _arena_click_local(local_pos: Vector2) -> void:
	if not _move_mode:
		return
	var hex: Vector2i = _shell.arena.pixel_to_hex(local_pos)
	_move_mode = false
	_shell.arena.set_move_mode(false)
	_issue({"type": "move", "actor": _active_actor, "to": [hex.x, hex.y]},
		"%s slides to hex %d,%d" % [_display_name_for(_active_actor), hex.x, hex.y])


## END TURN — v1 semantics unchanged: the controller's advance_moment() runs the
## enemy turn and advances; the next refresh re-derives the on-the-clock actor.
func _on_end_turn() -> void:
	if _gc == null:
		return
	_gc.advance_moment()
	refresh()
	_momus("END TURN — the Moment resolves; the enemies make their move")


## The one command funnel: apply, surface any rejection in the Momus ticker
## (never crash), otherwise show the flavor line. (v1, unchanged.)
func _issue(cmd: Dictionary, flavor := "") -> void:
	if _gc == null:
		return
	var events: Array = _gc.apply_command(cmd)
	var rejected := ""
	for e in events:
		if String((e as Dictionary).get("type", "")) == "command_rejected":
			rejected = String((e as Dictionary).get("reason", ""))
			break
	refresh()
	if rejected != "":
		_momus("DENIED · %s" % rejected.to_upper().replace("_", " "))
	elif flavor != "":
		_momus(flavor)


# --------------------------------------------------------- component interactions
func _on_category(cat: String) -> void:
	# A category press supersedes any open confirm panel (one transient at a time).
	if _shell != null:
		_shell.hide_action_preview()
		_shell.hide_end_turn_confirm()
	_pending_confirm = {}
	if cat == "move":
		_close_flyout()
		_on_move()
		return
	if _open_cat == cat:
		_close_flyout()
		return
	_open_cat = cat
	_shell.show_flyout(_flyout_data(cat))
	_update_launcher()


func _on_flyout_entry(id: String) -> void:
	_close_flyout()
	if id == "unarmed":
		_arm({"kind": "attack", "key": "unarmed_strike", "cost": 1,
			"damage_type": "crushed", "amount": 1, "label": "UNARMED STRIKE"})
	elif id == "combined":
		# Interactive pick -> confirm step (Area 10); Confirm calls the direct
		# _on_combined_strike (the v1 command shape, unchanged).
		if confirm_enabled:
			_open_combo_preview()
		else:
			_on_combined_strike()
	elif id == "camera_call":
		_on_camera_call()
	elif id == "bit":
		_on_bit()
	elif id.begins_with("skill:"):
		var key := id.substr(6)
		if SkillBook.is_self_skill(key):
			# Self skills have no part pick — the pick IS the confirm moment.
			if confirm_enabled:
				_open_self_preview(key)
			else:
				_on_skill(key)
		else:
			_arm({"kind": "skill", "key": key,
				"cost": int(SkillBook.mechanics(key, _skill_level_of(_active_actor, key)).get("cost", 1)),
				"label": key.replace("_", " ").to_upper()})


## Arms an action awaiting a TARGET PART pick in the inspector (spec Area 10
## flow: category -> action -> target part). Auto-focuses the boss so the
## part rows are immediately pickable.
func _arm(action: Dictionary) -> void:
	_armed = action
	if _boss_id_cache != "" and _is_party(_focus_id):
		_focus_id = _boss_id_cache
	_momus("ARMED · %s — click a part row in the inspector to target it (Esc cancels)"
		% String(action.get("label", "")))
	refresh()


## A part row was clicked while an action is armed: declare on the focused
## entity at that part. The commands are real; the sim adjudicates honestly.
func _on_inspector_part(part_key: String) -> void:
	if _armed.is_empty():
		return
	var a := _armed
	_armed = {}
	var target_id := _focus_id
	if String(a.get("kind", "")) == "attack":
		_issue({
			"type": "declare_action",
			"actor": _active_actor,
			"action": {
				"kind": "attack",
				"key": String(a.get("key", "unarmed_strike")),
				"cost": int(a.get("cost", 1)),
				"attack_range": 1,
				"damage": {"type": String(a.get("damage_type", "crushed")), "amount": int(a.get("amount", 1))},
				"targets": [{"id": target_id, "part": part_key}],
			},
		}, "%s throws an unarmed strike at the %s" % [_display_name_for(_active_actor), _part_label(part_key)])
	else:
		_declare_skill_attack_at(_active_actor, String(a.get("key", "")), target_id, part_key)


## Targeted-skill declaration at an explicit (target, part) — the armed-flow
## twin of _declare_skill_attack (which keeps the v1 boss-default path).
func _declare_skill_attack_at(actor_id: String, skill_key: String, target_id: String, part: String) -> void:
	_issue({
		"type": "declare_action",
		"actor": actor_id,
		"action": {
			"kind": "skill",
			"key": skill_key,
			"level": _skill_level_of(actor_id, skill_key),
			"attack_range": SKILL_ATTACK_RANGE,
			"targets": [{"id": target_id, "part": part}],
		},
	}, "%s winds up %s on the %s" % [_display_name_for(actor_id),
		skill_key.replace("_", " ").to_upper(), _part_label(part)])


# ------------------------------------------------- Phase 2 confirm flow (Areas 10/12)
## INTERACTIVE part pick while armed: opens the ActionPreview confirm panel fed
## by the READ-ONLY probe. The armed state STAYS set — BACK returns to it; the
## panel's CONFIRM calls the existing direct _on_inspector_part (v1 semantics).
func _on_inspector_part_clicked(part_key: String) -> void:
	if _armed.is_empty():
		return
	if not confirm_enabled or _gc == null:
		_on_inspector_part(part_key)
		return
	var action := _armed_action_for(_armed, _focus_id, part_key)
	var probe: Dictionary = _gc.preview_action(_active_actor, action)
	var archetype := ""
	if String(action.get("kind", "")) == "skill":
		archetype = String(SkillBook.mechanics(String(action.get("key", "")),
			int(action.get("level", 1))).get("archetype", ""))
	_pending_confirm = {"kind": "part", "part": part_key}
	var title := String(_armed.get("label", String(action.get("key", "")).replace("_", " ").to_upper()))
	var route := "%s → %s · %s" % [_display_name_for(_active_actor),
		_display_name_for(_focus_id), _part_label(part_key)]
	_shell.show_action_preview(_preview_display(title, route, probe, archetype))


## The action dict the armed action WOULD declare at (target, part) — the exact
## twin of _on_inspector_part's declare, used only to feed the preview probe.
func _armed_action_for(a: Dictionary, target_id: String, part_key: String) -> Dictionary:
	if String(a.get("kind", "")) == "attack":
		return {
			"kind": "attack",
			"key": String(a.get("key", "unarmed_strike")),
			"cost": int(a.get("cost", 1)),
			"attack_range": 1,
			"damage": {"type": String(a.get("damage_type", "crushed")), "amount": int(a.get("amount", 1))},
			"targets": [{"id": target_id, "part": part_key}],
		}
	return {
		"kind": "skill",
		"key": String(a.get("key", "")),
		"level": _skill_level_of(_active_actor, String(a.get("key", ""))),
		"attack_range": SKILL_ATTACK_RANGE,
		"targets": [{"id": target_id, "part": part_key}],
	}


## Self-skill pick (no part step): the pick IS the confirm moment. The preview
## runs at the actor's GRANTED level, so the panel shows the real numbers
## (e.g. brace Lv2 -> guard 2, dance Lv2 -> +2 Charm).
func _open_self_preview(key: String) -> void:
	if _gc == null:
		_on_skill(key)
		return
	var level := _skill_level_of(_active_actor, key)
	var action := {"kind": "skill", "key": key, "level": level}
	var probe: Dictionary = _gc.preview_action(_active_actor, action)
	var spec: Dictionary = SkillBook.mechanics(key, level)
	_pending_confirm = {"kind": "self", "key": key}
	var display := _preview_display(key.replace("_", " ").to_upper(),
		"%s → SELF" % _display_name_for(_active_actor), probe, String(spec.get("archetype", "")))
	# Honest self-effect line straight from the SkillBook numbers.
	var lines: Array = display.get("result_lines", [])
	match String(spec.get("archetype", "")):
		"self_guard":
			lines.append({"text": "▸ Buffers the next Crush/Burn hit by %d (guard then consumed)."
				% int(spec.get("guard_amount", 1)), "color": UI.col(UI.SUCCESS)})
		"self_stance":
			lines.append({"text": "▸ +%d Charm effect while dancing — ends when hit, knocked prone, or attacking."
				% int(spec.get("charm_bonus", 1)), "color": UI.col(UI.SUCCESS)})
	display["result_lines"] = lines
	_shell.show_action_preview(display)


## COMBINED STRIKE pick: previews the R15 merged gate before committing both
## contestants. CONFIRM calls the direct _on_combined_strike (v1 command shape).
func _open_combo_preview() -> void:
	if _gc == null:
		return
	var boss := _boss_id()
	if boss == "":
		_momus("No boss on the board.")
		return
	if not _combo_ready():
		_momus("DENIED · COMBINED STRIKE NEEDS BOTH CONTESTANTS READY")
		return
	var members: Array = []
	var names: Array = []
	for m in COMBO_MEMBERS:
		names.append(_display_name_for(String(m[0])))
		members.append({"actor_id": String(m[0]), "action": {
			"kind": "skill",
			"key": String(m[1]),
			"level": _skill_level_of(String(m[0]), String(m[1])),
			"attack_range": SKILL_ATTACK_RANGE,
			"targets": [{"id": boss, "part": BOSS_DEFAULT_PART}],
		}})
	var probe: Dictionary = _gc.preview_action(String(COMBO_MEMBERS[0][0]), {"combo_members": members})
	_pending_confirm = {"kind": "combo"}
	var route := "%s → %s · %s" % [" + ".join(PackedStringArray(names)),
		_display_name_for(boss), _part_label(BOSS_DEFAULT_PART)]
	_shell.show_action_preview(_preview_display("COMBINED STRIKE", route, probe, "committed_strike"))


## ActionPreview display dict from a probe result. Every number shown comes
## from the probe (or SkillBook) — the panel invents nothing.
func _preview_display(title: String, route_line: String, probe: Dictionary, archetype: String) -> Dictionary:
	var cost := int(probe.get("cost", 1))
	var windup := bool(probe.get("windup", false))
	var windup_line := ""
	if windup:
		windup_line = "⚠ COMMITS THROUGH THE WINDUP — EXPOSED" if archetype == "committed_strike" \
			else "⚠ COMMITS THROUGH THE WINDUP"
	var lines: Array = []
	for rd in probe.get("per_target", []):
		var r: Dictionary = rd
		var tgt := _display_name_for(String(r.get("id", "")))
		var part := _part_label(String(r.get("part", "")))
		match String(r.get("blocked_reason", "")):
			"robustness":
				lines.append({"text": "▸ BLOCKED — robustness (force %d ≤ robustness %d) · net 0"
					% [int(r.get("force", 0)), int(r.get("robustness", 0))], "color": UI.col(UI.MUTED)})
			"surface_immunity":
				lines.append({"text": "▸ BLOCKED — surface immunity · %s %s can't be reached yet"
					% [tgt, part], "color": UI.col(UI.MUTED)})
			"fire_heals":
				lines.append({"text": "▸ WOULD HEAL %s — it drinks fire" % tgt, "color": UI.col(UI.FIRE)})
			_:
				lines.append({"text": "▸ NET %d DAMAGE to %s %s (force %d vs robustness %d)"
					% [int(r.get("net", 0)), tgt, part, int(r.get("force", 0)), int(r.get("robustness", 0))],
					"color": UI.col(UI.SUCCESS) if int(r.get("net", 0)) > 0 else UI.col(UI.GOLD)})
		for cid in r.get("conditions", []):
			var chip := _cond_chip_data(String(cid), 1)
			lines.append({"text": "   + %s would ride the wound" % String(cid).to_upper(),
				"color": chip.get("color", UI.col(UI.TEXT))})
		if bool(r.get("dodge_possible", false)):
			lines.append({"text": "   ⚠ %s may dodge — threshold %d+" % [tgt, int(r.get("dodge_threshold", 0))],
				"color": UI.col(UI.GOLD)})
	if probe.has("merged"):
		var mg: Dictionary = probe.get("merged", {})
		lines.append({"text": "Σ MERGED FORCE %d vs ROBUSTNESS %d → NET %d (one linked hit)"
			% [int(mg.get("force", 0)), int(mg.get("robustness", 0)), int(mg.get("net", 0))],
			"color": UI.col(UI.GOLD)})
	if lines.is_empty():
		lines.append({"text": "Self action — no target.", "color": UI.col(UI.TEXT)})
	var prime := String(probe.get("prime_unmet", ""))
	return {
		"title": title,
		"route_line": route_line,
		"cost_line": "MOMENT COST %d" % cost,
		"windup_line": windup_line,
		"result_lines": lines,
		"prime_line": "" if prime == "" else "✕ PRIME UNMET · %s — cannot declare"
			% prime.replace(":", " ").replace("_", " ").to_upper(),
		"confirm_enabled": prime == "",
	}


func _on_preview_confirmed() -> void:
	var pending := _pending_confirm
	_pending_confirm = {}
	_shell.hide_action_preview()
	match String(pending.get("kind", "")):
		"part":
			_on_inspector_part(String(pending.get("part", "")))
		"self":
			_on_skill(String(pending.get("key", "")))
		"combo":
			_on_combined_strike()


func _on_preview_back() -> void:
	_pending_confirm = {}
	_shell.hide_action_preview()
	if not _armed.is_empty():
		_momus("BACK — still armed: pick a part row in the inspector (Esc cancels)")
	refresh()


## INTERACTIVE END TURN (spec Area 12): the button opens the confirmation;
## its CONFIRM calls the direct _on_end_turn (v1 semantics, driver surface).
func _on_end_turn_pressed() -> void:
	if not confirm_enabled or _gc == null:
		_on_end_turn()
		return
	_close_flyout()
	_shell.hide_action_preview()
	_pending_confirm = {}
	_shell.show_end_turn_confirm(_end_turn_display())


func _on_end_turn_confirmed() -> void:
	_shell.hide_end_turn_confirm()
	_on_end_turn()


func _on_end_turn_cancelled() -> void:
	_shell.hide_end_turn_confirm()
	refresh()


## EndTurnConfirmation display dict — every line from the read-only views
## (view_clock / view_turn_order / view_schedule / view_combatants).
func _end_turn_display() -> Dictionary:
	var clock: Dictionary = _gc.view_clock()
	var tick := int(clock.get("tick", 0))
	var next_tick := tick + 1
	var order: Array = _gc.view_turn_order()
	var active_entry: Dictionary = {}
	for e in order:
		if String((e as Dictionary).get("id", "")) == _active_actor:
			active_entry = e
			break
	var who := _display_name_for(_active_actor)
	var actor_line := "%s will wait." % who
	if bool(active_entry.get("windup_pending", false)):
		actor_line = "%s is committed — the windup keeps rolling." % who
	elif not bool(active_entry.get("ready", true)):
		actor_line = "%s has declared this Moment." % who
	var next_line := ""
	for e in order:
		var ed: Dictionary = e
		if String(ed.get("id", "")) != _active_actor:
			next_line = "NEXT TO ACT · %s" % String(ed.get("name", "")).to_upper()
			break
	var resolve_lines: Array = []
	for rd in _gc.view_schedule():
		var r: Dictionary = rd
		if int(r.get("resolve_tick", -1)) != next_tick:
			continue
		var rid := String(r.get("actor", ""))
		var enemy := not _is_party(rid)
		var text := "⚔ %s — %s resolves" % [_display_name_for(rid),
			String(r.get("key", "")).replace("_", " ").to_upper()]
		if bool(r.get("windup", false)):
			text += " (committed windup)"
		resolve_lines.append({"text": text,
			"color": UI.col(UI.DANGER) if enemy else UI.col(UI.CYAN)})
	var cond_lines: Array = []
	for cd in _last_combatants:
		var c: Dictionary = cd
		if String(c.get("team", "")) != "party":
			continue
		for pd in c.get("parts", []):
			var p: Dictionary = pd
			var conds: Dictionary = p.get("conditions", {})
			var cond_keys: Array = conds.keys()
			cond_keys.sort()
			for cid in cond_keys:
				if not ["bleeding", "burn", "poison"].has(String(cid)):
					continue
				var chip := _cond_chip_data(String(cid), int(conds[cid]))
				cond_lines.append({
					"text": "%s · %s %s — keeps ticking" % [String(chip.get("text", "")),
						String(c.get("name", "")).to_upper(), _part_label(String(p.get("key", "")))],
					"color": chip.get("color", UI.col(UI.TEXT)),
				})
	return {
		"actor_line": actor_line,
		"clock_line": "CLOCK %d · MOMENT %02d  →  CLOCK %d · MOMENT %02d" % [
			int(tick / 10) + 1, 10 - (tick % 10), int(next_tick / 10) + 1, 10 - (next_tick % 10)],
		"next_line": next_line,
		"resolve_lines": resolve_lines,
		"cond_lines": cond_lines,
	}


func _on_card_clicked(id: String) -> void:
	_selected_id = id
	_focus_id = id
	refresh()


func _on_token_clicked(id: String) -> void:
	_focus_id = id
	if _is_party(id):
		_selected_id = id
	refresh()


func _open_log() -> void:
	_shell.event_log.show_log(_event_log)


func _close_log() -> void:
	_shell.event_log.hide_log()


func _close_flyout() -> void:
	_open_cat = ""
	if _shell != null:
		_shell.hide_flyout()
	_update_launcher()


## Esc / right-click: close the topmost transient thing (log > end-turn
## confirmation > action preview [= BACK, one step] > armed action > flyout >
## move targeting) — spec Areas 3/10/12 close rules.
func _unhandled_input(event: InputEvent) -> void:
	var esc: bool = event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE
	var rmb: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_RIGHT
	if not (esc or rmb):
		return
	if _shell != null and _shell.event_log.visible:
		_close_log()
	elif _shell != null and _shell.end_turn_confirm.visible:
		_on_end_turn_cancelled()
	elif _shell != null and _shell.action_preview.visible:
		_on_preview_back()
	elif not _armed.is_empty():
		_armed = {}
		_momus("Cancelled.")
		refresh()
	elif _open_cat != "":
		_close_flyout()
	elif _move_mode:
		_on_move()  # toggles off
	else:
		return
	get_viewport().set_input_as_handled()


# --------------------------------------------------------------------- data bind
func refresh() -> void:
	if _gc == null:
		return
	_ensure_built()
	_last_combatants = _gc.view_combatants()
	_recompute_identity()
	var order: Array = _gc.view_turn_order()
	# Derive the on-the-clock contestant (v1 rule: first ready contestant).
	for e in order:
		var ed: Dictionary = e
		if bool(ed.get("ready", false)) and bool(ed.get("is_contestant", false)):
			_active_actor = String(ed.get("id", ""))
			break
	# Selection / focus defaults + cleanup of vanished ids.
	if _selected_id == "" or _find_combatant(_selected_id).is_empty() or not _is_party(_selected_id):
		_selected_id = _active_actor
	if _focus_id == "" or _find_combatant(_focus_id).is_empty():
		_focus_id = _selected_id

	var bc: Dictionary = _gc.view_broadcast()
	_bind_timeline(order)
	_bind_party(order, bc)
	_bind_summary(order, bc)
	_bind_crowd(bc)
	_bind_inspector()
	_bind_arena()
	_update_launcher(order)
	_shell.ticker.update({"recent_line": _recent_events_line()})
	if _open_cat != "":
		_shell.show_flyout(_flyout_data(_open_cat))  # keep entries (combo dim etc.) honest


func _bind_timeline(order: Array) -> void:
	var clock: Dictionary = _gc.view_clock()
	if clock.is_empty():
		return
	var tick := int(clock.get("tick", 0))
	var moment := int(clock.get("moment", 0))
	var clock_no := int(tick / 10) + 1
	var lap0 := tick - (tick % 10)
	var markers: Array = []
	for e in order:
		var ed: Dictionary = e
		var id := String(ed.get("id", ""))
		var raw := int(ed.get("next_action_tick", 0)) - lap0
		markers.append({
			"slot": clampi(raw, 0, 9),
			"late": raw > 9,
			"emoji": _emoji_for_id(id),
			"name": String(ed.get("name", id)).to_upper(),
			"active": id == _active_actor,
			"boss": id == _boss_id_cache,
			"windup": bool(ed.get("windup_pending", false)),
		})
	# Phase 2 — declared-action bars (Area 4): one bar per pending schedule row,
	# spanning declared -> resolve slot on the lap (clamped; carry-over marked).
	var bars: Array = []
	for rd in _gc.view_schedule():
		var r: Dictionary = rd
		var rid := String(r.get("actor", ""))
		var from_raw := int(r.get("declared_tick", 0)) - lap0
		var to_raw := int(r.get("resolve_tick", 0)) - lap0
		var key_label := String(r.get("key", "")).replace("_", " ").to_upper()
		bars.append({
			"from_slot": clampi(from_raw, 0, 9),
			"to_slot": clampi(maxi(to_raw, from_raw), 0, 9),
			"carry": to_raw > 9,
			"windup": bool(r.get("windup", false)),
			"enemy": not _is_party(rid),
			"emoji": _emoji_for_id(rid),
			"label": key_label,
			"name": "%s — %s · declared M%02d, resolves M%02d%s" % [
				_display_name_for(rid), key_label,
				10 - (int(r.get("declared_tick", 0)) % 10), 10 - (int(r.get("resolve_tick", 0)) % 10),
				" (windup)" if bool(r.get("windup", false)) else ""],
		})
	_shell.timeline.update({
		"clock_no": clock_no,
		"moment": moment,
		"slot_now": tick % 10,
		"next_reset": "NEXT RESET · CLOCK %d" % (clock_no + 1),
		"markers": markers,
		"bars": bars,
	})


func _bind_party(order: Array, bc: Dictionary) -> void:
	var by_id := {}
	for e in order:
		by_id[String((e as Dictionary).get("id", ""))] = e
	var spot_target := String((bc.get("spotlight", {}) as Dictionary).get("target", ""))
	var cards: Array = []
	for cd in _last_combatants:
		var c: Dictionary = cd
		if String(c.get("team", "")) != "party":
			continue
		var id := String(c.get("id", ""))
		var oe: Dictionary = by_id.get(id, {})
		var urgent: Array = []
		for u in _urgent_parts(c, 2):
			urgent.append(u)
		if spot_target == id:
			urgent.append({"text": "📸 SPOTLIGHT — SWINGS DOUBLED", "color": UI.col(UI.GOLD)})
		var state := _overall_state(c)
		cards.append({
			"id": id,
			"name": String(c.get("name", id)).to_upper(),
			"emoji": _emoji_for_id(id),
			"state_word": String(state["word"]),
			"state_color": state["color"],
			"ready_line": _readiness_line(c, oe, true),
			"acting": id == _active_actor,
			"selected": id == _selected_id,
			"alive": bool(c.get("alive", true)),
			"patron": String(c.get("patron", "")),
			"patron_color": _patron_col(String(c.get("patron", ""))),
			"urgent": urgent,
			"shock_line": ("⚡ SHOCK %d" % int(c.get("shock", 0))) if int(c.get("shock", 0)) > 0 else "",
		})
	_shell.party_rail.update(cards)


func _bind_summary(order: Array, bc: Dictionary) -> void:
	var c := _find_combatant(_selected_id)
	if c.is_empty():
		return
	var oe := {}
	for e in order:
		if String((e as Dictionary).get("id", "")) == _selected_id:
			oe = e
			break
	var urgent := _urgent_parts(c, 1)
	var urgent_line := ""
	if not urgent.is_empty():
		urgent_line = "▸ " + String((urgent[0] as Dictionary).get("text", ""))
	elif not bool(c.get("alive", true)):
		urgent_line = "▸ DOWN"
	var spot_target := String((bc.get("spotlight", {}) as Dictionary).get("target", ""))
	var spot_line := ""
	if spot_target == _selected_id:
		spot_line = "📸 SPOTLIGHT · SWINGS DOUBLED"
	var held: Array = ((bc.get("tags", {}) as Dictionary).get(_selected_id, {}) as Dictionary).get("held", [])
	if not held.is_empty():
		var tag_names: Array = []
		for t in held:
			tag_names.append(String(t).replace("_", " ").to_upper())
		spot_line += ("   " if spot_line != "" else "") + "🏷 " + " · ".join(PackedStringArray(tag_names))
	if bool(c.get("exposed", false)):
		spot_line += ("   " if spot_line != "" else "") + "⚠ EXPOSED"
	_shell.summary.update({
		"name": String(c.get("name", _selected_id)).to_upper(),
		"emoji": _emoji_for_id(_selected_id),
		"persona": String(c.get("persona", "")),
		"patron": String(c.get("patron", "")),
		"patron_color": _patron_col(String(c.get("patron", ""))),
		"ready_line": _readiness_line(c, oe, false),
		"acting": _selected_id == _active_actor,
		"urgent_line": urgent_line,
		"spot_line": spot_line,
	})


func _bind_crowd(bc: Dictionary) -> void:
	if bc.is_empty():
		return
	var hype: Dictionary = bc.get("hype", {})
	var goal: Dictionary = bc.get("goal", {})
	var goal_view := {}
	if not goal.is_empty():
		var cl := int(goal.get("clocks_left", 0))
		goal_view = {
			"title": String(goal.get("name", "")).to_upper(),
			"desc": _goal_blurb(String(goal.get("kind", ""))),
			"pay": "+%d HYPE" % int(goal.get("payout", 0)),
			"time": "%d CLOCK%s" % [cl, "" if cl == 1 else "S"],
		}
	var spot: Dictionary = bc.get("spotlight", {})
	var spot_line := "📸 CAMERA CALL · CHARM-GATED · AVAILABLE · DOUBLES GAINS & LOSSES"
	if not spot.is_empty():
		spot_line = "📸 SPOTLIGHT · %s · %d CLOCK%s LEFT · SWINGS DOUBLED" % [
			_display_name_for(String(spot.get("target", ""))),
			int(spot.get("clocks_left", 0)),
			"" if int(spot.get("clocks_left", 0)) == 1 else "S"]
	var tag_line := _latest_tag_line
	if tag_line == "":
		var held: Array = ((bc.get("tags", {}) as Dictionary).get(_active_actor, {}) as Dictionary).get("held", [])
		if not held.is_empty():
			tag_line = "🏷 %s: %s" % [_display_name_for(_active_actor),
				" · ".join(PackedStringArray(held)).to_upper()]
	_shell.crowd.update({
		"hype_meter": int(hype.get("meter", 0)),
		"band_display": String(hype.get("band_display", "")),
		"goal": goal_view,
		"spot_line": spot_line,
		"tag_line": tag_line,
	})


func _bind_inspector() -> void:
	var c := _find_combatant(_focus_id)
	if c.is_empty():
		_shell.inspector.update({"name": "—", "emoji": "❔", "kind_line": "NOTHING FOCUSED",
			"status_line": "Click a party card or an arena token to inspect it.", "parts": []})
		return
	var ally := _is_party(_focus_id)
	var is_boss := bool(c.get("is_boss", false))
	var parts: Array = []
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		var hidden := bool(p.get("hidden", false))
		if hidden:
			# Known-anatomy masking (spec Area 7): the label is anonymized and the
			# HP is withheld — the component never even receives the real values.
			parts.append({"key": String(p.get("key", "")), "label": "🔒 UNKNOWN INTERNAL STRUCTURE",
				"hp_text": "", "ratio": -1.0, "conds": [], "muted": true, "targetable": false})
			continue
		var hp := int(p.get("hp", 0))
		var mx := maxi(1, int(p.get("max_hp", 1)))
		var conds: Array = []
		var pc: Dictionary = p.get("conditions", {})
		var cond_keys: Array = pc.keys()
		cond_keys.sort()
		for cid in cond_keys:
			conds.append(_cond_chip_data(String(cid), int(pc[cid])))
		var destroyed := bool(p.get("destroyed", false))
		var label := _part_label(String(p.get("key", "")))
		if destroyed:
			label += " ✕ DESTROYED"
		elif bool(p.get("disabled", false)):
			label += " · DISABLED"
		parts.append({"key": String(p.get("key", "")), "label": label,
			"hp_text": "%d/%d" % [hp, mx], "ratio": float(hp) / float(mx),
			"conds": conds, "muted": destroyed, "targetable": not destroyed})
	var status_bits: Array = []
	if ally:
		status_bits.append("SHOCK %d" % int(c.get("shock", 0)))
	if bool(c.get("exposed", false)):
		status_bits.append("⚠ EXPOSED")
	if is_boss:
		status_bits.append("PHASE %d" % (2 if bool(c.get("breached", false)) else 1))
		status_bits.append("⚡ BREACHED" if bool(c.get("breached", false)) else "🔒 NETWORK HIDDEN")
	if not bool(c.get("alive", true)):
		status_bits.append("✕ DOWN")
	var kind_line := "ALLY · FULL ANATOMY"
	if not ally:
		kind_line = ("BOSS · " if is_boss else "ENEMY · ") + "KNOWN ANATOMY ONLY"
	var armed_line := ""
	if not _armed.is_empty():
		armed_line = "🎯 ARMED: %s · COST %d — click a part row to target it" % [
			String(_armed.get("label", "")), int(_armed.get("cost", 1))]
	_shell.inspector.update({
		"name": String(c.get("name", _focus_id)).to_upper(),
		"emoji": _emoji_for_id(_focus_id),
		"kind_line": kind_line,
		"status_line": " · ".join(PackedStringArray(status_bits)),
		"armed_line": armed_line,
		"parts": parts,
		"foot_line": "" if ally else "RESISTANCES · not in the view API yet — placeholder line",
	})


func _bind_arena() -> void:
	var boss := _find_combatant(_boss_id_cache)
	var objective: Dictionary = (_gc.view_encounter() as Dictionary).get("objective", {})
	_shell.arena.update({
		"combatants": _last_combatants,
		"boss_id": _boss_id_cache,
		"active_id": _active_actor,
		"emoji": _emoji_map,
		"objective": {
			"text": "OBJECTIVE · " + String(objective.get("text", "")),
			"hidden": _boss_network_hidden(boss) if not boss.is_empty() else true,
		},
		"boss_cond_line": _boss_cond_line(boss),
	})


func _update_launcher(order: Array = []) -> void:
	if _shell == null:
		return
	if order.is_empty() and _gc != null:
		order = _gc.view_turn_order()
	var next_name := ""
	for e in order:
		var ed: Dictionary = e
		if String(ed.get("id", "")) != _active_actor:
			next_name = String(ed.get("name", "")).to_upper()
			break
	var hint := "Pick a category — every entry shows its honest Moment cost."
	if not _armed.is_empty():
		hint = "🎯 ARMED: %s · COST %d — pick a part in the inspector (Esc cancels)" % [
			String(_armed.get("label", "")), int(_armed.get("cost", 1))]
	elif _move_mode:
		hint = "↔ MOVE — pick a highlighted hex for %s (Esc cancels)" % _display_name_for(_active_actor)
	_shell.launcher.update({
		"who": _display_name_for(_active_actor),
		"open_cat": _open_cat,
		"move_armed": _move_mode,
		"hint": hint,
		"end_hint": ("%s ACTS NEXT" % next_name) if next_name != "" else "",
	})


# ------------------------------------------------------------------ flyout data
func _flyout_data(cat: String) -> Dictionary:
	var who := _display_name_for(_active_actor)
	match cat:
		"attack":
			return {"title": "ATTACK — %s" % who, "entries": [
				{"id": "unarmed", "label": "UNARMED STRIKE",
					"sub": "COST 1 · CRUSHED 1 · arms part-targeting — often blocked by robustness",
					"enabled": true, "accent": UI.col(UI.TEXT)},
				{"id": "combined", "label": "COMBINED STRIKE",
					"sub": "IMANI + DARIO linked force · each pays COST 2 · the designed breach path",
					"enabled": _combo_ready(), "accent": UI.col(UI.GOLD)},
			]}
		"skills":
			# VIEW-DRIVEN (no fixture): the active actor's granted `skills` rows
			# off view_combatants — name, honest Moment cost, self/target tag and
			# the GRANTED level, all from the view. Scrollable past 4 entries.
			var entries: Array = []
			for rd in _skills_of(_active_actor):
				var row: Dictionary = rd
				var key := String(row.get("key", ""))
				entries.append({
					"id": "skill:" + key,
					"label": "%s · LV %d" % [String(row.get("name", key)).to_upper(),
						int(row.get("level", 1))],
					"sub": "COST %d · %s" % [int(row.get("cost", 1)),
						"SELF" if bool(row.get("self", false)) else "TARGETED · arms part-targeting"],
					"enabled": true,
					"accent": UI.col(UI.CYAN),
				})
			if entries.is_empty():
				# Honest empty state — a combatant with NO granted skills gets one
				# disabled entry, never a fixture fallback.
				entries.append({"id": "", "label": "NO SKILLS GRANTED",
					"sub": "this combatant has no granted loadout skills — nothing to declare",
					"enabled": false, "accent": UI.col(UI.MUTED)})
			return {"title": "SKILLS — %s (scrolls past 4)" % who, "entries": entries}
		"free":
			var bit := _bit_entry()
			return {"title": "FREE ACTIONS — %s" % who, "entries": [
				{"id": "camera_call", "label": "📸 CAMERA CALL",
					"sub": "CHARM-GATED · spotlights self · DOUBLES gains & losses",
					"enabled": true, "accent": UI.col(UI.GOLD)},
				bit,
			]}
	return {"title": "", "entries": []}


## THE BIT flyout entry, gated on the widened view field (defensive — the field
## is being added by a parallel story): enabled only when the active actor's
## view entry carries a non-empty `bit`; if NO actor has the field at all, keep
## the v1 always-enabled behavior so this flips automatically when it lands.
## FREE-ACTION economy (anti-spam ruling): the bit is a free action and the sim
## allows one free action per combatant per tick — when the active actor's view
## row reads `free_action_used` true, the entry dims honestly (read defensively;
## a view without the field keeps the entry live and lets the sim adjudicate).
func _bit_entry() -> Dictionary:
	var any_field := false
	for cd in _last_combatants:
		if (cd as Dictionary).has("bit"):
			any_field = true
			break
	var mine := _bit_of(_active_actor)
	if not any_field:
		return {"id": "bit", "label": "🎭 THE BIT",
			"sub": "pure spectacle · crowd only (authored bits not in the view yet)",
			"enabled": true, "accent": UI.col(UI.MYTHIC)}
	if mine.is_empty():
		return {"id": "bit", "label": "🎭 THE BIT",
			"sub": "no authored Bit for this contestant (decision-log #25)",
			"enabled": false, "accent": UI.col(UI.MUTED)}
	var bname := String(mine.get("name", mine.get("key", ""))).to_upper()
	if bool(_find_combatant(_active_actor).get("free_action_used", false)):
		return {"id": "bit", "label": "🎭 THE BIT — %s" % bname,
			"sub": "free action already used this Moment",
			"enabled": false, "accent": UI.col(UI.MUTED)}
	return {"id": "bit", "label": "🎭 THE BIT — %s" % bname,
		"sub": "authored spectacle · crowd only",
		"enabled": true, "accent": UI.col(UI.MYTHIC)}


## The active actor's authored bit from the view row, read DEFENSIVELY
## (missing field / wrong type -> {}).
func _bit_of(id: String) -> Dictionary:
	var c := _find_combatant(id)
	if c.is_empty():
		return {}
	var b: Variant = c.get("bit", {})
	return b if typeof(b) == TYPE_DICTIONARY else {}


# ------------------------------------------------------------ meaning-join helpers
## Boss straight from the view API (is_boss — spectator contract, no sniffing).
func _boss_id() -> String:
	if _gc == null:
		return ""
	for cd in _gc.view_combatants():
		var c: Dictionary = cd
		if bool(c.get("is_boss", false)):
			return String(c.get("id", ""))
	return ""


func _recompute_identity() -> void:
	_emoji_map.clear()
	_boss_id_cache = ""
	for cd in _last_combatants:
		var c: Dictionary = cd
		if bool(c.get("is_boss", false)):
			_boss_id_cache = String(c.get("id", ""))
		_emoji_map[String(c.get("id", ""))] = String(
			TOKEN_EMOJI.get(String(c.get("token", "")), TOKEN_EMOJI_DEFAULT))


func _emoji_for_id(id: String) -> String:
	return String(_emoji_map.get(id, TOKEN_EMOJI_DEFAULT))


func _find_combatant(id: String) -> Dictionary:
	for cd in _last_combatants:
		if String((cd as Dictionary).get("id", "")) == id:
			return cd
	return {}


func _is_party(id: String) -> bool:
	return String(_find_combatant(id).get("team", "")) == "party"


## Display name from the view API (falls back to a tidy upper-cased id). Reads
## the live view (not the cache) so it works before the first refresh — v1 rule.
func _display_name_for(id: String) -> String:
	if _gc != null:
		for cd in _gc.view_combatants():
			var c: Dictionary = cd
			if String(c.get("id", "")) == id:
				return String(c.get("name", id)).to_upper()
	return id.to_upper()


## The combatant's granted-skill rows ({key, level, name, cost, self}) from the
## view API. Reads the live view (not the cache) so it works before the first
## refresh — same rule as _display_name_for. [] when unknown / nothing granted.
func _skills_of(id: String) -> Array:
	if _gc != null:
		for cd in _gc.view_combatants():
			var c: Dictionary = cd
			if String(c.get("id", "")) == id:
				var rows: Variant = c.get("skills", [])
				return rows if rows is Array else []
	return []


## The actor's GRANTED level for a skill, off the view row. Default 1 when not
## granted — a declare for an ungranted key still does the honest Lv1 thing.
func _skill_level_of(id: String, skill_key: String) -> int:
	for rd in _skills_of(id):
		var r: Dictionary = rd
		if String(r.get("key", "")) == skill_key:
			return maxi(1, int(r.get("level", 1)))
	return 1


func _part_label(key: String) -> String:
	return String(PART_LABEL.get(key, key.replace("_", "-").to_upper()))


func _patron_col(patron_key: String) -> Color:
	return UI.col(String(PATRON_COLORS.get(patron_key, PATRON_COLOR_DEFAULT)))


## The 1–2 most urgent damaged VISIBLE parts, lowest HP first — the party rail's
## part-based read ("R-ARM 1/2 · BLEEDING T1").
func _urgent_parts(c: Dictionary, count: int) -> Array:
	var damaged: Array = []
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if bool(p.get("hidden", false)):
			continue
		var hp := int(p.get("hp", 0))
		var mx := maxi(1, int(p.get("max_hp", 1)))
		var conds: Dictionary = p.get("conditions", {})
		if hp >= mx and conds.is_empty():
			continue
		damaged.append({"p": p, "hp": hp, "ratio": float(hp) / float(mx)})
	damaged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["hp"] != b["hp"]:
			return int(a["hp"]) < int(b["hp"])
		return float(a["ratio"]) < float(b["ratio"]))
	var out: Array = []
	for d in damaged.slice(0, count):
		var p: Dictionary = (d as Dictionary)["p"]
		var bits: Array = ["%s %d/%d" % [_part_label(String(p.get("key", ""))),
			int(p.get("hp", 0)), int(p.get("max_hp", 1))]]
		var conds: Dictionary = p.get("conditions", {})
		var cond_keys: Array = conds.keys()
		cond_keys.sort()
		for cid in cond_keys:
			bits.append("%s T%d" % [String(cid).to_upper(), int(conds[cid])])
		out.append({"text": " · ".join(PackedStringArray(bits)),
			"color": UI.ramp(float((d as Dictionary)["ratio"]))})
	return out


## Overall state WORD derived from parts (never just a bar — ADOPTION.md).
func _overall_state(c: Dictionary) -> Dictionary:
	if not bool(c.get("alive", true)):
		return {"word": "DOWN", "color": UI.col(UI.DANGER)}
	var hp := 0
	var mx := 0
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if bool(p.get("hidden", false)):
			continue
		hp += int(p.get("hp", 0))
		mx += int(p.get("max_hp", 0))
	if mx <= 0:
		return {"word": "UNKNOWN", "color": UI.col(UI.MUTED)}
	var ratio := float(hp) / float(mx)
	if ratio >= 1.0:
		return {"word": "UNHURT", "color": UI.col(UI.SUCCESS)}
	if ratio > 0.65:
		return {"word": "SCUFFED", "color": UI.col(UI.GOLD)}
	if ratio > 0.35:
		return {"word": "BATTERED", "color": UI.col(UI.GOLD)}
	return {"word": "CRITICAL", "color": UI.col(UI.DANGER)}


## Readiness line from the turn-order entry (engine vocabulary: Clock/Moment).
func _readiness_line(c: Dictionary, oe: Dictionary, compact: bool) -> String:
	if not bool(c.get("alive", true)):
		return "DOWN"
	if oe.is_empty():
		return ""
	if bool(oe.get("windup_pending", false)):
		return "WINDUP"
	if bool(oe.get("ready", false)):
		return "◀ ON THE CLOCK" if String(c.get("id", "")) == _active_actor else "READY"
	var nat := int(oe.get("next_action_tick", 0))
	if compact:
		return "ACTS C%d·M%02d" % [int(nat / 10) + 1, 10 - (nat % 10)]
	return "ACTS AT CLOCK %d · MOMENT %02d" % [int(nat / 10) + 1, 10 - (nat % 10)]


func _boss_network_hidden(c: Dictionary) -> bool:
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if String(p.get("key", "")).contains("network"):
			return bool(p.get("hidden", false))
	return not bool(c.get("breached", false))


## Boss-condition overlay line (highest tier per condition) — v1 readout.
func _boss_cond_line(boss: Dictionary) -> String:
	if boss.is_empty():
		return ""
	var best := {}
	for pd in boss.get("parts", []):
		var p: Dictionary = pd
		var conds: Dictionary = p.get("conditions", {})
		for cid in conds:
			best[String(cid)] = maxi(int(best.get(String(cid), 0)), int(conds[cid]))
	if best.is_empty():
		return ""
	var keys: Array = best.keys()
	keys.sort()
	var bits: Array = []
	for k in keys:
		bits.append("%s T%d" % [String(k).to_upper(), int(best[k])])
	return "🩸 %s · %s" % [String(boss.get("name", "BOSS")).to_upper(),
		"  ·  ".join(PackedStringArray(bits))]


func _cond_chip_data(cond_id: String, tier: int) -> Dictionary:
	var emoji := "🩸"
	var color := UI.col("#ff6b88")
	match cond_id:
		"burn":
			emoji = "🔥"; color = UI.col("#ff9a5a")
		"poison":
			emoji = "🧪"; color = UI.col(UI.SUCCESS)
		"chilled":
			emoji = "❄"; color = UI.col(UI.CYAN)
	return {"text": "%s %s T%d" % [emoji, cond_id.to_upper(), tier], "color": color}


## Presentation copy keyed off goal.kind (the view API carries no blurb) — v1.
func _goal_blurb(kind: String) -> String:
	match kind:
		"exposed_strike": return "Land a hit from an Exposed state — make it look easy."
		"overkill": return "Land one huge hit — bury the needle in a single blow."
		"takedown": return "Finish a contestant off before the deadline."
		"part_break": return "Break a body part clean off — give them a souvenir."
		"forced_action": return "Trigger a Forced-Action pratfall — comedy is content."
		"body_block": return "Take a hit for a teammate — sell the sacrifice."
		"move_spaces": return "Cover ground — give the cameras a chase."
	return "Give the crowd the beat they came for."


# --------------------------------------------------------------- momus / event log
func _momus(text: String) -> void:
	if _shell != null:
		_shell.ticker.set_momus(text)


## One short line per sim event for the ticker/overlay: the interesting fields,
## in a stable order, joined tersely. Structure pass — copy comes with the
## visuals/writing epic.
func _event_line(e: Dictionary) -> String:
	var bits: Array = []
	for k in ["actor", "target", "id", "part", "amount", "damage_type", "condition",
			"tier", "reason", "tag", "key", "tick", "moment", "band", "meter", "outcome"]:
		if e.has(k):
			bits.append("%s=%s" % [k, str(e[k])])
	return " ".join(PackedStringArray(bits)) if not bits.is_empty() else "(no detail)"


func _recent_events_line() -> String:
	if _event_log.is_empty():
		return ""
	var types: Array = []
	for ed in _event_log.slice(maxi(0, _event_log.size() - 2)):
		types.append(String((ed as Dictionary).get("type", "")))
	return "LATEST: " + " · ".join(PackedStringArray(types))
