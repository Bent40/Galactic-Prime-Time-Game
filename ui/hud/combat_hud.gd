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
# KAN-6 phase 2 — the VOICEBOX throw's hex pick. R35 waives the throw's whole
# cost out of combat but never its RANGE, so the throw needs a target hex like
# any other: this arms the same board click-catcher MOVE uses, at the skill's
# own authored throw_range, and the click becomes the real declare's `at`.
var _throw := {}              # {} = not throwing, else {key, level, range}
# MODE D — the Mod-Center popup. Open state + which offer is expanded.
var _mod_center_open := false
var _mod_focus := ""

## R34/R35 FREE-FORM EXPLORATION (decision #36, approved frame 4).
##
## `_phase` is the live view_phase() projection — the one thing that decides
## WHICH GAME the HUD is drawing. Everything else here is DRIVER state, which
## is the whole point of the ruling: pause has no sim state and never will.
##
## `_explore_driver` is the missing half R34/R35 flagged: something must issue
## the exploration time step at a real-time cadence and STOP issuing it while
## paused or while an inventory / item-use surface is open. This facade owns
## it because this facade owns the PAUSE button and the inventory surface; it
## is pumped from _process and reads the phase off the same public projection.
var _phase: Dictionary = {}
var _explore_driver = null

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
## Loudest broadcast announce from the CURRENT command's events (skill-feel
## pass): feint payoffs / knockdowns / stand-ups must not be clobbered by the
## generic flavor line — _issue and _on_end_turn re-assert this after their
## refresh, then clear it.
var _pending_announce := ""

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
	_shell.launcher.pause_pressed.connect(_on_pause)
	_shell.timeline.pause_toggled.connect(_on_pause)
	_shell.flyout.entry_pressed.connect(_on_flyout_entry)
	_shell.ticker.clicked.connect(_open_log)
	_shell.event_log.close_requested.connect(_close_log)
	_shell.action_preview.confirmed.connect(_on_preview_confirmed)
	_shell.action_preview.back_requested.connect(_on_preview_back)
	_shell.end_turn_confirm.confirmed.connect(_on_end_turn_confirmed)
	_shell.end_turn_confirm.cancelled.connect(_on_end_turn_cancelled)
	_shell.mod_center.close_requested.connect(_close_mod_center)
	_shell.mod_center.offer_focused.connect(_on_offer_focused)
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
	# R35 driver contract: stand the exploration time-step driver up with the
	# binding. It advances NOTHING in combat (can_advance gates on the phase
	# projection), so a combat-only HUD behaves exactly as it did before.
	if _gc != null:
		_explore_driver = ExplorationClockDriver.new()
		_explore_driver.attach(_gc)
	refresh()


## The presentation loop, which is where the clock-driver contract says a
## driver is pumped from ("call try_advance() from the presentation loop").
## Out of combat this is what makes time run: one logged advance_tick every
## SECONDS_PER_TICK real seconds — and therefore one patrol beat, one
## condition sweep at the Clock reset, one crowd-goal draw per completed
## Clock. It stops dead while PAUSE is on or an inventory surface is open.
## Driver-facing escape hatch (the confirm_enabled idiom): flip this off and
## the HUD stops pumping time automatically, so a capture driver or a test can
## step the exploration clock by hand and assert exactly what one step does.
var auto_time_steps := true


func _process(delta: float) -> void:
	if _explore_driver == null or not auto_time_steps:
		return
	if _explore_driver.tick_realtime(delta) > 0:
		# The tick's own events already refreshed the HUD through sim_event;
		# this keeps the elapsed readout live even on a silent tick.
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
		# Skill-feel pass: payoff moments go LOUD — straight onto the Momus line
		# and remembered so _issue/_on_end_turn's generic flavor can't bury them.
		var announce := _broadcast_announce(e)
		if announce != "":
			_pending_announce = announce
			_momus(announce)
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
## Part-pick fix (owner #3): the interactive flyout path now arms the part-pick
## step and passes the PICKED part here; drivers calling this bare keep the v1
## default-part semantics (the sim is unchanged either way).
func _on_combined_strike(part := BOSS_DEFAULT_PART) -> void:
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
			"targets": [{"id": boss, "part": part}],
		}})
	_issue({"type": "combined_action", "combo_id": COMBO_ID, "members": members},
		"IMANI and DARIO strike as one — linked force on the %s" % _part_label(part))


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


# =====================================================================
# KAN-6 phase 2 — THE EXPLORATION ROWS THAT COMMIT (approved frame 4)
#
# Phase 1 shipped Mode A's shape and left these rows INSPECT-ONLY. R35 shipped
# the engine half of all three: the voicebox throw and the lockpick take the
# free-form declare waiver through ActionResolver.declare_free_form, and the
# inventory interaction takes its own through inventory_free_form. So there is
# nothing left to invent — these handlers emit the SAME commands the engine's
# own tests drive, and the sim adjudicates every gate (range, lock tier,
# adjacency, ownership) exactly as it does in combat. The HUD stays
# presentation: it names the actor, the hex, the door or the item, and reads
# the result back out of the event batch.
#
# WHAT THE RESULTS LOOK LIKE, and why they are worth showing:
#   * a throw emits `sound_thrown`, and CombatSim's own R20 noise sweep turns
#     it into `noise_heard` / `alerted` for anything in earshot — R34's "a door
#     heard through a wall can pull a room onto you before you enter it", live.
#   * a free-form pick emits `lock_picked` with `moments: 0` — that zero IS the
#     waiver, so the ticker says it out loud rather than hiding it.
#   * an inventory interaction emits `inventory_used {free: true, exploration:
#     true}` and really runs its effect (a dropped item comes back through
#     `item_recovered`) — never an acceptance stub.
# =====================================================================

## Arms the VOICEBOX throw: the board takes a click at the skill's own authored
## throw_range (SkillBook, never a HUD number) and that hex becomes the real
## declare's `at`. Esc / re-pressing INTERACT disarms.
func _arm_throw() -> void:
	var level := _granted_level_of(_active_actor, "voicebox")
	if level <= 0:
		_momus("DENIED · %s HAS NO VOICEBOX GRANT — nothing to throw"
			% _display_name_for(_active_actor).to_upper())
		return
	var reach := int(SkillBook.mechanics("voicebox", level).get("throw_range", 10))
	_move_mode = false
	_throw = {"key": "voicebox", "level": level, "range": reach}
	if _shell != null:
		_shell.arena.set_pick_mode(true, reach)
	_momus("🔊 VOICEBOX — pick a hex within %d for %s to throw the sound at (Esc cancels)"
		% [reach, _display_name_for(_active_actor)])
	_update_launcher()


## Disarms the throw pick without issuing anything.
func _cancel_throw() -> void:
	if _throw.is_empty():
		return
	_throw = {}
	if _shell != null:
		_shell.arena.set_pick_mode(false, 0)
	_update_launcher()


## The picked hex -> the real free-form declare. Out of combat CombatSim routes
## this through Exploration.is_free_form_declare to declare_free_form, which
## resolves it on the spot at zero cost; in combat the identical command pays
## the full R3 free-action budget. The HUD sends ONE command either way.
func _throw_at(hex: Vector2i) -> void:
	var throw := _throw
	_cancel_throw()
	_issue({
		"type": "declare_action",
		"actor": _active_actor,
		"action": {"kind": "skill", "key": String(throw.get("key", "voicebox")),
			"level": int(throw.get("level", 1)), "at": [hex.x, hex.y]},
	}, "%s throws a mimicked shout at hex %d,%d — anything in earshot investigates THE SOUND" % [
		_display_name_for(_active_actor), hex.x, hex.y])


## PICK THE <DOOR> — the R35 free-form lockpick. The command is the ordinary
## lockpicking declare naming the door key; the resolver prices it (0 out here,
## the substrate's tier table once the clock runs) and rejects an out-of-reach
## tier / unknown door / non-adjacent actor in its own vocabulary.
func _pick_lock(door_key: String) -> void:
	var level := _granted_level_of(_active_actor, "lockpicking")
	if level <= 0:
		_momus("DENIED · %s HAS NO LOCKPICKING GRANT"
			% _display_name_for(_active_actor).to_upper())
		return
	_issue({
		"type": "declare_action",
		"actor": _active_actor,
		"action": {"kind": "skill", "key": "lockpicking", "level": level, "door": door_key},
	}, "%s works the %s lock" % [_display_name_for(_active_actor),
		door_key.replace("_", " ").to_upper()])


