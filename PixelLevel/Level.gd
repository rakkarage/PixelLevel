extends Viewport
class_name Level

onready var _tween:       Tween = $Tween
onready var _camera:   Camera2D = $Camera
onready var _back:      TileMap = $Back
onready var _fore:      TileMap = $Fore
onready var _waterBack: TileMap = $WaterBack
onready var _mob:        Node2D = $Mob
onready var _waterFore: TileMap = $WaterFore
onready var _light:     TileMap = $Light
onready var _edge:      TileMap = $Edge
onready var _target:     Node2D = $Target
onready var _path:       Node2D = $Path
onready var _astar:             = AStar2D.new()
onready var _tileSet:           = _back.tile_set
var rect := Rect2()
var _oldSize = Vector2.ZERO
var _pathPoints := PoolVector2Array()
var _dragLeft := false
var _turn := false
var _time := 0.0
var _turnTotal := 0
var _timeTotal := 0.0
const _turnTime := 0.22
const _duration := 0.4444
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02
const _pathScene := preload("res://PixelLevel/Path.tscn")
var startAt := Vector2(4, 4)
var theme = 0
const themeCount = 4
var themeCliff = 0
const themeCliffCount = 2

enum Tile {
	Cliff0, Cliff1
	Banner0, Banner1,
	Furnature, Carpet,
	EdgeInside,	EdgeInsideCorner,
	EdgeOutsideCorner, EdgeOutside,
	Light,
	Theme0Torch, Theme0WallPlain, Theme0Wall, Theme0Floor, Theme0FloorRoom, Theme0Stair, Theme0Door,
	Theme1Torch, Theme1WallPlain, Theme1Wall, Theme1Floor, Theme1FloorRoom, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2WallPlain, Theme2Wall, Theme2Floor, Theme2FloorRoom, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3WallPlain, Theme3Wall, Theme3Floor, Theme3FloorRoom, Theme3Stair, Theme3Door,
	WaterShallowBack, WaterShallowFore,
	WaterDeepBack, WaterDeepFore,
	Rubble
}

signal updateMap
signal generate

func _ready() -> void:
	rect = _back.get_used_rect()
	_camera.zoom = Vector2(0.75, 0.75)
	generated()
	_cameraCenter()
	Utility.ok(connect("size_changed", self, "_onResize"))
	Utility.ok(Gesture.connect("onZoom", self, "_zoomPinch"))

func generated() -> void:
	_oldSize = size
	_drawEdge()
	_mob.global_position = _world(startAt) + _back.cell_size / 2.0
	_pathClear()
	_addPoints()
	_connectPoints()
	_targetToMob()
	_checkCenter()
	_dark()
	_findTorches()
	_lightUpdate(mobPosition(), _lightRadius)
	_cameraUpdate()
	emit_signal("updateMap")
	verifyCliff()

func _process(delta) -> void:
	_time += delta
	if _turn and _time > _turnTime:
		_turn = false
		_timeTotal += _time
		_turnTotal += 1
		if not _handleDoor():
			_move(_mob)
		if not _handleStair():
			_lightUpdate(mobPosition(), _lightRadius)
			_checkCenter()
			emit_signal("updateMap")
		_time = 0.0

func _move(mob: Node2D) -> void:
	if _pathPoints.size() > 1:
		var delta := _delta(_pathPoints[0], _pathPoints[1])
		_face(mob, delta)
		_step(mob, delta)
		_pathPoints.remove(0)
		_path.get_child(0).free()
		if _pathPoints.size() > 1:
			_turn = true
		else:
			_pathClear()

func _handleStair() -> bool:
	if _pathPoints.size() == 1 and isStairDownV(mobPosition()):
		emit_signal("generate")
		return true
	return false

func _handleDoor() -> bool:
	var from := mobPosition()
	var to := targetPosition()
	if from.distance_to(to) < 2.0:
		if isDoorV(to):
			_toggleDoorV(to)
			_astar.set_point_disabled(_tileIndex(to), isDoorShutV(to))
			return true
	return false

