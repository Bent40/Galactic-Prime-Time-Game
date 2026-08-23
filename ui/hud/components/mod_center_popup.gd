extends Control
## ModCenterPopup — THE MODIFICATION CENTER, as MODE D (approved frame 5,
## docs/ux-designs/front-rework-2026-08-19/mod-center.html).
##
## MODE D, verbatim from ARCHITECTURE.md: "Selected large popup · Background
## HUD dimmed · Popup button highlighted · Escape closes · Pause state clearly
## shown." All five are here — the dim is this overlay's own backdrop, Escape
## routes through the facade's close ladder, and the PAUSED chip is not
## decoration: the facade holds the exploration driver's time steps for exactly
## as long as this is open (the same blocker mechanism R35's inventory clause
## uses), so what the chip claims is what is actually happening.
##
## THE CONTENT IS THE OFFER PROJECTION, unchanged. Three BLESSED broad-only
## offers side by side with their group chips; the focused one expanded with
## its authored prose, the tier-2 chips, and one REQUIREMENT ROW per parent
## measured against the focused character's REAL granted levels (IN PROGRESS /
## NOT LEARNED / MET). The verdict line at the bottom is the engine's own
## arithmetic (SkillForge.validate_mutation through the projection), never this
## component's guess.
##
## TWO THINGS THIS DELIBERATELY DOES NOT DO, both because doing them would be
## a lie:
##   * PRICE. KAN-7 scope by ruling — the row shows the stamp and no number.
##     There is no currency in this file.
##   * REDEEM. No redemption command path exists anywhere in the engine (see
##     the projection's `redemption.missing`), so the action button renders as
##     an honest GATE that states what is missing instead of a button that
##     appears to work. The frame's own bottom row is the same gate
##     ("NOT YET — 2 REQUIREMENTS SHORT").
##
## Dumb component: renders the display dict it is handed; emits
## close_requested and offer_focused(key).

signal close_requested
signal offer_focused(key: String)

const UI := preload("res://ui/hud/components/hud_theme.gd")

## Above ArenaView.LABEL_Z (3) — see _ensure_built.
const POPUP_Z := 20

var _built := false
var _panel: PanelContainer
var _pause_lab: Label
var _cards: HBoxContainer
var _title: Label
var _blurb: RichTextLabel
var _chips: HBoxContainer
var _req_head: Label
var _reqs: VBoxContainer
var _framing: RichTextLabel
var _gate: PanelContainer
var _gate_lab: Label
var _gate_sub: Label


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	# The arena raises its token chips to z_index 3 so they clear the board, and
	# z beats tree order — a Mode D popup drawn at the default z would have unit
	# labels punching through it. "Background HUD dimmed" has to mean ALL of it.
	z_index = POPUP_Z

	# Mode D's dim: the HUD stays legible behind the popup (Area 3: "the HUD
	# remains visible behind the popup where useful") but stops competing.
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close_requested.emit())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col(UI.PANEL, 0.99), UI.col(UI.GOLD, 0.75), 8, Color(0, 0, 0, 0.7), 18))
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(1030, 560)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	var m := UI.margin(20, 20, 16, 16)
	_panel.add_child(m)
	var v := UI.vbox(12)
	m.add_child(v)

	# ---- header --------------------------------------------------------
	var head := UI.hbox(10)
	head.add_child(UI.emo("⬡", 17))
	head.add_child(UI.glow("MODIFICATION CENTER", UI.body(), 16, UI.col(UI.GOLD), 4.0, 6.0))
	head.add_child(UI.chip(
		UI.lab("SPECIAL OFFERS — THE HOUSE MAKES THREE", UI.body(), 9, UI.col(UI.GOLD), 2.0, true),
		UI.col(UI.GOLD, 0.10), UI.col(UI.GOLD, 0.55)))
	var hsp := Control.new()
	hsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hsp)
	_pause_lab = UI.lab("⏸ PAUSED", UI.body(), 9, UI.col(UI.PURPLE), 2.0, true)
	head.add_child(UI.chip(_pause_lab, UI.col(UI.PURPLE, 0.12), UI.col(UI.PURPLE, 0.6)))
	var esc := UI.chip(UI.lab("ESC CLOSES", UI.body(), 9, UI.col(UI.MUTED), 2.0, true),
		UI.col(UI.MUTED, 0.10), UI.col(UI.MUTED, 0.6)) as PanelContainer
	UI.attach_click(esc, func() -> void: close_requested.emit())
	head.add_child(esc)
	v.add_child(head)
	UI.border_line(v)

	# ---- the three offer cards ------------------------------------------
	_cards = UI.hbox(10)
	_cards.custom_minimum_size = Vector2(0, 96)
	v.add_child(_cards)

	# ---- focused offer: prose left, requirements right -------------------
	var body := UI.hbox(12)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)

	var left := PanelContainer.new()
	left.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL2), UI.col(UI.BORDER), 6))
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.35
	body.add_child(left)
	var lm := UI.margin(16, 16, 14, 14)
	left.add_child(lm)
	var lv := UI.vbox(9)
	lm.add_child(lv)
	_title = UI.glow("", UI.body(), 20, UI.col(UI.GOLD), 3.0, 6.0)
	lv.add_child(_title)
	_blurb = _rich(10)
	_blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(_blurb)
	_chips = UI.hbox(6)
	lv.add_child(_chips)

	var right := UI.vbox(9)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	body.add_child(right)
	_req_head = UI.lab("REQUIREMENTS", UI.body(), 9, UI.col(UI.MUTED), 3.0, true)
	right.add_child(_req_head)
	_reqs = UI.vbox(4)
	right.add_child(_reqs)
	var framing_box := PanelContainer.new()
	framing_box.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL2), UI.col(UI.BORDER), 5))
	framing_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fm := UI.margin(12, 12, 10, 10)
	framing_box.add_child(fm)
	_framing = _rich(9)
	fm.add_child(_framing)
	right.add_child(framing_box)

	_gate = PanelContainer.new()
	_gate.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.PANEL2), UI.col(UI.BORDER), 5))
	var gm := UI.margin(12, 12, 10, 10)
	_gate.add_child(gm)
	var gv := UI.vbox(3)
	gm.add_child(gv)
	_gate_lab = UI.lab("", UI.body(), 12, UI.col(UI.MUTED), 3.0, true)
	_gate_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(_gate_lab)
	_gate_sub = UI.lab("", UI.body(), 8, UI.col(UI.MUTED, 0.85), 0.5)
	_gate_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gate_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gv.add_child(_gate_sub)
	right.add_child(_gate)


