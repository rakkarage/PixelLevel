extends Generate
class_name GenerateCave

const _standardChance := 0.4
const _standardBirth := 4
const _standardDeath := 3
const _standardSteps := 10
var _outside := false
var _outsideWall := false

func _init(level: LevelBase) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_outside = Random.nextBool()
	_outsideWall = Random.nextBool()
	_fill(true, true, _outside)
	_drawCaves()
	if _outside:
		_drawOutside()
	if _stream:
		_generateStreams()
	_level.generated()

func _drawCaves() -> void:
	var list : Array
	while list.size() == 0 or not _bigEnough(list):
		list = _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
		if Random.nextBool():
			_removeSmall(list)
		if Random.nextBool():
			var other := _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
			if Random.nextBool():
				_removeSmall(other)
			_combineLists(list, other)
	for y in range(_height):
		for x in range(_width):
			var p := Vector2i(x, y)
			if list[Utility.index(p, _width)]:
				if _cliff:
					_level.setCliff(p)
				else:
					if _outside and _outsideWall:
						_setOutsideWall(p)
					else:
						_setWallPlain(p)
			else:
				_level.clearFore(p)
				if _outside:
					_setOutside(p)
				else:
					if _room:
						_level.setFloorRoom(p)
					else:
						_level.setFloor(p)
	if not _outside or not _outsideWall:
		_outlineCaves(list)
	_stairsAt(_biggest(list))

func _getAdjacentCount(list: Array, p: Vector2i) -> int:
	var count := 0
	for yy in range(-1, 2):
		for xx in range(-1, 2):
			if not ((xx == 0) and (yy == 0)):
				var new := Vector2(xx + p.x, yy + p.y)
				if _level.insideMapV(new):
					if list[Utility.indexV(new, _width)]:
						count += 1
				else:
					count += 1
	return count

func _getCellularList(steps: int, chance: float, birth: int, death: int) -> Array:
	var list := Utility.arrayRepeat(false, _width * _height)
	for i in range(list.size()):
		list[i] = Random.nextFloat() <= chance
	for _i in range(steps):
		var temp := Utility.arrayRepeat(false, _width * _height)
		for y in range(_height):
			for x in range(_width):
				var p := Vector2i(x, y)
				var adjacent := _getAdjacentCount(list, p)
				var index := _level._index(p, _width)
				var value: bool = list[index]
				if value:
					value = value and adjacent >= death
				else:
					value = value or adjacent > birth
				temp[index] = value
		list = temp.duplicate()
	if steps > 0 and Random.nextBool():
		_removeSmall(list)
	return list

func _combineLists(destination: Array, source: Array) -> void:
	var random := Random.nextBool()
	for y in range(_height):
		for x in range(_width):
			var index := _level._index(Vector2i(x, y), _width)
			destination[index] = (destination[index] and source[index]) if random else (destination[index] or source[index])

func _biggest(list: Array) -> Array:
	var disjointSet := _disjointSetup(list)
	var caves := disjointSet.split(list)
	_removeSmallCaves(caves, list)
	return caves.values()[0]

func _bigEnough(list: Array) -> bool:
	return _biggest(list).size() > 4

# TODO: should this go with disjoint set / naw replace that anyway
func _unionAdjacent(disjointSet: DisjointSet, list: Array, p: Vector2i) -> void:
	for yy in range(-1, 2):
		for xx in range(-1, 2):
			var new = Vector2i(p.x + xx, p.y + yy)
			if not ((xx == 0) and (yy == 0)) and _level.insideMap(new):
				var index1 := _level._index(new, _width)
				if not list[index1]:
					var root1 := disjointSet.find(index1)
					var index0 := _level._index(p, _width)
					var root0 := disjointSet.find(index0)
					if root0 != root1:
						disjointSet.union(root0, root1)

func _disjointSetup(list: Array) -> DisjointSet:
	var disjointSet := DisjointSet.new(_width * _height)
	for y in range(_height):
		for x in range(_width):
			var p := Vector2i(x, y)
			if not list[Utility.index(p, _width)]:
				_unionAdjacent(disjointSet, list, p)
	return disjointSet

