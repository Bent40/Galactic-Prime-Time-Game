extends PanelContainer
## ActionFlyout — the temporary action menu (spec §3 Area 10): opens upward from
## the launcher, one category at a time, Esc/right-click closes (handled by the
## facade). The entry list is a SCROLLABLE column (characters can have MORE THAN
## 4 skills — ADOPTION.md correction), each entry showing its honest cost line.
## Dumb component: renders the entry dicts it is handed; emits entry_pressed(id).

signal entry_pressed(id: String)

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _title: Label
var _list: VBoxContainer


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col("#0b1024", 0.97), UI.col(UI.GOLD, 0.6), 6, Color(0, 0, 0, 0.5), 10))
	custom_minimum_size = Vector2(330, 0)
	var m := UI.margin(12, 12, 10, 10)
	add_child(m)
	var v := UI.vbox(6)
	m.add_child(v)
	_title = UI.lab("", UI.body(), 9, UI.col(UI.GOLD), 3.0, true)
	v.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	_list = UI.vbox(5)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	v.add_child(UI.lab("ESC / RIGHT-CLICK CLOSES", UI.body(), 7, UI.col(UI.MUTED), 2.0))


## data: {title, entries: [{id, label, sub, enabled: bool, accent: Color}]}
func update(data: Dictionary) -> void:
	_ensure_built()
	_title.text = String(data.get("title", ""))
	for ch in _list.get_children():
		ch.queue_free()
	var entries: Array = data.get("entries", [])
	for ed in entries:
		_list.add_child(_entry(ed))
	# scrollable, capped height — the list scales past 4 entries (ADOPTION.md)
	var scroll := _list.get_parent() as ScrollContainer
	scroll.custom_minimum_size.y = minf(260.0, float(maxi(1, entries.size())) * 52.0)


func _entry(e: Dictionary) -> Control:
	var enabled := bool(e.get("enabled", true))
	var accent: Color = e.get("accent", UI.col(UI.GOLD))
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", UI.sb(
		Color(accent.r, accent.g, accent.b, 0.08) if enabled else UI.col(UI.PANEL2),
		Color(accent.r, accent.g, accent.b, 0.55) if enabled else UI.col(UI.BORDER), 5))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(10, 10, 6, 6)
	row.add_child(m)
	var v := UI.vbox(1)
	m.add_child(v)
	var top := UI.lab(String(e.get("label", "")), UI.body(), 11,
		accent if enabled else UI.col(UI.MUTED), 1.0, true)
	top.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(top)
	var sub := UI.lab(String(e.get("sub", "")), UI.body(), 8,
		UI.col(UI.TEXT, 0.75) if enabled else UI.col(UI.MUTED, 0.7), 1.0)
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(sub)
	if not enabled:
		row.modulate.a = 0.55
	else:
		var id := String(e.get("id", ""))
		UI.attach_click(row, func() -> void: entry_pressed.emit(id))
	return row
