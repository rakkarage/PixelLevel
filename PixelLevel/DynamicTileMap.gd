## Base class for [TileMap] levels.
## Handles panning and zooming with [Camera2D], clearing and coordinate conversions.
## Depends on [SubViewport] for [method size] and [signal size_changed] and [Gesture] for optional pinch.
extends SubViewport
class_name DynamicTileMap

@onready var _camera: Camera2D = $Camera
@onready var _map: TileMap = $TileMap

signal update_map

const INVALID := -1
const INVALID_CELL := Vector2i(INVALID, INVALID)
var _old_size := Vector2.ZERO
@export var _duration := 0.333 ## Duration of the camera tween.
@export_group("Zoom")
@export var _zoom_min := 0.2 ## Minimum zoom level.
@export var _zoom_max := 16.0 ## Maximum zoom level.
@export var _zoom_factor := 0.1 ## Zoom factor per mouse wheel tick. Positive = zoom in, negative = zoom out.
@export var _zoom_factor_base := 10.0 ## Base for zoom factor exponential scaling. 1.0 = linear scaling.
@export_group("Pan")
@export var _pan_momentum_max := Vector2(100.0, 100.0) ## Maximum pan momentum.
@export var _pan_momentum_threshold := 7.0 ## Pan momentum threshold. Below this value, momentum is reset.
@export var _pan_momentum_decay := 0.07 ## Pan momentum decay. 0.0 = no decay, 1.0 = instant decay.
@export var _pan_momentum_smoothing := 0.9 ## Pan momentum smoothing. 0.0 = no smoothing, 1.0 = no momentum.
@export var _pan_momentum_reset := 0.1 ## Reset momentum after this many seconds of no movement.
var _panning := false
var _pan_momentum := Vector2.ZERO
var _pan_momentum_timer := Timer.new()
var _pan_momentum_after := false

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_old_size = size
	center_camera()
	connect("size_changed", _on_resize)
	add_child(_pan_momentum_timer)
	_pan_momentum_timer.one_shot = true
	_pan_momentum_timer.connect("timeout", func(): _pan_momentum = Vector2.ZERO)
	Gesture.connect("on_zoom", _zoom)

## Called when the node's size changes. Adjusts the [member _camera] position based on the new size.
func _on_resize() -> void:
	var center: Vector2 = map_center()
	move_camera_to(center + (_camera.global_position - center) * (Vector2(size) / _old_size))
	_old_size = size
	constrain_map_to_camera()

## Called for unhandled input events. Emits an [member update_map] signal when the [member _camera] is panned or zoomed.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom(event.global_position, _zoom_factor)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom(event.global_position, -_zoom_factor)
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
			if not _panning:
				_pan_momentum_timer.stop()
	elif event is InputEventMouseMotion and _panning:
		_pan(event.relative)
		_pan_momentum_timer.start(_pan_momentum_reset)

## Called every frame. Handles panning momentum.
func _process(_delta: float) -> void:
	if _panning:
		_pan_momentum_after = true
	else:
		if _pan_momentum.length() > _pan_momentum_threshold:
			_camera.global_position -= _pan_momentum / _camera.zoom
		elif _pan_momentum_after:
			constrain_map_to_camera()
			_pan_momentum_after = false
	_pan_momentum = _pan_momentum.lerp(Vector2.ZERO, _pan_momentum_decay)

## Pan the [member _camera] by a given [param delta] and update momentum.
func _pan(delta: Vector2) -> void:
	var new_pan_momentum := _pan_momentum * _pan_momentum_smoothing + delta * (1.0 - _pan_momentum_smoothing)
	_pan_momentum = new_pan_momentum.clamp(-_pan_momentum_max, _pan_momentum_max)
	_camera.global_position -= delta / _camera.zoom

## Zoom the [member _camera] at a given [param position] by a specified [param factor].
func _zoom(position: Vector2, factor: float) -> void:
	var zoom_old := _camera.zoom
	var zoom_new := (zoom_old * pow(_zoom_factor_base, factor)).clamp(Vector2(_zoom_min, _zoom_min), Vector2(_zoom_max, _zoom_max))
	_camera.zoom = zoom_new
	var center := _camera.get_viewport().get_visible_rect().size / 2.0
	_camera.global_position += ((position - center) / zoom_old + (center - position) / zoom_new)
	constrain_map_to_camera()

## Move the [member _camera] to the given [param position].
func move_camera_to(position: Vector2) -> void: _camera.global_position = position
## Return the center coordinate of the [member _map].
func map_center() -> Vector2i: return map_size() / 2.0
## Center the [member _camera] on the [member _map].
func center_camera() -> void: move_camera_to(map_center())

