extends SubViewport

#region Variable

@onready var _tileMap: TileMap  = $TileMap
@onready var _camera:  Camera2D = $Camera
@onready var _hero:    Node2D   = $Hero
@onready var _target:  Node2D   = $Target
@onready var _path:    Node2D   = $Path

var _astar: AStar2D = AStar2D.new()
var _oldSize := Vector2.ZERO
var _pathPoints := PackedVector2Array()
var _dragLeft := false
var _capture := false
var _turn := false
var _tweenCamera : Tween
var _tweenStep : Tween
var _tweenTarget : Tween

const _duration := 0.333
const _pathScene := preload("res://Interface/Path.tscn")

#region Light Variables

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

#endregion

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

enum Tile {
	Cliff1, Cliff2,	Banner1, Banner2, Doodad, Rug, Fountain, Loot,
	EdgeInside, EdgeInsideCorner, EdgeOutsideCorner, EdgeOutside,
	Light, LightDebug,
	DayGrass, DayPillar, DayPath, DayStair, DayDesert, DayDoodad,
	DayWeed, DayHedge, DayWall, DayFloor,
	NightGrass, NightPillar, NightPath, NightStair, NightDesert, NightDoodad,
	NightWeed, NightHedge, NightWall, NightFloor,
	Tree, TreeStump, Flower, Rubble,
	Theme1Torch, Theme1Wall, Theme1Floor, Theme1Stair, Theme1Door,
	Theme2Torch, Theme2Wall, Theme2Floor, Theme2Stair, Theme2Door,
	Theme3Torch, Theme3Wall, Theme3Floor, Theme3Stair, Theme3Door,
	Theme4Torch, Theme4Wall, Theme4Floor, Theme4Stair, Theme4Door,
	WaterShallow, WaterDeep, WaterShallowPurple, WaterDeepPurple }

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
const _waterTiles := [Tile.WaterShallow, Tile.WaterDeep, Tile.WaterShallowPurple, Tile.WaterDeepPurple]
const _waterDeepTiles := [Tile.WaterDeep, Tile.WaterDeepPurple]
const _waterPurpleTiles := [Tile.WaterShallowPurple, Tile.WaterDeepPurple]

#endregion

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

func _tileIndex(pos: Vector2) -> int:
	return Utility.index(pos, _mapSize().x)

func _tilePosition(index: int) -> Vector2:
	return Utility.position(index, _mapSize().x)

# mob blocked by cliff or no floor or...
func isBlocked(p: Vector2i) -> bool:
	if not insideMap(p): return true
	var fore := _tileMap.get_cell_source_id(Layer.Fore, p)
	var back := _tileMap.get_cell_source_id(Layer.Back, p)
	return _cliffTiles.has(fore) or ((fore == INVALID_CELL) and not _floorTiles.has(back)) or isBlockedLight(p)

# light blocked by wall or shut door
func isBlockedLight(p: Vector2i) -> bool:
	if not insideMap(p): return true
	var fore := _fore.get_cell_source_id(0, p)
	var w := _wallTiles.has(fore)
	var d := _doorTiles.has(fore)
	var s = _fore.get_cell_atlas_coords(0, p)
	return w or (d and s == Vector2i.ZERO)

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

#endregion

func _zoomIn(p: Vector2) -> void:
	pass

func _zoomOut(p: Vector2) -> void:
	pass

func _face(node: Node2D, direction: Vector2i) -> void:
	pass

func _step(node: Node2D, direction: Vector2i) -> void:
	pass

func _lightUpdate(p: Vector2i, radius: int) -> void:
	pass

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

#region Tile

# TODO: flip and rotate in alternate now?
func _setRandomTile(map: TileMap, p: Vector2i, id: int, flipX: bool = false, flipY: bool = false, rot90: bool = false) -> void:
	map.set_cell(0, p, id, _randomTile(id))

func _randomTile(id: int) -> Vector2:
	var p := Vector2.ZERO
	var s = _tileSet.tile_get_region(id).size / _tileSet.autotile_get_size(id)
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

#endregion

#region Back

# TODO: flip and rotate in alternate now?
func _setBack(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2i.ZERO) -> void:
	_back.set_cell(0, p, tile, coord)

func _setBackRandom(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_back, p, tile, flipX, flipY, rot90)