func _toggleDoorV(p: Vector2) -> void:
	_toggleDoor(int(p.x), int(p.y))

func _toggleDoor(x: int, y: int) -> void:
	var door := _fore.get_cell_autotile_coord(x, y)
	_fore.set_cell(x, y, _fore.get_cell(x, y), false, false, false, Vector2(0 if door.x == 1 else 1, 0))

func _face(mob: Node2D, direction: Vector2) -> void:
	if direction.x > 0:
		mob.scale = Vector2(-1, 1)
	else:
		mob.scale = Vector2(1, 1)

func _step(mob: Node2D, direction: Vector2) -> void:
	# TODO: play walk animation and interpolate global_position
	mob.global_position += _world(direction)

func _tileIndex(p: Vector2) -> int:
	return int(p.y * rect.size.x + p.x)

func _tilePosition(index: int) -> Vector2:
	var y := int(index / rect.size.x)
	var x := int(index - rect.size.x * y)
	return Vector2(x, y)

func _addPoints() -> void:
	_astar.clear()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p := Vector2(x, y)
			_astar.add_point(_tileIndex(p), p)

func _connectPoints() -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			_connect(Vector2(x, y))

func _connect(p: Vector2) -> void:
	for yy in range(p.y - 1, p.y + 2):
		for xx in range(p.x - 1, p.x + 2):
			var pp := Vector2(xx, yy)
			if (not is_equal_approx(yy, p.y) or not is_equal_approx(xx, p.x)) and rect.has_point(pp):
				if isDoor(xx, yy) or not isBlocked(xx, yy):
					_astar.connect_points(_tileIndex(p), _tileIndex(pp), false)
					if isDoorShut(xx, yy):
						_astar.set_point_disabled(_tileIndex(pp), true)

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
			_cameraUpdate()
			emit_signal("updateMap")
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
			_cameraUpdate()
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
	return rect.size * _back.cell_size

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
	yield(_tween, "tween_all_completed")
	emit_signal("updateMap")

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
	if tile == targetPosition():
		_turn = true
	else:
		_target.global_position = _world(tile)

func _targetUpdate() -> void:
	var from := mobPosition()
	var to := _targetSnapClosest(targetPosition())
	_pathClear()
	if from != to:
		_drawPath(from, to)

func _drawPath(from: Vector2, to: Vector2) -> void:
	var color := _getPathColor(int(to.x), int(to.y))
	_target.modulate = color
	var rotation := 0
	var pathDelta := _delta(from, to)
	_pathPoints = _astar.get_point_path(_tileIndex(from), _tileIndex(to))
	for i in _pathPoints.size():
		var tile := _pathPoints[i]
		if i + 1 < _pathPoints.size():
			rotation = _pathRotate(_delta(tile, _pathPoints[i + 1]), pathDelta)
		var child := _pathScene.instance()
		child.modulate = color
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
	_target.modulate = Color.transparent
	for path in _path.get_children():
		path.free()
	for i in range(_pathPoints.size() - 1, 0, -1):
		_pathPoints.remove(i)

func _targetSnapClosest(tile: Vector2) -> Vector2:
	var p := _astar.get_point_position(_astar.get_closest_point(tile, true))
	_targetSnap(p)
	return p

func _targetSnap(tile: Vector2) -> void:
	var p := _world(tile)
	if not _target.global_position.is_equal_approx(p):
		_targetStop()
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
	var minY := rect.position.y - 1
	var maxY := rect.size.y
	var minX := rect.position.x - 1
	var maxX := rect.size.x
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
			if current > selected:
				return p
	return p

func isBlockedV(p: Vector2) -> bool:
	return isBlocked(int(p.x), int(p.y))

func isBlocked(x: int, y: int) -> bool:
	if not insideMap(x, y): return true
	var back := _back.get_cell(x, y)
	var fore := _fore.get_cell(x, y)
	var f := isFloorId(back)
	var w := isWallId(fore)
	var d := isDoorId(fore)
	var s := _fore.get_cell_autotile_coord(x, y)
	return w or not f or (d and s == Vector2(0, 0))

