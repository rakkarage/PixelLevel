extends SubViewport

#region Variable

@onready var _tileMap: TileMap  = $TileMap
@onready var _camera:  Camera2D = $Camera
@onready var _hero:    Node2D   = $Hero
@onready var _target:  Node2D   = $Target
@onready var _path:    Node2D   = $Path

const INVALID = Tile.Invalid
const INVALID_CELL := Vector2i(INVALID, INVALID)
const _turnTime := 0.22
const _duration := 0.333
const _zoomMin := Vector2(0.2, 0.2)
const _zoomMax := Vector2(1.0, 1.0)
const _zoomFactorIn := 0.90
const _zoomFactorOut := 1.10
const _zoomPinchIn := 0.02
const _zoomPinchOut := 1.02
const _pathScene := preload("res://Interface/Path.tscn")

var _astar: AStar2D = AStar2D.new()
var _oldSize := Vector2.ZERO
var _pathPoints := PackedVector2Array()
var _dragLeft := false
var _capture := false
var _turn := false
var _time := 0.0
var _turnTotal := 0
var _timeTotal := 0.0
var startAt := Vector2(4, 4)

var theme := 0 # dungeon theme
var day := true # day or night outside theme
var desert := false # desert or grass outside theme
const themeCount := 4 # number of dungeon themes
var themeCliff := 0 # cliff theme
const themeCliffCount := 2 # number of cliff themes

var _tweenCamera : Tween
var _tweenStep : Tween
var _tweenTarget : Tween

# matches tileMap layers
enum Layer {
	Back,
	Fore,
	Flower,
	WaterBack, SplitBack, ItemBack,
	Tree,
	ItemFore, SplitFore, WaterFore,
	Top,
	Light,
	Edge }

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

# used for testing if a tile is a certain type with isTileId
const _floorTiles := [
	Tile.Theme1Floor, Tile.Theme2Floor, Tile.Theme3Floor, Tile.Theme4Floor,
	Tile.DayGrass, Tile.NightGrass, Tile.DayPath, Tile.NightPath,
	Tile.DayDesert, Tile.NightDesert, Tile.DayFloor, Tile.NightFloor, Tile.Rubble ]
