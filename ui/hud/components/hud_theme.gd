extends RefCounted
## HudTheme — shared palette + widget builders for the HUD v2 component scenes.
##
## PRESENTATION ONLY. Pure static helpers; no state beyond lazily-built fonts.
## Every component preloads this script (no class_name — keeps the global class
## cache out of the harness compile path) so the whole HUD styles from one place.
## Palette = the existing char-sheet tokens (DESIGN.md) — placeholder styling
## until the art pass (ADOPTION.md Phase 1: structure, not final art).

# ---- palette (DESIGN.md — the existing char-sheet app tokens, unchanged) ----
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

# ---- status-effect palette (status-prominence pass) ------------------------
# One colour per rulebook condition + a distinct SHOCK accent, shared by the
# party cards, inspector ACTIVE STATUS section and arena token pips so a
# condition reads as the SAME colour everywhere on the HUD. Damaging conditions
# sit on the hot/danger side; shock is its own electric yellow (never confused
# with a condition); dissolution rides the psychic purple.
const SHOCK := "#ffd24a"
const COND_COLORS := {
	"bleeding": "#ff6b88",
	"crushed": "#c9a06a",
	"burn": "#ff9a5a",
	"chilled": CYAN,
	"poison": SUCCESS,
	"infected": "#a8d44a",
	"suffocation": "#8fa8d8",
	"dissolution": PURPLE,
	"exhausted": "#98a0b8",
}
## Compact condition abbreviations for the badge rows ("BLD 2" / "BRN 1").
const COND_ABBR := {
	"bleeding": "BLD", "crushed": "CRU", "burn": "BRN", "chilled": "CHL",
	"poison": "PSN", "infected": "INF", "suffocation": "SUF",
	"dissolution": "DSL", "exhausted": "EXH",
}


static func cond_col(cond_id: String) -> Color:
	return col(String(COND_COLORS.get(cond_id, DANGER)))


static func cond_abbr(cond_id: String) -> String:
	return String(COND_ABBR.get(cond_id, cond_id.substr(0, 3).to_upper()))

static var _f_body: Font
static var _f_mono: Font
static var _f_emoji: Font
static var _f_sym: Font


static func body() -> Font:
	if _f_body == null:
		_f_body = ThemeDB.fallback_font
	return _f_body


static func mono() -> Font:
	if _f_mono == null:
		_f_mono = _sysfont(["Liberation Mono", "DejaVu Sans Mono", "monospace"])
	return _f_mono


static func emoji_font() -> Font:
	if _f_emoji == null:
		_f_emoji = _sysfont(["Noto Color Emoji"])
	return _f_emoji


static func sym() -> Font:
	if _f_sym == null:
		_f_sym = _sysfont(["DejaVu Sans", "Noto Sans Symbols2", "FreeSans", "OpenSymbol"])
	return _f_sym


static func _sysfont(names: Array) -> SystemFont:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(names)
	sf.allow_system_fallback = true
	return sf


static func col(hexs: String, a := 1.0) -> Color:
	var c := Color(hexs)
	c.a = a
	return c


static func tracked(base: Font, glyph: float) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.spacing_glyph = int(glyph)
	return fv


static func bold_font() -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = body()
	fv.variation_embolden = 0.6
	return fv


## Generic label. tracking>0 wraps `font` in a spaced FontVariation; bold fakes
## weight with a same-colour outline (the fallback font ships no bold face).
static func lab(text: String, font: Font, fsize: int, color: Color, tracking := 0.0, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", tracked(font, tracking) if tracking > 0.0 else font)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_constant_override("outline_size", 2)
		l.add_theme_color_override("font_outline_color", color)
	return l


## Emoji glyph label (color emoji carries its own colour).
static func emo(glyph: String, px: int) -> Label:
	var l := Label.new()
	l.text = glyph
	l.add_theme_font_override("font", emoji_font())
	l.add_theme_font_size_override("font_size", px)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Label with a soft neon halo (accents only).
static func glow(text: String, font: Font, fsize: int, color: Color, tracking: float, halo: float) -> Label:
	var l := lab(text, font, fsize, color, tracking, true)
	l.add_theme_constant_override("outline_size", int(halo))
	l.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.28))
	return l


static func sb(bg: Color, border: Color, radius := 5, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(radius)
	return s


static func glow_sb(bg: Color, border: Color, radius: int, glow_col: Color, glow_size: int) -> StyleBoxFlat:
	var s := sb(bg, border, radius, 1)
	s.shadow_color = glow_col
	s.shadow_size = glow_size
	return s


static func hbox(sep := 0) -> HBoxContainer:
	var h := HBoxContainer.new()
	if sep != 0:
		h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep := 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	if sep != 0:
		v.add_theme_constant_override("separation", sep)
	return v


static func margin(l: int, r: int, t: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_bottom", b)
	return m


static func pad_top(node: Control, px: int) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_top", px)
	m.add_child(node)
	return m


static func pad_bottom(node: Control, px: int) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_bottom", px)
	m.add_child(node)
	return m


static func border_line(parent: Node) -> void:
	var r := ColorRect.new()
	r.color = col(BORDER)
	r.custom_minimum_size = Vector2(0, 1)
	parent.add_child(r)


static func h4(text: String) -> Control:
	return pad_bottom(lab(text, body(), 9, col(MUTED), 3.0, true), 7)


## Small pill chip wrapping arbitrary content.
static func chip(content: Control, bg: Color, border: Color, radius := 4) -> Control:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", sb(bg, border, radius))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var m := margin(8, 8, 3, 3)
	c.add_child(m)
	m.add_child(content)
	return c


## Compact status badge ("BLD 2" / "SHK 3" / "PRONE") — a tighter chip() for
## the per-card / inspector status rows: tinted fill, coloured border, bold text.
static func badge(text: String, color: Color) -> Control:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel",
		sb(Color(color.r, color.g, color.b, 0.12), Color(color.r, color.g, color.b, 0.5), 3))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var m := margin(5, 5, 1, 1)
	c.add_child(m)
	m.add_child(lab(text, body(), 8, color, 0.5, true))
	return c


## Makes a styled panel clickable without disturbing its look: a flat, focus-less
## Button laid over the full rect. Returns the button so callers can disable it.
static func attach_click(root: Control, on_press: Callable) -> Button:
	if not on_press.is_valid():
		return null
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(on_press)
	root.add_child(btn)
	return btn


## HP colour ramp (full = success, mid = gold, low = danger).
static func ramp(ratio: float) -> Color:
	if ratio >= 1.0:
		return col(SUCCESS)
	if ratio > 0.5:
		return col(GOLD)
	return col(DANGER)


## Rich label from [text, color, bold] runs.
static func rich_line(runs: Array, fsize: int, wrap := false) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	if wrap:
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_override("normal_font", body())
	r.add_theme_font_override("bold_font", bold_font())
	r.add_theme_font_size_override("normal_font_size", fsize)
	r.add_theme_font_size_override("bold_font_size", fsize)
	var bb := ""
	for run in runs:
		var seg := "[color=#%s]%s[/color]" % [(run[1] as Color).to_html(false), String(run[0])]
		if bool(run[2]):
			seg = "[b]%s[/b]" % seg
		bb += seg
	r.text = bb
	return r
