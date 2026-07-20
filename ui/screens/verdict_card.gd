extends Control
## VerdictCard — the demo-slice END-OF-RUN "Verdict" card (KAN-7 mockup gate).
##
## PRESENTATION ONLY. This scene never imports or touches `simulation/` classes.
## It reads the FINAL combat state exclusively through the GameController VIEW API
## (view_verdict) and authors NO sim state. "A VERDICT — NOT A VICTORY SCREEN"
## (DIRECTION.md ethos): the card frames the run as a judgement of spectacle, not
## a win screen — the show's thesis ("how much can we break your essence down in
## the name of entertainment?") answered against what actually happened.
##
## Visual identity: docs/ux-designs/demo-slice-2026-07-19/DESIGN.md (the sister
## char-sheet palette, extended) — matched to ui/hud/combat_hud.gd's established
## style (same fonts, styleboxes, neon-accent discipline). Layout blueprint:
## .working/key-verdict-card.html. Every NUMBER is PLACEHOLDER (R14) — watermark.
##
## Data-bound (live from view_verdict): outcome (SURVIVED/DIED) · contestant name ·
## hype_earned + peak_band · epithet (from a held slice-tag) · crowd_verdict +
## band-derived stars · boss breached/phase · slice_win. PLACEHOLDER-flagged in the
## view: patron_standing (no favor ledger) · tagline · the spine verdict-answer +
## viewer count + REC timer + "NEXT" chyron (broadcast dressing, no view field).

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

var _gc = null              # GameController (untyped: the `Game` autoload script)
var _cid: String = "imani"  # which contestant this card judges
var _verdict: Dictionary = {}
var _built := false

# fonts
var f_body: Font
var f_mono: Font
var f_emoji: Font
var f_sym: Font


func _ready() -> void:
	# Standalone entry (run loop: change_scene_to_file from combat): self-bind to the
	# Game autoload so the card reads the PERSISTED final combat state (Game survives
	# the scene change). A preview/render driver that already called bind() has set
	# _gc, so this branch is skipped and we just finish building. Mirrors bid_screen's
	# self-bind pattern.
	if _gc == null:
		var g := get_node_or_null("/root/Game")
		if g != null:
			bind(g, _cid)
			return
	_ensure_built()


## Build lazily on whichever call comes first (a preview driver may bind() before
## _ready() runs). Idempotent.
func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_init_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1600, 1000)
	_build()


# ------------------------------------------------------------------ public API
## Bind to a live GameController and render the final verdict for `contestant_id`.
## Rebuilds the card from view_verdict() — the card is a one-shot end-of-run frame,
## so it re-reads on bind rather than tracking the command stream.
func bind(game, contestant_id: String = "imani") -> void:
	_gc = game
	_cid = contestant_id
	if _gc != null:
		_verdict = _gc.view_verdict(contestant_id)
	if _built:
		# already built with stale/empty data — rebuild the tree from the new verdict
		for ch in get_children():
			ch.queue_free()
		_built = false
	_ensure_built()


# ------------------------------------------------------------- verdict accessors
func _v() -> Dictionary:
	return _verdict

func _outcome() -> String:
	return String(_v().get("outcome", "SURVIVED"))

func _survived() -> bool:
	return _outcome() == "SURVIVED"

func _contestant() -> String:
	return String(_v().get("contestant", "Imani \"The Door\""))

func _epithet() -> Dictionary:
	return _v().get("epithet", {"name": "THE UNBROKEN", "note": "essence held · zero shock tiers taken"})

func _crowd() -> Dictionary:
	return _v().get("crowd_verdict", {"name": "FAN FAVORITE", "stars": 4})

func _patron() -> Dictionary:
	return _v().get("patron_standing", {"name": "HESTIA", "state": "PLEASED", "note": "+ BLESSING banked for next run"})

func _boss() -> Dictionary:
	return _v().get("boss", {"name": "Incinedile", "breached": true, "phase": 2, "note": "network exposed"})


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
## weight with a same-colour outline (the fallback font ships no bold face).
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


