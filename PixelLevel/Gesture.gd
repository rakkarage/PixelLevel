extends Node2D

const _max := 2
var _alt := false
var _touch := []
var _zoom_last := 0.0
var _zoom_current := 0.0
var _rotate_last := 0.0
var _rotate_current := 0.0

signal on_zoom(at, value)
signal on_rotate(at, value)

func _ready() -> void:
	z_index = 999
	for _i in range(_max):
		_touch.append({ p = Vector2.ZERO, start = Vector2.ZERO, state = false })

func _mid(a: Vector2, b: Vector2) -> Vector2:
	return (a + b) / 2.0

func _opposite(center: Vector2, p: Vector2) -> Vector2:
	return center - (p - center)

func _mirror_clear() -> void:
	_touch[1].state = Vector2.ZERO
	_touch[1].p = Vector2.ZERO
	_touch[1].start = false

func _mirror() -> void:
	_touch[1].state = _touch[0].state
	_touch[1].p = _opposite(_touch[0].start, _touch[0].p)
	_touch[1].start = _touch[0].start

func _mirror_drag() -> void:
	_touch[1].p = _opposite(_touch[0].start, _touch[0].p)

func _mirror_touch(event: InputEvent) -> void:
	_touch[1].state = _touch[0].state
	_touch[1].p = _opposite(_touch[0].start, _touch[0].p)
	if event.pressed:
		_touch[1].start = _touch[0].start

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ALT:
		_mirror_clear()
		_alt = event.pressed
		if _alt:
			_mirror()
	if event is InputEventScreenDrag:
		_touch[event.index].p = event.position
		if _alt:
			_mirror_drag()
	if event is InputEventScreenTouch:
		_touch[event.index].state = event.pressed
		_touch[event.index].p = event.position
		if event.pressed:
			_touch[event.index].start = event.position
		if _alt:
			_mirror_touch(event)
	var count := 0
	for touch in _touch:
		if touch.state:
			count += 1
	if event is InputEventScreenTouch:
		if not event.pressed and count < 2:
			_zoom_last = 0
			_zoom_current = 0
			_rotate_last = 0
			_rotate_current = 0
	if count == 2:
		_zoom(event)
		_rotate(event)
	# update() TODO: !?

func _zoom(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var zoom : float = _touch[0].p.distance_to(_touch[1].p)
		_zoom_current = _zoom_last - zoom
		_zoom_last = zoom
		on_zoom.emit(_mid(_touch[0].p, _touch[1].p), _zoom_current)

func _rotate(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		var r : float = _touch[0].p.angle_to_point(_touch[1].p)
		_rotate_current = _rotate_last - r
		_rotate_last = r
		on_rotate.emit(_mid(_touch[0].p, _touch[1].p), _rotate_current)

const _colorA := Color(0.25, 0.25, 0.25)
const _colorB := Color(0.5, 0.5, 0.5)
const _colorC := Color(0.75, 0.75, 0.75)

func _draw() -> void:
	if _alt:
		for touch in _touch:
			if touch.state:
				draw_circle(touch.p, 16, _colorC )
				draw_circle(touch.start, 16, _colorA)
				draw_line(touch.start, touch.p, _colorB, 2)
				draw_arc(touch.start, touch.start.distance_to(touch.p), 0, TAU, 32, _colorC, 2)