## SCOUT AHEAD — "walk the party up without entering; the gate does not close
## behind you" (frame 4). The commit is deliberately NOT issued: this is only
## the free-form walk, one real `move` per living contestant toward the nearest
## authored exit, and the sim's own walker decides every step (bounds, walls,
## occupancy, reachability). PROVISIONAL, and presentation-side by construction:
## WHICH hex each contestant is sent to is a UI convenience (the free hex
## adjacent to the door nearest that contestant, deterministic by sorted id and
## fixed direction order) — nothing about it is a rule, and a rejection is
## surfaced rather than retried. With no authored door there is nothing to
## scout toward and the row says so instead of walking somewhere invented.
func _scout_ahead() -> void:
	var door := _nearest_exit_door()
	if door.is_empty():
		_momus("NOTHING TO SCOUT — this room authors no exits in the view API")
		return
	var pos: Array = door.get("position", [0, 0])
	var gate := Vector2i(int(pos[0]), int(pos[1]))
	var walkers: Array = []
	for cd in _last_combatants:
		var c: Dictionary = cd
		if String(c.get("team", "")) == "party" and bool(c.get("alive", false)):
			walkers.append(String(c.get("id", "")))
	# WHO LEADS. The contestant you are acting with goes first and takes the
	# slot closest to the way out; the rest follow by their own distance to it,
	# id-tie-broken. Order matters mechanically, not cosmetically: the walk is
	# the sim's own free-form walker, which does not re-plan around a body, so
	# a far walker claiming a near slot can wall the ones behind it out of
	# their own. Deterministic either way — same board, same order, same walk.
	walkers.sort_custom(func(a: String, b: String) -> bool:
		if (a == _active_actor) != (b == _active_actor):
			return a == _active_actor
		var da := _hex_distance(_hex_of(a), gate)
		var db := _hex_distance(_hex_of(b), gate)
		return da < db if da != db else a < b)
	var taken: Dictionary = {}
	var moved := 0
	for id_v: Variant in walkers:
		var id := String(id_v)
		var dest := _scout_hex_for(id, gate, taken)
		if dest == Vector2i(9999, 9999):
			continue
		taken[dest] = true
		var events: Array = _gc.apply_command(
			{"type": "move", "actor": id, "to": [dest.x, dest.y]})
		for e in events:
			if String((e as Dictionary).get("type", "")) == "moved":
				moved += 1
	refresh()
	if moved > 0:
		_momus("👣 SCOUTED — %d of %d walk up to the %s. Nothing is committed; the way stays open." % [
			moved, walkers.size(), String(door.get("key", "")).replace("_", " ").to_upper()])
	else:
		_momus("SCOUT FAILED — nobody could reach the %s from here"
			% String(door.get("key", "")).replace("_", " ").to_upper())


## The exit the party would scout toward: the authored door NEAREST the active
## contestant (sorted-key tie-break), off view_arena. {} when none is authored.
func _nearest_exit_door() -> Dictionary:
	var arena: Dictionary = _gc.view_arena() if _gc != null else {}
	var me := _hex_of(_active_actor)
	var best: Dictionary = {}
	var best_d := 1 << 30
	var doors: Array = arena.get("doors", [])
	for raw: Variant in doors:
		var door: Dictionary = raw
		var pos: Array = door.get("position", [0, 0])
		var d := _hex_distance(me, Vector2i(int(pos[0]), int(pos[1])))
		if d < best_d or (d == best_d and String(door.get("key", "")) < String(best.get("key", "~"))):
			best_d = d
			best = door
	return best


## A free hex adjacent to `gate` for `id` to walk to — nearest first, skipping
## hexes already claimed by an earlier walker, standing on a body, or OUTSIDE
## the arena's authored bounds (a doorway on the room's edge has fewer than six
## usable neighbours, and asking the sim to walk off the board would only earn
## an out_of_bounds rejection). Returns the sentinel (9999, 9999) when the
## doorway's ring has nothing left.
func _scout_hex_for(id: String, gate: Vector2i, taken: Dictionary) -> Vector2i:
	var occupied: Dictionary = {}
	for cd in _last_combatants:
		var c: Dictionary = cd
		if String(c.get("id", "")) == id or not bool(c.get("alive", false)):
			continue
		occupied[_hex_of(String(c.get("id", "")))] = true
	var from := _hex_of(id)
	var best := Vector2i(9999, 9999)
	var best_d := 1 << 30
	for dir: Vector2i in HexGeometry.DIRECTIONS:
		var hex: Vector2i = gate + dir
		if taken.has(hex) or occupied.has(hex) or not _in_bounds(hex):
			continue
		var d := _hex_distance(from, hex)
		if d < best_d:
			best_d = d
			best = hex
	return best


## Is the hex inside the arena's authored bounds? Read off view_arena's own
## bounds block (both shapes it publishes: the axial rect and the explicit hex
## set). An arena with no bounds block is the unbounded legacy combat, where
## every hex is in bounds.
func _in_bounds(hex: Vector2i) -> bool:
	var bounds: Dictionary = (_gc.view_arena() if _gc != null else {}).get("bounds", {})
	if bounds.is_empty():
		return true
	if String(bounds.get("kind", "")) == "hexes":
		for raw: Variant in bounds.get("hexes", []) as Array:
			var h: Array = raw
			if h.size() == 2 and int(h[0]) == hex.x and int(h[1]) == hex.y:
				return true
		return false
	var origin: Array = bounds.get("origin", [0, 0])
	var q0 := int(origin[0]) if origin.size() == 2 else 0
	var r0 := int(origin[1]) if origin.size() == 2 else 0
	return hex.x >= q0 and hex.x < q0 + int(bounds.get("width", 0)) \
		and hex.y >= r0 and hex.y < r0 + int(bounds.get("height", 0))


## USE / TAKE an item — R35's inventory waiver. `use` is the ordinary
## interaction (free and ledger-free out of combat, R3's first-free ladder
## resumed the instant the clock runs); `pickup` is the recovery path for an
## item on the floor, which really puts it back in hand (`item_recovered`).
func _use_item(item_key: String, interaction: String) -> void:
	var label := item_key.replace("_", " ").to_upper()
	for raw: Variant in _find_combatant(_active_actor).get("items", []):
		if String((raw as Dictionary).get("key", "")) == item_key:
			label = String((raw as Dictionary).get("name", label)).to_upper()
			break
	_issue({"type": "inventory", "actor": _active_actor,
		"interaction": interaction, "item": item_key},
		("%s picks the %s back up" if interaction == "pickup" else "%s uses the %s") % [
			_display_name_for(_active_actor), label])


## Axial hex of a combatant off the view row ((0, 0) when unknown).
func _hex_of(id: String) -> Vector2i:
	var pos: Array = _find_combatant(id).get("position", [0, 0])
	if pos.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(pos[0]), int(pos[1]))


func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


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
	if _throw.is_empty() and not _move_mode:
		return
	var hex: Vector2i = _shell.arena.pixel_to_hex(local_pos)
	if not _throw.is_empty():
		_throw_at(hex)
		return
	_move_mode = false
	_shell.arena.set_move_mode(false)
	_issue({"type": "move", "actor": _active_actor, "to": [hex.x, hex.y]},
		"%s slides to hex %d,%d" % [_display_name_for(_active_actor), hex.x, hex.y])


## END TURN — v1 semantics unchanged: the controller's advance_moment() runs the
## enemy turn and advances; the next refresh re-derives the on-the-clock actor.
## Skill-feel pass: a loud announce raised by the resolving events (feint
## payoff / knockdown / stand-up) keeps the ticker instead of the generic line.
func _on_end_turn() -> void:
	if _gc == null:
		return
	_pending_announce = ""
	_gc.advance_moment()
	refresh()
	if _pending_announce != "":
		_momus(_pending_announce)
		_pending_announce = ""
	else:
		_momus("END TURN — the Moment resolves; the enemies make their move")


## The one command funnel: apply, surface any rejection in the Momus ticker
## (never crash), otherwise show the flavor line. (v1 semantics; skill-feel
## pass: a loud announce raised by this command's events outranks the flavor.)
func _issue(cmd: Dictionary, flavor := "") -> void:
	if _gc == null:
		return
	_pending_announce = ""
	var events: Array = _gc.apply_command(cmd)
	var rejected := ""
	for e in events:
		if String((e as Dictionary).get("type", "")) == "command_rejected":
			rejected = String((e as Dictionary).get("reason", ""))
			break
	refresh()
	if rejected != "":
		_momus("DENIED · %s" % rejected.to_upper().replace("_", " "))
	elif _pending_announce != "":
		_momus(_pending_announce)
	elif flavor != "":
		_momus(flavor)
	_pending_announce = ""


# --------------------------------------------------------- component interactions
func _on_category(cat: String) -> void:
	# A category press supersedes any open confirm panel (one transient at a time).
	if _shell != null:
		_shell.hide_action_preview()
		_shell.hide_end_turn_confirm()
	_cancel_throw()
	_pending_confirm = {}
	if cat == "move":
		_close_flyout()
		_on_move()
		return
	if _open_cat == cat:
		_close_flyout()
		return
	_open_cat = cat
	# R35's Pokemon clause, honoured at the only place it can be: the driver
	# stops issuing time steps while the inventory / item-use surface is OPEN.
	# The sim has no pause state and never sees this — closing the flyout
	# (_close_flyout) lifts it again.
	if cat == "inventory" and _explore_driver != null:
		_explore_driver.set_blocker("inventory", true)
	_shell.show_flyout(_flyout_data(cat))
	_update_launcher()


