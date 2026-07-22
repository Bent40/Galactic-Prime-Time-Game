extends PanelContainer
## MomentTimeline — top-center timing strip (spec §3 Area 4, ENGINE VOCABULARY
## per ADOPTION.md: CLOCK = the 10-tick lap, MOMENT = the tick position, exactly
## as the v1 HUD showed "CLOCK 3 · MOMENT 07"; the spec's inverted usage is an
## OPEN owner question and is NOT adopted).
##
## Shows the current CLOCK number, the current MOMENT, and a 10-slot strip (the
## lap's ticks, labelled with their Moment numbers 10..1) with a marker for each
## live combatant at its next_action_tick, the current slot highlighted and
## windup flags marked. Dumb component: renders the marker dicts it is handed.

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _clock_num: Label
var _moment_num: Label
var _nextreset: Label
var _strip: HBoxContainer


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL), UI.col(UI.BORDER), 5))
	var pad := UI.margin(14, 14, 5, 5)
	add_child(pad)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	pad.add_child(row)

	_clock_num = UI.lab("1", UI.mono(), 19, UI.col(UI.PURPLE), 0.0, true)
	row.add_child(_kv_pill("CLOCK", _clock_num, UI.col(UI.PURPLE), UI.col(UI.PURPLE, 0.13), UI.col(UI.PURPLE, 0.55)))
	_moment_num = UI.lab("10", UI.mono(), 19, UI.col(UI.CYAN), 0.0, true)
	row.add_child(_kv_pill("MOMENT", _moment_num, UI.col(UI.CYAN), UI.col(UI.CYAN, 0.11), UI.col(UI.CYAN, 0.5)))

	var sep := ColorRect.new()
	sep.color = UI.col(UI.BORDER)
	sep.custom_minimum_size = Vector2(1, 40)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sep)

	_strip = UI.hbox(4)
	_strip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_strip)

	_nextreset = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 2.0)
	_nextreset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_nextreset)


## data: {clock_no: int, moment: int, slot_now: int (0..9), next_reset: String,
##        markers: [{slot: 0..9, emoji, name, active: bool, boss: bool,
##                   windup: bool, late: bool}]}
func update(data: Dictionary) -> void:
	_ensure_built()
	_clock_num.text = str(int(data.get("clock_no", 1)))
	_moment_num.text = "%02d" % int(data.get("moment", 10))
	_nextreset.text = String(data.get("next_reset", ""))
	var slot_now := int(data.get("slot_now", 0))
	var by_slot := {}
	for md in data.get("markers", []):
		var m: Dictionary = md
		var s := int(m.get("slot", 0))
		if not by_slot.has(s):
			by_slot[s] = []
		(by_slot[s] as Array).append(m)
	for ch in _strip.get_children():
		ch.queue_free()
	for i in 10:
		_strip.add_child(_cell(i, i == slot_now, by_slot.get(i, [])))


func _cell(i: int, now: bool, markers: Array) -> Control:
	var v := UI.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_END
	v.custom_minimum_size = Vector2(38, 0)
	# marker discs (may be several on one tick)
	var mrow := UI.hbox(2)
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	mrow.custom_minimum_size = Vector2(0, 26)
	for md in markers:
		var m: Dictionary = md
		var face := PanelContainer.new()
		var border := UI.col(UI.BORDER)
		var glow := Color(0, 0, 0, 0)
		if bool(m.get("active", false)):
			border = UI.col(UI.GOLD)
			glow = UI.col(UI.GOLD, 0.55)
		elif bool(m.get("boss", false)):
			border = UI.col(UI.FIRE)
		face.add_theme_stylebox_override("panel",
			UI.glow_sb(UI.col(UI.PANEL2), border, 7, glow, 5 if glow.a > 0.0 else 0))
		var cc := CenterContainer.new()
		cc.custom_minimum_size = Vector2(24, 24)
		cc.add_child(UI.emo(String(m.get("emoji", "🎪")), 12))
		face.add_child(cc)
		if bool(m.get("late", false)):
			face.modulate.a = 0.45  # acts next lap — drawn dim at the strip's edge
		face.tooltip_text = String(m.get("name", ""))
		mrow.add_child(face)
		if bool(m.get("windup", false)):
			var wu := PanelContainer.new()
			wu.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.FIRE, 0.9), UI.col(UI.FIRE, 0.0), 2))
			wu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var wm := UI.margin(3, 3, 1, 1)
			wu.add_child(wm)
			wm.add_child(UI.lab("W", UI.body(), 7, UI.col("#180a02"), 0.0, true))
			wu.tooltip_text = "WINDUP — committed, resolves later"
			mrow.add_child(wu)
	v.add_child(mrow)
	# the tick square, labelled with its MOMENT number (10..1 across the lap)
	var sq := PanelContainer.new()
	if now:
		sq.add_theme_stylebox_override("panel",
			UI.glow_sb(UI.col(UI.CYAN, 0.18), UI.col(UI.CYAN), 3, UI.col(UI.CYAN, 0.4), 5))
	else:
		sq.add_theme_stylebox_override("panel", UI.sb(UI.col("#0a0e1c"), UI.col(UI.BORDER), 3))
	var sm := UI.margin(0, 0, 1, 1)
	sq.add_child(sm)
	var num := UI.lab("%02d" % (10 - i), UI.mono(), 9,
		UI.col(UI.CYAN) if now else UI.col(UI.MUTED), 0.0, now)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sm.add_child(num)
	v.add_child(sq)
	return v


func _kv_pill(label_text: String, num_label: Label, text_col: Color, bg: Color, border: Color) -> Control:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UI.sb(bg, border, 4))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pm := UI.margin(12, 12, 6, 6)
	pill.add_child(pm)
	var h := UI.hbox(8)
	h.add_child(UI.lab(label_text, UI.body(), 12, text_col, 2.0, true))
	h.add_child(num_label)
	pm.add_child(h)
	return pill
