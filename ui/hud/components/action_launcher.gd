extends PanelContainer
## ActionLauncher — bottom-center stable category buttons (spec §3 Area 9).
## Flyouts (Area 10) are owned by the shell; this emits
## category_pressed(cat) / end_turn_pressed / pause_pressed and renders
## open/armed highlights, the consequence hint line, and the commit button's
## one-line consequence. Dumb component.
##
## TWO MODES (R34 decision #36, approved frames 1 and 4):
##
## COMBAT (Mode B/C) — [↔ MOVE] [ATTACK] [SKILLS] [FREE ACTIONS n/2] | [END TURN].
##   * The FREE ACTIONS button carries the R34 per-turn BUDGET on its face. The
##     budget is REAL state (view_combatants' free_actions_left /
##     free_actions_per_clock, refreshed per TICK per the owner's cadence
##     ruling) — never a counter this component keeps. It greys out at zero,
##     because at zero no free entry is legal any more.
##
## EXPLORATION (Mode A) — [↔ WALK free] [INTERACT] [SKILLS out-of-combat only]
##   [INVENTORY ⏸ pauses time] [⏸ PAUSE] | [ENTER ▸ <route>].
##   * There is no turn to end out of combat, so the commit button becomes the
##     deliberate ENTER (R34: "ENTER ▸ <route> is the commit"), riding the same
##     end_turn_pressed signal the facade already routes by phase.
##   * PAUSE is a DRIVER control and has no sim state (R34/R35, twice ruled) —
##     this button only asks; the facade's driver stops issuing time steps.
##   * INVENTORY is marked as pausing time because opening it must stop the
##     driver (R35's Pokemon clause) — the label states the contract on screen.

signal category_pressed(cat: String)
signal end_turn_pressed
signal pause_pressed

const UI := preload("res://ui/hud/components/hud_theme.gd")
const CATS := [["move", "↔ MOVE"], ["attack", "⚔ ATTACK"], ["skills", "✦ SKILLS"], ["free", "🎪 FREE ACTIONS"]]
const EXPLORE_CATS := [["move", "↔ WALK"], ["interact", "⛭ INTERACT"],
	["skills", "✦ SKILLS"], ["inventory", "🎒 INVENTORY"]]

