extends Control
## BidScreen — the demo-slice PATRON BID SCREEN ("The Bidding", KAN-6 mockup gate).
##
## PRESENTATION ONLY. This scene never imports or touches `simulation/` classes; it
## reads STATIC pre-run data exclusively through the GameController VIEW API
## (view_bid) and renders it. The bid → combat flow is wired on the LOCK IN PATRONS
## button: it changes to the combat slice scene (res://scenes/main.tscn).
##
## Visual identity: docs/ux-designs/demo-slice-2026-07-19/DESIGN.md (the sister
## char-sheet palette, extended). Layout blueprint: .working/key-bid-screen.html.
## Every NUMBER on screen is PLACEHOLDER (R14) — the watermark says so, and the
## bids/multipliers are DERIVED deterministically in view_bid (no RNG).
##
## Data-bound (from view_bid): table pot; per contestant name/persona/signed patron;
## per patron name, pantheon·domain, influence, favor/taboo/boons, bid, trait chips,
## multiplier, and the SIGNED / ▲ OUTBIDDING flags.

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
const PINK_SOFT := "#ff6b88"     # danger register text (softer than pure danger)
const PURPLE_SOFT := "#c79cf5"   # purple register text
const MYTHIC_SOFT := "#f5a3cd"   # mythic register text (enyo boons)
const RIBBON_INK := "#180f02"    # dark ink on the gold SIGNED ribbon

# gods rendered in the MYTHIC (heel) register wherever they appear (DESIGN.md:
# "mythic = Momus / Enyo / heel"). Enyo is Dario's chaos patron.
const MYTHIC_KEYS := ["enyo"]

var _gc = null           # GameController (the `Game` autoload script; no class_name)
var _built := false

# fonts
var f_body: Font
var f_mono: Font
var f_emoji: Font
var f_sym: Font


func _ready() -> void:
	# Standalone / editor run: self-bind to the Game autoload. view_bid reads only
	# static data (the DAL), so no combat needs to be running. The render harness
	# calls bind() itself before this fires (add_child defers _ready), so this is a
	# no-op there.
	if not _built and _gc == null:
		var g := get_node_or_null("/root/Game")
		if g != null:
			bind(g)


## Bind to a GameController and build the screen from view_bid(). Idempotent: the
## first call builds; later calls are ignored (the screen is static, bound once).
func bind(gc) -> void:
	_gc = gc
	if _built:
		return
	_built = true
	_init_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1600, 1000)
	_build(gc.view_bid())


# ---------------------------------------------------------------- fonts / util
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


## Title/value label with a soft neon halo (glow is rare + load-bearing — accents
## only, per DESIGN.md).
func _glow(text: String, font: Font, fsize: int, color: Color, tracking: float, halo: float) -> Label:
	var l := _lab(text, font, fsize, color, tracking, true)
	l.add_theme_constant_override("outline_size", int(halo))
	l.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.28))
	return l


## Emoji glyph label (colour emoji via Noto Color Emoji — the font carries colour).
func _emo(glyph: String, px: int) -> Label:
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_override("font", f_emoji)
	l.add_theme_font_size_override("font_size", px)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


