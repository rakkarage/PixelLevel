extends Generate

func generate() -> void:
	.generate()
	_fill(false, true)
	_stairs()
	if _stream:
		_generateStreams()
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
					if list[Utility.indexV(new, _width)]:
						count += 1
				else:
					count += 1
	return count

func _getCellularList(steps: int, chance: float, birth: int, death: int) -> Array:
	var list := []
	for y in range(_height):
		for x in range(_width):
			list[Utility.index(x, y, _width)] = Random.nextFloat() < chance
	for _i in range(steps):
		var temp := []
		for y in range(_height):
			for x in range(_width):
				var adjacent = _getAdjacentCount(list, x, y)
				var index = Utility.index(x, y, _width)
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
			var index = Utility.i(x, y, _width)
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
				var index1 = Utility.i(xx, yy, _width)
				if list[index1]:
					var root1 = disjointSet.find(index1)
					var index0 = Utility.index(x, y, _width)
					var root0 = disjointSet.find(index0)
					if root0 != root1:
						disjointSet.union(root0, root1)

func _disjointSetup(list: Array) -> DisjointSet:
	var disjointSet = DisjointSet.new(_width * _height)
	for y in range(_height):
		for x in range(_width):
			if list[Utility.index(x, y, _width)]:
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
