extends PanelContainer
## PartyCard — one party combatant on the left rail (spec §3 Area 2).
##
## PART-BASED, never just a bar (ADOPTION.md correction): shows the overall
## state word derived from parts plus 1–2 URGENT PART flags ("R-ARM 1/2 ·
## bleeding") plus the compact STATUS BADGE row (status-prominence pass:
## condition abbreviation + tier, shock tier, state flags — "BLD 2 · SHK 3 ·
## PRONE"). Ready/acting highlight, patron chip, click = select/inspect.
## Dumb component: renders exactly the display strings/colors it is handed.

signal pressed(id: String)

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _id := ""
var _built := false
var _pad: MarginContainer
var _portrait: Panel
var _portrait_glyph: Label
var _name_lab: Label
var _state_lab: Label
var _ready_lab: Label
var _patron_chip: PanelContainer
var _patron_lab: Label
var _flags_box: VBoxContainer
var _badge_flow: HFlowContainer


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	_pad = UI.margin(9, 9, 7, 7)
	add_child(_pad)
	var v := UI.vbox(4)
	_pad.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	_portrait = Panel.new()
	_portrait.custom_minimum_size = Vector2(34, 34)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pc := CenterContainer.new()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.add_child(pc)
	_portrait_glyph = UI.emo("🎪", 17)
	pc.add_child(_portrait_glyph)
	head.add_child(_portrait)

	var idbox := UI.vbox(1)
	idbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_name_lab = UI.lab("", UI.body(), 12, UI.col(UI.TEXT), 0.5, true)
	_name_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	idbox.add_child(_name_lab)
	_state_lab = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.5)
	idbox.add_child(_state_lab)
	head.add_child(idbox)

	var right := UI.vbox(2)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ready_lab = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.0, true)
	_ready_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(_ready_lab)
	_patron_chip = PanelContainer.new()
	_patron_chip.visible = false
	var pm := UI.margin(7, 7, 2, 2)
	_patron_chip.add_child(pm)
	var prow := UI.hbox(4)
	pm.add_child(prow)
	prow.add_child(UI.lab("⬢", UI.sym(), 9, UI.col(UI.MUTED)))
	_patron_lab = UI.lab("", UI.body(), 8, UI.col(UI.MUTED), 1.0, true)
	prow.add_child(_patron_lab)
	right.add_child(_patron_chip)
	head.add_child(right)

	# urgent part flags (1–2) — the part-based read at a glance
	_flags_box = UI.vbox(2)
	v.add_child(_flags_box)
	# status badge row — condition tiers / shock / state flags, wrapping
	_badge_flow = HFlowContainer.new()
	_badge_flow.add_theme_constant_override("h_separation", 3)
	_badge_flow.add_theme_constant_override("v_separation", 3)
	v.add_child(_badge_flow)

	UI.attach_click(self, func() -> void: pressed.emit(_id))


## data: {id, name, emoji, state_word, state_color: Color, ready_line,
##        acting: bool, selected: bool, alive: bool, patron, patron_color: Color,
##        urgent: [{text, color: Color}], badges: [{text, color: Color}]}
func update(data: Dictionary) -> void:
	_ensure_built()
	_id = String(data.get("id", ""))
	var acting := bool(data.get("acting", false))
	var selected := bool(data.get("selected", false))
	var alive := bool(data.get("alive", true))

	var border := UI.col(UI.BORDER)
	var glow := Color(0, 0, 0, 0)
	if acting:
		border = UI.col(UI.GOLD)
		glow = UI.col(UI.GOLD, 0.25)
	elif selected:
		border = UI.col(UI.CYAN, 0.7)
	if not alive:
		border = UI.col(UI.MUTED, 0.5)
	add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col(UI.PANEL2), border, 5, glow, 6 if glow.a > 0.0 else 0))

	var accent := UI.col(UI.GOLD) if acting else UI.col(UI.CYAN)
	if not alive:
		accent = UI.col(UI.MUTED)
	_portrait.add_theme_stylebox_override("panel",
		UI.sb(UI.col("#0c1428"), Color(accent.r, accent.g, accent.b, 0.6), 8))
	_portrait_glyph.text = String(data.get("emoji", "🎪"))
	_name_lab.text = String(data.get("name", ""))
	_name_lab.add_theme_color_override("font_color", accent)
	_name_lab.add_theme_color_override("font_outline_color", accent)
	_state_lab.text = String(data.get("state_word", ""))
	var sc: Color = data.get("state_color", UI.col(UI.MUTED))
	_state_lab.add_theme_color_override("font_color", sc)
	_ready_lab.text = String(data.get("ready_line", ""))
	_ready_lab.add_theme_color_override("font_color",
		UI.col(UI.GOLD) if acting else UI.col(UI.MUTED))
	_ready_lab.add_theme_color_override("font_outline_color",
		UI.col(UI.GOLD) if acting else UI.col(UI.MUTED))

	var patron := String(data.get("patron", ""))
	_patron_chip.visible = patron != ""
	if patron != "":
		var pcol: Color = data.get("patron_color", UI.col(UI.PURPLE))
		_patron_chip.add_theme_stylebox_override("panel",
			UI.sb(Color(pcol.r, pcol.g, pcol.b, 0.1), Color(pcol.r, pcol.g, pcol.b, 0.5), 10))
		_patron_lab.text = patron.to_upper()
		_patron_lab.add_theme_color_override("font_color", pcol)
		_patron_lab.add_theme_color_override("font_outline_color", pcol)

	for ch in _flags_box.get_children():
		ch.queue_free()
	for fd in data.get("urgent", []):
		var f: Dictionary = fd
		var fcol: Color = f.get("color", UI.col(UI.DANGER))
		var fl := UI.lab("▸ " + String(f.get("text", "")), UI.mono(), 9, fcol, 0.0, true)
		fl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_flags_box.add_child(fl)
	for ch in _badge_flow.get_children():
		ch.queue_free()
	var badges: Array = data.get("badges", [])
	for bd in badges:
		var b: Dictionary = bd
		_badge_flow.add_child(UI.badge(String(b.get("text", "")),
			b.get("color", UI.col(UI.DANGER))))
	_badge_flow.visible = not badges.is_empty()