const _wallTiles := [
	Tile.Theme1Torch, Tile.Theme1Wall, Tile.Theme2Torch, Tile.Theme2Wall,
	Tile.Theme3Torch, Tile.Theme3Wall, Tile.Theme4Torch, Tile.Theme4Wall,
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

#endregion

#region Map

func _ready() -> void:
	_camera.zoom = Vector2(0.75, 0.75)
	_generated()
	_cameraCenter()
	connect("size_changed", _onResize)

func _onResize() -> void:
	var normalize := (_camera.global_position - Vector2(_mapSize() / 2.0)) / _oldSize
	_camera.global_position = normalize * Vector2(size + Vector2i(_mapSize() / 2.0))
	_oldSize = size
	_cameraUpdate()

func _generated() -> void:
	#TODO
	pass

func _process(delta: float) -> void:
	_time += delta
	if _time > _turnTime and (_turn or _processWasd()):
		_timeTotal += _time
		_turnTotal += 1
		var test := _turn
		_turn = false
		if test:
			if not _handleDoor():
				await _move(_hero)
			if not _handleStair():
				_lightUpdate(heroPosition(), lightRadius)
				_checkCenter()
		_time = 0.0

func _move(mob: Node2D) -> void:
	await get_tree().process_frame
	if _pathPoints.size() > 1:
		var delta := _delta(_pathPoints[0], _pathPoints[1])
		_face(mob, delta)
		_fadeAndFree()
		await _step(mob, delta)

func _fadeAndFree() -> void:
	_pathPoints.remove_at(0)
	var node := _path.get_child(0)
	var tween := get_tree().create_tween()
	tween.tween_property(node, "modulate", Color.TRANSPARENT, _turnTime)
	await tween.finished
	node.queue_free()
	if _pathPoints.size() > 1:
		_turn = true
	else:
		_pathClear()

func _handleStair() -> bool:
	if _pathPoints.size() == 1:
		var p := heroPosition()
		if isStairDown(p):
			emit_signal("generate")
			return true
		elif isStairUp(p):
			emit_signal("generateUp")
			return true
	return false

func _handleDoor() -> bool:
	var from := heroPosition()
	var to := targetPosition()
	if (from - to).length() < 2.0:
		if isDoor(to):
			_toggleDoor(to)
			_astar.set_point_disabled(_tileIndex(to), isDoorShut(to))
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
	if direction.x > 0:
		mob.scale = Vector2i(-1, 1)
	else:
		mob.scale = Vector2i(1, 1)

func _step(mob: Node2D, direction: Vector2i) -> void:
	mob.walk()
	if _tweenStep:
		_tweenStep.kill()
	_tweenStep = create_tween()
	_tweenStep.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
	_tweenStep.tween_property(mob, "global_position", mob.global_position + Vector2(_world(direction)), _turnTime)
	await _tweenStep.finished

func _addPoints() -> void:
	_astar.clear()
	var rect := _tileMap.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p := Vector2i(x, y)
			_astar.add_point(_tileIndex(p), p)

func _connectPoints() -> void:
	var rect := _tileMap.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			_connect(Vector2i(x, y))

func _connect(p: Vector2i) -> void:
	var rect := _tileMap.get_used_rect()
	for yy in range(p.y - 1, p.y + 2):
		for xx in range(p.x - 1, p.x + 2):
			var pp := Vector2i(xx, yy)
			if (not is_equal_approx(yy, p.y) or not is_equal_approx(xx, p.x)) and rect.has_point(pp):
				if isDoor(pp) or not isBlocked(pp):
					_astar.connect_points(_tileIndex(p), _tileIndex(pp), false)
					if isDoorShut(pp):
						_astar.set_point_disabled(_tileIndex(pp), true)

func _tileIndex(pos: Vector2) -> int:
	return Utility.index(pos, _mapSize().x)

func _tilePosition(index: int) -> Vector2:
	return Utility.position(index, _mapSize().x)

func isBlocked(p: Vector2i) -> bool:
	return isFloor(p) && !isBlockedLight(p)

func isBlockedLight(p: Vector2i) -> bool:
	return isWall(p) or isDoorShut(p)

func insideMap(p: Vector2i) -> bool:
	return _tileMap.get_used_rect().has_point(p)

func getCameraRect() -> Rect2:
	return Rect2(_map(_camera.global_position), _map(_camera.global_position + _worldSize()))

func _world(tile: Vector2i) -> Vector2:
	return _tileMap.map_to_local(tile)

func _worldSize() -> Vector2:
	return Vector2(size) * _camera.zoom

func _worldBounds() -> Rect2:
	return Rect2(Vector2.ZERO, _worldSize())

func _map(position: Vector2) -> Vector2i:
	return _tileMap.local_to_map(position)

func _mapSize() -> Vector2i:
	return _tileMap.get_used_rect().size * _tileMap.tile_set.tile_size

func mapBounds() -> Rect2i:
	return Rect2(-_camera.global_position, _mapSize())

func _center() -> Vector2i:
	return -(_worldSize() / 2.0) + _mapSize() / 2.0

func _cameraCenter() -> void:
	_cameraTo(_center())

func _cameraTo(to: Vector2) -> void:
	if _tweenCamera:
		_tweenCamera.kill()
	_camera.global_position = to

func _cameraToMob() -> void:
	_cameraTo(-(_worldSize() / 2.0) + _hero.global_position)

func _cameraBy(by: Vector2) -> void:
	_cameraTo(_camera.global_position + by)

func _cameraUpdate() -> void:
	var map := mapBounds()
	var world := _worldBounds().grow(_tileMap.tile_set.tile_size.x)
	if not world.intersects(map):
		_cameraSnap(_camera.global_position + Utility.constrainRect(world, map))
	else:
		emit_signal("updateMap")

func _cameraSnap(to: Vector2) -> void:
	if _tweenCamera:
		_tweenCamera.kill()
	_tweenCamera = create_tween()
	_tweenCamera.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tweenCamera.tween_property(_camera, "global_position", to, _duration)
	await _tweenCamera.finished
	emit_signal("updateMap")

const _edgeOffset := 1.5
const _edgeOffsetV := Vector2(_edgeOffset, _edgeOffset)

func _checkCenter() -> void:
	var edge := Vector2(_world(_edgeOffsetV)) / _camera.zoom
	var test := -(_camera.global_position - _hero.global_position) / _camera.zoom
	if ((test.x > size.x - edge.x) or (test.x < edge.x) or
		(test.y > size.y - edge.y) or (test.y < edge.y)):
		_cameraSnap(-(_worldSize() / 2.0) + _hero.global_position)
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

#endregion

#region Input

func _unhandled_input(event: InputEvent) -> void:
	print("unhandled_input", event)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_turn = false
			if event.pressed:
				_dragLeft = true
				_capture = false
			else:
				if _capture:
					_cameraUpdate()
				elif _tweenStep:
					_targetTo(event.global_position, not _tweenStep.is_running())
					_targetUpdate()
				_dragLeft = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoomIn(event.global_position)
			_cameraUpdate()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoomOut(event.global_position)
			_cameraUpdate()
	elif event is InputEventMouseMotion:
		if _dragLeft:
			_capture = true
			_cameraTo(_camera.global_position - event.relative * _camera.zoom)
			emit_signal("updateMap")

func _processWasd() -> bool:
	var done := false
	if Input.is_action_pressed("ui_up"):
		_wasd(Vector2i.UP)
		done = true
	if Input.is_action_pressed("ui_ne"):
		_wasd(Vector2i.UP + Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_right"):
		_wasd(Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_se"):
		_wasd(Vector2i.DOWN + Vector2i.RIGHT)
		done = true
	if Input.is_action_pressed("ui_down"):
		_wasd(Vector2i.DOWN)
		done = true
	if Input.is_action_pressed("ui_sw"):
		_wasd(Vector2i.DOWN + Vector2i.LEFT)
		done = true
	if Input.is_action_pressed("ui_left"):
		_wasd(Vector2i.LEFT)
		done = true
	if Input.is_action_pressed("ui_nw"):
		_wasd(Vector2i.UP + Vector2i.LEFT)
		done = true
	return done

func _wasd(direction: Vector2i) -> void:
	var p := heroPosition() + direction
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
				emit_signal("generate")
			elif isStairUp(p):
				emit_signal("generateUp")

#endregion

#region Hero

func heroPosition() -> Vector2i:
	return _map(_hero.global_position)

#endregion

#region Target

func targetPosition() -> Vector2i:
	return _map(_target.global_position)

func _targetToMob() -> void:
	_targetTo(_hero.global_position, true)

func _targetTo(to: Vector2, turn: bool) -> void:
	if _tweenTarget:
		_tweenTarget.kill()
	var tile := _map(_camera.global_position + to * _camera.zoom)
	if tile == targetPosition():
		_turn = turn
	else:
		_target.global_position = _world(tile)

func _targetUpdate() -> void:
	var from := heroPosition()
	var to := _targetSnapClosest(targetPosition())
	_pathClear()
	if from != to:
		_drawPath(from, to)

func _targetSnapClosest(tile: Vector2i) -> Vector2i:
	var p := _astar.get_point_position(_astar.get_closest_point(tile, true))
	_targetSnap(p)
	return p

func _targetSnap(tile: Vector2) -> void:
	var p := _world(tile)
	if not _target.global_position.is_equal_approx(p):
		if _tweenTarget:
			_tweenTarget.kill()
		_tweenTarget = create_tween()
		_tweenTarget.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_tweenTarget.tween_property(_target, "global_position", p, _duration)

#endregion

#region Path

func _drawPath(from: Vector2i, to: Vector2i) -> void:
	var color := _getPathColor(to)
	_target.modulate = color
	var rotation := 0
	var pathDelta := _delta(from, to)
	_pathPoints = _astar.get_point_path(_tileIndex(from), _tileIndex(to))
	for i in _pathPoints.size():
		var tile := _pathPoints[i]
		if i + 1 < _pathPoints.size():
			rotation = _pathRotate(_delta(tile, _pathPoints[i + 1]), pathDelta)
		var child := _pathScene.instantiate()
		child.modulate = color
		child.global_rotation_degrees = rotation
		child.global_position = _world(tile)
		_path.add_child(child)

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
	for path in _path.get_children():
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

func getMapColor(p: Vector2i) -> Color:
	var camera := getCameraRect()
	var color := Color(0.25, 0.25, 0.25, 0.25)
	var on := _isRect(p, camera)
	if on:
		color = _colorCamera
	var lit := isLit(p)
	var explored := isExplored(p)
	var hero := heroPosition()
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

func _isRect(p: Vector2i, r: Rect2i) -> bool:
	return (((p.x >= r.position.x and p.x <= r.size.x) and (p.y == r.position.y or p.y == r.size.y)) or
		((p.y >= r.position.y and p.y <= r.size.y) and (p.x == r.position.x or p.x == r.size.x)))

const _alphaPath := 0.333
const _colorPathMob := Color(_colorMob.r, _colorMob.g, _colorMob.b, _alphaPath)
const _colorPathStair := Color(_colorStair.r, _colorStair.g, _colorStair.b, _alphaPath)
const _colorPathDoor := Color(_colorDoor.r, _colorDoor.g, _colorDoor.b, _alphaPath)
const _colorPathWall := Color(_colorWall.r, _colorWall.g, _colorWall.b, _alphaPath)

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
	_lightUpdate(heroPosition(), lightRadius)

func lightDecrease() -> void:
	lightRadius -= 1
	_lightUpdate(heroPosition(), lightRadius)

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
	var rect := _tileMap.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			_setLight(Vector2i(x, y), _lightMin, false)

func _darken() -> void:
	var rect := _tileMap.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p := Vector2i(x, y)
			if _getLight(p) != _lightMin:
				_setLight(p, _lightExplored, false)

#endregion

#region Tile

func _setTile(layer: Layer, p: Vector2i, id: Tile, coords := Vector2(0, 0), alternative := 0) -> void:
	_tileMap.set_cell(layer, p, id, coords, alternative)

func _clearTile(layer: Layer, p: Vector2i) -> void:
	_setTile(layer, p, INVALID)

func _setRandomTile(layer: Layer, p: Vector2i, id: Tile, coords := INVALID_CELL, alternative := INVALID) -> void:
	var source := _tileMap.tile_set.get_source(id)
	var c := _randomTileCoord(source) if coords == INVALID_CELL else coords
	var a := _randomTileAlternative(source, c) if alternative == INVALID else 0
	_setTile(layer, p, id, c, a)

func _randomTileCoord(source: TileSetSource) -> Vector2i:
	var array := []
	for i in source.get_tiles_count():
		array[i] = source.get_tile_probability(i)
	return source.get_tile_id(Random.probabilityIndex(array))

func _randomTileAlternative(source: TileSetSource, coords: Vector2i) -> int:
	var array := []
	for i in source.get_alternative_tiles_count(coords):
		array[i] = source.get_alternative_tile_probability(coords, i)
	return source.get_alternative_tile_id(coords, Random.probabilityIndex(array))

#endregion

#region Back / Floor

func _setBackRandom(p: Vector2i, tile: int) -> void:
	_setRandomTile(Layer.Back, p, tile)

func setFloor(p: Vector2) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1Floor
		1: id = Tile.Theme2Floor
		2: id = Tile.Theme3Floor
		3: id = Tile.Theme4Floor
	_setBackRandom(p, id)

func setFloorRoom(p: Vector2) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1FloorRoom
		1: id = Tile.Theme2FloorRoom
		2: id = Tile.Theme3FloorRoom
		3: id = Tile.Theme4FloorRoom
	_setBackRandom(p, id)

func setOutside(p: Vector2i) -> void:
	if desert:
		_setBackRandom(p, Tile.DayDesert if day else Tile.NightDesert)
	else:
		_setBackRandom(p, Tile.DayGrass if day else Tile.NightGrass)

func setOutsideFloor(p: Vector2) -> void:
	_setBackRandom(p, Tile.DayFloor if day else Tile.NightFloor)

func setOutsidePath(p: Vector2i) -> void:
	_setBackRandom(p, Tile.DayPath if day else Tile.NightPath)

func setRubble(p: Vector2i) -> void:
	_setBackRandom(p, Tile.Rubble)

func _isBackTile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_tileMap.get_cell_source_id(Layer.Back, p))

func isFloor(p: Vector2i) -> bool:
	return _isBackTile(p, _floorTiles)

#endregion

#region Fore / Wall

func _setForeRandom(p: Vector2i, tile: int, coords: Vector2i = INVALID_CELL) -> void:
	_setRandomTile(Layer.Fore, p, tile, coords)

func setWallPlain(p: Vector2i) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1WallPlain
		1: id = Tile.Theme2WallPlain
		2: id = Tile.Theme3WallPlain
		3: id = Tile.Theme4WallPlain
	_setForeRandom(p, id)

func setWall(p: Vector2i) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1Wall
		1: id = Tile.Theme2Wall
		2: id = Tile.Theme3Wall
		3: id = Tile.Theme4Wall
	_setForeRandom(p, id)

func setTorch(p: Vector2i) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1Torch
		1: id = Tile.Theme2Torch
		2: id = Tile.Theme3Torch
		3: id = Tile.Theme4Torch
	_setForeRandom(p, id)

func setOutsideWall(p: Vector2i) -> void:
	_setForeRandom(p, Tile.DayWall if day else Tile.NightWall)

func setOutsideHedge(p: Vector2i) -> void:
	_setForeRandom(p, Tile.DayHedge if day else Tile.NightHedge)

func setCliff(p: Vector2i) -> void:
	var id: Tile
	match themeCliff:
		0: id = Tile.Cliff1
		1: id = Tile.Cliff2
	_setForeRandom(p, id)

func _setStair(p: Vector2i, type: Stair) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1Stair
		1: id = Tile.Theme2Stair
		2: id = Tile.Theme3Stair
		3: id = Tile.Theme4Stair
	_setForeRandom(p, id, Vector2i(type, 0))

func setStairDown(p: Vector2i) -> void:
	_setStair(p, Stair.Down)

func setStairUp(p: Vector2i) -> void:
	_setStair(p, Stair.Up)

func _setStairOutside(p: Vector2i, type: Stair) -> void:
	if desert:
		_setForeRandom(p, Tile.DayStair if day else Tile.NightStair, Vector2i(type + 2, 0))
	else:
		_setForeRandom(p, Tile.DayStair if day else Tile.NightStair, Vector2i(type, 0))

func setStairOutsideUp(p: Vector2i) -> void:
	_setStairOutside(p, Stair.Up)

func setStairOutsideDown(p: Vector2i) -> void:
	_setStairOutside(p, Stair.Down)

func setDoor(p: Vector2i, type: Door) -> void:
	var id: Tile
	match theme:
		0: id = Tile.Theme1Door
		1: id = Tile.Theme2Door
		2: id = Tile.Theme3Door
		3: id = Tile.Theme4Door
	_setForeRandom(p, id, Vector2i(type, 0))

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
	var rect := _tileMap.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p = Vector2i(x, y)
			if isCliff(p) and not isFloor(Vector2i(x, y - 1)):
				_clearTile(Layer.Fore, p)

#endregion

#region Flower

func setFlower(p: Vector2i) -> void:
	_setRandomTile(Layer.Flower, p, Tile.Flower)

#endregion

#region Tree

func setTree(p: Vector2i) -> void:
	_setRandomTile(Layer.Tree, p, Tile.Tree)

func setTreeStump(p: Vector2i) -> void:
	_setRandomTile(Layer.Tree, p, Tile.TreeStump)

func clearTree(p: Vector2i) -> void:
	_clearTile(Layer.Tree, p)

func cutTree(p: Vector2i) -> void:
	clearTree(p)
	setTreeStump(p)

#endregion

#region Water

func setWaterShallow(p: Vector2i) -> void:
	_setRandomTile(Layer.WaterBack, p, Tile.WaterShallowBack)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterShallowFore)

func setWaterDeep(p: Vector2i) -> void:
	_setRandomTile(Layer.WaterBack, p, Tile.WaterDeepBack)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterDeepFore)

