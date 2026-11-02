extends RefCounted

## Colors and type sizes for the start page and level select.
## Change these constants to restyle both screens.
const TITLE := Color(0, 0, 0)
const INK := Color(0, 0, 0)
const FILL := Color(1, 1, 1)
const HOVER := Color(0.1, 0.1, 0.1)
const HOVER_INK := Color(1, 1, 1)
const LOCKED := Color(0.15, 0.15, 0.15)
const STROKE := 4.0
const TITLE_SIZE := 92
const BUTTON_TEXT_SIZE := 36
const LEVEL_NUMBER_SIZE := 48

static var _font: SystemFont


static func font() -> SystemFont:
	if _font == null:
		_font = SystemFont.new()
		_font.font_names = PackedStringArray(["Segoe UI", "Arial", "Helvetica", "Microsoft YaHei"])
		_font.font_weight = 700
		_font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return _font


static func add_background(host: Control) -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = load("res://start_bg.png")
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)


static func mount(host: Control) -> Control:
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_background(host)
	var stage := Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(stage)
	return stage
