extends Control
## Live arena floor — the demo HUD's center-stage hex board.
##
## Presentation only: the CombatHud owns the sim view API and hands this node a
## pure DRAW SPEC (a hex transform + which hexes to tint) via configure(); this
## node just paints it. It never imports simulation/ or reads the controller —
## the same rule the KAN-6 mockup gate set for the stage.
##
## R34 (2026-08-19): the old single DECORATIVE flamethrower cone is gone. Both
## cone families drawn here now come from real projections — vision eyelines
## from view_vision().watched and attack cones from the declared area_shape —
## and they carry the ruled colour semantics (see the draw spec below).
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
const DANGER := Color("#ff2255")
const NEUTRAL := Color("#96aacd")

# --- draw spec (set by ArenaView.configure) ---
var eff: float = 40.0                   # on-screen hex size
var off: Vector2 = Vector2.ZERO         # board offset (screen px)
var q_range: Vector2i = Vector2i(-2, 3) # inclusive qlo..qhi
var r_range: Vector2i = Vector2i(-2, 3) # inclusive rlo..rhi
var occupied: Array = []                # Array[Vector2i] — hexes with a token
var reachable: Array = []               # Array[Vector2i] — MOVE targeting highlight

## R34 CONE SEMANTICS (decision #36, amending decision 5). Two DIFFERENT things
## are drawn here and they must never be confused, which is the whole point of
## the ruling: colour answers "threat area or eyeline?" and "am I seen?".
##
## eyelines — one entry per observer, VISION cones. Each is
##   {hexes: Array[Vector2i], seen: bool} and is tinted per HEX, because the
##   hexes come from GameController.view_vision().watched, which is the sim's
##   own front-arc + range + LOS answer — not a decorative wedge. NEUTRAL while
##   its owner has spotted nobody, DANGER-RED the moment it holds a contestant.
## attack_cones — one entry per DECLARED area action, always hazard-orange and
##   NEVER recoloured (the ruling is explicit). Each is
##   {hexes: Array[Vector2i]} off the committed area_shape the resolver
##   re-checks at resolution (R2), so what is drawn is what will land.
var eyelines: Array = []
var attack_cones: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## The HUD's one call: hand over the board transform + tint sets, then repaint.
func configure(p_eff: float, p_off: Vector2, p_q: Vector2i, p_r: Vector2i,
		p_occupied: Array, p_reachable: Array,
		p_eyelines: Array, p_attack_cones: Array) -> void:
	eff = p_eff
	off = p_off
	q_range = p_q
	r_range = p_r
	occupied = p_occupied
	reachable = p_reachable
	eyelines = p_eyelines
	attack_cones = p_attack_cones
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

	# 2) VISION cones (R34): the observer's real eyeline, tinted hex by hex.
	# NEUTRAL while it has spotted nobody; RED the moment it holds a
	# contestant — so the board itself answers "am I seen?".
	for entry: Variant in eyelines:
		var eye: Dictionary = entry
		var seen := bool(eye.get("seen", false))
		var tint := DANGER if seen else NEUTRAL
		_tint_hexes(eye.get("hexes", []), Color(tint.r, tint.g, tint.b, 0.22 if seen else 0.17),
			Color(tint.r, tint.g, tint.b, 0.9 if seen else 0.8), 0.84)

	# 3) ATTACK cones (R34): hazard-orange, NEVER recoloured by anyone's
	# awareness — what the blow will cover, straight off the committed shape.
	# The fill stays LIGHT on purpose: an authored arc can be genuinely huge
	# (the flamethrower is "cone 10" — 120 hexes), and the honest answer is to
	# show all of it while keeping the board readable, so the OUTLINE carries
	# the signal and the wash only says "inside".
	for entry: Variant in attack_cones:
		var cone: Dictionary = entry
		_tint_hexes(cone.get("hexes", []), Color(FIRE.r, FIRE.g, FIRE.b, 0.10),
			Color(FIRE.r, FIRE.g, FIRE.b, 0.7), 0.88)


## Paints one tinted hex set (fill + outline) at `scale` of the hex radius.
func _tint_hexes(hexes: Array, fill: Color, edge: Color, hex_scale: float) -> void:
	for raw: Variant in hexes:
		var h: Vector2i = raw
		var pts: PackedVector2Array = _fr().hex_points(_center(h.x, h.y), eff * hex_scale)
		draw_colored_polygon(pts, fill)
		var outline := pts
		outline.append(pts[0])
		draw_polyline(outline, edge, 1.5, true)
