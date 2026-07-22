extends PanelContainer
## PartyRail — the LEFT-edge party overview (spec §3 Area 2): every party
## combatant as a PartyCard in a scrollable column. Emits card_clicked(id) for
## select/inspect. Dumb component: renders the card dicts it is handed.

signal card_clicked(id: String)

const UI := preload("res://ui/hud/components/hud_theme.gd")
const PartyCardScene := preload("res://ui/hud/components/party_card.tscn")

var _built := false
var _list: VBoxContainer


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL), UI.col(UI.BORDER), 5))
	var pad := UI.margin(9, 9, 9, 9)
	add_child(pad)
	var v := UI.vbox(6)
	pad.add_child(v)
	v.add_child(UI.h4("PARTY"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	_list = UI.vbox(7)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)


## cards: Array of PartyCard.update() dicts (see party_card.gd).
func update(cards: Array) -> void:
	_ensure_built()
	for ch in _list.get_children():
		ch.queue_free()
	for cd in cards:
		var card = PartyCardScene.instantiate()  # untyped: PartyCard methods are script-defined
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(card)
		card.update(cd)
		card.pressed.connect(func(id: String) -> void: card_clicked.emit(id))
