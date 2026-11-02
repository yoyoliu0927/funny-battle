extends Button

const MenuUi := preload("res://scripts/menu_ui.gd")

var shape := "play"
var caption := ""
var font_size := 36

var _label: Label
var _hot := false


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, empty)


func _ready() -> void:
	if shape == "lock":
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		mouse_entered.connect(_on_hover.bind(true))
		mouse_exited.connect(_on_hover.bind(false))
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)
	if caption != "":
		_label = Label.new()
		_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.text = caption
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_override("font", MenuUi.font())
		_label.add_theme_font_size_override("font_size", font_size)
		_label.add_theme_color_override("font_color", MenuUi.INK)
		add_child(_label)


func _on_hover(hot: bool) -> void:
	_hot = hot
	if _label != null:
		_label.add_theme_color_override("font_color", MenuUi.HOVER_INK if hot else MenuUi.INK)
	queue_redraw()


func _draw() -> void:
	var hot := _hot or button_pressed
	var ink := MenuUi.HOVER_INK if hot else MenuUi.INK
	var fill := MenuUi.HOVER if hot else MenuUi.FILL
	match shape:
		"play":
			_draw_circle_button(fill, ink, 1.0)
		"back":
			_draw_circle_button(fill, ink, -1.0)
		"tutorial", "level":
			_draw_box(fill, ink)
		"lock":
			_draw_box(MenuUi.FILL, MenuUi.LOCKED)
			_draw_lock()


func _draw_circle_button(fill: Color, ink: Color, direction: float) -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - MenuUi.STROKE * 0.5
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 64, ink, MenuUi.STROKE, true)
	var reach := radius * 0.42
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-reach * 0.75 * direction, -reach),
		center + Vector2(-reach * 0.75 * direction, reach),
		center + Vector2(reach * direction, 0.0),
	]), ink)


func _draw_box(fill: Color, ink: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), fill, true)
	var inset := MenuUi.STROKE * 0.5
	draw_rect(Rect2(inset, inset, size.x - MenuUi.STROKE, size.y - MenuUi.STROKE), ink, false, MenuUi.STROKE)


func _draw_lock() -> void:
	var center := size * 0.5
	var unit := minf(size.x, size.y)
	var body := Rect2(center.x - unit * 0.22, center.y - unit * 0.04, unit * 0.44, unit * 0.34)
	draw_arc(Vector2(center.x, body.position.y), unit * 0.13, PI, TAU, 24, MenuUi.LOCKED, unit * 0.06, true)
	draw_rect(body, MenuUi.LOCKED, true)
	draw_circle(Vector2(center.x, body.position.y + body.size.y * 0.5), unit * 0.055, MenuUi.FILL)
