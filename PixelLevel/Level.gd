extends Viewport
class_name Level

onready var _tween:       Tween = $Tween
onready var _camera:   Camera2D = $Camera
onready var _back:      TileMap = $Back
onready var _fore:      TileMap = $Fore
onready var _flower:    TileMap = $Flower
onready var _waterBack: TileMap = $WaterBack
onready var _splitBack: TileMap = $SplitBack
onready var _itemBack:  TileMap = $ItemBack
onready var _tree:      TileMap = $Tree
onready var _path:       Node2D = $Path
onready var _mob:        Node2D = $Mob
onready var _itemFore:  TileMap = $ItemFore
onready var _splitFore: TileMap = $SplitFore
onready var _waterFore: TileMap = $WaterFore
onready var _top:       TileMap = $Top
onready var _light:     TileMap = $Light
onready var _edge:      TileMap = $Edge
onready var _target:     Node2D = $Target
onready var _astar:             = AStar2D.new()
onready var _tileSet:           = _back.tile_set
var rect := Rect2()
var _oldSize = Vector2.ZERO
var _pathPoints := PoolVector2Array()
var _dragLeft := false
var _dragged := false
var _turn := false
var _time := 0.0
var _turnTotal := 0
var _timeTotal := 0.0
const _turnTime := 0.22
const _duration := 0.333
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02
const _pathScene := preload("res://PixelLevel/Path.tscn")
var startAt := Vector2(4, 4)
var theme := 0
var day := true
var desert := false
const themeCount := 4
var themeCliff := 0
const themeCliffCount := 2

var state := {
	"depth": 0
}

signal updateMap
signal generate
signal generateUp
signal regenerate

enum Tile { # match id in tileSet
	Cliff0, Cliff1
	Banner0, Banner1,
	Furnature, Carpet,
	Fountain, Chest, ChestOpenFull, ChestOpenEmpty, ChestBroke, Loot
	TreeStump, TreeBack, TreeFore,
	EdgeInside,	EdgeInsideCorner,
	EdgeOutsideCorner, EdgeOutside,
	Light,
	Theme0Torch, Theme0WallPlain, Theme0Wall, Theme0Floor, Theme0FloorRoom, Theme0Stair, Theme0Door,
	Theme1Torch, Theme1WallPlain, Theme1Wall, Theme1Floor, Theme1FloorRoom, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2WallPlain, Theme2Wall, Theme2Floor, Theme2FloorRoom, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3WallPlain, Theme3Wall, Theme3Floor, Theme3FloorRoom, Theme3Stair, Theme3Door,
	WaterShallowBack, WaterShallowFore,
	WaterDeepBack, WaterDeepFore,
	WaterShallowBackPurple, WaterShallowForePurple,
	WaterDeepBackPurple, WaterDeepForePurple,
	Rubble,
	OutsideDay, OutsideDayPillar, OutsideDayRubble, OutsideDayStair, OutsideFlower,
	OutsideDayDesert, OutsideDayDoodad, OutsideDayGrassDry, OutsideDayDesertStair, OutsideDayGrassGreen,
	OutsideDayHedge, OutsideDayWall, OutsideDayFloor
	OutsideNight, OutsideNightPillar, OutsideNightRubble, OutsideNightStair,
	OutsideNightDesert, OutsideNightDoodad, OutsideNightGrassDry, OutsideNightDesertStair, OutsideNightGrassGreen,
	OutsideBightHedge, OutsideNightWall, OutsideNightFloor
}

const _floorTiles := [Tile.Theme0Floor, Tile.Theme0FloorRoom,
	Tile.Theme1Floor, Tile.Theme1FloorRoom,
	Tile.Theme2Floor, Tile.Theme2FloorRoom,
	Tile.Theme3Floor, Tile.Theme3FloorRoom,
	Tile.OutsideDay, Tile.OutsideNight,
	Tile.OutsideDayDesert, Tile.OutsideNightDesert,
	Tile.OutsideDayFloor, Tile.OutsideNightFloor,
	Tile.Rubble, Tile.OutsideDayRubble, Tile.OutsideNightRubble]

