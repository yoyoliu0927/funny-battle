extends Control

const MenuUi := preload("res://scripts/menu_ui.gd")
const IconButton := preload("res://scripts/icon_button.gd")
const LEVEL_ONE := "res://scenes/spikes.tscn"
const COLUMNS := 5
const COUNT := 10
const BOX := 120.0
const GAP := 28.0

var _stage: Control
var _levels: Array[Control] = []
var _back


func _ready() -> void:
	_stage = MenuUi.mount(self)
	for index in COUNT:
		var button := IconButton.new()
		button.name = "Level%d" % (index + 1)
		button.size = Vector2(BOX, BOX)
		if index == 0:
			button.shape = "level"
			button.caption = "1"
			button.font_size = MenuUi.LEVEL_NUMBER_SIZE
			button.pressed.connect(_on_level_one)
		else:
			button.shape = "lock"
		_stage.add_child(button)
		_levels.append(button)
	_back = IconButton.new()
	_back.name = "Back"
	_back.shape = "back"
	_back.pressed.connect(_on_back)
	_stage.add_child(_back)
	_stage.resized.connect(_layout)
	_layout()


func _layout() -> void:
	var view := _stage.size
	if view.x < 2.0 or view.y < 2.0:
		return
	var grid := Vector2(COLUMNS * BOX + (COLUMNS - 1) * GAP, 2.0 * BOX + GAP)
	var origin := (view - grid) * 0.5
	for index in _levels.size():
		var column := index % COLUMNS
		var row := index / COLUMNS
		_levels[index].position = origin + Vector2(column, row) * (BOX + GAP)
		_levels[index].size = Vector2(BOX, BOX)
	var back_size := 84.0
	_back.position = Vector2(32, view.y - back_size - 32)
	_back.size = Vector2(back_size, back_size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		get_viewport().set_input_as_handled()


func _on_level_one() -> void:
	get_tree().change_scene_to_file(LEVEL_ONE)


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/start.tscn")
