extends PanelContainer
## EntityInspector — right-side contextual inspector for the FOCUSED entity
## (spec §3 Area 7). Ally focus: full part list with HP + per-part conditions +
## shock. Enemy focus: KNOWN anatomy only — hidden parts arrive pre-masked from
## the facade (label already anonymized, no HP) so this component cannot leak;
## resistances line is a placeholder. The set-off ACTIVE STATUS section
## (status-prominence pass) fronts the condition tiers + state flags as a badge
## row above the part list — the facade aggregates over VISIBLE parts only, so
## the masking holds here too. While an action is armed, part rows become
## clickable and emit part_clicked(part_key) to pick the TARGET part.
## Dumb component: renders the display dict it is handed.

signal part_clicked(part_key: String)

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _glyph: Label
var _name_lab: Label
var _kind_lab: Label
var _status_lab: Label
var _badge_panel: PanelContainer
var _badge_flow: HFlowContainer
var _armed_lab: Label
var _rows: VBoxContainer
var _foot_lab: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL), UI.col(UI.BORDER), 5))
	var pad := UI.margin(12, 12, 10, 10)
	add_child(pad)
	var v := UI.vbox(5)
	pad.add_child(v)
	v.add_child(UI.h4("INSPECTOR"))

	var head := UI.hbox(8)
	_glyph = UI.emo("🎪", 20)
	head.add_child(_glyph)
	var hv := UI.vbox(0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_lab = UI.lab("", UI.body(), 13, UI.col(UI.TEXT), 0.5, true)
	_name_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hv.add_child(_name_lab)
	_kind_lab = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 2.0)
	hv.add_child(_kind_lab)
	head.add_child(hv)
	v.add_child(head)

	_status_lab = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 1.0)
	_status_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_status_lab)

	# ACTIVE STATUS — clearly set-off badge block (condition tiers + state flags)
	_badge_panel = PanelContainer.new()
	_badge_panel.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.PANEL2), UI.col(UI.BORDER), 4))
	var bm := UI.margin(8, 8, 5, 5)
	_badge_panel.add_child(bm)
	var bv := UI.vbox(4)
	bm.add_child(bv)
	bv.add_child(UI.lab("ACTIVE STATUS", UI.body(), 8, UI.col(UI.MUTED), 3.0, true))
	_badge_flow = HFlowContainer.new()
	_badge_flow.add_theme_constant_override("h_separation", 4)
	_badge_flow.add_theme_constant_override("v_separation", 4)
	bv.add_child(_badge_flow)
	v.add_child(_badge_panel)

	_armed_lab = UI.lab("", UI.body(), 9, UI.col(UI.GOLD), 1.0, true)
	_armed_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_armed_lab.visible = false
	v.add_child(_armed_lab)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	_rows = UI.vbox(4)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)

	_foot_lab = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.0)
	_foot_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_foot_lab)


## data: {name, emoji, kind_line, status_line,
##        status_badges: [{text, color: Color}], armed_line ("" = not armed),
##        parts: [{key, label, hp_text ("" = masked), ratio (-1 = unknown),
##                 conds: [{text, color: Color}], muted: bool, targetable: bool}],
##        foot_line}
func update(data: Dictionary) -> void:
	_ensure_built()
	_glyph.text = String(data.get("emoji", "❔"))
	_name_lab.text = String(data.get("name", "—"))
	_kind_lab.text = String(data.get("kind_line", ""))
	_status_lab.text = String(data.get("status_line", ""))
	_status_lab.visible = _status_lab.text != ""
	for ch in _badge_flow.get_children():
		ch.queue_free()
	var badges: Array = data.get("status_badges", [])
	for bd in badges:
		var b: Dictionary = bd
		_badge_flow.add_child(UI.badge(String(b.get("text", "")),
			b.get("color", UI.col(UI.DANGER))))
	if badges.is_empty():
		# honest empty state — the section stays discoverable, never fakes a badge
		_badge_flow.add_child(UI.lab("— NONE —", UI.body(), 8, UI.col(UI.MUTED), 1.5))
	_badge_panel.visible = not data.get("parts", []).is_empty() or not badges.is_empty()
	var armed_line := String(data.get("armed_line", ""))
	_armed_lab.text = armed_line
	_armed_lab.visible = armed_line != ""
	var armed := armed_line != ""
	for ch in _rows.get_children():
		ch.queue_free()
	for pd in data.get("parts", []):
		_rows.add_child(_part_row(pd, armed))
	_foot_lab.text = String(data.get("foot_line", ""))
	_foot_lab.visible = _foot_lab.text != ""


func _part_row(p: Dictionary, armed: bool) -> Control:
	var muted := bool(p.get("muted", false))
	var targetable := bool(p.get("targetable", false))
	var row := PanelContainer.new()
	var border := UI.col(UI.BORDER)
	if armed and targetable:
		border = UI.col(UI.GOLD, 0.55)
	row.add_theme_stylebox_override("panel", UI.sb(UI.col("#0a0e1c"), border, 4))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(8, 8, 4, 4)
	row.add_child(m)
	var v := UI.vbox(2)
	m.add_child(v)

	var top := UI.hbox(6)
	var name_col := UI.col(UI.MUTED) if muted else UI.col(UI.TEXT)
	var nl := UI.lab(String(p.get("label", "")), UI.body(), 10, name_col, 1.0, not muted)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(nl)
	var hp_text := String(p.get("hp_text", ""))
	if hp_text != "":
		var ratio := float(p.get("ratio", 1.0))
		var hc := UI.ramp(ratio)
		top.add_child(UI.lab(hp_text, UI.mono(), 11, hc, 0.0, true))
	v.add_child(top)

	var ratio2 := float(p.get("ratio", -1.0))
	if ratio2 >= 0.0:
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 4
		bar.max_value = 1.0
		bar.value = ratio2
		bar.add_theme_stylebox_override("background", UI.sb(UI.col("#060912"), UI.col("#060912"), 2, 0))
		var rc := UI.ramp(ratio2)
		bar.add_theme_stylebox_override("fill", UI.sb(rc, rc, 2, 0))
		v.add_child(bar)

	var conds: Array = p.get("conds", [])
	if not conds.is_empty():
		var crow := UI.hbox(5)
		for cd in conds:
			var c: Dictionary = cd
			var ccol: Color = c.get("color", UI.col(UI.DANGER))
			crow.add_child(UI.chip(
				UI.lab(String(c.get("text", "")), UI.body(), 8, ccol, 0.5, true),
				Color(ccol.r, ccol.g, ccol.b, 0.1), Color(ccol.r, ccol.g, ccol.b, 0.45), 8))
		v.add_child(crow)

	if armed and targetable:
		var key := String(p.get("key", ""))
		UI.attach_click(row, func() -> void: part_clicked.emit(key))
	return row