## Emoji glyph label (color emoji via Noto Color Emoji — carries its own colour).
func _emo(glyph: String, px: int) -> Label:
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_override("font", f_emoji)
	l.add_theme_font_size_override("font_size", px)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Title/value label with a soft neon halo (glow is rare + load-bearing — accents
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


func _expand_spacer(weight := 1.0) -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_stretch_ratio = weight
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _fixed_y(node: Control, h: int) -> Control:
	node.custom_minimum_size.y = h
	node.size_flags_vertical = Control.SIZE_FILL
	return node


func _pad_top(node: Control, px: int) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", px)
	m.add_child(node)
	return m


# ----------------------------------------------------------------- rich text util
## A rich label from [text, color, bold] runs. wrap=true word-wraps to the
## container width; wrap=false is a single line. center=true centres the text.
func _rich_line(runs: Array, fsize: int, wrap := false, center := false, italic := false) -> RichTextLabel:
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
	r.add_theme_font_override("italics_font", f_body)
	r.add_theme_font_size_override("normal_font_size", fsize)
	r.add_theme_font_size_override("bold_font_size", fsize)
	r.add_theme_font_size_override("italics_font_size", fsize)
	var bb := ""
	if center:
		bb += "[center]"
	for run in runs:
		var t := String(run[0])
		var c: Color = run[1]
		var b: bool = run[2]
		var seg := "[color=#%s]%s[/color]" % [c.to_html(false), t]
		if b:
			seg = "[b]%s[/b]" % seg
		if italic:
			seg = "[i]%s[/i]" % seg
		bb += seg
	if center:
		bb += "[/center]"
	r.text = bb
	return r


func _bold_font() -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = f_body
	fv.variation_embolden = 0.6
	return fv


func _radial_tex(inner: Color, alpha: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(inner.r, inner.g, inner.b, alpha))
	g.set_color(1, Color(inner.r, inner.g, inner.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.34)
	gt.fill_to = Vector2(1.05, 0.95)
	gt.width = 512
	gt.height = 320
	return gt


# ---------------------------------------------------------------- build the tree
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = _col(BG)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_m := MarginContainer.new()
	root_m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_m.add_theme_constant_override("margin_left", 14)
	root_m.add_theme_constant_override("margin_right", 14)
	root_m.add_theme_constant_override("margin_top", 10)
	root_m.add_theme_constant_override("margin_bottom", 12)
	add_child(root_m)

	var col := _vbox(12)
	root_m.add_child(col)

	col.add_child(_fixed_y(_build_broadcast(), 48))
	col.add_child(_expand(_build_body()))
	col.add_child(_fixed_y(_build_chyron(), 52))

	# R14 watermark — faint, bottom-right, on every screen while numbers are placeholder.
	var wm := _lab("PLACEHOLDER NUMBERS · R14", f_body, 10, _col(TEXT, 0.16), 3.0, true)
	wm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	wm.position = Vector2(-252, -24)
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wm)


func _expand(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


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

	# left: LIVE pill + RUN COMPLETE · THE VERDICT · REC
	var left := _hbox(14)
	left.alignment = BoxContainer.ALIGNMENT_BEGIN
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	lrow.add_child(_live_dot())
	lrow.add_child(_lab("LIVE", f_body, 12, _col("#ff6b88"), 2.0, true))
	left.add_child(live)
	var rec := _rich_line([
		["RUN COMPLETE · ", _col(MUTED), false],
		["THE VERDICT", _col(TEXT), true],
		["  ·  REC 00:23:48", _col(MUTED), false],  # PLACEHOLDER: REC timer not in view API
	], 13)
	rec.add_theme_font_override("normal_font", f_mono)
	rec.add_theme_font_override("bold_font", f_mono)
	rec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_child(rec)
	row.add_child(left)

	# center: brand
	var center := _vbox(0)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := _glow("GALACTIC  PRIME  TIME", f_body, 20, _col(CYAN), 6.0, 9.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	row.add_child(center)

	# right: viewer count (PLACEHOLDER — not in view API)
	var right := _hbox(8)
	right.alignment = BoxContainer.ALIGNMENT_END
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(_emo("👁", 15))
	right.add_child(_lab("6,880,204", f_mono, 14, _col(TEXT), 1.0))
	right.add_child(_lab("WATCHED LIVE", f_body, 9, _col(MUTED), 2.0))
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


# ------------------------------------------------------------------- verdict body
func _build_body() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#080b18"), _col(BORDER), 8))
	p.clip_contents = true

	var stack := Control.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(stack)

	# radial "stage light" glow behind the verdict (gold+cyan halo, mockup .halo/.rays)
	var halo := TextureRect.new()
	halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	halo.texture = _radial_tex(_col("#1a2140"), 0.55)
	halo.stretch_mode = TextureRect.STRETCH_SCALE
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(halo)
	var goldhalo := TextureRect.new()
	goldhalo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	goldhalo.texture = _radial_tex(_col(GOLD), 0.10)
	goldhalo.stretch_mode = TextureRect.STRETCH_SCALE
	goldhalo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(goldhalo)

	# corner chips — a top row pinned full-width (win chip left, VIP table right)
	var chip_m := MarginContainer.new()
	chip_m.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	for s in ["left", "right"]:
		chip_m.add_theme_constant_override("margin_" + s, 16)
	chip_m.add_theme_constant_override("margin_top", 14)
	chip_m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(chip_m)
	var chip_row := _hbox(0)
	chip_m.add_child(chip_row)
	if bool(_boss().get("breached", false)) or bool(_v().get("slice_win", false)):
		var win := _corner_chip("◆ SLICE WIN · PHASE %d REACHED" % int(_boss().get("phase", 2)),
			_col(SUCCESS), _col(SUCCESS, 0.08), _col(SUCCESS, 0.4))
		win.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		chip_row.add_child(win)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(gap)
	var rank := _corner_chip("VIP TABLE — THE INCINERATOR", _col(GOLD), _col(GOLD, 0.08), _col(GOLD, 0.4))
	rank.size_flags_horizontal = Control.SIZE_SHRINK_END
	chip_row.add_child(rank)

	# content column: stage (upper) + earned cards (lower)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 40)
	m.add_theme_constant_override("margin_top", 58)
	m.add_theme_constant_override("margin_bottom", 30)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(m)

	var colv := _vbox(0)
	m.add_child(colv)
	colv.add_child(_expand_spacer(1.15))
	colv.add_child(_build_stage())
	colv.add_child(_expand_spacer(1.0))
	colv.add_child(_build_earned_row())
	colv.add_child(_expand_spacer(0.28))

	return p


func _corner_chip(text: String, fg: Color, bg: Color, border: Color) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _sb(bg, border, 4))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 11)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 5)
	chip.add_child(m)
	m.add_child(_lab(text, f_body, 9, fg, 3.0, true))
	return chip


