extends Generate
class_name GenerateTown

func _init(level: Level) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_set_level_rect(33, 33)
	_fill(true, false)
	_draw_room(_find_room(_level.tile_rect()))
	_stairs()
	_level.generated()
