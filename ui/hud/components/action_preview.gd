extends PanelContainer
## ActionPreview — the CONFIRM step of the action flow (spec §3 Area 10, §8
## named component): shown when an armed action gets its target part picked
## (and for self-skills / the combined strike on pick). Shows the action name,
## actor -> target·part route, the honest Moment cost (+ the windup commitment
## note), the predicted result lines from the READ-ONLY preview probe (net
## damage / BLOCKED / riding conditions / dodge uncertainty), and an unmet
## prime as a red line with CONFIRM disabled. [CONFIRM] issues the real
## declare (the facade routes it to the existing direct method); [BACK]
## returns to the armed state. Esc / right-click = Back (facade-handled).
## Dumb component: renders the display dict it is handed.

signal confirmed
signal back_requested

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _title: Label
var _route: Label
var _cost: Label
var _windup: Label
var _lines: VBoxContainer
var _prime: Label
var _confirm_btn: PanelContainer
var _confirm_click: Button


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col("#0b1024", 0.97), UI.col(UI.CYAN, 0.6), 6, Color(0, 0, 0, 0.55), 12))
	custom_minimum_size = Vector2(390, 0)
	var m := UI.margin(14, 14, 12, 12)
	add_child(m)
	var v := UI.vbox(6)
	m.add_child(v)

	v.add_child(UI.lab("CONFIRM ACTION", UI.body(), 8, UI.col(UI.MUTED), 3.0, true))
	_title = UI.lab("", UI.body(), 14, UI.col(UI.CYAN), 1.0, true)
	v.add_child(_title)
	_route = UI.lab("", UI.body(), 10, UI.col(UI.TEXT), 0.5)
	v.add_child(_route)
	_cost = UI.lab("", UI.mono(), 11, UI.col(UI.GOLD), 0.5, true)
	v.add_child(_cost)
	_windup = UI.lab("", UI.body(), 9, UI.col(UI.FIRE), 0.5, true)
	_windup.visible = false
	v.add_child(_windup)

	UI.border_line(v)
	_lines = UI.vbox(3)
	v.add_child(_lines)

	_prime = UI.lab("", UI.body(), 10, UI.col(UI.DANGER), 0.5, true)
	_prime.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Autowrap needs a CONCRETE width or the container computes its minimum
	# height at width 0 and the panel explodes vertically.
	_prime.custom_minimum_size = Vector2(350, 0)
	_prime.visible = false
	v.add_child(_prime)

	var btns := UI.hbox(10)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_btn = _btn("CONFIRM", UI.col(UI.SUCCESS))
	_confirm_click = UI.attach_click(_confirm_btn, func() -> void: confirmed.emit())
	btns.add_child(_confirm_btn)
	var back := _btn("BACK", UI.col(UI.MUTED))
	UI.attach_click(back, func() -> void: back_requested.emit())
	btns.add_child(back)
	v.add_child(UI.pad_top(btns, 4))
	v.add_child(UI.lab("ESC / RIGHT-CLICK = BACK", UI.body(), 7, UI.col(UI.MUTED), 2.0))


func _btn(text: String, accent: Color) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel",
		UI.sb(Color(accent.r, accent.g, accent.b, 0.1), Color(accent.r, accent.g, accent.b, 0.55), 5))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var m := UI.margin(18, 18, 8, 8)
	c.add_child(m)
	m.add_child(UI.lab(text, UI.body(), 11, accent, 1.5, true))
	return c


## data: {title, route_line, cost_line, windup_line ("" = none),
##        result_lines: [{text, color: Color}], prime_line ("" = prime met),
##        confirm_enabled: bool}
func update(data: Dictionary) -> void:
	_ensure_built()
	_title.text = String(data.get("title", ""))
	_route.text = String(data.get("route_line", ""))
	_route.visible = _route.text != ""
	_cost.text = String(data.get("cost_line", ""))
	_windup.text = String(data.get("windup_line", ""))
	_windup.visible = _windup.text != ""
	for ch in _lines.get_children():
		_lines.remove_child(ch)  # out of the layout NOW — a re-show must not inherit stale height
		ch.queue_free()
	for ld in data.get("result_lines", []):
		var l: Dictionary = ld
		var lab := UI.lab(String(l.get("text", "")), UI.body(), 10,
			l.get("color", UI.col(UI.TEXT)), 0.3)
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size = Vector2(350, 0)  # concrete wrap width (see _prime)
		_lines.add_child(lab)
	var prime_line := String(data.get("prime_line", ""))
	_prime.text = prime_line
	_prime.visible = prime_line != ""
	var enabled := bool(data.get("confirm_enabled", true))
	_confirm_btn.modulate.a = 1.0 if enabled else 0.4
	if _confirm_click != null:
		_confirm_click.disabled = not enabled
