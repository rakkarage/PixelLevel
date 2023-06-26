extends Generate
class_name GenerateRoom

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_set_level_rect(10, 10)
	_fill(true, false)
	_draw_room(_find_room(_level.tile_rect()))
	_stairs()
	if not _cliff and _stream:
		_generate_streams()
	_level.generated()