const _torchRadius := 8
const _torchRadiusMax := _torchRadius * 2
const _lightRadius := 16
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
var _torches := {}

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
			if not insideMap(x, y): continue
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
				var blockedAt := isBlocked(x, y)
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
	_torches.clear()
	var torch0 := _fore.get_used_cells_by_id(Tile.Theme0Torch)
	var torch1 := _fore.get_used_cells_by_id(Tile.Theme1Torch)
	var torch2 := _fore.get_used_cells_by_id(Tile.Theme2Torch)
	var torch3 := _fore.get_used_cells_by_id(Tile.Theme3Torch)
	for p in torch0 + torch1 + torch2 + torch3:
		_torches[p] = Random.next(_torchRadius)

func _lightTorches() -> void:
	for p in _torches.keys():
		_torches[p] = clamp(_torches[p] + Random.nextRange(-1, 1), 0, _torchRadiusMax)
		var current = _torches[p]
		var north := Vector2(p.x, p.y + 1)
		var east := Vector2(p.x + 1, p.y)
		var south := Vector2(p.x, p.y - 1)
		var west := Vector2(p.x - 1, p.y)
		var emitted := false
		if insideMapV(p):
			var northBlocked = isBlockedV(north)
			if not northBlocked and isLitV(north):
				emitted = true
				_lightEmit(north, current)
			var eastBlocked = isBlockedV(east)
			if not eastBlocked and isLitV(east):
				emitted = true
				_lightEmit(east, current)
			var southBlocked = isBlockedV(south)
			if not southBlocked and isLitV(south):
				emitted = true
				_lightEmit(south, current)
			var westBlocked = isBlockedV(west)
			if not westBlocked and isLitV(west):
				emitted = true
				_lightEmit(west, current)
			if not emitted:
				var northEast := Vector2(p.x + 1, p.y + 1)
				var southEast := Vector2(p.x + 1, p.y - 1)
				var southWest := Vector2(p.x - 1, p.y - 1)
				var northWest := Vector2(p.x - 1, p.y + 1)
				if northBlocked and eastBlocked and not isBlockedV(northEast) and isLitV(northEast):
					_lightEmit(northEast, current)
				if southBlocked and eastBlocked and not isBlockedV(southEast) and isLitV(southEast):
					_lightEmit(southEast, current)
				if southBlocked and westBlocked and not isBlockedV(southWest) and isLitV(southWest):
					_lightEmit(southWest, current)
				if northBlocked and westBlocked and not isBlockedV(northWest) and isLitV(northWest):
					_lightEmit(northWest, current)

func _dark() -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			_setLight(x, y, _lightMin, false)

func _darken() -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			if _getLight(x, y) != _lightMin:
				_setLight(x, y, _lightExplored, false)

func isExploredV(p: Vector2) -> bool:
	return isExplored(int(p.x), int(p.y))

func isExplored(x: int, y: int) -> bool:
	return _getLight(x, y) == _lightExplored

func isLitV(p: Vector2) -> bool:
	return isLit(int(p.x), int(p.y))

func isLit(x: int, y: int) -> bool:
	return _getLight(x, y) > _lightExplored

func isWallId(id: int) -> bool:
	return (id == Tile.Theme0WallPlain or id == Tile.Theme0Wall or id == Tile.Theme0Torch or
		id == Tile.Theme1WallPlain or id == Tile.Theme1Wall or id == Tile.Theme1Torch or
		id == Tile.Theme2WallPlain or id == Tile.Theme2Wall or id == Tile.Theme2Torch or
		id == Tile.Theme3WallPlain or id == Tile.Theme3Wall or id == Tile.Theme3Torch)

func isWallV(p: Vector2) -> bool:
	return isWall(int(p.x), int(p.y))

func isWall(x: int, y: int) -> bool:
	return isWallId(_fore.get_cell(x, y))

