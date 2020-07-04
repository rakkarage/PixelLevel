extends Generate

func generate() -> void:
	.generate()
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