func _on_flyout_entry(id: String) -> void:
	_close_flyout()
	if id == "unarmed":
		_arm({"kind": "attack", "key": "unarmed_strike", "cost": 1,
			"damage_type": "crushed", "amount": 1, "label": "UNARMED STRIKE"})
	elif id == "combined":
		# Part-pick, not left_hand default (owner fix #3): the combined strike
		# routes through the SAME part-pick step every targeted declare uses —
		# arm it (boss auto-focused), one click on a part row carries the picked
		# part into the combo preview + declare. Drivers calling the direct
		# _on_combined_strike() keep the v1 default-part semantics.
		if not _combo_ready():
			_momus("DENIED · COMBINED STRIKE NEEDS BOTH CONTESTANTS READY")
		else:
			_arm({"kind": "combined", "label": "COMBINED STRIKE", "cost": 2})
	elif id == "camera_call":
		_on_camera_call()
	elif id == "bit":
		_on_bit()
	# ---- KAN-6 phase 2: the exploration rows that COMMIT (frame 4) ----------
	elif id == "voicebox":
		_arm_throw()
	elif id == "scout":
		_scout_ahead()
	elif id.begins_with("pick:"):
		_pick_lock(id.substr(5))
	elif id.begins_with("use:"):
		_use_item(id.substr(4), "use")
	elif id.begins_with("take:"):
		_use_item(id.substr(5), "pickup")
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
## A combined pick always declares on the BOSS at the picked part (the combo's
## members are fixed) — the part is the choice, the target is the design.
func _on_inspector_part(part_key: String) -> void:
	if _armed.is_empty():
		return
	var a := _armed
	_armed = {}
	var target_id := _focus_id
	if String(a.get("kind", "")) == "combined":
		_on_combined_strike(part_key)
		return
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
	if String(_armed.get("kind", "")) == "combined":
		# Combined pick (owner fix #3): the picked part feeds the R15 merged
		# preview; CONFIRM routes back through _on_inspector_part -> the direct
		# _on_combined_strike(part). The armed state stays set so BACK returns.
		_open_combo_preview(part_key)
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
## contestants, at the PICKED part (owner fix #3 — no silent left_hand default
## on the interactive path; the direct-method default remains for drivers).
## CONFIRM calls the direct _on_combined_strike (v1 command shape).
func _open_combo_preview(part := BOSS_DEFAULT_PART) -> void:
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
			"targets": [{"id": boss, "part": part}],
		}})
	var probe: Dictionary = _gc.preview_action(String(COMBO_MEMBERS[0][0]), {"combo_members": members})
	_pending_confirm = {"kind": "combo", "part": part}
	var route := "%s → %s · %s" % [" + ".join(PackedStringArray(names)),
		_display_name_for(boss), _part_label(part)]
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
		# R24 feint READ-RISK — the Mind counter shown honestly, mirroring the
		# dodge-uncertainty line: outcome class + numbers straight off the
		# probe's additive read_* keys (never invented, never rolled).
		match String(r.get("read_outcome", "")):
			"auto_read":
				lines.append({"text": "   ✕ %s WILL read this — Mind %d ≥ threshold %d" % [
					tgt, int(r.get("read_mind", 0)), int(r.get("read_threshold", 0))],
					"color": UI.col(UI.DANGER)})
			"roll_needed":
				lines.append({"text": "   ⚠ %s reads on %d+ on d%d (Mind %d vs threshold %d)" % [
					tgt, int(r.get("read_roll_needed", 0)), int(r.get("read_die", 0)),
					int(r.get("read_mind", 0)), int(r.get("read_threshold", 0))],
					"color": UI.col(UI.GOLD)})
			"impossible":
				lines.append({"text": "   ✓ %s is too dim to read it — Mind %d, max %d < threshold %d" % [
					tgt, int(r.get("read_mind", 0)),
					int(r.get("read_mind", 0)) + int(r.get("read_die", 0)),
					int(r.get("read_threshold", 0))],
					"color": UI.col(UI.SUCCESS)})
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
			# Routes through _on_inspector_part so the armed combined pick is
			# cleared and the PICKED part reaches _on_combined_strike (fix #3).
			# Defensive: a combo confirm with nothing armed declares directly.
			if _armed.is_empty():
				_on_combined_strike(String(pending.get("part", BOSS_DEFAULT_PART)))
			else:
				_on_inspector_part(String(pending.get("part", BOSS_DEFAULT_PART)))


func _on_preview_back() -> void:
	_pending_confirm = {}
	_shell.hide_action_preview()
	if not _armed.is_empty():
		_momus("BACK — still armed: pick a part row in the inspector (Esc cancels)")
	refresh()


## INTERACTIVE END TURN (spec Area 12): the button opens the confirmation;
## its CONFIRM calls the direct _on_end_turn (v1 semantics, driver surface).
## PAUSE (R34/R35). Driver-side ONLY: this flips whether the exploration driver
## issues time steps. No command is sent, no sim state exists to send it to —
## the ruling is explicit that pause is deliberately not modelled.
func _on_pause() -> void:
	if _explore_driver == null:
		return
	var paused: bool = _explore_driver.toggle_pause()
	_momus("⏸ TIME PAUSED — the driver stops issuing time steps (nothing in the sim knows)"
		if paused else "▶ TIME RUNNING — mobs patrol, conditions tick, the crowd watches")
	refresh()


func _on_end_turn_pressed() -> void:
	if _gc == null:
		_on_end_turn()
		return
	# MODE A: there is no turn to end. The commit is the DELIBERATE ENTER —
	# view_phase()'s own enter_command — which starts the fight with
	# combat_started {reason: "deliberate"}. (The involuntary way in stays the
	# contact sweep, which the running time steps drive.)
	if _exploring():
		_close_flyout()
		_shell.hide_action_preview()
		_shell.hide_end_turn_confirm()
		_pending_confirm = {}
		_on_enter_route()
		return
	if not confirm_enabled:
		_on_end_turn()
		return
	_close_flyout()
	_shell.hide_action_preview()
	_pending_confirm = {}
	_shell.show_end_turn_confirm(_end_turn_display())


## Issues the ENTER commit exactly as the view API hands it over — the HUD
## never authors the phase command's shape.
func _on_enter_route() -> void:
	var cmd: Dictionary = _phase.get("enter_command", {})
	if cmd.is_empty():
		_momus("DENIED · NO ROUTE TO ENTER — the room is already a fight")
		return
	_issue(cmd, "ENTER ▸ %s — the route locks, turn order starts, wounds persist"
		% _route_name())


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


# =====================================================================
# MODE D — THE MODIFICATION CENTER POPUP (approved frame 5)
#
# ARCHITECTURE.md Area 3 requires every popup to DECLARE whether it pauses,
# and Mode D requires the pause state to be "clearly shown". This one pauses,
# and the declaration is enforced, not decorative: while it is open the
# exploration driver holds its time steps through the SAME named-blocker
# mechanism R35's inventory clause uses, so nothing ticks behind the popup.
# In combat there is nothing to hold — the combat clock only advances on END
# TURN, which is unreachable behind a modal — so the popup is honestly paused
# in both modes.
#
# ENTRY POINT: opened by the facade (key M, and directly by drivers). WHERE it
# appears in the run flow is KAN-7 scope by ruling (the approved frames' own
# note), and Area 3's popup-shortcut ROW is still deferred, so there is no
# shortcut button to highlight yet — flagged rather than invented.
# =====================================================================

func _open_mod_center() -> void:
	if _mod_center_open:
		_close_mod_center()
		return
	_mod_center_open = true
	# The declared pause, made real (R35's blocker set — a named surface, so two
	# overlapping holds cannot un-pause each other on close).
	if _explore_driver != null:
		_explore_driver.set_blocker("mod center", true)
	_shell.show_mod_center(_mod_center_data())
	_momus("⬡ MODIFICATION CENTER — the house makes three offers. Time is held while you read.")


func _close_mod_center() -> void:
	if not _mod_center_open:
		return
	_mod_center_open = false
	if _explore_driver != null:
		_explore_driver.set_blocker("mod center", false)
	_shell.hide_mod_center()
	_update_launcher()


func _on_offer_focused(key: String) -> void:
	_mod_focus = key
	if _mod_center_open:
		_shell.show_mod_center(_mod_center_data())


## The popup's display dict. Offers come straight off view_offers() measured
## against the FOCUSED contestant (the inspector's focus when it is a party
## member, else the on-the-clock contestant) — so the requirement rows are that
## character's real granted levels, and switching who you have selected
## re-measures them.
func _mod_center_data() -> Dictionary:
	var who := _selected_id if _is_party(_selected_id) else _active_actor
	var offers: Array = _gc.view_offers(who) if _gc != null else []
	if _mod_focus == "":
		# Default focus: the offer this character is CLOSEST to — the most
		# parents actually STARTED (owned at any level), then the fewest
		# requirements outstanding, then authored order. Derived from the
		# character's real grants, never picked at random, and stable: the same
		# roster always lands on the same offer.
		var best_started := -1
		var best_short := 1 << 30
		for raw: Variant in offers:
			var o: Dictionary = raw
			var started := 0
			for praw: Variant in o.get("parents", []):
				if int((praw as Dictionary).get("owned_level", 0)) > 0:
					started += 1
			var short := int(o.get("requirements_short", 99))
			if started > best_started or (started == best_started and short < best_short):
				best_started = started
				best_short = short
				_mod_focus = String(o.get("key", ""))
	return {
		"offers": offers,
		"focus": _mod_focus,
		"for_name": _display_name_for(who),
		"paused": true,
		"pause_note": "driver",
	}


func _close_log() -> void:
	_shell.event_log.hide_log()


## The one place a flyout closes — so the inventory time-block is lifted here
## and nowhere else (a blocker that outlives its surface would silently freeze
## the room).
func _close_flyout() -> void:
	if _explore_driver != null:
		_explore_driver.set_blocker("inventory", false)
	_open_cat = ""
	if _shell != null:
		_shell.hide_flyout()
	_update_launcher()