const _wallTiles := [Tile.Theme0WallPlain, Tile.Theme0Wall, Tile.Theme0Torch,
	Tile.Theme1WallPlain, Tile.Theme1Wall, Tile.Theme1Torch,
	Tile.Theme2WallPlain, Tile.Theme2Wall, Tile.Theme2Torch,
	Tile.Theme3WallPlain, Tile.Theme3Wall, Tile.Theme3Torch,
	Tile.OutsideDayWall, Tile.OutsideNightWall,
	Tile.OutsideDayHedge, Tile.OutsideBightHedge]

const _cliffTiles := [Tile.Cliff0, Tile.Cliff1]

const _stairTiles := [Tile.Theme0Stair, Tile.Theme1Stair,
	Tile.Theme2Stair, Tile.Theme3Stair,
	Tile.OutsideDayStair, Tile.OutsideNightStair,
	Tile.OutsideDayDesertStair, Tile.OutsideNightDesertStair]

const _doorTiles := [Tile.Theme0Door, Tile.Theme1Door,
	Tile.Theme2Door, Tile.Theme3Door]

const _waterTiles := [Tile.WaterShallowFore, Tile.WaterShallowBack,
	Tile.WaterDeepFore, Tile.WaterDeepBack,
	Tile.WaterShallowForePurple, Tile.WaterShallowBackPurple,
	Tile.WaterDeepForePurple, Tile.WaterDeepBackPurple]

const _waterDeepTiles := [Tile.WaterDeepFore, Tile.WaterDeepBack,
	Tile.WaterDeepForePurple, Tile.WaterDeepBackPurple]

const _waterPurpleTiles := [Tile.WaterShallowForePurple, Tile.WaterShallowBackPurple,
	Tile.WaterDeepForePurple, Tile.WaterDeepBackPurple]

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
	_target.modulate = Color.transparent
	_checkCenter()
	_dark()
	_findTorches()
	_lightUpdate(mobPosition(), lightRadius)
	_cameraUpdate()
	verifyCliff()

func _process(delta: float) -> void:
	_time += delta
	if _time > _turnTime and (_turn or _processWasd()):
		_timeTotal += _time
		_turnTotal += 1
		var test = _turn
		_turn = false
		if test:
			if not _handleDoor():
				_move(_mob)
			if not _handleStair():
				_lightUpdate(mobPosition(), lightRadius)
				_checkCenter()
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

func up() -> void:
	emit_signal("generateUp")

func down() -> void:
	emit_signal("generate")

func regen() -> void:
	emit_signal("regenerate")

func _handleDoor() -> bool:
	var from := mobPosition()
	var to := targetPosition()
	if from.distance_to(to) < 2.0:
		if isDoorV(to):
			_toggleDoorV(to)
			_astar.set_point_disabled(_tileIndex(to), isDoorShutV(to))
			return true
	return false

func _toggleDoorV(p: Vector2) -> void: _toggleDoor(int(p.x), int(p.y))

const _doorBreakChance = 0.02

func _toggleDoor(x: int, y: int) -> void:
	var door := _fore.get_cell_autotile_coord(x, y)
	var broke = Random.nextFloat() <= _doorBreakChance
	_fore.set_cell(x, y, _fore.get_cell(x, y), false, false, false, Vector2(2 if broke else 0 if door.x == 1 else 1, 0))

func _face(mob: Node2D, direction: Vector2) -> void:
	if direction.x > 0:
		mob.scale = Vector2(-1, 1)
	else:
		mob.scale = Vector2(1, 1)

func _step(mob: Node2D, direction: Vector2) -> void:
	# TODO: play walk animation and interpolate global_position
	mob.global_position += _world(direction)

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
				_dragLeft = true
				_dragged = false
			else:
				if _dragged:
					_cameraUpdate()
				else:
					_targetTo(event.global_position)
					_targetUpdate()
				_dragLeft = false
		elif event.button_index == BUTTON_WHEEL_UP:
			_zoomIn(event.global_position)
			_cameraUpdate()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
			_cameraUpdate()
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_dragged = true
			_cameraTo(_camera.global_position - event.relative * _camera.zoom)
			emit_signal("updateMap")

