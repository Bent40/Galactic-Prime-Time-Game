extends Control
## CombatHud — the demo-slice combat HUD (KAN-6 mockup gate).
##
## PRESENTATION ONLY. This scene never imports or touches `simulation/` classes.
## It reads sim state exclusively through the GameController VIEW API
## (view_clock / view_broadcast / view_combatants), subscribes to GameController
## signals so it re-renders as the command stream resolves, and drives input the
## other way: the action bar / skill chips / Camera Call / The Bit / END TURN issue
## real commands through GameController.apply_command (see the "input -> command"
## section). It still authors NO sim state — every command is one the sim already
## understands, and the HUD only re-binds off the resulting sim_event.
##
## Visual identity: docs/ux-designs/demo-slice-2026-07-19/DESIGN.md (the sister
## char-sheet palette, extended). Layout blueprint: .working/key-combat-hud.html.
## Every NUMBER on screen is PLACEHOLDER (R14) — the watermark says so.
##
## Data-bound (live from the view API):
##   * CLOCK n / MOMENT nn / NEXT RESET      (view_clock)
##   * HYPE meter + bar + band + CROWD:band  (view_broadcast.hype)
##   * ACTIVE CROWD GOAL name/payout/clocks  (view_broadcast.goal)
##   * SPOTLIGHT / CAMERA CALL card          (view_broadcast.spotlight)
##   * per-contestant 6-part HP grid, conditions, shock (view_combatants.parts)
##   * SLICE OBJECTIVE network status + boss NETWORK/PHASE tags (breached/hidden)
##   * ARENA hex board + unit tokens at their LIVE axial positions (view_combatants
##     .position), boss network masked until breached; MOVE click-to-target
##   * TICK-ORDER rail + ON-THE-CLOCK highlight + turn rotation (view_turn_order)
## PLACEHOLDER-stubbed (laid out faithfully, marked, static content) — see the
## inline `# PLACEHOLDER:` notes: GODS-AT-THE-TABLE multipliers + WAGER FEED,
## contestant persona/patron/skill chips, the flamethrower-cone hazard tint
## (decorative — no sim hazard model), viewer count, REC timer.

const ArenaFloor := preload("res://ui/hud/arena_floor.gd")
# field_renderer.gd carries the reusable, unit-tested hex math (axial_to_pixel /
# hex_points / pixel_to_axial). It is LOADED AT RUNTIME rather than preloaded: its
# _ready() references the `Game` autoload, and preloading it into this scene forces
# that reference to resolve during compile (before the autoload is live in the
# render/test harnesses). Runtime load sidesteps the cycle — see _fr().
var _field_renderer: GDScript


## The reusable hex-math script (lazy-loaded; see the note above).
func _fr() -> GDScript:
	if _field_renderer == null:
		_field_renderer = load("res://scenes/field/field_renderer.gd") as GDScript
	return _field_renderer

# ---- palette (DESIGN.md — extends the char-sheet app tokens exactly) ----
const BG := "#04050d"
const PANEL := "#090c1a"
const PANEL2 := "#0d1020"
const CYAN := "#00d4ff"
const GOLD := "#c8a84b"
const DANGER := "#ff2255"
const SUCCESS := "#00ff88"
const TEXT := "#b8c8e0"
const MUTED := "#3a4560"
const BORDER := "#1a2540"
const PURPLE := "#a855f7"
const MYTHIC := "#ec4899"
const FIRE := "#ff7a2f"

var _gc = null  # GameController (untyped: it is the `Game` autoload script, no class_name)

# ---- input wiring (this pass) ----------------------------------------------
## The "ON THE CLOCK" contestant — the action bar / The Bit / Camera Call / MOVE
## act as this id. DERIVED every refresh() from view_turn_order() as the first
## `ready && is_contestant` entry (fallback: keep the current one), so END TURN
## (advance_tick) rotates it automatically. set_active_actor() can force it as an
## override, but the next refresh re-derives from live turn order.
var _active_actor := "dario"

# ---- arena / turn-order live state (this pass) ------------------------------
var _stage: Control              # the center-stage container (arena panel body)
var _arena_floor                 # ArenaFloor — draws the live hex board
var _token_layer: Control        # holds the unit-token nodes (origin = disc centre)
var _click_catcher: Control      # top overlay; catches clicks only in MOVE mode
var _tick_strip: HBoxContainer   # the tick-order rail chips (rebuilt each refresh)
var _move_mode := false          # MOVE click-to-target armed?
var _arena_eff := 40.0           # current on-screen hex size (board transform)
var _arena_off := Vector2.ZERO   # current board offset (board transform)
var _arena_qr := Vector2i(-2, 3) # current drawn q range (qlo, qhi)
var _arena_rr := Vector2i(-2, 3) # current drawn r range (rlo, rhi)
var _last_combatants: Array = [] # cached view_combatants() for re-layout on resize
var _emoji_map := {}             # id -> token emoji (boss/contestant), rebuilt each refresh
var _boss_id_cache := ""         # id of the combatant carrying the hidden network

## Per-skill MECHANICS now live in the MODEL (simulation/skill_book.gd), consumed
## by ActionResolver's kind=="skill" path. The HUD is presentation only: a skill
## button declares a kind=="skill" action carrying just the key + level (and, for
## targeted skills, the boss target on the flamethrower arm — the designed path
## in). The sim supplies the damage/riders — the HUD sends NO damage numbers. The
## model decides self-vs-targeted (SkillBook.is_self_skill), so brace/dance
## declare with no target.
const BOSS_DEFAULT_PART := "left_hand"  # the flamethrower arm — the designed path in
const SKILL_ATTACK_RANGE := 2           # demo reach so the slice's spacing lands

# bound refs for the input feedback surfaces (set during _build)
var _spot_title: Label
var _spot_sub: Label
var _boss_cond: Label
var _chyron_line: RichTextLabel
var _actionbar_who: Label

# fonts
var f_body: Font
var f_mono: Font
var f_emoji: Font
var f_sym: Font

# bound node refs
var _clock_num: Label
var _moment_num: Label
var _nextreset: Label
var _hype_val: Label
var _hype_bar: ProgressBar
var _hype_band: Label
var _hype_delta: Label
var _goal_title: Label
var _goal_desc: Label
var _goal_pay: Label
var _goal_time: Label
var _obj_status: Label
# id -> {parts:{key:{val:Label, bar:ProgressBar}}, condbox:HBoxContainer, shock:Label}
var _cref := {}

# contestant presentation cfg. persona/patron/skills are fixture cfg (no view-API
# field yet) — see the report's "needs a view-API addition" list.
const PART_ORDER := ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg"]
const PART_LABEL := {
	"head": "HEAD", "torso": "TORSO", "left_arm": "L-ARM", "right_arm": "R-ARM",
	"left_leg": "L-LEG", "right_leg": "R-LEG",
}


var _built := false


func _ready() -> void:
	_ensure_built()


## Build once, on whichever call comes first. In a SceneTree preview driver,
## add_child() defers _ready() to the next idle frame, so bind() can arrive before
## _ready() — building lazily makes the HUD safe to bind immediately after
## instantiation (and a no-op on the later _ready()).
func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_init_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1600, 1000)
	_build()


# ------------------------------------------------------------------ public API
## Bind the HUD to a live GameController and do a first render. Also subscribes to
## the generic sim_event plus two typed signals (wiring proof) so the HUD tracks
## the command stream live.
func bind(game) -> void:
	_ensure_built()
	_gc = game
	if _gc != null and not _gc.sim_event.is_connected(_on_event):
		_gc.sim_event.connect(_on_event)
		_gc.clock_moment_changed.connect(_on_event)  # typed-signal wiring proof
		_gc.hype_band_changed.connect(_on_event)
	refresh()


func _on_event(_e: Dictionary = {}) -> void:
	refresh()


# ------------------------------------------------------------------ input -> command
## Every button funnels through GameController.apply_command (the one command
## gateway); the HUD re-binds off the resulting sim_event, so a resolved command
## updates the HUD automatically. These handler methods are what the buttons'
## click overlays call — and what the scripted preview driver calls directly.

## Forces the on-the-clock contestant (override). refresh() otherwise DERIVES it
## from view_turn_order(); a forced id holds only until the next refresh re-derives
## from live turn order. Kept for drivers that want to pin a specific contestant.
func set_active_actor(id: String) -> void:
	_active_actor = id
	if _actionbar_who != null:
		_actionbar_who.text = _display_name_for(id)


## Action-bar skill button (acts as the on-the-clock contestant).
func _on_skill(skill_key: String) -> void:
	_declare_skill_attack(_active_actor, skill_key)


## Per-contestant skill chip (acts as that contestant).
func _on_skill_for(actor_id: String, skill_key: String) -> void:
	_declare_skill_attack(actor_id, skill_key)


## Declares a kind=="skill" action; the sim (SkillBook + ActionResolver) owns the
## mechanics/damage. Self skills (brace, dance) declare with no target; every
## other skill targets the boss's flamethrower arm (the designed path in).
func _declare_skill_attack(actor_id: String, skill_key: String) -> void:
	# TODO: read the actor's per-skill level from the loadout when the view API
	# exposes it; the demo slice runs everything at level 1.
	var level := 1
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
			"targets": [{"id": boss, "part": BOSS_DEFAULT_PART}],
		},
	}, "%s winds up %s on the flamethrower arm" % [_display_name_for(actor_id), label])