func setWaterShallowPurple(p: Vector2i) -> void:
	_setRandomTile(Layer.WaterBack, p, Tile.WaterShallowPurpleBack)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterShallowPurpleFore)

func setWaterDeepPurple(p: Vector2i) -> void:
	_setRandomTile(Layer.WaterBack, p, Tile.WaterDeepPurpleBack)
	_setRandomTile(Layer.WaterFore, p, Tile.WaterDeepPurpleFore)

func _isWaterTile(p: Vector2i, tiles: Array) -> bool:
	return tiles.has(_tileMap.get_cell_source_id(Layer.WaterBack, p))

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

#region Split

func setGrass(p: Vector2i) -> void:
	if desert:
		_setRandomTile(Layer.SplitBack, p, Tile.DayWeed if day else Tile.NightWeed, Vector2i(Weed.BackDry, 0))
		_setRandomTile(Layer.SplitFore, p, Tile.DayWeed if day else Tile.NightWeed, Vector2i(Weed.ForeDry, 0))
	else:
		_setRandomTile(Layer.SplitBack, p, Tile.DayWeed if day else Tile.NightWeed, Vector2i(Weed.Back, 0))
		_setRandomTile(Layer.SplitFore, p, Tile.DayWeed if day else Tile.NightWeed, Vector2i(Weed.Fore, 0))

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

