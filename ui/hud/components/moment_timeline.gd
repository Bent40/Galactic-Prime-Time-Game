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
## R34 (decision #36, 2026-08-19) — THE TELEGRAPH LEFT THIS STRIP. Enemy
## declared-action bands are RETIRED here: enemy intent is read off the ENEMY
## now (the per-token intent icon on the board, hover = the full explanation),
## and R26's ⛔ undodgable declaration moved onto that icon. This strip keeps
## ORDER AND TIMING ONLY.
##
## What survives, and why: the PARTY's own declared-action bars (spec Area 4).
## Your own declaration's span is timing — it is where "your feint lands on
## Moment 05" is legible — not a telegraph of someone else's move, and the
## approved frame 2 keeps exactly this one band ("YOUR DECLARATION"). Frames 1
## and 3 carry no bands at all, which is what an all-enemy schedule now draws.
## The facade filters: it hands this component party rows only.
##
## MODE A — FREE-FORM EXPLORATION (R34 TIME AMENDMENT / R35, approved frame 4).
## Out of combat there is no turn order and nothing costs Moments, so the timing
## strip has nothing to time: this component swaps to the EXPLORATION strip in
## the same slot — "OUT OF COMBAT", the elapsed readout, the PAUSE control, the
## no-turn-order statement and the route breadcrumb. Time still RUNS (the ruling
## is "the clock runs, there is no turn ORDER"), which is why the elapsed
## readout is here at all and why PAUSE is a real control: pausing is the DRIVER
## declining to issue time steps, and this chip is how the player asks for it.

signal pause_toggled          ## the strip's PAUSE / RESUME control was clicked

const UI := preload("res://ui/hud/components/hud_theme.gd")

const SLOT_W := 38.0   # tick square min width (px)
const SLOT_SEP := 4.0  # strip separation (px)
const BAR_H := 13.0    # one bar lane (px)
const MAX_LANES := 3
## Condition-tick chip lane (approved frame 1, decision 2 + decision 4).
const TICK_H := 15.0
## How many chips the lane draws before it collapses into a "+N MORE" chip.
## A wide fight can schedule a lot of bites; the strip is a fixed-width band,
## so the overflow is stated rather than silently clipped.
const MAX_TICK_CHIPS := 6
## How many marker discs one tick cell draws before the rest become a "+N".
const MAX_CELL_MARKERS := 4

var _built := false
var _clock_num: Label
var _moment_num: Label
var _nextreset: Label
var _strip: HBoxContainer
var _bars_lane: Control
var _ticks_lane: Control
var _combat_row: Control
var _explore_row: Control
var _mode_lab: Label
var _pause_lab: Label
var _pause_chip: PanelContainer
var _elapsed_lab: Label
var _crumbs: HBoxContainer
var _explore_note: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL), UI.col(UI.BORDER), 5))
	var pad := UI.margin(14, 14, 5, 5)
	add_child(pad)
	var stack := UI.vbox(0)
	pad.add_child(stack)
	var row := UI.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(row)
	_combat_row = row

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
	# The condition-tick lane sits BELOW the declared-action bars and never
	# shares a row with them: a scheduled bite is a different kind of fact from
	# a declared action, and frame 1 gives it its own lane for exactly that
	# reason. Same left origin as the strip, so a chip's x IS its Moment.
	_ticks_lane = Control.new()
	_ticks_lane.custom_minimum_size = Vector2(10 * SLOT_W + 9 * SLOT_SEP, 0)
	_ticks_lane.clip_contents = true
	strip_col.add_child(_ticks_lane)
	row.add_child(strip_col)

	_nextreset = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 2.0)
	_nextreset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_nextreset)

	_explore_row = _build_explore_row()
	_explore_row.visible = false
	stack.add_child(_explore_row)


## Builds the MODE A strip (frame 4): mode chip + PAUSE control · elapsed ·
## route breadcrumb · the no-turn-order statement.
func _build_explore_row() -> Control:
	var row := UI.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.custom_minimum_size = Vector2(0, 56)

	var modes := UI.vbox(4)
	modes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mode_lab = UI.lab("✦ OUT OF COMBAT", UI.body(), 11, UI.col(UI.SUCCESS), 2.0, true)
	modes.add_child(UI.chip(_mode_lab, UI.col(UI.SUCCESS, 0.10), UI.col(UI.SUCCESS, 0.55)))
	_pause_lab = UI.lab("⏸ PAUSE", UI.body(), 10, UI.col(UI.GOLD), 2.0, true)
	_pause_chip = UI.chip(_pause_lab, UI.col(UI.GOLD, 0.10), UI.col(UI.GOLD, 0.6)) as PanelContainer
	UI.attach_click(_pause_chip, func() -> void: pause_toggled.emit())
	modes.add_child(_pause_chip)
	row.add_child(modes)

	# Elapsed: R0/R1's own conversion (one tick ~ 0.5 fictional seconds) applied
	# to the live tick — a real readout of the running clock, not a wall clock.
	_elapsed_lab = UI.lab("⏱ 00:00", UI.mono(), 15, UI.col(UI.PURPLE), 0.0, true)
	var elapsed_chip := UI.chip(_elapsed_lab, UI.col(UI.PURPLE, 0.13), UI.col(UI.PURPLE, 0.55))
	elapsed_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(elapsed_chip)

	var mid := UI.vbox(5)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_crumbs = UI.hbox(8)
	mid.add_child(_crumbs)
	_explore_note = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.5)
	mid.add_child(_explore_note)
	row.add_child(mid)
	return row


