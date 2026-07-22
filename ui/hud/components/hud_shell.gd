extends Control
## HudShell — the persistent HUD skeleton (spec §2): game world DOMINANT center;
## party rail LEFT edge; selected-actor summary TOP-LEFT; Moment/Clock timeline
## TOP-CENTER; compact crowd panel + contextual EntityInspector RIGHT;
## ActionLauncher + End Turn BOTTOM-CENTER; MomusTicker full-width BOTTOM;
## flyout + event-log overlays on top. Pure structure: instantiates and lays out
## the component scenes and exposes them; ALL data-binding and command routing
## live in the CombatHud facade. Deferred spec areas (ADOPTION.md): popup
## shortcuts, live odds, chat — their slots stay unbuilt until their systems land.

const UI := preload("res://ui/hud/components/hud_theme.gd")
const SummaryScene := preload("res://ui/hud/components/selected_actor_summary.tscn")
const TimelineScene := preload("res://ui/hud/components/moment_timeline.tscn")
const PartyRailScene := preload("res://ui/hud/components/party_rail.tscn")
const ArenaViewScene := preload("res://ui/hud/components/arena_view.tscn")
const CrowdPanelScene := preload("res://ui/hud/components/crowd_panel.tscn")
const InspectorScene := preload("res://ui/hud/components/entity_inspector.tscn")
const LauncherScene := preload("res://ui/hud/components/action_launcher.tscn")
const FlyoutScene := preload("res://ui/hud/components/action_flyout.tscn")
const TickerScene := preload("res://ui/hud/components/momus_ticker.tscn")
const EventLogScene := preload("res://ui/hud/components/event_log_overlay.tscn")

# Component refs are deliberately UNTYPED: each holds an instantiated component
# scene and is driven dynamically by the facade (typed as Node/Control they would
# fail static lookup of the components' update()/show_log()/... methods).
var summary
var timeline
var party_rail
var arena
var crowd
var inspector
var launcher
var flyout
var ticker
var event_log

var _built := false
var _launcher_row: Control


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = UI.col(UI.BG)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var glow := TextureRect.new()
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.texture = _radial_tex(Color("#0a1024"))
	glow.modulate = Color(1, 1, 1, 0.7)
	add_child(glow)

	var root_m := UI.margin(12, 12, 10, 10)
	root_m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_m)
	var col := UI.vbox(8)
	root_m.add_child(col)

	# ---- top band: summary (left) · timeline (center) · brand (right) ----
	var top := UI.hbox(8)
	top.custom_minimum_size = Vector2(0, 86)
	summary = SummaryScene.instantiate()
	summary.custom_minimum_size = Vector2(330, 0)
	summary.size_flags_horizontal = Control.SIZE_FILL
	top.add_child(summary)
	timeline = TimelineScene.instantiate()
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(timeline)
	top.add_child(_brand_block())
	col.add_child(top)

	# ---- main band: party rail (left) · arena (center) · crowd+inspector (right) ----
	var mid := UI.hbox(8)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL

	party_rail = PartyRailScene.instantiate()
	party_rail.custom_minimum_size = Vector2(236, 0)
	party_rail.size_flags_horizontal = Control.SIZE_FILL
	party_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(party_rail)

	var stage := PanelContainer.new()
	stage.add_theme_stylebox_override("panel", UI.sb(UI.col("#080b18"), UI.col(UI.BORDER), 5))
	stage.clip_contents = true
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arena = ArenaViewScene.instantiate()
	stage.add_child(arena)
	mid.add_child(stage)

	var right := UI.vbox(8)
	right.custom_minimum_size = Vector2(320, 0)
	right.size_flags_horizontal = Control.SIZE_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crowd = CrowdPanelScene.instantiate()
	crowd.size_flags_vertical = Control.SIZE_FILL
	right.add_child(crowd)
	inspector = InspectorScene.instantiate()
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(inspector)
	mid.add_child(right)
	col.add_child(mid)

	# ---- bottom bands: launcher, then the full-width Momus ticker ----
	_launcher_row = UI.hbox(0)
	_launcher_row.custom_minimum_size = Vector2(0, 64)
	launcher = LauncherScene.instantiate()
	launcher.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_launcher_row.add_child(launcher)
	col.add_child(_launcher_row)

	ticker = TickerScene.instantiate()
	ticker.custom_minimum_size = Vector2(0, 42)
	col.add_child(ticker)

	# ---- overlays (top of the tree = drawn last) ----
	flyout = FlyoutScene.instantiate()
	flyout.visible = false
	add_child(flyout)
	flyout.resized.connect(_place_flyout)

	event_log = EventLogScene.instantiate()
	add_child(event_log)

	# R14 watermark — every number on screen is placeholder until the numbers pass.
	var wm := UI.lab("PLACEHOLDER NUMBERS · R14", UI.body(), 10, UI.col(UI.TEXT, 0.16), 3.0, true)
	wm.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	wm.position = Vector2(-250, -14)
	add_child(wm)

	resized.connect(_place_flyout)


