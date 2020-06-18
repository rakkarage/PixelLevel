extends Viewport

onready var _tween:       Tween = $Tween
onready var _camera:   Camera2D = $Camera
onready var _back:      TileMap = $Camera/Back
onready var _waterBack: TileMap = $Camera/WaterBack
onready var _mob:        Node2D = $Camera/Mob
onready var _waterFore: TileMap = $Camera/WaterBack
onready var _fore:      TileMap = $Camera/Fore
onready var _light:     TileMap = $Camera/Light
onready var _edge:      TileMap = $Camera/Edge
onready var _target:     Node2D = $Camera/Target
onready var _path:       Node2D = $Camera/Path
onready var _astar:     AStar2D = AStar2D.new()
onready var _tileSet:           = _back.tile_set
var _rect := Rect2()
var _pathPoints := PoolVector2Array()
var _dragLeft := false
var _size := Vector2.ZERO
var _rng := RandomNumberGenerator.new()
var _turn := false
var _time := 0.0
var _turnTotal := 0
var _timeTotal := 0.0
const _turnTime := 0.333
const _duration := 0.22
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02
const _pathScene := preload("res://PixelLevel/Path.tscn")
const _startAt := Vector2(4, 4)

enum Tile {
	BannerA,
	BannerB,
	Carpet,
	Furnature,
	Theme0Torch, Theme0Wall, Theme0Floor, Theme0FloorRoom, Theme0Stair, Theme0Door,
	Theme4Torch, Theme4Wall, Theme4Floor, Theme4FloorRoom, Theme4Stair, Theme4Door,
	WaterDeepBack, WaterDeepFore,
	WaterShallowBack, WaterShallowFore,
	Light,
	EdgeInside,	EdgeInsideCorner,
	EdgeOutsideCorner, EdgeOutside,
}

func _ready() -> void:
	_rect = _back.get_used_rect()
	_size = size
	_rng.randomize()
	_drawEdge()
	_mob.position = _world(_startAt) + _back.cell_size / 2.0
	_targetToMob()
	_addPoints()
	_connectPoints()
	_camera.zoom = Vector2(0.75, 0.75)
	_cameraCenter()
	Utility.ok(connect("size_changed", self, "_onResize"))
	Utility.ok(Gesture.connect("onZoom", self, "_zoomPinch"))

func _process(delta) -> void:
	_time += delta
	if _turn and _time > _turnTime:
		_turn = false
		_timeTotal += _time
		_turnTotal += 1
		_move(_mob)
		_time = 0.0
		# update light!!!!!!!!!!!
		# if character too close to edge of screen center on character!
		# update minimap!

func _move(mob: Node2D) -> void:
	if _pathPoints.size() != 0:
		var delta = _delta(_pathPoints[0], _pathPoints[1])
		_face(mob, delta)
		# play walk animation!!!!!!!!!!!!!!!!!!!
		_step(mob, delta)
		_pathPoints.remove(0)
		_path.get_child(0).queue_free()
		if _pathPoints.size() > 1:
			_turn = true

func _face(mob: Node2D, direction: Vector2) -> void:
	if direction.x > 0 or direction.y > 0:
		mob.scale = Vector2(-1, 1)
	else:
		mob.scale = Vector2(1, 1)

func _step(mob: Node2D, direction: Vector2) -> void:
	mob.position += _world(direction)

func _tileIndex(p: Vector2) -> int:
	return int(p.y * _rect.size.x + p.x)

func _tilePosition(index: int) -> Vector2:
	var y := index / _rect.size.x
	var x := index - _rect.size.x * y
	return Vector2(x, y)

func _addPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			var p := Vector2(x, y)
			_astar.add_point(_tileIndex(p), p)

func _connectPoints() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			_connect(Vector2(x, y))

