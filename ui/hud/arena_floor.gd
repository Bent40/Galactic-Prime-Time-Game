extends Control
## PLACEHOLDER arena floor stub — the demo HUD's center stage.
##
## KAN-6 owns the real 2.5D tactical board (tilted hex grid + billboarded unit
## tokens + roaches + hazard tiles driven from view_combatants positions). Until
## that scene lands, this draws a faint isometric hex lattice with a couple of
## fire / flamethrower-cone hazard tiles so the center panel reads as the
## tactical board in the combat-HUD render. Purely decorative: no sim coupling.
## # PLACEHOLDER: needs the real hex board + token layer from the KAN-6 arena scene.

const BASE_TOP := Color("#1a2138")
const BASE_BOT := Color("#10162a")
const EDGE := Color("#223056")
const FIRE := Color("#ff7a2f")


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var s := size
	var cx := s.x * 0.5
	var cy := s.y * 0.46
	var rx := 46.0
	var ry := 25.0
	var col_step := rx * 1.5
	var row_step := ry * 1.18
	var rows := 6
	var cols := 6
	# (row,col) -> hazard kind. A fire tile "heals the boss" (left rail Hazard
	# Read); the cone is the telegraphed flamethrower sweep.
	var special := {
		Vector2i(1, 3): "fire", Vector2i(3, 1): "fire", Vector2i(3, 4): "fire",
		Vector2i(0, 3): "cone", Vector2i(1, 2): "cone", Vector2i(1, 4): "cone",
	}
	for r in rows:
		var y := cy + (float(r) - rows / 2.0) * row_step
		var offset: float = (col_step * 0.5) if (r % 2 == 1) else 0.0
		for c in cols:
			var x := cx + (float(c) - cols / 2.0) * col_step + offset
			var dim: float = 1.0 - clampf(absf(c - cols / 2.0) / cols + absf(r - rows / 2.0) / rows, 0.0, 0.65)
			_hex(Vector2(x, y), rx, ry, String(special.get(Vector2i(r, c), "")), dim)


func _hex(center: Vector2, rx: float, ry: float, kind: String, dim: float) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	var fill := BASE_BOT.lerp(BASE_TOP, 0.5)
	fill.a = 0.85 * dim + 0.12
	if kind == "fire":
		fill = Color("#3a1a0a"); fill.a = 0.95
	elif kind == "cone":
		fill = FIRE; fill.a = 0.16
	draw_colored_polygon(pts, fill)
	if kind == "fire":
		draw_colored_polygon(pts, Color(FIRE.r, FIRE.g, FIRE.b, 0.32))
	var edge := EDGE
	edge.a = 0.5 * dim + 0.08
	var outline := pts
	outline.append(pts[0])
	draw_polyline(outline, edge, 1.0, true)
