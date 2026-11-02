extends Control

const MenuUi := preload("res://scripts/menu_ui.gd")
const IconButton := preload("res://scripts/icon_button.gd")

var _stage: Control
var _play
var _tutorial


func _ready() -> void:
	_stage = MenuUi.mount(self)
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "FUNNY BATTLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.5
	title.offset_left = 0.0
	title.offset_right = 0.0
	title.offset_top = 0.0
	title.offset_bottom = 0.0
	title.add_theme_font_override("font", MenuUi.font())
	title.add_theme_font_size_override("font_size", MenuUi.TITLE_SIZE)
	title.add_theme_color_override("font_color", MenuUi.TITLE)
	_stage.add_child(title)

	_play = IconButton.new()
	_play.name = "Play"
	_play.shape = "play"
	_play.pressed.connect(_on_play)
	_stage.add_child(_play)

	_tutorial = IconButton.new()
	_tutorial.name = "Tutorial"
	_tutorial.shape = "tutorial"
	_tutorial.caption = "Tutorial"
	_tutorial.font_size = MenuUi.BUTTON_TEXT_SIZE
	_tutorial.pressed.connect(_tutorial_stub)
	_stage.add_child(_tutorial)
	_stage.resized.connect(_layout)
	_layout()


func _layout() -> void:
	var view := _stage.size
	if view.x < 2.0 or view.y < 2.0:
		return
	var play_size := 140.0
	var tutorial_size := Vector2(230, 76)
	var gap := 40.0
	var row_width := play_size + gap + tutorial_size.x
	var left := (view.x - row_width) * 0.5
	var mid_y := view.y * 0.58
	_play.position = Vector2(left, mid_y - play_size * 0.5)
	_play.size = Vector2(play_size, play_size)
	_tutorial.position = Vector2(left + play_size + gap, mid_y - tutorial_size.y * 0.5)
	_tutorial.size = tutorial_size


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/levels.tscn")


func _tutorial_stub() -> void:
	# Tutorial flow is not built yet.
	pass