## Esc / right-click: close the topmost transient thing (log > end-turn
## confirmation > action preview [= BACK, one step] > armed throw > armed
## action > flyout > move targeting) — spec Areas 3/10/12 close rules.
func _unhandled_input(event: InputEvent) -> void:
	# M toggles MODE D. A provisional binding: Area 3's popup-shortcut row is
	# still deferred and the Mod-Center's place in the run flow is KAN-7, so
	# this is a way IN, not the ruled entry point.
	if event is InputEventKey and event.pressed and event.keycode == KEY_M \
			and not event.is_echo():
		_open_mod_center()
		get_viewport().set_input_as_handled()
		return
	var esc: bool = event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE
	var rmb: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_RIGHT
	if not (esc or rmb):
		return
	if _mod_center_open:
		_close_mod_center()
	elif _shell != null and _shell.event_log.visible:
		_close_log()
	elif _shell != null and _shell.end_turn_confirm.visible:
		_on_end_turn_cancelled()
	elif _shell != null and _shell.action_preview.visible:
		_on_preview_back()
	elif not _throw.is_empty():
		_cancel_throw()
		_momus("Throw cancelled.")
		refresh()
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
	# WHICH GAME are we drawing? (R34) Everything below branches off this one
	# read — there is no turn order and nothing costs Moments out of combat.
	_phase = _gc.view_phase()
	var order: Array = _gc.view_turn_order()
	# WHO IS ACTING. In combat: the on-the-clock contestant (v1 rule — first
	# ready contestant). OUT OF COMBAT there is no turn order at all (R34: "no
	# Moment order, the party walks together"), so deriving an actor from one
	# is meaningless — worse, it silently overrides the player's choice every
	# refresh. Mode A's acting contestant is therefore the SELECTED one, which
	# is what makes the free-form rows (voicebox, lockpick, item use) belong to
	# the contestant whose card you clicked and be measured against THEIR real
	# grants. Falls back to the turn-order derivation before anything is
	# selected, so a driver that never selects behaves exactly as it did.
	var explore_actor := ""
	if _exploring() and _is_party(_selected_id) \
			and bool(_find_combatant(_selected_id).get("alive", false)):
		explore_actor = _selected_id
	if explore_actor != "":
		_active_actor = explore_actor
	else:
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
	if _mod_center_open:
		_shell.show_mod_center(_mod_center_data())
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
	#
	# R34 (decision 2): PARTY ROWS ONLY. The enemy telegraph bands are retired
	# from this strip — enemy intent is now read off the enemy's own INTENT
	# ICON on the board (with R26's ⛔ undodgable declaration on it), and the
	# strip keeps order and timing. Nothing is lost: every enemy row filtered
	# out here is rendered by _intent_rows() below, which carries strictly MORE
	# than the band did (kind, target, damage, interrupt state, undodgable).
	var bars: Array = []
	for rd in _gc.view_schedule():
		var r: Dictionary = rd
		var rid := String(r.get("actor", ""))
		if not _is_party(rid):
			continue
		var from_raw := int(r.get("declared_tick", 0)) - lap0
		var to_raw := int(r.get("resolve_tick", 0)) - lap0
		var key_label := String(r.get("key", "")).replace("_", " ").to_upper()
		bars.append({
			"from_slot": clampi(from_raw, 0, 9),
			"to_slot": clampi(maxi(to_raw, from_raw), 0, 9),
			"carry": to_raw > 9,
			"windup": bool(r.get("windup", false)),
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
		"ticks": _condition_tick_chips(lap0),
		# Mode A swaps this whole slot (R34): out of combat the timing strip
		# has nothing to time, so it becomes the exploration strip.
		"explore": _explore_strip(),
	})


## MODE A strip data ({} in combat). Every field is real: the elapsed readout
## is R0/R1's own tick->fiction conversion applied to the live tick, the pause
## flag is the DRIVER's (never the sim's), and the breadcrumb comes off
## view_run()'s encounter rows — with no run staged it degrades to the single
## honest crumb rather than inventing a route.
func _explore_strip() -> Dictionary:
	if not _exploring():
		return {}
	var paused: bool = _explore_driver != null and _explore_driver.blocked()
	var hold := "" if _explore_driver == null else String(_explore_driver.hold_reason())
	var note := "NO TURN ORDER · NOTHING COSTS MOMENTS · TURNS START ON CONTACT"
	if hold != "":
		note = "⏸ %s — TIME HELD · the world waits with you (driver, not sim state)" % hold
	return {
		"elapsed": _elapsed_text(int(_phase.get("tick", 0))),
		"paused": paused,
		"note": note,
		"crumbs": _route_crumbs(),
	}


## R0/R1 conversion, stated in the addendum and applied here verbatim: ONE TICK
## IS ~0.5 FICTIONAL SECONDS (a Clock ~ 5s). This is elapsed FICTION off the
## logged tick — never a wall clock, which the sim is forbidden to read and the
## HUD has no business showing as if it were game time.
const FICTIONAL_SECONDS_PER_TICK := 0.5


func _elapsed_text(tick: int) -> String:
	var secs := int(round(float(maxi(0, tick)) * FICTIONAL_SECONDS_PER_TICK))
	return "%02d:%02d" % [secs / 60, secs % 60]


## The route breadcrumb that replaces the timing strip (frame 4). Reads
## view_run()'s encounter rows: cleared rooms behind you, the room you stand
## in, what lies ahead. With NO run staged (the demo slice is a bare
## start_combat) there is no route to draw, so it says exactly that.
func _route_crumbs() -> Array:
	var run: Dictionary = _gc.view_run() if _gc != null else {}
	var rows: Array = run.get("encounters", [])
	if rows.is_empty():
		return [{"text": "⌖ YOU ARE HERE", "state": "here"},
			{"text": "NO ROUTE STAGED — SINGLE-ENCOUNTER DRIVE", "state": "ahead"}]
	var here := int((run.get("encounter", {}) as Dictionary).get("active_index", 0))
	var out: Array = []
	for raw: Variant in rows:
		var row: Dictionary = raw
		var idx := int(row.get("index", -1))
		if absi(idx - here) > 1:
			continue  # keep the crumb trail to the immediate neighbourhood
		var label := String(row.get("key", "")).replace("_", " ").to_upper()
		if idx < here:
			out.append({"text": "%s ✓" % label, "state": "done"})
		elif idx == here:
			out.append({"text": "⌖ %s — YOU ARE HERE" % label, "state": "here"})
		else:
			out.append({"text": label, "state": "ahead"})
	return out


## SCHEDULED CONDITION TICKS as timeline chips (approved frame 1's own example,
## "🔥 BURN II → DARIO"). Decision 2 keeps this strip as the order-and-timing
## surface and decision 4 makes status effects load-bearing everywhere: a
## scheduled TICK is timing — when the burn bites — not enemy intent, which R34
## moved onto the enemy's icon. So it belongs here, on its own lane.
##
## SOURCED, NEVER DERIVED. Every row comes off view_condition_schedule(), which
## reads ConditionEngine's own rules (which conditions advance at the reset,
## the infected-T2 acceleration rider, the activation-delay and delay ladders,
## the timer countdowns). This function only turns a row into a chip: the
## Clock-reset tick becomes a slot on the lap, the condition's own theme colour
## and emoji become the chip's, and the tooltip states the whole fact.
##
## WHAT IS SHOWN: the rows that actually BITE (advance / resolve / step-down /
## a timer moving or expiring). A `hold` row (a condition reapplied this Clock,
## or one resting through the reset) and a `dormant` row schedule nothing, so
## drawing them would be noise pretending to be a warning. A PAUSED timer has
## no tick to point at and is skipped for the same reason. Party rows sort
## first — your own bites are the ones you can still act on.
func _condition_tick_chips(lap0: int) -> Array:
	if _gc == null:
		return []
	var rows: Array = []
	for raw: Variant in _gc.view_condition_schedule():
		var r: Dictionary = raw
		var effect := String(r.get("effect", ""))
		if effect == "hold" or effect == "dormant" or effect == "paused":
			continue
		if not r.has("at_tick"):
			continue
		rows.append(r)
	# Party first, then soonest, then by combatant — deterministic every frame.
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := 0 if String(a.get("team", "")) == "party" else 1
		var pb := 0 if String(b.get("team", "")) == "party" else 1
		if pa != pb:
			return pa < pb
		if int(a.get("at_tick", 0)) != int(b.get("at_tick", 0)):
			return int(a.get("at_tick", 0)) < int(b.get("at_tick", 0))
		return String(a.get("combatant", "")) < String(b.get("combatant", "")))
	var out: Array = []
	for raw: Variant in rows:
		var r: Dictionary = raw
		var cond := String(r.get("condition", ""))
		var who := _display_name_for(String(r.get("combatant", ""))).to_upper()
		var slot := clampi(int(r.get("at_tick", 0)) - lap0, 0, 9)
		var effect := String(r.get("effect", ""))
		var label := ""
		var tip := ""
		var part := String(r.get("part", "")).replace("_", " ").to_upper()
		match effect:
			"advance":
				label = "%s %s → %s" % [UI.cond_abbr(cond),
					_roman(int(r.get("to_tier", 1))), who]
				tip = "%s: %s on the %s goes T%d → T%d at the Clock reset%s" % [
					who, String(r.get("condition_name", cond)).to_upper(), part,
					int(r.get("tier", 0)), int(r.get("to_tier", 0)),
					" (×%d — INFECTED T2 acceleration)" % int(r.get("steps", 1)) \
						if int(r.get("steps", 1)) > 1 else ""]
			"resolve":
				label = "%s CLEARS → %s" % [UI.cond_abbr(cond), who]
				tip = "%s: %s on the %s RESOLVES at the Clock reset" % [
					who, String(r.get("condition_name", cond)).to_upper(), part]
			"step_down":
				label = "%s ↓ %s → %s" % [UI.cond_abbr(cond),
					_roman(int(r.get("to_tier", 1))), who]
				tip = "%s: %s on the %s eases T%d → T%d (resting) at the Clock reset" % [
					who, String(r.get("condition_name", cond)).to_upper(), part,
					int(r.get("tier", 0)), int(r.get("to_tier", 0))]
			"timer_expires":
				label = "⏳ %s ENDS → %s" % [String(r.get("timer", "")).to_upper(), who]
				tip = "%s: the %s timer EXPIRES at the next Clock reset" % [
					who, String(r.get("timer", "")).replace("_", " ").to_upper()]
			"timer_tick":
				label = "⏳ %s %d → %s" % [String(r.get("timer", "")).to_upper(),
					int(r.get("clocks_remaining", 0)), who]
				tip = "%s: the %s timer counts down (%d Clock%s left)" % [
					who, String(r.get("timer", "")).replace("_", " ").to_upper(),
					int(r.get("clocks_remaining", 0)),
					"" if int(r.get("clocks_remaining", 0)) == 1 else "s"]
			_:
				continue
		var carry := bool(r.get("carry", false))
		if carry:
			tip += " — %d Clocks out (%s)" % [int(r.get("clocks_away", 1)),
				"incubating" if r.has("activation_delay") else "delayed"]
		out.append({
			"slot": slot,
			"emoji": String(COND_EMOJI.get(cond, "⏳")),
			"label": label,
			"color": UI.cond_col(cond),
			"carry": carry,
			"name": tip,
		})
	return out


