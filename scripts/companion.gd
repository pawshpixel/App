class_name Companion
extends Node2D
## Placeholder companion, drawn in code until the Procreate layers exist.
## Body, circuit traces, cables that sway, and one eye that is closed until the Cat is made.

const TEAL := Color("5de8c1")
const VIOLET := Color("9b6dff")
const BODY := Color(0.055, 0.184, 0.188, 0.94)
const HEAD_C := Vector2(0, -30)
const HEAD_R := 62.0
const BODY_C := Vector2(0, 42)
const BODY_R := Vector2(50, 44)
const EYE_R := 40.0

var eye_open := false
var covered := false
var _t := 0.0
var _blink := 0.0
var _next_blink := 5.0
var _look := Vector2.ZERO
var _look_target := Vector2.ZERO
var _flare := 0.0
var _dark := 0.0
var _twitch := 0.0


func open_eye_now() -> void:
	eye_open = true
	_blink = 0.0
	_flare = 1.0
	_look_target = Vector2(0, 6)
	Input.vibrate_handheld(60)


func slow_blink() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_blink", 1.0, 0.6)
	tw.tween_interval(0.8)
	tw.tween_property(self, "_blink", 0.0, 0.6)


func twitch_cable() -> void:
	_twitch = 1.0


func go_dark(seconds: float) -> void:
	_dark = 1.0
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(self, "_dark", 0.0, 0.8)


func look_toward(global_point: Vector2) -> void:
	var d := global_point - global_position
	_look_target = d.normalized() * minf(4.0, d.length() * 0.02)


func _process(delta: float) -> void:
	_t += delta
	_look = _look.lerp(_look_target, delta * 6.0)
	_flare = maxf(0.0, _flare - delta * 0.8)
	_twitch = maxf(0.0, _twitch - delta * 1.5)
	if eye_open:
		_next_blink -= delta
		if _next_blink <= 0.0:
			_next_blink = 7.0 + randf() * 4.0
			var tw := create_tween()
			tw.tween_property(self, "_blink", 1.0, 0.08)
			tw.tween_property(self, "_blink", 0.0, 0.12)
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 1.6) * 4.0
	var trace_a := (0.35 if not eye_open else 0.85) * (1.0 - _dark) + _flare * 0.6
	draw_set_transform(Vector2(0, bob))

	# cables: the traces carry straight down into them
	for i in 5:
		var x := -40.0 + i * 20.0
		var base := Vector2(x, BODY_C.y + BODY_R.y * sqrt(maxf(0.0, 1.0 - pow(x / BODY_R.x, 2))) - 4)
		var pts := PackedVector2Array()
		for s in 9:
			var k := s / 8.0
			var sway := sin(_t * 1.4 + i * 1.3 + k * 3.0) * 7.0 * k * k
			if i == 2:
				sway += sin(_t * 30.0) * 6.0 * _twitch * k
			pts.append(base + Vector2(sway + (x * 0.12) * k, k * 78.0))
		draw_polyline(pts, Color(TEAL, 0.25 + trace_a * 0.6), 8.0, true)
		draw_polyline(pts, Color("0c2a2a"), 4.5, true)
		draw_rect(Rect2(pts[-1] - Vector2(5, 0), Vector2(10, 10)), Color(TEAL, trace_a), false, 2.0)

	# silhouette with rim light
	var rim := Color(TEAL, 0.3 + trace_a * 0.5)
	_draw_ears(rim, 1.1)
	draw_circle(HEAD_C, HEAD_R + 5, rim)
	_draw_ellipse(BODY_C, BODY_R + Vector2(5, 5), rim)
	_draw_ears(BODY, 1.0)
	draw_circle(HEAD_C, HEAD_R, BODY)
	_draw_ellipse(BODY_C, BODY_R, BODY)

	# circuit traces with node rings
	var tc := Color(TEAL, trace_a)
	var traces := [
		[Vector2(-54, -44), Vector2(-44, -44), Vector2(-38, -52), Vector2(-26, -52)],
		[Vector2(54, -44), Vector2(44, -44), Vector2(38, -54)],
		[Vector2(-8, -84), Vector2(4, -84), Vector2(10, -90)],
		[Vector2(-40, 30), Vector2(-40, 58)],
		[Vector2(-26, 22), Vector2(-26, 50), Vector2(-20, 58), Vector2(-20, 76)],
		[Vector2(0, 26), Vector2(0, 80)],
		[Vector2(26, 22), Vector2(26, 50), Vector2(20, 58), Vector2(20, 76)],
		[Vector2(40, 30), Vector2(40, 58)],
	]
	for tr in traces:
		draw_polyline(PackedVector2Array(tr), tc, 2.0, true)
		draw_circle(tr[0], 4.0, BODY)
		draw_arc(tr[0], 4.0, 0, TAU, 12, tc, 1.6, true)

	# the eye
	var e := HEAD_C + Vector2(0, 4)
	if eye_open and not covered:
		var squash := 1.0 - _blink
		draw_set_transform(Vector2(0, bob) + e, 0.0, Vector2(1, maxf(0.05, squash)))
		draw_circle(Vector2.ZERO, EYE_R + 3, Color(VIOLET, 0.35))
		draw_circle(Vector2.ZERO, EYE_R, Color("161232"))
		draw_circle(Vector2.ZERO, EYE_R * 0.8, VIOLET)
		draw_circle(Vector2.ZERO, EYE_R * 0.58, TEAL)
		draw_circle(Vector2.ZERO, EYE_R * 0.5, Color("e8f7f0"))
		draw_circle(_look, EYE_R * 0.46, Color.BLACK)
		draw_set_transform(Vector2(0, bob))
	elif not eye_open:
		var lid := PackedVector2Array()
		for s in 13:
			var k := s / 12.0
			lid.append(e + Vector2(lerpf(-30, 30, k), -sin(k * PI) * 8.0))
		draw_polyline(lid, Color(VIOLET, 0.8), 5.0, true)
		draw_polyline(lid, Color("e8f7f0"), 1.5, true)
		for k in [0.15, 0.38, 0.62, 0.85]:
			var p := e + Vector2(lerpf(-30, 30, k), -sin(k * PI) * 8.0)
			draw_line(p, p + Vector2((k - 0.5) * 8.0, 7), Color(VIOLET, 0.6), 1.6, true)
		draw_circle(e + Vector2(0, 4), 26.0, Color(TEAL, 0.06))
	if covered:
		for side in [-1, 1]:
			var arc := PackedVector2Array()
			for s in 10:
				var k := s / 9.0
				arc.append(e + Vector2(side * lerpf(44, -8, k), lerpf(60, -14, k) - sin(k * PI) * 8))
			draw_polyline(arc, TEAL, 8.0, true)
			draw_polyline(arc, Color("0c2a2a"), 4.5, true)


func _draw_ears(col: Color, s: float) -> void:
	for side in [-1, 1]:
		var pts := PackedVector2Array([
			HEAD_C + Vector2(side * 34, -52) * s,
			HEAD_C + Vector2(side * 40, -96) * s,
			HEAD_C + Vector2(side * 6, -60) * s,
		])
		draw_colored_polygon(pts, col)


func _draw_ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
