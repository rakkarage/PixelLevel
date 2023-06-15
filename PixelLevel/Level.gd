extends LevelBase

#region Variable

@onready var _hero: Node2D = $Hero
@onready var _target: Node2D = $Target
@onready var _tileMapEdge: TileMap = $TileMapEdge

signal generate
signal generateUp

const _pathScene := preload("res://Interface/Path.tscn")
const Directions: Array[Vector2i] = [Vector2i.UP, Vector2i.UP + Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT + Vector2i.DOWN,
	Vector2i.DOWN, Vector2i.DOWN + Vector2i.LEFT, Vector2i.LEFT, Vector2i.LEFT + Vector2i.UP]
const _edge := Vector2i(2, 2)
const _turnTime := 0.22
const _minPathAlpha := 0.1
const _maxPathAlpha := 0.75

var _astar: AStar2D = AStar2D.new()
var _pathPoints := PackedVector2Array()
var _turn := false
var _time := 0.0
var startAt := Vector2i(4, 4)
var _tweenStep : Tween
var _sources: Array[TileSetSource]

var _theme := 0 # dungeon _theme
var _day := true # _day or night outside _theme
var _desert := false # _desert or grass outside _theme
const _themeCount := 4 # number of dungeon themes
var _themeCliff := 0 # cliff _theme
const _themeCliffCount := 2 # number of cliff themes

var _state := { "depth": 0, "time": 0.0, "turns": 0 }

#endregion

#region Tile Data

enum Direction { N, NE, E, SE, S, SW, W, NW }

# matches tileMap layers
enum Layer {
	Back,
	Fore,
	Flower,
	WaterBack, SplitBack, ItemBack,
	Tree,
	ItemFore, SplitFore, WaterFore,
	Top,
	Light }

# matches tileSet source id
enum Tile {
	Invalid = -1,
	Cliff1, Cliff2,	Banner1, Banner2, Doodad, Rug, Fountain, Loot,
	EdgeInside, EdgeInsideCorner, EdgeOutsideCorner, EdgeOutside,
	Light, LightDebug,
	DayGrass, DayPillar, DayPath, DayStair, DayDesert, DayDoodad,
	DayWeed, DayHedge, DayWall, DayFloor,
	NightGrass, NightPillar, NightPath, NightStair, NightDesert, NightDoodad,
	NightWeed, NightHedge, NightWall, NightFloor,
	Tree, TreeStump, Flower, Rubble,
	Theme1Torch, Theme1WallPlain, Theme1Wall, Theme1Floor, Theme1FloorRoom, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2WallPlain, Theme2Wall, Theme2Floor, Theme2FloorRoom, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3WallPlain, Theme3Wall, Theme3Floor, Theme3FloorRoom, Theme3Stair, Theme3Door,
	Theme4Torch, Theme4WallPlain, Theme4Wall, Theme4Floor, Theme4FloorRoom, Theme4Stair, Theme4Door,
	WaterShallowBack, WaterShallowFore, WaterDeepBack, WaterDeepFore,
	WaterShallowPurpleBack, WaterShallowPurpleFore, WaterDeepPurpleBack, WaterDeepPurpleFore }

# used for testing if a tile is a certain type
const _floorTiles := [
	Tile.Theme1Floor, Tile.Theme2Floor, Tile.Theme3Floor, Tile.Theme4Floor,
	Tile.Theme1FloorRoom, Tile.Theme2FloorRoom, Tile.Theme3FloorRoom, Tile.Theme4FloorRoom,
	Tile.DayGrass, Tile.NightGrass, Tile.DayPath, Tile.NightPath,
	Tile.DayDesert, Tile.NightDesert, Tile.DayFloor, Tile.NightFloor, Tile.Rubble ]
const _wallTiles := [
	Tile.Theme1Torch, Tile.Theme1Wall, Tile.Theme1WallPlain, Tile.Theme2Torch, Tile.Theme2Wall, Tile.Theme2WallPlain,
	Tile.Theme3Torch, Tile.Theme3Wall, Tile.Theme3WallPlain, Tile.Theme4Torch, Tile.Theme4Wall, Tile.Theme4WallPlain,
	Tile.DayWall, Tile.NightWall, Tile.DayHedge, Tile.NightHedge ]
const _cliffTiles := [Tile.Cliff1, Tile.Cliff2]
const _stairTiles := [Tile.Theme1Stair, Tile.Theme2Stair, Tile.Theme3Stair, Tile.Theme4Stair, Tile.DayStair, Tile.NightStair]
const _doorTiles := [Tile.Theme1Door, Tile.Theme2Door, Tile.Theme3Door, Tile.Theme4Door]
const _waterTiles := [Tile.WaterShallowBack, Tile.WaterShallowFore, Tile.WaterDeepBack, Tile.WaterDeepFore,
	Tile.WaterShallowPurpleBack, Tile.WaterShallowPurpleFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]
const _waterDeepTiles := [Tile.WaterDeepBack, Tile.WaterDeepFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]
const _waterPurpleTiles := [Tile.WaterShallowPurpleBack, Tile.WaterShallowPurpleFore, Tile.WaterDeepPurpleBack, Tile.WaterDeepPurpleFore]