func _on_camera_call() -> void:
	_issue({"type": "camera_call", "actor": _active_actor, "target": _active_actor},
		"%s calls the camera onto themselves — swings now doubled" % _display_name_for(_active_actor))


func _on_bit() -> void:
	_issue({"type": "bit", "actor": _active_actor, "key": "encore_bow"},
		"%s drops the Bit — pure spectacle for the crowd" % _display_name_for(_active_actor))


## MOVE arms click-to-target: the arena highlights the reachable hexes and the
## next click on a hex issues a real move(active_actor, [q,r]). Toggling MOVE off
## disarms it. The arena floor draws the highlight ring; the click catcher (a top
## overlay) is filter-STOP only while armed so it never eats clicks otherwise.
func _on_move() -> void:
	_move_mode = not _move_mode
	if _click_catcher != null:
		_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if _move_mode else Control.MOUSE_FILTER_IGNORE
	if _move_mode:
		_momus("MOVE — pick a highlighted hex for %s" % _display_name_for(_active_actor))
	_layout_arena()  # repaint the reachable-hex highlight


## gui_input on the click catcher: a left click while armed picks the hex under
## the cursor. event.position is local to the catcher, which shares the stage's
## coordinate space (both anchored full-rect), so it maps straight back through
## the board transform. Also callable directly by the render harness.
func _on_arena_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_arena_click_local(event.position)


## Turns a stage-local pixel into an axial hex (inverse of the board transform)
## and issues the move. Rejections (already_moved / grappled / winding_up / …)
## surface in the Momus chyron via _issue — never a crash.
func _arena_click_local(local_pos: Vector2) -> void:
	if not _move_mode:
		return
	var hex: Vector2i = _fr().pixel_to_axial(local_pos - _arena_off, _arena_eff)
	_move_mode = false
	if _click_catcher != null:
		_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_issue({"type": "move", "actor": _active_actor, "to": [hex.x, hex.y]},
		"%s slides to hex %d,%d" % [_display_name_for(_active_actor), hex.x, hex.y])


## END TURN drives the engine clock: advance_tick resolves every declared windup
## and advances the Moment (the HUD re-binds off the resulting events). The next
## refresh re-derives the on-the-clock contestant from view_turn_order(), so the
## action bar + tick-order highlight rotate automatically.
func _on_end_turn() -> void:
	_issue({"type": "advance_tick"}, "END TURN — the Moment resolves")


## The one command funnel for the HUD: apply, surface any rejection in the Momus
## chyron (never crash), otherwise show the flavor line. refresh() already ran via
## sim_event during apply_command; the trailing refresh() is a belt-and-suspenders
## repaint (the chyron text is set AFTER so it survives it).
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


## The boss = the combatant carrying a hidden or `network` part (stable pre- AND
## post-breach: `hidden` clears on breach but the key still contains "network").
func _boss_id() -> String:
	if _gc == null:
		return ""
	for cd in _gc.view_combatants():
		var c: Dictionary = cd
		for pd in c.get("parts", []):
			var p: Dictionary = pd
			if bool(p.get("hidden", false)) or String(p.get("key", "")).contains("network"):
				return String(c.get("id", ""))
	return ""


## Recomputes the boss id + the id->emoji map from the live roster, so the arena
## tokens and the tick-order rail agree on who's who. The boss is masked (🐊) and
## keeps its network hidden until breached; contestants map by name; anything else
## falls back to a generic marker.
func _recompute_identity() -> void:
	_emoji_map.clear()
	_boss_id_cache = _boss_id()
	if _gc == null:
		return
	for cd in _gc.view_combatants():
		var c: Dictionary = cd
		var id := String(c.get("id", ""))
		if id == _boss_id_cache:
			_emoji_map[id] = "🐊"
		else:
			_emoji_map[id] = _contestant_emoji(id, String(c.get("name", "")))


func _contestant_emoji(id: String, cname: String) -> String:
	var key := (id + " " + cname).to_lower()
	if key.contains("imani"):
		return "🛡️"
	if key.contains("dario"):
		return "🎭"
	if key.contains("roach"):
		return "🪳"
	return "🎪"  # generic contestant marker (no bespoke emoji)


func _emoji_for_id(id: String) -> String:
	return String(_emoji_map.get(id, "🎪"))


func _momus(text: String) -> void:
	if _chyron_line != null:
		_chyron_line.text = "[color=#e8d0dc]\"%s\"[/color]" % text


## Display name from the view API (falls back to a tidy upper-cased id).
func _display_name_for(id: String) -> String:
	if _gc != null:
		for cd in _gc.view_combatants():
			var c: Dictionary = cd
			if String(c.get("id", "")) == id:
				return String(c.get("name", id)).to_upper()
	return id.to_upper()


# ------------------------------------------------------------------- fonts/util
func _init_fonts() -> void:
	f_body = ThemeDB.fallback_font
	f_mono = _sysfont(["Liberation Mono", "DejaVu Sans Mono", "monospace"])
	f_emoji = _sysfont(["Noto Color Emoji"])
	f_sym = _sysfont(["DejaVu Sans", "Noto Sans Symbols2", "FreeSans", "OpenSymbol"])


func _sysfont(names: Array) -> SystemFont:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(names)
	sf.allow_system_fallback = true
	return sf


func _col(hexs: String, a := 1.0) -> Color:
	var c := Color(hexs)
	c.a = a
	return c


func _tracked(base: Font, glyph: float) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = int(glyph)
	return fv


## Generic label. tracking>0 wraps `font` in a spaced FontVariation; bold fakes
## weight with a 1px same-colour outline (the fallback font ships no bold face).
func _lab(text: String, font: Font, fsize: int, color: Color, tracking := 0.0, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _tracked(font, tracking) if tracking > 0.0 else font)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_constant_override("outline_size", 2)
		l.add_theme_color_override("font_outline_color", color)
	return l


## Emoji glyph label (color emoji via Noto Color Emoji — font_color is ignored,
## the font carries its own colour).
func _emo(glyph: String, px: int) -> Label:
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_override("font", f_emoji)
	l.add_theme_font_size_override("font_size", px)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Title/value label with a soft neon halo (glow is rare + load-bearing: accents
## only, per DESIGN.md).
func _glow(text: String, font: Font, fsize: int, color: Color, tracking: float, halo: float) -> Label:
	var l := _lab(text, font, fsize, color, tracking, true)
	l.add_theme_constant_override("outline_size", int(halo))
	l.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.28))
	return l


