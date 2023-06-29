extends Object
class_name Generate

var _level : Level
var priority = 1
var _width := 0
var _height := 0
var _cliff := false
var _stream := false
const _torch_chance := 0.01
const _fancy_chance := 0.02
const _cliff_chance := 0.333
const _stream_chance := 0.22
var _wonky := false
var _room := false
var _outside := false
var _outside_wall := false

func _init(level: Level) -> void:
	_level = level

func generate_up() -> void:
	generate(-1)

func generate(delta: int) -> void:
	_level.clear()
	_level._use_light = true
	LevelStore.data.main.depth += delta
	var d = 10 + abs(LevelStore.data.main.depth)
	_set_level_rect(d * 2 + Random.next(d), d * 2 + Random.next(d))
	_level._theme = Random.next(_level._theme_count)
	_level._day = Random.next_bool()
	_level._desert = Random.next(5) == 0
	_level._theme_cliff = Random.next(_level._theme_cliff_count)
	_cliff = Random.next_float() <= _cliff_chance
	_stream = Random.next_float() <= _stream_chance
	_wonky = Random.next_bool()
	_room = Random.next_bool()

func regenerate() -> void:
	generate(0)

func _set_level_rect(width: int, height: int) -> void:
	_width = width
	_height = height

func _fill(wall: bool, wallEdge: bool, outside: bool = false) -> void:
	_outside = outside
	for y in _height:
		for x in _width:
			var p := Vector2i(x, y)
			if _outside:
				_set_outside(p)
			else:
				_set_floor_or_room(p)
			if wall:
				_set_wall_plain(p)
			elif wallEdge:
				if y == 0 or y == _height - 1 or x == 0 or x == _width - 1:
					_set_wall(p)

func _stairs() -> void:
	if LevelStore.data.main.depth > 0:
		var up := _find_spot()
		_level.start_at = up
		_level.set_stair_outside_up(up) if _outside else _level.set_stair_up(up)
	var down := _find_spot()
	_level.set_stair_outside_down(down) if _outside else _level.set_stair_down(down)

func _stairs_at(array: Array) -> void:
	if LevelStore.data.main.depth > 0:
		var up := Utility.unflatten(array.pick_random(), _width)
		_level.start_at = up
		_level.set_stair_outside_up(up) if _outside else _level.set_stair_up(up)
	var down := Utility.unflatten(array.pick_random(), _width)
	_level.set_stair_outside_down(down) if _outside else _level.set_stair_down(down)

func _random() -> Vector2i:
	return Vector2i(Random.next_range(1, _width - 2), Random.next_range(1, _height - 2))

func _find_spot() -> Vector2:
	var p := _random()
	while _level.is_wall(p) or _level.is_stair(p) or not _level.is_floor(p):
		p = _random()
	return p

func _set_floor(p: Vector2i) -> void:
	_level.set_floor(p, _wonky)
	_level.clear_fore(p)

func _set_floor_room(p: Vector2i) -> void:
	_level.set_floor_room(p, _wonky)
	_level.clear_fore(p)

func _set_outside(p: Vector2i) -> void:
	_level.set_outside(p)
	_level.clear_fore(p)

func _set_floor_or_room(p: Vector2i) -> void:
	if _room:
		_level.set_floor_room(p, _wonky)
	else:
		_level.set_floor(p, _wonky)
	_level.clear_fore(p)

func _set_outside_wall(p: Vector2i) -> void:
	_level.set_outside_wall(p)
	_level.clear_back(p)

func _set_wall_plain(p: Vector2i) -> void:
	if _cliff:
		_level.set_cliff(p)
	else:
		_level.set_wall_plain(p)
	_level.clear_back(p)

func _set_wall(p: Vector2i) -> void:
	if _cliff:
		_level.set_cliff(p)
	else:
		if Random.next_float() <= _torch_chance:
			_level.set_torch(p)
		else:
			if Random.next_float() <= _fancy_chance:
				_level.set_wall(p)
			else:
				_level.set_wall_plain(p)
	_level.clear_back(p)

func _set_cave_floor(p: Vector2i) -> void:
	if _outside:
		_set_outside(p)
	else:
		if _room:
			_set_floor_room(p)
		else:
			_set_floor(p)

