extends Control
## TitleScreen — the run-loop entry point (KAN-7 run loop). The first thing the
## game boots into: TITLE → (NEW RUN) → BID → COMBAT → VERDICT → (NEW RUN) → TITLE.
##
## PRESENTATION ONLY. It touches no sim state — it is a static front door that hands
## off to the bid screen. NEW RUN advances to res://ui/screens/bid_screen.tscn (which
## itself locks in patrons and enters combat). Visual identity matches the demo-slice
## screens (bid_screen / verdict_card): the sister char-sheet palette, uppercase
## wide-tracked labels, a blinking red ● LIVE pill, MOMUS as host. PLACEHOLDER visuals
## — the owner's "Rework Visuals Properly" pass replaces these; kept clean + simple.

# ---- palette (DESIGN.md — extends the char-sheet app tokens exactly) ----
const BG := "#04050d"
const PANEL := "#090c1a"
const PANEL2 := "#0d1020"
const CYAN := "#00d4ff"
const GOLD := "#c8a84b"
const DANGER := "#ff2255"
const TEXT := "#b8c8e0"
const MUTED := "#3a4560"
const BORDER := "#1a2540"
const MYTHIC := "#ec4899"
const PINK_SOFT := "#ff6b88"

# fonts
var f_body: Font
var f_mono: Font
var f_emoji: Font


func _ready() -> void:
	_init_fonts()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	custom_minimum_size = Vector2(1600, 1000)
	_build()


# ---------------------------------------------------------------- fonts / util
func _init_fonts() -> void:
	f_body = ThemeDB.fallback_font
	f_mono = _sysfont(["Liberation Mono", "DejaVu Sans Mono", "monospace"])
	f_emoji = _sysfont(["Noto Color Emoji"])


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
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if bold:
		l.add_theme_constant_override("outline_size", 2)
		l.add_theme_color_override("font_outline_color", color)
	return l


## Title/value label with a soft neon halo (glow is rare + load-bearing — accents only).
func _glow(text: String, font: Font, fsize: int, color: Color, tracking: float, halo: float) -> Label:
	var l := _lab(text, font, fsize, color, tracking, true)
	l.add_theme_constant_override("outline_size", int(halo))
	l.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.28))
	return l


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


func _spacer(weight := 1.0) -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_stretch_ratio = weight
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


# ---------------------------------------------------------------- build the tree
func _build() -> void:
	var bg := ColorRect.new()
	bg.color = _col(BG)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# twin top glows (cyan left / mythic right) — matches the bid/verdict backdrops.
	_add_corner_glow(_col(CYAN), Vector2(0.26, -0.02))
	_add_corner_glow(_col(MYTHIC), Vector2(0.74, -0.02))

	var col := _vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)

	col.add_child(_spacer(1.0))

	# ● LIVE · COSMIC CASINO pill row
	var live_row := _hbox(14)
	live_row.alignment = BoxContainer.ALIGNMENT_CENTER
	live_row.add_child(_live_pill())
	live_row.add_child(_lab("COSMIC CASINO · VIP TABLE", f_mono, 14, _col(TEXT), 4.0, true))
	col.add_child(live_row)

	# the brand
	var title := _glow("GALACTIC  PRIME  TIME", f_body, 66, _col(CYAN), 10.0, 20.0)
	var title_wrap := MarginContainer.new()
	title_wrap.add_theme_constant_override("margin_top", 26)
	title_wrap.add_theme_constant_override("margin_bottom", 10)
	title_wrap.add_child(title)
	col.add_child(title_wrap)

	# gold subtitle
	col.add_child(_lab("A REALITY-TV DUNGEON CRAWL · GODS WAGER ON WHO BREAKS", f_body, 13, _col(GOLD), 5.0, true))

	# MOMUS welcome line
	var welcome := _hbox(9)
	welcome.alignment = BoxContainer.ALIGNMENT_CENTER
	var welcome_wrap := MarginContainer.new()
	welcome_wrap.add_theme_constant_override("margin_top", 24)
	welcome_wrap.add_theme_constant_override("margin_bottom", 30)
	welcome.add_child(_emo("🦩", 18))
	welcome.add_child(_lab("MOMUS:", f_body, 13, _col(MYTHIC), 2.0, true))
	welcome.add_child(_lab("\"Welcome back to the table, darling. The crowd is starving.\"", f_body, 14, _col(TEXT), 0.5))
	welcome_wrap.add_child(welcome)
	col.add_child(welcome_wrap)

	# ▶ NEW RUN (primary) + QUIT (secondary)
	var btn_row := _hbox(16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_child(_new_run_button())
	btn_row.add_child(_quit_button())
	col.add_child(btn_row)

	col.add_child(_spacer(1.15))

	# footer credit line
	var foot := _lab("PRE-ALPHA · PLACEHOLDER VISUALS · R14", f_body, 10, _col(MUTED), 3.0, true)
	var foot_wrap := MarginContainer.new()
	foot_wrap.add_theme_constant_override("margin_bottom", 22)
	foot_wrap.add_child(foot)
	col.add_child(foot_wrap)


func _add_corner_glow(tint: Color, frac: Vector2) -> void:
	var g := TextureRect.new()
	g.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.set_color(0, Color(tint.r, tint.g, tint.b, 0.10))
	grad.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = frac
	gt.fill_to = frac + Vector2(0.36, 0.5)
	gt.width = 800
	gt.height = 600
	g.texture = gt
	g.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(g)


func _live_pill() -> Control:
	var live := PanelContainer.new()
	live.add_theme_stylebox_override("panel", _sb(_col(DANGER, 0.12), _col(DANGER, 0.5), 4))
	live.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lm := MarginContainer.new()
	for s in ["left", "right"]:
		lm.add_theme_constant_override("margin_" + s, 11)
	for s in ["top", "bottom"]:
		lm.add_theme_constant_override("margin_" + s, 4)
	live.add_child(lm)
	var lrow := _hbox(7)
	lm.add_child(lrow)
	lrow.add_child(_live_dot())
	lrow.add_child(_lab("LIVE", f_body, 12, _col(PINK_SOFT), 2.0, true))
	return live


func _live_dot() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(11, 11)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot := Panel.new()
	dot.add_theme_stylebox_override("panel", _glow_sb(_col(DANGER), _col(DANGER), 6, _col(DANGER, 0.9), 4))
	dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dot)
	var tw := create_tween().set_loops()
	tw.tween_property(dot, "modulate:a", 0.15, 0.55)
	tw.tween_property(dot, "modulate:a", 1.0, 0.55)
	return holder