## data: {clock_no: int, moment: int, slot_now: int (0..9), next_reset: String,
##        markers: [{slot: 0..9, emoji, name, active: bool, boss: bool,
##                   windup: bool, late: bool}],
##        bars: [{from_slot: 0..9, to_slot: 0..9, carry: bool, windup: bool,
##                emoji, label, name}]  — PARTY rows only (R34, see above)
##        ticks: [{slot: 0..9, emoji, label, color: Color, carry: bool,
##                name}] — SCHEDULED CONDITION TICKS on their own lane
##                (approved frame 1: "🔥 BURN II → DARIO"). A tick is TIMING,
##                which is what this strip keeps; it is NOT enemy intent,
##                which R34 moved onto the enemy's own icon. Conditions bite
##                at the CLOCK RESET, so every chip lands on the lap's last
##                slot; `carry` marks one whose reset is a LATER lap (an
##                incubating poison, a delayed bleed) and draws it dim.}
##        explore: {} in combat, else {elapsed: "MM:SS", paused: bool,
##                 note: String, crumbs: [{text, state: "done"|"here"|"ahead"}]}
##                 — a non-empty `explore` swaps this slot to MODE A.
func update(data: Dictionary) -> void:
	_ensure_built()
	var explore: Dictionary = data.get("explore", {})
	_combat_row.visible = explore.is_empty()
	_explore_row.visible = not explore.is_empty()
	if not explore.is_empty():
		_bind_explore(explore)
		return
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
	_update_ticks(data.get("ticks", []))


## MODE A binding. PAUSED is DRIVER state, never sim state (R34/R35, twice
## ruled) — the facade hands it down; this component only shows and asks.
func _bind_explore(explore: Dictionary) -> void:
	var paused := bool(explore.get("paused", false))
	_mode_lab.text = "✦ OUT OF COMBAT"
	_pause_lab.text = "▶ RESUME TIME" if paused else "⏸ PAUSE"
	var accent: Color = UI.col(UI.SUCCESS) if paused else UI.col(UI.GOLD)
	_pause_lab.add_theme_color_override("font_color", accent)
	_pause_lab.add_theme_color_override("font_outline_color", accent)
	_pause_chip.add_theme_stylebox_override("panel",
		UI.sb(Color(accent.r, accent.g, accent.b, 0.10), Color(accent.r, accent.g, accent.b, 0.6), 4))
	_elapsed_lab.text = "⏸ %s" % String(explore.get("elapsed", "00:00")) if paused \
		else "⏱ %s" % String(explore.get("elapsed", "00:00"))
	_explore_note.text = String(explore.get("note", ""))
	for ch in _crumbs.get_children():
		ch.queue_free()
	for raw: Variant in explore.get("crumbs", []):
		var crumb: Dictionary = raw
		var state := String(crumb.get("state", "ahead"))
		var tint: Color = UI.col(UI.MUTED)
		if state == "done":
			tint = UI.col(UI.SUCCESS)
		elif state == "here":
			tint = UI.col(UI.CYAN)
		var lab := UI.lab(String(crumb.get("text", "")), UI.body(), 9, tint, 1.5, state != "ahead")
		_crumbs.add_child(UI.chip(lab, Color(tint.r, tint.g, tint.b, 0.10),
			Color(tint.r, tint.g, tint.b, 0.5)))


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
	var carry := bool(b.get("carry", false))
	# Accents (party-only now — the enemy DANGER accent retired with the enemy
	# bands): a committed windup burns FIRE, an instant/move is muted cyan.
	var accent := UI.col(UI.FIRE) if windup else UI.col(UI.CYAN)
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