## Tier as a numeral the frame's own way ("BURN II"); past IV it degrades to
## the plain number rather than inventing deeper Roman.
func _roman(tier: int) -> String:
	return ["", "I", "II", "III", "IV"][tier] if tier >= 1 and tier <= 4 else str(tier)


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
			# Status-prominence pass: the compact badge row ("BLD 2" · "SHK 3" ·
			# "PRONE") replaces the old shock-only line — every active condition
			# tier + state flag reads at a glance, one colour language HUD-wide.
			"badges": _status_badges(c),
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
		"chain": _chain_banner(),
	})


## THE R29 HYPE-CHAIN BANNER (approved frame 4's crowd panel). The frame states
## the carry in words — "the next room opens at 40% of your ending meter —
## 68 -> 27 head start. Chain the den after and it keeps 60%." — and this is
## that sentence, built from view_hype_chain().
##
## NOTHING HERE IS HARDCODED. The percentages are the LIVE rungs of decision
## #32's retention ladder as the projection read them off
## RunState.CHAIN_RETENTION_PCT (40 / 60 / 80 / 100 today); the meter is the
## live one; the head start is the projection's floor(meter x pct), the same
## arithmetic RunState.chain_hype_start does when the next room actually
## stages. Re-rule the ladder and this banner follows for free.
##
## {} — the banner is hidden — only when there is no run at all (a bare
## start_combat demo drive has no chain to speak of and the HUD says nothing
## rather than inventing one). A TERMINAL room reports armed false and the
## banner says the meter is banked, not carried.
func _chain_banner() -> Dictionary:
	var chain: Dictionary = _gc.view_hype_chain() if _gc != null else {}
	if chain.is_empty():
		return {}
	var meter := int(chain.get("meter", 0))
	if not bool(chain.get("armed", false)):
		var why := "This room is TERMINAL — there is no next room to carry into." \
			if bool(chain.get("terminal", false)) \
			else "No next room is staged — nothing to carry the meter into."
		return {
			"armed": false,
			"title": "⛓ HYPE CHAIN — R29",
			"body": "%s The meter you end on (%d) is banked into the verdict, not carried." % [why, meter],
			"foot": "",
		}
	var pct := int(chain.get("pct", 0))
	var opens := int(chain.get("opens_at", 0))
	var body := ("Exploration is glue, not rest. The next room opens at [b]%d%%[/b] "
		+ "of your ending meter — [b]%d → %d[/b] head start.") % [pct, meter, opens]
	var then_pct := int(chain.get("then_pct", 0))
	if then_pct != pct:
		body += " Chain the room after that and it keeps [b]%d%%[/b]." % then_pct
	var rooms: Array = chain.get("next_rooms", [])
	if rooms.size() > 1:
		body += "\n[color=#8892b0]Both routes carry the same %d%% — the branch is the fight, not the meter.[/color]" % pct
	elif rooms.size() == 1:
		body += "\n[color=#8892b0]Next: %s[/color]" % \
			String((rooms[0] as Dictionary).get("to", "")).replace("_", " ").to_upper()
	return {
		"armed": true,
		"title": "⛓ HYPE CHAIN — R29",
		"body": body,
		"foot": "CHAINING IS REWARDED",
	}


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
	# Boss phase / network and DOWN keep the terse top line; conditions, shock
	# and the state flags moved into the set-off ACTIVE STATUS badge section.
	var status_bits: Array = []
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
		# ACTIVE STATUS section (status-prominence pass): condition tiers + state
		# flags as one badge row, aggregated over VISIBLE parts only — the
		# known-anatomy masking above also masks a hidden part's conditions.
		"status_badges": _status_badges(c),
		# ATTENTION section (R23 grudge ledger): who this AI combatant has
		# learned to hate, off the view's additive antagonism map — see
		# _attention_rows. [] (contestants / empty ledger) omits the section.
		"attention_rows": _attention_rows(c),
		"armed_line": armed_line,
		"parts": parts,
		"foot_line": "" if ally else "RESISTANCES · not in the view API yet — placeholder line",
	})


func _bind_arena() -> void:
	var boss := _find_combatant(_boss_id_cache)
	var objective: Dictionary = (_gc.view_encounter() as Dictionary).get("objective", {})
	var exploring := _exploring()
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
		# Status pips (status-prominence pass): id -> ordered colour list, one pip
		# per active condition / shock / state flag — same order and colours as the
		# badge rows, so the board itself shows who is hurt or locked.
		"status_pips": _status_pips(),
		# R34 board surfaces (decision #36): the per-enemy intent icons, the
		# per-enemy eyeline + 👁 chip, and the declared attack arcs.
		"intents": _intent_rows(),
		"vision": _vision_rows(),
		"attack_cones": _attack_cone_rows(),
		"mode_line": ("✦ FREE MOVEMENT · TIME %s" %
			("HELD" if _time_held() else "RUNNING")) if exploring else "",
		"hazard_line": "" if exploring else "🔥 FIRE HEALS IT — stop feeding the flame",
	})


# --------------------------------------------------- R34 intent icons (delta 1)
## Emoji + label bucket per intent KIND. Emoji are PLACEHOLDER ART (approved
## for the mockups; ARCHITECTURE.md §7 bans them from the final release only).
const INTENT_GLYPH := {
	"attack": "⚔", "aoe": "🔥", "buff": "💚", "debuff": "🕸",
	"other": "👣", "unknown": "❓",
}


## The intent icon for every enemy on the board — R34 decision 2, the ruling
## that moved the telegraph off the timeline and onto the enemy.
##
## THE READ RULE, and why it is this one. Intent is KNOWN INFORMATION, never
## omniscience: "an enemy the party has not read shows UNREAD (❓) rather than
## a fabricated guess". The only thing the view API can honestly say an enemy
## WILL do is what it has already DECLARED — view_schedule's pending rows,
## which are exactly the windup/telegraph R26 requires be shown loudly. So:
##   * a pending declared row  -> READ: its real kind, target, damage, timing,
##                                and the R26 undodgable flag if it carries one
##   * no pending row          -> UNREAD ❓, with the hover saying why
## Nothing here guesses from a stance, a personality or an ability list — the
## AI's own `ai_stance` is deliberately NOT used, because R23/Batch-C rules it
## FEELING, never intent (the lane rule), and reading it as intent would be
## precisely the fabricated guess the ruling forbids.
func _intent_rows() -> Dictionary:
	var out := {}
	if _gc == null:
		return out
	# Next pending declaration per actor (earliest resolve wins — it is the
	# thing about to happen; ties keep schedule order, which is seq order).
	var next_by_actor := {}
	for raw: Variant in _gc.view_schedule():
		var row: Dictionary = raw
		var actor := String(row.get("actor", ""))
		var prev: Dictionary = next_by_actor.get(actor, {})
		if prev.is_empty() or int(row.get("resolve_tick", 0)) < int(prev.get("resolve_tick", 0)):
			next_by_actor[actor] = row
	for raw: Variant in _last_combatants:
		var c: Dictionary = raw
		var id := String(c.get("id", ""))
		if _is_party(id) or not bool(c.get("alive", true)):
			continue
		out[id] = _intent_for(c, next_by_actor.get(id, {}))
	return out


func _intent_for(c: Dictionary, row: Dictionary) -> Dictionary:
	var who := String(c.get("name", "")).to_upper()
	if row.is_empty():
		return {
			"kind": "unknown", "glyph": INTENT_GLYPH["unknown"], "label": "UNREAD",
			"undodgable": false,
			"tip": ("%s — UNREAD\n\nIt has declared nothing you can see yet.\n" % who)
				+ "Intent is known information, never a guess: this icon stays ❓ "
				+ "until it commits to something, and then it says exactly what "
				+ "that is. (R34)",
		}
	var key := String(row.get("key", ""))
	var label := key.replace("_", " ").to_upper()
	var kind := String(row.get("kind", "attack"))
	var area: Dictionary = row.get("area", {})
	var damage: Dictionary = row.get("damage", {})
	var undodgable := bool(row.get("undodgable", false))
	var bucket := "other"
	if bool(row.get("heal", false)):
		bucket = "buff"
	elif not area.is_empty():
		bucket = "aoe"
		label += " · " + String(area.get("kind", "AREA")).to_upper()
	elif kind == "attack":
		bucket = "attack"
	elif kind == "grapple":
		bucket = "debuff"
	elif kind == "skill":
		bucket = "buff"

	# --- the hover: the ruled "full explanation", built from facts only ---
	var resolve_tick := int(row.get("resolve_tick", 0))
	var timing := "RESOLVES CLOCK %d · MOMENT %02d" % [
		resolve_tick / 10 + 1, 10 - (resolve_tick % 10)]
	var windup := bool(row.get("windup", false))
	var lines: Array = ["%s — %s" % [who, label],
		"%s · %s · %s" % [bucket.to_upper(), timing,
			"WINDUP — INTERRUPT OPEN" if windup else "COMMITTED"]]
	var target_names: Array = []
	for traw: Variant in row.get("targets", []):
		var t: Dictionary = traw
		var tname := _display_name_for(String(t.get("id", ""))).to_upper()
		var part := String(t.get("part", ""))
		target_names.append("%s (%s)" % [tname, _part_label(part)] if part != "" else tname)
	if not target_names.is_empty():
		lines.append("HITS: " + " · ".join(PackedStringArray(target_names)))
	if not damage.is_empty():
		lines.append("%d %s" % [int(damage.get("amount", 0)),
			String(damage.get("type", "")).to_upper()])
	if not area.is_empty():
		lines.append("AREA — everything in the committed arc; leaving it before "
			+ "it resolves still works (R2 re-check).")
	if undodgable:
		# R26's transparency half, relocated onto this icon by R34.
		lines.append("⛔ UNDODGABLE — no threshold dodge, no Tactical Roll, no "
			+ "authored dodge block. MOVEMENT IS NOT A DODGE: leaving the range "
			+ "or arc before it resolves is still the counterplay. (R26)")
	return {
		"kind": bucket, "glyph": String(INTENT_GLYPH.get(bucket, "❓")),
		"label": label, "undodgable": undodgable,
		"tip": "\n".join(PackedStringArray(lines)),
	}