func _sb(bg: Color, border: Color, radius := 5, bw := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(bw)
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	return sb


func _glow_sb(bg: Color, border: Color, radius: int, glow: Color, glow_size: int) -> StyleBoxFlat:
	var sb := _sb(bg, border, radius, 1)
	sb.shadow_color = glow
	sb.shadow_size = glow_size
	return sb


func _vfill(node: Control) -> Control:
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


func _hbox(sep := 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	if sep != 0:
		h.add_theme_constant_override("separation", sep)
	return h


func _vbox(sep := 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	if sep != 0:
		v.add_theme_constant_override("separation", sep)
	return v


func _border_line(parent: Node) -> void:
	var r := ColorRect.new()
	r.color = _col(BORDER)
	r.custom_minimum_size = Vector2(0, 1)
	parent.add_child(r)


# ---------------------------------------------------------------- build the tree
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = _col(BG)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# subtle top glow (the .screen radial in the blueprint)
	var glow := TextureRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.texture = _radial_tex(Color("#0a1024"), 0.55)
	glow.modulate = Color(1, 1, 1, 0.7)
	add_child(glow)

	var root_m := MarginContainer.new()
	root_m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_m.add_theme_constant_override("margin_left", 12)
	root_m.add_theme_constant_override("margin_right", 12)
	root_m.add_theme_constant_override("margin_top", 10)
	root_m.add_theme_constant_override("margin_bottom", 10)
	add_child(root_m)

	var col := _vbox(9)
	root_m.add_child(col)

	col.add_child(_fixed_y(_build_broadcast(), 52))
	col.add_child(_fixed_y(_build_clockbar(), 58))
	col.add_child(_vfill(_build_main()))
	col.add_child(_fixed_y(_build_contestants(), 176))
	col.add_child(_fixed_y(_build_actionbar(), 66))
	col.add_child(_fixed_y(_build_chyron(), 46))

	# R14 watermark — faint, bottom-right, on every screen while numbers are placeholder.
	var wm := _lab("PLACEHOLDER NUMBERS · R14", f_body, 10, _col(TEXT, 0.16), 3.0, true)
	wm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	wm.position = Vector2(-250, -22)
	add_child(wm)


func _fixed_y(node: Control, h: int) -> Control:
	node.custom_minimum_size.y = h
	node.size_flags_vertical = Control.SIZE_FILL
	return node


func _radial_tex(inner: Color, dark_a: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(inner.r, inner.g, inner.b, 0.5))
	g.set_color(1, Color(inner.r, inner.g, inner.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(1.1, 0.6)
	gt.width = 400
	gt.height = 250
	return gt


# ---------------------------------------------------------------- broadcast bar
func _build_broadcast() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#0a1024"), _col(BORDER), 5))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 18)
	pad.add_theme_constant_override("margin_right", 18)
	p.add_child(pad)
	var row := _hbox(0)
	pad.add_child(row)

	# left: LIVE pill + REC
	var left := _hbox(14)
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	var live := PanelContainer.new()
	live.add_theme_stylebox_override("panel", _sb(_col(DANGER, 0.12), _col(DANGER, 0.5), 4))
	live.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lm := MarginContainer.new()
	for s in ["left", "right"]:
		lm.add_theme_constant_override("margin_" + s, 10)
	for s in ["top", "bottom"]:
		lm.add_theme_constant_override("margin_" + s, 4)
	live.add_child(lm)
	var lrow := _hbox(7)
	lm.add_child(lrow)
	var dot := _live_dot()
	lrow.add_child(dot)
	lrow.add_child(_lab("LIVE", f_body, 12, _col("#ff6b88"), 2.0, true))
	left.add_child(live)
	var rec := _hbox(6)
	rec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rec.add_child(_lab("REC", f_mono, 13, _col(MUTED), 1.0))
	rec.add_child(_lab("00:04:12", f_mono, 13, _col(TEXT), 1.0, true))  # PLACEHOLDER: REC timer not in view API
	left.add_child(rec)
	row.add_child(left)

	# center: brand + subtitle
	var center := _vbox(2)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := _glow("GALACTIC  PRIME  TIME", f_body, 22, _col(CYAN), 6.0, 9.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	var sub := _lab("◆ COSMIC CASINO · VIP TABLE — THE INCINERATOR", f_body, 10, _col(GOLD), 3.0, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(sub)
	row.add_child(center)

	# right: viewers + MOMUS chip
	var right := _hbox(12)
	right.alignment = BoxContainer.ALIGNMENT_END
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var watch := _hbox(6)
	watch.add_child(_emo("👁", 16))
	watch.add_child(_lab("4,102,338", f_mono, 14, _col(TEXT), 1.0))  # PLACEHOLDER: viewer count not in view API
	watch.add_child(_lab("WATCHING", f_body, 10, _col(MUTED), 2.0))
	right.add_child(watch)
	var momus := PanelContainer.new()
	momus.add_theme_stylebox_override("panel", _sb(_col(MYTHIC, 0.1), _col(MYTHIC, 0.55), 20))
	momus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mm := MarginContainer.new()
	for s in ["left", "right"]:
		mm.add_theme_constant_override("margin_" + s, 11)
	for s in ["top", "bottom"]:
		mm.add_theme_constant_override("margin_" + s, 4)
	momus.add_child(mm)
	var mrow := _hbox(7)
	mm.add_child(mrow)
	mrow.add_child(_emo("🦩", 15))
	mrow.add_child(_lab("MOMUS", f_body, 11, _col(MYTHIC), 2.0, true))
	right.add_child(momus)
	row.add_child(right)
	return p


func _live_dot() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(11, 11)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot := Panel.new()
	dot.add_theme_stylebox_override("panel", _glow_sb(_col(DANGER), _col(DANGER), 6, _col(DANGER, 0.9), 4))
	dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dot)
	# blink (captured mid-cycle in a still render; animates in live play)
	var tw := create_tween().set_loops()
	tw.tween_property(dot, "modulate:a", 0.15, 0.55)
	tw.tween_property(dot, "modulate:a", 1.0, 0.55)
	return holder


# ------------------------------------------------------------------- clock bar
func _build_clockbar() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col(PANEL), _col(BORDER), 5))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	p.add_child(pad)
	var row := _hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	pad.add_child(row)

	_clock_num = _lab("3", f_mono, 19, _col(PURPLE), 0.0, true)
	row.add_child(_kv_pill("CLOCK", _clock_num, _col(PURPLE), _col(PURPLE, 0.13), _col(PURPLE, 0.55)))
	_moment_num = _lab("07", f_mono, 19, _col(CYAN), 0.0, true)
	row.add_child(_kv_pill("MOMENT", _moment_num, _col(CYAN), _col(CYAN, 0.11), _col(CYAN, 0.5)))

	var sep := ColorRect.new()
	sep.color = _col(BORDER)
	sep.custom_minimum_size = Vector2(1, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sep)

	# tick-order rail — bound live to view_turn_order() in _bind_turn_order().
	row.add_child(_lab("TICK ORDER", f_body, 9, _col(MUTED), 3.0))
	_tick_strip = _hbox(8)
	_tick_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tick_strip.alignment = BoxContainer.ALIGNMENT_BEGIN
	_tick_strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_tick_strip)

	_nextreset = _lab("NEXT RESET · CLOCK 4", f_body, 9, _col(MUTED), 2.0)
	_nextreset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_nextreset)
	return p


func _kv_pill(label_text: String, num_label: Label, text_col: Color, bg: Color, border: Color) -> Control:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _sb(bg, border, 4))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pm := MarginContainer.new()
	for s in ["left", "right"]:
		pm.add_theme_constant_override("margin_" + s, 12)
	for s in ["top", "bottom"]:
		pm.add_theme_constant_override("margin_" + s, 6)
	pill.add_child(pm)
	var h := _hbox(8)
	h.add_child(_lab(label_text, f_body, 12, text_col, 2.0, true))
	h.add_child(num_label)
	pm.add_child(h)
	return pill


func _turn_token(cfg: Dictionary) -> Control:
	var v := _vbox(3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var face := PanelContainer.new()
	var border := _col(BORDER)
	var glow := Color(0, 0, 0, 0)
	if bool(cfg["now"]):
		border = _col(CYAN)
		glow = _col(CYAN, 0.55)
	elif bool(cfg["boss"]):
		border = _col(FIRE)
	face.add_theme_stylebox_override("panel", _glow_sb(_col(PANEL2), border, 8, glow, 6 if bool(cfg["now"]) else 0))
	face.custom_minimum_size = Vector2(34, 34)
	var fm := CenterContainer.new()
	fm.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	face.add_child(fm)
	fm.add_child(_emo(String(cfg["e"]), 16))
	# windup marker
	if bool(cfg["windup"]):
		var wrap := Control.new()
		wrap.custom_minimum_size = Vector2(34, 34)
		wrap.add_child(face)
		face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var wu := PanelContainer.new()
		wu.add_theme_stylebox_override("panel", _sb(_col(FIRE, 0.9), _col(FIRE, 0.0), 3))
		wu.position = Vector2(6, -9)
		var wum := MarginContainer.new()
		wum.add_theme_constant_override("margin_left", 4)
		wum.add_theme_constant_override("margin_right", 4)
		wu.add_child(wum)
		wum.add_child(_lab("WINDUP", f_body, 7, _col("#180a02"), 1.0, true))
		wrap.add_child(wu)
		v.add_child(wrap)
	else:
		v.add_child(face)
	var nm := _lab(String(cfg["n"]), f_body, 8, _col(CYAN) if bool(cfg["now"]) else _col(MUTED), 1.0)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	return v


# --------------------------------------------------------------------- main row
func _build_main() -> Control:
	var row := _hbox(9)
	row.add_child(_size_x(_build_left(), 280))
	row.add_child(_expand(_build_stage()))
	row.add_child(_size_x(_build_right(), 330))
	return row


func _size_x(node: Control, w: int) -> Control:
	node.custom_minimum_size.x = w
	node.size_flags_horizontal = Control.SIZE_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


func _expand(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


# ------- left director rail -------
func _build_left() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col(PANEL), _col(BORDER), 5))
	var v := _vbox(0)
	p.add_child(v)

	# Slice Objective
	var obj := _card(v)
	obj.add_child(_h4("SLICE OBJECTIVE"))
	var objbody := _vbox(0)
	objbody.add_theme_constant_override("separation", 0)
	# cyan left-accent
	var objwrap := _accent_left(objbody, _col(CYAN))
	var big := _rich_line([
		["Find & breach the Incine-Dile's ", _col(TEXT), false],
		["hidden network", _col(CYAN), true],
		[" → force ", _col(TEXT), false],
		["Phase 2", _col(CYAN), true],
	], 13, true)
	objbody.add_child(big)
	var prog := ProgressBar.new()
	prog.show_percentage = false
	prog.custom_minimum_size.y = 7
	prog.max_value = 100
	prog.value = 0
	prog.add_theme_stylebox_override("background", _sb(_col("#0a0e1c"), _col(BORDER), 4))
	prog.add_theme_stylebox_override("fill", _sb(_col(CYAN), _col(CYAN, 0.0), 4))
	var progpad := _pad_top(prog, 9)
	objbody.add_child(progpad)
	_obj_status = _hint_line("🔒", "NETWORK not yet exposed · surface immune until a breach", _col(MUTED))
	objbody.add_child(_pad_top(_obj_status.get_parent(), 7))
	obj.add_child(objwrap)

	_border_line(v)

	# Hazard Read
	var haz := _card(v)
	haz.add_child(_h4("HAZARD READ"))
	var hazbody := _vbox(5)
	var hazwrap := _accent_left(hazbody, _col(FIRE))
	hazbody.add_child(_rich_line([
		["🔥 ", _col(FIRE), false],
		["FIRE HEALS IT", _col(FIRE), true],
		[" — stop feeding the flame", _col("#ffb27a"), true],
	], 13, true))
	hazbody.add_child(_lab("Burning trash cans mend the boss. Imani reads fuel: \"quit lighting things up.\"", f_body, 10, _col("#8a6a4a")))
	(hazbody.get_child(1) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	haz.add_child(hazwrap)

	_border_line(v)

	# Gods At The Table (# PLACEHOLDER: patron multipliers + wager feed — patron_manager not wired)
	var gods := _card(v)
	gods.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	gods.add_child(_h4("GODS AT THE TABLE"))
	var wager := _vbox(7)
	wager.add_child(_wager_row("HESTIA", "on Imani", "×2.4 ▲", _col(GOLD), _col(GOLD)))
	wager.add_child(_wager_row("ENYO", "on Dario", "×3.1 ▲", _col(MYTHIC), _col(MYTHIC)))
	wager.add_child(_wager_row("ARES", "watching", "circling", _col(MUTED), _col(MUTED)))
	var dash := ColorRect.new()
	dash.color = _col(BORDER)
	dash.custom_minimum_size = Vector2(0, 1)
	wager.add_child(_pad_top(dash, 9))
	var feed := _rich_line([
		["WAGER FEED\n", _col(PURPLE), true],
		["ENYO ▲ raises on the bow · ARES eyes a buy-out of Imani · pot swells to ", _col(MUTED), false],
		["18.2k favor", _col(PURPLE), true],
	], 9, true)
	wager.add_child(feed)
	gods.add_child(wager)
	return p


func _card(parent: Node) -> VBoxContainer:
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 13)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 11)
	parent.add_child(m)
	var v := _vbox(0)
	m.add_child(v)
	return v


