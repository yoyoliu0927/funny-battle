extends "res://scripts/duel.gd"
## One additional arena, using the existing duel UI, actors and three props.

const SPIKE_STAGE := preload("res://scripts/spike_stage.gd")
const SLIP_DISTANCE := 64.0
const BANANA_RADIUS := 20.0
const RUSH_WINDUP := 0.85
const RUSH_TIME := 1.0
const EDGE_HOLD := 0.4
const EDGE_MARGIN := 20.0
const HERO_HP := 8
const BOSS_PATTERN: Array[String] = ["普通1", "衝刺", "遠距離普攻", "蓄力", "遠距離追擊", "衝刺"]
var _ended := false
var _hero_wait := 0.0
var _boss_move: Dictionary = {}
var _boss_state := ""
var _rush_direction := -1.0
var _rush_target := 380.0
var _rush_previous_x := 780.0
var _rush_hit := false
var _banana_fall := false
var _boss_turn := 0
var _boss_action := ""


func _ready() -> void:
	qte = false
	brawl = false
	super._ready()
	remove_child(_stage)
	_stage.queue_free()
	_stage = SPIKE_STAGE.new()
	add_child(_stage)
	_boss_move = (_moves["普通1"] as Dictionary).duplicate()
	_boss_move.merge({
		"startup": 0.85, "active": 0.12, "recover": 0.65,
		"range": 145.0, "damage": 2, "stun": 0.35, "kb": 20.0, "chain": "",
	}, true)
	_reset_fighters()


func _reset_fighters() -> void:
	_ended = false
	_hero_wait = 0.0
	_boss_state = ""
	_rush_direction = -1.0
	_rush_target = 380.0
	_rush_previous_x = 780.0
	_rush_hit = false
	_banana_fall = false
	_boss_turn = 0
	_boss_action = ""
	left.display_name = "主角"
	right.display_name = "BOSS"
	left.hp_max = HERO_HP
	right.hp_max = 30
	left.scale = Vector2.ONE * 0.65
	right.scale = Vector2.ONE * 1.2
	left.use_sheet("bare")
	right.use_sheet("armor")
	left.position = Vector2(460, 500)
	right.position = Vector2(780, 500)
	for body in [left, right]:
		body.set_process(true)
		body.ground_y = 500
		body.relax()
		body.glow = 0
		_stand(body)
	left.face_right = true
	right.face_right = false
	left.play("idle")
	right.play("idle")
	_apply_pace()
	_apply_hp_flags()
	_title.text = ""
	_hide_arena_chrome()
	_refresh_hint()


func _restart() -> void:
	super._restart()
	_reset_fighters()


func _process(delta: float) -> void:
	if _ended:
		return
	if not _preview and not _stage.editing:
		_keep_boss_on_bridge()
		_check_spikes()
		if _ended:
			return
	_hero_wait = maxf(0, _hero_wait - delta * _pace)
	super._process(delta)
	if _preview or _stage.editing:
		return
	_check_spikes()
	if left.out or right.out:
		_finish_round()
	else:
		var power_windup := right.use_module and str(right.sheet_move.get("id", "")) == "蓄力" and right.action_age < float(right.sheet_move.get("startup", 0))
		right.glow = 1 if (_boss_state == "windup" and right.use_module) or power_windup else 0
		if _boss_state == "charge" and right.use_module and right.action_age >= RUSH_TIME and right.anim == "run":
			right._swap_anim("idle")
		if _boss_state == "windup" and right.use_module:
			_title.text = "蓄力"
		elif _boss_state == "charge" and right.anim == "run":
			_title.text = "衝刺"
		elif right.use_module and not right.sheet_move.is_empty():
			_title.text = _move_title(str(right.sheet_move["id"]))
		elif left.use_module and not left.sheet_move.is_empty():
			_title.text = _move_title(str(left.sheet_move["id"]))
		else:
			_title.text = ""


