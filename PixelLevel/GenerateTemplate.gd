extends Generate
class_name GenerateTemplate

const _color_back_floor := Color8(71, 112, 76, 0)
const _color_back_floor_room := Color8(255, 255, 255, 255)
const _color_back_wall := Color8(0, 0, 0, 255)
const _color_back_grass := Color8(193, 255, 113, 255)

const _color_fore_water_shallow := Color8(128, 255, 248, 255)
const _color_fore_water_deep := Color8(128, 200, 255, 255)
const _color_fore_water_shallow_purple := Color8(196, 110, 255, 255)
const _color_fore_water_deep_purple := Color8(156, 82, 255, 255)
const _color_fore_red := Color8(255, 41, 157, 255)
const _color_fore_yellow := Color8(255, 200, 33, 255)
const _color_fore_purple := Color8(132, 41, 255, 255)

var _select = Vector2.ZERO
var _rotate = 0

var _connect_any := []
var _connect_all := [0, 1, 2, 3]
var _connect_west_east := [1, 3]
var _connect_north_south := [0, 2]
var _connect_north := [0]
var _connect_east := [1]
var _connect_south := [2]
var _connect_west := [3]
var _connect_north_east := [2, 3]
var _connect_south_east := [0, 3]
var _connect_south_west := [0, 1]
var _connect_north_west := [2, 1]

var _data := {
	"a": {
		"name": "a",
		"back": load("res://PixelLevel/Sprite/Template/ABack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/AFore.png"),
		"size": 15,
		"probability": 33
	},
	"b": {
		"name": "b",
		"back": load("res://PixelLevel/Sprite/Template/BasicBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/BasicFore.png"),
		"size": 15,
		"probability": 100
	},
	"c": {
		"name": "c",
		"back": load("res://PixelLevel/Sprite/Template/CastleBack.png"),
		"fore": load("res://PixelLevel/Sprite/Template/CastleFore.png"),
		"size": 75,
		"probability": 1
	}
}

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	var template = Random.probability(_data)
	var single := true
	if template.name == "c":
		_cliff = false
		single = true
	else:
		single = Random.next_bool()
	if single:
		_set_level_rect(template.size + 10, template.size + 10)
		if template.name == "c":
			_fill(false, false, true)
		else:
			_fill(true, true)
		_find_template_with(template, _connect_any)
		_apply_template_at(template, Vector2(5, 5))
	else:
		if Random.next_bool(): # crossroad
			_set_level_rect(template.size * 3 + 10, template.size * 3 + 10)
			_fill(true, true)
			for y in 3:
				for x in 3:
					if x == 1 or y == 1:
						if x == 1 and y == 1:
							_find_template_with(template, _connect_all)
						elif x == 1 and y == 0:
							_find_template_with(template, _connect_north)
						elif x == 1 and y == 1:
							_find_template_with(template, _connect_south)
						elif x == 0 and y == 1:
							_find_template_with(template, _connect_east)
						elif x == 1 and y == 1:
							_find_template_with(template, _connect_west)
						_apply_template_at(template, Vector2(x * template.size + 5, y * template.size + 5))
		else:
			match Random.next(3):
				0: # all
					var width := Random.next(7)
					var height := Random.next(7)
					_set_level_rect(template.size * width, template.size * height)
					_fill(true, true)
					for y in height:
						for x in width:
							_find_template_with(template, _connect_all)
							_apply_template_at(template, Vector2(x * template.size, y * template.size))
				1: # loop
					var width := Random.next(7)
					var height := Random.next(7)
					_set_level_rect(template.size * width, template.size * height)
					_fill(true, true)
					for y in height:
						for x in width:
							if x == 0 and y == 0:
								_find_template_with(template, _connect_north_west)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
							elif x == width - 1 and y == 0:
								_find_template_with(template, _connect_north_east)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
							elif x == width - 1 and y == height - 1:
								_find_template_with(template, _connect_south_east)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
							elif x == 0 and y == height - 1:
								_find_template_with(template, _connect_south_west)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
							elif x == 0 or x == width - 1:
								_find_template_with(template, _connect_north_south)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
							elif y == 0 or y == height - 1:
								_find_template_with(template, _connect_west_east)
								_apply_template_at(template, Vector2(x * template.size, y * template.size))
				2: # tunnel
					var width: int
					var height: int
					var connections: Array
					if Random.next_bool():
						width = 1
						height = 1 + Random.next(7)
						connections = _connect_north_south
					else:
						width = 1 + Random.next(7)
						height = 1
						connections = _connect_west_east
					_set_level_rect(template.size * width, template.size * height)
					_fill(true, true)
					for y in height:
						for x in width:
							_find_template_with(template, connections)
							_apply_template_at(template, Vector2(x * template.size, y * template.size))
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()

