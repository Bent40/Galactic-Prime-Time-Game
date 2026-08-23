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
var _chain_flag: PanelContainer
var _chain_box: PanelContainer
var _chain_title: Label
var _chain_body: RichTextLabel
var _chain_foot: Label
var _chain_chip: PanelContainer


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
	var bandrow := UI.hbox(6)
	_hype_band = UI.lab("", UI.body(), 11, UI.col(UI.GOLD), 2.0, true)
	bandrow.add_child(_hype_band)
	var bandspacer := Control.new()
	bandspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bandrow.add_child(bandspacer)
	# The armed flag rides the band line (frame 4's HYPE CHAIN ARMED chip).
	_chain_flag = UI.chip(UI.lab("HYPE CHAIN ARMED", UI.body(), 8, UI.col(UI.MYTHIC), 1.5, true),
		UI.col(UI.MYTHIC, 0.12), UI.col(UI.MYTHIC, 0.6)) as PanelContainer
	_chain_flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chain_flag.visible = false
	bandrow.add_child(_chain_flag)
	v.add_child(bandrow)

	# ---- R29 HYPE-CHAIN banner (approved frame 4) ------------------------
	_chain_box = PanelContainer.new()
	_chain_box.add_theme_stylebox_override("panel",
		UI.sb(UI.col(UI.MYTHIC, 0.07), UI.col(UI.MYTHIC, 0.45), 5))
	_chain_box.visible = false
	var cm := UI.margin(10, 10, 7, 7)
	_chain_box.add_child(cm)
	var cv := UI.vbox(4)
	cm.add_child(cv)
	_chain_title = UI.lab("", UI.body(), 11, UI.col(UI.MYTHIC), 1.5, true)
	cv.add_child(_chain_title)
	# RichText so the carry ARITHMETIC can be emphasised inside the sentence
	# the way the frame emphasises it, without splitting it into fake fields.
	_chain_body = RichTextLabel.new()
	_chain_body.bbcode_enabled = true
	_chain_body.fit_content = true
	_chain_body.scroll_active = false
	_chain_body.custom_minimum_size = Vector2(0, 0)
	_chain_body.add_theme_font_override("normal_font", UI.body())
	_chain_body.add_theme_font_override("bold_font", UI.body())
	_chain_body.add_theme_font_override("mono_font", UI.mono())
	_chain_body.add_theme_font_size_override("normal_font_size", 9)
	_chain_body.add_theme_font_size_override("bold_font_size", 9)
	_chain_body.add_theme_font_size_override("mono_font_size", 9)
	_chain_body.add_theme_color_override("default_color", UI.col(UI.TEXT))
	cv.add_child(_chain_body)
	_chain_foot = UI.lab("", UI.body(), 8, UI.col(UI.GOLD), 1.5, true)
	_chain_chip = UI.chip(_chain_foot, UI.col(UI.GOLD, 0.10), UI.col(UI.GOLD, 0.55)) as PanelContainer
	_chain_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cv.add_child(_chain_chip)
	v.add_child(_chain_box)

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
##        spot_line, tag_line,
##        chain: {} | {armed: bool, title, body (bbcode), foot}}
##
## R29 HYPE CHAIN (approved frame 4). `chain` is the carry banner: while a
## chain is armed the panel states the math in words — which rung of the
## retention ladder the next room sits on, the live meter, and the head start
## that falls out — and flags the band line ARMED. {} hides the whole block
## (nothing to chain, or no run staged); an unarmed non-empty block still
## renders, because "this room ends the run, the meter is banked" is a fact
## the crowd panel owes the player just as much as the carry.
func update(data: Dictionary) -> void:
	_ensure_built()
	var meter := int(data.get("hype_meter", 0))
	_hype_val.text = str(meter)
	_hype_bar.value = clampi(meter, 0, 100)
	_hype_band.text = "CROWD: %s" % String(data.get("band_display", ""))
	var chain: Dictionary = data.get("chain", {})
	_chain_box.visible = not chain.is_empty()
	_chain_flag.visible = bool(chain.get("armed", false))
	if not chain.is_empty():
		var armed := bool(chain.get("armed", false))
		var accent: Color = UI.col(UI.MYTHIC) if armed else UI.col(UI.MUTED)
		_chain_box.add_theme_stylebox_override("panel",
			UI.sb(Color(accent.r, accent.g, accent.b, 0.07),
				Color(accent.r, accent.g, accent.b, 0.45), 5))
		_chain_title.text = String(chain.get("title", ""))
		_chain_title.add_theme_color_override("font_color", accent)
		_chain_title.add_theme_color_override("font_outline_color", accent)
		_chain_body.text = String(chain.get("body", ""))
		_chain_foot.text = String(chain.get("foot", ""))
		_chain_chip.visible = _chain_foot.text != ""
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