# atlas coords
enum Door { Shut, Open, Broke }
enum Stair { Down, Up}
enum Loot { ChestShut, ChestOpenFull, ChestOpenEmpty, ChestBroke, Pile }
enum Weed { BackDry, Back, ForeDry, Fore }
enum EdgeOutsideCorner { TopRight, TopLeft, BottomLeft, BottomRight }

# alternatives
enum Edge { Top, TopFlip, Bottom, Left, Right, LeftFlip, BottomFlip, RightFlip }
enum EdgeInsideCorner { TopLeft, TopRight, BottomLeft, TopLeftFlip, TopRightFlip, BottomLeftFlip, BottomRight, BottomRightFlip }

#endregion

#region Init / Input

func _ready() -> void: call_deferred("_readyDeferred")

func _readyDeferred() -> void:
	super._readyDeferred()
	_cacheSources()
	for i in 10:
		setWall(Vector2i(i, 9))
	setBanner0(startAt) if Random.nextBool() else setBanner1(startAt)
	setWaterShallow(Vector2i(7, 7))
	setWaterDeep(Vector2i(8, 7))
	setWaterShallow(Vector2i(9, 7))
	setWaterShallowPurple(Vector2i(7, 8))
	setWaterDeepPurple(Vector2i(8, 8))
	setWaterShallowPurple(Vector2i(9, 8))
	generated()

func generated() -> void:
	_drawEdge()
	_hero.global_position = mapToLocal(startAt)
	_pathClear()
	_target.modulate = Color.TRANSPARENT
	_target.z_index = 13
	_cameraToHero()
	_dark()
	_findTorches()
	_lightUpdate(_heroPosition(), lightRadius)
	verifyCliff()
	_addPoints()
	_connect()

func _cacheSources() -> void:
	for i in _tileMap.tile_set.get_source_count():
		_sources.append(_tileMap.tile_set.get_source(i))

func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	_state.time += _time
	if _time > _turnTime and (_turn or _processWasd()):
		_state.turns += 1
		var test := _turn
		_turn = false
		if test:
			if not _handleDoor():
				await _move(_hero)
			if not _handleStair():
				_lightUpdate(_heroPosition(), lightRadius)
				_checkCenter()
		_time = 0.0

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_turn = false
			if not event.pressed && not _panning:
				var turn = not _tweenStep or not _tweenStep.is_running()
				_targetTo(globalToMap(event.global_position), turn)

func clear() -> void:
	super.clear()
	_tileMapEdge.clear()

func _checkCenter() -> void:
	constrainTileToCamera(_heroPosition())