func _expand(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


func _fixed_y(node: Control, h: int) -> Control:
	node.custom_minimum_size.y = h
	node.size_flags_vertical = Control.SIZE_FILL
	return node


func _hline(color: Color, h := 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, h)
	return r


## First-letter-uppercased, period-terminated flavor sentence (favor/taboo copy in
## the data is lower-case and unpunctuated).
func _sentence(s: String) -> String:
	if s.is_empty():
		return s
	var out := s.substr(0, 1).to_upper() + s.substr(1)
	var last := out.substr(out.length() - 1)
	if last != "." and last != "!" and last != "?":
		out += "."
	return out


func _kfmt(n: int) -> String:
	return "%0.1fk" % (float(n) / 1000.0)


# ---------------------------------------------------------------- build the tree
func _build(view: Dictionary) -> void:
	var bg := ColorRect.new()
	bg.color = _col(BG)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# twin top glows (cyan left / mythic right) — the .screen radials in the blueprint
	_add_corner_glow(_col(CYAN), Vector2(0.26, -0.06))
	_add_corner_glow(_col(MYTHIC), Vector2(0.74, -0.06))

	var root_m := MarginContainer.new()
	root_m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_m.add_theme_constant_override("margin_left", 14)
	root_m.add_theme_constant_override("margin_right", 14)
	root_m.add_theme_constant_override("margin_top", 10)
	root_m.add_theme_constant_override("margin_bottom", 12)
	add_child(root_m)

	var col := _vbox(11)
	root_m.add_child(col)

	col.add_child(_fixed_y(_build_broadcast(), 50))
	col.add_child(_fixed_y(_build_header(), 92))
	col.add_child(_expand(_build_columns(view.get("contestants", []))))
	col.add_child(_fixed_y(_build_footer(view), 70))

	# R14 watermark — faint, rotated, bottom-right, on every screen while placeholder.
	var wm := _lab("PLACEHOLDER NUMBERS · R14", f_body, 10, _col(TEXT, 0.16), 3.0, true)
	wm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	wm.position = Vector2(-250, -22)
	wm.rotation = deg_to_rad(-1.0)
	add_child(wm)


func _add_corner_glow(tint: Color, frac: Vector2) -> void:
	var g := TextureRect.new()
	g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 0.09))
	grad.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = frac
	gt.fill_to = frac + Vector2(0.34, 0.42)
	gt.width = 800
	gt.height = 500
	g.texture = gt
	g.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(g)


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

	# left: LIVE pill + PRE-RUN · DIVINITY EXCHANGE OPEN
	var left := _hbox(14)
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
	lrow.add_child(_live_dot())
	lrow.add_child(_lab("LIVE", f_body, 12, _col(PINK_SOFT), 2.0, true))
	left.add_child(live)
	var rec := _hbox(6)
	rec.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rec.add_child(_lab("PRE-RUN", f_mono, 13, _col(MUTED), 1.0))
	rec.add_child(_lab("·", f_mono, 13, _col(MUTED), 1.0))
	rec.add_child(_lab("DIVINITY EXCHANGE OPEN", f_mono, 13, _col(TEXT), 1.0, true))
	left.add_child(rec)
	row.add_child(left)

	# center: brand
	var center := _vbox(0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := _glow("GALACTIC  PRIME  TIME", f_body, 22, _col(CYAN), 6.0, 9.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(title)
	row.add_child(center)

	# right: MOMUS host chip
	var right := _hbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	var momus := PanelContainer.new()
	momus.add_theme_stylebox_override("panel", _sb(_col(MYTHIC, 0.1), _col(MYTHIC, 0.55), 20))
	momus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mm := MarginContainer.new()
	for s in ["left", "right"]:
		mm.add_theme_constant_override("margin_" + s, 12)
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


# ------------------------------------------------------------------- gold header
func _build_header() -> Control:
	var v := _vbox(6)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var h1 := _glow("THE  BIDDING", f_body, 30, _col(GOLD), 8.0, 12.0)
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h1)
	var sub := _hbox(0)
	sub.alignment = BoxContainer.ALIGNMENT_CENTER
	sub.add_child(_lab("PATRONS WAGER ON ", f_body, 11, _col(MUTED), 4.0, true))
	sub.add_child(_lab("TONIGHT'S CONTESTANTS", f_body, 11, _col(TEXT), 4.0, true))
	sub.add_child(_lab(" · GODS BUY LOW ON DESPERATE MORTALS", f_body, 11, _col(MUTED), 4.0, true))
	v.add_child(sub)
	# gold rule under the title (centered, faded ends)
	var rule_row := _hbox(0)
	rule_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var rule := _grad_rule(_col(GOLD, 0.55), 760)
	rule_row.add_child(rule)
	v.add_child(rule_row)
	return v


func _grad_rule(mid: Color, width: int) -> Control:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(width, 1)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(mid.r, mid.g, mid.b, 0.0), mid, Color(mid.r, mid.g, mid.b, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = width
	gt.height = 1
	tr.texture = gt
	return tr


# --------------------------------------------------------------- two columns
func _build_columns(contestants: Array) -> Control:
	var row := _hbox(16)
	for cv: Variant in contestants:
		row.add_child(_expand(_build_column(cv)))
	return row


func _build_column(contestant: Dictionary) -> Control:
	var cid := String(contestant.get("id", ""))
	var is_heel := cid.contains("dario")
	var accent := _col(GOLD) if is_heel else _col(CYAN)

	var wrap := _vbox(11)
	wrap.add_child(_fixed_y(_build_contestant_header(contestant, accent, is_heel), 80))

	var cards := _vbox(10)
	_expand(cards)
	for pv: Variant in contestant.get("patrons", []):
		cards.add_child(_expand(_build_god_card(pv)))
	wrap.add_child(_expand(cards))
	return wrap


func _build_contestant_header(contestant: Dictionary, accent: Color, is_heel: bool) -> Control:
	var root := Control.new()
	root.clip_contents = true
	var bgp := Panel.new()
	bgp.add_theme_stylebox_override("panel", _glow_sb(_col(PANEL), Color(accent.r, accent.g, accent.b, 0.4), 6, accent, 3))
	bgp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bgp)

	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 10)
	pad.add_theme_constant_override("margin_bottom", 10)
	root.add_child(pad)

	var row := _hbox(12)
	pad.add_child(row)

	# avatar
	var av := Panel.new()
	av.add_theme_stylebox_override("panel", _glow_sb(_col(PANEL2), accent, 11, Color(accent.r, accent.g, accent.b, 0.4), 8))
	av.custom_minimum_size = Vector2(50, 50)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var avc := CenterContainer.new()
	avc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av.add_child(avc)
	avc.add_child(_emo(_avatar_emoji(String(contestant.get("id", ""))), 26))
	row.add_child(av)

	# name + persona
	var info := _vbox(3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(_lab(String(contestant.get("name", "")).to_upper(), f_body, 18, accent, 1.0, true))
	var persona := _lab(String(contestant.get("persona", "")), f_body, 10, _col(MUTED), 1.0)
	persona.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	persona.max_lines_visible = 2
	persona.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	persona.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(persona)
	row.add_child(info)

	# "PATRON" + "N GODS BIDDING"
	var seek := _vbox(3)
	seek.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lp := _lab("PATRON", f_body, 8, _col(GOLD), 3.0, true)
	lp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	seek.add_child(lp)
	var n := (contestant.get("patrons", []) as Array).size()
	var ln := _lab("%d GODS BIDDING" % n, f_body, 11, _col(TEXT), 1.0, true)
	ln.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	seek.add_child(ln)
	row.add_child(seek)
	return root


func _avatar_emoji(cid: String) -> String:
	if cid.contains("imani"):
		return "🛡️"
	if cid.contains("dario"):
		return "🎭"
	return "🎪"


# --------------------------------------------------------------- god bid card
func _build_god_card(p: Dictionary) -> Control:
	var signed := bool(p.get("signed", false))
	var outbid := bool(p.get("outbidding", false))
	var is_mythic := MYTHIC_KEYS.has(String(p.get("key", "")))
	var accent := _col(MYTHIC) if is_mythic else _col(GOLD)  # the "signed" accent register

	# per-state colour scheme (mirrors the blueprint's .signed / .outbid / .rival)
	var border_col := _col(BORDER)
	var glow_col := Color(0, 0, 0, 0)
	var glow_px := 0
	var name_col := _col(TEXT)
	var sigil_col := _col(CYAN)
	var dots_col := _col(GOLD)
	var mult_col := _col(CYAN)
	var trait_kind := "wry"
	var card_bg := _col(PANEL)
	if signed:
		border_col = _col(GOLD); glow_col = _col(GOLD, 0.22); glow_px = 12
		name_col = accent; sigil_col = accent; dots_col = accent; mult_col = accent
		trait_kind = "pos"; card_bg = _col("#12100a")
	elif outbid:
		border_col = _col(DANGER, 0.4); sigil_col = _col(DANGER)
		name_col = _col(TEXT); dots_col = _col(GOLD); mult_col = _col(DANGER)
		trait_kind = "neg"
	else:
		name_col = accent if is_mythic else _col(TEXT)
		sigil_col = accent if is_mythic else _col(CYAN)
		mult_col = accent if is_mythic else _col(CYAN)
		trait_kind = "wry"

	var root := Control.new()
	root.clip_contents = true
	var bgp := Panel.new()
	bgp.add_theme_stylebox_override("panel", _glow_sb(card_bg, border_col, 7, glow_col, glow_px))
	bgp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bgp)

	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 15)
	pad.add_theme_constant_override("margin_right", 15)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	root.add_child(pad)

	var body := _vbox(9)
	pad.add_child(body)

	# ---- top: sigil + name/trad + influence stars ----
	var top := _hbox(11)
	var sig := Panel.new()
	sig.add_theme_stylebox_override("panel", _sb(_col(PANEL2), Color(sigil_col.r, sigil_col.g, sigil_col.b, 0.7), 9))
	sig.custom_minimum_size = Vector2(40, 40)
	sig.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sigc := CenterContainer.new()
	sigc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sig.add_child(sigc)
	sigc.add_child(_lab("⬡", f_sym, 20, sigil_col))
	top.add_child(sig)

	var idbox := _vbox(2)
	idbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var gname := _lab(String(p.get("name", "")).to_upper(), f_body, 16, name_col, 2.0, true)
	if signed:
		gname = _glow(String(p.get("name", "")).to_upper(), f_body, 16, name_col, 2.0, 6.0)
	idbox.add_child(gname)
	var trad := "%s · %s" % [String(p.get("pantheon", "")), String(p.get("domain", ""))]
	idbox.add_child(_lab(trad.to_upper(), f_body, 9, _col(MUTED), 2.0))
	top.add_child(idbox)

	top.add_child(_stars(int(p.get("influence", 0))))
	if signed:
		# clear the SIGNED corner ribbon (blueprint's .god.signed .g-top padding-right)
		var ribbon_gap := Control.new()
		ribbon_gap.custom_minimum_size = Vector2(26, 0)
		top.add_child(ribbon_gap)
	body.add_child(top)

	# ---- deal block: FAVOR / TABOO / BOONS between hairlines ----
	body.add_child(_hline(_col(BORDER)))
	var deal := _vbox(6)
	deal.add_theme_constant_override("margin_top", 0)
	var dealpad := MarginContainer.new()
	dealpad.add_theme_constant_override("margin_top", 8)
	dealpad.add_theme_constant_override("margin_bottom", 8)
	dealpad.add_child(deal)
	deal.add_child(_deal_row("FAVOR", _col(SUCCESS), _lab(_sentence(String(p.get("favor", ""))), f_body, 11, _col(TEXT))))
	deal.add_child(_deal_row("TABOO", _col(DANGER), _lab(_sentence(String(p.get("taboo", ""))), f_body, 11, _col(TEXT))))
	deal.add_child(_deal_row("BOONS", _col(PURPLE), _boons_row(p.get("boons", []), is_mythic)))
	body.add_child(dealpad)
	body.add_child(_hline(_col(BORDER)))

	# spacer pins the bid/multiplier row to the card's bottom edge (blueprint layout)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

	# ---- bottom: bid (dots + value) | trait chips + ×mult ----
	var bot := _hbox(0)
	bot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bid := _hbox(9)
	bid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bid.alignment = BoxContainer.ALIGNMENT_BEGIN
	bid.add_child(_bid_dots(int(p.get("influence", 0)), dots_col))
	var bidval := _hbox(5)
	bidval.add_child(_lab("BID", f_body, 9, _col(MUTED), 1.0))
	bidval.add_child(_lab(_comma(int(p.get("bid", 0))), f_mono, 13, dots_col, 1.0, true))
	bidval.add_child(_lab("favor", f_body, 9, _col(MUTED), 1.0))
	bid.add_child(bidval)
	bot.add_child(bid)

	var persona := _hbox(6)
	persona.alignment = BoxContainer.ALIGNMENT_END
	persona.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if outbid:
		persona.add_child(_outflag())
	for tv: Variant in p.get("traits", []):
		persona.add_child(_trait_chip(String(tv), trait_kind))
	var mult := _glow("×%s" % _mult_str(float(p.get("multiplier", 1.0))), f_mono, 19, mult_col, 1.0, 6.0)
	persona.add_child(mult)
	bot.add_child(persona)
	body.add_child(bot)

	if signed:
		root.add_child(_signed_ribbon())
	return root