func _h4(text: String) -> Control:
	# Returns the padded WRAPPER (_pad_bottom -> MarginContainer), not the bare
	# Label — the annotation must be Control or the typed return coerces to null at
	# runtime and the heading silently vanishes (regression fixed 2026-07-20).
	var l := _lab(text, f_body, 9, _col(MUTED), 3.0, true)
	return _pad_bottom(l, 8)


func _accent_left(content: Control, color: Color) -> Control:
	var h := _hbox(10)
	var bar := ColorRect.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(2, 0)
	bar.size_flags_vertical = Control.SIZE_FILL
	h.add_child(bar)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(content)
	return h


func _wager_row(god: String, note: String, amount: String, sig_col: Color, amt_col: Color) -> Control:
	var h := _hbox(0)
	var lft := _hbox(6)
	lft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lft.add_child(_lab("⬢", f_sym, 11, sig_col))
	lft.add_child(_lab(god, f_body, 11, _col(TEXT), 0.0, true))
	lft.add_child(_lab(note.to_upper(), f_body, 9, _col(MUTED), 1.0))
	h.add_child(lft)
	h.add_child(_lab(amount, f_mono, 11, amt_col, 1.0, true))
	return h


# ------- center stage / arena — LIVE hex board bound to view_combatants -------
## The arena is now real: ArenaFloor paints the hex board from the board transform
## the HUD computes each refresh (auto-centred/scaled on the LIVE occupied hexes),
## and _bind_arena drops one unit token per combatant at
## FieldRenderer.axial_to_pixel(position, eff) + offset. MOVE arms the click catcher.
func _build_stage() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#080b18"), _col(BORDER), 5))
	p.clip_contents = true
	_stage = Control.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(_stage)

	# live hex board (bottom)
	_arena_floor = ArenaFloor.new()
	_arena_floor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_arena_floor)

	# vignette
	var vig := TextureRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.texture = _vignette_tex()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(vig)

	# unit-token layer (each token's origin is its disc centre → drop onto a hex)
	_token_layer = Control.new()
	_token_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_token_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_token_layer)

	# broadcast feed corner marks
	var fl := _lab("◉ FEED 01 · ARENA CAM", f_body, 9, _col(CYAN, 0.55), 2.0)
	fl.position = Vector2(14, 12)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(fl)
	var fr := _lab("● REC", f_body, 9, _col(DANGER, 0.65), 2.0)
	fr.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fr.position = Vector2(-70, 12)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(fr)
	var cam := _lab("▮ FLAMETHROWER WINDUP DETECTED — CONE TELEGRAPHED", f_body, 9, _col(TEXT, 0.42), 2.0)
	cam.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cam.position = Vector2(14, -22)
	cam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(cam)
	# Live boss-condition readout (bleeding/etc.) — bound in _update_boss_cond().
	_boss_cond = _lab("", f_body, 11, _col("#ff6b88"), 2.0, true)
	_boss_cond.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_boss_cond.position = Vector2(14, -40)
	_boss_cond.visible = false
	_boss_cond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_boss_cond)

	# click catcher — top overlay, filter-STOP only while MOVE is armed
	_click_catcher = Control.new()
	_click_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_click_catcher.gui_input.connect(_on_arena_input)
	_stage.add_child(_click_catcher)

	# re-layout tokens/board once the panel gets its real size (and on any resize)
	_stage.resized.connect(_layout_arena)
	return p


## Rebuilds the arena token layer from view_combatants(), masks the boss network
## until breach, updates the objective + boss-condition readouts, then lays the
## board + tokens out with a single shared transform.
func _bind_arena() -> void:
	if _token_layer == null:
		return
	for ch in _token_layer.get_children():
		ch.queue_free()
	var combs: Array = _gc.view_combatants()
	_last_combatants = combs
	var boss_hidden := true
	for cd in combs:
		var c: Dictionary = cd
		var is_boss := String(c.get("id", "")) == _boss_id_cache
		var token := _build_combatant_token(c, is_boss)
		_token_layer.add_child(token)
		if is_boss:
			boss_hidden = _boss_network_hidden(c)
			_update_boss_cond(c)
	_bind_objective(boss_hidden)
	_layout_arena()


## Positions every token onto its live hex and reconfigures the floor's draw spec,
## all through one board transform (auto-centred/scaled on the occupied hexes).
func _layout_arena() -> void:
	if _stage == null or _token_layer == null or _arena_floor == null:
		return
	var panel := _stage.size
	if panel.x < 40.0 or panel.y < 40.0:
		return  # panel not sized yet; the resized signal will call us again
	var coords: Array = []
	for cd in _last_combatants:
		coords.append(_axial_of(cd))
	var xf := _arena_transform(coords, panel)
	_arena_eff = xf["eff"]
	_arena_off = xf["off"]
	_arena_qr = Vector2i(xf["qlo"], xf["qhi"])
	_arena_rr = Vector2i(xf["rlo"], xf["rhi"])
	for t in _token_layer.get_children():
		var a: Vector2i = t.get_meta("axial", Vector2i.ZERO)
		var tp: Vector2 = _fr().axial_to_pixel(a.x, a.y, _arena_eff) + _arena_off
		(t as Control).position = tp
	# decorative flamethrower cone off the boss toward the party centroid
	var cone := _cone_spec(coords)
	var reach: Array = _reachable_hexes() if _move_mode else []
	_arena_floor.configure(_arena_eff, _arena_off, _arena_qr, _arena_rr,
		coords, reach, bool(cone["on"]), cone["origin"], cone["dir"])


## Board transform: pick an on-screen hex size + offset that fit the occupied
## hexes (plus a margin ring) inside the panel, and the drawn q/r range. Since
## axial_to_pixel scales linearly with size, folding the fit-scale into the hex
## size is exact — tokens and the floor then share one (eff, off) mapping.
func _arena_transform(coords: Array, panel: Vector2) -> Dictionary:
	if coords.is_empty():
		coords = [Vector2i.ZERO]
	var minq := 999999
	var maxq := -999999
	var minr := 999999
	var maxr := -999999
	for c: Vector2i in coords:
		minq = mini(minq, c.x); maxq = maxi(maxq, c.x)
		minr = mini(minr, c.y); maxr = maxi(maxr, c.y)
	var margin := 2
	var qlo := minq - margin; var qhi := maxq + margin
	var rlo := minr - margin; var rhi := maxr + margin
	# pixel bbox of the drawn hex centres at nominal size 1.0
	var pmin := Vector2(INF, INF)
	var pmax := Vector2(-INF, -INF)
	for r: int in range(rlo, rhi + 1):
		for q: int in range(qlo, qhi + 1):
			var pp: Vector2 = _fr().axial_to_pixel(q, r, 1.0)
			pmin.x = minf(pmin.x, pp.x); pmin.y = minf(pmin.y, pp.y)
			pmax.x = maxf(pmax.x, pp.x); pmax.y = maxf(pmax.y, pp.y)
	pmin -= Vector2.ONE   # + one hex radius of padding at nominal size
	pmax += Vector2.ONE
	var bw := maxf(0.001, pmax.x - pmin.x)
	var bh := maxf(0.001, pmax.y - pmin.y)
	var padf := 0.82
	var scale := minf(panel.x * padf / bw, panel.y * padf / bh)
	var eff := clampf(scale, 20.0, 70.0)
	var center_nom := (pmin + pmax) * 0.5
	var off := panel * 0.5 - center_nom * eff
	return {"eff": eff, "off": off, "qlo": qlo, "qhi": qhi, "rlo": rlo, "rhi": rhi}


