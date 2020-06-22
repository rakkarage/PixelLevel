extends Viewport
class_name Level

onready var _tween:       Tween = $Tween
onready var _camera:   Camera2D = $Camera
onready var _back:      TileMap = $Back
onready var _waterBack: TileMap = $WaterBack
onready var _mob:        Node2D = $Mob
onready var _waterFore: TileMap = $WaterBack
onready var _fore:      TileMap = $Fore
onready var _light:     TileMap = $Light
onready var _edge:      TileMap = $Edge
onready var _target:     Node2D = $Target
onready var _path:       Node2D = $Path
onready var _astar:             = AStar2D.new()
onready var _tileSet:           = _back.tile_set
var _rect := Rect2()
var _oldSize = Vector2.ZERO
var _pathPoints := PoolVector2Array()
var _dragLeft := false
var _turn := false
var _time := 0.0
var _turnTotal := 0
var _timeTotal := 0.0
const _turnTime := 0.333
const _duration := 0.4444
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
	EdgeOutsideCorner, EdgeOutside
}

signal updateMap

func _ready() -> void:
	_rect = getMapRect()
	_oldSize = size
	_drawEdge()
	_mob.global_position = _world(_startAt) + _back.cell_size / 2.0
	_targetToMob()
	_addPoints()
	_connectPoints()
	_camera.zoom = Vector2(0.75, 0.75)
	_cameraCenter()
	_dark()
	_findTorches()
	_lightUpdate(_map(_mob.global_position), _lightRadius)
	Utility.ok(connect("size_changed", self, "_onResize"))
	Utility.ok(Gesture.connect("onZoom", self, "_zoomPinch"))

func _process(delta) -> void:
	_time += delta
	if _turn and _time > _turnTime:
		_turn = false
		_timeTotal += _time
		_turnTotal += 1
		_move(_mob)
		_lightUpdate(_map(_mob.global_position), _lightRadius)
		_checkCenter()
		emit_signal("updateMap")
		_time = 0.0

func _move(mob: Node2D) -> void:
	if _pathPoints.size() > 1:
		var delta := _delta(_pathPoints[0], _pathPoints[1])
		_face(mob, delta)
		# TODO: play walk animation which has step sounds!!!!!!!!!!!!!!!!!!!
		_step(mob, delta)
		_pathPoints.remove(0)
		_path.get_child(0).queue_free()
		if _pathPoints.size() > 1:
			_turn = true
		else:
			_path.get_child(1).queue_free()

func _face(mob: Node2D, direction: Vector2) -> void:
	if direction.x > 0 or direction.y > 0:
		mob.scale = Vector2(-1, 1)
	else:
		mob.scale = Vector2(1, 1)

func _step(mob: Node2D, direction: Vector2) -> void:
	mob.global_position += _world(direction)

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
				_targetTo(event.global_position)
				_dragLeft = true
			else:
				_targetUpdate()
				_cameraUpdate()
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_zoomIn(event.global_position)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
		emit_signal("updateMap")
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_cameraTo(_camera.global_position - event.relative * _camera.zoom)
			emit_signal("updateMap")

func _world(tile: Vector2) -> Vector2:
	return _back.map_to_world(tile)

func _worldSize() -> Vector2:
	return size * _camera.zoom

func _worldBounds() -> Rect2:
	return Rect2(Vector2.ZERO, _worldSize())

func _map(position: Vector2) -> Vector2:
	return _back.world_to_map(position)

func _mapSize() -> Vector2:
	return _rect.size * _back.cell_size

func mapBounds() -> Rect2:
	return Rect2(-_camera.global_position, _mapSize())

func _center() -> Vector2:
	return -(_worldSize() / 2.0) + _mapSize() / 2.0

func _cameraCenter() -> void:
	_cameraTo(_center())

func _cameraTo(to: Vector2) -> void:
	_cameraStop()
	_camera.global_position = to

func _cameraBy(by: Vector2) -> void:
	_cameraTo(_camera.global_position + by)

static func _constrainRect(world: Rect2, map: Rect2) -> Vector2:
	return _constrain(world.position, world.end, map.position, map.end)

static func _constrain(minWorld: Vector2, maxWorld: Vector2, minMap: Vector2, maxMap: Vector2) -> Vector2:
	var delta := Vector2.ZERO
	if minWorld.x > minMap.x: delta.x += minMap.x - minWorld.x
	if maxWorld.x < maxMap.x: delta.x -= maxWorld.x - maxMap.x
	if minWorld.y > minMap.y: delta.y += minMap.y - minWorld.y
	if maxWorld.y < maxMap.y: delta.y -= maxWorld.y - maxMap.y
	return delta