# ------- the centre stage: kicker / name / verdict verb / tagline / spine -------
func _build_stage() -> Control:
	var v := _vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER

	# kicker — "A VERDICT — NOT A VICTORY SCREEN"
	var kicker := _rich_line([
		["A ", _col(MUTED), false],
		["VERDICT", _col(DANGER), true],
		[" — NOT A VICTORY SCREEN", _col(MUTED), false],
	], 12, false, true)
	kicker.add_theme_font_override("normal_font", _tracked(f_body, 6.0))
	kicker.add_theme_font_override("bold_font", _tracked(_bold_font(), 6.0))
	v.add_child(kicker)

	# contestant name (cyan glow)
	var name_lbl := _glow(_contestant().to_upper(), f_body, 40, _col(CYAN), 5.0, 12.0)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_pad_top(name_lbl, 14))

	# the verdict verb — SURVIVED (gold) / DIED (danger), huge
	var verb_col := _col(GOLD) if _survived() else _col(DANGER)
	var verb := _glow(_outcome(), f_body, 74, verb_col, 6.0, 16.0)
	verb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_pad_top(verb, 2))

	# tagline (patron-line)
	var tagline := String(_v().get("tagline", "CARRIED THREE OUT · BURNED FOR NONE · THE DOOR HELD"))
	var tl := _lab(tagline, f_body, 11, _col(MUTED), 3.0, true)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_pad_top(tl, 12))

	# spine — the show's thesis question + the verdict-answer (framed by hairlines)
	v.add_child(_pad_top(_build_spine(), 22))
	return v


func _build_spine() -> Control:
	var holder := CenterContainer.new()
	var box := _vbox(0)
	box.custom_minimum_size.x = 920
	holder.add_child(box)

	box.add_child(_hairline())
	var inner := _vbox(0)
	var im := MarginContainer.new()
	for s in ["top", "bottom"]:
		im.add_theme_constant_override("margin_" + s, 15)
	im.add_child(inner)
	box.add_child(im)

	# the question (italic; the mythic-highlighted thesis)
	var q := _rich_line([
		["HOW MUCH CAN WE ", _col(TEXT), false],
		["BREAK YOUR ESSENCE DOWN", _col(MYTHIC), true],
		[" IN THE NAME OF ENTERTAINMENT?", _col(TEXT), false],
	], 13, true, true, true)
	inner.add_child(q)

	# the verdict-answer, keyed off outcome (PLACEHOLDER copy — narrative pass later)
	var answer := _survived_answer() if _survived() else _died_answer()
	inner.add_child(_pad_top(answer, 11))

	box.add_child(_hairline())
	return holder


func _survived_answer() -> RichTextLabel:
	return _rich_line([
		["VERDICT — ", _col(GOLD), true],
		["NOT ENOUGH. ", _col(CYAN), true],
		["She gave the crowd everything but the one thing they wanted: to watch her crack.", _col(GOLD), true],
	], 15, true, true)


