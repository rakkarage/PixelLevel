extends Node

onready var _level : Level = $Viewport

var _depth := 0
var _width := 0
var _height := 0
var _theme := 0
var _cliff := 0.0
const _torch := 0.03
const _fancy := 0.03
var _wonky := false
var _room := false

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

var _generator = {
	# funcref(self, "_generateBasic"): 10,
	# funcref(self, "_generateSingleRoom"): 1,
	funcref(self, "_generateDungeon"): 1,
	# funcref(self, "_generateCrossroad"): 1,
	# funcref(self, "_generateMaze"): 1,
	# funcref(self, "_generateBuilding"): 1,
	# funcref(self, "_generateCave"): 1,
	# funcref(self, "_generateTemplate"): 1,
	# funcref(self, "_generateTemplateCastle"): 1
}

func _getGenerator() -> FuncRef:
	return _getPriority(_generator) as FuncRef

func _getPriority(d: Dictionary) -> Object:
	var o
	var total := 0
	for value in d.values():
		total += value
	var selected := Random.next(total)
	var current := 0
	for key in d.keys():
		o = key
		current += d[key]
		if current > selected:
			return o
	return o

func _generate() -> void:
	_clear()
	_depth += 1
	var d := 10 + _depth
	_setLevelRect(d * 2 + Random.next(d), d * 2 + Random.next(d))
	_theme = Random.next(2)
	_cliff = Random.nextFloat() < 0.333
	_wonky = Random.nextBool()
	_room = Random.nextBool()
	_level.theme = Random.next(_level.themeCount)
	_level.themeCliff = Random.next(_level.themeCliffCount)
	_getGenerator().call_func()

func _setLevelRect(width: int, height: int) -> void:
	_width = width
	_height = height
	_level.rect = Rect2(_level.rect.position, Vector2(_width, _height))

func _clear() -> void:
	_level.clear()

func _fill(wall: bool, wallEdge: bool) -> void:
	for y in range(_height):
		for x in range(_width):
			if _room:
				_setFloorRoom(x, y)
			else:
				_setFloor(x, y)
			if wall:
				_setWallPlain(x, y)
			elif wallEdge:
				if y == 0 or y == _height - 1 or x == 0 or x == _width - 1:
					if _cliff:
						_setCliff(x, y)
					else:
						_setWall(x, y)

func _start() -> void:
	var up := _findSpot()
	_level.startAt = up
	_setStairUpV(up)
	_setStairDownV(_findSpot())

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

func _generateBasic() -> void:
	_fill(false, Random.nextBool())
	_start()
	_level.generated()

func _generateSingleRoom() -> void:
	_setLevelRect(10, 10)
	_fill(true, false)
	_drawRoom(_findRoom(_level.rect))
	_start()
	_level.generated()

func _generateDungeon() -> void:
	var width = _maxRoomWidth * (1 + Random.next(9))
	var height = _maxRoomHeight * (1 + Random.next(9))
	_setLevelRect(width, height)
	_fill(true, false)
	var rooms := _placeRooms()
	_placeTunnels(rooms)
	_start()
	_level.generated()

func _findRoom(rect: Rect2) -> Rect2:
	var px := Random.nextRange(int(rect.position.x), int(rect.size.x / 2.0 - 2))
	var py := Random.nextRange(int(rect.position.x), int(rect.size.y / 2.0 - 2))
	var ex := Random.nextRange(px + 4, int(rect.end.x - px))
	var ey := Random.nextRange(py + 4, int(rect.end.y - py))
	return Rect2(Vector2(px, py), Vector2(ex, ey))

func _drawRoom(rect: Rect2) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if (x == rect.position.x or x == rect.end.x - 1 or
				y == rect.position.y or y == rect.end.y - 1):
				_setWall(x, y)
			else:
				_level.clearFore(x, y)

const _maxRoomWidth := 7
const _maxRoomHeight := 7
const _minRoomWidth := 4
const _minRoomHeight := 4

func _placeRooms() -> Array:
	var across := int((_width) / float(_maxRoomWidth))
	var down := int((_height) / float(_maxRoomHeight))
	var maxRooms := across * down
	var used := []
	for _i in range(maxRooms):
		used.append(false)
	var actual := 1 + Random.next(maxRooms - 1)
	var rooms := []
	var fill = Random.nextBool()
	var roomIndex := 0
	for i in range(actual):
		var usedRoom := true;
		while usedRoom:
			roomIndex = Random.next(maxRooms)
			usedRoom = used[roomIndex]
		used[roomIndex] = true
		var w := _maxRoomWidth if fill else Random.nextRange(_minRoomWidth, _maxRoomWidth)
		var h := _maxRoomHeight if fill else Random.nextRange(_minRoomHeight, _maxRoomHeight)
		var p = _position(i, across) * Vector2(_maxRoomWidth, _maxRoomHeight)
		if not fill:
			p.x += _maxRoomWidth - w / 2.0
			p.y += _maxRoomHeight - h / 2.0
		var room := Rect2(p.x, p.y, w, h)
		_drawRoom(room)
		rooms.append(room)
	return rooms

