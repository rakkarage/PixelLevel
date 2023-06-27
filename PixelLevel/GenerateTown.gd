extends Generate
class_name GenerateTown

func _init(level: Level) -> void:
	super(level)

func generate(delta: int) -> void:
	super.generate(delta)
	_set_level_rect(33, 33)
	_fill(false, Random.next_bool())
	_cliff = false
	_level._use_light = false
	_level.start_at = Vector2i(12, 12)
	for i in 10:
		_set_wall(Vector2i(i, 5))
	_level.set_door(Vector2i(10, 5))
	for i in 10:
		_set_wall(Vector2i(i+11, 5))
	var right := Vector2i(_level.start_at.x+1, _level.start_at.y)
	var left := Vector2i(_level.start_at.x-1, _level.start_at.y)
	_level.set_banner_0(right) if Random.next_bool() else _level.set_banner_1(right)
	_level.set_fountain(_level.start_at)
	_level.set_banner_0(left) if Random.next_bool() else _level.set_banner_1(left)
	_level.set_water_shallow(Vector2i(7, 7))
	_level.set_water_deep(Vector2i(8, 7))
	_level.set_water_shallow(Vector2i(9, 7))
	_level.set_water_shallow_purple(Vector2i(7, 8))
	_level.set_water_deep_purple(Vector2i(8, 8))
	_level.set_water_shallow_purple(Vector2i(9, 8))
	_stairs()
	_level.generated()