func _rich(fsize: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", UI.body())
	r.add_theme_font_override("bold_font", UI.body())
	r.add_theme_font_override("italics_font", UI.body())
	r.add_theme_font_override("mono_font", UI.mono())
	for k: String in ["normal_font_size", "bold_font_size", "italics_font_size", "mono_font_size"]:
		r.add_theme_font_size_override(k, fsize)
	r.add_theme_color_override("default_color", UI.col(UI.TEXT))
	return r


## data: {offers: [projection rows], focus: offer key, for_name: String,
##        paused: bool, pause_note: String}
## Every offer row is a view_offers() row verbatim — this only lays it out.
func update(data: Dictionary) -> void:
	_ensure_built()
	_pause_lab.text = "⏸ PAUSED" if bool(data.get("paused", true)) else "▶ TIME RUNNING"
	var offers: Array = data.get("offers", [])
	var focus := String(data.get("focus", ""))
	for ch in _cards.get_children():
		ch.queue_free()
	var focused: Dictionary = {}
	for raw: Variant in offers:
		var o: Dictionary = raw
		if String(o.get("key", "")) == focus:
			focused = o
		_cards.add_child(_offer_card(o, String(o.get("key", "")) == focus))
	if focused.is_empty() and not offers.is_empty():
		focused = offers[0]
	if offers.is_empty():
		_cards.add_child(UI.lab("NO OFFERS AUTHORED — data/mod_center_offers.json is empty or absent",
			UI.body(), 11, UI.col(UI.MUTED), 2.0, true))
	_bind_focus(focused, String(data.get("for_name", "")))


## One of the three side-by-side cards: name, the parent pair with the authored
## min-levels, the BROAD-ONLY group chip, and BLESSED / PROVISIONAL status.
func _offer_card(o: Dictionary, is_focus: bool) -> Control:
	var accent: Color = UI.col(UI.GOLD) if is_focus else UI.col(UI.TEXT)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.glow_sb(
		Color(accent.r, accent.g, accent.b, 0.09 if is_focus else 0.03),
		Color(accent.r, accent.g, accent.b, 0.9 if is_focus else 0.30), 6,
		Color(accent.r, accent.g, accent.b, 0.35) if is_focus else Color(0, 0, 0, 0),
		8 if is_focus else 0))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := UI.margin(14, 14, 10, 10)
	card.add_child(m)
	var v := UI.vbox(5)
	m.add_child(v)
	var name_lab := UI.lab(String(o.get("name", "")).to_upper(), UI.body(), 13,
		accent if is_focus else UI.col(UI.TEXT), 2.0, true)
	name_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(name_lab)
	var pairs: Array = []
	for raw: Variant in o.get("parents", []):
		var p: Dictionary = raw
		pairs.append("%s %d" % [String(p.get("name", "")).to_upper(), int(p.get("min_level", 1))])
	# The parent pair is the card's actual content; on the FOCUSED card the gold
	# tint swallows a muted grey, so it steps up to body text there.
	var pair_lab := UI.lab(" + ".join(PackedStringArray(pairs)), UI.body(), 9,
		UI.col(UI.TEXT) if is_focus else UI.col(UI.MUTED), 1.0)
	pair_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(pair_lab)
	var chips := UI.hbox(5)
	var groups: Array = o.get("shared_broad", [])
	var group_text := "BROAD-ONLY"
	if not groups.is_empty():
		group_text = "BROAD-ONLY · " + " / ".join(PackedStringArray(groups)).to_upper()
	chips.add_child(UI.chip(UI.lab(group_text, UI.body(), 7, UI.col(UI.PURPLE), 1.5, true),
		UI.col(UI.PURPLE, 0.12), UI.col(UI.PURPLE, 0.55)))
	var blessed := String(o.get("status", "")).begins_with("BLESSED")
	chips.add_child(UI.chip(
		UI.lab("BLESSED" if blessed else "UNBLESSED", UI.body(), 7,
			UI.col(UI.GOLD) if blessed else UI.col(UI.MUTED), 1.5, true),
		UI.col(UI.GOLD, 0.12) if blessed else UI.col(UI.MUTED, 0.10),
		UI.col(UI.GOLD, 0.55) if blessed else UI.col(UI.MUTED, 0.55)))
	v.add_child(chips)
	var key := String(o.get("key", ""))
	UI.attach_click(card, func() -> void: offer_focused.emit(key))
	return card


