extends Generate

func generate() -> void:
	.generate()
	assert(_level != null)
	_fill(false, Random.nextBool())
	if _stream:
		_generateStreams()
	_stairs()
	_level.generated()