func _think_open(body: Duelist, other: Duelist) -> void:
	if _preview:
		super._think_open(body, other)
		return
	if _ended or _stage.editing or not body.can_act() or body.out or other.out:
		return
	body.just_landed = false
	if body.anim == "down":
		body.go("getup", body.position.x, body.clip_cycle("getup"))
		return
	var gap := other.position.x - body.position.x
	body.face_right = gap >= 0
	if body == left:
		_think_hero(other)
		return
	if body.chain != "":
		var next := body.chain
		body.chain = ""
		if not other.airborne and _chain_ok(body, other, next):
			_play_module(body, other, next)
			return
	match _boss_state:
		"windup":
			_boss_state = "charge"
			_rush_hit = false
			_rush_previous_x = body.position.x
			body.face_right = _rush_direction > 0
			body.sheet_move = {}
			body.start_module("run", _rush_target, RUSH_TIME + EDGE_HOLD, RUSH_TIME, -1.0, "")
		"charge", "interrupted":
			_start_return()
		"approach":
			_begin_boss_move()
		"attack":
			# Leave a readable opening after the full attack/chain so the
			# smaller fighter can close in and finish its own original combo.
			_boss_state = "recover"
			body.go("idle", body.position.x, 0.35)
		_:
			var distance := absf(gap)
			if other.slipping and _band(distance, "遠距離追擊"):
				_boss_action = "遠距離追擊"
			elif other.frozen > 0 and _band(distance, "遠距離普攻"):
				_boss_action = "遠距離普攻"
			elif other.frozen > 0 and _band(distance, "蓄力"):
				_boss_action = "蓄力"
			else:
				_boss_action = BOSS_PATTERN[_boss_turn % BOSS_PATTERN.size()]
				_boss_turn += 1
			_begin_boss_move()


func _think_hero(other: Duelist) -> void:
	var gap := other.position.x - left.position.x
	var distance := absf(gap)
	if left.chain != "":
		var next := left.chain
		left.chain = ""
		if not other.airborne and _chain_ok(left, other, next):
			_play_module(left, other, next)
			return
	if _hero_wait <= 0 and other.frozen > 0:
		if _band(distance, "遠距離普攻"):
			_play_module(left, other, "遠距離普攻")
			_hero_wait = 1.0
			return
		if _band(distance, "蓄力"):
			_play_module(left, other, "蓄力")
			_hero_wait = 1.0
			return
	if _hero_wait <= 0 and other.slipping and not _banana_fall and _band(distance, "遠距離追擊"):
		_play_module(left, other, "遠距離追擊")
		_hero_wait = 1.0
		return
	if _boss_state in ["windup", "charge"] and not other.slipping:
		# Retreat inside the bridge instead of standing still or running into
		# the edge trap. A spring or enemy knockback can still knock us off.
		_step_fighter(left, left.position.x - signf(gap) * 48.0)
	elif distance > 88 and not other.airborne:
		_step_fighter(left, left.position.x + signf(gap) * minf(48, distance - 84))
	elif _hero_wait <= 0 and not other.airborne:
		_play_module(left, other, "普通1")
		_hero_wait = 1.2
	else:
		left.go("idle", left.position.x, 0.2)


func _step_fighter(body: Duelist, target: float) -> void:
	var bounds := _bridge_bounds()
	var margin := minf(72.0 if body == left else EDGE_MARGIN, (bounds.y - bounds.x) * 0.45)
	var destination := clampf(target, bounds.x + margin, bounds.y - margin)
	if absf(destination - body.position.x) < 2:
		body.go("idle", body.position.x, 0.2)
		return
	body.face_right = destination > body.position.x
	body.go("walk", destination, 0.4)