## Spring tween the [member _camera] to the given [param position] and emit an [member update_map] signal when finished.
func tween_camera_to(position: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(_camera, "global_position", position, _duration).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): update_map.emit())

## Constrain the given [param map] to fit within the given [param view]. See [method _constrain].
func _constrain_rect(view: Rect2i, map: Rect2i) -> Vector2:
	return _constrain(view.position, view.end, map.position, map.end)
## Constrain the given [param map] to fit within the given [param view]. See [method _constrain_rect].
func _constrain(minView: Vector2i, maxView: Vector2i, minMap: Vector2i, maxMap: Vector2i) -> Vector2i:
	var delta := Vector2i.ZERO
	if minView.x > minMap.x: delta.x += minMap.x - minView.x
	if maxView.x < maxMap.x: delta.x -= maxView.x - maxMap.x
	if minView.y > minMap.y: delta.y += minMap.y - minView.y
	if maxView.y < maxMap.y: delta.y -= maxView.y - maxMap.y
	return delta

## Ensure the [member _map] is within the [member _camera] bounds with tween if necessary. See [method tween_camera_to], [method _constrain_rect].
func constrain_map_to_camera() -> void:
	var map := map_bounds()
	var view := camera_bounds().grow(-int(_map.tile_set.tile_size.x / _camera.zoom.x))
	if not view.intersects(map):
		tween_camera_to(_camera.global_position + _constrain_rect(view, map))
	else:
		update_map.emit()

## Ensure the given [param position] is within the [member _camera] bounds with tween if necessary. See [method tween_camera_to]
func constrain_tile_to_camera(position: Vector2i) -> void:
	var test := Rect2(position, Vector2i.ONE)
	var view := camera_bounds_map().grow(-1)
	if not view.intersects(test):
		tween_camera_to(map_to_local(test.position))
	else:
		update_map.emit()

## Clear all tiles from the [member _map] and emit an [member update_map] signal.
func clear() -> void:
	_map.clear()
	update_map.emit()

## Return the bounding rectangle of the used tiles in the [member _map].
func tile_rect() -> Rect2i: return _map.get_used_rect()
## Return true if the given [param position] is inside the [member _map].
func is_inside_map(position: Vector2i) -> bool: return tile_rect().has_point(position)

## Return the index of the tile with the given [param position] using the width of the [member _map]. See [method tile_position], [method Utility.flatten].
func tile_index(position: Vector2i) -> int: return Utility.flatten(position, tile_rect().size.x)
## Return the position of the tile with the given [param index] using the width of the [member _map]. See [method tile_index], [method Utility.unflatten].
func tile_position(index: int) -> Vector2i: return Utility.unflatten(index, tile_rect().size.x)

## Convert a map [param position] to a local position. See [method local_to_map].
func map_to_local(position: Vector2i) -> Vector2i: return _map.map_to_local(position)
## Convert a local [param position] to a map position. See [method map_to_local].
func local_to_map(position: Vector2i) -> Vector2i: return _map.local_to_map(position)
## Convert a local [param position] to a global position. See [method global_to_local].
func local_to_global(position: Vector2i) -> Vector2i: return _map.to_global(position) * _camera.zoom - camera_position()
## Convert a global [param position] to a local position. See [method local_to_global].
func global_to_local(position: Vector2i) -> Vector2i: return _map.to_local(Vector2(position) / _camera.zoom + camera_position())
## Convert a map [param position] to a global position. See [method global_to_map].
func map_to_global(position: Vector2i) -> Vector2i: return local_to_global(map_to_local(position))
## Convert a global [param position] to a map position. See [method map_to_global].
func global_to_map(position: Vector2i) -> Vector2i: return local_to_map(global_to_local(position))

## Return the size of the [member _map] in pixels.
func map_size() -> Vector2i: return tile_rect().size * _map.tile_set.tile_size
## Return the position of the [member _map] in pixels.
func map_position() -> Vector2i: return tile_rect().position * _map.tile_set.tile_size
## Return the bounding rectangle of the [member _map] in pixels.
func map_bounds() -> Rect2i: return Rect2i(map_position(), map_size())

## Return the size of the [member _camera] in pixels.
func camera_size() -> Vector2: return Vector2(size) / _camera.zoom
## Return the position of the [member _camera] in pixels.
func camera_position() -> Vector2: return _camera.global_position - camera_size() / 2.0
## Return the bounding rectangle of the [member _camera] in pixels. See [method camera_bounds_map].
func camera_bounds() -> Rect2: return Rect2(camera_position(), camera_size())

## Return the bounding rectangle of the [member _camera] in map coordinates. See [method camera_bounds].
func camera_bounds_map() -> Rect2i: return Rect2i(local_to_map(camera_position()), local_to_map(camera_size()))
