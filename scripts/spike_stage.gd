extends "res://scripts/stage_edit.gd"
## Same editable strips as the original stage, above a fixed spike pit.

const SPIKE_Y := 578.0


func _ready() -> void:
	super._ready()
	strips = [{"x0": 360.0, "x1": 1050.0, "y0": 500.0, "y1": 500.0, "tilt": false}]
	queue_redraw()


func _draw() -> void:
	super._draw()
	draw_rect(Rect2(0, SPIKE_Y + 22, 1280, 120), Color(0.13, 0.14, 0.18))
	for x in range(0, 1280, 32):
		var points := PackedVector2Array([
			Vector2(x, SPIKE_Y + 24), Vector2(x + 16, SPIKE_Y), Vector2(x + 32, SPIKE_Y + 24),
		])
		draw_colored_polygon(points, Color(0.63, 0.64, 0.68))
		draw_line(points[0], points[1], Color(0.88, 0.86, 0.81), 2.0)
