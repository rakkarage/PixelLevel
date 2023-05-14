extends Node
class_name TestLevelBase

@onready var _viewport: SubViewport = $Level/SubViewport
@onready var _camera: Camera2D = $Level/SubViewport/Camera3D
@onready var _back: TileMap = $Level/SubViewport/Back
var _oldSize := Vector2.ZERO
var _tweenCamera = Tween
var _dragLeft := false
var _capture := false
const _tweenTime := 0.333
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02

func _ready() -> void:
	_camera.zoom = Vector2(0.75, 0.75)
	_oldSize = _viewport.size
	_tweenCamera = create_tween()
	_cameraTo(_center())
	_viewport.connect("size_changed", _onResize)
	Gesture.connect("onZoom", _zoomPinch)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragLeft = true
				_capture = false
			else:
				if _capture:
					_cameraUpdate()
				_dragLeft = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoomIn(event.global_position)
			_cameraUpdate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
			_cameraUpdate()
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_capture = true
			_cameraTo(_camera.global_position - event.relative * _camera.zoom)

func _tileIndex(p: Vector2) -> int:
	return Utility.indexV(p, int(_back.get_used_rect().size.x))

func _tilePosition(i: int) -> Vector2:
	return Utility.position(i, int(_back.get_used_rect().size.x))

func insideMap(p: Vector2) -> bool:
	return _back.get_used_rect().has_point(p)

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_local(tile)

func _worldSize() -> Vector2:
	# return _viewport.size * _camera.zoom
	return Vector2.ZERO

func _worldBounds() -> Rect2:
	return Rect2(Vector2.ZERO, _worldSize())

func _map(position: Vector2) -> Vector2:
	return _back.local_to_map(position)

func _mapSize() -> Vector2:
	return _back.get_used_rect().size * _back.cell_size

func mapBounds() -> Rect2:
	return Rect2(-_camera.global_position, _mapSize())

func _center() -> Vector2:
	return -(_worldSize() / 2.0) + _mapSize() / 2.0

func _cameraTo(to: Vector2) -> void:
	_tweenCamera.kill()
	_camera.global_position = to

func _cameraBy(by: Vector2) -> void:
	_cameraTo(_camera.global_position + by)

func _cameraUpdate() -> void:
	var map := mapBounds()
	var world := _worldBounds().grow(-_back.cell_size.x)
	if not world.intersects(map):
		_cameraSnap(_camera.global_position + Utility.constrainRect(world, map))

func _cameraSnap(to: Vector2) -> void:
	_tweenCamera.kill()
	_tweenCamera.interpolate_property(_camera, "global_position", null, to, _tweenTime, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

func _zoomPinch(at: Vector2, amount: float) -> void:
	if amount > 0: _zoom(at, _zoomFactorOut)
	elif amount < 0: _zoom(at, _zoomFactorIn)

func _zoomIn(at: Vector2) -> void: _zoom(at, _zoomFactorIn)

func _zoomOut(at: Vector2) -> void: _zoom(at, _zoomFactorOut)

func _zoom(at: Vector2, factor: float) -> void:
	var z0 := _camera.zoom
	var z1 := _zoomClamp(z0 * factor)
	var c0 := _camera.global_position
	var c1 := c0 + at * (z0 - z1)
	_camera.zoom = z1
	_camera.global_position = c1

func _zoomClamp(z: Vector2) -> Vector2:
	return _zoomMin if z < _zoomMin else _zoomMax if z > _zoomMax else z

func _normalize() -> Vector2:
	return (_camera.global_position - _mapSize() / 2.0) / _oldSize

func _onResize() -> void:
	# _camera.global_position = _normalize() * _viewport.size + _mapSize() / 2.0
	# _oldSize = _viewport.size
	_cameraUpdate()
