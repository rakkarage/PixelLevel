extends Node
class_name Generate

var _level : Level
export var priority = 1
var _depth := 0
var _width := 0
var _height := 0
var _theme := 0
var _cliff := false
var _stream := false
const _torch := 0.03
const _fancy := 0.03
var _wonky := false
var _room := false

func setup(level: Level) -> void:
	_level = level

func generate() -> void:
	assert(_level != null)
	_clear()
	_depth += 1
	var d := 10 + _depth
	_setLevelRect(d * 2 + Random.next(d), d * 2 + Random.next(d))
	_theme = Random.next(2)
	_cliff = Random.nextFloat() < 0.333
	_stream = Random.nextFloat() < 0.333
	_wonky = Random.nextBool()
	_room = Random.nextBool()
	_level.theme = Random.next(_level.themeCount)
	_level.themeCliff = Random.next(_level.themeCliffCount)

func _setLevelRect(width: int, height: int) -> void:
	_width = width
	_height = height
	_level.rect = Rect2(_level.rect.position, Vector2(_width, _height))

func _clear() -> void:
	_level.clear()

func _fill(wall: bool, wallEdge: bool) -> void:
	for y in range(_height):
		for x in range(_width):
			_setFloorOrRoom(x, y)
			if wall:
					if _cliff:
						_setCliff(x, y)
					else:
						_setWallPlain(x, y)
					_level.clearBack(x, y)
			elif wallEdge:
				if y == 0 or y == _height - 1 or x == 0 or x == _width - 1:
					if _cliff:
						_setCliff(x, y)
					else:
						_setWall(x, y)
					_level.clearBack(x, y)

func _stairs() -> void:
	var up := _findSpot()
	_level.startAt = up
	_setStairUpV(up)
	_setStairDownV(_findSpot())

func _stairsAt(array: Array) -> void:
	var up = Utility.position(array[Random.next(array.size())], _width)
	_level.startAt = up
	_setStairUpV(up)
	var down = Utility.position(array[Random.next(array.size())], _width)
	while _level.isStairV(down):
		down = Utility.position(array[Random.next(array.size())], _width)
	_setStairDownV(down)

func _findX() -> int:
	return Random.nextRange(1, _width - 2)

func _findY() -> int:
	return Random.nextRange(1, _height - 2)

func _findSpot() -> Vector2:
	var x := _findX()
	var y := _findY()
	while _level.isWall(x, y) or _level.isStair(x, y) or not _level.isFloor(x, y):
		x = _findX()
		y = _findY()
	return Vector2(x, y)

func _setFloorOrRoomV(p: Vector2) -> void:
	_setFloorOrRoom(int(p.x), int(p.y))

func _setFloorOrRoom(x: int, y: int) -> void:
	if _room:
		_setFloorRoom(x, y)
	else:
		_setFloor(x, y)

func _setFloor(x: int, y: int) -> void:
	var flipX := Random.nextBool() if _wonky else false
	var flipY := Random.nextBool() if _wonky else false
	var rot90 := Random.nextBool() if _wonky else false
	_level.setFloor(x, y, flipX, flipY, rot90)

func _setFloorRoom(x: int, y: int) -> void:
	var flipX := Random.nextBool() if _wonky else false
	var flipY := Random.nextBool() if _wonky else false
	var rot90 := Random.nextBool() if _wonky else false
	_level.setFloorRoom(x, y, flipX, flipY, rot90)

func _setWallPlainV(p: Vector2) -> void:
	_setWallPlain(int(p.x), int(p.y))

func _setWallPlain(x: int, y: int) -> void:
	if _cliff:
		_setCliff(x, y)
	else:
		var flipX := Random.nextBool()
		_level.setWallPlain(x, y, flipX)

func _setWallV(p: Vector2) -> void:
	_setWall(int(p.x), int(p.y))

func _setWall(x: int, y: int) -> void:
	if _cliff:
		_setCliff(x, y)
	else:
		var flipX := Random.nextBool()
		if Random.nextFloat() < _torch:
			_level.setTorch(x, y, flipX)
		else:
			if Random.nextFloat() < _fancy:
				_level.setWall(x, y, flipX)
			else:
				_level.setWallPlain(x, y, flipX)

func _setStairUpV(p: Vector2) -> void:
	_setStairUp(int(p.x), int(p.y))

func _setStairUp(x: int, y: int) -> void:
	_level.setStairUp(x, y, Random.nextBool())

func _setStairDownV(p: Vector2) -> void:
	_setStairDown(int(p.x), int(p.y))

