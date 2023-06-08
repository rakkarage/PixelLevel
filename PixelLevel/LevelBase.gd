extends SubViewport
class_name LevelBase

@onready var _camera: Camera2D = $Camera
@onready var _tileMap: TileMap = $TileMap

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)

const _tweenTime := 0.333
const _zoomMin := 0.2
const _zoomMax := 8.0
const _zoomFactor := 0.1
const _zoomRate := 5.0
var _zoomTarget := 1.0
var _click := false
var _drag := false
var _oldSize := Vector2.ZERO
var _dragMomentum: Vector2 = Vector2.ZERO
const _momentumDecay: float = 0.8
const _momentumDamping: float = 0.333
const _minMouseSpeed: float = 0.1

func _ready() -> void:
	call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	_onGenerated()
	_cameraCenter()
	connect("size_changed", _onResize)
	Gesture.connect("onZoom", _zoom)

func _onResize() -> void:
	_cameraTo(Vector2(_center()) + (_camera.global_position - Vector2(_center())) * (Vector2(size) / _oldSize))
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
					_cameraSnap()
				_click = false
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

func _process(delta: float) -> void:
	_camera.zoom = _camera.zoom.move_toward(Vector2(_zoomTarget, _zoomTarget), delta * _zoomRate)
	if not _click and _dragMomentum.length() > _minMouseSpeed:
		_cameraTo(_camera.global_position - _dragMomentum * _momentumDamping)
	_dragMomentum = _dragMomentum * _momentumDecay
	if _dragMomentum.is_zero_approx():
		_dragMomentum = Vector2.ZERO
		if not _click:
			_cameraSnap()

func _zoom(at: Vector2, factor: float) -> void:
	var zoomNew := _zoomTarget * pow(_zoomRate, factor)
	_zoomTarget = clamp(zoomNew, _zoomMin, _zoomMax)
	var positionNew := at + (_camera.global_position - at) * (_zoomTarget / zoomNew)
	_cameraTo(positionNew + _camera.global_position - positionNew)
	_cameraSnap()

func _index(p: Vector2i, w: int) -> int:
	return p.x + p.y * w

func _position(i: int, w: int) -> Vector2i:
	return Vector2i(i % w, int(i / float(w)))

func _tileIndex(p: Vector2i) -> int:
	return _index(p, _tileMap.get_used_rect().size.x)

func _tilePosition(i: int) -> Vector2i:
	return _position(i, _tileMap.get_used_rect().size.x)

func _mapToLocal(p: Vector2i) -> Vector2i:
	return _tileMap.map_to_local(p)

func _localToMap(p: Vector2i) -> Vector2i:
	return _tileMap.local_to_map(p)

func _insideMap(p: Vector2i) -> bool:
	return _tileMap.get_used_rect().has_point(p)

func _center() -> Vector2i:
	return _tileMap.get_used_rect().size * _tileMap.tile_set.tile_size / 2.0

func _cameraTo(to: Vector2i) -> void:
	_camera.global_position = to

func _cameraCenter() -> void:
	_cameraTo(_center())

func constrainRect(view: Rect2i, map: Rect2i) -> Vector2:
	return constrain(view.position, view.end, map.position, map.end)

func constrain(minView: Vector2i, maxView: Vector2i, minMap: Vector2i, maxMap: Vector2i) -> Vector2:
	var delta := Vector2i.ZERO
	if minView.x > minMap.x: delta.x += minMap.x - minView.x
	if maxView.x < maxMap.x: delta.x -= maxView.x - maxMap.x
	if minView.y > minMap.y: delta.y += minMap.y - minView.y
	if maxView.y < maxMap.y: delta.y -= maxView.y - maxMap.y
	return delta

func _cameraBounds() -> Rect2i:
	return Rect2i(_camera.global_position - size / 2.0, _camera.get_viewport_rect().size / _zoomTarget)

func _cameraSnap() -> void:
	var map := _tileMap.get_used_rect()
	var view := _cameraBounds().grow(-int(_tileMap.tile_set.tile_size.x / _zoomTarget))
	if not view.intersects(map):
		var to := _camera.global_position + constrainRect(view, map)
		create_tween().tween_property(_camera, "global_position", to, _tweenTime).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