func _deal_row(key: String, key_col: Color, value: Control) -> Control:
	var row := _hbox(9)
	var k := _lab(key, f_body, 8, key_col, 2.0, true)
	k.custom_minimum_size.x = 52
	k.size_flags_vertical = Control.SIZE_FILL
	row.add_child(k)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if value is Label:
		(value as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value)
	return row


func _boons_row(boons: Array, is_mythic: bool) -> Control:
	var h := _hbox(6)
	for b: Variant in boons:
		h.add_child(_boon_chip(String(b), is_mythic))
	return h


func _boon_chip(text: String, is_mythic: bool) -> Control:
	var tint := _col(MYTHIC) if is_mythic else _col(PURPLE)
	var txt := _col(MYTHIC_SOFT) if is_mythic else _col(PURPLE_SOFT)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(tint.r, tint.g, tint.b, 0.1), Color(tint.r, tint.g, tint.b, 0.4), 4))
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 8)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 3)
	pc.add_child(m)
	m.add_child(_lab(text.to_upper(), f_body, 9, txt, 1.0, true))
	return pc


func _stars(influence: int) -> Control:
	var v := _vbox(1)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := _hbox(0)
	row.alignment = BoxContainer.ALIGNMENT_END
	var filled := ""
	for i in range(influence):
		filled += "★"
	var empty := ""
	for i in range(5 - influence):
		empty += "★"
	if filled != "":
		row.add_child(_lab(filled, f_sym, 12, _col(GOLD), 1.0))
	if empty != "":
		row.add_child(_lab(empty, f_sym, 12, _col(MUTED), 1.0))
	v.add_child(row)
	var il := _lab("INFLUENCE %d/5" % influence, f_body, 7, _col(MUTED), 2.0)
	il.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(il)
	return v


