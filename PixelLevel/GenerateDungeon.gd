extends Generate
class_name GenerateDungeon

const _max_room_width := 7
const _max_room_height := 7
const _min_room_width := 4
const _min_room_height := 4

func _init(level: Level) -> void:
	super(level)

func generate(delta: int) -> void:
	super.generate(delta)
	var width := _max_room_width * (1 + Random.next(9))
	var height := _max_room_height * (1 + Random.next(9))
	_set_level_rect(width, height)
	_fill(true, false)
	var rooms := _place_rooms()
	_place_tunnels(rooms)
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()

func _place_rooms() -> Array[Rect2i]:
	var across := int((_width) / float(_max_room_width))
	var down := int((_height) / float(_max_room_height))
	var max_rooms := across * down
	var used := Utility.array_repeat(false, max_rooms)
	var actual := 1 + Random.next(max_rooms - 1)
	var rooms: Array[Rect2i] = []
	var room_index := 0
	for _i in actual:
		var used_room := true
		while used_room:
			room_index = Random.next(max_rooms)
			used_room = used[room_index]
		used[room_index] = true
		var p := Utility.unflatten(room_index, across) * Vector2i(_max_room_width, _max_room_height)
		var room := Rect2i(p.x, p.y, _max_room_width, _max_room_height)
		_draw_room(_find_room(room))
		rooms.append(room)
	return rooms

const Directions: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

func _place_tunnels(_rooms: Array[Rect2i]) -> void:
	var astar := AStarGrid2D.new()
	astar.size = Vector2i(_width, _height)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	var current := _rooms[0]
	for room in _rooms:
		var from := current.position + Vector2i(current.size / 2.0)
		var to := room.position + Vector2i(room.size / 2.0)
		var path := astar.get_point_path(from, to)
		for step in path:
			if _level.is_wall(step) or _level.is_cliff(step) or _level.is_fore_invalid(step):
				_level.clear_fore(step)
				_set_floor_or_room(step)
		current = room