func setFloor(p: Vector2, wonky := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Floor
		1: id = Tile.Theme1Floor
		2: id = Tile.Theme2Floor
		3: id = Tile.Theme3Floor
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(p, id, flipX, flipY, rot90)

func setFloorRoom(p: Vector2, wonky := false) -> void:
	var id
	match theme:
		0: id = Tile.Theme0FloorRoom
		1: id = Tile.Theme1FloorRoom
		2: id = Tile.Theme2FloorRoom
		3: id = Tile.Theme3FloorRoom
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(p, id, flipX, flipY, rot90)

func setOutside(p: Vector2i) -> void:
	if desert:
		_setBackRandom(p, Tile.OutsideDayDesert if day else Tile.OutsideNightDesert)
	else:
		_setBackRandom(p, Tile.OutsideDay if day else Tile.OutsideNight, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideFloor(p: Vector2, wonky := false) -> void:
	var flipX := Random.nextBool() if wonky else false
	var flipY := Random.nextBool() if wonky else false
	var rot90 := Random.nextBool() if wonky else false
	_setBackRandom(p, Tile.OutsideDayFloor if day else Tile.OutsideNightFloor, flipX, flipY, rot90)

func _isBackTile(p: Vector2i, tiles: Array) -> bool:
	return isTileId(_back.get_cell_source_id(0, p), tiles)

func isFloor(p: Vector2i) -> bool:
	return _isBackTile(p, _floorTiles)

func clearBack(p: Vector2i) -> void:
	_setBack(p, INVALID_CELL)

func isBackInvalid(p: Vector2i) -> bool:
	return _back.get_cell(p) == INVALID_CELL

#endregion

#region Fore

# TODO: flip and rotate in alternate now?
func _setFore(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2i.ZERO) -> void:
	_fore.set_cell(0, p, tile, coord)

func _setForeRandom(p: Vector2i, int, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_fore, p, tile, flipX, flipY, rot90)

func setWallPlain(p: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0WallPlain
		1: id = Tile.Theme1WallPlain
		2: id = Tile.Theme2WallPlain
		3: id = Tile.Theme3WallPlain
	_setForeRandom(p, id, Random.nextBool())

func setWall(p: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Wall
		1: id = Tile.Theme1Wall
		2: id = Tile.Theme2Wall
		3: id = Tile.Theme3Wall
	_setForeRandom(p, id, Random.nextBool())

func setTorch(p: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Torch
		1: id = Tile.Theme1Torch
		2: id = Tile.Theme2Torch
		3: id = Tile.Theme3Torch
	_setForeRandom(p, id, Random.nextBool())

func setRubble(p: Vector2i) -> void:
	_setRandomTile(_back, p, Tile.Rubble, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideRubble(p: Vector2i) -> void:
	_setRandomTile(_back, p, Tile.OutsideDayRubble if day else Tile.OutsideNightRubble, Random.nextBool(), Random.nextBool(), Random.nextBool())

func setOutsideWall(p: Vector2i) -> void:
	_setRandomTile(_fore, p, Tile.OutsideDayWall if day else Tile.OutsideNightWall, Random.nextBool())

func setOutsideHedge(p: Vector2i) -> void:
	_setRandomTile(_fore, p, Tile.OutsideDayHedge if day else Tile.OutsideNightHedge, Random.nextBool())

func setCliff(p: Vector2i) -> void:
	var id
	match themeCliff:
		0: id = Tile.Cliff0
		1: id = Tile.Cliff1
	_setForeRandom(p, id, Random.nextBool())

func _setStair(p: Vector2i, coord: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Stair
		1: id = Tile.Theme1Stair
		2: id = Tile.Theme2Stair
		3: id = Tile.Theme3Stair
	_setFore(p, id, Random.nextBool(), false, false, coord)

func setStairDown(p: Vector2i) -> void:
	_setStair(p, Vector2(0, 0))

func setStairUp(p: Vector2i) -> void:
	_setStair(p, Vector2(1, 0))

func _setStairOutside(p: Vector2i, coord: Vector2i) -> void:
	if desert:
		_setFore(p, Tile.OutsideDayDesertStair if day else Tile.OutsideNightDesertStair, Random.nextBool(), false, false, coord)
	else:
		_setFore(p, Tile.OutsideDayStair if day else Tile.OutsideNightStair, Random.nextBool(), false, false, coord)

func setStairOutsideUp(p: Vector2i) -> void:
	_setStairOutside(p, Vector2(0, 0))

func setStairOutsideDown(p: Vector2i) -> void:
	_setStairOutside(p, Vector2(1, 0))

func setDoor(p: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Door
		1: id = Tile.Theme1Door
		2: id = Tile.Theme2Door
		3: id = Tile.Theme3Door
	_setRandomTile(_fore, p, id, Random.nextBool())

func setDoorBroke(p: Vector2i) -> void:
	var id
	match theme:
		0: id = Tile.Theme0Door
		1: id = Tile.Theme1Door
		2: id = Tile.Theme2Door
		3: id = Tile.Theme3Door
	_setFore(p, id, Random.nextBool(), false, false, Vector2(2, 0))

func setFountain(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Fountain, Random.nextBool())

func setBanner0(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Banner0, Random.nextBool())

func setBanner1(p: Vector2i) -> void:
	_setForeRandom(p, Tile.Banner1, Random.nextBool())

func setLoot(p: Vector2i) -> void:
	var id
	match Random.next(4):
		0: id = Tile.Chest
		1: id = Tile.ChestBroke
		2: id = Tile.ChestOpenEmpty
		3: id = Tile.ChestOpenFull
	_setItemBackRandom(p, id, Random.nextBool())
	if Random.nextBool():
		_setItemFore(p, Tile.Loot)

func _isForeTile(p: Vector2i, tiles: Array) -> bool:
	return isTileId(_fore.get_cell_source_id(0, p), tiles)

func isWall(p: Vector2i) -> bool:
	return _isForeTile(p, _wallTiles)

func isCliff(p: Vector2i) -> bool:
	return _isForeTile(p, _cliffTiles)

func isStair(p: Vector2i) -> bool:
	return _isForeTile(p, _stairTiles)

func isStairUp(p: Vector2i) -> bool:
	return isStair(p) and _fore.get_cell_autotile_coord(p) == Vector2i(1, 0)

func isStairDown(p: Vector2i) -> bool:
	return isStair(p) and _fore.get_cell_autotile_coord(p) == Vector2i(0, 0)

func isDoor(p: Vector2i) -> bool:
	return _isForeTile(p, _doorTiles)

func isDoorShut(p: Vector2i) -> bool:
	return isDoor(p) and (_fore.get_cell_atlas_coords(0, p) == Vector2i.ZERO)

func clearFore(p: Vector2i) -> void:
	_setFore(p, INVALID_CELL)

func isForeInvalid(p: Vector2i) -> bool:
	return _fore.get_cell(p) == INVALID_CELL

func verifyCliff() -> void:
	var rect := _back.get_used_rect()
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var p = Vector2i(x, y)
			if isCliff(p) and not isFloor(Vector2i(x, y - 1)):
				clearFore(p)

#endregion

#region Flower

func setFlower(p: Vector2i) -> void:
	_setRandomTile(_flower, p, Tile.OutsideFlower, Random.nextBool())

#endregion

#region Tree

func setTree(p: Vector2i) -> void:
	var coord := Vector2(Random.next(3), 0)
	_tree.set_cell(0, p, Tile.TreeBack, coord)
	_top.set_cell(0, Vector2i(p.x, p.y - 1), Tile.TreeFore, coord)

func setTreeStump(p: Vector2i) -> void:
	_setRandomTile(_tree, p, Tile.TreeStump, Random.nextBool())

func clearTree(p: Vector2i) -> void:
	_tree.set_cell(0, p, INVALID_CELL)
	_top.set_cell(0, Vector2i(p.x, p.y - 1), INVALID_CELL)

func cutTree(p: Vector2i) -> void:
	clearTree(p)
	setTreeStump(p)

#endregion

#region Water

func setWaterShallow(p: Vector2i) -> void:
	_waterBack.set_cell(0, p, Tile.WaterShallowBack)
	_waterFore.set_cell(0, p, Tile.WaterShallowFore)

func setWaterDeep(p: Vector2i) -> void:
	_waterBack.set_cell(0, p, Tile.WaterDeepBack)
	_waterFore.set_cell(0, p, Tile.WaterDeepFore)

func setWaterShallowPurple(p: Vector2i) -> void:
	_waterBack.set_cell(0, p, Tile.WaterShallowBackPurple)
	_waterFore.set_cell(0, p, Tile.WaterShallowForePurple)

func setWaterDeepPurple(p: Vector2i) -> void:
	_waterBack.set_cell(0, p, Tile.WaterDeepBackPurple)
	_waterFore.set_cell(0, p, Tile.WaterDeepForePurple)

func _isWaterTile(p: Vector2i, tiles: Array) -> bool:
	return isTileId(_waterBack.get_cell(p), tiles)

func isWater(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterTiles)

func isWaterDeep(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterDeepTiles)

func isWaterPurple(p: Vector2i) -> bool:
	return _isWaterTile(p, _waterPurpleTiles)

#endregion

#region Item

# TODO: flip and rotate in alternate now?
func _setItemFore(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_itemFore.set_cell(0, p, tile, coord)

func _setItemForeRandom(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_itemFore, p, tile, flipX, flipY, rot90)

# TODO: flip and rotate in alternate now?
func _setItemBack(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false, coord := Vector2.ZERO) -> void:
	_itemBack.set_cell(0, p, tile, coord)

func _setItemBackRandom(p: Vector2i, tile: int, flipX := false, flipY := false, rot90 := false) -> void:
	_setRandomTile(_itemBack, p, tile, flipX, flipY, rot90)

#endregion

#region Split

# TODO: flip and rotate in alternate now?
func setGrass(p: Vector2i) -> void:
	var flipX = Random.nextBool()
	# if desert:
	# 	_splitBack.set_cell(0, p, Tile.OutsideDayGrassDry if day else Tile.OutsideNightGrassDry, flipX, false, false, Vector2(0, 0))
	# 	_splitFore.set_cell(0, p, Tile.OutsideDayGrassDry if day else Tile.OutsideNightGrassDry, flipX, false, false, Vector2(1, 0))
	# else:
	# 	_splitBack.set_cell(x, y, Tile.OutsideDayGrassGreen if day else Tile.OutsideNightGrassGreen, flipX, false, false, Vector2(0, 0))
	# 	_splitFore.set_cell(x, y, Tile.OutsideDayGrassGreen if day else Tile.OutsideNightGrassGreen, flipX, false, false, Vector2(1, 0))

#endregion

#region Light

func _getLight(p: Vector2i) -> int:
	return _tileMap.get_cell(Layer.Light, 0, p).x
	# return _light.get_cell_atlas_coords(0, p).x

func _setLight(p: Vector2i, light: int, test: bool) -> void:
	if not test or light > _getLight(p):
		_tileMap.set_cell(Layer.Light, 0, p, Tile.Light, Vector2(light, 0))

func isExplored(p: Vector2i) -> bool:
	return _getLight(p) == _lightExplored

func isLit(p: Vector2i) -> bool:
	return _getLight(p) > _lightExplored

#endregion


#region Edge

# TODO: flip and rotate in alternate now?
func _drawEdge() -> void:
	var rect := _back.get_used_rect()
	# var minY: int = rect.position.y - 1
	# var maxY: int = rect.end.y
	# var minX: int = rect.position.x - 1
	# var maxX: int = rect.end.x
	# for y in range(minY, maxY + 1):
	# 	for x in range(minX, maxX + 1):
	# 		if x == minX or x == maxX or y == minY or y == maxY:
	# 			if x == minX and y == minY: # nw
	# 				_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(1, 0))
	# 			elif x == minX and y == maxY: # sw
	# 				_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(2, 0))
	# 			elif x == maxX and y == minY: # ne
	# 				_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(0, 0))
	# 			elif x == maxX and y == maxY: # se
	# 				_edge.set_cell(x, y, Tile.EdgeOutsideCorner, false, false, false, Vector2(3, 0))
	# 			elif x == minX: # w
	# 				_setRandomTile(_edge, x, y, Tile.EdgeOutside, false, Random.nextBool(), true)
	# 			elif x == maxX: # e
	# 				_setRandomTile(_edge, x, y, Tile.EdgeOutside, true, Random.nextBool(), true)
	# 			elif y == minY: # n
	# 				_setRandomTile(_edge, x, y, Tile.EdgeOutside, Random.nextBool(), false, false)
	# 			elif y == maxY: # s
	# 				_setRandomTile(_edge, x, y, Tile.EdgeOutside, Random.nextBool(), true, false)
	# 		elif (x == minX + 1) or (x == maxX - 1) or (y == minY + 1) or (y == maxY - 1):
	# 			if x == minX + 1 and y == minY + 1: # nw
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, false, false, false)
	# 			elif x == minX + 1 and y == maxY - 1: # sw
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, false, true, false)
	# 			elif x == maxX - 1 and y == minY + 1: # ne
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, true, false, true)
	# 			elif x == maxX - 1 and y == maxY - 1: # se
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInsideCorner, true, true, false)
	# 			elif x == minX + 1: # w
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInside, false, Random.nextBool(), true)
	# 			elif x == maxX - 1: # e
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInside, true, Random.nextBool(), true)
	# 			elif y == minY + 1: # n
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInside, Random.nextBool(), false, false)
	# 			elif y == maxY - 1: # s
	# 				_setRandomTile(_edge, x, y, Tile.EdgeInside, Random.nextBool(), true, false)

#endregion
