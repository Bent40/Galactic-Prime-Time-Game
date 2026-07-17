extends Node2D
## Hex field renderer — KAN3-S3 readability SPIKE. Placeholder shapes by ruling
## (ComfyUI shelved 2026-07-18; free/code-drawn placeholders until GPT sprites
## land). Presentation only: reads the Game view API, redraws on any sim_event,
## and never imports simulation/ classes (grep-gated). Styling decisions belong
## to the KAN-6 mockup gate — everything here optimizes for at-a-glance reads.

const HEX_SIZE: float = 30.0
const GRID_COLS: int = 12
const GRID_ROWS: int = 8
const GRID_COLOR: Color = Color(0.25, 0.22, 0.3, 0.8)
const BODY_ALIVE: Color = Color(0.85, 0.8, 0.7)
const BODY_EXPOSED: Color = Color(0.95, 0.75, 0.35)
const BODY_DEAD: Color = Color(0.35, 0.3, 0.3)
const CONDITION_COLORS: Dictionary = {
	"bleeding": Color(0.85, 0.15, 0.15),
	"crushed": Color(0.55, 0.4, 0.25),
	"burn": Color(0.95, 0.55, 0.1),
	"chilled": Color(0.4, 0.8, 0.95),
	"poison": Color(0.35, 0.8, 0.3),
	"infected": Color(0.6, 0.65, 0.2),
	"dissolution": Color(0.7, 0.3, 0.85),
	"exhausted": Color(0.6, 0.6, 0.6),
	"suffocation": Color(0.3, 0.35, 0.6),
}


func _ready() -> void:
	Game.sim_event.connect(func(_event: Dictionary) -> void: queue_redraw())


## Pointy-top axial -> pixel (pure; unit-tested headless).
static func axial_to_pixel(q: int, r: int, size: float) -> Vector2:
	return Vector2(size * (sqrt(3.0) * q + sqrt(3.0) * 0.5 * r), size * 1.5 * r)


## Six vertices of a pointy-top hex (pure; unit-tested headless).
static func hex_points(center: Vector2, size: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(6):
		var angle: float = PI / 180.0 * (60.0 * i - 30.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	return points


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	for r: int in range(GRID_ROWS):
		for q: int in range(GRID_COLS):
			var pts: PackedVector2Array = hex_points(axial_to_pixel(q, r, HEX_SIZE), HEX_SIZE - 1.0)
			pts.append(pts[0])
			draw_polyline(pts, GRID_COLOR, 1.5)
	var clock: Dictionary = Game.view_clock()
	if not clock.is_empty():
		draw_string(font, Vector2(0, -34), "MOMENT %d   tick %d" % [clock.get("moment", 0), clock.get("tick", 0)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	for view: Dictionary in Game.view_combatants():
		_draw_combatant(view, font)


func _draw_combatant(view: Dictionary, font: Font) -> void:
	var pos_arr: Array = view.get("position", [0, 0])
	var center: Vector2 = axial_to_pixel(int(pos_arr[0]), int(pos_arr[1]), HEX_SIZE)
	var alive: bool = bool(view.get("alive", true))
	var body: Color = BODY_DEAD if not alive else (BODY_EXPOSED if bool(view.get("exposed", false)) else BODY_ALIVE)
	draw_circle(center, HEX_SIZE * 0.45, body)
	if not alive:
		var arm: float = HEX_SIZE * 0.45
		draw_line(center + Vector2(-arm, -arm), center + Vector2(arm, arm), Color.BLACK, 3.0)
		draw_line(center + Vector2(-arm, arm), center + Vector2(arm, -arm), Color.BLACK, 3.0)
	var shock: int = int(view.get("shock", 0))
	if shock > 0:
		draw_arc(center, HEX_SIZE * 0.55, 0, TAU, 24, Color(1.0, 1.0, 0.2, 0.25 * shock), 3.0)
	draw_string(font, center + Vector2(-HEX_SIZE, -HEX_SIZE * 0.7), String(view.get("name", "?")),
		HORIZONTAL_ALIGNMENT_CENTER, HEX_SIZE * 2.0, 12, Color.WHITE)
	# Part pips: one bar per part under the body — green->red by HP, gray = disabled.
	var parts: Array = view.get("parts", [])
	var pip_w: float = clampf(HEX_SIZE * 1.6 / maxf(1.0, parts.size()), 4.0, 14.0)
	var x0: float = center.x - (pip_w * parts.size()) * 0.5
	for i: int in range(parts.size()):
		var part: Dictionary = parts[i]
		var frac: float = 0.0 if int(part.get("max_hp", 0)) == 0 else float(part.get("hp", 0)) / float(part.get("max_hp", 1))
		var pip: Color = Color(0.4, 0.4, 0.4) if bool(part.get("disabled", false)) else Color(1.0 - frac, frac, 0.15)
		draw_rect(Rect2(x0 + i * pip_w, center.y + HEX_SIZE * 0.55, pip_w - 1.0, 6.0), pip)
		# Condition dots stack above the pip, colored by condition id.
		var dot_y: float = center.y + HEX_SIZE * 0.55 - 5.0
		for cond_id: Variant in (part.get("conditions", {}) as Dictionary):
			var tier: int = int(part["conditions"][cond_id])
			var dot: Color = CONDITION_COLORS.get(String(cond_id), Color.MAGENTA)
			for t: int in range(tier):
				draw_circle(Vector2(x0 + i * pip_w + pip_w * 0.5, dot_y - t * 5.0), 2.2, dot)
