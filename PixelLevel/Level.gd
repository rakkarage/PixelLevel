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
const _duration := 0.22
const _zoomMin := Vector2(0.01, 0.01)
const _zoomMax := Vector2(1.0, 1.0)
const _factorIn := 0.98
const _factorOut := 1.02

func _ready() -> void:
	_rect = _back.get_used_rect()
	_targetToMob()
	_cameraCenter()
	_addPoints();

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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_targetTo(event.global_position)
				_dragLeft = true
			else:
				_targetUpdate()
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_zoom(_factorIn, event.global_position)
			# var new = _camera.zoom * _zoomIn
			# if new >= _zoomMin:
			# 	_camera.zoom = new
			# 	print("up: %s" % new.x)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoom(_factorOut, event.global_position)
			# var new = _camera.zoom * _zoomOut
			# if new <= _zoomMax:
			# 	_camera.zoom = new
			# 	print("down: %s" % new.x)
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_camera.global_position -= event.relative * _camera.zoom

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _targetToMob() -> void:
	_targetTo(_mob.global_position)

func _targetTo(to: Vector2) -> void:
	_target.global_position = _world(_map(to * _camera.zoom + _camera.global_position))

func _targetUpdate() -> void:
	_targetSnapClosest(_map(_target.global_position))

func _targetSnapClosest(tile: Vector2) -> void:
	_targetSnap(_astar.get_point_position(_astar.get_closest_point(tile)))

func _targetSnap(tile: Vector2) -> void:
	_snap(_target, tile)

func _cameraCenter() -> void:
	_cameraTo(-(size / 2.0) + _rect.size * _back.cell_size / 2.0)

func _cameraTo(to: Vector2) -> void:
	_camera.global_position = _world(_map(to))

func _cameraUpdate() -> void:
	_cameraSnap(_map(_camera.global_position))

func _cameraSnapClosest(tile: Vector2) -> void:
	_targetSnap(_astar.get_point_position(_astar.get_closest_point(tile)))

func _cameraSnap(tile: Vector2) -> void:
	_snap(_camera, tile)

func _snap(node: Node2D, tile: Vector2) -> void:
	var p = _world(tile)
	if node.global_position != p:
		_tween.stop(node, "global_position")
		_tween.interpolate_property(node, "global_position", null, p, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		_tween.start()

func _zoom(factor: float, at: Vector2) -> void:
	var z0 = _camera.zoom
	var z1 = z0 * factor
	var c0 = _camera.position
	var c1 = c0 + at * (z0 - z1)
	_camera.zoom = z1
	_camera.global_position = c1

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
# factor = multiply: use it with itself for better expo scaling!? idk * not + u dolt