## Hexes the active actor can step onto (allowance 3, unoccupied, within range).
## PLACEHOLDER: prone/slowed would cap the allowance at 1, but the view API does
## not surface those statuses — an illegal move is still rejected by the sim and
## narrated in the Momus chyron, so an optimistic highlight never mis-moves.
func _reachable_hexes() -> Array:
	var out: Array = []
	var actor := _find_combatant(_active_actor)
	if actor.is_empty():
		return out
	var ap := _axial_of(actor)
	var allowance := 3
	var occ := {}
	for cd in _last_combatants:
		occ[_axial_of(cd)] = true
	for dq: int in range(-allowance, allowance + 1):
		for dr: int in range(-allowance, allowance + 1):
			var h := Vector2i(ap.x + dq, ap.y + dr)
			if h == ap or occ.has(h):
				continue
			if _hex_dist(ap, h) > allowance:
				continue
			out.append(h)
	return out


func _hex_dist(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


## Decorative telegraph: a cone off the boss hex toward the party centroid.
func _cone_spec(coords: Array) -> Dictionary:
	if _boss_id_cache == "":
		return {"on": false, "origin": Vector2.ZERO, "dir": Vector2.RIGHT}
	var boss := _find_combatant(_boss_id_cache)
	if boss.is_empty():
		return {"on": false, "origin": Vector2.ZERO, "dir": Vector2.RIGHT}
	var bhex := _axial_of(boss)
	var boss_px: Vector2 = _fr().axial_to_pixel(bhex.x, bhex.y, _arena_eff) + _arena_off
	var centroid := Vector2.ZERO
	var n := 0
	for cd in _last_combatants:
		var c: Dictionary = cd
		if String(c.get("id", "")) == _boss_id_cache:
			continue
		var h := _axial_of(c)
		var hp: Vector2 = _fr().axial_to_pixel(h.x, h.y, _arena_eff) + _arena_off
		centroid += hp
		n += 1
	if n == 0:
		return {"on": false, "origin": boss_px, "dir": Vector2.DOWN}
	centroid /= float(n)
	var dir := centroid - boss_px
	if dir.length() < 1.0:
		dir = Vector2.DOWN
	return {"on": true, "origin": boss_px, "dir": dir}


## A unit token whose ORIGIN (0,0) is the disc CENTRE, so the HUD drops it onto a
## hex's screen point. Tags sit above the disc, name plate + HP sliver below — all
## absolutely positioned and re-pinned on resize so layout timing never nudges the
## disc off its hex. Boss network stays masked (tag + HP) until breached.
func _build_combatant_token(c: Dictionary, is_boss: bool) -> Control:
	var id := String(c.get("id", ""))
	var alive := bool(c.get("alive", true))
	var breached := bool(c.get("breached", false))
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Non-active contestants carry a subdued cyan ring; the ON-THE-CLOCK one pops in
	# GOLD with a bigger halo, so the arena agrees with the tick-order rail at a glance.
	var border := _col(CYAN, 0.7)
	var name_col := _col(CYAN)
	var glow := _col(CYAN, 0.3)
	var glow_px := 8
	var disc_bg := "#0c1428"
	var disc := _arena_eff * 1.15
	if is_boss:
		border = _col(FIRE); name_col = _col("#ff9a5a"); glow = _col(FIRE, 0.6); glow_px = 14
		disc_bg = "#3a1206"; disc = _arena_eff * 2.05
	elif id == _active_actor:
		border = _col(GOLD); name_col = _col(GOLD); glow = _col(GOLD, 0.95); glow_px = 22
	if not alive:
		border = _col(MUTED); name_col = _col(MUTED); glow = Color(0, 0, 0, 0)

	# disc (centred on origin)
	var d := Panel.new()
	var radius := int(disc * 0.18)
	d.add_theme_stylebox_override("panel", _glow_sb(_col(disc_bg), border, radius, glow, glow_px if glow.a > 0.0 else 0))
	d.size = Vector2(disc, disc)
	d.position = Vector2(-disc * 0.5, -disc * 0.5)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dc := CenterContainer.new()
	dc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(dc)
	dc.add_child(_emo(_emoji_for_id(id), int(disc * 0.55)))
	root.add_child(d)
	if not alive:
		var x := _lab("✕", f_sym, int(disc * 0.7), _col(DANGER))
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(x)
		_pin_row(x, -disc * 0.5, false)

	# tags above (boss PHASE / NETWORK — network masked until breach)
	var tags := _token_tags(c, is_boss, breached)
	if not tags.is_empty():
		var trow := _hbox(5)
		trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for tg in tags:
			trow.add_child(_unit_tag(String(tg["t"]), String(tg["kind"])))
		root.add_child(trow)
		_pin_row(trow, -disc * 0.5 - 8.0, true)

	# name plate below the disc
	var np := PanelContainer.new()
	np.add_theme_stylebox_override("panel", _sb(_col(BG, 0.85), Color(name_col.r, name_col.g, name_col.b, 0.4), 3))
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var npm := MarginContainer.new()
	for s in ["left", "right"]:
		npm.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		npm.add_theme_constant_override("margin_" + s, 2)
	np.add_child(npm)
	npm.add_child(_lab(String(c.get("name", id)).to_upper(), f_body, 10, name_col, 1.5, true))
	root.add_child(np)
	_pin_row(np, disc * 0.5 + 6.0, false)

	# HP sliver (boss: arm pre-breach → network post-breach; never leaks early)
	var hp_info := _token_hp(c, is_boss, breached)
	if bool(hp_info["show"]):
		var mx := maxi(1, int(hp_info["max"]))
		var hp := ProgressBar.new()
		hp.show_percentage = false
		hp.custom_minimum_size = Vector2(maxf(48.0, disc * 0.95), 5)
		hp.max_value = mx
		hp.value = clampi(int(hp_info["hp"]), 0, mx)
		hp.add_theme_stylebox_override("background", _sb(_col("#0a0e1c"), _col(BORDER), 3))
		var ramp := _ramp(float(int(hp_info["hp"])) / float(mx))
		hp.add_theme_stylebox_override("fill", _sb(ramp, ramp, 3, 0))
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(hp)
		_pin_row(hp, disc * 0.5 + 26.0, false)

	root.set_meta("axial", _axial_of(c))
	return root


## Keeps an absolutely-positioned token row centred on the token origin. `edge` is
## the y of the row's anchored edge (its BOTTOM if `above`, else its TOP); re-pins
## on the row's `resized` so font/layout timing never leaves it off-centre.
func _pin_row(node: Control, edge: float, above: bool) -> void:
	var place := func() -> void:
		var sz := node.size
		node.position = Vector2(-sz.x * 0.5, (edge - sz.y) if above else edge)
	node.resized.connect(place)
	node.reset_size()
	place.call()


func _axial_of(c: Dictionary) -> Vector2i:
	var pos: Array = c.get("position", [0, 0])
	return Vector2i(int(pos[0]), int(pos[1]))


func _find_combatant(id: String) -> Dictionary:
	for cd in _last_combatants:
		if String((cd as Dictionary).get("id", "")) == id:
			return cd
	return {}


## The network part reads hidden=true until the boss is breached (the view masks
## it); pre-breach the arena shows NETWORK 🔒 HIDDEN and never leaks its HP.
func _boss_network_hidden(c: Dictionary) -> bool:
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if String(p.get("key", "")).contains("network"):
			return bool(p.get("hidden", false))
	return not bool(c.get("breached", false))


func _token_tags(c: Dictionary, is_boss: bool, breached: bool) -> Array:
	if not is_boss:
		return []
	return [
		{"t": ("PHASE 1" if not breached else "PHASE 2"), "kind": "phase"},
		{"t": ("NETWORK 🔒 HIDDEN" if _boss_network_hidden(c) else "NETWORK ⚡ EXPOSED"), "kind": "net"},
	]


## Which HP the token sliver shows. Boss: the flamethrower arm pre-breach (the
## designed path in), the exposed network post-breach. Contestants: aggregate HP.
func _token_hp(c: Dictionary, is_boss: bool, breached: bool) -> Dictionary:
	if not bool(c.get("alive", true)):
		return {"show": false}
	var by_key := {}
	for pd in c.get("parts", []):
		by_key[String((pd as Dictionary).get("key", ""))] = pd
	if is_boss:
		var show_key := "network" if breached else BOSS_DEFAULT_PART
		if not by_key.has(show_key):
			return {"show": false}
		var part: Dictionary = by_key[show_key]
		return {"show": true, "hp": int(part.get("hp", 0)), "max": maxi(1, int(part.get("max_hp", 1)))}
	var hp := 0
	var mx := 0
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if bool(p.get("hidden", false)):
			continue
		hp += int(p.get("hp", 0))
		mx += int(p.get("max_hp", 0))
	if mx <= 0:
		return {"show": false}
	return {"show": true, "hp": hp, "max": mx}


## Boss-condition readout overlay (bleeding etc.) — highest tier per condition.
func _update_boss_cond(boss: Dictionary) -> void:
	if _boss_cond == null:
		return
	var conds := _gather_conditions(boss)
	if conds.is_empty():
		_boss_cond.visible = false
		return
	var bits := []
	for cond in conds:
		bits.append("%s T%d" % [String(cond[0]).to_upper(), int(cond[1])])
	_boss_cond.text = "🩸 %s · %s" % [String(boss.get("name", "BOSS")).to_upper(), "  ·  ".join(bits)]
	_boss_cond.visible = true


## Left-rail SLICE OBJECTIVE network status (mirrors the boss network mask).
func _bind_objective(network_hidden: bool) -> void:
	if _obj_status == null:
		return
	if network_hidden:
		_obj_status.text = "NETWORK not yet exposed · surface immune until a breach"
		_obj_status.add_theme_color_override("font_color", _col(MUTED))
	else:
		_obj_status.text = "NETWORK EXPOSED · Phase 2 is in reach — pour in"
		_obj_status.add_theme_color_override("font_color", _col(CYAN))


## Tick-order rail + on-the-clock derivation, both from view_turn_order(). The
## active actor is the first ready contestant (fallback: keep the current one);
## END TURN re-runs this, so the rail highlight + action bar rotate automatically.
func _bind_turn_order() -> void:
	var order: Array = _gc.view_turn_order()
	for e in order:
		var ed: Dictionary = e
		if bool(ed.get("ready", false)) and bool(ed.get("is_contestant", false)):
			_active_actor = String(ed.get("id", ""))
			break
	if _actionbar_who != null:
		_actionbar_who.text = _display_name_for(_active_actor)
	if _tick_strip == null:
		return
	for ch in _tick_strip.get_children():
		ch.queue_free()
	for i in order.size():
		var ed: Dictionary = order[i]
		var id := String(ed.get("id", ""))
		if i > 0:
			_tick_strip.add_child(_lab("→", f_body, 13, _col(MUTED)))
		_tick_strip.add_child(_turn_token({
			"e": _emoji_for_id(id),
			"n": String(ed.get("name", id)).to_upper(),
			"now": id == _active_actor,
			"boss": id == _boss_id_cache,
			"windup": bool(ed.get("windup_pending", false)),
		}))


func _unit_tag(text: String, kind: String) -> Control:
	var bg := _col(CYAN, 0.12)
	var bd := _col(CYAN, 0.5)
	var fg := _col(CYAN)
	if kind == "phase":
		bg = _col(FIRE, 0.16); bd = _col(FIRE, 0.6); fg = _col("#ff9a5a")
	elif kind == "net":
		bg = _col(PURPLE, 0.14); bd = _col(PURPLE, 0.6); fg = _col(PURPLE)
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _sb(bg, bd, 3))
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 6)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 2)
	chip.add_child(m)
	var lbl := _lab(text, f_body, 8, fg, 1.0, true)
	m.add_child(lbl)
	chip.set_meta("label", lbl)
	return chip


