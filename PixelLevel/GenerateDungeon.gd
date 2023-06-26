extends Generate
class_name GenerateDungeon

const _max_room_width := 7
const _max_room_height := 7
const _min_room_width := 4
const _min_room_height := 4

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	var width := _max_room_width * (1 + Random.next(9))
	var height := _max_room_height * (1 + Random.next(9))
	_set_level_rect(width, height)
	_fill(true, false)
	var rooms := _place_rooms()
	_place_tunnels(rooms)
	_stairs()
	if _stream:
		_generate_streams()
	_level.generated()

func _place_rooms() -> Array:
	var across := int((_width) / float(_max_room_width))
	var down := int((_height) / float(_max_room_height))
	var max_rooms := across * down
	var used := Utility.array_repeat(false, max_rooms)
	var actual := 1 + Random.next(max_rooms - 1)
	var rooms := []
	var room_index := 0
	for _i in actual:
		var used_room := true
		while used_room:
			room_index = Random.next(max_rooms)
			used_room = used[room_index]
		used[room_index] = true
		var p := Utility.unflatten(room_index, across) * Vector2i(_max_room_width, _max_room_height)
		var room := Rect2(p.x, p.y, _max_room_width, _max_room_height)
		_draw_room(_find_room(room))
		rooms.append(room)
	return rooms

# FIXME: !?
func _place_tunnels(_rooms: Array) -> void:
	var delta_x_sign := 0
	var delta_y_sign := 0
	var current : Rect2
	var delta := Vector2.ZERO
	for room in _rooms:
		if current.size == Vector2.ZERO:
			current = room
			continue
		var current_center := current.position + current.size / 2.0
		var room_center : Vector2 = room.position + room.size / 2.0
		delta = room_center - current_center
		if is_equal_approx(delta.x, 0):	delta_x_sign = 1
		else: delta_x_sign = int(delta.x / abs(delta.x))
		if is_equal_approx(delta.y, 0): delta_y_sign = 1
		else: delta_y_sign = int(delta.y / abs(delta.y))
		while not (is_equal_approx(delta.x, 0) and is_equal_approx(delta.y, 0)):
			var moving_x := Random.next_bool()
			if moving_x and is_equal_approx(delta.x, 0): moving_x = false
			if not moving_x and is_equal_approx(delta.y, 0): moving_x = true
			var carve_length := Random.next_range(1, int(abs(delta.x if moving_x else delta.y)))
			for _i in carve_length:
				if moving_x: current_center.x += delta_x_sign * 1
				else: current_center.y += delta_y_sign * 1
				if not is_equal_approx(current_center.x, 1) and not is_equal_approx(current_center.y, 1):
					if _level.is_wall(current_center) or _level.is_cliff(current_center) or _level.is_fore_invalid(current_center):
						_level.clear_fore(current_center)
						_set_floor_or_room(current_center)
			if moving_x: delta.x -= delta_x_sign * carve_length
			else: delta.y -= delta_y_sign * carve_length
		current = room