func setWallPlain(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0WallPlain
		1: id = Tile.Theme1WallPlain
		2: id = Tile.Theme2WallPlain
		3: id = Tile.Theme3WallPlain
	_setRandomTile(_fore, x, y, id, flipX, flipY, rot90)

func setWall(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Wall
		1: id = Tile.Theme1Wall
		2: id = Tile.Theme2Wall
		3: id = Tile.Theme3Wall
	_setRandomTile(_fore, x, y, id, flipX, flipY, rot90)

func setRubble(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_fore, x, y, Tile.Rubble, flipX, flipY, rot90)

func isCliffId(id: int) -> bool:
	return id == Tile.Cliff0 or id == Tile.Cliff1

func isCliff(x: int, y: int) -> bool:
	return isCliffId(_back.get_cell(x, y))

func setCliff(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match themeCliff:
		0: id = Tile.Cliff0
		1: id = Tile.Cliff1
	_setRandomTile(_back, x, y, id, flipX, flipY, rot90)

func clearBackV(p: Vector2) -> void:
	clearBack(int(p.x), int(p.y))

func clearBack(x: int, y: int) -> void:
	_back.set_cell(x, y, TileMap.INVALID_CELL)

func clearForeV(p: Vector2) -> void:
	clearFore(int(p.x), int(p.y))

func clearFore(x: int, y: int) -> void:
	_fore.set_cell(x, y, TileMap.INVALID_CELL)

func setTorch(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Torch
		1: id = Tile.Theme1Torch
		2: id = Tile.Theme2Torch
		3: id = Tile.Theme3Torch
	_setRandomTile(_fore, x, y, id, flipX, flipY, rot90)

func isStairId(id: int) -> bool:
	return (id == Tile.Theme0Stair or id == Tile.Theme1Stair or
		id == Tile.Theme2Stair or id == Tile.Theme3Stair)

func isStairV(p: Vector2) -> bool:
	return isStair(int(p.x), int(p.y))

func isStair(x: int, y: int) -> bool:
	return isStairId(_fore.get_cell(x, y))

func isStairUpV(p: Vector2) -> bool:
	return isStairUp(int(p.x), int(p.y))

func isStairUp(x: int, y: int) -> bool:
	return isStair(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2(1, 0)

func isStairDownV(p: Vector2) -> bool:
	return isStairDown(int(p.x), int(p.y))

func isStairDown(x: int, y: int) -> bool:
	return isStair(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2(0, 0)

func setStairDown(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Stair
		1: id = Tile.Theme1Stair
		2: id = Tile.Theme2Stair
		3: id = Tile.Theme3Stair
	_fore.set_cell(x, y, id, flipX, flipY, rot90, Vector2(0, 0))

func setStairUp(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Stair
		1: id = Tile.Theme1Stair
		2: id = Tile.Theme2Stair
		3: id = Tile.Theme3Stair
	_fore.set_cell(x, y, id, flipX, flipY, rot90, Vector2(1, 0))

func isDoorId(id: int) -> bool:
	return (id == Tile.Theme0Door or id == Tile.Theme1Door or
		id == Tile.Theme2Door or id == Tile.Theme3Door)

func isDoorV(p: Vector2) -> bool:
	return isDoor(int(p.x), int(p.y))

func isDoor(x: int, y: int) -> bool:
	return isDoorId(_fore.get_cell(x, y))

func isDoorShutV(p: Vector2) -> bool:
	return isDoorShut(int(p.x), int(p.y))

func isDoorShut(x: int, y: int) -> bool:
	return isDoor(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2.ZERO

func isFloorId(id: int) -> bool:
	return (id == Tile.Theme0Floor or id == Tile.Theme0FloorRoom or
		id == Tile.Theme1Floor or id == Tile.Theme1FloorRoom or
		id == Tile.Theme2Floor or id == Tile.Theme2FloorRoom or
		id == Tile.Theme3Floor or id == Tile.Theme3FloorRoom)

func isFloor(x: int, y: int) -> bool:
	return isFloorId(_back.get_cell(x, y))

func setFloor(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Floor
		1: id = Tile.Theme1Floor
		2: id = Tile.Theme2Floor
		3: id = Tile.Theme3Floor
	_setRandomTile(_back, x, y, id, flipX, flipY, rot90)

func setFloorRoom(x: int, y: int, flipX := false, flipY := false, rot90 := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0FloorRoom
		1: id = Tile.Theme1FloorRoom
		2: id = Tile.Theme2FloorRoom
		3: id = Tile.Theme3FloorRoom
	_setRandomTile(_back, x, y, id, flipX, flipY, rot90)

func _getLight(x: int, y: int) -> int:
	return int(_light.get_cell_autotile_coord(x, y).x)

func _setLight(x: int, y: int, light: int, test: bool) -> void:
	if not test or light > _getLight(x, y):
		_light.set_cell(x, y, Tile.Light, false, false, false, Vector2(light, 0))

func insideMapV(p: Vector2) -> bool:
	return rect.has_point(p)

func insideMap(x: int, y: int) -> bool:
	return x >= rect.position.x and y >= rect.position.y and x < rect.size.x and y < rect.size.y

func getCameraRect() -> Rect2:
	return Rect2(_map(_camera.global_position), _map(_camera.global_position + _worldSize()))

const _alpha := 0.75
const _colorMob := Color(0, 1, 0, _alpha)
const _colorStair := Color(1, 1, 0, _alpha)
const _colorDoor := Color(0, 0, 1, _alpha)
const _colorWallLit := Color(0.8, 0.8, 0.8, _alpha)
const _colorWall := Color(0.6, 0.6, 0.6, _alpha)
const _colorFloorLit := Color(0.4, 0.4, 0.4, _alpha)
const _colorFloor := Color(0.2, 0.2, 0.2, _alpha)
const _colorCamera := Color(1, 0, 1, _alpha)

func getMapColor(x: int, y: int) -> Color:
	var camera = getCameraRect()
	var color = Color(0.25, 0.25, 0.25, 0.25)
	var lit = isLit(x, y)
	var explored = isExplored(x, y)
	var mob = mobPosition()
	if lit or explored:
		if x == mob.x and y == mob.y:
			color = _colorMob
		elif isStair(x, y):
			color = _colorStair
		elif isDoor(x, y):
			color = _colorDoor
		elif (((x >= camera.position.x and x <= camera.size.x) and
			(y == camera.position.y or y == camera.size.y)) or
			((y >= camera.position.y and y <= camera.size.y) and
			(x == camera.position.x or x == camera.size.x))):
			color = _colorCamera
		elif isWall(x, y):
			color = _colorWallLit if lit else _colorWall
		elif isFloor(x, y):
			color = _colorFloorLit if lit else _colorFloor
		else:
			color = _colorWallLit if lit else _colorWall
	return color

const _alphaPath := 0.333
const _colorPathMob := Color(_colorMob.r, _colorMob.g, _colorMob.b, _alphaPath)
const _colorPathStair := Color(_colorStair.r, _colorStair.g, _colorStair.b, _alphaPath)
const _colorPathDoor := Color(_colorDoor.r, _colorDoor.g, _colorDoor.b, _alphaPath)
const _colorPathWall := Color(_colorWall.r, _colorWall.g, _colorWall.b, _alphaPath)

func _getPathColor(x: int, y: int) -> Color:
	var color = Color(0.25, 0.25, 0.25, 0.25)
	if isStair(x, y):
		color = _colorPathStair
	elif isDoor(x, y):
		color = _colorPathDoor
	elif isWall(x, y):
		color = _colorPathWall
	elif isFloor(x, y):
		color = _colorPathMob
	return color

func clear() -> void:
	_back.clear()
	_fore.clear()
	_waterBack.clear()
	_waterFore.clear()
	_light.clear()
	_edge.clear()

func mobPosition() -> Vector2:
	return _map(_mob.global_position)

func targetPosition() -> Vector2:
	return _map(_target.global_position)

func verifyCliff() -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			if isCliff(x, y) and not isFloor(x, y - 1):
				clearBack(x, y)
