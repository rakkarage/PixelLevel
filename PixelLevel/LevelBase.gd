## Base class for [TileMap] levels.
##
## Handles panning and zooming with [Camera2D], clearing and coordinate conversions.
extends SubViewport
class_name LevelBase

@onready var _camera: Camera2D = $Camera
@onready var _tileMap: TileMap = $TileMap

signal updateMap ## Signal emitted when the map is updated due to panning, zooming, or clearing.

const INVALID := -1 ## An invalid int.
const INVALID_CELL := Vector2i(INVALID, INVALID) ## An invalid Vector2i.
const _tweenTime := 0.333
var _oldSize := Vector2.ZERO ## Stores the old size of the node. Used for resizing.
var _pressed := false

const _zoomMin := 0.2
const _zoomMax := 16.0
const _zoomFactor := 0.1
const _zoomRate := 5.0
var _zoomTarget := 1.0

const _panMomentumDecay := 0.8
const _panMomentumDamping := 0.333
const _panMomentumThreshold := 7.0
var _panning := false
var _panFinished := false
var _panMomentum := Vector2.ZERO

## Called when the node enters the scene tree for the first time.
func _ready() -> void: call_deferred("_readyDeferred")

## Called after the node has entered the scene tree.
func _readyDeferred() -> void:
	_oldSize = size
	centerCamera()
	connect("size_changed", _onResize)
	Gesture.connect("onZoom", _zoom)

## Called when the node's size changes. Adjusts the [member _camera] position based on the new size.
func _onResize() -> void:
	var center: Vector2 = mapCenter()
	moveCameraTo(center + (_camera.global_position - center) * (Vector2(size) / _oldSize))
	_oldSize = size
	constrainMapToCamera() # Sometimes resize near edge can cause the map to go out of bounds.

## Called for unhandled input events. Emits an [member updateMap] signal when the [member _camera] is panned or zoomed.
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
			constrainMapToCamera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(event.global_position, _zoomFactor)
			updateMap.emit()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(event.global_position, -_zoomFactor)
			updateMap.emit()
	elif event is InputEventMouseMotion:
		if _pressed:
			_panning = true
			var mouseDelta = event.relative / _zoomTarget
			_panMomentum = _panMomentum * _panMomentumDecay + mouseDelta
			moveCameraTo(_camera.global_position - mouseDelta)
			updateMap.emit()

## Called every frame. Handles zooming to target and panning momentum.
func _process(delta: float) -> void:
	_camera.zoom = _camera.zoom.move_toward(Vector2(_zoomTarget, _zoomTarget), delta * _zoomRate)
	if not _pressed and _panMomentum.length() > _panMomentumThreshold:
		moveCameraTo(_camera.global_position - _panMomentum * _panMomentumDamping)
	_panMomentum = _panMomentum * _panMomentumDecay
	if _panMomentum.is_zero_approx() and _panFinished:
		_panFinished = false
		constrainMapToCamera()

## Zoom the [member _camera] at a given [param position] by a specified [param factor].
func _zoom(position: Vector2, factor: float) -> void:
	var dynamicZoomFactor := _zoomTarget * factor # Adjust factor based on current zoom level
	var zoomNew := _zoomTarget * pow(_zoomRate, dynamicZoomFactor)
	_zoomTarget = clamp(zoomNew, _zoomMin, _zoomMax)
	var positionNew := position + (_camera.global_position - position) * (_zoomTarget / zoomNew)
	moveCameraTo(positionNew + _camera.global_position - positionNew)
	constrainMapToCamera()

## Move the [member _camera] to the given [param position].
func moveCameraTo(position: Vector2) -> void: _camera.global_position = position
## Return the center coordinate of the [member _tileMap].
func mapCenter() -> Vector2i: return mapSize() / 2.0
## Center the [member _camera] on the [member _tileMap].
func centerCamera() -> void: moveCameraTo(mapCenter())

