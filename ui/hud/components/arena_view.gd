extends Control
## ArenaView — the DOMINANT center game-world panel (spec §2): the live hex board
## (ArenaFloor), unit tokens at their live axial positions, boss network masking,
## the decorative flamethrower-cone hazard tint, MOVE click-to-target, and the
## broadcast overlay lines (objective / hazard read / boss conditions).
##
## PRESENTATION ONLY, dumb by contract: receives plain view data via update()
## (the facade does every meaning join — boss id, emoji, masking strings, status
## pip colours) and reports input back out through signals. Never reads the
## controller or sim. The board transform (eff/off) is computed here exactly as
## the v1 HUD did, so FieldRenderer.axial_to_pixel(q, r, eff) + off maps hex ->
## local pixel for tokens, floor and click-targeting alike.
##
## SMOOTH MOTION (status/motion pass): token nodes are PERSISTENT, keyed by
## combatant id — created on first sight (snap, no tween), removed when the id
## leaves the view, and TWEENED (~0.3s, eased) whenever their on-screen target
## moves. Purely presentational: the sim position is already final when it is
## read; the glide never delays or reorders anything, and a mid-tween removal
## kills the tween before freeing the node. Token CONTENT (disc, plates, pips)
## is rebuilt in place each update, so state changes stay live while the
## wrapper's position animates independently.

signal click_input(event: InputEvent)   ## raw gui_input from the MOVE click catcher
signal token_clicked(id: String)        ## a unit token was clicked (focus/inspect)

const UI := preload("res://ui/hud/components/hud_theme.gd")
const ArenaFloorScript := preload("res://ui/hud/arena_floor.gd")

# field_renderer.gd carries the reusable, unit-tested hex math. LOADED AT RUNTIME
# rather than preloaded: its _ready() references the `Game` autoload, and
# preloading forces that to resolve during compile (before the autoload is live
# in the render/test harnesses). Same pattern as the v1 HUD.
var _field_renderer: GDScript


func _fr() -> GDScript:
	if _field_renderer == null:
		_field_renderer = load("res://scenes/field/field_renderer.gd") as GDScript
	return _field_renderer


# ---- live board transform (read by the facade for the compatibility surface) ----
var eff := 40.0                  # current on-screen hex size
var off := Vector2.ZERO          # current board offset (local px)
var _qr := Vector2i(-2, 3)
var _rr := Vector2i(-2, 3)

# ---- current draw state (set via update()/set_move_mode()) ----
var _combatants: Array = []      # cached view rows for re-layout on resize
var _boss_id := ""
var _active_id := ""
var _emoji := {}                 # id -> token emoji (facade-computed)
var _pips := {}                  # id -> Array[Color] status pips (facade-computed)
var _move_mode := false
## MOVE's walking allowance (PLACEHOLDER R14 — the v1 highlight radius).
const MOVE_ALLOWANCE := 3
## Radius the click-to-target highlight is painted at: MOVE_ALLOWANCE for a
## walk, the calling skill's own reach for a pick (see set_pick_mode).
var _pick_radius := MOVE_ALLOWANCE

## R34 board surfaces (decision #36) — all facade-computed, this node only
## paints them. See update()'s contract for the exact dict shapes.
var _intents := {}               # id -> intent chip spec (enemies only)
var _vision := {}                # id -> {seen_label, seen, hexes, note}
var _attack_cones: Array = []    # [{hexes: Array[Vector2i]}] declared area arcs

## Token PLATES (name, intent chip, eye chip, boss tags) draw above every disc:
## on a tight board the tokens overlap, and a readout clipped by a neighbour's
## disc is a readout the player does not get — which for the R34 intent/eye
## chips would defeat the ruling.
const LABEL_Z := 3

## Position-glide spec: one eased tween per moving token (see SMOOTH MOTION above).
const MOVE_TWEEN_SEC := 0.3
const MAX_PIPS := 6