func _vignette_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.6)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	gt.width = 480
	gt.height = 320
	return gt


# ------- right spectacle column -------
func _build_right() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col(PANEL), _col(BORDER), 5))
	var v := _vbox(0)
	p.add_child(v)

	# hype
	var hype := _rc_sec(v)
	var hhead := _hbox(0)
	hhead.add_child(_lab("HYPE METER", f_body, 9, _col(GOLD), 3.0, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hhead.add_child(spacer)
	_hype_val = _glow("68", f_mono, 26, _col(GOLD), 0.0, 0.0)
	var hval := _hbox(0)
	hval.alignment = BoxContainer.ALIGNMENT_END
	hval.add_child(_hype_val)
	hval.add_child(_lab(" / 100", f_mono, 13, _col("#7a6a3a")))
	hhead.add_child(hval)
	hype.add_child(hhead)
	_hype_bar = ProgressBar.new()
	_hype_bar.show_percentage = false
	_hype_bar.custom_minimum_size.y = 20
	_hype_bar.max_value = 100
	_hype_bar.value = 68
	_hype_bar.add_theme_stylebox_override("background", _sb(_col("#0a0e1c"), _col(GOLD, 0.35), 5))
	_hype_bar.add_theme_stylebox_override("fill", _glow_sb(_col(GOLD), _col(GOLD, 0.0), 5, _col(GOLD, 0.4), 6))
	hype.add_child(_pad_top(_hype_bar, 11))
	var hfoot := _hbox(0)
	var band_row := _hbox(6)
	band_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hype_band = _lab("CROWD: ELECTRIC", f_body, 12, _col(GOLD), 2.0, true)
	band_row.add_child(_hype_band)
	band_row.add_child(_emo("⚡", 13))
	hfoot.add_child(band_row)
	_hype_delta = _lab("+12", f_mono, 11, _col(SUCCESS), 1.0, true)  # PLACEHOLDER: last-gain delta not in view API
	var delta_chip := PanelContainer.new()
	delta_chip.add_theme_stylebox_override("panel", _sb(_col(SUCCESS, 0.1), _col(SUCCESS, 0.4), 4))
	delta_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dcm := MarginContainer.new()
	for s in ["left", "right"]:
		dcm.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		dcm.add_theme_constant_override("margin_" + s, 2)
	delta_chip.add_child(dcm)
	dcm.add_child(_hype_delta)
	hfoot.add_child(delta_chip)
	hype.add_child(_pad_top(hfoot, 8))

	_border_line(v)

	# active crowd goal
	var goalsec := _rc_sec(v)
	goalsec.add_child(_pad_bottom(_lab("ACTIVE CROWD GOAL", f_body, 9, _col(MUTED), 3.0, true), 9))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(_col(CYAN, 0.05), _col(CYAN, 0.3), 6))
	var cardm := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		cardm.add_theme_constant_override("margin_" + s, 12)
	card.add_child(cardm)
	var cardv := _vbox(0)
	cardm.add_child(cardv)
	var gt := _hbox(6)
	gt.add_child(_emo("🎯", 15))
	_goal_title = _glow("SHOW-OFF!", f_body, 14, _col(CYAN), 1.0, 6.0)
	gt.add_child(_goal_title)
	cardv.add_child(gt)
	_goal_desc = _lab("Land a hit from an Exposed state — make it look easy.", f_body, 11, _col(TEXT))
	_goal_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cardv.add_child(_pad_top(_goal_desc, 7))
	var meta := _hbox(8)
	_goal_pay = _lab("+40 HYPE", f_mono, 9, _col(SUCCESS), 1.0, true)
	meta.add_child(_chip(_goal_pay, _col(SUCCESS, 0.1), _col(SUCCESS, 0.4)))
	var timerow := _hbox(4)
	timerow.add_child(_emo("⏱", 11))
	_goal_time = _lab("2 CLOCKS", f_mono, 9, _col(PURPLE), 1.0, true)
	timerow.add_child(_goal_time)
	meta.add_child(_chip(timerow, _col(PURPLE, 0.12), _col(PURPLE, 0.45)))
	cardv.add_child(_pad_top(meta, 9))
	goalsec.add_child(card)

	_border_line(v)

	# spotlight / camera call
	var spot := _rc_sec(v)
	spot.get_parent().size_flags_vertical = Control.SIZE_EXPAND_FILL
	spot.add_child(_pad_bottom(_lab("SPOTLIGHT", f_body, 9, _col(MUTED), 3.0, true), 9))
	var cam := PanelContainer.new()
	cam.add_theme_stylebox_override("panel", _glow_sb(_col(GOLD, 0.14), _col(GOLD), 6, _col(GOLD, 0.35), 8))
	var camm := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		camm.add_theme_constant_override("margin_" + s, 12)
	cam.add_child(camm)
	var camv := _vbox(4)
	camv.alignment = BoxContainer.ALIGNMENT_CENTER
	var camtop := _hbox(7)
	camtop.alignment = BoxContainer.ALIGNMENT_CENTER
	camtop.add_child(_emo("📸", 16))
	# Bound live from view_broadcast().spotlight (empty = available, set = active).
	_spot_title = _glow("CAMERA CALL", f_body, 14, _col(GOLD), 2.0, 6.0)
	camtop.add_child(_spot_title)
	camv.add_child(camtop)
	_spot_sub = _lab("CHARM-GATED · AVAILABLE · DOUBLES GAINS & LOSSES", f_body, 9, _col("#8a7a4a"), 2.0, true)
	_spot_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spot_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	camv.add_child(_spot_sub)
	camm.add_child(camv)
	spot.add_child(cam)
	var spotdesc := _rich_line([
		["Spotlight a contestant to ", _col(MUTED), false],
		["double their next spectacle swing", _col(GOLD), false],
		[". Encore's doubling-down vice, made mechanical.", _col(MUTED), false],
	], 10, true)
	spot.add_child(_pad_top(spotdesc, 12))
	return p


func _rc_sec(parent: Node) -> VBoxContainer:
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 15)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 13)
	parent.add_child(m)
	var v := _vbox(0)
	m.add_child(v)
	return v


func _chip(content: Control, bg: Color, border: Color) -> Control:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _sb(bg, border, 4))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 3)
	c.add_child(m)
	m.add_child(content)
	return c