func _cameraUpdate() -> void:
	var map := mapBounds()
	var world := _worldBounds().grow(-_back.cell_size.x)
	if not world.intersects(map):
		_cameraSnap(_camera.global_position + _constrainRect(world, map))

func _cameraSnap(to: Vector2) -> void:
	_cameraStop()
	Utility.stfu(_tween.interpolate_property(_camera, "global_position", null, to, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
	Utility.stfu(_tween.start())

func _cameraStop() -> void:
	Utility.stfu(_tween.stop(_camera, "global_position"))

const _edgeOffset := 1.5
const _edgeOffsetV := Vector2(_edgeOffset, _edgeOffset)

func _checkCenter() -> void:
	var edge = _world(_edgeOffsetV) / _camera.zoom
	var test = -(_camera.global_position - _mob.global_position) / _camera.zoom
	if ((test.x > size.x - edge.x) or (test.x < edge.x) or
		(test.y > size.y - edge.y) or (test.y < edge.y)):
		_cameraSnap(-(_worldSize() / 2.0) + _mob.global_position)

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

func _targetToMob() -> void:
	_targetTo(_mob.global_position)

func _targetTo(to: Vector2) -> void:
	_targetStop()
	var tile := _map(_camera.global_position + to * _camera.zoom)
	if tile == _map(_target.global_position):
		_turn = true
	else:
		_target.global_position = _world(tile)

func _targetUpdate() -> void:
	var from := _map(_mob.global_position)
	var to := _map(_target.global_position)
	to = _targetSnapClosest(to)
	_pathUpdate(from, to)

func _pathUpdate(from: Vector2, to: Vector2) -> void:
	_pathPoints = _astar.get_point_path(_tileIndex(from), _tileIndex(to))
	_pathClear()
	var rotation := 0
	var pathDelta := _delta(from, to)
	for i in _pathPoints.size():
		var tile := _pathPoints[i]
		if i + 1 < _pathPoints.size():
			rotation = _pathRotate(_delta(tile, _pathPoints[i + 1]), pathDelta)
		var child := _pathScene.instance()
		child.global_rotation_degrees = rotation
		child.global_position = _world(tile)
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
	if not _target.global_position.is_equal_approx(p):
		Utility.stfu(_tween.stop(_target, "global_position"))
		Utility.stfu(_tween.interpolate_property(_target, "global_position", null, p, _duration, Tween.TRANS_ELASTIC, Tween.EASE_OUT))
		Utility.stfu(_tween.start())

func _targetStop() -> void:
	Utility.stfu(_tween.stop(_target, "global_position"))

func _normalize() -> Vector2:
	return (_camera.global_position - _mapSize() / 2.0) / _oldSize

func _onResize() -> void:
	_camera.global_position = _normalize() * size + _mapSize() / 2.0
	_oldSize = size
	_cameraUpdate()

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
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, false, Random.nextBool(), true)
				elif x == maxX: # e
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, true, Random.nextBool(), true)
				elif y == minY: # n
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, Random.nextBool(), false, false)
				elif y == maxY: # s
					_setRandomTile(_edge, x, y, Tile.EdgeOutside, Random.nextBool(), true, false)
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
					_setRandomTile(_edge, x, y, Tile.EdgeInside, false, Random.nextBool(), true)
				elif x == maxX - 1: # e
					_setRandomTile(_edge, x, y, Tile.EdgeInside, true, Random.nextBool(), true)
				elif y == minY + 1: # n
					_setRandomTile(_edge, x, y, Tile.EdgeInside, Random.nextBool(), false, false)
				elif y == maxY - 1: # s
					_setRandomTile(_edge, x, y, Tile.EdgeInside, Random.nextBool(), true, false)

func _setRandomTile(map: TileMap, x: int, y: int, id: int, flipX: bool = false, flipY: bool = false, rot90: bool = false) -> void:
	map.set_cell(x, y, id, flipX, flipY, rot90, _randomTile(id))

func _randomTile(id: int) -> Vector2:
	var p := Vector2.ZERO
	var s := _tileSet.tile_get_region(id).size / _tileSet.autotile_get_size(id)
	var total := 0
	for y in range(s.y):
		for x in range(s.x):
			total += _tileSet.autotile_get_subtile_priority(id, Vector2(x, y))
	var selected := Random.next(total)
	var current := 0
	for y in range(s.y):
		for x in range(s.x):
			p = Vector2(x, y)
			current += _tileSet.autotile_get_subtile_priority(id, p)
			if current >= selected:
				return p
	return p