## Flyouts open UPWARD from the launcher (spec Area 10): anchored just above the
## launcher row, horizontally centred on it.
func show_flyout(data: Dictionary) -> void:
	_ensure_built()
	flyout.update(data)
	flyout.visible = true
	_place_flyout()


func hide_flyout() -> void:
	if flyout != null:
		flyout.visible = false


func _place_flyout() -> void:
	if flyout == null or not flyout.visible or _launcher_row == null:
		return
	flyout.reset_size()
	var row_rect := _launcher_row.get_global_rect()
	var local_top := row_rect.position - get_global_rect().position
	flyout.position = Vector2(
		clampf(local_top.x + (row_rect.size.x - flyout.size.x) * 0.5, 8.0, size.x - flyout.size.x - 8.0),
		local_top.y - flyout.size.y - 8.0)


func _brand_block() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.sb(UI.col("#0a1024"), UI.col(UI.BORDER), 5))
	p.custom_minimum_size = Vector2(250, 0)
	var m := UI.margin(14, 14, 6, 6)
	p.add_child(m)
	var v := UI.vbox(3)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(v)
	var lrow := UI.hbox(8)
	lrow.alignment = BoxContainer.ALIGNMENT_CENTER
	var live := PanelContainer.new()
	live.add_theme_stylebox_override("panel", UI.sb(UI.col(UI.DANGER, 0.12), UI.col(UI.DANGER, 0.5), 4))
	live.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var lm := UI.margin(8, 8, 2, 2)
	live.add_child(lm)
	var lrow2 := UI.hbox(6)
	lm.add_child(lrow2)
	lrow2.add_child(_live_dot())
	lrow2.add_child(UI.lab("LIVE", UI.body(), 10, UI.col("#ff6b88"), 2.0, true))
	lrow.add_child(live)
	lrow.add_child(UI.glow("GALACTIC PRIME TIME", UI.body(), 13, UI.col(UI.CYAN), 3.0, 7.0))
	v.add_child(lrow)
	var sub := UI.lab("◆ COSMIC CASINO · VIP TABLE — THE INCINERATOR", UI.body(), 8, UI.col(UI.GOLD), 2.0, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var watch := UI.hbox(5)
	watch.alignment = BoxContainer.ALIGNMENT_CENTER
	watch.add_child(UI.emo("👁", 11))
	watch.add_child(UI.lab("4,102,338 WATCHING", UI.mono(), 9, UI.col(UI.MUTED), 1.0))  # PLACEHOLDER: viewer count not in view API
	v.add_child(watch)
	return p


func _live_dot() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(9, 9)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var dot := Panel.new()
	dot.add_theme_stylebox_override("panel",
		UI.glow_sb(UI.col(UI.DANGER), UI.col(UI.DANGER), 5, UI.col(UI.DANGER, 0.9), 4))
	dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(dot)
	# blink — the tween needs the SceneTree, so start it when the dot enters it
	dot.tree_entered.connect(func() -> void:
		var tw := dot.create_tween().set_loops()
		tw.tween_property(dot, "modulate:a", 0.15, 0.55)
		tw.tween_property(dot, "modulate:a", 1.0, 0.55))
	return holder


func _radial_tex(inner: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(inner.r, inner.g, inner.b, 0.5))
	g.set_color(1, Color(inner.r, inner.g, inner.b, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(1.1, 0.6)
	gt.width = 400
	gt.height = 250
	return gt