func _set_cave_wall(p: Vector2i) -> void:
	if _cliff:
		_level.set_cliff(p)
	else:
		if _outside and _outside_wall:
			_set_outside_wall(p)
		else:
			_set_wall_plain(p)

func _generate_streams() -> void:
	if Random.next_float() <= 0.333:
		_generate_stream(true)
		_generate_stream(false)
	elif Random.next_bool():
		_generate_stream(Random.next_bool())
		if Random.next_bool():
			_generate_stream(Random.next_bool())
	else:
		_generate_stream(Random.next_bool())

const _leave_chance := 0.333
const _leave_none_chance := 0.333
var _leave_none := false

func _generate_stream(horizontal: bool) -> void:
	_leave_none = Random.next_float() <= _leave_none_chance
	var roughness := Random.next_float()
	var windyness := Random.next_float()
	var width := 3 + Random.next(5)
	var half := int(width / 2.0)
	var start
	var rect
	var opposite := Random.next_bool()
	if horizontal:
		var tempY := 2 + half + Random.next(_height - 4 - half)
		start = Vector2(_width - 1 if opposite else 0, tempY)
		rect = Rect2(start.x, tempY - half, 1, width)
	else:
		var tempX := 2 + half + Random.next(_width - 4 - half)
		start = Vector2(tempX, _height - 1 if opposite else 0)
		rect = Rect2(tempX - half, start.y, width, 1)
	_fill_stream(rect)
	while ((start.x > 0 if horizontal else start.y > 0) if opposite else
		(start.x < _width - 1 if horizontal else start.y < _height - 1)):
		if horizontal:
			start.x += -1 if opposite else 1
		else:
			start.y += -1 if opposite else 1
		if Random.next_float() <= roughness:
			var add := -2 + Random.next(5)
			width += add
			if horizontal:
				if width > _height:
					width = _height
			else:
				if width > _width:
					width = _width
			if width < 3:
				width = 3
			half = int(width / 2.0)
		if Random.next_float() <= windyness:
			var add := -1 + Random.next(3)
			if horizontal:
				start.y += add
				if start.y > _height - 2:
					start.y = _height - 1
				elif start.y < 2:
					start.y = 2
			else:
				start.x += add
				if start.x > _width - 2:
					start.x = _width - 2
				elif start.x < 2:
					start.x = 2
		if horizontal:
			rect = Rect2(start.x, start.y - half, 1, width)
		else:
			rect = Rect2(start.x - half, start.y, width, 1)
		_fill_stream(rect)

func _fill_stream(rect: Rect2) -> void:
	var horizontal := rect.size.x == 1
	var deep_width := int(rect.size.y / 3.0 if horizontal else rect.size.x / 3.0)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var p := Vector2i(x, y)
			var deep := false
			if horizontal:
				if y >= rect.position.y + deep_width && y < rect.end.y - deep_width:
					deep = true
			else:
				if x >= rect.position.x + deep_width && x < rect.end.x - deep_width:
					deep = true
			if _level.is_inside_map(p) and _level.is_floor(p) or _level.is_wall(p):
				var keep := false
				if _level.is_wall(p):
					if _leave_none or Random.next_float() > _leave_chance:
						_level.set_rubble(p)
						_level.clear_fore(p)
					else:
						keep = true
				elif _level.is_door(p):
					_level.set_door_broke(p)
				if not keep:
					if not _level.is_stair(p):
						_level.clear_fore(p)
					var already_deep = _level.is_water_deep(p)
					if deep or already_deep:
						if not already_deep:
							_level.set_water_deep(p)
					else:
						_level.set_water_shallow(p)

func _find_room(rect: Rect2) -> Rect2:
	var position_x := Random.next_range(int(rect.position.x), int(rect.position.x + rect.size.x / 2.0 - 2))
	var position_y := Random.next_range(int(rect.position.y), int(rect.position.y + rect.size.y / 2.0 - 2))
	var size_x := Random.next_range(4, int(rect.end.x - position_x))
	var size_y := Random.next_range(4, int(rect.end.y - position_y))
	return Rect2(position_x, position_y, size_x, size_y)

func _draw_room(rect: Rect2) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var p := Vector2i(x, y)
			if (x == rect.position.x or x == rect.end.x - 1 or
				y == rect.position.y or y == rect.end.y - 1):
				_set_wall(p)
			else:
				_level.clear_fore(p)
				_set_floor_or_room(p)
