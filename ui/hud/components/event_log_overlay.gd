extends Control
## EventLogOverlay — the complete session event log (spec §3 Area 11 click-through):
## a modal overlay listing every sim_event the HUD has received this session
## (type + short line), newest last, scrollable. Esc or clicking the dimmed
## backdrop closes (close itself is handled by the facade via close_requested).

signal close_requested

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _list: VBoxContainer
var _scroll: ScrollContainer
var _count_lab: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close_requested.emit())
	add_child(dim)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col(UI.PANEL, 0.98), UI.col(UI.MYTHIC, 0.6), 6, Color(0, 0, 0, 0.6), 14))
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(680, 460)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var m := UI.margin(16, 16, 12, 12)
	panel.add_child(m)
	var v := UI.vbox(8)
	m.add_child(v)

	var head := UI.hbox(8)
	head.add_child(UI.emo("🦩", 16))
	head.add_child(UI.lab("EVENT LOG — THIS SESSION", UI.body(), 12, UI.col(UI.MYTHIC), 2.0, true))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_count_lab = UI.lab("", UI.mono(), 10, UI.col(UI.MUTED))
	head.add_child(_count_lab)
	v.add_child(head)
	UI.border_line(v)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_scroll)
	_list = UI.vbox(3)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)

	v.add_child(UI.lab("ESC / CLICK OUTSIDE CLOSES", UI.body(), 8, UI.col(UI.MUTED), 2.0))


## events: [{type, line}] — oldest first; rendered newest LAST and auto-scrolled.
func show_log(events: Array) -> void:
	_ensure_built()
	for ch in _list.get_children():
		ch.queue_free()
	if events.is_empty():
		_list.add_child(UI.lab("No events yet — the broadcast is just warming up.", UI.body(), 10, UI.col(UI.MUTED)))
	for ed in events:
		var e: Dictionary = ed
		var row := UI.hbox(8)
		var tchip := UI.lab(String(e.get("type", "")), UI.mono(), 9, UI.col(UI.CYAN, 0.8))
		tchip.custom_minimum_size.x = 170
		row.add_child(tchip)
		var line := UI.lab(String(e.get("line", "")), UI.body(), 10, UI.col(UI.TEXT))
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(line)
		_list.add_child(row)
	_count_lab.text = "%d EVENTS" % events.size()
	visible = true
	# jump to the newest entries once the list has laid out
	await get_tree().process_frame
	if _scroll != null:
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func hide_log() -> void:
	visible = false