func _processWasd() -> bool:
	var done := false
	if Input.is_action_pressed("ui_up"):
		_wasd(Vector2i.UP)
		done = true
	if Input.is_action_pressed("ui_right"):
		_wasd(Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_down"):
		_wasd(Vector2i.DOWN)
		done = true
	if Input.is_action_pressed("ui_left"):
		_wasd(Vector2i.LEFT)
		done = true
	return done

func _wasd(direction: Vector2i) -> void:
	var p := _heroPosition() + direction
	if isDoorShut(p):
		_toggleDoor(p)
	if not isBlocked(p):
		_face(_hero, direction)
		await _step(_hero, direction)
		_pathClear()
		if not isStair(p):
			_lightUpdate(p, lightRadius)
			_checkCenter()
		else:
			if isStairDown(p):
				generate.emit()
			elif isStairUp(p):
				generateUp.emit()

#endregion

#region Map

func _move(mob: Node2D) -> void:
	await get_tree().process_frame
	if _pathPoints.size() > 1:
		var delta := _delta(_pathPoints[0], _pathPoints[1])
		_face(mob, delta)
		_fadeAndFree()
		await _step(mob, delta)

func _fadeAndFree() -> void:
	_pathPoints.remove_at(0)
	var node := _tileMap.get_child(0)
	await create_tween().tween_property(node, "modulate", Color.TRANSPARENT, _turnTime).finished
	node.queue_free()
	if _pathPoints.size() > 1:
		_turn = true
	else:
		_pathClear()

func _handleStair() -> bool:
	if _pathPoints.size() == 1:
		var p := _heroPosition()
		if isStairDown(p):
			_state.depth += 1
			generate.emit()
			return true
		elif isStairUp(p):
			_state.depth -= 1
			generateUp.emit()
			return true
	return false

func _handleDoor() -> bool:
	var from := _heroPosition()
	var to := _targetPosition()
	if (from - to).length() < 2.0:
		if isDoor(to):
			_toggleDoor(to)
			_astar.set_point_disabled(tileIndex(to), isDoorShut(to))
			return true
	return false

const _doorBreakChance = 0.02

func _toggleDoor(p: Vector2i) -> void:
	if not isDoor(p): return
	var door = _tileMap.get_cell_atlas_coords(Layer.Fore, p).x
	if door != Door.Broke:
		var broke := Random.nextFloat() <= _doorBreakChance
		setDoor(p, Door.Broke if broke else Door.Shut if door == Door.Open else Door.Open)

func _face(mob: Node2D, direction: Vector2i) -> void:
	if direction.x > 0 or direction.y > 0:
		mob.scale = Vector2i(-1, 1)
	else:
		mob.scale = Vector2i(1, 1)

func _step(mob: Node2D, direction: Vector2i) -> void:
	var to: Vector2 = mapToLocal(localToMap(mob.global_position) + direction)
	_tweenStep = create_tween()
	_tweenStep.tween_property(mob, "global_position", to, _turnTime)
	_tweenStep.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	_tweenStep.tween_callback(func(): updateMap.emit())
	await _tweenStep.finished

func _addPoints() -> void:
	_astar.clear()
	var rect := tileRect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p := Vector2i(x, y)
			_astar.add_point(tileIndex(p), p)
			if isDoorShut(p):
				_astar.set_point_disabled(tileIndex(p))

func _connect() -> void:
	var rect := tileRect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var cell := Vector2i(x, y)
			var cellId := tileIndex(cell)
			if insideMap(cell) and not isBlocked(cell):
				for direction in Directions:
					var neighbor := cell + direction
					var neighborId := tileIndex(neighbor)
					if insideMap(neighbor) and not isBlocked(neighbor) and not _astar.are_points_connected(cellId, neighborId):
						_astar.connect_points(cellId, neighborId)

func isBlocked(p: Vector2i) -> bool:
	return !isFloor(p) || isBlockedLight(p)

func isBlockedLight(p: Vector2i) -> bool:
	return isWall(p) or isDoorShut(p)

func _cameraToHero() -> void:
	moveCameraTo(_hero.global_position)

#endregion

#region Target

func _heroPosition() -> Vector2i:
	return localToMap(_hero.global_position)

func _targetPosition() -> Vector2i:
	return localToMap(_target.global_position)

func _targetToHero() -> void:
	_targetTo(_heroPosition())

func _targetTo(tile: Vector2i, turn := true) -> void:
	if insideMap(tile):
		if tile == _targetPosition():
			_turn = turn
		else:
			_targetUpdate(tile)
	else:
		_targetUpdate(_targetClosest(tile))

func _targetClosest(tile: Vector2i) -> Vector2i:
	return _astar.get_point_position(_astar.get_closest_point(tile, true))

func _targetUpdate(tile: Vector2i) -> void:
	var from := _heroPosition()
	var to: Vector2 = mapToLocal(tile)
	var toColor := _getPathColor(to)
	toColor.a = 0.75
	_target.global_position = mapToLocal(from)
	_target.modulate = Color.TRANSPARENT
	var tween := create_tween().set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tween.tween_property(_target, "global_position", to, _tweenTime)
	tween.parallel().tween_property(_target, "modulate", toColor, _tweenTime)
	_pathClear()
	if from != tile:
		_drawPath(from, tile)

#endregion

#region Path

func _drawPath(from: Vector2i, to: Vector2i) -> void:
	var rotation := 0
	var pathDelta := _delta(from, to)
	_pathPoints = _astar.get_point_path(tileIndex(from), tileIndex(to))
	for i in _pathPoints.size():
		var tile := _pathPoints[i]
		if i + 1 < _pathPoints.size():
			rotation = _pathRotate(_delta(tile, _pathPoints[i + 1]), pathDelta)
		var child = _pathScene.instantiate()
		var toColor := _getPathColor(to)
		toColor.a = i / float(_pathPoints.size()) * (_maxPathAlpha - _minPathAlpha) + _minPathAlpha
		create_tween().tween_property(child, "modulate", toColor, _tweenTime).set_delay(i / float(_pathPoints.size()) * _tweenTime)
		child.global_rotation_degrees = rotation
		child.global_position = mapToLocal(tile)
		_tileMap.add_child(child)

func _delta(from: Vector2i, to: Vector2i) -> Vector2:
	return to - from

func _pathRotate(stepDelta: Vector2i, pathDelta: Vector2i) -> int:
	var rotation := 0
	var trending = abs(pathDelta.y) > abs(pathDelta.x)
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
	_target.modulate = Color.TRANSPARENT
	for path in _tileMap.get_children():
		path.free()
	for i in range(_pathPoints.size() - 1, 0, -1):
		_pathPoints.remove_at(i)

#endregion

#region MiniMap

const _alpha := 0.8
const _colorMob := Color(0, 1, 0, _alpha)
const _colorStair := Color(1, 1, 0, _alpha)
const _colorDoor := Color(0, 0, 1, _alpha)
const _colorWallLit := Color(1, 1, 1, _alpha)
const _colorWall := Color(0.8, 0.8, 0.8, _alpha)
const _colorFloorLit := Color(0.4, 0.4, 0.4, _alpha)
const _colorFloor := Color(0.2, 0.2, 0.2, _alpha)
const _colorCamera := Color(1, 0, 1, _alpha)

func _isOnRect(p: Vector2i, r: Rect2i) -> bool:
	return (((p.x >= r.position.x and p.x <= r.position.x + r.size.x - 1) and (p.y == r.position.y or p.y == r.position.y + r.size.y - 1)) or
			((p.y >= r.position.y and p.y <= r.position.y + r.size.y - 1) and (p.x == r.position.x or p.x == r.position.x + r.size.x - 1)))

func getMapColor(p: Vector2i) -> Color:
	var camera := cameraBoundsMap()
	var color := Color(0.25, 0.25, 0.25, 0.25)
	var on := _isOnRect(p, camera)
	if on:
		color = _colorCamera
	var lit := isLit(p)
	var explored := isExplored(p)
	var hero := _heroPosition()
	if not _tileMap.is_layer_enabled(Layer.Light) or (lit or explored):
		if p == hero:
			color = _colorMob
		elif isStair(p):
			color = _colorStair
		elif isDoor(p):
			color = _colorDoor
		elif on:
			color = _colorCamera
		elif isWall(p):
			color = _colorWallLit if lit else _colorWall
		elif isFloor(p):
			color = _colorFloorLit if lit else _colorFloor
		else:
			color = _colorWallLit if lit else _colorWall
	return color

const _colorPathMob := Color(_colorMob.r, _colorMob.g, _colorMob.b)
const _colorPathStair := Color(_colorStair.r, _colorStair.g, _colorStair.b)
const _colorPathDoor := Color(_colorDoor.r, _colorDoor.g, _colorDoor.b)
const _colorPathWall := Color(_colorWall.r, _colorWall.g, _colorWall.b)

func _getPathColor(p: Vector2i) -> Color:
	var color := _colorPathWall
	if isStair(p):
		color = _colorPathStair
	elif isDoor(p):
		color = _colorPathDoor
	elif isWall(p):
		color = _colorPathWall
	elif isFloor(p):
		color = _colorPathMob
	return color

#endregion

#region Light

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
	_tileMap.set_layer_enabled(Layer.Light, not _tileMap.is_layer_enabled(Layer.Light))

func lightIncrease() -> void:
	lightRadius += 1
	_lightUpdate(_heroPosition(), lightRadius)

func lightDecrease() -> void:
	lightRadius -= 1
	_lightUpdate(_heroPosition(), lightRadius)

# https://web.archive.org/web/20130705072606/http://doryen.eptalys.net/2011/03/ramblings-on-lights-in-full-color-roguelikes/
# https://journal.stuffwithstuff.com/2015/09/07/what-the-hero-sees/
# https://www.roguebasin.com/index.php/FOV_using_recursive_shadowcasting
func _lightEmitRecursive(at: Vector2i, radius: float, maxRadius: float, start: float, end: float, xx: int, xy: int, yx: int, yy: int) -> void:
	if start < end: return
	var rSquared := maxRadius * maxRadius
	var newStart := 0.0
	for i in range(radius, maxRadius + 1):
		var dx := -i - 1
		var dy := -i
		var blocked := false
		while dx <= 0:
			dx += 1
			var p := Vector2i(at.x + dx * xx + dy * xy, at.y + dx * yx + dy * yy)
			if not insideMap(p): continue
			var lSlope := (dx - 0.5) / (dy + 0.5)
			var rSlope := (dx + 0.5) / (dy - 0.5)
			if start < rSlope: continue
			elif end > lSlope: break
			else:
				var distanceSquared := (at.x - p.x) * (at.x - p.x) + (at.y - p.y) * (at.y - p.y)
				if distanceSquared < rSquared:
					var intensity1 := 1.0 / (1.0 + distanceSquared / maxRadius)
					var intensity2 := intensity1 - 1.0 / (1.0 + rSquared)
					var intensity := intensity2 / (1.0 - 1.0 / (1.0 + rSquared))
					var light := int(intensity * _lightCount)
					_setLight(p, _lightExplored + light, true)
				var blockedAt := isBlockedLight(p)
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

func _lightEmit(at: Vector2i, radius: int) -> void:
	for i in range(_fovOctants[0].size()):
		_lightEmitRecursive(at, 1, radius, 1.0, 0.0, _fovOctants[0][i], _fovOctants[1][i], _fovOctants[2][i], _fovOctants[3][i])
	_setLight(at, _lightMax, true)

func _lightUpdate(at: Vector2i, radius: int) -> void:
	_darken()
	_lightEmit(at, radius)
	_lightTorches()

func _findTorches() -> void:
	_torches.clear()
	var torch0 := _tileMap.get_used_cells_by_id(Layer.Fore, Tile.Theme1Torch)
	var torch1 := _tileMap.get_used_cells_by_id(Layer.Fore, Tile.Theme1Torch)
	var torch2 := _tileMap.get_used_cells_by_id(Layer.Fore, Tile.Theme2Torch)
	var torch3 := _tileMap.get_used_cells_by_id(Layer.Fore, Tile.Theme3Torch)
	for p in torch0 + torch1 + torch2 + torch3:
		_torches[p] = Random.next(_torchRadius)

func _lightTorches() -> void:
	for p in _torches.keys():
		_torches[p] = clamp(_torches[p] + Random.nextRange(-1, 1), 2, _torchRadiusMax)
		var current = _torches[p]
		var north := Vector2i(p.x, p.y + 1)
		var east := Vector2i(p.x + 1, p.y)
		var south := Vector2i(p.x, p.y - 1)
		var west := Vector2i(p.x - 1, p.y)
		var emitted := false
		if insideMap(p):
			var northBlocked = isBlocked(north)
			if not northBlocked and isLit(north):
				emitted = true
				_lightEmit(north, current)
			var eastBlocked = isBlocked(east)
			if not eastBlocked and isLit(east):
				emitted = true
				_lightEmit(east, current)
			var southBlocked = isBlocked(south)
			if not southBlocked and isLit(south):
				emitted = true
				_lightEmit(south, current)
			var westBlocked = isBlocked(west)
			if not westBlocked and isLit(west):
				emitted = true
				_lightEmit(west, current)
			if not emitted:
				var northEast := Vector2i(p.x + 1, p.y + 1)
				var southEast := Vector2i(p.x + 1, p.y - 1)
				var southWest := Vector2i(p.x - 1, p.y - 1)
				var northWest := Vector2i(p.x - 1, p.y + 1)
				if northBlocked and eastBlocked and not isBlocked(northEast) and isLit(northEast):
					_lightEmit(northEast, current)
				if southBlocked and eastBlocked and not isBlocked(southEast) and isLit(southEast):
					_lightEmit(southEast, current)
				if southBlocked and westBlocked and not isBlocked(southWest) and isLit(southWest):
					_lightEmit(southWest, current)
				if northBlocked and westBlocked and not isBlocked(northWest) and isLit(northWest):
					_lightEmit(northWest, current)

func _dark() -> void:
	var rect := tileRect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			_setLight(Vector2i(x, y), _lightMin, false)

func _darken() -> void:
	var rect := tileRect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p := Vector2i(x, y)
			if _getLight(p) != _lightMin:
				_setLight(p, _lightExplored, false)

#endregion

#region Tile

func _setTileMap(tileMap: TileMap, layer: Layer, p: Vector2i, tile := INVALID, coords := INVALID_CELL, alternative := 0) -> void:
	tileMap.set_cell(layer, p, tile, coords, alternative)

func _setTile(layer: Layer, p: Vector2i, tile := INVALID, coords := INVALID_CELL, alternative := 0) -> void:
	_setTileMap(_tileMap, layer, p, tile, coords, alternative)

func _clearTileMap(tileMap: TileMap, layer: Layer, p: Vector2i) -> void:
	_setTileMap(tileMap, layer, p)

func _clearTile(layer: Layer, p: Vector2i) -> void:
	_clearTileMap(_tileMap, layer, p)

func _setRandomTileMap(tileMap: TileMap, layer: Layer, p: Vector2i, tile: Tile, coords := INVALID_CELL, alternative := INVALID) -> void:
	var c := _sources[tile].get_tile_id(_randomTileCoords(tile)) if coords == INVALID_CELL else coords
	var a := _randomTileAlternative(tile, c) if alternative == INVALID else alternative
	_setTileMap(tileMap, layer, p, tile, c, a)

func _setRandomTile(layer: Layer, p: Vector2i, tile: Tile, coords := INVALID_CELL, alternative := INVALID) -> void:
	_setRandomTileMap(_tileMap, layer, p, tile, coords, alternative)

func _setRandomTileEdge(p: Vector2i, tile: Tile, coords := INVALID_CELL, alternative := INVALID) -> void:
	_setRandomTileMap(_tileMapEdge, Layer.Back, p, tile, coords, alternative)

func _randomTileCoords(tile: Tile) -> int:
	var array := []
	var source = _sources[tile]
	for i in source.get_tiles_count():
		array.append(source.get_tile_data(source.get_tile_id(i), 0).probability)
	return Random.probabilityIndex(array)

func _randomTileAlternative(tile: Tile, coords: Vector2i) -> int:
	return Random.next(_sources[tile].get_alternative_tiles_count(coords))

#region Back / Floor

func clearBack(p: Vector2i) -> void:
	_clearTile(Layer.Back, p)

func _setBackRandom(p: Vector2i, tile: int, wonky := true) -> void:
	_setRandomTile(Layer.Back, p, tile, INVALID_CELL, INVALID if wonky else 0)

func setFloor(p: Vector2, wonky: bool) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Floor
		1: tile = Tile.Theme2Floor
		2: tile = Tile.Theme3Floor
		3: tile = Tile.Theme4Floor
	_setBackRandom(p, tile, wonky)

func setFloorRoom(p: Vector2, wonky: bool) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1FloorRoom
		1: tile = Tile.Theme2FloorRoom
		2: tile = Tile.Theme3FloorRoom
		3: tile = Tile.Theme4FloorRoom
	_setBackRandom(p, tile, wonky)

func setOutside(p: Vector2i) -> void:
	if _desert:
		_setBackRandom(p, Tile.DayDesert if _day else Tile.NightDesert)
	else:
		_setBackRandom(p, Tile.DayGrass if _day else Tile.NightGrass)

func setOutsideFloor(p: Vector2) -> void:
	_setBackRandom(p, Tile.DayFloor if _day else Tile.NightFloor)

func setOutsidePath(p: Vector2i) -> void:
	_setBackRandom(p, Tile.DayPath if _day else Tile.NightPath)

func setRubble(p: Vector2i) -> void:
	_setBackRandom(p, Tile.Rubble)

func _isBackTile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_tileMap.get_cell_source_id(Layer.Back, p))