var _built := false
var _arena_floor  # ArenaFloor (untyped: its configure() is script-defined)
var _token_layer: Control
var _click_catcher: Control
var _boss_cond: Label
var _obj_text: Label
var _obj_status: Label
var _legend: Control          # R34 on-board cone-reading legend (frame 1)
var _mode_chip: Control       # exploration mode banner (frame 4)
var _mode_lab: Label
var _haz_lab: Label
var _cam_lab: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_arena_floor = ArenaFloorScript.new()
	_arena_floor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_arena_floor)

	var vig := TextureRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.texture = _vignette_tex()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	_token_layer = Control.new()
	_token_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_token_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_token_layer)

	# broadcast overlay marks (kept from v1 — the show frames the battlefield)
	var fl := UI.lab("◉ FEED 01 · ARENA CAM", UI.body(), 9, UI.col(UI.CYAN, 0.55), 2.0)
	fl.position = Vector2(14, 12)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fl)
	var fr_lab := UI.lab("● REC", UI.body(), 9, UI.col(UI.DANGER, 0.65), 2.0)
	fr_lab.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fr_lab.position = Vector2(-70, 12)
	fr_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fr_lab)

	# objective chip — top-center overlay, bound via update() (view_encounter)
	var objv := UI.vbox(1)
	objv.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	objv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objv.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_obj_text = UI.lab("", UI.body(), 10, UI.col(UI.TEXT, 0.8), 1.5, true)
	_obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objv.add_child(_obj_text)
	_obj_status = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 1.5)
	_obj_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objv.add_child(_obj_status)
	objv.position.y = 10
	add_child(objv)

	# hazard read (PLACEHOLDER copy, as in v1 — no sim hazard model yet)
	_haz_lab = UI.lab("🔥 FIRE HEALS IT — stop feeding the flame", UI.body(), 9, UI.col("#8a6a4a"), 1.5)
	_haz_lab.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_haz_lab.position = Vector2(14, -22)
	_haz_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_haz_lab)
	# The cone-telegraph line is now BOUND (R34): it names the live declared
	# area arc the floor is drawing, and hides when nothing is telegraphed —
	# the v1 always-on placeholder claimed a windup that might not exist.
	_cam_lab = UI.lab("", UI.body(), 9, UI.col(UI.TEXT, 0.42), 2.0)
	_cam_lab.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_cam_lab.position = Vector2(14, -38)
	_cam_lab.visible = false
	_cam_lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cam_lab)

	# R34 CONE-READING LEGEND (frame 1, decision 5 amendment): the board is now
	# the hidden/revealed readout, so it ships its own key. Shown only while an
	# eyeline or an attack cone is actually on screen.
	_legend = _build_legend()
	_legend.position = Vector2(16, 44)
	_legend.visible = false
	add_child(_legend)

	# Exploration banner (frame 4, Mode A): "<ROOM> — CLEAR" + the free-movement
	# read. Bound via update(); hidden in combat.
	_mode_chip = PanelContainer.new()
	_mode_chip.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.SUCCESS, 0.10), UI.col(UI.SUCCESS, 0.55), 4))
	_mode_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_chip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_mode_chip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_mode_chip.position.y = 34
	var mm := UI.margin(12, 12, 3, 3)
	_mode_chip.add_child(mm)
	_mode_lab = UI.lab("", UI.body(), 10, UI.col(UI.SUCCESS), 2.0, true)
	mm.add_child(_mode_lab)
	_mode_chip.visible = false
	add_child(_mode_chip)

	# live boss-condition readout (bleeding etc.) — bound via update()
	_boss_cond = UI.lab("", UI.body(), 11, UI.col("#ff6b88"), 2.0, true)
	_boss_cond.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_boss_cond.position = Vector2(14, -56)
	_boss_cond.visible = false
	_boss_cond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_boss_cond)

	# click catcher — top overlay, filter-STOP only while MOVE is armed
	_click_catcher = Control.new()
	_click_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_click_catcher.gui_input.connect(func(e: InputEvent) -> void: click_input.emit(e))
	add_child(_click_catcher)

	resized.connect(_layout)


