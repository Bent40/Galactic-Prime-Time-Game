extends PanelContainer
## ActionLauncher — bottom-center stable category buttons (spec §3 Area 9):
## [MOVE] [ATTACK] [SKILLS] [FREE ACTIONS] | [END TURN]. Flyouts (Area 10) are
## owned by the shell; this emits category_pressed(cat) / end_turn_pressed and
## renders open/armed highlights, the consequence hint line, and the END TURN
## one-line consequence ("who acts next"). Dumb component.

signal category_pressed(cat: String)
signal end_turn_pressed

const UI := preload("res://ui/hud/components/hud_theme.gd")
const CATS := [["move", "↔ MOVE"], ["attack", "⚔ ATTACK"], ["skills", "✦ SKILLS"], ["free", "🎪 FREE ACTIONS"]]

var _built := false
var _who_lab: Label
var _btns := {}          # cat -> PanelContainer
var _hint_title: Label
var _hint_line: Label
var _end_hint: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col("#0b1024"), UI.col(UI.GOLD), 5, UI.col(UI.GOLD, 0.15), 4))
	var m := UI.margin(16, 16, 0, 0)
	add_child(m)
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	m.add_child(row)

	var who := UI.vbox(2)
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	who.add_child(UI.lab("ON THE CLOCK", UI.body(), 10, UI.col(UI.GOLD), 2.0, true))
	_who_lab = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 1.0)
	who.add_child(_who_lab)
	row.add_child(who)

	var btns := UI.hbox(8)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for cd in CATS:
		var cat := String(cd[0])
		var b := _btn(String(cd[1]), UI.col(UI.TEXT), UI.col(UI.BORDER), UI.col(UI.PANEL2))
		UI.attach_click(b, func() -> void: category_pressed.emit(cat))
		_btns[cat] = b
		btns.add_child(b)
	var sep := ColorRect.new()
	sep.color = UI.col(UI.BORDER)
	sep.custom_minimum_size = Vector2(1, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btns.add_child(sep)
	var endv := UI.vbox(2)
	endv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var endb := _btn("END TURN", UI.col("#ff6b88"), UI.col(UI.DANGER), UI.col(UI.PANEL2))
	UI.attach_click(endb, func() -> void: end_turn_pressed.emit())
	endv.add_child(endb)
	_end_hint = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.0)
	_end_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endv.add_child(_end_hint)
	btns.add_child(endv)
	row.add_child(btns)

	var prev := UI.vbox(2)
	prev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prev.alignment = BoxContainer.ALIGNMENT_CENTER
	_hint_title = UI.lab("CONSEQUENCE PREVIEW", UI.body(), 8, UI.col(UI.MUTED), 2.0)
	_hint_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prev.add_child(_hint_title)
	_hint_line = UI.lab("", UI.body(), 10, UI.col(UI.TEXT), 0.5)
	_hint_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	prev.add_child(_hint_line)
	row.add_child(prev)


func _btn(text: String, fg: Color, bd: Color, bg: Color) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", UI.sb(bg, bd, 5))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := UI.margin(14, 14, 9, 9)
	c.add_child(m)
	var l := UI.lab(text, UI.body(), 11, fg, 1.0, true)
	m.add_child(l)
	c.set_meta("label", l)
	c.set_meta("fg", fg)
	return c


func set_who(name: String) -> void:
	_ensure_built()
	_who_lab.text = name


## data: {who, open_cat ("" = none), move_armed: bool, hint, end_hint}
func update(data: Dictionary) -> void:
	_ensure_built()
	_who_lab.text = String(data.get("who", _who_lab.text))
	var open_cat := String(data.get("open_cat", ""))
	var move_armed := bool(data.get("move_armed", false))
	for cat in _btns:
		var b: PanelContainer = _btns[cat]
		var lit: bool = (cat == open_cat) or (cat == "move" and move_armed)
		var fg: Color = UI.col(UI.GOLD) if lit else b.get_meta("fg")
		b.add_theme_stylebox_override("panel", UI.glow_sb(
			UI.col(UI.GOLD, 0.12) if lit else UI.col(UI.PANEL2),
			UI.col(UI.GOLD) if lit else UI.col(UI.BORDER), 5,
			UI.col(UI.GOLD, 0.3) if lit else Color(0, 0, 0, 0), 6 if lit else 0))
		var l: Label = b.get_meta("label")
		l.add_theme_color_override("font_color", fg)
		l.add_theme_color_override("font_outline_color", fg)
	_hint_line.text = String(data.get("hint", ""))
	_end_hint.text = String(data.get("end_hint", ""))
