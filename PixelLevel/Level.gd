extends Viewport

onready var _camera       := $Camera
onready var _back: TileMap = $Back
onready var _fore: TileMap = $Fore
onready var _mob          := $Mob
onready var _target       := $Target
onready var _tween        := $Tween
onready var _astar        := AStar2D.new()
var _rect := Rect2()
var _path := PoolVector2Array()
var _dragRight := false
var _dragLeft := false
const _duration := 0.333
var _zoomMin := Vector2(0.01, 0.01)
var _zoomMax := Vector2(1.0, 1.0)
const _zoomVector := Vector2(0.02, 0.02)

func _ready() -> void:
	_rect = _back.get_used_rect()
	_addPoints();
	# _targetTo(_map(_mob.global_position))
	# _cameraTo(_map(_mob.position))
	# _camera.global_position = Vector2(320, 240)
	# print(_camera.position)
	# print(_camera.offset)

func _tileIndex(p: Vector2) -> int:
	return int(p.x + (p.y * _rect.size.x))

func _tilePosition(i: int) -> Vector2:
	var y := i / _rect.size.x
	var x := i - _rect.size.x * y
	return Vector2(x, y);

func _addPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			var p := Vector2(x, y)
			_astar.add_point(_tileIndex(p), p)

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				_targetTo(event.global_position)
				_dragRight = true
			else:
				_dragRight = false
		elif event.button_index == BUTTON_LEFT:
			if event.pressed:
				_targetTo(event.global_position)
				_dragLeft = true
			else:
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			var new = _camera.zoom - _zoomVector
			if new >= _zoomMin:
				_camera.zoom = new
				print("up: %s" % new.x)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			var new = _camera.zoom + _zoomVector
			if new <= _zoomMax:
				_camera.zoom = new
				print("down: %s" % new.x)
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_camera.offset -= event.relative * _camera.zoom
		if _dragRight:
			_camera.global_position -= event.relative * _camera.zoom

# func _zoomIn(offset: Vector2) -> void:
# 	_zoom(Vector2(_zoomMin, _zoomMin), offset)

# func _zoomOut(offset: Vector2) -> void:
# 	_zoom(Vector2(_zoomMax, _zoomMax), offset)

# func _zoom(zoom: Vector2, offset: Vector2) -> void:
# 	if zoom.x != _zoomCurrent:
# 		_zoomCurrent = zoom.x
# 		_tween.stop(_camera, "zoom")
# 		_tween.interpolate_property(_camera, "zoom", _camera.zoom, Vector2(_zoomCurrent, _zoomCurrent), _duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# 		_tween.stop(_camera, "offset")
# 		_tween.interpolate_property(_camera, "offset", _camera.offset, offset, _duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
# 		_tween.start()

func _targetTo(to: Vector2) -> void:
	var tile := _map(to * _camera.zoom + _camera.offset)
	_target.global_position = _world(tile)
	if not _rect.has_point(tile):
		_targetSnapClosest(tile)

func _targetSnapClosest(to: Vector2) -> void:
	_targetSnap(_astar.get_point_position(_astar.get_closest_point(to)))

func _targetSnap(to: Vector2) -> void:
	_tween.stop(_target, "position")
	_tween.interpolate_property(_target, "position", null, _world(to), _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	_tween.start()

# func _cameraToClosest(to: Vector2) -> void:
# 	_cameraTo(_astar.get_point_position(_astar.get_closest_point(to)))

# func _cameraTo(to: Vector2) -> void:
# 	_tween.stop(_camera, "offset")
# 	_tween.interpolate_property(_camera, "offset", null, _world(to), _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
# 	_tween.start()

# func _findPath() -> void:
# 	# from mob to target and draw it with effect
# 	pass