func _blockedV(p: Vector2) -> bool:
	return _blocked(int(p.x), int(p.y))

func _blocked(x: int, y: int) -> bool:
	if not _insideMap(x, y): return true
	var back := _back.get_cell(x, y)
	var fore := _fore.get_cell(x, y)
	var f: bool = back == Tile.Theme0Floor or back == Tile.Theme4Floor
	var fr: bool = back == Tile.Theme0FloorRoom or back == Tile.Theme4FloorRoom
	var w: bool = fore == Tile.Theme0Wall or fore == Tile.Theme4Wall or fore == Tile.Theme0Torch or fore == Tile.Theme4Torch
	var d: bool = fore == Tile.Theme0Door or fore == Tile.Theme4Door
	var s := _fore.get_cell_autotile_coord(x, y)
	return w or (not f and not fr) or (d and s == Vector2(0, 0))

const _torchRadius := 5
const _lightRadius := 8
const _lightMin := 0
const _lightMax := 31
const _lightExplored := 8
const _lightCount := 24
const _fovOctants = [
	[1,  0,  0, -1, -1,  0,  0,  1],
	[0,  1, -1,  0,  0, -1,  1,  0],
	[0,  1,  1,  0,  0, -1, -1,  0],
	[1,  0,  0,  1, -1,  0,  0, -1]
]
var _torches := []