# ------------------------------------------ R34 cone semantics (delta 3)
## Per-enemy eyeline + 👁 chip, straight off view_vision(). The COLOUR rule is
## the owner's amendment to decision 5: neutral while it has spotted nobody,
## red the moment it holds a contestant. The HUD never re-derives the stealth
## predicate — it renders the sim's answer.
func _vision_rows() -> Dictionary:
	var out := {}
	if _gc == null:
		return out
	for raw: Variant in _gc.view_vision():
		var row: Dictionary = raw
		var id := String(row.get("id", ""))
		var seen_ids: Array = row.get("sees", [])
		var reach := int(row.get("sight_range", 0))
		var hexes: Array = []
		for pair: Variant in row.get("watched", []):
			var p: Array = pair
			hexes.append(Vector2i(int(p[0]), int(p[1])))
		var label := "UNAWARE"
		if seen_ids.size() == 1:
			label = "HAS %s" % _display_name_for(String(seen_ids[0])).to_upper()
		elif seen_ids.size() > 1:
			label = "HAS THE PARTY"
		var note := ""
		if seen_ids.is_empty() and reach <= 0:
			# Honest content gap, stated rather than papered over: no enemy in
			# data/enemies.json authors a `mind` trait, so Stealth.sight_range
			# (2 x Mind) is 0 and the eyeline is genuinely empty. The HUD will
			# not invent a radius to make the board look busier.
			note = ("NO EYELINE — this enemy authors no Mind trait, so its sight "
				+ "range is 0 (R20/R30). That is the seed data, not a HUD guess.")
		elif seen_ids.is_empty():
			note = ("UNAWARE — nobody is inside its front arc within %d hexes with "
				+ "line of sight. Stay out and you stay hidden. (R20/R30)") % reach
		else:
			note = ("REVEALED — it holds %s inside its front arc (sight range %d). "
				+ "Break the arc, the line of sight, or the range.") % [
					", ".join(PackedStringArray(_names_of(seen_ids))), reach]
		out[id] = {"seen": not seen_ids.is_empty(), "label": label,
			"hexes": hexes, "note": note}
	return out


func _names_of(ids: Array) -> Array:
	var out: Array = []
	for id: Variant in ids:
		out.append(_display_name_for(String(id)).to_upper())
	return out


## Declared AREA arcs (attack cones): hazard-orange always, never recoloured by
## anyone's awareness — the ruling is explicit. The hexes come off the
## COMMITTED area_shape the resolver re-checks at resolution, so what the board
## paints is what will actually land.
func _attack_cone_rows() -> Array:
	var out: Array = []
	if _gc == null:
		return out
	for raw: Variant in _gc.view_schedule():
		var row: Dictionary = raw
		var area: Dictionary = row.get("area", {})
		if area.is_empty():
			continue
		var hexes: Array = []
		for pair: Variant in area.get("hexes", []):
			var p: Array = pair
			hexes.append(Vector2i(int(p[0]), int(p[1])))
		if hexes.is_empty():
			continue
		out.append({"hexes": hexes, "label": "%s %s TELEGRAPHED%s" % [
			String(row.get("key", "")).replace("_", " ").to_upper(),
			String(area.get("kind", "area")).to_upper(),
			" · ⛔ UNDODGABLE" if bool(row.get("undodgable", false)) else ""]})
	return out


# ------------------------------------------------- phase helpers (delta 4)
func _exploring() -> bool:
	return bool(_phase.get("exploring", false))


func _time_held() -> bool:
	return _explore_driver != null and _explore_driver.blocked()


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
	if not _throw.is_empty():
		hint = "🔊 VOICEBOX — pick a hex within %d for %s to throw the sound at (Esc cancels)" % [
			int(_throw.get("range", 10)), _display_name_for(_active_actor)]
	elif not _armed.is_empty():
		hint = "🎯 ARMED: %s · COST %d — pick a part in the inspector (Esc cancels)" % [
			String(_armed.get("label", "")), int(_armed.get("cost", 1))]
	elif _move_mode:
		hint = "↔ MOVE — pick a highlighted hex for %s (Esc cancels)" % _display_name_for(_active_actor)

	# R34 delta 5 — the FREE-ACTION BUDGET on the button's face. Read straight
	# off view_combatants (free_actions_left / free_actions_per_clock), which
	# the sim refreshes every TICK per the owner's cadence ruling ("per tick is
	# correct, keep it"), so this readout re-derives nothing and cannot drift.
	# Shown as REMAINING/CAP — the button says what you can still spend, and
	# greys out when the answer is nothing. (Which half of "1/2" the approved
	# frame meant is not stated there; PROVISIONAL, flagged.)
	var subs := {}
	var dim := {}
	var actor := _find_combatant(_active_actor)
	var cap := int(actor.get("free_actions_per_clock", 2))
	var left := int(actor.get("free_actions_left", cap))
	if not actor.is_empty():
		subs["free"] = "%d/%d" % [left, cap]
		dim["free"] = left <= 0

	var exploring := _exploring()
	var commit := "END TURN"
	var end_hint := ("%s ACTS NEXT" % next_name) if next_name != "" else ""
	var who_title := "ON THE CLOCK"
	var who := _display_name_for(_active_actor)
	if exploring:
		# Mode A (frame 4): no turn to end — the deliberate ENTER is the commit,
		# and the free-form verbs state their own costs on their faces.
		who_title = "FREE MOVEMENT"
		who = "PARTY WALKS TOGETHER"
		commit = "ENTER ▸ %s" % _route_name()
		end_hint = "LOCKS THE ROUTE · TURN ORDER STARTS"
		subs = {
			"move": "FREE", "interact": "FREE OUT HERE",
			"skills": "OUT-OF-COMBAT ONLY", "inventory": "⏸ PAUSES TIME",
		}
		var hold := "" if _explore_driver == null else String(_explore_driver.hold_reason())
		hint = ("No turn to end — but the world does not wait: mobs patrol, "
			+ "conditions tick, the crowd is bored by safety.")
		if not _throw.is_empty():
			# An armed pick outranks the standing Mode A line: it is the thing
			# the player is being asked to do right now.
			hint = "🔊 VOICEBOX — pick a hex within %d for %s to throw the sound at (Esc cancels)" % [
				int(_throw.get("range", 10)), _display_name_for(_active_actor)]
		elif hold != "":
			hint = "⏸ %s — no time steps are being issued. The sim holds no pause state; the driver simply stops." % hold

	_shell.launcher.update({
		"who": who,
		"who_title": who_title,
		"open_cat": _open_cat,
		"move_armed": _move_mode,
		"hint": hint,
		"end_hint": end_hint,
		"explore": exploring,
		"paused": _time_held(),
		"commit": commit,
		"subs": subs,
		"dim": dim,
	})


## The route the ENTER commit leads into: the run's ACTIVE encounter key. With
## no run staged there is no route name to show, and the button says so plainly
## rather than inventing one.
func _route_name() -> String:
	var run: Dictionary = _gc.view_run() if _gc != null else {}
	var here := int((run.get("encounter", {}) as Dictionary).get("active_index", -1))
	for raw: Variant in run.get("encounters", []):
		var row: Dictionary = raw
		if int(row.get("index", -2)) == here:
			return String(row.get("key", "")).replace("_", " ").to_upper()
	return "THE FIGHT"


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
					"sub": "IMANI + DARIO linked force · each pays COST 2 · arms part-targeting",
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
			var actor := _find_combatant(_active_actor)
			var left := int(actor.get("free_actions_left", 2))
			var cap := int(actor.get("free_actions_per_clock", 2))
			return {"title": "FREE ACTIONS — %s · %d/%d LEFT THIS MOMENT" % [who, left, cap],
				"entries": [
				{"id": "camera_call", "label": "📸 CAMERA CALL",
					"sub": "CHARM-GATED · spotlights self · DOUBLES gains & losses",
					"enabled": left > 0, "accent": UI.col(UI.GOLD)},
				bit,
			]}
		"interact":
			return {"title": "INTERACT — FREE OUT OF COMBAT", "entries": _interact_entries()}
		"inventory":
			return {"title": "INVENTORY — ⏸ TIME IS HELD WHILE THIS IS OPEN",
				"entries": _inventory_entries()}
	return {"title": "", "entries": []}


