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
	for _i in range(_max):
		_touch.append({ p = Vector2.ZERO, start = Vector2.ZERO, state = false })

func _mirror() -> void:
	var i = 0
	var o = i + 5
	_touch[o].state = _touch[i].state
	_touch[o].p = _opposite(_touch[i].start, _touch[i].p)
	_touch[o].start = _touch[i].start

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
		if _alt:
			_mirror()
	if event is InputEventScreenDrag:
		_touch[event.index].p = event.position
		if _alt:
			_mirrorDrag(event)
	if event is InputEventScreenTouch:
		_touch[event.index].state = event.pressed
		_touch[event.index].p = event.position
		if event.pressed:
			_touch[event.index].start = event.position
		if _alt:
			_mirrorTouch(event)
	var count := 0
	for touch in _touch:
		if touch.state:
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
	update()

func _zoom(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		# hardcode 0 and 1 if going to!?
		var zoom : float = _touch[0].p.distance_to(_touch[1].p)
		# print("z: %s" % zoom)
		if _zoomStarted:
			_zoomStarted = false
			_zoomLast = zoom
			_zoomCurrent = zoom
		else:
			_zoomCurrent = _zoomLast - zoom
			_zoomLast = zoom
		# print(_zoomCurrent)
		emit_signal("onZoom", _touch[0].start, _zoomCurrent)

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
		emit_signal("onRotate", _touch[0].start, _rotateCurrent)

func _draw():
	# if get_tree().is_editor_hint():
	for touch in _touch:
		if touch.state:
			draw_circle(touch.p, 16, Color(1, 0, 0))
			draw_circle(touch.start, 16, Color(0, 1, 0))
			draw_line(touch.start, touch.p, Color(1, 1, 0), 2)

func _opposite(center: Vector2, p: Vector2) -> Vector2:
	return center - (p - center)