func isFloor(p: Vector2i) -> bool:
	return _isBackTile(p, _floorTiles)

#endregion

#region Fore / Wall

func isForeInvalid(p: Vector2i) -> bool:
	return _tileMap.get_cell_tile_data(Layer.Fore, p) == null

func clearFore(p: Vector2i) -> void:
	_clearTile(Layer.Fore, p)

func _setForeRandom(p: Vector2i, tile: int, coords := INVALID_CELL, alternative := INVALID) -> void:
	_setRandomTile(Layer.Fore, p, tile, coords, alternative)

func setWallPlain(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1WallPlain
		1: tile = Tile.Theme2WallPlain
		2: tile = Tile.Theme3WallPlain
		3: tile = Tile.Theme4WallPlain
	_setForeRandom(p, tile)

func setWall(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Wall
		1: tile = Tile.Theme2Wall
		2: tile = Tile.Theme3Wall
		3: tile = Tile.Theme4Wall
	_setForeRandom(p, tile)

func setTorch(p: Vector2i) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Torch
		1: tile = Tile.Theme2Torch
		2: tile = Tile.Theme3Torch
		3: tile = Tile.Theme4Torch
	_setForeRandom(p, tile)

func setOutsideWall(p: Vector2i) -> void:
	_setForeRandom(p, Tile.DayWall if _day else Tile.NightWall)

func setOutsideHedge(p: Vector2i) -> void:
	_setForeRandom(p, Tile.DayHedge if _day else Tile.NightHedge)

func setCliff(p: Vector2i) -> void:
	var tile: Tile
	match _themeCliff:
		0: tile = Tile.Cliff1
		1: tile = Tile.Cliff2
	_setForeRandom(p, tile)

func _setStair(p: Vector2i, type: Stair) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Stair
		1: tile = Tile.Theme2Stair
		2: tile = Tile.Theme3Stair
		3: tile = Tile.Theme4Stair
	_setForeRandom(p, tile, _sources[tile].get_tile_id(type), 0)

func setStairDown(p: Vector2i) -> void:
	_setStair(p, Stair.Down)

func setStairUp(p: Vector2i) -> void:
	_setStair(p, Stair.Up)

func _setStairOutside(p: Vector2i, type: Stair) -> void:
	if _desert:
		_setForeRandom(p, Tile.DayStair if _day else Tile.NightStair, Vector2i(type + 2, 0))
	else:
		_setForeRandom(p, Tile.DayStair if _day else Tile.NightStair, Vector2i(type, 0))

func setStairOutsideUp(p: Vector2i) -> void:
	_setStairOutside(p, Stair.Up)

func setStairOutsideDown(p: Vector2i) -> void:
	_setStairOutside(p, Stair.Down)

func setDoor(p: Vector2i, type: Door) -> void:
	var tile: Tile
	match _theme:
		0: tile = Tile.Theme1Door
		1: tile = Tile.Theme2Door
		2: tile = Tile.Theme3Door
		3: tile = Tile.Theme4Door
	_setForeRandom(p, tile, _sources[tile].get_tile_id(type))

func setFountain(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Fountain)

func setBanner0(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Banner1)

func setBanner1(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Banner2)

func _isForeTile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_tileMap.get_cell_source_id(Layer.Fore, p))

func isWall(p: Vector2i) -> bool:
	return _isForeTile(p, _wallTiles)

func isCliff(p: Vector2i) -> bool:
	return _isForeTile(p, _cliffTiles)

func isStair(p: Vector2i) -> bool:
	return _isForeTile(p, _stairTiles)

func isStairUp(p: Vector2i) -> bool:
	return isStair(p) and _tileMap.get_cell_atlas_coords(Layer.Fore, p) == Vector2i(Stair.Up, 0)

func isStairDown(p: Vector2i) -> bool:
	return isStair(p) and _tileMap.get_cell_atlas_coords(Layer.Fore, p) == Vector2i(Stair.Down, 0)

func isDoor(p: Vector2i) -> bool:
	return _isForeTile(p, _doorTiles)

func isDoorShut(p: Vector2i) -> bool:
	return isDoor(p) and _tileMap.get_cell_atlas_coords(Layer.Fore, p) == Vector2i(Door.Shut, 0)

func verifyCliff() -> void:
	var rect := tileRect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p = Vector2i(x, y)
			if isCliff(p) and not isFloor(Vector2i(x, y - 1)):
				clearFore(p)

#endregion

#region Outside

func setFlower(p: Vector2i) -> void:
	_setRandomTile(Layer.Flower, p, Tile.Flower)

func setTree(p: Vector2i) -> void:
	_setRandomTile(Layer.Tree, p, Tile.Tree)

func setTreeStump(p: Vector2i) -> void:
	_setRandomTile(Layer.Tree, p, Tile.TreeStump)

func clearTree(p: Vector2i) -> void:
	_clearTile(Layer.Tree, p)

func cutTree(p: Vector2i) -> void:
	clearTree(p)
	setTreeStump(p)

func setGrass(p: Vector2i) -> void:
	if _desert:
		_setRandomTile(Layer.SplitBack, p, Tile.DayWeed if _day else Tile.NightWeed, Vector2i(Weed.BackDry, 0))
		_setRandomTile(Layer.SplitFore, p, Tile.DayWeed if _day else Tile.NightWeed, Vector2i(Weed.ForeDry, 0))
	else:
		_setRandomTile(Layer.SplitBack, p, Tile.DayWeed if _day else Tile.NightWeed, Vector2i(Weed.Back, 0))
		_setRandomTile(Layer.SplitFore, p, Tile.DayWeed if _day else Tile.NightWeed, Vector2i(Weed.Fore, 0))

#endregion

#region Water

func setWaterShallow(p: Vector2i) -> void:
	var sourceBack := _sources[Tile.WaterShallowBack]
	var sourceFore := _sources[Tile.WaterShallowFore]
	var c := _randomTileCoords(Tile.WaterShallowBack)
	var backId := sourceBack.get_tile_id(c)
	var foreId := sourceFore.get_tile_id(c)
	var a := _randomTileAlternative(Tile.WaterShallowBack, backId)
	_setRandomTile(Layer.WaterBack, p, Tile.WaterShallowBack, backId, a)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterShallowFore, foreId, a)