func _begin_boss_move() -> void:
	var gap := left.position.x - right.position.x
	if _boss_action == "衝刺":
		var bounds := _bridge_bounds()
		_boss_state = "windup"
		_rush_direction = 1.0 if gap > 0 else -1.0
		_rush_target = bounds.y - EDGE_MARGIN if _rush_direction > 0 else bounds.x + EDGE_MARGIN
		right.face_right = _rush_direction > 0
		right.chain = ""
		right.sheet_move = {}
		right.start_module("power", right.position.x, RUSH_WINDUP, 0.0, -1.0, "")
		return
	var move: Dictionary = _moves[_boss_action]
	var reach := 88.0 if _boss_action == "普通1" else float(move["range"])
	if _boss_action == "遠距離追擊":
		reach += float(move["travel_max"])
	if absf(gap) > reach:
		_boss_state = "approach"
		_step_fighter(right, right.position.x + signf(gap) * minf(56, absf(gap) - reach + 4))
		return
	_boss_state = "attack"
	_play_module(right, left, _boss_action)


func _play_module(body: Duelist, other: Duelist, id: String) -> void:
	super._play_module(body, other, id)
	if _preview or not body.use_module:
		return
	# Reuse the original modules and animations. Limit their travel to safe
	# bridge positions; external slips and hits on the hero remain dangerous.
	var bounds := _bridge_bounds()
	var margin := minf(72.0 if body == left else EDGE_MARGIN, (bounds.y - bounds.x) * 0.45)
	body._to = clampf(body._to, bounds.x + margin, bounds.y - margin)
	if body == right:
		body.sheet_move["kb"] = minf(float(body.sheet_move["kb"]), 18)


func _bridge_bounds() -> Vector2:
	if _stage.strips.is_empty():
		return Vector2(360, 1050)
	var strip: Dictionary = _stage.strips[0]
	return Vector2(minf(float(strip["x0"]), float(strip["x1"])), maxf(float(strip["x0"]), float(strip["x1"])))


func _start_return() -> void:
	_boss_state = "return"
	_boss_action = ""
	_banana_fall = false
	var bounds := _bridge_bounds()
	var home := clampf(780, bounds.x + EDGE_MARGIN, bounds.y - EDGE_MARGIN)
	right.face_right = home > right.position.x
	right.go("walk", home, 1.2)


func _moving_off_right() -> bool:
	var edge := _bridge_bounds().y
	if right.position.x > edge:
		return true
	if right.slipping and right._to > edge:
		return true
	# A rightward bounce keeps its speed. Once that arc reaches the lip, let it leave.
	return right.airborne and right.air_vx > 0.0 and right.position.x >= edge - right.air_vx / 60.0 - 1.0


func _keep_boss_on_bridge() -> void:
	# Banana slips can leave either lip. A bounce or slide can also carry the
	# boss off the right lip. The left lip still rejects a spring by itself.
	if right.out:
		return
	if _moving_off_right():
		_banana_fall = true
		return
	if _banana_fall:
		return
	var bounds := _bridge_bounds()
	var safe_x := clampf(right.position.x, bounds.x + 1, bounds.y - 1)
	if not is_equal_approx(safe_x, right.position.x):
		right.position.x = safe_x
		right.air_vx = 0
	right._from = clampf(right._from, bounds.x + 1, bounds.y - 1)
	right._to = clampf(right._to, bounds.x + 1, bounds.y - 1)
	if right.position.y >= SPIKE_STAGE.SPIKE_Y:
		right.ground_y = ground_height(safe_x, 500)
		if right.ground_y >= SPIKE_STAGE.SPIKE_Y:
			right.ground_y = 500
		right.position.y = right.ground_y
		right._plant()
		var health := right.hp
		right.relax()
		right.hp = health
		_boss_state = "interrupted"


func _resolve_modules() -> void:
	super._resolve_modules()
	if _preview or _boss_state != "charge" or _rush_hit or right.out or left.out:
		return
	if not right.use_module or right.slipping or right.airborne or right.frozen > 0 or right.hitstop > 0:
		return
	var low := minf(_rush_previous_x, right.position.x) - 58.0
	var high := maxf(_rush_previous_x, right.position.x) + 58.0
	if right.action_age <= RUSH_TIME and left.position.x >= low and left.position.x <= high and absf(left.position.y - right.position.y) < 100:
		_rush_hit = true
		_land_hit(right, left, _boss_move)
	_rush_previous_x = right.position.x


