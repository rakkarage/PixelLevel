extends SubViewport
class_name LevelBase

@onready var _camera:  Camera2D = $Camera
@onready var _tileMap: TileMap  = $TileMap

signal updateMap

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)

const _zoomMin := 0.2
const _zoomMax := 4.0
const _zoomFactor := 0.1

const _duration := 0.333

var _dragLeft := false
var _capture := false
var _oldSize := Vector2.ZERO
var _tweenCamera: Tween
var _tileSet: TileSet
var _sources: Array[TileSetSource]
var _tileSize: Vector2i

func _ready() -> void:
	call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	_tileSet = _tileMap.tile_set
	_tileSize = _tileSet.tile_size
	for i in _tileSet.get_source_count():
		_sources.append(_tileSet.get_source(_tileSet.get_source_id(i)))
	_generated()
	_cameraCenter()
	connect("size_changed", _onResize)
	print(mapBounds(), _worldBounds())

func _generated() -> void:
	_oldSize = size

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
			_zoom(event.global_position, _zoomFactor)
			_cameraUpdate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(event.global_position, -_zoomFactor)
			_cameraUpdate()
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_capture = true
			_cameraTo(_camera.global_position - event.relative / _camera.zoom)
			emit_signal("updateMap")

func _onResize() -> void:
	var center: Vector2 = _center()
	var normalized := (_camera.global_position - center) / _oldSize
	_camera.global_position = normalized * Vector2(size) + center
	_oldSize = size
	_cameraUpdate()

func getCameraRect() -> Rect2:
	return Rect2(_map(_camera.global_position), _map(_camera.global_position + _worldSize()))

func _world(p: Vector2i) -> Vector2:
	return _tileMap.map_to_local(p)

func _worldSize() -> Vector2:
	return Vector2(size) * _camera.zoom

func _worldBounds() -> Rect2:
	return Rect2(_camera.global_position, _worldSize())

func _map(p: Vector2) -> Vector2i:
	return _tileMap.local_to_map(p)

func _mapPosition() -> Vector2:
	return _tileMap.get_used_rect().position

func _mapSize() -> Vector2i:
	return _tileMap.get_used_rect().size * _tileSize

func mapBounds() -> Rect2i:
	return Rect2(_mapPosition(), _mapSize())

func _center() -> Vector2i:
	var bounds := mapBounds()
	return bounds.position + Vector2i(bounds.size / 2.0)

func _cameraCenter() -> void:
	_cameraTo(_center())

func _cameraTo(to: Vector2) -> void:
	if _tweenCamera:
		_tweenCamera.kill()
	_camera.global_position = to

func _zoomPinch(at: Vector2, amount: float) -> void:
	if amount > 0: _zoom(at, _zoomFactor)
	elif amount < 0: _zoom(at, -_zoomFactor)

func _zoom(at: Vector2, factor: float) -> void:
	var zoom := _camera.zoom.x
	var zoomNew := zoom + factor
	zoomNew = clamp(zoomNew, _zoomMin, _zoomMax)
	_camera.zoom = Vector2(zoomNew, zoomNew)
	var position := -size / 2.0 + get_mouse_position()
	var positionNew := at - position / zoom - position / zoomNew
	_camera.global_position = positionNew

func _cameraUpdate() -> void:
	var map := mapBounds()
	var world := _worldBounds() #.grow(_tileSize.x)
	print(map, world)
	if not world.intersects(map):
		print("snap")
		_cameraSnap(_camera.global_position + Utility.constrainRect(world, map))
	else:
		emit_signal("updateMap")

func _cameraSnap(to: Vector2) -> void:
	if _tweenCamera:
		_tweenCamera.kill()
	_tweenCamera = create_tween()
	_tweenCamera.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	_tweenCamera.tween_property(_camera, "global_position", to, _duration)
	await _tweenCamera.finished
	emit_signal("updateMap")