func _lightEmitRecursive(at: Vector2, radius: int, maxRadius: int, start: float, end: float, xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end: return
	var rSquared := maxRadius * maxRadius
	var newStart := 0.0
	for i in range(radius, maxRadius + 1):
		var dx := -i - 1
		var dy := -i
		var blocked := false
		while dx <= 0:
			dx += 1
			var x := int(at.x + dx * xx + dy * xy)
			var y := int(at.y + dx * yx + dy * yy)
			if not _insideMap(x, y): continue
			var lSlope := (dx - 0.5) / (dy + 0.5)
			var rSlope := (dx + 0.5) / (dy - 0.5)
			if start < rSlope: continue
			elif end > lSlope: break
			else:
				var distanceSquared := (at.x - x) * (at.x - x) + (at.y - y) * (at.y - y)
				if distanceSquared < rSquared:
					var intensity1 := 1.0 / (1.0 + distanceSquared / maxRadius)
					var intensity2 := intensity1 - 1.0 / (1.0 + rSquared)
					var intensity := intensity2 / (1.0 - 1.0 / (1.0 + rSquared))
					var light := int(intensity * _lightCount)
					_setLight(x, y, _lightExplored + light, true)
				var blockedAt := _blocked(x, y)
				if blocked:
					if blockedAt:
						newStart = rSlope
						continue
					else:
						blocked = false
						start = newStart
				elif blockedAt and radius < maxRadius:
					blocked = true
					_lightEmitRecursive(at, i + 1, maxRadius, start, lSlope, xx, xy, yx, yy)
					newStart = rSlope
		if blocked: break

func _lightEmit(at: Vector2, radius: int) -> void:
	for i in range(_fovOctants[0].size()):
		_lightEmitRecursive(at, 1, radius, 1.0, 0.0, _fovOctants[0][i], _fovOctants[1][i], _fovOctants[2][i], _fovOctants[3][i])
	_setLight(int(at.x), int(at.y), _lightMax, true)

func _lightUpdate(at: Vector2, radius: int) -> void:
	_darken()
	_lightEmit(at, radius)
	_lightTorches()

func _findTorches() -> void:
	var torch0 := _fore.get_used_cells_by_id(Tile.Theme0Torch)
	var torch1 := _fore.get_used_cells_by_id(Tile.Theme4Torch)
	_torches = torch0 + torch1

func _lightTorches() -> void:
	for _repeat in range(2, 0, -1):
		for p in _torches:
			var north := Vector2(p.x, p.y + 1)
			var east := Vector2(p.x + 1, p.y)
			var south := Vector2(p.x, p.y - 1)
			var west := Vector2(p.x - 1, p.y)
			var emitted := false
			if _insideMapV(p):
				var northBlocked = _blockedV(north)
				if not northBlocked and _litV(north):
					emitted = true
					_lightEmit(north, Random.next(_torchRadius))
				var eastBlocked = _blockedV(east)
				if not eastBlocked and _litV(east):
					emitted = true
					_lightEmit(east, Random.next(_torchRadius))
				var southBlocked = _blockedV(south)
				if not southBlocked and _litV(south):
					emitted = true
					_lightEmit(south, Random.next(_torchRadius))
				var westBlocked = _blockedV(west)
				if not westBlocked and _litV(west):
					emitted = true
					_lightEmit(west, Random.next(_torchRadius))
				if not emitted:
					var northEast := Vector2(p.x + 1, p.y + 1)
					var southEast := Vector2(p.x + 1, p.y - 1)
					var southWest := Vector2(p.x - 1, p.y - 1)
					var northWest := Vector2(p.x - 1, p.y + 1)
					if northBlocked and eastBlocked and not _blockedV(northEast) and _litV(northEast):
						_lightEmit(northEast, Random.next(_torchRadius))
					if southBlocked and eastBlocked and not _blockedV(southEast) and _litV(southEast):
						_lightEmit(southEast, Random.next(_torchRadius))
					if southBlocked and westBlocked and not _blockedV(southWest) and _litV(southWest):
						_lightEmit(southWest, Random.next(_torchRadius))
					if northBlocked and westBlocked and not _blockedV(northWest) and _litV(northWest):
						_lightEmit(northWest, Random.next(_torchRadius))

func _dark() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			_setLight(x, y, _lightMin, false)

func _darken() -> void:
	for y in range(_rect.size.y):
		for x in range(_rect.size.x):
			if _getLight(x, y) != _lightMin:
				_setLight(x, y, _lightExplored, false)

func _exploredV(p: Vector2) -> bool:
	return _explored(int(p.x), int(p.y))

func _explored(x: int, y: int) -> bool:
	return _getLight(x, y) == _lightExplored

func _litV(p: Vector2) -> bool:
	return _lit(int(p.x), int(p.y))

func _lit(x: int, y: int) -> bool:
	return _getLight(x, y) > _lightExplored

func _wall(x: int, y: int) -> bool:
	var tile = _fore.get_cell(x, y)
	return (tile == Tile.Theme0Wall or tile == Tile.Theme4Wall or
		tile == Tile.Theme0Torch or tile == Tile.Theme4Torch)

func _stair(x: int, y: int) -> bool:
	var tile = _fore.get_cell(x, y)
	return tile == Tile.Theme0Stair or tile == Tile.Theme4Stair

func _door(x: int, y: int) -> bool:
	var tile = _fore.get_cell(x, y)
	return tile == Tile.Theme0Door or tile == Tile.Theme4Door

func _floor(x: int, y: int) -> bool:
	var tile = _back.get_cell(x, y)
	return (tile == Tile.Theme0Floor or tile == Tile.Theme0FloorRoom or
		tile == Tile.Theme4Floor or tile == Tile.Theme4FloorRoom)

func _getLight(x: int, y: int) -> int:
	return int(_light.get_cell_autotile_coord(x, y).x)

func _setLight(x: int, y: int, light: int, test: bool) -> void:
	if not test or light > _getLight(x, y):
		_light.set_cell(x, y, Tile.Light, false, false, false, Vector2(light, 0))

func _insideMapV(p: Vector2) -> bool:
	return _rect.has_point(p)

func _insideMap(x: int, y: int) -> bool:
	return x >= _rect.position.x and y >= _rect.position.y and x < _rect.size.x and y < _rect.size.y

func getMapRect() -> Rect2:
	return _back.get_used_rect()

func getCameraRect() -> Rect2:
	return Rect2(_map(_camera.global_position), _map(_camera.global_position + _worldSize()))

const _colorMob := Color(0, 1, 1, 1)
const _colorStair := Color(1.0, 1.0, 0.0, 0.75)
const _colorDoor := Color(0.0, 0.0, 1.0, 0.75)
const _colorWall := Color(0.75, 0.75, 0.75, 0.75)
const _colorFloorLit := Color(0.5, 0.5, 0.5, 0.5)
const _colorFloor := Color(0.25, 0.25, 0.25, 0.25)
const _colorCamera := Color(1, 0, 1, 0.75)

func getMapColor(x: int, y: int) -> Color:
	var rect = getCameraRect()
	var color = Color(0.25, 0.25, 0.25, 1)
	var lit = _lit(x, y)
	var mob = _map(_mob.global_position)
	if lit or _explored(x, y):
		if x == mob.x and y == mob.y:
			color = _colorMob
		elif (((x >= rect.position.x and x <= rect.size.x) and
			(y == rect.position.y or y == rect.size.y)) or
			((y >= rect.position.y and y <= rect.size.y) and
			(x == rect.position.x or x == rect.size.x))):
			color = _colorCamera
		elif _stair(x, y):
			color = _colorStair
		elif _door(x, y):
			color = _colorDoor
		elif _wall(x, y):
			color = _colorWall
		elif _floor(x, y):
			color = _colorFloorLit if lit else _colorFloor
	return color