## MODE A interact list (approved frame 4). Real objects only: the arena's
## authored doors with their LIVE state and lock, off view_arena(). R34 rules
## exploration-time actions free and R35 waived the voicebox / lockpick costs
## out here, so the entries say FREE and mean it.
##
## WHICH ROWS COMMIT, and why the split is not arbitrary. An EXIT row still
## inspects: walking through a door is the deliberate ENTER, which is the
## commit button with its own consequence line — a flyout row must never
## silently start a fight. Everything else on this list is a real act with a
## real command behind it, and phase 2 wires all three:
##   PICK THE <DOOR>   -> the lockpicking declare (free-form out here)
##   <ACTOR> - VOICEBOX -> arms the throw's hex pick, then the real declare
##   SCOUT AHEAD       -> free-form `move` commands toward the nearest exit
## Each row is enabled only when it is honestly available: the pick and the
## throw need the ACTUAL grant on the acting contestant (the shipped roster
## carries neither skill — the frame's rows presuppose grants the seed data
## does not author, so the rows say so instead of pretending), and a lock the
## grant cannot reach is left to the sim to reject rather than pre-judged.
func _interact_entries() -> Array:
	var entries: Array = []
	var arena: Dictionary = _gc.view_arena() if _gc != null else {}
	var pick_level := _granted_level_of(_active_actor, "lockpicking")
	# The frame's own row reads "SASHA — VOICEBOX": the FIRST name, so the act
	# stays legible in a flyout row. The full authored display name lives on the
	# summary panel and the inspector, which have room for it.
	var who := _display_name_for(_active_actor).split(" ")[0].to_upper()
	var doors: Array = arena.get("doors", [])
	for raw: Variant in doors:
		var door: Dictionary = raw
		var key := String(door.get("key", ""))
		var label := key.replace("_", " ").to_upper()
		var state := String(door.get("state", "")).to_upper()
		var lock: Dictionary = door.get("lock", {})
		var sub := "DOOR · %s" % state
		if not lock.is_empty():
			# The substrate stores the tier as its ENUM STRING ("simple" ..
			# "magical"), not a number — read it as one.
			sub += " · %s LOCK (%s)" % [
				String(lock.get("tier", "")).to_upper(), String(lock.get("state", "")).to_upper()]
		entries.append({"id": "", "label": "🚪 %s" % label, "sub": sub + " — EXIT: entering is the ENTER commit, not a menu row",
			"enabled": false, "accent": UI.col(UI.CYAN)})
		# The pick row rides its door (frame 4's "PICK THE SUPPLY CAGE").
		if lock.is_empty() or String(lock.get("state", "")) != "locked":
			continue
		var tier := String(lock.get("tier", "simple"))
		if pick_level > 0:
			entries.append({"id": "pick:" + key,
				"label": "🔓 PICK THE %s" % label,
				"sub": "%s LOCK · LOCKPICKING LV %d · FREE out here, %d MOMENT%s once the fighting starts" % [
					tier.to_upper(), pick_level, _lock_moments(tier),
					"" if _lock_moments(tier) == 1 else "S"],
				"enabled": true, "accent": UI.col(UI.GOLD)})
		else:
			entries.append({"id": "", "label": "🔓 PICK THE %s" % label,
				"sub": "%s LOCK — %s HAS NO LOCKPICKING GRANT (no roster loadout authors one)" % [
					tier.to_upper(), who],
				"enabled": false, "accent": UI.col(UI.MUTED)})
	if doors.is_empty():
		entries.append({"id": "", "label": "NO DOORS IN THIS ROOM",
			"sub": "this encounter authors no arena doors — no exits, locks or props in the view API",
			"enabled": false, "accent": UI.col(UI.MUTED)})

	# ---- VOICEBOX: the decoy throw (R35's first waived act) ----------------
	var throw_level := _granted_level_of(_active_actor, "voicebox")
	if throw_level > 0:
		var reach := int(SkillBook.mechanics("voicebox", throw_level).get("throw_range", 10))
		entries.append({"id": "voicebox", "label": "🔊 %s — VOICEBOX" % who,
			"sub": "throw a mimicked shout up to %d hexes · mobs investigate THE SOUND, not you · FREE" % reach,
			"enabled": true, "accent": UI.col(UI.MYTHIC)})
	else:
		entries.append({"id": "", "label": "🔊 %s — VOICEBOX" % who,
			"sub": "%s has no voicebox grant — no roster loadout authors one (the throw is real; the grant is not)" % who,
			"enabled": false, "accent": UI.col(UI.MUTED)})

	# ---- SCOUT AHEAD: walk up without entering ----------------------------
	var gate := _nearest_exit_door()
	if not gate.is_empty():
		entries.append({"id": "scout", "label": "👣 SCOUT AHEAD",
			"sub": "walk the party up to the %s without entering — the way does not close behind you · FREE" % 				String(gate.get("key", "")).replace("_", " ").to_upper(),
			"enabled": true, "accent": UI.col(UI.SUCCESS)})
	else:
		entries.append({"id": "", "label": "👣 SCOUT AHEAD",
			"sub": "nothing to scout toward — this room authors no exits",
			"enabled": false, "accent": UI.col(UI.MUTED)})

	entries.append({"id": "", "label": "↔ WALK",
		"sub": "FREE · no Moment cost, no turn order — the clock still runs (R34)",
		"enabled": false, "accent": UI.col(UI.SUCCESS)})
	return entries


## The substrate's own Moments-to-pick for a lock tier (Arena.LOCK_PICK_MOMENTS
## — read, never retyped), so the row can state the COMBAT price the waiver
## is suspending. 1 for an unknown tier (the substrate's floor).
func _lock_moments(tier: String) -> int:
	return int(Arena.LOCK_PICK_MOMENTS.get(tier, 1))


## MODE A inventory list. The rows are the ACTOR'S REAL carried items off
## view_combatants — an empty pack says so instead of showing invented loot.
## What matters mechanically is that this surface being OPEN holds time
## (R35's Pokemon clause, enforced in _on_category / _close_flyout).
##
## PHASE 2 — the rows COMMIT. R35's third waived act is the `inventory` command
## itself: out of combat it is free every time and leaves R3's first-free
## ledger untouched, so an out-of-combat heal never charges the next fight.
## A row therefore issues the real interaction and the effect really runs —
## `use` for an item in hand, `pickup` for one on the floor (the `dropped`
## projection), which genuinely puts it back (`item_recovered`). In COMBAT the
## same rows still commit; the sim simply charges R3's ladder instead.
func _inventory_entries() -> Array:
	var entries: Array = []
	var exploring := _exploring()
	for raw: Variant in _find_combatant(_active_actor).get("items", []):
		var item: Dictionary = raw
		var key := String(item.get("key", ""))
		var dropped := bool(item.get("dropped", false))
		var sub := "FREE out of combat · R3's inventory ledger is untouched out here" if exploring \
			else "IN COMBAT: R3's ladder applies — first interaction free, every later one a Moment"
		if item.has("magazine_loaded"):
			sub = "MAGAZINE %d · %s" % [int(item.get("magazine_loaded", 0)), sub]
		if dropped:
			entries.append({"id": "take:" + key,
				"label": "🫳 PICK UP %s" % String(item.get("name", key)).to_upper(),
				"sub": "ON THE FLOOR (dropped) · " + sub,
				"enabled": key != "", "accent": UI.col(UI.GOLD)})
		else:
			entries.append({"id": "use:" + key,
				"label": "🎒 USE %s" % String(item.get("name", key)).to_upper(),
				"sub": sub, "enabled": key != "", "accent": UI.col(UI.TEXT)})
	if entries.is_empty():
		entries.append({"id": "", "label": "NOTHING CARRIED",
			"sub": "this contestant carries no items — nothing to use, and nothing invented",
			"enabled": false, "accent": UI.col(UI.MUTED)})
	if exploring:
		entries.append({"id": "", "label": "⏸ TIME IS HELD",
			"sub": "the driver stops issuing time steps while this is open — a burn cannot tick while you rummage (R35)",
			"enabled": false, "accent": UI.col(UI.PURPLE)})
	return entries


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


## The GRANTED level for a skill, or 0 when the combatant does not own it.
## _skill_level_of deliberately floors at 1 (its callers already know the actor
## owns the skill — it answers "at what level"), so it cannot answer "does this
## contestant own it at all". Every exploration row that must be OFFERED ONLY
## TO AN OWNER asks this instead.
func _granted_level_of(id: String, skill_key: String) -> int:
	for rd in _skills_of(id):
		var r: Dictionary = rd
		if String(r.get("key", "")) == skill_key:
			return maxi(1, int(r.get("level", 1)))
	return 0


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
	# MODE A (R34): there is no turn order and nothing costs Moments, so a
	# readiness line would be a lie in both directions — "READY" implies a turn
	# that does not exist, "ACTS AT CLOCK 4" implies a queue that does not
	# either. The frame says what is actually true out here.
	if _exploring():
		return "✦ FREE" if compact else "✦ FREE TO WALK — NO MOMENT COST · TIME RUNS"
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


## Boss-condition overlay line (highest tier per condition) — v1 readout, now
## masking-aware: a HIDDEN part's conditions never leak here (same rule as the
## badge rows — the pre-breach network stays fully off-screen).
func _boss_cond_line(boss: Dictionary) -> String:
	if boss.is_empty():
		return ""
	var best := {}
	for pd in boss.get("parts", []):
		var p: Dictionary = pd
		if bool(p.get("hidden", false)):
			continue
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


