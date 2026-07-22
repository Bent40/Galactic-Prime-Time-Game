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
##
## Phase 2 — DECLARED-ACTION BARS (spec Area 4): under the strip, one
## horizontal bar per pending view_schedule row spanning declared -> resolve
## slot on the lap (clamped; carry-over past the lap marked "▸"), labelled
## actor token + action key. Windup bars are visually distinct (bright border +
## W tag) and ENEMY windup bars ride the danger accent — the telegraph.

const UI := preload("res://ui/hud/components/hud_theme.gd")

const SLOT_W := 38.0   # tick square min width (px)
const SLOT_SEP := 4.0  # strip separation (px)
const BAR_H := 13.0    # one bar lane (px)
const MAX_LANES := 3

var _built := false
var _clock_num: Label
var _moment_num: Label
var _nextreset: Label
var _strip: HBoxContainer
var _bars_lane: Control


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

	# strip + the declared-action bars lane share one left origin so bar x
	# positions line up with the tick squares beneath the markers.
	var strip_col := UI.vbox(2)
	strip_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_strip = UI.hbox(int(SLOT_SEP))
	strip_col.add_child(_strip)
	_bars_lane = Control.new()
	_bars_lane.custom_minimum_size = Vector2(10 * SLOT_W + 9 * SLOT_SEP, 0)
	_bars_lane.clip_contents = true
	strip_col.add_child(_bars_lane)
	row.add_child(strip_col)

	_nextreset = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 2.0)
	_nextreset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_nextreset)


## data: {clock_no: int, moment: int, slot_now: int (0..9), next_reset: String,
##        markers: [{slot: 0..9, emoji, name, active: bool, boss: bool,
##                   windup: bool, late: bool}],
##        bars: [{from_slot: 0..9, to_slot: 0..9, carry: bool, windup: bool,
##                enemy: bool, emoji, label, name}]}
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
	_update_bars(data.get("bars", []))


## Declared-action bars: greedy first-fit lane packing (bars that overlap in
## slot span stack into separate lanes, capped at MAX_LANES).
func _update_bars(bars: Array) -> void:
	for ch in _bars_lane.get_children():
		ch.queue_free()
	var lanes: Array = []  # per lane: Array of [from, to]
	var shown := 0
	for bd in bars:
		var b: Dictionary = bd
		var from_slot := clampi(int(b.get("from_slot", 0)), 0, 9)
		var to_slot := clampi(int(b.get("to_slot", 0)), from_slot, 9)
		var lane := -1
		for li in lanes.size():
			var fits := true
			for span in lanes[li]:
				if from_slot <= int((span as Array)[1]) and to_slot >= int((span as Array)[0]):
					fits = false
					break
			if fits:
				lane = li
				break
		if lane < 0:
			if lanes.size() >= MAX_LANES:
				lane = lanes.size() - 1  # overflow rides the last lane (demo scale)
			else:
				lanes.append([])
				lane = lanes.size() - 1
		(lanes[lane] as Array).append([from_slot, to_slot])
		_bars_lane.add_child(_bar(b, from_slot, to_slot, lane))
		shown += 1
	_bars_lane.custom_minimum_size.y = (BAR_H + 2.0) * float(mini(lanes.size(), MAX_LANES)) if shown > 0 else 0.0


func _bar(b: Dictionary, from_slot: int, to_slot: int, lane: int) -> Control:
	var windup := bool(b.get("windup", false))
	var enemy := bool(b.get("enemy", false))
	var carry := bool(b.get("carry", false))
	# The telegraph accents: enemy windups = DANGER; party windups = FIRE;
	# instants/moves = muted cyan. Windups get the bright border + W tag.
	var accent := UI.col(UI.CYAN)
	if windup:
		accent = UI.col(UI.DANGER) if enemy else UI.col(UI.FIRE)
	elif enemy:
		accent = UI.col("#ff6b88")
	var bar := PanelContainer.new()
	bar.position = Vector2(float(from_slot) * (SLOT_W + SLOT_SEP), float(lane) * (BAR_H + 2.0))
	bar.custom_minimum_size = Vector2(
		float(to_slot - from_slot) * (SLOT_W + SLOT_SEP) + SLOT_W, BAR_H)
	bar.add_theme_stylebox_override("panel", UI.glow_sb(
		Color(accent.r, accent.g, accent.b, 0.30 if windup else 0.16),
		Color(accent.r, accent.g, accent.b, 0.95 if windup else 0.45), 3,
		Color(accent.r, accent.g, accent.b, 0.5) if windup else Color(0, 0, 0, 0),
		4 if windup else 0))
	bar.clip_contents = true
	bar.tooltip_text = String(b.get("name", ""))
	var m := UI.margin(4, 4, 0, 0)
	bar.add_child(m)
	var h := UI.hbox(3)
	m.add_child(h)
	h.add_child(UI.emo(String(b.get("emoji", "")), 8))
	var text := String(b.get("label", ""))
	if windup:
		text = "W· " + text
	if carry:
		text += " ▸"  # resolves past this lap's edge
	var l := UI.lab(text, UI.body(), 7, accent, 0.5, windup)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return bar


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
