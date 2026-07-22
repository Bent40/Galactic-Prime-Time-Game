extends PanelContainer
## MomusTicker — full-width bottom broadcast ticker (spec §3 Area 11): the Momus
## commentary line + the most recent event one-liners. CLICK anywhere on it to
## open the EventLogOverlay (the facade owns the overlay). Flavor only — stable
## warnings live in the timeline / rail / inspector, never only here.

signal clicked

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _line: RichTextLabel
var _recent: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col("#0d0510"), UI.col(UI.MYTHIC, 0.4), 5))
	var row := UI.hbox(0)
	add_child(row)

	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.MYTHIC, 0.18), UI.col(UI.MYTHIC, 0.0), 0))
	var bm := UI.margin(16, 16, 0, 0)
	badge.add_child(bm)
	var brow := UI.hbox(7)
	brow.alignment = BoxContainer.ALIGNMENT_CENTER
	bm.add_child(brow)
	brow.add_child(UI.emo("🦩", 17))
	brow.add_child(UI.lab("MOMUS", UI.body(), 12, UI.col(UI.MYTHIC), 3.0, true))
	row.add_child(badge)

	var lm := MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 18)
	lm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_line = UI.rich_line([["", UI.col("#e8d0dc"), false]], 14)
	_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lm.add_child(_line)
	row.add_child(lm)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	_recent = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 0.5)
	_recent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_recent.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(_recent)

	var logm := UI.margin(12, 14, 0, 0)
	logm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logm.add_child(UI.lab("▸ EVENT LOG", UI.body(), 9, UI.col(UI.MYTHIC, 0.8), 1.5, true))
	row.add_child(logm)

	UI.attach_click(self, func() -> void: clicked.emit())


func set_momus(text: String) -> void:
	_ensure_built()
	_line.text = "[color=#e8d0dc]\"%s\"[/color]" % text


## data: {recent_line} — the last event one-liners, pre-joined by the facade.
func update(data: Dictionary) -> void:
	_ensure_built()
	_recent.text = String(data.get("recent_line", ""))