func _removeSmall(list: Array) -> void:
	_removeSmallCaves(_disjointSetup(list).split(list), list)

func _removeSmallCaves(caves: Dictionary, list: Array) -> void:
	var biggest := 0
	var biggestKey := 0
	for key in caves.keys():
		var size: int = caves[key].size()
		if size > biggest:
			biggest = size
			biggestKey = key
	var delete := []
	for key in caves.keys():
		if key != biggestKey:
			delete.append(key)
	for key in delete:
		if list != null:
			var cave: Array = caves[key]
			for i in cave:
				list[i] = true
		caves.erase(key)

func _isCaveEdge(list: Array, p: Vector2i) -> bool:
	var edge := false
	for yy in range(-1, 2):
		for xx in range(-1, 2):
			if not ((xx == 0) and (yy == 0)):
				var new := Vector2(p.x + xx, p.y + yy)
				if _level.insideMapV(new) and not list[Utility.indexV(new, _width)]:
					edge = true
	return edge

func _outlineCaves(list: Array) -> void:
	for y in range(_height):
		for x in range(_width):
			var p := Vector2i(x, y)
			if list[Utility.index(p, _width)]:
				if _isCaveEdge(list, p):
					_setWall(p)

func _drawOutside() -> void:
	if not _level.desert:
		if Random.nextBool():
			_drawFlowers()
		if Random.nextBool():
			_drawTrees()
		if Random.nextBool():
			_drawGrass()

func _drawFlowers() -> void:
	var array := _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
	if Random.nextBool():
		_removeSmall(array)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not array[Utility.index(p, _width)] and (not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p)):
				_level.setFlower(p)

func _drawTrees() -> void:
	var steps := Random.next(_standardSteps)
	var array := _getCellularList(steps, _standardChance, _standardBirth, _standardDeath)
	if Random.nextBool():
		_removeSmall(array)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			var index := _level._index(p, _width)
			if not array[index] and (not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p)):
				if steps == 0 and Random.nextBool():
					_level.setTreeStump(p)
				else:
					_level.setTree(p)
	if steps > 0 and Random.nextBool():
		_cutTrees(array)

func _cutTrees(array: Array) -> void:
	var disjointSet := _disjointSetup(array)
	var caves := disjointSet.split(array)
	for key in caves:
		var cave = caves[key]
		if Random.next(3) == 0: # cut
			if Random.next(4) == 0: # all
				for i in cave:
					_level.cutTreeV(Utility.position(i, _width))
			elif Random.nextBool(): # some
				var direction := Random.next(4)
				var test := _level._position(cave[Random.next(cave.size())], _width)
				for i in cave:
					var p := _level._position(i, _width)
					match direction:
						0:
							if p.x > test.x:
								_level.cutTreeV(p)
							elif is_equal_approx(p.x, test.x):
								if Random.nextBool():
									_level.cutTreeV(p)
						1:
							if p.x < test.x:
								_level.cutTreeV(p)
							elif is_equal_approx(p.x, test.x):
								if Random.nextBool():
									_level.cutTreeV(p)
						2:
							if p.y > test.y:
								_level.cutTreeV(p)
							elif is_equal_approx(p.y, test.y):
								if Random.nextBool():
									_level.cutTreeV(p)
						3:
							if p.y < test.y:
								_level.cutTreeV(p)
							elif is_equal_approx(p.y, test.y):
								if Random.nextBool():
									_level.cutTreeV(p)

func _drawGrass() -> void:
	var array := _getCellularList(Random.next(_standardSteps), _standardChance, _standardBirth, _standardDeath)
	if Random.nextBool():
		_removeSmall(array)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not array[Utility.index(p, _width)] and (not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p)):
				_level.setGrass(p)

func _printArray(array: Array) -> void:
	var output := ""
	for y in range(_height):
		for x in range(_width):
			output += "1" if array[Utility.index(Vector2i(x, y), _width)] else "0"
		output += "\n"
	output += "\r"
	print(output)