func _bind_focus(o: Dictionary, for_name: String) -> void:
	for ch in _chips.get_children():
		ch.queue_free()
	for ch in _reqs.get_children():
		ch.queue_free()
	if o.is_empty():
		_title.text = "—"
		_blurb.text = ""
		_req_head.text = "REQUIREMENTS"
		_framing.text = ""
		_gate_lab.text = "NOTHING TO SHOW"
		_gate_sub.text = ""
		return
	_title.text = String(o.get("name", "")).to_upper()
	_blurb.text = String(o.get("note", ""))
	_req_head.text = "REQUIREMENTS — %s" % for_name.to_upper() if for_name != "" else "REQUIREMENTS"

	# The tier-2 chips (frame 5's row under the prose). Every one is a FACT off
	# the row: the merge tier, the consumption warning, where the result lands,
	# the decision-#36 parent cap, and the provisional NAME.
	var result: Dictionary = o.get("result", {})
	_add_chip(_chips, "TIER 2 — GEMSTONE MERGE", UI.col(UI.GOLD))
	if bool(o.get("consumes_parents", false)):
		_add_chip(_chips, "CONSUMES BOTH PARENTS", UI.col(UI.DANGER))
	_add_chip(_chips, "ARRIVES AT L%d · CAP %d" % [int(result.get("level", 1)),
		int(o.get("parent_cap", 5))], UI.col(UI.MUTED))
	_add_chip(_chips, "OPTIONAL — PARENTS CAP AT %d ANYWAY" % int(o.get("parent_cap", 5)),
		UI.col(UI.CYAN))
	if bool(o.get("provisional", false)):
		_add_chip(_chips, "NAME PROVISIONAL", UI.col(UI.MYTHIC))

	for raw: Variant in o.get("parents", []):
		_reqs.add_child(_req_row(raw as Dictionary, bool(o.get("known", false))))
	_reqs.add_child(_price_row(o.get("price", {})))

	_framing.text = ("An offer is the recorded GM call on a broad-only pair — [b]offered, never "
		+ "automatic[/b]. Parents stop at %d either way (unless that skill was always linear); "
		+ "declining costs you nothing but the ceiling. Tier-3 merges exist. The house is patient.") \
		% int(o.get("parent_cap", 5))
	_bind_gate(o)


