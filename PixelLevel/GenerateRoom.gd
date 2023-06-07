extends Generate
class_name GenerateRoom

func _init(level: LevelBase) -> void:
	super(level)

func generate(delta: int = 1) -> void:
	super.generate(delta)
	_setLevelRect(10, 10)
	_fill(true, false)
	_drawRoom(_findRoom(_level.rect))
	_stairs()
	if _stream:
		_generateStreams()
	_level.generated()