func _bid_dots(count: int, color: Color) -> Control:
	var h := _hbox(0)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var filled := ""
	for i in range(count):
		filled += "●"
	var empty := ""
	for i in range(5 - count):
		empty += "●"
	if filled != "":
		h.add_child(_lab(filled, f_sym, 11, color, 1.0))
	if empty != "":
		h.add_child(_lab(empty, f_sym, 11, _col(MUTED), 1.0))
	return h


func _trait_chip(word: String, kind: String) -> Control:
	var tint := _col(PURPLE)
	var txt := _col(PURPLE_SOFT)
	if kind == "pos":
		tint = _col(SUCCESS); txt = _col(SUCCESS)
	elif kind == "neg":
		tint = _col(DANGER); txt = _col(PINK_SOFT)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(Color(tint.r, tint.g, tint.b, 0.1), Color(tint.r, tint.g, tint.b, 0.4), 11))
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 7)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 3)
	pc.add_child(m)
	m.add_child(_lab(word.to_upper(), f_body, 8, txt, 1.0, true))
	return pc


func _outflag() -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _sb(_col(DANGER, 0.1), _col(DANGER, 0.4), 3))
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 7)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 2)
	pc.add_child(m)
	m.add_child(_lab("▲ OUTBIDDING", f_sym, 8, _col(PINK_SOFT), 2.0, true))
	return pc


