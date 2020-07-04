extends Generate

const _maxRoomWidth := 7
const _maxRoomHeight := 7
const _minRoomWidth := 4
const _minRoomHeight := 4

func generate() -> void:
	.generate()
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
		var p := Utility.position(i, across) * Vector2(_maxRoomWidth, _maxRoomHeight)
		if not fill:
			p.x += _maxRoomWidth - w / 2.0
			p.y += _maxRoomHeight - h / 2.0
		var room := Rect2(p.x, p.y, w, h)
		_drawRoom(room)
		rooms.append(room)
	return rooms

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