func setWaterDeep(p: Vector2i) -> void:
	var sourceBack := _sources[Tile.WaterDeepBack]
	var sourceFore := _sources[Tile.WaterDeepFore]
	var c := _randomTileCoords(Tile.WaterDeepBack)
	var backId := sourceBack.get_tile_id(c)
	var foreId := sourceFore.get_tile_id(c)
	var a := _randomTileAlternative(Tile.WaterDeepBack, backId)
	_setRandomTile(Layer.WaterBack, p, Tile.WaterDeepBack, backId, a)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterDeepFore, foreId, a)

func setWaterShallowPurple(p: Vector2i) -> void:
	var sourceBack := _sources[Tile.WaterShallowPurpleBack]
	var sourceFore := _sources[Tile.WaterShallowPurpleFore]
	var c := _randomTileCoords(Tile.WaterShallowPurpleBack)
	var backId := sourceBack.get_tile_id(c)
	var foreId := sourceFore.get_tile_id(c)
	var a := _randomTileAlternative(Tile.WaterShallowPurpleBack, backId)
	_setRandomTile(Layer.WaterBack, p, Tile.WaterShallowPurpleBack, backId, a)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterShallowPurpleFore, foreId, a)

func setWaterDeepPurple(p: Vector2i) -> void:
	var sourceBack := _sources[Tile.WaterDeepPurpleBack]
	var sourceFore := _sources[Tile.WaterDeepPurpleFore]
	var c := _randomTileCoords(Tile.WaterDeepPurpleBack)
	var backId := sourceBack.get_tile_id(c)
	var foreId := sourceFore.get_tile_id(c)
	var a := _randomTileAlternative(Tile.WaterDeepPurpleBack, backId)
	_setRandomTile(Layer.WaterBack, p, Tile.WaterDeepPurpleBack, backId, a)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterDeepPurpleFore, foreId, a)

