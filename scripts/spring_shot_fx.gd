extends Node2D
## 短暫的彈射氣流、槍口閃光與曳光；命中仍由戰鬥模組在開火影格判定。

var kind := "launch"
var origin := Vector2.ZERO
var end := Vector2.ZERO
var direction := -1.0
var hit := false
var pace := 1.0
var age := 0.0
var life := 0.32


func _ready() -> void:
	z_index = 12
	add_to_group("spring_shot_fx")
	if kind == "shot":
		life = 0.22
	_play_sound()


func _process(delta: float) -> void:
	age += delta * pace
	if age >= life:
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	var t := clampf(age / life, 0.0, 1.0)
	var fade := 1.0 - t
	var cyan := Color(0.28, 1.0, 0.9, fade)
	if kind == "launch":
		for i in 5:
			var offset := Vector2(-direction * (12.0 + float(i) * 8.0), -12.0 - float(i) * 9.0)
			var drift := Vector2(-direction * t * 48.0, -t * 18.0)
			draw_line(origin + offset + drift, origin + offset + drift + Vector2(-direction * 24.0, 0), cyan, 3.0)
		draw_arc(origin + Vector2(0, -12), 14.0 + t * 44.0, 0, TAU, 32, Color(0.4, 1, 0.92, fade * 0.6), 3.0)
		return
	draw_line(origin, end, Color(0.15, 0.8, 1.0, fade * 0.22), 16.0)
	draw_line(origin, end, Color(0.4, 1.0, 0.94, fade), 5.0)
	draw_line(origin, end, Color(1.0, 1.0, 0.86, fade), 2.0)
	var aim := (end - origin).normalized()
	draw_circle(origin, 13.0 * fade, Color(1.0, 0.94, 0.55, fade))
	for i in 6:
		var ray := Vector2.RIGHT.rotated(TAU * float(i) / 6.0)
		draw_line(origin + ray * 9.0, origin + ray * (10.0 + 16.0 * fade), Color(1, 0.85, 0.4, fade), 2.0)
	if hit:
		for i in 8:
			var ray := aim.rotated(TAU * float(i) / 8.0)
			draw_line(end + ray * (8.0 + t * 10.0), end + ray * (18.0 + t * 38.0), cyan, 3.0)
		draw_arc(end, 8.0 + t * 30.0, 0, TAU, 32, cyan, 2.0)


func _play_sound() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var duration := 0.16 if kind == "launch" else 0.10
	var samples := int(duration * float(stream.mix_rate))
	var data := PackedByteArray()
	data.resize(samples * 2)
	var phase := 0.0
	for i in samples:
		var t := float(i) / float(samples)
		var frequency := lerpf(180.0, 620.0, t) if kind == "launch" else lerpf(1600.0, 180.0, t)
		phase += TAU * frequency / float(stream.mix_rate)
		var envelope := minf(t * 40.0, 1.0) * pow(1.0 - t, 2.0)
		var wave := sin(phase) * 0.7 + sin(phase * 2.31) * 0.3
		data.encode_s16(i * 2, int(wave * envelope * 10000.0))
	stream.data = data
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -13.0
	add_child(player)
	player.play()