## The primary CTA: ▶ NEW RUN advances to the bid screen (which enters combat).
func _new_run_button() -> Control:
	var btn := Button.new()
	btn.text = "▶  NEW RUN"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", _tracked(f_body, 4.0))
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", _col(CYAN))
	btn.add_theme_color_override("font_hover_color", _col("#b8f4ff"))
	btn.add_theme_color_override("font_pressed_color", _col("#b8f4ff"))
	btn.add_theme_color_override("font_outline_color", _col(CYAN, 0.5))
	btn.add_theme_constant_override("outline_size", 6)
	var normal := _glow_sb(_col(CYAN, 0.14), _col(CYAN), 6, _col(CYAN, 0.35), 12)
	var hover := _glow_sb(_col(CYAN, 0.24), _col(CYAN), 6, _col(CYAN, 0.5), 16)
	for pset in [["normal", normal], ["hover", hover], ["pressed", hover], ["focus", normal]]:
		var box: StyleBoxFlat = pset[1]
		box.content_margin_left = 34
		box.content_margin_right = 34
		box.content_margin_top = 15
		box.content_margin_bottom = 15
		btn.add_theme_stylebox_override(String(pset[0]), box)
	btn.pressed.connect(_on_new_run)
	return btn


## Secondary CTA: QUIT closes the game.
func _quit_button() -> Control:
	var btn := Button.new()
	btn.text = "QUIT"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", _tracked(f_body, 3.0))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", _col(MUTED))
	btn.add_theme_color_override("font_hover_color", _col(TEXT))
	btn.add_theme_color_override("font_pressed_color", _col(TEXT))
	var normal := _sb(_col(PANEL2), _col(BORDER), 6)
	var hover := _sb(_col(PANEL), _col(MUTED), 6)
	for pset in [["normal", normal], ["hover", hover], ["pressed", hover], ["focus", normal]]:
		var box: StyleBoxFlat = pset[1]
		box.content_margin_left = 22
		box.content_margin_right = 22
		box.content_margin_top = 15
		box.content_margin_bottom = 15
		btn.add_theme_stylebox_override(String(pset[0]), box)
	btn.pressed.connect(_on_quit)
	return btn


## NEW RUN → the bid screen (bid → combat is wired on that screen's LOCK IN button).
func _on_new_run() -> void:
	get_tree().change_scene_to_file("res://ui/screens/bid_screen.tscn")


func _on_quit() -> void:
	get_tree().quit()
