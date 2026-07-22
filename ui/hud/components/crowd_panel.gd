extends PanelContainer
## CrowdPanel — compact right-side crowd state (spec §3 Area 6): hype value +
## band, the active crowd goal + reward + time, the spotlight state, and the
## latest audience tag line. Compact by design; the expanded crowd view is a
## later phase. Dumb component: renders the display dict it is handed.

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _hype_val: Label
var _hype_bar: ProgressBar
var _hype_band: Label
var _goal_title: Label
var _goal_desc: Label
var _goal_pay: Label
var _goal_time: Label
var _spot_lab: Label
var _tag_lab: Label


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

	var hhead := UI.hbox(0)
	hhead.add_child(UI.lab("CROWD", UI.body(), 9, UI.col(UI.GOLD), 3.0, true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hhead.add_child(spacer)
	_hype_val = UI.glow("0", UI.mono(), 20, UI.col(UI.GOLD), 0.0, 0.0)
	hhead.add_child(_hype_val)
	hhead.add_child(UI.lab(" / 100", UI.mono(), 11, UI.col("#7a6a3a")))
	v.add_child(hhead)

	_hype_bar = ProgressBar.new()
	_hype_bar.show_percentage = false
	_hype_bar.custom_minimum_size.y = 12
	_hype_bar.max_value = 100
	_hype_bar.add_theme_stylebox_override("background", UI.sb(UI.col("#0a0e1c"), UI.col(UI.GOLD, 0.35), 5))
	_hype_bar.add_theme_stylebox_override("fill",
		UI.glow_sb(UI.col(UI.GOLD), UI.col(UI.GOLD, 0.0), 5, UI.col(UI.GOLD, 0.4), 5))
	v.add_child(_hype_bar)
	_hype_band = UI.lab("", UI.body(), 11, UI.col(UI.GOLD), 2.0, true)
	v.add_child(_hype_band)

	UI.border_line(v)

	_goal_title = UI.lab("", UI.body(), 12, UI.col(UI.CYAN), 1.0, true)
	_goal_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(UI.pad_top(_goal_title, 3))
	_goal_desc = UI.lab("", UI.body(), 9, UI.col(UI.TEXT))
	_goal_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_goal_desc)
	var meta := UI.hbox(8)
	_goal_pay = UI.lab("", UI.mono(), 9, UI.col(UI.SUCCESS), 1.0, true)
	meta.add_child(UI.chip(_goal_pay, UI.col(UI.SUCCESS, 0.1), UI.col(UI.SUCCESS, 0.4)))
	_goal_time = UI.lab("", UI.mono(), 9, UI.col(UI.PURPLE), 1.0, true)
	meta.add_child(UI.chip(_goal_time, UI.col(UI.PURPLE, 0.12), UI.col(UI.PURPLE, 0.45)))
	v.add_child(meta)

	UI.border_line(v)

	_spot_lab = UI.lab("", UI.body(), 9, UI.col(UI.GOLD, 0.9), 1.0)
	_spot_lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(UI.pad_top(_spot_lab, 3))
	_tag_lab = UI.lab("", UI.body(), 9, UI.col(UI.MYTHIC, 0.9), 1.0)
	_tag_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_tag_lab)


## data: {hype_meter: int, band_display, goal: {title, desc, pay, time} or {},
##        spot_line, tag_line}
func update(data: Dictionary) -> void:
	_ensure_built()
	var meter := int(data.get("hype_meter", 0))
	_hype_val.text = str(meter)
	_hype_bar.value = clampi(meter, 0, 100)
	_hype_band.text = "CROWD: %s" % String(data.get("band_display", ""))
	var goal: Dictionary = data.get("goal", {})
	if goal.is_empty():
		_goal_title.text = "NO ACTIVE GOAL"
		_goal_desc.text = ""
		_goal_pay.text = "—"
		_goal_time.text = "—"
	else:
		_goal_title.text = "🎯 " + String(goal.get("title", ""))
		_goal_desc.text = String(goal.get("desc", ""))
		_goal_pay.text = String(goal.get("pay", ""))
		_goal_time.text = String(goal.get("time", ""))
	_spot_lab.text = String(data.get("spot_line", ""))
	_tag_lab.text = String(data.get("tag_line", ""))
	_tag_lab.visible = _tag_lab.text != ""