## data: {combatants: Array[Dictionary] (view rows), boss_id, active_id,
##        emoji: {id->glyph}, objective: {text, hidden: bool},
##        boss_cond_line: String, status_pips: {id -> Array[Color]},
##        R34 additions (all facade-computed — this node re-derives nothing):
##        intents: {id -> {glyph, label, kind ("attack"|"aoe"|"buff"|"debuff"|
##                 "unknown"), undodgable: bool, tip: String}} — the per-enemy
##                 INTENT ICON (decision 2). An enemy with no entry gets no
##                 chip at all; an UNREAD enemy gets kind "unknown".
##        vision:  {id -> {seen: bool, label ("UNAWARE"/"HAS DARIO"/...),
##                 hexes: Array[Vector2i], note: String}} — the eye chip + the
##                 eyeline the floor tints (decision 5 amendment).
##        attack_cones: [{hexes: Array[Vector2i], label: String}] — declared
##                 area arcs, hazard-orange and never recoloured.
##        mode_line: String — the exploration banner ("" hides it, i.e. combat).
##        hazard_line: String — the ambient hazard read ("" hides it).
func update(data: Dictionary) -> void:
	_ensure_built()
	_combatants = data.get("combatants", [])
	_boss_id = String(data.get("boss_id", ""))
	_active_id = String(data.get("active_id", ""))
	_emoji = data.get("emoji", {})
	_pips = data.get("status_pips", {})
	_intents = data.get("intents", {})
	_vision = data.get("vision", {})
	_attack_cones = data.get("attack_cones", [])
	var obj: Dictionary = data.get("objective", {})
	_obj_text.text = String(obj.get("text", ""))
	if bool(obj.get("hidden", true)):
		_obj_status.text = "🔒 NETWORK not yet exposed · surface immune until a breach"
		_obj_status.add_theme_color_override("font_color", UI.col(UI.MUTED))
	else:
		_obj_status.text = "⚡ NETWORK EXPOSED · Phase 2 is in reach — pour in"
		_obj_status.add_theme_color_override("font_color", UI.col(UI.CYAN))
	var cond_line := String(data.get("boss_cond_line", ""))
	_boss_cond.text = cond_line
	_boss_cond.visible = cond_line != ""
	if data.has("hazard_line"):
		var hazard := String(data.get("hazard_line", ""))
		_haz_lab.text = hazard
		_haz_lab.visible = hazard != ""
	var mode_line := String(data.get("mode_line", ""))
	_mode_lab.text = mode_line
	_mode_chip.visible = mode_line != ""
	# The telegraph line names the live declared arc (R34: what is drawn is
	# what will land) — and says nothing when nothing is committed.
	var cone_labels: Array = []
	for entry: Variant in _attack_cones:
		var label := String((entry as Dictionary).get("label", ""))
		if label != "":
			cone_labels.append(label)
	_cam_lab.text = ("▮ " + " · ".join(PackedStringArray(cone_labels))) if not cone_labels.is_empty() else ""
	_cam_lab.visible = not cone_labels.is_empty()
	# The legend earns its space only while the board is actually using it.
	_legend.visible = not _attack_cones.is_empty() or _has_eyeline()
	_sync_tokens()
	_layout()


## True while any observer projects a non-empty eyeline (an enemy with sight
## range 0 — every seeded enemy today, none of which authors a `mind` trait —
## projects none, and the legend honestly stays away).
func _has_eyeline() -> bool:
	for id: Variant in _vision:
		if not (_vision[id] as Dictionary).get("hexes", []).is_empty():
			return true
	return false


## The R34 cone-reading key (frame 1): three rows, one per cone meaning.
func _build_legend() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.BG, 0.82), UI.col(UI.BORDER), 7))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UI.margin(11, 11, 9, 9)
	p.add_child(m)
	var v := UI.vbox(5)
	m.add_child(v)
	v.add_child(UI.lab("CONE READING", UI.body(), 9, UI.col(UI.MUTED), 3.0, true))
	v.add_child(_legend_row(UI.col("#96aacd"), "VISION · UNAWARE", "nobody spotted — you are hidden"))
	v.add_child(_legend_row(UI.col(UI.DANGER), "VISION · HAS SOMEONE", "it sees a contestant — you are revealed"))
	v.add_child(_legend_row(UI.col(UI.FIRE), "ATTACK CONE", "what the blow will cover"))
	return p


