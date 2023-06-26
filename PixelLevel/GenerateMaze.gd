extends Generate
class_name GenerateMaze

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	var depth = abs(_level._state.depth) + 10
	var width := Random.next_range_odd(depth, depth + Random.next(depth))
	var height := Random.next_range_odd(depth, depth + Random.next(depth))
	_set_level_rect(width, height)
	_fill(true, true)
	_drawMaze()
	if _stream:
		_generate_streams()
	_level.generated()

func _drawMaze() -> void:
	var start := Vector2i.ZERO
	var end := Vector2i.ZERO
	var p := Vector2i.ZERO
	var g := Random.next(4)
	match g:
		0: p = Vector2i(1, 1)
		1: p = Vector2i(1, _height - 2)
		2: p = Vector2i(_width - 2, 1)
		3: p = Vector2i(_width - 2, _height - 2)
	var s = Random.next(4)
	match s:
		0:
			start = Vector2i(1, 1)
			end = Vector2i(_width - 2, _height - 2)
		1:
			start = Vector2i(1, _height - 2)
			end = Vector2i(_width - 2, 1)
		2:
			start = Vector2i(_width - 2, 1)
			end = Vector2i(1, _height - 2)
		3:
			start = Vector2i(_width - 2, _height - 2)
			end = Vector2i(1, 1)
	_level.start_at = start
	_level.clear_fore(p)
	_set_floor_or_room(p)
	var points: Array[Vector2i] = []
	points.append(p)
	while points.size():
		var random := Random.next(points.size())
		var current := points[random]
		points.remove_at(random)
		var east := Vector2i(current.x + 1, current.y)
		var east_east := Vector2i(current.x + 2, current.y)
		var west := Vector2i(current.x - 1, current.y)
		var west_west := Vector2i(current.x - 2, current.y)
		var north := Vector2i(current.x, current.y + 1)
		var north_north := Vector2i(current.x, current.y + 2)
		var south := Vector2i(current.x, current.y - 1)
		var south_south := Vector2i(current.x, current.y - 2)
		var checked_east := false
		var checked_west := false
		var checked_north := false
		var checked_south := false
		while not checked_east or not checked_west or not checked_north or not checked_south:
			match Random.next(4):
				0:
					checked_east = true
					if ((_level.is_wall(east) or _level.is_cliff(east)) and
						(_level.is_wall(east_east) or _level.is_cliff(east_east))):
						_level.clear_fore(east)
						_set_floor_or_room(east)
						_level.clear_fore(east_east)
						_set_floor_or_room(east_east)
						points.append(east_east)
				1:
					checked_west = true
					if ((_level.is_wall(west) or _level.is_cliff(west)) and
						(_level.is_wall(west_west) or _level.is_cliff(west_west))):
						_level.clear_fore(west)
						_set_floor_or_room(west)
						_level.clear_fore(west_west)
						_set_floor_or_room(west_west)
						points.append(west_west)
				2:
					checked_north = true
					if ((_level.is_wall(north) or _level.is_cliff(north)) and
						(_level.is_wall(north_north) or _level.is_cliff(north_north))):
						_level.clear_fore(north)
						_set_floor_or_room(north)
						_level.clear_fore(north_north)
						_set_floor_or_room(north_north)
						points.append(north_north)
				3:
					checked_south = true
					if ((_level.is_wall(south) or _level.is_cliff(south)) and
						(_level.is_wall(south_south) or _level.is_cliff(south_south))):
						_level.clear_fore(south)
						_set_floor_or_room(south)
						_level.clear_fore(south_south)
						_set_floor_or_room(south_south)
						points.append(south_south)
	_level.set_stair_up(start)
	_level.set_stair_down(end)