func _index(p: Vector2, w: int) -> int:
	return int(p.y * w + p.x)

func _position(i: int, w: int) -> Vector2:
	var y := int(i / float(w))
	var x := int(i - w * y)
	return Vector2(x, y)

# FIXME: Warrior needs food, badly!
func _placeTunnels(_rooms: Array) -> void:
	var deltaXSign := 0
	var deltaYSign := 0
	var current : Rect2
	var delta := Vector2.ZERO
	for room in _rooms:
		if current.size == Vector2.ZERO:
			current = room
			continue
		var currentCenter := current.position + current.size / 2.0
		var roomCenter : Vector2 = room.position + room.size / 2.0
		delta = roomCenter - currentCenter
		print(delta)
		if is_equal_approx(delta.x, 0):	deltaXSign = 1
		else: deltaXSign = int(delta.x / abs(delta.x))
		if is_equal_approx(delta.y, 0): deltaYSign = 1
		else: deltaYSign = int(delta.y / abs(delta.y))
		while not (is_equal_approx(delta.x, 0) and is_equal_approx(delta.y, 0)):
			var movingX := Random.nextBool()
			if movingX and is_equal_approx(delta.x, 0): movingX = false
			if not movingX and is_equal_approx(delta.y, 0): movingX = true
			var carveLength := Random.nextRange(1, int(abs(delta.x if movingX else delta.y)));
			for _i in range(carveLength):
				if movingX: currentCenter.x += deltaXSign * 1
				else: currentCenter.y += deltaYSign * 1
				if not is_equal_approx(currentCenter.x, 1) and not is_equal_approx(currentCenter.y, 1):
					if _level.isWallV(currentCenter):
						# setFloorV(p)
						_level.clearForeV(currentCenter)
			if movingX: delta.x -= deltaXSign * carveLength
			else: delta.y -= deltaYSign * carveLength
		current = room;

func _generateCrossroad() -> void:
	_fill(false, true)
	_level.generated()

func _generateMaze() -> void:
	_fill(false, true)
	_level.generated()

func _generateBuilding() -> void:
	_fill(false, true)
	_level.generated()

func _generateCave() -> void:
	_fill(false, true)
	_level.generated()

func _generateTemplate() -> void:
	_fill(false, true)
	_level.generated()

func _generateTemplateCastle() -> void:
	_fill(false, true)
	_level.generated()

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

func _setWallPlain(x: int, y: int) -> void:
	var flipX := Random.nextBool()
	_level.setWallPlain(x, y, flipX)

func _setWall(x: int, y: int) -> void:
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

func _generateStream(horizontal: bool) -> void:
	var roughness = Random.nextFloat()
	var windyness = Random.nextFloat()
	var width = 3 + Random.next(5)
	var half = int(width / 2.0)
	var start
	var rect
	var opposite = Random.nextBool()
	if horizontal:
		var tempY = 2 + half + Random.next(_height - 4 - half)
		start = Vector2(_width - 3 if opposite else 2, tempY)
		rect = Rect2(start.x, tempY - half, 1, width)
	else:
		var tempX = 2 + half + Random.next(_width - 4 - half)
		start = Vector2(tempX, _height - 3 if opposite else 2)
		rect = Rect2(tempX - half, start.y, width, 1)
	_fillStream(rect)
	while ((start.x > 2.0 if horizontal else start.y > 2.0) if opposite else
		(start.x < _width - 3 if horizontal else start.y < _height - 3)):
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
	var deepWodth = rect.size.x / 3.0 if horizontal else rect.size.y / 3.0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var deep = false
			if horizontal:
				if y >= deepWodth && y < rect.end.y - deepWodth:
					deep = true
			else:
				if x >= deepWodth && x < rect.end.x - deepWodth:
					deep = true
			if _level.insideMap(x, y):
				var keep = false
				if not _level.isWall(x, y):
					if Random.nextFloat() < 0.333:
						_level.setRubble(x, y)
					else:
						keep = true
				elif _level.isDoor(x, y):
					_level.setDoorBroke(x, y)
				if not keep:
					var alreadyDeep = _level.isWaterDeep(x, y)
					if deep or alreadyDeep:
						if not alreadyDeep:
							_level.setWaterDeep(x, y)
						else:
							_level.setWaterShallow(x, y)
