extends Node2D

const _max := 2
var _alt := false
var _touch := []
var _zoomLast := 0.0
var _zoomCurrent := 0.0
var _rotateLast := 0.0
var _rotateCurrent := 0.0

signal onZoom(at, value)
signal onRotate(at, value)

func _ready() -> void:
	z_index = 999
	for _i in range(_max):
		_touch.append({ p = Vector2.ZERO, start = Vector2.ZERO, state = false })

func _mid(a: Vector2, b: Vector2) -> Vector2:
	return (a + b) / 2.0

func _opposite(center: Vector2, p: Vector2) -> Vector2:
	return center - (p - center)

func _mirror() -> void:
	if _alt:
		_touch[1].state = _touch[0].state
		_touch[1].p = _opposite(_touch[0].start, _touch[0].p)
		_touch[1].start = _touch[0].start
	else:
		_touch[1].state = Vector2.ZERO
		_touch[1].p = Vector2.ZERO
		_touch[1].start = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.scancode == KEY_ALT:
		_alt = event.pressed
		_mirror()
	if event is InputEventScreenDrag:
		_touch[event.index].p = event.position
		_mirror()
	if event is InputEventScreenTouch:
		_touch[event.index].state = event.pressed
		_touch[event.index].p = event.position
		if event.pressed:
			_touch[event.index].start = event.position
		_mirror()
	var count := 0
	for touch in _touch:
		if touch.state:
			count += 1
	if event is InputEventScreenTouch:
		if not event.pressed and count < 2:
			_zoomLast = 0
			_zoomCurrent = 0
			_rotateLast = 0
			_rotateCurrent = 0
	if count == 2:
		_zoom(event)
		_rotate(event)
	update()

func _zoom(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var zoom : float = _touch[0].p.distance_to(_touch[1].p)
		_zoomCurrent = _zoomLast - zoom
		_zoomLast = zoom
		emit_signal("onZoom", _mid(_touch[0].p, _touch[1].p), _zoomCurrent)

func _rotate(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var rotate : float = _touch[0].p.angle_to_point(_touch[1].p)
		_rotateCurrent = _rotateLast - rotate
		_rotateLast = rotate
		emit_signal("onRotate", _mid(_touch[0].p, _touch[1].p), -_rotateCurrent)

const _colorA := Color(0.25, 0.25, 0.25)
const _colorB := Color(0.5, 0.5, 0.5)
const _colorC := Color(0.75, 0.75, 0.75)

func _draw():
	if _alt:
		for touch in _touch:
			if touch.state:
				draw_circle(touch.p, 16, _colorC )
				draw_circle(touch.start, 16, _colorA)
				draw_line(touch.start, touch.p, _colorB, 2)
				draw_arc(touch.start, touch.start.distance_to(touch.p), 0, TAU, 32, _colorC, 2)
