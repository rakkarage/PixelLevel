extends Object
class_name Generate

var _level : LevelBase
@export var priority = 1
var _width := 0
var _height := 0
var _cliff := false
var _stream := false
const _torchChance := 0.01
const _fancyChance := 0.02
const _cliffChance := 0.333
const _streamChance := 0.22
var _wonky := false
var _room := false

func _init(level: LevelBase) -> void:
	_level = level

func generateUp() -> void:
	generate(-1)

func generate(delta: int = 1) -> void:
	_level.clear()
	_level._state.depth += delta
	var d: int = 10 + int(abs(_level._state.depth))
	_setLevelRect(d * 2 + Random.next(d), d * 2 + Random.next(d))
	_level.theme = Random.next(_level.themeCount)
	_level.day = Random.nextBool()
	_level.desert = Random.next(5) == 0
	_level.themeCliff = Random.next(_level.themeCliffCount)
	_cliff = Random.nextFloat() <= _cliffChance
	_stream = Random.nextFloat() <= _streamChance
	_wonky = Random.nextBool()
	_room = Random.nextBool()
	_level.themeCliff = Random.next(_level.themeCliffCount)

func regenerate() -> void:
	generate(0)

func _setLevelRect(width: int, height: int) -> void:
	_width = width
	_height = height
	_level.size = Vector2(_width, _height)

func _fill(wall: bool, wallEdge: bool, outside: bool = false) -> void:
	for y in range(_height):
		for x in range(_width):
			var p := Vector2i(x, y)
			if outside:
				_setOutside(p)
			else:
				_setFloorOrRoom(p)
			if wall:
				_setWallPlain(p)
			elif wallEdge:
				if y == 0 or y == _height - 1 or x == 0 or x == _width - 1:
					_setWall(p)

func _stairs() -> void:
	var up := _findSpot()
	_level.startAt = up
	_level.setStairUp(up)
	_level.setStairDown(_findSpot())

func _stairsAt(array: Array) -> void:
	var up = Utility.position(array[Random.next(array.size())], _width)
	_level.startAt = up
	_level.setStairUp(up)
	var down = Utility.position(array[Random.next(array.size())], _width)
	while _level.isStair(down):
		down = Utility.position(array[Random.next(array.size())], _width)
	_level.setStairDown(down)

func _random() -> Vector2i:
	return Vector2i(Random.nextRange(1, _width - 2), Random.nextRange(1, _height - 2))

func _findSpot() -> Vector2:
	var p := _random()
	while _level.isWall(p) or _level.isStair(p) or not _level.isFloor(p):
		p = _random()
	return p

func _setFloor(p: Vector2i) -> void:
	_level.setFloor(p, _wonky)
	_level.clearFore(p)

func _setFloorRoom(p: Vector2i) -> void:
	_level.setFloorRoom(p, _wonky)
	_level.clearFore(p)

func _setOutside(p: Vector2i) -> void:
	_level.setOutside(p)
	_level.clearFore(p)

func _setFloorOrRoom(p: Vector2i) -> void:
	if _room:
		_level.setFloorRoom(p, _wonky)
	else:
		_level.setFloor(p, _wonky)
	_level.clearFore(p)

func _setOutsideWall(p: Vector2i) -> void:
	_level.setOutsideWall(p)
	_level.clearBack(p)

func _setWallPlain(p: Vector2i) -> void:
	if _cliff:
		_level.setCliff(p)
	else:
		_level.setWallPlain(p)
	_level.clearBack(p)

func _setWall(p: Vector2i) -> void:
	if _cliff:
		_level.setCliff(p)
	else:
		if Random.nextFloat() <= _torchChance:
			_level.setTorch(p)
		else:
			if Random.nextFloat() <= _fancyChance:
				_level.setWall(p)
			else:
				_level.setWallPlain(p)
	_level.clearBack(p)

func _generateStreams() -> void:
	if Random.nextFloat() <= 0.333:
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
	_leaveNone = Random.nextFloat() <= _leaveNoneChance
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
		if Random.nextFloat() <= roughness:
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
		if Random.nextFloat() <= windyness:
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
			var p := Vector2i(x, y)
			var deep = false
			if horizontal:
				if y >= rect.position.y + deepWidth && y < rect.end.y - deepWidth:
					deep = true
			else:
				if x >= rect.position.x + deepWidth && x < rect.end.x - deepWidth:
					deep = true
			if _level.insideMap(p) and _level.isFloor(p) or _level.isWall(p):
				var keep = false
				if _level.isWall(p):
					if _leaveNone or Random.nextFloat() > _leaveChance:
						_level.setRubble(p)
						_level.clearFore(p)
					else:
						keep = true
				elif _level.isDoor(p):
					_level.setDoorBroke(p)
				if not keep:
					if not _level.isStair(p):
						_level.clearFore(p)
					var alreadyDeep = _level.isWaterDeep(p)
					if deep or alreadyDeep:
						if not alreadyDeep:
							_level.setWaterDeep(p)
					else:
						_level.setWaterShallow(p)

func _findRoom(rect: Rect2) -> Rect2:
	var px := Random.nextRange(int(rect.position.x), int(rect.position.x + rect.size.x / 2.0 - 2))
	var py := Random.nextRange(int(rect.position.y), int(rect.position.y + rect.size.y / 2.0 - 2))
	var sx := Random.nextRange(4, int(rect.end.x - px))
	var sy := Random.nextRange(4, int(rect.end.y - py))
	return Rect2(px, py, sx, sy)

func _drawRoom(rect: Rect2) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var p := Vector2i(x, y)
			if (x == rect.position.x or x == rect.end.x - 1 or
				y == rect.position.y or y == rect.end.y - 1):
				_setWall(p)
			else:
				_level.clearFore(p)
				_setFloorOrRoom(p)
