extends Control
## Live arena floor — the demo HUD's center-stage hex board.
##
## Presentation only: the CombatHud owns the sim view API and hands this node a
## pure DRAW SPEC (a hex transform + which hexes to tint) via configure(); this
## node just paints it. It never imports simulation/ or reads the controller —
## the same rule the KAN-6 mockup gate set for the stage.
##
## The board transform (eff_size + offset) is computed by the HUD from the LIVE
## occupied hexes (auto-centred/scaled to the panel), so it matches exactly where
## the HUD places the unit tokens on top — both go through
## FieldRenderer.axial_to_pixel(q, r, eff) + offset. Redraws whenever the HUD
## reconfigures it (which the HUD does on every sim_event).

# field_renderer.gd (the reusable, unit-tested hex math) is LOADED AT RUNTIME, not
# preloaded: its _ready() references the `Game` autoload, which is not resolvable at
# this scene's compile time inside the render/test harnesses. See _fr().
var _field_renderer: GDScript


func _fr() -> GDScript:
	if _field_renderer == null:
		_field_renderer = load("res://scenes/field/field_renderer.gd") as GDScript
	return _field_renderer


# char-sheet palette (DESIGN.md)
const GRID := Color("#3a4560")          # muted grid line
const TILE_TOP := Color("#141a30")
const TILE_BOT := Color("#0b1020")
const CYAN := Color("#00d4ff")
const FIRE := Color("#ff7a2f")

# --- draw spec (set by CombatHud.configure) ---
var eff: float = 40.0                   # on-screen hex size
var off: Vector2 = Vector2.ZERO         # board offset (screen px)
var q_range: Vector2i = Vector2i(-2, 3) # inclusive qlo..qhi
var r_range: Vector2i = Vector2i(-2, 3) # inclusive rlo..rhi
var occupied: Array = []                # Array[Vector2i] — hexes with a token
var reachable: Array = []               # Array[Vector2i] — MOVE targeting highlight
var cone_on: bool = false               # flamethrower-cone hazard hint (decorative)
var cone_origin: Vector2 = Vector2.ZERO
var cone_dir: Vector2 = Vector2.RIGHT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## The HUD's one call: hand over the board transform + tint sets, then repaint.
func configure(p_eff: float, p_off: Vector2, p_q: Vector2i, p_r: Vector2i,
		p_occupied: Array, p_reachable: Array,
		p_cone_on: bool, p_cone_origin: Vector2, p_cone_dir: Vector2) -> void:
	eff = p_eff
	off = p_off
	q_range = p_q
	r_range = p_r
	occupied = p_occupied
	reachable = p_reachable
	cone_on = p_cone_on
	cone_origin = p_cone_origin
	cone_dir = p_cone_dir
	queue_redraw()


func _center(q: int, r: int) -> Vector2:
	return _fr().axial_to_pixel(q, r, eff) + off


func _draw() -> void:
	var occ := {}
	for h: Vector2i in occupied:
		occ[h] = true
	var reach := {}
	for h: Vector2i in reachable:
		reach[h] = true

	# 1) the hex lattice (auto-centred on the live occupied hexes)
	for r: int in range(r_range.x, r_range.y + 1):
		for q: int in range(q_range.x, q_range.y + 1):
			var center := _center(q, r)
			var pts: PackedVector2Array = _fr().hex_points(center, eff * 0.92)
			var key := Vector2i(q, r)
			var fill := TILE_BOT.lerp(TILE_TOP, 0.5)
			fill.a = 0.55
			if reach.has(key):
				fill = CYAN
				fill.a = 0.16
			elif occ.has(key):
				fill.a = 0.8
			draw_colored_polygon(pts, fill)
			var outline := pts
			outline.append(pts[0])
			var edge := CYAN if reach.has(key) else GRID
			edge.a = 0.55 if reach.has(key) else 0.45
			draw_polyline(outline, edge, 1.5 if reach.has(key) else 1.0, true)

	# 2) flamethrower cone hint — a translucent telegraph fanning off the boss
	# toward the party. DECORATIVE (no sim hazard model yet), tied to the live
	# boss hex so it tracks the boss token.
	if cone_on:
		var dir := cone_dir.normalized()
		var length := eff * 2.6
		var left := dir.rotated(deg_to_rad(-26.0)) * length
		var right := dir.rotated(deg_to_rad(26.0)) * length
		var apex := cone_origin + dir * (eff * 0.5)
		var fan := PackedVector2Array([apex, apex + left, apex + right])
		var glow := FIRE
		glow.a = 0.13
		draw_colored_polygon(fan, glow)
		var core := PackedVector2Array([apex, apex + left * 0.6, apex + right * 0.6])
		var hot := FIRE
		hot.a = 0.22
		draw_colored_polygon(core, hot)