func _legend_row(tint: Color, label: String, note: String) -> Control:
	var h := UI.hbox(8)
	var sw := Panel.new()
	sw.custom_minimum_size = Vector2(20, 12)
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.add_theme_stylebox_override("panel",
		UI.sb(Color(tint.r, tint.g, tint.b, 0.18), Color(tint.r, tint.g, tint.b, 0.7), 2))
	h.add_child(sw)
	var l := UI.lab(label, UI.body(), 8, UI.col(UI.TEXT), 1.5, true)
	l.custom_minimum_size = Vector2(150, 0)
	h.add_child(l)
	h.add_child(UI.lab(note, UI.body(), 8, UI.col(UI.MUTED), 0.5))
	return h


func set_move_mode(on: bool) -> void:
	_ensure_built()
	_pick_radius = MOVE_ALLOWANCE
	_move_mode = on
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	_layout()  # repaint the reachable-hex highlight


## KAN-6 phase 2 — the same click-to-target board at an EXPLICIT radius, for a
## pick that is not a walk. The voicebox throw is the first caller: R35 waived
## the throw's cost, never its range, so the highlight must be the skill's own
## authored throw_range rather than MOVE's walking allowance. Identical
## machinery otherwise (same catcher, same highlight, same pixel_to_hex), so
## `move_mode()` keeps reading true while a pick is armed and every existing
## probe behaves as it did.
func set_pick_mode(on: bool, radius: int) -> void:
	_ensure_built()
	_pick_radius = maxi(1, radius) if on else MOVE_ALLOWANCE
	_move_mode = on
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	_layout()


func move_mode() -> bool:
	return _move_mode


## Local pixel -> axial hex through the live board transform.
func pixel_to_hex(local_pos: Vector2) -> Vector2i:
	return _fr().pixel_to_axial(local_pos - off, eff)


# --------------------------------------------------------------------- tokens
var _tokens_eff := -1.0   # eff the current tokens were built at (discs scale with it)
var _tokens := {}         # id -> persistent wrapper Control (position tweened)
var _token_tweens := {}   # id -> in-flight position Tween


## Reconciles the persistent token set against the current view rows: drop
## wrappers whose combatant left the view (mid-tween removal kills the tween
## first), create a wrapper on first sight (marked fresh -> first placement
## snaps), and rebuild every wrapper's CONTENT in place at the current eff.
func _sync_tokens() -> void:
	if _token_layer == null:
		return
	_tokens_eff = eff
	var live := {}
	for cd in _combatants:
		live[String((cd as Dictionary).get("id", ""))] = true
	for id in _tokens.keys():
		if not live.has(id):
			_drop_token(String(id))
	for cd in _combatants:
		var c: Dictionary = cd
		var id := String(c.get("id", ""))
		var wrapper: Control = _tokens.get(id)
		if wrapper == null:
			wrapper = Control.new()
			wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			wrapper.set_meta("fresh", true)
			_token_layer.add_child(wrapper)
			_tokens[id] = wrapper
		for ch in wrapper.get_children():
			ch.queue_free()
		_build_token_content(wrapper, c, id == _boss_id)
		wrapper.set_meta("axial", _axial_of(c))


## Removes one persistent token (its combatant left the view). The tween dies
## before the node so a mid-glide removal never animates a freed wrapper.
func _drop_token(id: String) -> void:
	_kill_tween(id)
	var wrapper: Control = _tokens.get(id)
	if wrapper != null:
		wrapper.queue_free()
	_tokens.erase(id)


func _kill_tween(id: String) -> void:
	var tw: Tween = _token_tweens.get(id)
	if tw != null and tw.is_valid():
		tw.kill()
	_token_tweens.erase(id)


## Positions every token onto its live hex and reconfigures the floor's draw
## spec, all through one board transform (auto-centred/scaled on occupied hexes).
func _layout() -> void:
	if _token_layer == null or _arena_floor == null:
		return
	var panel := size
	if panel.x < 40.0 or panel.y < 40.0:
		return  # not sized yet; the resized signal calls us again
	var coords: Array = []
	for cd in _combatants:
		coords.append(_axial_of(cd))
	var xf := _transform_for(coords, panel)
	eff = xf["eff"]
	off = xf["off"]
	_qr = Vector2i(xf["qlo"], xf["qhi"])
	_rr = Vector2i(xf["rlo"], xf["rhi"])
	# discs/plates are sized at build time from eff — rebuild when the board
	# scale changed materially (first real layout after a resize)
	if absf(eff - _tokens_eff) > 0.5:
		_sync_tokens()
	for id in _tokens:
		_place_token(String(id), _tokens[id])
	var reach: Array = _reachable_hexes() if _move_mode else []
	var eyelines := _eyeline_specs()
	var cones := _attack_cone_specs()
	# The lattice must reach far enough to hold whatever is tinted on it, or a
	# committed arc paints onto bare background. The BOARD TRANSFORM is left
	# alone on purpose: fitting a 10-hex flamethrower cone into the panel would
	# shrink every token to nothing, and the stage clips, so an arc that runs
	# off the edge simply runs off the edge — as it does in the fiction.
	_grow_lattice(eyelines)
	_grow_lattice(cones)
	_arena_floor.configure(eff, off, _qr, _rr, coords, reach, eyelines, cones)