var _built := false
var _who_title: Label
var _who_lab: Label
var _btns := {}          # cat -> PanelContainer (combat set)
var _explore_btns := {}  # cat -> PanelContainer (exploration set)
var _btn_row: HBoxContainer
var _explore_row: HBoxContainer
var _pause_btn: PanelContainer
var _pause_lab: Label
var _commit_lab: Label
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
	_who_title = UI.lab("ON THE CLOCK", UI.body(), 10, UI.col(UI.GOLD), 2.0, true)
	who.add_child(_who_title)
	_who_lab = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 1.0)
	who.add_child(_who_lab)
	row.add_child(who)

	var btns := UI.hbox(8)
	btns.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_btn_row = UI.hbox(8)
	for cd in CATS:
		var cat := String(cd[0])
		var b := _btn(String(cd[1]), UI.col(UI.TEXT), UI.col(UI.BORDER), UI.col(UI.PANEL2))
		UI.attach_click(b, func() -> void: category_pressed.emit(cat))
		_btns[cat] = b
		_btn_row.add_child(b)
	btns.add_child(_btn_row)

	_explore_row = UI.hbox(8)
	_explore_row.visible = false
	for cd in EXPLORE_CATS:
		var cat := String(cd[0])
		var b := _btn(String(cd[1]), UI.col(UI.TEXT), UI.col(UI.BORDER), UI.col(UI.PANEL2))
		UI.attach_click(b, func() -> void: category_pressed.emit(cat))
		_explore_btns[cat] = b
		_explore_row.add_child(b)
	_pause_btn = _btn("⏸ PAUSE", UI.col(UI.GOLD), UI.col(UI.GOLD, 0.6), UI.col(UI.GOLD, 0.08))
	_pause_lab = _pause_btn.get_meta("label")
	UI.attach_click(_pause_btn, func() -> void: pause_pressed.emit())
	_explore_row.add_child(_pause_btn)
	btns.add_child(_explore_row)

	var sep := ColorRect.new()
	sep.color = UI.col(UI.BORDER)
	sep.custom_minimum_size = Vector2(1, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btns.add_child(sep)
	var endv := UI.vbox(2)
	endv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var endb := _btn("END TURN", UI.col("#ff6b88"), UI.col(UI.DANGER), UI.col(UI.PANEL2))
	_commit_lab = endb.get_meta("label")
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


## A category button: title line plus an optional SUB line (the budget readout,
## "FREE", "⏸ PAUSES TIME"). The sub label is always built so update() can fill
## or blank it without rebuilding the button.
func _btn(text: String, fg: Color, bd: Color, bg: Color) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", UI.sb(bg, bd, 5))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := UI.margin(14, 14, 6, 6)
	c.add_child(m)
	var v := UI.vbox(1)
	m.add_child(v)
	var l := UI.lab(text, UI.body(), 11, fg, 1.0, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var sub := UI.lab("", UI.body(), 8, UI.col(UI.GOLD), 1.0, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.visible = false
	v.add_child(sub)
	c.set_meta("label", l)
	c.set_meta("sub", sub)
	c.set_meta("fg", fg)
	return c


func set_who(name: String) -> void:
	_ensure_built()
	_who_lab.text = name


## data: {who, open_cat ("" = none), move_armed: bool, hint, end_hint,
##        who_title: String  — "ON THE CLOCK" / "FREE MOVEMENT"
##        commit: String     — the commit button's face ("END TURN" / "ENTER ▸ X")
##        explore: bool      — swap to the Mode A button set
##        paused: bool       — PAUSE control face (driver state, not sim state)
##        subs: {cat -> String}  — per-button sub line ("1/2", "FREE", ...)
##        dim:  {cat -> bool}    — grey a button out (a spent budget, a
##                                 category with nothing legal in it)}
func update(data: Dictionary) -> void:
	_ensure_built()
	_who_lab.text = String(data.get("who", _who_lab.text))
	_who_title.text = String(data.get("who_title", "ON THE CLOCK"))
	var explore := bool(data.get("explore", false))
	_btn_row.visible = not explore
	_explore_row.visible = explore
	var paused := bool(data.get("paused", false))
	_pause_lab.text = "▶ RESUME" if paused else "⏸ PAUSE"
	var pause_col: Color = UI.col(UI.SUCCESS) if paused else UI.col(UI.GOLD)
	_pause_lab.add_theme_color_override("font_color", pause_col)
	_pause_lab.add_theme_color_override("font_outline_color", pause_col)
	_pause_btn.add_theme_stylebox_override("panel",
		UI.sb(Color(pause_col.r, pause_col.g, pause_col.b, 0.10),
			Color(pause_col.r, pause_col.g, pause_col.b, 0.6), 5))
	_commit_lab.text = String(data.get("commit", "END TURN"))

	var open_cat := String(data.get("open_cat", ""))
	var move_armed := bool(data.get("move_armed", false))
	var subs: Dictionary = data.get("subs", {})
	var dim: Dictionary = data.get("dim", {})
	var active: Dictionary = _explore_btns if explore else _btns
	for cat: Variant in active:
		var b: PanelContainer = active[cat]
		var lit: bool = (cat == open_cat) or (cat == "move" and move_armed)
		var greyed := bool(dim.get(cat, false))
		var fg: Color = UI.col(UI.GOLD) if lit else (UI.col(UI.MUTED) if greyed else b.get_meta("fg"))
		b.add_theme_stylebox_override("panel", UI.glow_sb(
			UI.col(UI.GOLD, 0.12) if lit else UI.col(UI.PANEL2),
			UI.col(UI.GOLD) if lit else UI.col(UI.BORDER), 5,
			UI.col(UI.GOLD, 0.3) if lit else Color(0, 0, 0, 0), 6 if lit else 0))
		var l: Label = b.get_meta("label")
		l.add_theme_color_override("font_color", fg)
		l.add_theme_color_override("font_outline_color", fg)
		var sub: Label = b.get_meta("sub")
		var sub_text := String(subs.get(cat, ""))
		sub.text = sub_text
		sub.visible = sub_text != ""
		var sub_col: Color = UI.col(UI.MUTED) if greyed else UI.col(UI.GOLD)
		sub.add_theme_color_override("font_color", sub_col)
		sub.add_theme_color_override("font_outline_color", sub_col)
	_hint_line.text = String(data.get("hint", ""))
	_end_hint.text = String(data.get("end_hint", ""))