func _setStairDown(x: int, y: int) -> void:
	_level.setStairDown(x, y, Random.nextBool())

func _setCliff(x: int, y: int) -> void:
	_level.setCliff(x, y, Random.nextBool())

func _setDoor(x: int, y: int) -> void:
	_level.setDoor(x, y, Random.nextBool())

func _setDoorBroke(x: int, y: int) -> void:
	_level.setDoorBroke(x, y, Random.nextBool())

func _generateStreams() -> void:
	if Random.nextFloat() < 0.333:
		_generateStream(true)
		_generateStream(false)
	elif Random.nextBool():
		_generateStream(Random.nextBool())
		if Random.nextBool():
			_generateStream(Random.nextBool())
	else:
		_generateStream(Random.nextBool())

const _leaveChance := 0.333
const _leaveNoneChance := 0.333
var _leaveNone := false

func _generateStream(horizontal: bool) -> void:
	_leaveNone = Random.nextFloat() < _leaveNoneChance
	var roughness = Random.nextFloat()
	var windyness = Random.nextFloat()
	var width = 3 + Random.next(5)
	var half = int(width / 2.0)
	var start
	var rect
	var opposite = Random.nextBool()
	if horizontal:
		var tempY = 2 + half + Random.next(_height - 4 - half)
		start = Vector2(_width - 1 if opposite else 0, tempY)
		rect = Rect2(start.x, tempY - half, 1, width)
	else:
		var tempX = 2 + half + Random.next(_width - 4 - half)
		start = Vector2(tempX, _height - 1 if opposite else 0)
		rect = Rect2(tempX - half, start.y, width, 1)
	_fillStream(rect)
	while ((start.x > 0 if horizontal else start.y > 0) if opposite else
		(start.x < _width - 1 if horizontal else start.y < _height - 1)):
		if horizontal:
			start.x += -1 if opposite else 1
		else:
			start.y += -1 if opposite else 1
		if Random.nextFloat() < roughness:
			var add = -2 + Random.next(5)
			width += add
			if horizontal:
				if width > _height:
					width = _height
			else:
				if width > _width:
					width = _width
			if width < 3:
				width = 3
			half = int(width / 2.0)
		if Random.nextFloat() < windyness:
			var add = -1 + Random.next(3)
			if horizontal:
				start.y += add
				if start.y > _height - 2:
					start.y = _height - 1
				elif start.y < 2:
					start.y = 2
			else:
				start.x += add
				if start.x > _width - 2:
					start.x = _width - 2
				elif start.x < 2:
					start.x = 2
		if horizontal:
			rect = Rect2(start.x, start.y - half, 1, width)
		else:
			rect = Rect2(start.x - half, start.y, width, 1)
		_fillStream(rect)

func _fillStream(rect: Rect2) -> void:
	var horizontal = rect.size.x == 1
	var deepWidth = int(rect.size.y / 3.0 if horizontal else rect.size.x / 3.0)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var deep = false
			if horizontal:
				if y >= rect.position.y + deepWidth && y < rect.end.y - deepWidth:
					deep = true
			else:
				if x >= rect.position.x + deepWidth && x < rect.end.x - deepWidth:
					deep = true
			if _level.insideMap(x, y) and _level.isFloor(x, y) or _level.isWall(x, y):
				var keep = false
				if _level.isWall(x, y):
					if _leaveNone or Random.nextFloat() > _leaveChance:
						_level.setRubble(x, y)
						_setFloorOrRoom(x, y)
					else:
						keep = true
				elif _level.isDoor(x, y):
					_setDoorBroke(x, y)
				if not keep:
					var alreadyDeep = _level.isWaterDeep(x, y)
					if deep or alreadyDeep:
						if not alreadyDeep:
							_level.setWaterDeep(x, y)
					else:
						_level.setWaterShallow(x, y)

func _findRoom(rect: Rect2) -> Rect2:
	var px := Random.nextRange(int(rect.position.x), int(rect.position.x + rect.size.x / 2.0 - 2))
	var py := Random.nextRange(int(rect.position.y), int(rect.position.y + rect.size.y / 2.0 - 2))
	var sx := Random.nextRange(4, int(rect.end.x - px))
	var sy := Random.nextRange(4, int(rect.end.y - py))
	return Rect2(px, py, sx, sy)

func _drawRoom(rect: Rect2) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if (x == rect.position.x or x == rect.end.x - 1 or
				y == rect.position.y or y == rect.end.y - 1):
				_setWall(x, y)
			else:
				_level.clearFore(x, y)
				_setFloorOrRoom(x, y)