## Drives one wrapper toward its live hex's screen point. FIRST placement snaps
## (no tween — spawn/rebind never glides in from nowhere); every later target
## change TWEENS from wherever the token currently is, killing any in-flight
## glide first. Same-target refreshes (every sim event re-renders) leave a
## running tween alone so the glide completes instead of restarting.
func _place_token(id: String, wrapper: Control) -> void:
	var a: Vector2i = wrapper.get_meta("axial", Vector2i.ZERO)
	var target: Vector2 = _fr().axial_to_pixel(a.x, a.y, eff) + off
	if bool(wrapper.get_meta("fresh", false)):
		wrapper.set_meta("fresh", false)
		wrapper.set_meta("target_px", target)
		wrapper.position = target
		return
	var prev: Variant = wrapper.get_meta("target_px", null)
	if prev != null and (prev as Vector2).distance_to(target) < 0.5:
		return
	wrapper.set_meta("target_px", target)
	_kill_tween(id)
	if wrapper.position.distance_to(target) < 0.5:
		wrapper.position = target
		return
	var tw := wrapper.create_tween()
	tw.tween_property(wrapper, "position", target, MOVE_TWEEN_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_token_tweens[id] = tw


## Board transform: hex size + offset fitting the occupied hexes (plus a margin
## ring) inside the panel. Identical math to the v1 HUD.
func _transform_for(coords: Array, panel: Vector2) -> Dictionary:
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
	var pmin := Vector2(INF, INF)
	var pmax := Vector2(-INF, -INF)
	for r: int in range(rlo, rhi + 1):
		for q: int in range(qlo, qhi + 1):
			var pp: Vector2 = _fr().axial_to_pixel(q, r, 1.0)
			pmin.x = minf(pmin.x, pp.x); pmin.y = minf(pmin.y, pp.y)
			pmax.x = maxf(pmax.x, pp.x); pmax.y = maxf(pmax.y, pp.y)
	pmin -= Vector2.ONE
	pmax += Vector2.ONE
	var bw := maxf(0.001, pmax.x - pmin.x)
	var bh := maxf(0.001, pmax.y - pmin.y)
	var padf := 0.82
	var scale := minf(panel.x * padf / bw, panel.y * padf / bh)
	var e := clampf(scale, 20.0, 70.0)
	var center_nom := (pmin + pmax) * 0.5
	return {"eff": e, "off": panel * 0.5 - center_nom * e,
		"qlo": qlo, "qhi": qhi, "rlo": rlo, "rhi": rhi}


## Hexes the active actor can step onto (allowance 3, unoccupied, within range).
## PLACEHOLDER: prone/slowed would cap the allowance at 1, but the view API does
## not surface those statuses — an illegal move is still rejected by the sim.
func _reachable_hexes() -> Array:
	var out: Array = []
	var actor := _find(_active_id)
	if actor.is_empty():
		return out
	var ap := _axial_of(actor)
	var allowance := _pick_radius
	var occ := {}
	for cd in _combatants:
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


## Widens the drawn lattice to contain a tinted hex set, capped so a very deep
## arc cannot turn one repaint into a huge loop (the panel clips long before).
const LATTICE_MAX_SPAN := 26


func _grow_lattice(specs: Array) -> void:
	for raw: Variant in specs:
		for hraw: Variant in (raw as Dictionary).get("hexes", []):
			var h: Vector2i = hraw
			_qr.x = mini(_qr.x, h.x)
			_qr.y = maxi(_qr.y, h.x)
			_rr.x = mini(_rr.x, h.y)
			_rr.y = maxi(_rr.y, h.y)
	_qr.y = mini(_qr.y, _qr.x + LATTICE_MAX_SPAN)
	_rr.y = mini(_rr.y, _rr.x + LATTICE_MAX_SPAN)


## R34 eyelines for the floor: one entry per observer that actually projects a
## watched-hex set, carrying only what the painter needs (the hexes + whether
## the cone is HOT). The `seen` flag is the sim's answer, never this node's.
func _eyeline_specs() -> Array:
	var out: Array = []
	var ids: Array = _vision.keys()
	ids.sort()
	for id: Variant in ids:
		var eye: Dictionary = _vision[id]
		var hexes: Array = eye.get("hexes", [])
		if hexes.is_empty():
			continue
		out.append({"hexes": hexes, "seen": bool(eye.get("seen", false))})
	return out


## R34 attack cones for the floor: the committed arcs, hazard-orange always.
func _attack_cone_specs() -> Array:
	var out: Array = []
	for entry: Variant in _attack_cones:
		var cone: Dictionary = entry
		if not (cone.get("hexes", []) as Array).is_empty():
			out.append({"hexes": cone.get("hexes", [])})
	return out


## Fills a persistent wrapper with one unit token's visuals; the wrapper ORIGIN
## is the disc CENTRE (drop onto a hex's screen point). Boss network stays
## masked (tag + HP) until breached. Clicking the disc focuses the entity in
## the inspector (token_clicked).
func _build_token_content(root: Control, c: Dictionary, is_boss: bool) -> void:
	var id := String(c.get("id", ""))
	var alive := bool(c.get("alive", true))
	var breached := bool(c.get("breached", false))

	var border := UI.col(UI.CYAN, 0.7)
	var name_col := UI.col(UI.CYAN)
	var glow := UI.col(UI.CYAN, 0.3)
	var glow_px := 8
	var disc_bg := "#0c1428"
	var disc := eff * 1.15
	if is_boss:
		border = UI.col(UI.FIRE); name_col = UI.col("#ff9a5a")
		glow = UI.col(UI.FIRE, 0.6); glow_px = 14
		disc_bg = "#3a1206"; disc = eff * 2.05
	elif id == _active_id:
		border = UI.col(UI.GOLD); name_col = UI.col(UI.GOLD)
		glow = UI.col(UI.GOLD, 0.95); glow_px = 22
	if not alive:
		border = UI.col(UI.MUTED); name_col = UI.col(UI.MUTED)
		glow = Color(0, 0, 0, 0)

	var d := Panel.new()
	d.add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col(disc_bg), border, int(disc * 0.18), glow, glow_px if glow.a > 0.0 else 0))
	d.size = Vector2(disc, disc)
	d.position = Vector2(-disc * 0.5, -disc * 0.5)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dc := CenterContainer.new()
	dc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_child(dc)
	dc.add_child(UI.emo(String(_emoji.get(id, "🎪")), int(disc * 0.55)))
	root.add_child(d)
	UI.attach_click(d, func() -> void: token_clicked.emit(id))
	if not alive:
		var x := UI.lab("✕", UI.sym(), int(disc * 0.7), UI.col(UI.DANGER))
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(x)
		_pin_row(x, -disc * 0.5, false)

	# R34 INTENT ICON (decision 2 — the biggest change): every enemy carries the
	# TYPE of action expected next, right on the token. Hovering gives the full
	# explanation; an unread enemy reads UNREAD ❓ rather than a fabricated
	# guess, and an R26 undodgable attack declares ⛔ here from the windup on.
	var intent: Dictionary = _intents.get(id, {})
	var tag_edge := -disc * 0.5 - 8.0
	if not intent.is_empty():
		var chip := _intent_chip(intent)
		chip.z_index = LABEL_Z
		root.add_child(chip)
		_pin_row(chip, tag_edge, true)
		tag_edge -= 26.0

	# tags above (boss PHASE / NETWORK — network masked until breach)
	if is_boss:
		var trow := UI.hbox(5)
		trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trow.add_child(_unit_tag("PHASE 1" if not breached else "PHASE 2", "phase"))
		trow.add_child(_unit_tag(
			"NETWORK 🔒 HIDDEN" if _network_hidden(c) else "NETWORK ⚡ EXPOSED", "net"))
		trow.z_index = LABEL_Z
		root.add_child(trow)
		_pin_row(trow, tag_edge, true)

	# name plate below the disc
	var np := PanelContainer.new()
	np.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.BG, 0.85), Color(name_col.r, name_col.g, name_col.b, 0.4), 3))
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var npm := UI.margin(8, 8, 2, 2)
	np.add_child(npm)
	npm.add_child(UI.lab(String(c.get("name", id)).to_upper(), UI.body(), 10, name_col, 1.5, true))
	np.z_index = LABEL_Z
	root.add_child(np)
	_pin_row(np, disc * 0.5 + 6.0, false)

	# R34 EYE CHIP (decision 5 amendment): the per-enemy 👁 UNAWARE / HAS <name>
	# state, so the hidden/revealed readout survives when cones overlap or are
	# off screen. Only enemies carry one (the facade supplies enemy rows only).
	var below := disc * 0.5 + 30.0
	var eye: Dictionary = _vision.get(id, {})
	if alive and not eye.is_empty():
		var eye_chip := _eye_chip(eye)
		eye_chip.z_index = LABEL_Z
		root.add_child(eye_chip)
		_pin_row(eye_chip, below, false)
		below += 18.0

	# HP sliver (boss: arm pre-breach -> network post-breach; never leaks early)
	var hp_info := _token_hp(c, is_boss, breached)
	if bool(hp_info["show"]):
		var mx := maxi(1, int(hp_info["max"]))
		var hp := ProgressBar.new()
		hp.show_percentage = false
		hp.custom_minimum_size = Vector2(maxf(48.0, disc * 0.95), 5)
		hp.max_value = mx
		hp.value = clampi(int(hp_info["hp"]), 0, mx)
		hp.add_theme_stylebox_override("background", UI.sb(UI.col("#0a0e1c"), UI.col(UI.BORDER), 3))
		var rc := UI.ramp(float(int(hp_info["hp"])) / float(mx))
		hp.add_theme_stylebox_override("fill", UI.sb(rc, rc, 3, 0))
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(hp)
		_pin_row(hp, below, false)
		below += 12.0

	# status pips (status-prominence pass): one coloured dot per active
	# condition / shock / state flag, colours facade-computed in badge order —
	# the board itself shows who is hurt or locked, readable at token scale
	# (dots, never text; capped with a +n overflow count).
	var pips: Array = _pips.get(id, [])
	if alive and not pips.is_empty():
		var prow := UI.hbox(3)
		prow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pip_px := clampf(eff * 0.16, 6.0, 9.0)
		for i in mini(pips.size(), MAX_PIPS):
			var pcol: Color = pips[i]
			var dot := Panel.new()
			dot.custom_minimum_size = Vector2(pip_px, pip_px)
			dot.add_theme_stylebox_override("panel",
				UI.sb(pcol, pcol.darkened(0.3), int(pip_px * 0.5)))
			prow.add_child(dot)
		if pips.size() > MAX_PIPS:
			var more := UI.lab("+%d" % (pips.size() - MAX_PIPS), UI.mono(), 8, UI.col(UI.TEXT), 0.0, true)
			more.mouse_filter = Control.MOUSE_FILTER_IGNORE
			prow.add_child(more)
		root.add_child(prow)
		_pin_row(prow, below, false)


