extends Generate
class_name GenerateCave

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_outside = Random.next_bool()
	_outside_wall = Random.next_bool()
	_fill(true, true, _outside)
	_drawCaves()
	if _outside:
		_draw_outside()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()

func _drawCaves() -> void:
	var ca := CellularAutomaton.new(_width, _height)
	var caves := ca.generate()
	var biggest := ca.find_biggest(caves)
	if Random.next_bool():
		caves = ca.map_biggest(biggest)
	while biggest.size() < 4:
		caves = ca.generate()
		biggest = ca.find_biggest(caves)
		if Random.next_bool():
			caves = ca.map_biggest(biggest)
	if Random.next_bool():
		var other := ca.generate()
		var other_biggest := ca.find_biggest(other)
		if Random.next_bool():
			other = ca.map_biggest(other_biggest)
		caves = ca.combine(caves, other)
		biggest.append_array(other_biggest.filter(func(index: int): return !biggest.has(index)))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if caves[Utility.flatten(p, _width)]:
				_set_cave_wall(p)
			else:
				_set_cave_floor(p)
	if not _outside or not _outside_wall:
		_outline_caves(caves)
	_stairs_at(biggest)

func _is_cave_edge(list: Array, position: Vector2i) -> bool:
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

func _outline_caves(list: Array) -> void:
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if list[Utility.flatten(p, _width)]:
				if _is_cave_edge(list, p):
					_set_wall(p)

func _draw_outside() -> void:
	if not _level._desert:
		if Random.next_bool():
			_draw_flowers()
		if Random.next_bool():
			_draw_trees()
		if Random.next_bool():
			_draw_weed()

func _draw_flowers() -> void:
	var ca := CellularAutomaton.new(_width, _height)
	var flowers := ca.generate()
	if Random.next_bool():
		flowers = ca.map_biggest(ca.find_biggest(flowers))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not flowers[Utility.flatten(p, _width)] and not _level.is_wall(p) and not _level.is_back_invalid(p) and not _level.is_stair(p):
				_level.set_flower(p)

func _draw_trees() -> void:
	var cut_some := Random.next_float() < 0.333
	var cut_patch := Random.next_float() < 0.333
	var ca := CellularAutomaton.new(_width, _height)
	var trees := ca.generate()
	if Random.next_bool():
		trees = ca.map_biggest(ca.find_biggest(trees))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not trees[Utility.flatten(p, _width)] and not _level.is_wall(p) and not _level.is_back_invalid(p) and not _level.is_stair(p):
				if cut_some and Random.next_bool():
					_level.set_tree_stump(p)
				else:
					_level.set_tree(p)
	if not cut_some and cut_patch and Random.next_bool():
		_cut_trees(trees)

func _cut_trees(array: Array) -> void:
	var caves := DisjointSet.new(_width, _height, array).split()
	for cave in caves:
		if Random.next(3) == 0: # cut
			if Random.next(4) == 0: # cut all
				for i in cave:
					var p := Utility.unflatten(i, _width)
					if not _level.is_wall(p) and not _level.is_back_invalid(p) and not _level.is_stair(p):
						_level.cut_cree(Utility.unflatten(i, _width))
			elif Random.next_bool(): # cut some
				var direction := Random.next(4)
				var test := Utility.unflatten(cave[Random.next(cave.size())], _width)
				for i in cave:
					var p := Utility.unflatten(i, _width)
					if not _level.is_wall(p) and not _level.is_back_invalid(p) and not _level.is_stair(p):
						match direction:
							0:
								if p.x > test.x:
									_level.cut_tree(p)
								elif p.x == test.x:
									if Random.next_bool():
										_level.cut_tree(p)
							1:
								if p.x < test.x:
									_level.cut_tree(p)
								elif p.x == test.x:
									if Random.next_bool():
										_level.cut_tree(p)
							2:
								if p.y > test.y:
									_level.cut_tree(p)
								elif p.y == test.y:
									if Random.next_bool():
										_level.cut_tree(p)
							3:
								if p.y < test.y:
									_level.cut_tree(p)
								elif p.y == test.y:
									if Random.next_bool():
										_level.cut_tree(p)

func _draw_weed() -> void:
	var ca := CellularAutomaton.new(_width, _height)
	var grass := ca.generate()
	if Random.next_bool():
		grass = ca.map_biggest(ca.find_biggest(grass))
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if not grass[Utility.flatten(p, _width)] and not _level.is_wall(p) and not _level.is_back_invalid(p) and not _level.is_stair(p):
				_level.set_weed(p)
