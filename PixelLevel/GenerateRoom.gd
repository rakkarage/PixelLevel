extends Generate

func generate() -> void:
	.generate()
	_setLevelRect(10, 10)
	_fill(true, false)
	_drawRoom(_findRoom(_level.rect))
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()