# TODO bug detetected in this function. looping through the template size is not correct. wtf
func _apply_template_at(template: Dictionary, p: Vector2) -> void:
	for y in template.size:
		for x in template.size:
			var write := p + _apply_rotate(Vector2i(x, y), template.size, _rotate)
			var back_color: Color = template.back.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			var fore_color: Color = template.fore.get_pixel(_select.x * template.size + x, _select.y * template.size + y)
			if back_color == _color_back_floor:
				_set_floor(write)
			elif back_color == _color_back_wall:
				if template.name == "b":
					_set_wall_plain(write)
				else:
					_set_wall(write)
			elif back_color == _color_back_floor_room:
				_set_floor_room(write)
			elif back_color == _color_back_grass:
				_set_outside(write)
			if fore_color == _color_fore_water_shallow:
				_level.set_water_shallow(write)
			elif fore_color == _color_fore_water_deep:
				_level.set_water_deep(write)
			elif fore_color == _color_fore_water_shallow_purple:
				_level.set_water_shallow_purple(write)
			elif fore_color == _color_fore_water_deep_purple:
				_level.set_water_deep_purple(write)
			elif fore_color == _color_fore_red:
				_set_floor_room(write)
				_level.set_door(write)
			elif fore_color == _color_fore_purple:
				if Random.next_bool():
					if Random.next_bool():
						_level.set_banner_0(write)
					else:
						_level.set_banner_1(write)
				else:
					_level.set_fountain(write)
			elif fore_color == _color_fore_yellow:
				if Random.next_bool():
					_level.set_loot(write)

func _find_template_with(template: Dictionary, connections: Array) -> void:
	var size: int = template.size
	var count_x := int(template.back.get_size().x / size)
	var count_y := int(template.back.get_size().y / size)
	_select = Vector2(Random.next(count_x), Random.next(count_y))
	_rotate = Random.next(4)
	var offset := Vector2(_select.x * size, _select.y * size)
	var up := offset + _apply_rotate_back(Vector2(size / 2.0, 0), size, _rotate)
	var right := offset + _apply_rotate_back(Vector2(size - 1, size / 2.0), size, _rotate)
	var down := offset + _apply_rotate_back(Vector2(size / 2.0, size - 1), size, _rotate)
	var left := offset + _apply_rotate_back(Vector2(0, size / 2.0), size, _rotate)
	var connect_up: bool = template.back.get_pixelv(up) != _color_back_wall
	var connect_right: bool = template.back.get_pixelv(right) != _color_back_wall
	var connect_down: bool = template.back.get_pixelv(down) != _color_back_wall
	var connect_left: bool = template.back.get_pixelv(left) != _color_back_wall
	while (connections.size() and
		(connections.has(0) and not connect_up) or
		(connections.has(1) and not connect_right) or
		(connections.has(2) and not connect_down) or
		(connections.has(3) and not connect_left)):
		_select = Vector2(Random.next(count_x), Random.next(count_y))
		_rotate = Random.next(4)
		offset = Vector2(_select.x * size, _select.y * size)
		up = offset + _apply_rotate_back(Vector2(size / 2.0, 0), size, _rotate)
		right = offset + _apply_rotate_back(Vector2(size - 1, size / 2.0), size, _rotate)
		down = offset + _apply_rotate_back(Vector2(size / 2.0, size - 1), size, _rotate)
		left = offset + _apply_rotate_back(Vector2(0, size / 2.0), size, _rotate)
		connect_up = template.back.get_pixelv(up) != _color_back_wall
		connect_right = template.back.get_pixelv(right) != _color_back_wall
		connect_down = template.back.get_pixelv(down) != _color_back_wall
		connect_left = template.back.get_pixelv(left) != _color_back_wall

func _apply_rotate(p: Vector2, size: int, rotate: int) -> Vector2:
	var value: Vector2
	match rotate:
		0: value = Vector2(p.x, p.y) # north
		1: value = Vector2(size - p.y - 1, p.x) # east
		2: value = Vector2(size - p.x - 1, size - p.y - 1) # south
		3: value = Vector2(p.y, size - p.x - 1) # west
	return value

# TODO: this is a duplicate of _apply_rotate? why does it have different order? connections?
func _apply_rotate_back(p: Vector2, size: int, rotate: int) -> Vector2:
	var value: Vector2
	match rotate:
		0: value = Vector2(p.x, p.y) # north
		1: value = Vector2(p.y, size - p.x - 1) # west
		2: value = Vector2(size - p.x - 1, size - p.y - 1) # south
		3: value = Vector2(size - p.y - 1, p.x) # east
	return value
