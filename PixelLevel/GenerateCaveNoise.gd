extends Generate
class_name GenerateCaveNoise

var _noise := FastNoiseLite.new()
var _offset := Vector2i.ZERO
var _max := 1000000

func _init(level: Level) -> void:
	super(level)

func generate(delta: int) -> void:
	super.generate(delta)
	_outside = Random.next_bool()
	_outside_wall = Random.next_bool()
	_fill(true, true, _outside)
	_draw_caves()
	if Random.next_bool():
		_draw_caves()
		if Random.next_bool():
			_draw_caves()
	_draw_tunnels()
	if Random.next_bool():
		_draw_tunnels()
		if Random.next_bool():
			_draw_tunnels()
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()

func _randomize() -> void:
	_noise.seed = Random.next(_max)
	_offset = Vector2i(Random.next(_max), Random.next(_max))

func _draw_caves() -> void:
	_randomize()
	for y in _height:
		for x in _width:
			if _noise.get_noise_2d(_offset.x + x, _offset.y + y) < 0:
				_set_floor_or_room(Vector2(x, y))

func _draw_tunnels() -> void:
	_randomize()
	for y in _height:
		for x in _width:
			if abs(_noise.get_noise_2d(_offset.x + x, _offset.y + y)) <= 0.1:
				_set_floor_or_room(Vector2(x, y))