func _land_hit(attacker: Duelist, defender: Duelist, move: Dictionary) -> void:
	if _preview or defender != right:
		super._land_hit(attacker, defender, move)
		return
	if defender.out:
		return
	# Small attacks can chip health, but never push, cancel a charge/slide,
	# or defeat the boss without the required terrain interaction.
	var damage := maxi(int(round(float(move["damage"]))), 0)
	defender.hp = maxi(1, defender.hp - damage)
	attacker.chain = str(move.get("chain", ""))
	if attacker.chain != "":
		attacker.leave_active(float(move["active"]))
	attacker.hitstop = maxf(attacker.hitstop, 0.03)
	defender.hitstop = maxf(defender.hitstop, 0.03)
	_shake = maxf(_shake, 4)
	_spark(defender.chest(), attacker.sheet)


func _try_peel(body: Duelist, prop: DuelProp) -> bool:
	if _preview:
		return super._try_peel(body, prop)
	if body.out or body.slipping or body.airborne:
		return false
	var row: Dictionary = _items["香蕉"]
	var direction := signf(body.vx) if absf(body.vx) > 1 else (1.0 if body.face_right else -1.0)
	body.begin_slip(direction, SLIP_DISTANCE, float(row["recover"]))
	if body == right:
		var bounds := _bridge_bounds()
		_banana_fall = body._to < bounds.x or body._to > bounds.y
		_boss_state = "interrupted"
		body.glow = 0
	prop.consume()
	return true


func _try_spring(body: Duelist, prop: DuelProp) -> bool:
	var launched := super._try_spring(body, prop)
	if launched and body == right and not _preview:
		_banana_fall = false
		_boss_state = "interrupted"
	return launched


func _place(at: Vector2) -> void:
	if _ended or ground_height(at.x, at.y) >= SPIKE_STAGE.SPIKE_Y:
		return
	var before := get_child_count()
	super._place(at)
	if get_child_count() > before:
		var prop := get_child(get_child_count() - 1) as DuelProp
		if prop != null and prop.kind == "peel" and not _preview:
			prop.radius = BANANA_RADIUS


func _facing_hit(attacker: Duelist, defender: Duelist, reach: float) -> bool:
	if attacker.out or defender.out or absf(attacker.position.y - defender.position.y) > 100:
		return false
	return super._facing_hit(attacker, defender, reach)


func _check_spikes() -> void:
	for body in [left, right]:
		if not body.out and body.position.y >= SPIKE_STAGE.SPIKE_Y:
			if body == right and not _banana_fall:
				_keep_boss_on_bridge()
				continue
			body.hp = 0
			body.out = true
	if left.out or right.out:
		_finish_round()


func _finish_round() -> void:
	_ended = true
	for body in [left, right]:
		body.glow = 0
		body.set_process(false)
	for node in get_tree().get_nodes_in_group("duel_prop"):
		node.set_process(false)
	_title.text = "平手" if left.out and right.out else ("失敗" if left.out else "勝利")
	_refresh_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/levels.tscn")
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB or event.keycode == KEY_G or event.keycode == KEY_P or event.keycode == KEY_T:
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _refresh_hint() -> void:
	super._refresh_hint()
	if _hint != null:
		_hint.visible = false
		_hint.text = ""


func _hide_arena_chrome() -> void:
	for key in _cast_buttons.keys():
		var button := _cast_buttons[key] as Node
		if button != null:
			button.queue_free()
	_cast_buttons.clear()
	for node in [_watch_button, _pace_button, _hp_button, _count_button, _practice_button, _ground_button, _preview_row]:
		if node != null:
			node.queue_free()
	_watch_button = null
	_pace_button = null
	_hp_button = null
	_count_button = null
	_practice_button = null
	_ground_button = null
	_preview_row = null
	if _hint != null:
		_hint.visible = false
		_hint.text = ""