func _processWasd() -> bool:
	var done := false
	if Input.is_action_pressed("ui_up"):
		_wasd(Vector2.UP)
		done = true
	if Input.is_action_pressed("ui_ne"):
		_wasd(Vector2.UP + Vector2.RIGHT)
		done = true
	if Input.is_action_pressed("ui_right"):
		_wasd(Vector2.RIGHT)
		done = true
	if Input.is_action_pressed("ui_se"):
		_wasd(Vector2.DOWN + Vector2.RIGHT)
		done = true
	if Input.is_action_pressed("ui_down"):
		_wasd(Vector2.DOWN)
		done = true
	if Input.is_action_pressed("ui_sw"):
		_wasd(Vector2.DOWN + Vector2.LEFT)
		done = true
	if Input.is_action_pressed("ui_left"):
		_wasd(Vector2.LEFT)
		done = true
	if Input.is_action_pressed("ui_nw"):
		_wasd(Vector2.UP + Vector2.LEFT)
		done = true
	return done

func _wasd(direction: Vector2) -> void:
	var p := mobPosition() + direction
	if isDoorShutV(p):
		_toggleDoorV(p)
	if not isBlockedV(p):
		_face(_mob, direction)
		_step(_mob, direction)
		_pathClear()
		if not isStairDownV(p):
			_lightUpdate(p, lightRadius)
			_checkCenter()
		else:
			emit_signal("generate")

func _tileIndex(p: Vector2) -> int:
	return Utility.indexV(p, int(rect.size.x))

func _tilePosition(i: int) -> Vector2:
	return Utility.position(i, int(rect.size.x))

func insideMapV(p: Vector2) -> bool: return rect.has_point(p)

func insideMap(x: int, y: int) -> bool:
	return x >= rect.position.x and y >= rect.position.y and x < rect.size.x and y < rect.size.y

func getCameraRect() -> Rect2:
	return Rect2(_map(_camera.global_position), _map(_camera.global_position + _worldSize()))

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
	else:
		emit_signal("updateMap")

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
	else:
		emit_signal("updateMap")

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

# Path

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

# Target

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

func isBlockedV(p: Vector2) -> bool: return isBlocked(int(p.x), int(p.y))

func isBlocked(x: int, y: int) -> bool:
	if not insideMap(x, y): return true
	var fore := _fore.get_cell(x, y)
	var back := _back.get_cell(x, y)
	return _cliffTiles.has(fore) or ((fore == TileMap.INVALID_CELL) and not _floorTiles.has(back)) or isBlockedLight(x, y)

func isBlockedLight(x: int, y: int) -> bool:
	if not insideMap(x, y): return true
	var fore := _fore.get_cell(x, y)
	var w := _wallTiles.has(fore)
	var d := _doorTiles.has(fore)
	var s := _fore.get_cell_autotile_coord(x, y)
	return w or (d and s == Vector2(0, 0))

# Light

const _torchRadius := 8
const _torchRadiusMax := _torchRadius * 2
var lightRadius := 16
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

func lightToggle() -> void:
	_light.visible = not _light.visible

func lightIncrease() -> void:
	lightRadius += 1
	_lightUpdate(mobPosition(), lightRadius)

func lightDecrease() -> void:
	lightRadius -= 1
	_lightUpdate(mobPosition(), lightRadius)

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
				var blockedAt := isBlockedLight(x, y)
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
		_torches[p] = clamp(_torches[p] + Random.nextRange(-1, 1), 2, _torchRadiusMax)
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

# Map

const _alpha := 0.8
const _colorMob := Color(0, 1, 0, _alpha)
const _colorStair := Color(1, 1, 0, _alpha)
const _colorDoor := Color(0, 0, 1, _alpha)
const _colorWallLit := Color(1, 1, 1, _alpha)
const _colorWall := Color(0.8, 0.8, 0.8, _alpha)
const _colorFloorLit := Color(0.4, 0.4, 0.4, _alpha)
const _colorFloor := Color(0.2, 0.2, 0.2, _alpha)
const _colorCamera := Color(1, 0, 1, _alpha)