## Chip emoji per condition (display art only; colours come from the theme's
## COND_COLORS so a condition reads as the same colour everywhere on the HUD).
const COND_EMOJI := {
	"bleeding": "🩸", "crushed": "💥", "burn": "🔥", "chilled": "❄",
	"poison": "🧪", "infected": "🦠", "suffocation": "🫁",
	"dissolution": "🌀", "exhausted": "💤",
}


func _cond_chip_data(cond_id: String, tier: int) -> Dictionary:
	return {"text": "%s %s T%d" % [String(COND_EMOJI.get(cond_id, "🩸")),
		cond_id.to_upper(), tier], "color": UI.cond_col(cond_id)}


## At-a-glance status badges for one combatant view row: every active condition
## at its HIGHEST tier across VISIBLE parts ("BLD 2"), the shock tier ("SHK 3"),
## then the state flags (PRONE / EXPOSED / HELPLESS / BREACHED). One list, one
## colour language (hud_theme COND_COLORS / SHOCK), consumed by the party cards,
## the inspector ACTIVE STATUS section and the arena token pips alike. Hidden
## parts (known-anatomy masking) never leak their conditions; the widened
## helpless/prone view keys are read defensively (absent -> false).
func _status_badges(c: Dictionary) -> Array:
	var best := {}
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if bool(p.get("hidden", false)):
			continue
		var conds: Dictionary = p.get("conditions", {})
		for cid in conds:
			best[String(cid)] = maxi(int(best.get(String(cid), 0)), int(conds[cid]))
	var keys: Array = best.keys()
	keys.sort()
	var out: Array = []
	for k in keys:
		out.append({"text": "%s %d" % [UI.cond_abbr(String(k)), int(best[k])],
			"color": UI.cond_col(String(k))})
	if int(c.get("shock", 0)) > 0:
		out.append({"text": "SHK %d" % int(c.get("shock", 0)), "color": UI.col(UI.SHOCK)})
	# Skill-feel pass: the armed feint debuff reads as a badge on the victim's
	# card / inspector / pips while it pends (view key ADDITIVE, absent -> false).
	if bool(c.get("feint_forced", false)):
		out.append({"text": "FEINTED", "color": UI.col(UI.MYTHIC)})
	if bool(c.get("prone", false)):
		out.append({"text": "PRONE", "color": UI.col(UI.GOLD)})
	if bool(c.get("exposed", false)):
		out.append({"text": "EXPOSED", "color": UI.col(UI.GOLD)})
	if bool(c.get("helpless", false)):
		out.append({"text": "HELPLESS", "color": UI.col(UI.DANGER)})
	if bool(c.get("breached", false)):
		out.append({"text": "BREACHED", "color": UI.col(UI.PURPLE)})
	return out


## R23 grudge ledger — the inspector's ATTENTION rows for one combatant view
## row (broadcast voice: who an AI creature has learned to hate is WATCHABLE
## behavior, not hidden info — it names opponents already on the board and
## reveals nothing about anatomy). One row per opponent on the additive
## `antagonism` view map ({} for contestants), grudge DESCENDING with id
## ascending on ties — deterministic; share normalized to the max score, the
## exact float kept as secondary text. [] for an empty/absent map — the
## section is omitted entirely, no noise.
func _attention_rows(c: Dictionary) -> Array:
	var antag: Variant = c.get("antagonism", {})
	if not (antag is Dictionary):
		return []
	var entries: Array = []
	var ids: Array = (antag as Dictionary).keys()
	ids.sort()
	for oid in ids:
		var score := float((antag as Dictionary)[oid])
		if score > 0.0:
			entries.append({"id": String(oid), "score": score})
	if entries.is_empty():
		return []
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) != float(b["score"]):
			return float(a["score"]) > float(b["score"])
		return String(a["id"]) < String(b["id"]))
	var top := float((entries[0] as Dictionary)["score"])
	var rows: Array = []
	for ed in entries:
		var e: Dictionary = ed
		rows.append({
			"name": _display_name_for(String(e["id"])),
			"share": float(e["score"]) / top,
			"score_text": "%.1f" % float(e["score"]),
		})
	return rows


## Arena pip map: id -> ordered Colors, one per badge (same order as the badge
## row, so a card's "BLD 2" and the token's first pip are the same red).
func _status_pips() -> Dictionary:
	var out := {}
	for cd in _last_combatants:
		var c: Dictionary = cd
		var colors: Array = []
		for bd in _status_badges(c):
			colors.append((bd as Dictionary).get("color", UI.col(UI.DANGER)))
		if not colors.is_empty():
			out[String(c.get("id", ""))] = colors
	return out


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


## Broadcast-voice announce for the PAYOFF events the skill-feel pass surfaces
## loudly (feint fallout / feint read / knockdown / standing back up), plus the
## decision-#27 pressure-valve beat (telegraph / blast / per-victim knockout /
## breach reset — `explosion_building` is an ai_decision wait REASON, not an
## event, so the hold window stays quiet by design). "" for every other event
## type — the generic _event_line handles those. Every announce here rides the
## _pending_announce priority: it outranks the generic END TURN / flavor lines.
func _broadcast_announce(e: Dictionary) -> String:
	match String(e.get("type", "")):
		"feint_read":
			# R24: the Mind counter lands — the read is a beat, not a badge
			# (nothing armed on the reader; the feinter's Moment is just gone).
			return "%s READS the feint — %s's trick wastes the Moment!" % [
				_display_name_for(String(e.get("reader", ""))).to_upper(),
				_display_name_for(String(e.get("feinter", ""))).to_upper()]
		"feint_fallout":
			var what := String(e.get("key", ""))
			if what == "":
				what = String(e.get("kind", "action"))
			return "%s's feint pays off — %s's %s CRUMBLES into a Forced Action!" % [
				_display_name_for(String(e.get("actor", ""))),
				_display_name_for(String(e.get("victim", ""))),
				what.replace("_", " ").to_upper()]
		"knocked_prone":
			return "%s's %s FLATTENS %s — grounded: no dodge, no sweep!" % [
				_display_name_for(String(e.get("source", ""))),
				String(e.get("skill", "")).replace("_", " ").to_upper(),
				_display_name_for(String(e.get("combatant", "")))]
		"stood_up":
			return "%s spends the whole Moment hauling itself back upright" % \
				_display_name_for(String(e.get("combatant", "")))
		"explosion_telegraph":
			# The decision-#27 counterplay cue — echoes the slice harness's line
			# verbatim (radius + Moments straight off the event, never invented).
			# R26 transparency: an undodgable blast SAYS SO on the windup — the
			# marker rides the flag on the event, loudly, so nobody banks on a
			# roll that cannot save them (running out of the radius still can).
			var telegraph := "STEAM SCREAMS from the vents — blast in %d Moments, radius %d. RUN." % [
				int(e.get("moments_until_blast", 0)), int(e.get("radius", 0))]
			if bool(e.get("undodgable", false)):
				telegraph += " UNDODGABLE — no dodge escapes this; distance is the only cover."
			return telegraph
		"explosion_blast":
			var blast_line := "THE VALVE BLOWS — a radius-%d eruption tears through the arena!" % \
				int(e.get("radius", 0))
			if bool(e.get("undodgable", false)):
				blast_line += " (UNDODGABLE)"
			return blast_line
		"explosion_knockout":
			# Per-victim: Helpless for 2 Clocks (owner ruling #27 — no damage).
			return "%s is OUT COLD — helpless for 2 Clocks" % \
				_display_name_for(String(e.get("combatant", "")))
		"breach_reset":
			return "The network RETREATS deeper — the breach seals; the wounds remain"
		# ---- KAN-6 phase 2: the exploration acts, read back off their events.
		"sound_thrown":
			# R20's reserved no-visible-source LOUD lane. Loudness off the event.
			return "🔊 %s THROWS A SOUND onto %s — loudness %d, and it came from nowhere" % [
				_display_name_for(String(e.get("actor", ""))).to_upper(),
				str(e.get("position", [])), int(e.get("loudness", 0))]
		"noise_heard":
			# The pull R34 names: a sound can bring a room onto you before you
			# enter it. The hearer knows the HEX, never the thrower.
			return "👂 %s HEARS IT at %s — alerted, not located: it walks toward the sound" % [
				_display_name_for(String(e.get("combatant", ""))).to_upper(),
				str(e.get("position", []))]
		"lock_picked":
			# `moments: 0` IS the R35 waiver — stated, never hidden.
			var moments := int(e.get("moments", 0))
			if moments == 0:
				return "🔓 THE %s LOCK GIVES — 0 MOMENTS: out of combat the pick is free (R35)" % \
					String(e.get("door", "")).replace("_", " ").to_upper()
			return "🔓 THE %s LOCK GIVES — %d Moment%s charged (R3 price, the clock is running)" % [
				String(e.get("door", "")).replace("_", " ").to_upper(), moments,
				"" if moments == 1 else "s"]
		"item_recovered":
			return "🫳 %s HAS THE %s BACK IN HAND" % [
				_display_name_for(String(e.get("actor", ""))).to_upper(),
				String(e.get("item", "")).replace("_", " ").to_upper()]
		"inventory_used":
			if not bool(e.get("exploration", false)):
				return ""
			return "🎒 %s rummages — free out here, and R3's first-free ledger stays untouched" % \
				_display_name_for(String(e.get("actor", "")))
	return ""


## One short line per sim event for the ticker/overlay: the interesting fields,
## in a stable order, joined tersely. Structure pass — copy comes with the
## visuals/writing epic. The skill-feel payoff events reuse their loud
## broadcast-voice announce so the log reads the same beat the ticker shouted.
func _event_line(e: Dictionary) -> String:
	var announce := _broadcast_announce(e)
	if announce != "":
		return announce
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