func _died_answer() -> RichTextLabel:
	return _rich_line([
		["VERDICT — ", _col(DANGER), true],
		["ENOUGH. ", _col(MYTHIC), true],
		["The essence broke on camera, and the crowd will replay it forever.", _col(GOLD), true],
	], 15, true, true)


func _hairline() -> Control:
	var r := ColorRect.new()
	r.color = _col(BORDER)
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# ------------------------------------- the 5 "earned" stat cards -------------
func _build_earned_row() -> Control:
	var holder := CenterContainer.new()
	var row := _hbox(12)
	holder.add_child(row)

	# HYPE EARNED
	row.add_child(_ecard("HYPE EARNED",
		[[str(int(_v().get("hype_earned", 0))), _col(GOLD)]],
		"peak crowd: %s 🔥" % String(_v().get("peak_band", "ON FIRE")),
		_col(GOLD, 0.4), _col(GOLD), true, Color(0, 0, 0, 0), ""))

	# EPITHET UNLOCKED (cyan, glow border)
	row.add_child(_ecard("EPITHET UNLOCKED",
		[["⬡ ", _col(CYAN)], [String(_epithet().get("name", "")), _col(CYAN)]],
		String(_epithet().get("note", "")),
		_col(CYAN, 0.5), _col(CYAN), false, _col(CYAN, 0.15), "sym"))

	# PATRON STANDING (gold; note in success)
	var patron := _patron()
	row.add_child(_ecard("PATRON STANDING",
		[["%s — %s" % [String(patron.get("name", "")), String(patron.get("state", ""))], _col(GOLD)]],
		String(patron.get("note", "")),
		_col(GOLD, 0.4), _col(GOLD), false, Color(0, 0, 0, 0), "", true))

	# CROWD VERDICT (gold headline + stars)
	row.add_child(_crowd_card())

	# THE BOSS (fire/orange; breach)
	var boss := _boss()
	var breached := bool(boss.get("breached", false))
	var boss_head := "%s: %s" % [_boss_short(String(boss.get("name", ""))), "BREACHED" if breached else "HOLDING"]
	row.add_child(_ecard("THE BOSS",
		[[boss_head, _col("#ff9a5a")]],
		"PHASE %d REACHED · %s" % [int(boss.get("phase", 0)), String(boss.get("note", ""))],
		_col(FIRE, 0.5), _col("#ff9a5a"), false, Color(0, 0, 0, 0), "", false, true))
	return holder


## A single earned card. `value_runs` is [[text,color],...] rendered on the value
## line; `note` is the muted sub-line (may carry a trailing emoji token). `glow`
## non-transparent adds a card halo. `note_hi` bolds the leading "+ X" of the note
## in success green (patron blessing). `fire_bg` gives the boss card its warm wash.
func _ecard(kicker: String, value_runs: Array, note: String, border: Color, _vcol: Color,
		value_glow: bool, glow: Color, sym: String, note_hi := false, fire_bg := false) -> Control:
	var card := PanelContainer.new()
	var bg := _col(PANEL)
	if fire_bg:
		bg = _col("#170d0a")
	if glow.a > 0.0:
		card.add_theme_stylebox_override("panel", _glow_sb(bg, border, 7, glow, 10))
	else:
		card.add_theme_stylebox_override("panel", _sb(bg, border, 7))
	card.custom_minimum_size = Vector2(250, 96)

	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 16)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 13)
	card.add_child(m)
	var v := _vbox(6)
	m.add_child(v)

	v.add_child(_lab(kicker, f_body, 8, _col(MUTED), 3.0, true))

	# value line
	if value_glow and value_runs.size() == 1:
		var g := _glow(String(value_runs[0][0]), f_mono, 24, value_runs[0][1], 0.0, 0.0)
		v.add_child(g)
	else:
		var runs: Array = []
		for vr in value_runs:
			runs.append([String(vr[0]), vr[1], true])
		var rl := _rich_line(runs, 17)
		if sym == "sym":
			rl.add_theme_font_override("normal_font", f_sym)
			rl.add_theme_font_override("bold_font", f_sym)
		v.add_child(rl)

	# note line
	if note_hi and note.begins_with("+"):
		var sp := note.find(" ", 2)
		var head := note.substr(0, sp) if sp > 0 else note
		var tail := note.substr(sp) if sp > 0 else ""
		v.add_child(_rich_line([[head, _col(SUCCESS), true], [tail, _col(MUTED), false]], 10))
	elif note.ends_with("🔥"):
		var base := note.substr(0, note.length() - 2)
		var h := _hbox(2)
		h.add_child(_lab(base, f_body, 10, _col(MUTED), 1.0))
		h.add_child(_emo("🔥", 11))
		v.add_child(h)
	else:
		var nl := _lab(note, f_body, 10, _col(MUTED), 1.0)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	return card