## Spring tween the [member _camera] to the given [param position] and emit an [member updateMap] signal when finished.
func tweenCameraTo(position: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", position, _tweenTime).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): updateMap.emit())

## Constrain the given [param map] to fit within the given [param view]. See [method _constrain].
func _constrainRect(view: Rect2i, map: Rect2i) -> Vector2:
	return _constrain(view.position, view.end, map.position, map.end)
## Constrain the given [param map] to fit within the given [param view]. See [method _constrainRect].
func _constrain(minView: Vector2i, maxView: Vector2i, minMap: Vector2i, maxMap: Vector2i) -> Vector2i:
	var delta := Vector2i.ZERO
	if minView.x > minMap.x: delta.x += minMap.x - minView.x
	if maxView.x < maxMap.x: delta.x -= maxView.x - maxMap.x
	if minView.y > minMap.y: delta.y += minMap.y - minView.y
	if maxView.y < maxMap.y: delta.y -= maxView.y - maxMap.y
	return delta

## Ensure the [member _tileMap] is within the [member _camera] bounds with tween if necessary. See [method tweenCameraTo], [method _constrainRect], .
func constrainMapToCamera() -> void:
	var map := mapBounds()
	var view := cameraBounds().grow(-int(_tileMap.tile_set.tile_size.x / _zoomTarget))
	if not view.intersects(map):
		tweenCameraTo(_camera.global_position + _constrainRect(view, map))

## Ensure the given [param position] is within the [member _camera] bounds with tween if necessary. See [method tweenCameraTo]
func constrainTileToCamera(position: Vector2i) -> void:
	var test := Rect2(position, Vector2i.ONE)
	var view := cameraBoundsMap().grow(-1)
	if not view.intersects(test):
		tweenCameraTo(mapToLocal(test.position))

## Clear all tiles from the [member _tileMap] and emit an [member updateMap] signal.
func clear() -> void:
	_tileMap.clear()
	updateMap.emit()

## Return the bounding rectangle of the used tiles in the [member _tileMap].
func tileRect() -> Rect2i: return _tileMap.get_used_rect()
## Return true if the given [param position] is inside the [member _tileMap].
func insideMap(position: Vector2i) -> bool: return tileRect().has_point(position)

## Return the index of the tile with the given [param position] using the width of the [member _tileMap]. See [method tilePosition], [method Utility.flatten].
func tileIndex(position: Vector2i) -> int: return Utility.flatten(position, tileRect().size.x)
## Return the position of the tile with the given [param index] using the width of the [member _tileMap]. See [method tileIndex], [method Utility.unflatten].
func tilePosition(index: int) -> Vector2i: return Utility.unflatten(index, tileRect().size.x)

## Convert a map [param position] to a local position. See [method localToMap].
func mapToLocal(position: Vector2i) -> Vector2i: return _tileMap.map_to_local(position)
## Convert a local [param position] to a map position. See [method mapToLocal].
func localToMap(position: Vector2i) -> Vector2i: return _tileMap.local_to_map(position)
## Convert a local [param position] to a global position. See [method globalToLocal].
func localToGlobal(position: Vector2i) -> Vector2i: return _tileMap.to_global(position) * _zoomTarget - cameraPosition()
## Convert a global [param position] to a local position. See [method localToGlobal].
func globalToLocal(position: Vector2i) -> Vector2i: return _tileMap.to_local(position / _zoomTarget + cameraPosition())
## Convert a map [param position] to a global position. See [method globalToMap].
func mapToGlobal(position: Vector2i) -> Vector2i: return localToGlobal(mapToLocal(position))
## Convert a global [param position] to a map position. See [method mapToGlobal].
func globalToMap(position: Vector2i) -> Vector2i: return localToMap(globalToLocal(position))

## Return the size of the [member _tileMap] in pixels.
func mapSize() -> Vector2i: return tileRect().size * _tileMap.tile_set.tile_size
## Return the position of the [member _tileMap] in pixels.
func mapPosition() -> Vector2i: return tileRect().position * _tileMap.tile_set.tile_size
## Return the bounding rectangle of the [member _tileMap] in pixels.
func mapBounds() -> Rect2i: return Rect2i(mapPosition(), mapSize())

## Return the size of the [member _camera] in pixels.
func cameraSize() -> Vector2: return size / _zoomTarget
## Return the position of the [member _camera] in pixels.
func cameraPosition() -> Vector2: return _camera.global_position - cameraSize() / 2.0
## Return the bounding rectangle of the [member _camera] in pixels. See [method cameraBoundsMap].
func cameraBounds() -> Rect2: return Rect2(cameraPosition(), cameraSize())

# Return the bounding rectangle of the [member _camera] in map coordinates. See [method cameraBounds].
func cameraBoundsMap() -> Rect2i: return Rect2i(localToMap(cameraPosition()), localToMap(cameraSize()))
