extends Generate
class_name GenerateRoom

func _init(level: Level).(level) -> void: pass

func generate() -> void:
	.generate()
	_setLevelRect(10, 10)
	_fill(true, false)
	_drawRoom(_findRoom(_level.rect))
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()