## Keeps an absolutely-positioned token row centred on the token origin.
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


func _find(id: String) -> Dictionary:
	for cd in _combatants:
		if String((cd as Dictionary).get("id", "")) == id:
			return cd
	return {}


## The network part reads hidden=true until the boss is breached (the view masks it).
func _network_hidden(c: Dictionary) -> bool:
	for pd in c.get("parts", []):
		var p: Dictionary = pd
		if String(p.get("key", "")).contains("network"):
			return bool(p.get("hidden", false))
	return not bool(c.get("breached", false))


## Which HP the token sliver shows. Boss: flamethrower arm pre-breach, exposed
## network post-breach. Contestants: aggregate visible HP.
func _token_hp(c: Dictionary, is_boss: bool, breached: bool) -> Dictionary:
	if not bool(c.get("alive", true)):
		return {"show": false}
	var by_key := {}
	for pd in c.get("parts", []):
		by_key[String((pd as Dictionary).get("key", ""))] = pd
	if is_boss:
		var show_key := "network" if breached else "left_hand"
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


## The R34 intent chip: [glyph] [LABEL] (+ ⛔ when the declared attack is
## undodgable). Border colour carries the intent KIND — the Slay-the-Spire
## read at a glance — and the tooltip carries the ruled "full explanation".
## R34 names five buckets (attack · area · buff · debuff · unknown). "other" is
## a documented SIXTH for a declared action that is none of them — a
## reposition, a grapple-shaped commit — because filing a READ declaration
## under "unknown" would lie about it being unread, which is the one thing the
## ruling is most careful about. It reads cyan: informative, not threatening.
const INTENT_COLORS := {
	"attack": UI.DANGER, "aoe": UI.FIRE, "buff": UI.SUCCESS,
	"debuff": UI.PURPLE, "other": UI.CYAN, "unknown": UI.MUTED,
}


