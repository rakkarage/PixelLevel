extends Viewport

onready var _tween:       Tween = $Tween
onready var _camera:   Camera2D = $Camera
onready var _back:      TileMap = $Camera/Back
onready var _waterBack: TileMap = $Camera/WaterBack
onready var _mob:        Node2D = $Camera/Mob
onready var _waterFore: TileMap = $Camera/WaterBack
onready var _fore:      TileMap = $Camera/Fore
onready var _target:     Node2D = $Camera/Target
onready var _astar := AStar2D.new()
var _rect := Rect2()
var _path := PoolVector2Array()
var _dragLeft := false
var _size := Vector2.ZERO
const _duration := 0.22
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMinMin := Vector2(0.06, 0.06)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomMaxMax := Vector2(1.16, 1.16)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02

func _ready() -> void:
	_rect = _back.get_used_rect()
	_size = size;
	_targetToMob()
	_addPoints()
	_camera.zoom = Vector2(0.75, 0.75)
	_cameraCenter()
	Utility.ok(connect("size_changed", self, "_onResize"))
	Utility.ok(Gesture.connect("onZoom", self, "_zoomPinch"))

func _tileIndex(p: Vector2) -> int:
	return int(p.x + (p.y * _rect.size.x))

func _tilePosition(i: int) -> Vector2:
	var y := i / _rect.size.x
	var x := i - _rect.size.x * y
	return Vector2(x, y)

func _addPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			var p := Vector2(x, y)
			_astar.add_point(_tileIndex(p), p)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_targetTo(event.position)
				_dragLeft = true
			else:
				_targetUpdate()
				_zoomSnap()
				_cameraSnap()
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_zoomIn(event.position)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoomOut(event.position)
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_cameraTo(_camera.offset - event.relative * _camera.zoom)

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _worldSize() -> Vector2:
	return _size * _camera.zoom

func _worldBounds() -> Rect2:
	return Rect2(Vector2.ZERO, _worldSize())

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _mapSize() -> Vector2:
	return _rect.size * _back.cell_size

func _mapBounds() -> Rect2:
	return Rect2(-_camera.offset, _mapSize())

func _center() -> Vector2:
	return -(_worldSize() / 2.0) + _mapSize() / 2.0

func _cameraCenter() -> void:
	_cameraTo(_center())

func _cameraTo(to: Vector2) -> void:
	_cameraStop()
	_camera.offset = to

func _cameraBy(by: Vector2) -> void:
	_cameraTo(_camera.offset + by)

static func _constrainRect(world: Rect2, map: Rect2) -> Vector2:
	return _constrain(world.position, world.end, map.position, map.end)

static func _constrain(minWorld: Vector2, maxWorld: Vector2, minMap: Vector2, maxMap: Vector2) -> Vector2:
	var delta := Vector2.ZERO
	if minWorld.x > minMap.x: delta.x += minMap.x - minWorld.x
	if maxWorld.x < maxMap.x: delta.x -= maxWorld.x - maxMap.x
	if minWorld.y > minMap.y: delta.y += minMap.y - minWorld.y
	if maxWorld.y < maxMap.y: delta.y -= maxWorld.y - maxMap.y
	return delta

func _cameraSnap() -> void:
	var map := _mapBounds()
	var world := _worldBounds().grow(-_back.cell_size.x)
	if not world.intersects(map):
		var to = _camera.offset + _constrainRect(world, map)
		Utility.stfu(_tween.stop(_camera, "offset"))
		Utility.stfu(_tween.interpolate_property(_camera, "offset", null, to, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.start())

func _cameraStop() -> void:
	Utility.stfu(_tween.stop(_camera, "offset"))

func _zoomPinch(at: Vector2, amount: float) -> void:
	if amount > 0: _zoom(at, _zoomFactorOut)
	elif amount < 0: _zoom(at, _zoomFactorIn)

func _zoomIn(at: Vector2) -> void: _zoom(at, _zoomFactorIn)

func _zoomOut(at: Vector2) -> void: _zoom(at, _zoomFactorOut)

func _zoom(at: Vector2, factor: float) -> void:
	var z0 := _camera.zoom
	var z1 := _zoomClampp(z0 * factor)
	var c0 := _camera.offset
	var c1 := c0 + at * (z0 - z1)
	_camera.zoom = z1
	_camera.offset = c1

func _zoomClamp(z: Vector2) -> Vector2:
	return _zoomMin if z < _zoomMin else _zoomMax if z > _zoomMax else z

func _zoomClampp(z: Vector2) -> Vector2:
	return _zoomMinMin if z < _zoomMinMin else _zoomMaxMax if z > _zoomMaxMax else z

# TODO: this moves it need to zoom without move?!!! copy _zoom
# cant do this at same time as cameraSnap with also changes offset over time
# combine!?
func _zoomSnap() -> void:
	var z0 := _camera.zoom
	var z1 := _zoomClamp(z0)

	var map := _mapBounds()
	var rect := Rect2(Vector2.ZERO, _size * z1)
	var world := rect.grow(-_back.cell_size.x)
	var c0 := _camera.offset + (_mapSize() / 2.0)
	# if not world.intersects(map):
	# 	c0 = _constrainRect(world, map)
	# # var c1 := c0 + (_mapSize() / 2.0) * (z0 - z1)
	# var c1 := c0 * (z0 - z1)

	# mouse wheel should no go past max!?!?!?
	### make some ui to test this shit right!?
	### confirm current position!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	print(_map(_center()))
	print("---: %s" % _map(-_camera.offset))
	### being called twice???????????????????????????????????

	if not z0.is_equal_approx(z1) or not world.intersects(map):
		c0 = _constrainRect(world, map)
		# var c1 := c0 + (_mapSize() / 2.0) * (z0 - z1)
		var c1 := c0 * (z0 - z1)
		Utility.stfu(_tween.stop(_camera, "zoom"))
		Utility.stfu(_tween.stop(_camera, "offset"))
		Utility.stfu(_tween.interpolate_property(_camera, "zoom", null, z1, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.interpolate_property(_camera, "offset", null, c1, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.start())

# func _zoomUpdate() -> void:
# 		_zoom(_camera.offset - _mapSize() / 2.0, _zoomClamp(_camera.zoom).x)

func _targetToMob() -> void:
	_targetTo(_mob.position)

func _targetTo(to: Vector2) -> void:
	_targetStop()
	var tile = _map(to * _camera.zoom + _camera.offset)
	print(tile)
	_target.position = _world(tile)

func _targetUpdate() -> void:
	_targetSnapClosest(_map(_target.position))

func _targetSnapClosest(tile: Vector2) -> void:
	_targetSnap(_astar.get_point_position(_astar.get_closest_point(tile)))

func _targetSnap(tile: Vector2) -> void:
	var p := _world(tile)
	if not _target.position.is_equal_approx(p):
		Utility.stfu(_tween.stop(_target, "position"))
		Utility.stfu(_tween.interpolate_property(_target, "position", null, p, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.start())

func _targetStop() -> void:
	Utility.stfu(_tween.stop(_target, "position"))

func _normalize() -> Vector2:
	return (_camera.offset - _mapSize() / 2.0) / _size

func _onResize() -> void:
	_camera.offset = _normalize() * size + _mapSize() / 2.0
	_size = size
	_cameraSnap()