func _isWaterTile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_tileMap.get_cell_source_id(Layer.WaterBack, p)) or tiles.has(_tileMap.get_cell_source_id(Layer.WaterFore, p))

func isWater(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterTiles)

func isWaterDeep(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterDeepTiles)

func isWaterPurple(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterPurpleTiles)

#endregion

#region Item

func _setItemForeRandom(p: Vector2i, tile: int) -> void:
	_setRandomTile(Layer.ItemFore, p, tile)

func _setItemBackRandom(p: Vector2i, tile: int) -> void:
	_setRandomTile(Layer.ItemBack, p, tile)

func setLoot(p: Vector2i) -> void:
	_setItemBackRandom(p, Tile.Loot)

#endregion

#region Light

func _getLight(p: Vector2i) -> int:
	return _tileMap.get_cell_atlas_coords(Layer.Light, p).x

func _setLight(p: Vector2i, light: int, test: bool) -> void:
	if not test or light > _getLight(p):
		_setTile(Layer.Light, p, Tile.Light, Vector2(light, 0))

func isExplored(p: Vector2i) -> bool:
	return _getLight(p) == _lightExplored

func isLit(p: Vector2i) -> bool:
	return _getLight(p) > _lightExplored

#endregion

#region Edge

func _randomEdgeOutside(d: Direction) -> int:
	match d:
		Direction.N:
			return Edge.Top if Random.nextBool() else Edge.TopFlip
		Direction.E:
			return Edge.Right if Random.nextBool() else Edge.RightFlip
		Direction.S:
			return Edge.Bottom if Random.nextBool() else Edge.BottomFlip
		Direction.W:
			return Edge.Left if Random.nextBool() else Edge.LeftFlip
	return INVALID