func _intent_chip(intent: Dictionary) -> Control:
	var kind := String(intent.get("kind", "unknown"))
	var undodgable := bool(intent.get("undodgable", false))
	var accent := UI.col(String(INTENT_COLORS.get(kind, UI.MUTED)))
	var c := PanelContainer.new()
	# R26: the undodgable declaration is the LOUDEST thing on the chip — a hot
	# border plus a halo, so "you cannot dodge this" is visible from the windup.
	c.add_theme_stylebox_override("panel", UI.glow_sb(
		UI.col(UI.BG, 0.92), Color(accent.r, accent.g, accent.b, 0.95 if undodgable else 0.65),
		5, UI.col(UI.DANGER, 0.55) if undodgable else Color(0, 0, 0, 0), 8 if undodgable else 0))
	c.mouse_filter = Control.MOUSE_FILTER_STOP   # hover = the full explanation
	c.tooltip_text = String(intent.get("tip", ""))
	var m := UI.margin(8, 8, 3, 3)
	c.add_child(m)
	var h := UI.hbox(5)
	m.add_child(h)
	h.add_child(UI.emo(String(intent.get("glyph", "❓")), 13))
	if undodgable:
		h.add_child(UI.lab("⛔", UI.sym(), 12, UI.col(UI.DANGER)))
	h.add_child(UI.lab(String(intent.get("label", "UNREAD")), UI.body(), 8, accent, 1.5, true))
	return c


