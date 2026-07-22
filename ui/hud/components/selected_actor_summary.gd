extends PanelContainer
## SelectedActorSummary — top-left immediate summary of the selected party
## member (spec §3 Area 1): portrait, name, persona (elided), patron, most
## urgent injury/condition, spotlight/tags state, current readiness.
## An immediate summary — full anatomy lives in the right-side EntityInspector.

const UI := preload("res://ui/hud/components/hud_theme.gd")

var _built := false
var _portrait: Panel
var _glyph: Label
var _name_lab: Label
var _persona_lab: Label
var _patron_lab: Label
var _ready_lab: Label
var _urgent_lab: Label
var _spot_lab: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL), UI.col(UI.BORDER), 5))
	var pad := UI.margin(11, 11, 7, 7)
	add_child(pad)
	var row := UI.hbox(10)
	pad.add_child(row)

	_portrait = Panel.new()
	_portrait.custom_minimum_size = Vector2(52, 52)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pc := CenterContainer.new()
	pc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.add_child(pc)
	_glyph = UI.emo("🎪", 26)
	pc.add_child(_glyph)
	row.add_child(_portrait)

	var v := UI.vbox(1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(v)

	var nrow := UI.hbox(8)
	_name_lab = UI.lab("", UI.body(), 15, UI.col(UI.GOLD), 0.5, true)
	nrow.add_child(_name_lab)
	_patron_lab = UI.lab("", UI.body(), 9, UI.col(UI.PURPLE), 1.0, true)
	_patron_lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nrow.add_child(_patron_lab)
	_ready_lab = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 1.0, true)
	_ready_lab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nrow.add_child(_ready_lab)
	v.add_child(nrow)

	_persona_lab = UI.lab("", UI.body(), 9, UI.col(UI.MUTED), 0.5)
	_persona_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_persona_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_persona_lab)
	_urgent_lab = UI.lab("", UI.mono(), 10, UI.col(UI.DANGER), 0.0, true)
	_urgent_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_urgent_lab)
	_spot_lab = UI.lab("", UI.body(), 9, UI.col(UI.GOLD, 0.85), 1.0)
	_spot_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_spot_lab)


## data: {name, emoji, persona, patron, patron_color: Color, ready_line,
##        acting: bool, urgent_line, spot_line}
func update(data: Dictionary) -> void:
	_ensure_built()
	var acting := bool(data.get("acting", false))
	var accent := UI.col(UI.GOLD) if acting else UI.col(UI.CYAN)
	_portrait.add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col("#0c1428"), accent, 9, Color(accent.r, accent.g, accent.b, 0.4), 5))
	_glyph.text = String(data.get("emoji", "🎪"))
	_name_lab.text = String(data.get("name", ""))
	_name_lab.add_theme_color_override("font_color", accent)
	_name_lab.add_theme_color_override("font_outline_color", accent)
	var patron := String(data.get("patron", ""))
	_patron_lab.text = ("⬢ " + patron.to_upper()) if patron != "" else ""
	var pcol: Color = data.get("patron_color", UI.col(UI.PURPLE))
	_patron_lab.add_theme_color_override("font_color", pcol)
	_patron_lab.add_theme_color_override("font_outline_color", pcol)
	_ready_lab.text = String(data.get("ready_line", ""))
	_ready_lab.add_theme_color_override("font_color",
		UI.col(UI.GOLD) if acting else UI.col(UI.MUTED))
	_ready_lab.add_theme_color_override("font_outline_color",
		UI.col(UI.GOLD) if acting else UI.col(UI.MUTED))
	_persona_lab.text = String(data.get("persona", ""))
	_urgent_lab.text = String(data.get("urgent_line", ""))
	_urgent_lab.visible = _urgent_lab.text != ""
	_spot_lab.text = String(data.get("spot_line", ""))
	_spot_lab.visible = _spot_lab.text != ""