## Condition-tick chips. Conditions bite at the CLOCK RESET, so every chip in a
## group shares one slot: the group is packed so its RUN ENDS on that slot's
## cell — the eye lands on "these all land there" instead of on a stack in the
## corner. A group too wide for the band wraps onto another lane row, and a
## lane with more chips than MAX_TICK_CHIPS says so with a "+N MORE" chip
## rather than clipping the overflow into invisibility.
func _update_ticks(ticks: Array) -> void:
	for ch in _ticks_lane.get_children():
		ch.queue_free()
	if ticks.is_empty():
		_ticks_lane.custom_minimum_size.y = 0.0
		return
	var shown: Array = ticks.slice(0, MAX_TICK_CHIPS)
	var hidden: int = ticks.size() - shown.size()
	var lane_w: float = 10.0 * SLOT_W + 9.0 * SLOT_SEP
	# group by slot, preserving the facade's ordering within each group
	var order: Array = []
	var groups: Dictionary = {}
	for raw: Variant in shown:
		var t: Dictionary = raw
		var slot: int = clampi(int(t.get("slot", 9)), 0, 9)
		if not groups.has(slot):
			groups[slot] = []
			order.append(slot)
		(groups[slot] as Array).append(_tick_chip(t))
	if hidden > 0:
		var more_slot: int = clampi(int((shown.back() as Dictionary).get("slot", 9)), 0, 9)
		if not groups.has(more_slot):
			groups[more_slot] = []
			order.append(more_slot)
		(groups[more_slot] as Array).append(_tick_chip({
			"label": "+%d MORE" % hidden, "emoji": "⋯", "color": UI.col(UI.MUTED),
			"name": "%d more scheduled condition ticks than the lane can draw" % hidden}))
	var y: float = 0.0
	var rows: int = 0
	for slot_v: Variant in order:
		var slot: int = slot_v
		var chips: Array = groups[slot]
		var total: float = 0.0
		for c: Variant in chips:
			total += (c as Control).custom_minimum_size.x + 4.0
		total -= 4.0
		# the right edge of this slot's cell — where the run should END
		var edge: float = float(slot) * (SLOT_W + SLOT_SEP) + SLOT_W
		var x: float = clampf(edge - total, 0.0, maxf(0.0, lane_w - total))
		for c: Variant in chips:
			var chip := c as Control
			if x + chip.custom_minimum_size.x > lane_w and x > 0.0:
				x = 0.0
				y += TICK_H + 2.0
				rows += 1
			chip.position = Vector2(x, y)
			_ticks_lane.add_child(chip)
			x += chip.custom_minimum_size.x + 4.0
		y += TICK_H + 2.0
		rows += 1
	_ticks_lane.custom_minimum_size.y = float(maxi(1, rows)) * (TICK_H + 2.0)


func _tick_chip(t: Dictionary) -> Control:
	var accent: Color = t.get("color", UI.col(UI.FIRE))
	var carry := bool(t.get("carry", false))
	var text := String(t.get("label", ""))
	var chip := PanelContainer.new()
	# Dark fill, bright rim, bright text: the condition's colour has to read as
	# the TEXT, not as a slab — a chip filled at the same hue as its label is
	# just a coloured bar with nothing legible on it.
	chip.add_theme_stylebox_override("panel", UI.glow_sb(
		Color(accent.r * 0.22, accent.g * 0.22, accent.b * 0.22, 0.92),
		Color(accent.r, accent.g, accent.b, 0.40 if carry else 0.95), 3,
		Color(0, 0, 0, 0) if carry else Color(accent.r, accent.g, accent.b, 0.40),
		0 if carry else 4))
	chip.clip_contents = true
	chip.tooltip_text = String(t.get("name", ""))
	var m := UI.margin(4, 4, 0, 0)
	chip.add_child(m)
	var h := UI.hbox(3)
	m.add_child(h)
	h.add_child(UI.emo(String(t.get("emoji", "")), 9))
	var l := UI.lab(text, UI.body(), 8, accent, 0.5, not carry)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# EXPAND_FILL is load-bearing, not decoration: a trimmed Label reports a
	# minimum width of ~1px, so without it the row hands the label nothing and
	# the chip renders as an emoji on an empty slab.
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	# Width is the chip's own content, capped so one long name cannot eat the
	# lane (~5.2px per char at size 7 + the emoji and padding).
	chip.custom_minimum_size = Vector2(
		minf(220.0, 32.0 + float(text.length()) * 5.9), TICK_H)
	if carry:
		chip.modulate.a = 0.6
	return chip


func _cell(i: int, now: bool, markers: Array) -> Control:
	var v := UI.vbox(2)
	v.alignment = BoxContainer.ALIGNMENT_END
	v.custom_minimum_size = Vector2(38, 0)
	# marker discs (may be several on one tick). CAPPED: a cell's width is its
	# content's width, so an unbounded pile of discs on one tick widens the
	# whole strip and pushes the top band off a 1600-wide HUD. Past the cap the
	# rest are counted, not drawn.
	var mrow := UI.hbox(2)
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	mrow.custom_minimum_size = Vector2(0, 26)
	var overflow: int = maxi(0, markers.size() - MAX_CELL_MARKERS)
	if overflow > 0:
		markers = markers.slice(0, MAX_CELL_MARKERS)
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
	if overflow > 0:
		var more := UI.lab("+%d" % overflow, UI.mono(), 9, UI.col(UI.MUTED), 0.0, true)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		more.tooltip_text = "%d more combatants act on this Moment" % overflow
		mrow.add_child(more)
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