func _add_chip(row: HBoxContainer, text: String, color: Color) -> void:
	row.add_child(UI.chip(UI.lab(text, UI.body(), 7, color, 1.5, true),
		Color(color.r, color.g, color.b, 0.11), Color(color.r, color.g, color.b, 0.55)))


## One requirement row: "FEINT — identity parent    3 / 5  [IN PROGRESS]".
## The owned level is the character's REAL granted level; a not-learned parent
## shows the frame's own em-dash rather than a fake 0.
func _req_row(p: Dictionary, known: bool) -> Control:
	var state := String(p.get("state", "UNKNOWN"))
	var tint: Color = UI.col(UI.MUTED)
	if state == "MET":
		tint = UI.col(UI.SUCCESS)
	elif state == "IN PROGRESS":
		tint = UI.col(UI.CYAN)
	elif state == "NOT LEARNED":
		tint = UI.col(UI.DANGER)
	var row := UI.hbox(8)
	var name_lab := UI.lab("%s — %s parent" % [String(p.get("name", "")).to_upper(),
		String(p.get("role", "secondary"))], UI.body(), 10, UI.col(UI.TEXT), 1.0, true)
	name_lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_lab)
	var owned := int(p.get("owned_level", 0))
	var have := str(owned) if (known and owned > 0) else "–"
	row.add_child(UI.lab("%s / %d" % [have, int(p.get("min_level", 1))],
		UI.mono(), 11, tint, 1.0, true))
	row.add_child(UI.chip(UI.lab(state, UI.body(), 7, tint, 1.5, true),
		Color(tint.r, tint.g, tint.b, 0.12), Color(tint.r, tint.g, tint.b, 0.55)))
	return row


## The PRICE row. KAN-7 by ruling: the stamp, the scope chip, and no number.
func _price_row(price: Dictionary) -> Control:
	var row := UI.hbox(8)
	var lab := UI.lab("PRICE", UI.body(), 10, UI.col(UI.TEXT), 1.0, true)
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lab)
	row.add_child(UI.lab("%s — TBD" % String(price.get("scope", "KAN-7")),
		UI.mono(), 10, UI.col(UI.MYTHIC), 1.0, true))
	row.add_child(UI.chip(UI.lab("LOUNGE ECONOMY", UI.body(), 7, UI.col(UI.MYTHIC), 1.5, true),
		UI.col(UI.MYTHIC, 0.12), UI.col(UI.MYTHIC, 0.55)))
	return row


## The bottom verdict. Requirements first (the frame's own gate), then the
## honest engine gate: even a fully-qualified offer cannot be redeemed, because
## no redemption path exists — so the button never pretends otherwise.
func _bind_gate(o: Dictionary) -> void:
	var redemption: Dictionary = o.get("redemption", {})
	var short := int(o.get("requirements_short", 0))
	var known := bool(o.get("known", false))
	var tint: Color = UI.col(UI.MUTED)
	var text := ""
	var sub := ""
	if not known:
		text = "NO CHARACTER IN FOCUS"
		sub = "Focus a contestant to measure this offer against their real granted levels."
	elif short > 0:
		text = "NOT YET — %d REQUIREMENT%s SHORT" % [short, "" if short == 1 else "S"]
		sub = "The house does not sell you the shortcut. Level the parents first."
	elif not bool(redemption.get("available", false)):
		tint = UI.col(UI.GOLD)
		text = "REQUIREMENTS MET — REDEMPTION NOT WIRED (KAN-7)"
		sub = "The forge validates this merge, but nothing can execute it yet: " \
			+ "; ".join(PackedStringArray(_short_missing(redemption)))
	else:
		tint = UI.col(UI.SUCCESS)
		text = "REDEEM"
		sub = ""
	_gate_lab.text = text
	_gate_lab.add_theme_color_override("font_color", tint)
	_gate_lab.add_theme_color_override("font_outline_color", tint)
	_gate_sub.text = sub
	_gate.add_theme_stylebox_override("panel",
		UI.sb(Color(tint.r, tint.g, tint.b, 0.07), Color(tint.r, tint.g, tint.b, 0.45), 5))


## The missing-piece list, trimmed to its leading clause per entry so the gate
## stays one readable sentence (the projection carries the full text).
func _short_missing(redemption: Dictionary) -> Array:
	var out: Array = []
	for raw: Variant in redemption.get("missing", []):
		var line := String(raw)
		var cut := line.find(" (")
		out.append(line.substr(0, cut) if cut > 0 else line)
	return out


func show_popup(data: Dictionary) -> void:
	update(data)
	visible = true


func hide_popup() -> void:
	visible = false