## Diagonal gold "SIGNED" corner banner. Anchored to the card's top-right corner,
## rotated 45°, and clipped by the card (clip_contents) into a corner ribbon.
func _signed_ribbon() -> Control:
	var band := PanelContainer.new()
	var sb := _sb(_col(GOLD), _col(GOLD), 0, 0)
	band.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	for s in ["left", "right"]:
		m.add_theme_constant_override("margin_" + s, 34)
	for s in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 3)
	band.add_child(m)
	m.add_child(_lab("SIGNED", f_body, 10, _col(RIBBON_INK), 3.0, true))
	# Anchored top-right (grows left), rotated 45° about its top-left; a small
	# up-right nudge parks the bar across the corner, and the card's clip_contents
	# trims the overhang into a corner ribbon.
	band.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	band.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	band.pivot_offset = Vector2.ZERO
	band.rotation = deg_to_rad(45.0)
	band.position += Vector2(11.0, -3.0)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return band


func _comma(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


func _mult_str(m: float) -> String:
	return "%0.1f" % m


# --------------------------------------------------------------------- footer
func _build_footer(view: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(_col("#0a1024"), _col(BORDER), 6))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 20)
	pad.add_theme_constant_override("margin_right", 20)
	p.add_child(pad)
	var row := _hbox(0)
	pad.add_child(row)

	# left: table pot
	var pot := _hbox(9)
	pot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pot.alignment = BoxContainer.ALIGNMENT_BEGIN
	pot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pot.add_child(_lab("TABLE POT", f_body, 10, _col(MUTED), 2.0, true))
	pot.add_child(_lab(_kfmt(int(view.get("table_pot", 0))), f_mono, 15, _col(GOLD), 1.0, true))
	pot.add_child(_lab("FAVOR · SEEDED PATRONS HELD FOR THE SLICE", f_body, 10, _col(MUTED), 2.0))
	row.add_child(pot)

	# center: mid-run warning note
	var note := _hbox(0)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.alignment = BoxContainer.ALIGNMENT_CENTER
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	note.add_child(_lab("⚠ Rival gods may bless or curse mid-run", f_sym, 11, _col(MYTHIC), 1.0, true))
	note.add_child(_lab(" — an outbid god does not simply walk away.", f_body, 11, _col(MUTED), 1.0))
	row.add_child(note)

	# right: LOCK IN PATRONS CTA
	var right := _hbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_END
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_child(_lock_button())
	row.add_child(right)
	return p