func _crowd_card() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _sb(_col(PANEL), _col(GOLD, 0.35), 7))
	card.custom_minimum_size = Vector2(250, 96)
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 16)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 13)
	card.add_child(m)
	var v := _vbox(6)
	m.add_child(v)
	v.add_child(_lab("CROWD VERDICT", f_body, 8, _col(MUTED), 3.0, true))
	v.add_child(_lab(String(_crowd().get("name", "")), f_body, 17, _col(GOLD), 0.5, true))
	# stars
	var stars := clampi(int(_crowd().get("stars", 0)), 0, 5)
	var srow := _hbox(3)
	for i in range(5):
		srow.add_child(_lab("★" if i < stars else "☆", f_sym, 14, _col(GOLD) if i < stars else _col(MUTED)))
	v.add_child(srow)
	return card


func _boss_short(boss_name: String) -> String:
	# "Incinedile" -> "INCINE-DILE" (the broadcast styling in the mockup)
	var n := boss_name.to_upper()
	if n == "INCINEDILE":
		return "INCINE-DILE"
	return n


# ------------------------------------------------------------------------ chyron
func _build_chyron() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#0d0510"), _col(MYTHIC, 0.45), 5))
	var row := _hbox(0)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(row)

	# MOMUS badge
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _sb(_col(MYTHIC, 0.2), _col(MYTHIC, 0.0), 0))
	var bm := MarginContainer.new()
	for s in ["left", "right"]:
		bm.add_theme_constant_override("margin_" + s, 18)
	badge.add_child(bm)
	var brow := _hbox(8)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	bm.add_child(brow)
	brow.add_child(_emo("🦩", 18))
	brow.add_child(_lab("MOMUS", f_body, 13, _col(MYTHIC), 3.0, true))
	row.add_child(badge)

	# sign-off line
	var line := _rich_line([
		["\"This is Momus. ", _col("#e8d0dc"), false],
		["Stay tuned!", _col(MYTHIC), true],
		["\"", _col("#e8d0dc"), false],
	], 16)
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lm := MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 20)
	lm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lm.add_child(line)
	row.add_child(lm)

	# NEXT (right) — PLACEHOLDER: next-contestant flow not wired
	var nxt := _lab("NEXT: DARIO \"ENCORE\" TAKES THE TABLE ▶", f_body, 10, _col(MUTED), 3.0)
	nxt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var nm := MarginContainer.new()
	for s in ["left", "right"]:
		nm.add_theme_constant_override("margin_" + s, 20)
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nm.add_child(nxt)
	row.add_child(nm)

	# NEW RUN (far right) — closes the run loop back to the title screen.
	var rm := MarginContainer.new()
	rm.add_theme_constant_override("margin_right", 16)
	rm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rm.add_child(_new_run_button())
	row.add_child(rm)
	return p


## The run-loop CTA on the verdict card: ▶ NEW RUN returns to the title screen. A
## primary cyan button sized to sit in the chyron without restructuring the card.
func _new_run_button() -> Button:
	var btn := Button.new()
	btn.text = "▶ NEW RUN"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_override("font", _tracked(f_body, 2.0))
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", _col(CYAN))
	btn.add_theme_color_override("font_hover_color", _col("#b8f4ff"))
	btn.add_theme_color_override("font_pressed_color", _col("#b8f4ff"))
	btn.add_theme_color_override("font_outline_color", _col(CYAN, 0.5))
	btn.add_theme_constant_override("outline_size", 4)
	var normal := _glow_sb(_col(CYAN, 0.14), _col(CYAN), 5, _col(CYAN, 0.3), 8)
	var hover := _glow_sb(_col(CYAN, 0.24), _col(CYAN), 5, _col(CYAN, 0.45), 12)
	for pset in [["normal", normal], ["hover", hover], ["pressed", hover], ["focus", normal]]:
		var box: StyleBoxFlat = pset[1]
		box.content_margin_left = 16
		box.content_margin_right = 16
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		btn.add_theme_stylebox_override(String(pset[0]), box)
	btn.pressed.connect(_on_new_run)
	return btn


func _on_new_run() -> void:
	get_tree().change_scene_to_file("res://scenes/title.tscn")
