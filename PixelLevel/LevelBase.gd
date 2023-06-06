extends SubViewport
class_name LevelBase

@onready var _camera:  Camera2D = $Camera
@onready var _tileMap: TileMap  = $TileMap

signal updateMap

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)

const _tweenTime := 0.333
const _zoomMin := 0.2
const _zoomMax := 4.0
const _zoomFactor := 0.1
const _zoomRate := 5.0
var _zoomTarget := Vector2.ONE
var _dragLeft := false
var _capture := false
var _oldSize := Vector2.ZERO
var _tweenCamera: Tween
var _tileSet: TileSet
var _sources: Array[TileSetSource]
var _tileSize: Vector2i
var _dragMomentum: Vector2 = Vector2.ZERO
const _momentumDecay: float = 0.9
const _momentumDamping: float = 0.2
const _minMouseSpeed: float = 0.1

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

func _generated() -> void:
	_oldSize = size

func _process(delta: float) -> void:
	_camera.zoom = lerp(_camera.zoom, _zoomTarget, delta * _zoomRate)
	if not _dragLeft and _dragMomentum.length() > _minMouseSpeed:
		_cameraTo(_camera.global_position - _dragMomentum * _momentumDamping)
	_dragMomentum = _dragMomentum * _momentumDecay
	if not _dragLeft and _dragMomentum.is_zero_approx() or _cameraUpdate():
		_dragMomentum = Vector2.ZERO
		emit_signal("updateMap")

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
			var mouseDelta = event.relative / _zoomTarget
			_dragMomentum = _dragMomentum * _momentumDecay + mouseDelta
			_cameraTo(_camera.global_position - mouseDelta)
			emit_signal("updateMap")

func _onResize() -> void:
	_camera.global_position = Vector2(_center()) + (_camera.global_position - Vector2(_center())) * (Vector2(size) / _oldSize)
	_oldSize = size
	_cameraUpdate()

func _world(p: Vector2i) -> Vector2:
	return _tileMap.map_to_local(p)

func _worldSize() -> Vector2i:
	return Vector2(size) / _zoomTarget

func _worldBounds() -> Rect2i:
	return Rect2i(_camera.global_position - _worldSize() / 2.0, _worldSize())

func _map(p: Vector2i) -> Vector2i:
	return _tileMap.local_to_map(p)

func _mapPosition() -> Vector2i:
	return _tileMap.get_used_rect().position

func _mapSize() -> Vector2i:
	return _tileMap.get_used_rect().size * _tileSize

func _mapBounds() -> Rect2i:
	return Rect2i(_mapPosition(), _mapSize())

func _center() -> Vector2i:
	var bounds: Rect2 = _mapBounds()
	var borderSize := Vector2(max(-bounds.position.x, 0), max(-bounds.position.y, 0))
	var center := bounds.position + (bounds.size + 2.0 * borderSize) / 2.0 / _zoomTarget
	center -= borderSize * (_tileSize.x / _zoomTarget.x)
	return center

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
	var zoom := _zoomTarget.x
	var zoomNew := zoom * pow(_zoomRate, factor)
	zoomNew = clamp(zoomNew, _zoomMin, _zoomMax)
	_zoomTarget = Vector2(zoomNew, zoomNew)
	var position := _camera.global_position
	var positionNew := at + (position - at) * (zoom / zoomNew)
	var diff := position - positionNew
	_camera.global_position = positionNew + diff

func _cameraUpdate() -> bool:
	var map := _mapBounds()
	var world := _worldBounds().grow(-int(_tileSize.x / _zoomTarget.x))
	if not world.intersects(map):
		_cameraSnap(_camera.global_position + Utility.constrainRect(world, map))
		return true
	else:
		emit_signal("updateMap")
		return false

func _cameraSnap(to: Vector2) -> void:
	if _tweenCamera:
		_tweenCamera.kill()
	_tweenCamera = create_tween()
	_tweenCamera.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	_tweenCamera.tween_property(_camera, "global_position", to, _tweenTime)
	await _tweenCamera.finished
	emit_signal("updateMap")
