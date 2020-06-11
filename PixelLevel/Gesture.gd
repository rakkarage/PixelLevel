extends Node2D

const _max := 10

var _touch := []

var _zoomLast := 0.0
var _zoomCurrent := 0.0
const _zoomRate := 0.05
var _zoomStarted := false

var _rotateLast := 0.0
var _rotateCurrent := 0.0
const _rotateRate := 1
var _rotateStarted := false

signal onZoom(at, value)
signal onRotate(at, value)

var _alt = false

func _ready() -> void:
	# var test = []
	# test[0] = 1
	# test[1] = 999

	for _i in range(_max):
		_touch.append({ p = Vector2.ZERO, start = Vector2.ZERO, state = false })
	# Utility.ok(connect("onZoom", self, "onZoom"))
	# Utility.ok(connect("onRotate", self, "onRotate"))

func _mirrorDrag(event: InputEvent) -> void:
	var i = event.index
	var o = i + 5
	_touch[o].p = _opposite(_touch[i].start, _touch[i].p)

func _mirrorTouch(event: InputEvent) -> void:
	var i = event.index
	var o = i + 5
	_touch[o].state = _touch[i].state
	_touch[o].p = _opposite(_touch[i].start, _touch[i].p)
	if event.pressed:
		_touch[o].start = _touch[i].start

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.scancode == KEY_ALT:
		_alt = event.pressed
	if event is InputEventScreenDrag:
		_touch[event.index].p = event.position
		if _alt:
			print("alt drag")
			_mirrorDrag(event)
		# 	var i = event.index
		# 	var o = i + 5
		# 	_touch[o].p = _opposite(_touch[i].start, _touch[i].p)
	if event is InputEventScreenTouch:
		_touch[event.index].state = event.pressed
		_touch[event.index].p = event.position
		if event.pressed:
			_touch[event.index].start = event.position
		if _alt:
			print("alt touch")
			_mirrorTouch(event)
	var count := 0
	for touch in _touch:
		if touch.state:
			count += 1
	print(count)
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

# func _simulateTouch(event: InputEvent) -> void:
# 	if event is InputEventKey and event.scancode == KEY_ALT:
# 		var i = 0
# 		if event.pressed:
# 			if i == 0: i = 1
# 		else:
# 			if i == 1: i = 0
# 	if event is InputEventMouseButton:
# 		_points[event.index].state = event.pressed
# 		_points[event.index].p  = event.position
# 		if event.pressed:
# 			_points[event.index].start = event.position
# 	if event is InputEventMouseMotion:
# 		_points[event.index].p = event.position
# 	update_touch_info()
# 	update_pinch_gesture()

func _zoom(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var zoom : float = _touch[0].p.distance_to(_touch[1].p)
		if _zoomStarted:
			_zoomStarted = false
			_zoomLast = zoom
			_zoomCurrent = zoom
		else:
			_zoomCurrent = _zoomLast - zoom
			_zoomLast = zoom
		emit_signal("onZoom", event.position, _zoomCurrent)

func _rotate(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var rotate : float = _touch[0].p.angle_to_point(_touch[1].p)
		if _rotateStarted:
			_rotateStarted = false
			_rotateLast = rotate
			_rotateCurrent = rotate
		else:
			_rotateCurrent = _rotateLast - rotate
			_rotateLast = rotate
		emit_signal("onRotate", event.position, _rotateCurrent)

# func onZoom(_at: Vector2, _value: float) -> void:
# 	print("zoom")
# 	if abs(_zoomCurrent) > 0.1 and abs(_zoomCurrent) < 20:
# 		var s : Vector2 = $Sprite.scale
# 		var zoom := - _zoomCurrent * _zoomRate
# 		s.x = clamp(s.x + zoom, 1, 10)
# 		s.y = clamp(s.y + zoom, 1, 10)
# 		$Sprite.scale = s

# func onRotate(_at: Vector2, _value) -> void:
# 	print("rotate")
# 	if abs(_rotateCurrent) > 0.001 and abs(_rotateCurrent) < 0.5:
# 		var r : float = $Sprite.rotation
# 		var a := _rotateCurrent * _rotateRate
# 		$Sprite.rotation = r - a

func _process(_delta) -> void:
	update()

func _draw():
	# if get_tree().is_editor_hint():
	for touch in _touch:
		if touch.state:
			draw_circle(touch.p, 16, Color(1, 0, 0))
			draw_circle(touch.start, 16, Color(0, 1, 0))
			draw_line(touch.start, touch.p, Color(1, 1, 0), 2)
			# if _alt:
			# 	var opposite = _opposite(touch.start, touch.p)
			# 	draw_circle(opposite, 16, Color(0, 1, 1))
			# 	draw_line(opposite, touch.start, Color(1, 1, 0), 2)

func _opposite(start: Vector2, p: Vector2) -> Vector2:
	return start - (p - start)
