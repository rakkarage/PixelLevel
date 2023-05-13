extends Generate
class_name GenerateMaze

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	var depth: int = int(abs(_level.state.depth)) + 10
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
	var p := Vector2.ZERO
	var g := Random.next(4)
	match g:
		0: p = Vector2(1, 1)
		1: p = Vector2(1, _height - 2)
		2: p = Vector2(_width - 2, 1)
		3: p = Vector2(_width - 2, _height - 2)
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
	_level.clearForeV(p)
	_setFloorOrRoomV(p)
	var points := []
	points.append(p)
	while points.size():
		var random := Random.next(points.size())
		var current : Vector2 = points[random]
		points.remove_at(random)
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
					if ((_level.isWallV(east) or _level.isCliffV(east)) and
						(_level.isWallV(eastEast) or _level.isCliffV(eastEast))):
						_level.clearForeV(east)
						_setFloorOrRoomV(east)
						_level.clearForeV(eastEast)
						_setFloorOrRoomV(eastEast)
						points.append(eastEast)
				1:
					westChecked = true
					if ((_level.isWallV(west) or _level.isCliffV(west)) and
						(_level.isWallV(westWest) or _level.isCliffV(westWest))):
						_level.clearForeV(west)
						_setFloorOrRoomV(west)
						_level.clearForeV(westWest)
						_setFloorOrRoomV(westWest)
						points.append(westWest)
				2:
					northChecked = true
					if ((_level.isWallV(north) or _level.isCliffV(north)) and
						(_level.isWallV(northNorth) or _level.isCliffV(northNorth))):
						_level.clearForeV(north)
						_setFloorOrRoomV(north)
						_level.clearForeV(northNorth)
						_setFloorOrRoomV(northNorth)
						points.append(northNorth)
				3:
					southChecked = true
					if ((_level.isWallV(south) or _level.isCliffV(south)) and
						(_level.isWallV(southSouth) or _level.isCliffV(southSouth))):
						_level.clearForeV(south)
						_setFloorOrRoomV(south)
						_level.clearForeV(southSouth)
						_setFloorOrRoomV(southSouth)
						points.append(southSouth)
	_level.setStairUpV(start)
	_level.setStairDownV(end)