# ------------------------------------------------------------- contestant panels
func _build_contestants() -> Control:
	var row := _hbox(9)
	row.add_child(_expand(_build_contestant({
		"id": "imani", "accent": _col(CYAN), "avatar": "🛡️", "name": "IMANI", "epithet": "\"THE DOOR\"",
		"tagline": "The wall between the monster and everyone else",
		"patron": "HESTIA", "patron_col": _col(GOLD), "active": false, "steady": true,
		"skills": [["STRONG STRIKE", false], ["OVERHEAD SLAM", false], ["BRACE", false]],
	})))
	row.add_child(_expand(_build_contestant({
		"id": "dario", "accent": _col(GOLD), "avatar": "🎭", "name": "DARIO", "epithet": "\"ENCORE\"",
		"tagline": "The heel you pay to boo — bows after every kill",
		"patron": "ENYO", "patron_col": _col(MYTHIC), "active": true, "steady": false,
		"skills": [["FEINT", true], ["PRESSURE STRIKE", false], ["DANCE", false]],
	})))
	return row


func _build_contestant(cfg: Dictionary) -> Control:
	var accent: Color = cfg["accent"]
	var active: bool = cfg["active"]
	var p := PanelContainer.new()
	if active:
		p.add_theme_stylebox_override("panel", _glow_sb(_col(PANEL), _col(GOLD), 5, _col(GOLD, 0.18), 6))
	else:
		p.add_theme_stylebox_override("panel", _sb(_col(PANEL), _col(BORDER), 5))
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 14)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 11)
	p.add_child(m)
	var v := _vbox(8)
	m.add_child(v)

	# header
	var head := _hbox(10)
	var av := Panel.new()
	av.add_theme_stylebox_override("panel", _glow_sb(_col(PANEL2), accent, 9, Color(accent.r, accent.g, accent.b, 0.4), 5))
	av.custom_minimum_size = Vector2(40, 40)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var avc := CenterContainer.new()
	avc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av.add_child(avc)
	avc.add_child(_emo(String(cfg["avatar"]), 20))
	head.add_child(av)
	var info := _vbox(1)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nrow := _rich_line([
		[String(cfg["name"]) + " ", accent, true],
		[String(cfg["epithet"]), Color(accent.r, accent.g, accent.b, 0.7), true],
	], 14)
	info.add_child(nrow)
	info.add_child(_lab(String(cfg["tagline"]), f_body, 9, _col(MUTED), 1.0))  # PLACEHOLDER: persona/tagline is fixture cfg
	head.add_child(info)
	# patron badge (# PLACEHOLDER: patron identity is fixture cfg — patron_manager not in view API)
	var patron := PanelContainer.new()
	var pc: Color = cfg["patron_col"]
	patron.add_theme_stylebox_override("panel", _sb(Color(pc.r, pc.g, pc.b, 0.1), Color(pc.r, pc.g, pc.b, 0.5), 14))
	patron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var patm := MarginContainer.new()
	for s in ["left", "right"]:
		patm.add_theme_constant_override("margin_" + s, 9)
	for s in ["top", "bottom"]:
		patm.add_theme_constant_override("margin_" + s, 4)
	patron.add_child(patm)
	var patrow := _hbox(5)
	patrow.add_child(_lab("⬢", f_sym, 10, pc))
	patrow.add_child(_lab(String(cfg["patron"]), f_body, 9, pc, 1.0, true))
	patm.add_child(patrow)
	if active:
		var vv := _vbox(2)
		vv.alignment = BoxContainer.ALIGNMENT_BEGIN
		var otc := _lab("◀ ON THE CLOCK", f_body, 8, _col(GOLD), 2.0, true)
		otc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vv.add_child(otc)
		vv.add_child(patron)
		head.add_child(vv)
	else:
		head.add_child(patron)
	v.add_child(head)

	# hp grid
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var parts_ref := {}
	for key in PART_ORDER:
		var cell := _part_cell(String(PART_LABEL[key]))
		grid.add_child(cell)
		parts_ref[key] = {"val": cell.get_meta("val"), "bar": cell.get_meta("bar")}
	v.add_child(grid)

	# footer: conditions/shock/steady + skills
	var foot := _hbox(7)
	foot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var condbox := _hbox(7)
	foot.add_child(condbox)
	var shock := _lab("SHOCK 0", f_body, 9, _col(MUTED), 1.0)
	foot.add_child(shock)
	if bool(cfg["steady"]):
		foot.add_child(_lab("● STEADY", f_body, 9, _col(SUCCESS), 1.0))
	var skills := _hbox(6)
	skills.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skills.alignment = BoxContainer.ALIGNMENT_END
	for sk in cfg["skills"]:
		var skill_key := String(sk[0]).to_lower().replace(" ", "_")
		skills.add_child(_skill_chip(String(sk[0]), bool(sk[1]), accent,
			_on_skill_for.bind(String(cfg["id"]), skill_key)))
	foot.add_child(skills)
	v.add_child(_vfill(Control.new()))  # push footer down
	v.add_child(foot)

	_cref[String(cfg["id"])] = {"parts": parts_ref, "condbox": condbox, "shock": shock}
	return p


func _part_cell(label: String) -> Control:
	var cell := PanelContainer.new()
	cell.add_theme_stylebox_override("panel", _sb(_col("#0a0e1c"), _col(BORDER), 4))
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 4)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 5)
	cell.add_child(m)
	var v := _vbox(3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)
	var pl := _lab(label, f_body, 7, _col(MUTED), 1.0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pl)
	var pv := _lab("0/0", f_mono, 12, _col(SUCCESS), 0.0, true)
	pv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(pv)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 4
	bar.max_value = 1
	bar.value = 1
	bar.add_theme_stylebox_override("background", _sb(_col("#060912"), _col("#060912"), 2, 0))
	bar.add_theme_stylebox_override("fill", _sb(_col(SUCCESS), _col(SUCCESS), 2, 0))
	v.add_child(bar)
	cell.set_meta("val", pv)
	cell.set_meta("bar", bar)
	return cell


func _skill_chip(text: String, on: bool, accent: Color, on_press := Callable()) -> Control:
	var c := PanelContainer.new()
	if on:
		c.add_theme_stylebox_override("panel", _glow_sb(_col(GOLD, 0.1), _col(GOLD), 4, _col(GOLD, 0.25), 4))
	else:
		c.add_theme_stylebox_override("panel", _sb(_col(PANEL2), _col(BORDER), 4))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 4)
	c.add_child(m)
	m.add_child(_lab(text, f_body, 9, _col(GOLD) if on else _col(MUTED), 0.5, on))
	_attach_click(c, on_press)
	return c


# --------------------------------------------------------------------- action bar
func _build_actionbar() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _glow_sb(_col("#0b1024"), _col(GOLD), 5, _col(GOLD, 0.15), 4))
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 16)
	p.add_child(m)
	var row := _hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	m.add_child(row)
	# who (# PLACEHOLDER: active contestant identity — turn order not in view API)
	var who := _vbox(2)
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(_lab("ON THE CLOCK", f_body, 10, _col(GOLD), 2.0, true))
	_actionbar_who = _lab("DARIO \"ENCORE\"", f_body, 9, _col(MUTED), 1.0)
	who.add_child(_actionbar_who)
	row.add_child(who)
	# buttons — wired to real sim commands through GameController.apply_command.
	var btns := _hbox(8)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btns.add_child(_action_btn("FEINT", "primary", _on_skill.bind("feint")))
	btns.add_child(_action_btn("PRESSURE STRIKE", "normal", _on_skill.bind("pressure_strike")))
	btns.add_child(_action_btn("DANCE", "normal", _on_skill.bind("dance")))
	btns.add_child(_action_btn("↔ MOVE", "normal", _on_move))
	btns.add_child(_action_btn("📸 CAMERA CALL", "cam", _on_camera_call))
	btns.add_child(_action_btn("🎭 THE BIT", "bit", _on_bit))
	btns.add_child(_action_btn("END TURN", "end", _on_end_turn))
	row.add_child(btns)
	# consequence preview
	var prev := _vbox(2)
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prev.alignment = BoxContainer.ALIGNMENT_CENTER
	var pl := _lab("CONSEQUENCE PREVIEW", f_body, 8, _col(MUTED), 2.0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prev.add_child(pl)
	var pt := _rich_line([
		["FEINT", _col(GOLD), true],
		[" → forces a reaction · sets up ", _col(TEXT), false],
		["Pressure Strike", _col(GOLD), true],
	], 11)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prev.add_child(pt)
	row.add_child(prev)
	return p


func _action_btn(text: String, kind: String, on_press := Callable()) -> Control:
	var bg := _col(PANEL2)
	var bd := _col(BORDER)
	var fg := _col(TEXT)
	var glow := Color(0, 0, 0, 0)
	var emoji := ""
	var label := text
	match kind:
		"primary":
			bd = _col(GOLD); fg = _col(GOLD); bg = _col(GOLD, 0.12); glow = _col(GOLD, 0.3)
		"cam":
			bd = _col(GOLD); fg = _col(GOLD); bg = _col(GOLD, 0.1)
			emoji = "📸"; label = "CAMERA CALL"
		"bit":
			bd = _col(MYTHIC); fg = _col(MYTHIC); bg = _col(MYTHIC, 0.1); glow = _col(MYTHIC, 0.22)
			emoji = "🎭"; label = "THE BIT"
		"end":
			bd = _col(DANGER); fg = _col("#ff6b88")
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _glow_sb(bg, bd, 5, glow, 6 if glow.a > 0 else 0))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 14)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 9)
	c.add_child(m)
	var h := _hbox(5)
	if emoji != "":
		h.add_child(_emo(emoji, 13))
	h.add_child(_lab(label, f_body, 11, fg, 1.0, true))
	m.add_child(h)
	_attach_click(c, on_press)
	return c