func getMapColor(x: int, y: int) -> Color:
	var camera = getCameraRect()
	var color = Color(0.25, 0.25, 0.25, 0.25)
	var on = _isRect(x, y, camera)
	if on:
		color = _colorCamera
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
		elif on:
			color = _colorCamera
		elif isWall(x, y):
			color = _colorWallLit if lit else _colorWall
		elif isFloor(x, y):
			color = _colorFloorLit if lit else _colorFloor
		else:
			color = _colorWallLit if lit else _colorWall
	return color

func _isRect(x, y, r) -> bool:
	return (((x >= r.position.x and x <= r.size.x) and
		(y == r.position.y or y == r.size.y)) or
		((y >= r.position.y and y <= r.size.y) and
		(x == r.position.x or x == r.size.x)))

const _alphaPath := 0.333
const _colorPathMob := Color(_colorMob.r, _colorMob.g, _colorMob.b, _alphaPath)
const _colorPathStair := Color(_colorStair.r, _colorStair.g, _colorStair.b, _alphaPath)
const _colorPathDoor := Color(_colorDoor.r, _colorDoor.g, _colorDoor.b, _alphaPath)
const _colorPathWall := Color(_colorWall.r, _colorWall.g, _colorWall.b, _alphaPath)

func _getPathColor(x: int, y: int) -> Color:
	var color = _colorPathWall
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
	_flower.clear()
	_waterBack.clear()
	_splitBack.clear()
	_itemBack.clear()
	_tree.clear()
	_itemFore.clear()
	_splitFore.clear()
	_waterFore.clear()
	_top.clear()
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
				clearFore(x, y)

# Tile

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

func isTileId(tile: int, tiles: Array) -> bool:
	for id in tiles:
		if tile == id:
			return true
	return false

## Back

