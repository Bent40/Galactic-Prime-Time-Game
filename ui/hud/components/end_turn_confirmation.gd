extends PanelContainer
## EndTurnConfirmation — the END TURN confirm step (spec §3 Area 12, §8 named
## component): opened by the END TURN button, so ending the Moment is never an
## unexplained generic click. Shows the current actor + whether they declared
## this tick ("… will wait" when not), the CLOCK/MOMENT advance (from -> to),
## who acts next, what RESOLVES next tick (the enemy telegraph from the
## view_schedule probe), and the party conditions that keep ticking. [CONFIRM]
## runs the existing direct _on_end_turn(); [CANCEL] leaves the tick untouched.
## Dumb component: renders the display dict it is handed.

signal confirmed
signal cancelled

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _actor: Label
var _clock: Label
var _next: Label
var _resolve_head: Label
var _resolves: VBoxContainer
var _conds: VBoxContainer


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col("#0b1024", 0.97), UI.col(UI.DANGER, 0.55), 6, Color(0, 0, 0, 0.55), 12))
	custom_minimum_size = Vector2(400, 0)
	var m := UI.margin(14, 14, 12, 12)
	add_child(m)
	var v := UI.vbox(6)
	m.add_child(v)

	v.add_child(UI.lab("END TURN", UI.body(), 13, UI.col("#ff6b88"), 3.0, true))
	_actor = UI.lab("", UI.body(), 11, UI.col(UI.TEXT), 0.5)
	v.add_child(_actor)
	_clock = UI.lab("", UI.mono(), 11, UI.col(UI.CYAN), 0.5, true)
	v.add_child(_clock)
	_next = UI.lab("", UI.body(), 10, UI.col(UI.GOLD), 0.5, true)
	v.add_child(_next)

	UI.border_line(v)
	_resolve_head = UI.lab("RESOLVES NEXT MOMENT", UI.body(), 8, UI.col(UI.MUTED), 2.5, true)
	v.add_child(_resolve_head)
	_resolves = UI.vbox(2)
	v.add_child(_resolves)
	_conds = UI.vbox(2)
	v.add_child(_conds)

	var btns := UI.hbox(10)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	var ok := _btn("CONFIRM", UI.col(UI.SUCCESS))
	UI.attach_click(ok, func() -> void: confirmed.emit())
	btns.add_child(ok)
	var cancel := _btn("CANCEL", UI.col(UI.MUTED))
	UI.attach_click(cancel, func() -> void: cancelled.emit())
	btns.add_child(cancel)
	v.add_child(UI.pad_top(btns, 4))
	v.add_child(UI.lab("ESC / RIGHT-CLICK = CANCEL", UI.body(), 7, UI.col(UI.MUTED), 2.0))


func _btn(text: String, accent: Color) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel",
		UI.sb(Color(accent.r, accent.g, accent.b, 0.1), Color(accent.r, accent.g, accent.b, 0.55), 5))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := UI.margin(18, 18, 8, 8)
	c.add_child(m)
	m.add_child(UI.lab(text, UI.body(), 11, accent, 1.5, true))
	return c


## data: {actor_line, clock_line, next_line,
##        resolve_lines: [{text, color: Color}]  (empty = quiet Moment),
##        cond_lines:    [{text, color: Color}]}
func update(data: Dictionary) -> void:
	_ensure_built()
	_actor.text = String(data.get("actor_line", ""))
	_clock.text = String(data.get("clock_line", ""))
	_next.text = String(data.get("next_line", ""))
	_next.visible = _next.text != ""
	for ch in _resolves.get_children():
		_resolves.remove_child(ch)  # out of the layout NOW (stale-height guard)
		ch.queue_free()
	var resolve_lines: Array = data.get("resolve_lines", [])
	if resolve_lines.is_empty():
		_resolves.add_child(UI.lab("Nothing scheduled resolves next Moment.",
			UI.body(), 9, UI.col(UI.MUTED), 0.3))
	for ld in resolve_lines:
		var l: Dictionary = ld
		var lab := UI.lab(String(l.get("text", "")), UI.body(), 10,
			l.get("color", UI.col(UI.TEXT)), 0.3)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Concrete wrap width — autowrap at width 0 explodes the panel height.
		lab.custom_minimum_size = Vector2(360, 0)
		_resolves.add_child(lab)
	for ch in _conds.get_children():
		_conds.remove_child(ch)  # out of the layout NOW (stale-height guard)
		ch.queue_free()
	for ld in data.get("cond_lines", []):
		var l: Dictionary = ld
		var lab := UI.lab(String(l.get("text", "")), UI.body(), 9,
			l.get("color", UI.col(UI.TEXT)), 0.3)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(360, 0)  # concrete wrap width
		_conds.add_child(lab)