func _drawEdge() -> void:
	var rect := _tileMap.get_used_rect()
	var minY: int = rect.position.y - 1
	var maxY: int = rect.end.y
	var minX: int = rect.position.x - 1
	var maxX: int = rect.end.x
	for y in range(minY, maxY + 1):
		for x in range(minX, maxX + 1):
			if x == minX or x == maxX or y == minY or y == maxY:
				if x == minX and y == minY: # nw
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutsideCorner)
				elif x == minX and y == maxY: # sw
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutsideCorner)
				elif x == maxX and y == minY: # ne
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutsideCorner)
				elif x == maxX and y == maxY: # se
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutsideCorner)
				elif x == minX: # w
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutside)
				elif x == maxX: # e
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutside)
				elif y == minY: # n
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutside)
				elif y == maxY: # s
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeOutside)
			elif (x == minX + 1) or (x == maxX - 1) or (y == minY + 1) or (y == maxY - 1):
				if x == minX + 1 and y == minY + 1: # nw
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInsideCorner)
				elif x == minX + 1 and y == maxY - 1: # sw
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInsideCorner)
				elif x == maxX - 1 and y == minY + 1: # ne
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInsideCorner)
				elif x == maxX - 1 and y == maxY - 1: # se
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInsideCorner)
				elif x == minX + 1: # w
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInside)
				elif x == maxX - 1: # e
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInside)
				elif y == minY + 1: # n
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInside)
				elif y == maxY - 1: # s
					_setRandomTile(Layer.Edge, Vector2i(x, y), Tile.EdgeInside)

#endregion
