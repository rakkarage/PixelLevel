extends Node

onready var _level : Level = $Viewport

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

func _ready() -> void:
	Utility.ok(_level.connect("generate", self, "_generate"))

var _generator = {
	# funcref(self, "_generateBasic"): 1,
	# funcref(self, "_generateSingleRoom"): 1,
	# funcref(self, "_generateDungeon"): 1,
	# funcref(self, "_generateMaze"): 1,
	funcref(self, "_generateCave"): 1,
	# funcref(self, "_generateTemplate"): 1,
	# funcref(self, "_generateTemplateCrossroad"): 1,
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
	_stream = Random.nextFloat() < 0.333
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

func _stairs() -> void:
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
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()

func _generateSingleRoom() -> void:
	_setLevelRect(10, 10)
	_fill(true, false)
	_drawRoom(_findRoom(_level.rect))
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()

func _generateDungeon() -> void:
	var width = _maxRoomWidth * (1 + Random.next(9))
	var height = _maxRoomHeight * (1 + Random.next(9))
	_setLevelRect(width, height)
	_fill(true, false)
	var rooms := _placeRooms()
	_placeTunnels(rooms)
	if _stream:
		_generateStreams()
	_stairs()
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
	var fill := Random.nextBool()
	var roomIndex := 0
	for i in range(actual):
		var usedRoom := true
		while usedRoom:
			roomIndex = Random.next(maxRooms)
			usedRoom = used[roomIndex]
		used[roomIndex] = true
		var w := _maxRoomWidth if fill else Random.nextRange(_minRoomWidth, _maxRoomWidth)
		var h := _maxRoomHeight if fill else Random.nextRange(_minRoomHeight, _maxRoomHeight)
		var p := _position(i, across) * Vector2(_maxRoomWidth, _maxRoomHeight)
		if not fill:
			p.x += _maxRoomWidth - w / 2.0
			p.y += _maxRoomHeight - h / 2.0
		var room := Rect2(p.x, p.y, w, h)
		_drawRoom(room)
		rooms.append(room)
	return rooms

func _indexV(p: Vector2, w: int) -> int:
	return _index(int(p.x), int(p.y), w)

func _index(x: int, y: int, w: int) -> int:
	return int(y * w + x)

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
		if is_equal_approx(delta.x, 0):	deltaXSign = 1
		else: deltaXSign = int(delta.x / abs(delta.x))
		if is_equal_approx(delta.y, 0): deltaYSign = 1
		else: deltaYSign = int(delta.y / abs(delta.y))
		while not (is_equal_approx(delta.x, 0) and is_equal_approx(delta.y, 0)):
			var movingX := Random.nextBool()
			if movingX and is_equal_approx(delta.x, 0): movingX = false
			if not movingX and is_equal_approx(delta.y, 0): movingX = true
			var carveLength := Random.nextRange(1, int(abs(delta.x if movingX else delta.y)))
			for _i in range(carveLength):
				if movingX: currentCenter.x += deltaXSign * 1
				else: currentCenter.y += deltaYSign * 1
				if not is_equal_approx(currentCenter.x, 1) and not is_equal_approx(currentCenter.y, 1):
					if _level.isWallV(currentCenter):
						# setFloorV(p)
						_level.clearForeV(currentCenter)
			if movingX: delta.x -= deltaXSign * carveLength
			else: delta.y -= deltaYSign * carveLength
		current = room

func _generateMaze() -> void:
	var depth := _depth + 10
	var width := Random.nextRangeOdd(depth, depth + Random.next(depth))
	var height := Random.nextRangeOdd(depth, depth + Random.next(depth))
	_setLevelRect(width, height)
	_fill(true, true)
	_drawMaze()
	if _stream:
		_generateStreams()
	_level.generated()

func _drawMaze() -> void:
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	var generate := Vector2.ZERO
	var g := Random.next(4)
	match g:
		0: generate = Vector2(1, 1)
		1: generate = Vector2(1, _height - 2)
		2: generate = Vector2(_width - 2, 1)
		3: generate = Vector2(_width - 2, _height - 2)
	_level.clearForeV(generate)
	var s = Random.next(4)
	match s:
		0:
			start = Vector2(1, 1)
			end = Vector2(_width - 2, _height - 2)
		1:
			start = Vector2(1, _height - 2)
			end = Vector2(_width - 2, 1)
		2:
			start = Vector2(_width - 2, 1)
			end = Vector2(1, _height - 2)
		3:
			start = Vector2(_width - 2, _height - 2)
			end = Vector2(1, 1)
	_level.startAt = start
	_level.setStairUpV(start)
	_level.setStairDownV(end)
	var points : PoolVector2Array = []
	points.append(generate)
	while points.size():
		var random := Random.next(points.size())
		var current : Vector2 = points[random]
		points.remove(random)
		var east := Vector2(current.x + 1, current.y)
		var eastEast := Vector2(current.x + 2, current.y)
		var west := Vector2(current.x - 1, current.y)
		var westWest := Vector2(current.x - 2, current.y)
		var north := Vector2(current.x, current.y + 1)
		var northNorth := Vector2(current.x, current.y + 2)
		var south := Vector2(current.x, current.y - 1)
		var southSouth := Vector2(current.x, current.y - 2)
		var eastChecked := false
		var westChecked := false
		var northChecked := false
		var southChecked := false
		while not eastChecked or not westChecked or not northChecked or not southChecked:
			match Random.next(4):
				0:
					eastChecked = true
					if (_level.isStairV(east) or _level.isWallV(east)) and (_level.isStairV(eastEast) or _level.isWallV(eastEast)):
						if not _level.isStairV(east):
							_level.clearForeV(east)
						if not _level.isStairV(eastEast):
							_level.clearForeV(eastEast)
						points.append(eastEast)
				1:
					westChecked = true
					if (_level.isStairV(west) or _level.isWallV(west)) and (_level.isStairV(westWest) or _level.isWallV(westWest)):
						if not _level.isStairV(west):
							_level.clearForeV(west)
						if not _level.isStairV(westWest):
							_level.clearForeV(westWest)
						points.append(westWest)
				2:
					northChecked = true
					if (_level.isStairV(north) or _level.isWallV(north)) and (_level.isStairV(northNorth) or _level.isWallV(northNorth)):
						if not _level.isStairV(north):
							_level.clearForeV(north)
						if not _level.isStairV(northNorth):
							_level.clearForeV(northNorth)
						points.append(northNorth)
				3:
					southChecked = true
					if (_level.isStairV(south) or _level.isWallV(south)) and (_level.isStairV(southSouth) or _level.isWallV(southSouth)):
						if not _level.isStairV(south):
							_level.clearForeV(south)
						if not _level.isStairV(southSouth):
							_level.clearForeV(southSouth)
						points.append(southSouth)

func _generateCave() -> void:
	_fill(false, true)
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()

func _getAdjacentCount(list: Array, x: int, y: int) -> int:
	var count := 0
	for yy in range(-1, 2):
		print(y)
		for xx in range(-1, 2):
			print(x)
			if not ((xx == 0) and (yy == 0)):
				var new = Vector2(xx + x, yy + y)
				if _level.insideMapV(new):
					if list[_indexV(new, _width)]:
						count += 1
				else:
					count += 1
	return count

func _getCellularList(steps: int, chance: float, birth: int, death: int) -> Array:
	var list := []
	for y in range(_height):
		for x in range(_width):
			list[_index(x, y, _width)] = Random.nextFloat() < chance
	for _i in range(steps):
		var temp := []
		for y in range(_height):
			for x in range(_width):
				var adjacent = _getAdjacentCount(list, x, y)
				var index = _index(x, y, _width)
				var value = list[index]
				if value:
					value = value and adjacent >= death
				else:
					value = value or adjacent > birth
				temp[index] = value
		list = temp.duplicate()
	# TODO: !?
	# if steps > 0 and Random.nextBool():
	# 	_removeSmall(list)
	return list

func _combineLists(destination: Array, source: Array) -> void:
	var random = Random.nextBool()
	for y in range(_height):
		for x in range(_width):
			var index = _index(x, y, _width)
			destination[index] = (destination[index] and source[index]) if random else (destination[index] or source[index])

const _standardChance := 0.4
const _standardBirth := 4
const _standardDeath := 3
const _standardSteps := 10

# func _drawCaves() -> void:
# 	var invert := Random.nextBool()
# 	var list : Array
# 	while not _bigEnough(list):
# 		list = _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
# 		if Random.nextBool():
# 			var other := _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
# 			_combineLists(list, other)
# 	for y in range(_height):
# 		for x in range(_width):
# 			var index := _index(x, y, _width)
# 			var value : bool = list[index]
# 			if not value if invert else value:
# 				_level.setWallPlain(x, y)
# 			else:
# 				_level.clearFore(x, y)
	# if Random.nextBool():
	# 	list = _outlineCaves(list)

# func _biggest(list: Array) -> Array:
# 	var disjointSet := _disjointSetup(list)
# 	var caves := disjointSet.split(list)
# 	_removeSmallCaves(list, caves)
# 	return caves[0]

# func _bigEnough(list: Array) -> bool:
# 	return _biggest(list).size() > 4

func _unionAdjacent(disjointSet: DisjointSet, list: Array, x: int, y: int) -> void:
	for yy in range(-1, 2):
		for xx in range(-1, 2):
			if not ((xx == 0) and (yy == 0)):
				var index1 = _index(xx, yy, _width)
				if list[index1]:
					var root1 = disjointSet.find(index1)
					var index0 = _index(x, y, _width)
					var root0 = disjointSet.find(index0)
					if root0 != root1:
						disjointSet.union(root0, root1)

func _disjointSetup(list: Array) -> DisjointSet:
	var disjointSet = DisjointSet.new(_width * _height)
	for y in range(_height):
		for x in range(_width):
			if list[_index(x, y, _width)]:
				_unionAdjacent(disjointSet, list, x, y)
	return disjointSet

# void OutlineCaves(ref List<bool> list)
# {
# 	var disjoint = DisjointSetup(ref list);
# 	var caves = disjoint.Split(ref list);
# 	foreach (var cave in caves)
# 	{
# 		foreach (var i in cave.Value)
# 		{
# 			var p = TilePosition(i);
# 			if (InsideEdge(p))
# 			{
# 				if (IsCaveEdge(ref list, p))
# 				{
# 					SetCaveEdge(p);
# 				}
# 			}
# 		}
# 	}
# }

# void RemoveSmallCaves(ref List<bool> list, Dictionary<int, List<int>> caves)
# {
# 	var biggest = 0;
# 	var biggestKey = 0;
# 	foreach (var cave in caves)
# 	{
# 		if (cave.Value.Count > biggest)
# 		{
# 			biggest = cave.Value.Count;
# 			biggestKey = cave.Key;
# 		}
# 	}
# 	var tbd = new List<int>();
# 	foreach (var cave in caves)
# 	{
# 		if (cave.Key != biggestKey)
# 		{
# 			tbd.Add(cave.Key);
# 		}
# 	}
# 	foreach (var key in tbd)
# 	{
# 		var cave = caves[key];
# 		FillCave(ref list, ref cave);
# 		caves.Remove(key);
# 	}
# }
# void FillCave(ref List<bool> list, ref List<int> cave)
# {
# 	foreach (var index in cave)
# 	{
# 		list[index] = false;
# 	}
# }
# void RemoveSmall(ref List<bool> list)
# {
# 	RemoveSmallCaves(ref list, DisjointSetup(ref list).Split(ref list));
# }
# bool IsCaveEdge(ref List<bool> list, Vector2 p)
# {
# 	var edge = false;
# 	for (var y = -1; y <= 1; y++)
# 	{
# 		for (var x = -1; x <= 1; x++)
# 		{
# 			if (!((x == 0) && (y == 0)))
# 			{
# 				var point = new Vector2(p.x + x, p.y + y);
# 				if (InsideMap(point))
# 				{
# 					var index = TileIndex(point);
# 					if (!list[index])
# 					{
# 						edge = true;
# 					}
# 				}
# 			}
# 		}
# 	}
# 	return edge;
# }
# void DrawArray(ref List<bool> list)
# {
# 	var sb = new StringBuilder();
# 	for (var y = Height - 1; y >= 0; y--)
# 	{
# 		for (var x = 0; x < Width; x++)
# 		{
# 			sb.Append(list[TileIndex(x, y)] ? 1 : 0);
# 		}
# 		sb.Append('\n');
# 	}
# 	sb.Append('\r');
# 	Debug.Log(sb);
# }

func _generateTemplate() -> void:
	_fill(false, true)
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()

func _generateTemplateCrossroad() -> void:
	_fill(false, true)
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()

func _generateTemplateCastle() -> void:
	_fill(false, true)
	if _stream:
		_generateStreams()
	_stairs()
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

func _generateStreams() -> void:
	if Random.nextFloat() < 0.333:
		_generateStream(true)
		_generateStream(false)
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
			if _level.insideMap(x, y) and _level.isFloor(x, y):
				var keep = false
				if _level.isWall(x, y):
					if _leaveNone or Random.nextFloat() < _leaveChance:
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