func _connect(p: Vector2) -> void:
	for yy in range(p.y - 1, p.y + 2):
		for xx in range(p.x - 1, p.x + 2):
			var pp := Vector2(xx, yy)
			if (not is_equal_approx(yy, p.y) or not is_equal_approx(xx, p.x)) and _rect.has_point(pp):
				if not _blocked(xx, yy):
					_astar.connect_points(_tileIndex(p), _tileIndex(pp), false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_targetTo(event.position)
				_dragLeft = true
			else:
				_targetUpdate()
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
		var to := _camera.offset + _constrainRect(world, map)
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
	var z1 := _zoomClamp(z0 * factor)
	var c0 := _camera.offset
	var c1 := c0 + at * (z0 - z1)
	_camera.zoom = z1
	_camera.offset = c1

func _zoomClamp(z: Vector2) -> Vector2:
	return _zoomMin if z < _zoomMin else _zoomMax if z > _zoomMax else z

func _targetToMob() -> void:
	_targetTo(_mob.position)

func _targetTo(to: Vector2) -> void:
	_targetStop()
	var new = _map(to * _camera.zoom + _camera.offset)
	if _map(_target.position) == new:
		_turn = true
	else:
		_target.position = _world(new)

func _targetUpdate() -> void:
	var from := _map(_mob.position)
	var to := _map(_target.position)
	to = _targetSnapClosest(to)
	_pathPoints = _astar.get_point_path(_tileIndex(from), _tileIndex(to))
	_pathClear()
	var rotation := 0
	var pathDelta := _delta(from, to)
	for i in _pathPoints.size():
		var tile := _pathPoints[i]
		if i + 1 < _pathPoints.size():
			rotation = _pathRotate(_delta(tile, _pathPoints[i + 1]), pathDelta)
		var child := _pathScene.instance()
		child.rotation_degrees = rotation
		child.position = _world(tile)
		_path.add_child(child)

func _delta(from: Vector2, to: Vector2) -> Vector2:
	return to - from

func _pathRotate(stepDelta, pathDelta) -> int:
	var rotation := 0
	var trending := abs(pathDelta.y) > abs(pathDelta.x)
	if stepDelta.x > 0 and stepDelta.y < 0:
		rotation = 270 if trending else 0
	elif stepDelta.x > 0 and stepDelta.y > 0:
		rotation = 90 if trending else 0
	elif stepDelta.x < 0 and stepDelta.y < 0:
		rotation = 270 if trending else 180
	elif stepDelta.x < 0 and stepDelta.y > 0:
		rotation = 90 if trending else 180
	elif stepDelta.x > 0:
		rotation = 0
	elif stepDelta.x < 0:
		rotation = 180
	elif stepDelta.y < 0:
		rotation = 270
	elif stepDelta.y > 0:
		rotation = 90
	return rotation

func _pathClear():
	for path in _path.get_children():
		path.free()

func _targetSnapClosest(tile: Vector2) -> Vector2:
	var p := _astar.get_point_position(_astar.get_closest_point(tile))
	_targetSnap(p)
	return p

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

func _drawEdge() -> void:
	var minY := _rect.position.y - 1
	var maxY := _rect.size.y
	var minX := _rect.position.x - 1
	var maxX := _rect.size.x
	for y in range(minY, maxY + 1):
		for x in range(minX, maxX + 1):
			if x == minX or x == maxX or y == minY or y == maxY:
				if x == minX and y == minY: # nw
					_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(1, 0))
				elif x == minX and y == maxY: # sw
					_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(2, 0))
				elif x == maxX and y == minY: # ne
					_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(0, 0))
				elif x == maxX and y == maxY: # se
					_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(3, 0))
				elif x == minX: # w
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, false, _randomBool(), true)
				elif x == maxX: # e
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, true, _randomBool(), true)
				elif y == minY: # n
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, _randomBool(), false, false)
				elif y == maxY: # s
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, _randomBool(), true, false)
			elif (x == minX + 1) or (x == maxX - 1) or (y == minY + 1) or (y == maxY - 1):
				if x == minX + 1 and y == minY + 1: # nw
					_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, false, false, false)
				elif x == minX + 1 and y == maxY - 1: # sw
					_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, false, true, false)
				elif x == maxX - 1 and y == minY + 1: # ne
					_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, true, false, true)
				elif x == maxX - 1 and y == maxY - 1: # se
					_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, true, true, false)
				elif x == minX + 1: # w
					_setRandomTile(_edge, x, y, Tile.EdgeInside, false, _randomBool(), true)
				elif x == maxX - 1: # e
					_setRandomTile(_edge, x, y, Tile.EdgeInside, true, _randomBool(), true)
				elif y == minY + 1: # n
					_setRandomTile(_edge, x, y, Tile.EdgeInside, _randomBool(), false, false)
				elif y == maxY - 1: # s
					_setRandomTile(_edge, x, y, Tile.EdgeInside, _randomBool(), true, false)

func _randomBool() -> bool:
	return bool(_rng.randi() % 2)

func _setRandomTile(map: TileMap, x: int, y: int, id: int, flipX: bool = false, flipY: bool = false, rot90: bool = false) -> void:
	map.set_cell(x, y, id, flipX, flipY, rot90, _randomTile(id))

func _randomTile(id: int) -> Vector2:
	var p := Vector2.ZERO
	var r := _tileSet.tile_get_region(id)
	var s := _tileSet.autotile_get_size(id)
	var size := r.size / s
	var total := 0
	for y in range(size.y):
		for x in range(size.x):
			total += _tileSet.autotile_get_subtile_priority(id, Vector2(x, y))
	var random := _rng.randi() % total
	var current := 0
	for y in range(size.y):
		for x in range(size.x):
			p = Vector2(x, y)
			current += _tileSet.autotile_get_subtile_priority(id, p)
			if current >= random:
				return p
	return p

func _blocked(x: int, y: int) -> bool:
	var back := _back.get_cell(x, y)
	var fore := _fore.get_cell(x, y)
	var f: bool = back == Tile.Theme0Floor or back == Tile.Theme4Floor
	var fr: bool = back == Tile.Theme0FloorRoom or back == Tile.Theme4FloorRoom
	var w: bool = fore == Tile.Theme0Wall or fore == Tile.Theme4Wall
	var d: bool = fore == Tile.Theme0Door or fore == Tile.Theme4Door
	var s := _fore.get_cell_autotile_coord(x, y)
	return w or (not f and not fr) or (d and s == Vector2(0, 0))