func _randomEdgeInside(d: Direction) -> int:
	match d:
		Direction.N:
			return Edge.Top if Random.nextBool() else Edge.TopFlip
		Direction.E:
			return Edge.Right if Random.nextBool() else Edge.RightFlip
		Direction.S:
			return Edge.Bottom if Random.nextBool() else Edge.BottomFlip
		Direction.W:
			return Edge.Left if Random.nextBool() else Edge.LeftFlip
	return INVALID

func _randomEdgeInsideCorner(d: Direction) -> int:
	match d:
		Direction.NW:
			return EdgeInsideCorner.TopLeft if Random.nextBool() else EdgeInsideCorner.TopLeftFlip
		Direction.NE:
			return EdgeInsideCorner.TopRight if Random.nextBool() else EdgeInsideCorner.TopRightFlip
		Direction.SW:
			return EdgeInsideCorner.BottomLeft if Random.nextBool() else EdgeInsideCorner.BottomLeftFlip
		Direction.SE:
			return EdgeInsideCorner.BottomRight if Random.nextBool() else EdgeInsideCorner.BottomRightFlip
	return INVALID

func _drawEdge() -> void:
	var rect := tileRect()
	if rect.size == Vector2i.ZERO:
		return
	var o = _sources[Tile.EdgeOutsideCorner]
	var i = _sources[Tile.EdgeInsideCorner]
	var minY: int = rect.position.y - 1
	var maxY: int = rect.end.y
	var minX: int = rect.position.x - 1
	var maxX: int = rect.end.x
	for y in range(minY, maxY + 1):
		for x in range(minX, maxX + 1):
			var p := Vector2i(x, y)
			if x == minX or x == maxX or y == minY or y == maxY:
				if x == minX and y == minY: # nw
					_setRandomTileEdge(p, Tile.EdgeOutsideCorner, o.get_tile_id(EdgeOutsideCorner.TopLeft))
				elif x == minX and y == maxY: # sw
					_setRandomTileEdge(p, Tile.EdgeOutsideCorner, o.get_tile_id(EdgeOutsideCorner.BottomLeft))
				elif x == maxX and y == minY: # ne
					_setRandomTileEdge(p, Tile.EdgeOutsideCorner, o.get_tile_id(EdgeOutsideCorner.TopRight))
				elif x == maxX and y == maxY: # se
					_setRandomTileEdge(p, Tile.EdgeOutsideCorner, o.get_tile_id(EdgeOutsideCorner.BottomRight))
				elif x == minX: # w
					_setRandomTileEdge(p, Tile.EdgeOutside, INVALID_CELL, _randomEdgeOutside(Direction.W))
				elif x == maxX: # e
					_setRandomTileEdge(p, Tile.EdgeOutside, INVALID_CELL, _randomEdgeOutside(Direction.E))
				elif y == minY: # n
					_setRandomTileEdge(p, Tile.EdgeOutside, INVALID_CELL, _randomEdgeOutside(Direction.N))
				elif y == maxY: # s
					_setRandomTileEdge(p, Tile.EdgeOutside, INVALID_CELL, _randomEdgeOutside(Direction.S))
			elif (x == minX + 1) or (x == maxX - 1) or (y == minY + 1) or (y == maxY - 1):
				if x == minX + 1 and y == minY + 1: # nw
					_setRandomTileEdge(p, Tile.EdgeInsideCorner, i.get_tile_id(EdgeInsideCorner.TopLeft), _randomEdgeInsideCorner(Direction.NW))
				elif x == minX + 1 and y == maxY - 1: # sw
					_setRandomTileEdge(p, Tile.EdgeInsideCorner, i.get_tile_id(EdgeInsideCorner.BottomLeft), _randomEdgeInsideCorner(Direction.SW))
				elif x == maxX - 1 and y == minY + 1: # ne
					_setRandomTileEdge(p, Tile.EdgeInsideCorner, i.get_tile_id(EdgeInsideCorner.TopRight), _randomEdgeInsideCorner(Direction.NE))
				elif x == maxX - 1 and y == maxY - 1: # se
					_setRandomTileEdge(p, Tile.EdgeInsideCorner, i.get_tile_id(EdgeInsideCorner.BottomRight), _randomEdgeInsideCorner(Direction.SE))
				elif x == minX + 1: # w
					_setRandomTileEdge(p, Tile.EdgeInside, INVALID_CELL, _randomEdgeInside(Direction.W))
				elif x == maxX - 1: # e
					_setRandomTileEdge(p, Tile.EdgeInside, INVALID_CELL, _randomEdgeInside(Direction.E))
				elif y == minY + 1: # n
					_setRandomTileEdge(p, Tile.EdgeInside, INVALID_CELL, _randomEdgeInside(Direction.N))
				elif y == maxY - 1: # s
					_setRandomTileEdge(p, Tile.EdgeInside, INVALID_CELL, _randomEdgeInside(Direction.S))

#endregion

#endregion