## Makes a styled panel clickable without disturbing its look: a flat, focus-less
## Button is laid over the full rect (added last -> on top). The panel's visuals
## show through; a left click fires `on_press`. The scripted preview driver can
## also call the same handler methods directly — both paths hit apply_command.
func _attach_click(root: Control, on_press: Callable) -> void:
	if not on_press.is_valid():
		return
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(on_press)
	root.add_child(btn)


# ------------------------------------------------------------------------ chyron
func _build_chyron() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#0d0510"), _col(MYTHIC, 0.4), 5))
	var row := _hbox(0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(row)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _sb(_col(MYTHIC, 0.18), _col(MYTHIC, 0.0), 0))
	var bm := MarginContainer.new()
	for s in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + s, 16)
	badge.add_child(bm)
	var brow := _hbox(7)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	bm.add_child(brow)
	brow.add_child(_emo("🦩", 17))
	brow.add_child(_lab("MOMUS", f_body, 12, _col(MYTHIC), 3.0, true))
	row.add_child(badge)
	# Momus commentary line — a static quote until an action fires, then live
	# play-by-play / rejection feedback via _momus() (announcer feed not otherwise wired).
	_chyron_line = _rich_line([
		["\"—and Dario bows ", _col("#e8d0dc"), false],
		["mid-combat", _col("#e8d0dc"), false],
		[", the absolute professional!\"", _col("#e8d0dc"), false],
	], 14)
	_chyron_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lm := MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 18)
	lm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lm.add_child(_chyron_line)
	row.add_child(lm)
	return p


# ----------------------------------------------------------------- rich text util
## A rich label from [text, color, bold] runs. wrap=true word-wraps to the
## container width (fit_content sizes height); wrap=false is a single line.
func _rich_line(runs: Array, fsize: int, wrap := false) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	if wrap:
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", f_body)
	r.add_theme_font_override("bold_font", _bold_font())
	r.add_theme_font_size_override("normal_font_size", fsize)
	r.add_theme_font_size_override("bold_font_size", fsize)
	var bb := ""
	for run in runs:
		var t := String(run[0])
		var c: Color = run[1]
		var b: bool = run[2]
		var seg := "[color=#%s]%s[/color]" % [c.to_html(false), t]
		if b:
			seg = "[b]%s[/b]" % seg
		bb += seg
	r.text = bb
	return r


func _bold_font() -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = f_body
	fv.variation_embolden = 0.6
	return fv


func _hint_line(emoji: String, text: String, color: Color) -> Label:
	var h := _hbox(5)
	h.add_child(_emo(emoji, 10))
	var l := _lab(text, f_body, 10, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return l


# --------------------------------------------------------------- padding helpers
func _pad_top(node: Control, px: int) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", px)
	m.add_child(node)
	return m


func _pad_bottom(node: Control, px: int) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", px)
	m.add_child(node)
	return m


# --------------------------------------------------------------------- data bind
func refresh() -> void:
	if _gc == null:
		return
	_recompute_identity()   # boss id + emoji map (arena + rail agree on who's who)
	_bind_clock()
	_bind_broadcast()
	_bind_turn_order()      # derives the on-the-clock actor + rail (before arena)
	_bind_arena()           # live hex board + tokens + boss mask + objective
	_bind_contestant_panels()


func _bind_clock() -> void:
	var clock: Dictionary = _gc.view_clock()
	if clock.is_empty():
		return
	var tick := int(clock.get("tick", 0))
	var moment := int(clock.get("moment", 0))
	var clock_no := int(tick / 10) + 1
	_clock_num.text = str(clock_no)
	_moment_num.text = "%02d" % moment
	_nextreset.text = "NEXT RESET · CLOCK %d" % (clock_no + 1)


func _bind_broadcast() -> void:
	var bc: Dictionary = _gc.view_broadcast()
	if bc.is_empty():
		return
	var hype: Dictionary = bc.get("hype", {})
	_hype_val.text = str(int(hype.get("meter", 0)))
	_hype_bar.value = clampi(int(hype.get("meter", 0)), 0, 100)
	_hype_band.text = "CROWD: %s" % String(hype.get("band_display", ""))
	# active crowd goal
	var goal: Dictionary = bc.get("goal", {})
	if goal.is_empty():
		_goal_title.text = "NO ACTIVE GOAL"
		_goal_pay.text = "—"
		_goal_time.text = "—"
	else:
		_goal_title.text = String(goal.get("name", "")).to_upper()
		_goal_pay.text = "+%d HYPE" % int(goal.get("payout", 0))
		var cl := int(goal.get("clocks_left", 0))
		_goal_time.text = "%d CLOCK%s" % [cl, "" if cl == 1 else "S"]
		# description is presentation copy keyed off goal.kind (view API carries no blurb)
		_goal_desc.text = _goal_blurb(String(goal.get("kind", "")))
	# spotlight / camera-call card (empty = available, set = active on a target)
	var spot: Dictionary = bc.get("spotlight", {})
	if _spot_title != null and _spot_sub != null:
		if spot.is_empty():
			_spot_title.text = "CAMERA CALL"
			_spot_sub.text = "CHARM-GATED · AVAILABLE · DOUBLES GAINS & LOSSES"
		else:
			_spot_title.text = "SPOTLIGHT · %s" % _display_name_for(String(spot.get("target", "")))
			_spot_sub.text = "ACTIVE · %d CLOCK%s LEFT · SWINGS DOUBLED" % [
				int(spot.get("clocks_left", 0)),
				"" if int(spot.get("clocks_left", 0)) == 1 else "S"]


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


## The bottom contestant PANELS (6-part HP grid / conditions / shock). The arena
## tokens + boss mask + objective are bound separately in _bind_arena().
func _bind_contestant_panels() -> void:
	for cd in _gc.view_combatants():
		var c: Dictionary = cd
		var id := String(c.get("id", ""))
		if _cref.has(id):
			_bind_contestant(id, c)


func _bind_contestant(id: String, c: Dictionary) -> void:
	var ref: Dictionary = _cref[id]
	# index parts by key
	var by_key := {}
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		by_key[String(p.get("key", ""))] = p
	for key in PART_ORDER:
		if not (ref["parts"] as Dictionary).has(key):
			continue
		var cellref: Dictionary = ref["parts"][key]
		var val: Label = cellref["val"]
		var bar: ProgressBar = cellref["bar"]
		if by_key.has(key):
			var p: Dictionary = by_key[key]
			var hp := int(p.get("hp", 0))
			var mx := maxi(1, int(p.get("max_hp", 1)))
			val.text = "%d/%d" % [hp, mx]
			var ratio := float(hp) / float(mx)
			var ramp := _ramp(ratio)
			val.add_theme_color_override("font_color", ramp)
			val.add_theme_color_override("font_outline_color", ramp)
			bar.max_value = mx
			bar.value = hp
			bar.add_theme_stylebox_override("fill", _sb(ramp, ramp, 2, 0))
		else:
			val.text = "—"
	# conditions + shock
	var condbox: HBoxContainer = ref["condbox"]
	for ch in condbox.get_children():
		ch.queue_free()
	var conds := _gather_conditions(c)
	for cond in conds:
		condbox.add_child(_cond_chip(String(cond[0]), int(cond[1])))
	var shock: Label = ref["shock"]
	shock.text = "SHOCK %d" % int(c.get("shock", 0))


func _ramp(ratio: float) -> Color:
	if ratio >= 1.0:
		return _col(SUCCESS)
	if ratio > 0.5:
		return _col(GOLD)
	return _col(DANGER)


func _gather_conditions(c: Dictionary) -> Array:
	# collect the highest tier per condition id across all parts
	var best := {}
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		var conds: Dictionary = p.get("conditions", {})
		for cid in conds:
			best[String(cid)] = maxi(int(best.get(String(cid), 0)), int(conds[cid]))
	var out := []
	var keys := best.keys()
	keys.sort()
	for k in keys:
		out.append([String(k), int(best[k])])
	return out


func _cond_chip(cond_id: String, tier: int) -> Control:
	var emoji := "🩸"
	var color := _col("#ff6b88")
	var bg := _col(DANGER, 0.12)
	var bd := _col(DANGER, 0.5)
	match cond_id:
		"burn": emoji = "🔥"; color = _col("#ff9a5a"); bg = _col(FIRE, 0.14); bd = _col(FIRE, 0.55)
		"poison": emoji = "🧪"; color = _col(SUCCESS); bg = _col(SUCCESS, 0.1); bd = _col(SUCCESS, 0.45)
		"chilled": emoji = "❄"; color = _col(CYAN); bg = _col(CYAN, 0.12); bd = _col(CYAN, 0.5)
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _sb(bg, bd, 12))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 3)
	c.add_child(m)
	var h := _hbox(4)
	h.add_child(_emo(emoji, 10))
	h.add_child(_lab("%s T%d" % [cond_id.to_upper(), tier], f_body, 9, color, 1.0, true))
	m.add_child(h)
	return c
