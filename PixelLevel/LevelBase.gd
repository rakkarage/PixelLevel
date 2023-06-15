extends SubViewport
class_name LevelBase

@onready var _camera: Camera2D = $Camera
@onready var _tileMap: TileMap = $TileMap

signal updateMap

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)
const _tweenTime := 0.333
var _oldSize := Vector2.ZERO
var _pressed := false

const _zoomMin := 0.2
const _zoomMax := 8.0
const _zoomFactor := 0.1
const _zoomRate := 5.0
var _zoomTarget := 1.0

const _panMomentumDecay := 0.8
const _panMomentumDamping := 0.333
const _panMomentumThreshold := 7.0
var _panning := false
var _panFinished := false
var _panMomentum := Vector2.ZERO

func _ready() -> void: call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	_oldSize = size
	centerCamera()
	connect("size_changed", _onResize)
	Gesture.connect("onZoom", _zoom)

func _onResize() -> void:
	var center: Vector2 = mapCenter()
	cameraTo(center + (_camera.global_position - center) * (Vector2(size) / _oldSize))
	_oldSize = size
	cameraUpdate()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed = true
				_panning = false
			else:
				if _panning:
					_panFinished = true
				_pressed = false
			cameraUpdate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(event.global_position, _zoomFactor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(event.global_position, -_zoomFactor)
	elif event is InputEventMouseMotion:
		if _pressed:
			_panning = true
			var mouseDelta = event.relative / _zoomTarget
			_panMomentum = _panMomentum * _panMomentumDecay + mouseDelta
			cameraTo(_camera.global_position - mouseDelta)
			updateMap.emit()

func _process(delta: float) -> void:
	_camera.zoom = _camera.zoom.move_toward(Vector2(_zoomTarget, _zoomTarget), delta * _zoomRate)
	if not _pressed and _panMomentum.length() > _panMomentumThreshold:
		cameraTo(_camera.global_position - _panMomentum * _panMomentumDamping)
	_panMomentum = _panMomentum * _panMomentumDecay
	if _panMomentum.is_zero_approx() and _panFinished:
		_panFinished = false
		cameraUpdate()

func _zoom(at: Vector2, factor: float) -> void:
	var zoomNew := _zoomTarget * pow(_zoomRate, factor)
	_zoomTarget = clamp(zoomNew, _zoomMin, _zoomMax)
	var positionNew := at + (_camera.global_position - at) * (_zoomTarget / zoomNew)
	cameraTo(positionNew + _camera.global_position - positionNew)
	cameraUpdate()

func cameraTo(to: Vector2) -> void: _camera.global_position = to

func centerCamera() -> void: cameraTo(mapCenter())

func cameraUpdate() -> void:
	var map := mapBounds()
	var view := cameraBounds().grow(-int(_tileMap.tile_set.tile_size.x / _zoomTarget))
	if not view.intersects(map):
		cameraSnap(_camera.global_position + _constrainRect(view, map))

func cameraSnap(to: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", to, _tweenTime).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): updateMap.emit())

func checkTileInCamera(p: Vector2i) -> void:
	var test := Rect2(p, Vector2i.ONE)
	var view := cameraBoundsMap().grow(-1)
	if not view.intersects(test):
		cameraSnap(mapToLocal(test.position))

func clear() -> void: _tileMap.clear()

func index(p: Vector2i, w: int) -> int: return p.x + p.y * w

func position(i: int, w: int) -> Vector2i: return Vector2i(i % w, int(i / float(w)))

func tileIndex(p: Vector2i) -> int: return index(p, tileRect().size.x)

func tilePosition(i: int) -> Vector2i: return position(i, tileRect().size.x)

func mapToLocal(p: Vector2i) -> Vector2i: return _tileMap.map_to_local(p)

func localToMap(p: Vector2i) -> Vector2i: return _tileMap.local_to_map(p)

func localToGlobal(p: Vector2i) -> Vector2: return _tileMap.to_global(p) * _zoomTarget - cameraPosition()

func globalToLocal(p: Vector2) -> Vector2i: return _tileMap.to_local(p / _zoomTarget + cameraPosition())

func mapToGlobal(p: Vector2i) -> Vector2: return localToGlobal(mapToLocal(p))

func globalToMap(p: Vector2) -> Vector2i: return localToMap(globalToLocal(p))

func tileRect() -> Rect2i: return _tileMap.get_used_rect()

func insideMap(p: Vector2i) -> bool: return tileRect().has_point(p)

func mapCenter() -> Vector2i: return mapSize() / 2.0

func mapSize() -> Vector2i: return tileRect().size * _tileMap.tile_set.tile_size

func mapPosition() -> Vector2i: return tileRect().position * _tileMap.tile_set.tile_size

func mapBounds() -> Rect2i: return Rect2i(mapPosition(), mapSize())

func cameraSize() -> Vector2: return size / _zoomTarget

func cameraPosition() -> Vector2: return _camera.global_position - cameraSize() / 2.0

func cameraBounds() -> Rect2: return Rect2(cameraPosition(), cameraSize())

func cameraBoundsMap() -> Rect2i: return Rect2i(localToMap(cameraPosition()), localToMap(cameraSize()))

func _constrainRect(view: Rect2i, map: Rect2i) -> Vector2:
	return _constrain(view.position, view.end, map.position, map.end)

func _constrain(minView: Vector2i, maxView: Vector2i, minMap: Vector2i, maxMap: Vector2i) -> Vector2i:
	var delta := Vector2i.ZERO
	if minView.x > minMap.x: delta.x += minMap.x - minView.x
	if maxView.x < maxMap.x: delta.x -= maxView.x - maxMap.x
	if minView.y > minMap.y: delta.y += minMap.y - minView.y
	if maxView.y < maxMap.y: delta.y -= maxView.y - maxMap.y
	return delta
