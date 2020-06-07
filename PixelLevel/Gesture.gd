extends Node2D
class_name Gesture

const _max := 10

var _points := []

var _zoomLast := 0.0
var _zoomCurrent := 0.0
const _zoomRate := 0.05
var _zoomStarted := false

var _rotateLast := 0.0
var _rotateCurrent := 0.0
const _rotateRate := 1
var _rotateStarted := false

signal onZoom(event)
signal onRotate(event)

var _dragging = false

func _ready() -> void:
	for _i in range(_max):
		_points.append({ p = Vector2.ZERO, start = Vector2.ZERO, state = false })
	Utility.ok(connect("onZoom", self, "onZoom"))
	Utility.ok(connect("onRotate", self, "onRotate"))

func _input(event) -> void:
	if event is InputEventScreenDrag:
		_points[event.index].pos = event.position
	if event is InputEventScreenTouch:
		_points[event.index].state = event.pressed
		_points[event.index].pos  = event.position
		if event.pressed:
			_points[event.index].start_pos = event.position
	var count := 0
	for point in _points:
		if point.state:
			count += 1
	if event is InputEventScreenTouch:
		if not event.pressed and count < 2:
			_zoomLast = 0
			_zoomCurrent = 0
			_zoomStarted = false
			_rotateLast = 0
			_rotateCurrent = 0
			_rotateStarted = false
		if event.pressed and count == 2:
			_zoomStarted = true
			_rotateStarted = true
	if count == 2:
		_zoom(event)
		_rotate(event)

func _zoom(event) -> void:
	if event is InputEventScreenDrag:
		var zoom : float = _points[0].p.distance_to(_points[1].p)
		if _zoomStarted:
			_zoomStarted = false
			_zoomLast = zoom
			_zoomCurrent = zoom
		else:
			_zoomCurrent = _zoomLast - zoom
			_zoomLast = zoom
		emit_signal("onZoom", _zoomCurrent)

func _rotate(event) -> void:
	if event is InputEventScreenDrag:
		var rotate : float = _points[0].p.angle_to_point(_points[1].p)
		if _rotateStarted:
			_rotateStarted = false
			_rotateLast = rotate
			_rotateCurrent = rotate
		else:
			_rotateCurrent = _rotateLast - rotate
			_rotateLast = rotate
		emit_signal("onRotate", _rotateCurrent)

func onZoom(_event) -> void:
	if abs(_zoomCurrent) > 0.1 and abs(_zoomCurrent) < 20:
		var s : Vector2 = $Sprite.scale
		var zoom := - _zoomCurrent * _zoomRate
		s.x = clamp(s.x + zoom, 1, 10)
		s.y = clamp(s.y + zoom, 1, 10)
		$Sprite.scale = s

func onRotate(_event) -> void:
	if abs(_rotateCurrent) > 0.001 and abs(_rotateCurrent) < 0.5:
		var r : float = $Sprite.rotation
		var a := _rotateCurrent * _rotateRate
		$Sprite.rotation = r - a

func _process(_delta) -> void:
	update()

func _draw():
	for point in _points:
		var c := Color(1, 0, 0)
		if not point.state:
			c = Color(0, 0, 1)
		draw_circle(point.p, 32, c)
		draw_circle(point.start, 32, Color(0, 1, 0))
		draw_line(point.p, point.start, Color(1, 1, 0), 4)
