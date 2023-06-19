extends Generate
class_name GenerateCave

func _init(level: Level) -> void:
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
	var ca := CellularAutomaton.new(_width, _height)
	var caves := ca.generate()
	var biggest := ca.findBiggest(caves)
	if Random.nextBool():
		caves = ca.mapBiggest(biggest)
	while caves.size() < 4:
		caves = ca.generate()
		biggest = ca.findBiggest(caves)
		if Random.nextBool():
			caves = ca.mapBiggest(biggest)
	if Random.nextBool():
		var other = ca.generate()
		var otherBiggest = ca.findBiggest(other)
		if Random.nextBool():
			other = ca.mapBiggest(otherBiggest)
		caves = ca.combine(caves, other)
		biggest.append_array(otherBiggest.filter(func(index: int): return !biggest.has(index)))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if caves[Utility.flatten(p, _width)]:
				_setCaveWall(p)
			else:
				_setCaveFloor(p)
	if not _outside or not _outsideWall:
		_outlineCaves(caves)
	_stairsAt(biggest)

func _isCaveEdge(list: Array, position: Vector2i) -> bool:
	var edge := false
	for y in range(-1, 2):
		for x in range(-1, 2):
			var neighbor := Vector2i(position.x + x, position.y + y)
			if x == 0 and y == 0:
				continue
			elif neighbor.x < 0 or neighbor.x >= _width or neighbor.y < 0 or neighbor.y >= _height:
				continue
			if not list[Utility.flatten(neighbor, _width)]:
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
			_drawWeed()

func _drawFlowers() -> void:
	var ca := CellularAutomaton.new(_width, _height)
	var flowers := ca.generate()
	if Random.nextBool():
		flowers = ca.mapBiggest(ca.findBiggest(flowers))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not flowers[Utility.flatten(p, _width)] and not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p):
				_level.setFlower(p)

func _drawTrees() -> void:
	var cutSome := Random.nextFloat() < 0.333
	var cutPatch := Random.nextFloat() < 0.333
	var ca := CellularAutomaton.new(_width, _height)
	var trees := ca.generate()
	if Random.nextBool():
		trees = ca.mapBiggest(ca.findBiggest(trees))
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

func _drawWeed() -> void:
	var ca := CellularAutomaton.new(_width, _height)
	var grass := ca.generate()
	if Random.nextBool():
		grass = ca.mapBiggest(ca.findBiggest(grass))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not grass[Utility.flatten(p, _width)] and not _level.isWall(p) and not _level.isBackInvalid(p) and not _level.isStair(p):
				_level.setWeed(p)
