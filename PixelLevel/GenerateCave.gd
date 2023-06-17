extends Generate
class_name GenerateCave

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
	var caves := CellularAutomaton.generate(_width, _height)
	var biggest := _biggest(caves)
	if Random.nextBool():
		caves = _mapCave(biggest)
	while caves.size() < 4:
		caves = CellularAutomaton.generate(_width, _height)
		biggest = _biggest(caves)
		if Random.nextBool():
			caves = _mapCave(biggest)
	if Random.nextBool():
		var other = CellularAutomaton.generate(_width, _height)
		var otherBiggest = _biggest(other)
		if Random.nextBool():
			other = _mapCave(otherBiggest)
		caves = _combineLists(caves, other)
		biggest.append_array(otherBiggest.filter(func(index: int): return !biggest.has(index)))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if caves[Utility.flatten(p, _width)]:
				if _cliff:
					_level.setCliff(p)
				else:
					if _outside and _outsideWall:
						_setOutsideWall(p)
					else:
						_setWallPlain(p)
			else:
				if _outside:
					_setOutside(p)
				else:
					if _room:
						_setFloorRoom(p)
					else:
						_setFloor(p)
	if not _outside or not _outsideWall:
		_outlineCaves(caves)
	_stairsAt(biggest)

# returns array of index so can check size
func _biggest(caves: Array[bool]) -> Array:
	var disjointSet := DisjointSet.new(_width, _height)
	for i in _width * _height:
		if caves[i]:
			continue
		var position := Utility.unflatten(i, _width)
		for x in range(-1, 2):
			for y in range(-1, 2):
				if abs(x) + abs(y) != 1:
					continue
				var neighbor := Vector2i(position.x + x, position.y + y)
				if neighbor.x < 0 or neighbor.x >= _width or neighbor.y < 0 or neighbor.y >= _height:
					continue
				var neighborIndex := Utility.flatten(neighbor, _width)
				if not caves[neighborIndex]:
					disjointSet.union(i, neighborIndex)
	var arrays := disjointSet.split()
	if arrays.size() == 0: return []
	if arrays.size() == 1: return arrays[0]
	var maxSize := 0
	var biggest := []
	for array in arrays:
		if array.size() > maxSize:
			maxSize = array.size()
			biggest = array
	return biggest

# returns map sized array of bools to replace old grid
func _mapCave(cave: Array) -> Array[bool]:
	var map: Array[bool] = []
	for y in _height:
		for x in _width:
			map.append(Utility.flatten(Vector2i(x, y), _width) not in cave)
	print("map size: " + str(map.size()))
	CellularAutomaton._print(map, _width, _height)
	return map

func _combineLists(array1: Array[bool], array2: Array[bool]) -> Array[bool]:
	var result: Array[bool] = []
	for y in range(_height):
		for x in range(_width):
			var index := Utility.flatten(Vector2i(x, y), _width)
			result.append(not array1[index] and not array2[index])
	print("combine size: " + str(result.size()))
	CellularAutomaton._print(result, _width, _height)
	return result

func _isCaveEdge(list: Array, p: Vector2i) -> bool:
	var edge := false
	for yy in range(-1, 2):
		for xx in range(-1, 2):
			if not ((xx == 0) and (yy == 0)):
				var new := Vector2(p.x + xx, p.y + yy)
				if _level.insideMap(new) and not list[Utility.flatten(new, _width)]:
					edge = true
	return edge

func _outlineCaves(list: Array) -> void:
	for y in range(_height):
		for x in range(_width):
			var p := Vector2i(x, y)
			if list[Utility.flatten(p, _width)]:
				if _isCaveEdge(list, p):
					_setWall(p)

func _drawOutside() -> void:
	if not _level._desert:
		if Random.nextBool():
			print("drawing flowers")
			_drawFlowers()
		if Random.nextBool():
			print("drawing trees")
			_drawTrees()
		if Random.nextBool():
			print("drawing grass")
			_drawGrass()

func _drawFlowers() -> void:
	var flowers := CellularAutomaton.generate(_width, _height)
	var biggest := _biggest(flowers)
	if Random.nextBool():
		flowers = _mapCave(biggest)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not flowers[Utility.flatten(p, _width)] and not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p):
				_level.setFlower(p)

func _drawTrees() -> void:
	var cutSome := Random.nextFloat() < 0.333
	var cutPatch := Random.nextFloat() < 0.333
	var trees := CellularAutomaton.generate(_width, _height)
	var biggest := _biggest(trees)
	if Random.nextBool():
		trees = _mapCave(biggest)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not trees[Utility.flatten(p, _width)] and not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p):
				if cutSome and Random.nextBool():
					_level.setTreeStump(p)
				else:
					_level.setTree(p)
	if not cutSome and cutPatch and Random.nextBool():
		_cutTrees(trees)

func _cutTrees(array: Array) -> void:
	var disjointSet := DisjointSet.new(_width, _height, array)
	var caves := disjointSet.split()
	for cave in caves:
		if Random.next(3) == 0: # cut
			if Random.next(4) == 0: # cut all
				for i in cave:
					_level.cutTree(Utility.unflatten(i, _width))
			elif Random.nextBool(): # cut some
				var direction := Random.next(4)
				var test := Utility.unflatten(cave[Random.next(cave.size())], _width)
				for i in cave:
					var p := Utility.unflatten(i, _width)
					match direction:
						0:
							if p.x > test.x:
								_level.cutTree(p)
							elif p.x == test.x:
								if Random.nextBool():
									_level.cutTree(p)
						1:
							if p.x < test.x:
								_level.cutTree(p)
							elif p.x == test.x:
								if Random.nextBool():
									_level.cutTree(p)
						2:
							if p.y > test.y:
								_level.cutTree(p)
							elif p.y == test.y:
								if Random.nextBool():
									_level.cutTree(p)
						3:
							if p.y < test.y:
								_level.cutTree(p)
							elif p.y == test.y:
								if Random.nextBool():
									_level.cutTree(p)

func _drawGrass() -> void:
	var grass := CellularAutomaton.generate(_width, _height)
	var biggest := _biggest(grass)
	if Random.nextBool():
		grass = _mapCave(biggest)
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not grass[Utility.flatten(p, _width)] and not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p):
				_level.setGrass(p)
