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
	var haz := UI.lab("🔥 FIRE HEALS IT — stop feeding the flame", UI.body(), 9, UI.col("#8a6a4a"), 1.5)
	haz.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	haz.position = Vector2(14, -22)
	haz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(haz)
	var cam := UI.lab("▮ FLAMETHROWER WINDUP DETECTED — CONE TELEGRAPHED", UI.body(), 9, UI.col(UI.TEXT, 0.42), 2.0)
	cam.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	cam.position = Vector2(14, -38)
	cam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cam)

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
##        boss_cond_line: String, status_pips: {id -> Array[Color]}}
func update(data: Dictionary) -> void:
	_ensure_built()
	_combatants = data.get("combatants", [])
	_boss_id = String(data.get("boss_id", ""))
	_active_id = String(data.get("active_id", ""))
	_emoji = data.get("emoji", {})
	_pips = data.get("status_pips", {})
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
	_sync_tokens()
	_layout()


func set_move_mode(on: bool) -> void:
	_ensure_built()
	_move_mode = on
	_click_catcher.mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	_layout()  # repaint the reachable-hex highlight


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
	var cone := _cone_spec(coords)
	var reach: Array = _reachable_hexes() if _move_mode else []
	_arena_floor.configure(eff, off, _qr, _rr, coords, reach,
		bool(cone["on"]), cone["origin"], cone["dir"])


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
	var allowance := 3
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


## Decorative telegraph: a cone off the boss hex toward the party centroid.
func _cone_spec(coords: Array) -> Dictionary:
	if _boss_id == "":
		return {"on": false, "origin": Vector2.ZERO, "dir": Vector2.RIGHT}
	var boss := _find(_boss_id)
	if boss.is_empty():
		return {"on": false, "origin": Vector2.ZERO, "dir": Vector2.RIGHT}
	var bhex := _axial_of(boss)
	var boss_px: Vector2 = _fr().axial_to_pixel(bhex.x, bhex.y, eff) + off
	var centroid := Vector2.ZERO
	var n := 0
	for cd in _combatants:
		var c: Dictionary = cd
		if String(c.get("id", "")) == _boss_id:
			continue
		var h := _axial_of(c)
		centroid += _fr().axial_to_pixel(h.x, h.y, eff) + off
		n += 1
	if n == 0:
		return {"on": false, "origin": boss_px, "dir": Vector2.DOWN}
	centroid /= float(n)
	var dir := centroid - boss_px
	if dir.length() < 1.0:
		dir = Vector2.DOWN
	return {"on": true, "origin": boss_px, "dir": dir}


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

	# tags above (boss PHASE / NETWORK — network masked until breach)
	if is_boss:
		var trow := UI.hbox(5)
		trow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trow.add_child(_unit_tag("PHASE 1" if not breached else "PHASE 2", "phase"))
		trow.add_child(_unit_tag(
			"NETWORK 🔒 HIDDEN" if _network_hidden(c) else "NETWORK ⚡ EXPOSED", "net"))
		root.add_child(trow)
		_pin_row(trow, -disc * 0.5 - 8.0, true)

	# name plate below the disc
	var np := PanelContainer.new()
	np.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.BG, 0.85), Color(name_col.r, name_col.g, name_col.b, 0.4), 3))
	np.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var npm := UI.margin(8, 8, 2, 2)
	np.add_child(npm)
	npm.add_child(UI.lab(String(c.get("name", id)).to_upper(), UI.body(), 10, name_col, 1.5, true))
	root.add_child(np)
	_pin_row(np, disc * 0.5 + 6.0, false)

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
		_pin_row(hp, disc * 0.5 + 26.0, false)

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
		_pin_row(prow, disc * 0.5 + 34.0, false)


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
