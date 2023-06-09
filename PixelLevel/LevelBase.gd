extends SubViewport
class_name LevelBase

@onready var _camera: Camera2D = $Camera
@onready var _tileMap: TileMap = $TileMap

signal updateMap

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)
const _tweenTime := 0.333
const _zoomMin := 0.2
const _zoomMax := 8.0
const _zoomFactor := 0.1
const _zoomRate := 5.0
const _momentumDecay := 0.8
const _momentumDamping := 0.333
const _minMouseSpeed := 7.0
var _zoomTarget := 1.0
var _oldSize := Vector2.ZERO
var _dragMomentum := Vector2.ZERO
var _click := false
var _drag := false
var _update := false

func _ready() -> void: call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	_onGenerated()
	_centerCamera()
	connect("size_changed", _onResize)
	Gesture.connect("onZoom", _zoom)

func _onResize() -> void:
	var center: Vector2 = _mapCenter()
	_cameraTo(center + (_camera.global_position - center) * (Vector2(size) / _oldSize))
	_oldSize = size
	_cameraSnap()

func _onGenerated() -> void:
	_oldSize = size

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_click = true
				_drag = false
			else:
				if _drag:
					_update = true
				_click = false
			_cameraSnap()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(event.global_position, _zoomFactor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(event.global_position, -_zoomFactor)
	elif event is InputEventMouseMotion:
		if _click:
			_drag = true
			var mouseDelta = event.relative / _zoomTarget
			_dragMomentum = _dragMomentum * _momentumDecay + mouseDelta
			_cameraTo(_camera.global_position - mouseDelta)
			updateMap.emit()

func _process(delta: float) -> void:
	_camera.zoom = _camera.zoom.move_toward(Vector2(_zoomTarget, _zoomTarget), delta * _zoomRate)
	if not _click and _dragMomentum.length() > _minMouseSpeed:
		_cameraTo(_camera.global_position - _dragMomentum * _momentumDamping)
	_dragMomentum = _dragMomentum * _momentumDecay
	if _dragMomentum.is_zero_approx():
		if _update:
			_update = false
			_cameraSnap()

func _zoom(at: Vector2, factor: float) -> void:
	var zoomNew := _zoomTarget * pow(_zoomRate, factor)
	_zoomTarget = clamp(zoomNew, _zoomMin, _zoomMax)
	var positionNew := at + (_camera.global_position - at) * (_zoomTarget / zoomNew)
	_cameraTo(positionNew + _camera.global_position - positionNew)
	_cameraSnap()

func _cameraTo(to: Vector2) -> void: _camera.global_position = to

func _centerCamera() -> void: _cameraTo(_mapCenter())

func _cameraSnap() -> void:
	var map := _mapBounds()
	var view := _cameraBounds().grow(-int(_tileMap.tile_set.tile_size.x / _zoomTarget))
	if not view.intersects(map):
		var to := _camera.global_position + constrainRect(view, map)
		create_tween().tween_property(_camera, "global_position", to, _tweenTime).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	updateMap.emit()

func _index(p: Vector2i, w: int) -> int: return p.x + p.y * w

func _position(i: int, w: int) -> Vector2i: return Vector2i(i % w, int(i / float(w)))

func _tileIndex(p: Vector2i) -> int: return _index(p, _tileMap.get_used_rect().size.x)

func _tilePosition(i: int) -> Vector2i: return _position(i, _tileMap.get_used_rect().size.x)

func _mapToLocal(p: Vector2i) -> Vector2i: return _tileMap.map_to_local(p)

func _localToMap(p: Vector2i) -> Vector2i: return _tileMap.local_to_map(p)

func _localToGlobal(p: Vector2i) -> Vector2: return _tileMap.to_global(p) * _zoomTarget - _cameraPosition()

func _globalToLocal(p: Vector2) -> Vector2i: return _tileMap.to_local(p / _zoomTarget + _cameraPosition())

func _mapToGlobal(p: Vector2i) -> Vector2: return _localToGlobal(_mapToLocal(p))

func _globalToMap(p: Vector2) -> Vector2i: return _localToMap(_globalToLocal(p))

func _insideMap(p: Vector2i) -> bool: return _tileMap.get_used_rect().has_point(p)

func _mapCenter() -> Vector2i: return _mapSize() / 2.0

func _mapSize() -> Vector2i: return _tileMap.get_used_rect().size * _tileMap.tile_set.tile_size

func _mapPosition() -> Vector2i: return _tileMap.get_used_rect().position * _tileMap.tile_set.tile_size

func _mapBounds() -> Rect2i: return Rect2i(_mapPosition(), _mapSize())

func _cameraSize() -> Vector2: return size / _zoomTarget

func _cameraPosition() -> Vector2: return _camera.global_position - _cameraSize() / 2.0

func _cameraBounds() -> Rect2: return Rect2(_cameraPosition(), _cameraSize())

func _cameraBoundsMap() -> Rect2i: return Rect2i(_localToMap(_cameraPosition()), _localToMap(_cameraSize()))

func constrainRect(view: Rect2i, map: Rect2i) -> Vector2:
	return constrain(view.position, view.end, map.position, map.end)

func constrain(minView: Vector2i, maxView: Vector2i, minMap: Vector2i, maxMap: Vector2i) -> Vector2i:
	var delta := Vector2i.ZERO
	if minView.x > minMap.x: delta.x += minMap.x - minView.x
	if maxView.x < maxMap.x: delta.x -= maxView.x - maxMap.x
	if minView.y > minMap.y: delta.y += minMap.y - minView.y
	if maxView.y < maxMap.y: delta.y -= maxView.y - maxMap.y
	return delta