func _setBack(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_back.set_cell(x, y, tile, flipX, flipY, rot90, coord)

func _setBackRandom(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_back, x, y, tile, flipX, flipY, rot90)

func setFloorV(p: Vector2) -> void:	setFloor(int(p.x), int(p.y))

func setFloor(x: int, y: int, wonky := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Floor
		1: id = Tile.Theme1Floor
		2: id = Tile.Theme2Floor
		3: id = Tile.Theme3Floor
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(x, y, id, flipX, flipY, rot90)

func setFloorRoomV(p: Vector2) -> void:	setFloorRoom(int(p.x), int(p.y))

func setFloorRoom(x: int, y: int, wonky := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0FloorRoom
		1: id = Tile.Theme1FloorRoom
		2: id = Tile.Theme2FloorRoom
		3: id = Tile.Theme3FloorRoom
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(x, y, id, flipX, flipY, rot90)

func setOutside(x: int, y: int) -> void:
	if desert:
		_setBackRandom(x, y, Tile.OutsideDayDesert if day else Tile.OutsideNightDesert)
	else:
		_setBackRandom(x, y, Tile.OutsideDay if day else Tile.OutsideNight, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideFloor(x: int, y: int, wonky := false) -> void:
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(x, y, Tile.OutsideDayFloor if day else Tile.OutsideNightFloor, flipX, flipY, rot90)

func _isBackTile(x: int, y: int, tiles: Array) -> bool:
	return isTileId(_back.get_cell(x, y), tiles)

func isFloorV(p: Vector2) -> bool: return isFloor(int(p.x), int(p.y))

func isFloor(x: int, y: int) -> bool:
	return _isBackTile(x, y, _floorTiles)

func clearBackV(p: Vector2) -> void: clearBack(int(p.x), int(p.y))

func clearBack(x: int, y: int) -> void:
	_setBack(x, y, TileMap.INVALID_CELL)

func isBackInvalidV(p: Vector2) -> bool: return isBackInvalid(int(p.x), int(p.y))

func isBackInvalid(x: int, y: int) -> bool:
	return _back.get_cell(x, y) == TileMap.INVALID_CELL

## Fore

func _setFore(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_fore.set_cell(x, y, tile, flipX, flipY, rot90, coord)

func _setForeRandom(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_fore, x, y, tile, flipX, flipY, rot90)

func setWallPlainV(p: Vector2) -> void: setWallPlain(int(p.x), int(p.y))

func setWallPlain(x: int, y: int) -> void:
	var id
	match theme:
		0: id = Tile.Theme0WallPlain
		1: id = Tile.Theme1WallPlain
		2: id = Tile.Theme2WallPlain
		3: id = Tile.Theme3WallPlain
	_setForeRandom(x, y, id, Random.nextBool())

func setWallV(p: Vector2) -> void: setWall(int(p.x), int(p.y))

func setWall(x: int, y: int) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Wall
		1: id = Tile.Theme1Wall
		2: id = Tile.Theme2Wall
		3: id = Tile.Theme3Wall
	_setForeRandom(x, y, id, Random.nextBool())

func setTorchV(p: Vector2) -> void: setTorch(int(p.x), int(p.y))

func setTorch(x: int, y: int) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Torch
		1: id = Tile.Theme1Torch
		2: id = Tile.Theme2Torch
		3: id = Tile.Theme3Torch
	_setForeRandom(x, y, id, Random.nextBool())

func setRubbleV(p: Vector2) -> void: setRubble(int(p.x), int(p.y))

func setRubble(x: int, y: int) -> void:
	_setRandomTile(_back, x, y, Tile.Rubble, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideRubble(x: int, y: int) -> void:
	_setRandomTile(_back, x, y, Tile.OutsideDayRubble if day else Tile.OutsideNightRubble, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideWall(x: int, y: int) -> void:
	_setRandomTile(_fore, x, y, Tile.OutsideDayWall if day else Tile.OutsideNightWall, Random.nextBool())

func setOutsideHedge(x: int, y: int) -> void:
	_setRandomTile(_fore, x, y, Tile.OutsideDayHedge if day else Tile.OutsideNightHedge, Random.nextBool())

func setCliff(x: int, y: int) -> void:
	var id
	match themeCliff:
		0: id = Tile.Cliff0
		1: id = Tile.Cliff1
	_setForeRandom(x, y, id, Random.nextBool())

func _setStair(x: int, y: int, coord: Vector2) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Stair
		1: id = Tile.Theme1Stair
		2: id = Tile.Theme2Stair
		3: id = Tile.Theme3Stair
	_setFore(x, y, id, Random.nextBool(), false, false, coord)

func setStairDownV(p: Vector2) -> void: setStairDown(int(p.x), int(p.y))

func setStairDown(x: int, y: int) -> void:
	_setStair(x, y, Vector2(0, 0))

func setStairUpV(p: Vector2) -> void: setStairUp(int(p.x), int(p.y))

func setStairUp(x: int, y: int) -> void:
	_setStair(x, y, Vector2(1, 0))

func _setStairOutside(x: int, y: int, coord: Vector2) -> void:
	if desert:
		_setFore(x, y, Tile.OutsideDayDesertStair if day else Tile.OutsideNightDesertStair, Random.nextBool(), false, false, coord)
	else:
		_setFore(x, y, Tile.OutsideDayStair if day else Tile.OutsideNightStair, Random.nextBool(), false, false, coord)

func setStairOutsideUp(x: int, y: int) -> void:
	_setStairOutside(x, y, Vector2(0, 0))

func setStairOutsideDown(x: int, y: int) -> void:
	_setStairOutside(x, y, Vector2(1, 0))

func setDoorV(p: Vector2) -> void: setDoor(int(p.x), int(p.y))

func setDoor(x: int, y: int) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Door
		1: id = Tile.Theme1Door
		2: id = Tile.Theme2Door
		3: id = Tile.Theme3Door
	_setRandomTile(_fore, x, y, id, Random.nextBool())

func setDoorBrokeV(p: Vector2) -> void: setDoorBroke(int(p.x), int(p.y))

func setDoorBroke(x: int, y: int) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Door
		1: id = Tile.Theme1Door
		2: id = Tile.Theme2Door
		3: id = Tile.Theme3Door
	_setFore(x, y, id, Random.nextBool(), false, false, Vector2(2, 0))

func setFountainV(p: Vector2) -> void: setFountain(int(p.x), int(p.y))

func setFountain(x: int, y: int) -> void:
	_setForeRandom(x, y, Tile.Fountain, Random.nextBool())

func setBanner0V(p: Vector2) -> void: setBanner0(int(p.x), int(p.y))

func setBanner0(x: int, y: int) -> void:
	_setForeRandom(x, y, Tile.Banner0, Random.nextBool())

func setBanner1V(p: Vector2) -> void: setBanner1(int(p.x), int(p.y))

func setBanner1(x: int, y: int) -> void:
	_setForeRandom(x, y, Tile.Banner1, Random.nextBool())

func setLootV(p: Vector2) -> void: setLoot(int(p.x), int(p.y))

func setLoot(x: int, y: int) -> void:
	var id
	match Random.next(4):
		0: id = Tile.Chest
		1: id = Tile.ChestBroke
		2: id = Tile.ChestOpenEmpty
		3: id = Tile.ChestOpenFull
	_setItemBackRandom(x, y, id, Random.nextBool())
	if Random.nextBool():
		_setItemFore(x, y, Tile.Loot)

func _isForeTile(x: int, y: int, tiles: Array) -> bool:
	return isTileId(_fore.get_cell(x, y), tiles)

func isWallV(p: Vector2) -> bool: return isWall(int(p.x), int(p.y))

func isWall(x: int, y: int) -> bool:
	return _isForeTile(x, y, _wallTiles)

func isCliffV(p: Vector2) -> bool: return isCliff(int(p.x), int(p.y))

func isCliff(x: int, y: int) -> bool:
	return _isForeTile(x, y, _cliffTiles)

func isStairV(p: Vector2) -> bool: return isStair(int(p.x), int(p.y))

func isStair(x: int, y: int) -> bool:
	return _isForeTile(x, y, _stairTiles)

func isStairUpV(p: Vector2) -> bool: return isStairUp(int(p.x), int(p.y))

func isStairUp(x: int, y: int) -> bool:
	return isStair(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2(1, 0)

func isStairDownV(p: Vector2) -> bool: return isStairDown(int(p.x), int(p.y))

func isStairDown(x: int, y: int) -> bool:
	return isStair(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2(0, 0)

func isDoorV(p: Vector2) -> bool: return isDoor(int(p.x), int(p.y))

func isDoor(x: int, y: int) -> bool:
	return _isForeTile(x, y, _doorTiles)

func isDoorShutV(p: Vector2) -> bool: return isDoorShut(int(p.x), int(p.y))

func isDoorShut(x: int, y: int) -> bool:
	return isDoor(x, y) and _fore.get_cell_autotile_coord(x, y) == Vector2(0, 0)

func clearForeV(p: Vector2) -> void: clearFore(int(p.x), int(p.y))

func clearFore(x: int, y: int) -> void:
	_setFore(x, y, TileMap.INVALID_CELL)

func isForeInvalidV(p: Vector2) -> bool: return isForeInvalid(int(p.x), int(p.y))

func isForeInvalid(x: int, y: int) -> bool:
	return _fore.get_cell(x, y) == TileMap.INVALID_CELL

## Flower

func setFlower(x: int, y: int) -> void:
	_setRandomTile(_flower, x, y, Tile.OutsideFlower, Random.nextBool())

## Tree

func setTree(x: int, y: int) -> void:
	var p := Vector2(Random.next(3), 0)
	_tree.set_cell(x, y, Tile.TreeBack, false, false, false, p)
	_top.set_cell(x, y - 1, Tile.TreeFore, false, false, false, p)

func setTreeStump(x: int, y: int) -> void:
	_setRandomTile(_tree, x, y, Tile.TreeStump, Random.nextBool())

func clearTree(x: int, y: int) -> void:
	_tree.set_cell(x, y, TileMap.INVALID_CELL)
	_top.set_cell(x, y - 1, TileMap.INVALID_CELL)

func cutTreeV(p: Vector2) -> void: cutTree(int(p.x), int(p.y))

func cutTree(x: int, y: int) -> void:
	clearTree(x, y)
	setTreeStump(x, y)

## Water

func setWaterShallowV(p: Vector2) -> void: setWaterShallow(int(p.x), int(p.y))

func setWaterShallow(x: int, y: int) -> void:
	_waterBack.set_cell(x, y, Tile.WaterShallowBack)
	_waterFore.set_cell(x, y, Tile.WaterShallowFore)

func setWaterDeepV(p: Vector2) -> void: setWaterDeep(int(p.x), int(p.y))

func setWaterDeep(x: int, y: int) -> void:
	_waterBack.set_cell(x, y, Tile.WaterDeepBack)
	_waterFore.set_cell(x, y, Tile.WaterDeepFore)

func setWaterShallowPurpleV(p: Vector2) -> void: setWaterShallowPurple(int(p.x), int(p.y))

func setWaterShallowPurple(x: int, y: int) -> void:
	_waterBack.set_cell(x, y, Tile.WaterShallowBackPurple)
	_waterFore.set_cell(x, y, Tile.WaterShallowForePurple)

func setWaterDeepPurpleV(p: Vector2) -> void: setWaterDeepPurple(int(p.x), int(p.y))

func setWaterDeepPurple(x: int, y: int) -> void:
	_waterBack.set_cell(x, y, Tile.WaterDeepBackPurple)
	_waterFore.set_cell(x, y, Tile.WaterDeepForePurple)

func _isWaterTile(x: int, y: int, tiles: Array) -> bool:
	return isTileId(_waterBack.get_cell(x, y), tiles)

func isWater(x: int, y: int) -> bool:
	return _isWaterTile(x, y, _waterTiles)

func isWaterDeep(x: int, y: int) -> bool:
	return _isWaterTile(x, y, _waterDeepTiles)

func isWaterPurple(x: int, y: int) -> bool:
	return _isWaterTile(x, y, _waterPurpleTiles)

## Item

func _setItemFore(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_itemFore.set_cell(x, y, tile, flipX, flipY, rot90, coord)

func _setItemForeRandom(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_itemFore, x, y, tile, flipX, flipY, rot90)

func _setItemBack(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_itemBack.set_cell(x, y, tile, flipX, flipY, rot90, coord)

func _setItemBackRandom(x: int, y: int, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_itemBack, x, y, tile, flipX, flipY, rot90)

## Split

func setGrass(x: int, y: int) -> void:
	var flipX = Random.nextBool()
	if desert:
		_splitBack.set_cell(x, y, Tile.OutsideDayGrassDry if day else Tile.OutsideNightGrassDry, flipX, false, false, Vector2(0, 0))
		_splitFore.set_cell(x, y, Tile.OutsideDayGrassDry if day else Tile.OutsideNightGrassDry, flipX, false, false, Vector2(1, 0))
	else:
		_splitBack.set_cell(x, y, Tile.OutsideDayGrassGreen if day else Tile.OutsideNightGrassGreen, flipX, false, false, Vector2(0, 0))
		_splitFore.set_cell(x, y, Tile.OutsideDayGrassGreen if day else Tile.OutsideNightGrassGreen, flipX, false, false, Vector2(1, 0))

## Light

func _getLight(x: int, y: int) -> int:
	return int(_light.get_cell_autotile_coord(x, y).x)

func _setLight(x: int, y: int, light: int, test: bool) -> void:
	if not test or light > _getLight(x, y):
		_light.set_cell(x, y, Tile.Light, false, false, false, Vector2(light, 0))

func isExploredV(p: Vector2) -> bool: return isExplored(int(p.x), int(p.y))

func isExplored(x: int, y: int) -> bool:
	return _getLight(x, y) == _lightExplored

func isLitV(p: Vector2) -> bool: return isLit(int(p.x), int(p.y))

func isLit(x: int, y: int) -> bool:
	return _getLight(x, y) > _lightExplored

## Edge

func _drawEdge() -> void:
	var minY := rect.position.y - 1
	var maxY := rect.end.y
	var minX := rect.position.x - 1
	var maxX := rect.end.x
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