## The R34 eye chip: 👁 UNAWARE (muted) / 👁 HAS <NAME> (danger).
func _eye_chip(eye: Dictionary) -> Control:
	var seen := bool(eye.get("seen", false))
	var accent := UI.col(UI.DANGER) if seen else UI.col(UI.MUTED)
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.BG, 0.9), Color(accent.r, accent.g, accent.b, 0.75), 3))
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.tooltip_text = String(eye.get("note", ""))
	var m := UI.margin(6, 6, 1, 1)
	c.add_child(m)
	var h := UI.hbox(4)
	m.add_child(h)
	h.add_child(UI.emo("👁", 9))
	h.add_child(UI.lab(String(eye.get("label", "UNAWARE")), UI.body(), 7, accent, 1.5, true))
	return c


func _unit_tag(text: String, kind: String) -> Control:
	var bg := UI.col(UI.CYAN, 0.12)
	var bd := UI.col(UI.CYAN, 0.5)
	var fg := UI.col(UI.CYAN)
	if kind == "phase":
		bg = UI.col(UI.FIRE, 0.16); bd = UI.col(UI.FIRE, 0.6); fg = UI.col("#ff9a5a")
	elif kind == "net":
		bg = UI.col(UI.PURPLE, 0.14); bd = UI.col(UI.PURPLE, 0.6); fg = UI.col(UI.PURPLE)
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", UI.sb(bg, bd, 3))
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UI.margin(6, 6, 2, 2)
	c.add_child(m)
	m.add_child(UI.lab(text, UI.body(), 8, fg, 1.0, true))
	return c


func _vignette_tex() -> GradientTexture2D:
	var g := Gradient.new()
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
