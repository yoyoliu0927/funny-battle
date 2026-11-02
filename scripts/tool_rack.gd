extends Control

var host: Node = null
var tool := 0
var cool: Array[float] = [0.0, 0.0, 0.0]
var span: Array[float] = [1.0, 1.0, 1.0]
var _mark: Array[float] = [-1.0, -1.0, -1.0]
var _mark_tool := -1

const SLOT := 72.0
const GAP := 12.0
const BANANA_ICON := preload("res://assets/props/banana.png")
const SPRING_ICON := preload("res://assets/props/spring.png")
const STOPWATCH_ICON := preload("res://assets/ui/icon_stopwatch.png")
const SPRING_REGION := Rect2(0, 20, 70, 50)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(SLOT * 3.0 + GAP * 2.0, SLOT)


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var index := int(mouse.position.x / (SLOT + GAP))
	if index < 0 or index > 2:
		return
	if host != null and host.has_method("pick_tool"):
		host.pick_tool(index)
	accept_event()


func sync(selected: int, remaining: Array[float], full: Array[float]) -> void:
	var changed := selected != _mark_tool
	for i in mini(remaining.size(), _mark.size()):
		if not is_equal_approx(_mark[i], remaining[i]):
			changed = true
			_mark[i] = remaining[i]
	if not changed:
		return
	_mark_tool = selected
	tool = selected
	cool = remaining
	span = full
	queue_redraw()


func _draw() -> void:
	for i in 3:
		var origin := Vector2(float(i) * (SLOT + GAP), 0.0)
		var box := Rect2(origin, Vector2(SLOT, SLOT))
		var hot := i == tool
		draw_rect(box, Color(0.14, 0.15, 0.2), true)
		draw_rect(box, Color(0.96, 0.9, 0.55) if hot else Color(0.45, 0.46, 0.52), false, 3.0)
		_draw_icon(i, origin + Vector2(SLOT, SLOT) * 0.5)
		var full := span[i] if i < span.size() else 1.0
		var left := cool[i] if i < cool.size() else 0.0
		if left > 0.0 and full > 0.0:
			_draw_cool(origin + Vector2(SLOT, SLOT) * 0.5, SLOT * 0.46, clampf(left / full, 0.0, 1.0))
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(font, origin + Vector2(6, 20), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.9, 0.92))


func _draw_icon(index: int, center: Vector2) -> void:
	if index == 0:
		draw_texture_rect(BANANA_ICON, _fit_rect(BANANA_ICON, center, Vector2(52, 34), Vector2(0, 2)), false)
		return
	if index == 1:
		var scale := minf(46.0 / SPRING_REGION.size.x, 32.0 / SPRING_REGION.size.y)
		var drawn := SPRING_REGION.size * scale
		var target := Rect2(center - drawn * 0.5 + Vector2(0, 2), drawn)
		draw_texture_rect_region(SPRING_ICON, target, SPRING_REGION)
		return
	draw_texture_rect(STOPWATCH_ICON, _fit_rect(STOPWATCH_ICON, center, Vector2(44, 44), Vector2(2, 2)), false)


func _fit_rect(texture: Texture2D, center: Vector2, max_size: Vector2, offset := Vector2.ZERO) -> Rect2:
	var size := texture.get_size()
	var scale := minf(max_size.x / size.x, max_size.y / size.y)
	var drawn := size * scale
	return Rect2(center - drawn * 0.5 + offset, drawn)


func _draw_cool(center: Vector2, radius: float, remain: float) -> void:
	var steps := maxi(int(round(24.0 * remain)), 3)
	var start := -PI * 0.5
	var sweep := TAU * remain
	var wedge := PackedVector2Array()
	wedge.append(center)
	for i in steps + 1:
		var ang := start + sweep * float(i) / float(steps)
		wedge.append(center + Vector2(cos(ang), sin(ang)) * radius)
	draw_colored_polygon(wedge, Color(0.04, 0.05, 0.08, 0.72))
	draw_arc(center, radius, start, start + sweep, steps, Color(1, 1, 1, 0.55), 2.0)