func _lock_button() -> Control:
	var btn := Button.new()
	btn.text = "LOCK IN PATRONS  ▶"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", _tracked(f_body, 3.0))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", _col(GOLD))
	btn.add_theme_color_override("font_hover_color", _col("#ffe9a8"))
	btn.add_theme_color_override("font_pressed_color", _col("#ffe9a8"))
	btn.add_theme_color_override("font_focus_color", _col(GOLD))
	btn.add_theme_color_override("font_outline_color", _col(GOLD, 0.5))
	btn.add_theme_constant_override("outline_size", 6)
	var normal := _glow_sb(_col(GOLD, 0.16), _col(GOLD), 6, _col(GOLD, 0.35), 10)
	var hover := _glow_sb(_col(GOLD, 0.26), _col(GOLD), 6, _col(GOLD, 0.5), 14)
	for pset in [["normal", normal], ["hover", hover], ["pressed", hover], ["focus", normal]]:
		var box: StyleBoxFlat = pset[1]
		box.content_margin_left = 26
		box.content_margin_right = 26
		box.content_margin_top = 13
		box.content_margin_bottom = 13
		btn.add_theme_stylebox_override(String(pset[0]), box)
	btn.pressed.connect(_on_lock_in)
	return btn


## The bid → combat flow: LOCK IN PATRONS advances to the combat slice scene.
func _on_lock_in() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
